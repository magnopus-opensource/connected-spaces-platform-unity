%{
#include "CSP/Systems/ExternalServices/ExternalServiceProxySystem.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ExternalServicesOperationParams)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::AgoraUserTokenParams)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ExternalServiceProxySystem)

%include "CSP/Systems/ExternalServices/ExternalServiceProxySystem.h"
