%{
#include "CSP/Multiplayer/Components/FogSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::FogSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::FogSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.FogSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/FogSpaceComponent.h"
