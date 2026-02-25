%{
#include "CSP/Multiplayer/Components/AnimatedModelSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::AnimatedModelSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::AnimatedModelSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.AnimatedModelSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/AnimatedModelSpaceComponent.h"
