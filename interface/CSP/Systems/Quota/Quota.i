%{
#include "CSP/Systems/Quota/Quota.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::FeatureLimitInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::UserTierInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::FeatureQuotaInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::FeaturesLimitResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::FeatureLimitResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::UserTierResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::FeatureQuotaResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::FeaturesQuotaResult)

%include "CSP/Systems/Quota/Quota.h"