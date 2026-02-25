%{
#include "CSP/Multiplayer/Components/ConversationSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::ConversationSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::ConversationSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.ConversationSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/ConversationSpaceComponent.h"
