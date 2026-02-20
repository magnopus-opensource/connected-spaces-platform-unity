namespace InteropTestsXUnit;

using csp.web;
using System.Runtime.InteropServices;

public class EnumTests
{

    /*
     * Test enums as they come out of the SWIG generator atop CSP
     */

    [Fact]
    public void TestEnumUnderlyingType()
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
        {
            Assert.Equal(1,2);
        }
        
        Type enumType = Enum.GetUnderlyingType(typeof(EResponseCodes));
        Assert.Equal("UInt16", enumType.Name);
    }


    [Fact]
    public void TestEnumAssignedValues()
    {
        // Check that the assigned values in the cpp source code make it through to csharp
        EResponseCodes code = EResponseCodes.ResponseGone; //This is 410, set in the cpp
        Assert.Equal(410, (ushort)code);
    }
}
