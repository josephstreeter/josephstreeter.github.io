# Data Types

What are data types?

## String

Strings are sequences of characters used to represent text. In PowerShell, strings are of the type ```[string]```. Strings support a wide range of operations, including concatenation, substring extraction, and pattern matching.

Methods:

- Split()
- Replace()
- ToLower()
- ToUpper()
- Substring()
- StartsWith()

- [PowerShell String Manipulation: A Comprehensive Guide](https://www.sharepointdiary.com/2021/11/powershell-string-manipulation-comprehensive-guide.html)

## Character

A character data type in PowerShell represents a single character, such as a letter, digit, or symbol. In PowerShell, characters are of the type ```[char]```, which corresponds to a Unicode character. This type is useful for handling individual characters in strings, performing character-level operations, and working with text data.

If you simply set the variable to a single character the variable will be created as a string.

```powershell
$Char = "A"
$char.GetType()
```

Output:

```text
IsPublic IsSerial Name          BaseType
-------- -------- ----          --------
True     True     String        System.Object

```

Use the ```[char]``` accelerator to cast the variable as char if that is the data type needed.

```powershell
[char]$Char = "A"
$char.GetType()
```

Output:

```text
IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Char                                     System.ValueType
```

An error is thrown if the variable is being cast as char and the value being assigned is more than a single character.

```powershell
[char]$char = "AB" 
```

Output

```text
MetadataError: Cannot convert value "AB" to type "System.Char". Error: "String must be exactly one character long."
```

## Byte

A byte is...

## Numeric Type

A numeric type is one that allows representation of integer or fractional values, and that supports arithmetic operations on those values. The set of numerical types includes the integer and real number types, but does not include bool or char.

### Integer

Integers are whole numbers without any fractional component. They can be positive or negative. In PowerShell, integers are typically of the type ```[int]```, which corresponds to a 32-bit signed integer in the .NET framework.

Other integer types are SByte, Int16, UInt16, UInt32, and UInt64, all in the namespace System.

```powershell
[int]$positiveInt = 26
[int]$negativeInt = -17

$sum = $positiveInt + $negativeInt

Write-Output $sum
```

Output

```text
9
```

### Long

The type of ```[long]``` uses 64 bits as opposed to ```[int]```, which only uses 32 bits. Using 64 bits gives it a range of -9223372036854775808 to +9223372036854775807 opposed to -2147483648 to +2147483647.

### Bool

Booleans represent true or false values for logical operations and control flow. In PowerShell, Booleans are of the type ```[bool]```. They are essential for making decisions in scripts, such as conditional statements and loops, which allow scripts to execute different code paths based on certain conditions.

### Decimal

Decimals are used for high-precision arithmetic, especially useful in financial calculations where rounding errors can be unacceptable. The ```[decimal]``` type in PowerShell provides a higher precision and a smaller range of values compared to floats and doubles, making it ideal for currency and other precise calculations.

### Single

A single....

### Float and Double

Floats and doubles represent numbers with fractional components. Floats (single precision) and doubles (double precision) differ in the amount of precision and range they offer. Floats are generally used when less precision is acceptable, while doubles are used for more accurate calculations.

```powershell
[float]$float = 3.14
[double]$double = 3.141592653589793

$floatSum = $float + 2.86
$doubleSum = $double + 2.86

Write-Output $floatSum
Write-Output $doubleSum
```

Output:

```text
6.00000010490417
6.00159265358979
```

## DateTime

Dates represent date and time values. In PowerShell, dates are of the type [datetime], which provides various methods and properties for manipulating date and time data.

## Custom Objects

Custom objects allow you to create structured data by defining properties. In PowerShell, you can create custom objects using the New-Object cmdlet or by using a more modern and concise syntax with [PSCustomObject].

```powershell
New-Object -TypeName PSCustomObject 
```

```powershell
$Object = [PSCustomObject]@{
    GivenName = "John"
    Surname = "Smith"
}
```

## Check Data Type

n PowerShell, you can determine the data type of a variable by using the GetType() method. This method provides detailed information about the variable type, such as its name and base type. Here’s how you can use it:

```powershell
$x = 10
$xType = $x.GetType()
Write-Output $xType
```

Output

```text
IsPublic IsSerial Name     BaseType
-------- -------- ----     --------
True     True     Int32    System.ValueType
```

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
