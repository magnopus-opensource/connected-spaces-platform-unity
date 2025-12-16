// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;
using System.Net;

namespace Magnopus.Extra.Exceptions
{
    /// <summary>
    /// A custom exception to store the Web Status Code along with a message.
    /// </summary>
    public class FoundationEndpointException : FoundationException
    {
        public ushort StatusCode { get; private set; }

        public string ResponseBody { get; private set; }

        public csp.systems.ERequestFailureReason FailureReason { get; private set; }

        public FoundationEndpointException(string message, ushort statusCode, string responseBody = null, csp.systems.ERequestFailureReason failureReason = 0)
            : base(message)
        {
            StatusCode = statusCode;
            ResponseBody = responseBody;
            FailureReason = failureReason;
        }

        public FoundationEndpointException(string message, ushort statusCode, Exception innerException, string responseBody = null, csp.systems.ERequestFailureReason failureReason = 0)
            : base(message, innerException)
        {
            StatusCode = statusCode;
            ResponseBody = responseBody;
            FailureReason = failureReason;
        }

        public FoundationEndpointException(string message, HttpStatusCode statusCode, string responseBody = null, csp.systems.ERequestFailureReason failureReason = 0)
            : base(message)
        {
            StatusCode = (ushort)statusCode;
            ResponseBody = responseBody;
            FailureReason = failureReason;
        }

        public FoundationEndpointException(string message, HttpStatusCode statusCode, Exception innerException, string responseBody = null, csp.systems.ERequestFailureReason failureReason = 0)
            : base(message, innerException)
        {
            StatusCode = (ushort)statusCode;
            ResponseBody = responseBody;
            FailureReason = failureReason;
        }

        /// <summary>
        /// ToString override that includes the <see cref="StatusCode"/>, <see cref="FailureReason"/>, and <see cref="ResponseBody"/>.
        /// The implementation is approximately based upon <see cref="Exception.ToString()"/>
        /// but does not localise the strings used.
        /// </summary>
        /// <returns>String representation of the exception.</returns>
        public override string ToString()
        {
            string result;
            if (string.IsNullOrWhiteSpace(Message))
            {
                result = $"{GetType()}{Environment.NewLine}Status Code:{StatusCode}{Environment.NewLine}Failure Reason:{FailureReason}{Environment.NewLine}Response Body:{Environment.NewLine}{(string.IsNullOrWhiteSpace(ResponseBody) ? "(Empty)" : ResponseBody)}";
            }
            else
            {
                result = $"{GetType()}: {Message}{Environment.NewLine}Status Code:{StatusCode}{Environment.NewLine}Failure Reason:{FailureReason}{Environment.NewLine}Response Body:{Environment.NewLine}{(string.IsNullOrWhiteSpace(ResponseBody) ? "(Empty)" : ResponseBody)}";
            }

            if (InnerException != null)
            {
                result = $"{result}{ Environment.NewLine} ---> { InnerException} { Environment.NewLine}   ---End of inner exception stack trace ---";
            }

            if (StackTrace != null)
            {
                result = $"{result}{Environment.NewLine}{StackTrace}";
            }

            return result;
        }
    }
}