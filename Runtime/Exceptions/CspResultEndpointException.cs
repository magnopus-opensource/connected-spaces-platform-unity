// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;
using System.Net;
using System.Text;

namespace Magnopus.Extra.Exceptions
{
    /// <summary>
    /// A custom exception to store the Web Status Code along with a message.
    /// </summary>
    public class CspResultEndpointException : CspResultException
    {
        public ushort StatusCode { get; private set; }

        public string ResponseBody { get; private set; }

        public csp.systems.ERequestFailureReason FailureReason { get; private set; }

        public CspResultEndpointException(string message, ushort statusCode, string responseBody = null, csp.systems.ERequestFailureReason failureReason = 0)
            : base(message)
        {
            StatusCode = statusCode;
            ResponseBody = responseBody;
            FailureReason = failureReason;
        }

        public CspResultEndpointException(string message, ushort statusCode, Exception innerException, string responseBody = null, csp.systems.ERequestFailureReason failureReason = 0)
            : base(message, innerException)
        {
            StatusCode = statusCode;
            ResponseBody = responseBody;
            FailureReason = failureReason;
        }

        public CspResultEndpointException(string message, HttpStatusCode statusCode, string responseBody = null, csp.systems.ERequestFailureReason failureReason = 0)
            : base(message)
        {
            StatusCode = (ushort)statusCode;
            ResponseBody = responseBody;
            FailureReason = failureReason;
        }

        public CspResultEndpointException(string message, HttpStatusCode statusCode, Exception innerException, string responseBody = null, csp.systems.ERequestFailureReason failureReason = 0)
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
            var sb = new StringBuilder();

            sb.Append(GetType());

            if (!string.IsNullOrWhiteSpace(Message))
            {
                sb.Append(": ").Append(Message);
            }

            sb.AppendLine()
                .Append("Status Code:").AppendLine(StatusCode.ToString())
                .Append("Failure Reason:").AppendLine(FailureReason.ToString())
                .AppendLine("Response Body:")
                .AppendLine(string.IsNullOrWhiteSpace(ResponseBody) ? "(Empty)" : ResponseBody);

            if (InnerException != null)
            {
                sb.AppendLine()
                    .Append(" ---> ").Append(InnerException)
                    .AppendLine()
                    .Append("   --- End of inner exception stack trace ---");
            }

            if (StackTrace != null)
            {
                sb.AppendLine()
                    .Append(StackTrace);
            }

            return sb.ToString();
        }
    }
}