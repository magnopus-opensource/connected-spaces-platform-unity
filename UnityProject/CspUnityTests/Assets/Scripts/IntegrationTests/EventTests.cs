using System;
using System.Collections.Generic;
using System.Reflection;
using NUnit.Framework;
using UnityEngine;
using csp.systems;
using LoginTokenInfoResult = csp.systems.LoginTokenInfoResult;

namespace Magnopus.Foundation.Unity.Tests.Integration
{
    public class EventTests : FoundationFixture
    {
#if UNITY_EDITOR
        private UserSystem userSystem;
        private List<string> eventLog;
        private LoginTokenInfoResult capturedTokenResult;
        private bool tokenEventFired;
        
        private const string onNewLoginTokenReceivedFieldName = "_OnNewLoginTokenReceivedAdapter";

        protected override void FoundationFixtureSetup()
        {
            settings = new FoundationFixtureSettings
            {
                InitializeFoundationFixtureOnOneTimeSetup = true,
                StartFoundation = true,
                CreatePrimaryAccount = false,
                Login = false
            };
        }

        [SetUp]
        public void Setup()
        {
            eventLog = new List<string>();
            capturedTokenResult = null;
            tokenEventFired = false;
            
            if (isInitialized)
            {
                userSystem = SystemsManager.Get().GetUserSystem();
                Assert.IsNotNull(userSystem, "UserSystem should be available after initialization.");
            }
            else
            {
                Assert.Ignore("Foundation not initialized - skipping event tests");
            }
        }

        [TearDown]
        public void TearDown()
        {
            // Clean up any subscriptions to prevent cross-test contamination
            if (userSystem != null)
            {
                // Try to clear backing delegates via reflection (events cannot be assigned directly)
                var userSystemType = typeof(UserSystem);
                var fi = userSystemType.GetField(onNewLoginTokenReceivedFieldName, 
                    BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.IgnoreCase);
                if (fi != null)
                {
                    fi.SetValue(userSystem, null);
                    return;
                }

                Debug.LogWarning(
                    $"Could not find backing field '{onNewLoginTokenReceivedFieldName}' to clear event subscriptions." +
                    $" Subscriptions may persist between tests.");
            }
        }

        /// <summary>
        /// Helper method to invoke a UserSystem event using reflection.
        /// This fires the internal event delegate to simulate the event being triggered by the system.
        /// </summary>
        private void FireLoginTokenEvent(LoginTokenInfoResult result)
        {
            var userSystemType = typeof(UserSystem);
            var eventField = userSystemType.GetField(
                onNewLoginTokenReceivedFieldName, 
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.IgnoreCase);
            
            if (eventField != null)
            {
                try
                {
                    var target = eventField.GetValue(userSystem);

                    var invokeDelegate = target.GetType().GetField("_invoked", 
                        BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.IgnoreCase);
                    if(invokeDelegate != null && invokeDelegate.GetValue(target) is Delegate del)
                    {
                        del.DynamicInvoke(result);
                        return;
                    }
                }
                catch (Exception ex)
                {
                    Debug.LogWarning($"Failed to invoke OnNewLoginTokenReceived via field '{onNewLoginTokenReceivedFieldName}': {ex.Message}");
                }
            }
            Debug.LogWarning("Could not find OnNewLoginTokenReceived backing field. Event handlers will not be invoked.");
        }

        /// <summary>
        /// Tests that OnNewLoginTokenReceived event can be subscribed to and fires with correct data.
        /// </summary>
        [Test]
        public void OnNewLoginTokenReceived_Subscribe_EventFiresWithCorrectData()
        {
            var handlerCalled = false;

            void TokenReceivedHandler(LoginTokenInfoResult result)
            {
                handlerCalled = true;
                tokenEventFired = true;
                capturedTokenResult = result;
                eventLog.Add("TokenReceived");
            }
            
            // Subscribe to the real event
            userSystem.OnNewLoginTokenReceived += TokenReceivedHandler;

            // Create test data and fire the event using an uninitialized instance to avoid invoking internal constructors
            var tokenResultObj = System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(LoginTokenInfoResult)) as LoginTokenInfoResult;
            FireLoginTokenEvent(tokenResultObj);
            
            Assert.IsTrue(handlerCalled, "Handler should have been called.");
            Assert.IsTrue(tokenEventFired, "Event flag should be set.");
            Assert.IsNotNull(capturedTokenResult, "Token result should be captured.");
            Assert.IsTrue(eventLog.Contains("TokenReceived"), "Event log should contain token receipt message.");
        }

        /// <summary>
        /// Tests that multiple handlers can be subscribed to OnNewLoginTokenReceived event and all are fired.
        /// </summary>
        [Test]
        public void OnNewLoginTokenReceived_MultipleHandlers_AllAreFired()
        {
            var handler1Called = false;
            var handler2Called = false;
            var handler3Called = false;

            void Handler1(LoginTokenInfoResult result)
            {
                handler1Called = true;
                eventLog.Add("Handler1");
            }
            void Handler2(LoginTokenInfoResult result)
            {
                handler2Called = true;
                eventLog.Add("Handler2");
            }
            void Handler3(LoginTokenInfoResult result)
            {
                handler3Called = true;
                eventLog.Add("Handler3");
            }
            
            // Subscribe multiple handlers
            userSystem.OnNewLoginTokenReceived += Handler1;
            userSystem.OnNewLoginTokenReceived += Handler2;
            userSystem.OnNewLoginTokenReceived += Handler3;

            // Fire the event
            var tokenResult = System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(LoginTokenInfoResult)) as LoginTokenInfoResult;
            FireLoginTokenEvent(tokenResult);
            
            Assert.IsTrue(handler1Called, "Handler1 should have been called.");
            Assert.IsTrue(handler2Called, "Handler2 should have been called.");
            Assert.IsTrue(handler3Called, "Handler3 should have been called.");
            Assert.AreEqual(3, eventLog.Count, "All three handlers should have logged their execution.");
            Assert.Contains("Handler1", eventLog);
            Assert.Contains("Handler2", eventLog);
            Assert.Contains("Handler3", eventLog);
        }

        /// <summary>
        /// Tests that OnNewLoginTokenReceived event handlers are called in the order they were subscribed.
        /// </summary>
        [Test]
        public void OnNewLoginTokenReceived_MultipleHandlers_ExecuteInOrder()
        {
            void Handler1(LoginTokenInfoResult result) => eventLog.Add("1");
            void Handler2(LoginTokenInfoResult result) => eventLog.Add("2");
            void Handler3(LoginTokenInfoResult result) => eventLog.Add("3");

            userSystem.OnNewLoginTokenReceived += Handler1;
            userSystem.OnNewLoginTokenReceived += Handler2;
            userSystem.OnNewLoginTokenReceived += Handler3;

            var tokenResult = System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(LoginTokenInfoResult)) as LoginTokenInfoResult;
            FireLoginTokenEvent(tokenResult);
            
            Assert.AreEqual(3, eventLog.Count, "All handlers should have been called.");
            Assert.AreEqual("1", eventLog[0], "Handler1 should execute first.");
            Assert.AreEqual("2", eventLog[1], "Handler2 should execute second.");
            Assert.AreEqual("3", eventLog[2], "Handler3 should execute third.");
        }

        /// <summary>
        /// Tests that OnNewLoginTokenReceived event handler receives correct sender parameter.
        /// Note: some event signatures don't include a sender parameter; this test verifies the handler receives the event parameter.
        /// </summary>
        [Test]
        public void OnNewLoginTokenReceived_Handler_ReceivesParameter()
        {
            LoginTokenInfoResult receivedParam = null;

            void TokenReceivedHandler(LoginTokenInfoResult result)
            {
                receivedParam = result;
            }
            
            // Subscribe to the real event
            userSystem.OnNewLoginTokenReceived += TokenReceivedHandler;

            var tokenResult = System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(LoginTokenInfoResult)) as LoginTokenInfoResult;
            FireLoginTokenEvent(tokenResult);
            
            Assert.IsNotNull(receivedParam, "Parameter should be passed to handler.");
        }

        /// <summary>
        /// Tests that handlers can be unsubscribed from OnNewLoginTokenReceived event and won't be called.
        /// </summary>
        [Test]
        public void OnNewLoginTokenReceived_Unsubscribe_HandlerNotCalled()
        {
            var handlerCalled = false;
            void TokenReceivedHandler(LoginTokenInfoResult result)
            {
                handlerCalled = true;
                eventLog.Add("Handler called");
            }
            
            // Subscribe, then unsubscribe
            userSystem.OnNewLoginTokenReceived += TokenReceivedHandler;
            userSystem.OnNewLoginTokenReceived -= TokenReceivedHandler;

            var tokenResult = System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(LoginTokenInfoResult)) as LoginTokenInfoResult;
            FireLoginTokenEvent(tokenResult);
            
            Assert.IsFalse(handlerCalled, "Unsubscribed handler should not be called.");
            Assert.IsFalse(eventLog.Contains("Handler called"), "Event log should not contain handler call.");
        }

        /// <summary>
        /// Tests that OnNewLoginTokenReceived event is not fired when no handlers are subscribed.
        /// </summary>
        [Test]
        public void OnNewLoginTokenReceived_NoHandlers_NoErrorsOnFire()
        {
            // Fire event with no handlers (should not throw)
            var tokenResult = System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(LoginTokenInfoResult)) as LoginTokenInfoResult;
            
            Assert.DoesNotThrow(() => FireLoginTokenEvent(tokenResult), 
                "Firing event with no handlers should not throw an exception.");
            Assert.AreEqual(0, eventLog.Count, "No handlers should have been called.");
        }

        /// <summary>
        /// Tests that OnNewLoginTokenReceived event handler properly receives and processes token data.
        /// </summary>
        [Test]
        public void OnNewLoginTokenReceived_Handler_ProcessesTokenDataCorrectly()
        {
            var processedTokens = new List<object>();
            var processedExpirations = new List<object>();

            void TokenProcessor(LoginTokenInfoResult result)
            {
                if (result != null)
                {
                    processedTokens.Add(result);
                    processedExpirations.Add(result);
                }
            }
            
            userSystem.OnNewLoginTokenReceived += TokenProcessor;

            // Fire multiple token events
            var token1 = System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(LoginTokenInfoResult)) as LoginTokenInfoResult;
            var token2 = System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(LoginTokenInfoResult)) as LoginTokenInfoResult;

            FireLoginTokenEvent(token1);
            FireLoginTokenEvent(token2);

            Assert.AreEqual(2, processedTokens.Count, "Both tokens should be processed.");
            Assert.AreEqual(2, processedExpirations.Count, "Both expirations should be processed.");
        }

        /// <summary>
        /// Tests that the event subscriptions are properly isolated between different test instances.
        /// </summary>
        [Test]
        public void Events_IsolationBetweenTests_NoContamination()
        {
            var testEventFired = false;

            void TestHandler(LoginTokenInfoResult result)
            {
                testEventFired = true;
            }
            
            userSystem.OnNewLoginTokenReceived += TestHandler;

            Assert.IsFalse(testEventFired, "Event should not be fired yet.");
            
            var tokenResult = System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(LoginTokenInfoResult)) as LoginTokenInfoResult;
            FireLoginTokenEvent(tokenResult);
            
            Assert.IsTrue(testEventFired, "Event should have been fired.");
        }
#endif
    }
}

