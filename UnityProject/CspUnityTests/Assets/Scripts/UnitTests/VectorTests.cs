// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Vector3 = Csp.Vector3;
using NUnit.Framework;

namespace Magnopus.Csp.Unity.Tests
{
    public class VectorTests
    {
        [Test]
        public void CreateVector()
        {
            const float x = 1.0f;
            const float y = 2.0f;
            const float z = 3.0f;

            var vector = new Vector3(x, y, z);

            Assert.NotNull(vector);
            Assert.IsTrue(vector.x == x);
            Assert.IsTrue(vector.y == y);
            Assert.IsTrue(vector.z == z);
        }

        [Test]
        public void CspVectorToUnityVectorConversion()
        {
            var cspVector = new Vector3(1.0f, 2.0f, 3.0f);
            var unityVector = cspVector.ToUnity();

            Assert.AreEqual(1.0f, unityVector.x, "X component conversion is incorrect.");
            Assert.AreEqual(2.0f, unityVector.y, "Y component conversion is incorrect.");
            Assert.AreEqual(3.0f, unityVector.z, "Z component conversion is incorrect.");
        }
        
        [Test]
        public void UnityVectorToFoundationVectorConversion()
        {
            var unityVector = new UnityEngine.Vector3(1.0f, 2.0f, 3.0f);
            var cspVector = new Vector3(unityVector);

            Assert.AreEqual(1.0f, cspVector.x, "X component conversion is incorrect.");
            Assert.AreEqual(2.0f, cspVector.y, "Y component conversion is incorrect.");
            Assert.AreEqual(3.0f, cspVector.z, "Z component conversion is incorrect.");
        }
    }
}