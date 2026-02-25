%{
#include "CSP/Multiplayer/Components/VideoPlayerSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::VideoPlayerSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::VideoPlayerSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.VideoPlayerSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/VideoPlayerSpaceComponent.h"
