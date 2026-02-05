namespace InteropTestsXUnit;

using csp.common;
using csp.systems;
using Xunit.Sdk;

public class ArrayTests
{
    /* We use FeatureFlagValueArray to test this, just cause it was the first one exposed.
     * The point of this test is to test the Array typemap from csp::common::Array -> C# IReadOnlyList
     * This whole test suite should go away once we migrate away from the CSP common types, this
     * is sort of redundant work just to support a migration :(
     * 
     * This sort of Array type as an interface type is a bit silly anyway in my opinion.
     * We should just use vectors (ie, Lists) everywhere. 
     * If we want an _actual_ array for some reason, language arrays exists.
     */

    static SpaceUserRole[] MakeManySpaceUserRoles()
    {
        // There's only 4 potential values, use them all.
        SpaceUserRole[] array = new SpaceUserRole[4];
        array[0] = SpaceUserRole.Invalid;
        array[1] = SpaceUserRole.User;
        array[2] = SpaceUserRole.Owner;
        array[3] = SpaceUserRole.Moderator;
        return array;
    }

    static ReplicatedValue[] MakeManyReplicatedValues()
    {
        var array = new ReplicatedValue[4];
        array[0] = new ReplicatedValue(1.0f);
        array[1] = new ReplicatedValue(1);
        array[2] = new ReplicatedValue("One");
        array[3] = new ReplicatedValue(true);
        return array;
    }


    [Fact]
    public void NewArrayIsEmpty()
    {
        var array = new SpaceUserRoleValueArray();
        Assert.Equal(0, array.Count);
        Assert.Empty(array);
    }

    [Fact]
    public void ArrayIsInSequence()
    {
        var items = MakeManySpaceUserRoles();
        var array = new SpaceUserRoleValueArray(items);
        Assert.Equal(4, array.Count);

        Assert.Equal(SpaceUserRole.Invalid, array[0]);
        Assert.Equal(SpaceUserRole.User, array[1]);
        Assert.Equal(SpaceUserRole.Owner, array[2]);
        Assert.Equal(SpaceUserRole.Moderator, array[3]);
    }

    [Fact]
    public void NullConstructionThrows()
    {
        Assert.Throws<ArgumentNullException>(() => new SpaceUserRoleValueArray(null));
    }

    [Fact]
    public void ArrayCount()
    {
        var items = MakeManySpaceUserRoles();
        var array = new SpaceUserRoleValueArray(items);
        Assert.Equal(4, array.Count);
    }

    [Fact]
    public void GetSetAccessOperatorOnValueArray()
    {
        var items = MakeManySpaceUserRoles();
        var array = new SpaceUserRoleValueArray(items);
        Assert.Equal(4, array.Count);

        var gotInvalid = array[0];
        Assert.Equal(SpaceUserRole.Invalid, gotInvalid);

        array[0] = SpaceUserRole.User;

        // We're a value array, the original should not have updated
        Assert.Equal(SpaceUserRole.Invalid, gotInvalid);
        Assert.Equal(SpaceUserRole.User, array[0]);
    }

    [Fact]
    public void CopyToArrayHappyPath()
    {
        var items = MakeManyReplicatedValues();
        var array = new ReplicatedValueArray(items);
        Assert.Equal(4, array.Count);

        ReplicatedValue[] arrayFromToArray = array.DeepCopyToArray();
        Assert.Equal(arrayFromToArray.Length, array.Count);
        Assert.Equal(arrayFromToArray[0], array[0]);
        Assert.Equal(arrayFromToArray[1], array[1]);
        Assert.Equal(arrayFromToArray[2], array[2]);
        Assert.Equal(arrayFromToArray[3], array[3]);

        // Assert that the underlying pointers are different, as we should have made new ApplicationSettings in deep copy.
        Assert.NotEqual(ReplicatedValue.getCPtr(array[0]), ReplicatedValue.getCPtr(arrayFromToArray[0]));
    }

    [Fact]
    public void CopyToListHappyPath()
    {
        var items = MakeManyReplicatedValues();
        var array = new ReplicatedValueArray(items);
        Assert.Equal(4, array.Count);

        List<ReplicatedValue> listFromToArray = array.DeepCopyToList();
        Assert.Equal(listFromToArray.Count, array.Count);
        Assert.Equal(listFromToArray[0], array[0]);
        Assert.Equal(listFromToArray[1], array[1]);
        Assert.Equal(listFromToArray[2], array[2]);
        Assert.Equal(listFromToArray[3], array[3]);

        // Assert that the underlying pointers are different, as we should have made new ApplicationSettings in deep copy.
        Assert.NotEqual(ReplicatedValue.getCPtr(array[0]), ReplicatedValue.getCPtr(listFromToArray[0]));
    }

    [Fact]
    public void CopyTo()
    {
        /* 
         * We test the most explicit `CopyTo` method here, as
         * all the other overloads defer to it
         */
        var items = MakeManySpaceUserRoles();
        var array = new SpaceUserRoleValueArray(items);
        Assert.Equal(4, array.Count);

        SpaceUserRole[] newArray = new SpaceUserRole[4];
        array.CopyTo(0, newArray, 0, 4);

        Assert.Equal(newArray.Length, array.Count);
        Assert.Equal(newArray[0], array[0]);
        Assert.Equal(newArray[1], array[1]);
        Assert.Equal(newArray[2], array[2]);
        Assert.Equal(newArray[3], array[3]);
    }

    [Fact]
    public void PartialCopyTo()
    {
        /* 
         * We test the most explicit `CopyTo` method here, as
         * all the other overloads defer to it
         */
        var items = MakeManySpaceUserRoles();
        var array = new SpaceUserRoleValueArray(items);
        Assert.Equal(4, array.Count);

        SpaceUserRole[] newArray = new SpaceUserRole[10];

        // Insert [0](Invalid) and [1](User) into index 7 and 8
        array.CopyTo(0, newArray, 7, 2);

        Assert.Equal(10, newArray.Length);
        Assert.Equal(SpaceUserRole.Owner, newArray[0]); //Owner is default
        Assert.Equal(SpaceUserRole.Invalid, newArray[7]);
        Assert.Equal(SpaceUserRole.User, newArray[8]);
        Assert.Equal(SpaceUserRole.Owner, newArray[9]); //Owner is default
    }

    [Fact]
    public void CopyToArrayExceptions()
    {
        var items = MakeManySpaceUserRoles();
        var array = new SpaceUserRoleValueArray(items);
        Assert.Equal(4, array.Count);

        var newArray = new SpaceUserRole[10];

        // Null out array
        Assert.Throws<ArgumentNullException>(() => array.CopyTo(0, null, 0, 0));
        //SrcStartIndex less than zero
        Assert.Throws<ArgumentOutOfRangeException>(() => array.CopyTo(-1, newArray, 0, 0));
        //outStartIndex less than zero
        Assert.Throws<ArgumentOutOfRangeException>(() => array.CopyTo(0, newArray, -1, 0));
        //count to copy less than zero
        Assert.Throws<ArgumentOutOfRangeException>(() => array.CopyTo(0, newArray, 0, -1));
        //Too many arguments to copy
        Assert.Throws<ArgumentException>(() => array.CopyTo(0, newArray, 0, 11));
    }

    [Fact]
    public void LinqSmokeTest()
    {
        /*
         * Just test some Linq to make sure it's available
         */

        var items = MakeManySpaceUserRoles();
        var array = new SpaceUserRoleValueArray(items);
        Assert.Equal(4, array.Count);

        var SelectOneAndTwoWithWhere = array.Where(x => x == SpaceUserRole.User || x == SpaceUserRole.Moderator);
        Assert.Equal(SpaceUserRole.User, SelectOneAndTwoWithWhere.First());
        Assert.Equal(SpaceUserRole.Moderator, SelectOneAndTwoWithWhere.Last());
    }

    [Fact]
    public void EnumeratorTest()
    {
        var items = MakeManySpaceUserRoles();
        var array = new SpaceUserRoleValueArray(items);
        Assert.Equal(4, array.Count);

        HashSet<SpaceUserRole> foundRoles = new HashSet<SpaceUserRole>();

        using (var e = array.GetEnumerator())
        {
            int i = 0;
            while (e.MoveNext())
            {
                foundRoles.Add(e.Current);
                i++;
            }
            Assert.Equal(4, i); // Verify we enumerated all 4 items
            Assert.Contains(SpaceUserRole.Invalid, foundRoles);
            Assert.Contains(SpaceUserRole.User, foundRoles);
            Assert.Contains(SpaceUserRole.Owner, foundRoles);
            Assert.Contains(SpaceUserRole.Moderator, foundRoles);
        }
    }

    [Fact]
    public void Reverse()
    {
        var items = MakeManySpaceUserRoles();
        var array = new SpaceUserRoleValueArray(items);
        Assert.Equal(SpaceUserRole.Invalid, array[0]);
        Assert.Equal(SpaceUserRole.User, array[1]);
        Assert.Equal(SpaceUserRole.Owner, array[2]);
        Assert.Equal(SpaceUserRole.Moderator, array[3]);

        array.Reverse();

        Assert.Equal(SpaceUserRole.Moderator, array[0]);
        Assert.Equal(SpaceUserRole.Owner, array[1]);
        Assert.Equal(SpaceUserRole.User, array[2]);
        Assert.Equal(SpaceUserRole.Invalid, array[3]);
    }

    [Fact]
    public void ReverseSubset()
    {
        var items = MakeManySpaceUserRoles();
        var array = new SpaceUserRoleValueArray(items);
        Assert.Equal(SpaceUserRole.Invalid, array[0]);
        Assert.Equal(SpaceUserRole.User, array[1]);
        Assert.Equal(SpaceUserRole.Owner, array[2]);
        Assert.Equal(SpaceUserRole.Moderator, array[3]);

        array.Reverse(2, 2);

        Assert.Equal(SpaceUserRole.Invalid, array[0]);
        Assert.Equal(SpaceUserRole.User, array[1]);
        Assert.Equal(SpaceUserRole.Moderator, array[2]);
        Assert.Equal(SpaceUserRole.Owner, array[3]);
    }

    [Fact]
    public void Fill()
    {
        SpaceUserRoleValueArray array = new SpaceUserRoleValueArray(10);
        array.Fill(SpaceUserRole.User);

        Assert.Equal(10, array.Count);
        for (int i = 0; i < array.Count; i++)
        {
            Assert.Equal(SpaceUserRole.User, array[i]);
        }
    }

}
