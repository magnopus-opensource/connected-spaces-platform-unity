// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using NUnit.Framework;
using System;
using System.Collections;
using UnityEngine;

namespace Magnopus.OKO.Tests.Editor
{
    /// <summary>
    /// Static methods to allow for async testing in Unity 6 
    /// with reduced boilerplate.  These use the new Unity 
    /// <see cref="Awaitable"/>.
    /// </summary>
    public static class AsyncTest
    {
        /// <summary>
        /// Runs the test async test returning an <see cref="IEnumerator"/>
        /// so that the test can be run with the 
        /// <see cref="UnityEngine.TestTools.UnityTestAttribute"/>.
        /// <example>
        /// <code>
        /// [UnityTest]
        /// public IEnumerator TestedMethod_Scenario_ExpectedResult()
        ///    => AsyncTest.RunAsync(async () =>
        /// {
        ///     // Arrange
        ///     //...
        ///  
        ///     // Act
        ///     //Some Async Test Code...
        ///     await Task.Delay(1);
        ///  
        ///     // Assert
        ///     //...
        /// });
        /// </code>
        /// </example> 
        /// </summary>
        /// <param name="asyncTest">The func that represents the test being run.</param>
        /// <returns>An <see cref="IEnumerator"/> which can be run with the <see cref="UnityEngine.TestTools.UnityTestAttribute"/> which will return a failure if <paramref name="asyncTest"/> is null.</returns>
        public static IEnumerator RunAsync(Func<Awaitable> asyncTest)
        {
            if (asyncTest is null)
            {
                Assert.Fail($"The test function was null.");
            }
            return asyncTest();
        }

        /// <summary>
        /// Runs the test async test with a return type of <typeparamref name="TResult"/> 
        /// returning an <see cref="IEnumerator"/>
        /// so that the test can be run with the 
        /// <see cref="UnityEngine.TestTools.UnityTestAttribute"/>.
        /// The return is tested for equality against the <paramref name="expectedResult"/>
        /// failing the test if the result is not as expected.
        /// <example>
        /// <code>
        /// [UnityTest]
        /// public IEnumerator TestedMethod_Scenario_ReturnsExpectedValue()
        ///   => AsyncTest.RunWithResultAsync&lt;string&gt;("ExpectedResult", async () =>
        /// {
        ///     // Arrange
        ///     var testedClass = new TestedClass();
        /// 
        ///     // Act
        ///     //Some Async Test Code...
        ///     string result = await testedClass.Method();
        /// 
        ///     // Assert
        ///     return result;
        /// });
        /// </code>
        /// </example> 
        /// </summary>
        /// <typeparam name="TResult">The type of result that the test returns.</typeparam>
        /// <param name="expectedResult">The expected result from running the test.</param>
        /// <param name="asyncTest">The func that represents the test being run.</param>
        /// <returns>An <see cref="IEnumerator"/> which can be run with the <see cref="UnityEngine.TestTools.UnityTestAttribute"/> which will return a failure if <paramref name="asyncTest"/> is null or the result of the test is not as expected.</returns>
        public static IEnumerator RunWithResultAsync<TResult>(
            TResult expectedResult,
            Func<Awaitable<TResult>> asyncTest)
        => AssertResultAsync(expectedResult, asyncTest);

        /// <summary>
        /// Runs the test async test returning an <see cref="IEnumerator"/>
        /// so that the test can be run with the 
        /// <see cref="UnityEngine.TestTools.UnityTestAttribute"/> where 
        /// the test is expected to throw an exception of <see cref="TException"/>
        /// if the type does not match the test will fail.
        /// <example>
        /// <code>
        /// [UnityTest]
        /// public IEnumerator TestedMethod_Scenario_Throws()
        ///    => AsyncTest.ThrowsAsync&lt;InvalidOperationException&gt;(async () =>
        /// {
        ///     // Arrange
        ///     var testedClass = new TestedClass();
        /// 
        ///     // Act
        ///     //Some Async Test Code which throws...
        ///     await testedClass.MethodThatThrowsAsync();
        /// 
        ///     // Assert
        ///     // Throws
        /// });
        /// </code>
        /// </example> 
        /// </summary>
        /// <typeparam name="TException">The type of exception that is expected to be returned when <paramref name="asyncTest"/> is invoked.</typeparam>
        /// <param name="asyncTest">The func that represents the test being run.</param>
        /// <returns>An <see cref="IEnumerator"/> which can be run with the <see cref="UnityEngine.TestTools.UnityTestAttribute"/> which will return a failure if <paramref name="asyncTest"/> is null or the exception thrown by invoking <paramref name="asyncTest"/> is not of the type <typeparamref name="TException"/>.</returns>
        
        public static IEnumerator ThrowsAsync<TException>(Func<Awaitable> asyncTest)
            => AssertThrowsAsync<TException>(asyncTest);

        private static async Awaitable AssertResultAsync<TResult>(
            TResult expectedResult,
            Func<Awaitable<TResult>> asyncTest)
        {
            if (asyncTest is null)
            {
                Assert.Fail($"The test function was null.");
            }
            TResult result = await asyncTest();
            Assert.AreEqual(expectedResult, result, "The result of the test was not equal to the expected value.");
        }

        private static async Awaitable AssertThrowsAsync<TException>(Func<Awaitable> asyncTest)
        {
            if (asyncTest is null)
            {
                Assert.Fail($"The test function was null.");
            }
            Exception exception = null;

            try
            {
                await asyncTest();
            }
            catch (Exception caughtException)
            {
                exception = caughtException;
            }
            Assert.IsInstanceOf(typeof(TException), exception);
        }
    }
}
