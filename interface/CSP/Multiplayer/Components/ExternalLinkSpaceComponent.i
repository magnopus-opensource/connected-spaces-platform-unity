%{
#include "CSP/Multiplayer/Components/ExternalLinkSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::ExternalLinkSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::ExternalLinkSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.ExternalLinkSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/ExternalLinkSpaceComponent.h"
