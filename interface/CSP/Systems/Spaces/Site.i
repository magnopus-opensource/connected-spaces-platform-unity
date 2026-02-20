%{
#include "CSP/Systems/Spaces/Site.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::Site)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::SiteResult)

%include "CSP/Systems/Spaces/Site.h"

/************************************************************
 * UNITY EXTENSIONS SECTION — ENABLED WITH:
 *   cmake -DENABLE_UNITY_EXTENSIONS=ON
 ************************************************************/
#ifdef SWIG_UNITY_EXTENSIONS
/* Add Unity extension functions */
%extend csp::systems::OlyRotation {
%proxycode %{
#region UNITY EXTENSIONS
  public static implicit operator OlyRotation(UnityEngine.Quaternion rot) 
  {
    return new OlyRotation(rot.x, rot.y, rot.z, rot.w);
  }
  
  public static implicit operator UnityEngine.Quaternion(OlyRotation rot) 
  {
    return new UnityEngine.Quaternion((float)rot.X, (float)rot.Y, (float)rot.Z, (float)rot.W);
  }
#endregion
%}
}
#endif