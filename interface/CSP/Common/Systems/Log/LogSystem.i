%{
#include "CSP/Systems/SystemsResult.h"
#include "CSP/Common/Systems/Log/LogSystem.h"
#include <thread>
#include <chrono>
%}

// START: This section injects code to allow us to test async functions in LogSystem.
// This approach is temporary and only for testing purposes. We should not make this a habit.
// The correct fix would be to update CSP accordingly.
%include "CSP/Systems/WebService.i"

%inline  %{
namespace extra
{
    namespace test
    {
        class TestBooleanResult : public csp::systems::ResultBase
        {
            public:

            TestBooleanResult(csp::systems::EResultCode ResCode, uint16_t HttpResCode) 
                : ResultBase(ResCode, HttpResCode) {}

            TestBooleanResult(csp::systems::EResultCode ResCode, uint16_t HttpResCode, csp::systems::ERequestFailureReason Reason)
                : ResultBase(ResCode, HttpResCode, Reason) {}

            void SetResult(csp::systems::EResultCode ResCode, uint16_t HttpResCode)
            {
                ResultBase::SetResult(ResCode, HttpResCode);
            }

            void SetValue(bool InValue)
            {
                Value = InValue;
            }

            bool GetValue() const
            {
                return Value;
            }

            private:

            bool Value;            
        };

        // Custom callback we can use for our async function testing.
        // Note: we pass result by value, not by reference, because C++ does not have a way
        // to know when C# will stop using the result, and C++ is responsible for the memory
        // deallocation for it. So, to avoid crashes due to access violation to the
        // memory of result we pass a copy of it to be safer.
        typedef std::function<void(TestBooleanResult)> TestBooleanResultCallback;
    }
}
%}

%feature("director") extra::test::TestBooleanResultCallback;
// END: This section injects code to allow us to test async functions in LogSystem.

%include "CSP/Common/Systems/Log/LogSystem.h"

// Helper macro to wrap director callbacks in try/catch blocks to convert native exceptions into C# exceptions, 
// since C# won't be able to catch native exceptions thrown across the async boundary.
// NOTE: THIS NEEDS TO BE DECLARED BEFORE THE FUNCTION DECLARATION, OTHERWISE SWIG DOES NOT WRAP THE FUNCTION IN A TRY/CATCH BLOCK!
%exception csp::common::LogSystem::LogAndThrow {
    try {
        $action
    }
    catch (const std::exception& e) {
        SWIG_CSharpSetPendingException(
            SWIG_CSharpApplicationException,
            e.what()
        );
    }
}

%exception csp::common::LogSystem::ThrowImmediately {
    try {
        $action
    }
    catch (const std::exception& e) {
        SWIG_CSharpSetPendingException(
            SWIG_CSharpApplicationException,
            e.what()
        );
    }
}

%extend csp::common::LogSystem 
{
    /// <summary>
    /// Logs a boolean value after a delay of a specified number of seconds.
    /// If true is passed, completes successfully.
    /// If false is passed, throws via ResultBase.
    /// </summary>
    void LogAfterSeconds(bool value, int seconds, extra::test::TestBooleanResultCallback callback)
    {
        std::thread([value, seconds, callback]() mutable {

            std::this_thread::sleep_for(
                std::chrono::seconds(seconds)
            );

            // Construct *test-only* result, which derives from ResultBase
            extra::test::TestBooleanResult result(
                value ? csp::systems::EResultCode::Success
                      : csp::systems::EResultCode::Failed,
                value ? 200 : 500
            );

            result.SetValue(value);

            // Invoke callback (director-safe)
            callback(result);

        }).detach();
    }

    /// <summary> 
	/// Throws an exception to test that it is properly propagated to C#.
	/// </summary>
    void LogAndThrow(extra::test::TestBooleanResultCallback callback)
	{
		// Note: not doing anything with the callback to see if the swig exception handling works even when the callback is not invoked.
	    std::thread([callback]() mutable {
	        try {
	            throw std::runtime_error("Native async exception from SWIG");
	        }
	        catch (const std::exception& e) {
	            // SWIG-safe way to propagate to C#
	            SWIG_CSharpSetPendingException(SWIG_CSharpApplicationException, e.what());
	        }
	    }).detach();
	}

	/// <summary>
    /// Synchronously throws an exception to test that it is properly propagated to C#. 
    /// </summary>
	void ThrowImmediately()
    {
        throw std::runtime_error("Native synchronous failure");
    }
}

/* LoginSystem Async functions */
MAKE_ASYNC(csp::common::LogSystem,
          LogAfterSeconds,
          TestBooleanResultCallback,
          LogSystem_TestBooleanResultCallbackCSharpAdapter,
          ARGLIST(extra.test.TestBooleanResult result),
          ARGLIST(extra.test.TestBooleanResult),
          ARGLIST(result),
		  ARGLIST(bool boolValue, int seconds),
		  ARGLIST(boolValue, seconds)
)

MAKE_ASYNC_ZERO(csp::common::LogSystem,
          LogAndThrow,
          TestBooleanResultCallback,
          LogSystem_TestBooleanResultCallbackCSharpAdapter,
          ARGLIST(extra.test.TestBooleanResult result),
          ARGLIST(extra.test.TestBooleanResult),
          ARGLIST(result)
)
