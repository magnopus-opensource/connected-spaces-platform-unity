namespace InteropTestsXUnit;

using csp.common;
using System;
using System.Diagnostics;

public class ValueEquatableTest
{
    /*
     * Test that Equals, ==, and Hash works as expected for types declared as value types
     */
    [Fact]
    public void IsEquatableType()
    {
        /* Check that types marked as equatable inherit the interface 
           Don't need to do every type, just check the typemapping is working */

        Vector2 EquatableVec2 = new Vector2(1.0f, 2.0f);
        Assert.True(EquatableVec2 is IEquatable<Vector2>);

        Vector3 EquatableVec3 = new Vector3(1.0f, 2.0f, 3.0f);
        Assert.True(EquatableVec3 is IEquatable<Vector3>);

        Vector4 EquatableVec4 = new Vector4(1.0f, 2.0f, 3.0f, 4.0f);
        Assert.True(EquatableVec4 is IEquatable<Vector4>);
    }

    [Fact]
    public void EqualsReflexiveSameInstance()
    {
        var Vec = new Vector2(1.0f, 2.0f);

        Assert.True(Vec.Equals(Vec));
        Assert.True(Vec == Vec);
    }

    [Fact]
    public void EqualsSymmetric()
    {
        var Vec1 = new Vector2(1.0f, 2.0f);
        var Vec2 = new Vector2(1.0f, 2.0f);

        Assert.Equal(Vec1.Equals(Vec2), Vec2.Equals(Vec1));
        Assert.Equal(Vec1 == Vec2, Vec2 == Vec1);
    }

    [Fact]
    public void EqualsTransitive()
    {
        var Vec1 = new Vector2(1.0f, 2.0f);
        var Vec2 = new Vector2(1.0f, 2.0f);
        var Vec3 = new Vector2(1.0f, 2.0f);

        Assert.True(Vec1.Equals(Vec2));
        Assert.True(Vec2.Equals(Vec3));
        Assert.True(Vec1.Equals(Vec3));

        Assert.True(Vec1 == Vec2);
        Assert.True(Vec2 == Vec3);
        Assert.True(Vec1 == Vec3);
    }

    [Fact]
    public void EqualsWithNull()
    {
        var Vec1 = new Vector2(1.0f, 2.0f);
        Assert.False(Vec1.Equals(null));
    }

    [Fact]
    public void NotEqual()
    {
        var Vec1 = new Vector2(1.0f, 2.0f);
        var Vec2 = new Vector2(2.0f, 2.0f);

        Assert.False(Vec1.Equals(Vec2));
        Assert.False(Vec1 == Vec2);
        Assert.True(Vec1 != Vec2);
    }

    [Fact]
    public void EqualHashCodes()
    {
        var Vec1 = new Vector2(1.0f, 2.0f);
        var Vec2 = new Vector2(1.0f, 2.0f);

        Assert.True(Vec1 == Vec2);
        Assert.Equal(Vec1.GetHashCode(), Vec2.GetHashCode());
    }

    [Fact]
    public void NotEqualHashCodes()
    {
        var Vec1 = new Vector2(1.0f, 2.0f);
        var Vec2 = new Vector2(1.0f, 3.0f);

        Assert.True(Vec1 != Vec2);
        Assert.NotEqual(Vec1.GetHashCode(), Vec2.GetHashCode());
    }

    [Fact]
    public void DeferToTypedEquals()
    {
        //Boxed comparison should defer to the typed one and do value comparison
        var Vec1 = new Vector2(1.0f, 2.0f);
        var Vec2 = new Vector2(1.0f, 2.0f);

        Assert.True(Vec1.Equals((object)Vec2));
    }
}
