# PowerShell

Put the "investment quote" here.

- [How to Run a PowerShell Script? A Comprehensive Guide!](https://www.sharepointdiary.com/2023/08/how-to-run-powershell-script.html)

## Variables

[https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_variables?view=powershell-7.4](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_variables?view=powershell-7.4)

```powershell
$a = 93                         # System.Int32
$a = "string"                   # System.String
$a = "string", 120              # array of System.Int32, System.String
$a = Get-ChildItem C:\Windows   # FileInfo and DirectoryInfo types
```

```powershell
[int]$count = 256         # Creates a variable that will only contain an int
$count = 1024             # Sets the variable to another int
$count = "256"            # Converts the string to an int
$count = "String"         # Throws an error "Cannot convert value "String" to type "System.Int32". Error: "Input string was not in a correct format."
```

## Data Types

What are data types?

### String

Strings are sequences of characters used to represent text. In PowerShell, strings are of the type ```[string]```. Strings support a wide range of operations, including concatenation, substring extraction, and pattern matching.

Methods:

- Split()
- Replace()
- ToLower()
- ToUpper()
- Substring()
- StartsWith()

- [PowerShell String Manipulation: A Comprehensive Guide](https://www.sharepointdiary.com/2021/11/powershell-string-manipulation-comprehensive-guide.html)

### Character

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

### Byte

A byte is...

### Numeric Type

A numeric type is one that allows representation of integer or fractional values, and that supports arithmetic operations on those values. The set of numerical types includes the integer and real number types, but does not include bool or char.

#### Integer

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

#### Long

The type of ```[long]``` uses 64 bits as opposed to ```[int]```, which only uses 32 bits. Using 64 bits gives it a range of -9223372036854775808 to +9223372036854775807 opposed to -2147483648 to +2147483647.

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

### Bool

Booleans represent true or false values for logical operations and control flow. In PowerShell, Booleans are of the type ```[bool]```. They are essential for making decisions in scripts, such as conditional statements and loops, which allow scripts to execute different code paths based on certain conditions.

### DateTime

Dates represent date and time values. In PowerShell, dates are of the type ```[datetime]```, which provides various methods and properties for manipulating date and time data. DateTime is a .NET ```System.DateTime``` object. The DateTime object can be formated many different ways to meet your needs. You can return the specific parts of the DateTime object, such as the year, month, hour, day, or seconds, and format the output any way that you want.

```powershell
Get-Date
```

Output

```text
Saturday, November 23, 2024 5:31:32 AM
```

Calculate a date 13 days from now (November 23, 2024)

```powershell
(get-date).AddDays(13)
```

Output

```text
Friday, December 6, 2024 5:32:43 AM
```

Format the date.
```yy``` = 2 digit year
```yyyy``` = 4 digit year
``MM`` = Month
``dd`` = Day
```mm``` = Minutes
```ss``` = Seconds

```powershell
(get-date).ToString("yyyy-MM-dd")
```

Output

```text
2024-11-23
```

Specify a date

```powershell
(get-date 2024-10-13)
(get-date 2024-10-13).ToString("yyyy-MM-dd")
```

Output

```text
Sunday, October 13, 2024 12:00:00 AM
2024-10-13
```

Measure the difference between dates and times by subtracting one DateTime from another.

```powershell
(get-date 2024-12-25) - (get-Date)

```

Output

```text
Days              : 31
Hours             : 18
Minutes           : 19
Seconds           : 1
Milliseconds      : 333
Ticks             : 27443413334918
TotalDays         : 31.7632098783773
TotalHours        : 762.317037081056
TotalMinutes      : 45739.0222248633
TotalSeconds      : 2744341.3334918
TotalMilliseconds : 2744341333.4918
```

TimeSpans can also be used todefine a measurement of time between two DateTime objects.

```powershell
$TimeSpan = New-TimeSpan -Start (Get-Date) -End (Get-Date "2024-12-25")
```

Output

```text
Days              : 31
Hours             : 17
Minutes           : 46
Seconds           : 7
Milliseconds      : 868
Ticks             : 27423678684757
TotalDays         : 31.7403688480984
TotalHours        : 761.768852354361
TotalMinutes      : 45706.1311412617
TotalSeconds      : 2742367.8684757
TotalMilliseconds : 2742367868.4757
```

```powershell
$diff = (get-date 2024-12-25) - (get-Date)
Write-Output ("{0} days until Christmas!" -f $diff.Days)
```

Output

```text
31 days until Christmas!
```

Convert DateTime to Universal Time.

```powershell
(Get-Date).ToUniversalTime().ToString('yyyy-MM-dd:hh-mm-ss')
```

Output

```text
2024-11-23:11-53-23
```

The DateTime accelerator can be used instead of the ```Get-Date``` CmdLet.

```powershell
$date = [DateTime]"2023-01-16 12:00:00 AM"
$date.ToString("MM/dd/yyyy")
```

Output

```text
01/16/2023
```

Calculate the number of days in a month

```powershell
[DateTime]::DaysInMonth(2025,2)
[DateTime]::DaysInMonth(2024,2)
```

Output

```text
28
29
```

### Custom Objects

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

### Check Data Type

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

### Type Accelerators

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

### Data Type References

- [Microsoft Learn - PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-05?view=powershell-7.4)
- [Building Arrays and Collections in PowerShell](https://vexx32.github.io/2020/02/15/Building-Arrays-Collections/)
- [PowerShell One-Liners: Collections, Hashtables, Arrays and Strings](https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-one-liners-collections-hashtables-arrays-and-strings/)
- [Everything you wanted to know about arrays](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.4)

## Collections

A collection is basically a set of individual items. Those items could be strings, integers, objects, other collections, or almost anything.

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

### Array List

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

### Generic List

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

### Performance Considerations

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

### Collections References

- [Building Arrays and Collections in PowerShell](https://vexx32.github.io/2020/02/15/Building-Arrays-Collections/)
- [PowerShell One-Liners: Collections, Hashtables, Arrays and Strings](https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-one-liners-collections-hashtables-arrays-and-strings/)
- [Everything you wanted to know about arrays](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.4)

## Conditions

### If Statement

```powershell
if (condition1) 
{
   # code to execute if condition1 is true
}
```

### If Else Statement

```powershell
if (condition1) 
{
   # code to execute if condition1 is true
}
else 
{
   # code to execute if all conditions are false
}
```

### If ElseIf Statement

```powershell
if (condition1) 
{
   # code to execute if condition1 is true
}
elseif (condition2) 
{
   # code to execute if condition2 is true
}
else 
{
   # code to execute if all conditions are false
}
```

### If Else Finally

```powershell

```

### Switch

```powershell
$Color = "red"

switch ($CSolor) 
{
    "red" { Write-Host "The color is red." }
    "blue" { Write-Host "The color is blue." }
    "green" { Write-Host "The color is green." }
    default { Write-Host "The color is not red, blue, or green." }
}
```

## Loops

### For Loop

```powershell
for ($var = 1; $var -le 5 -and $var -ne 3; $var++) 
{
    Write-Output The value of Var is: $var
}
```

### Foreach Loop

```powershell
$collection = 1..15

foreach ($item in $collection) 
{
    Write-Output The value of Item is: $item
}
```

```powershell
foreach ($service in (Get-Service | Select-Object -First 5)) 
{
    Write-Output "Service name is: $service.name and status is $service.status"
}
```

### While Loop and Do Loop

While Loop

```powershell
$var = 1
while ($var -le 5)
{
    Write-Output The value of Var is: $var
    $var++
}
```

Do Loop

```Powershell
do {
  if ($x[$a] -lt 0) { continue }
  Write-Host $x[$a]
}
while (++$a -lt 10)
```

## Output Streams

### Write-Debug

### Write-Error

### Write-Host

### Write-Information

### Write-Output

### Write-Verbose

### Write-Warning

### Output Stream References

- [Write-Host](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-host?view=powershell-7.4)
- [Write-Output](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-output?view=powershell-7.4)
- [Write-Verbose](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-verbose?view=powershell-7.4)
- [Write-Information](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-information?view=powershell-7.4)
- [Write-Debug](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-debug?view=powershell-7.4)
- [Write-Warning](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-warning?view=powershell-7.4)

## Error Handling

### What is Error Handling

Error handling is a critical to writing PowerShell or any other type of code. Error handling involves anticipating and managing errors or exceptions that may occur during the execution of a script. It is a way to protect resources and to make sure that the process behaves in an expected way, even when the unexpected happens. Handling errors is all about dealing with errors or exceptions and provide meaningful feedback. It is important to stop a process that is not working as expected. Error handling techniques, such as try-catch blocks or error logging, allow exceptions and errors to be identified and delt with in a controlled manner, improving the reliability of the code.

### Terminating vs Non-Terminating Errors

Terminating errors, known as exceptions, terminate the execution process. Non-terminanting errots will cause an error message to be written the error stream, but theh script will continue to execute.

### PowerShell ErrorAction

The following ErrorAction options available with the $ErrorActionPreference and -ErrorAction parameters:

- **Continue:** Writes the error to the pipeline and continues executing the command or script. This is the default behavior in PowerShell.
- **Ignore:** Suppresses error messages and continues executing the command. The errors are never written to the error stream.
- **Inquire:** Pauses the execution of the command and asks the user how to proceed. Cannot be set globally with the $ErrorActionPreference variable.

```console
Action to take for this exception:
Attempted to divide by zero.
[C] Continue  [I] Silent Continue  [B] Break  [S] Suspend  [?] Help (default is
"C"):
```

- **SilentlyContinue:** Suppresses error messages and continues executing the command. The errors are still written to the error stream, which you can query with the $Error automatic variable.
- **Stop:** Displays the error and stops executing the command. This option also generates an ActionPreferenceStopException object to the error stream.
- **Suspend:** Suspends a workflow that can later be resumed. The Suspend option is only available to workflows.

### ErrorActionPreference Variable

The $ErrorActionPreference variable specifies the action to take in response to an error occurring. This allows you to specify, as the name implies, your prefernce for Error Action. If you wanted Error Action for a script to be ```Stop``` for everything you could set the preference varialbe to ```Stop``` and not have to include ```-ErrorAction $Stop``` for each cmdlet. Including the ErrorAction Parameter would only be necessary when you wanted to something different than what you set the prefernce to.

The available values are most of the same ones availble for the ErrorAction parameter:

- Continue (default).
- SilentlyContinue
- Stop
- Inquire

When error action is set to ```Inquire```, the code execution stops and a description is presented to the user. The user is also prompted for what to do next.

```powershell
Action to take for this exception:
Attempted to divide by zero.
[C] Continue  [I] Silent Continue  [B] Break  [S] Suspend  [?] Help (default is "C"):
```

To set the ```$ErrorActionPreference```, issue the following command:

```powershell
$ErrorActionPreference = "SilentlyContinue"
```

### Throw

When the throw command is called, it creates a terminating error. Throw can be used to stop the processing of a command, function, or script.

The throw command used in a script block of an if statement to in a catch block of a try-catch statement to end a process that has experienced an error.

Throw can display any object, such as a user message string or the object that caused the error.

Throw a message:

```powershell
throw "Something went wrong."
```

Output:

```console
Exception: Something went wrong"
```

### Trap

Trap

### Try/Catch/Finally

Try/Catch

```powershell
try
{
    Get-ADUser JMSmith -ErrorAction Stop
}
catch
{
    Write-Error -Message $_.Exception.Message
}
```

Try/Catch/Finally

```powershell
try
{
    Get-ADUser JMSmith -ErrorAction Stop
}
catch
{
    Write-Error -Message $_.Exception.Message
}
```

### Error Handling References

- ["Everything you wanted to know about Exceptions"](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-exceptions?view=powershell-7.4)
