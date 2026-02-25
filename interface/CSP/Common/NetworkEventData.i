%{
#include "CSP/Common/NetworkEventData.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::common::NetworkEventData)
ADD_OUTER_OBJECT_PIN_SLOT(csp::common::AssetDetailBlobChangedNetworkEventData)
ADD_OUTER_OBJECT_PIN_SLOT(csp::common::ConversationNetworkEventData)
ADD_OUTER_OBJECT_PIN_SLOT(csp::common::AccessControlChangedNetworkEventData)
ADD_OUTER_OBJECT_PIN_SLOT(csp::common::SequenceChangedNetworkEventData)
ADD_OUTER_OBJECT_PIN_SLOT(csp::common::AsyncCallCompletedEventData)
ADD_OUTER_OBJECT_PIN_SLOT(csp::common::MaterialChangedParams)

%include "CSP/Common/NetworkEventData.h"
