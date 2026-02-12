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

/* Footgun note: I think this replaces the entire inheritance list, which will be a problem if used
 * on types with their own bases. Fixable, but watch out. */
%typemap(csinterfaces) CLASS_FULLY_NAMESPACED "global::System.IDisposable, System.IEquatable<$csclassname>"

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

    //GetStdHashCode is size_t, may be different lengths on different platforms
    long hash = (long)GetStdHashCode();

    // GetHashCode wants a 32 bit int, XOR the ptr with itself, shifting the upper part down, so we
    // avoid collisions with values that have the same lower bits but different higher bits.
    // In the case of a 32 bit system, we just shift 0's so this is a no-op.
    // In checked contexts, this cast from long to int can trigger overflow exceptions.
    // `unchecked` prevents this, overflow is well defined in C#, so hashes remain stable.
    return unchecked((int)(hash ^ (hash >> 32)));
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

/* Pointer equatability checks if the underlying C-pointer is the same.
 * This is what you want for things like SpaceEntities, where even if you
 * have duplicates that are identical in every way, they are still 
 * conceptually "different things". 
 *
 * Adding pointer equality is easier than value equality, because you don't
 * require underlying C++ operators. However, please hesitate to do this
 * if you need value equality. Improving the platform generally is important,
 * get CSP to add operators if you need them
 */
%define MAKE_POINTER_EQUATABLE(CLASS_FULLY_NAMESPACED)
%typemap(csinterfaces) CLASS_FULLY_NAMESPACED "global::System.IDisposable, System.IEquatable<$csclassname>"

%typemap(cscode) CLASS_FULLY_NAMESPACED %{

  public bool Equals($csclassname? obj)
  {
    if (ReferenceEquals(this, obj)) return true; // The same proxy object
    if (obj is null) return false;
    return $csclassname.getCPtr(this).Handle == $csclassname.getCPtr(obj).Handle;
  }

  public override bool Equals(object? obj) {
    return Equals(obj as $csclassname);
  }

  public override int GetHashCode() {
    //On 32 bit platforms, the additional bits are filled with 0's, making the below cast harmless.
    var href = $csclassname.getCPtr(this);
    long ptr = href.Handle.ToInt64();

    // GetHashCode wants a 32 bit int, XOR the ptr with itself, shifting the upper part down, so we
    // avoid collisions with values that have the same lower bits but different higher bits.
    // In the case of a 32 bit system, we just shift 0's so this is a no-op.
    // In checked contexts, this cast from long to int can trigger overflow exceptions.
    // `unchecked` prevents this, overflow is well defined in C#, so hashes remain stable.
    return unchecked((int)(ptr ^ (ptr >> 32)));
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

%enddef

MAKE_VALUE_EQUATABLE(csp::common::Vector2)
MAKE_VALUE_EQUATABLE(csp::common::Vector3)
MAKE_VALUE_EQUATABLE(csp::common::Vector4)
MAKE_VALUE_EQUATABLE(csp::common::ReplicatedValue)
MAKE_VALUE_EQUATABLE(csp::common::SettingsCollection)
MAKE_VALUE_EQUATABLE(csp::common::ApplicationSettings)

MAKE_POINTER_EQUATABLE(csp::multiplayer::SpaceEntity)

// TODO, Build the full list of all the other types.