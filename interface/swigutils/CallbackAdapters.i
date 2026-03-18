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

/*********** CALLBACK TYPEMAPS **********/

/* With the above adapters, we can typemap all the callbacks in the csp interfaces
 * such that they use the adapters. You'll need to be sure the above declarations
 * are in sync with the below. Although you should get a build error if they're not.
 * You can see in AsyncAdapters.i how the above adapters are extended from by C# action
 * based director objects, creating a natural C# like interface that fits into CSP callbacks. */


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
    // Note: checking for nullptr because we could pass that to unsubscribe.
    if($input == nullptr)
    {
        return;
    }
    return $input->Call(ARG_LIST_WITHOUT_TYPES);
  };
}
%enddef

