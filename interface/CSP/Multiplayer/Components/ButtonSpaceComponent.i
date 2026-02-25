%{
#include "CSP/Multiplayer/Components/ButtonSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::ButtonSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::ButtonSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.ButtonSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/ButtonSpaceComponent.h"
