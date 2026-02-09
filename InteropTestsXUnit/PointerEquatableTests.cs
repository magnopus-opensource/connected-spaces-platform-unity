namespace InteropTestsXUnit;

using csp.common;
using csp.multiplayer;
using System;
using System.Diagnostics;

public class PointerEquatableTests
{
    /*
     * Test that Equals, ==, and Hash works as expected for types declared as pointer equatable types
     */
    [Fact]
    public void IsEquatableType()
    {
        /* Check that types marked as equatable inherit the interface
           Don't need to do every type, just check the typemapping is working */

        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            using SpaceEntity SpaceEntity = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);
            Assert.IsAssignableFrom<IEquatable<SpaceEntity>>(SpaceEntity);
        }
    }

    [Fact]
    public void EqualsReflexiveSameInstance()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            using SpaceEntity SpaceEntity = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);

            Assert.True(SpaceEntity.Equals(SpaceEntity));
            Assert.True(SpaceEntity == SpaceEntity);
        }
    }

    [Fact]
    public void EqualsWithNull()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            using SpaceEntity SpaceEntity = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);

            Assert.False(SpaceEntity.Equals(null));
        }
    }

    [Fact]
    public async Task DifferentProxyObjectsSameUnderlyingEqual()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            // The proxy objects we have will be different, but they will still compare equal
            // due to holding pointers to the same C++ memory.
            using SpaceEntity SpaceEntity1 = await RealtimeEngine.CreateEntityAsync("Name", new SpaceTransform(), null);
            using SpaceEntity SpaceEntity2 = RealtimeEngine.GetEntityByIndex(0);

            Assert.True(SpaceEntity1.Equals(SpaceEntity2));
            Assert.True(SpaceEntity1 == SpaceEntity2);
            Assert.False(SpaceEntity1 != SpaceEntity2);
        }
    }

    [Fact]
    public void NotEqual()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            // Any two pointer unique equatable types are not equal, even if they have the same values
            using SpaceEntity SpaceEntity1 = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);
            using SpaceEntity SpaceEntity2 = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);

            Assert.False(SpaceEntity1.Equals(SpaceEntity2));
            Assert.False(SpaceEntity1 == SpaceEntity2);
            Assert.True(SpaceEntity1 != SpaceEntity2);
        }
    }

    [Fact]
    public async Task EqualHashCodes()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            // Hash codes for pointer equality is just the pointer value itself. So the same underlying
            // C++ memory should have the same hash
            using SpaceEntity SpaceEntity1 = await RealtimeEngine.CreateEntityAsync("Name", new SpaceTransform(), null);
            using SpaceEntity SpaceEntity2 = RealtimeEngine.GetEntityByIndex(0);

            Assert.Equal(SpaceEntity1, SpaceEntity2);
            Assert.Equal(SpaceEntity1.GetHashCode(), SpaceEntity2.GetHashCode());
        }
    }

    [Fact]
    public void NotEqualHashCodes()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            //Different pointers, different hashes
            using SpaceEntity SpaceEntity1 = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);
            using SpaceEntity SpaceEntity2 = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);

            Assert.NotEqual(SpaceEntity1, SpaceEntity2);
            Assert.NotEqual(SpaceEntity1.GetHashCode(), SpaceEntity2.GetHashCode());
        }
    }

    [Fact]
    public async Task DeferToTypedEquals()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            //Boxed comparison should defer to the typed one
            using SpaceEntity SpaceEntity1 = await RealtimeEngine.CreateEntityAsync("Name", new SpaceTransform(), null);
            using SpaceEntity SpaceEntity2 = RealtimeEngine.GetEntityByIndex(0);

            Assert.True(SpaceEntity1.Equals((object)SpaceEntity2));
        }
    }
}
