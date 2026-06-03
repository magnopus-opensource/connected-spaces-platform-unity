%include "swigutils/Events.i"

// Note: we need to check the existing action adapters, so we include them to see their define directives.
%include "Declarations/AsyncDeclarations.i"

/*
 * Declare here all the events that need to be exposed to C# as class properties, wrapping the related native registration 
 * method (e.g. SetXCallback(Callbacktype) in most of the cases according to what we currently have in CSP).
 * Make sure to group the declaration by class to keep this file well organised. 
 */

/* csp::common::LogSystem events */
MAKE_EVENT_FOR_CALLBACK(
    OnLogReceived,
    LogCallback,
    SetLogCallback,
    ARGLIST(csp.common.LogLevel, string),
    csp::common::LogSystem
)

MAKE_EVENT_FOR_CALLBACK(
    OnEvent,
    EventCallback,
    SetEventCallback,
    string,
    csp::common::LogSystem
)

MAKE_EVENT_FOR_CALLBACK(
    OnBeginMarker,
    BeginMarkerCallback,
    SetBeginMarkerCallback,
    string,
    csp::common::LogSystem
)

MAKE_EVENT_FOR_CALLBACK(
    OnEndMarker,
    EndMarkerCallback,
    SetEndMarkerCallback,
    System.IntPtr,
    csp::common::LogSystem
)

/* csp::multiplayer::ConversationSpaceComponent events */

MAKE_EVENT_FOR_CALLBACK(
    OnConversationUpdate,
    ConversationNetworkEventCallback,
    SetConversationUpdateCallback,
    csp.common.ConversationNetworkEventData,
    csp::multiplayer::ConversationSpaceComponent
)

/* csp::multiplayer::MultiplayerConnection events */

MAKE_EVENT_FOR_CALLBACK(
    OnConnection,
    ConnectionCallback,
    SetConnectionCallback,
    string,
    csp::multiplayer::MultiplayerConnection
)

MAKE_EVENT_FOR_CALLBACK(
    OnDisconnection,
    DisconnectionCallback,
    SetDisconnectionCallback,
    string,
    csp::multiplayer::MultiplayerConnection
)

MAKE_EVENT_FOR_CALLBACK(
    OnNetworkInterruption,
    NetworkInterruptionCallback,
    SetNetworkInterruptionCallback,
    string,
    csp::multiplayer::MultiplayerConnection
)

/* csp::multiplayer::OfflineRealtimeEngine events */

MAKE_EVENT_FOR_CALLBACK(
    OnEntityFetchComplete,
    EntityFetchCompleteCallback,
    SetEntityFetchCompleteCallback,
    uint,
    csp::multiplayer::OfflineRealtimeEngine
)

/* csp::multiplayer::OnlineRealtimeEngine events */

MAKE_EVENT_FOR_CALLBACK(
    OnRemoteEntityCreated,
    EntityCreatedCallback,
    SetRemoteEntityCreatedCallback,
    csp.multiplayer.SpaceEntity,
    csp::multiplayer::OnlineRealtimeEngine
)

MAKE_EVENT_FOR_CALLBACK(
    OnEntityFetchComplete,
    EntityFetchCompleteCallback,
    SetEntityFetchCompleteCallback,
    uint,
    csp::multiplayer::OnlineRealtimeEngine
)

/* csp::multiplayer::SpaceEntity events */

MAKE_EVENT_FOR_CALLBACK(
    OnUpdate,
    UpdateCallback,
    SetUpdateCallback,
    ARGLIST(csp.multiplayer.SpaceEntity, csp.multiplayer.SpaceEntityUpdateFlags, csp.common.ComponentUpdateInfoArray),
    csp::multiplayer::SpaceEntity
)

MAKE_EVENT_FOR_CALLBACK(
    OnDestroy,
    DestroyCallback,
    SetDestroyCallback,
    bool,
    csp::multiplayer::SpaceEntity
)

/* csp::systems::AssetSystem events */

MAKE_EVENT_FOR_CALLBACK(
    OnAssetDetailBlobChanged,
    AssetDetailBlobChangedCallback,
    SetAssetDetailBlobChangedCallback,
    csp.common.AssetDetailBlobChangedNetworkEventData,
    csp::systems::AssetSystem
)

MAKE_EVENT_FOR_CALLBACK(
    OnMaterialChanged,
    MaterialChangedCallback,
    SetMaterialChangedCallback,
    csp.common.MaterialChangedParams,
    csp::systems::AssetSystem
)

/* csp::systems::HotspotSequenceSystem events */

MAKE_EVENT_FOR_CALLBACK(
    OnHotspotSequenceChanged,
    SequenceChangedCallback,
    SetHotspotSequenceChangedCallback,
    csp.common.SequenceChangedNetworkEventData,
    csp::systems::HotspotSequenceSystem
)

/* csp::systems::SequenceSystem events */

MAKE_EVENT_FOR_CALLBACK(
    OnSequenceChanged,
    SequenceChangedCallback,
    SetSequenceChangedCallback,
    csp.common.SequenceChangedNetworkEventData,
    csp::systems::SequenceSystem
)

/* csp::systems::SpaceSystem events */

MAKE_EVENT_FOR_CALLBACK(
    OnAsyncCallCompleted,
    AsyncCallCompletedCallback,
    SetAsyncCallCompletedCallback,
    csp.common.AsyncCallCompletedEventData,
    csp::systems::SpaceSystem
)

/* csp::systems::UserSystem events */
MAKE_EVENT_FOR_CALLBACK(
    OnNewLoginTokenReceived,
    LoginTokenInfoCallback,
    SetNewLoginTokenReceivedCallback,
    csp.systems.LoginTokenInfoResult,
    csp::systems::UserSystem
)

MAKE_EVENT_FOR_CALLBACK(
    OnUserPermissionsChanged,
    UserPermissionsChangedCallback,
    SetUserPermissionsChangedCallback,
    csp.common.AccessControlChangedNetworkEventData,
    csp::systems::UserSystem
)

