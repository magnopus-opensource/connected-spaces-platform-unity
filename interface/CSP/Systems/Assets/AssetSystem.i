%{
#include "CSP/Systems/Assets/AssetSystem.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::AssetSystem)

// The caller owns the Material returned by the Parse functions.
%newobject csp::systems::AssetSystem::ParseMaterial;
%newobject csp::systems::AssetSystem::ParseMaterialFromAssetCollection;

%include "CSP/Systems/Assets/AssetSystem.h"
