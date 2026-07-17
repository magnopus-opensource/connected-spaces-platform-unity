%{
#include "CSP/Systems/Assets/AlphaVideoMaterial.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::AlphaVideoMaterial)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::systems::AlphaVideoMaterial, csp::systems::Material, csp.systems.AlphaVideoMaterial, csp.systems.Material)

%include "CSP/Systems/Assets/AlphaVideoMaterial.h"
