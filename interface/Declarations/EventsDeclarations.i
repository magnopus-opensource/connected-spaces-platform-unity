%include "swigutils/Events.i"

/*
 * Declare here all the events that need to be exposed to C# as class properties, wrapping the related native registration 
 * method (e.g. SetXCallback(Callbacktype) in most of the cases according to what we currently have in CSP).
 * Make sure to group the declaration by class to keep this file well organised. 
 */

/* csp::systems::UserSystem events */
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

