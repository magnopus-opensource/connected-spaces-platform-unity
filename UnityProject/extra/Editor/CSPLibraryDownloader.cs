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
                    if (forceManual) Debug.LogError($"[MAGNOPUS] Metadata not found at {metadataPath}. Ensure package is installed via Git.");
                    return;
                }

                string json = File.ReadAllText(metadataPath);
                var data = JsonUtility.FromJson<DistributionMetadata>(json);

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

        private static void StartEditorDownload(string url, string targetPath)
        {
            UnityWebRequest www = UnityWebRequest.Get(url);
            www.SendWebRequest();

            // Standard Editor Update loop to handle the download without blocking the UI
            EditorApplication.CallbackFunction updateAction = null;
            updateAction = () =>
            {
                if (www == null) 
                {
                    EditorApplication.update -= updateAction;
                    return;
                }

                if (!www.isDone)
                {
                    EditorUtility.DisplayProgressBar("Downloading CSP", $"Fetching binaries... {Mathf.RoundToInt(www.downloadProgress * 100)}%", www.downloadProgress);
                    return;
                }

                // Cleanup
                EditorUtility.ClearProgressBar();
                EditorApplication.update -= updateAction;

                if (www.result == UnityWebRequest.Result.Success)
                {
                    ProcessDownload(www.downloadHandler.data, targetPath);
                }
                else
                {
                    EditorUtility.DisplayDialog("Download Failed", $"Error: {www.error}", "OK");
                }
            
                www.Dispose();
            };

            EditorApplication.update += updateAction;
        }

        private static void ProcessDownload(byte[] data, string targetFolder)
        {
            try 
            {
                if (!Directory.Exists(targetFolder)) Directory.CreateDirectory(targetFolder);
            
                string tempPath = Path.Combine(Application.temporaryCachePath, "csp_binaries.tgz");
                File.WriteAllBytes(tempPath, data);

                Debug.Log($"[MAGNOPUS] Extracting to {targetFolder}...");
            
                // Uses system 'tar' (Available on Win 10+, macOS, Linux)
                System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = "tar",
                    Arguments = $"-xf \"{tempPath}\" -C \"{targetFolder}\"",
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var process = System.Diagnostics.Process.Start(startInfo))
                {
                    process.WaitForExit();
                }

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

                File.Delete(tempPath);
                AssetDatabase.Refresh();
                EditorUtility.DisplayDialog("Success", "CSP Binaries installed in Assets/Plugins/CSP/Internal.", "OK");
            }
            catch (Exception e)
            {
                Debug.LogError($"[MAGNOPUS] Extraction failed: {e.Message}");
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