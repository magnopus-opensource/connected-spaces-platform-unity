%{
#include "CSP/Systems/Script/ScriptSystem.h"
%}

//This type inherits from a type in another namespace (common, IJSScriptRunner), so we need the using directive
%typemap(csimports) csp::systems::ScriptSystem %{
using csp.common;
%}

%include "CSP/Systems/Script/ScriptSystem.h"
