# Data Types

## String

## Character

## Byte

## Numeric Type

A numeric type is one that allows representation of integer or fractional values, and that supports arithmetic operations on those values. The set of numerical types includes the integer and real number types, but does not include bool or char.

### Integer

Other integer types are SByte, Int16, UInt16, UInt32, and UInt64, all in the namespace System.

### Long

### Bool

### Decimal

### Single

### Double

## DateTime

## XML

## Collections

Many collection classes are defined as part of the System.Collections or System.Collections.Generic namespaces. Most collection classes implement the interfaces ICollection, IComparer, IEnumerable, IList, IDictionary, and IDictionaryEnumerator and their generic equivalents.

### Arrays

#### Array List

#### Generic List

#### Performance Considerations

```console
PS C:\> $ArrayList = [System.Collections.ArrayList]@()
PS C:\> $Array = @()
PS C:\> Measure-Command -Expression {@(0..10000).foreach({$ArrayList.Add("Number: {0}" -f $_)})} | Select-Object Milliseconds

Milliseconds
------------
          43

PS C:\> Measure-Command -Expression {@(0..10000).foreach({$Array += ("Number: {0}" -f $_)})} | Select-Object Milliseconds

Milliseconds
------------
         915
```

### Hashtable

## Type Excellerators

The most common DataTypes (type accelerators) used in PowerShell are listed below.

|Excellerator | Description                                   |
|-------------|-----------------------------------------------|
| [string]    | Fixed-length string of Unicode characters     |
| [char]      | A Unicode 16-bit character                    |
| [byte]      | An 8-bit unsigned character                   |
|             |                                               |
| [int]       | 32-bit signed integer                         |
| [long]      | 64-bit signed integer                         |
| [bool]      | Boolean True/False value                      |
|             |                                               |
| [decimal]   | A 128-bit decimal value                       |
| [single]    | Single-precision 32-bit floating point number |
| [double]    | Double-precision 64-bit floating point number |
| [DateTime]  | Date and Time                                 |
|             |                                               |
| [xml]       | Xml object                                    |
| [array]     | An array of values                            |
| [hashtable] | Hashtable object                              |

## References

- [Microsoft Learn - PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-05?view=powershell-7.4)
- [Building Arrays and Collections in PowerShell](https://vexx32.github.io/2020/02/15/Building-Arrays-Collections/)
- [PowerShell One-Liners: Collections, Hashtables, Arrays and Strings](https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-one-liners-collections-hashtables-arrays-and-strings/)
- [Everything you wanted to know about arrays](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.4)
