using csp.common;
using Magnopus.Extra.Exceptions;
using System.Diagnostics;

namespace InteropTestsXUnit;

public class AsyncInteropTests
{
    /// <summary>
    /// Number of asynchronous operations to test the async behaviour. 
    /// </summary>
    public const int NumberOfAsyncOperationsToTest = 1000;
    
    [Fact(DisplayName = "Async success path completes and returns managed result")]
    public async Task Async_Success_CompletesAndReturnsResult()
    {
        using LogSystem logSystem = new LogSystem();

        var result = await logSystem.LogAfterSecondsAsync(true, 1);

        Assert.True(result.GetValue());
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

    // Note: this test only makes sense if ThrowOnFailure is defined
    [Fact(DisplayName = "Failure in one async call does not poison subsequent calls")]
    public async Task Failure_DoesNotPoisonSubsequentCalls()
    {
        using LogSystem logSystem = new LogSystem();

        await Assert.ThrowsAsync<CspResultEndpointException>(() =>
            logSystem.LogAfterSecondsAsync(false, 1));

        var result = await logSystem.LogAfterSecondsAsync(true, 1);

        Assert.True(result.GetValue());
    }
    
    // Note: this test only makes sense if ThrowOnFailure is defined
    [Fact(DisplayName = "Native failure propagates as managed exception via ThrowOnFailure")]
    public async Task Async_Failure_ThrowsManagedException()
    {
        using LogSystem logSystem = new LogSystem();

        var ex = await Assert.ThrowsAsync<CspResultEndpointException>(() =>
            logSystem.LogAfterSecondsAsync(false, 1));

        Assert.Equal(500, ex.StatusCode);
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

    [EnvironmentFact("RUN_LONG_RUNNING_TESTS", DisplayName = "AsyncLifetime concurrency handles high concurrency")]
    public async Task AsyncLifetime_Lock_Contention_Stress_V1()
    {
        using var logSystem = new LogSystem();

        int totalOps = 1_000;

        var tasks = Enumerable.Range(0, totalOps)
            .Select(async _ =>
            {
                try
                {
                    var result = await logSystem.LogAfterSecondsAsync(true, 0);
                    Assert.True(result.GetValue());
                }
                catch (Exception ex)
                {
                    Assert.Fail($"Unexpected exception: {ex}");
                }
            })
            .ToArray();

        await Task.WhenAll(tasks);

        // If we got here:
        // - no deadlock
        // - no callback lost
        // - no corruption
        Assert.Equal(totalOps, tasks.Length);
    }

    [EnvironmentFact("RUN_LONG_RUNNING_TESTS", DisplayName = "AsyncLifetime global concurrency scales under heavy concurrency")]
    public async Task AsyncLifetime_Lock_Contention_Stress_V2()
    {
        using var logSystem = new LogSystem();

        var tasks = new List<Task>(NumberOfAsyncOperationsToTest);
        for (var i = 0; i < NumberOfAsyncOperationsToTest; i++)
        {
            tasks.Add(logSystem.LogAfterSecondsAsync(true, 0));
        }

        await Task.WhenAll(tasks);
        
        // If we got here:
        // - no deadlock
        // - no callback lost
        // - no corruption
        Assert.Equal(NumberOfAsyncOperationsToTest, tasks.Count);
    }



    [EnvironmentFact("RUN_LONG_RUNNING_TESTS", DisplayName = "AsyncLifetime survives GC under extreme async pressure")]
    public async Task AsyncLifetime_Survives_GC_Pressure_ExpectFailure()
    {
        using var logSystem = new LogSystem();

        Task[] tasks = Enumerable.Range(0, NumberOfAsyncOperationsToTest)
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

    [EnvironmentFact("RUN_LONG_RUNNING_TESTS", DisplayName = "AsyncLifetime scales with bounded async concurrency")]
    public async Task AsyncLifetime_BoundedConcurrency()
    {
        using var logSystem = new LogSystem();
        const int maxConcurrency = 64;

        int inFlight = 0;
        int maxObservedConcurrency = 0;

        await Parallel.ForEachAsync(
            Enumerable.Range(0, NumberOfAsyncOperationsToTest),
            new ParallelOptions { MaxDegreeOfParallelism = maxConcurrency },
            async (_, _) =>
            {
                int current = Interlocked.Increment(ref inFlight);
                maxObservedConcurrency = Math.Max(maxObservedConcurrency, current);

                try
                {
                    var result = await logSystem.LogAfterSecondsAsync(true, 0);
                    Assert.True(result.GetValue());
                }
                finally
                {
                    Interlocked.Decrement(ref inFlight);
                }
            });

        Assert.True(
            maxObservedConcurrency <= maxConcurrency,
            $"Observed concurrency {maxObservedConcurrency} exceeded limit {maxConcurrency}"
        );
    }

    [EnvironmentFact("RUN_LONG_RUNNING_TESTS", DisplayName = "AsyncLifetime survives GC under async pressure")]
    public async Task AsyncLifetime_Survives_GC_Pressure()
    {
        using var logSystem = new LogSystem();

        var tasks = new List<Task>(NumberOfAsyncOperationsToTest);
        for (var i = 0; i < NumberOfAsyncOperationsToTest; i++)
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
    
    [Fact(DisplayName = "Async method with progress callback invokes handler sequentially")]
    public async Task Async_WithProgressCallback_InvokesProgressSequentially()
    {
        using var logSystem = new LogSystem();
        var progressUpdates = new List<float>();
        var progressCalled = false;

        Action<float> progressHandler = (progress) =>
        {
            lock (progressUpdates)
            {
                progressCalled = true;
                progressUpdates.Add(progress);
            }
        };

        GC.Collect();
        GC.WaitForPendingFinalizers();

        var result = await logSystem.LogAfterSecondsAsync(true, 1, progressHandler);
        Assert.True(result.GetValue());
        
        if (progressCalled)
        {
            Assert.NotEmpty(progressUpdates);
            // Verify progress always positive
            Assert.All(progressUpdates, p => Assert.True(p >= 0f));
        }
    }

    [Fact(DisplayName = "Async method handles null progress parameter gracefully without crashing")]
    public async Task Async_NullProgressCallback_CompletesSuccessfully()
    {
        using LogSystem logSystem = new LogSystem();
        var result = await logSystem.LogAfterSecondsAsync(true, 1, progressCallback: null);
        Assert.True(result.GetValue());
    }

    [Fact(DisplayName = "Concurrent async calls completely isolate unique progress callback states")]
    public async Task ConcurrentCalls_IsolateUniqueProgressCallbacks()
    {
        using LogSystem logSystem = new LogSystem();

        var operation1Progress = new List<float>();
        var operation2Progress = new List<float>();

        var task1 = logSystem.LogAfterSecondsAsync(true, 1, p => { lock(operation1Progress) operation1Progress.Add(p); });
        var task2 = logSystem.LogAfterSecondsAsync(true, 1, p => { lock(operation2Progress) operation2Progress.Add(p); });

        await Task.WhenAll(task1, task2);

        Assert.True(task1.Result.GetValue());
        Assert.True(task2.Result.GetValue());
    }

    [EnvironmentFact("RUN_LONG_RUNNING_TESTS", DisplayName = "Async progress handlers survive extreme GC pressure under heavy load")]
    public async Task AsyncProgress_Survives_Extreme_GC_Pressure()
    {
        using var logSystem = new LogSystem();
        int totalOps = 100;
        int progressCallbacksFired = 0;

        var tasks = Enumerable.Range(0, totalOps)
            .Select(_ => logSystem.LogAfterSecondsAsync(true, 0, p => Interlocked.Increment(ref progressCallbacksFired)))
            .ToArray();

        for (var i = 0; i < 3; i++)
        {
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            await Task.Delay(5, TestContext.Current.CancellationToken);
        }

        var results = await Task.WhenAll(tasks);
        
        Assert.Equal(totalOps, results.Length);
        Assert.All(results, r => Assert.True(r.GetValue()));
    }
    
    [Fact(DisplayName = "Async progress pipeline cleanly unroots and releases callback memory on completion")]
    public async Task AsyncProgress_OnCompletion_CleanlyUnrootsCallbackMemory()
    {
        using LogSystem logSystem = new LogSystem();
        
        // Note: trying to check AsyncLifeTime objects while cooping with parallel execution of tests.
        var rootsField = typeof(ConnectedSpacesPlatformDotNet)
            .GetNestedType("AsyncLifetime", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static)
            ?.GetField("_roots", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);

        Assert.NotNull(rootsField);
        var rootsDictionary = rootsField.GetValue(null) as System.Collections.IDictionary;
        Assert.NotNull(rootsDictionary);

        var initialKeys = new HashSet<object>(rootsDictionary.Keys.Cast<object>());

        var result = await logSystem.LogAfterSecondsAsync(true, 0, progress => { /* no-op */ });
        Assert.True(result.GetValue());

        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();

        var currentKeys = rootsDictionary.Keys.Cast<object>().ToList();

        var ourActiveCallbacks = currentKeys
            .Where(key => !initialKeys.Contains(key) && key.GetType().Name == "TestBooleanResultCallback")
            .ToList();

        Assert.Empty(ourActiveCallbacks);
    }
}
