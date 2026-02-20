// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Foundation.Unity.Runtime.User.Schema;
using System;
using System.Threading;
using System.Threading.Tasks;
using csp;
using csp.common;
using Magnopus.Foundation.Unity.Runtime.User.Extensions;
using UnityEngine;
using CancellationToken = System.Threading.CancellationToken;

namespace Magnopus.Foundation.Unity.Runtime.User.Manager
{
    /// <summary>
    /// An API wrapper around starting and stopping the OKO Foundation.
    /// </summary>
    public class FoundationManager
    {
        private const int TickDelayMilli = 1000 / 60;

        public event Action<string> TickError;

        /// <summary>
        /// Returns whether OKO Foundation has been started.
        /// </summary>
        public bool IsStarted { get; set; }

        private string currentBackendEndpoint;

        private CancellationTokenSource cancellationTokenSource;
        private bool shouldRetryTick = false;
        private int maxRetries;
        private int maxTickDelayMilli;
        private bool tickRetryFailed = false;

        public FoundationManager()
        {
            // Note: not including logger for testing purposes.
        }

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

            currentBackendEndpoint = backendEndpoint;

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
        /// Attempts to call Tick in a series of retries. Returns when it finishes from either failing all retries or succeeding one of them.
        /// </summary>
        /// <param name="maxRetries"> Max attempts at calling Tick </param>
        /// <param name="maxTickDelayMilli"> The Max millisecond delay between retries. Retry delay starts normally between retries and exponentially increases up to this max. </param>
        /// <returns> True if it succeeded, False if it failed all retries </returns>
        public async Task<bool> RetryTick(int maxRetries, int maxTickDelayMilli)
        {
            Debug.Log($"Starting retries for Tick. Max Retries: {maxRetries}");
            shouldRetryTick = true;
            tickRetryFailed = false;
            this.maxRetries = maxRetries;

            if (maxTickDelayMilli < TickDelayMilli)
            {
                maxTickDelayMilli = TickDelayMilli;
            }
            this.maxTickDelayMilli = maxTickDelayMilli;
            StartTickLoop();

            while (shouldRetryTick)
            {
                await Task.Delay(TickDelayMilli);
            }

            return !tickRetryFailed;
        }

        /// <summary>
        /// Starts a cancellable forever-loop to call Tick with a specified delay.
        /// Tick is necessary for multiplayer. It allows sending object messages and patches.
        /// It can also fail / throw an exception, so be sure to listen for the <seealso cref="TickError"/> event.
        /// </summary>
        public void StartTickLoop()
        {
            cancellationTokenSource?.Cancel();
            cancellationTokenSource?.Dispose();
            cancellationTokenSource = new CancellationTokenSource();

            Tick(cancellationTokenSource.Token);
        }

        /// <summary>
        /// Stops the Tick loop.
        /// </summary>
        public void StopTickLoop()
        {
            cancellationTokenSource?.Cancel();
        }

        /// <summary>
        /// Create an <seealso cref="EndpointUris"/> object containing URIs to various services needed by CSP.
        /// </summary>
        /// <param name="endpointRootUri"></param>
        /// <returns> <seealso cref="EndpointUris"/> class with deduced endpoint URIs. </returns>
        public EndpointURIs CreateEndpointsFromRoot(string endpointRootUri)
        {
            return CSPFoundation.CreateEndpointsFromRoot(endpointRootUri);
        }

        private async void Tick(CancellationToken cancellationToken)
        {
            int currRetries = 0;
            while (true)
            {
                if (cancellationToken.IsCancellationRequested)
                {
                    cancellationTokenSource.Dispose();
                    cancellationTokenSource = null;
                    return;
                }

                try
                {
                    CSPFoundation.Tick();

                    if (shouldRetryTick)
                    {
                        shouldRetryTick = false;
                        Debug.Log($"Tick has executed successfully after {currRetries} retries.");
                    }
                }
                catch (Exception ex)
                {
                    Debug.LogError(ex.ToString());

                    if (shouldRetryTick)
                    {
                        if (currRetries < maxRetries)
                        {
                            currRetries++;

                            // Every retry, wait longer than last time exponentially, also clamped so we don't wait forever
                            int waitTime = Math.Min(TickDelayMilli * currRetries * currRetries, maxTickDelayMilli);
                            // Incrementally call Dealy so we can check the cancellation token inbetween waiting
                            int increments = waitTime / TickDelayMilli;
                            for (int i = 0; i < increments; i++)
                            {
                                await Task.Delay(TickDelayMilli);

                                if (cancellationToken.IsCancellationRequested)
                                {
                                    cancellationTokenSource.Dispose();
                                    cancellationTokenSource = null;
                                    return;
                                }
                            }
                        }
                        else
                        {
                            shouldRetryTick = false;
                            tickRetryFailed = true;
                            Debug.Log($"Tick has exhausted all retries and failed.");
                            return;
                        }
                    }
                    else
                    {
                        TickError?.Invoke(ex.Message);
                        return;
                    }
                }

                await Task.Delay(TickDelayMilli);
            }
        }
    }
}