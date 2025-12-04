> [!IMPORTANT]  
> 👷Under construction. Check back in a few months :D

## Building

To build, run the a standard configure/build/install CMake triplet from the root directory.

```bash
cmake -S . -B build
cmake --build build --config Debug
cmake --install build --config Debug
```

Building on Android/iOS is a little more involved, you can see specific invocations in the actions files. ([Desktop](https://github.com/MAG-ElliotMorris/connected-spaces-platform-unity/blob/main/.github/workflows/build-desktop.yml), [Android](https://github.com/MAG-ElliotMorris/connected-spaces-platform-unity/blob/main/.github/workflows/build-android.yml), [iOS](https://github.com/MAG-ElliotMorris/connected-spaces-platform-unity/blob/main/.github/workflows/build-ios.yml))

This should produce you an `install` directory with `bin`, `lib` and `include`subdirectories (dependent on platform).

### Installing to Unity
To use the install output in unity, copy the files like so:
- The contents of the `include` directory -> `Assets/Csp/Runtime/`
- Copy both binary files (`ConnectedSpacesPlatform` and `ConnectedSpacesPlatformDotNet`) to the platform specific folder under `Assets/Plugins`
    - Windows: `Assets/Plugins/x86_64`
    - iOS : `Assets/Plugins/iOS`
    - Android: `Assets/Plugins/Android/arm64-v8a`
    - MacOS: `Assets/Plugins/macOS`

### Running tests into Unity test project
- Enable the cmake variable ENABLE_UNITY_EXTENSIONS to let cmake install the generated binaries, libraries and code into the Unity test project.
- Run cmake with the required configuration for your target platform (e.g. Android, iOS, Windows, MacOS).
- Once the binaries, libraries and generated C# files are in place, make sure that he CspUnityTests.asmdef file has a dependency on ConnectedSpacesPlatform.Unity.Core.asmdef, so that the Unity tests can build and run successfully.
- To run the tests in Unity, go to Window -> General -> Test Runner, and run the tests from the PlayMode tab.

### Dependencies
- [CMake](https://cmake.org/): Version 3.28 or greater 
- [Github CLI](https://cli.github.com/): You must have the github command line tools installed and activated in order to discover and download the latest CSP release.
- (For Android) [Android NDK](https://developer.android.com/ndk/downloads): Tested with specific version `29.0.14206865`, but most should work.  

### Relevant CMake Variables

| Var | Type | Description                                                                                                                                                                                                                                                     |
|----------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `BUILD_SHARED_LIBS`| Boolean | Whether to produce shared .dlls/.dylibs/.so's, or static .lib/.a's.                                                                                                                                                                                             |
| `TRIM_CSP_NO_EXPORTS` | Boolean | Whether to trim the NO_EXPORT sections of CSP headers when consuming a release.                                                                                                                                                                                 |
| `COPY_OUTPUT_TO_UNITY_TEST_PROJECT` | Boolean | Whether to copy the latest generated classes and libraries to the Unity test project.                                                                                                                                                                           |
| `ENABLE_UNITY_EXTENSIONS` | Boolean | Whether to generate additional type conversions to and from common UnityEngine types.                                                                                                                                                                           |
| `CMAKE_BUILD_TYPE` | "Debug" or "Release" | What type of build to produce.                                                                                                                                                                                                                                  |
| `INSTALL_DIR`| Path | Where the `install` command places the final package. Defaults to `./install`                                                                                                                                                                                   |
| `CSHARP_CSP_NAMESPACE`| String | What to call the namespace generated Csp code is namespaced under. Defaults to "Csp"                                                                                                                                                                            |
| `ROOT_I_DIR`| Path | Directory where the root `.i` SWIG interface file can be found. Defaults to `./interface`. The root `.i` file should be called `main.i`                                                                                                                         |
| `CSP_ROOT_DIR` | Path | Path to the root directory of a CSP release. Include directories are used in SWIG `.i` files, and provided binaries are linked against. This is normally downloaded automatically, and will be set by default to `BUILD_FOLDER/_deps/connected-spaces-platform` |
| `SWIG_EXE`| Path | Path to the directory containing the swig executable that is used to generate .cpp and .cs code. This is normally downloaded automatically, and will be set by default to `BUILD_FOLDER/_deps/swig-il2cpp-directors/bin/swig`                                   |
| `CSP_LIB_UNITY_DIR`| Path | Path to Unity CSP plugin directory where the CSP generated code and libs from SWIG will be copied to, if desired.                                                                                                                                               |
| `CSP_ASMDEF_PATH`| Path | Path to ConnectedSpacesPlatform Unity .asmdef file, which will be used in Unity to handle the dependency over the CSP code.                                                                                                                                     |
| `CMAKE_OSX_ARCHITECTURES`| String | Target architecture for macOS. This is a common footgun because of rosetta terminals or x86_64 cmake installs, you can use this to make it work in those contexts by setting "arm64".                                                                                                                                                       |
