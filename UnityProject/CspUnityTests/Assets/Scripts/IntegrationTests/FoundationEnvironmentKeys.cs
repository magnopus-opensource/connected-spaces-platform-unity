// ------------------------------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ------------------------------------------------------------------

namespace Magnopus.Foundation.Unity.Tests.Integration.EnvironmentFile
{
    /// <summary>
    /// Environment keys used to access various configuration settings from the .env file.
    /// </summary>
    public class FoundationEnvironmentKeys
    {
        // ReSharper disable InconsistentNaming

        // Admin Credentials for O2Dev
        public const string OKO_TESTS_ADMIN_EMAIL = nameof(OKO_TESTS_ADMIN_EMAIL);
        public const string OKO_TESTS_ADMIN_PW = nameof(OKO_TESTS_ADMIN_PW);

        // ReSharper restore InconsistentNaming

        public static readonly string[] AllEnvironmentVariableNames = new[]
        {
            OKO_TESTS_ADMIN_EMAIL, OKO_TESTS_ADMIN_PW
        };
    }
}