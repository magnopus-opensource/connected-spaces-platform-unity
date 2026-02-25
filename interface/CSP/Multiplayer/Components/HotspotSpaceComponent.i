%{
#include "CSP/Multiplayer/Components/HotspotSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::HotspotSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::HotspotSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.HotspotSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/HotspotSpaceComponent.h"
