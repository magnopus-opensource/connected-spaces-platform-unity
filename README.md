A SWIG based interop surface to the [connected spaces platform](https://github.com/magnopus-opensource/connected-spaces-platform) library. Designed for off-the-shelf use in .NET applications as well as Unity based applications.

## Getting Started

As this is an interop surface for the connected-spaces-platform, you'll want to primarily reference the documentation [there](https://connected-spaces-platform.net/), most API's are a 1:1 mapping. You may also with to reference the getting started [tutorials](https://connected-spaces-platform.net/manual/tutorials/cplusplus.html), what is written here is mostly just a subset of that.

Download and link the compiled binaries as you normally would, the specifics of this will depend on your platform. Add the `include` directory containing the `.cs` files. You can reference the `.csproj` in [InteropTestsXUnit](./InteropTestsXUnit/) for an example of this.

>[!NOTE]
>
> If you are linking dynamically, you need to make sure both dynamic libraries `ConnectedSpacesPlatformDotNet` and `ConnectedSpacesPlatform` are loadable by your application. The former depends on the latter.

For a more full explanation of internal workings, consult the [Implementor Guide](./Doc/Implementor-Guide.md)

Before you begin, you will need a Magnopus Cloud Services tenant. You can create one automatically via this [form](https://ogs.magnopus-stg.cloud/mag-user/tenants/CreateTenant). You will have to verify this via email before you can continue.

Once you have one, go ahead and Initialize CSP.

```csharp
ClientUserAgent userAgent = new ClientUserAgent();
userAgent.CSPVersion = csp.CSPFoundation.GetVersion();;
userAgent.ClientOS = "<my_operating_system>";
userAgent.ClientSKU = "<my_project_identifier>";
userAgent.ClientVersion = "<my_project_version>";

//Don't worry about the `null` argument, that's just a slot for Feature Flags.
bool result = CSPFoundation.Initialise("https://ogs.magnopus-stg.cloud", "<my_tenant>", userAgent, null);
```

Don't worry too much about the specific values you set in `ClientUserAgent`, they can be somewhat arbitrary.

Once Initialized, let's go ahead and create a user
```csharp
UserSystem userSystem = SystemsManager.Get().GetUserSystem();
csp.systems.ProfileResult newUser = await userSystem.CreateUserAsync("<my_username>", "<my_displayname>", "<my_email>", "<my_password>", false, true, null, null);
Debug.Assert(newUser.GetResultCode() == EResultCode.Success);
```

You may receive and email at this point to confirm the new user. Go ahead and accept. Remember that if you run this code more than once, creating a user of the same email will fail if it already exists. In fact, if you are using the same email that you created the tenant with, you may find a user already made for you, in which case you can skip this step.

Then, let's login.

```csharp
await userSystem.LoginAsync("", "<my_email>", "<my_password>", true, true, new csp.systems.TokenOptions());

// Check that we're logged in.
Debug.Assert(userSystem.GetLoginState().State == csp.common.ELoginState.LoggedIn);
```

Once logged in, you should be able to create a space using the `SpaceSystem`

```csharp
SpaceSystem spaceSystem = SystemsManager.Get().GetSpaceSystem();

csp.common.StringDict metaData = new csp.common.StringDict();
SpaceResult createSpaceResult = await spaceSystem.CreateSpaceAsync("<my_space_name>", "<my_space_description>", SpaceAttributes.Public, null, metaData, null, null);

//Did the space create successfully?
Debug.Assert(createSpaceResult.GetResultCode() == EResultCode.Success);
```

And then enter it. 

```csharp
ConnectedSpacesPlatformDotNet.EntityFetchCompleteCallback ENTITY_FETCH_CB = new ConnectedSpacesPlatformDotNet.EntityFetchCompleteCallback((entitiesFetched) =>
  {
      Debug.WriteLine($"Fetched {entitiesFetched} entities upon space entry.");
  });

using OnlineRealtimeEngine realtimeEngine = new OnlineRealtimeEngine(
   SystemsManager.Get().GetMultiplayerConnection(),
   SystemsManager.Get().GetLogSystem(),
   SystemsManager.Get().GetEventBus(),
   SystemsManager.Get().GetScriptSystem());

realtimeEngine.SetEntityFetchCompleteCallback(ENTITY_FETCH_CB);

SpaceResult enterSpaceResult = await spaceSystem.EnterSpaceAsync(createSpaceResult.GetSpace().Id, realtimeEngine);

Debug.Assert(enterSpaceResult.GetResultCode() == EResultCode.Success);
```

To enter spaces, you need to create a RealtimeEngine which drives the connection. We're trying to enter an online space, so we make an `OnlineRealtimeEngine`

> [!TIP]
>
> Don't let the realtime engine be garbage collected whilst you are in a space. You are free to allow it to be cleaned up once you have finished exiting a space. The same goes for any registerable callbacks, such as `ENTITY_FETCH_CB` above. You can consider making these static to simplify things.

You're now in a space, you can use the `RealtimeEngine` to query entities and their components, the `SpaceSystem` to interact with the space in general, and the other systems to do ... other things! This is where this quick start guide leaves you. Try to leave and delete the space all on your own.

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
> [!IMPORTANT]
> When building the libraries for usage in Unity on macOS, it is necessary to set the cmake variable CMAKE_OSX_ARCHITECTURES to "arm64", or the linking will fail.

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
- [Github CLI](https://cli.github.com/): You must have the github command line tools installed and activated in order to discover and download a specific CSP release version.
- (For Android) [Android NDK](https://developer.android.com/ndk/downloads): Tested with specific version `29.0.14206865`, but most should work.  

### Relevant CMake Variables

| Var | Type | Description                                                                                                                                                                                                                                                     |
|----------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `BUILD_SHARED_LIBS`| Boolean | Whether to produce shared .dlls/.dylibs/.so's, or static .lib/.a's.                                                                                                                                                                                             |
| `GUARD_CSP_NO_EXPORTS` | Boolean | Whether to #ifndef guard the NO_EXPORT sections of CSP headers when consuming a release.                                                                                                                                                                                 |
| `COPY_OUTPUT_TO_UNITY_TEST_PROJECT` | Boolean | Whether to copy the latest generated classes and libraries to the Unity test project.                                                                                                                                                                           |
| `ENABLE_UNITY_EXTENSIONS` | Boolean | Whether to generate additional type conversions to and from common UnityEngine types.                                                                                                                                                                           |
| `ENABLE_THROW_EXCEPTION_ON_RESULTBASE_FAILURE` | Boolean | Whether to generate code for throwing an exception automatically whenever a callback returns a ResultBase object with failure status code. This is enabled by default.                                                                                                                                                                           |
| `CMAKE_BUILD_TYPE` | "Debug" or "Release" | What type of build to produce.                                                                                                                                                                                                                                  |
| `INSTALL_DIR`| Path | Where the `install` command places the final package. Defaults to `./install`                                                                                                                                                                                   |
| `ROOT_I_DIR`| Path | Directory where the root `.i` SWIG interface file can be found. Defaults to `./interface`. The root `.i` file should be called `main.i`                                                                                                                         |
| `CSP_ROOT_DIR` | Path | Path to the root directory of a CSP release. Include directories are used in SWIG `.i` files, and provided binaries are linked against. This is normally downloaded automatically, and will be set by default to `BUILD_FOLDER/_deps/connected-spaces-platform` |
| `SWIG_EXE`| Path | Path to the directory containing the swig executable that is used to generate .cpp and .cs code. This is normally downloaded automatically, and will be set by default to `BUILD_FOLDER/_deps/swig-il2cpp-directors/bin/swig`                                   |
| `CSP_TARGET_VERSION`| String | Git tag representing the CSP release version targeted by the SWIG build.                                                                                                                                     |
| `CSP_LIB_UNITY_DIR`| Path | Path to Unity CSP plugin directory where the CSP generated code and libs from SWIG will be copied to, if desired.                                                                                                                                               |
| `CSP_ASMDEF_PATH`| Path | Path to ConnectedSpacesPlatform Unity .asmdef file, which will be used in Unity to handle the dependency over the CSP code.                                                                                                                                     |
| `LEGACY_BUILD_SYSTEM`| Boolean | If true, will use the legacy CSP build (premake). False will use the new (currently in progress, so may have some rough patches) cmake based CSP build system.                                                                                                                                      |