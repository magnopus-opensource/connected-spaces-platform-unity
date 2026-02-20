// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using csp.common;
using System;

namespace Magnopus.Foundation.Unity.Runtime.User.Schema
{
    /// <summary>
    /// Wrapper for the <seealso cref="Csp.Common.CancellationToken"/> for our endpoint usage.
    /// </summary>
    public class CspCancellationTokenSource: IDisposable
    {
        internal CancellationToken Token { get; private set; }

        public CspCancellationTokenSource()
        {
            Token = new CancellationToken();
        }

        public void Dispose()
        {
            Token?.Dispose();
            Token = null;
        }

        public void Cancel()
        {
            Token.Cancel();
        }

        public bool IsCancelled()
        {
            return Token.Cancelled();
        }
    }
}