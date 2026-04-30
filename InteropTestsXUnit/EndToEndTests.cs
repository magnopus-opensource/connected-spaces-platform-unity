namespace InteropTestsXUnit;

using csp;
using csp.common;
using csp.multiplayer;
using csp.systems;
using System.Diagnostics;
using System.Threading.Tasks;

public class EndToEndTests : IDisposable
{

    /*
     * Tests that run against live services, require an internet connection and to
     * be able to reach CHS (ie, on the VPN).
     * I don't recommend running these as part of a regular test loop,
     * they were added as acceptance tests near the end of initial delivery of the
     * C# interop layer, to gain some confidence that it's fit for purpose inside magnopus teams.
     * They're not really testing the interop layer as such, and are going to be slow and fragile.
     */

    public EndToEndTests()
    {
        // Every test here initializes CSP.

        ClientUserAgent userAgent = new ClientUserAgent();
        userAgent.CSPVersion = "Unknown";
        userAgent.ClientOS = "Unknown";
        userAgent.ClientSKU = "CSharp-Interop";
        userAgent.ClientVersion = "Unknown";
        userAgent.ClientEnvironment = "ODev";
        userAgent.CHSEnvironment = "oDev";
        bool result = CSPFoundation.Initialise("https://ogs-internal.magnopus-dev.cloud", "OKO_TESTS", userAgent, null);
        Assert.True(result);
    }

    public void Dispose()
    {
        // Every test shuts down CSP when it's done

        bool result = CSPFoundation.Shutdown();
        Assert.True(result);
    }

    const string TEST_ACCOUNT_PASSWORD = "3R{d2}3C<x[J7=jU";

    private async Task<Profile> MakeTestUser()
    {
        UserSystem userSystem = SystemsManager.Get().GetUserSystem();
        string GUID = Guid.NewGuid().ToString();
        string uniqueEmail = $"testnopus.pokemon+{GUID}@magnopus.com";

        ProfileResult createUserResult = await userSystem.CreateUserAsync("DisplayName", uniqueEmail, TEST_ACCOUNT_PASSWORD, false, true, null, null);
        Profile prof = createUserResult.GetProfile();
        return prof;
    }

    private async Task<Space> MakeTestSpace()
    {
        SpaceSystem spaceSystem = SystemsManager.Get().GetSpaceSystem();
        string spaceID = Guid.NewGuid().ToString();
        csp.common.StringDict metaData = new csp.common.StringDict();
        SpaceResult createSpaceResult = await spaceSystem.CreateSpaceAsync(spaceID, "Test CSharp space description", SpaceAttributes.Public, null, metaData, null, null);
        Assert.Equal(EResultCode.Success, createSpaceResult.GetResultCode());

        return createSpaceResult.GetSpace();
    }

    /* Footgun alert. Unlike the callbacks awaitable methods use, registerable callbacks do need
     * to be kept alive somehow. */
    static ConnectedSpacesPlatformDotNet.EntityFetchCompleteCallback ENTITY_FETCH_CB = new((entitiesFetched) =>
    {
        Debug.WriteLine($"Fetched {entitiesFetched} entities");
    });

    private async Task<SpaceResult> EnterSpace(Space space, OnlineRealtimeEngine realtimeEngine)
    {
        SpaceSystem spaceSystem = SystemsManager.Get().GetSpaceSystem();

        realtimeEngine.SetEntityFetchCompleteCallback(ENTITY_FETCH_CB);

        SpaceResult enterSpaceResult = await spaceSystem.EnterSpaceAsync(space.Id, realtimeEngine);
        Assert.Equal(EResultCode.Success, enterSpaceResult.GetResultCode());
        return enterSpaceResult;
    }

    private async Task ExitAndDeleteSpace(Space space)
    {
        SpaceSystem spaceSystem = SystemsManager.Get().GetSpaceSystem();
        NullResult exitSpaceResult = await spaceSystem.ExitSpaceAsync();
        Assert.Equal(EResultCode.Success, exitSpaceResult.GetResultCode());
        NullResult deleteSpaceResult = await spaceSystem.DeleteSpaceAsync(space.Id);
        Assert.Equal(EResultCode.Success, deleteSpaceResult.GetResultCode());
    }

    [EnvironmentFact("RUN_LIVE_SERVICE_TESTS")]
    public async Task MakeAndEnterSpace()
    {
        // Login with temp user
        Profile testUser = await MakeTestUser();
        UserSystem userSystem = SystemsManager.Get().GetUserSystem();
        await userSystem.LoginAsync(testUser.Email, TEST_ACCOUNT_PASSWORD, true, true, null);
        Assert.Equal(csp.common.ELoginState.LoggedIn, userSystem.GetLoginState().State);

        Space space = await MakeTestSpace();

        using OnlineRealtimeEngine realtimeEngine = new OnlineRealtimeEngine(
           SystemsManager.Get().GetMultiplayerConnection(),
           SystemsManager.Get().GetLogSystem(),
           SystemsManager.Get().GetEventBus(),
           SystemsManager.Get().GetScriptSystem());

        await EnterSpace(space, realtimeEngine);

        await ExitAndDeleteSpace(space);
    }

    [EnvironmentFact("RUN_LIVE_SERVICE_TESTS")]
    public async Task MakeAssetCollection()
    {
        // Login with temp user
        Profile testUser = await MakeTestUser();
        UserSystem userSystem = SystemsManager.Get().GetUserSystem();
        await userSystem.LoginAsync(testUser.Email, TEST_ACCOUNT_PASSWORD, true, true, null);
        Assert.Equal(csp.common.ELoginState.LoggedIn, userSystem.GetLoginState().State);

        /* A little nervous this test may suffer from determinism issues due to distributed effects.
         * Just because you get a response dosen't necessarily mean it's in the DB caching layer, but i'm not
         * sure if those concerns always apply. Not sure what else to do other than add speculative
         * sleeps. It's working fine currently. */

        // Make an asset collection
        string assetCollectionName = $"TestCSharpAssetCollection{Guid.NewGuid()}";
        AssetSystem assetSystem = SystemsManager.Get().GetAssetSystem();
        AssetCollectionResult createAssetCollectionResult = await assetSystem.CreateAssetCollectionAsync(null, null, assetCollectionName, null, EAssetCollectionType.DEFAULT, null);
        Assert.Equal(EResultCode.Success, createAssetCollectionResult.GetResultCode());

        // Create an asset
        string assetName = $"TestCSharpAsset{Guid.NewGuid()}";
        AssetResult createAssetResult = await assetSystem.CreateAssetAsync(createAssetCollectionResult.GetAssetCollection(), assetName, null, EThirdPartyPlatform.Unity, EAssetType.IMAGE);
        Assert.Equal(EResultCode.Success, createAssetResult.GetResultCode());

        // Destroy an asset
        NullResult deleteAssetResult = await assetSystem.DeleteAssetAsync(createAssetCollectionResult.GetAssetCollection(), createAssetResult.GetAsset());
        Assert.Equal(EResultCode.Success, deleteAssetResult.GetResultCode());

        // Destroy an asset collection
        NullResult deleteAssetCollectionResult = await assetSystem.DeleteAssetCollectionAsync(createAssetCollectionResult.GetAssetCollection());
        Assert.Equal(EResultCode.Success, deleteAssetCollectionResult.GetResultCode());
    }

    [EnvironmentFact("RUN_LIVE_SERVICE_TESTS")]
    public async Task SendAndRecieveNetworkMessage()
    {

        // Login with temp user
        Profile testUser = await MakeTestUser();
        UserSystem userSystem = SystemsManager.Get().GetUserSystem();
        await userSystem.LoginAsync(testUser.Email, TEST_ACCOUNT_PASSWORD, true, true, null);
        Assert.Equal(csp.common.ELoginState.LoggedIn, userSystem.GetLoginState().State);

        //Allow self messaging for this test
        MultiplayerConnection multiplayerConnection = SystemsManager.Get().GetMultiplayerConnection();
        ErrorCode selfMessagingErrorCode = await multiplayerConnection.SetAllowSelfMessagingFlagAsync(true);
        Assert.Equal(ErrorCode.None, selfMessagingErrorCode);

        NetworkEventBus eventBus = SystemsManager.Get().GetEventBus();

        /* Enter space scope
         * I think this is poor design, or something that's broken. You need to be in a scope
         * To get messaging, the only way currently to be in a scope is to enter the scope of a space.
         * CSP cheats a bit when testing this, using an internal `SetScopes` method. Bad. */
        Space space = await MakeTestSpace();

        using OnlineRealtimeEngine realtimeEngine = new OnlineRealtimeEngine(
           SystemsManager.Get().GetMultiplayerConnection(),
           SystemsManager.Get().GetLogSystem(),
           SystemsManager.Get().GetEventBus(),
           SystemsManager.Get().GetScriptSystem());

        await EnterSpace(space, realtimeEngine);

        //Start Listening
        TaskCompletionSource<NetworkEventData> networkEventDataTCS = new TaskCompletionSource<NetworkEventData>(TaskCreationOptions.RunContinuationsAsynchronously);
        ConnectedSpacesPlatformDotNet.NetworkEventCallback networkEventCallback = new ConnectedSpacesPlatformDotNet.NetworkEventCallback((x) =>
        {
            networkEventDataTCS.SetResult(x); ;
        });

        const string NETWORK_EVENT_ID = "CSharpTestNetworkEvent";
        eventBus.ListenNetworkEvent(new NetworkEventRegistration("me", NETWORK_EVENT_ID), networkEventCallback);

        //Send a message to ourselves
        const string MESSAGE_PAYLOAD = "Test message";
        ReplicatedValueArray payload = new ReplicatedValueArray(1);
        payload[0] = new ReplicatedValue(MESSAGE_PAYLOAD);
        ErrorCode sendEventErrorCode = await eventBus.SendNetworkEventToClientAsync(NETWORK_EVENT_ID, payload, SystemsManager.Get().GetMultiplayerConnection().GetClientId());
        Assert.Equal(ErrorCode.None, sendEventErrorCode);

        //Wait for the message
        NetworkEventData messageData = await networkEventDataTCS.Task;
        ReplicatedValue val = messageData.EventValues[0];
        var valType = val.GetReplicatedValueType();
        string valStr = val.GetString();
        Assert.Equal(ReplicatedValueType.String, valType);
        Assert.Equal(MESSAGE_PAYLOAD, valStr);

        //Cleanup
        ErrorCode selfMessagingDisableErrorCode = await SystemsManager.Get().GetMultiplayerConnection().SetAllowSelfMessagingFlagAsync(false);
        Assert.Equal(ErrorCode.None, selfMessagingDisableErrorCode);
        await ExitAndDeleteSpace(space);
    }

}