// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;
using System.Threading.Tasks;
using csp.common;
using AgoraUserTokenParams = csp.systems.AgoraUserTokenParams;
using BasicProfile = csp.systems.BasicProfile;
using LoginInfo = csp.common.LoginState;
using LoginTokenInfo = Magnopus.Foundation.Unity.Runtime.User.Schema.LoginTokenInfo;
using Profile = csp.systems.Profile;
using TokenInfoParams = csp.systems.ExternalServicesOperationParams;
using FoundationSystems = csp.systems;

namespace Magnopus.Foundation.Unity.Runtime.User
{
    /// <summary>
    /// Interface for the User API to wrap User endpoints
    /// </summary>
    public interface IUserApi : IDisposable
    {
        event Action<LoginTokenInfo> LoginTokenReceived;
        event Action<AccessControlChangedNetworkEventData> UserPermissionsChanged;

        LoginState GetLoginState();
        Task<LoginInfo> LoginAsync(string email, string password, bool createMultiplayerConnection, 
            bool? userHasVerifiedAge, FoundationSystems.TokenOptions? tokenOptions);
        Task<LoginInfo> LoginAsGuestAsync(bool createMultiplayerConnection, bool? guestHasVerifiedAge, FoundationSystems.TokenOptions? tokenOptions);
        Task<LoginInfo> LoginAsGuestWithDeferredProfileCreationAsync(bool? guestHasVerifiedAge);
        Task<LoginInfo> LoginWithTokenAsync(string userId, string token, bool createMultiplayerConnection, FoundationSystems.TokenOptions? tokenOptions);
        Task LogoutAsync();
        string GetValidAuthToken();
        Task<Profile> CreateUserAsync(string displayName, string email, string password, bool receiveNewsletter, bool userHasVerifiedAge, string redirectUrl, string inviteToken);
        Task DeleteUserAsync(string userId);
        Task<Profile> GetProfileByIdAsync(string userId);
        Task<BasicProfile[]> GetProfilesByUserIdsAsync(string[] userIds);
        Task<Profile> UpgradeGuestAccountAsync(string userName, string displayName, string email, string password);
        Task ConfirmUserEmailAsync();
        Task ResetUserPasswordAsync(string token, string userId, string newPassword);
        Task ForgotPasswordAsync(string email, string emailLinkUrl, string redirectUrl, bool useTokenChangePasswordUrl);
        Task UpdateUserDisplayNameAsync(string userId, string newUserDisplayName);
        EThirdPartyAuthenticationProvidersArray GetSupportedThirdPartyAuthenticationProviders();
        Task<string> GetThirdPartyProviderAuthorizeUrlAsync(FoundationSystems.EThirdPartyAuthenticationProviders authProvider, string redirectURL);
        Task<LoginInfo> LoginToThirdPartyAuthenticationProviderAsync(string thirdPartyToken, 
            string thirdPartyStateId, bool createMultiplayerConnection, bool? userHasVerifiedAge, FoundationSystems.TokenOptions? tokenOptions);
        Task<string> GetAgoraUserTokenAsync(AgoraUserTokenParams tokenParams);
        Task<string> GetCustomerPortalUrlAsync(string userId);
        Task<string> GetCheckoutSessionUrlAsync(FoundationSystems.TierNames tierName);
        Task ResendVerificationEmail(string inEmail, string inRedirectUrl);
        Task<string> PostServiceProxy(TokenInfoParams tokenParams);
    }
}