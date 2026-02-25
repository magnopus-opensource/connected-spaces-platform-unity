%{
#include "CSP/Multiplayer/Components/PortalSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::PortalSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::PortalSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.PortalSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/PortalSpaceComponent.h"
