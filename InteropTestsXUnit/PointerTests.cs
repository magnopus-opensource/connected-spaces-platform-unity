
namespace InteropTestsXUnit;

using csp;
using csp.common;
using csp.multiplayer;
using System.Reflection;
using System.Runtime.InteropServices;

public class PointerTests
{

    [Fact]
    public async Task SpaceEntityPointersPointToSameMemory()
    {
        /* I'll write this here, although it applies in many places
         * Currently, SpaceEntity has a destructor dependency on the script runner.
         * Normally this is more hidden as the script runner is always the globally
         * managed ScriptSystem, but not here in our tests at the moment. */
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            SpaceTransform NewEntityTransform = new SpaceTransform(new Vector3(1, 2, 3), new Vector4(0, 0, 0, 1), new Vector3(2, 3, 4));

            using SpaceEntity OriginalEntity = await RealtimeEngine.CreateEntityAsync("OriginalEntity", NewEntityTransform, null);

            Assert.Equal("OriginalEntity", OriginalEntity.GetName());
            Assert.Equal(new Vector3(1, 2, 3), OriginalEntity.GetPosition());

            // Get the same entity, check that they are equal.
            using SpaceEntity SameEntity = RealtimeEngine.GetEntityByIndex(0);

            //Space entities are pointer equatable
            Assert.Equal(OriginalEntity, SameEntity);

            //However, the underlying swigCPtr should be the same. Do some reflection dark arts to check
            var SwigCPtrField = typeof(SpaceEntity)
            .GetField("swigCPtr", BindingFlags.Instance | BindingFlags.NonPublic);

            HandleRef OriginalEntitySwigCPtrHandle = (HandleRef)SwigCPtrField.GetValue(OriginalEntity);
            HandleRef SameEntitySwigCPtrHandle = (HandleRef)SwigCPtrField.GetValue(SameEntity);

            Assert.Equal(OriginalEntitySwigCPtrHandle.Handle, SameEntitySwigCPtrHandle.Handle);
        }
    }

    [Fact]
    public async Task UpdateChangesPropagateToOriginalProxyObject()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            SpaceTransform NewEntityTransform = new SpaceTransform(new Vector3(1, 2, 3), new Vector4(0, 0, 0, 1), new Vector3(2, 3, 4));

            using SpaceEntity OriginalEntity = await RealtimeEngine.CreateEntityAsync("OriginalName", NewEntityTransform, null);

            TaskCompletionSource<SpaceEntity> CallbackSpaceEntityTCS = new TaskCompletionSource<SpaceEntity>();
            OriginalEntity.SetUpdateCallback(new ConnectedSpacesPlatformDotNet.UpdateCallback((UpdatedSpaceEntity, UpdateFlags, UpdatedComponentInfoArray) =>
            {
                CallbackSpaceEntityTCS.TrySetResult(UpdatedSpaceEntity);
            }));

            OriginalEntity.SetPosition(new Vector3(2, 3, 4));
            using SpaceEntity CallbackEntity = await CallbackSpaceEntityTCS.Task;

            //Now we have two proxy objects, each point to the same memory and have the same data

            //Both proxy objects are different, but should have the same position.
            Assert.NotNull(CallbackEntity);
            Assert.Equal(new Vector3(2, 3, 4), OriginalEntity.GetPosition());
            Assert.Equal(new Vector3(2, 3, 4), CallbackEntity.GetPosition());

            //Perform a similar update on the callback proxy object, check the original proxy object updates
            CallbackEntity.SetName("NewName");

            Assert.Equal("NewName", CallbackEntity.GetName());
            Assert.Equal("NewName", OriginalEntity.GetName());

        }
    }

    [Fact]
    public async Task DifferentSpaceEntitiesPointToDifferentMemory()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            SpaceTransform NewEntityTransform = new SpaceTransform(new Vector3(1, 2, 3), new Vector4(0, 0, 0, 1), new Vector3(2, 3, 4));

            using SpaceEntity Entity1 = await RealtimeEngine.CreateEntityAsync("SameName", NewEntityTransform, null);
            using SpaceEntity Entity2 = await RealtimeEngine.CreateEntityAsync("SameName", NewEntityTransform, null);

            //Check that the underlying swig pointers are different
            var SwigCPtrField = typeof(SpaceEntity)
            .GetField("swigCPtr", BindingFlags.Instance | BindingFlags.NonPublic);

            HandleRef OriginalEntitySwigCPtrHandle = (HandleRef)SwigCPtrField.GetValue(Entity1);
            HandleRef SameEntitySwigCPtrHandle = (HandleRef)SwigCPtrField.GetValue(Entity2);

            Assert.NotEqual(OriginalEntitySwigCPtrHandle.Handle, SameEntitySwigCPtrHandle.Handle);
        }
    }

    [Fact]
    public async Task MemoryOwnershipDependsOnWhereItemInstantiated()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            SpaceTransform NewEntityTransform = new SpaceTransform(new Vector3(1, 2, 3), new Vector4(0, 0, 0, 1), new Vector3(2, 3, 4));

            using SpaceEntity CreatedByCpp = await RealtimeEngine.CreateEntityAsync("SameName", NewEntityTransform, null);

            // The injection of the RealtimeEngine is suspicious here. I'm not convinced CSP is designed with this
            // sort of instantiation in mind. Not a concern for the CSharp wrapper, but CSP should break this 
            // dependency as it creates dangerous assumptions around memory ownership.
            using SpaceEntity CreatedByCSharp = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);

            //Check underlying memory ownership
            var SwigCMemOwnField = typeof(SpaceEntity)
            .GetField("swigCMemOwn", BindingFlags.Instance | BindingFlags.NonPublic);

            bool SwigCMemOwnCreatedByCpp = (bool)SwigCMemOwnField.GetValue(CreatedByCpp);
            bool SwigCMemOwnCreatedByCSharp = (bool)SwigCMemOwnField.GetValue(CreatedByCSharp);

            Assert.False(SwigCMemOwnCreatedByCpp);
            Assert.True(SwigCMemOwnCreatedByCSharp);
        }
    }

    [Fact]
    public void PointerListsImplementIList()
    {
        // Check that pointer lists get the IList interface by default, as all pointers should provide semantics to satisfy it.
        Assert.True(typeof(IList<SpaceEntity>).IsAssignableFrom(typeof(SpaceEntityPtrList)));
    }

}
