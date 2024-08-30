# Collections

A collection is basically a set of individual items. Those items could be strings, integers, other collections, or almost anything.

## Collections in PowerShell

Many collection classes are defined as part of the System.Collections or System.Collections.Generic namespaces. Most collection classes implement the interfaces ICollection, IComparer, IEnumerable, IList, IDictionary, and IDictionaryEnumerator and their generic equivalents.

Typical collections in PowerShell are:

- Array
- Array List
- Generic List
- Hastable (Dictionaries)

### Arrays

Arrays are collections of items of the same or different types stored in a single variable. In PowerShell, arrays are of the type [array]. They are useful for storing lists of data, such as numbers, strings, or objects. They also provide various methods for accessing, adding, and manipulating elements.

```powershell
$Array = @()
```

#### Array List

```powershell
$ArrayList = New-Object System.Collections.ArrayList

# or 

$ArrayList = [System.Collections.ArrayList]@() 
```

Once the array list is created, you can add items to it.

```powershell
$ArrayList = [System.Collections.ArrayList]@()

$Object = [PSCustomObject]@{
    GivenName = "John"
    Surname = "Smith"
}

$ArrayList.Add($Object)
```

Some of the other methods that can be used are:

- Count()
- Clear()
- Contains()
- Insert()
- Remove()
- Reverse()
- Sort()

#### Generic List

```powershell
$List = [System.Collections.Generic.List[string]]@()

$String = "String"
$List.Add($String)
```

```powershell
$List = [System.Collections.Generic.List[object]]@()

$Object = [PSCustomObject]@{
    GivenName = "John"
    Surname = "Smith"
}

$List.Add($Object)
```

Methods:

- Add()
- AddRange()
- FindAll()
- Others...

#### Performance Considerations

Adding to an standard array using "+=" is expensive and slow and the performance decrease is greater the larger the collection is. The reason for this is that arrays are fixed size and items cannot be added to it after it is created. To get around this a new array is created each time "+=" is executed with the new item added.

There is a considerable performance improvement using an array list or generic list.

```powershell
$Array = @()
$ArrayList = [System.Collections.ArrayList]@()
$GenericList = [System.Collections.Generic.List[string]]@()

$ArrayTime = Measure-Command `
    -Expression {@(0..10000).foreach({$Array += ("Number: {0}" -f $_)})}
$ArrayListTime = Measure-Command `
    -Expression {@(0..10000).foreach({$ArrayList.Add("Number: {0}" -f $_)})}
$GenaricListTime = Measure-Command `
    -Expression {@(0..10000).foreach({$GenericList.Add("Number: {0}" -f $_)})}

Write-Output ("Array: {0}ms ArrayList: {1}ms Generic List: {2}ms" -f $ArrayTime.Milliseconds, $ArrayListTime.Milliseconds, $GenaricListTime.Milliseconds)
```

### Hashtable

Hash tables are collections of key-value pairs, similar to dictionaries in other programming languages. In PowerShell, hash tables are of the type [hashtable]. Hash tables store data that can be quickly accessed via a unique key. They are useful for configuring settings, mapping data, and storing structured information.

## References

- [Building Arrays and Collections in PowerShell](https://vexx32.github.io/2020/02/15/Building-Arrays-Collections/)
- [PowerShell One-Liners: Collections, Hashtables, Arrays and Strings](https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-one-liners-collections-hashtables-arrays-and-strings/)
- [Everything you wanted to know about arrays](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.4)