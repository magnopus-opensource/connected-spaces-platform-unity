%{
#include "CSP/Multiplayer/Components/CollisionSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::CollisionSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::CollisionSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.CollisionSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/CollisionSpaceComponent.h"
