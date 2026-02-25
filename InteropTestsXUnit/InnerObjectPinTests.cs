namespace InteropTestsXUnit;

using csp;
using csp.common;
using csp.multiplayer;
using csp.systems;
using System;
using System.Runtime.CompilerServices;
using Xunit.Runner.Common;

public class InnerObjectPinTests
{
    /* Test the pinning behavior where inner objects pin their outer objects such that 
     * premature GC doesn't clobber underlying C++ memory.
     * There's a lot of utility methods here because returns are an easy way to get an inner object
     * out whilst making the outer object a candidate to GC.
     * We also clobber the C++ memory to try and make reproduction more likely, because this is UB
     * so nothing is guaranteed. */

    // The noinlining is just a prayer, since we're shouting into the memory void here.
    // Make a _lot_ of memory. This is also just a prayer. I needed to get a failing test.
    [MethodImpl(MethodImplOptions.NoInlining)]
    static void ClobberNativeHeap()
    {
        SpaceTransform[] clobber = new SpaceTransform[500000];
        for (int j = 0; j < clobber.Length; j++)
        {
            clobber[j] = new SpaceTransform();
        }
        for (int j = 0; j < clobber.Length; j++)
        {
            clobber[j].Dispose();
        }
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    static (Vector3, WeakReference) CreateComponentAndGetColor(LogSystem logSystem, SpaceEntity parent)
    {
        FogSpaceComponent fogComponent = new FogSpaceComponent(logSystem, parent);
        fogComponent.SetColor(new Vector3(5.0f, 6.0f, 7.0f));
        Vector3 color = fogComponent.GetColor();
        WeakReference weak = new WeakReference(fogComponent);
        return (color, weak);
    }

    [EnvironmentFact("RUN_LONG_RUNNING_TESTS")]
    public async Task InnerRefReturnDanglesAfterGCCollectsOwner()
    {
        using LogSystem logSystem = new LogSystem();
        using TempMockScriptRunner mockScriptRunner = new TempMockScriptRunner();
        using LogSystem engineLogSystem = new LogSystem();
        using OfflineRealtimeEngine realtimeEngine = new OfflineRealtimeEngine(engineLogSystem, mockScriptRunner);

        SpaceEntity parent = await realtimeEngine.CreateEntityAsync("TestEntity", new SpaceTransform(), null);

        Vector3 innerObject = null;
        WeakReference weakRef = null;

        // This tests takes some time as we're using components, which have a fair amount of heft inside them.
        for (int i = 0; i < 25; ++i)
        {
            GC.Collect(GC.MaxGeneration, GCCollectionMode.Forced, blocking: true);
            GC.WaitForPendingFinalizers();
            GC.Collect(GC.MaxGeneration, GCCollectionMode.Forced, blocking: true);

            ClobberNativeHeap();

            if (weakRef != null)
            {
                Assert.True(weakRef.IsAlive,
                    $"Iteration {i}: FogSpaceComponent was collected by GC, despite being pinned by its inner object");
            }

            if (innerObject != null)
            {
                // This shouldn't crash, and should be 5.
                // If the pinning functionality doesn't work, this will _probably_ be zero or garbage.
                Assert.Equal(5.0f, innerObject.X);
            }

            var result = CreateComponentAndGetColor(logSystem, parent);
            innerObject = result.Item1;
            weakRef = result.Item2;
        }
    }


    [MethodImpl(MethodImplOptions.NoInlining)]
    static (Vector3, WeakReference) CreateTransformAndGetPosition()
    {
        SpaceTransform transform = new SpaceTransform(
            new Vector3(5.0f, 6.0f, 7.0f),
            new Vector4(0.0f, 0.0f, 0.0f, 1.0f),
            new Vector3(1.0f, 1.0f, 1.0f));
        Vector3 position = transform.Position;
        WeakReference weak = new WeakReference(transform);
        return (position, weak);
    }

    [Fact]
    public void PropertyReturnDanglesAfterGCCollectsOwner()
    {
        Vector3 innerObject = null;
        WeakReference weakRef = null;

        for (int i = 0; i < 25; ++i)
        {
            GC.Collect(GC.MaxGeneration, GCCollectionMode.Forced, blocking: true);
            GC.WaitForPendingFinalizers();
            GC.Collect(GC.MaxGeneration, GCCollectionMode.Forced, blocking: true);

            ClobberNativeHeap();

            if (weakRef != null)
            {
                Assert.True(weakRef.IsAlive,
                    $"Iteration {i}: SpaceTransform was collected by GC, despite being pinned by its inner property");
            }

            if (innerObject != null)
            {
                // This shouldn't crash, and should be 5.
                // If the pinning functionality doesn't work, this will _probably_ be zero or garbage.
                Assert.Equal(5.0f, innerObject.X);
            }

            var result = CreateTransformAndGetPosition();
            innerObject = result.Item1;
            weakRef = result.Item2;
        }
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    static (Vector3, WeakReference) CreateVector3ListAndGetItem()
    {
        Vector3List list = new Vector3List();
        list.Add(new Vector3(5.0f, 5.0f, 5.0f));
        WeakReference weak = new WeakReference(list);
        return (list[0], weak);
    }

    [Fact]
    public void ContainerItemDanglesAfterGCCollectsOwner()
    {
        Vector3 innerObject = null;
        WeakReference weakRef = null;

        for (int i = 0; i < 25; ++i)
        {
            GC.Collect(GC.MaxGeneration, GCCollectionMode.Forced, blocking: true);
            GC.WaitForPendingFinalizers();
            GC.Collect(GC.MaxGeneration, GCCollectionMode.Forced, blocking: true);

            ClobberNativeHeap();

            if (weakRef != null)
            {
                Assert.True(weakRef.IsAlive,
                    $"Iteration {i}: Vector3List was collected by GC, despite being pinned by its inner value");
            }

            if (innerObject != null)
            {
                // This shouldn't crash, and should be 5.
                // If the pinning functionality doesn't work, this will _probably_ be zero or garbage.
                Assert.Equal(5.0f, innerObject.X);
            }

            var result = CreateVector3ListAndGetItem();
            innerObject = result.Item1;
            weakRef = result.Item2;
        }
    }


    [MethodImpl(MethodImplOptions.NoInlining)]
    static Space CreateTestSpaceSync(SpaceSystem spaceSystem)
    {
        SpaceResult createSpaceResult = spaceSystem.CreateSpaceAsync(
            Guid.NewGuid().ToString(), "Test CSharp space description",
            SpaceAttributes.Public, null, new StringDict(), null, null)
            .GetAwaiter().GetResult(); // Use Awaiter to avoid generating an async state machine,
                                       // which confounds the test.
        Assert.Equal(EResultCode.Success, createSpaceResult.GetResultCode());
        return createSpaceResult.GetSpace();
    }

    [EnvironmentFact("RUN_LIVE_SERVICE_TESTS")]
    public async Task AsyncResultReturnDanglesAfterGCCollectsOwner()
    {
        /* I'd rather test this without calling to services, but Result objects
         * are so important for this issue, not testing them would be irresponsible, and
         * this is the only easy way to do it currently */

        ClientUserAgent userAgent = new ClientUserAgent();
        userAgent.CSPVersion = "Unknown";
        userAgent.ClientOS = "Unknown";
        userAgent.ClientSKU = "CSharp-Interop";
        userAgent.ClientVersion = "Unknown";
        userAgent.ClientEnvironment = "ODev";
        userAgent.CHSEnvironment = "oDev";
        bool initResult = CSPFoundation.Initialise("https://ogs-internal.magnopus-dev.cloud", "OKO_TESTS", userAgent, null);
        Assert.True(initResult);

        UserSystem userSystem = SystemsManager.Get().GetUserSystem();
        string guid = Guid.NewGuid().ToString();
        string testAccountPW = "3R{d2}3C<x[J7=jU";
        ProfileResult createUserResult = await userSystem.CreateUserAsync(
            $"CSharp-TestUser{guid}", "DisplayName",
            $"testnopus.pokemon+{guid}@magnopus.com",
            testAccountPW, false, true, null, null);
        Profile testUser = createUserResult.GetProfile();

        await userSystem.LoginAsync("", testUser.Email, testAccountPW, true, true, null);
        Assert.Equal(ELoginState.LoggedIn, userSystem.GetLoginState().State);

        // Create space in a non-async, non-inlineable method so the SpaceResult
        // is a true stack local that dies when the method returns.
        SpaceSystem spaceSystem = SystemsManager.Get().GetSpaceSystem();
        Space space = CreateTestSpaceSync(spaceSystem);

        GC.Collect(GC.MaxGeneration, GCCollectionMode.Forced, blocking: true);
        GC.WaitForPendingFinalizers();
        GC.Collect(GC.MaxGeneration, GCCollectionMode.Forced, blocking: true);

        ClobberNativeHeap();

        Assert.Equal("Test CSharp space description", space.Description);

        NullResult deleteResult = await spaceSystem.DeleteSpaceAsync(space.Id);
        Assert.Equal(EResultCode.Success, deleteResult.GetResultCode());

        CSPFoundation.Shutdown();
    }

    // No Optional<T> return or callback args in the API. 
    // This is a bit of a hole in testing as optional typemaps are effected by this feature.
}
