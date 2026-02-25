%{
#include "CSP/Multiplayer/Components/AvatarSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::AvatarSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::AvatarSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.AvatarSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/AvatarSpaceComponent.h"
