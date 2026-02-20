// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.OKO.Tests.Editor;
using System;
using System.Collections;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.TestTools;

namespace Magnopus.Foundation.Unity.Tests.Integration
{
    public class AsyncTestTests
    {
        [UnityTest]
        public IEnumerator TestRunAsyncTask()
        {
            Func<Awaitable> asyncTest = async () =>
            {
                await Task.Delay(1);
            };
            yield return asyncTest;
        }

        [UnityTest]
        public IEnumerator TestRunAsyncFunction() => AsyncTest.RunAsync(async () =>
        {
            await Task.Delay(1);
        });

        [UnityTest]
        public IEnumerator TestThrowsAsync() => AsyncTest.ThrowsAsync<InvalidOperationException>(async () =>
        {
            await Task.Delay(1);
            throw new InvalidOperationException();
        });
    }
}