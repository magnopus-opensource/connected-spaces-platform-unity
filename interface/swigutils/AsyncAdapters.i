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
 */

%define MAKE_ACTION_CALLBACK(ACTION_CALLBACK_TYPENAME, CALLBACKT, ACTION_TYPELIST_WITH_NAMES, ACTION_TYPELIST_WITHOUT_NAMES, ACTION_TYPELIST_ONLY_NAMES)
#ifdef SWIG_ACTION_CALLBACK_##ACTION_CALLBACK_TYPENAME##_DEFINED
  %warn "MAKE_ACTION_CALLBACK: callback '" #ACTION_CALLBACK_TYPENAME "' already defined, skipping"
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
 * Note:
 * FULLY_NAMESPACED_CLASST is the full namespaced C++ class name, e.g. csp::systems::QuotaSystem
 * METHODNAME is the method name, e.g. GetTotalSpacesOwnedByUser
 * CALLBACK_TYPENAME is the type of the callback adapter class, for example FeatureLimitCallback. Note that we should not include
 * any namespace here, as the C# adapter class is always in the ConnectedSpacesPlatformDotNet namespace.
 * CALLBACKT is the C# adapter class that extends the callback type, for example QuotaSystem_FeatureLimitCallbackCSharpAdapter
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
 * "ThrowIfNeeded" mechanism we currently have in place in Unity. 
 */
%extend FULLY_NAMESPACED_CLASST {
%proxycode %{
    
  /*
   * When handling callbacks while the async method is running, we need to be careful to keep a reference to the callback
   * safely in memory until it is called. Otherwise, the garbage collector may collect it before it is invoked, leading to
   * unexpected behavior or SIGSEGV. To do that, we keep a ConditionalWeakTable that prevents leaks and automatically
   * cleans if the Task is collected before the callback is invoked.
   */
  private static readonly HashSet<object> _callbackRoots = new();

  /*
   * We make access to _callbackRoots thread-safe by locking on it whenever we add or remove entries.
   */
  private static readonly object _callbackLock = new();

  public System.Threading.Tasks.Task<CALLBACK_TYPELIST_WITHOUT_NAMES> METHODNAME##Async(FUNCTION_TYPELIST_WITH_NAMES)
  {
    // Create a TaskCompletionSource to represent the async operation.
    System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES> tcs = 
        new System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES>();

    ConnectedSpacesPlatformDotNet.CALLBACK_TYPENAME callback = null;
    
    // Define the callback that will be called by the C++ code
    callback = new ConnectedSpacesPlatformDotNet.CALLBACK_TYPENAME(CALLBACK_TYPELIST_ONLY_NAMES => 
    {
        try
        {
            if(CALLBACK_TYPELIST_ONLY_NAMES is csp.systems.ResultBase)
            {
        	    // Before returning the result, we check if we need to throw an exception
   	    	    CALLBACK_TYPELIST_ONLY_NAMES.ThrowIfNeeded(nameof(METHODNAME##Async));
            }

            // Set the result on the task completion source
            tcs.TrySetResult(CALLBACK_TYPELIST_ONLY_NAMES);
        }
        catch (Exception ex)
        {
            // If any other exception occurs, we set it on the task completion source
            tcs.TrySetException(ex);
        }
        finally 
        { 
            lock (_callbackLock)
            {
                // Now that the callback has been invoked, we can remove the root reference
                _callbackRoots.Remove(callback);
            } 
        }

    });

    lock (_callbackLock)
    {
        // ROOT the callback for the lifetime of the Task
        _callbackRoots.Add(callback);
    }

    // Run the method with the provided arguments and the callback
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
 * CALLBACKT is the C# adapter class that extends the callback type, for example QuotaSystem_FeatureLimitCallbackCSharpAdapter
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
    System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES> tcs = new System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES>();
    METHODNAME(new ConnectedSpacesPlatformDotNet.CALLBACK_TYPENAME(CALLBACK_TYPELIST_ONLY_NAMES => 
    {
		if(CALLBACK_TYPELIST_ONLY_NAMES is ResultBase)
        {
        	// Before returning the result, we check if we need to throw an exception
   	    	CALLBACK_TYPELIST_ONLY_NAMES.ThrowIfNeeded(nameof(METHODNAME##Async));
        }

		// Set the result on the task completion source
        tcs.SetResult(CALLBACK_TYPELIST_ONLY_NAMES);
    }));
   	return tcs.Task;
  }
%}
}

%enddef

/* 
 * Stamp out all the async convertors you need. Remember for inheritance heirarchies, you generally want to put these things on the base class 
 * Annoyingly manual, might be a better way, especially if you're willing to consider a templating step such as a Jinja pass. 
 * Definately think about putting these listings in a different file to keep them seperate from the disgusting generic declarations above,
 * as well as to better isolate errors when they are inevitably made.
 */

/* LogSystem Callbacks */
MAKE_ACTION_CALLBACK(LogCallback,
                     LogSystem_LogCallbackHandlerCSharpAdapter,
                     ARGLIST(csp.common.LogLevel logLevel, string message),
                     ARGLIST(csp.common.LogLevel, string),
                     ARGLIST(logLevel, message));
MAKE_ACTION_CALLBACK(EventCallback,
                     LogSystem_EventCallbackHandlerCSharpAdapter,
                     ARGLIST(string eventMessage),
                     ARGLIST(string),
                     ARGLIST(eventMessage));
MAKE_ACTION_CALLBACK(BeginMarkerCallback,
                     LogSystem_BeginMarkerCallbackHandlerCSharpAdapter,
                     ARGLIST(string beginMarker),
                     ARGLIST(string),
                     ARGLIST(beginMarker));
MAKE_ACTION_CALLBACK(EndMarkerCallback,
                     LogSystem_EndMarkerCallbackHandlerCSharpAdapter,
                     ARGLIST(System.IntPtr irrelevant),
                     ARGLIST(System.IntPtr),
                     ARGLIST(irrelevant));

/* QuotaSystem Async functions */
MAKE_ASYNC_ZERO(csp::systems::QuotaSystem,
           GetTotalSpacesOwnedByUser,
           FeatureLimitCallback,
           QuotaSystem_FeatureLimitCallbackCSharpAdapter,
           ARGLIST(csp.systems.FeatureLimitResult featureLimitResult),
           ARGLIST(csp.systems.FeatureLimitResult),
           ARGLIST(featureLimitResult)
)

MAKE_ASYNC(csp::systems::QuotaSystem,
          GetConcurrentUsersInSpace,
          FeatureLimitCallback,
          QuotaSystem_FeatureLimitCallbackCSharpAdapter,
          ARGLIST(csp.systems.FeatureLimitResult featureLimitResult),
          ARGLIST(csp.systems.FeatureLimitResult),
          ARGLIST(featureLimitResult),
		  ARGLIST(string spaceID),
		  ARGLIST(spaceID)
)