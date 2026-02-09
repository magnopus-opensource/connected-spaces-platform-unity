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
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            using SpaceEntity SpaceEntity = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);
            using ComponentBase Component = SpaceEntity.AddComponent(ComponentType.Text);

            Assert.NotNull(Component);

            // Cast to the correct subtype
            TextSpaceComponent TextComponent = TextSpaceComponent.FromBaseCast(Component);
            Assert.NotNull(TextComponent);

            TextSpaceComponent? TextComponentTry = TextSpaceComponent.TryFromBaseCast(Component);
            Assert.NotNull(TextComponentTry);
        }
    }

    [Fact]
    public void InvalidComponentCastThrows()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            using SpaceEntity SpaceEntity = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);
            using ComponentBase Component = SpaceEntity.AddComponent(ComponentType.Text);

            Assert.NotNull(Component);

            // Attempt to cast to the wrong subtype
            var exception = Assert.Throws<ArgumentException>(() => CollisionSpaceComponent.FromBaseCast(Component));
            Assert.Contains("Failed to cast", exception.Message);
            Assert.Equal("baseObj", exception.ParamName);
        }
    }

    [Fact]
    public void InvalidComponentCastTryIsNull()
    {
        using (TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem LogSystem = new LogSystem();
            using OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

            using SpaceEntity SpaceEntity = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);
            using ComponentBase Component = SpaceEntity.AddComponent(ComponentType.Text);

            Assert.NotNull(Component);

            // Attempt to cast to the wrong subtype
            Assert.Null(CollisionSpaceComponent.TryFromBaseCast(Component));
        }
    }
}
