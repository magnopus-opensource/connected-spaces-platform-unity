// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Extra.Exceptions;
using CspLoginState = csp.common.LoginState;

namespace Magnopus.Foundation.Unity.Runtime.User.Schema
{
    /// <summary>
    /// Data transfer object for login state data.  This represents <see cref="CspLoginState"/>
    /// </summary>
    public struct LoginState
    {
        public csp.common.ELoginState State { get; set; }
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
        public string UserId { get; set; }
        public string DeviceId { get; set; }
        
        internal LoginState(CspLoginState loginState)
        {
            if (loginState == null)
            {
                throw new CspResultException($"Argument: {nameof(loginState)} was null. Could not create the {nameof(LoginState)}");
            }

            State = loginState.State;
            AccessToken = loginState.AccessToken;
            RefreshToken = loginState.RefreshToken;
            UserId = loginState.UserId;
            DeviceId = loginState.DeviceId;
        }
              
        internal CspLoginState ToFoundationLoginState()
        {
            var loginState = new CspLoginState();
            loginState.State = this.State;
            loginState.AccessToken = this.AccessToken;
            loginState.RefreshToken = this.RefreshToken;
            loginState.UserId = this.UserId;
            loginState.DeviceId = this.DeviceId;
            return loginState;
        }
    }
}