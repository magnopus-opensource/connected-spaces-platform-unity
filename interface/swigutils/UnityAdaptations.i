/************************************************************
 * UNITY EXTENSIONS SECTION — ENABLED WITH:
 *   cmake -DENABLE_UNITY_EXTENSIONS=ON
 ************************************************************/

#ifdef SWIG_UNITY_EXTENSIONS

/* ============================================================
 * OlyRotation: Implicit operator conversions for Unity
 * ============================================================ */
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

/* ============================================================
 * Vector Components: Follow Unity naming convention (x, y, z, w)
 * ============================================================ */
%rename(x) csp::common::Vector2::X;
%rename(y) csp::common::Vector2::Y;

%rename(x) csp::common::Vector3::X;
%rename(y) csp::common::Vector3::Y;
%rename(z) csp::common::Vector3::Z;

%rename(x) csp::common::Vector4::X;
%rename(y) csp::common::Vector4::Y;
%rename(z) csp::common::Vector4::Z;
%rename(w) csp::common::Vector4::W;

/* ============================================================
 * Vector2: Unity extensions and conversions
 * ============================================================ */
%extend csp::common::Vector2 {
%proxycode %{
#region UNITY EXTENSIONS
    public Vector2(UnityEngine.Vector2 UnityVec2) : this(UnityVec2.x, UnityVec2.y) { }
    public UnityEngine.Vector2 ToUnity() => new UnityEngine.Vector2(x, y);
#endregion
%}
}

/* ============================================================
 * Vector3: Unity extensions, conversions, and coordinate space
 * ============================================================ */
%extend csp::common::Vector3 {
%proxycode %{
#region UNITY EXTENSIONS
    public Vector3(UnityEngine.Vector3 UnityVec3) : this(UnityVec3.x, UnityVec3.y, UnityVec3.z) { }
    public UnityEngine.Vector3 ToUnity() => new UnityEngine.Vector3(x, y, z);

    #region COORDINATE SPACE CONVERSIONS
    // See "/unity-client/docs/CoordinateSpaceConversions.svg"

    // https://github.com/KhronosGroup/UnityGLTF/blob/master/UnityGLTF/Assets/UnityGLTF/Runtime/Scripts/Extensions/SchemaExtensions.cs
    // GLTF coordinate (right handed): -x = right, y = up, z = forward
    private static readonly UnityEngine.Vector3 GLTFCoordinateSpaceConversionScale = new UnityEngine.Vector3(-1, 1, 1);

    /// <summary>
    /// Convert from GLTF coordinate (right handed)
    /// -x = right
    /// y = up
    /// z = forward
    /// </summary>
    public UnityEngine.Vector3 ToUnityPositionFromGLTF()
    {
        var unityPosition = UnityEngine.Vector3.Scale(this.ToUnity(), GLTFCoordinateSpaceConversionScale);
        return unityPosition;
    }

    /// <summary>
    /// Convert from GLTF coordinate (right handed)
    /// -x = right
    /// y = up
    /// z = forward
    /// </summary>
    public UnityEngine.Vector3 ToUnityEulerRotationFromGLTF()
    {
        // Flip handness
        float axisFlipScale = -1.0f;
        var unityEuler = axisFlipScale * UnityEngine.Vector3.Scale(this.ToUnity(), GLTFCoordinateSpaceConversionScale);
        return unityEuler;
    }

    public UnityEngine.Vector3 ToUnityScaleFromGLTF()
    {
        return this.ToUnity();
    }

    public UnityEngine.Vector3 ToGLTFPositionFromUnity()
    {
        var gltfPosition = UnityEngine.Vector3.Scale(this.ToUnity(), GLTFCoordinateSpaceConversionScale);
        return gltfPosition;
    }

    public UnityEngine.Vector3 ToGLTFEulerRotationFromUnity()
    {
        // Flip handness
        float axisFlipScale = -1.0f;
        var gltfEuler = axisFlipScale * UnityEngine.Vector3.Scale(this.ToUnity(), GLTFCoordinateSpaceConversionScale);
        return gltfEuler;
    }

    public UnityEngine.Vector3 ToGLTFScaleFromUnity()
    {
        return this.ToUnity();
    }
    #endregion
    
#endregion
%}
}

/* ============================================================
 * Vector4: Unity extensions, conversions, and coordinate space
 * ============================================================ */
%extend csp::common::Vector4 {
%proxycode %{
#region UNITY EXTENSIONS
    public Vector4(UnityEngine.Quaternion UnityQuat) : this(UnityQuat.x, UnityQuat.y, UnityQuat.z, UnityQuat.w) { }
    public UnityEngine.Quaternion ToUnity() => new UnityEngine.Quaternion(x, y, z, w);

    #region COORDINATE SPACE CONVERSIONS
    // See "/unity-client/docs/CoordinateSpaceConversions.svg"

    // https://github.com/KhronosGroup/UnityGLTF/blob/master/UnityGLTF/Assets/UnityGLTF/Runtime/Scripts/Extensions/SchemaExtensions.cs
    // GLTF coordinate (right handed): -x = right, y = up, z = forward
    private static readonly UnityEngine.Vector3 GLTFCoordinateSpaceConversionScale = new UnityEngine.Vector3(-1, 1, 1);

    /// <summary>
    /// Convert from GLTF coordinate (right handed)
    /// -x = right
    /// y = up
    /// z = forward
    /// </summary>
    public UnityEngine.Quaternion ToUnityRotationFromGLTF()
    {
        var gltfRotation = this.ToUnity();
        UnityEngine.Vector3 fromAxisOfRotation = new UnityEngine.Vector3(gltfRotation.x, gltfRotation.y, gltfRotation.z);

        // Flip handness
        float axisFlipScale = -1.0f;
        var toAxisOfRotation = axisFlipScale * UnityEngine.Vector3.Scale(fromAxisOfRotation, GLTFCoordinateSpaceConversionScale);
        var unityRotation = new UnityEngine.Quaternion(toAxisOfRotation.x, toAxisOfRotation.y, toAxisOfRotation.z, gltfRotation.w);
        return unityRotation;
    }

    /// <summary>
    /// Convert from Attitude sensor coordinate, returned in Right-Handed but Unity uses Left-Handed coords.
    /// x = right
    /// y = up
    /// -z = forward
    /// -w = rotation scalar
    /// </summary>
    public UnityEngine.Quaternion ToUnityRotationFromAttitude()
    {
        var attitudeRotation = this.ToUnity();
        var unityRotation =  new UnityEngine.Quaternion(attitudeRotation.x, attitudeRotation.y, -attitudeRotation.z, -attitudeRotation.w);

        return unityRotation;
    }

    public UnityEngine.Quaternion ToGLTFRotationFromUnity()
    {
        var unityRotation = this.ToUnity();
        var fromAxisOfRotation = new UnityEngine.Vector3(unityRotation.x, unityRotation.y, unityRotation.z);
        // Flip handness
        float axisFlipScale = -1.0f;
        var toAxisOfRotation = axisFlipScale * UnityEngine.Vector3.Scale(fromAxisOfRotation, GLTFCoordinateSpaceConversionScale);
        var gltfRotation = new UnityEngine.Quaternion(toAxisOfRotation.x, toAxisOfRotation.y, toAxisOfRotation.z, unityRotation.w);

        return gltfRotation;
    }

    #endregion
#endregion
%}
}
#endif