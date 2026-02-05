namespace InteropTestsXUnit;

using csp.common;
using csp.multiplayer;
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class InterfaceTests
{
    /*
     * Test types declared as %interface are represented correctly in generated output
     * At time of writing, this is exclusively multiplayer component interfaces.
     * ... which to be honest, I doubt are a design that's going to stick around very long.
     */

    [Fact]
    public void InterfacesAreCSharpInterface()
    {
        // Just test a couple
        Assert.True(typeof(ITransformComponent).IsInterface);
        Assert.True(typeof(IVisibleComponent).IsInterface);
    }

    [Fact]
    public void HasInterface()
    {
        // Don't need to actually instantiate to test this.
        StaticModelSpaceComponent StaticModelSpaceComponent = new StaticModelSpaceComponent(0, false);
        Assert.True(StaticModelSpaceComponent is ComponentBase);

        // Look at all these interfaces!
        Assert.True(StaticModelSpaceComponent is IExternalResourceComponent);
        Assert.True(StaticModelSpaceComponent is IShadowCasterComponent);
        Assert.True(StaticModelSpaceComponent is IThirdPartyComponentRef);
        Assert.True(StaticModelSpaceComponent is ITransformComponent);
        Assert.True(StaticModelSpaceComponent is IPositionComponent);
        Assert.True(StaticModelSpaceComponent is IRotationComponent);
        Assert.True(StaticModelSpaceComponent is IScaleComponent);
        Assert.True(StaticModelSpaceComponent is IVisibleComponent);
        Assert.True(StaticModelSpaceComponent is IRenderBehaviourComponent);
    }

    [Fact]
    public void CanUseAsInterface()
    {
        TempMockScriptRunner MockScriptRunner = new TempMockScriptRunner();
        LogSystem LogSystem = new LogSystem();
        OfflineRealtimeEngine RealtimeEngine = new OfflineRealtimeEngine(LogSystem, MockScriptRunner);

        SpaceEntity SpaceEntity = new SpaceEntity(RealtimeEngine, MockScriptRunner, LogSystem);

        StaticModelSpaceComponent StaticModelSpaceComponent = new StaticModelSpaceComponent(LogSystem, SpaceEntity);

        Assert.Equal(StaticModelSpaceComponent.GetPosition(), new Vector3(0, 0, 0));
        StaticModelSpaceComponent.SetPosition(new Vector3(1, 2, 3));
        Assert.Equal(StaticModelSpaceComponent.GetPosition(), new Vector3(1, 2, 3));

        // Get the component as an interface, try to do the same thing
        IPositionComponent PositionComponentInterface = StaticModelSpaceComponent;
        Assert.Equal(PositionComponentInterface.GetPosition(), new Vector3(1, 2, 3));
        StaticModelSpaceComponent.SetPosition(new Vector3(2, 4, 6));
        Assert.Equal(StaticModelSpaceComponent.GetPosition(), new Vector3(2, 4, 6));
    }


}
