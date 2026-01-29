/* Implement the IEquatable interface on compatible types.
 * This interface wants 3 things
 * - Equals(Class)
 * - Equals(Object)
 * - GetHashCode()
 *
 * For the equals operators, declaring something equatable means it is comparable,
 * which we define to mean that the C++ type has operator ==, and has a std::hash implementation.
 * If both of these things are not true, the type cannot be equatable, and is probably
 * not a "value type". CSP does need to do work to make this true, don't just necessarily
 * accept that the underlying objects value category is correct, you may need to cajole people to add
 * some operators into CSP ... or do it yourself.
 *
 * This interface makes value equality work in C#, so Obj1 and Obj2 will be equal
 * if they have the same data. It also allows container types to function more
 * optimally.
 *
 * You may be wondering why we're implementing GetHashCode, since it's not on the
 * IEquatable interface. That is because there is a contract between Equals and
 * GetHashCode, in that if two objects are equal according to Equals, they must
 * also be equal according to GetHashCode. Leaving the System.base reference equality
 * implementation would violate this contract.
 *
 * This also registers the enhanced form of List<T>, as these types are equatable
 * so can support it, although you will still need to declare the template for
 * this list for this to have any effect, otherwise the type isn't generated at all.
 */

 %include "swigutils/typemaps/Csp_List.i"

%define MAKE_VALUE_EQUATABLE(CLASS_FULLY_NAMESPACED)
SWIG_STD_VECTOR_ENHANCED(CLASS_FULLY_NAMESPACED)

%typemap(csinterfaces) CLASS_FULLY_NAMESPACED "System.IEquatable<$csclassname>"

%typemap(cscode) CLASS_FULLY_NAMESPACED %{

  public bool Equals($csclassname? obj)
  {
    if (ReferenceEquals(this, obj)) return true;
    if (obj is null) return false;
    return NativeEquals(obj);
  }

  public override bool Equals(object? obj) {
    return Equals(obj as $csclassname);
  }

  public override int GetHashCode() {
    return (int)GetStdHashCode();
  }

  public static bool operator ==($csclassname left, $csclassname right)
  {
    return left.Equals(right);
  }

  public static bool operator !=($csclassname left, $csclassname right)
  {
    return !(left == right);
  }

%}

/* In the SWIG C++ binary, use the hash implementation and the == implementation.
   This will be a compile error if such things don't exist. */

%csmethodmodifiers CLASS_FULLY_NAMESPACED::GetStdHashCode "internal";
%csmethodmodifiers CLASS_FULLY_NAMESPACED::NativeEquals "internal";

%extend CLASS_FULLY_NAMESPACED {
  bool NativeEquals(const CLASS_FULLY_NAMESPACED& other){
    return *$self == other;
  }

  size_t GetStdHashCode() const {
    return std::hash<CLASS_FULLY_NAMESPACED>()(*$self);
  }
}
%enddef

MAKE_VALUE_EQUATABLE(csp::common::Vector2)
MAKE_VALUE_EQUATABLE(csp::common::Vector3)
MAKE_VALUE_EQUATABLE(csp::common::Vector4)

// TODO, Build the full list of all the other types.