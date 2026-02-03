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
 * Declare one adapter, and multiple typemaps to it in these cases.
 */
 
%include "swigutils/GeneralUtils.i" 

/*********** CALLBACK ADAPTERS **********/

%define MAKE_CALLBACK_ADAPTER(CALLBACK_ADAPTER_NAME, CALL_ARG_LIST_WITH_TYPES, CALL_RETURN_T)
%feature("director") CALLBACK_ADAPTER_NAME;
%inline %{
class CALLBACK_ADAPTER_NAME
{
public:
    virtual ~CALLBACK_ADAPTER_NAME() = default;
    virtual CALL_RETURN_T Call(CALL_ARG_LIST_WITH_TYPES) = 0;
};
%}
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
%}

// Forward declarations for types used in callbacks, which due to the order of swig interface includes could be needed.
%inline %{
namespace extra {
    namespace test {
        class TestBooleanResult;  // forward declaration
    }
}
%}

MAKE_CALLBACK_ADAPTER(BoolCallbackAdapter, ARGLIST(bool), void)
MAKE_CALLBACK_ADAPTER(UInt32CallbackAdapter, ARGLIST(std::uint32_t), void)
MAKE_CALLBACK_ADAPTER(StringCallbackAdapter, ARGLIST(const csp::common::String&), void)
MAKE_CALLBACK_ADAPTER(StringStringCallbackAdapter, ARGLIST(const csp::common::String&, const csp::common::String&), void)

/* LogSystem Callback Adapters */

MAKE_CALLBACK_ADAPTER(LogSystem_LogCallbackHandlerCSharpAdapter, ARGLIST(csp::common::LogLevel, const csp::common::String&), void)
MAKE_CALLBACK_ADAPTER(LogSystem_EventCallbackHandlerCSharpAdapter, ARGLIST(const csp::common::String&), void)
MAKE_CALLBACK_ADAPTER(LogSystem_BeginMarkerCallbackHandlerCSharpAdapter, ARGLIST(const csp::common::String&), void)
MAKE_CALLBACK_ADAPTER(LogSystem_EndMarkerCallbackHandlerCSharpAdapter, ARGLIST(void*), void)
MAKE_CALLBACK_ADAPTER(LogSystem_TestBooleanResultCallbackCSharpAdapter, ARGLIST(extra::test::TestBooleanResult), void)

/* Systems Callback Adapters */
MAKE_CALLBACK_ADAPTER(QuotaSystem_FeatureLimitCallbackCSharpAdapter, ARGLIST(const csp::systems::FeatureLimitResult&), void)
MAKE_CALLBACK_ADAPTER(NullResultCallbackAdapter, ARGLIST(const csp::systems::NullResult&), void)
MAKE_CALLBACK_ADAPTER(StringResultCallbackAdapter, ARGLIST(const csp::systems::StringResult&), void)
 
/* Multiplayer Callback Adapters */
MAKE_CALLBACK_ADAPTER(SpaceEntityUpdatedCallbackAdapter, 
                      ARGLIST(csp::multiplayer::SpaceEntity*,
                      csp::multiplayer::SpaceEntityUpdateFlags,
                      csp::common::Array<csp::multiplayer::ComponentUpdateInfo>), void)
MAKE_CALLBACK_ADAPTER(EntityCreatedCallbackAdapter, ARGLIST(csp::multiplayer::SpaceEntity*), void)
MAKE_CALLBACK_ADAPTER(ErrorCodeCallbackAdapter, ARGLIST(csp::multiplayer::ErrorCode), void)
MAKE_CALLBACK_ADAPTER(NetworkEventCallbackAdapter, ARGLIST(const csp::common::NetworkEventData&), void)
MAKE_CALLBACK_ADAPTER(EntityActionCallbackAdapter, ARGLIST(csp::multiplayer::ComponentBase*, const csp::common::String&, const csp::common::String&), void)

/* Conversation Callback Adapters */
MAKE_CALLBACK_ADAPTER(MessageResultCallbackAdapter, ARGLIST(const csp::multiplayer::MessageResult&), void)
MAKE_CALLBACK_ADAPTER(MessageCollectionResultCallbackAdapter, ARGLIST(const csp::multiplayer::MessageCollectionResult&), void)
MAKE_CALLBACK_ADAPTER(ConversationResultCallbackAdapter, ARGLIST(const csp::multiplayer::ConversationResult&), void)
MAKE_CALLBACK_ADAPTER(NumberOfRepliesResultCallbackAdapter, ARGLIST(const csp::multiplayer::NumberOfRepliesResult&), void)
MAKE_CALLBACK_ADAPTER(AnnotationResultCallbackAdapter, ARGLIST(const csp::multiplayer::AnnotationResult&), void)
MAKE_CALLBACK_ADAPTER(AnnotationThumbnailCollectionResultCallbackAdapter, ARGLIST(const csp::multiplayer::AnnotationThumbnailCollectionResult&), void)
MAKE_CALLBACK_ADAPTER(ConversationNetworkEventCallbackAdapter, ARGLIST(const csp::common::ConversationNetworkEventData&), void)


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

%define MAKE_CALLBACK_TYPEMAP(CALLBACK_CPP_SYMBOL, ADAPTER_NAME, ARG_LIST_WITH_TYPES, ARG_LIST_WITHOUT_TYPES)

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

/* LogSystem Callback Typemaps */
MAKE_CALLBACK_TYPEMAP(csp::common::LogSystem::LogCallbackHandler,
                      LogSystem_LogCallbackHandlerCSharpAdapter, 
                      ARGLIST(csp::common::LogLevel logLevel, const csp::common::String& message),
                      ARGLIST(logLevel, message))
MAKE_CALLBACK_TYPEMAP(csp::common::LogSystem::EventCallbackHandler,
                      LogSystem_EventCallbackHandlerCSharpAdapter, 
                      ARGLIST(const csp::common::String& eventMessage),
                      ARGLIST(eventMessage))
MAKE_CALLBACK_TYPEMAP(csp::common::LogSystem::BeginMarkerCallbackHandler,
                      LogSystem_BeginMarkerCallbackHandlerCSharpAdapter, 
                      ARGLIST(const csp::common::String& beginMarker),
                      ARGLIST(beginMarker))
MAKE_CALLBACK_TYPEMAP(csp::common::LogSystem::EndMarkerCallbackHandler,
                      LogSystem_EndMarkerCallbackHandlerCSharpAdapter, 
                      ARGLIST(void* irrelevantArg /* Legacy wrapper gen implication, ignore */),
                      ARGLIST(irrelevantArg))
MAKE_CALLBACK_TYPEMAP(extra::test::TestBooleanResultCallback,
                      LogSystem_TestBooleanResultCallbackCSharpAdapter, 
                      ARGLIST(extra::test::TestBooleanResult result),
                      ARGLIST(result))

/* Systems Callback Typemaps */
MAKE_CALLBACK_TYPEMAP(csp::systems::FeatureLimitCallback,
                      QuotaSystem_FeatureLimitCallbackCSharpAdapter,
                      ARGLIST(const csp::systems::FeatureLimitResult& result),
                      ARGLIST(result))
MAKE_CALLBACK_TYPEMAP(csp::systems::NullResultCallback,
                      NullResultCallbackAdapter,
                      ARGLIST(const csp::systems::NullResult& result),
                      ARGLIST(result))
MAKE_CALLBACK_TYPEMAP(csp::systems::StringResultCallback,
                      StringResultCallbackAdapter,
                      ARGLIST(const csp::systems::StringResult& result),
                      ARGLIST(result))

/* Multiplayer Callback Typemaps */
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::CallbackHandler,
                      BoolCallbackAdapter,
                      ARGLIST(bool success),
                      ARGLIST(success))

// This is a bit of a mess on CSP's part, duplicate callbacks in multiplayer and multiplayer::SpaceEntity.
// No reason for these to be different.
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::EntityCreatedCallback,
                      EntityCreatedCallbackAdapter,
                      ARGLIST(csp::multiplayer::SpaceEntity* spaceEntity),
                      ARGLIST(spaceEntity))

//SpaceEntity
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::SpaceEntity::UpdateCallback,
                      SpaceEntityUpdatedCallbackAdapter,
                      ARGLIST(csp::multiplayer::SpaceEntity* spaceEntity,
                              csp::multiplayer::SpaceEntityUpdateFlags updateFlags,
                              csp::common::Array<csp::multiplayer::ComponentUpdateInfo> componentUpdateInfos),
                      ARGLIST(spaceEntity, updateFlags, componentUpdateInfos))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::SpaceEntity::DestroyCallback,
                      BoolCallbackAdapter,
                      ARGLIST(bool success),
                      ARGLIST(success))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::SpaceEntity::CallbackHandler,
                      BoolCallbackAdapter,
                      ARGLIST(bool success),
                      ARGLIST(success))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::SpaceEntity::EntityCreatedCallback,
                      EntityCreatedCallbackAdapter,
                      ARGLIST(csp::multiplayer::SpaceEntity* spaceEntity),
                      ARGLIST(spaceEntity))

//RealtimeEngine
MAKE_CALLBACK_TYPEMAP(csp::common::EntityFetchCompleteCallback,
                      UInt32CallbackAdapter,
                      ARGLIST(std::uint32_t numEntitiesFetched),
                      ARGLIST(numEntitiesFetched))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::OnlineRealtimeEngine::ScopeLeaderCallback,
                      StringStringCallbackAdapter,
                      ARGLIST(const csp::common::String& scopeId, const csp::common::String& userId),
                      ARGLIST(scopeId, userId))

//MultiplayerConnection
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::MultiplayerConnection::ErrorCodeCallbackHandler,
                      ErrorCodeCallbackAdapter,
                      ARGLIST(csp::multiplayer::ErrorCode errorCode),
                      ARGLIST(errorCode))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::MultiplayerConnection::DisconnectionCallbackHandler,
                      StringCallbackAdapter,
                      ARGLIST(const csp::common::String& disconnectReason),
                      ARGLIST(disconnectReason))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::MultiplayerConnection::ConnectionCallbackHandler,
                      StringCallbackAdapter,
                      ARGLIST(const csp::common::String& connectionStatus),
                      ARGLIST(connectionStatus))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::MultiplayerConnection::NetworkInterruptionCallbackHandler,
                      StringCallbackAdapter,
                      ARGLIST(const csp::common::String& interruptReason),
                      ARGLIST(interruptReason))

//NetworkEventBus
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::NetworkEventCallback,
                      NetworkEventCallbackAdapter,
                      ARGLIST(const csp::common::NetworkEventData& networkEventData),
                      ARGLIST(networkEventData))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::NetworkEventBus::ErrorCodeCallbackHandler,
                      ErrorCodeCallbackAdapter,
                      ARGLIST(csp::multiplayer::ErrorCode errorCode),
                      ARGLIST(errorCode))

//ComponentBase
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::ComponentBase::EntityActionHandler,
                      EntityActionCallbackAdapter,
                      ARGLIST(csp::multiplayer::ComponentBase* component, const csp::common::String& actionName, const csp::common::String& actionParams),
                      ARGLIST(component, actionName, actionParams))

//Conversation
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::MessageResultCallback,
                      MessageResultCallbackAdapter,
                      ARGLIST(const csp::multiplayer::MessageResult& result),
                      ARGLIST(result))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::MessageCollectionResultCallback,
                      MessageCollectionResultCallbackAdapter,
                      ARGLIST(const csp::multiplayer::MessageCollectionResult& result),
                      ARGLIST(result))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::ConversationResultCallback,
                      ConversationResultCallbackAdapter,
                      ARGLIST(const csp::multiplayer::ConversationResult& result),
                      ARGLIST(result))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::NumberOfRepliesResultCallback,
                      NumberOfRepliesResultCallbackAdapter,
                      ARGLIST(const csp::multiplayer::NumberOfRepliesResult& result),
                      ARGLIST(result))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::AnnotationResultCallback,
                      AnnotationResultCallbackAdapter,
                      ARGLIST(const csp::multiplayer::AnnotationResult& result),
                      ARGLIST(result))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::AnnotationThumbnailCollectionResultCallback,
                      AnnotationThumbnailCollectionResultCallbackAdapter,
                      ARGLIST(const csp::multiplayer::AnnotationThumbnailCollectionResult& result),
                      ARGLIST(result))
MAKE_CALLBACK_TYPEMAP(csp::multiplayer::ConversationSpaceComponent::ConversationUpdateCallbackHandler,
                      ConversationNetworkEventCallbackAdapter,
                      ARGLIST(const csp::common::ConversationNetworkEventData& eventData),
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