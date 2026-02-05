using csp.common;
using Magnopus.Extra.Exceptions;
using System.Diagnostics;

namespace InteropTestsXUnit;

public class AsyncInteropTests
{
    [Fact(DisplayName = "Async success path completes and returns managed result")]
    public async Task Async_Success_CompletesAndReturnsResult()
    {
        using LogSystem logSystem = new LogSystem();

        var result = await logSystem.LogAfterSecondsAsync(true, 1);

        Assert.True(result.GetValue());
    }

    [Fact(DisplayName = "Native failure propagates as managed exception via ThrowOnFailure")]
    public async Task Async_Failure_ThrowsManagedException()
    {
        using LogSystem logSystem = new LogSystem();

        var ex = await Assert.ThrowsAsync<CspResultEndpointException>(() =>
            logSystem.LogAfterSecondsAsync(false, 1));

        Assert.Equal(500, ex.StatusCode);
    }

    [Fact(DisplayName = "Async call is non-blocking and does not complete synchronously")]
    public async Task Async_IsTrulyAsynchronous()
    {
        using LogSystem logSystem = new LogSystem();

        Task task = logSystem.LogAfterSecondsAsync(true, 1);

        Assert.False(task.IsCompleted);

        await task;
    }

    [Fact(DisplayName = "Native delay is respected and not bypassed by managed wrapper")]
    public async Task Async_RespectsNativeTiming()
    {
        using LogSystem logSystem = new LogSystem();

        Stopwatch sw = Stopwatch.StartNew();
        await logSystem.LogAfterSecondsAsync(true, 1);
        sw.Stop();

        Assert.True(sw.ElapsedMilliseconds >= 900);
    }

    [Fact(DisplayName = "Native callback executes on a background thread")]
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

    [Fact(DisplayName = "Multiple concurrent async calls do not interfere with each other")]
    public async Task ConcurrentCalls_DoNotInterfere()
    {
        using LogSystem logSystem = new LogSystem();

        var tasks = Enumerable.Range(0, 10)
            .Select(_ => logSystem.LogAfterSecondsAsync(true, 1))
            .ToArray();

        var results = await Task.WhenAll(tasks);

        Assert.All(results, r => Assert.True(r.GetValue()));
    }

    [Fact(DisplayName = "Failure in one async call does not poison subsequent calls")]
    public async Task Failure_DoesNotPoisonSubsequentCalls()
    {
        using LogSystem logSystem = new LogSystem();

        await Assert.ThrowsAsync<CspResultEndpointException>(() =>
            logSystem.LogAfterSecondsAsync(false, 1));

        var result = await logSystem.LogAfterSecondsAsync(true, 1);

        Assert.True(result.GetValue());
    }

    [Fact(DisplayName = "Callback and result survive garbage collection pressure")]
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


    [Fact(DisplayName = "Disposing managed wrapper before callback does not crash or deadlock")]
    public async Task Dispose_BeforeCallback_IsSafe()
    {
        LogSystem logSystem = new LogSystem();

        Task task = logSystem.LogAfterSecondsAsync(true, 1);

        logSystem.Dispose();

        await task;
    }

    [Fact(DisplayName = "Async call completes under thread pool pressure")]
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

    [Fact(DisplayName = "Async task follows valid lifecycle and reaches completion state")]
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

    
    [Fact(DisplayName = "Concurrent async calls on separate LogSystem instances run in parallel")]
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

    
    [Fact(DisplayName = "Callback is invoked exactly once per async call")]
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
    
    [Fact(
        Skip = "This seems to fail due to swig director registration code not being thread safe, maybe worth investigating...",
        DisplayName = "CallbackLifetime global lock scales under heavy concurrency")]
    public async Task CallbackLifetime_Lock_Contention_Stress_V1()
    {
        using var logSystem = new LogSystem();

        const int operations = 10_000;

        var sw = Stopwatch.StartNew();

        // Fire a large number of async operations concurrently
        var tasks = Enumerable.Range(0, operations)
            .Select(_ => logSystem.LogAfterSecondsAsync(true, 0))
            .Cast<Task>()
            .ToArray();

        await Task.WhenAll(tasks);

        sw.Stop();

        // The value for the comparison here is somewhat arbitrary, but the point is just to verify we would not have
        // a problem with the locking strategy.
        Assert.True(
            sw.ElapsedMilliseconds < 1500,
            $"Expected < 1500ms, actual: {sw.ElapsedMilliseconds}ms"
        );
    }
    
    [Fact(
        Skip = "Despite we create tasks sequentially, SWIG director construction does not seem to happen sequentially " +
               "in practice, so the test is executed in a non thread-safe manner. We should fix this on the SWIG director code.",
        DisplayName = "CallbackLifetime global lock scales under heavy concurrency")]
    public async Task CallbackLifetime_Lock_Contention_Stress_V2()
    {
        using var logSystem = new LogSystem();

        const int operations = 10000;

        // STEP 1: create tasks sequentially (director construction is NOT thread-safe)
        var tasks = new List<Task>(operations);
        for (var i = 0; i < operations; i++)
        {
            tasks.Add(logSystem.LogAfterSecondsAsync(true, 0));
        }

        // STEP 2: measure execution + callback rooting
        var sw = Stopwatch.StartNew();

        await Task.WhenAll(tasks);

        sw.Stop();

        Assert.True(
            sw.ElapsedMilliseconds < 1500,
            $"Expected < 1500ms, actual: {sw.ElapsedMilliseconds}ms"
        );
    }

    

    [Fact(
        Skip = "This seems to fail due to swig director registration code not being thread safe, maybe worth investigating...",
        DisplayName = "CallbackLifetime survives GC under extreme async pressure")]
    public async Task CallbackLifetime_Survives_GC_Pressure_ExpectFailure()
    {
        using var logSystem = new LogSystem();

        const int operations = 5_000;

        Task[] tasks = Enumerable.Range(0, operations)
            .Select(_ => logSystem.LogAfterSecondsAsync(true, 0))
            .Cast<Task>()
            .ToArray();

        // Aggressively force GC while callbacks are pending
        for (var i = 0; i < 5; i++)
        {
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            await Task.Delay(10, TestContext.Current.CancellationToken);
        }

        await Task.WhenAll(tasks);
    }
    
    [Fact(
        Skip = "This never ends, potentially because the Parallel.ForEachAsync is challenging too much the swig director" +
               " registration code which does not seem to be thread safe, maybe worth investigating...",
        DisplayName = "CallbackLifetime scales with bounded async concurrency")]
    public async Task CallbackLifetime_BoundedConcurrency()
    {
        using var logSystem = new LogSystem();

        const int operations = 10_000;
        const int maxConcurrency = 64;

        var sw = Stopwatch.StartNew();

        await Parallel.ForEachAsync(
            Enumerable.Range(0, operations),
            new ParallelOptions { MaxDegreeOfParallelism = maxConcurrency },
            async (_, _) =>
            {
                await logSystem.LogAfterSecondsAsync(true, 0);
            });

        sw.Stop();

        Assert.True(
            sw.ElapsedMilliseconds < 1500,
            $"Expected < 1500ms, actual: {sw.ElapsedMilliseconds}ms"
        );
    }

    [Fact(
        Skip = "This seems to fail due to swig director registration code not being thread safe, maybe worth investigating...",
        DisplayName = "CallbackLifetime survives GC under async pressure")]
    public async Task CallbackLifetime_Survives_GC_Pressure()
    {
        using var logSystem = new LogSystem();

        const int operations = 5_000;

        var tasks = new List<Task>(operations);
        for (var i = 0; i < operations; i++)
        {
            tasks.Add(logSystem.LogAfterSecondsAsync(true, 0));
        }

        // Force GC while callbacks are alive
        for (var i = 0; i < 5; i++)
        {
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            await Task.Delay(10, TestContext.Current.CancellationToken);
        }

        await Task.WhenAll(tasks);
    }


    [Fact(DisplayName = "CallbackLifetime lock overhead is minimal")]
    public void CallbackLifetime_Lock_Overhead()
    {
        const int iterations = 1_000_000;

        var dummy = new object();

        var sw = Stopwatch.StartNew();

        Parallel.For(0, iterations, _ =>
        {
            ConnectedSpacesPlatformDotNet.CallbackLifetime.Root(dummy);
            ConnectedSpacesPlatformDotNet.CallbackLifetime.Unroot(dummy);
        });

        sw.Stop();

        // As long as this succeeds, we can keep a single container for all the callbacks pinning without performance concerns.
        Assert.True(
            sw.ElapsedMilliseconds < 500,
            $"Lock overhead too high: {sw.ElapsedMilliseconds}ms"
        );
    }


}
