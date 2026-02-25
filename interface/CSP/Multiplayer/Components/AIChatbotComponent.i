%{
#include "CSP/Multiplayer/Components/AIChatbotComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::AIChatbotSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::AIChatbotSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.AIChatbotSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/AIChatbotComponent.h"
