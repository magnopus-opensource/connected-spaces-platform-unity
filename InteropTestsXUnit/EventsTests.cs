using csp.common;

namespace InteropTestsXUnit
{
    /*
     * These tests test the generation of the event member variable from the `MAKE_EVENT_FOR_CALLBACK` macro.
     * Note that since events are based on top of the action adapters mechanisms, it might be redundant to test
     * the event firing itself, but for the time being it might be worth keeping these tests for a sanity check.
     */
    public class EventTests
    {
        [Fact]
        public void OnLogReceived_Subscribe_EventFiresWithCorrectData()
        {
            var handlerCalled = false;
            var logEventFired = false;
            var capturedLogEventMessage = string.Empty;

            void LogReceivedHandler(LogLevel level, string message)
            {
                handlerCalled = true;
                logEventFired = true;
                capturedLogEventMessage = message;
            }

            var logSystem = new LogSystem();
            logSystem.OnLogReceived += LogReceivedHandler;
            
            // Enforce GC to ensure the callback survives
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            
            logSystem.LogMsg(LogLevel.Log, "TestLogMessage");

            Assert.True(handlerCalled);
            Assert.True(logEventFired);
            Assert.NotEmpty(capturedLogEventMessage);
        }

        [Fact]
        public void OnLogReceived_MultipleHandlers_AllAreFired()
        {
            var handler1Called = false;
            var handler2Called = false;
            var handler3Called = false;
            var eventLog = new List<string>();

            void Handler1(LogLevel level, string message)
            {
                handler1Called = true;
                eventLog.Add("Handler1");
            }

            void Handler2(LogLevel level, string message)
            {
                handler2Called = true;
                eventLog.Add("Handler2");
            }

            void Handler3(LogLevel level, string message)
            {
                handler3Called = true;
                eventLog.Add("Handler3");
            }

            var logSystem = new LogSystem();
            logSystem.OnLogReceived += Handler1;
            logSystem.OnLogReceived += Handler2;
            logSystem.OnLogReceived += Handler3;
            
            // Enforce GC to ensure the callback survives
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();

            logSystem.LogMsg(LogLevel.Log, "TestLogMessage");

            Assert.True(handler1Called);
            Assert.True(handler2Called);
            Assert.True(handler3Called);
            Assert.Equal(3, eventLog.Count);
            Assert.Contains("Handler1", eventLog);
            Assert.Contains("Handler2", eventLog);
            Assert.Contains("Handler3", eventLog);
            
            logSystem.OnLogReceived -= Handler3;
            logSystem.OnLogReceived -= Handler2;
            logSystem.OnLogReceived -= Handler1;
        }

        [Fact]
        public void OnLogReceived_MultipleHandlers_ExecuteInOrder()
        {
            var eventLog = new List<string>();
            
            void Handler1(LogLevel level, string message) => eventLog.Add("1");
            void Handler2(LogLevel level, string message) => eventLog.Add("2");
            void Handler3(LogLevel level, string message) => eventLog.Add("3");

            var logSystem = new LogSystem();
            logSystem.OnLogReceived += Handler1;
            logSystem.OnLogReceived += Handler2;
            logSystem.OnLogReceived += Handler3;
            
            // Enforce GC to ensure the callback survives
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();

            logSystem.LogMsg(LogLevel.Log, "TestLogMessage");

            Assert.Equal(3, eventLog.Count);
            Assert.Equal("1", eventLog[0]);
            Assert.Equal("2", eventLog[1]);
            Assert.Equal("3", eventLog[2]);
            
            logSystem.OnLogReceived -= Handler3;
            logSystem.OnLogReceived -= Handler2;
            logSystem.OnLogReceived -= Handler1;
        }

        [Fact]
        public void OnLogReceived_Unsubscribe_HandlerNotCalled()
        {
            var handlerCalled = false;
            var eventLog = new List<string>();

            void Handler(LogLevel level, string message)
            {
                handlerCalled = true;
                eventLog.Add("Handler called");
            }

            var logSystem = new LogSystem();
            logSystem.OnLogReceived += Handler;
            
            // Enforce GC to ensure the callback survives
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            
            logSystem.OnLogReceived -= Handler;

            logSystem.LogMsg(LogLevel.Log, "TestLogMessage");

            Assert.False(handlerCalled);
            Assert.DoesNotContain("Handler called", eventLog);
        }

        [Fact]
        public void OnLogReceived_NoHandlers_NoErrorsOnFire()
        {
            var logSystem = new LogSystem();
            logSystem.LogMsg(LogLevel.Log, "TestLogMessage");
        }

        [Fact]
        public void OnLogReceived_Handler_ProcessesTokenDataCorrectly()
        {
            var processed = new List<object>();

            void Processor(LogLevel level, string message)
            {
                processed.Add(message);
            }

            var logSystem = new LogSystem();
            logSystem.OnLogReceived += Processor;
            
            // Enforce GC to ensure the callback survives
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();

            const string msg1 = "TestLogMessage1";
            const string msg2 = "TestLogMessage2";

            logSystem.LogMsg(LogLevel.Log, msg1);
            logSystem.LogMsg(LogLevel.Log, msg2);

            Assert.Equal(2, processed.Count);
            Assert.Equal(msg1, processed[0]);
            Assert.Equal(msg2, processed[1]);
            
            logSystem.OnLogReceived -= Processor;
        }

        [Fact]
        public void OnLogReceived_MultipleHandlers_ProcessesLogsCorrectly()
        {
            using LogSystem logSystem1 = new LogSystem();
            Assert.True(logSystem1 != null);
            using LogSystem logSystem2 = new LogSystem();
            Assert.True(logSystem2 != null);

            LogLevel? capturedLevel = null;
            string? capturedMessage = null;
            int timesCalled = 0;
            
            void Handler(LogLevel logLevel, string message)
            {
                capturedLevel = logLevel;
                capturedMessage = message;
                timesCalled++;
            };
            
            logSystem1.OnLogReceived += Handler;
            logSystem2.OnLogReceived += Handler;
            
            // Enforce GC to ensure callbacks survive
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();

            logSystem1.LogMsg(LogLevel.Log, "First call.");

            Assert.Equal(LogLevel.Log, capturedLevel);
            Assert.Equal("First call.", capturedMessage);
            Assert.Equal(1, timesCalled);

            logSystem2.LogMsg(LogLevel.Warning, "Second call.");

            Assert.Equal(LogLevel.Warning, capturedLevel);
            Assert.Equal("Second call.", capturedMessage);
            Assert.Equal(2, timesCalled);
        }
    }
}