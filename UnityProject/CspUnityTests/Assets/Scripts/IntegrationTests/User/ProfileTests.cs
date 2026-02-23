// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Foundation.Unity.Tests.Integration.Config;
using Magnopus.Foundation.Unity.Tests.Integration.Extensions;
using Magnopus.OKO.Tests.Editor;
using NUnit.Framework;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using csp.common;
using IntegrationTests.Spaces;
using UnityEngine.TestTools;

using FoundationSystems = csp.systems;
using SpaceInfo = csp.systems.Space;
using TokenInfoParams = csp.systems.ExternalServicesOperationParams;

namespace Magnopus.Foundation.Unity.Tests.Integration.User
{
    public class ProfileTests : FoundationFixture
    {
        private static (HttpStatusCode ExpectedCode, bool ExpectedReturnValue,  Func<string> UserId)[] getProfileValues = 
        {
            (HttpStatusCode.BadRequest, false, ()=> "userId"),
            (HttpStatusCode.OK, true, ()=> LoginTests.GetTestUserProfile(TestUserProfileType.Primary).UserId)
        };

        private static (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, string Username, string DisplayName, Func<string> Email, string Password, bool ReceiveNewsletter, bool UserHasVerifiedAge, string RedirectUrl, string InviteToken)[] createUserValues = 
        {
            (HttpStatusCode.Unauthorized, false, null, null, ()=> ConfigSettings.PrimaryUser.BaseUsername + DateTime.Now.Ticks + "@magnopus.com", null, false, false, null, null),
            // Commenting out tests that use bad emails until we use seeded data
            //(HttpStatusCode.BadRequest, false, "username", "displayName", "email", "password", false, null)
            (HttpStatusCode.Conflict, false, "username", "displayName", ()=> ConfigSettings.PrimaryUser.BaseUsername +  DateTime.Now.Ticks + "@magnopus.com", "password", false,true, null, null)
        };

        private static (HttpStatusCode ExpectedCode, string UserId)[] deleteUserValues = 
        {
            (HttpStatusCode.Unauthorized, null),
            (HttpStatusCode.BadRequest, "userId")
        };

        private static (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, string[] UserIds)[] getProfilesValues = 
        {
            (HttpStatusCode.BadRequest, false, new string[1] { "userId" })
        };

        private static (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, string Username, string DisplayName, string Email, string Password)[] upgradeGuestAccountValues = 
        {
            (HttpStatusCode.Unauthorized, false, null, null, null, null),
            // Commenting out tests that use bad emails until we use seeded data
            //(HttpStatusCode.BadRequest, false, "username", "displayName", "email", "password"),
        };

        private static (HttpStatusCode ExpectedCode, string Email, string EmailLinkUrl, string RedirectUrl, bool UseTokenChangePasswordUrl)[] forgotPasswordValues = 
        {
            (HttpStatusCode.Unauthorized, null, null, null, false),
            // TODO: https://magnopus.atlassian.net/browse/OF-399 wait for fix to the crash of forgotten password
            // Also: Commenting out tests that use bad emails until we use seeded data
            //(HttpStatusCode.BadRequest, "email")
        };

        private static (HttpStatusCode ExpectedCode, Func<string> UserId, string NewUserDisplayName)[] updateUserDisplayNameValues =
        {
            (HttpStatusCode.Unauthorized, null, null),
            (HttpStatusCode.BadRequest, ()=> "badUserId", "newUserDisplayName"),
            (HttpStatusCode.OK,  ()=> LoginTests.GetTestUserProfile(TestUserProfileType.Primary).UserId, ConfigSettings.PrimaryUser.DisplayName2),
            (HttpStatusCode.OK, ()=> LoginTests.GetTestUserProfile(TestUserProfileType.Primary).UserId, ConfigSettings.PrimaryUser.DisplayName1)
        };

        private static (HttpStatusCode ExpectedCode, string serviceName, string operationName, bool setHelp)[] postProxyServiceValues =
        {
            (HttpStatusCode.Unauthorized, String.Empty, String.Empty, false),
            (HttpStatusCode.NotFound, "BadServiceName", "getUserToken", false),
            (HttpStatusCode.NotFound, "Agora", "BadOperationName", false),
            (HttpStatusCode.OK, "Agora", "getUserToken", false) // Agora is the only service being currently used
        };

        private static SpaceInfo spaceInfo;
        
        private FoundationSystems.SpaceSystem spacesService;

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
        /// Using the get profile by Id endpoint with various params to get specific exceptions and success cases.
        /// </summary>
        [UnityTest]
        public IEnumerator GetProfileCases([ValueSource(nameof(getProfileValues))] (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, Func<string> UserId) value)
            => AsyncTest.RunAsync(async () =>
            {
                Assert.IsTrue(isInitialized);

                // Action:
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = true;
                }
                var profileResult = await TestHelper.WrapEndpoint(() => userService.GetProfileByIdAsync(value.UserId?.Invoke()));
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = false;
                }

                // Assert:
                Assert.AreEqual((ushort)value.ExpectedCode, profileResult.ReturnCode);
                Assert.AreEqual(!string.IsNullOrWhiteSpace(profileResult.ReturnData?.UserId), value.ExpectedReturnValue);
                FoundationSystems.Profile profile = profileResult.ReturnData;

                if (TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    Assert.IsTrue(profile.Email == primaryUser.Email);
                    Assert.IsTrue(profile.UserId == primaryUser.UserId);
                }

                // Min wait between endpoint calls
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
            });

        /// <summary>
        /// Using the get profile by Id endpoint with various params to get specific exceptions and success cases.
        /// </summary>
        [UnityTest]
        public IEnumerator CreateUserCases([ValueSource(nameof(createUserValues))] (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, string Username,
            string DisplayName, Func<string> Email, string Password, bool ReceiveNewsletter, bool UserHasVerifiedAge, string RedirectUrl, string InviteToken) value)
            => AsyncTest.RunAsync(async () =>
            {
                Assert.IsTrue(isInitialized);

                // Action:
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = true;
                }
                var profileResult = await TestHelper.WrapEndpoint(() => userService.CreateUserAsync(value.Username, value.DisplayName, value.Email?.Invoke(), value.Password, value.ReceiveNewsletter, value.UserHasVerifiedAge, value.RedirectUrl, value.InviteToken));
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = false;
                }

                // Assert:
                Assert.AreEqual((ushort)value.ExpectedCode, profileResult.ReturnCode);
                Assert.AreEqual(!string.IsNullOrWhiteSpace(profileResult.ReturnData?.UserId), value.ExpectedReturnValue);

                // Min wait between endpoint calls
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
            });

        /// <summary>
        /// Using the delete user by Id endpoint with various params to get specific exceptions and success cases.
        /// </summary>
        [UnityTest]
        public IEnumerator DeleteUserCases([ValueSource(nameof(deleteUserValues))] (HttpStatusCode ExpectedCode, string UserId) value)
            => AsyncTest.RunAsync(async () =>
            {
                Assert.IsTrue(isInitialized);

                // Action:
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = true;
                }
                var deleteUserResult = await TestHelper.WrapEndpoint(() => userService.DeleteUserAsync(value.UserId));
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = false;
                }

                // Assert:
                Assert.AreEqual((ushort)value.ExpectedCode, deleteUserResult);
                
                // Min wait between endpoint calls
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
            });

        /// <summary>
        /// Using the get profiles by Ids endpoint with various params to get specific exceptions and success cases.
        /// </summary>
        [UnityTest]
        public IEnumerator GetProfilesCases([ValueSource(nameof(getProfilesValues))] (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, string[] UserIds) value)
            => AsyncTest.RunAsync(async () =>
            {
                Assert.IsTrue(isInitialized);

                // Action:
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = true;
                }
                var profileResult = await TestHelper.WrapEndpoint(() => userService.GetProfilesByUserIdsAsync(value.UserIds));
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = false;
                }

                // Assert:
                Assert.AreEqual((ushort)value.ExpectedCode, profileResult.ReturnCode);
                Assert.AreEqual(profileResult.ReturnData != null, value.ExpectedReturnValue);

                // Min wait between endpoint calls
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
            });

        /// <summary>
        /// Using the upgrade guest account endpoint with various params to get specific exceptions and success cases.
        /// </summary>
        [UnityTest]
        public IEnumerator UpgradeGuestAccountCases([ValueSource(nameof(upgradeGuestAccountValues))] (HttpStatusCode ExpectedCode, bool ExpectedReturnValue, string Username, string DisplayName, string Email, string Password) value)
            => AsyncTest.RunAsync(async () =>
            {
                Assert.IsTrue(isInitialized);

                // Action:
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = true;
                }
                var profileResult = await TestHelper.WrapEndpoint(() => userService.UpgradeGuestAccountAsync(value.Username, value.DisplayName, value.Email, value.Password));
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = false;
                }

                // Assert:
                Assert.AreEqual((ushort)value.ExpectedCode, profileResult.ReturnCode);
                Assert.AreEqual(!string.IsNullOrWhiteSpace(profileResult.ReturnData?.UserId), value.ExpectedReturnValue);

                // Min wait between endpoint calls
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
            });

        /// <summary>
        /// Using the forgot password endpoint with various params to get specific exceptions and success cases.
        /// </summary>
        [UnityTest]
        public IEnumerator ForgotPasswordCases([ValueSource(nameof(forgotPasswordValues))] (HttpStatusCode ExpectedCode, string Email, string EmailLinkUrl, string RedirectUrl, bool UseTokenChangePasswordUrl) value)
       => AsyncTest.RunAsync(async () =>
       {
           Assert.IsTrue(isInitialized);

           // Action:
           if (!TestHelper.IsSuccessCase(value.ExpectedCode))
           {
               LogAssert.ignoreFailingMessages = true;
           }
           var fogotPasswordResult = await TestHelper.WrapEndpoint(() => userService.ForgotPasswordAsync(value.Email, value.EmailLinkUrl, value.RedirectUrl, value.UseTokenChangePasswordUrl));
           if (!TestHelper.IsSuccessCase(value.ExpectedCode))
           {
               LogAssert.ignoreFailingMessages = false;
           }

           // Assert:
           Assert.AreEqual((ushort)value.ExpectedCode, fogotPasswordResult);

           // Min wait between endpoint calls
           await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
       });

        /// <summary>
        /// Using the Update User DisplayName endpoint with various params to get specific exceptions and success cases.
        /// </summary>
        [UnityTest]
        public IEnumerator UpdateUserDisplayNameCases([ValueSource(nameof(updateUserDisplayNameValues))] (HttpStatusCode ExpectedCode, Func<string> UserId, string NewUserDisplayName) value)
            => AsyncTest.RunAsync(async () =>
            {
                Assert.IsTrue(isInitialized);

                // Action:
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = true;
                }
                var updateUserNameResult = await TestHelper.WrapEndpoint(() => userService.UpdateUserDisplayNameAsync(value.UserId?.Invoke(), value.NewUserDisplayName));
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = false;
                }

                // Assert:
                Assert.AreEqual((ushort)value.ExpectedCode, updateUserNameResult);

                // Min wait between endpoint calls
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);

                if (value.ExpectedCode == HttpStatusCode.OK)
                {
                    var profileResult = await TestHelper.WrapEndpoint(() => userService.GetProfileByIdAsync(value.UserId?.Invoke()));

                    // Assert:
                    Assert.AreEqual((ushort)value.ExpectedCode, profileResult.ReturnCode);
                    Assert.AreEqual(!string.IsNullOrWhiteSpace(profileResult.ReturnData?.UserId), true);
                    FoundationSystems.Profile profile = profileResult.ReturnData;

                    Assert.IsTrue(profile.DisplayName == value.NewUserDisplayName, $"Display Name match? Set to: {value.NewUserDisplayName}, and Returned is: {profile.DisplayName}");
                }
            });

        /// <summary>
        /// Using the Post Proxy Service endpoint with various params to get specific exceptions.
        /// </summary>
        [UnityTest]
        public IEnumerator PostProxyServiceCases([ValueSource(nameof(postProxyServiceValues))] (HttpStatusCode ExpectedCode, string serviceName, string operationName, bool setHelp) value)
            => AsyncTest.RunAsync(async () =>
            {
                Assert.IsTrue(isInitialized);

                // Action:
                Dictionary<string, string> tokenParams = new Dictionary<string, string>()
                {
                    {
                        "userId", primaryUser.UserId
                    },
                    {
                        "channelName", spaceInfo.Id
                    },
                    {
                        "referenceId", spaceInfo.Id
                    },
                    {
                        "lifespan", "10000"
                    },
                    {
                        "readOnly", "true"
                    },
                    {
                        "shareAudio", "false"
                    },
                    {
                        "shareVideo", "false"
                    },
                    {
                        "shareScreen", "false"
                    }
                };

                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = true;
                }
                var tokenInfoParams = new TokenInfoParams();
                tokenInfoParams.ServiceName = value.serviceName;
                tokenInfoParams.OperationName = value.operationName;
                tokenInfoParams.SetHelp = value.setHelp;
                
                // Note: could be improved via swig extend
                var parametersDict = new StringDict();
                foreach (var kv in tokenParams)
                {
                    parametersDict[kv.Key] = kv.Value;
                }
                tokenInfoParams.Parameters = parametersDict;
                
                var result = await TestHelper.WrapEndpoint(() => userService.PostServiceProxy(tokenInfoParams));
                if (!TestHelper.IsSuccessCase(value.ExpectedCode))
                {
                    LogAssert.ignoreFailingMessages = false;
                }

                // Assert:
                Assert.AreEqual((ushort)value.ExpectedCode, result.ReturnCode);

                // Min wait between endpoint calls
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
            });
        
        
        protected override void FoundationFixtureSetup()
        {
            settings = new FoundationFixtureSettings
            {
                InitializeFoundationFixtureOnOneTimeSetup = true,
                StartFoundation = true, 
                CreatePrimaryAccount = true,
                CreateSecondaryAccount = false, // No need to create a secondary account for these tests
                Login = true,
                LoginWithSecondaryAccount = false
            };
        }

        protected override async Task PostSetUpBaseAsync()
        {
            if (!isInitialized)
            {
                var serviceManager = FoundationSystems.SystemsManager.Get();
                if (serviceManager == null)
                {
                    throw new Exception($"Failed to get service manager. Make sure CSP has been started.");
                }
                spacesService = serviceManager.GetSpaceSystem();
                
                // Create a new space to be used for self-managed testing, owned by Primary User
                spaceInfo = await SpacesTests.CreateNewSpace(spacesService, SpacesTests.OwnedSpaceName, 
                    SpacesTests.defaultSpaceMetadata, SpacesTests.defaultTags, FoundationSystems.SpaceAttributes.Private);
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
            }
        }

        protected override void PostFoundationFixtureOneTimeTearDown()
        {
            spacesService = null;
        }
    }
}