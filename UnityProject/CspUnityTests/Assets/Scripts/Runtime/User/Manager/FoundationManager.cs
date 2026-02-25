// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;
using System.Threading;
using csp;
using csp.common;
using UnityEngine;

namespace Magnopus.Foundation.Unity.Runtime.User.Manager
{
    /// <summary>
    /// An API wrapper around starting and stopping the OKO Foundation.
    /// </summary>
    public class FoundationManager
    {
        /// <summary>
        /// Returns whether OKO Foundation has been started.
        /// </summary>
        public bool IsStarted { get; set; }

        private CancellationTokenSource cancellationTokenSource;
        
        /// <summary>
        /// Starts the underlying OKO Foundation systems, you should also call <see cref="StopFoundation"/> during the 
        /// consuming application's shutdown process.
        /// </summary>
        /// <param name="backendEndpoint">The endpoint url for the backend services.</param>
        /// <returns>True if foundation successfully started.</returns>
        public bool StartFoundation(string backendEndpoint, string tenant, ClientUserAgent userAgent, FeatureFlag[] cspFeatureFlags)
        {
            if (IsStarted)
            {
                Debug.LogError("Failed to initialize OKO Foundation. It is already initialized.");
                return false;
            }

            if (string.IsNullOrWhiteSpace(backendEndpoint))
            {
                Debug.LogError("Failed to initailize OKO Foundation. No backend endpoint given.");
                return false;
            }
            
            // If null CSP feature flags passed in, create an empty array for initialising CSP
            cspFeatureFlags ??= Array.Empty<FeatureFlag>();

            bool IsFoundationAlreadyInitialised = CSPFoundation.GetIsInitialised();

            if (!IsFoundationAlreadyInitialised)
            {
                Debug.Log("Initializing OKO Foundation ...");
                bool successInit = CSPFoundation.Initialise(backendEndpoint, tenant, userAgent, new FeatureFlagArray(cspFeatureFlags));
                if (!successInit)
                {
                    Debug.LogError("Failed to initialize OKO Foundation. Error is within Foundation package.");
                    return false;
                }
            }

            IsStarted = true;
            Debug.Log("Initialized OKO Foundation");

            return true;
        }

        /// <summary>
        /// Shuts down the underlying OKO Foundation systems, this should be called by consuming application
        /// during application shutdown once all of the dependant systems have been shutdown.
        /// </summary>
        /// <returns>True if the foundation was started and successfully shutdown.</returns>
        public bool StopFoundation()
        {
            if (!IsStarted)
            {
                Debug.LogError("Failed to shut down OKO Foundation. It is already shut down.");
                return false;
            }

            StopTickLoop();

            Debug.Log("Shutting down OKO Foundation ...");
            bool successShutdown = CSPFoundation.Shutdown();
            if (!successShutdown)
            {
                Debug.LogError("Failed to shut down OKO Foundation. Error is within Foundation package.");
                return false;
            }

            IsStarted = false;
            Debug.Log("Shutdown OKO Foundation");

            return true;
        }

        /// <summary>
        /// Stops the Tick loop.
        /// </summary>
        public void StopTickLoop()
        {
            cancellationTokenSource?.Cancel();
        }
    }
}