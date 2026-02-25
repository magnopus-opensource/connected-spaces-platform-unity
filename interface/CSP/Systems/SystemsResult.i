%{
#include "CSP/Systems/SystemsResult.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::NullResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::BooleanResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::StringResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::StringArrayResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::UInt64Result)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::HTTPHeadersResult)

%include "CSP/Systems/SystemsResult.h"