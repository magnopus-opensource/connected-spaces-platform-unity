%{
#include "CSP/Multiplayer/Components/GaussianSplatSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::GaussianSplatSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::GaussianSplatSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.GaussianSplatSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/GaussianSplatSpaceComponent.h"
