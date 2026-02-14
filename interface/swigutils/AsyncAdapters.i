/*
 * This deals with generating glue that converts the director callback pattern into async/await that's natural to use in C#.
 * As we don't want to write several methods of boilerplate for each method, we abuse macros.
 * This is the only part of the prototype that I do not fully know how I would eliminate the need for manual wrapping effort, given enough time.
 * Perhaps you could symbol dump the .dll, figure out all the callback symbols, build a .txt file and run jinja with that as an input?
 *
 * If any of this sort of stuff becomes a significant effort, you may want to consider
 * a very small jinja2 step to preprocess some of your SWIG input files instead of this
 * undignified macrolarkey.
 */

/* 
 * Generic macros to stamp two things:
 * 1. An extension of the C++ callback type (from within C#) that overrides its `Call` function, and dispatches to an injected Action.
 * 2. An extension of the C# class that uses the callback type to create an awaitable member function.
 * The extension of the callback type is the magic that lets C++ call C# functions, it uses SWIGs director feature.
 * For #2, it's possible just packaging strait up C# extension methods may be more desirable, yet to be seen where the line is around stuff like this.
 * TODO: Extending this to something that can handle multiple callback arguments will be something that needs doing.
 * Params with types and params without types ... gross. There's probably a nicer way to do this.
 */
 
%include "swigutils/GeneralUtils.i" 

/*
 * If it's a method like `SetXCallback(Callback)`, then you just want to stamp MAKE_ACTION_CALLBACK"
 * If it's a full on Async method you want to await, like `await EnterSpace(spaceID...)`, then 
 * stamp with MAKE_ASYNC, which makes an action callback but also wraps in an awaitable. 
 * At the moment (2025), CALLBACKT is generally a csharp adapter defined in CallbackAdapters.i
 *
 * Note: MAKE_ACTION_CALLBACK is used by both MAKE_ASYNC_ZERO and MAKE_ASYNC macros, in order to define the related
 * callback type that is used by the async function. 
 *
 * Important note: some async functions might use the same callback type. This means that we needed a way to ensure
 * the same callback type would not be re-defined causing a compilation error. To do that, whenever a new callback
 * type is defined, a SWIG #define declaration is generated and used as reference to check for re-definitions.
 * Uniqueness is ensured based on name. It's possible to register identical types but with different
 * names. This is fine, but redundant, sort of up to you if you want your exposed action interfaces
 * to all be unique, or the same for action adapters that have the same types. I'd favour the latter.
 */

%define MAKE_ACTION_CALLBACK(ACTION_CALLBACK_TYPENAME, CALLBACKT, ACTION_TYPELIST_WITH_NAMES, ACTION_TYPELIST_WITHOUT_NAMES, ACTION_TYPELIST_ONLY_NAMES)
#ifdef SWIG_ACTION_CALLBACK_##ACTION_CALLBACK_TYPENAME##_DEFINED
  %echo "MAKE_ACTION_CALLBACK: action wrapper '" #ACTION_CALLBACK_TYPENAME "' already defined, skipping"
#else
  #define SWIG_ACTION_CALLBACK_##ACTION_CALLBACK_TYPENAME##_DEFINED
  %pragma(csharp) modulecode=%{
    public sealed class ACTION_CALLBACK_TYPENAME: CALLBACKT
    {
      private readonly System.Action<ACTION_TYPELIST_WITHOUT_NAMES> CallbackHandler;
      public ACTION_CALLBACK_TYPENAME(System.Action<ACTION_TYPELIST_WITHOUT_NAMES> handler) => CallbackHandler = handler;
      public override void Call(ACTION_TYPELIST_WITH_NAMES) => CallbackHandler(ACTION_TYPELIST_ONLY_NAMES);
    }
  %}
#endif
%enddef


/*
 * Below you'll note we have MAKE_ASYNC and MAKE_ASYNC_ZERO, and unfortunate compromise
 * for working in macrotown.
 * The bulk of these macros are the same, we only need to change whether or not we're providing an argument list.
 * This is the callback body that is shared between both async macros, such that we can avoid duplicating it.
 */
%define MAKE_ASYNC_CALLBACK_BODY(METHODNAME, CALLBACK_TYPENAME, CALLBACK_TYPELIST_ONLY_NAMES)
ConnectedSpacesPlatformDotNet.CALLBACK_TYPENAME callback = null;
    
    // Define the callback that will be called by the C++ code
    callback = new ConnectedSpacesPlatformDotNet.CALLBACK_TYPENAME(CALLBACK_TYPELIST_ONLY_NAMES => 
    {
        try
        {
            /* This is a bit jank. Due to the desire to use passthrough macros between async
             * and actions, we have this CALLBACK_TYPELIST_ONLY_NAMES param which yes, can be
             * a comma separated list for action style callbacks, but in async (awaitable) functions,
             * it's only ever a single name.
             * It ISNT always a ResultBase type (although that would simplify things if CSP would do that...)
             * Sometime's it's just a space entity, or a bool, or something else. */

            if((object)CALLBACK_TYPELIST_ONLY_NAMES is csp.systems.ResultBase _result)
            {
              // It's a result base
              #ifdef THROW_EXCEPTION_ON_RESULTBASE_FAILURE
              // Convert the failing result to a throw if we have that option enabled
              _result.ThrowOnFailure(nameof(METHODNAME##Async));
              #endif
              
              // Use _result here because we need to call ResultBase api, but we still pass the fully specified type in the TrySetResult
              // Remember that callbacks also have `init` and `inProgress` status's. We will often receive this callback more than once,
              // only finish when we get a final status.
              if (_result.GetResultCode() == csp.systems.EResultCode.Success || _result.GetResultCode() == csp.systems.EResultCode.Failed)
              {
                tcs.TrySetResult(CALLBACK_TYPELIST_ONLY_NAMES);
                // Now that the callback has been invoked, we can remove the root reference
                ConnectedSpacesPlatformDotNet.CallbackLifetime.Unroot(callback);
              }
            }
            else {
              // It's something else
              tcs.TrySetResult(CALLBACK_TYPELIST_ONLY_NAMES);
              // Now that the callback has been invoked, we can remove the root reference
              ConnectedSpacesPlatformDotNet.CallbackLifetime.Unroot(callback);
            }
        }
        catch (System.Exception ex)
        {
            // If any other exception occurs, we set it on the task completion source. Failsafe.
            tcs.TrySetException(ex);
        }

    });

    // ROOT the callback for the lifetime of the Task
    ConnectedSpacesPlatformDotNet.CallbackLifetime.Root(callback);
%enddef

/*
 * Note:
 * FULLY_NAMESPACED_CLASST is the full namespaced C++ class name, e.g. csp::systems::QuotaSystem
 * METHODNAME is the method name, e.g. GetTotalSpacesOwnedByUser
 * CALLBACK_TYPENAME is the type of the callback adapter class, for example FeatureLimitCallback. Note that we should not include
 * any namespace here, as the C# adapter class is always in the ConnectedSpacesPlatformDotNet namespace.
 * CALLBACKT is the C# adapter class that extends the callback type, for example FeatureLimitCallbackAdapter
 * CALLBACK_TYPELIST_WITH_NAMES is the full argument list with types, e.g. ARGLIST(const csp::systems::FeatureLimitResult& result)
 * CALLBACK_TYPELIST_WITHOUT_NAMES is the argument list without types, e.g. ARGLIST(const csp::systems::FeatureLimitResult)
 * CALLBACK_TYPELIST_ONLY_NAMES is just the argument names, e.g. ARGLIST(result)
 * FUNCTION_TYPELIST_WITH_NAMES is the full argument list with types for the function being wrapped, e.g. ARGLIST(const csp::common::String& userId, int someValue)
 * FUNCTION_TYPELIST_ONLY_NAMES is just the argument names for the function being wrapped, e.g. ARGLIST(userId, someValue)
 */
%define MAKE_ASYNC(
    FULLY_NAMESPACED_CLASST, 
    METHODNAME, 
    CALLBACK_TYPENAME,
    CALLBACKT,
    CALLBACK_TYPELIST_WITH_NAMES,
    CALLBACK_TYPELIST_WITHOUT_NAMES,
    CALLBACK_TYPELIST_ONLY_NAMES,
    FUNCTION_TYPELIST_WITH_NAMES,
    FUNCTION_TYPELIST_ONLY_NAMES
)
    
MAKE_ACTION_CALLBACK(CALLBACK_TYPENAME, CALLBACKT, CALLBACK_TYPELIST_WITH_NAMES, CALLBACK_TYPELIST_WITHOUT_NAMES, CALLBACK_TYPELIST_ONLY_NAMES)

/* 
 * Note: here we can add the ResultBase check to throw exceptions on failure. Ideally, the better place would be even 
 * callbacks instead of the async code. This is just a reminder that we have this option to replace the ugly 
 * "ThrowOnFailure" mechanism we currently have in place in Unity. 
 */
%extend FULLY_NAMESPACED_CLASST {
%proxycode %{

  public System.Threading.Tasks.Task<CALLBACK_TYPELIST_WITHOUT_NAMES> METHODNAME##Async(FUNCTION_TYPELIST_WITH_NAMES)
  {
    // Create a TaskCompletionSource to represent the async operation.
    System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES> tcs = 
        new System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES>();

    MAKE_ASYNC_CALLBACK_BODY(METHODNAME, CALLBACK_TYPENAME, CALLBACK_TYPELIST_ONLY_NAMES);

    // Run the method with the provided arguments and the callback
    // callback is defined in MAKE_ASYNC_CALLBACK_BODY
    METHODNAME(FUNCTION_TYPELIST_ONLY_NAMES, callback);

    return tcs.Task;
  }
%}
}
%enddef

/*
 * Variant of MAKE_ASYNC for zero-argument functions
 * Use this for things like `GetTotalSpacesOwnedByUser(Action<FeatureLimitResult> callback)`, where the calling
 * function takes no arguments other than the callback.
 *
 * Note:
 * FULLY_NAMESPACED_CLASST is the full namespaced C++ class name, e.g. csp::systems::QuotaSystem
 * METHODNAME is the method name, e.g. GetTotalSpacesOwnedByUser
 * CALLBACK_TYPENAME is the type of the callback adapter class, for example FeatureLimitCallback
 * CALLBACKT is the C# adapter class that extends the callback type, for example FeatureLimitCallbackAdapter
 * CALLBACK_TYPELIST_WITH_NAMES is the full argument list with types, e.g. ARGLIST(const csp::systems::FeatureLimitResult& result)
 * CALLBACK_TYPELIST_WITHOUT_NAMES is the argument list without types, e.g. ARGLIST(const csp::systems::FeatureLimitResult)
 * CALLBACK_TYPELIST_ONLY_NAMES is just the argument names, e.g. ARGLIST(result)
 */
%define MAKE_ASYNC_ZERO(
    FULLY_NAMESPACED_CLASST, 
    METHODNAME, 
    CALLBACK_TYPENAME,
    CALLBACKT,
    CALLBACK_TYPELIST_WITH_NAMES,
    CALLBACK_TYPELIST_WITHOUT_NAMES,
    CALLBACK_TYPELIST_ONLY_NAMES
)
    
MAKE_ACTION_CALLBACK(CALLBACK_TYPENAME, CALLBACKT, CALLBACK_TYPELIST_WITH_NAMES, CALLBACK_TYPELIST_WITHOUT_NAMES, CALLBACK_TYPELIST_ONLY_NAMES)

%extend FULLY_NAMESPACED_CLASST {
%proxycode %{
  public System.Threading.Tasks.Task<CALLBACK_TYPELIST_WITHOUT_NAMES> METHODNAME##Async()
  {  
    // Create a TaskCompletionSource to represent the async operation.
    System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES> tcs = 
        new System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES>();

    MAKE_ASYNC_CALLBACK_BODY(METHODNAME, CALLBACK_TYPENAME, CALLBACK_TYPELIST_ONLY_NAMES);

    // Run the method with the provided arguments and the callback
    METHODNAME(callback);

    return tcs.Task;

  }
%}
}

%enddef

/* 
 * Stamp out all the async convertors you need. Remember for inheritance hierarchies, you generally want to put these things on the base class 
 * Annoyingly manual, might be a better way, especially if you're willing to consider a templating step such as a Jinja pass. 
 * Definitely think about putting these listings in a different file to keep them separate from the disgusting generic declarations above,
 * as well as to better isolate errors when they are inevitably made.
 * Everything here depends on the CallbackAdapters declared in CallbackAdapters.i.
 */

 /*
  * Start with Action Adapters. MAKE_ASYNC (for await) also does this, as its how we do the TaskCompletionSource for that,
  * however, not everything is an `await` style function. Some functions take registerable callbacks for repeated use,
  * such as the LogSystem. For these functions, we only create action adapters, as doing `await SetLogCallback` is nonsensical.
  *

/* LogSystem Actions Adapters */
MAKE_ACTION_CALLBACK(LogCallback,
                     LogCallbackHandlerAdapter,
                     ARGLIST(csp.common.LogLevel logLevel, string message),
                     ARGLIST(csp.common.LogLevel, string),
                     ARGLIST(logLevel, message));
MAKE_ACTION_CALLBACK(EventCallback,
                     EventCallbackHandlerAdapter,
                     ARGLIST(string eventMessage),
                     ARGLIST(string),
                     ARGLIST(eventMessage));
MAKE_ACTION_CALLBACK(BeginMarkerCallback,
                     BeginMarkerCallbackHandlerAdapter,
                     ARGLIST(string beginMarker),
                     ARGLIST(string),
                     ARGLIST(beginMarker));
MAKE_ACTION_CALLBACK(EndMarkerCallback,
                     EndMarkerCallbackHandlerAdapter,
                     ARGLIST(System.IntPtr irrelevant),
                     ARGLIST(System.IntPtr),
                     ARGLIST(irrelevant));

/* SpaceEntity Action Adapters */
MAKE_ACTION_CALLBACK(UpdateCallback,
                     SpaceEntityUpdatedCallbackAdapter,
                     ARGLIST(csp.multiplayer.SpaceEntity spaceEntity, csp.multiplayer.SpaceEntityUpdateFlags updateFlags, csp.common.ComponentUpdateInfoArray componentUpdateInfos),
                     ARGLIST(csp.multiplayer.SpaceEntity, csp.multiplayer.SpaceEntityUpdateFlags, csp.common.ComponentUpdateInfoArray),
                     ARGLIST(spaceEntity, updateFlags, componentUpdateInfos));

MAKE_ACTION_CALLBACK(DestroyCallback,
                     BoolCallbackAdapter,
                     ARGLIST(bool destroyed),
                     ARGLIST(bool),
                     ARGLIST(destroyed));

MAKE_ACTION_CALLBACK(PatchSentCallback,
                     BoolCallbackAdapter,
                     ARGLIST(bool patchSent),
                     ARGLIST(bool),
                     ARGLIST(patchSent));

/* MultiplayerConnection Action Adapters */
MAKE_ACTION_CALLBACK(DisconnectionCallback,
                     StringCallbackAdapter,
                     ARGLIST(string disconnectReason),
                     ARGLIST(string),
                     ARGLIST(disconnectReason));

MAKE_ACTION_CALLBACK(ConnectionCallback,
                     StringCallbackAdapter,
                     ARGLIST(string connectionStatus),
                     ARGLIST(string),
                     ARGLIST(connectionStatus));

MAKE_ACTION_CALLBACK(NetworkInterruptionCallback,
                     StringCallbackAdapter,
                     ARGLIST(string interruptReason),
                     ARGLIST(string),
                     ARGLIST(interruptReason));

/* OnlineRealtimeEngine Action Adapters */
MAKE_ACTION_CALLBACK(RemoteEntityCreatedCallback,
                     EntityCreatedCallbackAdapter,
                     ARGLIST(csp.multiplayer.SpaceEntity spaceEntity),
                     ARGLIST(csp.multiplayer.SpaceEntity),
                     ARGLIST(spaceEntity));

MAKE_ACTION_CALLBACK(ScriptLeaderReadyCallback,
                     BoolCallbackAdapter,
                     ARGLIST(bool ready),
                     ARGLIST(bool),
                     ARGLIST(ready));

MAKE_ACTION_CALLBACK(ScopeLeaderCallback,
                     StringStringCallbackAdapter,
                     ARGLIST(string scopeId, string userId),
                     ARGLIST(string, string),
                     ARGLIST(scopeId, userId));

MAKE_ACTION_CALLBACK(EntityFetchCompleteCallback,
                     UInt32CallbackAdapter,
                     ARGLIST(uint numEntitiesFetched),
                     ARGLIST(uint),
                     ARGLIST(numEntitiesFetched));

/* ConversationSpaceComponent Action Adapters */
MAKE_ACTION_CALLBACK(ConversationUpdateCallback,
                     ConversationNetworkEventCallbackAdapter,
                     ARGLIST(csp.common.ConversationNetworkEventData eventData),
                     ARGLIST(csp.common.ConversationNetworkEventData),
                     ARGLIST(eventData));

/* AssetSystem Action Adapters */
MAKE_ACTION_CALLBACK(AssetDetailBlobChangedCallback,
                     AssetDetailBlobChangedCallbackAdapter,
                     ARGLIST(csp.common.AssetDetailBlobChangedNetworkEventData eventData),
                     ARGLIST(csp.common.AssetDetailBlobChangedNetworkEventData),
                     ARGLIST(eventData));

MAKE_ACTION_CALLBACK(MaterialChangedCallback,
                     MaterialChangedCallbackAdapter,
                     ARGLIST(csp.common.MaterialChangedParams materialParams),
                     ARGLIST(csp.common.MaterialChangedParams),
                     ARGLIST(materialParams));

/* SpaceSystem Action Adapters */
MAKE_ACTION_CALLBACK(AsyncCallCompletedCallback,
                     AsyncCallCompletedCallbackAdapter,
                     ARGLIST(csp.common.AsyncCallCompletedEventData eventData),
                     ARGLIST(csp.common.AsyncCallCompletedEventData),
                     ARGLIST(eventData));

/* UserSystem Action Adapters */
MAKE_ACTION_CALLBACK(LoginTokenInfoCallback,
                     LoginTokenInfoResultCallbackAdapter,
                     ARGLIST(csp.systems.LoginTokenInfoResult result),
                     ARGLIST(csp.systems.LoginTokenInfoResult),
                     ARGLIST(result));

MAKE_ACTION_CALLBACK(UserPermissionsChangedCallback,
                     UserPermissionsChangedCallbackAdapter,
                     ARGLIST(csp.common.AccessControlChangedNetworkEventData eventData),
                     ARGLIST(csp.common.AccessControlChangedNetworkEventData),
                     ARGLIST(eventData));

/* SequenceSystem Action Adapters */
MAKE_ACTION_CALLBACK(SequenceChangedCallback,
                     SequenceChangedCallbackAdapter,
                     ARGLIST(csp.common.SequenceChangedNetworkEventData eventData),
                     ARGLIST(csp.common.SequenceChangedNetworkEventData),
                     ARGLIST(eventData));

/* HotspotSequenceSystem Action Adapters */
MAKE_ACTION_CALLBACK(HotspotSequenceChangedCallback,
                     SequenceChangedCallbackAdapter,
                     ARGLIST(csp.common.SequenceChangedNetworkEventData eventData),
                     ARGLIST(csp.common.SequenceChangedNetworkEventData),
                     ARGLIST(eventData));

/* NetworkEventBus Action Adapters */
MAKE_ACTION_CALLBACK(NetworkEventCallback,
                     NetworkEventCallbackAdapter,
                     ARGLIST(csp.common.NetworkEventData networkEventData),
                     ARGLIST(csp.common.NetworkEventData),
                     ARGLIST(networkEventData));


/* 
 * Now stamp out Async adapters.
 * These are the things that let you call Result myResult = await MyFunctionAsync(); 
 * Note the "Async" there, a compromise we have made is that all awaitable functions
 * get "Async" appended to them. Due to this, you can use both the actions formulation
 * where you manually set a callback, or the await one, supporting multiple programming styles.
 */


/* MULTIPLAYER MODULE */

/* SpaceEntity */
MAKE_ASYNC(csp::multiplayer::SpaceEntity,
           CreateChildEntity,
           EntityCreatedCallback,
           EntityCreatedCallbackAdapter,
           ARGLIST(csp.multiplayer.SpaceEntity spaceEntity),
           ARGLIST(csp.multiplayer.SpaceEntity),
           ARGLIST(spaceEntity),
           ARGLIST(string name, csp.multiplayer.SpaceTransform spaceTransform),
           ARGLIST(name, spaceTransform)
)

MAKE_ASYNC_ZERO(csp::multiplayer::SpaceEntity,
                Destroy,
                DestroyCallback,
                BoolCallbackAdapter,
                ARGLIST(bool success),
                ARGLIST(bool),
                ARGLIST(success)
)

/* MultiplayerConnection */
MAKE_ASYNC(csp::multiplayer::MultiplayerConnection,
           SetAllowSelfMessagingFlag,
           ErrorCodeCallback,
           ErrorCodeCallbackAdapter,
           ARGLIST(csp.multiplayer.ErrorCode errorCode),
           ARGLIST(csp.multiplayer.ErrorCode),
           ARGLIST(errorCode),
           ARGLIST(bool allowSelfMessaging),
           ARGLIST(allowSelfMessaging)
)

/* OnlineRealtimeEngine */
MAKE_ASYNC(csp::multiplayer::OnlineRealtimeEngine,
           CreateAvatar,
           EntityCreatedCallback,
           EntityCreatedCallbackAdapter,
           ARGLIST(csp.multiplayer.SpaceEntity spaceEntity),
           ARGLIST(csp.multiplayer.SpaceEntity),
           ARGLIST(spaceEntity),
           ARGLIST(string name, string userId, csp.multiplayer.SpaceTransform spaceTransform, bool isVisible, csp.multiplayer.AvatarState state, string avatarId, csp.multiplayer.AvatarPlayMode avatarPlayMode, csp.multiplayer.LocomotionModel locomotionModel),
           ARGLIST(name, userId, spaceTransform, isVisible, state, avatarId, avatarPlayMode, locomotionModel)
)

MAKE_ASYNC(csp::multiplayer::OnlineRealtimeEngine,
           CreateEntity,
           EntityCreatedCallback,
           EntityCreatedCallbackAdapter,
           ARGLIST(csp.multiplayer.SpaceEntity spaceEntity),
           ARGLIST(csp.multiplayer.SpaceEntity),
           ARGLIST(spaceEntity),
           ARGLIST(string name, csp.multiplayer.SpaceTransform spaceTransform, ulong? parentId),
           ARGLIST(name, spaceTransform, parentId)
)

MAKE_ASYNC(csp::multiplayer::OnlineRealtimeEngine,
           DestroyEntity,
           DestroyCallback,
           BoolCallbackAdapter,
           ARGLIST(bool success),
           ARGLIST(bool),
           ARGLIST(success),
           ARGLIST(csp.multiplayer.SpaceEntity entity),
           ARGLIST(entity)
)

/* OfflineRealtimeEngine */
MAKE_ASYNC(csp::multiplayer::OfflineRealtimeEngine,
           CreateAvatar,
           EntityCreatedCallback,
           EntityCreatedCallbackAdapter,
           ARGLIST(csp.multiplayer.SpaceEntity spaceEntity),
           ARGLIST(csp.multiplayer.SpaceEntity),
           ARGLIST(spaceEntity),
           ARGLIST(string name, string userId, csp.multiplayer.SpaceTransform transform, bool isVisible, csp.multiplayer.AvatarState state, string avatarId, csp.multiplayer.AvatarPlayMode avatarPlayMode, csp.multiplayer.LocomotionModel locomotionModel),
           ARGLIST(name, userId, transform, isVisible, state, avatarId, avatarPlayMode, locomotionModel)
)

MAKE_ASYNC(csp::multiplayer::OfflineRealtimeEngine,
           CreateEntity,
           EntityCreatedCallback,
           EntityCreatedCallbackAdapter,
           ARGLIST(csp.multiplayer.SpaceEntity spaceEntity),
           ARGLIST(csp.multiplayer.SpaceEntity),
           ARGLIST(spaceEntity),
           ARGLIST(string name, csp.multiplayer.SpaceTransform transform, ulong? parentId),
           ARGLIST(name, transform, parentId)
)

MAKE_ASYNC(csp::multiplayer::OfflineRealtimeEngine,
           DestroyEntity,
           DestroyCallback,
           BoolCallbackAdapter,
           ARGLIST(bool success),
           ARGLIST(bool),
           ARGLIST(success),
           ARGLIST(csp.multiplayer.SpaceEntity entity),
           ARGLIST(entity)
)

/* NetworkEventBus */
MAKE_ASYNC(csp::multiplayer::NetworkEventBus,
           SendNetworkEvent,
           ErrorCodeCallback,
           ErrorCodeCallbackAdapter,
           ARGLIST(csp.multiplayer.ErrorCode errorCode),
           ARGLIST(csp.multiplayer.ErrorCode),
           ARGLIST(errorCode),
           ARGLIST(string eventName, csp.common.ReplicatedValueArray args),
           ARGLIST(eventName, args)
)

MAKE_ASYNC(csp::multiplayer::NetworkEventBus,
           SendNetworkEventToClient,
           ErrorCodeCallback,
           ErrorCodeCallbackAdapter,
           ARGLIST(csp.multiplayer.ErrorCode errorCode),
           ARGLIST(csp.multiplayer.ErrorCode),
           ARGLIST(errorCode),
           ARGLIST(string eventName, csp.common.ReplicatedValueArray args, ulong targetClientId),
           ARGLIST(eventName, args, targetClientId)
)

/* ConversationSpaceComponent */
MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
           CreateConversation,
           StringResultCallback,
           StringResultCallbackAdapter,
           ARGLIST(csp.systems.StringResult result),
           ARGLIST(csp.systems.StringResult),
           ARGLIST(result),
           ARGLIST(string message),
           ARGLIST(message)
)

MAKE_ASYNC_ZERO(csp::multiplayer::ConversationSpaceComponent,
                DeleteConversation,
                NullResultCallback,
                NullResultCallbackAdapter,
                ARGLIST(csp.systems.NullResult result),
                ARGLIST(csp.systems.NullResult),
                ARGLIST(result)
) 

MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
           AddMessage,
           MessageResultCallback,
           MessageResultCallbackAdapter,
           ARGLIST(csp.multiplayer.MessageResult result),
           ARGLIST(csp.multiplayer.MessageResult),
           ARGLIST(result),
           ARGLIST(string message),
           ARGLIST(message)
)

MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
           DeleteMessage,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string messageId),
           ARGLIST(messageId)
)

MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
           GetMessagesFromConversation,
           MessageCollectionResultCallback,
           MessageCollectionResultCallbackAdapter,
           ARGLIST(csp.multiplayer.MessageCollectionResult result),
           ARGLIST(csp.multiplayer.MessageCollectionResult),
           ARGLIST(result),
           ARGLIST(int? resultsSkipNumber, int? resultsMaxNumber),
           ARGLIST(resultsSkipNumber, resultsMaxNumber)
)

MAKE_ASYNC_ZERO(csp::multiplayer::ConversationSpaceComponent,
                GetConversationInfo,
                ConversationResultCallback,
                ConversationResultCallbackAdapter,
                ARGLIST(csp.multiplayer.ConversationResult result),
                ARGLIST(csp.multiplayer.ConversationResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
           UpdateConversation,
           ConversationResultCallback,
           ConversationResultCallbackAdapter,
           ARGLIST(csp.multiplayer.ConversationResult result),
           ARGLIST(csp.multiplayer.ConversationResult),
           ARGLIST(result),
           ARGLIST(csp.multiplayer.MessageUpdateParams newData),
           ARGLIST(newData)
)

MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
           GetMessageInfo,
           MessageResultCallback,
           MessageResultCallbackAdapter,
           ARGLIST(csp.multiplayer.MessageResult result),
           ARGLIST(csp.multiplayer.MessageResult),
           ARGLIST(result),
           ARGLIST(string messageId),
           ARGLIST(messageId)
)

MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
           UpdateMessage,
           MessageResultCallback,
           MessageResultCallbackAdapter,
           ARGLIST(csp.multiplayer.MessageResult result),
           ARGLIST(csp.multiplayer.MessageResult),
           ARGLIST(result),
           ARGLIST(string messageId, csp.multiplayer.MessageUpdateParams newData),
           ARGLIST(messageId, newData)
)

MAKE_ASYNC_ZERO(csp::multiplayer::ConversationSpaceComponent,
                GetNumberOfReplies,
                NumberOfRepliesResultCallback,
                NumberOfRepliesResultCallbackAdapter,
                ARGLIST(csp.multiplayer.NumberOfRepliesResult result),
                ARGLIST(csp.multiplayer.NumberOfRepliesResult),
                ARGLIST(result)
)

MAKE_ASYNC_ZERO(csp::multiplayer::ConversationSpaceComponent,
                GetConversationAnnotation,
                AnnotationResultCallback,
                AnnotationResultCallbackAdapter,
                ARGLIST(csp.multiplayer.AnnotationResult result),
                ARGLIST(csp.multiplayer.AnnotationResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
           SetConversationAnnotation,
           AnnotationResultCallback,
           AnnotationResultCallbackAdapter,
           ARGLIST(csp.multiplayer.AnnotationResult result),
           ARGLIST(csp.multiplayer.AnnotationResult),
           ARGLIST(result),
           ARGLIST(csp.multiplayer.AnnotationUpdateParams annotationParams, csp.systems.BufferAssetDataSource annotation, csp.systems.BufferAssetDataSource annotationThumbnail),
           ARGLIST(annotationParams, annotation, annotationThumbnail)
)

MAKE_ASYNC_ZERO(csp::multiplayer::ConversationSpaceComponent,
                DeleteConversationAnnotation,
                NullResultCallback,
                NullResultCallbackAdapter,
                ARGLIST(csp.systems.NullResult result),
                ARGLIST(csp.systems.NullResult),
                ARGLIST(result)
) 

MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
           GetAnnotation,
           AnnotationResultCallback,
           AnnotationResultCallbackAdapter,
           ARGLIST(csp.multiplayer.AnnotationResult result),
           ARGLIST(csp.multiplayer.AnnotationResult),
           ARGLIST(result),
           ARGLIST(string messageId),
           ARGLIST(messageId)
)

MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
          SetAnnotation,
          AnnotationResultCallback,
          AnnotationResultCallbackAdapter,
          ARGLIST(csp.multiplayer.AnnotationResult result),
          ARGLIST(csp.multiplayer.AnnotationResult),
          ARGLIST(result),
          ARGLIST(string messageId, csp.multiplayer.AnnotationUpdateParams updateParams, csp.systems.BufferAssetDataSource annotation, csp.systems.BufferAssetDataSource annotationThumbnail),
          ARGLIST(messageId, updateParams, annotation, annotationThumbnail)
)

MAKE_ASYNC(csp::multiplayer::ConversationSpaceComponent,
           DeleteAnnotation,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string messageId),
           ARGLIST(messageId)
)

MAKE_ASYNC_ZERO(csp::multiplayer::ConversationSpaceComponent,
                GetAnnotationThumbnailsForConversation,
                AnnotationThumbnailCollectionResultCallback,
                AnnotationThumbnailCollectionResultCallbackAdapter,
                ARGLIST(csp.multiplayer.AnnotationThumbnailCollectionResult result),
                ARGLIST(csp.multiplayer.AnnotationThumbnailCollectionResult),
                ARGLIST(result)
)


/* SYSTEMS MODULE */

/* AssetSystem Async Functions */
MAKE_ASYNC(csp::systems::AssetSystem,
           CreateAssetCollection,
           AssetCollectionResultCallback,
           AssetCollectionResultCallbackAdapter,
           ARGLIST(csp.systems.AssetCollectionResult result),
           ARGLIST(csp.systems.AssetCollectionResult),
           ARGLIST(result),
           ARGLIST(string? spaceId, string? parentAssetCollectionId, string assetCollectionName, csp.common.StringDict? metadata, csp.systems.EAssetCollectionType type, csp.common.StringArray? tags),
           ARGLIST(spaceId, parentAssetCollectionId, assetCollectionName, metadata, type, tags)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           DeleteAssetCollection,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AssetCollection assetCollection),
           ARGLIST(assetCollection)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           DeleteMultipleAssetCollections,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.common.AssetCollectionArray assetCollections),
           ARGLIST(assetCollections)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           CopyAssetCollectionsToSpace,
           AssetCollectionsResultCallback,
           AssetCollectionsResultCallbackAdapter,
           ARGLIST(csp.systems.AssetCollectionsResult result),
           ARGLIST(csp.systems.AssetCollectionsResult),
           ARGLIST(result),
           ARGLIST(csp.common.AssetCollectionArray sourceAssetCollections, string destSpaceId, bool copyAsync),
           ARGLIST(sourceAssetCollections, destSpaceId, copyAsync)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetAssetCollectionById,
           AssetCollectionResultCallback,
           AssetCollectionResultCallbackAdapter,
           ARGLIST(csp.systems.AssetCollectionResult result),
           ARGLIST(csp.systems.AssetCollectionResult),
           ARGLIST(result),
           ARGLIST(string assetCollectionId),
           ARGLIST(assetCollectionId)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetAssetCollectionByName,
           AssetCollectionResultCallback,
           AssetCollectionResultCallbackAdapter,
           ARGLIST(csp.systems.AssetCollectionResult result),
           ARGLIST(csp.systems.AssetCollectionResult),
           ARGLIST(result),
           ARGLIST(string assetCollectionName),
           ARGLIST(assetCollectionName)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           FindAssetCollections,
           AssetCollectionsResultCallback,
           AssetCollectionsResultCallbackAdapter,
           ARGLIST(csp.systems.AssetCollectionsResult result),
           ARGLIST(csp.systems.AssetCollectionsResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray? ids, string? parentId, csp.common.StringArray? names, csp.common.EAssetCollectionTypeArray? types, csp.common.StringArray? tags, csp.common.StringArray? spaceIds, int? resultsSkipNumber, int? resultsMaxNumber),
           ARGLIST(ids, parentId, names, types, tags, spaceIds, resultsSkipNumber, resultsMaxNumber)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           UpdateAssetCollectionMetadata,
           AssetCollectionResultCallback,
           AssetCollectionResultCallbackAdapter,
           ARGLIST(csp.systems.AssetCollectionResult result),
           ARGLIST(csp.systems.AssetCollectionResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AssetCollection assetCollection, csp.common.StringDict newMetadata, csp.common.StringArray? tags),
           ARGLIST(assetCollection, newMetadata, tags)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetAssetCollectionCount,
           AssetCollectionCountResultCallback,
           AssetCollectionCountResultCallbackAdapter,
           ARGLIST(csp.systems.AssetCollectionCountResult result),
           ARGLIST(csp.systems.AssetCollectionCountResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray? ids, string? parentId, csp.common.StringArray? names, csp.common.EAssetCollectionTypeArray? types, csp.common.StringArray? tags, csp.common.StringArray? spaceIds),
           ARGLIST(ids, parentId, names, types, tags, spaceIds)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           CreateAsset,
           AssetResultCallback,
           AssetResultCallbackAdapter,
           ARGLIST(csp.systems.AssetResult result),
           ARGLIST(csp.systems.AssetResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AssetCollection assetCollection, string name, string? thirdPartyPackagedAssetIdentifier, csp.systems.EThirdPartyPlatform? thirdPartyPlatform, csp.systems.EAssetType type),
           ARGLIST(assetCollection, name, thirdPartyPackagedAssetIdentifier, thirdPartyPlatform, type)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           UpdateAsset,
           AssetResultCallback,
           AssetResultCallbackAdapter,
           ARGLIST(csp.systems.AssetResult result),
           ARGLIST(csp.systems.AssetResult),
           ARGLIST(result),
           ARGLIST(csp.systems.Asset asset),
           ARGLIST(asset)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           DeleteAsset,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AssetCollection assetCollection, csp.systems.Asset asset),
           ARGLIST(assetCollection, asset)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetAssetsInCollection,
           AssetsResultCallback,
           AssetsResultCallbackAdapter,
           ARGLIST(csp.systems.AssetsResult result),
           ARGLIST(csp.systems.AssetsResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AssetCollection assetCollection),
           ARGLIST(assetCollection)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetAssetById,
           AssetResultCallback,
           AssetResultCallbackAdapter,
           ARGLIST(csp.systems.AssetResult result),
           ARGLIST(csp.systems.AssetResult),
           ARGLIST(result),
           ARGLIST(string assetCollectionId, string assetId),
           ARGLIST(assetCollectionId, assetId)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetAssetsByCollectionIds,
           AssetsResultCallback,
           AssetsResultCallbackAdapter,
           ARGLIST(csp.systems.AssetsResult result),
           ARGLIST(csp.systems.AssetsResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray assetCollectionIds),
           ARGLIST(assetCollectionIds)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetAssetsByCriteria,
           AssetsResultCallback,
           AssetsResultCallbackAdapter,
           ARGLIST(csp.systems.AssetsResult result),
           ARGLIST(csp.systems.AssetsResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray assetCollectionIds, csp.common.StringArray? assetIds, csp.common.StringArray? assetNames, csp.common.EAssetTypeArray? assetTypes),
           ARGLIST(assetCollectionIds, assetIds, assetNames, assetTypes)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           UploadAssetData,
           UriResultCallback,
           UriResultCallbackAdapter,
           ARGLIST(csp.systems.UriResult result),
           ARGLIST(csp.systems.UriResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AssetCollection assetCollection, csp.systems.Asset asset, csp.systems.AssetDataSource assetDataSource),
           ARGLIST(assetCollection, asset, assetDataSource)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           UploadAssetDataEx,
           UriResultCallback,
           UriResultCallbackAdapter,
           ARGLIST(csp.systems.UriResult result),
           ARGLIST(csp.systems.UriResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AssetCollection assetCollection, csp.systems.Asset asset, csp.systems.AssetDataSource assetDataSource, csp.common.CancellationToken cancellationToken),
           ARGLIST(assetCollection, asset, assetDataSource, cancellationToken)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           DownloadAssetData,
           AssetDataResultCallback,
           AssetDataResultCallbackAdapter,
           ARGLIST(csp.systems.AssetDataResult result),
           ARGLIST(csp.systems.AssetDataResult),
           ARGLIST(result),
           ARGLIST(csp.systems.Asset asset),
           ARGLIST(asset)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           DownloadAssetDataEx,
           AssetDataResultCallback,
           AssetDataResultCallbackAdapter,
           ARGLIST(csp.systems.AssetDataResult result),
           ARGLIST(csp.systems.AssetDataResult),
           ARGLIST(result),
           ARGLIST(csp.systems.Asset asset, csp.common.CancellationToken cancellationToken),
           ARGLIST(asset, cancellationToken)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetAssetDataSize,
           UInt64ResultCallback,
           UInt64ResultCallbackAdapter,
           ARGLIST(csp.systems.UInt64Result result),
           ARGLIST(csp.systems.UInt64Result),
           ARGLIST(result),
           ARGLIST(csp.systems.Asset asset),
           ARGLIST(asset)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetLODChain,
           LODChainResultCallback,
           LODChainResultCallbackAdapter,
           ARGLIST(csp.systems.LODChainResult result),
           ARGLIST(csp.systems.LODChainResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AssetCollection assetCollection),
           ARGLIST(assetCollection)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           RegisterAssetToLODChain,
           AssetResultCallback,
           AssetResultCallbackAdapter,
           ARGLIST(csp.systems.AssetResult result),
           ARGLIST(csp.systems.AssetResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AssetCollection assetCollection, csp.systems.Asset asset, int lodLevel),
           ARGLIST(assetCollection, asset, lodLevel)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           CreateMaterial,
           MaterialResultCallback,
           MaterialResultCallbackAdapter,
           ARGLIST(csp.systems.MaterialResult result),
           ARGLIST(csp.systems.MaterialResult),
           ARGLIST(result),
           ARGLIST(string name, csp.systems.EShaderType shaderType, string spaceId, csp.common.StringDict metadata, csp.common.StringArray assetTags),
           ARGLIST(name, shaderType, spaceId, metadata, assetTags)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           UpdateMaterial,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.systems.Material material),
           ARGLIST(material)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           DeleteMaterial,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.systems.Material material),
           ARGLIST(material)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetMaterials,
           MaterialsResultCallback,
           MaterialsResultCallbackAdapter,
           ARGLIST(csp.systems.MaterialsResult result),
           ARGLIST(csp.systems.MaterialsResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetMaterial,
           MaterialResultCallback,
           MaterialResultCallbackAdapter,
           ARGLIST(csp.systems.MaterialResult result),
           ARGLIST(csp.systems.MaterialResult),
           ARGLIST(result),
           ARGLIST(string assetCollectionId, string assetId),
           ARGLIST(assetCollectionId, assetId)
)

MAKE_ASYNC(csp::systems::AssetSystem,
           GetMaterialFromUri,
           MaterialResultCallback,
           MaterialResultCallbackAdapter,
           ARGLIST(csp.systems.MaterialResult result),
           ARGLIST(csp.systems.MaterialResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AssetCollection assetCollection, string assetId, string uri),
           ARGLIST(assetCollection, assetId, uri)
)

/* SpaceSystem Async Functions */

MAKE_ASYNC(csp::systems::SpaceSystem,
           EnterSpace,
           SpaceResultCallback,
           SpaceResultCallbackAdapter,
           ARGLIST(csp.systems.SpaceResult result),
           ARGLIST(csp.systems.SpaceResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.common.IRealtimeEngine realtimeEngine),
           ARGLIST(spaceId, realtimeEngine)
)

MAKE_ASYNC_ZERO(csp::systems::SpaceSystem,
                ExitSpace,
                NullResultCallback,
                NullResultCallbackAdapter,
                ARGLIST(csp.systems.NullResult result),
                ARGLIST(csp.systems.NullResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           CreateSpace,
           SpaceResultCallback,
           SpaceResultCallbackAdapter,
           ARGLIST(csp.systems.SpaceResult result),
           ARGLIST(csp.systems.SpaceResult),
           ARGLIST(result),
           ARGLIST(string name, string description, csp.systems.SpaceAttributes attributes, csp.systems.InviteUserRoleInfoCollection? inviteUsers, csp.common.StringDict metadata, csp.systems.FileAssetDataSource? fileThumbnail, csp.common.StringArray? tags),
           ARGLIST(name, description, attributes, inviteUsers, metadata, fileThumbnail, tags)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           CreateSpaceWithBuffer,
           SpaceResultCallback,
           SpaceResultCallbackAdapter,
           ARGLIST(csp.systems.SpaceResult result),
           ARGLIST(csp.systems.SpaceResult),
           ARGLIST(result),
           ARGLIST(string name, string description, csp.systems.SpaceAttributes attributes, csp.systems.InviteUserRoleInfoCollection? inviteUsers, csp.common.StringDict metadata, csp.systems.BufferAssetDataSource thumbnail, csp.common.StringArray? tags),
           ARGLIST(name, description, attributes, inviteUsers, metadata, thumbnail, tags)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           UpdateSpace,
           BasicSpaceResultCallback,
           BasicSpaceResultCallbackAdapter,
           ARGLIST(csp.systems.BasicSpaceResult result),
           ARGLIST(csp.systems.BasicSpaceResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string? name, string? description, csp.systems.SpaceAttributes? type, csp.common.StringArray? tags),
           ARGLIST(spaceId, name, description, type, tags)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           DeleteSpace,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC_ZERO(csp::systems::SpaceSystem,
                GetSpaces,
                SpacesResultCallback,
                SpacesResultCallbackAdapter,
                ARGLIST(csp.systems.SpacesResult result),
                ARGLIST(csp.systems.SpacesResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetSpacesByAttributes,
           BasicSpacesResultCallback,
           BasicSpacesResultCallbackAdapter,
           ARGLIST(csp.systems.BasicSpacesResult result),
           ARGLIST(csp.systems.BasicSpacesResult),
           ARGLIST(result),
           ARGLIST(bool? isDiscoverable, bool? isArchived, bool? requiresInvite, int? resultsSkip, int? resultsMax, csp.common.StringArray? mustContainTags, csp.common.StringArray? mustExcludeTags, bool? mustIncludeAllTags),
           ARGLIST(isDiscoverable, isArchived, requiresInvite, resultsSkip, resultsMax, mustContainTags, mustExcludeTags, mustIncludeAllTags)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetSpacesByIds,
           SpacesResultCallback,
           SpacesResultCallbackAdapter,
           ARGLIST(csp.systems.SpacesResult result),
           ARGLIST(csp.systems.SpacesResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray requestedSpaceIDs),
           ARGLIST(requestedSpaceIDs)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetSpacesForUserId,
           SpacesResultCallback,
           SpacesResultCallbackAdapter,
           ARGLIST(csp.systems.SpacesResult result),
           ARGLIST(csp.systems.SpacesResult),
           ARGLIST(result),
           ARGLIST(string userId),
           ARGLIST(userId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetSpace,
           SpaceResultCallback,
           SpaceResultCallbackAdapter,
           ARGLIST(csp.systems.SpaceResult result),
           ARGLIST(csp.systems.SpaceResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           InviteToSpace,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string email, bool? isModeratorRole, string? emailLinkUrl, string? signupUrl),
           ARGLIST(spaceId, email, isModeratorRole, emailLinkUrl, signupUrl)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           BulkInviteToSpace,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.systems.InviteUserRoleInfoCollection inviteUsers),
           ARGLIST(spaceId, inviteUsers)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetPendingUserInvites,
           PendingInvitesResultCallback,
           PendingInvitesResultCallbackAdapter,
           ARGLIST(csp.systems.PendingInvitesResult result),
           ARGLIST(csp.systems.PendingInvitesResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetAcceptedUserInvites,
           AcceptedInvitesResultCallback,
           AcceptedInvitesResultCallbackAdapter,
           ARGLIST(csp.systems.AcceptedInvitesResult result),
           ARGLIST(csp.systems.AcceptedInvitesResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           RemoveUserFromSpace,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string userId),
           ARGLIST(spaceId, userId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           AddUserToSpace,
           SpaceResultCallback,
           SpaceResultCallbackAdapter,
           ARGLIST(csp.systems.SpaceResult result),
           ARGLIST(csp.systems.SpaceResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string userId),
           ARGLIST(spaceId, userId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           AddSiteInfo,
           SiteResultCallback,
           SiteResultCallbackAdapter,
           ARGLIST(csp.systems.SiteResult result),
           ARGLIST(csp.systems.SiteResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.systems.Site siteInfo),
           ARGLIST(spaceId, siteInfo)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           RemoveSiteInfo,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.systems.Site siteInfo),
           ARGLIST(spaceId, siteInfo)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetSitesInfo,
           SitesCollectionResultCallback,
           SitesCollectionResultCallbackAdapter,
           ARGLIST(csp.systems.SitesCollectionResult result),
           ARGLIST(csp.systems.SitesCollectionResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           UpdateUserRole,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.systems.UserRoleInfo newUserRoleInfo),
           ARGLIST(spaceId, newUserRoleInfo)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetUsersRoles,
           UserRoleCollectionCallback,
           UserRoleCollectionCallbackAdapter,
           ARGLIST(csp.systems.UserRoleCollectionResult result),
           ARGLIST(csp.systems.UserRoleCollectionResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.common.StringArray requestedUserIds),
           ARGLIST(spaceId, requestedUserIds)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           UpdateSpaceMetadata,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.common.StringDict newMetadata),
           ARGLIST(spaceId, newMetadata)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetSpacesMetadata,
           SpacesMetadataResultCallback,
           SpacesMetadataResultCallbackAdapter,
           ARGLIST(csp.systems.SpacesMetadataResult result),
           ARGLIST(csp.systems.SpacesMetadataResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray spaces),
           ARGLIST(spaces)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetSpaceMetadata,
           SpaceMetadataResultCallback,
           SpaceMetadataResultCallbackAdapter,
           ARGLIST(csp.systems.SpaceMetadataResult result),
           ARGLIST(csp.systems.SpaceMetadataResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           UpdateSpaceThumbnail,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.systems.FileAssetDataSource newThumbnail),
           ARGLIST(spaceId, newThumbnail)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           UpdateSpaceThumbnailWithBuffer,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.systems.BufferAssetDataSource newThumbnail),
           ARGLIST(spaceId, newThumbnail)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetSpaceThumbnail,
           UriResultCallback,
           UriResultCallbackAdapter,
           ARGLIST(csp.systems.UriResult result),
           ARGLIST(csp.systems.UriResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           AddUserToSpaceBanList,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string requestedUserId),
           ARGLIST(spaceId, requestedUserId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           DeleteUserFromSpaceBanList,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string requestedUserId),
           ARGLIST(spaceId, requestedUserId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           UpdateSpaceGeoLocation,
           SpaceGeoLocationResultCallback,
           SpaceGeoLocationResultCallbackAdapter,
           ARGLIST(csp.systems.SpaceGeoLocationResult result),
           ARGLIST(csp.systems.SpaceGeoLocationResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.systems.GeoLocation? location, float? orientation, csp.common.GeoLocationArray? geoFence),
           ARGLIST(spaceId, location, orientation, geoFence)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           GetSpaceGeoLocation,
           SpaceGeoLocationResultCallback,
           SpaceGeoLocationResultCallbackAdapter,
           ARGLIST(csp.systems.SpaceGeoLocationResult result),
           ARGLIST(csp.systems.SpaceGeoLocationResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           DeleteSpaceGeoLocation,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           DuplicateSpace,
           SpaceResultCallback,
           SpaceResultCallbackAdapter,
           ARGLIST(csp.systems.SpaceResult result),
           ARGLIST(csp.systems.SpaceResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string newName, csp.systems.SpaceAttributes newAttributes, csp.common.StringArray? memberGroupIds, bool shallowCopy),
           ARGLIST(spaceId, newName, newAttributes, memberGroupIds, shallowCopy)
)

MAKE_ASYNC(csp::systems::SpaceSystem,
           DuplicateSpaceAsync,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string newName, csp.systems.SpaceAttributes newAttributes, csp.common.StringArray? memberGroupIds, bool shallowCopy),
           ARGLIST(spaceId, newName, newAttributes, memberGroupIds, shallowCopy)
)

/* UserSystem Async Functions */

MAKE_ASYNC(csp::systems::UserSystem,
           Login,
           LoginStateResultCallback,
           LoginStateResultCallbackAdapter,
           ARGLIST(csp.systems.LoginStateResult result),
           ARGLIST(csp.systems.LoginStateResult),
           ARGLIST(result),
           ARGLIST(string userName, string email, string password, bool createMultiplayerConnection, bool? userHasVerifiedAge, csp.systems.TokenOptions? tokenOptions),
           ARGLIST(userName, email, password, createMultiplayerConnection, userHasVerifiedAge, tokenOptions)
)

MAKE_ASYNC(csp::systems::UserSystem,
           LoginWithRefreshToken,
           LoginStateResultCallback,
           LoginStateResultCallbackAdapter,
           ARGLIST(csp.systems.LoginStateResult result),
           ARGLIST(csp.systems.LoginStateResult),
           ARGLIST(result),
           ARGLIST(string userId, string refreshToken, bool createMultiplayerConnection, csp.systems.TokenOptions? tokenOptions),
           ARGLIST(userId, refreshToken, createMultiplayerConnection, tokenOptions)
)

MAKE_ASYNC(csp::systems::UserSystem,
           LoginAsGuest,
           LoginStateResultCallback,
           LoginStateResultCallbackAdapter,
           ARGLIST(csp.systems.LoginStateResult result),
           ARGLIST(csp.systems.LoginStateResult),
           ARGLIST(result),
           ARGLIST(bool createMultiplayerConnection, bool? userHasVerifiedAge, csp.systems.TokenOptions? tokenOptions),
           ARGLIST(createMultiplayerConnection, userHasVerifiedAge, tokenOptions)
)

MAKE_ASYNC(csp::systems::UserSystem,
           LoginAsGuestWithDeferredProfileCreation,
           LoginStateResultCallback,
           LoginStateResultCallbackAdapter,
           ARGLIST(csp.systems.LoginStateResult result),
           ARGLIST(csp.systems.LoginStateResult),
           ARGLIST(result),
           ARGLIST(bool? userHasVerifiedAge),
           ARGLIST(userHasVerifiedAge)
)

MAKE_ASYNC(csp::systems::UserSystem,
           GetThirdPartyProviderAuthoriseURL,
           StringResultCallback,
           StringResultCallbackAdapter,
           ARGLIST(csp.systems.StringResult result),
           ARGLIST(csp.systems.StringResult),
           ARGLIST(result),
           ARGLIST(csp.systems.EThirdPartyAuthenticationProviders authProvider, string redirectURL),
           ARGLIST(authProvider, redirectURL)
)

MAKE_ASYNC(csp::systems::UserSystem,
           LoginToThirdPartyAuthenticationProvider,
           LoginStateResultCallback,
           LoginStateResultCallbackAdapter,
           ARGLIST(csp.systems.LoginStateResult result),
           ARGLIST(csp.systems.LoginStateResult),
           ARGLIST(result),
           ARGLIST(string thirdPartyToken, string thirdPartyStateId, bool createMultiplayerConnection, bool? userHasVerifiedAge, csp.systems.TokenOptions? tokenOptions),
           ARGLIST(thirdPartyToken, thirdPartyStateId, createMultiplayerConnection, userHasVerifiedAge, tokenOptions)
)

MAKE_ASYNC_ZERO(csp::systems::UserSystem,
                Logout,
                NullResultCallback,
                NullResultCallbackAdapter,
                ARGLIST(csp.systems.NullResult result),
                ARGLIST(csp.systems.NullResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::UserSystem,
           CreateUser,
           ProfileResultCallback,
           ProfileResultCallbackAdapter,
           ARGLIST(csp.systems.ProfileResult result),
           ARGLIST(csp.systems.ProfileResult),
           ARGLIST(result),
           ARGLIST(string? userName, string? displayName, string email, string password, bool receiveNewsletter, bool userHasVerifiedAge, string? redirectUrl, string? inviteToken),
           ARGLIST(userName, displayName, email, password, receiveNewsletter, userHasVerifiedAge, redirectUrl, inviteToken)
)

MAKE_ASYNC(csp::systems::UserSystem,
           UpgradeGuestAccount,
           ProfileResultCallback,
           ProfileResultCallbackAdapter,
           ARGLIST(csp.systems.ProfileResult result),
           ARGLIST(csp.systems.ProfileResult),
           ARGLIST(result),
           ARGLIST(string userName, string displayName, string email, string password),
           ARGLIST(userName, displayName, email, password)
)

MAKE_ASYNC_ZERO(csp::systems::UserSystem,
                ConfirmUserEmail,
                NullResultCallback,
                NullResultCallbackAdapter,
                ARGLIST(csp.systems.NullResult result),
                ARGLIST(csp.systems.NullResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::UserSystem,
           ResetUserPassword,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string token, string userId, string newPassword),
           ARGLIST(token, userId, newPassword)
)

MAKE_ASYNC(csp::systems::UserSystem,
           UpdateUserDisplayName,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string userId, string newUserDisplayName),
           ARGLIST(userId, newUserDisplayName)
)

MAKE_ASYNC(csp::systems::UserSystem,
           DeleteUser,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string userId),
           ARGLIST(userId)
)

MAKE_ASYNC(csp::systems::UserSystem,
           ForgotPassword,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string email, string? redirectUrl, string? emailLinkUrl, bool useTokenChangePasswordUrl),
           ARGLIST(email, redirectUrl, emailLinkUrl, useTokenChangePasswordUrl)
)

MAKE_ASYNC(csp::systems::UserSystem,
           GetProfileByUserId,
           ProfileResultCallback,
           ProfileResultCallbackAdapter,
           ARGLIST(csp.systems.ProfileResult result),
           ARGLIST(csp.systems.ProfileResult),
           ARGLIST(result),
           ARGLIST(string inUserId),
           ARGLIST(inUserId)
)

MAKE_ASYNC(csp::systems::UserSystem,
           GetProfilesByUserId,
           BasicProfilesResultCallback,
           BasicProfilesResultCallbackAdapter,
           ARGLIST(csp.systems.BasicProfilesResult result),
           ARGLIST(csp.systems.BasicProfilesResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray inUserIds),
           ARGLIST(inUserIds)
)

MAKE_ASYNC(csp::systems::UserSystem,
           GetBasicProfilesByUserId,
           BasicProfilesResultCallback,
           BasicProfilesResultCallbackAdapter,
           ARGLIST(csp.systems.BasicProfilesResult result),
           ARGLIST(csp.systems.BasicProfilesResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray inUserIds),
           ARGLIST(inUserIds)
)

MAKE_ASYNC_ZERO(csp::systems::UserSystem,
                Ping,
                NullResultCallback,
                NullResultCallbackAdapter,
                ARGLIST(csp.systems.NullResult result),
                ARGLIST(csp.systems.NullResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::UserSystem,
           ResendVerificationEmail,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string inEmail, string? inRedirectUrl),
           ARGLIST(inEmail, inRedirectUrl)
)

MAKE_ASYNC(csp::systems::UserSystem,
           GetCustomerPortalUrl,
           StringResultCallback,
           StringResultCallbackAdapter,
           ARGLIST(csp.systems.StringResult result),
           ARGLIST(csp.systems.StringResult),
           ARGLIST(result),
           ARGLIST(string userId),
           ARGLIST(userId)
)

MAKE_ASYNC(csp::systems::UserSystem,
           GetCheckoutSessionUrl,
           StringResultCallback,
           StringResultCallbackAdapter,
           ARGLIST(csp.systems.StringResult result),
           ARGLIST(csp.systems.StringResult),
           ARGLIST(result),
           ARGLIST(csp.systems.TierNames tier),
           ARGLIST(tier)
)

/* SettingsSystem Async Functions */

MAKE_ASYNC(csp::systems::SettingsSystem,
           SetNDAStatus,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(bool inValue),
           ARGLIST(inValue)
)

MAKE_ASYNC_ZERO(csp::systems::SettingsSystem,
                GetNDAStatus,
                BooleanResultCallback,
                BooleanResultCallbackAdapter,
                ARGLIST(csp.systems.BooleanResult result),
                ARGLIST(csp.systems.BooleanResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::SettingsSystem,
           SetNewsletterStatus,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(bool inValue),
           ARGLIST(inValue)
)

MAKE_ASYNC_ZERO(csp::systems::SettingsSystem,
                GetNewsletterStatus,
                BooleanResultCallback,
                BooleanResultCallbackAdapter,
                ARGLIST(csp.systems.BooleanResult result),
                ARGLIST(csp.systems.BooleanResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::SettingsSystem,
           AddRecentlyVisitedSpace,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string inSpaceID),
           ARGLIST(inSpaceID)
)

MAKE_ASYNC_ZERO(csp::systems::SettingsSystem,
                GetRecentlyVisitedSpaces,
                StringArrayResultCallback,
                StringArrayResultCallbackAdapter,
                ARGLIST(csp.systems.StringArrayResult result),
                ARGLIST(csp.systems.StringArrayResult),
                ARGLIST(result)
)

MAKE_ASYNC_ZERO(csp::systems::SettingsSystem,
                ClearRecentlyVisitedSpaces,
                NullResultCallback,
                NullResultCallbackAdapter,
                ARGLIST(csp.systems.NullResult result),
                ARGLIST(csp.systems.NullResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::SettingsSystem,
           AddBlockedSpace,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string inSpaceID),
           ARGLIST(inSpaceID)
)

MAKE_ASYNC(csp::systems::SettingsSystem,
           RemoveBlockedSpace,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string inSpaceID),
           ARGLIST(inSpaceID)
)

MAKE_ASYNC_ZERO(csp::systems::SettingsSystem,
                GetBlockedSpaces,
                StringArrayResultCallback,
                StringArrayResultCallbackAdapter,
                ARGLIST(csp.systems.StringArrayResult result),
                ARGLIST(csp.systems.StringArrayResult),
                ARGLIST(result)
)

MAKE_ASYNC_ZERO(csp::systems::SettingsSystem,
                ClearBlockedSpaces,
                NullResultCallback,
                NullResultCallbackAdapter,
                ARGLIST(csp.systems.NullResult result),
                ARGLIST(csp.systems.NullResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::SettingsSystem,
           UpdateAvatarPortrait,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.systems.FileAssetDataSource newAvatarPortrait),
           ARGLIST(newAvatarPortrait)
)

MAKE_ASYNC(csp::systems::SettingsSystem,
           GetAvatarPortrait,
           UriResultCallback,
           UriResultCallbackAdapter,
           ARGLIST(csp.systems.UriResult result),
           ARGLIST(csp.systems.UriResult),
           ARGLIST(result),
           ARGLIST(string inUserID),
           ARGLIST(inUserID)
)

MAKE_ASYNC(csp::systems::SettingsSystem,
           UpdateAvatarPortraitWithBuffer,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.systems.BufferAssetDataSource newAvatarPortrait),
           ARGLIST(newAvatarPortrait)
)

MAKE_ASYNC(csp::systems::SettingsSystem,
           SetAvatarInfo,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AvatarType inType, string inIdentifier, bool inAvatarVisible),
           ARGLIST(inType, inIdentifier, inAvatarVisible)
)

MAKE_ASYNC_ZERO(csp::systems::SettingsSystem,
                GetAvatarInfo,
                AvatarInfoResultCallback,
                AvatarInfoResultCallbackAdapter,
                ARGLIST(csp.systems.AvatarInfoResult result),
                ARGLIST(csp.systems.AvatarInfoResult),
                ARGLIST(result)
)

/* ApplicationSettingsSystem Async Functions */

MAKE_ASYNC(csp::systems::ApplicationSettingsSystem,
           GetSettingsByContext,
           ApplicationSettingsResultCallback,
           ApplicationSettingsResultCallbackAdapter,
           ARGLIST(csp.systems.ApplicationSettingsResult result),
           ARGLIST(csp.systems.ApplicationSettingsResult),
           ARGLIST(result),
           ARGLIST(string applicationName, string context, csp.common.StringArray? keys),
           ARGLIST(applicationName, context, keys)
)

MAKE_ASYNC(csp::systems::ApplicationSettingsSystem,
           GetSettingsByContextAnonymous,
           ApplicationSettingsResultCallback,
           ApplicationSettingsResultCallbackAdapter,
           ARGLIST(csp.systems.ApplicationSettingsResult result),
           ARGLIST(csp.systems.ApplicationSettingsResult),
           ARGLIST(result),
           ARGLIST(string tenant, string applicationName, string context, csp.common.StringArray? keys),
           ARGLIST(tenant, applicationName, context, keys)
)

/* QuotaSystem Async Functions  */

MAKE_ASYNC(csp::systems::QuotaSystem,
           GetTotalSpaceSizeInKilobytes,
           FeatureLimitCallback,
           FeatureLimitCallbackAdapter,
           ARGLIST(csp.systems.FeatureLimitResult featureLimitResult),
           ARGLIST(csp.systems.FeatureLimitResult),
           ARGLIST(featureLimitResult),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::QuotaSystem,
           GetTierFeatureProgressForUser,
           FeaturesLimitCallback,
           FeaturesLimitCallbackAdapter,
           ARGLIST(csp.systems.FeaturesLimitResult result),
           ARGLIST(csp.systems.FeaturesLimitResult),
           ARGLIST(result),
           ARGLIST(csp.common.TierFeaturesArray featureNames),
           ARGLIST(featureNames)
)

MAKE_ASYNC(csp::systems::QuotaSystem,
           GetTierFeatureProgressForSpace,
           FeaturesLimitCallback,
           FeaturesLimitCallbackAdapter,
           ARGLIST(csp.systems.FeaturesLimitResult result),
           ARGLIST(csp.systems.FeaturesLimitResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.common.TierFeaturesArray featureNames),
           ARGLIST(spaceId, featureNames)
)

MAKE_ASYNC(csp::systems::QuotaSystem,
           SetUserTier,
           UserTierCallback,
           UserTierCallbackAdapter,
           ARGLIST(csp.systems.UserTierResult result),
           ARGLIST(csp.systems.UserTierResult),
           ARGLIST(result),
           ARGLIST(csp.systems.TierNames tier, string userId),
           ARGLIST(tier, userId)
)

MAKE_ASYNC_ZERO(csp::systems::QuotaSystem,
                GetCurrentUserTier,
                UserTierCallback,
                UserTierCallbackAdapter,
                ARGLIST(csp.systems.UserTierResult result),
                ARGLIST(csp.systems.UserTierResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::QuotaSystem,
           GetTierFeatureQuota,
           FeatureQuotaCallback,
           FeatureQuotaCallbackAdapter,
           ARGLIST(csp.systems.FeatureQuotaResult result),
           ARGLIST(csp.systems.FeatureQuotaResult),
           ARGLIST(result),
           ARGLIST(csp.systems.TierNames tierName, csp.systems.TierFeatures featureName),
           ARGLIST(tierName, featureName)
)

MAKE_ASYNC(csp::systems::QuotaSystem,
           GetTierFeaturesQuota,
           FeaturesQuotaCallback,
           FeaturesQuotaCallbackAdapter,
           ARGLIST(csp.systems.FeaturesQuotaResult result),
           ARGLIST(csp.systems.FeaturesQuotaResult),
           ARGLIST(result),
           ARGLIST(csp.systems.TierNames tierName),
           ARGLIST(tierName)
)

MAKE_ASYNC_ZERO(csp::systems::QuotaSystem,
                GetTotalSpacesOwnedByUser,
                FeatureLimitCallback,
                FeatureLimitCallbackAdapter,
                ARGLIST(csp.systems.FeatureLimitResult featureLimitResult),
                ARGLIST(csp.systems.FeatureLimitResult),
                ARGLIST(featureLimitResult)
)

MAKE_ASYNC(csp::systems::QuotaSystem,
           GetConcurrentUsersInSpace,
           FeatureLimitCallback,
           FeatureLimitCallbackAdapter,
           ARGLIST(csp.systems.FeatureLimitResult featureLimitResult),
           ARGLIST(csp.systems.FeatureLimitResult),
           ARGLIST(featureLimitResult),
           ARGLIST(string spaceID),
           ARGLIST(spaceID)
)

/* ECommerceSystem Async Functions */

MAKE_ASYNC(csp::systems::ECommerceSystem,
           GetProductInformation,
           ProductInfoResultCallback,
           ProductInfoResultCallbackAdapter,
           ARGLIST(csp.systems.ProductInfoResult result),
           ARGLIST(csp.systems.ProductInfoResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string productId),
           ARGLIST(spaceId, productId)
)

MAKE_ASYNC(csp::systems::ECommerceSystem,
           GetProductInfoCollectionByVariantIds,
           ProductInfoCollectionResultCallback,
           ProductInfoCollectionResultCallbackAdapter,
           ARGLIST(csp.systems.ProductInfoCollectionResult result),
           ARGLIST(csp.systems.ProductInfoCollectionResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.common.StringArray variantIds),
           ARGLIST(spaceId, variantIds)
)

MAKE_ASYNC(csp::systems::ECommerceSystem,
           GetCheckoutInformation,
           CheckoutInfoResultCallback,
           CheckoutInfoResultCallbackAdapter,
           ARGLIST(csp.systems.CheckoutInfoResult result),
           ARGLIST(csp.systems.CheckoutInfoResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string cartId),
           ARGLIST(spaceId, cartId)
)

MAKE_ASYNC(csp::systems::ECommerceSystem,
           CreateCart,
           CartInfoResultCallback,
           CartInfoResultCallbackAdapter,
           ARGLIST(csp.systems.CartInfoResult result),
           ARGLIST(csp.systems.CartInfoResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

MAKE_ASYNC(csp::systems::ECommerceSystem,
           GetCart,
           CartInfoResultCallback,
           CartInfoResultCallbackAdapter,
           ARGLIST(csp.systems.CartInfoResult result),
           ARGLIST(csp.systems.CartInfoResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string cartId),
           ARGLIST(spaceId, cartId)
)

MAKE_ASYNC(csp::systems::ECommerceSystem,
           GetShopifyStores,
           GetShopifyStoresResultCallback,
           GetShopifyStoresResultCallbackAdapter,
           ARGLIST(csp.systems.GetShopifyStoresResult result),
           ARGLIST(csp.systems.GetShopifyStoresResult),
           ARGLIST(result),
           ARGLIST(bool? isActive),
           ARGLIST(isActive)
)

MAKE_ASYNC(csp::systems::ECommerceSystem,
           AddShopifyStore,
           AddShopifyStoreResultCallback,
           AddShopifyStoreResultCallbackAdapter,
           ARGLIST(csp.systems.AddShopifyStoreResult result),
           ARGLIST(csp.systems.AddShopifyStoreResult),
           ARGLIST(result),
           ARGLIST(string storeName, string spaceId, bool isEcommerceActive, string privateAccessToken),
           ARGLIST(storeName, spaceId, isEcommerceActive, privateAccessToken)
)

MAKE_ASYNC(csp::systems::ECommerceSystem,
           SetECommerceActiveInSpace,
           AddShopifyStoreResultCallback,
           AddShopifyStoreResultCallbackAdapter,
           ARGLIST(csp.systems.AddShopifyStoreResult result),
           ARGLIST(csp.systems.AddShopifyStoreResult),
           ARGLIST(result),
           ARGLIST(string storeName, string spaceId, bool isEcommerceActive),
           ARGLIST(storeName, spaceId, isEcommerceActive)
)

MAKE_ASYNC(csp::systems::ECommerceSystem,
           ValidateShopifyStore,
           ValidateShopifyStoreResultCallback,
           ValidateShopifyStoreResultCallbackAdapter,
           ARGLIST(csp.systems.ValidateShopifyStoreResult result),
           ARGLIST(csp.systems.ValidateShopifyStoreResult),
           ARGLIST(result),
           ARGLIST(string storeName, string privateAccessToken),
           ARGLIST(storeName, privateAccessToken)
)

MAKE_ASYNC(csp::systems::ECommerceSystem,
           UpdateCartInformation,
           CartInfoResultCallback,
           CartInfoResultCallbackAdapter,
           ARGLIST(csp.systems.CartInfoResult result),
           ARGLIST(csp.systems.CartInfoResult),
           ARGLIST(result),
           ARGLIST(csp.systems.CartInfo cartInformation),
           ARGLIST(cartInformation)
)

/* EventTicketingSystem Async Functions */

MAKE_ASYNC(csp::systems::EventTicketingSystem,
           CreateTicketedEvent,
           TicketedEventResultCallback,
           TicketedEventResultCallbackAdapter,
           ARGLIST(csp.systems.TicketedEventResult result),
           ARGLIST(csp.systems.TicketedEventResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.systems.EventTicketingVendor vendor, string vendorEventId, string vendorEventUri, bool isTicketingActive),
           ARGLIST(spaceId, vendor, vendorEventId, vendorEventUri, isTicketingActive)
)

MAKE_ASYNC(csp::systems::EventTicketingSystem,
           UpdateTicketedEvent,
           TicketedEventResultCallback,
           TicketedEventResultCallbackAdapter,
           ARGLIST(csp.systems.TicketedEventResult result),
           ARGLIST(csp.systems.TicketedEventResult),
           ARGLIST(result),
           ARGLIST(string spaceId, string eventId, csp.systems.EventTicketingVendor? vendor, string? vendorEventId, string? vendorEventUri, bool? isTicketingActive),
           ARGLIST(spaceId, eventId, vendor, vendorEventId, vendorEventUri, isTicketingActive)
)

MAKE_ASYNC(csp::systems::EventTicketingSystem,
           GetTicketedEvents,
           TicketedEventCollectionResultCallback,
           TicketedEventCollectionResultCallbackAdapter,
           ARGLIST(csp.systems.TicketedEventCollectionResult result),
           ARGLIST(csp.systems.TicketedEventCollectionResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray spaceIds, int? skip, int? limit),
           ARGLIST(spaceIds, skip, limit)
)

MAKE_ASYNC(csp::systems::EventTicketingSystem,
           SubmitEventTicket,
           EventTicketResultCallback,
           EventTicketResultCallbackAdapter,
           ARGLIST(csp.systems.EventTicketResult result),
           ARGLIST(csp.systems.EventTicketResult),
           ARGLIST(result),
           ARGLIST(string spaceId, csp.systems.EventTicketingVendor vendor, string vendorEventId, string vendorTicketId, string? onBehalfOfUserId),
           ARGLIST(spaceId, vendor, vendorEventId, vendorTicketId, onBehalfOfUserId)
)

MAKE_ASYNC(csp::systems::EventTicketingSystem,
           GetVendorAuthorizeInfo,
           TicketedEventVendorAuthorizeInfoCallback,
           TicketedEventVendorAuthInfoResultCallbackAdapter,
           ARGLIST(csp.systems.TicketedEventVendorAuthInfoResult result),
           ARGLIST(csp.systems.TicketedEventVendorAuthInfoResult),
           ARGLIST(result),
           ARGLIST(csp.systems.EventTicketingVendor vendor, string userId),
           ARGLIST(vendor, userId)
)

MAKE_ASYNC(csp::systems::EventTicketingSystem,
           GetIsSpaceTicketed,
           SpaceIsTicketedResultCallback,
           SpaceIsTicketedResultCallbackAdapter,
           ARGLIST(csp.systems.SpaceIsTicketedResult result),
           ARGLIST(csp.systems.SpaceIsTicketedResult),
           ARGLIST(result),
           ARGLIST(string spaceId),
           ARGLIST(spaceId)
)

/* MaintenanceSystem Async Functions */

MAKE_ASYNC(csp::systems::MaintenanceSystem,
           GetMaintenanceInfo,
           MaintenanceInfoCallback,
           MaintenanceInfoCallbackAdapter,
           ARGLIST(csp.systems.MaintenanceInfoResult result),
           ARGLIST(csp.systems.MaintenanceInfoResult),
           ARGLIST(result),
           ARGLIST(string maintenanceURL),
           ARGLIST(maintenanceURL)
)

/* GraphQLSystem Async Functions */

MAKE_ASYNC(csp::systems::GraphQLSystem,
           RunRequest,
           GraphQLReceivedCallback,
           GraphQLReceivedCallbackAdapter,
           ARGLIST(csp.systems.GraphQLResult result),
           ARGLIST(csp.systems.GraphQLResult),
           ARGLIST(result),
           ARGLIST(string requestBody),
           ARGLIST(requestBody)
)

MAKE_ASYNC(csp::systems::GraphQLSystem,
           RunQuery,
           GraphQLReceivedCallback,
           GraphQLReceivedCallbackAdapter,
           ARGLIST(csp.systems.GraphQLResult result),
           ARGLIST(csp.systems.GraphQLResult),
           ARGLIST(result),
           ARGLIST(string queryText),
           ARGLIST(queryText)
)

/* PointOfInterestSystem Async Functions */

MAKE_ASYNC(csp::systems::PointOfInterestSystem,
           CreatePOI,
           POIResultCallback,
           POIResultCallbackAdapter,
           ARGLIST(csp.systems.POIResult result),
           ARGLIST(csp.systems.POIResult),
           ARGLIST(result),
           ARGLIST(string title, string description, string name, csp.common.StringArray? tags, csp.systems.EPointOfInterestType type, string owner, csp.systems.GeoLocation location, csp.systems.AssetCollection assetCollection),
           ARGLIST(title, description, name, tags, type, owner, location, assetCollection)
)

MAKE_ASYNC(csp::systems::PointOfInterestSystem,
           DeletePOI,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.systems.PointOfInterest poi),
           ARGLIST(poi)
)

MAKE_ASYNC(csp::systems::PointOfInterestSystem,
           GetPOIsInArea,
           POICollectionResultCallback,
           POICollectionResultCallbackAdapter,
           ARGLIST(csp.systems.POICollectionResult result),
           ARGLIST(csp.systems.POICollectionResult),
           ARGLIST(result),
           ARGLIST(csp.systems.GeoLocation originLocation, double areaRadius, csp.systems.EPointOfInterestType? type),
           ARGLIST(originLocation, areaRadius, type)
)

/* AnchorSystem Async Functions */

MAKE_ASYNC(csp::systems::AnchorSystem,
           CreateAnchor,
           AnchorResultCallback,
           AnchorResultCallbackAdapter,
           ARGLIST(csp.systems.AnchorResult result),
           ARGLIST(csp.systems.AnchorResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AnchorProvider thirdPartyAnchorProvider, string thirdPartyAnchorId, string assetCollectionId, csp.systems.GeoLocation location, csp.systems.OlyAnchorPosition position, csp.systems.OlyRotation rotation, csp.common.StringDict? spatialKeyValue, csp.common.StringArray? tags),
           ARGLIST(thirdPartyAnchorProvider, thirdPartyAnchorId, assetCollectionId, location, position, rotation, spatialKeyValue, tags)
)

MAKE_ASYNC(csp::systems::AnchorSystem,
           CreateAnchorInSpace,
           AnchorResultCallback,
           AnchorResultCallbackAdapter,
           ARGLIST(csp.systems.AnchorResult result),
           ARGLIST(csp.systems.AnchorResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AnchorProvider thirdPartyAnchorProvider, string thirdPartyAnchorId, string spaceId, ulong spaceEntityId, string assetCollectionId, csp.systems.GeoLocation location, csp.systems.OlyAnchorPosition position, csp.systems.OlyRotation rotation, csp.common.StringDict? spatialKeyValue, csp.common.StringArray? tags),
           ARGLIST(thirdPartyAnchorProvider, thirdPartyAnchorId, spaceId, spaceEntityId, assetCollectionId, location, position, rotation, spatialKeyValue, tags)
)

MAKE_ASYNC(csp::systems::AnchorSystem,
           DeleteAnchors,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray anchorIds),
           ARGLIST(anchorIds)
)

MAKE_ASYNC(csp::systems::AnchorSystem,
           GetAnchorsInArea,
           AnchorCollectionResultCallback,
           AnchorCollectionResultCallbackAdapter,
           ARGLIST(csp.systems.AnchorCollectionResult result),
           ARGLIST(csp.systems.AnchorCollectionResult),
           ARGLIST(result),
           ARGLIST(csp.systems.GeoLocation originLocation, double areaRadius, csp.common.StringArray? spatialKeys, csp.common.StringArray? spatialValues, csp.common.StringArray? tags, bool? allTags, csp.common.StringArray? spaceIds, int? skip, int? limit),
           ARGLIST(originLocation, areaRadius, spatialKeys, spatialValues, tags, allTags, spaceIds, skip, limit)
)

MAKE_ASYNC(csp::systems::AnchorSystem,
           GetAnchorsInSpace,
           AnchorCollectionResultCallback,
           AnchorCollectionResultCallbackAdapter,
           ARGLIST(csp.systems.AnchorCollectionResult result),
           ARGLIST(csp.systems.AnchorCollectionResult),
           ARGLIST(result),
           ARGLIST(string spaceId, int? skip, int? limit),
           ARGLIST(spaceId, skip, limit)
)

MAKE_ASYNC(csp::systems::AnchorSystem,
           GetAnchorsByAssetCollectionId,
           AnchorCollectionResultCallback,
           AnchorCollectionResultCallbackAdapter,
           ARGLIST(csp.systems.AnchorCollectionResult result),
           ARGLIST(csp.systems.AnchorCollectionResult),
           ARGLIST(result),
           ARGLIST(string assetCollectionId, int? skip, int? limit),
           ARGLIST(assetCollectionId, skip, limit)
)

MAKE_ASYNC(csp::systems::AnchorSystem,
           CreateAnchorResolution,
           AnchorResolutionResultCallback,
           AnchorResolutionResultCallbackAdapter,
           ARGLIST(csp.systems.AnchorResolutionResult result),
           ARGLIST(csp.systems.AnchorResolutionResult),
           ARGLIST(result),
           ARGLIST(string anchorId, bool successfullyResolved, int resolveAttempted, double resolveTime, csp.common.StringArray tags),
           ARGLIST(anchorId, successfullyResolved, resolveAttempted, resolveTime, tags)
)

/* SequenceSystem Async Functions */

MAKE_ASYNC(csp::systems::SequenceSystem,
           CreateSequence,
           SequenceResultCallback,
           SequenceResultCallbackAdapter,
           ARGLIST(csp.systems.SequenceResult result),
           ARGLIST(csp.systems.SequenceResult),
           ARGLIST(result),
           ARGLIST(string sequenceKey, string referenceType, string referenceId, csp.common.StringArray items, csp.common.StringDict metaData),
           ARGLIST(sequenceKey, referenceType, referenceId, items, metaData)
)

MAKE_ASYNC(csp::systems::SequenceSystem,
           UpdateSequence,
           SequenceResultCallback,
           SequenceResultCallbackAdapter,
           ARGLIST(csp.systems.SequenceResult result),
           ARGLIST(csp.systems.SequenceResult),
           ARGLIST(result),
           ARGLIST(string sequenceKey, string referenceType, string referenceId, csp.common.StringArray items, csp.common.StringDict metaData),
           ARGLIST(sequenceKey, referenceType, referenceId, items, metaData)
)

MAKE_ASYNC(csp::systems::SequenceSystem,
           RenameSequence,
           SequenceResultCallback,
           SequenceResultCallbackAdapter,
           ARGLIST(csp.systems.SequenceResult result),
           ARGLIST(csp.systems.SequenceResult),
           ARGLIST(result),
           ARGLIST(string oldSequenceKey, string newSequenceKey),
           ARGLIST(oldSequenceKey, newSequenceKey)
)

MAKE_ASYNC(csp::systems::SequenceSystem,
           GetSequencesByCriteria,
           SequencesResultCallback,
           SequencesResultCallbackAdapter,
           ARGLIST(csp.systems.SequencesResult result),
           ARGLIST(csp.systems.SequencesResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray sequenceKeys, string? keyRegex, string? referenceType, csp.common.StringArray referenceIds, csp.common.StringDict metaData),
           ARGLIST(sequenceKeys, keyRegex, referenceType, referenceIds, metaData)
)

MAKE_ASYNC(csp::systems::SequenceSystem,
           GetAllSequencesContainingItems,
           SequencesResultCallback,
           SequencesResultCallbackAdapter,
           ARGLIST(csp.systems.SequencesResult result),
           ARGLIST(csp.systems.SequencesResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray items, string? referenceType, csp.common.StringArray referenceIds),
           ARGLIST(items, referenceType, referenceIds)
)

MAKE_ASYNC(csp::systems::SequenceSystem,
           GetSequence,
           SequenceResultCallback,
           SequenceResultCallbackAdapter,
           ARGLIST(csp.systems.SequenceResult result),
           ARGLIST(csp.systems.SequenceResult),
           ARGLIST(result),
           ARGLIST(string sequenceKey),
           ARGLIST(sequenceKey)
)

MAKE_ASYNC(csp::systems::SequenceSystem,
           DeleteSequences,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(csp.common.StringArray sequenceKeys),
           ARGLIST(sequenceKeys)
)

/* HotspotSequenceSystem Async Functions */

MAKE_ASYNC(csp::systems::HotspotSequenceSystem,
           CreateHotspotGroup,
           HotspotGroupResultCallback,
           HotspotGroupResultCallbackAdapter,
           ARGLIST(csp.systems.HotspotGroupResult result),
           ARGLIST(csp.systems.HotspotGroupResult),
           ARGLIST(result),
           ARGLIST(string groupName, csp.common.StringArray hotspotIds),
           ARGLIST(groupName, hotspotIds)
)

MAKE_ASYNC(csp::systems::HotspotSequenceSystem,
           RenameHotspotGroup,
           HotspotGroupResultCallback,
           HotspotGroupResultCallbackAdapter,
           ARGLIST(csp.systems.HotspotGroupResult result),
           ARGLIST(csp.systems.HotspotGroupResult),
           ARGLIST(result),
           ARGLIST(string groupName, string newGroupName),
           ARGLIST(groupName, newGroupName)
)

MAKE_ASYNC(csp::systems::HotspotSequenceSystem,
           UpdateHotspotGroup,
           HotspotGroupResultCallback,
           HotspotGroupResultCallbackAdapter,
           ARGLIST(csp.systems.HotspotGroupResult result),
           ARGLIST(csp.systems.HotspotGroupResult),
           ARGLIST(result),
           ARGLIST(string groupName, csp.common.StringArray hotspotIds),
           ARGLIST(groupName, hotspotIds)
)

MAKE_ASYNC(csp::systems::HotspotSequenceSystem,
           GetHotspotGroup,
           HotspotGroupResultCallback,
           HotspotGroupResultCallbackAdapter,
           ARGLIST(csp.systems.HotspotGroupResult result),
           ARGLIST(csp.systems.HotspotGroupResult),
           ARGLIST(result),
           ARGLIST(string groupName),
           ARGLIST(groupName)
)

MAKE_ASYNC_ZERO(csp::systems::HotspotSequenceSystem,
                GetHotspotGroups,
                HotspotGroupsResultCallback,
                HotspotGroupsResultCallbackAdapter,
                ARGLIST(csp.systems.HotspotGroupsResult result),
                ARGLIST(csp.systems.HotspotGroupsResult),
                ARGLIST(result)
)

MAKE_ASYNC(csp::systems::HotspotSequenceSystem,
           DeleteHotspotGroup,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string groupName),
           ARGLIST(groupName)
)

MAKE_ASYNC(csp::systems::HotspotSequenceSystem,
           RemoveItemFromGroups,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string itemID),
           ARGLIST(itemID)
)

/* AnalyticsSystem Async Functions */
MAKE_ASYNC(csp::systems::AnalyticsSystem,
           SendAnalyticsEvent,
           NullResultCallback,
           NullResultCallbackAdapter,
           ARGLIST(csp.systems.NullResult result),
           ARGLIST(csp.systems.NullResult),
           ARGLIST(result),
           ARGLIST(string productContextSection, string category, string interactionType, string? subCategory, csp.common.StringDict? metadata),
           ARGLIST(productContextSection, category, interactionType, subCategory, metadata)
)

MAKE_ASYNC_ZERO(csp::systems::AnalyticsSystem,
                FlushAnalyticsEventsQueue,
                NullResultCallback,
                NullResultCallbackAdapter,
                ARGLIST(csp.systems.NullResult result),
                ARGLIST(csp.systems.NullResult),
                ARGLIST(result)
)

/* ExternalServiceProxySystem Async Functions */
MAKE_ASYNC(csp::systems::ExternalServiceProxySystem,
           InvokeOperation,
           StringResultCallback,
           StringResultCallbackAdapter,
           ARGLIST(csp.systems.StringResult result),
           ARGLIST(csp.systems.StringResult),
           ARGLIST(result),
           ARGLIST(csp.systems.ExternalServicesOperationParams operationParams),
           ARGLIST(operationParams)
)

MAKE_ASYNC(csp::systems::ExternalServiceProxySystem,
           GetAgoraUserToken,
           StringResultCallback,
           StringResultCallbackAdapter,
           ARGLIST(csp.systems.StringResult result),
           ARGLIST(csp.systems.StringResult),
           ARGLIST(result),
           ARGLIST(csp.systems.AgoraUserTokenParams agoraParams),
           ARGLIST(agoraParams)
)