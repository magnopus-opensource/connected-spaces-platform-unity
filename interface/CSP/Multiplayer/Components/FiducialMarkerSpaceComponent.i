%{
#include "CSP/Multiplayer/Components/FiducialMarkerSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::FiducialMarkerSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::FiducialMarkerSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.FiducialMarkerSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/FiducialMarkerSpaceComponent.h"
