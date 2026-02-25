%{
#include "CSP/Multiplayer/Components/AudioSpaceComponent.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::AudioSpaceComponent)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::multiplayer::AudioSpaceComponent, csp::multiplayer::ComponentBase, csp.multiplayer.AudioSpaceComponent, csp.multiplayer.ComponentBase)

%include "CSP/Multiplayer/Components/AudioSpaceComponent.h"
