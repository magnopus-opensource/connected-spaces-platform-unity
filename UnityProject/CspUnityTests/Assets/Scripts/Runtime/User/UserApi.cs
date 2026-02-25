// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;
using System.Net;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using Magnopus.Extra.Exceptions;
using UnityEngine;
using AgoraUserTokenParams = csp.systems.AgoraUserTokenParams;
using AccessControlParams = csp.common.AccessControlChangedNetworkEventData;
using BasicProfile = csp.systems.BasicProfile;
using LoginInfo = csp.common.LoginState;
using LoginTokenInfo = Magnopus.Foundation.Unity.Runtime.User.Schema.LoginTokenInfo;
using Profile = csp.systems.Profile;
using FoundationCommon = csp.common;
using FoundationSystems = csp.systems;

[assembly: InternalsVisibleTo("Magnopus.Foundation.Unity.Tests.Unit", AllInternalsVisible = true)]
namespace Magnopus.Foundation.Unity.Runtime.User
{
    /// <summary>
    /// An API to wrap the Foundation User system endpoints and make it easier for first time users to use.
    /// </summary>
    public class UserApi : IUserApi
    {
        public event Action<LoginTokenInfo> LoginTokenReceived;
        public event Action<AccessControlParams> UserPermissionsChanged;

        private FoundationSystems.UserSystem userSystem;
        private FoundationSystems.ExternalServiceProxySystem externalServiceProxySystem;

        /// <summary>
        /// Constructor for the API. Must be called after the <seealso cref="User.Manager.FoundationManager"/> has been started.
        /// May throw a <seealso cref="FoundationException"/> on error.
        /// </summary>
        internal UserApi(FoundationSystems.UserSystem userSystem, FoundationSystems.ExternalServiceProxySystem externalServiceProxySystem)
        {
            this.userSystem = userSystem ?? throw new CspResultException("Could not get user service");
            this.externalServiceProxySystem = externalServiceProxySystem ?? throw new CspResultException("Could not get external service proxy system");

            // TODO: Uncomment when events are available through SWIG
            //this.userSystem.OnNewLoginTokenReceived += OnNewLoginTokenReceived;
            //this.userSystem.OnUserPermissionsChanged += OnUserPermissionsChangedCallback;
        }

        public void Dispose()
        {
            if (userSystem != null)
            {
                // TODO: Uncomment when events are available through SWIG
                //userSystem.OnNewLoginTokenReceived -= OnNewLoginTokenReceived;
                //userSystem.OnUserPermissionsChanged -= OnUserPermissionsChangedCallback;
            }

            userSystem = null;
        }

        private void OnNewLoginTokenReceived(FoundationSystems.LoginTokenInfoResult loginTokenAccessor)
        {
            if (loginTokenAccessor != null)
            {
                using var tokenInfo = loginTokenAccessor.GetLoginTokenInfo();
                var loginTokenInfo = new LoginTokenInfo()
                {
                    AccessToken = tokenInfo.AccessToken,
                    RefreshToken = tokenInfo.RefreshToken,
                };

                if (DateTimeOffset.TryParse(tokenInfo.AccessExpiryTime, out var accessExpiryDate))
                {
                    loginTokenInfo.AccessExpiryTime = accessExpiryDate;
                }

                if (DateTimeOffset.TryParse(tokenInfo.RefreshExpiryTime, out var refreshExpiryDate))
                {
                    loginTokenInfo.RefreshExpiryTime = refreshExpiryDate;
                }
                LoginTokenReceived?.Invoke(loginTokenInfo);
                return;
            }
            throw new CspResultEndpointException($"Login token was called but found null result.", HttpStatusCode.NotFound);
        }

        private void OnUserPermissionsChangedCallback(FoundationCommon.AccessControlChangedNetworkEventData message)
        {
            if (message == null)
            {
                Debug.LogError("Received null AccessControlChangedNetworkEventData.");
                return;
            }

            try
            {
                // Note: not expecting hotspot data
                UserPermissionsChanged?.Invoke(message);
            }
            catch (Exception ex)
            {
                Debug.LogError($"Error processing AccessControlChangedNetworkEventData: {ex}");
            }
            finally
            {
                message.Dispose();
            }
        }

        /// <summary>Get the current login state.</summary>
        /// <returns>Current login state</returns>
        public LoginInfo GetLoginState()
        {
            FoundationCommon.LoginState result = userSystem.GetLoginState();
            if (result == null)
            {
                throw new CspResultEndpointException("User system did not return a valid login state.", HttpStatusCode.InternalServerError);
            }
            return result;
        }

        /// <summary>
        /// Requests the Foundation layer to Login with email and password.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="email"> email of the user </param>
        /// <param name="password"> password of the user </param>
        /// <param name="createMultiplayerConnection">Whether to create a multiplayer connection.
        /// If false, this session will not establish a SignalR connection to backend services, and thus be unable to
        /// receive messages or events. This session will also be unable to enter online spaces via an OnlineRealtimeEngine.
        /// If true, this session will receive events, and may enter both online and offline spaces.</param>
        /// <param name="userHasVerifiedAge"> Optional: Whether the user has confirmed they are above the required age or not.
        /// Null if the user has not confirmed either.</param>
        /// <param name="tokenOptions">Optional override for default token options.
        /// The default token expiry length is configured by MCS and defaults to 30 minutes.
        /// Value must be less than the default expiry length, or it will be ignored.</param>
        /// <returns> Returns login information </returns>
        public async Task<LoginInfo> LoginAsync(string email, string password, bool createMultiplayerConnection, 
            bool? userHasVerifiedAge, FoundationSystems.TokenOptions? tokenOptions)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(email))
            {
                throw new CspResultEndpointException($"Did not login, parameter: {nameof(email)} was null.", HttpStatusCode.Unauthorized);
            }

            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(password))
            {
                throw new CspResultEndpointException($"Did not login, parameter: {nameof(password)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log($"Logging in with Email {email} ...");

            try
            {
                FoundationSystems.LoginStateResult loginResult = await userSystem.LoginAsync(string.Empty, email,
                    password, createMultiplayerConnection, userHasVerifiedAge, tokenOptions);

                FoundationCommon.LoginState result = loginResult.GetLoginState();
                if (result == null)
                {
                    throw new CspResultEndpointException("Did not login, endpoint result was null.",
                        HttpStatusCode.InternalServerError);
                }

                return result;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Login failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during login: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during login.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to Login with username and password.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="username"> username of the user </param>
        /// <param name="password"> password of the user </param>
        /// <param name="createMultiplayerConnection">Whether to create a multiplayer connection.
        /// If false, this session will not establish a SignalR connection to backend services, and thus be unable to
        /// receive messages or events. This session will also be unable to enter online spaces via an OnlineRealtimeEngine.
        /// If true, this session will receive events, and may enter both online and offline spaces.</param>
        /// <param name="userHasVerifiedAge"> Optional: Whether the user has confirmed they are above the required age or not. Null if the user has not confirmed either.</param>
        /// <param name="tokenOptions">Optional override for default token options.
        /// The default token expiry length is configured by MCS and defaults to 30 minutes.
        /// Value must be less than the default expiry length, or it will be ignored.</param>
        /// <returns> Returns login information </returns>
        public async Task<LoginInfo> LoginWithUsernameAsync(string username, string password, bool createMultiplayerConnection, 
            bool? userHasVerifiedAge, FoundationSystems.TokenOptions? tokenOptions)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(username))
            {
                throw new CspResultEndpointException($"Did not login, parameter: {nameof(username)} was null.", HttpStatusCode.Unauthorized);
            }

            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(password))
            {
                throw new CspResultEndpointException($"Did not login, parameter: {nameof(password)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log($"Logging in with Username {username} ...");

            try
            {
                FoundationSystems.LoginStateResult loginResult = await userSystem.LoginAsync(username, string.Empty,
                    password, createMultiplayerConnection, userHasVerifiedAge, tokenOptions);

                FoundationCommon.LoginState result = loginResult.GetLoginState();
                if (result == null)
                {
                    throw new CspResultEndpointException("Did not login, endpoint result was null.",
                        HttpStatusCode.InternalServerError);
                }

                return result;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Login failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during login: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during login.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to Login as a guest.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="createMultiplayerConnection">Whether to create a multiplayer connection.
        /// If false, this session will not establish a SignalR connection to backend services, and thus be unable to
        /// receive messages or events. This session will also be unable to enter online spaces via OnlineRealtimeEngine.
        /// If true, this session will receive events, and may enter both online and offline spaces.</param>
        /// <param name="guestHasVerifiedAge"> Optional: Whether the guest has confirmed they are above the required age or not.
        /// Null if the guest has not confirmed either.</param>
        /// <param name="tokenOptions">Optional override for default token options.
        /// The default token expiry length is configured by MCS and defaults to 30 minutes.
        /// Value must be less than the default expiry length, or it will be ignored.</param>
        /// <returns> Returns login information </returns>
        public async Task<LoginInfo> LoginAsGuestAsync(bool createMultiplayerConnection, bool? guestHasVerifiedAge, FoundationSystems.TokenOptions? tokenOptions)
        {
            Debug.Log($"Logging in as Guest ...");

            try
            {
                FoundationSystems.LoginStateResult loginResult = await userSystem.LoginAsGuestAsync(
                    createMultiplayerConnection, guestHasVerifiedAge, tokenOptions);

                FoundationCommon.LoginState result = loginResult.GetLoginState();
                if (result == null)
                {
                    throw new CspResultEndpointException("Did not login, endpoint result was null.",
                        HttpStatusCode.InternalServerError);
                }

                return result;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Login failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during login: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during login.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Log in to Magnopus Cloud Services as a guest, allowing the backend to defer profile creation and perform other optimizations.
        /// This login method is intended only for use with offline realtime engines, and as such does not start a multiplayer connection.
        /// @warning Unless you have a good reason, you should prefer the regular LoginAsGuest function.
        /// This method is designed for specific non-multiplayer cases where the backend services are expecting a huge
        /// amount of anonymous profiles and wish to be allowed to buffer profile creation. For this reason, there is an
        /// undefined delay after calling this function until the session can be thought to be conceptually "logged in".
        /// Beware if you are calling user system methods after having logged in using this method.
        /// If you find yourself doing that, you may wish to use the regular <seealso cref="LoginAsGuestAsync"/> method instead.
        /// </summary>
        /// <param name="guestHasVerifiedAge">Optional: Whether the guest has confirmed they are above the required age or not.
        /// Null if the guest has not confirmed either.</param>
        /// <returns></returns>
        /// <exception cref="CspResultEndpointException"></exception>
        public async Task<LoginInfo> LoginAsGuestWithDeferredProfileCreationAsync(bool? guestHasVerifiedAge)
        {
            Debug.Log($"Logging in as Guest with deferred profile creation ...");

            try
            {
                FoundationSystems.LoginStateResult loginResult =
                    await userSystem.LoginAsGuestWithDeferredProfileCreationAsync(guestHasVerifiedAge);

                FoundationCommon.LoginState result = loginResult.GetLoginState();
                if (result == null)
                {
                    throw new CspResultEndpointException("Did not login, endpoint result was null.",
                        HttpStatusCode.InternalServerError);
                }

                return result;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Login failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during login: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during login.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to Login using a refresh token.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="userId"> user Id of the user </param>
        /// <param name="token"> a non-expired, valid authentication or refresh token from a previous login</param>
        /// <param name="createMultiplayerConnection">Whether to create a multiplayer connection.
        /// If false, this session will not establish a SignalR connection to backend services, and thus be unable to
        /// receive messages or events. This session will also be unable to enter online spaces via OnlineRealtimeEngine.
        /// If true, this session will receive events, and may enter both online and offline spaces.</param>
        /// <param name="tokenOptions">Optional override for default token options.
        /// The default token expiry length is configured by MCS and defaults to 30 minutes.
        /// Value must be less than the default expiry length, or it will be ignored.</param>
        /// <returns> Returns login information </returns>
        public async Task<LoginInfo> LoginWithTokenAsync(string userId, string token, bool createMultiplayerConnection, FoundationSystems.TokenOptions? tokenOptions)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(userId))
            {
                throw new CspResultEndpointException($"Did not login, parameter: {nameof(userId)} was null.", HttpStatusCode.Unauthorized);
            }

            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(token))
            {
                throw new CspResultEndpointException($"Did not login, parameter: {nameof(token)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log("Logging in with a Token ...");

            try
            {
                FoundationSystems.LoginStateResult loginResult = await userSystem.LoginWithRefreshTokenAsync(userId,
                    token,
                    createMultiplayerConnection, tokenOptions);

                FoundationCommon.LoginState result = loginResult.GetLoginState();
                if (result == null)
                {
                    throw new CspResultEndpointException("Did not login, endpoint result was null.",
                        HttpStatusCode.InternalServerError);
                }

                return result;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Login failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during login: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during login.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to make the user logout.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <returns> Just the Task object to await, if this endpoint fails, an exception will be thrown </returns>
        public async Task LogoutAsync()
        {
            Debug.Log($"Logging out ...");

            using FoundationSystems.NullResult result = await userSystem.LogoutAsync();
        }

        /// <summary>
        /// Requests the Foundation layer for the authentication token. It is only guaranteed to be valid for the current frame.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <returns> Returns a valid authentication token. Only guaranteed to be valid for the current frame. </returns>
        public string GetValidAuthToken()
        {
            FoundationCommon.LoginState result = userSystem.GetLoginState();
            if (result == null || result.State == FoundationCommon.ELoginState.Error)
            {
                throw new CspResultEndpointException("Did not get auth token, endpoint result experienced an error.", HttpStatusCode.InternalServerError);
            }

            return result.AccessToken;
        }

        /// <summary>
        /// Requests the Foundation layer to create a new account for the user using the given email and password.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="username"> optional username of the new account. Set the Username if you want to be able to login using a username. </param>
        /// <param name="displayName"> visual name that other users may see when connected online </param>
        /// <param name="email"> email of the new account </param>
        /// <param name="password"> password of the new account </param>
        /// <param name="receiveNewsletter"> true if the user wants to receive emails and news updates for the app </param>
        /// <param name="userHasVerifiedAge"> A bool to specify whether or not the user has verified that they are over 18 </param>
        /// <param name="redirectUrl"> optional: url used by the backend services to send the user to the desired page </param>
        /// <param name="inviteToken"> optional: token provided to the user that can be used to auto-confirm their account </param>
        /// <returns> the profile information of the created account </returns>
        public async Task<Profile> CreateUserAsync(string username, string displayName, string email, string password, bool receiveNewsletter, bool userHasVerifiedAge, string redirectUrl, string inviteToken)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(username))
            {
                throw new CspResultEndpointException($"Did not create account, parameter: {nameof(username)} was null.", HttpStatusCode.Unauthorized);
            }

            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(displayName))
            {
                throw new CspResultEndpointException($"Did not create account, parameter: {nameof(displayName)} was null.", HttpStatusCode.Unauthorized);
            }

            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(email))
            {
                throw new CspResultEndpointException($"Did not create account, parameter: {nameof(email)} was null.", HttpStatusCode.Unauthorized);
            }

            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(password))
            {
                throw new CspResultEndpointException($"Did not create account, parameter: {nameof(password)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log($"Creating account with Email {email} ...");

            try
            {
                FoundationSystems.ProfileResult result = await userSystem.CreateUserAsync(username, displayName,
                    email, password, receiveNewsletter, userHasVerifiedAge, redirectUrl, inviteToken);

                var responseBody = result.GetResponseBody();
                Debug.Log($"Profile result response body: {responseBody}");

                FoundationSystems.Profile profile = result.GetProfile();
                if (profile == null)
                {
                    throw new CspResultEndpointException("Did not create account, endpoint result was null.",
                        HttpStatusCode.InternalServerError);
                }

                return profile;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Account creation failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during account creation: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during account creation.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to delete the user's account.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="userId"> the Id of the user you want to EXTERMINATE </param>
        /// <returns> Just the Task object to await, if this endpoint fails, an exception will be thrown </returns>
        public async Task DeleteUserAsync(string userId)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(userId))
            {
                throw new CspResultEndpointException($"Did not delete profile, parameter: {nameof(userId)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log($"Attempting to Delete user: {userId}'s account ...");

            try
            {
                using FoundationSystems.NullResult result = await userSystem.DeleteUserAsync(userId);
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Account deletion failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during account deletion: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during account deletion.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to get the profile info of the given user Id.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="userId"> the Id of the user you want to get the profile of </param>
        /// <returns> the profile info of the found user </returns>
        public async Task<Profile> GetProfileByIdAsync(string userId)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(userId))
            {
                throw new CspResultEndpointException($"Did not get profile, parameter: {nameof(userId)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log($"Getting profile for userId: {userId} ...");

            try
            {
                FoundationSystems.ProfileResult result = await userSystem.GetProfileByUserIdAsync(userId);

                Debug.Log($"Got profile for userId: {userId} ...");

                Debug.Log($"Reading profile from request response ...");

                FoundationSystems.Profile profile = result.GetProfile();

                Debug.Log($"Checking profile from request response ...");

                if (profile == null)
                {
                    throw new CspResultEndpointException("Did not get profile, endpoint result was null.",
                        HttpStatusCode.InternalServerError);
                }

                Debug.Log($"Making DTO for profile from request response ...");

                var responseBody = result.GetResponseBody();
                Debug.Log($"Profile result response body: {responseBody}");

                return profile;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Get profile failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during get profile: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during get profile.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to get a list of minimal profiles (avatarId, personalityType, userName, and platform) by user Ids.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="userIds"> an array of user Ids of profiles you want to get </param>
        /// <returns> the lite Profile information of the requested users </returns>
        public async Task<BasicProfile[]> GetProfilesByUserIdsAsync(string[] userIds)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (userIds == null || userIds.Length == 0)
            {
                throw new CspResultEndpointException($"Did not get profiles, parameter: {nameof(userIds)} was empty.", HttpStatusCode.Unauthorized);
            }

            Debug.Log($"Getting profiles for userIds ...");
            
            using FoundationCommon.StringArray profileArray = new FoundationCommon.StringArray(userIds);

            try
            {
                FoundationSystems.BasicProfilesResult result =
                    await userSystem.GetBasicProfilesByUserIdAsync(profileArray);

                var profiles = result.GetProfiles();
                if (profiles == null)
                {
                    throw new CspResultEndpointException("Did not get profiles, endpoint result was null.",
                        HttpStatusCode.InternalServerError);
                }

                return profiles.DeepCopyToArray();
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Get profiles failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during get profiles: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during get profiles.", HttpStatusCode.InternalServerError, ex);
            }
        }

        // TODO: https://magnopus.atlassian.net/browse/OF-198 get clarity on foundation parameters
        /// <summary>
        /// Requests the Foundation layer to upgrade guest user to a full account.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="userName"> userName of the new account for the guest user </param>
        /// <param name="displayName"> visual name for the new account that other users may see when connected online </param>
        /// <param name="email"> email of the new account for the guest user </param>
        /// <param name="password"> password of the new account for the guest user </param>
        /// <returns> the new profile for the newly upgraded guest user </returns>
        public async Task<Profile> UpgradeGuestAccountAsync(string userName, string displayName, string email, string password)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(email))
            {
                throw new CspResultEndpointException($"Did not upgrade guest account, parameter: {nameof(email)} was null.", HttpStatusCode.Unauthorized);
            }
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(password))
            {
                throw new CspResultEndpointException($"Did not upgrade guest account, parameter: {nameof(password)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log("Upgrading Guest account ...");

            try
            {
                FoundationSystems.ProfileResult result =
                    await userSystem.UpgradeGuestAccountAsync(userName, displayName, email, password);

                FoundationSystems.Profile profile = result.GetProfile();
                if (profile == null)
                {
                    throw new CspResultEndpointException("Did not upgrade guest account, endpoint result was null.",
                        HttpStatusCode.InternalServerError);
                }

                var responseBody = result.GetResponseBody();
                Debug.Log($"Profile result response body: {responseBody}");

                return profile;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Upgrade guest account failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during upgrade guest account: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during upgrade guest account.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to send a confirmation email for the newly created account. Used if the previous email link timed out.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <returns> Just the Task object to await, if this endpoint fails, an exception will be thrown </returns>
        public async Task ConfirmUserEmailAsync()
        {
            Debug.Log("Sending confirmation email to current user ...");

            try
            {
                using FoundationSystems.NullResult result = await userSystem.ConfirmUserEmailAsync();
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Send confirmation email failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during send confirmation email: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during send confirmation email.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to reset the user's password.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="token">Token received through email by user.</param>
        /// <param name="userId">The id of the user resetting their password</param>
        /// <param name="newPassword">The new password for the associated account.</param>
        /// <returns> Just the Task object to await, if this endpoint fails, an exception will be thrown </returns>
        public async Task ResetUserPasswordAsync(string token, string userId, string newPassword)
        {
            Debug.Log("Resetting the user's password ...");

            try
            {
                using FoundationSystems.NullResult result = await userSystem.ResetUserPasswordAsync(token, userId, newPassword);
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Reset user password failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during reset user password: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during reset user password.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to send an email to the user to reset their password by providing an email address.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="email"> email to send a link to </param>
        /// <param name="emailLinkUrl">The url inside the reset email sent to the user</param>
        /// <param name="redirectUrl"> optional URL to redirect the user to after they have registered </param>
        /// <param name="useTokenChangePasswordUrl"> if true the link in the email will direct the user to the Token Change URL </param>
        /// <returns> Just the Task object to await, if this endpoint fails, an exception will be thrown </returns>
        public async Task ForgotPasswordAsync(string email,string emailLinkUrl, string redirectUrl, bool useTokenChangePasswordUrl)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(email))
            {
                throw new CspResultEndpointException($"Did not send email for forgotten password, parameter: {nameof(email)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log($"Sending forgot password email to email: {email} ...");

            try
            {
                using FoundationSystems.NullResult result =
                    await userSystem.ForgotPasswordAsync(email, emailLinkUrl, redirectUrl, useTokenChangePasswordUrl);
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Forgot password failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during forgot password: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during forgot password.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to update the user's display name.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="userId"> user Id of the user </param>
        /// <param name="newUserDisplayName"> new display name to use </param>
        /// <returns> Just the Task object to await, if this endpoint fails, an exception will be thrown </returns>
        public async Task UpdateUserDisplayNameAsync(string userId, string newUserDisplayName)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(userId))
            {
                throw new CspResultEndpointException($"Did not update user display name, parameter: {nameof(userId)} was null.", HttpStatusCode.Unauthorized);
            }
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(newUserDisplayName))
            {
                throw new CspResultEndpointException($"Did not update user display name, parameter: {nameof(newUserDisplayName)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log("Updating user's display name ...");

            try
            {
                using FoundationSystems.NullResult result =
                    await userSystem.UpdateUserDisplayNameAsync(userId, newUserDisplayName);
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Update user display name failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during update user display name: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during update user display name.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Endpoint to retrieve the FDN supported 3rd party authentication providers
        /// </summary>
        /// <returns> Array of FDN supported 3rd party authentication providers </returns>
        public FoundationCommon.EThirdPartyAuthenticationProvidersArray GetSupportedThirdPartyAuthenticationProviders()
        {
            return userSystem.GetSupportedThirdPartyAuthenticationProviders();
        }

        /// <summary>
        /// Requests the Foundation layer to get the 'Authorize' Url from the third party provider.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <remarks> First step of the 3rd party authentication flow.
        /// If you call this API but for some reason you'd like to call this again, this is supported, the params you pass second time will replace the
        /// ones you've passed initially </remarks>
        /// <param name="authProvider"> one of the supported Authentication Providers </param>
        /// <param name="redirectURL"> the RedirectURL you want to be used for this authentication flow </param>
        /// <returns> the Authorise URL that the Client should be navigating next before moving to the second FDN Authentication step </returns>
        public async Task<string> GetThirdPartyProviderAuthorizeUrlAsync(
            FoundationSystems.EThirdPartyAuthenticationProviders authProvider, string redirectURL)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (authProvider == FoundationSystems.EThirdPartyAuthenticationProviders.Invalid || 
                authProvider == FoundationSystems.EThirdPartyAuthenticationProviders.Num)
            {
                throw new CspResultEndpointException($"Did not get authorize url, parameter: {nameof(authProvider)} was invalid.", HttpStatusCode.Unauthorized);
            }

            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(redirectURL))
            {
                throw new CspResultEndpointException($"Did not get authorize url, parameter: {nameof(redirectURL)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log("Getting third party provider authorize Url ...");

            try
            {
                using FoundationSystems.StringResult result =
                    await userSystem.GetThirdPartyProviderAuthoriseURLAsync(authProvider, redirectURL);

                string response = result.GetValue();

                return response;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Get third party provider authorize url failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during get third party provider authorize url: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during get third party provider authorize url.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to login to CHS using the third party authentication data.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <remarks> Second step of the 3rd party authentication flow.
        /// Note: The Authentication Provider and the Redirect URL you've passed in the first step will be used now </remarks>
        /// <param name="thirdPartyToken"> The authentication token returned by the Provider </param>
        /// <param name="thirdPartyStateId"> The state Id returned by the Provider </param>
        /// <param name="createMultiplayerConnection">Whether to create a multiplayer connection.
        /// If false, this session will not establish a SignalR connection to backend services, and thus be unable to
        /// receive messages or events. This session will also be unable to enter online spaces via OnlineRealtimeEngine.
        /// If true, this session will receive events, and may enter both online and offline spaces.</param>
        /// <param name="userHasVerifiedAge">An optional bool to specify whether the user has verified that they are over 18</param>
        /// <param name="tokenOptions">Optional override for default token options.
        /// The default token expiry length is configured by MCS and defaults to 30 minutes.
        /// Value must be less than the default expiry length, or it will be ignored.</param>
        /// <returns> the result of the CHS Authentication operation </returns>
        public async Task<LoginInfo> LoginToThirdPartyAuthenticationProviderAsync(string thirdPartyToken, 
            string thirdPartyStateId, bool createMultiplayerConnection, bool? userHasVerifiedAge, FoundationSystems.TokenOptions? tokenOptions)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(thirdPartyToken))
            {
                throw new CspResultEndpointException($"Did not login, parameter: {nameof(thirdPartyToken)} was null.", HttpStatusCode.Unauthorized);
            }

            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(thirdPartyStateId))
            {
                throw new CspResultEndpointException($"Did not login, parameter: {nameof(thirdPartyStateId)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log("Logging in with third party auth details ...");

            try
            {
                using FoundationSystems.LoginStateResult loginResult =
                    await userSystem.LoginToThirdPartyAuthenticationProviderAsync(
                        thirdPartyToken, thirdPartyStateId, createMultiplayerConnection, userHasVerifiedAge,
                        tokenOptions);

                FoundationCommon.LoginState result = loginResult.GetLoginState();
                if (result == null)
                {
                    throw new CspResultEndpointException("Did not login, endpoint result was null.",
                        HttpStatusCode.InternalServerError);
                }

                return result;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Login failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during login: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during login.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the Foundation layer to retrieve the User token from Agora.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="tokenParams"> Parameters to configure the User token </param>
        /// <returns> The Agora User Token </returns>
        public async Task<string> GetAgoraUserTokenAsync(AgoraUserTokenParams tokenParams)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrEmpty(tokenParams.AgoraUserId))
            {
                throw new CspResultEndpointException($"Did not get token, parameter: {nameof(tokenParams)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log("Getting Agora user token ...");

            try
            {
                using FoundationSystems.StringResult result =
                    await externalServiceProxySystem.GetAgoraUserTokenAsync(tokenParams);

                string token = result.GetValue();
                return token;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Get Agora user token failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during get Agora user token: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during get Agora user token.", HttpStatusCode.InternalServerError, ex);
            }
        }
        
        /// <summary>
        /// Requests the Foundation layer to retrieve the url for a user customer portal request for accessing Stripe account.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="userId"> user Id of the user </param>
        /// <returns> The user's customer portal URL</returns>
        public async Task<string> GetCustomerPortalUrlAsync(string userId)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(userId))
            {
                throw new CspResultEndpointException($"Did not update user display name, parameter: {nameof(userId)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log("Getting customer portal Url...");

            try
            {
                using FoundationSystems.StringResult result = await userSystem.GetCustomerPortalUrlAsync(userId);

                string url = result.GetValue();
                return url;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Get customer portal url failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during get customer portal url: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during get customer portal url.", HttpStatusCode.InternalServerError, ex);
            }
        }
        
        /// <summary>
        /// Requests the Foundation layer to retrieve the checkout session url for a specific pricing Tier.
        /// May throw a <seealso cref="CspResultEndpointException"/> on error.
        /// </summary>
        /// <param name="tierName"> The tier for which to retrieve the checkout session Url. </param>
        /// <returns> The tier's checkout session URL</returns>
        public async Task<string> GetCheckoutSessionUrlAsync(FoundationSystems.TierNames tierName)
        {
            Debug.Log($"Getting Checkout Session Url for {tierName} ...");

            try
            {
                using FoundationSystems.StringResult result = await userSystem.GetCheckoutSessionUrlAsync(tierName);

                string url = result.GetValue();
                return url;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Get checkout session url failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during get checkout session url: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during get checkout session url.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Requests the CSP layer to re-send the user verification email.
        /// </summary>
        /// <param name="inEmail">User's email address</param>
        /// <param name="inRedirectUrl"></param>
        /// <exception cref="CspResultEndpointException">URL to redirect user to after they have verified.</exception>
        public async Task ResendVerificationEmail(string inEmail, string inRedirectUrl)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(inEmail))
            {
                throw new CspResultEndpointException($"Did not update user display name, parameter: {nameof(inEmail)} was null.", HttpStatusCode.Unauthorized);
            }
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrWhiteSpace(inRedirectUrl))
            {
                throw new CspResultEndpointException($"Did not update user display name, parameter: {nameof(inRedirectUrl)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log("Requesting re-send of verificaiton email ...");

            try
            {
                using FoundationSystems.NullResult result =
                    await userSystem.ResendVerificationEmailAsync(inEmail, inRedirectUrl);
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Resend verification email failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during resend verification email: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during resend verification email.", HttpStatusCode.InternalServerError, ex);
            }
        }

        /// <summary>
        /// Post Service Proxy to perform specified operation of specified service
        /// </summary>
        /// <returns> The result of the request </returns>
        /// <exception cref="CspResultEndpointException"></exception>
        public async Task<string> PostServiceProxy(csp.systems.ExternalServicesOperationParams tokenParams)
        {
            // TODO: https://magnopus.atlassian.net/browse/OF-207 don't check params once foundation does
            if (string.IsNullOrEmpty(tokenParams.ServiceName))
            {
                throw new CspResultEndpointException($"Did not post service proxy, parameter: {nameof(tokenParams.ServiceName)} was null.", HttpStatusCode.Unauthorized);
            }

            Debug.Log("Posting Service Proxy...");

            try
            {
                using FoundationSystems.StringResult result =
                    await externalServiceProxySystem.InvokeOperationAsync(tokenParams);

                string resultStr = result.GetValue();
                return resultStr;
            }
            catch (CspResultEndpointException ex)
            {
                Debug.LogError($"Post service proxy failed: {ex.Message}");
                throw;
            }
            catch (Exception ex)
            {
                Debug.LogError($"An unexpected error occurred during post service proxy: {ex}");
                throw new CspResultEndpointException("An unexpected error occurred during post service proxy.", HttpStatusCode.InternalServerError, ex);
            }
        }
    }
}