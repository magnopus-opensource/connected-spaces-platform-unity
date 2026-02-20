// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Foundation.Unity.Runtime.User.Exceptions;
using csp;
using Magnopus.Foundation.Unity.Tests.Integration.Config;
using Magnopus.Foundation.Unity.Tests.Integration.User;
using Magnopus.Foundation.Unity.Runtime.User;
using Magnopus.Foundation.Unity.Runtime.User.Manager;
using Magnopus.Foundation.Unity.Runtime.User.Schema;
using System;
using System.Net;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Assertions;

using LoginInfo = csp.common.LoginState;

namespace Magnopus.Foundation.Unity.Tests.Integration.Extensions
{
    public static class TestHelper
    {
        public const int ApiDelayMs = 100;
        
        public struct WrappedEndpointResult<T>
        {
            public ushort ReturnCode;
            public T ReturnData;
            public bool DidError;

            public WrappedEndpointResult(ushort returnCode, T returnData, bool didError)
            {
                ReturnCode = returnCode;
                ReturnData = returnData;
                DidError = didError;
            }
        }
        public static ClientUserAgent TesterUserAgent = new ClientUserAgent()
        {
            CHSEnvironment = "ODev",
            ClientEnvironment = "Dev",
            ClientOS = "iOS",
            ClientSKU = "Foundation Unity Integration Tests",
            ClientVersion = "3.8.3",
            CSPVersion = "6.19.0"
        };

        public static async Task<WrappedEndpointResult<T>> WrapEndpoint<T>(Func<Task<T>> endpoint)
        {
            try
            {
                T result = await endpoint();
                return new WrappedEndpointResult<T>((ushort)HttpStatusCode.OK, result, false);
            }
            catch (FoundationEndpointException ex)
            {
                Debug.LogError(ex.ToString());
                return new WrappedEndpointResult<T>(ex.StatusCode, default(T), true);
            }
            catch (FoundationException ex)
            {
                Debug.LogError(ex.ToString());
                return new WrappedEndpointResult<T>(400, default(T), true);
            }
            catch (Exception ex)
            {
                Debug.LogError(ex.ToString());
                return new WrappedEndpointResult<T>(400, default(T), true);
            }
        }

        public static async Task<ushort> WrapEndpoint(Func<Task> endpoint)
        {
            try
            {
                await endpoint();

                return (ushort)HttpStatusCode.OK;
            }
            catch (FoundationEndpointException ex)
            {
                Debug.LogError(ex.ToString());
                return ex.StatusCode;
            }
            catch (FoundationException ex)
            {
                Debug.LogError(ex.ToString());
                return 400;
            }
            catch (Exception ex)
            {
                Debug.LogError(ex.ToString());
                return (400);
            }
        }

        public static bool IsSuccessCase(HttpStatusCode expectedCode)
        {
            return (int)expectedCode >= 200 && (int)expectedCode < 300;
        }

        /// <summary>
        /// Starts foundation using the provided endpoint and tenants, or using the default ones.
        /// <remarks>
        /// Note: this function also asserts any failure.
        /// </remarks>
        /// </summary>
        /// <param name="endpointUrl">[Optional] custom URl for the endpoint. Default from ConfigSettings.Environment.Endpoint.</param>
        /// <param name="tenant">[Optional] custom tenant. Default from ConfigSettings.Environment.Tenant.</param>
        /// <returns>The foundation manager, once it is created and started.</returns>
        public static FoundationManager StartDefaultFoundation(
            string endpointUrl = null,
            string tenant = ConfigSettings.Environment.Tenant)
        {
            if (string.IsNullOrEmpty(endpointUrl))
            {
                endpointUrl = ConfigSettings.Environment.Endpoint;
            }
            
            Assert.IsFalse(string.IsNullOrEmpty(endpointUrl), "Failed to get Endpoint Url!");
            Assert.IsFalse(string.IsNullOrEmpty(tenant), "Failed to get Tenant!");
            FoundationManager foundation = new();
            bool successfulFoundationStart = foundation.StartFoundation(endpointUrl, tenant, TesterUserAgent, null);
            Assert.IsTrue(successfulFoundationStart,"Failed to start up Foundation Manager!");
            return foundation;
        }

        public static async Task<TestUserProfile> CreateUser(
            string baseUsername,
            string displayName,
            TestUserProfileType userProfileType,
            UserApi userService)
        {
            var primaryUsername = baseUsername + DateTime.Now.Ticks;
            var primaryEmail = primaryUsername + "@magnopus.com";
            var primaryUserPassword = $"{DateTime.Now.Ticks}{DateTime.Now.Ticks}";
            var primaryUserProfileResult = await userService.CreateUserAsync(
                primaryUsername, 
                displayName,
                primaryEmail,
                primaryUserPassword,false,true,string.Empty,string.Empty);
                
            return new TestUserProfile
            {
                UserId = primaryUserProfileResult.UserId,
                Username = primaryUserProfileResult.UserName,
                Email = primaryUserProfileResult.Email,
                Password = primaryUserPassword,
                TestUserType = userProfileType
            };
        }

        public static async Task<TestUserProfile> CreatePrimaryUser(UserApi userService)
            => await CreateUser(
                ConfigSettings.PrimaryUser.BaseUsername, 
                ConfigSettings.PrimaryUser.DisplayName1,
                TestUserProfileType.Primary, userService);

        public static async Task<TestUserProfile> CreateSecondaryUser(UserApi userService)
            => await CreateUser(
                ConfigSettings.SecondaryUser.BaseUsername, 
                ConfigSettings.SecondaryUser.DisplayName1,
                TestUserProfileType.Secondary, userService);

        public static async Task<LoginTests.LoginSuccessResult> LoginUser(TestUserProfile user, UserApi userService, 
            bool createMultiplayerConnection, bool ageVerified = true, TokenOptions? tokenOptions = null)
        {
            try
            {
                LoginInfo loginInfo = await userService.LoginAsync(user.Email, user.Password, createMultiplayerConnection, ageVerified, tokenOptions);
                return new LoginTests.LoginSuccessResult(loginInfo, null);
            }
            catch (FoundationEndpointException ex)
            {
                Debug.LogError(
                    $"Failed to Login, Error Code: {ex.StatusCode} | Failure Reason: {ex.FailureReason} | Msg: {ex.Message} | Stack: {ex.StackTrace}");
                return new LoginTests.LoginSuccessResult(new LoginInfo(), ex);
            }
        }

        /// <summary>
        /// Passes a test if it throws a specified exception type.
        /// </summary>
        /// <remarks>
        /// <see cref="NUnit.Framework.Assert.ThrowsAsync()"/> causes the editor to hang.
        /// https://issuetracker.unity3d.com/issues/editor-hangs-when-using-assert-dot-throwsasync-in-a-test
        /// </remarks>
        /// <param name="task">Task to await.</param>
        /// <typeparam name="T">Expected exception type.</typeparam>
        public static async Task AssertThrowsAsync<T>(Task task)
        where T : Exception
        {
            try
            {
                await task;
            }
            catch (T)
            {
                NUnit.Framework.Assert.Pass();
                return;
            }
            
            NUnit.Framework.Assert.Fail();
        }
    }
}
