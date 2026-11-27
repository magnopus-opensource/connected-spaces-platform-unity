%{
#include "CSP/Systems/Script/ScriptSystem.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ScriptErrorData)

//This type inherits from a type in another namespace (common, IJSScriptRunner), so we need the using directive
%typemap(csimports) csp::systems::ScriptSystem %{
using csp.common;
%}

%include "CSP/Systems/Script/ScriptSystem.h"
