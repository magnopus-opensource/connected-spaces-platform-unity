// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;

namespace Magnopus.Foundation.Unity.Runtime.User.Schema
{
    public struct LoginTokenInfo
    {
        public string AccessToken { get; set; }

        public DateTimeOffset? AccessExpiryTime { get; set; }

        public string RefreshToken { get; set; }

        public DateTimeOffset? RefreshExpiryTime { get; set; }
    }
}