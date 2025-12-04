%module(directors="1") CspCommonVectors

%include "typemaps.i"
%include "carrays.i"

%{
#include "CSP/Common/Vector.h"
%}

/************************************************************
 * UNITY EXTENSIONS SECTION — ENABLED WITH:
 *   cmake -DENABLE_UNITY_EXTENSIONS=ON
 ************************************************************/
#ifdef SWIG_UNITY_EXTENSIONS

/* Follow convention for Unity vector components */
%rename(x) csp::common::Vector2::X;
%rename(y) csp::common::Vector2::Y;

%rename(x) csp::common::Vector3::X;
%rename(y) csp::common::Vector3::Y;
%rename(z) csp::common::Vector3::Z;

%rename(x) csp::common::Vector4::X;
%rename(y) csp::common::Vector4::Y;
%rename(z) csp::common::Vector4::Z;
%rename(w) csp::common::Vector4::W;

/* Add Unity extension converters */
%extend csp::common::Vector2 {
%proxycode %{
  public Vector2(UnityEngine.Vector2 UnityVec2) : this(UnityVec2.x, UnityVec2.y) { }
  //Could easily get fancy with assignment operators here instead, this is just basic for prototyping.
  public UnityEngine.Vector2 ToUnity() => new UnityEngine.Vector2(x, y);
%}
}

%extend csp::common::Vector3 {
%proxycode %{
  public Vector3(UnityEngine.Vector3 UnityVec3) : this(UnityVec3.x, UnityVec3.y, UnityVec3.z) { }
  //Could easily get fancy with assignment operators here instead, this is just basic for prototyping.
  public UnityEngine.Vector3 ToUnity() => new UnityEngine.Vector3(x, y, z);
%}
}

%extend csp::common::Vector4 {
%proxycode %{
  public Vector4(UnityEngine.Quaternion UnityQuat) : this(UnityQuat.x, UnityQuat.y, UnityQuat.z, UnityQuat.w) { }
   //Could easily get fancy with assignment operators here instead, this is just basic for prototyping.
  public UnityEngine.Quaternion ToUnity() => new UnityEngine.Quaternion(x, y, z, w);
%}
}

#endif  // SWIG_UNITY_EXTENSIONS

/* C# operator renames for arithmetic operators */
%rename(Add) csp::common::Vector2::operator+;
%rename(Subtract) csp::common::Vector2::operator-;
%rename(Multiply) csp::common::Vector2::operator*;
%rename(Divide) csp::common::Vector2::operator/;

%rename(Add) csp::common::Vector3::operator+;
%rename(Subtract) csp::common::Vector3::operator-;
%rename(Multiply) csp::common::Vector3::operator*;
%rename(Divide) csp::common::Vector3::operator/;

%rename(Add) csp::common::Vector4::operator+;
%rename(Subtract) csp::common::Vector4::operator-;
%rename(Multiply) csp::common::Vector4::operator*;
%rename(Divide) csp::common::Vector4::operator/;

/* Now that all the rules are in place, start parsing the header applying them. */
%include "CSP/Common/Vector.h"
