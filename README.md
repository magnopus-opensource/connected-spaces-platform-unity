A SWIG based interop surface to the [connected spaces platform](https://github.com/magnopus-opensource/connected-spaces-platform) library. Designed for off-the-shelf use in .NET applications as well as Unity based applications.

## Getting Started

As this is an interop surface for the connected-spaces-platform, you'll want to primarily reference the documentation [there](https://connected-spaces-platform.net/): most API's are a 1:1 mapping. You may also with to reference the [Getting Started tutorials](https://connected-spaces-platform.net/manual/tutorials/cplusplus.html), which expand on the information in this document.

Download and link the compiled binaries, following the instructions specific to your platform. Add the `include` directory containing the `.cs` files. You can reference the `.csproj` in [InteropTestsXUnit](./InteropTestsXUnit/) for an example of this.

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

Don't worry too much about the specific values you set in `ClientUserAgent`; they can be somewhat arbitrary.

Once Initialized, let's go ahead and create a user:

```csharp
UserSystem userSystem = SystemsManager.Get().GetUserSystem();
csp.systems.ProfileResult newUser = await userSystem.CreateUserAsync("<my_username>", "<my_displayname>", "<my_email>", "<my_password>", false, true, null, null);
Debug.Assert(newUser.GetResultCode() == EResultCode.Success);
```

You may receive an email at this point to confirm the new user. Go ahead and accept. If you run this code more than once, creating a user with the same email address will fail since it already exists. In fact, if you are using the same email address that you created the tenant with, you may find a user already made for you, in which case you can skip this step.

Then, let's login.

```csharp
await userSystem.LoginAsync("", "<my_email>", "<my_password>", true, true, new csp.systems.TokenOptions());

// Check that we're logged in.
Debug.Assert(userSystem.GetLoginState().State == csp.common.ELoginState.LoggedIn);
```

Once logged in, you should be able to create a space using the `SpaceSystem`:

```csharp
SpaceSystem spaceSystem = SystemsManager.Get().GetSpaceSystem();

csp.common.StringDict metaData = new csp.common.StringDict();
SpaceResult createSpaceResult = await spaceSystem.CreateSpaceAsync("<my_space_name>", "<my_space_description>", SpaceAttributes.Public, null, metaData, null, null);

//Did the space create successfully?
Debug.Assert(createSpaceResult.GetResultCode() == EResultCode.Success);
```

And then enter it:

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

Build and installation instructions have been moved to [BUILD.md](./BUILD.md).