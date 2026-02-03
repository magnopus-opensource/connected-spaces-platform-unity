
/* Make a FromBaseCast() method that takes a base proxy object, and gives you a fully derived one.
 * The most obvious use of this is casting from ComponentBase -> A fully derived component, since
 * CSP tends to give you back ComponentBase pointers. Remember that you can't just cast a proxy object using `as`
 * as they're related in that way. they just manage opaque pointers, they're quite dumb wrappers.
 * Requires std_except.i to be included to do the exception conversion, can be caught as ArgumentException in C#. */
%define MAKE_FROM_BASE_CAST(DERIVED_TYPE, BASE_TYPE)

// Check dynamic_cast result and throw C# exception if it fails
%exception DERIVED_TYPE::FromBaseCast {
    $action
    if (!result) {
        SWIG_CSharpSetPendingExceptionArgument(SWIG_CSharpArgumentException, "Failed to cast " #BASE_TYPE " to " #DERIVED_TYPE, "base");
        return $null;
    }
}

%extend DERIVED_TYPE {
    static DERIVED_TYPE* FromBaseCast(BASE_TYPE* base) {
        return dynamic_cast<DERIVED_TYPE*>(base);
    }
}
%enddef
