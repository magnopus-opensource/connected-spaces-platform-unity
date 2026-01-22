// Purpose: SWIG interface file for csp::common::Optional<> type.
//
// This file defines macros for handling optional types in SWIG.
// The macros provided are %optional, %optional_string, and %optional_arithmetic.
//
// Adapted from a PR almost accepted into Upstream https://github.com/swig/swig/pull/3078 
// Initially based on the optional typemaps by @vadz, which they kindly share here : https://github.com/swig/swig/issues/1307#issuecomment-469258404
// Usage:
//
// 1. %optional_arithmetic(TYPE, INTERNAL_NAME [, CLASSMODIFIER]):
//    This macro is used to bind arithmetic types (int, float, double, etc.) to C# nullable value type (represented as Nullable<T>).
//    Example:
//    %optional_arithmetic(double, OptDouble)
//    This will generate code to handle csp::common::Optional<double>.
//    An internal class name OptDouble will be created to bind the optional type from C++ to C# nullable value type. The internal class will be marked as internal by default.
//    If you want to change the access modifier of the internal class for one specific type, you can pass an optional CLASSMODIFIER parameter to the macro.
//    See the SWIG_STD_OPTIONAL_INTERNAL_CLASS_MODIFIER macro for more information.
// 
// 2. %optional_string():
//    This macro is used specifically for csp::common::Optional<csp::common::String>.
//    Example:
//    %optional_string()
//    This will generate code to handle csp::common::Optional<csp::common::String>.
//
// 3. %optional(TYPE):
//    This macro is used to bind structs and classes to either C# nullable reference type (if SWIG_STD_OPTIONAL_USE_NULLABLE_REFERENCE_TYPES is defined) or C# non-nullable reference type.
//    Example:
//    %optional(MyStruct)
//    This will generate code to handle csp::common::Optional<MyStruct>.
//
// The SWIG_STD_OPTIONAL_USE_NULLABLE_REFERENCE_TYPES macro definition is used to enable the use of nullable reference types in the generated SWIG bindings.
// When this macro is defined, SWIG will generate code that treats csp::common::Optional types as C# nullable reference types, allowing the compiler to run null-state analysis (C# >= 8 required).
// When this macro is defined, any module using this file should be declared with the #nullable enable directive.
// Example:
// %module(csbegin="#nullable enable\n") MyModule
//
// The SWIG_STD_OPTIONAL_INTERNAL_CLASS_MODIFIER macro is used to define the access modifier for the internal class generated for the arithmetic optional types. By default it is set to internal.
// You may want to define it to 'public' so the internal class is accessible from outside the assembly it's defined in. See the documentation of the SWIG_CSBODY_PROXY macro for more information.
// Defining this macro will affect all optional arithmetic types defined in the module.

#if defined(SWIG_STD_OPTIONAL_USE_NULLABLE_REFERENCE_TYPES)
%define SWIG_STD_OPTIONAL_NULLABLE_TYPE "?" %enddef
#else
%define SWIG_STD_OPTIONAL_NULLABLE_TYPE "" %enddef
#endif

#ifndef SWIG_STD_OPTIONAL_STRINGIFY
#define SWIG_STD_OPTIONAL_STRINGIFY_(x) #x
#define SWIG_STD_OPTIONAL_STRINGIFY(x) SWIG_STD_OPTIONAL_STRINGIFY_(x)
#endif


%{
    #include "CSP/Common/Optional.h"
%}

%include <Csp_String.i>

%include "CSP/Common/Optional.h"

%define %optional(TYPE)

%naturalvar csp::common::Optional< TYPE >;

%typemap(cstype) csp::common::Optional< TYPE >, csp::common::Optional< TYPE > const & "$typemap(cstype, TYPE)"SWIG_STD_OPTIONAL_NULLABLE_TYPE


// This typemap is used to convert C# nullable type to the handler passed to the
// intermediate native wrapper function.
%typemap(csin) csp::common::Optional< TYPE >, csp::common::Optional< TYPE > const & "$typemap(cstype, TYPE).getCPtr($csinput)"

// This is used for functions returning optional values.
%typemap(csout, excode=SWIGEXCODE) csp::common::Optional< TYPE > {
    var instance = $imcall;
    var ret = (instance != global::System.IntPtr.Zero) ? new $typemap(cstype, TYPE)(instance, true) : null;$excode
    return ret;
  }
%typemap(csout, excode=SWIGEXCODE) csp::common::Optional< TYPE > const &, csp::common::Optional< TYPE > *, csp::common::Optional< TYPE > const * {
    var instance = $imcall;
    var ret = (instance != global::System.IntPtr.Zero) ? new $typemap(cstype, TYPE)(instance, $owner) : null;$excode
    return ret;
  }

%typemap(in) csp::common::Optional< TYPE > const & (csp::common::Optional< TYPE > var) %{
    $1 = &var;
    var = ($input == nullptr) ? csp::common::Optional< TYPE >() : csp::common::Optional< TYPE > { *(TYPE*) $input };
%}

%typemap(in) csp::common::Optional< TYPE > %{
    if ($input != nullptr) {
      $1 = *static_cast<TYPE*>($input);
    }
%}

%typemap(out) csp::common::Optional< TYPE > const & %{ 
    $result = $1->HasValue() ? &$1->operator*() : nullptr;
%}

%typemap(out) csp::common::Optional< TYPE > %{ 
    $result = $1.HasValue() ? new TYPE { $1.__ref__() } : nullptr;
%}


// This code is used for the optional-valued properties in C#.
%typemap(cstype) csp::common::Optional< TYPE > *, csp::common::Optional< TYPE > const * "$typemap(cstype, TYPE)"SWIG_STD_OPTIONAL_NULLABLE_TYPE
%typemap(csin) csp::common::Optional< TYPE > *, csp::common::Optional< TYPE > const * "$typemap(cstype, TYPE).getCPtr($csinput)"

%typemap(csvarin, excode=SWIGEXCODE) csp::common::Optional< TYPE > *, csp::common::Optional< TYPE > const * %{
    set {
      $imcall;$excode
    }%}
%typemap(csvarout, excode=SWIGEXCODE2) csp::common::Optional< TYPE > *, csp::common::Optional< TYPE > const * %{
    get {
        var instance = $imcall;
        var ret = (instance != global::System.IntPtr.Zero) ? new $typemap(cstype, TYPE)(instance, $owner) : null;$excode
        return ret;
    }%}

%typemap(in) csp::common::Optional< TYPE > * (csp::common::Optional< TYPE > var) %{
    $1 = &var;
    var = ($input == nullptr) ? csp::common::Optional< TYPE >() : csp::common::Optional< TYPE > { *(TYPE*) $input };
%}
%typemap(out) csp::common::Optional< TYPE > * %{ 
    $result = $1->HasValue() ? &$1->operator*() : nullptr;
%}

%typemap(csdirectorin) csp::common::Optional< TYPE >, csp::common::Optional< TYPE > const & "($iminput != global::System.IntPtr.Zero) ? new $typemap(cstype, TYPE)($iminput, true) : null"


%enddef

// ----------------------------------------------------------------------------
// optional arithmetic specialisation
// ----------------------------------------------------------------------------
// Macro to set the class modifier for the internal class generated for the
// optional type.
#ifndef SWIG_STD_OPTIONAL_INTERNAL_CLASS_MODIFIER
#define SWIG_STD_OPTIONAL_INTERNAL_CLASS_MODIFIER internal
#endif

// Define the optional arithmetic types.
%define %optional_arithmetic(TYPE, NAME, CLASSMODIFIER...)
 
// The csp::common::Optional<> specializations themselves are only going to be used
// inside our own code, the user will deal with either T? or T, depending on
// whether T is a value or a reference type, so make them private to our own
// assembly.
#if #CLASSMODIFIER == ""
%typemap(csclassmodifiers) csp::common::Optional< TYPE > SWIG_STD_OPTIONAL_STRINGIFY(SWIG_STD_OPTIONAL_INTERNAL_CLASS_MODIFIER) " class"
#else
%typemap(csclassmodifiers) csp::common::Optional< TYPE > SWIG_STD_OPTIONAL_STRINGIFY(CLASSMODIFIER) " class"
#endif

// Do this to use reference typemaps instead of the pointer ones used by
// default for the member variables of this type.
//
// Notice that this must be done before %template below, SWIG must know about
// all features attached to the type before dealing with it.
%naturalvar csp::common::Optional< TYPE >;

// Ignore constructors and operators that expose raw TYPE* pointers
// SWIG converts a lot of C++ specific constructs to T*.
// None of these are useful from C#, and cause noisy (albeit harmless)
// SWIGTYPE_p_* wrapper files to be generated.
// This is only a thing for arithmetic types because other types will
// have typemaps that handle this properly ... I think.
%ignore csp::common::Optional< TYPE >::Optional(TYPE *);
%ignore csp::common::Optional< TYPE >::Optional(TYPE *, std::function<void(TYPE *)>);
%ignore csp::common::Optional< TYPE >::Optional(TYPE &&);
%ignore csp::common::Optional< TYPE >::Optional(std::nullptr_t);
%ignore csp::common::Optional< TYPE >::operator->;
%ignore csp::common::Optional< TYPE >::operator*;

// Even although we're not going to really use them, we must still name the
// exported template instantiation, otherwise SWIG would give it an
// auto-generated name starting with SWIGTYPE which would be even uglier.
%template("NAME") csp::common::Optional< TYPE >;


// Define the type we want to use in C#.
%typemap(cstype) csp::common::Optional< TYPE >, csp::common::Optional< TYPE > const & "$typemap(cstype, TYPE)?"

// This typemap is used to convert C# nullable type to the handler passed to the
// intermediate native wrapper function.
%typemap(csin,
         pre="    NAME opt_$csinput = $csinput.HasValue ? new NAME($csinput.Value) : new NAME();"
         ) csp::common::Optional< TYPE >, csp::common::Optional< TYPE > const& "$csclassname.getCPtr(opt_$csinput)"

// This is used for functions returning optional values.
%typemap(csout, excode=SWIGEXCODE) csp::common::Optional< TYPE >, csp::common::Optional< TYPE > const & {
    NAME ret = new NAME($imcall, $owner);$excode
    return ret.HasValue() ? ret.__ref__() : ($typemap(cstype, TYPE)?)null;
  }

// This code is used for the optional-valued properties in C#.
%typemap(csvarin, excode=SWIGEXCODE2) csp::common::Optional< TYPE >, csp::common::Optional< TYPE > const & %{
    set {
      NAME opt_value = value.HasValue ? new NAME(value.Value) : new NAME();
      $imcall;$excode
    }%}
%typemap(csvarout, excode=SWIGEXCODE2) csp::common::Optional< TYPE >, csp::common::Optional< TYPE > const & %{
    get {
      NAME ret = new NAME($imcall, $owner);$excode
      return ret.HasValue() ? ret.__ref__() : ($typemap(cstype, TYPE)?)null;
    }%}

%typemap(csdirectorin,
         pre="    NAME opt_$iminput = ($iminput != global::System.IntPtr.Zero) ? new NAME($iminput, true) : new NAME();"
         ) csp::common::Optional< TYPE >, csp::common::Optional< TYPE > const & "opt_$iminput.HasValue() ? opt_$iminput.__ref__() : ($typemap(cstype, TYPE)?)null"

%enddef


// ----------------------------------------------------------------------------
// optional string specialisation
// ----------------------------------------------------------------------------
%define %optional_string()

%naturalvar csp::common::Optional<csp::common::String>;

// csp::common::Optional<csp::common::String>
%typemap(ctype) csp::common::Optional<csp::common::String> "const char *"
%typemap(imtype) csp::common::Optional<csp::common::String> "string"
%typemap(cstype) csp::common::Optional<csp::common::String> "string"SWIG_STD_OPTIONAL_NULLABLE_TYPE

%typemap(csdirectorin) csp::common::Optional<csp::common::String> "$iminput"
%typemap(csdirectorout) csp::common::Optional<csp::common::String> "$cscall"

%typemap(in) csp::common::Optional<csp::common::String> (csp::common::Optional<csp::common::String> var) %{
    $1 = &var;
    var = ($input == nullptr) ? csp::common::Optional<csp::common::String>() : csp::common::Optional<csp::common::String> { (char const*) $input };
%}
%typemap(out) csp::common::Optional<csp::common::String> %{ 
    $result = SWIG_csharp_string_callback($1.HasValue() ? $1.__ref__().c_str() : nullptr );
%}

%typemap(csin) csp::common::Optional<csp::common::String> "$csinput"
%typemap(csout, excode=SWIGEXCODE) csp::common::Optional<csp::common::String> {
    string ret = $imcall;$excode
    return ret;
  }

%typemap(typecheck) csp::common::Optional<csp::common::String> = char *;


// csp::common::Optional<csp::common::String> const &
%typemap(ctype) csp::common::Optional<csp::common::String> const & "const char *"
%typemap(imtype) csp::common::Optional<csp::common::String> const & "string"
%typemap(cstype) csp::common::Optional<csp::common::String> const & "string"SWIG_STD_OPTIONAL_NULLABLE_TYPE

%typemap(csdirectorin) csp::common::Optional<csp::common::String> const & "$iminput"
%typemap(csdirectorout) csp::common::Optional<csp::common::String> const & "$cscall"

%typemap(in) csp::common::Optional<csp::common::String> const & (csp::common::Optional<csp::common::String> var) %{
    $1 = &var;
    var = ($input == nullptr) ? csp::common::Optional<csp::common::String>() : csp::common::Optional<csp::common::String> { (char const*) $input };
%}
%typemap(out) csp::common::Optional<csp::common::String> const & %{ 
    $result = SWIG_csharp_string_callback($1->HasValue() ? $1->operator*().c_str() : nullptr); 
%}

%typemap(directorin) csp::common::Optional<csp::common::String> const & %{ 
    $input = $1.HasValue() ? $1.__ref__().c_str() : nullptr;
%}
%typemap(directorout) csp::common::Optional<csp::common::String> const & %{
    #error not implemented
%}

%typemap(csin) csp::common::Optional<csp::common::String> const & "$csinput"
%typemap(csout, excode=SWIGEXCODE) csp::common::Optional<csp::common::String> const & {
    string ret = $imcall;$excode
    return ret;
  }

%typemap(typecheck) csp::common::Optional<csp::common::String> const & = char *;


// csp::common::Optional<csp::common::String> * (used to map C# properties)
%typemap(ctype) csp::common::Optional<csp::common::String> * "const char *"
%typemap(imtype) csp::common::Optional<csp::common::String> * "string"
%typemap(cstype) csp::common::Optional<csp::common::String> * "string"SWIG_STD_OPTIONAL_NULLABLE_TYPE

%typemap(csdirectorin) csp::common::Optional<csp::common::String> * "$iminput"
%typemap(csdirectorout) csp::common::Optional<csp::common::String> * "$cscall"

%typemap(in) csp::common::Optional<csp::common::String> * (csp::common::Optional<csp::common::String> var) %{
    $1 = &var;
    var = ($input == nullptr) ? csp::common::Optional<csp::common::String>() : csp::common::Optional<csp::common::String> { (char const*) $input };
%}
%typemap(out) csp::common::Optional<csp::common::String> * %{ 
    $result = SWIG_csharp_string_callback($1->HasValue() ? $1->operator*().c_str() : nullptr); 
%}

%typemap(csvarin, excode=SWIGEXCODE2) csp::common::Optional<csp::common::String> * %{
    set {
      $imcall;$excode
    } %}
%typemap(csvarout, excode=SWIGEXCODE2) csp::common::Optional<csp::common::String> * %{
    get {
      string ret = $imcall;$excode
      return ret;
    } %}

%typemap(csin) csp::common::Optional<csp::common::String> * "$csinput"
%typemap(csout, excode=SWIGEXCODE) csp::common::Optional<csp::common::String> * {
    string ret = $imcall;$excode
    return ret;
  }

%enddef