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
