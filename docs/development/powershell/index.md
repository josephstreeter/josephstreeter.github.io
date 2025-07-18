# PowerShell

Put the "investment quote" here.

- [How to Run a PowerShell Script? A Comprehensive Guide!](https://www.sharepointdiary.com/2023/08/how-to-run-powershell-script.html)

---

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

---

## Comments and Documentation

Comments are used to explain code and make scripts easier to understand and maintain. PowerShell supports both single-line and multi-line comments.

**Single-line comment:**

```powershell
# This is a single-line comment
Write-Output "Hello, World!" # This is an inline comment
```

**Multi-line comment:**

```powershell
<#
This is a
multi-line comment.
It can span several lines.
#>
```

**Comment-based help for functions:**

You can add special comments before a function to provide help information.

```powershell
<#
.SYNOPSIS
    Gets a friendly greeting.
.DESCRIPTION
    This function returns a greeting for the specified name.
.PARAMETER Name
    The name of the person to greet.
.EXAMPLE
    Get-Greeting -Name "Alice"
#>
function Get-Greeting 
{
    param($Name)
    "Hello, $Name!"
}
```

---

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

A byte is an 8-bit unsigned integer with a range of 0 to 255. Useful for binary data.

```powershell
[byte]$b = 255
$b.GetType()
```

Output:

```text
IsPublic IsSerial Name          BaseType
-------- -------- ----          --------
True     True     Byte          System.ValueType
```

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

Output:

```text
9
```

#### Long

The type of ```[long]``` uses 64 bits as opposed to ```[int]```, which only uses 32 bits. Using 64 bits gives it a range of -9223372036854775808 to +9223372036854775807 opposed to -2147483648 to +2147483647.

### Decimal

Decimals are used for high-precision arithmetic, especially useful in financial calculations where rounding errors can be unacceptable. The ```[decimal]``` type in PowerShell provides a higher precision and a smaller range of values compared to floats and doubles, making it ideal for currency and other precise calculations.

### Single

A single is a 32-bit floating point number, less precise than a double.

```powershell
[single]$single = 3.14
$single.GetType()
```

```output
IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Single                                   System.ValueType
```

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

In PowerShell, you can determine the data type of a variable by using the GetType() method. This method provides detailed information about the variable type, such as its name and base type. Here’s how you can use it:

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

|Accelerator | Description                                   |
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
- [Building Arrays and Collections in PowerShell](https://vexx32.github.io/2020/02/15/Building-Arrays-Collections/index.md)
- [PowerShell One-Liners: Collections, Hashtables, Arrays and Strings](https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-one-liners-collections-hashtables-arrays-and-strings/index.md)
- [Everything you wanted to know about arrays](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.4)

---

## Comparisons

Comparison operators let you compare values or finding values that match specified patterns.

PowerShell includes the following comparison operators:

| Equality                                  |              |               |               |
|-------------------------------------------|--------------|---------------|---------------|
| equals                                    | -eq          | -ieq          | -ceq          |
| not equals                                | -ne          | -ine          | -cne          |
| greater than                              | -gt          | -igt          | -cgt          |
| greater than or equal                     | -ge          | -ige          | -cge          |
| less than                                 | -lt          | -ilt          | -clt          |
| less than or equal                        | -le          | -ile          | -cle          |

| Matching                                  |              |               |               |
|-------------------------------------------|--------------|---------------|---------------|
| string matches wildcard pattern           | -like        | -ilike        | -clike        |
| string doesn't match wildcard pattern     | -notlike     | -inotlike     | -cnotlike     |
| string matches regex pattern              | -match       | -imatch       | -cmatch       |
| string doesn't match regex pattern        | -notmatch    | -inotmatch    | -cnotmatch    |

| Replacement                               |              |               |               |
|-------------------------------------------|--------------|---------------|---------------|
| replaces strings matching a regex pattern | -replace     | -ireplace     | -creplace     |

| Containment                               |              |               |               |
|-------------------------------------------|--------------|---------------|---------------|
| collection contains a value               | -contains    | -icontains    | -ccontains    |
| collection doesn't contain a value        | -notcontains | -inotcontains | -cnotcontains |
| value is in a collection-in               | -iin         | -cin          |               |
| value isn't in a collection               | -notin       | -inotin       | -cnotin       |

| Type                                      |              |
|-------------------------------------------|--------------|
| both objects are the same type            | -is          |
| the objects aren't the same type          | -isnot       |

<https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators?view=powershell-7.5>

## Collections

A collection is basically a set of individual items. Those items could be strings, integers, objects, other collections, or almost anything.

Many collection classes are defined as part of the System.Collections or System.Collections.Generic namespaces. Most collection classes implement the interfaces ICollection, IComparer, IEnumerable, IList, IDictionary, and IDictionaryEnumerator and their generic equivalents.

Typical collections in PowerShell are:

- Array
- Array List
- Generic List
- Hashtable (Dictionaries)

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

- [Building Arrays and Collections in PowerShell](https://vexx32.github.io/2020/02/15/Building-Arrays-Collections/index.md)
- [PowerShell One-Liners: Collections, Hashtables, Arrays and Strings](https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-one-liners-collections-hashtables-arrays-and-strings/index.md)
- [Everything you wanted to know about arrays](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.4)

---

## Loops

Loops iterate through collections and repeat tasks until a condition is met.

The different types of loops:

- For loop
- Foreach loop
- While loop
- Do while loop
- Do until loop

### For Loop

For loops run as long as the specified condition evaluates as ```$true``` and terminates when the condition evaluates as ```$false```.

```powershell
for ($var = 1; $var -le 5 -and $var -ne 3; $var++) 
{
    Write-Output The value of Var is: $var
}
```

The first component, ```$var = 1```, represents one or more command that are run prior to the loop. This component typically sets an integer variable that is a starting point for the loop.

The second component, ```$var -le 5```, is the condition that resolves to a boolean value, either ```$true``` or ```$false```. The loop will continue to run as long as this condition evaluates to ```$true```. This component typically evaluates the integer set in the first component against the specified value.

The third component, ```$var++```, executes each time the loop repeats. This commponent typically increments or decrements the variable in the first component.

### Foreach Loop

foreach loops iterate though a collection of items and executes commands on each item.

The foreach loop comes in several differnt forms:

- Foreach Statement
- Foreach Cmdlet
- Foreach Method

The foreach statement. In the example below, ```$Items``` is a collection of integers. As the foreach loop iterages through them, it initializes ```$Item``` before executing the code in the statement. It is good practice to name the collection and item variables for the type of items contained in them. Note that the collection and item variables are named the same, but collection variable is plural and the item variable is singular.

The foreach statement more easily read than the others and is faster than pipelining to the Foreach-Object cmdlet.

```powershell
$Items = 1..15

foreach ($Item in $Items) 
{
    Write-Output The value of Item is: $Item
}
```

In the below example, the collection is created within the foreach statement by the ```(Get-Service | Select-Object -First 5)``` code.

```powershell
foreach ($service in (Get-Service | Select-Object -First 5)) 
{
    Write-Output ("Service name is: {0} and status is {1}" -f $service.name, $service.status)
}
```

```powershell
$Animals = "Bear", "Lion", "Monkey", "Deer"

$Animals | Foreach-Object {Write-Output $_}
```

A method called foreach can be called on collections. This can be a fast way to iterate through a collection if just listing the contents. Much more than simple listing of items and readability of the code can suffer.

```powershell
(Get-Service).ForEach({$_.name})
```

### While, Do-Until, Do-While Loops

While Loop will only execute the code block if the condition is true.

```powershell
$var = 1
while ($var -le 5)
{
    Write-Output The value of Var is: $var
    $var++
}
```

Do-While and Do-Until Loops

Writing each of the loops only varies slightly in the use of the words ```while``` and ```until```. The difference between the two comes down to how the condition of the loop is evaluated.

The Do-Until loop will execute the code as long as the condition is ```$false```.

```Powershell
$a = 0
do 
{
  Write-Output $a
  $a++
}
Until ($a -gt 10)
```

The Do-While loop will execute the block of code as long as the condition resolves to ```$true```.

```Powershell
$a = 0
do 
{
  Write-Output $a
  $a++
}
while ($a -lt 10)
```

## Conditional Statements

Conditional statements allow the code to make logic-based decisions to determine which code gets run. The ```if``` and ```switch``` statements are used to make those logic-based decisions.

### If Statement

The ```if``` statement evaluates a condition and executes the code if the condition evaluates to ```true```.

```powershell
$condition = $true
if (condition) 
{
   Write-Output "The condition is true"
}
```

### If Else Statement

```powershell
$condition = $true
if (condition) 
{
   Write-Output "The condition is true"
}
else 
{
   Write-Output "The condition is false"
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

### Switch

The switch statement is used for controlling the execution flow of the script. A switch can typically be used where a long list if ```elseif``` statements might be used. The switch statement provides a variable and a list of possible values. If the value matches the variable, then its scriptblock is executed.

```powershell
$Color = "red"

switch ($Color) 
{
    "red" { Write-Host "The color is red." }
    "blue" { Write-Host "The color is blue." }
    "green" { Write-Host "The color is green." }
    default { Write-Host "The color is not red, blue, or green." }
}
```

Output:

```text
The color is red.
```

---

## Output Streams

PowerShell provides several output stream cmdlets that allow scripts to send different types of messages or data to the console, logs, or other commands in the pipeline. Each cmdlet writes to a specific stream, such as standard output, error, warning, verbose, debug, or information. Using these cmdlets helps organize script output, making it easier to display, capture, or troubleshoot messages according to their purpose and

### Write-Host

Displays output directly to the console. Use for messages that do not need to be captured or redirected.

```powershell
Write-Host "This is a message to the console."
```

---

### Write-Output

Sends objects to the next command in the pipeline or to the console if it is the last command. Preferred for script output.

```powershell
Write-Output "This is standard output."
```

---

### Write-Error

Writes an error message to the error stream. Use for reporting errors.

```powershell
Write-Error "An error has occurred."
```

---

### Write-Warning

Writes a warning message to the warning stream. Warnings are displayed in yellow by default.

```powershell
Write-Warning "This is a warning message."
```

---

### Write-Verbose

Writes detailed information, typically used for debugging or providing additional context. Only shown if `$VerbosePreference` is set to `Continue` or `-Verbose` is used.

```powershell
Write-Verbose "This is a verbose message."
```

---

### Write-Debug

Writes debug messages to the debug stream. Only shown if `$DebugPreference` is set to `Continue` or `-Debug` is used.

```powershell
Write-Debug "This is a debug message."
```

---

### Write-Information

Writes informational messages to the information stream. Can be selectively displayed or suppressed.

```powershell
Write-Information "This is an informational message."
```

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

---
