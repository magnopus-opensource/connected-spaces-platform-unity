%{
#include "CSP/Multiplayer/Components/ImageSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::ImageSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::ImageSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.ImageSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/ImageSpaceComponent.h"
