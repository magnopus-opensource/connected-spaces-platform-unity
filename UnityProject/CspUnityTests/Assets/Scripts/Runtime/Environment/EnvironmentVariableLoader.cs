// ------------------------------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ------------------------------------------------------------------

using System;
using System.Collections.Generic;
using System.IO;
#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;

namespace Magnopus.SessionState.Environment
{
    public class EnvironmentVariableLoader
    {
        private const string EnvFileDirectory = "ProjectConfigs";
        private const string EnvFileName = "EnvironmentVariables.env";

        private static Dictionary<string, string> envVariables = new Dictionary<string, string>();
        private static bool isEnvFileLoaded;
        
        /// <summary>
        /// Used to create a .env file during build time since the build pipeline will never contain a .env file to begin with.
        /// The build pipeline will use the system environment variables instead.
        /// </summary>
        public static void WriteEnvFile()
        {
            if (!isEnvFileLoaded)
            {
                // Throw if we haven't even attempted to load the env file first
                throw new InvalidOperationException("Attempting to write env file without loading it first.");
            }

            if (envVariables == null || envVariables.Count == 0)
            {
                Debug.LogWarning("No environment variables found to write to .env file. Skipping write operation.");
                return;
            }

            try
            {
                var writeFilePath = Path.Combine(Application.streamingAssetsPath, EnvFileDirectory, EnvFileName);

                Debug.Log($"Begin writing .env file to path: {writeFilePath}");

                var writeDir = Path.GetDirectoryName(writeFilePath);
                if (!string.IsNullOrWhiteSpace(writeDir) && !Directory.Exists(writeDir))
                {
                    Directory.CreateDirectory(writeDir);
                }

                using (var writer = new StreamWriter(writeFilePath, false))
                {
                    foreach (var kvp in envVariables)
                    {
                        writer.WriteLine($"{kvp.Key}={kvp.Value}");
                    }
                }

                Debug.Log("Finished writing .env file.");
            }
            catch (Exception ex)
            {
                Debug.LogError($"Failed to write .env file. MSG: {ex.Message} | Stack: {ex.StackTrace}");
            }
        }

        /// <summary>
        /// Sets up and loads the environment file. If no env file exists, this will try to use the system environment variables instead.
        /// This must be called before getting an environment variable or writing the env file.
        /// </summary>
        /// <param name="allEnvironmentVariableNames"> An array of all variable names to load from the local system if no env file is found. </param>
        /// <param name="customFullDirectoryPath"> Optional: new directory path to use instead of the default streaming assets path. </param>
        /// <returns> True if successful (Even if there is no environment file to load). Only returns false if <paramref name="allEnvironmentVariableNames"/> is null, or there is an error. </returns>
        public static bool LoadEnvFile(string[] allEnvironmentVariableNames, string customFullDirectoryPath = null)
        {
            // We don't need to reload the env file if it was already loaded
            if (isEnvFileLoaded)
            {
                return true;
            }

            string envFilePath = !string.IsNullOrWhiteSpace(customFullDirectoryPath) ? 
                Path.Combine(customFullDirectoryPath, EnvFileName) 
                : Path.Combine(Application.streamingAssetsPath, EnvFileDirectory, EnvFileName);
            string[] allLines = null;
            
#if UNITY_ANDROID && !UNITY_EDITOR
            // On Android, skip File.Exists (it will always fail for StreamingAssets)
            logger.LogDebug($"Looking for .env file at {envFilePath} on Android...");
            using (var request = UnityEngine.Networking.UnityWebRequest.Get(envFilePath))
            {
                // TODO (https://magnopus.atlassian.net/browse/OPE-2840): Consider making this async to improve performance
                request.SendWebRequest();
                while (!request.isDone) { } // blocking version; async is better if possible

                if (request.result == UnityEngine.Networking.UnityWebRequest.Result.Success)
                {
                    allLines = request.downloadHandler.text
                        .Split(new[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries);
                }
                else
                {
                    logger.LogWarning($"Failed to load .env on Android file from {envFilePath}. Error: {request.error}. Falling back to system environment variables.");
                    return LoadFromSystemEnvironment(allEnvironmentVariableNames);
                }
            }
#else
            Debug.Log($"Looking for .env file at {envFilePath} ...");
            if (File.Exists(envFilePath))
            {
                Debug.Log($"Found .env file at {envFilePath}, creating dictionary from values.");
                try
                {
                    allLines = File.ReadAllLines(envFilePath);
                }
                catch (Exception ex)
                {
                    Debug.LogWarning($"Failed to read all lines for .env file found at {envFilePath}. MSG: {ex.Message}. Falling back to system environment variables.");
                    return LoadFromSystemEnvironment(allEnvironmentVariableNames);
                }
            }
            else
            {
                Debug.LogWarning($"No .env file found at {envFilePath}. Falling back to system environment variables.");
#if UNITY_EDITOR
                EditorUtility.DisplayDialog("Missing Environment File",
                    $"No .env file was found at the expected path: {envFilePath}.\n \n"
                    + $"The system environment variables will be used instead.\n \n"
                    + $"Please ensure that the required environment variables file is in the location shown above, check docs for details.",
                    ok: "OK");
#endif
                return LoadFromSystemEnvironment(allEnvironmentVariableNames);
            }
#endif
            try
            {
                if (allLines.Length == 0)
                {
                    Debug.LogWarning($"No lines to read for .env file at {envFilePath}. Falling back to system environment variables.");
                    return LoadFromSystemEnvironment(allEnvironmentVariableNames);
                }

                foreach (var line in allLines)
                {
                    if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#'))
                    {
                        continue; // Skip comments and empty lines
                    }

                    var parts = line.Split('=', 2);
                    if (parts.Length == 2)
                    {
                        envVariables[parts[0].Trim()] = parts[1].Trim();
                    }
                }
                        
                isEnvFileLoaded = true;
                return true;
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"Failed to parse all lines for .env file found at {envFilePath}. MSG: {ex.Message}. Falling back to system environment variables.");
                return LoadFromSystemEnvironment(allEnvironmentVariableNames);
            }
        }

        /// <summary>
        /// Loads from the system environment variables (in build pipeline) instead of the .env file.
        /// This is useful when making builds in CI/CD pipelines where the .env file is not available.
        /// </summary>
        private static bool LoadFromSystemEnvironment(string[] allEnvironmentVariableNames)
        {
            if (allEnvironmentVariableNames == null || allEnvironmentVariableNames.Length == 0)
            {
                Debug.LogError("Cannot load from system environment. No environment variables names given.");
                return false;
            }

            foreach (var variableName in allEnvironmentVariableNames)
            {
                try
                {
                    var variable = System.Environment.GetEnvironmentVariable(variableName);
                    if (string.IsNullOrWhiteSpace(variable))
                    {
                        continue;
                    }

                    var keyValue = variable.Split('=');
                    if (keyValue.Length == 2)
                    {
                        envVariables[keyValue[0].Trim()] = keyValue[1].Trim();
                    }
                }
                catch (Exception ex)
                {
                    Debug.LogWarning($"Failed to load environment variable {variableName} from system environment. MSG: {ex.Message}");
                    return false;
                }
            }

            isEnvFileLoaded = true;
            return true;
        }

        /// <summary>
        /// Used to get the value of an environment variable from the .env file or system environment variables.
        /// </summary>
        /// <param name="variableName"> The key used to get the value </param>
        /// <returns> The environment variable value </returns>
        public static string GetEnvironmentVariable(string variableName)
        {
            if (!isEnvFileLoaded)
            {
                // Throw if we haven't even attempted to load the env file first
                throw new InvalidOperationException("Attempting to get env file variable without loading it first.");
            }

            return envVariables.TryGetValue(variableName, out string value) ? value : null;
        }
    }
}
