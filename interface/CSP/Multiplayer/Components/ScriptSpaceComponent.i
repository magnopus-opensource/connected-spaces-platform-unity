%{
#include "CSP/Multiplayer/Components/ScriptSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::ScriptSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::ScriptSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.ScriptSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/ScriptSpaceComponent.h"
