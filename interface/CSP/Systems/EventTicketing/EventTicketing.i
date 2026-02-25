%{
#include "CSP/Systems/EventTicketing/EventTicketing.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::TicketedEvent)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::EventTicket)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::TicketedEventVendorAuthInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::TicketedEventResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::TicketedEventCollectionResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::EventTicketResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::SpaceIsTicketedResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::TicketedEventVendorAuthInfoResult)

%include "CSP/Systems/EventTicketing/EventTicketing.h"
