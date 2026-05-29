// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;
using System.Collections;
using System.Net;
using System.Threading.Tasks;
using Magnopus.Extra.Exceptions;
using Magnopus.Foundation.Unity.Runtime.User;
using Magnopus.Foundation.Unity.Tests.Integration.Config;
using Magnopus.Foundation.Unity.Tests.Integration.Extensions;
using Magnopus.OKO.Tests.Editor;
using Magnopus.SessionState.Environment;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using LoginInfo = csp.common.LoginState;

namespace Magnopus.Foundation.Unity.Tests.Integration.User
{
    public class LoginTests : FoundationFixture
    {
        public struct LoginSuccessResult
        {
            public LoginInfo Info;
            public Exception Exception;

            public LoginSuccessResult(LoginInfo info, Exception exception)
            {
                Info = info;
                Exception = exception;
            }
        }
        
        private static TestUserProfile primaryUserStatic;
        private static TestUserProfile secondaryUserStatic;
        
        private static (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, Func<string> Email, Func<string> Password, bool UserHasVerifiedAge)[] loginAsEmailValues = 
        {
            // Commenting out tests that use bad emails until we use seeded data
            //(HttpStatusCode.Forbidden, false, "email", "password"),
            (HttpStatusCode.Forbidden, false, ()=> GetTestUserProfile(TestUserProfileType.Primary).Email, ()=> "password", false),
            (HttpStatusCode.OK, true, ()=> GetTestUserProfile(TestUserProfileType.Primary).Email, ()=> GetTestUserProfile(TestUserProfileType.Primary).Password, true)
        };

        private static (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, Func<string> Password, bool UserHasVerifiedAge)[] loginAsUsernameValues = 
        {
            (HttpStatusCode.Forbidden, false, ()=> "password", false),
            (HttpStatusCode.OK, true, ()=> GetTestUserProfile(TestUserProfileType.Primary).Password, true)
        };

        private static (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, string UserId, string Token)[] loginWithTokenValues = 
        {
            (HttpStatusCode.BadRequest, false, "userId", "token")
        };

        /// <summary>
        /// Helper function to create primary user account.
        /// </summary>
        public static async Task<TestUserProfile> CreatePrimaryUser(UserApi userService)
        {
            TestUserProfile primaryUserProfile = await TestHelper.CreatePrimaryUser(userService);
            Assert.IsNotNull(primaryUserProfile, "Primary user creation failed!");
            primaryUserStatic = primaryUserProfile;
            return primaryUserStatic;
        }
        
        /// <summary>
        /// Helper function to create secondary user account.
        /// </summary>
        public static async Task<TestUserProfile> CreateSecondaryUser(UserApi userService)
        {
            TestUserProfile secondaryUserProfile = await TestHelper.CreateSecondaryUser(userService);
            Assert.IsNotNull(secondaryUserProfile, "Secondary user creation failed!");
            secondaryUserStatic = secondaryUserProfile;
            return secondaryUserStatic;
        }
        
        /// <summary>
        /// Helper function for other tests to ensure a successful login
        /// </summary>
        public static async Task<LoginSuccessResult> LoginSuccess(UserApi userService, TestUserProfile userToLogin)
        {
            Assert.NotNull(userToLogin, $"Attempting to login with invalid user: {nameof(userToLogin)} must not be null!");
            
            try
            {
                // Note: create multiplayer connection since we use online realtime engine, and no token option passed.
                LoginInfo result = await userService.LoginAsync(userToLogin.Email, userToLogin.Password,
                    true, true, null);
                return new LoginSuccessResult(result, null);
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Failed to Login, Error Code: {ex.StatusCode} | Failure Reason: {ex.FailureReason} | Msg: {ex.Message} | Stack: {ex.StackTrace}");
                return new LoginSuccessResult(new LoginInfo(), ex);
            }
        }

        [UnityTest, Order(0)]
        public IEnumerator Setup_Success()
        {
            Assert.IsTrue(isInitialized);

            // Action:
            // Do Nothing
            yield return null;

            Assert.IsNotNull(userService);
            Assert.IsNotNull(foundation);
            Assert.IsTrue(foundation.IsStarted);
        }

        /// <summary>
        /// Using the login with email and password endpoint with various params to get specific exceptions and success cases.
        /// </summary>
        [UnityTest]
        public IEnumerator LoginAsEmailCases([ValueSource(nameof(loginAsEmailValues))] (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, Func<string> Email, Func<string> Password, bool UserHasVerifiedAge) value)
            => AsyncTest.RunAsync(async () =>
            {
                Assert.IsTrue(isInitialized);

                // Action:
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = true;
                }
                
                // Note: create multiplayer connection since we use online realtime engine, and no token option passed.
                var loginResult = await TestHelper.WrapEndpoint(() => userService.LoginAsync(
                    value.Email?.Invoke(), value.Password?.Invoke(), true, value.UserHasVerifiedAge, null));
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = false;
                }

                // Assert:
                Assert.AreEqual((ushort)value.ExpectedCode, loginResult.ReturnCode);
                Assert.AreEqual(!string.IsNullOrWhiteSpace(loginResult.ReturnData?.UserId), value.ExpectedReturnValue);

                // Min wait between endpoint calls
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);

                if (TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    string authToken = userService.GetValidAuthToken();
                    Assert.IsFalse(string.IsNullOrWhiteSpace(authToken));

                    await userService.LogoutAsync();
                    await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
                }
            });

        /// <summary>
        /// Using the login with username and password endpoint with various params to get specific exceptions and success cases.
        /// </summary>
        [UnityTest]
        public IEnumerator LoginAsUsernameCases([ValueSource(nameof(loginAsUsernameValues))] (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, Func<string> Username, Func<string> Password, bool UserHasVerifiedAge) value)
            => AsyncTest.RunAsync(async () =>
            {
                Assert.IsTrue(isInitialized);

                // Action:
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = true;
                }
                // Note: create multiplayer connection since we use online realtime engine, and no token option passed.
                var loginResult = await TestHelper.WrapEndpoint(() => userService.LoginWithUsernameAsync(
                    value.Username?.Invoke(), value.Password?.Invoke(), true, value.UserHasVerifiedAge, null));
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = false;
                }

                // Assert:
                Assert.AreEqual((ushort)value.ExpectedCode, loginResult.ReturnCode);
                Assert.AreEqual(!string.IsNullOrWhiteSpace(loginResult.ReturnData?.UserId), value.ExpectedReturnValue);

                // Min wait between endpoint calls
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);

                if (TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    string authToken = userService.GetValidAuthToken();
                    Assert.IsFalse(string.IsNullOrWhiteSpace(authToken));

                    await userService.LogoutAsync();
                    await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
                }
            });

        /// <summary>
        /// Using the login with username and password endpoint with various params to get specific exceptions and success cases.
        /// </summary>
        [UnityTest]
        public IEnumerator LoginWithTokenCases([ValueSource(nameof(loginWithTokenValues))] (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, string UserId, string Token) value)
            => AsyncTest.RunAsync(async () =>
            {
                Assert.IsTrue(isInitialized);

                // Action:
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = true;
                }
                // Note: create multiplayer connection since we use online realtime engine, and no token option passed.
                var loginResult = await TestHelper.WrapEndpoint(() => userService.LoginWithTokenAsync(
                    value.UserId, value.Token, true, null));
                {
                    LogAssert.ignoreFailingMessages = false;
                }

                // Assert:
                Assert.AreEqual((ushort)value.ExpectedCode, loginResult.ReturnCode);
                Assert.AreEqual(!string.IsNullOrWhiteSpace(loginResult.ReturnData?.UserId), value.ExpectedReturnValue);

                // Min wait between endpoint calls
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);

                if (TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    string authToken = userService.GetValidAuthToken();
                    Assert.IsFalse(string.IsNullOrWhiteSpace(authToken));

                    await userService.LogoutAsync();
                    await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
                }
            });
        
        public static TestUserProfile GetTestUserProfile(TestUserProfileType testUserProfileValue)
        {
            switch (testUserProfileValue)
            {
                case TestUserProfileType.Null:
                    return null;
                case TestUserProfileType.Primary:
                    return primaryUserStatic;
                case TestUserProfileType.Secondary:
                    return secondaryUserStatic;
                default:
                    return null;
            }
        }
        
        protected override void FoundationFixtureSetup()
        {
            settings = new FoundationFixtureSettings
            {
                InitializeFoundationFixtureOnOneTimeSetup = true,
                StartFoundation = true, 
                CreatePrimaryAccount = true,
                CreateSecondaryAccount = true,
                Login = false,                      // No need to login before the tests start
                LoginWithSecondaryAccount = false
            };
        }
    }
}