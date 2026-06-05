namespace InteropTestsXUnit;

using csp;
using csp.common;
using csp.multiplayer;

public class PropertiesTests

{
    /*
     * Test strings, which are typemapped from csp::common::String
     * (They should be typemapped from std::string, which will come after we can remove compatability shims)
     */
    [Fact]
    public void PropertyGetSet()
    {
        // EndpointURIs has value properties of service defintions,
        // providing us a decent place to test get/sets
        EndpointURIs endpointUris = new EndpointURIs();

        ServiceDefinition testMultiplayerServiceDefinition = new ServiceDefinition("http://fake-service.com", 1);

        // Test defaults (these are set in cpp constructor)
        Assert.Equal("", endpointUris.MultiplayerService.GetURI());
        Assert.Equal(0, endpointUris.MultiplayerService.GetVersion());

        endpointUris.MultiplayerService = testMultiplayerServiceDefinition;

        // This dosen't work because equality operators arn't implemented, poor form. https://github.com/MAG-ElliotMorris/connected-spaces-platform-unity/issues/4
        // Assert(endpointUris.MultiplayerService == testMultiplayerServiceDefinition);

        Assert.Equal("http://fake-service.com", endpointUris.MultiplayerService.GetURI());
        Assert.Equal(1, endpointUris.MultiplayerService.GetVersion());
    }

    [Fact]
    public void ListProperty()
    {
        using (TempMockScriptRunner mockScriptRunner = new TempMockScriptRunner())
        {
            using LogSystem logSystem = new LogSystem();
            using OfflineRealtimeEngine realtimeEngine = new OfflineRealtimeEngine(logSystem, mockScriptRunner);

            using SpaceEntity spaceEntityParent = new SpaceEntity(realtimeEngine, mockScriptRunner, logSystem);

            csp.multiplayer.SplineSpaceComponent splineSpaceComponent = new csp.multiplayer.SplineSpaceComponent(logSystem, spaceEntityParent);

            Assert.Empty(splineSpaceComponent.GetWaypoints());

            // Insert two waypoints
            splineSpaceComponent.SetWaypoints([new Vector3(1, 2, 3), new Vector3(4, 5, 6)]);

            // Verify the waypoints were set correctly
            Assert.Equal(2, splineSpaceComponent.GetWaypoints().Count);
            Assert.Equal(new Vector3(1, 2, 3), splineSpaceComponent.GetWaypoints()[0]);
            Assert.Equal(new Vector3(4, 5, 6), splineSpaceComponent.GetWaypoints()[1]);
        }
    }

    [Fact]
    public void MapProperty()
    {
        //SettingsCollection.Settings is an IDictionary<string, string>
        SettingsCollection settings = new SettingsCollection();

        // Crashes! (System.AccessViolationException: 'Attempted to read or write protected memory. This is often an indication that other memory is corrupt.')
        // Anything we can do about this to promote to a friendlier exception? Probably a general case error for setting non-nullable things to null.
        // settings.Settings = null;

        Assert.Empty(settings.Settings);

        // Add some elements
        settings.Settings.Add("key1", "value1");
        settings.Settings.Add("key2", "value2");

        Assert.Equal(2, settings.Settings.Count);

        //Set a brand new dicts.
        StringDict newDict = new StringDict();
        newDict.Add("keyNew", "valueNew");
        settings.Settings = newDict;

        Assert.Single(settings.Settings);
        Assert.Equal("keyNew", settings.Settings.First().Key);
        Assert.Equal("valueNew", settings.Settings.First().Value);

        settings.Settings.Clear();
        Assert.Empty(settings.Settings);
    }
}
