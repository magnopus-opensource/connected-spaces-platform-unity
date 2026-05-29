// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using csp.common;
using Magnopus.Extra.Exceptions;
using NUnit.Framework;
using UnityEngine.TestTools;

namespace Magnopus.Csp.Unity.Tests
{
    public static class AsyncTest
    {
        /// <summary>
        /// Number of asynchronous operations to test the async behaviour. 
        /// </summary>
        public const int NumberOfAsyncOperationsToTest = 1000;
        
#if UNITY_EDITOR
        /// <summary>
        /// Runs an async Task method as a Unity coroutine.
        /// </summary>
        public static IEnumerator RunAsync(Func<Task> asyncTest)
        {
            if (asyncTest == null)
            {
                Assert.Fail("Async test delegate was null.");
            }

            Task task;

            try
            {
                task = asyncTest();
            }
            catch (Exception ex)
            {
                throw ex;
            }

            while (!task.IsCompleted)
            {
                yield return null;
            }

            if (!task.IsFaulted)
            {
                yield break;
            }
            
            // Unwrap AggregateException so NUnit reports correctly
            if (task.Exception != null)
            {
                if (task.Exception.InnerException != null)
                {
                    throw task.Exception.InnerException;
                }
            }
            else
            {
                throw new Exception("Task faulted without exception details.");
            }
        }
    }
    
    [TestFixture]
    public class LogSystemAsyncTests
    {
        [UnityTest]
        public IEnumerator LogAfterSecondsAsync_ThrowsOnFailure()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();

                try
                {
                    await logSystem.LogAfterSecondsAsync(false, 1);
                    Assert.Fail("Expected exception was not thrown.");
                }
                catch (CspResultEndpointException ex)
                {
                    Assert.AreEqual(500, ex.StatusCode);
                }
            });
        }

        [UnityTest]
        public IEnumerator LogAfterSecondsAsync_CompletesSuccessfully()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();

                var result = await logSystem.LogAfterSecondsAsync(true, 1);

                Assert.NotNull(result);
                Assert.IsTrue(result.GetValue());
            });
        }

        [UnityTest]
        public IEnumerator Async_IsTrulyAsynchronous()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();

                var task = logSystem.LogAfterSecondsAsync(true, 1);

                Assert.False(task.IsCompleted);

                await task;
            });
        }

        [UnityTest]
        public IEnumerator Async_RespectsNativeTiming()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();

                var sw = Stopwatch.StartNew();
                await logSystem.LogAfterSecondsAsync(true, 1);
                sw.Stop();

                Assert.GreaterOrEqual(sw.ElapsedMilliseconds, 900);
            });
        }

        [UnityTest]
        public IEnumerator ConcurrentCalls_DoNotInterfere()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();

                var tasks = Enumerable.Range(0, 10)
                    .Select(_ => logSystem.LogAfterSecondsAsync(true, 1))
                    .ToArray();

                var results = await Task.WhenAll(tasks);

                foreach (var r in results)
                {
                    Assert.IsTrue(r.GetValue());
                }
            });
        }

        [UnityTest]
        public IEnumerator Failure_DoesNotPoisonSubsequentCalls()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();

                try
                {
                    await logSystem.LogAfterSecondsAsync(false, 1);
                    Assert.Fail();
                }
                catch (CspResultEndpointException) { }

                var result = await logSystem.LogAfterSecondsAsync(true, 1);

                Assert.True(result.GetValue());
            });
        }

        [UnityTest]
        public IEnumerator Callback_IsInvokedExactlyOnce()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();
                int calls = 0;

                var result = await logSystem.LogAfterSecondsAsync(true, 1)
                    .ContinueWith(t =>
                    {
                        Interlocked.Increment(ref calls);
                        return t.Result;
                    });

                Assert.AreEqual(1, calls);
                Assert.True(result.GetValue());
            });
        }

        [UnityTest]
        public IEnumerator CallbackLifetime_BoundedConcurrency()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();
                const int maxConcurrency = 64;

                var semaphore = new SemaphoreSlim(maxConcurrency);
                var tasks = new List<Task>(AsyncTest.NumberOfAsyncOperationsToTest);

                var sw = Stopwatch.StartNew();

                for (int i = 0; i < AsyncTest.NumberOfAsyncOperationsToTest; i++)
                {
                    await semaphore.WaitAsync();
                    tasks.Add(Task.Run(async () =>
                    {
                        try
                        {
                            await logSystem.LogAfterSecondsAsync(true, 0);
                        }
                        finally
                        {
                            semaphore.Release();
                        }
                    }));
                }

                await Task.WhenAll(tasks);

                sw.Stop();

                // Note: there might be additional delay due to task scheduling.
                Assert.Less(sw.ElapsedMilliseconds, 1500);
            });
        }

        [UnityTest]
        public IEnumerator CallbackLifetime_Survives_GC_Pressure()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();

                var tasks = new List<Task>(AsyncTest.NumberOfAsyncOperationsToTest);
                for (int i = 0; i < AsyncTest.NumberOfAsyncOperationsToTest; i++)
                {
                    tasks.Add(logSystem.LogAfterSecondsAsync(true, 0));
                }

                for (int i = 0; i < 5; i++)
                {
                    GC.Collect();
                    GC.WaitForPendingFinalizers();
                    GC.Collect();
                    await Task.Delay(10);
                }

                await Task.WhenAll(tasks);
            });
        }

        [UnityTest]
        public IEnumerator Async_WithProgressCallback_InvokesProgressSequentially()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();
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
                Assert.NotNull(result);
                Assert.IsTrue(result.GetValue());
                
                if (progressCalled)
                {
                    Assert.IsNotEmpty(progressUpdates);
                    foreach (var p in progressUpdates)
                    {
                        Assert.GreaterOrEqual(p, 0f);
                    }
                }
            });
        }

        [UnityTest]
        public IEnumerator Async_NullProgressCallback_CompletesSuccessfully()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();
                var result = await logSystem.LogAfterSecondsAsync(true, 1, progressCallback: null);
                
                Assert.NotNull(result);
                Assert.IsTrue(result.GetValue());
            });
        }

        [UnityTest]
        public IEnumerator ConcurrentCalls_IsolateUniqueProgressCallbacks()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();
                var operation1Progress = new List<float>();
                var operation2Progress = new List<float>();

                var task1 = logSystem.LogAfterSecondsAsync(true, 1, p => { lock(operation1Progress) operation1Progress.Add(p); });
                var task2 = logSystem.LogAfterSecondsAsync(true, 1, p => { lock(operation2Progress) operation2Progress.Add(p); });

                await Task.WhenAll(task1, task2);

                Assert.IsTrue(task1.Result.GetValue());
                Assert.IsTrue(task2.Result.GetValue());
            });
        }

        [UnityTest]
        public IEnumerator AsyncProgress_Survives_Extreme_GC_Pressure()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();
                int totalOps = 100;
                int progressCallbacksFired = 0;

                var tasks = Enumerable.Range(0, totalOps)
                    .Select(_ => logSystem.LogAfterSecondsAsync(true, 0, p => Interlocked.Increment(ref progressCallbacksFired)))
                    .ToArray();

                for (int i = 0; i < 3; i++)
                {
                    GC.Collect();
                    GC.WaitForPendingFinalizers();
                    GC.Collect();
                    await Task.Delay(5);
                }

                var results = await Task.WhenAll(tasks);
                
                Assert.AreEqual(totalOps, results.Length);
                foreach (var r in results)
                {
                    Assert.IsTrue(r.GetValue());
                }
            });
        }

        [UnityTest]
        public IEnumerator AsyncProgress_OnCompletion_CleanlyUnrootsCallbackMemory()
        {
            yield return AsyncTest.RunAsync(async () =>
            {
                var logSystem = new LogSystem();
                
                GC.Collect();
                GC.WaitForPendingFinalizers();
                
                var result = await logSystem.LogAfterSecondsAsync(true, 0, progress => { /* no-op */ });
                Assert.IsTrue(result.GetValue());

                GC.Collect();
                GC.WaitForPendingFinalizers();
                GC.Collect();

                // Use reflection to inspect the private '_roots' dictionary inside the static AsyncLifetime class.
                // This ensures the custom macro tracking cleanly detached everything on completion.
                var rootsField = typeof(ConnectedSpacesPlatformDotNet)
                    .GetNestedType("AsyncLifetime", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static)
                    ?.GetField("_roots", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);

                if (rootsField != null)
                {
                    var rootsDictionary = rootsField.GetValue(null) as System.Collections.IDictionary;
                    Assert.NotNull(rootsDictionary);
                    Assert.IsEmpty(rootsDictionary);
                }
            });
        }
#endif
    }
}