%{
#include "CSP/Multiplayer/Components/CinematicCameraSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::CinematicCameraSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::CinematicCameraSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.CinematicCameraSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/CinematicCameraSpaceComponent.h"
