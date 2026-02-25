%{
#include "CSP/Multiplayer/Components/ScreenSharingSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::ScreenSharingSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::ScreenSharingSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.ScreenSharingSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/ScreenSharingSpaceComponent.h"
