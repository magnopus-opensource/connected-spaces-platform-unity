%{
#include "CSP/Systems/WebService.h"
%}

%include "CSP/Systems/WebService.h"

/************************************************************
 * THROW ON FAILURE SECTION — ENABLED WITH:
 *   cmake -DTHROW_EXCEPTION_ON_RESULTBASE_FAILURE=ON
 ************************************************************/
#ifdef THROW_EXCEPTION_ON_RESULTBASE_FAILURE

%extend csp::systems::ResultBase {
%proxycode %{
#region EXCEPTIONS HANDLING
    /// <summary>
    /// Throws a <seealso cref="CspResultEndpointException"/> if something went wrong. The exception contains the error code.
    /// </summary>
    /// <param name="callingMethodName"> The name of the method that called this extension method. It is used to help log the message of the exception if there is one. </param>
    public void ThrowOnFailure(string callingMethodName)
    {
        if (swigCPtr == null || swigCPtr.Handle == System.IntPtr.Zero)
        {
            throw new System.InvalidOperationException(
                $"{callingMethodName} failed. Native poitner has already been disposed."
            );
        }

        var resultCode = GetResultCode();
        if (resultCode == EResultCode.Failed)
        {
            ushort statusCode = this.GetHttpResultCode();
            string responseBody = this.GetResponseBody();
            ERequestFailureReason failureReason = this.GetFailureReason();

            throw new Magnopus.Extra.Exceptions.CspResultEndpointException(
              $"{callingMethodName} failed.", statusCode, responseBody: responseBody, 
              failureReason: failureReason);
        }
    }
#endregion
%}
}

#endif