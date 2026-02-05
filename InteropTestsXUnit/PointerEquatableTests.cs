namespace InteropTestsXUnit;

using csp.common;
using csp.multiplayer;
using System;
using System.Diagnostics;

public class PointerEquatableTests
{
    TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner();
    LogSystem LogSystem = new LogSystem();
    OfflineRealtimeEngine _RealtimeEngine;

    public PointerEquatableTests()
    {
        _RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);
    }

    /*
     * Test that Equals, ==, and Hash works as expected for types declared as pointer equatable types
     */
    [Fact]
    public void IsEquatableType()
    {
        /* Check that types marked as equatable inherit the interface 
           Don't need to do every type, just check the typemapping is working */

        SpaceEntity SpaceEntity = new SpaceEntity(_RealtimeEngine, MockScriptRunner, LogSystem);
        Assert.IsAssignableFrom<IEquatable<SpaceEntity>>(SpaceEntity);
    }

    [Fact]
    public void EqualsReflexiveSameInstance()
    {
        SpaceEntity SpaceEntity = new SpaceEntity(_RealtimeEngine, MockScriptRunner, LogSystem);

        Assert.True(SpaceEntity.Equals(SpaceEntity));
        Assert.True(SpaceEntity == SpaceEntity);
    }

    [Fact]
    public void EqualsWithNull()
    {
        SpaceEntity SpaceEntity = new SpaceEntity(_RealtimeEngine, MockScriptRunner, LogSystem);

        Assert.False(SpaceEntity.Equals(null));
    }

    [Fact]
    public async Task DifferentProxyObjectsSameUnderlyingEqual()
    {
        // The proxy objects we have will be different, but they will still compare equal
        // due to holding pointers to the same C++ memory.
        SpaceEntity SpaceEntity1 = await _RealtimeEngine.CreateEntityAsync("Name", new SpaceTransform(), null);
        SpaceEntity SpaceEntity2 = _RealtimeEngine.GetEntityByIndex(0);

        Assert.True(SpaceEntity1.Equals(SpaceEntity2));
        Assert.True(SpaceEntity1 == SpaceEntity2);
        Assert.False(SpaceEntity1 != SpaceEntity2);
    }

    [Fact]
    public void NotEqual()
    {
        // Any two pointer unique equatable types are not equal, even if they have the same values
        SpaceEntity SpaceEntity1 = new SpaceEntity(_RealtimeEngine, MockScriptRunner, LogSystem);
        SpaceEntity SpaceEntity2 = new SpaceEntity(_RealtimeEngine, MockScriptRunner, LogSystem);

        Assert.False(SpaceEntity1.Equals(SpaceEntity2));
        Assert.False(SpaceEntity1 == SpaceEntity2);
        Assert.True(SpaceEntity1 != SpaceEntity2);
    }

    [Fact]
    public async Task EqualHashCodes()
    {
        // Hash codes for pointer equality is just the pointer value itself. So the same underlying
        // C++ memory should have the same hash
        SpaceEntity SpaceEntity1 = await _RealtimeEngine.CreateEntityAsync("Name", new SpaceTransform(), null);
        SpaceEntity SpaceEntity2 = _RealtimeEngine.GetEntityByIndex(0);

        Assert.Equal(SpaceEntity1, SpaceEntity2);
        Assert.Equal(SpaceEntity1.GetHashCode(), SpaceEntity2.GetHashCode());
    }

    [Fact]
    public void NotEqualHashCodes()
    {
        //Different pointers, different hashes
        SpaceEntity SpaceEntity1 = new SpaceEntity(_RealtimeEngine, MockScriptRunner, LogSystem);
        SpaceEntity SpaceEntity2 = new SpaceEntity(_RealtimeEngine, MockScriptRunner, LogSystem);

        Assert.NotEqual(SpaceEntity1, SpaceEntity2);
        Assert.NotEqual(SpaceEntity1.GetHashCode(), SpaceEntity2.GetHashCode());
    }

    [Fact]
    public async Task DeferToTypedEquals()
    {
        //Boxed comparison should defer to the typed one
        SpaceEntity SpaceEntity1 = await _RealtimeEngine.CreateEntityAsync("Name", new SpaceTransform(), null);
        SpaceEntity SpaceEntity2 = _RealtimeEngine.GetEntityByIndex(0);

        Assert.True(SpaceEntity1.Equals((object)SpaceEntity2));
    }
}
