// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;

namespace Magnopus.Extra.Exceptions
{
    /// <summary>
    /// Base exception for the OKO Founation Unity package. All exceptions will inherit from this.
    /// </summary>
    public class FoundationException : Exception
    {
        public FoundationException(string message)
            : base(message)
        {
        }

        public FoundationException(string message, Exception innerException)
            : base(message, innerException)
        {
        }

        /// <summary>
        /// ToString override that includes the <see cref="StatusCode"/> and <see cref="ResponseBody"/>.
        /// The implementation is approximately based upon <see cref="Exception.ToString()"/>
        /// but does not localise the strings used.
        /// </summary>
        /// <returns>String representation of the exception.</returns>
        public override string ToString()
        {
            string result = $"{GetType()}";
            if (!string.IsNullOrWhiteSpace(Message))
            {
                result = $"{result}: {Message}";
            }

            if (InnerException != null)
            {
                result = $"{result}{Environment.NewLine} ---> {InnerException}{Environment.NewLine}   ---End of inner exception stack trace ---";
            }

            if (StackTrace != null)
            {
                result = $"{result}{Environment.NewLine}{StackTrace}";
            }

            return result;
        }
    }
}