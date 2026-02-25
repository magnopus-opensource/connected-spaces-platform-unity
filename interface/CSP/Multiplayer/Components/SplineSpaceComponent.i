%{
#include "CSP/Multiplayer/Components/SplineSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::SplineSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::SplineSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.SplineSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/SplineSpaceComponent.h"
