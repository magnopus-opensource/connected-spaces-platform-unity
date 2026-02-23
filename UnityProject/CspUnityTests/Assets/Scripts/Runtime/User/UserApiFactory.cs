// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Foundation.Unity.Runtime.User.Manager;
using csp.systems;
using Magnopus.Extra.Exceptions;

namespace Magnopus.Foundation.Unity.Runtime.User
{
    /// <summary>
    /// Factory to create the <seealso cref="UserApi"/>
    /// </summary>
    public static class UserApiFactory
    {
        /// <summary>
        /// Factory function to access the OKO Foundation's <seealso cref="UserSystem"/> and create the <see cref="UserApi"/>.
        /// May throw a <seealso cref="FoundationException"/> on error.
        /// </summary>
        public static UserApi Create()
        {
            var serviceManager = SystemsManager.Get();
            if (serviceManager == null)
            {
                throw new CspResultException($"Failed to get service manager. Make sure {nameof(FoundationManager)} has been started.");
            }

            var userSystem = serviceManager.GetUserSystem();
            var externalServicesProxySystem = serviceManager.GetExternalServicesProxySystem();
            return new UserApi(userSystem, externalServicesProxySystem);
        }
    }
}