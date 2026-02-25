%{
#include "CSP/Multiplayer/Components/StaticModelSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::StaticModelSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::StaticModelSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.StaticModelSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/StaticModelSpaceComponent.h"
