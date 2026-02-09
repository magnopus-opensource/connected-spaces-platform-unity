namespace InteropTestsXUnit;

using csp;

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
        // Note: we decided to use GetBuildType instead of GetIsInitialised because we got one occurrence on the
        // following CI test: https://github.com/magnopus-opensource/connected-spaces-platform-unity/actions/runs/21819826644/job/62950038376?pr=26
        // where CSP for some reason resulted initialised. We assume this is related to the above CSPFoundation issue.
        var buildType = CSPFoundation.GetBuildType();
        Assert.False(string.IsNullOrEmpty(buildType), "Expected GetBuildType to return a non-empty string indicating the build type, even if CSP is not initialized.");
    }

}
