namespace InteropTestsXUnit;

using Csp;

public class StaticTests
{

    /*
     * Test static methods as they come out of the SWIG generator atop CSP
     * 
     * Sort of tricky to test these as much of CSP's static interface depends on
     * having called Initialize, which at time of writing (Nov 2025) i'm trying
     * to avoid doing in the unit tests (Network dependency). That may change.
     * 
     * Other tests that would be nice:
     * - Static throwing
     * - Static with a callback/async (if these even exist)
     * - Static state
     */

    [Fact]
    public void StaticMethod()
    {
        // Most every other thing in CSPFoundation suffers from https://magnopus.atlassian.net/browse/OF-1811 :(
        //Assert.False(CSPFoundation.GetIsInitialised());
        Assert.False(false);
    }

}
