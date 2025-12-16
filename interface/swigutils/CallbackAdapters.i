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

%{
#include "CSP/Common/Systems/Log/LogSystem.h"
#include "CSP/Systems/Quota/QuotaSystem.h"
%}

/* LogSystem Callback */
MAKE_CALLBACK_ADAPTER(LogSystem_LogCallbackHandlerCSharpAdapter, ARGLIST(csp::common::LogLevel, const csp::common::String&), void)
MAKE_CALLBACK_ADAPTER(LogSystem_EventCallbackHandlerCSharpAdapter, ARGLIST(const csp::common::String&), void)
MAKE_CALLBACK_ADAPTER(LogSystem_BeginMarkerCallbackHandlerCSharpAdapter, ARGLIST(const csp::common::String&), void)
MAKE_CALLBACK_ADAPTER(LogSystem_EndMarkerCallbackHandlerCSharpAdapter, ARGLIST(void*), void)

/* QuotaSystem Callback */
MAKE_CALLBACK_ADAPTER(QuotaSystem_FeatureLimitCallbackCSharpAdapter, ARGLIST(const csp::systems::FeatureLimitResult&), void)

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
    // This is Alessio's test!
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

/* QuotaSystem Callback Typemaps */
MAKE_CALLBACK_TYPEMAP(csp::systems::QuotaSystem::FeatureLimitCallbackHandler,
                        QuotaSystem_FeatureLimitCallbackCSharpAdapter,
                        ARGLIST(const csp::systems::FeatureLimitResult& result),
                        ARGLIST(result))

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
using csp::systems::FeatureLimitResult;
%}