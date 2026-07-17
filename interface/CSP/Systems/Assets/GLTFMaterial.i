%{
#include "CSP/Systems/Assets/GLTFMaterial.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::GLTFMaterial)

%include "swigutils/FromBaseCast.i"
MAKE_FROM_BASE_CAST(csp::systems::GLTFMaterial, csp::systems::Material, csp.systems.GLTFMaterial, csp.systems.Material)

%include "CSP/Systems/Assets/GLTFMaterial.h"
