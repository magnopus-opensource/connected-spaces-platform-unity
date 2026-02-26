// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;
using UnityEngine;
using Random = UnityEngine.Random;

namespace Magnopus.Foundation.Unity.Tests.Integration.Config
{
    public static class ConfigSettings
    {
        public const float MinWaitBetweenEndpoints = 0.25f;
        public const int MinWaitBetweenEndpointsMilliseconds = (int)(MinWaitBetweenEndpoints * 1000);

        public static class Environment
        {
            public const string Tenant = "OKO_TESTS";
            public const string TestResultsFilePath = "";

            private static string endpoint;
            
            public static string Endpoint
            {
                get
                {
                    if (string.IsNullOrWhiteSpace(endpoint))
                    {
                        var endPointConfig = Resources.Load<TextAsset>("EndpointConfig");
                        if (endPointConfig != null)
                        {
                            endpoint = endPointConfig.text;
                        }
                    }

                    return endpoint;
                }
            }
        }

        public static class PrimaryUser
        {
            public static string BaseUsername = "TestUserA";
            public const string DisplayName1 = "TestUser 1";
            public const string DisplayName2 = "TestUser 2";
        }

        public static class SecondaryUser
        {
            public static string BaseUsername = "TestUserB";
            public const string DisplayName1 = "TestUserB 1";
        }
        
        private static string eventBriteID = "";
        public static string GetNewEventBriteID()
        {
            eventBriteID = GenerateEventBriteID();
            return eventBriteID;
        }
        
        public static string GetEventBriteURL()
        {
            return EventBriteURLFromID(eventBriteID);
        }
        
        private static string EventBriteURLFromID(string id)
        {
            return $"https://www.eventbrite.com/e/csp-test-event-tickets-{id}";
        }
        
        private static string GenerateEventBriteID()
        {
            string id = "";
            int digits = 12;
            
            for (int i = 0; i < digits; ++i)
            {
                float value = Random.Range(0.0f, 10.0f);
                int number = (int)Math.Min(Math.Floor(value),9);
                id = id + number;
            }

            return id;
        }
    }
}