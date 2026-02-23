// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Extra.Exceptions;
using CspUserRoleInfo = csp.systems.UserRoleInfo;

namespace Magnopus.Foundation.Unity.Runtime.User.Schema
{
    /// <summary>
    /// Data transfer object for User role info data.  This represents <see cref="CspUserRoleInfo"/>
    /// </summary>
    public struct UserRoleInfo
    {
        public string UserId { get; set; }
        public csp.systems.SpaceUserRole UserRole { get; set; }

        public UserRoleInfo(string userId, csp.systems.SpaceUserRole userRole)
        {
            UserId = userId;
            UserRole = userRole;
        }

        internal UserRoleInfo(CspUserRoleInfo userRoleInfo)
        {
            if (userRoleInfo == null)
            {
                throw new CspResultException($"Argument: {nameof(userRoleInfo)} was null. Could not create {nameof(UserRoleInfo)}");
            }
            
            UserId = userRoleInfo.UserId;
            UserRole = userRoleInfo.UserRole;
        }

        internal CspUserRoleInfo ToCspUserRoleInfo()
        {
            var cspUserRoleInfo = new CspUserRoleInfo();
            cspUserRoleInfo.UserId = UserId;
            cspUserRoleInfo.UserRole = UserRole;
            return cspUserRoleInfo;
        }
    }
}