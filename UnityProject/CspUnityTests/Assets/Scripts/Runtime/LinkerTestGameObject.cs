using csp;
using UnityEngine;

namespace Runtime
{
    public class LinkerTestGameObject : MonoBehaviour
    {
        private void Awake()
        {
            ClientUserAgent userAgent = new ClientUserAgent();
            userAgent.CSPVersion = "Unknown";
            userAgent.ClientOS = "Unknown";
            userAgent.ClientSKU = "CSharp-Interop";
            userAgent.ClientVersion = "Unknown";
            userAgent.ClientEnvironment = "ODev";
            userAgent.CHSEnvironment = "oDev";
            bool result = CSPFoundation.Initialise("https://ogs-internal.magnopus-dev.cloud", "OKO_TESTS", userAgent, null);
            Debug.Log("CSPFoundation.Initialise result: " + result);
        }

        private void OnDestroy()
        {
            bool result = CSPFoundation.Shutdown();
            Debug.Log("CSPFoundation.Shutdown result: " + result);
        }
    }
}