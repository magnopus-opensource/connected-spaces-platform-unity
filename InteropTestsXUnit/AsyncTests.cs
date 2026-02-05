using csp.common;
using Magnopus.Extra.Exceptions;
using System.Diagnostics;

namespace InteropTestsXUnit;

public class AsyncInteropTests
{
    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Async success path completes and returns managed result")]
    public async Task Async_Success_CompletesAndReturnsResult()
    {
        using LogSystem logSystem = new LogSystem();

        var result = await logSystem.LogAfterSecondsAsync(true, 1);

        Assert.True(result.GetValue());
    }

    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Native failure propagates as managed exception via ThrowOnFailure")]
    public async Task Async_Failure_ThrowsManagedException()
    {
        using LogSystem logSystem = new LogSystem();

        var ex = await Assert.ThrowsAsync<CspResultEndpointException>(() =>
            logSystem.LogAfterSecondsAsync(false, 1));

        Assert.Equal(500, ex.StatusCode);
    }

    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Async call is non-blocking and does not complete synchronously")]
    public async Task Async_IsTrulyAsynchronous()
    {
        using LogSystem logSystem = new LogSystem();

        Task task = logSystem.LogAfterSecondsAsync(true, 1);

        Assert.False(task.IsCompleted);

        await task;
    }

    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Native delay is respected and not bypassed by managed wrapper")]
    public async Task Async_RespectsNativeTiming()
    {
        using LogSystem logSystem = new LogSystem();

        Stopwatch sw = Stopwatch.StartNew();
        await logSystem.LogAfterSecondsAsync(true, 1);
        sw.Stop();

        Assert.True(sw.ElapsedMilliseconds >= 900);
    }

    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Native callback executes on a background thread")]
    public async Task Callback_ExecutesOffCallingThread()
    {
        using LogSystem logSystem = new LogSystem();

        int callingThread = Environment.CurrentManagedThreadId;
        int callbackThread = -1;

        await logSystem.LogAfterSecondsAsync(true, 1)
            .ContinueWith(t =>
            {
                callbackThread = Environment.CurrentManagedThreadId;
                return t.Result;
            });

        Assert.NotEqual(callingThread, callbackThread);
    }

    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Multiple concurrent async calls do not interfere with each other")]
    public async Task ConcurrentCalls_DoNotInterfere()
    {
        using LogSystem logSystem = new LogSystem();

        var tasks = Enumerable.Range(0, 10)
            .Select(_ => logSystem.LogAfterSecondsAsync(true, 1))
            .ToArray();

        var results = await Task.WhenAll(tasks);

        Assert.All(results, r => Assert.True(r.GetValue()));
    }

    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Failure in one async call does not poison subsequent calls")]
    public async Task Failure_DoesNotPoisonSubsequentCalls()
    {
        using LogSystem logSystem = new LogSystem();

        await Assert.ThrowsAsync<CspResultEndpointException>(() =>
            logSystem.LogAfterSecondsAsync(false, 1));

        var result = await logSystem.LogAfterSecondsAsync(true, 1);

        Assert.True(result.GetValue());
    }

    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Callback and result survive garbage collection pressure")]
    public async Task Async_SurvivesGarbageCollection()
    {
        using LogSystem logSystem = new LogSystem();

        Task<extra.test.TestBooleanResult> task =
            logSystem.LogAfterSecondsAsync(true, 1);

        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();

        var result = await task;

        Assert.True(result.GetValue());
    }


    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Disposing managed wrapper before callback does not crash or deadlock")]
    public async Task Dispose_BeforeCallback_IsSafe()
    {
        LogSystem logSystem = new LogSystem();

        Task task = logSystem.LogAfterSecondsAsync(true, 1);

        logSystem.Dispose();

        await task;
    }

    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Async call completes under thread pool pressure")]
    public async Task Async_CompletesUnderThreadPoolPressure()
    {
        using LogSystem logSystem = new LogSystem();

        var blockers = Enumerable.Range(0, Environment.ProcessorCount)
            .Select(_ => Task.Run(() => Thread.Sleep(500)))
            .ToArray();

        Task asyncTask = logSystem.LogAfterSecondsAsync(true, 1);

        await Task.WhenAll(blockers);
        await asyncTask;
    }

    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Async task follows valid lifecycle and reaches completion state")]
    public async Task Task_Lifecycle_IsValid()
    {
        using LogSystem logSystem = new LogSystem();

        Task task = logSystem.LogAfterSecondsAsync(true, 1);

        Assert.True(
            task.Status == TaskStatus.WaitingForActivation ||
            task.Status == TaskStatus.Running);

        await task;

        Assert.Equal(TaskStatus.RanToCompletion, task.Status);
    }

    
    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Concurrent async calls on separate LogSystem instances run in parallel")]
    public async Task ConcurrentCalls_OnDifferentInstances_DoNotBlock()
    {
        using var a = new LogSystem();
        using var b = new LogSystem();

        var sw = System.Diagnostics.Stopwatch.StartNew();

        await Task.WhenAll(
            a.LogAfterSecondsAsync(true, 1),
            b.LogAfterSecondsAsync(true, 1)
        );

        sw.Stop();
        Assert.True(sw.Elapsed.TotalSeconds < 2, 
            $"Expected calls on different instances to run concurrently, but elapsed time was {sw.Elapsed.TotalSeconds}s");
    }

    
    // TODO (OPE-3089): Do not skip this test once we have a strategy to keep the callback delegate alive
    [Fact(
        Skip = "This test will fail until we have a strategy to ensure the callback is kept in memory by C# until the C++ async operation completes.",
        DisplayName = "Callback is invoked exactly once per async call")]
    public async Task Callback_IsInvokedExactlyOnce()
    {
        using var logSystem = new LogSystem();

        int calls = 0;

        var result = await logSystem.LogAfterSecondsAsync(true, 1)
            .ContinueWith(t =>
            {
                Interlocked.Increment(ref calls);
                return t.Result;
            });

        Assert.Equal(1, calls);
    }

}
