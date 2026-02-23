// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Foundation.Unity.Tests.Integration.User;

namespace Magnopus.Foundation.Unity.Tests.Integration.Config
{
    public enum TestUserProfileType
    {
        Null,
        Primary,
        Secondary
    }
    
    /// <summary>
    /// Data structure to hold the runtime representation of a primary or secondary user, used for executing integration tests
    /// </summary>
    public class TestUserProfile
    {
        public string UserId = "";
        public string Email = "";
        public string Username = "";
        public string Password = "";
        public TestUserProfileType TestUserType;
    }
}