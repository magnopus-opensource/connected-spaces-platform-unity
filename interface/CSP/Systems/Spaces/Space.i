%{
#include "CSP/Systems/Spaces/Space.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::Space)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::BasicSpace)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::SpaceGeoLocation)

%include "CSP/Systems/Spaces/Space.h"

// ---------------------------------------------------------

CSP_DEEP_COPY(csp::systems::Space)