%{
#include "CSP/Multiplayer/Components/CustomSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::CustomSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::CustomSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.CustomSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/CustomSpaceComponent.h"
