// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using FoundationSystems = csp.systems;
using System;
using UnityEngine;
using Random = UnityEngine.Random;
using GeoLocation = Magnopus.Foundation.Unity.Runtime.GeographicLocation.Schema.GeoLocation;

namespace Magnopus.Foundation.Unity.Tests.Integration.Config
{
    public static class ConfigSettings
    {
        public const float MinWaitBetweenEndpoints = 0.25f;
        public const int MinWaitBetweenEndpointsMilliseconds = (int)(MinWaitBetweenEndpoints * 1000);

        public static class Environment
        {
            public const string MaintenanceWindowEndpoint = "https://maintenance-windows.magnopus-dev.cloud/maintenance-windows.json";
            public const string Tenant = "OKO_TESTS";
            public const string ApplicationName = "OKO";
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

        public static class ApplicationSettings
        {
            public const string SettingsContextAuthenticated = "test_context_authenticated";
            public const string SettingsContextAnonymous = "test_context_anonymous";
            public const string SettingsContextFirstAuthenticatedKey = "test_context_key_first_authenticated";
            public const string SettingsContextFirstAuthenticatedValue = "1";
            public const string SettingsContextSecondAuthenticatedKey = "test_context_key_second_authenticated";
            public const string SettingsContextSecondAuthenticatedValue = "2";
            public const string SettingsContextFirstAnonymousKey = "test_context_key_first_anonymous";
            public const string SettingsContextFirstAnonymousValue = "3";
            public const string SettingsContextSecondAnonymousKey = "test_context_key_second_anonymous";
            public const string SettingsContextSecondAnonymousValue = "4";
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

        public static class EventTicketing
        {
            public const string VendorEventId = "234567891234";
            public const string VendorEventUri = "https://www.eventbrite.com/e/csp-test-event-tickets-234567891234";
        }
        
        public static class Poi
        {
            public static GeoLocation SuccessLocation = new()
            {
                Latitude = 34.0488222, Longitude = -118.254431
            };

            public const float SuccessRadius = 5;

            public const FoundationSystems.EPointOfInterestType SuccessPoiType = FoundationSystems.EPointOfInterestType.DEFAULT;
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
            for (int i=0; i<digits; ++i)
            {
                float value = Random.Range(0.0f, 10.0f);
                int number = (int)Math.Min(Math.Floor(value),9);
                id = id + number;
            }

            return id;
        }
    }
}