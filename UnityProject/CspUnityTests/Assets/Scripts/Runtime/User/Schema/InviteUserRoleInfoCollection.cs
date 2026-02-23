// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using csp.common;
using csp.systems;
using Magnopus.Extra.Exceptions;
using CspInviteUserRoleInfoCollection = csp.systems.InviteUserRoleInfoCollection;
using CspInviteUserRoleInfo = csp.systems.InviteUserRoleInfo;

namespace Magnopus.Foundation.Unity.Runtime.User.Schema
{
    /// <summary>
    /// Data transfer object for invite user role info collection info data.
    /// This represents <see cref="CspInviteUserRoleInfoCollection"/>
    /// </summary>
    public struct InviteUserRoleInfoCollection
    {
        public string EmailLinkUrl { get; set; }
        public string SignupUrl { get; set; }
        public CspInviteUserRoleInfo[] InviteUserRoles { get; set; }

        public InviteUserRoleInfoCollection(string emailLinkUrl, string signupUrl, CspInviteUserRoleInfo[] inviteUserRoles)
        {
            EmailLinkUrl = emailLinkUrl ?? string.Empty;
            SignupUrl = signupUrl ?? string.Empty;
            InviteUserRoles = inviteUserRoles ?? new InviteUserRoleInfo[] { };
        }

        internal InviteUserRoleInfoCollection(CspInviteUserRoleInfoCollection inviteUserRoles)
        {
            if (inviteUserRoles == null)
            {
                throw new CspResultException($"Argument: {nameof(inviteUserRoles)} was null. Could not create {nameof(InviteUserRoleInfoCollection)}");
            }
            
            EmailLinkUrl = inviteUserRoles.EmailLinkUrl;
            SignupUrl = inviteUserRoles.SignupUrl;
            using var roles = inviteUserRoles.InviteUserRoleInfos;
            InviteUserRoles = roles.DeepCopyToArray();
        }

        internal CspInviteUserRoleInfoCollection ToCspInviteUserRoleInfoCollection()
        {
            var cspInviteUserRoles = new CspInviteUserRoleInfoCollection();
            cspInviteUserRoles.EmailLinkUrl = EmailLinkUrl;
            cspInviteUserRoles.SignupUrl = SignupUrl;
            cspInviteUserRoles.InviteUserRoleInfos = new InviteUserRoleInfoArray(InviteUserRoles);
            return cspInviteUserRoles;
        }
    }
}