%{
#include "CSP/Multiplayer/Components/ReflectionSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::ReflectionSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::ReflectionSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.ReflectionSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/ReflectionSpaceComponent.h"
