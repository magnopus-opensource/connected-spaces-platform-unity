%{
#include "CSP/Multiplayer/Components/CustomSpaceComponent.h"
%}

%include "CSP/Multiplayer/Components/CustomSpaceComponent.h"

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::CustomSpaceComponent, csp::multiplayer::ComponentBase)
