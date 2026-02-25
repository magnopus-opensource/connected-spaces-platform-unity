%{
#include "CSP/Systems/Assets/Asset.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::Asset)

// Ignore non-const GetUri — the const overload maps correctly to string via the String typemaps
%ignore csp::systems::UriResult::GetUri();

%include "CSP/Systems/Assets/Asset.h"
