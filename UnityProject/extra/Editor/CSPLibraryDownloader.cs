using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.Networking;

namespace Plugins.Editor
{
    [InitializeOnLoad]
    public class CSPBinaryDownloader
    {
        private const string PackageName = "com.magnopus.csp.unity";
        private const string MenuPath = "MAGNOPUS/Download CSP Libraries";

        // A targeted custom exception for our downstream catchers
        public class LibraryInstallationException : Exception
        {
            public LibraryInstallationException(string message) : base(message) { }
            public LibraryInstallationException(string message, Exception innerException) : base(message, innerException) { }
        }

        static CSPBinaryDownloader()
        {
            // Check for binaries shortly after the editor opens
            EditorApplication.delayCall += () => CheckForMissingBinaries(false);
        }

        [MenuItem(MenuPath)]
        public static void ManualDownloadTrigger()
        {
            CheckForMissingBinaries(true);
        }

        public static void CheckForMissingBinaries(bool forceManual)
        {
            string packagePath = Path.GetFullPath($"Packages/{PackageName}");
            string metadataPath = Path.Combine(packagePath, "package-dist.json");
        
            // Target: Assets/Plugins/CSP/Internal (Unity has write access here)
            string localPluginsPath = Path.Combine(Application.dataPath, "Plugins/CSP/Internal");

            bool binariesExist = Directory.Exists(localPluginsPath) && 
                                 Directory.GetFiles(localPluginsPath, "*", SearchOption.AllDirectories).Length > 0;

            if (!binariesExist || forceManual)
            {
                if (!File.Exists(metadataPath))
                {
                    if (forceManual) Debug.LogError($"Metadata not found at {metadataPath}. Ensure package is installed via Git.");
                    return;
                }

                DistributionMetadata data;
                try
                {
                    data = ReadMetadata(metadataPath);
                }
                catch (LibraryInstallationException e)
                {
                    Debug.LogException(e);
                    if (forceManual)
                    {
                        EditorUtility.DisplayDialog("Error", e.Message, "OK");
                    }
                    return;
                }

                bool proceed = forceManual || EditorUtility.DisplayDialog(
                    "CSP Binaries Missing",
                    $"The {PackageName} package requires native binaries ({data.version}).\n\nDownload approx 400MB from GitHub?",
                    "Download", "Skip");

                if (proceed)
                {
                    StartEditorDownload(data.downloadUrl, localPluginsPath);
                }
            }
        }

        private static DistributionMetadata ReadMetadata(string path)
        {
            try
            {
                string json = File.ReadAllText(path);
                var data = JsonUtility.FromJson<DistributionMetadata>(json);
                
                if (data == null || string.IsNullOrEmpty(data.downloadUrl))
                    throw new LibraryInstallationException("downloadUrl is empty or malformed in package-dist.json");
                    
                return data;
            }
            catch (IOException e)
            {
                throw new LibraryInstallationException($"Failed to read metadata file at {path}", e);
            }
            catch (ArgumentException e)
            {
                throw new LibraryInstallationException($"Failed to parse JSON in metadata file at {path}", e);
            }
        }

        private static void StartEditorDownload(string url, string targetPath)
        {
            UnityWebRequest www = UnityWebRequest.Get(url);
            www.SendWebRequest();

            // Standard Editor Update loop to handle the download without blocking the UI
            EditorApplication.CallbackFunction updateAction = null;
            updateAction = () =>
            {
                bool shouldCleanup = false;

                try
                {
                    if (www == null) 
                    {
                        shouldCleanup = true;
                        return;
                    }

                    if (!www.isDone)
                    {
                        bool isCanceled = EditorUtility.DisplayCancelableProgressBar(
                            "Downloading CSP", 
                            $"Fetching binaries... {Mathf.RoundToInt(www.downloadProgress * 100)}%", 
                            www.downloadProgress);

                        if (isCanceled)
                        {
                            www.Abort(); 
                            shouldCleanup = true;
                            Debug.Log("CSP Binary download was canceled by the user.");
                        }
                        return; // Exit normally, wait for next frame
                    }

                    // If we reach here, the download naturally finished
                    shouldCleanup = true;

                    if (www.result == UnityWebRequest.Result.Success)
                    {
                        ProcessDownload(www.downloadHandler.data, targetPath);
                    }
                    else
                    {
                        var webEx = new LibraryInstallationException($"Network error during download: {www.error}");
                        Debug.LogException(webEx);
                        EditorUtility.DisplayDialog("Download Failed", $"Could not download binaries: {www.error}", "OK");
                    }
                }
                catch (Exception e)
                {
                    // Catch any unexpected errors so they don't break the Editor
                    Debug.LogException(e);
                    shouldCleanup = true; 
                }
                finally
                {
                    // This guarantees the UI is unblocked and memory is freed, 
                    // but ONLY when the process is actually terminating!
                    if (shouldCleanup)
                    {
                        EditorUtility.ClearProgressBar();
                        EditorApplication.update -= updateAction;
                        
                        if (www != null)
                        {
                            www.Dispose();
                            www = null; // Null it out to prevent double-disposal
                        }
                    }
                }
            };

            EditorApplication.update += updateAction;
        }

        private static void ProcessDownload(byte[] data, string targetFolder)
        {
            string tempPath = Path.Combine(Application.temporaryCachePath, "csp_binaries.tgz");
            
            try 
            {
                SaveTarball(data, tempPath);
                ExtractTarball(tempPath, targetFolder);
                CleanupRedundantFiles(targetFolder);

                AssetDatabase.Refresh();
                EditorUtility.DisplayDialog("Success", "CSP Binaries successfully installed.", "OK");
            }
            catch (LibraryInstallationException e)
            {
                Debug.LogException(e);
                EditorUtility.DisplayDialog("Extraction Error", $"Failed to install binaries:\n{e.Message}", "OK");
            }
            finally
            {
                if (File.Exists(tempPath)) 
                {
                    try
                    {
                        File.Delete(tempPath);
                    }
                    catch
                    {
                         /* Ignore cleanup errors in finally block */
                    }
                }
            }
        }

        private static void SaveTarball(byte[] data, string savePath)
        {
            try
            {
                File.WriteAllBytes(savePath, data);
            }
            catch (IOException e)
            {
                throw new LibraryInstallationException($"Could not write temporary tarball to {savePath}", e);
            }
            catch (UnauthorizedAccessException e)
            {
                throw new LibraryInstallationException($"Access denied when writing to {savePath}", e);
            }
        }

        private static void ExtractTarball(string archivePath, string targetFolder)
        {
            try 
            {
                if (!Directory.Exists(targetFolder))
                {
                    Directory.CreateDirectory(targetFolder);
                }
            }
            catch (Exception e)
            {
                throw new LibraryInstallationException($"Failed to create target directory {targetFolder}", e);
            }

            Debug.Log($"Extracting to {targetFolder}...");
            
            // Uses system 'tar' (Available on Win 10+, macOS, Linux)
            System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo
            {
                FileName = "tar",
                Arguments = $"-xf \"{archivePath}\" -C \"{targetFolder}\"",
                UseShellExecute = false,
                CreateNoWindow = true
            };

            try
            {
                using (var process = System.Diagnostics.Process.Start(startInfo))
                {
                    if (process == null) throw new LibraryInstallationException("Failed to initialize tar process.");
                    
                    process.WaitForExit();
                    if (process.ExitCode != 0)
                    {
                        throw new LibraryInstallationException($"Tar extraction failed with exit code {process.ExitCode}");
                    }
                }
            }
            catch (System.ComponentModel.Win32Exception e)
            {
                throw new LibraryInstallationException("Failed to start the 'tar' command. Ensure it is available on your system.", e);
            }
        }

        private static void CleanupRedundantFiles(string targetFolder)
        {
            try
            {
                // Remove duplicated C# source folders that were included in the tarball
                string[] redundantDirs = { "Runtime", "Editor" };
                foreach (string dir in redundantDirs)
                {
                    string path = Path.Combine(targetFolder, dir);
                    if (Directory.Exists(path)) Directory.Delete(path, true);
                    if (File.Exists(path + ".meta")) File.Delete(path + ".meta");
                }

                // Remove package manifests so they don't clutter the project
                string[] redundantFiles = { "package.json", "package.json.meta", "package-dist.json", "package-dist.json.meta" };
                foreach (string file in redundantFiles)
                {
                    string path = Path.Combine(targetFolder, file);
                    if (File.Exists(path)) File.Delete(path);
                }
            }
            catch (IOException e)
            {
                throw new LibraryInstallationException("Failed to clean up redundant files after extraction.", e);
            }
            catch (UnauthorizedAccessException e)
            {
                throw new LibraryInstallationException("Access denied during cleanup of extracted files.", e);
            }
        }

        [Serializable]
        private class DistributionMetadata
        {
            public string version;
            public string tag;
            public string downloadUrl;
        }
    }
}