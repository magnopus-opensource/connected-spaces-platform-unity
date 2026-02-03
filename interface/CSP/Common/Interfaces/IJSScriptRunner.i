%{
#include "CSP/Common/Interfaces/IJSScriptRunner.h"
%}

%interface_impl(csp::common::IJSScriptRunner);
%include "CSP/Common/Interfaces/IJSScriptRunner.h"



// A temporary empty IJSScriptRunner implementation such that we can test things.
// Normally you just get the script system and use that as you IJSScriptRunner.
%inline  %{
namespace csp
{
    namespace common{
        class TempMockScriptRunner : public csp::common::IJSScriptRunner
        {
            public:
            bool RunScript(int64_t ContextId, const csp::common::String& ScriptText) override
            {
                return true;
            }
            void RegisterScriptBinding (csp::common::IScriptBinding* /*ScriptBinding*/) override {}
            void UnregisterScriptBinding(csp::common::IScriptBinding* /*ScriptBinding*/) override {}

            bool BindContext(int64_t /*ContextID*/) override {return true;}
            bool ResetContext(int64_t /*ContextID*/) override {return true;}
            void* GetContext(int64_t /*ContextID*/) override {return nullptr;}

            void* GetModule(int64_t /*ContextID*/, const csp::common::String& /*ModuleName*/) override {return nullptr;}

            bool CreateContext(int64_t /*ContextID*/) override {return true;}
            bool DestroyContext(int64_t /*ContextID*/) override {return true;}

            void SetModuleSource(csp::common::String /*ModuleUrl*/, csp::common::String /*Source*/) override {}
            void ClearModuleSource(csp::common::String /*ModuleUrl*/) override {}
        };

    }
}
%}
