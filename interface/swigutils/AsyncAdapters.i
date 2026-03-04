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
 * If it's a method like `SetXCallback(Callback)`, then you just want to stamp MAKE_ACTION_ADAPTER"
 * If it's a full on Async method you want to await, like `await EnterSpace(spaceID...)`, then 
 * stamp with MAKE_AWAITABLE, which makes an action callback but also wraps in an awaitable. 
 * At the moment (2025), CALLBACKT is generally a csharp adapter defined in CallbackAdapters.i
 *
 * Note: MAKE_ACTION_ADAPTER is used by both MAKE_AWAITABLE_ZERO and MAKE_AWAITABLE macros, in order to define the related
 * callback type that is used by the async function. 
 *
 * Whilst action adapters such as these are used in both Async (awaitable) formulations (see MAKE_AWAITABLE, it calls this),
 * and registerable callbacks, using this to expose a registerable "SetXCallback" style callback DOES NOT perform
 * the automatic rooting that the async style does. You can think of this as, because the async/await style creates the
 * callback we pass to CSP automatically, it also takes on responsibility for rooting it. Here, that callback is created
 * directly by the C# user, so they have a handle to it, and are expected to keep it alive. 
 *
 * Important note: some async functions might use the same callback type. This means that we needed a way to ensure
 * the same callback type would not be re-defined causing a compilation error. To do that, whenever a new callback
 * type is defined, a SWIG #define declaration is generated and used as reference to check for re-definitions.
 * Uniqueness is ensured based on name. It's possible to register identical types but with different
 * names. This is fine, but redundant, sort of up to you if you want your exposed action interfaces
 * to all be unique, or the same for action adapters that have the same types. I'd favour the latter.
 */

%define MAKE_ACTION_ADAPTER(ACTION_CALLBACK_TYPENAME, CALLBACKT, ACTION_TYPELIST_WITH_NAMES, ACTION_TYPELIST_WITHOUT_NAMES, ACTION_TYPELIST_ONLY_NAMES)
#ifdef SWIG_ACTION_CALLBACK_##ACTION_CALLBACK_TYPENAME##_DEFINED
  %echo "MAKE_ACTION_ADAPTER: action wrapper '" #ACTION_CALLBACK_TYPENAME "' already defined, skipping"
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
 * Below you'll note we have MAKE_AWAITABLE and MAKE_AWAITABLE_ZERO, an unfortunate compromise for working in macrotown.
 * The bulk of these macros are the same, we only need to change whether or not we're providing an argument list.
 * This is the callback body that is shared between both async macros, such that we can avoid duplicating it.
 *
 * Performs automatic rooting of the callback into a global rooting container, to protect it from GC. 
 * It unroots itself when the callback is completed. Users should not have to concern themselves with this
 * and should be able to call var x = await MyXAsync(); without fear.
 */
%define MAKE_ROOTED_ASYNC_CALLBACK_BODY(METHODNAME, CALLBACK_TYPENAME, CALLBACK_TYPELIST_ONLY_NAMES)
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
                ConnectedSpacesPlatformDotNet.AsyncLifetime.Unroot(callback);
              }
            }
            else {
              // It's something else
              tcs.TrySetResult(CALLBACK_TYPELIST_ONLY_NAMES);
              // Now that the callback has been invoked, we can remove the root reference
              ConnectedSpacesPlatformDotNet.AsyncLifetime.Unroot(callback);
            }
        }
        catch (System.Exception ex)
        {
            // If any other exception occurs, we set it on the task completion source. Failsafe.
            tcs.TrySetException(ex);
        }

    });

    // ROOT the callback for the lifetime of the Task
    ConnectedSpacesPlatformDotNet.AsyncLifetime.Root(callback);
%enddef

/*
 * Note:
 * FULLY_NAMESPACED_CLASST is the full namespaced C++ class name, e.g. csp::systems::QuotaSystem
 * METHODNAME is the method name, e.g. GetTotalSpacesOwnedByUser
 * CALLBACK_TYPENAME is the type of the callback adapter class, for example FeatureLimitCallback. Note that we should not include
 * any namespace here, as the C# adapter class is always in the ConnectedSpacesPlatformDotNet namespace.
 * CALLBACKT is the C# adapter class that extends the callback type, for example FeatureLimitCallbackAdapter
 * CALLBACK_TYPELIST_WITH_NAMES is the full argument list including both types and names, e.g. ARGLIST(const csp::systems::FeatureLimitResult& result)
 * CALLBACK_TYPELIST_WITHOUT_NAMES is the argument list with only types, e.g. ARGLIST(const csp::systems::FeatureLimitResult)
 * CALLBACK_TYPELIST_ONLY_NAMES is just the argument names, e.g. ARGLIST(result)
 * FUNCTION_TYPELIST_WITH_NAMES is the full argument list with types for the function being wrapped, e.g. ARGLIST(const csp::common::String& userId, int someValue)
 * FUNCTION_TYPELIST_ONLY_NAMES is just the argument names for the function being wrapped, e.g. ARGLIST(userId, someValue)
 */
%define MAKE_AWAITABLE(
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
    
MAKE_ACTION_ADAPTER(CALLBACK_TYPENAME, CALLBACKT, CALLBACK_TYPELIST_WITH_NAMES, CALLBACK_TYPELIST_WITHOUT_NAMES, CALLBACK_TYPELIST_ONLY_NAMES)

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
        new System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES>(System.Threading.Tasks.TaskCreationOptions.RunContinuationsAsynchronously);

    MAKE_ROOTED_ASYNC_CALLBACK_BODY(METHODNAME, CALLBACK_TYPENAME, CALLBACK_TYPELIST_ONLY_NAMES);

    // Run the method with the provided arguments and the callback
    // callback is defined in MAKE_AWAITABLE_CALLBACK_BODY
    METHODNAME(FUNCTION_TYPELIST_ONLY_NAMES, callback);

    return tcs.Task;
  }
%}
}
%enddef

/*
 * Variant of MAKE_AWAITABLE for zero-argument functions
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
%define MAKE_AWAITABLE_ZERO(
    FULLY_NAMESPACED_CLASST, 
    METHODNAME, 
    CALLBACK_TYPENAME,
    CALLBACKT,
    CALLBACK_TYPELIST_WITH_NAMES,
    CALLBACK_TYPELIST_WITHOUT_NAMES,
    CALLBACK_TYPELIST_ONLY_NAMES
)
    
MAKE_ACTION_ADAPTER(CALLBACK_TYPENAME, CALLBACKT, CALLBACK_TYPELIST_WITH_NAMES, CALLBACK_TYPELIST_WITHOUT_NAMES, CALLBACK_TYPELIST_ONLY_NAMES)

%extend FULLY_NAMESPACED_CLASST {
%proxycode %{
  public System.Threading.Tasks.Task<CALLBACK_TYPELIST_WITHOUT_NAMES> METHODNAME##Async()
  {  
    // Create a TaskCompletionSource to represent the async operation.
    System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES> tcs = 
        new System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES>(System.Threading.Tasks.TaskCreationOptions.RunContinuationsAsynchronously);

    MAKE_ROOTED_ASYNC_CALLBACK_BODY(METHODNAME, CALLBACK_TYPENAME, CALLBACK_TYPELIST_ONLY_NAMES);

    // Run the method with the provided arguments and the callback
    METHODNAME(callback);

    return tcs.Task;

  }
%}
}

%enddef