%{
#include "CSP/Systems/WebService.h"
%}

%include "CSP/Systems/WebService.h"

%extend csp::systems::ResultBase {
%proxycode %{
#region EXCEPTIONS HANDLING
    /// <summary>
    /// Throws a <seealso cref="FoundationEndpointException"/> if something went wrong. The exception contains the error code.
    /// </summary>
    /// <param name="callingMethodName"> The name of the method that called this extension method. It is used to help log the message of the exception if there is one. </param>
    public void ThrowIfNeeded(string callingMethodName)
    {
        if (this?.GetResultCode() != EResultCode.Success
            || this?.swigCPtr.Handle == System.IntPtr.Zero)
        {
            ushort statusCode = 500;
            string responseBody = null;
            ERequestFailureReason failureReason = 0;
            if (this != null && this?.swigCPtr.Handle != System.IntPtr.Zero)
            {
                statusCode = this.GetHttpResultCode();
                responseBody = this.GetResponseBody();
                failureReason = this.GetFailureReason();
            }

            throw new Magnopus.Extra.Exceptions.FoundationEndpointException(
              $"{callingMethodName} failed.", statusCode, responseBody: responseBody, 
              failureReason: failureReason);
        }
    }
#endregion
%}
}