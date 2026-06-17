using System;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
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
            public LibraryInstallationException(string message) : base(message)
            {
            }

            public LibraryInstallationException(string message, Exception innerException) : base(message, innerException)
            {
            }
        }

        static CSPBinaryDownloader()
        {
            if (Application.isBatchMode)
            {
                Debug.Log("[CSP-CI] Batch mode detected on startup. Checking for binaries...");
                
                try
                {
                    // Run the dedicated synchronous CI pipeline
                    RunCIWorkflow();
                    Debug.Log("[CSP-CI] CI Initialization complete. Proceeding with batch tasks...");
                }
                catch (Exception e)
                {
                    Debug.LogError($"[CSP-CI] FATAL ERROR during CI binary download: {e}");
                    EditorApplication.Exit(1); 
                }
            }
            else
            {
                // Safely fire-and-forget in the background without freezing the UI.
                EditorApplication.delayCall += () => _ = RunEditorWorkflowAsync(false);
            }
        }

        [MenuItem(MenuPath)]
        public static async void ManualDownloadTrigger()
        {
            try
            {
                await RunEditorWorkflowAsync(true);
            }
            catch (Exception ex)
            {
                Debug.LogError($"[CSP] Manual binary download failed: {ex.Message}\n{ex.StackTrace}");
                UnityEditor.EditorUtility.DisplayDialog(
                    "CSP Binary Download Failed", 
                    $"An error occurred while downloading or extracting the native binaries.\n\n{ex.Message}\n\nCheck the Unity Console for more details.", 
                    "OK"
                );
            }
        }

        // --- DEDICATED CI PIPELINE (Deadlock Free) ---
        private static void RunCIWorkflow()
        {
            string packagePath = Path.GetFullPath($"Packages/{PackageName}");
            var packageInfo = UnityEditor.PackageManager.PackageInfo.FindForAssetPath($"Packages/{PackageName}");
            
            if (packageInfo != null)
            {
                packagePath = packageInfo.resolvedPath; 
            }

            string metadataPath = Path.Combine(packagePath, "package-dist.json");
        
            // Target: Assets/Plugins/CSP/Internal (Unity has write access here)
            string localPluginsPath = Path.Combine(Application.dataPath, "Plugins/CSP/Internal");

            if (!File.Exists(metadataPath))
            {
                throw new LibraryInstallationException($"Metadata missing at {metadataPath}");
            }

            DistributionMetadata data = ReadMetadata(metadataPath);
            string targetVersionFile = Path.Combine(localPluginsPath, $".version-{data.version}");
            
            if (!Directory.Exists(localPluginsPath) || !File.Exists(targetVersionFile))
            {
                Debug.Log($"[CSP-CI] Missing binaries (Target: {data.version}). Starting download...");
                string tempDownloadPath = Path.Combine(Application.temporaryCachePath, "csp_binaries.tgz");

                try
                {
                    // Isolate ONLY the HTTP network stream to a background thread to prevent Unity API deadlocks
                    Task.Run(async () =>
                    {
                        using (HttpClient client = new HttpClient())
                        {
                            // Disable the default 100-second timeout for large artifact downloads
                            client.Timeout = System.Threading.Timeout.InfiniteTimeSpan;

                            using (HttpResponseMessage response = await client.GetAsync(data.downloadUrl, HttpCompletionOption.ResponseHeadersRead))
                            {
                                response.EnsureSuccessStatusCode();
                                
                                using (Stream contentStream = await response.Content.ReadAsStreamAsync())
                                {
                                    using (Stream fileStream = new FileStream(tempDownloadPath, FileMode.Create, FileAccess.Write, FileShare.None, 8192, true))
                                    {
                                        await contentStream.CopyToAsync(fileStream);
                                    }
                                }
                            }
                        }
                    }).GetAwaiter().GetResult();

                    Debug.Log("[CSP-CI] Download complete. Processing...");
                    
                    // Back on the Main Thread safely: Extract and call Unity APIs
                    ExtractTarball(tempDownloadPath, localPluginsPath);
                    CleanupRedundantFiles(localPluginsPath);
                    File.Create(targetVersionFile).Dispose();

                    AssetDatabase.Refresh();
                    Debug.Log($"[CSP-CI] Successfully installed native binaries version: {data.version}");
                }
                finally
                {
                    // Ensure cleanup happens on all success and failure paths
                    if (File.Exists(tempDownloadPath))
                    {
                        try
                        {
                            File.Delete(tempDownloadPath);
                        }
                        catch
                        {
                            // Ignore cleanup errors to prevent masking the original exception
                        }
                    }
                }
            }
        }

        // --- DEDICATED EDITOR PIPELINE (UI Responsive) ---
        private static async Task RunEditorWorkflowAsync(bool forceManual)
        {
            string packagePath = Path.GetFullPath($"Packages/{PackageName}");
            var packageInfo = UnityEditor.PackageManager.PackageInfo.FindForAssetPath($"Packages/{PackageName}");
            
            if (packageInfo != null)
            {
                packagePath = packageInfo.resolvedPath; 
            }

            string metadataPath = Path.Combine(packagePath, "package-dist.json");
            string localPluginsPath = Path.Combine(Application.dataPath, "Plugins/CSP/Internal");

            if (!File.Exists(metadataPath))
            {
                if (forceManual)
                {
                    Debug.LogError($"Metadata not found at {metadataPath}. Ensure package is installed.");
                }

                return;
            }

            DistributionMetadata data = ReadMetadata(metadataPath);

            // Check if the folder exists and if the specific target version marker exists
            string targetVersionFile = Path.Combine(localPluginsPath, $".version-{data.version}");
            
            bool needsDownload = !Directory.Exists(localPluginsPath) || !File.Exists(targetVersionFile) || forceManual;

            if (needsDownload)
            {
                bool proceed = true;

                if (forceManual)
                {
                    proceed = EditorUtility.DisplayDialog(
                        "Download CSP Binaries",
                        $"Force download native binaries ({data.version})?\n\nThis will download approx 780MB from GitHub.",
                        "Download",
                        "Cancel");
                }
                else
                {
                    Debug.Log($"[CSP] Outdated or missing binaries detected (Target: {data.version}). Starting download...");
                }

                if (proceed)
                {
                    string tempDownloadPath = Path.Combine(Application.temporaryCachePath, "csp_binaries.tgz");
                    
                    using (UnityWebRequest www = UnityWebRequest.Get(data.downloadUrl))
                    {
                        www.downloadHandler = new DownloadHandlerFile(tempDownloadPath);
                        var operation = www.SendWebRequest();

                        try
                        {
                            while (!operation.isDone)
                            {
                                bool isCanceled = EditorUtility.DisplayCancelableProgressBar(
                                    "Downloading CSP Binaries", 
                                    $"Fetching assets... {Mathf.RoundToInt(www.downloadProgress * 100)}%", 
                                    www.downloadProgress);

                                if (isCanceled)
                                {
                                    www.Abort(); 
                                    Debug.LogWarning("[CSP] Binary download canceled by user.");
                                    return; 
                                }
                                
                                await Task.Delay(100);
                            }

                            EditorUtility.ClearProgressBar();

                            if (www.result == UnityWebRequest.Result.Success)
                            {
                                ExtractTarball(tempDownloadPath, localPluginsPath);
                                CleanupRedundantFiles(localPluginsPath);
                                File.Create(targetVersionFile).Dispose();

                                AssetDatabase.Refresh();
                                Debug.Log($"[CSP] Successfully installed native binaries version: {data.version}");
                                
                                if (forceManual)
                                {
                                    EditorUtility.DisplayDialog("Success", $"CSP Binaries ({data.version}) successfully installed.", "OK");
                                }
                            }
                            else
                            {
                                Debug.LogError($"[CSP] Network error: {www.error}");
                                EditorUtility.DisplayDialog("Download Failed", www.error, "OK");
                            }
                        }
                        catch (Exception e)
                        {
                            Debug.LogException(e);
                        }
                        finally
                        {
                            EditorUtility.ClearProgressBar();
                            
                            if (File.Exists(tempDownloadPath)) 
                            {
                                try
                                {
                                    File.Delete(tempDownloadPath);
                                }
                                catch
                                {
                                    // Ignore cleanup errors
                                }
                            }
                        }
                    }
                }
            }
        }

        private static DistributionMetadata ReadMetadata(string path)
        {
            string json = File.ReadAllText(path);
            var data = JsonUtility.FromJson<DistributionMetadata>(json);

            if (data == null || string.IsNullOrEmpty(data.downloadUrl))
            {
                throw new LibraryInstallationException("downloadUrl is empty in package-dist.json");
            }

            return data;
        }

        private static void ExtractTarball(string archivePath, string targetFolder)
        {
            if (!Directory.Exists(targetFolder))
            {
                Directory.CreateDirectory(targetFolder);
            }

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
                    if (process == null)
                    {
                        throw new LibraryInstallationException("Failed to initialize tar process.");
                    }
                    
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

                    if (Directory.Exists(path)) 
                    {
                        Directory.Delete(path, true);
                    }

                    if (File.Exists(path + ".meta")) 
                    {
                        File.Delete(path + ".meta");
                    }
                }

                string[] redundantFiles = { "package.json", "package.json.meta", "package-dist.json", "package-dist.json.meta" };

                foreach (string file in redundantFiles)
                {
                    string path = Path.Combine(targetFolder, file);

                    if (File.Exists(path))
                    { 
                        File.Delete(path);
                    }
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