%include "swigutils/CallbackAdapters.i"

/* Declare all the callback adapters and typemaps necessary for interacting with CSP 
 * See CallbackAdapters.i for the nuts and bolts of how this works */

/* This include listing should be exhaustive, but I wouldn't put it past us to 
 * have some transient includes peeking their heads through somewhere */
%{
#include "CSP/Common/Systems/Log/LogSystem.h"
#include "CSP/Systems/SystemsResult.h"
#include "CSP/Common/SharedEnums.h"
#include "CSP/Systems/Quota/Quota.h"
#include "CSP/Systems/Quota/QuotaSystem.h"
#include "CSP/Systems/SystemsResult.h"
#include "CSP/Common/NetworkEventData.h"
#include "CSP/Multiplayer/MultiplayerConnection.h"
#include "CSP/Multiplayer/SpaceEntity.h"
#include "CSP/Multiplayer/OnlineRealtimeEngine.h"
#include "CSP/Multiplayer/PatchTypes.h"
#include "CSP/Multiplayer/NetworkEventBus.h"
#include "CSP/Multiplayer/Conversation/Conversation.h"
#include "CSP/Multiplayer/Components/ConversationSpaceComponent.h"
#include <stdint.h>
#include "CSP/Systems/Assets/Asset.h"
#include "CSP/Systems/Assets/AssetCollection.h"
#include "CSP/Systems/Assets/Material.h"
#include "CSP/Systems/Assets/LOD.h"
#include "CSP/Systems/Assets/AssetSystem.h"
#include "CSP/Systems/Spaces/Space.h"
#include "CSP/Systems/Spaces/SpaceSystem.h"
#include "CSP/Systems/Spaces/Site.h"
#include "CSP/Systems/Spaces/UserRoles.h"
#include "CSP/Systems/Users/Profile.h"
#include "CSP/Systems/Users/Authentication.h"
#include "CSP/Systems/Users/UserSystem.h"
#include "CSP/Systems/Settings/ApplicationSettings.h"
#include "CSP/Systems/Settings/SettingsCollection.h"
#include "CSP/Systems/ECommerce/ECommerce.h"
#include "CSP/Systems/EventTicketing/EventTicketing.h"
#include "CSP/Systems/Maintenance/Maintenance.h"
#include "CSP/Systems/GraphQL/GraphQL.h"
#include "CSP/Systems/Spatial/PointOfInterest.h"
#include "CSP/Systems/Spatial/Anchor.h"
#include "CSP/Systems/Sequence/Sequence.h"
#include "CSP/Systems/Sequence/SequenceSystem.h"
#include "CSP/Systems/HotspotSequence/HotspotGroup.h"
#include "CSP/Systems/HotspotSequence/HotspotSequenceSystem.h"
%}

// Forward declarations for types used in callbacks, which due to the order of swig interface includes could be needed.
// These are like this because test stuff like this is declared in .i files, so the C++ #include list above is not
// appropriate.
%inline %{
namespace extra 
{
    namespace test 
    {
        class TestBooleanResult;  // forward declaration
    }
}
%}

/* For the below callbacks, note how some types don't match their CSP signature, in that what CSP passes as const&,
 * we take by value. This is because CSP returns references to local variables in their callbacks, perhaps in a 
 * misguided performance optimization. This does not work well with async/await, or any sort of task based capture.
 * By using the value signature here, we invoke the copy constructor, freeing us from the burden of thinking about
 * scope. CSP should change these, interop layers are not the place to be providing memory safety, and this proves 
 * it can be done as all these types have copy constructors by virtue of this compiling.
 * Strings don't matter, because they get type-mapped to csharp strings anyhow.
 *
 * The namespacing for these callbacks can be a mess. CSP needs to do some housecleaning */

/* General/Top-Level Systems Callback Typemaps */
MAKE_CALLBACK(csp::systems::FeatureLimitCallback,
                      FeatureLimitCallbackAdapter,
                      ARGLIST(csp::systems::FeatureLimitResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::NullResultCallback,
                      NullResultCallbackAdapter,
                      ARGLIST(csp::systems::NullResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::StringResultCallback,
                      StringResultCallbackAdapter,
                      ARGLIST(csp::systems::StringResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::BooleanResultCallback,
                      BooleanResultCallbackAdapter,
                      ARGLIST(csp::systems::BooleanResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::StringArrayResultCallback,
                      StringArrayResultCallbackAdapter,
                      ARGLIST(csp::systems::StringArrayResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::UInt64ResultCallback,
                      UInt64ResultCallbackAdapter,
                      ARGLIST(csp::systems::UInt64Result result),
                      ARGLIST(result))

/* LogSystem Callback Typemaps */
MAKE_CALLBACK(csp::common::LogSystem::LogCallbackHandler,
                      LogCallbackHandlerAdapter, 
                      ARGLIST(csp::common::LogLevel logLevel, const csp::common::String& message),
                      ARGLIST(logLevel, message))
MAKE_CALLBACK(csp::common::LogSystem::EventCallbackHandler,
                      EventCallbackHandlerAdapter, 
                      ARGLIST(const csp::common::String& eventMessage),
                      ARGLIST(eventMessage))
MAKE_CALLBACK(csp::common::LogSystem::BeginMarkerCallbackHandler,
                      BeginMarkerCallbackHandlerAdapter, 
                      ARGLIST(const csp::common::String& beginMarker),
                      ARGLIST(beginMarker))
MAKE_CALLBACK(csp::common::LogSystem::EndMarkerCallbackHandler,
                      EndMarkerCallbackHandlerAdapter, 
                      ARGLIST(void* irrelevantArg /* Legacy wrapper gen implication, ignore */),
                      ARGLIST(irrelevantArg))
MAKE_CALLBACK(extra::test::TestBooleanResultCallback,
                      TestBooleanResultCallbackAdapter, 
                      ARGLIST(extra::test::TestBooleanResult result),
                      ARGLIST(result))


/* Assets Callback Typemaps */
MAKE_CALLBACK(csp::systems::AssetResultCallback,
                      AssetResultCallbackAdapter,
                      ARGLIST(csp::systems::AssetResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AssetsResultCallback,
                      AssetsResultCallbackAdapter,
                      ARGLIST(csp::systems::AssetsResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::UriResultCallback,
                      UriResultCallbackAdapter,
                      ARGLIST(csp::systems::UriResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AssetDataResultCallback,
                      AssetDataResultCallbackAdapter,
                      ARGLIST(csp::systems::AssetDataResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AssetCollectionResultCallback,
                      AssetCollectionResultCallbackAdapter,
                      ARGLIST(csp::systems::AssetCollectionResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AssetCollectionsResultCallback,
                      AssetCollectionsResultCallbackAdapter,
                      ARGLIST(csp::systems::AssetCollectionsResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AssetCollectionCountResultCallback,
                      AssetCollectionCountResultCallbackAdapter,
                      ARGLIST(csp::systems::AssetCollectionCountResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::MaterialResultCallback,
                      MaterialResultCallbackAdapter,
                      ARGLIST(csp::systems::MaterialResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::MaterialsResultCallback,
                      MaterialsResultCallbackAdapter,
                      ARGLIST(csp::systems::MaterialsResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::LODChainResultCallback,
                      LODChainResultCallbackAdapter,
                      ARGLIST(csp::systems::LODChainResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AssetSystem::AssetDetailBlobChangedCallbackHandler,
                      AssetDetailBlobChangedCallbackAdapter,
                      ARGLIST(csp::common::AssetDetailBlobChangedNetworkEventData eventData),
                      ARGLIST(eventData))
MAKE_CALLBACK(csp::systems::AssetSystem::MaterialChangedCallbackHandler,
                      MaterialChangedCallbackAdapter,
                      ARGLIST(csp::common::MaterialChangedParams params),
                      ARGLIST(params))

/* Spaces Callback Typemaps */
MAKE_CALLBACK(csp::systems::SpaceResultCallback,
                      SpaceResultCallbackAdapter,
                      ARGLIST(csp::systems::SpaceResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SpacesResultCallback,
                      SpacesResultCallbackAdapter,
                      ARGLIST(csp::systems::SpacesResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::BasicSpaceResultCallback,
                      BasicSpaceResultCallbackAdapter,
                      ARGLIST(csp::systems::BasicSpaceResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::BasicSpacesResultCallback,
                      BasicSpacesResultCallbackAdapter,
                      ARGLIST(csp::systems::BasicSpacesResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SpaceMetadataResultCallback,
                      SpaceMetadataResultCallbackAdapter,
                      ARGLIST(csp::systems::SpaceMetadataResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SpacesMetadataResultCallback,
                      SpacesMetadataResultCallbackAdapter,
                      ARGLIST(csp::systems::SpacesMetadataResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::PendingInvitesResultCallback,
                      PendingInvitesResultCallbackAdapter,
                      ARGLIST(csp::systems::PendingInvitesResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AcceptedInvitesResultCallback,
                      AcceptedInvitesResultCallbackAdapter,
                      ARGLIST(csp::systems::AcceptedInvitesResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SpaceGeoLocationResultCallback,
                      SpaceGeoLocationResultCallbackAdapter,
                      ARGLIST(csp::systems::SpaceGeoLocationResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SiteResultCallback,
                      SiteResultCallbackAdapter,
                      ARGLIST(csp::systems::SiteResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SitesCollectionResultCallback,
                      SitesCollectionResultCallbackAdapter,
                      ARGLIST(csp::systems::SitesCollectionResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::UserRoleCollectionCallback,
                      UserRoleCollectionCallbackAdapter,
                      ARGLIST(csp::systems::UserRoleCollectionResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SpaceSystem::AsyncCallCompletedCallbackHandler,
                      AsyncCallCompletedCallbackAdapter,
                      ARGLIST(csp::common::AsyncCallCompletedEventData eventData),
                      ARGLIST(eventData))

/* Users Callback Typemaps */
MAKE_CALLBACK(csp::systems::ProfileResultCallback,
                      ProfileResultCallbackAdapter,
                      ARGLIST(csp::systems::ProfileResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::BasicProfilesResultCallback,
                      BasicProfilesResultCallbackAdapter,
                      ARGLIST(csp::systems::BasicProfilesResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::LoginStateResultCallback,
                      LoginStateResultCallbackAdapter,
                      ARGLIST(csp::systems::LoginStateResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::LoginTokenInfoResultCallback,
                      LoginTokenInfoResultCallbackAdapter,
                      ARGLIST(csp::systems::LoginTokenInfoResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::UserSystem::UserPermissionsChangedCallbackHandler,
                      UserPermissionsChangedCallbackAdapter,
                      ARGLIST(csp::common::AccessControlChangedNetworkEventData eventData),
                      ARGLIST(eventData))

/* Settings Callback Typemaps */
MAKE_CALLBACK(csp::systems::ApplicationSettingsResultCallback,
                      ApplicationSettingsResultCallbackAdapter,
                      ARGLIST(csp::systems::ApplicationSettingsResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AvatarInfoResultCallback,
                      AvatarInfoResultCallbackAdapter,
                      ARGLIST(csp::systems::AvatarInfoResult result),
                      ARGLIST(result))

/* Quota Callback Typemaps */
MAKE_CALLBACK(csp::systems::FeaturesLimitCallback,
                      FeaturesLimitCallbackAdapter,
                      ARGLIST(csp::systems::FeaturesLimitResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::UserTierCallback,
                      UserTierCallbackAdapter,
                      ARGLIST(csp::systems::UserTierResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::FeatureQuotaCallback,
                      FeatureQuotaCallbackAdapter,
                      ARGLIST(csp::systems::FeatureQuotaResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::FeaturesQuotaCallback,
                      FeaturesQuotaCallbackAdapter,
                      ARGLIST(csp::systems::FeaturesQuotaResult result),
                      ARGLIST(result))

/* ECommerce Callback Typemaps */
MAKE_CALLBACK(csp::systems::ProductInfoResultCallback,
                      ProductInfoResultCallbackAdapter,
                      ARGLIST(csp::systems::ProductInfoResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::ProductInfoCollectionResultCallback,
                      ProductInfoCollectionResultCallbackAdapter,
                      ARGLIST(csp::systems::ProductInfoCollectionResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::CheckoutInfoResultCallback,
                      CheckoutInfoResultCallbackAdapter,
                      ARGLIST(csp::systems::CheckoutInfoResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::CartInfoResultCallback,
                      CartInfoResultCallbackAdapter,
                      ARGLIST(csp::systems::CartInfoResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AddShopifyStoreResultCallback,
                      AddShopifyStoreResultCallbackAdapter,
                      ARGLIST(csp::systems::AddShopifyStoreResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SetECommerceActiveResultCallback,
                      AddShopifyStoreResultCallbackAdapter,
                      ARGLIST(csp::systems::AddShopifyStoreResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::ValidateShopifyStoreResultCallback,
                      ValidateShopifyStoreResultCallbackAdapter,
                      ARGLIST(csp::systems::ValidateShopifyStoreResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::GetShopifyStoresResultCallback,
                      GetShopifyStoresResultCallbackAdapter,
                      ARGLIST(csp::systems::GetShopifyStoresResult result),
                      ARGLIST(result))

/* EventTicketing Callback Typemaps */
MAKE_CALLBACK(csp::systems::TicketedEventResultCallback,
                      TicketedEventResultCallbackAdapter,
                      ARGLIST(csp::systems::TicketedEventResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::TicketedEventCollectionResultCallback,
                      TicketedEventCollectionResultCallbackAdapter,
                      ARGLIST(csp::systems::TicketedEventCollectionResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::EventTicketResultCallback,
                      EventTicketResultCallbackAdapter,
                      ARGLIST(csp::systems::EventTicketResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SpaceIsTicketedResultCallback,
                      SpaceIsTicketedResultCallbackAdapter,
                      ARGLIST(csp::systems::SpaceIsTicketedResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::TicketedEventVendorAuthorizeInfoCallback,
                      TicketedEventVendorAuthInfoResultCallbackAdapter,
                      ARGLIST(csp::systems::TicketedEventVendorAuthInfoResult result),
                      ARGLIST(result))

/* Maintenance Callback Typemaps */
MAKE_CALLBACK(csp::systems::MaintenanceInfoCallback,
                      MaintenanceInfoCallbackAdapter,
                      ARGLIST(csp::systems::MaintenanceInfoResult result),
                      ARGLIST(result))

/* GraphQL Callback Typemaps */
MAKE_CALLBACK(csp::systems::GraphQLReceivedCallback,
                      GraphQLReceivedCallbackAdapter,
                      ARGLIST(csp::systems::GraphQLResult result),
                      ARGLIST(result))

/* Spatial Callback Typemaps */
MAKE_CALLBACK(csp::systems::POIResultCallback,
                      POIResultCallbackAdapter,
                      ARGLIST(csp::systems::POIResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::POICollectionResultCallback,
                      POICollectionResultCallbackAdapter,
                      ARGLIST(csp::systems::POICollectionResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AnchorResultCallback,
                      AnchorResultCallbackAdapter,
                      ARGLIST(csp::systems::AnchorResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AnchorCollectionResultCallback,
                      AnchorCollectionResultCallbackAdapter,
                      ARGLIST(csp::systems::AnchorCollectionResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::AnchorResolutionResultCallback,
                      AnchorResolutionResultCallbackAdapter,
                      ARGLIST(csp::systems::AnchorResolutionResult result),
                      ARGLIST(result))

/* Sequence Callback Typemaps */
MAKE_CALLBACK(csp::systems::SequenceResultCallback,
                      SequenceResultCallbackAdapter,
                      ARGLIST(csp::systems::SequenceResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SequencesResultCallback,
                      SequencesResultCallbackAdapter,
                      ARGLIST(csp::systems::SequencesResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::SequenceSystem::SequenceChangedCallbackHandler,
                      SequenceChangedCallbackAdapter,
                      ARGLIST(csp::common::SequenceChangedNetworkEventData eventData),
                      ARGLIST(eventData))

/* HotspotSequence Callback Typemaps */
MAKE_CALLBACK(csp::systems::HotspotGroupResultCallback,
                      HotspotGroupResultCallbackAdapter,
                      ARGLIST(csp::systems::HotspotGroupResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::HotspotGroupsResultCallback,
                      HotspotGroupsResultCallbackAdapter,
                      ARGLIST(csp::systems::HotspotGroupsResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::systems::HotspotSequenceSystem::HotspotSequenceChangedCallbackHandler,
                      SequenceChangedCallbackAdapter,
                      ARGLIST(csp::common::SequenceChangedNetworkEventData eventData),
                      ARGLIST(eventData))

/* Multiplayer Callback Typemaps */
MAKE_CALLBACK(csp::multiplayer::CallbackHandler,
                      BoolCallbackAdapter,
                      ARGLIST(bool success),
                      ARGLIST(success))

// This is a bit of a mess on CSP's part, duplicate callbacks in multiplayer and multiplayer::SpaceEntity.
// No reason for these to be different.
MAKE_CALLBACK(csp::multiplayer::EntityCreatedCallback,
                      EntityCreatedCallbackAdapter,
                      ARGLIST(csp::multiplayer::SpaceEntity* spaceEntity),
                      ARGLIST(spaceEntity))

//SpaceEntity
MAKE_CALLBACK(csp::multiplayer::SpaceEntity::UpdateCallback,
                      SpaceEntityUpdatedCallbackAdapter,
                      ARGLIST(csp::multiplayer::SpaceEntity* spaceEntity,
                              csp::multiplayer::SpaceEntityUpdateFlags updateFlags,
                              csp::common::Array<csp::multiplayer::ComponentUpdateInfo> componentUpdateInfos),
                      ARGLIST(spaceEntity, updateFlags, componentUpdateInfos))
MAKE_CALLBACK(csp::multiplayer::SpaceEntity::DestroyCallback,
                      BoolCallbackAdapter,
                      ARGLIST(bool success),
                      ARGLIST(success))
MAKE_CALLBACK(csp::multiplayer::SpaceEntity::CallbackHandler,
                      BoolCallbackAdapter,
                      ARGLIST(bool success),
                      ARGLIST(success))
MAKE_CALLBACK(csp::multiplayer::SpaceEntity::EntityCreatedCallback,
                      EntityCreatedCallbackAdapter,
                      ARGLIST(csp::multiplayer::SpaceEntity* spaceEntity),
                      ARGLIST(spaceEntity))

//RealtimeEngine
MAKE_CALLBACK(csp::common::EntityFetchCompleteCallback,
                      UInt32CallbackAdapter,
                      ARGLIST(std::uint32_t numEntitiesFetched),
                      ARGLIST(numEntitiesFetched))
MAKE_CALLBACK(csp::multiplayer::OnlineRealtimeEngine::ScopeLeaderCallback,
                      StringStringCallbackAdapter,
                      ARGLIST(const csp::common::String& scopeId, const csp::common::String& userId),
                      ARGLIST(scopeId, userId))

//MultiplayerConnection
MAKE_CALLBACK(csp::multiplayer::MultiplayerConnection::ErrorCodeCallbackHandler,
                      ErrorCodeCallbackAdapter,
                      ARGLIST(csp::multiplayer::ErrorCode errorCode),
                      ARGLIST(errorCode))
MAKE_CALLBACK(csp::multiplayer::MultiplayerConnection::DisconnectionCallbackHandler,
                      StringCallbackAdapter,
                      ARGLIST(const csp::common::String& disconnectReason),
                      ARGLIST(disconnectReason))
MAKE_CALLBACK(csp::multiplayer::MultiplayerConnection::ConnectionCallbackHandler,
                      StringCallbackAdapter,
                      ARGLIST(const csp::common::String& connectionStatus),
                      ARGLIST(connectionStatus))
MAKE_CALLBACK(csp::multiplayer::MultiplayerConnection::NetworkInterruptionCallbackHandler,
                      StringCallbackAdapter,
                      ARGLIST(const csp::common::String& interruptReason),
                      ARGLIST(interruptReason))

//NetworkEventBus
MAKE_CALLBACK(csp::multiplayer::CustomNetworkEventCallback,
                      CustomNetworkEventCallbackAdapter,
                      ARGLIST(csp::common::NetworkEventData networkEventData),
                      ARGLIST(networkEventData))
MAKE_CALLBACK(csp::multiplayer::NetworkEventBus::ErrorCodeCallbackHandler,
                      ErrorCodeCallbackAdapter,
                      ARGLIST(csp::multiplayer::ErrorCode errorCode),
                      ARGLIST(errorCode))
MAKE_CALLBACK(csp::multiplayer::AccessControlChangedEventCallback,
                      AccessControlChangedEventCallbackAdapter,
                      ARGLIST(csp::common::AccessControlChangedNetworkEventData eventData),
                      ARGLIST(eventData))
MAKE_CALLBACK(csp::multiplayer::AssetDetailBlobChangedEventCallback,
                      AssetDetailBlobChangedEventCallbackAdapter,
                      ARGLIST(csp::common::AssetDetailBlobChangedNetworkEventData eventData),
                      ARGLIST(eventData))
MAKE_CALLBACK(csp::multiplayer::AsyncCallCompletedEventCallback,
                      AsyncCallCompletedEventCallbackAdapter,
                      ARGLIST(csp::common::AsyncCallCompletedEventData eventData),
                      ARGLIST(eventData))
MAKE_CALLBACK(csp::multiplayer::ConversationEventCallback,
                      ConversationEventCallbackAdapter,
                      ARGLIST(csp::common::ConversationNetworkEventData eventData),
                      ARGLIST(eventData))
MAKE_CALLBACK(csp::multiplayer::SequenceChangedEventCallback,
                      SequenceChangedEventCallbackAdapter,
                      ARGLIST(csp::common::SequenceChangedNetworkEventData eventData),
                      ARGLIST(eventData))

//ComponentBase
MAKE_CALLBACK(csp::multiplayer::ComponentBase::EntityActionHandler,
                      EntityActionCallbackAdapter,
                      ARGLIST(csp::multiplayer::ComponentBase* component, const csp::common::String& actionName, const csp::common::String& actionParams),
                      ARGLIST(component, actionName, actionParams))

//Conversation
MAKE_CALLBACK(csp::multiplayer::MessageResultCallback,
                      MessageResultCallbackAdapter,
                      ARGLIST(csp::multiplayer::MessageResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::multiplayer::MessageCollectionResultCallback,
                      MessageCollectionResultCallbackAdapter,
                      ARGLIST(csp::multiplayer::MessageCollectionResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::multiplayer::ConversationResultCallback,
                      ConversationResultCallbackAdapter,
                      ARGLIST(csp::multiplayer::ConversationResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::multiplayer::NumberOfRepliesResultCallback,
                      NumberOfRepliesResultCallbackAdapter,
                      ARGLIST(csp::multiplayer::NumberOfRepliesResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::multiplayer::AnnotationResultCallback,
                      AnnotationResultCallbackAdapter,
                      ARGLIST(csp::multiplayer::AnnotationResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::multiplayer::AnnotationThumbnailCollectionResultCallback,
                      AnnotationThumbnailCollectionResultCallbackAdapter,
                      ARGLIST(csp::multiplayer::AnnotationThumbnailCollectionResult result),
                      ARGLIST(result))
MAKE_CALLBACK(csp::multiplayer::ConversationSpaceComponent::ConversationUpdateCallbackHandler,
                      ConversationNetworkEventCallbackAdapter,
                      ARGLIST(csp::common::ConversationNetworkEventData eventData),
                      ARGLIST(eventData))

/* Progress callback */
MAKE_CALLBACK(csp::systems::ProgressCallback,
              ProgressCallbackAdapter,
              ARGLIST(float progress),
              ARGLIST(progress))


/*********** CALLBACK NAMESPACE ADAPTATION **********/
/* First, know that callbacks (std::functions) are going through the Fulton transform (https://swig.org/Doc4.4/SWIGPlus.html)
 * This transforms it into a SwigValueWrapper<return(args...)>, which does not need a default constructor.
 * This will have the same declaration style as in the CSP source, which is not always fully namespaced.
 * This is a problem for code rendered in the .cxx file.
 * If CSP fully namespaced their arguments to callbacks this could all be deleted.
 * ... (or we could maybe do richer namespacing here in SWIG? Not fully sure.) */

/* This is placed directly into the .cxx (not .h, despite the name of the insert macro) */
%insert("header") %{
/* Namespace escape hatches for difficult types, like callback signatures.
 * Careful here, potential cause of collisions. */
using csp::common::String;
using csp::common::LogLevel;
%}