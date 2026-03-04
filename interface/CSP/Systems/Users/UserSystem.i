%{
#include "CSP/Systems/Users/UserSystem.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::UserSystem)

%include "CSP/Systems/Users/UserSystem.h"

MAKE_EVENT_FOR_CALLBACK(
    OnNewLoginTokenReceived,
    ConnectedSpacesPlatformDotNet.LoginTokenInfoCallback,
    SetNewLoginTokenReceivedCallback,
    csp.systems.LoginTokenInfoResult,
    csp::systems::UserSystem
)

MAKE_EVENT_FOR_CALLBACK(
    OnUserPermissionsChanged,
    ConnectedSpacesPlatformDotNet.UserPermissionsChangedCallback,
    SetUserPermissionsChangedCallback,
    csp.common.AccessControlChangedNetworkEventData,
    csp::systems::UserSystem
)