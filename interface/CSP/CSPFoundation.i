%{
#include "CSP/CSPFoundation.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::FeatureFlag)
ADD_OUTER_OBJECT_PIN_SLOT(csp::ServiceDefinition)
ADD_OUTER_OBJECT_PIN_SLOT(csp::EndpointURIs)
ADD_OUTER_OBJECT_PIN_SLOT(csp::ClientUserAgent)
ADD_OUTER_OBJECT_PIN_SLOT(csp::CSPFoundation)

%include "CSP/CSPFoundation.h"
