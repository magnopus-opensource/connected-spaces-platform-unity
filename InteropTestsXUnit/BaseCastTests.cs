namespace InteropTestsXUnit;

using csp.common;
using csp.multiplayer;
using System.Diagnostics;
using System.Reflection;
using System.Runtime.InteropServices;

public class BaseCastTests
{

    [Fact]
    public void ComponentCast()
    {
        TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner();
        LogSystem LogSystem = new LogSystem();
        OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

        SpaceEntity SpaceEntity = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);
        ComponentBase Component = SpaceEntity.AddComponent(ComponentType.Text);

        Assert.NotNull(Component);

        // Cast to the correct subtype
        TextSpaceComponent TextComponent = TextSpaceComponent.FromBaseCast(Component);
        Assert.NotNull(TextComponent);

        TextSpaceComponent? TextComponentTry = TextSpaceComponent.TryFromBaseCast(Component);
        Assert.NotNull(TextComponentTry);
    }

    [Fact]
    public void InvalidComponentCastThrows()
    {
        TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner();
        LogSystem LogSystem = new LogSystem();
        OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

        SpaceEntity SpaceEntity = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);
        ComponentBase Component = SpaceEntity.AddComponent(ComponentType.Text);

        Assert.NotNull(Component);

        // Attempt to cast to the wrong subtype
        var exception = Assert.Throws<ArgumentException>(() => CollisionSpaceComponent.FromBaseCast(Component));
        Assert.Contains("Failed to cast", exception.Message);
        Assert.Equal("baseObj", exception.ParamName);
    }

    [Fact]
    public void InvalidComponentCastTryIsNull()
    {
        TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner();
        LogSystem LogSystem = new LogSystem();
        OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

        SpaceEntity SpaceEntity = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);
        ComponentBase Component = SpaceEntity.AddComponent(ComponentType.Text);

        Assert.NotNull(Component);

        // Attempt to cast to the wrong subtype
        Assert.Null(CollisionSpaceComponent.TryFromBaseCast(Component));
    }
}
