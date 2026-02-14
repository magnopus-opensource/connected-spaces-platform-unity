/*
 * Declare director objects that we use to interface with CSP's std::function callbacks.
 * The reason we need to do it this way, rather than just making directors directly
 * out of the callback arguments CSP provides, is because CSP has chosen to take
 * type-elided std::function callbacks by value.
 * As SWIG directors use virtual dispatch as their callback mechanism, this means
 * if we did this naively, we would slice, and not get callbacks. Therefore, we 
 * make these adapter objects in the SWIG C++ layer, such that we can capture them
 * in the std::functions, and perform a proxied dispatch that way.
 * I'll be honest, it would be good if CSP could take callbacks in ways that allowed
 * virtual dispatch, as type-elided function objects are not the friendliest interface
 * when crossing language boundaries.
 *
 * You'll need to declare a callback adapter for any function that takes a callback.
 * These adapters are used in AsyncAdapters.i in order to support async/await as well.
 *
 * You'll also need to declare a typemap between the CSP callback typedef, and the
 * callback adapter.
 *
 * There only needs to be one callback adapter for any given type signature.
 * For example, we have a BoolCallbackAdapter which has a bool arg, but there are
 * multiple callbacks that have that sig, "CallbackHandler", "DestroyCallback", etc.
 * The macro machinery handles making sure that only a single adapter of any given
 * name is created, whilst there will still be multiple callback typemaps that
 * make use of it.
 *
 * CSharp devs won't use these things directly almost ever, see AsyncAdapters.i
 * for adaptations that turn these callback adapters into things that work nicely
 * with csharp semantics.
 */
 
%include "swigutils/GeneralUtils.i" 

/* 
 * Make the actual director object that goes into CSP. This gets captures into CSP's std::function
 * interfaces via lambda capture. We're calling this a "Callback Adapter"
 * Ensures uniqueness based on name. It's possible to register identical types but with different
 * names. This is fine, but redundant, sort of up to you if you want your exposed callback interfaces
 * to all be unique, or the same for callbacks that have the same types. I'd favour the latter.
 */
%define MAKE_CALLBACK_ADAPTER(CALLBACK_ADAPTER_NAME, CALL_ARG_LIST_WITH_TYPES, CALL_RETURN_T)
#ifdef SWIG_CALLBACK_ADAPTER_##CALLBACK_ADAPTER_NAME##_DEFINED
  %echo "MAKE_CALLBACK_ADAPTER: callback '" #CALLBACK_ADAPTER_NAME "' already defined, skipping"
#else
#define SWIG_CALLBACK_ADAPTER_##CALLBACK_ADAPTER_NAME##_DEFINED
%feature("director") CALLBACK_ADAPTER_NAME;
%inline %{
class CALLBACK_ADAPTER_NAME
{
public:
    virtual ~CALLBACK_ADAPTER_NAME() = default;
    virtual CALL_RETURN_T Call(CALL_ARG_LIST_WITH_TYPES) = 0;
};
%}
#endif
%enddef

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

/*********** CALLBACK TYPEMAPS **********/

/* With the adapters, we can typemap all the callbacks in the csp interfaces
 * such that they use the adapters. You'll need to be sure the above declarations
 * are in sync with the below. Although you should get a build error if they're not.

/* In SWIG, #MACRO_ARG converts to "MACRO_ARG", which is pretty neat
 * X##Y Concatanates as you'd expect */

/* We need to add "*" to the type for the C type (ctype) */
%define QUOTED_STRSTAR_HELPER(x)
#x "*"
%enddef
/* Similarly, need to fetch the CPtr for the CSharp layer (csin) */
%define QUOTED_GETCPTR_HELPER(x)
#x ".getCPtr($csinput)"
%enddef


/* Make a CSP callback such that it can be called from C#
 * What this does it make a callback adapter (a director object),
 * and inject it into CSP's std::function interfaces via a lambda capture.
 * We also setup all the typemaps such that when SWIG sees a CSP function
 * with a callback argument, it inserts this injection.
 *
 * This is good enough to use callbacks in C#. But you probably want to further
 * wrap these with actions adapters and async adapters to get nicer C# semantics.
 * See AsyncAdapters.i */
%define MAKE_CALLBACK(CALLBACK_CPP_SYMBOL, ADAPTER_NAME, ARG_LIST_WITH_TYPES, ARG_LIST_WITHOUT_TYPES)

// Presume void as the return type, because all the CSP callbacks return void currently.
MAKE_CALLBACK_ADAPTER(ADAPTER_NAME, ARGLIST(ARG_LIST_WITH_TYPES), void)

%typemap(ctype) CALLBACK_CPP_SYMBOL QUOTED_STRSTAR_HELPER(ADAPTER_NAME) // Declared type in C
%typemap(cstype) CALLBACK_CPP_SYMBOL #ADAPTER_NAME // Declared type in C#
%typemap(imtype) CALLBACK_CPP_SYMBOL "global::System.Runtime.InteropServices.HandleRef" // P/Invoke type 
%typemap(csin)   CALLBACK_CPP_SYMBOL QUOTED_GETCPTR_HELPER(ADAPTER_NAME) //How we pass the object from Csharp to the PINVOKE layer

/* _cbtemp here is making a temp variable in the C function to store the temporary std::function in.
 * This is clearer in the generated code */
%typemap(in) CALLBACK_CPP_SYMBOL {
  $1 = [$input](ARG_LIST_WITH_TYPES) {
    return $input->Call(ARG_LIST_WITHOUT_TYPES);
  };
}
%enddef

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
MAKE_CALLBACK(csp::multiplayer::NetworkEventCallback,
                      NetworkEventCallbackAdapter,
                      ARGLIST(csp::common::NetworkEventData networkEventData),
                      ARGLIST(networkEventData))
MAKE_CALLBACK(csp::multiplayer::NetworkEventBus::ErrorCodeCallbackHandler,
                      ErrorCodeCallbackAdapter,
                      ARGLIST(csp::multiplayer::ErrorCode errorCode),
                      ARGLIST(errorCode))

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


/*********** CALLBACK NAMESPACE ADAPTATION **********/
/* First, know that callbacks (std::functions) are going through the Fulton transform (https://swig.org/Doc1.3/SWIGPlus.html)
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