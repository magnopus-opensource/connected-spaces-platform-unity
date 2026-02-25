%{
#include "CSP/Multiplayer/Components/ECommerceSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::ECommerceSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::ECommerceSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.ECommerceSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/ECommerceSpaceComponent.h"
