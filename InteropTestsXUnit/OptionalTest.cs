namespace InteropTestsXUnit;

using csp.systems;
using csp.common;
using csp.multiplayer;
using csp;
using System.Drawing;
using System.Reflection;

public class OptionalTest : IDisposable
{
    /*
     * Test optional conversion
     * This one's a bit different, as whilst there _are_ underlying concrete Optional types,
     * the interface is expressed using C# `?` annotations. C# users won't see then.
     * 
     * A tad tricky to test in isolation as there arn't that many isolated Optional<T> interfaces
     * in CSP.
     */

    public void Dispose()
    {
        //We call initialize in some tests, we don't want this to affect others.
        if (CSPFoundation.GetIsInitialised())
        {
            CSPFoundation.Shutdown();
        }

        // Runs after each test, helps trigger some GC bugs earlier. Should probably put this in every test.
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();
    }


    /* Optional Properties did work when the wrapper was implemented, but CSP no longer exposes Optional<T> return values
     * for legacy wrapper gen reason. No doubt they will return, but are not tested yet for that reason 
     * Optional input params are still a thing. */

    [Fact]
    public void OptionalContainer()
    {
        //Initialise has an Optional<Array<FeatureFlag>> (FeatureFlagArray? in C#) interface that we can use to at least check the interface accepts the type.

        ClientUserAgent agent = new ClientUserAgent();
        FeatureFlagArray? OptArray = null;
        Assert.Null(OptArray);
        CSPFoundation.Initialise("", "", agent, OptArray);

        OptArray = new FeatureFlagArray(1);
        OptArray[0] = new FeatureFlag(EFeatureFlag.Invalid, true);
        Assert.Single(OptArray);
        Assert.NotNull(OptArray);

        OptArray = null;
        Assert.Null(OptArray);
    }

}
