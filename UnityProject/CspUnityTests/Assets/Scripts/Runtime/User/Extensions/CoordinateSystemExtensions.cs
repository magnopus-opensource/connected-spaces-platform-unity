// ------------------------------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ------------------------------------------------------------------

using UnityEngine;

namespace Magnopus.Foundation.Unity.Runtime.User.Extensions
{
    // See "/unity-client/docs/CoordinateSpaceConversions.svg"
    public static class CoordinateSystemExtensions
    {
        // For UE conversion, UE treats 1 unit as 1 centimeter.
        private const float MetersInCentimeter = 0.01f;

        // Playcanvas coordinate (right handed): x = right, y = up, -z = forward
        private static readonly Vector3 PlaycanvasCoordinateSpaceConversionScale = new Vector3(1, 1, -1);

        // https://github.com/KhronosGroup/UnityGLTF/blob/master/UnityGLTF/Assets/UnityGLTF/Runtime/Scripts/Extensions/SchemaExtensions.cs
        // GLTF coordinate (right handed): -x = right, y = up, z = forward
        private static readonly Vector3 GLTFCoordinateSpaceConversionScale = new Vector3(-1, 1, 1);

        public static Vector3 ToUnityPositionFromPlaycanvas(this Vector3 playcanvasPosition)
        {
            // Convert from playcanvas coordinate (right handed)
            // x = right
            // y = up
            // -z = forward

            var unityPosition = Vector3.Scale(playcanvasPosition, PlaycanvasCoordinateSpaceConversionScale);
            return unityPosition;
        }

        public static Quaternion ToUnityRotationFromPlaycanvas(this Quaternion playcanvasRotation)
        {
            // Convert from playcanvas coordinate (right handed)
            // x = right
            // y = up
            // -z = forward

            Vector3 fromAxisOfRotation = new Vector3(playcanvasRotation.x, playcanvasRotation.y, playcanvasRotation.z);
            // Flip handness
            float axisFlipScale = -1.0f;
            Vector3 toAxisOfRotation = axisFlipScale * Vector3.Scale(fromAxisOfRotation, PlaycanvasCoordinateSpaceConversionScale);
            var unityRotation = new Quaternion(toAxisOfRotation.x, toAxisOfRotation.y, toAxisOfRotation.z, playcanvasRotation.w);
            return unityRotation;
        }

        public static Vector3 ToUnityEulerRotationFromPlaycanvas(this Vector3 playcanvasEuler)
        {
            // Convert from playcanvas coordinate (right handed)
            // x = right
            // y = up
            // -z = forward

            // Flip handness
            float axisFlipScale = -1.0f;
            Vector3 unityEuler = axisFlipScale * Vector3.Scale(playcanvasEuler, PlaycanvasCoordinateSpaceConversionScale);
            return unityEuler;
        }

        public static Vector3 ToUnityScaleFromPlaycanvas(this Vector3 playcanvasScale)
        {
            return playcanvasScale;
        }

        public static Vector3 ToPlaycanvasPositionFromUnity(this Vector3 unityPosition)
        {
            var playcanvasPosition = Vector3.Scale(unityPosition, PlaycanvasCoordinateSpaceConversionScale);
            return playcanvasPosition;
        }

        public static Quaternion ToPlaycanvasRotationFromUnity(this Quaternion unityRotation)
        {
            Vector3 fromAxisOfRotation = new Vector3(unityRotation.x, unityRotation.y, unityRotation.z);
            // Flip handness
            float axisFlipScale = -1.0f;
            Vector3 toAxisOfRotation = axisFlipScale * Vector3.Scale(fromAxisOfRotation, PlaycanvasCoordinateSpaceConversionScale);
            var playcanvasRotation = new Quaternion(toAxisOfRotation.x, toAxisOfRotation.y, toAxisOfRotation.z, unityRotation.w);
            return playcanvasRotation;
        }

        public static Vector3 ToPlaycanvasEulerRotationFromUnity(this Vector3 unityEuler)
        {
            // Flip handness
            float axisFlipScale = -1.0f;
            Vector3 playcanvasEuler = axisFlipScale * Vector3.Scale(unityEuler, PlaycanvasCoordinateSpaceConversionScale);
            return playcanvasEuler;
        }

        public static Vector3 ToPlaycanvasScaleFromUnity(this Vector3 unityScale)
        {
            return unityScale;
        }

        public static Vector3 ToUnityPositionFromGLTF(this Vector3 gltfPosition)
        {
            // Convert from GLTF coordinate (right handed)
            // -x = right
            // y = up
            // z = forward

            var unityPosition = Vector3.Scale(gltfPosition, GLTFCoordinateSpaceConversionScale);
            return unityPosition;
        }

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

        public static Quaternion ToUnityRotationFromAttitude(this Quaternion attitudeRotation)
        {
            // Convert from Attitude sensor coordinate, returned in Right-Handed but Unity uses Left-Handed coords.
            // x = right
            // y = up
            // -z = forward
            // -w = rotation scalar
            Quaternion unityRotation =  new Quaternion(attitudeRotation.x, attitudeRotation.y, -attitudeRotation.z, -attitudeRotation.w);

            return unityRotation;
        }
        
        public static Vector3 ToUnityEulerRotationFromGLTF(this Vector3 gltfEuler)
        {
            // Convert from GLTF coordinate (right handed)
            // -x = right
            // y = up
            // z = forward

            // Flip handness
            float axisFlipScale = -1.0f;
            Vector3 unityEuler = axisFlipScale * Vector3.Scale(gltfEuler, GLTFCoordinateSpaceConversionScale);
            return unityEuler;
        }

        public static Vector3 ToUnityScaleFromGLTF(this Vector3 gltfScale)
        {
            return gltfScale;
        }

        public static Vector3 ToGLTFPositionFromUnity(this Vector3 unityPosition)
        {
            var gltfPosition = Vector3.Scale(unityPosition, GLTFCoordinateSpaceConversionScale);
            return gltfPosition;
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

        public static Vector3 ToGLTFEulerRotationFromUnity(this Vector3 unityEuler)
        {
            // Flip handness
            float axisFlipScale = -1.0f;
            Vector3 gltfEuler = axisFlipScale * Vector3.Scale(unityEuler, GLTFCoordinateSpaceConversionScale);
            return gltfEuler;
        }

        public static Vector3 ToGLTFScaleFromUnity(this Vector3 unityScale)
        {
            return unityScale;
        }

        public static Vector3 ToUnityPositionFromUnreal(this Vector3 unrealPosition)
        {
            // 1 Unreal unit = 1cm (centimeter)
            // 1 Unity unit = 1m (meter)
            // Unreal Up axis is Z and Forward axis is X
            // Unity Up axis is Y and Forward axis is Z

            ///  z              y
            ///  ^  x           ^  z
            ///  | /        ->  | /
            ///  + ---> y       + ---> x
            ///  UE             Unity
            ///                                                z
            /// (x, y, z, w) --(Rotate 90 on x)--> (x, z, -y, w) --(Rotate 90 on y)--> (-y, z, -x, w)
            /// new x = unreal y
            /// new y = unreal z
            /// new z = unreal x

            // First conversion to meters
            var unityPosition = unrealPosition * MetersInCentimeter;

            // Convert the position (axis-wise)
            unityPosition = new Vector3(unityPosition.y, unityPosition.z, unityPosition.x);

            return unityPosition;
        }

        public static Quaternion ToUnityRotationFromUnreal(this Quaternion unrealRotation)
        {
            // 1 Unreal unit = 1cm (centimeter)
            // 1 Unity unit = 1m (meter)
            // Unreal Up axis is Z and Forward axis is X
            // Unity Up axis is Y and Forward axis is Z

            ///  z              y
            ///  ^  x           ^  z
            ///  | /        ->  | /
            ///  + ---> y       + ---> x
            ///  UE             Unity
            ///                                                z
            /// (x, y, z, w) --(Rotate 90 on x)--> (x, z, -y, w) --(Rotate 90 on y)--> (-y, z, -x, w)
            /// new x = unreal y
            /// new y = unreal z
            /// new z = unreal x

            // Then convert axis' of rotation
            var unityRotation = new Quaternion(unrealRotation.y, unrealRotation.z, unrealRotation.x, unrealRotation.w);

            return unityRotation;
        }

        public static Vector3 ToUnityEulerRotationFromUnreal(this Vector3 unrealEuler)
        {
            // 1 Unreal unit = 1cm (centimeter)
            // 1 Unity unit = 1m (meter)
            // Unreal Up axis is Z and Forward axis is X
            // Unity Up axis is Y and Forward axis is Z

            ///  z              y
            ///  ^  x           ^  z
            ///  | /        ->  | /
            ///  + ---> y       + ---> x
            ///  UE             Unity
            ///                                                z
            /// (x, y, z, w) --(Rotate 90 on x)--> (x, z, -y, w) --(Rotate 90 on y)--> (-y, z, -x, w)
            /// new x = unreal y
            /// new y = unreal z
            /// new z = unreal x

            // Then convert axis' of rotation
            // UE and Unity rotation order are both front -> right -> up (XYZ for UE, ZXY for Unity), so don't have to worry about the euler rotation order here
            var unityEuler = new Vector3(unrealEuler.y, unrealEuler.z, unrealEuler.x);

            return unityEuler;
        }

        public static Vector3 ToUnityScaleFromUnreal(this Vector3 unrealScale)
        {
            // 1 Unreal unit = 1cm (centimeter)
            // 1 Unity unit = 1m (meter)
            // Unreal Up axis is Z and Forward axis is X
            // Unity Up axis is Y and Forward axis is Z

            ///  z              y
            ///  ^  x           ^  z
            ///  | /        ->  | /
            ///  + ---> y       + ---> x
            ///  UE             Unity
            ///                                                z
            /// (x, y, z, w) --(Rotate 90 on x)--> (x, z, -y, w) --(Rotate 90 on y)--> (-y, z, -x, w)
            /// new x = unreal y
            /// new y = unreal z
            /// new z = unreal x

            // Convert the scale (axis-wise) because it is not always uniform scaled
            var unityScale = new Vector3(unrealScale.y, unrealScale.z, unrealScale.x);
            return unityScale;
        }

        public static Vector3 ToUnrealPositionFromUnity(this Vector3 unityPosition)
        {
            // First conversion to centimeters
            var unrealPosition = unityPosition / MetersInCentimeter;

            // +x, +y, +z, original
            // +y, +z, +x  to unity
            // +z, +x, +y  to unreal
            // Convert the position (axis-wise)
            unrealPosition = new Vector3(unrealPosition.z, unrealPosition.x, unrealPosition.y);

            return unrealPosition;
        }

        public static Quaternion ToUnrealRotationFromUnity(this Quaternion unityRotation)
        {
            // +x, +y, +z, original
            // +y, +z, +x  to unity
            // +z, +x, +y  to unreal
            // Convert axis' of rotation
            var unrealRotation = new Quaternion(unityRotation.z, unityRotation.x, unityRotation.y, unityRotation.w);

            return unrealRotation;
        }

        public static Vector3 ToUnrealEulerRotationFromUnity(this Vector3 unityEuler)
        {
            // +x, +y, +z, original
            // +y, +z, +x  to unity
            // +z, +x, +y  to unreal
            // Convert axis' of rotation
            // UE and Unity rotation order are both front -> right -> up (XYZ for UE, ZXY for Unity), so don't have to worry about the euler rotation order here
            var unrealEuler = new Vector3(unityEuler.z, unityEuler.x, unityEuler.y);

            return unrealEuler;
        }

        public static Vector3 ToUnrealScaleFromUnity(this Vector3 unityScale)
        {
            // x, y, z original
            // y, z, x to unity
            // z, x, y to unreal
            var unrealScale = new Vector3(unityScale.z, unityScale.x, unityScale.y);
            return unrealScale;
        }
    }
}
