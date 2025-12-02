namespace InteropTestsXUnit;

using Csp;
using System.Drawing;
using System.Reflection;

public class OptionalTest
{
    /*
     * Test optional conversion
     * This one's a bit different, as whilst there _are_ underlying concrete Optional types,
     * the interface is expressed using C# `?` annotations. C# users won't see then.
     * 
     * A tad tricky to test in isolation as there arn't that many isolated Optional<T> interfaces
     * in CSP.
     */

    [Fact]
    public void OptionalValueType()
    {
        //Test one of the underlying types which are hidden from the C# interface
        OptionalInt optInt = new OptionalInt();
        Assert.False(optInt.HasValue());

        OptionalInt optInt2 = new OptionalInt(2);
        Assert.True(optInt2.HasValue());
    }

    [Fact]
    public void OptionalReferenceType()
    {
        //Test one of the underlying types which are hidden from the C# interface
        OptionalHotspotSequenceChangedNetworkEventData optHotspotSequenceChanged = new OptionalHotspotSequenceChangedNetworkEventData();
        Assert.False(optHotspotSequenceChanged.HasValue());

        HotspotSequenceChangedNetworkEventData data = new HotspotSequenceChangedNetworkEventData();
        OptionalHotspotSequenceChangedNetworkEventData optHotspotSequenceChanged2 = new OptionalHotspotSequenceChangedNetworkEventData(data);
        Assert.True(optHotspotSequenceChanged2.HasValue());
    }

/*
    [Fact]
    public void OptionalContainer()
    {
        //Initialise has an Optional<Array<FeatureFlag>> (FeatureFlagValueArray? in C#) interface that we can use to at least check the interface accepts the type.

        ClientUserAgent agent = new ClientUserAgent();
        FeatureFlagValueArray? OptArray = null;
        Assert.Null(OptArray);
        CSPFoundation.Initialise("", "", agent, OptArray);

        OptArray = new FeatureFlagValueArray(1);
        OptArray[0] = new FeatureFlag(EFeatureFlag.Invalid, true);
        Assert.Single(OptArray);
        Assert.NotNull(OptArray);

        OptArray = null;
        Assert.Null(OptArray);
    }
*/
}
