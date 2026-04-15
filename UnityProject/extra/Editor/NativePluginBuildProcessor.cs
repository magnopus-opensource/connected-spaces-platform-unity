/*
 * Copyright 2025 Magnopus LLC

 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#if UNITY_EDITOR

using System.IO;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;

public class NativePluginBuildProcessor : IPreprocessBuildWithReport
{
    public int callbackOrder => 0;

    public void OnPreprocessBuild(BuildReport report)
    {
        Debug.Log($"NativePluginBuildProcessor: Filtering CSP binaries for platform {report.summary.platform}.");

        var importers = PluginImporter.GetImporters(report.summary.platform);

        foreach (var importer in importers)
        {
            if (!importer.isNativePlugin || !importer.assetPath.Contains("ConnectedSpacesPlatform"))
                continue;

            ConfigureInclude(report, importer);
        }

        Debug.Log($"NativePluginBuildProcessor: Done {report.summary.platform}.");
    }

    private static void ConfigureInclude(BuildReport report, PluginImporter importer)
    {
        var platform = report.summary.platform;
        var options = report.summary.options;
        var assetPath = importer.assetPath;
        var extension = Path.GetExtension(assetPath);

        // --- 1. Named Flags for Platform Logic ---
        // Apple-based platforms often require special handling for static libraries (.a) 
        // and framework bundling.
        bool isApplePlatform = platform is BuildTarget.iOS or BuildTarget.StandaloneOSX or BuildTarget.VisionOS;
        
        // Specifically iOS and VisionOS use IL2CPP with static linking, which is 
        // prone to aggressive symbol stripping.
        bool requiresForceLoadLinkerFlag = platform is BuildTarget.iOS or BuildTarget.VisionOS;

        bool isDevelopmentBuild = options.HasFlag(BuildOptions.Development);
        bool isDebugBinary = assetPath.EndsWith($"_D{extension}");

        // --- 2. Binary Selection Logic ---
        
        if (isApplePlatform)
        {
            if (platform == BuildTarget.VisionOS)
            {
                // Explicitly check if the user is building for the Vision Pro or the Simulator
                bool isSimulatorBuild = PlayerSettings.VisionOS.targetSDK == UnityEditor.VisionOS.VisionOSSdk.Simulator;
                bool isSimulatorPlugin = assetPath.Contains("Simulator");
                
                // Only include the plugin if the SDK target perfectly matches the folder it came from
                importer.SetIncludeInBuildDelegate((_) => isSimulatorBuild == isSimulatorPlugin);
            }
            else
            {
                // TODO: Remove this hack that always includes iOS and macOS binaries.
                // This exists because we currently only provide release binaries for these platforms 
                // to keep the SDK package size manageable.
                importer.SetIncludeInBuildDelegate((_) => true);
            }
        }
        else
        {
            // For other platforms (Android/Windows), we swap between the Release and 
            // Debug (_D) versions of the plugin based on the Unity Build Settings.
            bool shouldInclude = isDevelopmentBuild == isDebugBinary;
            importer.SetIncludeInBuildDelegate((_) => shouldInclude);
        }

        // --- 3. Linker Configuration ---
        
        if (requiresForceLoadLinkerFlag)
        {
            ApplyAppleLinkerFix();
        }
    }

    /// <summary>
    /// Adds specific linker arguments to the IL2CPP build pipeline.
    /// 
    /// WHY THIS IS NECESSARY:
    /// On iOS and VisionOS, the native linker (ld) performs dead-code stripping. 
    /// Because our C# code interfaces with the 'ConnectedSpacesPlatform' library via P/Invoke, 
    /// the linker often fails to see these "soft" references. It assumes the static library 
    /// is unused and strips its symbols, leading to "Entry point not found" crashes at runtime.
    /// 
    /// The '-force_load' flag tells the linker to include every object file in the 
    /// specified archive, regardless of whether it thinks symbols are being used.
    /// </summary>
    private static void ApplyAppleLinkerFix()
    {
        const string linkerArg = "--linker-flags=\"-Wl,-force_load,libConnectedSpacesPlatform.a\"";
        PlayerSettings.SetAdditionalIl2CppArgs(linkerArg);
    }
}

#endif