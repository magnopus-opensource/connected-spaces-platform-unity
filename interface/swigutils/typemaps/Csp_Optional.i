/* 
 * Based on the optional typemaps by @vadz, which they kindly share here : https://github.com/swig/swig/issues/1307#issuecomment-469258404
 * There is an effort to get this integrated upstream, which you can see here : https://github.com/swig/swig/pull/3078 
 * Imo, this is a fair bit better than the currently in-built SWIG typemaps. Nice one vadz.
 * Produces a T? interface in the C#, using concrete optional types underneath to facilitate interop.
 */

// The macro arguments for all these macros are the name of the exported class
// and the C++ type T of csp::common::Optional<T> to generate the typemaps for.

%{
#include "CSP/Common/Optional.h"
%}

%include "CSP/Common/Optional.h"

// Common part of the macros below, shouldn't be used directly.
%define DEFINE_OPTIONAL_HELPER(OptT, T)

// The csp::common::Optional<> specializations themselves are only going to be used
// inside our own code, the user will deal with either T? or T, depending on
// whether T is a value or a reference type, so make them private to our own
// assembly.
%typemap(csclassmodifiers) csp::common::Optional< T > "internal class"

// Do this to use reference typemaps instead of the pointer ones used by
// default for the member variables of this type.
//
// Notice that this must be done before %template below, SWIG must know about
// all features attached to the type before dealing with it.
%naturalvar csp::common::Optional< T >;

// Even although we're not going to really use them, we must still name the
// exported template instantiation, otherwise SWIG would give it an
// auto-generated name starting with SWIGTYPE which would be even uglier.
%template(OptT) csp::common::Optional< T >;

%enddef

// This macro should be used for simple types that can be represented as
// Nullable<T> in C#.
// Put more directly, this is for value types

%define DEFINE_OPTIONAL_VALUE_TYPE(OptT, T)

DEFINE_OPTIONAL_HELPER(OptT, T)

// Define the type we want to use in C#.
%typemap(cstype) csp::common::Optional< T >, const csp::common::Optional< T > & "$typemap(cstype, T)?"

// This typemap is used to convert C# OptT to the handler passed to the
// intermediate native wrapper function. Notice that it assumes that the OptT
// variable is obtained from the C# variable by prefixing it with "opt", this
// is important for the csvarin typemap below which uses "optvalue" because the
// property value is accessible as "value" in C#.
%typemap(csin,
         pre="    OptT opt$csinput = $csinput.HasValue ? new OptT($csinput.Value) : new OptT();"
         ) const csp::common::Optional< T >& "$csclassname.getCPtr(opt$csinput)"

// This is used for functions returning optional values.
%typemap(csout, excode=SWIGEXCODE) csp::common::Optional< T >, const csp::common::Optional< T >& {
    OptT optvalue = new OptT($imcall, $owner);$excode
    if (optvalue.HasValue())
      return optvalue.__ref__();
    else
      return null;
  }

// This code is used for the optional-valued properties in C#.
%typemap(csvarin, excode=SWIGEXCODE2) const csp::common::Optional< T >& %{
    set {
      OptT optvalue = value.HasValue ? new OptT(value.Value) : new OptT();
      $imcall;$excode
    }%}
%typemap(csvarout, excode=SWIGEXCODE2) const csp::common::Optional< T >& %{
    get {
      OptT optvalue = new OptT($imcall, $owner);$excode
      if (optvalue.HasValue())
          return optvalue.__ref__();
      else
          return null;
    }%}

%enddef


%define DEFINE_OPTIONAL_CLASS_HELPER(OptT, T)

DEFINE_OPTIONAL_HELPER(OptT, T)

%typemap(cstype) const csp::common::Optional< T > & "$typemap(cstype, T)?"

%typemap(csin,
         pre="    OptT opt$csinput = $csinput != null ? new OptT($csinput): new OptT();"
         ) const csp::common::Optional< T >& "$csclassname.getCPtr(opt$csinput)"

// This is used for functions returning optional values.
%typemap(csout, excode=SWIGEXCODE) csp::common::Optional< T >, const csp::common::Optional< T >& {
    OptT optvalue = new OptT($imcall, $owner);$excode
    return optvalue.HasValue() ? optvalue.__ref__() : null;
  }

%typemap(csvarin, excode=SWIGEXCODE2) const csp::common::Optional< T >& %{
    set {
      OptT optvalue = value != null ? new OptT(value) : new OptT();
      $imcall;$excode
    }%}
%typemap(csvarout, excode=SWIGEXCODE2) const csp::common::Optional< T >& %{
    get {
      OptT optvalue = new OptT($imcall, $owner);$excode
      return optvalue.HasValue() ? optvalue.__ref__() : null;
    }%}

%enddef

// This macro should be used for optional classes which are represented by
// either a valid object or null in C#.
//
// Its arguments are the scope in which the class is defined (either a
// namespace or, possibly, a class name if this is a nested class) and the
// unqualified name of the class, the name of the exported optional type is
// constructed by prepending "Optional" to the second argument.
//
// Put more directly, this is for reference types
%define DEFINE_OPTIONAL_REFERENCE_TYPE(optClassName, classnameFullyScoped)

DEFINE_OPTIONAL_CLASS_HELPER(optClassName, classnameFullyScoped)

%enddef
