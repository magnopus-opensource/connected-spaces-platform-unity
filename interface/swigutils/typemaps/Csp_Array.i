/* -----------------------------------------------------------------------------
 * THE BELOW IS BASED ON SWIGS ON std_array.i TYPEMAP
 * It shouldn't exist long term, it is a shim until we can expose standard
 * types properly in the interface.
 *
 * SWIG typemaps for csp::common::Array<T, N>
 * C# implementation
 * The C# wrapper is made to look and feel like a C# System.Collections.Generic.IReadOnlyList<> collection.
 * Note: This is a list that cannot be grown or shrunk, _not_ one with immutable elements.
 * ----------------------------------------------------------------------------- */

%include <std_common.i>


%define SWIG_STD_ARRAY_INTERNAL(CTYPE)
%typemap(csinterfaces) csp::common::Array< CTYPE > "global::System.IDisposable, global::System.Collections.Generic.IReadOnlyList<$typemap(cstype, CTYPE)>"
%proxycode %{
  public $csclassname(global::System.Collections.ICollection c) : this(c != null ? (uint)c.Count : 0) {
    if (c == null) {
      // This is the expected error for a null input to a collection.
      // We'd get NullReferenceException if we did't guard the initializer list constructor arg (Count)
      throw new global::System.ArgumentNullException("c");
    } 
    int count = this.Count;
    int i = 0;
    foreach ($typemap(cstype, CTYPE) element in c) {
      if (i >= count)
        break;
      this[i++] = element;
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

  public int Count {
    get {
      return (int)Size();
    }
  }

  public void CopyTo($typemap(cstype, CTYPE)[] array)
  {
    CopyTo(0, array, 0, this.Count);
  }

  public void CopyTo($typemap(cstype, CTYPE)[] array, int arrayIndex)
  {
    CopyTo(0, array, arrayIndex, this.Count);
  }

  public void CopyTo(int index, $typemap(cstype, CTYPE)[] array, int arrayIndex, int count)
  {
    if (array == null)
      throw new global::System.ArgumentNullException("array");
    if (index < 0)
      throw new global::System.ArgumentOutOfRangeException("index", "Value is less than zero");
    if (arrayIndex < 0)
      throw new global::System.ArgumentOutOfRangeException("arrayIndex", "Value is less than zero");
    if (count < 0)
      throw new global::System.ArgumentOutOfRangeException("count", "Value is less than zero");
    if (array.Rank > 1)
      throw new global::System.ArgumentException("Multi dimensional array.", "array");
    if (index+count > this.Count || arrayIndex+count > array.Length)
      throw new global::System.ArgumentException("Number of elements to copy is too large.");
    for (int i=0; i<count; i++)
      array.SetValue(getitemcopy(index+i), arrayIndex+i);
  }

  public $typemap(cstype, CTYPE)[] DeepCopyToArray()
  {
    int count = this.Count;
    $typemap(cstype, CTYPE)[] result = new $typemap(cstype, CTYPE)[count];
    for (int i = 0; i < count; i++)
      result[i] = getitemcopy(i);
    return result;
  }
  
  public global::System.Collections.Generic.List<$typemap(cstype, CTYPE)> DeepCopyToList()
  {
    int count = this.Count;
    global::System.Collections.Generic.List<$typemap(cstype, CTYPE)> result = 
      new global::System.Collections.Generic.List<$typemap(cstype, CTYPE)>(count);
    for (int i = 0; i < count; i++)
      result.Add(getitemcopy(i));
    return result;
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
  /// whenever the collection is modified. This has been done for changes in the size of the
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
      int size = collectionRef.Count;
      bool moveOkay = (currentIndex+1 < size) && (size == currentSize);
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
    Array();
    Array(const size_t Size);

    size_t Size() const;
    bool IsEmpty() const;

    %extend {
      CTYPE getitemcopy(int index) throw (std::out_of_range) {
        if (index>=0 && index<(int)$self->Size())
          return (*$self)[index];
        else
          throw std::out_of_range("index");
      }
      const CTYPE& getitem(int index) throw (std::out_of_range) {
        if (index>=0 && index<(int)$self->Size())
          return (*$self)[index];
        else
          throw std::out_of_range("index");
      }
      void setitem(int index, const CTYPE& val) throw (std::out_of_range) {
        if (index>=0 && index<(int)$self->Size())
          (*$self)[index] = val;
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
      void Fill(const CTYPE& value)
      {
        for (auto it = $self->begin(); it != $self->end(); ++it)
        {
            *it = value;
        }
      }
    }
%enddef

%{
#include "CSP/Common/Array.h"
#include <algorithm>
#include <stdexcept>
%}

%csmethodmodifiers csp::common::Array::Size "private"
%csmethodmodifiers csp::common::Array::getitemcopy "private"
%csmethodmodifiers csp::common::Array::getitem "private"
%csmethodmodifiers csp::common::Array::setitem "private"

namespace csp::common {
  template<class T> class Array {
    SWIG_STD_ARRAY_INTERNAL(T)
  };
}