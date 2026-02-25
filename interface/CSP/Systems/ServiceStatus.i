%{
#include "CSP/Systems/ServiceStatus.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::VersionMetadata)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ServiceStatus)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ServicesDeploymentStatus)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ServicesDeploymentStatusResult)

%include "CSP/Systems/ServiceStatus.h"
