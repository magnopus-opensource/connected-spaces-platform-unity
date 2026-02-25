%{
#include "CSP/Multiplayer/NetworkEventBus.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::NetworkEventRegistration)
ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::NetworkEventBus)

%include "CSP/Multiplayer/NetworkEventBus.h"
