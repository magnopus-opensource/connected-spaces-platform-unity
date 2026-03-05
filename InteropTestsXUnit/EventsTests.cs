using System.Reflection;
using csp;
using csp.systems;
using LoginTokenInfoResult = csp.systems.LoginTokenInfoResult;

namespace InteropTestsXUnit
{
    public class EventTests : IDisposable
    {
        private readonly UserSystem _userSystem;
        private readonly List<string> _eventLog;
        private LoginTokenInfoResult? _capturedTokenResult;
        private bool _tokenEventFired;

        private const string OnNewLoginTokenReceivedFieldName = "_OnNewLoginTokenReceivedAdapter";

        public EventTests()
        {
            // Every test here initializes CSP.
            ClientUserAgent userAgent = new ClientUserAgent();
            userAgent.CSPVersion = "Unknown";
            userAgent.ClientOS = "Unknown";
            userAgent.ClientSKU = "CSharp-Interop";
            userAgent.ClientVersion = "Unknown";
            userAgent.ClientEnvironment = "ODev";
            userAgent.CHSEnvironment = "oDev";
            var result = CSPFoundation.Initialise("https://ogs-internal.magnopus-dev.cloud", "OKO_TESTS", userAgent, null);
            Assert.True(result);
            
            _eventLog = new List<string>();
            _capturedTokenResult = null;
            _tokenEventFired = false;
            
            _userSystem = SystemsManager.Get().GetUserSystem();
            Assert.NotNull(_userSystem);
        }
        
        public void Dispose()
        {
            var userSystemType = typeof(UserSystem);
            var fi = userSystemType.GetField(
                OnNewLoginTokenReceivedFieldName,
                BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.IgnoreCase);

            fi?.SetValue(_userSystem, null);

            // Every test shuts down CSP when it's done
            var result = CSPFoundation.Shutdown();
            Assert.True(result);
        }

        /// <summary>
        /// Helper method to invoke the internal login token event.
        /// </summary>
        private void FireLoginTokenEvent(LoginTokenInfoResult result)
        {
            var userSystemType = typeof(UserSystem);

            var eventField = userSystemType.GetField(
                OnNewLoginTokenReceivedFieldName,
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.IgnoreCase);

            if (eventField == null)
                return;

            var target = eventField.GetValue(_userSystem);
            if (target == null)
                return;

            var invokeDelegate = target.GetType().GetField(
                "_invoked",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.IgnoreCase);

            if (invokeDelegate?.GetValue(target) is Delegate del)
            {
                del.DynamicInvoke(result);
            }
        }

        [Fact]
        public void OnNewLoginTokenReceived_Subscribe_EventFiresWithCorrectData()
        {
            var handlerCalled = false;
            _eventLog.Clear();

            void TokenReceivedHandler(LoginTokenInfoResult result)
            {
                handlerCalled = true;
                _tokenEventFired = true;
                _capturedTokenResult = result;
                _eventLog.Add("TokenReceived");
            }

            _userSystem.OnNewLoginTokenReceived += TokenReceivedHandler;

            var tokenResult = new LoginTokenInfoResult(1, false);

            FireLoginTokenEvent(tokenResult);

            Assert.True(handlerCalled);
            Assert.True(_tokenEventFired);
            Assert.NotNull(_capturedTokenResult);
            Assert.Contains("TokenReceived", _eventLog);
        }

        [Fact]
        public void OnNewLoginTokenReceived_MultipleHandlers_AllAreFired()
        {
            var handler1Called = false;
            var handler2Called = false;
            var handler3Called = false;
            _eventLog.Clear();

            void Handler1(LoginTokenInfoResult result)
            {
                handler1Called = true;
                _eventLog.Add("Handler1");
            }

            void Handler2(LoginTokenInfoResult result)
            {
                handler2Called = true;
                _eventLog.Add("Handler2");
            }

            void Handler3(LoginTokenInfoResult result)
            {
                handler3Called = true;
                _eventLog.Add("Handler3");
            }

            _userSystem.OnNewLoginTokenReceived += Handler1;
            _userSystem.OnNewLoginTokenReceived += Handler2;
            _userSystem.OnNewLoginTokenReceived += Handler3;

            var tokenResult = new LoginTokenInfoResult(1, false);

            FireLoginTokenEvent(tokenResult);

            Assert.True(handler1Called);
            Assert.True(handler2Called);
            Assert.True(handler3Called);
            Assert.Equal(3, _eventLog.Count);
            Assert.Contains("Handler1", _eventLog);
            Assert.Contains("Handler2", _eventLog);
            Assert.Contains("Handler3", _eventLog);
            
            _userSystem.OnNewLoginTokenReceived -= Handler3;
            _userSystem.OnNewLoginTokenReceived -= Handler2;
            _userSystem.OnNewLoginTokenReceived -= Handler1;
        }

        [Fact]
        public void OnNewLoginTokenReceived_MultipleHandlers_ExecuteInOrder()
        {
            _eventLog.Clear();
            
            void Handler1(LoginTokenInfoResult result) => _eventLog.Add("1");
            void Handler2(LoginTokenInfoResult result) => _eventLog.Add("2");
            void Handler3(LoginTokenInfoResult result) => _eventLog.Add("3");

            _userSystem.OnNewLoginTokenReceived += Handler1;
            _userSystem.OnNewLoginTokenReceived += Handler2;
            _userSystem.OnNewLoginTokenReceived += Handler3;

            var tokenResult = new LoginTokenInfoResult(1, false);

            FireLoginTokenEvent(tokenResult);

            Assert.Equal(3, _eventLog.Count);
            Assert.Equal("1", _eventLog[0]);
            Assert.Equal("2", _eventLog[1]);
            Assert.Equal("3", _eventLog[2]);
            
            _userSystem.OnNewLoginTokenReceived -= Handler3;
            _userSystem.OnNewLoginTokenReceived -= Handler2;
            _userSystem.OnNewLoginTokenReceived -= Handler1;
        }

        [Fact]
        public void OnNewLoginTokenReceived_Unsubscribe_HandlerNotCalled()
        {
            var handlerCalled = false;
            _eventLog.Clear();

            void Handler(LoginTokenInfoResult result)
            {
                handlerCalled = true;
                _eventLog.Add("Handler called");
            }

            _userSystem.OnNewLoginTokenReceived += Handler;
            _userSystem.OnNewLoginTokenReceived -= Handler;

            var tokenResult = new LoginTokenInfoResult(1, false);

            FireLoginTokenEvent(tokenResult);

            Assert.False(handlerCalled);
            Assert.DoesNotContain("Handler called", _eventLog);
        }

        [Fact]
        public void OnNewLoginTokenReceived_NoHandlers_NoErrorsOnFire()
        {
            _eventLog.Clear();
            var tokenResult = new LoginTokenInfoResult(1, false);

            FireLoginTokenEvent(tokenResult);

            Assert.Empty(_eventLog);
        }

        [Fact]
        public void OnNewLoginTokenReceived_Handler_ProcessesTokenDataCorrectly()
        {
            _eventLog.Clear();
            var processed = new List<object>();

            void Processor(LoginTokenInfoResult result)
            {
                processed.Add(result);
            }

            _userSystem.OnNewLoginTokenReceived += Processor;

            var token1 = new LoginTokenInfoResult(1, false);
            var token2 = new LoginTokenInfoResult(2, false);

            FireLoginTokenEvent(token1);
            FireLoginTokenEvent(token2);

            Assert.Equal(2, processed.Count);
            
            _userSystem.OnNewLoginTokenReceived -= Processor;
        }
    }
}