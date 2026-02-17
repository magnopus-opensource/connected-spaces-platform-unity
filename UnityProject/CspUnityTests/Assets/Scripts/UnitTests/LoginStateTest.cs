// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using NUnit.Framework;

using LoginState = csp.common.LoginState;
using ELoginState = csp.common.ELoginState;

namespace Magnopus.Csp.Unity.Tests
{
    public class UserSchemaTests
    {
#if UNITY_EDITOR
        [Test]
        public void CreateLoginState()
        {
            const string userId = "12345";
            const string deviceId = "67890";
            const ELoginState state = ELoginState.LoggedIn;
            
            using var loginState = new LoginState();
            loginState.UserId = userId;
            loginState.DeviceId = deviceId;
            loginState.State = state;

            Assert.NotNull(loginState);
            Assert.IsTrue(loginState.UserId == userId);
            Assert.IsTrue(loginState.DeviceId == deviceId);
            Assert.IsTrue(loginState.State == state);
        }
#endif
    }
}