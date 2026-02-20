// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Foundation.Unity.Tests.Integration.Config;
using Magnopus.Foundation.Unity.Tests.Integration.Extensions;
using Magnopus.Foundation.Unity.Tests.Integration.User;
using Magnopus.OKO.Tests.Editor;
using NUnit.Framework;
using System.Collections;
using System.Threading.Tasks;
using Magnopus.Foundation.Unity.Runtime.User;
using Magnopus.Foundation.Unity.Runtime.User.Manager;
using UnityEngine;
using UnityEngine.TestTools;

namespace Magnopus.Foundation.Unity.Tests.Integration
{
    /// <summary>
    /// Class to use as base for most of our integration tests.
    /// <remarks>
    /// Derived classes can override:
    /// <list type="bullet">
    ///   <item>
    ///     <description>
    ///       <see cref="FoundationFixtureSetup"/> which is intended to update the <see cref="FoundationFixtureSettings"/>
    /// configuration before any test starts (e.g. establish if primary or secondary users need to be created, which one logs in, etc.).
    ///     </description>
    ///   </item>
    ///   <item>
    ///     <description>
    ///       <see cref="PostSetUpBase"/> or <see cref="PostSetUpBaseAsync"/>, which is executed during the UnitySetup,
    /// after the base SetUp for the fixture is completed and just before the isInitialized is set to true.
    ///     </description>
    ///   </item>
    ///   <item>
    ///     <description>
    ///       <see cref="BeforeEachTestStart"/>, which is executed after <see cref="isInitialized"/> is set to true
    /// and every time before a new test starts.
    ///     </description>
    ///   </item>
    ///   <item>
    ///     <description>
    ///       <see cref="AfterEachTestEnd"/>, which is executed after each test finishes (e.g. to uninitialize manually unwanted data).
    ///     </description>
    ///   </item>
    ///   <item>
    ///     <description>
    ///       <see cref="PreFoundationFixtureOneTimeTearDown"/>, which is executed before the OneTimeTearDown starts its execution.
    ///     </description>
    ///   </item>
    ///   <item>
    ///     <description>
    ///       <see cref="PostFoundationFixtureOneTimeTearDown"/>, which is executed as last operation within the OneTimeTearDown execution.
    ///     </description>
    ///   </item>
    /// </list>
    /// </remarks>
    /// </summary>
    public class FoundationFixture
    {
        /// <summary>
        /// Settings to use for this <see cref="FoundationFixture"/> configuration.
        /// </summary>
        protected struct FoundationFixtureSettings
        {
            /// <summary>
            /// If true, the <see cref="InitializeFoundationFixture()"/> will be called automatically within the OneTimeSetup.
            /// Otherwise, the derived classes will be responsible to call it manually. For example, if the
            /// initialization needs to happen for each test instead of one time before the tests, set this to
            /// false and call manually <see cref="InitializeFoundationFixture"/> from within the
            /// <see cref="BeforeEachTestStart"/> function.
            /// </summary>
            public bool InitializeFoundationFixtureOnOneTimeSetup { get; set; }
            
            /// <summary>
            /// If true, the setup will automatically start foundation.
            /// </summary>
            public bool StartFoundation { get; set; }

            /// <summary>
            /// If true, create primary test account.
            /// Note: <see cref="userService"/> will be created if this is true.
            /// </summary>
            public bool CreatePrimaryAccount { get; set; }
            
            /// <summary>
            /// If true, create secondary test account.
            /// Note: <see cref="userService"/> will be created if this is true.
            /// </summary>
            public bool CreateSecondaryAccount { get; set; }
            
            /// <summary>
            /// If true, primary or secondary user will be logged in depending on the loginWithSecondaryAccount flag.
            /// Note: <see cref="userService"/> will be created if this is true.
            /// </summary>
            public bool Login { get; set; }

            /// <summary>
            /// If true, the secondary user will be logged in after signup instead of the primary user.
            /// False by default.
            /// <remarks>
            /// If CreateSecondaryAccount is false but <see cref="LoginWithSecondaryAccount"/> is true, an error should be fired.
            /// </remarks>
            /// </summary>
            public bool LoginWithSecondaryAccount { get; set; }
        }

        /// <summary>
        /// If true, <see cref="InitializeFoundationFixture"/> was called and the <see cref="UninitializeFoundationFixture"/>
        /// needs to be executed before tear down or before calling again <see cref="InitializeFoundationFixture"/>.
        /// </summary>
        public bool NeedsToUninitializeFoundationFixture { get => needsUninitializeFoundationFixture; }
        protected FoundationFixtureSettings settings;
        protected FoundationManager foundation;
        protected UserApi userService;
        protected TestUserProfile primaryUser;
        protected TestUserProfile secondaryUser;
        protected string tenant;
        protected string baseEndpoint;
        protected bool isInitialized;
        private bool needsUninitializeFoundationFixture;
        
        /// <summary>
        /// Runs only once before all tests start.
        /// </summary>
        [OneTimeSetUp]
        public void OneTimeSetUp()
        {
            FoundationFixtureSetup();
        }

        /// <summary>
        /// Performs steps after the <see cref="OneTimeSetUp"/>. Runs every time before each test.
        /// Depending on the configuration established by derived classes in <see cref="FoundationFixtureSetup"/>,
        /// this function will take care of starting foundation (if enabled), create primary / secondary accounts
        /// (if enabled), and log one of them (if enabled). Then, <see cref="PostSetUpBase"/> and
        /// <see cref="PostSetUpBaseAsync"/> are called before <see cref="isInitialized"/> is set to true.
        /// </summary>
        /// <returns>An enumerator that supports yielding for asynchronous setup operations.</returns>
        [UnitySetUp]
        public IEnumerator SetUpBase()
        {
            if (!isInitialized)
            {
                // Note: this only happens one time, before all tests start.
                if (settings.InitializeFoundationFixtureOnOneTimeSetup)
                {
                    // Configure this foundation fixture only if requested, otherwise derived classes can call
                    // manually InitializeFoundationFixture(), for example if they want to execute it before
                    // every test instead of only one time before all tests start.
                    yield return InitializeFoundationFixture();
                }

                // Perform synchronous post setup
                PostSetUpBase();
                
                // Perform asynchronous post setup
                yield return AsyncTest.RunAsync(async () =>
                {
                    await PostSetUpBaseAsync();
                });
                
                isInitialized = true;
            }
            yield return BeforeEachTestStart();
        }

        /// <summary>
        /// This is performed at the end of each test.
        /// Derived classes can override <see cref="AfterEachTestEnd"/> for operations to perform at the end of each
        /// test. Note that the <see cref="AfterEachTestEnd"/> returns an IEnumerator to support supports yielding
        /// for asynchronous setup operations.
        /// </summary>
        /// <returns>
        /// An enumerator that supports yielding for asynchronous setup operations.
        /// </returns>
        [UnityTearDown]
        public IEnumerator TearDownBase()
        {
            // Any operation derived classes need to perform at the end of each test.
            yield return AfterEachTestEnd();
            
            yield return AsyncTest.RunAsync(async () =>
            {
                // Add a short delay between each test to throttle the rate at which we hit endpoints
                await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
            });
        }

        [OneTimeTearDown]
        public void OneTimeTearDownBase()
        {
            // Any operation derived classes need to perform before base one time teardown.
            PreFoundationFixtureOneTimeTearDown();
            
            Debug.Log("One Time Tear down at the end of all tests.");
            if (needsUninitializeFoundationFixture)
            {
                UninitializeFoundationFixture();
            }
            
            // Any operation derived classes need to perform after base one time teardown.
            PostFoundationFixtureOneTimeTearDown();
        }
        
        
        #region Overridable functions for custom setup by derived classes
        /// <summary>
        /// Performs one-time setup operations before the <see cref="SetUpBase"/> is executed.
        /// <remarks>
        /// This can be used to configure the specific setup by the derived test classes.
        /// For example, derived classes can establish which user to login after signup (primary or secondary)
        /// by changing the value of the <see cref="FoundationFixtureSettings.LoginWithSecondaryAccount"/> flag.
        /// By default, the initialization of this foundation fixture is done once before all tests start (not for each test).
        /// This means that when the one time setup foundation starts, primary and secondary accounts are created,
        /// and primary account logs in.
        /// </remarks>
        /// </summary>
        protected virtual void FoundationFixtureSetup()
        {
            settings = new FoundationFixtureSettings
            {
                InitializeFoundationFixtureOnOneTimeSetup = true,
                StartFoundation = true, 
                CreatePrimaryAccount = true,
                CreateSecondaryAccount = true,
                Login = true,
                LoginWithSecondaryAccount = false
            };
        }
        
        /// <summary>
        /// Performs synchronous setup operations within the <see cref="SetUpBase"/> function before isInitialized is set to true.
        /// </summary>
        /// <remarks>
        /// This method is intended to be overridden by derived classes to provide custom setup logic that runs once
        /// after the <see cref="SetUpBase"/>. By default, it does nothing and immediately completes.
        /// Note: if async is needed, derived classes should override <see cref="PostSetUpBaseAsync"/> instead.
        /// </remarks>
        protected virtual void PostSetUpBase()
        {
        }
        
        /// <summary>
        /// Performs asynchronous setup operations within the <see cref="SetUpBase"/> function before isInitialized is set to true.
        /// </summary>
        /// <remarks>
        /// This method is intended to be overridden by derived classes to provide custom setup logic that runs once
        /// after the <see cref="SetUpBase"/>. By default, it does nothing and immediately completes.
        /// Note: if synchronous is needed, derived classes should override <see cref="PostSetUpBase"/> instead.
        /// </remarks>
        /// <returns>
        /// Task from the async operation. By default, it returns await Task.Yield().
        /// </returns>
        protected virtual async Task PostSetUpBaseAsync()
        {
            await Task.Yield();
        }

        /// <summary>
        /// Executed just after <see cref="SetUpBase"/> and before each test starts,
        /// after <see cref="isInitialized"/> was already set to true.
        /// </summary>
        /// <returns>
        /// An enumerator that supports yielding for asynchronous setup operations.
        /// By default, it yields no values.
        /// </returns>
        protected virtual IEnumerator BeforeEachTestStart()
        {
            yield break;
        }
        
        /// <summary>
        /// Derived classes can override this to perform custom operations when each test ends.
        /// </summary>
        /// <returns>
        /// An enumerator that supports yielding for asynchronous setup operations.
        /// By default, it yields no values.
        /// </returns>
        protected virtual IEnumerator AfterEachTestEnd()
        {
            yield break;
        }
        
        /// <summary>
        /// Derived classes can override this to perform custom operations just before the one time teardown for tests is called.
        /// </summary>
        protected virtual void PreFoundationFixtureOneTimeTearDown()
        {
        }
        
        /// <summary>
        /// Derived classes can override this to perform custom operations after one time teardown for tests is completed.
        /// </summary>
        protected virtual void PostFoundationFixtureOneTimeTearDown()
        {
        }
        #endregion
        
        
        #region Foundation Fixture initialization

        /// <summary>
        /// Depending on the configuration established by derived classes in <see cref="FoundationFixtureSetup"/>,
        /// this function will take care of starting foundation (if enabled), create primary / secondary accounts
        /// (if enabled), and log one of them (if enabled).
        /// </summary>
        protected IEnumerator InitializeFoundationFixture()
        {
            if (needsUninitializeFoundationFixture)
            {
                // Error, initializing multiple times
                Assert.Fail($"{nameof(InitializeFoundationFixture)} was already called, " +
                            $"call ${nameof(UninitializeFoundationFixture)} first before calling this again!");
            }
            
            if (settings.StartFoundation)
            {
                baseEndpoint = ConfigSettings.Environment.Endpoint;
                tenant = ConfigSettings.Environment.Tenant;
                foundation = TestHelper.StartDefaultFoundation();
                Debug.Log($"{nameof(InitializeFoundationFixture)}: Started Foundation");
            }

            yield return AsyncTest.RunAsync(async () =>
            {
                // Only instantiate if we need it here or for derived classes.
                userService = UserApiFactory.Create();
                
                if (settings.CreatePrimaryAccount)
                {
                    primaryUser = await LoginTests.CreatePrimaryUser(userService);
                    await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
                    Debug.Log($"{nameof(InitializeFoundationFixture)}: Created Primary Account");
                }

                if (settings.CreateSecondaryAccount)
                {
                    secondaryUser = await LoginTests.CreateSecondaryUser(userService);
                    await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
                    Debug.Log($"{nameof(InitializeFoundationFixture)}: Created Secondary Account");
                }
                
                if (settings.Login)
                {
                    // Ensure the primary account was created if we want to login with it
                    if (settings is { CreatePrimaryAccount: false, LoginWithSecondaryAccount: false })
                    {
                        Assert.Fail($"Misconfigured {nameof(InitializeFoundationFixture)}: " +
                                    "cannot login with primary account if primary account creation is disabled!");
                    }
                    
                    // Ensure the secondary account was created if we want to login with it
                    if (settings is { CreateSecondaryAccount: false, LoginWithSecondaryAccount: true })
                    {
                        Assert.Fail($"Misconfigured {nameof(InitializeFoundationFixture)}: " +
                                    "cannot login with secondary account if secondary account creation is disabled!");
                    }

                    var userToLogin = settings.LoginWithSecondaryAccount ? secondaryUser : primaryUser;
                    Assert.IsNotNull(userToLogin, "User to login is null! Ensure the user setup is correct!");

                    var loginResult = await LoginTests.LoginSuccess(userService, userToLogin);
                    Assert.IsNotNull(loginResult);
                    Assert.IsNull(loginResult.Exception);
                    await Task.Delay(ConfigSettings.MinWaitBetweenEndpointsMilliseconds);
                    
                    var loggedInAccount = settings.LoginWithSecondaryAccount ? "Secondary" : "Primary";
                    Debug.Log($"{nameof(InitializeFoundationFixture)}: Logged in with {loggedInAccount} Account");
                }
            });
            
            needsUninitializeFoundationFixture = true;
        }

        /// <summary>
        /// Uninitializes all the properties that were instantiated on initialization.
        /// <remarks>
        /// NOTE: this function does not log the user out, since there is no way to our knowledge to
        /// do a one time tear down that is an enumerator, which is needed for the async logout.
        /// </remarks>
        /// </summary>
        protected void UninitializeFoundationFixture()
        {
            // NOTE: we decided to not log the user out here as there is no way to our knowledge to
            // do a one time tear down that is an enumerator, which is needed for the async logout

            foundation?.StopFoundation();
            baseEndpoint = null;
            tenant = null;
            userService = null;
            foundation = null;
            primaryUser = null;
            secondaryUser = null;

            needsUninitializeFoundationFixture = false;
        }
        #endregion
    }
}