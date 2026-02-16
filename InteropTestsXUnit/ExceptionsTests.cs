using csp.common;

namespace InteropTestsXUnit;

public class ExceptionsTests
{
    [Fact(Skip="This test is expected to fail. We'd want some sort of failsafe handler for when the CSP api contract is broken")]
    public async Task AsyncCppException_IsObservedInCSharp()
    {
        using var logSystem = new LogSystem();

        var ex = await Assert.ThrowsAsync<Exception>(() =>
            logSystem.LogAndThrowAsync()
        );

        Assert.Contains("Native async exception from SWIG", ex.Message);
    }
    
    [Fact(Skip="This test is expected to fail. We'd want some sort of failsafe handler for when the CSP api contract is broken", 
        DisplayName = "Native async failure surfaces as C# exception")]
    public async Task AsyncFailure_IsCatchable()
    {
        using var logSystem = new LogSystem();

        await Assert.ThrowsAsync<Exception>(async () =>
        {
            await logSystem.LogAndThrowAsync();
        });
    }
    
    [Fact(DisplayName = "Native C++ failure surfaces as C# exception when not async")]
    public void NativeException_CaughtByCSharpLayer()
    {
        using var logSystem = new LogSystem();

        Assert.Throws<ApplicationException>(() =>
        {
            logSystem.ThrowImmediately();
        });
    }

}