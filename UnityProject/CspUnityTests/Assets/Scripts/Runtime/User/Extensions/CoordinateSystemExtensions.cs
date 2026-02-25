// ------------------------------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ------------------------------------------------------------------

using UnityEngine;

namespace Magnopus.Foundation.Unity.Runtime.User.Extensions
{
    // See "/unity-client/docs/CoordinateSpaceConversions.svg"
    public static class CoordinateSystemExtensions
    {
        // https://github.com/KhronosGroup/UnityGLTF/blob/master/UnityGLTF/Assets/UnityGLTF/Runtime/Scripts/Extensions/SchemaExtensions.cs
        // GLTF coordinate (right handed): -x = right, y = up, z = forward
        private static readonly Vector3 GLTFCoordinateSpaceConversionScale = new Vector3(-1, 1, 1);

        public static Quaternion ToUnityRotationFromGLTF(this Quaternion gltfRotation)
        {
            // Convert from GLTF coordinate (right handed)
            // -x = right
            // y = up
            // z = forward

            Vector3 fromAxisOfRotation = new Vector3(gltfRotation.x, gltfRotation.y, gltfRotation.z);
            // Flip handness
            float axisFlipScale = -1.0f;
            Vector3 toAxisOfRotation = axisFlipScale * Vector3.Scale(fromAxisOfRotation, GLTFCoordinateSpaceConversionScale);
            var unityRotation = new Quaternion(toAxisOfRotation.x, toAxisOfRotation.y, toAxisOfRotation.z, gltfRotation.w);

            return unityRotation;
        }

        public static Quaternion ToGLTFRotationFromUnity(this Quaternion unityRotation)
        {
            Vector3 fromAxisOfRotation = new Vector3(unityRotation.x, unityRotation.y, unityRotation.z);
            // Flip handness
            float axisFlipScale = -1.0f;
            Vector3 toAxisOfRotation = axisFlipScale * Vector3.Scale(fromAxisOfRotation, GLTFCoordinateSpaceConversionScale);
            var gltfRotation = new Quaternion(toAxisOfRotation.x, toAxisOfRotation.y, toAxisOfRotation.z, unityRotation.w);

            return gltfRotation;
        }
    }
}
