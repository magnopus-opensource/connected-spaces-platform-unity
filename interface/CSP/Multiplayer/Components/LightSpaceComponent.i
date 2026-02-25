%{
#include "CSP/Multiplayer/Components/LightSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::LightSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::LightSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.LightSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/LightSpaceComponent.h"
