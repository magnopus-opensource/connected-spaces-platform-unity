/* 
 * Utility code for pinning inner objects to outer objects
 *
 * The problem this solves is a rather gnarly one, caused by the presence of reference
 * getters in underlying API. This isn't a poor thing the underlying API has done, but
 * it is problematic when exposed to a GC'd language
 *
 * Imagine a C++ object like the following.
```cpp
    class OuterObject
    {
    public:
      const InnerObject& GetInnerObject() const { return m_innerObject; }
    private:
      InnerObject m_innerObject;
    } 
```
 * This is perfectly cromulent C++. However, the issue comes from the fact that OO
 * based interop layers, such as this one, represent each C++ object via a proxy object
 * that simply manages a single dumb pointer.
 * With this in mind, imagine this scenario, c# this time.
 ```csharp
    InnerObject GetInnerObject(){
      return CSP.GetOuterObject().GetInnerObject();
    }

    InnerObject myObj = GetInnerObject();
    myObj.DoSomething(); // Might crash!
```
 * Why might that crash? That seems fine.
 * Well, consider the C# proxy object lifetime. In `GetInnerObject`, a proxy OuterObject
 * is created, which owns the C++ OuterObject memory, and then a proxy InnerObject is
 * created with a pointer to m_innerObject. When the function GetInnerObject exits, the
 * proxy OuterObject is now a candidate for GC. If this happens, the finalizer will run,
 * which will then cause the destructor of OuterObject to be called. Oh no, if OuterObject
 * is destructed, then the m_innerObject memory will become a candidate for deallocation!
 *
 * That is the problem. The way we solve it is by making every reference getter, including
 * properties, insert a pin into the outer object. This is somewhat of a sledgehammer solution,
 * but I believe conceptually stable. If the underlying C++ is doing something odd, like
 * returning a reference to memory it doesn't own (arguably a bug imo), all this should do is
 * extend the lifetime of the outer object inappropriately, but not cause any actual issues.
 *
 * For this reason, every C# proxy object in the api is generated with a slot to place an
 * outer object pin.
 */


%define ADD_OUTER_OBJECT_PIN_SLOT(FULLY_NAMESPACED_CLASST)
%extend FULLY_NAMESPACED_CLASST {
%proxycode %{
  // Any time this object is returned from an outer C++ object via reference, this is set
  // to prevent premature garbage collection causing premature C++ memory deallocation.
  public object OuterObjectPin { private get; set; }
%}
}
%enddef



/* Global typemaps to call the outer pin in getters. For both reference getter methods
 * and properties. Doing this is the recommended approach, you can read it in the C#
 * SWIG docs here: https://swig.org/Doc4.4/CSharp.html#CSharp_typemap_examples
 * WARNING that this is a global typemaps. Only one of each typemap type (csout, csvarout, etc)
 * will be applied to each object. Beware when using more specialized typemaps, as you want to
 * do this for everything. There's some structural project thinking to be done around this. */

%typemap(csout, excode=SWIGEXCODE) SWIGTYPE& {
  global::System.IntPtr cPtr = $imcall;$excode
  $csclassname ret = null;
  if (cPtr != global::System.IntPtr.Zero) {
    ret = new $csclassname(cPtr, $owner);
    ret.OuterObjectPin = this;
  }
  return ret;
}

%typemap(csvarout, excode=SWIGEXCODE2) SWIGTYPE* %{
    get {
      global::System.IntPtr cPtr = $imcall;$excode
      $csclassname ret = null;
      if (cPtr != global::System.IntPtr.Zero) {
        ret = new $csclassname(cPtr, $owner);
        ret.OuterObjectPin = this;
      }
      return ret;
    }
%}

/* Override csout for static methods returning references — `this` is not valid in a static context
 * Set the typemap back to the default
 * I do wonder if there's ways to get the default typemap rather than just duplicating the known
 * code it generates, worth looking into. */
%typemap(csout, excode=SWIGEXCODE) const csp::common::Vector2& csp::common::Vector2::Zero,
                                   const csp::common::Vector2& csp::common::Vector2::One,
                                   const csp::common::Vector3& csp::common::Vector3::Zero,
                                   const csp::common::Vector3& csp::common::Vector3::One,
                                   const csp::common::Vector4& csp::common::Vector4::Zero,
                                   const csp::common::Vector4& csp::common::Vector4::One,
                                   const csp::common::Vector4& csp::common::Vector4::Identity,
                                   const csp::EndpointURIs& csp::CSPFoundation::GetEndpoints,
                                   const csp::ClientUserAgent& csp::CSPFoundation::GetClientUserAgentInfo,
                                   csp::common::CancellationToken& csp::common::CancellationToken::Dummy,
                                   csp::common::MimeTypeHelper& csp::common::MimeTypeHelper::Get,
                                   csp::systems::SystemsManager& csp::systems::SystemsManager::Get,
                                   const csp::common::Vector2& csp::common::ReplicatedValue::GetDefaultVector2,
                                   const csp::common::Vector3& csp::common::ReplicatedValue::GetDefaultVector3,
                                   const csp::common::Vector4& csp::common::ReplicatedValue::GetDefaultVector4,
                                   const csp::common::Array<csp::FeatureFlag>& csp::CSPFoundation::GetFeatureFlags {
  global::System.IntPtr cPtr = $imcall;$excode
  $csclassname ret = null;
  if (cPtr != global::System.IntPtr.Zero) {
    ret = new $csclassname(cPtr, $owner);
  }
  return ret;
}
