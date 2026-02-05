namespace InteropTestsXUnit;

using csp.common;
using Xunit.Sdk;

public class ListTests
{
    /* We use ApplicationSettingsValueList to test this, just cause it was the first one exposed.
     * The point of this test is to test the List typemap from csp::common::List -> C# IEnumerable
     * This whole test suite should go away once we migrate away from the CSP common types, this
     * is sort of redundant work just to support a migration :(
     */

    static ApplicationSettings[] MakeManyApplicationSettings(int num)
    {
        ApplicationSettings[] list = new ApplicationSettings[num];
        for (int i = 0; i < num; ++i)
        {
            ApplicationSettings setting = new ApplicationSettings();
            setting.ApplicationName = i.ToString(); //Just so there's some unique data to identify the thing with.
            list[i] = setting;
        }
        return list;
    }

    [Fact]
    public void NewListIsEmptyAndWriteable()
    {
        var list = new ApplicationSettingsValueList();
        Assert.False(list.IsReadOnly);
        Assert.Equal(0, list.Count);
        Assert.Empty(list);
    }

    [Fact]
    public void ListIsInSequence()
    {
        var items = MakeManyApplicationSettings(5);
        var list = new ApplicationSettingsValueList(items);
        Assert.Equal(5, list.Count);

        int i = 0;
        foreach (ApplicationSettings setting in list)
        {
            Assert.Equal(setting.ApplicationName, i.ToString());
            i++;
        }
    }

    [Fact]
    public void NullConstructionThrows()
    {
        Assert.Throws<ArgumentNullException>(() => new ApplicationSettingsValueList(null));
    }

    [Fact]
    public void AddAppends()
    {
        var list = new ApplicationSettingsValueList();

        ApplicationSettings one = new ApplicationSettings();
        one.ApplicationName = "One";
        ApplicationSettings two = new ApplicationSettings();
        two.ApplicationName = "Two";

        list.Add(one);
        Assert.Equal("One", list[0].ApplicationName);

        list.Add(two);
        Assert.Equal("One", list[0].ApplicationName);
        Assert.Equal("Two", list[1].ApplicationName);
    }

    [Fact]
    public void InsertAddsBefore()
    {
        var list = new ApplicationSettingsValueList();
        ApplicationSettings one = new ApplicationSettings();
        one.ApplicationName = "One";
        ApplicationSettings three = new ApplicationSettings();
        three.ApplicationName = "Three";

        list.Add(one);
        list.Add(three);

        Assert.Equal("One", list[0].ApplicationName);
        Assert.Equal("Three", list[1].ApplicationName);

        ApplicationSettings two = new ApplicationSettings();
        two.ApplicationName = "Two";

        list.Insert(1, two);

        Assert.Equal("One", list[0].ApplicationName);
        Assert.Equal("Two", list[1].ApplicationName);
        Assert.Equal("Three", list[2].ApplicationName);

        ApplicationSettings onePointFive = new ApplicationSettings();
        onePointFive.ApplicationName = "OnePointFive";

        list.Insert(1, onePointFive);

        Assert.Equal("One", list[0].ApplicationName);
        Assert.Equal("OnePointFive", list[1].ApplicationName);
        Assert.Equal("Two", list[2].ApplicationName);
        Assert.Equal("Three", list[3].ApplicationName);
    }

    [Fact]
    public void GetSetAccessOperatorOnValueList()
    {
        /*
         * I'll put an explanation here because I've gotta put one somewhere.
         * Think about how C# and Cpp handle reference/pointer/value semantics when it comes to containers.
         * In C#, whether an object is "connected" to another is decided at the type level,
         * it's about whether you declare something as `class` or `struct`.
         * If you declare a List<StructType>, then you'll get disconnected value gets and sets,
         * but List<ClassType> is "connected", you get reference semantics.
         * It's not like this in Cpp, the declaration of your types have no bearing on whether they
         * are handled in a value/reference manner, that's to do with how you declare you container.
         * For example:
         *  - std::vector<Type> is a value container
         *  - std::vector<Type*> is a pointer/reference etc container.
         *  
         *  This is, when you think about it, a fundamental incompatibility between the languages.
         *  So, in an attempt to make this incompatibility not _infuriating_ to C# developers,
         *  we'll be naming the containers that we typemap after whether they are declared as a value
         *  or a pointer. 
         *  This isn't ideal, as a C# developer might look at the type, see it's a `Class` and presume
         *  that even inside `ApplicationsSettingsValueList` it's going to behave like they expect,
         *  but I think this is the minimum reasonable disruption to normal operations we can achieve
         *  when mapping from general-purpose native code.
         */

        var list = new ApplicationSettingsValueList();
        ApplicationSettings one = new ApplicationSettings();
        one.ApplicationName = "One";
        list.Add(one);

        var gotOne = list[0];
        Assert.Equal(one.ApplicationName, gotOne.ApplicationName);

        list[0].ApplicationName = "Two";

        // We're a value list, the original should not have updated
        Assert.Equal("One", one.ApplicationName);
        Assert.Equal("Two", list[0].ApplicationName);
    }

    [Fact]
    public void EmptyListIsEmpty()
    {
        var list = new ApplicationSettingsValueList();
        Assert.True(list.IsEmpty);

        list.Add(new ApplicationSettings());
        Assert.False(list.IsEmpty);
    }

    [Fact]
    public void ListCount()
    {
        var list = new ApplicationSettingsValueList();
        Assert.Equal(0, list.Count);

        list.Add(new ApplicationSettings());
        list.Add(new ApplicationSettings());
        list.Add(new ApplicationSettings());

        Assert.Equal(3, list.Count);
    }

    [Fact]
    public void CopyToArrayHappyPath()
    {
        var list = new ApplicationSettingsValueList();

        ApplicationSettings one = new ApplicationSettings();
        one.ApplicationName = "One";
        ApplicationSettings two = new ApplicationSettings();
        two.ApplicationName = "Two";

        list.Add(one);
        list.Add(two);

        ApplicationSettings[] arrayFromToArray = list.DeepCopyToArray();
        Assert.Equal(arrayFromToArray.Length, list.Count);
        Assert.Equal(arrayFromToArray[0].ApplicationName, list[0].ApplicationName);
        Assert.Equal(arrayFromToArray[1].ApplicationName, list[1].ApplicationName);

        // Assert that the underlying pointers are different, as we should have made new ApplicationSettings in deep copy.
        Assert.NotEqual(ApplicationSettings.getCPtr(list[0]), ApplicationSettings.getCPtr(arrayFromToArray[0]));
    }

    [Fact]
    public void CopyToListHappyPath()
    {
        var list = new ApplicationSettingsValueList();

        ApplicationSettings one = new ApplicationSettings();
        one.ApplicationName = "One";
        ApplicationSettings two = new ApplicationSettings();
        two.ApplicationName = "Two";

        list.Add(one);
        list.Add(two);

        List<ApplicationSettings> listFromToList = list.DeepCopyToList();
        Assert.Equal(listFromToList.Count, list.Count);
        Assert.Equal(listFromToList[0].ApplicationName, list[0].ApplicationName);
        Assert.Equal(listFromToList[1].ApplicationName, list[1].ApplicationName);

        // Assert that the underlying pointers are different, as we should have made new ApplicationSettings in deep copy.
        Assert.NotEqual(ApplicationSettings.getCPtr(list[0]), ApplicationSettings.getCPtr(listFromToList[0]));
    }


    [Fact]
    public void CopyTo()
    {
        /* 
         * We test the most explicit `CopyTo` method here, as
         * all the other overloads defer to it
         */

        var list = new ApplicationSettingsValueList();

        ApplicationSettings one = new ApplicationSettings();
        one.ApplicationName = "One";
        ApplicationSettings two = new ApplicationSettings();
        two.ApplicationName = "Two";
        ApplicationSettings three = new ApplicationSettings();
        two.ApplicationName = "Three";

        list.Add(one);
        list.Add(two);
        list.Add(three);

        ApplicationSettings[] newArray = new ApplicationSettings[3];
        list.CopyTo(0, newArray, 0, 3);

        Assert.Equal(newArray.Length, list.Count);
        Assert.Equal(newArray[0].ApplicationName, list[0].ApplicationName);
        Assert.Equal(newArray[1].ApplicationName, list[1].ApplicationName);
        Assert.Equal(newArray[2].ApplicationName, list[2].ApplicationName);
    }

    [Fact]
    public void PartialCopyTo()
    {
        /* 
         * We test the most explicit `CopyTo` method here, as
         * all the other overloads defer to it
         */

        var items = MakeManyApplicationSettings(5);
        var list = new ApplicationSettingsValueList(items);
        Assert.Equal(5, list.Count);

        ApplicationSettings[] newArray = new ApplicationSettings[10];

        // Insert "2", "3" and "4" into indices 7,8,9
        list.CopyTo(2, newArray, 7, 3);

        Assert.Equal(10, newArray.Length);
        Assert.Null(newArray[0]);
        Assert.NotNull(newArray[7]);
        Assert.NotNull(newArray[8]);
        Assert.NotNull(newArray[9]);

        Assert.Equal(newArray[7].ApplicationName, list[2].ApplicationName);
        Assert.Equal(newArray[8].ApplicationName, list[3].ApplicationName);
        Assert.Equal(newArray[9].ApplicationName, list[4].ApplicationName);
    }

    [Fact]
    public void CopyToArrayExceptions()
    {
        var items = MakeManyApplicationSettings(5);
        var list = new ApplicationSettingsValueList(items);

        var newArray = new ApplicationSettings[10];

        // Null out array
        Assert.Throws<ArgumentNullException>(() => list.CopyTo(0, null, 0, 0));
        //SrcStartIndex less than zero
        Assert.Throws<ArgumentOutOfRangeException>(() => list.CopyTo(-1, newArray, 0, 0));
        //outStartIndex less than zero
        Assert.Throws<ArgumentOutOfRangeException>(() => list.CopyTo(0, newArray, -1, 0));
        //count to copy less than zero
        Assert.Throws<ArgumentOutOfRangeException>(() => list.CopyTo(0, newArray, 0, -1));
        //Too many arguments to copy
        Assert.Throws<ArgumentException>(() => list.CopyTo(0, newArray, 0, 11));
    }

    [Fact]
    public void LinqSmokeTest()
    {
        /*
         * Just test some Linq to make sure it's available
         */

        var items = MakeManyApplicationSettings(5);
        var list = new ApplicationSettingsValueList(items);

        var SelectOneAndTwoWithWhere = list.Where(x => x.ApplicationName == "1" || x.ApplicationName == "2");
        Assert.Equal("1", SelectOneAndTwoWithWhere.First().ApplicationName);
        Assert.Equal("2", SelectOneAndTwoWithWhere.Last().ApplicationName);
    }

    [Fact]
    public void EnumeratorTest()
    {
        var items = MakeManyApplicationSettings(5);
        var list = new ApplicationSettingsValueList(items);
        using (var e = list.GetEnumerator())
        {
            int i = 0;
            while (e.MoveNext())
            {
                Assert.Equal(i.ToString(), e.Current.ApplicationName);
                i++;
            }
            Assert.Equal(5, i); // Verify we enumerated all 5 items
        }
    }

}
