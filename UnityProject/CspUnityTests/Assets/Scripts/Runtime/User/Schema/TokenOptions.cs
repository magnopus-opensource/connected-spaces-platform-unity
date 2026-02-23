// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Extra.Exceptions;
using CspTokenOptions = csp.systems.TokenOptions;

namespace Magnopus.Foundation.Unity.Runtime.User.Schema
{
    /// <summary>
    /// The length of time for a token to expire formatted as "HH:MM:SS", must be between "00:00:01" and "00:30:00"
    /// The default token expiry length is configured by MCS and defaults to 30 minutes.
    /// Value must be less than the default expiry length, or it will be ignored.
    /// </summary>
    public struct TokenOptions
    {
        public string AccessTokenExpiryLength { get; set; }
        
        public TokenOptions(string accessTokenExpiryLength)
        {
            AccessTokenExpiryLength  = accessTokenExpiryLength;
        }
        
        internal TokenOptions(CspTokenOptions tokenOptions)
        {
            if (tokenOptions == null)
            {
                throw new CspResultException($"Argument: {nameof(tokenOptions)} was null. Could not create {nameof(TokenOptions)}");
            }

            AccessTokenExpiryLength = tokenOptions.AccessTokenExpiryLength;
        }

        internal CspTokenOptions ToCspTokenOptions()
        {
            var cspTokenOptions = new CspTokenOptions();
            cspTokenOptions.AccessTokenExpiryLength = AccessTokenExpiryLength;
            return cspTokenOptions;
        }
    }
}