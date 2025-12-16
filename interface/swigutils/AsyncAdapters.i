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
 */
 

%define MAKE_ACTION_CALLBACK(ACTION_CALLBACK_TYPENAME, CALLBACKT, ACTION_TYPELIST_WITH_NAMES, ACTION_TYPELIST_WITHOUT_NAMES, ACTION_TYPELIST_ONLY_NAMES)
%pragma(csharp) modulecode=%{
    public sealed class ACTION_CALLBACK_TYPENAME: CALLBACKT
    {
      private readonly System.Action<ACTION_TYPELIST_WITHOUT_NAMES> CallbackHandler;
      public ACTION_CALLBACK_TYPENAME(System.Action<ACTION_TYPELIST_WITHOUT_NAMES> handler) => CallbackHandler = handler;
      public override void Call(ACTION_TYPELIST_WITH_NAMES) => CallbackHandler(ACTION_TYPELIST_ONLY_NAMES);
    }
%}
%enddef

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
  public System.Threading.Tasks.Task<CALLBACK_TYPELIST_WITHOUT_NAMES> METHODNAME##Async(FUNCTION_TYPELIST_WITH_NAMES)
  {
    System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES> tcs = new System.Threading.Tasks.TaskCompletionSource<CALLBACK_TYPELIST_WITHOUT_NAMES>();
    METHODNAME(FUNCTION_TYPELIST_ONLY_NAMES, new ConnectedSpacesPlatformDotNet.CALLBACK_TYPENAME(CALLBACK_TYPELIST_ONLY_NAMES => 
    {
        tcs.SetResult(CALLBACK_TYPELIST_ONLY_NAMES);
    }));
    return tcs.Task;
  }
%}
}
%enddef


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


/* QuotaSystem Callback */

MAKE_ASYNC_ZERO(csp::systems::QuotaSystem,
           GetTotalSpacesOwnedByUser,
           FeatureLimitCallback,
           QuotaSystem_FeatureLimitCallbackCSharpAdapter,
           ARGLIST(csp.systems.FeatureLimitResult featureLimitResult),
           ARGLIST(csp.systems.FeatureLimitResult),
           ARGLIST(featureLimitResult)
)