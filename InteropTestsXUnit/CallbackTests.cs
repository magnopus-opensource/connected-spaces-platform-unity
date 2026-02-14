namespace InteropTestsXUnit;

using csp.common;
using csp.multiplayer;
using System.Diagnostics;
using System.Reflection;
using System.Runtime.InteropServices;

public class CallbackTests
{

    [Fact]
    public void Callbacks()
    {
        /* Test that our callback adaptations function
         * We test 2 here, because we have a static buffer under the hood (swig IL2CPP adaptation), so 
         * it's possible state could be getting mangled. */
        using LogSystem logSystem = new LogSystem();
        Assert.True(logSystem != null);

        LogLevel? capturedLevel1 = null;
        string? capturedMessage1 = null;

        using ConnectedSpacesPlatformDotNet.LogCallback callback1 = new ConnectedSpacesPlatformDotNet.LogCallback((logLevel, message) =>
        {
            capturedLevel1 = logLevel;
            capturedMessage1 = message;
        });

        logSystem.SetLogCallback(callback1);
        logSystem.LogMsg(LogLevel.Log, "The first wrapped function works!");

        Assert.Equal(LogLevel.Log, capturedLevel1);
        Assert.Equal("The first wrapped function works!", capturedMessage1);

        LogLevel? capturedLevel2 = null;
        string? capturedMessage2 = null;

        ConnectedSpacesPlatformDotNet.LogCallback callback2 = new ConnectedSpacesPlatformDotNet.LogCallback((logLevel, message) =>
        {
            capturedLevel2 = logLevel;
            capturedMessage2 = message;
        });


        logSystem.SetLogCallback(callback2);
        logSystem.LogMsg(LogLevel.Warning, "The second wrapped function works!");

        Assert.Equal(LogLevel.Warning, capturedLevel2);
        Assert.Equal("The second wrapped function works!", capturedMessage2);
    }

    [Fact]
    public void CallbacksAcrossMultipleObjects()
    {
        /* Just a bit of paranoia really, no reason to believe this wouldn't work.
         * You can delete this if you like, once the initial integration is complete */

        using LogSystem logSystem1 = new LogSystem();
        Assert.True(logSystem1 != null);
        using LogSystem logSystem2 = new LogSystem();
        Assert.True(logSystem2 != null);

        LogLevel? capturedLevel = null;
        string? capturedMessage = null;
        int timesCalled = 0;

        using ConnectedSpacesPlatformDotNet.LogCallback callback1 = new ConnectedSpacesPlatformDotNet.LogCallback((logLevel, message) =>
        {
            capturedLevel = logLevel;
            capturedMessage = message;
            timesCalled++;
        });

        logSystem1.SetLogCallback(callback1);
        logSystem2.SetLogCallback(callback1);

        logSystem1.LogMsg(LogLevel.Log, "First call.");

        Assert.Equal(LogLevel.Log, capturedLevel);
        Assert.Equal("First call.", capturedMessage);
        Assert.Equal(1, timesCalled);

        logSystem2.LogMsg(LogLevel.Warning, "Second call.");

        Assert.Equal(LogLevel.Warning, capturedLevel);
        Assert.Equal("Second call.", capturedMessage);
        Assert.Equal(2, timesCalled);
    }

    [Fact]
    public async Task SpaceEntityCallbacks()
    {
        /* Arguably this isn't a neccesary mechanism test, as the log callbacks above prove this out.
         * However I want a little bit of confidence in callbacks firing based on other actions. */

        using TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner();
        using LogSystem LogSystem = new LogSystem();
        using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

        SpaceTransform NewEntityTransform = new SpaceTransform(new Vector3(1, 2, 3), new Vector4(0, 0, 0, 1), new Vector3(2, 3, 4));
        SpaceEntity SpaceEntity = await RealtimeEngine.CreateEntityAsync("SpaceEntity", NewEntityTransform, null);

        TaskCompletionSource<bool> UpdateTCS = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
        TaskCompletionSource<bool> DestroyTCS = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);

        SpaceEntity.SetUpdateCallback(new ConnectedSpacesPlatformDotNet.UpdateCallback((UpdatedSpaceEntity, UpdateFlags, UpdatedComponentInfoArray) => { UpdateTCS.TrySetResult(true); }));
        SpaceEntity.SetDestroyCallback(new ConnectedSpacesPlatformDotNet.DestroyCallback(x => { DestroyTCS.TrySetResult(true); }));

        SpaceEntity.SetPosition(new Vector3(0, 1, 2));
        Assert.True(await UpdateTCS.Task);
        Assert.False(DestroyTCS.Task.IsCompleted);

        await RealtimeEngine.DestroyEntityAsync(SpaceEntity);
        Assert.True(await DestroyTCS.Task);
    }

    [Fact]
    public async Task ComplexCallbackValues()
    {
        using TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner();
        using LogSystem LogSystem = new LogSystem();
        using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

        SpaceTransform NewEntityTransform = new SpaceTransform(new Vector3(1, 2, 3), new Vector4(0, 0, 0, 1), new Vector3(2, 3, 4));
        SpaceEntity SpaceEntity = await RealtimeEngine.CreateEntityAsync("SpaceEntity", NewEntityTransform, null);

        ComponentBase CollisionComponent = SpaceEntity.AddComponent(ComponentType.Collision);

        TaskCompletionSource<SpaceEntity> CallbackSpaceEntityTCS = new TaskCompletionSource<SpaceEntity>(TaskCreationOptions.RunContinuationsAsynchronously);
        TaskCompletionSource<SpaceEntityUpdateFlags> CallbackUpdateFlagsTCS = new TaskCompletionSource<SpaceEntityUpdateFlags>(TaskCreationOptions.RunContinuationsAsynchronously);
        TaskCompletionSource<List<ComponentUpdateInfo>> CallbackComponentUpdateInfoArrayTCS = new TaskCompletionSource<List<ComponentUpdateInfo>>(TaskCreationOptions.RunContinuationsAsynchronously);

        SpaceEntity.SetUpdateCallback(new ConnectedSpacesPlatformDotNet.UpdateCallback((UpdatedSpaceEntity, UpdateFlags, UpdatedComponentInfoArray) =>
        {
            CallbackSpaceEntityTCS.TrySetResult(UpdatedSpaceEntity);
            CallbackUpdateFlagsTCS.TrySetResult(UpdateFlags);

            // If you don't copy, CSP releases the memory under you for certain reference arguments. This is just an api design bug straight up.
            // I tried to fix this at the CSP level, but wouldn't you know legacy wrapper generator makes it somewhat impossible to naively switch
            // to a value argument in the callback.
            if (!UpdatedComponentInfoArray.IsEmpty()) // Not catastrophic, but an annoying quirk for writing capturing callbacks like this.
            {                                         // Even actions that don't impact the components will give you an empty list, so can't just set the TCS.
                CallbackComponentUpdateInfoArrayTCS.TrySetResult(UpdatedComponentInfoArray.DeepCopyToList());
            }
        }));

        //Trigger behavior
        SpaceEntity.SetPosition(new Vector3(5, 5, 5));

        SpaceEntity CallbackSpaceEntity = await CallbackSpaceEntityTCS.Task;
        SpaceEntityUpdateFlags CallbackUpdateFlags = await CallbackUpdateFlagsTCS.Task;

        Assert.NotNull(CallbackSpaceEntity);

        Assert.True((CallbackUpdateFlags & SpaceEntityUpdateFlags.UPDATE_FLAGS_POSITION) != 0);
        Assert.False((CallbackUpdateFlags & SpaceEntityUpdateFlags.UPDATE_FLAGS_NAME) != 0);
        Assert.False(CallbackComponentUpdateInfoArrayTCS.Task.IsCompleted);

        CollisionSpaceComponent CollisionComp = CollisionSpaceComponent.FromBaseCast(CollisionComponent);
        Assert.NotNull(CollisionComp);

        // Trigger a component update
        CollisionComp.SetCollisionShape(CollisionShape.Capsule);

        List<ComponentUpdateInfo> CallbackComponentUpdateInfoArray = await CallbackComponentUpdateInfoArrayTCS.Task;

        Assert.True(CallbackComponentUpdateInfoArray.Count == 1);
        Assert.Equal(ComponentUpdateType.Update, CallbackComponentUpdateInfoArray[0].UpdateType);

        // Is this always 0? Or do we expect clients to set this explicitly. Component update api could really use some work.
        Assert.Equal(0, CallbackComponentUpdateInfoArray[0].ComponentId);
    }

    // Still nervous about testing these with the online engine when that's possible, with complex off-thread items in callbacks.
    // Mostly nervous about separating "normal" CSP threading issues from issues with the wrapper.
}
