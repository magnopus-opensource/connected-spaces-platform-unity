/* -----------------------------------------------------------------------------
 * THE BELOW IS BASED ON SWIGS ON std_vector.i TYPEMAP
 * It shouldn't exist long term, it is a shim until we can expose standard
 * types properly in the interface.
 * Quick overview of changes:
 * - Namespaces changed from std->csp::common
 * - "Vector" type name changed to "List"
 * - Removed the typedeffing as we don't have those in csp::common::List, just use the `T` values directly.
 * - Updated the interfaces in the declared type to match the functions available on List
 *
 * SWIG typemaps for csp::common::List<T>
 * C# implementation
 * The C# wrapper is made to look and feel like a C# System.Collections.Generic.List<> collection.
 *
 * Note that IEnumerable<> is implemented in the proxy class which is useful for using LINQ with
 * C++ csp::common::List wrappers. The IList<> interface is also implemented to provide enhanced functionality
 * whenever we are confident that the required C++ operator== is available. This is the case for when
 * T is a primitive type or a pointer. If T does define an operator==, then use the SWIG_STD_VECTOR_ENHANCED
 * macro to obtain this enhanced functionality, for example:
 *
 *   SWIG_STD_VECTOR_ENHANCED(SomeNamespace::Klass)
 *   %template(VectKlass) csp::common::List<SomeNamespace::Klass>;
 * ----------------------------------------------------------------------------- */

%include <std_common.i>

// MACRO for use within the csp::common::List class body
%define SWIG_STD_VECTOR_MINIMUM_INTERNAL(CSINTERFACE, CTYPE_REF_RETURN, CTYPE...)
%typemap(csinterfaces) csp::common::List< CTYPE > "global::System.IDisposable, global::System.Collections.IEnumerable, global::System.Collections.Generic.CSINTERFACE<$typemap(cstype, CTYPE)>\n"
%proxycode %{
  public $csclassname(global::System.Collections.IEnumerable c) : this() {
    if (c == null)
      throw new global::System.ArgumentNullException("c");
    foreach ($typemap(cstype, CTYPE) element in c) {
      this.Add(element);
    }
  }

  public $csclassname(global::System.Collections.Generic.IEnumerable<$typemap(cstype, CTYPE)> c) : this() {
    if (c == null)
      throw new global::System.ArgumentNullException("c");
    foreach ($typemap(cstype, CTYPE) element in c) {
      this.Add(element);
    }
  }

  public bool IsFixedSize {
    get {
      return false;
    }
  }

  public bool IsReadOnly {
    get {
      return false;
    }
  }

  public $typemap(cstype, CTYPE) this[int index]  {
    get {
      return getitem(index);
    }
    set {
      setitem(index, value);
    }
  }

  public bool IsEmpty {
    get {
      return Size() == 0;
    }
  }

  public int Count {
    get {
      return (int)Size();
    }
  }

  public bool IsSynchronized {
    get {
      return false;
    }
  }

  public void CopyTo($typemap(cstype, CTYPE)[] outArray)
  {
    CopyTo(0, outArray, 0, this.Count);
  }

  public void CopyTo($typemap(cstype, CTYPE)[] outArray, int outStartIndex)
  {
    CopyTo(0, outArray, outStartIndex, this.Count);
  }

  public void CopyTo(int srcStartIndex, $typemap(cstype, CTYPE)[] outArray, int outStartIndex, int count)
  {
    if (outArray == null)
      throw new global::System.ArgumentNullException("outArray");
    if (srcStartIndex < 0)
      throw new global::System.ArgumentOutOfRangeException("srcStartIndex", "Value is less than zero");
    if (outStartIndex < 0)
      throw new global::System.ArgumentOutOfRangeException("outStartIndex", "Value is less than zero");
    if (count < 0)
      throw new global::System.ArgumentOutOfRangeException("count", "Value is less than zero");
    if (outArray.Rank > 1)
      throw new global::System.ArgumentException("Multi dimensional array.", "array");
    if (srcStartIndex+count > this.Count || outStartIndex+count > outArray.Length)
      throw new global::System.ArgumentException("Number of elements to copy is too large.");
    for (int i=0; i<count; i++)
      outArray.SetValue(getitemcopy(srcStartIndex+i), outStartIndex+i);
  }

  public $typemap(cstype, CTYPE)[] ToArray() {
    $typemap(cstype, CTYPE)[] array = new $typemap(cstype, CTYPE)[this.Count];
    this.CopyTo(array);
    return array;
  }

  global::System.Collections.Generic.IEnumerator<$typemap(cstype, CTYPE)> global::System.Collections.Generic.IEnumerable<$typemap(cstype, CTYPE)>.GetEnumerator() {
    return new $csclassnameEnumerator(this);
  }

  global::System.Collections.IEnumerator global::System.Collections.IEnumerable.GetEnumerator() {
    return new $csclassnameEnumerator(this);
  }

  public $csclassnameEnumerator GetEnumerator() {
    return new $csclassnameEnumerator(this);
  }

  // Type-safe enumerator
  /// Note that the IEnumerator documentation requires an InvalidOperationException to be thrown
  /// whenever the collection is modified. This has been done for changes in the Size of the
  /// collection but not when one of the elements of the collection is modified as it is a bit
  /// tricky to detect unmanaged code that modifies the collection under our feet.
  public sealed class $csclassnameEnumerator : global::System.Collections.IEnumerator
    , global::System.Collections.Generic.IEnumerator<$typemap(cstype, CTYPE)>
  {
    private $csclassname collectionRef;
    private int currentIndex;
    private object currentObject;
    private int currentSize;

    public $csclassnameEnumerator($csclassname collection) {
      collectionRef = collection;
      currentIndex = -1;
      currentObject = null;
      currentSize = collectionRef.Count;
    }

    // Type-safe iterator Current
    public $typemap(cstype, CTYPE) Current {
      get {
        if (currentIndex == -1)
          throw new global::System.InvalidOperationException("Enumeration not started.");
        if (currentIndex > currentSize - 1)
          throw new global::System.InvalidOperationException("Enumeration finished.");
        if (currentObject == null)
          throw new global::System.InvalidOperationException("Collection modified.");
        return ($typemap(cstype, CTYPE))currentObject;
      }
    }

    // Type-unsafe IEnumerator.Current
    object global::System.Collections.IEnumerator.Current {
      get {
        return Current;
      }
    }

    public bool MoveNext() {
      int Size = collectionRef.Count;
      bool moveOkay = (currentIndex+1 < Size) && (Size == currentSize);
      if (moveOkay) {
        currentIndex++;
        currentObject = collectionRef[currentIndex];
      } else {
        currentObject = null;
      }
      return moveOkay;
    }

    public void Reset() {
      currentIndex = -1;
      currentObject = null;
      if (collectionRef.Count != currentSize) {
        throw new global::System.InvalidOperationException("Collection modified.");
      }
    }

    public void Dispose() {
        currentIndex = -1;
        currentObject = null;
    }
  }
%}

  public:

    /* 
     * These methods changed to match necessary methods in csp::common::List 
     * They are referenced in the below implementations to shim to the C# interface.
     */
    List();
    List(const List &other);

    size_t Size() const;
    void Insert(size_t Index, CTYPE item);
    void Clear();
    %rename(Add) Append;
    void Append(CTYPE x);

    %extend {
      List(int capacity) throw (std::out_of_range) {
        csp::common::List< CTYPE >* pv = 0;
        if (capacity >= 0) {
          pv = new csp::common::List< CTYPE >(capacity);
       } else {
          throw std::out_of_range("capacity");
       }
       return pv;
      }
      CTYPE getitemcopy(int index) throw (std::out_of_range) {
        if (index>=0 && index<(int)$self->Size())
          return (*$self)[index];
        else
          throw std::out_of_range("index");
      }
      CTYPE_REF_RETURN getitem(int index) throw (std::out_of_range) {
        if (index>=0 && index<(int)$self->Size())
          return (*$self)[index];
        else
          throw std::out_of_range("index");
      }
      void setitem(int index, CTYPE const& val) throw (std::out_of_range) {
        if (index>=0 && index<(int)$self->Size())
          (*$self)[index] = val;
        else
          throw std::out_of_range("index");
      }

      void Insert(int index, CTYPE const& x) throw (std::out_of_range) {
        if (index>=0 && index<(int)$self->Size()+1)
          $self->Insert(index, x);
        else
          throw std::out_of_range("index");
      }
      void RemoveAt(int index) throw (std::out_of_range) {
        if (index>=0 && index<(int)$self->Size())
          $self->Remove(index);
        else
          throw std::out_of_range("index");
      }
      void Reverse() {
        std::reverse($self->begin(), $self->end());
      }
      void Reverse(int index, int count) throw (std::out_of_range, std::invalid_argument) {
        if (index < 0)
          throw std::out_of_range("index");
        if (count < 0)
          throw std::out_of_range("count");
        if (index >= (int)$self->Size()+1 || index+count > (int)$self->Size())
          throw std::invalid_argument("invalid range");
        std::reverse($self->begin()+index, $self->begin()+index+count);
      }
      // Takes a deep copy of the elements unlike ArrayList.SetRange
      void SetRange(int index, const csp::common::List< CTYPE >& values) throw (std::out_of_range) {
        if (index < 0)
          throw std::out_of_range("index");
        if (index+values.Size() > $self->Size())
          throw std::out_of_range("index");
        std::copy(values.begin(), values.end(), $self->begin()+index);
      }
    }
%enddef

// Extra methods added to the collection class if operator== is defined for the class being wrapped
// The class will then implement IList<>, which adds extra functionality
%define SWIG_STD_VECTOR_EXTRA_OP_EQUALS_EQUALS(CTYPE...)
    %extend {
      bool Contains(CTYPE const& value) {
        return std::find($self->begin(), $self->end(), value) != $self->end();
      }
      int IndexOf(CTYPE const& value) {
        int index = -1;
        csp::common::List< CTYPE >::iterator it = std::find($self->begin(), $self->end(), value);
        if (it != $self->end())
          index = (int)(it - $self->begin());
        return index;
      }
      int LastIndexOf(CTYPE const& value) {
        int index = -1;
        csp::common::List< CTYPE >::reverse_iterator rit = std::find($self->rbegin(), $self->rend(), value);
        if (rit != $self->rend())
          index = (int)($self->rend() - 1 - rit);
        return index;
      }
      bool Remove(CTYPE const& value) {
        csp::common::List< CTYPE >::iterator it = std::find($self->begin(), $self->end(), value);
        if (it != $self->end()) {
          $self->RemoveItem(value); //Would be better if RemoveItem returned directly
          return true;
        }
        return false;
      }
    }
%enddef

// Macros for csp::common::List class specializations/enhancements
%define SWIG_STD_VECTOR_ENHANCED(CTYPE...)
namespace csp::common {
  template<> class List< CTYPE > {
    SWIG_STD_VECTOR_MINIMUM_INTERNAL(IList, const CTYPE&, %arg(CTYPE))
    SWIG_STD_VECTOR_EXTRA_OP_EQUALS_EQUALS(CTYPE)
  };
}
%enddef

%{
#include "CSP/Common/List.h"
#include <algorithm>
#include <stdexcept>
%}


%csmethodmodifiers csp::common::List::getitemcopy "private"
%csmethodmodifiers csp::common::List::getitem "private"
%csmethodmodifiers csp::common::List::setitem "private"
%csmethodmodifiers csp::common::List::Size "private" //handled by Count


namespace csp::common {
  // primary (unspecialized) class template for csp::common::List
  // does not require operator== to be defined
  template<class T> class List {
    SWIG_STD_VECTOR_MINIMUM_INTERNAL(IEnumerable, const CTYPE&, T)
  };
  // specialization for pointers
  template<class T> class List<T *> {
    SWIG_STD_VECTOR_MINIMUM_INTERNAL(IList, CTYPE, T *)
    SWIG_STD_VECTOR_EXTRA_OP_EQUALS_EQUALS(T *)
  };
}

// template specializations for csp::common::List
// these provide extra collections methods as operator== is defined
SWIG_STD_VECTOR_ENHANCED(char)
SWIG_STD_VECTOR_ENHANCED(signed char)
SWIG_STD_VECTOR_ENHANCED(unsigned char)
SWIG_STD_VECTOR_ENHANCED(short)
SWIG_STD_VECTOR_ENHANCED(unsigned short)
SWIG_STD_VECTOR_ENHANCED(int)
SWIG_STD_VECTOR_ENHANCED(unsigned int)
SWIG_STD_VECTOR_ENHANCED(long)
SWIG_STD_VECTOR_ENHANCED(unsigned long)
SWIG_STD_VECTOR_ENHANCED(long long)
SWIG_STD_VECTOR_ENHANCED(unsigned long long)
SWIG_STD_VECTOR_ENHANCED(float)
SWIG_STD_VECTOR_ENHANCED(double)
SWIG_STD_VECTOR_ENHANCED(csp::common::String)
SWIG_STD_VECTOR_ENHANCED(std::string) // also requires a %include <std_string.i>
SWIG_STD_VECTOR_ENHANCED(std::wstring) // also requires a %include <std_wstring.i>