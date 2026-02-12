
/* Make a FromBaseCast() method that takes a base proxy object, and gives you a fully derived one.
 * The most obvious use of this is casting from ComponentBase -> A fully derived component, since
 * CSP tends to give you back ComponentBase pointers. Remember that you can't just cast a proxy object using `as`
 * as they're not related in that way. They just manage opaque pointers, they're quite dumb wrappers.
 * Requires std_except.i to be included to do the exception conversion, can be caught as ArgumentException in C#. */

%define MAKE_FROM_BASE_CAST(DERIVED_TYPE_CPP, BASE_TYPE_CPP, DERIVED_TYPE_CSHARP, BASE_TYPE_CSHARP)

// We use typemap(cscode) here rather than relying on an automatic mapping from a C++
// file just to easily get the optional (?) annotation in. Tbh, it also feels like
// quite a clean and comprehensible pattern, with the hidden native call and the 
// public C#.
%typemap(cscode) DERIVED_TYPE_CPP %{

  // Returns null on failure.
  public static DERIVED_TYPE_CSHARP? TryFromBaseCast(BASE_TYPE_CSHARP baseObj)
  {
    return NativeFromBaseCast(baseObj);
  }

  // Throws ArgumentException on failure.
  public static DERIVED_TYPE_CSHARP FromBaseCast(BASE_TYPE_CSHARP baseObj)
  {
    DERIVED_TYPE_CSHARP? derived = TryFromBaseCast(baseObj);
    if (derived == null){
      throw new System.ArgumentException("Failed to cast " + nameof(BASE_TYPE_CSHARP) + " to " + nameof(DERIVED_TYPE_CSHARP), "baseObj");
    }
    return derived;
  }

%}

%csmethodmodifiers DERIVED_TYPE_CPP::NativeFromBaseCast "internal";

%extend DERIVED_TYPE_CPP {
  static DERIVED_TYPE_CPP* NativeFromBaseCast(BASE_TYPE_CPP* baseObj) {
       return dynamic_cast<DERIVED_TYPE_CPP*>(baseObj);
   }
}
%enddef