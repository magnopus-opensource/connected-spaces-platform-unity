%{
#include "CSP/Multiplayer/Components/TextSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::TextSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::TextSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.TextSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/TextSpaceComponent.h"
