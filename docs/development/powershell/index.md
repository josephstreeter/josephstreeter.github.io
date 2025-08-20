# PowerShell: Complete Development Guide

> *"PowerShell is the Swiss Army knife of system administration and automation. Once you master its fundamentals, you'll wonder how you ever managed without it."* - Jeffrey Snover, Architect of PowerShell¹

PowerShell is a powerful cross-platform task automation solution consisting of a command-line shell, scripting language, and configuration management framework. Built on the .NET platform, PowerShell provides IT professionals and developers with comprehensive tools for managing systems, automating tasks, and building robust applications.

## Table of Contents

- [PowerShell Fundamentals](#powershell-fundamentals)
- [Getting Started](#getting-started)
- [Core Language Features](#core-language-features)
- [Data Types and Variables](#data-types-and-variables)
- [Collections and Arrays](#collections-and-arrays)
- [Control Structures](#control-structures)
- [Output Stream Standards](#output-stream-standards)
- [Error Handling Fundamentals](#error-handling-fundamentals)
- [Best Practices](#best-practices)
- [Development Resources](#development-resources)

---

## PowerShell Fundamentals

### What is PowerShell?

PowerShell is a cross-platform task automation and configuration management framework, consisting of:

- **Command-line shell**: Interactive interface for executing commands
- **Scripting language**: Rich programming language with advanced features
- **Configuration management**: Infrastructure as Code (IaC) capabilities
- **Object-oriented pipeline**: Processes .NET objects rather than plain text

### Core Architecture

PowerShell is built on the .NET runtime, providing:

- **Object-based operations**: Commands work with .NET objects
- **Extensible type system**: Custom types and formatting
- **Rich cmdlet ecosystem**: Thousands of built-in and community cmdlets
- **Module system**: Organized, reusable command collections

### PowerShell Editions

| Edition | Description | Platform Support |
|---------|-------------|-------------------|
| **PowerShell Core** | Open-source, cross-platform | Windows, Linux, macOS |
| **Windows PowerShell** | Built-in Windows version | Windows only |

### Key Advantages

1. **Object-Oriented Pipeline**: Unlike traditional shells that pass text, PowerShell passes rich .NET objects
2. **Consistent Syntax**: Verb-Noun naming convention (Get-Process, Set-Location)
3. **Extensive Help System**: Built-in documentation with examples
4. **Rich Type System**: Native support for .NET data types and methods
5. **Powerful Remoting**: Execute commands on remote systems seamlessly

---

## Getting Started

### Installation and Setup

#### PowerShell Core Installation

**Windows:**

```powershell
# Install via Windows Package Manager
winget install Microsoft.PowerShell

# Install via Chocolatey
choco install powershell-core

# Install via Microsoft Store
# Search for "PowerShell" in Microsoft Store
```

**Linux (Ubuntu/Debian):**

```bash
# Update package list
sudo apt update

# Install dependencies
sudo apt install -y wget apt-transport-https software-properties-common

# Download and install PowerShell
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y powershell
```

**macOS:**

```bash
# Install via Homebrew
brew install powershell/tap/powershell
```

### First Steps

#### Starting PowerShell

- **Windows**: Type `pwsh` in Command Prompt or search "PowerShell"
- **Linux/macOS**: Type `pwsh` in terminal

#### Basic Navigation Commands

```powershell
# Get current location
Get-Location

# Change directory  
Set-Location "C:\Users\Username\Documents"

# List directory contents
Get-ChildItem

# Get command help
Get-Help Get-Process
```

#### Essential Cmdlets

```powershell
# System information
Get-ComputerInfo

# Running processes
Get-Process

# Services
Get-Service

# Event logs
Get-EventLog -LogName System -Newest 10

# Network configuration
Get-NetAdapter
```

### PowerShell ISE vs Visual Studio Code

#### PowerShell ISE (Integrated Scripting Environment)

- **Pros**: Built into Windows, integrated debugging
- **Cons**: Windows-only, limited features compared to modern editors

#### Visual Studio Code with PowerShell Extension

- **Pros**: Cross-platform, rich features, active development
- **Cons**: Requires separate installation
- **Recommended**: Use for serious PowerShell development

**VS Code PowerShell Extension Features:**

- Syntax highlighting and IntelliSense
- Integrated debugging
- Code formatting and linting
- Interactive console
- Script analysis (PSScriptAnalyzer integration)

### Execution Policy

PowerShell execution policies control script execution permissions:

```powershell
# View current execution policy
Get-ExecutionPolicy

# Set execution policy (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Bypass execution policy for single script
PowerShell -ExecutionPolicy Bypass -File script.ps1
```

#### Execution Policy Levels

| Policy | Description |
|--------|-------------|
| **Restricted** | No scripts allowed (default on Windows clients) |
| **AllSigned** | Only scripts signed by trusted publishers |
| **RemoteSigned** | Local scripts run freely, remote scripts must be signed |
| **Unrestricted** | All scripts run (not recommended) |
| **Bypass** | No restrictions or warnings |

---

## Core Language Features

### PowerShell Syntax Fundamentals

#### Command Structure

PowerShell follows a consistent Verb-Noun pattern:

```powershell
# Basic syntax: Verb-Noun -Parameter Value
Get-Process -Name "notepad"
Set-Content -Path "file.txt" -Value "Hello World"
New-Item -ItemType File -Name "test.txt"
```

#### Parameters and Aliases

```powershell
# Full parameter names
Get-ChildItem -Path "C:\" -Recurse -Force

# Parameter aliases
Get-ChildItem -Path "C:\" -r -f

# Positional parameters
Get-Content "file.txt"  # -Path is implied for first parameter
```

#### Pipeline Operations

PowerShell's pipeline passes objects between commands:

```powershell
# Basic pipeline
Get-Process | Where-Object CPU -gt 100 | Sort-Object CPU -Descending

# Complex pipeline with formatting
Get-Service | 
    Where-Object Status -eq "Running" | 
    Select-Object Name, Status, StartType |
    Sort-Object Name |
    Format-Table -AutoSize
```

### Operators

#### Comparison Operators

```powershell
# Equality comparisons
$value -eq "test"       # Equals
$value -ne "test"       # Not equals
$value -gt 5            # Greater than
$value -ge 5            # Greater than or equal
$value -lt 10           # Less than
$value -le 10           # Less than or equal

# Case sensitivity
$value -ceq "Test"      # Case-sensitive equals
$value -ieq "test"      # Case-insensitive equals (default)
```

#### Pattern Matching

```powershell
# Wildcard matching
$name -like "J*"        # Starts with J
$name -notlike "*test*" # Doesn't contain "test"

# Regular expressions
$email -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
$text -replace "old", "new"  # Replace using regex
```

#### Logical Operators

```powershell
# Logical operations
($value -gt 5) -and ($value -lt 10)   # Both conditions true
($status -eq "Running") -or ($status -eq "Stopped")  # Either condition true
-not ($process -eq $null)             # Logical NOT
```

### Variables and Scoping

#### Variable Declaration and Assignment

```powershell
# Simple assignment (dynamic typing)
$message = "Hello PowerShell"
$number = 42
$array = @("item1", "item2", "item3")

# Strongly typed variables
[string]$name = "John Doe"
[int]$age = 30
[datetime]$birthDate = "1990-01-15"
```

#### Variable Scopes

```powershell
# Global scope - available throughout session
$global:SharedVariable = "Available everywhere"

# Script scope - available throughout script
$script:ScriptVariable = "Available in script"

# Local scope - current scope only (default)
$local:LocalVariable = "Available locally"

# Private scope - current scope only, not inherited
$private:PrivateVariable = "Not inherited by child scopes"
```

#### Automatic Variables

PowerShell provides numerous automatic variables:

```powershell
$_              # Current pipeline object
$args           # Command line arguments
$Error          # Error objects from previous commands  
$Host           # Current host application information
$PSVersionTable # PowerShell version information
$pwd            # Current directory (Present Working Directory)
$true/$false    # Boolean values
```

---

## Data Types and Variables

### Understanding PowerShell Data Types

PowerShell uses the .NET type system, providing rich data type support with automatic type conversion when possible. Understanding data types is crucial for effective PowerShell programming.

#### Variable Declaration and Typing

```powershell
# Dynamic typing (PowerShell infers type)
$dynamicVar = "Hello World"        # System.String
$dynamicVar = 42                   # System.Int32 
$dynamicVar = Get-Date            # System.DateTime
$dynamicVar = @("a", "b", "c")    # System.Object[]

# Strongly typed variables
[string]$name = "John Doe"
[int]$age = 30
[bool]$isActive = $true
[datetime]$created = Get-Date
```

#### Type Checking and Conversion

```powershell
# Check variable type
$variable = "123"
$variable.GetType().Name          # Returns: String

# Type conversion
[int]$number = "123"              # Converts string to integer
[string]$text = 123               # Converts integer to string
[bool]$boolean = 1                # Converts to True

# Explicit conversion methods
$stringValue = "123.45"
$floatValue = [float]::Parse($stringValue)
$intValue = [int]::Parse($stringValue)  # Will truncate decimal
```

### Core Data Types

#### String Manipulation

Strings are fundamental for text processing and output formatting:

```powershell
# String creation
$singleQuoted = 'Literal string - variables not expanded'
$doubleQuoted = "Interpolated string - $env:USERNAME"
$hereString = @"
Multi-line string
with preserved formatting
and $variable expansion
"@

# String methods
$text = "PowerShell Scripting"
$text.Length                      # 19
$text.ToUpper()                   # POWERSHELL SCRIPTING
$text.ToLower()                   # powershell scripting
$text.Substring(0, 10)            # PowerShel
$text.Replace("Shell", "Core")    # PowerCore Scripting
$text.Split(" ")                  # ["PowerShell", "Scripting"]
$text.Contains("Shell")           # True
$text.StartsWith("Power")         # True
$text.EndsWith("ing")             # True

# String formatting
$name = "Alice"
$age = 30
"Hello {0}, you are {1} years old" -f $name, $age
"Hello $name, you are $age years old"
```

#### Numeric Types

PowerShell supports various numeric types for different precision requirements:

```powershell
# Integer types
[byte]$byteValue = 255                    # 0 to 255
[int16]$shortValue = -32768               # -32,768 to 32,767  
[int32]$intValue = 2147483647             # Standard integer
[int64]$longValue = 9223372036854775807   # Large integers

# Floating point types
[single]$floatValue = 3.14159             # 32-bit precision
[double]$doubleValue = 3.141592653589793  # 64-bit precision (default)
[decimal]$decimalValue = 123.456789       # High precision for financial calculations

# Numeric operations
$a = 10
$b = 3
$a + $b          # Addition: 13
$a - $b          # Subtraction: 7
$a * $b          # Multiplication: 30
$a / $b          # Division: 3.33333333333333
$a % $b          # Modulus: 1
[Math]::Pow($a, $b)  # Power: 1000
[Math]::Sqrt($a)     # Square root: 3.16227766016838

# Number formatting
$price = 1234.56
$price.ToString("C")              # Currency: $1,234.56
$price.ToString("F2")             # Fixed point: 1234.56
$price.ToString("N2")             # Number: 1,234.56
$price.ToString("P2")             # Percentage: 123,456.00%
```

#### Boolean and Logical Operations

```powershell
# Boolean values
[bool]$isTrue = $true
[bool]$isFalse = $false

# Boolean conversion
[bool]0           # False
[bool]1           # True
[bool]""          # False (empty string)
[bool]"false"     # True (non-empty string)
[bool]@()         # False (empty array)
[bool]@(1,2,3)    # True (non-empty array)

# Logical operations
$condition1 = $true
$condition2 = $false
$condition1 -and $condition2      # False
$condition1 -or $condition2       # True
-not $condition1                  # False
!$condition1                      # False (alternative syntax)
```

#### DateTime Operations

DateTime handling is essential for logging, scheduling, and data processing:

```powershell
# Creating DateTime objects
$now = Get-Date
$specific = Get-Date "2024-12-25 09:30:00"
$utc = (Get-Date).ToUniversalTime()

# DateTime arithmetic
$tomorrow = $now.AddDays(1)
$lastWeek = $now.AddDays(-7)
$nextMonth = $now.AddMonths(1)
$inOneYear = $now.AddYears(1)

# Time span calculations
$timeSpan = $specific - $now
$timeSpan.Days                    # Days between dates
$timeSpan.Hours                   # Hours component
$timeSpan.TotalHours              # Total hours as decimal

# DateTime formatting
$now.ToString("yyyy-MM-dd")              # 2024-11-23
$now.ToString("yyyy-MM-dd HH:mm:ss")     # 2024-11-23 14:30:25
$now.ToString("dddd, MMMM dd, yyyy")     # Saturday, November 23, 2024

# Parsing dates
$dateString = "2024-01-15"
$parsedDate = [DateTime]::Parse($dateString)
$parsedDate = [DateTime]::ParseExact("20240115", "yyyyMMdd", $null)

# Working with time zones
$easternTime = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($now, "Eastern Standard Time")
$availableTimeZones = [TimeZoneInfo]::GetSystemTimeZones()
```

#### Custom Objects

Custom objects allow you to create structured data by defining properties. In PowerShell, you can create custom objects using the New-Object cmdlet or by using a more modern and concise syntax with [PSCustomObject].

```powershell
# PSCustomObject (recommended)
$user = [PSCustomObject]@{
    Name = "John Doe"
    Department = "IT"
    HireDate = Get-Date "2020-01-15"
    IsActive = $true
    Skills = @("PowerShell", "Azure", "Windows Server")
}

# Access properties
$user.Name                        # John Doe
$user.Skills[0]                   # PowerShell

# Add properties dynamically
$user | Add-Member -MemberType NoteProperty -Name "Manager" -Value "Jane Smith"

# New-Object method (legacy)
$server = New-Object -TypeName PSCustomObject -Property @{
    Name = "Server01"
    OS = "Windows Server 2022"
    RAM = 32
    CPU = 16
}
```

### Type Accelerators Reference

PowerShell provides convenient type accelerators for common .NET types:

| Accelerator | Full Type Name | Description |
|-------------|----------------|-------------|
| `[string]` | System.String | Text data |
| `[char]` | System.Char | Single Unicode character |
| `[byte]` | System.Byte | 8-bit unsigned integer |
| `[int]` | System.Int32 | 32-bit signed integer |
| `[long]` | System.Int64 | 64-bit signed integer |
| `[bool]` | System.Boolean | True/False values |
| `[decimal]` | System.Decimal | High-precision decimal |
| `[single]` | System.Single | Single-precision float |
| `[double]` | System.Double | Double-precision float |
| `[datetime]` | System.DateTime | Date and time |
| `[xml]` | System.Xml.XmlDocument | XML document |
| `[array]` | System.Array | Array of objects |
| `[hashtable]` | System.Collections.Hashtable | Key-value pairs |

---

## Collections and Arrays

### Understanding PowerShell Collections

Collections are fundamental for managing groups of data efficiently. PowerShell supports various collection types, each optimized for different scenarios and performance requirements.

#### Array Fundamentals

```powershell
# Array creation
$simpleArray = @("apple", "banana", "cherry")
$numericArray = @(1, 2, 3, 4, 5)
$mixedArray = @("text", 123, $true, (Get-Date))

# Array access and manipulation
$simpleArray[0]                   # apple
$simpleArray[-1]                  # cherry (last element)
$simpleArray[1..2]               # banana, cherry (range)
$simpleArray.Length               # 3
$simpleArray.Count               # 3
```

#### Performance-Optimized Collections

**ArrayList for Dynamic Sizing:**

```powershell
# Create ArrayList
$arrayList = New-Object System.Collections.ArrayList
# or
$arrayList = [System.Collections.ArrayList]@()

# Add items efficiently
[void]$arrayList.Add("Item1")     # [void] suppresses return value
[void]$arrayList.Add("Item2")
[void]$arrayList.Add("Item3")

# ArrayList methods
$arrayList.Remove("Item2")        # Remove specific item
$arrayList.RemoveAt(0)           # Remove by index
$arrayList.Insert(1, "NewItem")  # Insert at index
$arrayList.Contains("Item1")     # Check if contains
$arrayList.Clear()               # Remove all items
```

**Generic Lists (Recommended):**

```powershell
# Strongly typed generic list
$stringList = [System.Collections.Generic.List[string]]@()
$objectList = [System.Collections.Generic.List[object]]@()

# Add items
$stringList.Add("PowerShell")
$stringList.Add("Azure")
$stringList.Add("Windows")

# Generic list methods
$stringList.AddRange(@("Linux", "macOS"))
$filteredList = $stringList.FindAll({param($item) $item.Length -gt 5})
$stringList.Sort()
$stringList.Reverse()
```

#### Hashtables (Dictionaries)

Hashtables provide fast key-based lookups:

```powershell
# Hashtable creation
$serverInfo = @{
    Name = "Server01"
    OS = "Windows Server 2022"
    IP = "192.168.1.100"
    Services = @("IIS", "SQL Server", "DNS")
}

# Access and modify
$serverInfo["Name"]               # Server01
$serverInfo.Name                  # Alternative syntax
$serverInfo["Location"] = "DataCenter1"  # Add new key
$serverInfo.Remove("Services")    # Remove key

# Hashtable operations
$serverInfo.Keys                  # Get all keys
$serverInfo.Values               # Get all values
$serverInfo.ContainsKey("OS")    # Check if key exists

# Iterate through hashtable
foreach ($key in $serverInfo.Keys) 
{
    Write-Output "$key : $($serverInfo[$key])"
}
```

#### Ordered Collections

```powershell
# Ordered hashtable (maintains insertion order)
$orderedHash = [ordered]@{
    First = "Value1"
    Second = "Value2"
    Third = "Value3"
}

# Queue (First In, First Out)
$queue = New-Object System.Collections.Queue
$queue.Enqueue("First")
$queue.Enqueue("Second")
$firstOut = $queue.Dequeue()     # Returns "First"

# Stack (Last In, First Out)
$stack = New-Object System.Collections.Stack
$stack.Push("First")
$stack.Push("Second")
$lastOut = $stack.Pop()          # Returns "Second"
```

### Performance Considerations

**Avoid Array Concatenation in Loops:**

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

```powershell
# ❌ Slow - Creates new array each iteration
$results = @()
foreach ($i in 1..1000) 
{
    $results += "Item $i"        # Poor performance
}

# ✅ Fast - Use ArrayList or Generic List
$results = [System.Collections.Generic.List[string]]@()
foreach ($i in 1..1000) 
{
    $results.Add("Item $i")      # Excellent performance
}
```

**Performance Comparison:**

```powershell
# Measure performance difference
$iterations = 10000

$arrayTime = Measure-Command {
    $array = @()
    1..$iterations | ForEach-Object { $array += $_ }
}

$listTime = Measure-Command {
    $list = [System.Collections.Generic.List[int]]@()
    1..$iterations | ForEach-Object { $list.Add($_) }
}

Write-Output "Array: $($arrayTime.TotalMilliseconds)ms"
Write-Output "Generic List: $($listTime.TotalMilliseconds)ms"
```

---

## Control Structures

### Conditional Statements

#### If Statements

```powershell
# Basic if statement
$number = 10
if ($number -gt 5) 
{
    Write-Output "Number is greater than 5"
}

# If-else
if ($number -eq 10) 
{
    Write-Output "Number is exactly 10"
} 
else 
{
    Write-Output "Number is not 10"
}

# If-elseif-else
$grade = 85
if ($grade -ge 90) 
{
    Write-Output "Grade A"
} 
elseif ($grade -ge 80) 
{
    Write-Output "Grade B"
} 
elseif ($grade -ge 70) 
{
    Write-Output "Grade C"
} 
else 
{
    Write-Output "Grade F"
}
```

#### Switch Statements

Switch statements provide efficient multi-condition handling:

```powershell
# Basic switch
$dayOfWeek = (Get-Date).DayOfWeek
switch ($dayOfWeek) 
{
    "Monday"    { Write-Output "Start of work week" }
    "Friday"    { Write-Output "TGIF!" }
    "Saturday"  { Write-Output "Weekend!" }
    "Sunday"    { Write-Output "Weekend!" }
    default     { Write-Output "Regular work day" }
}

# Switch with pattern matching
$filename = "report.pdf"
switch -Regex ($filename) 
{
    "\.txt$"  { Write-Output "Text file" }
    "\.pdf$"  { Write-Output "PDF document" }
    "\.doc$"  { Write-Output "Word document" }
    default   { Write-Output "Unknown file type" }
}

# Switch with arrays
$numbers = @(1, 2, 3, 4, 5)
switch ($numbers) 
{
    {$_ -lt 3}  { Write-Output "$_ is less than 3" }
    {$_ -eq 3}  { Write-Output "$_ is exactly 3" }
    {$_ -gt 3}  { Write-Output "$_ is greater than 3" }
}
```

### Loops

#### For Loops

```powershell
# Traditional for loop
for ($i = 0; $i -lt 5; $i++) 
{
    Write-Output "Iteration: $i"
}

# For loop with step
for ($i = 0; $i -le 20; $i += 5) 
{
    Write-Output "Count: $i"
}

# Nested for loops
for ($row = 1; $row -le 3; $row++) 
{
    for ($col = 1; $col -le 3; $col++) 
    {
        Write-Output "Position: $row,$col"
    }
}
```

#### ForEach Loops

```powershell
# ForEach statement (fastest for arrays)
$services = Get-Service | Select-Object -First 5
foreach ($service in $services) 
{
    Write-Output "Service: $($service.Name) - Status: $($service.Status)"
}

# ForEach-Object (pipeline cmdlet)
Get-Process | ForEach-Object 
{
    if ($_.WorkingSet -gt 100MB) 
    {
        Write-Output "$($_.Name): $([Math]::Round($_.WorkingSet / 1MB))MB"
    }
}

# ForEach method (collection method)
$numbers = @(1, 2, 3, 4, 5)
$squared = $numbers.ForEach({$_ * $_})
```

#### While Loops

```powershell
# While loop
$counter = 0
while ($counter -lt 5) 
{
    Write-Output "Counter: $counter"
    $counter++
}

# Do-while loop (executes at least once)
$input = ""
do 
{
    $input = Read-Host "Enter 'exit' to quit"
    Write-Output "You entered: $input"
} while ($input -ne "exit")

# Do-until loop
$attempts = 0
do 
{
    $attempts++
    Write-Output "Attempt: $attempts"
    $success = Get-Random -Maximum 10 -lt 2  # 20% success rate
} until ($success -or $attempts -ge 5)
```

### Loop Control

```powershell
# Break - exit loop
foreach ($number in 1..10) 
{
    if ($number -eq 5) 
    {
        break  # Exit the loop
    }
    Write-Output $number
}

# Continue - skip current iteration
foreach ($number in 1..10) 
{
    if ($number % 2 -eq 0) 
    {
        continue  # Skip even numbers
    }
    Write-Output "Odd number: $number"
}

# Labeled breaks for nested loops
:outerLoop foreach ($i in 1..3) 
{
    foreach ($j in 1..3) 
    {
        if ($i -eq 2 -and $j -eq 2) 
        {
            break outerLoop  # Break out of both loops
        }
        Write-Output "i=$i, j=$j"
    }
}
```

---

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

---

## Output Stream Standards

### Understanding PowerShell Streams

PowerShell provides multiple output streams that allow developers to send different types of information to appropriate destinations:

| Stream | Stream Number | Description | Default Destination |
|--------|---------------|-------------|-------------------|
| Success (Output) | 1 | Standard output for pipeline objects | Console/Pipeline |
| Error | 2 | Error messages and exceptions | Console (red text) |
| Warning | 3 | Warning messages | Console (yellow text) |
| Verbose | 4 | Detailed operational information | Suppressed by default |
| Debug | 5 | Development and troubleshooting info | Suppressed by default |
| Information | 6 | Informational messages | Console |
| Progress | N/A | Progress indicators | Console (progress bars) |

### Stream Cmdlets and Usage

#### Write-Output - Standard Pipeline Output

Use for data that should flow through the PowerShell pipeline:

```powershell
function Get-ServerInfo 
{
    param([string]$ComputerName)
    
    # This data flows to the pipeline
    Write-Output [PSCustomObject]@{
        Name = $ComputerName
        Status = "Online"
        LastChecked = Get-Date
    }
}

# Can be captured and processed
$servers = Get-ServerInfo "Server01"
```

#### Write-Host - Console Display Only

Use for console messages that should not be captured:

```powershell
function Install-Application 
{
    param([string]$AppName)
    
    Write-Host "Starting installation of $AppName..." -ForegroundColor Green
    # Installation logic here
    Write-Host "Installation completed successfully!" -ForegroundColor Green
}
```

#### Write-Error - Error Messages

Use for error conditions and exceptions:

```powershell
function Get-UserAccount 
{
    param([string]$UserName)
    
    try 
    {
        $user = Get-ADUser $UserName -ErrorAction Stop
        return $user
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] 
    {
        Write-Error "User '$UserName' not found in Active Directory"
        return $null
    }
}
```

#### Write-Warning - Warning Messages

Use for conditions that require attention but aren't errors:

```powershell
function Set-ServerMaintenance 
{
    param([string]$ComputerName)
    
    $uptime = (Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName).LastBootUpTime
    if ((Get-Date) - $uptime -lt (New-TimeSpan -Days 30)) 
    {
        Write-Warning "Server $ComputerName has been running for less than 30 days"
    }
}
```

#### Write-Verbose - Detailed Information

Use for detailed operational information:

```powershell
function Backup-Database 
{
    [CmdletBinding()]
    param([string]$DatabaseName)
    
    Write-Verbose "Starting backup process for database: $DatabaseName"
    Write-Verbose "Checking database connectivity..."
    # Backup logic
    Write-Verbose "Backup completed successfully"
}

# Enable with -Verbose parameter or $VerbosePreference = "Continue"
Backup-Database -DatabaseName "MyDB" -Verbose
```

#### Write-Debug - Development Information

Use for debugging and development information:

```powershell
function Process-DataFile 
{
    [CmdletBinding()]
    param([string]$FilePath)
    
    Write-Debug "Processing file: $FilePath"
    Write-Debug "File size: $((Get-Item $FilePath).Length) bytes"
    # Processing logic
}

# Enable with -Debug parameter or $DebugPreference = "Continue"
Process-DataFile -FilePath "C:\data.txt" -Debug
```

#### Write-Information - Informational Messages

Use for structured informational output:

```powershell
function Deploy-Application 
{
    [CmdletBinding()]
    param([string]$ApplicationName)
    
    Write-Information "Deployment started for $ApplicationName" -InformationAction Continue
    
    # Deployment steps with structured information
    Write-Information @{
        Stage = "Validation"
        Status = "Complete"
        Timestamp = Get-Date
    } -InformationAction Continue
}
```

### Stream Redirection and Capture

#### Redirecting Streams

```powershell
# Redirect error stream to file
Get-Process "NonExistentProcess" 2> errors.txt

# Redirect verbose stream to file
Get-Process -Verbose 4> verbose.txt

# Redirect all streams to file
Get-Process * *> all_output.txt

# Redirect errors to success stream (combine streams)
Get-Process "NonExistentProcess" 2>&1
```

#### Capturing Streams in Variables

```powershell
# Capture different streams
$result = Get-Process 2>&1  # Captures both output and errors
$errors = Get-Process 2>&1 | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
$output = Get-Process 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
```

### Best Practices for Output Streams

#### 1. Choose the Right Stream

```powershell
function Get-SystemStatus 
{
    [CmdletBinding()]
    param()
    
    Write-Verbose "Checking system status..." # Development info
    
    $cpu = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average
    
    if ($cpu.Average -gt 80) 
    {
        Write-Warning "CPU usage is high: $($cpu.Average)%" # Warning condition
    }
    
    Write-Information "System check completed at $(Get-Date)" -InformationAction Continue # Info
    
    # Return structured data
    Write-Output [PSCustomObject]@{
        CPUUsage = $cpu.Average
        Status = if ($cpu.Average -gt 80) { "Warning" } else { "Normal" }
        CheckTime = Get-Date
    }
}
```

#### 2. Support Stream Preferences

```powershell
function Advanced-Function 
{
    [CmdletBinding()]
    param()
    
    # Respect user preferences
    Write-Verbose "Verbose message" # Shown only if $VerbosePreference allows
    Write-Debug "Debug information" # Shown only if $DebugPreference allows
    Write-Information "Info message" -InformationAction $InformationPreference
}
```

#### 3. Consistent Error Handling

```powershell
function Robust-Function 
{
    [CmdletBinding()]
    param([string]$Path)
    
    try 
    {
        if (-not (Test-Path $Path)) 
        {
            Write-Error "Path not found: $Path" -ErrorAction Stop
        }
        
        Write-Verbose "Processing path: $Path"
        # Main logic here
        
    } 
    catch 
    {
        Write-Error "Failed to process $Path`: $($_.Exception.Message)"
        throw
    }
}
```

### Stream Performance Considerations

- **Write-Host** is slower than other cmdlets as it bypasses the pipeline
- **Write-Output** is fastest for pipeline data
- **Stream redirection** has minimal performance impact
- **Verbose/Debug streams** should be used judiciously in performance-critical code

---

## Error Handling Fundamentals

### Understanding PowerShell Errors

PowerShell has two primary types of errors that developers must handle effectively:

**Terminating Errors**: Stop cmdlet or function processing immediately and cannot be ignored without proper handling.

**Non-Terminating Errors**: Generate error messages but allow processing to continue unless configured otherwise.

```powershell
# Non-terminating error example
Get-ChildItem "C:\NonExistentPath" -ErrorAction Continue

# Converting to terminating error
Get-ChildItem "C:\NonExistentPath" -ErrorAction Stop
```

### Error Action Preferences

Control how PowerShell responds to non-terminating errors using `$ErrorActionPreference` or the `-ErrorAction` parameter:

```powershell
# Global setting
$ErrorActionPreference = "Stop"  # Stop, Continue, SilentlyContinue, Inquire

# Per-cmdlet setting
Get-Process "NonExistentProcess" -ErrorAction SilentlyContinue
```

### Structured Error Handling

#### Try-Catch-Finally Blocks

```powershell
try 
{
    # Risky operation
    $user = Get-ADUser $username -ErrorAction Stop
    Write-Verbose "Successfully retrieved user: $($user.Name)"
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
    Write-Warning "User '$username' not found in Active Directory"
    return $null
}
catch [System.UnauthorizedAccessException]
{
    Write-Error "Insufficient permissions to access Active Directory"
    throw
}
catch 
{
    Write-Error "Unexpected error: $($_.Exception.Message)"
    Write-Debug "Full exception: $($_.Exception | Out-String)"
    throw
}
finally 
{
    # Cleanup operations (always executes)
    Write-Verbose "Cleaning up resources"
}
```

### Automatic Error Variables

PowerShell provides built-in variables for error information:

```powershell
# $Error array contains recent errors
Write-Output "Last error: $($Error[0])"
Write-Output "Error count: $($Error.Count)"

# $? indicates success/failure of last command
Get-Process "ValidProcess"
Write-Output "Command succeeded: $?"

# $_ in catch blocks contains current error
try { throw "Test error" }
catch { Write-Output "Error message: $($_.Exception.Message)" }
```

### Best Practices for Error Handling

1. **Use specific exception types** when possible
2. **Set -ErrorAction Stop** for operations in try blocks
3. **Provide meaningful error messages** without exposing sensitive data
4. **Log errors appropriately** for debugging and monitoring
5. **Clean up resources** in finally blocks

### When to Use Write-Error vs Throw

Understanding when to use `Write-Error` versus `throw` is crucial for proper error handling in PowerShell:

#### Use Write-Error When

- **Non-terminating errors**: The function should continue processing other items
- **Validation failures**: Input validation that shouldn't stop the entire script
- **Recoverable conditions**: Errors that the calling code can handle gracefully
- **Logging errors**: You want to record the error but continue execution

```powershell
function Get-UserInfo 
{
    param([string[]]$UserNames)
    
    foreach ($user in $UserNames) 
    {
        try 
        {
            $userInfo = Get-ADUser $user -ErrorAction Stop
            Write-Output $userInfo
        }
        catch 
        {
            # Use Write-Error to report the problem but continue with next user
            Write-Error "Failed to get information for user '$user': $($_.Exception.Message)"
            # Continue processing other users
        }
    }
}

# This will process all users, even if some fail
Get-UserInfo -UserNames @("validuser", "invaliduser", "anotheruser")
```

#### Use Throw When

- **Critical failures**: Conditions that make it impossible to continue
- **Re-throwing exceptions**: After logging or partial handling in catch blocks
- **Invalid states**: When the function cannot fulfill its primary purpose
- **Resource failures**: Database connections, file access, etc.

```powershell
function Initialize-DatabaseConnection 
{
    param([string]$ConnectionString)
    
    try 
    {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        return $connection
    }
    catch 
    {
        Write-Error "Database connection failed: $($_.Exception.Message)"
        # Use throw because the function cannot fulfill its primary purpose
        throw "Unable to establish database connection. Operation cannot continue."
    }
}

# This will stop execution if database connection fails
$db = Initialize-DatabaseConnection -ConnectionString $connString
```

#### Decision Matrix

| Scenario | Use Write-Error | Use Throw | Reason |
|----------|----------------|-----------|---------|
| Processing multiple items | ✅ | ❌ | Allow processing of remaining items |
| Critical resource failure | ❌ | ✅ | Cannot continue without the resource |
| Input validation failure | ✅ | ❌ | Caller may want to retry with different input |
| System configuration error | ❌ | ✅ | Fundamental issue that prevents operation |
| Network timeout | ✅ | ❌ | Temporary condition, may succeed on retry |
| Security violation | ❌ | ✅ | Critical failure requiring immediate attention |

#### Best Practice Examples

```powershell
function Process-Files 
{
    param([string[]]$FilePaths)
    
    $results = @()
    
    foreach ($file in $FilePaths) 
    {
        try 
        {
            if (-not (Test-Path $file)) 
            {
                # Non-terminating - continue with other files
                Write-Error "File not found: $file"
                continue
            }
            
            $content = Get-Content $file -ErrorAction Stop
            $results += [PSCustomObject]@{
                File = $file
                LineCount = $content.Count
                Status = "Success"
            }
        }
        catch 
        {
            # Log the error but continue processing
            Write-Error "Failed to process file '$file': $($_.Exception.Message)"
            $results += [PSCustomObject]@{
                File = $file
                LineCount = 0
                Status = "Error"
            }
        }
    }
    
    return $results
}

function Connect-ToService 
{
    param([string]$ServiceUrl, [PSCredential]$Credential)
    
    if (-not $Credential) 
    {
        # Critical failure - cannot proceed without credentials
        throw "Credentials are required for service connection"
    }
    
    try 
    {
        $service = New-WebServiceProxy -Uri $ServiceUrl -Credential $Credential
        Test-Connection $service  # Verify connection works
        return $service
    }
    catch 
    {
        Write-Error "Service connection failed: $($_.Exception.Message)"
        # Re-throw because the function cannot fulfill its purpose
        throw "Unable to establish service connection to $ServiceUrl"
    }
}
```

---

## Best Practices

### Code Organization and Structure

#### Script Structure Standards

Following the [Allman formatting style](scripts.md#allman-formatting-style) defined in our PowerShell scripting guidelines:

```powershell
<#
.SYNOPSIS
    Comprehensive user management script following best practices.
.DESCRIPTION
    Demonstrates proper PowerShell script structure, error handling,
    and documentation standards.
.PARAMETER UserName
    The username to process.
.PARAMETER Action
    The action to perform (Create, Modify, Validate).
.EXAMPLE
    .\UserManagement.ps1 -UserName "jdoe" -Action "Create"
.NOTES
    Author: Your Name
    Version: 1.0
    Last Modified: 2025-08-20
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$UserName,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create", "Modify", "Validate")]
    [string]$Action
)

# Import required modules
if (-not (Get-Module -Name ActiveDirectory -ListAvailable))
{
    throw "ActiveDirectory module is required but not available"
}
Import-Module ActiveDirectory -ErrorAction Stop

# Main execution
try
{
    Write-Verbose "Processing user: $UserName with action: $Action"
    
    switch ($Action)
    {
        "Create" 
        {
            # Creation logic
        }
        "Modify" 
        {
            # Modification logic  
        }
        "Validate" 
        {
            # Validation logic
        }
    }
}
catch
{
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}
```

### Parameter Validation and Security

#### Comprehensive Parameter Validation

```powershell
function New-UserAccount
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(3, 20)]
        [ValidatePattern('^[a-zA-Z][a-zA-Z0-9_-]*$')]
        [string]$UserName,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FirstName,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LastName,
        
        [Parameter()]
        [ValidateScript({
            if (Test-Path (Split-Path $_ -Parent))
            {
                $true
            }
            else
            {
                throw "Directory does not exist: $(Split-Path $_ -Parent)"
            }
        })]
        [string]$LogPath = "$PSScriptRoot\UserManagement.log",
        
        [Parameter()]
        [ValidateRange(1, 365)]
        [int]$PasswordExpirationDays = 90
    )
    
    # Function implementation
}
```

#### Secure Credential Handling

```powershell
# ❌ Never do this - hardcoded credentials
$username = "admin"
$password = "P@ssw0rd"

# ✅ Proper credential handling
$credential = Get-Credential -Message "Enter service account credentials"

# ✅ For automation scenarios
$securePassword = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("admin", $securePassword)

# ✅ Using Windows Credential Manager
$credential = Get-StoredCredential -Target "MyApplication"
```

### Performance Optimization

#### Collection Performance

```powershell
# ❌ Inefficient - array concatenation
$results = @()
foreach ($item in $largeCollection)
{
    $results += $item  # Creates new array each time
}

# ✅ Efficient - Generic List
$results = [System.Collections.Generic.List[object]]@()
foreach ($item in $largeCollection)
{
    $results.Add($item)  # Fast insertion
}

# ✅ Most efficient - pipeline when possible
$results = $largeCollection | Where-Object { $_.Property -eq "Value" }
```

#### Memory Management

```powershell
# Clear variables when done with large datasets
$largeDataset = Get-VeryLargeDataset
# Process the data
$results = $largeDataset | Process-Data
# Clear the large dataset from memory
$largeDataset = $null
[System.GC]::Collect()  # Force garbage collection if needed
```

### Error Handling Standards

#### Advanced Error Handling Patterns

```powershell
function Get-UserInformation
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    
    try
    {
        # Attempt to get user
        $user = Get-ADUser $UserName -ErrorAction Stop
        Write-Verbose "Successfully retrieved user: $($user.Name)"
        return $user
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        Write-Warning "User '$UserName' not found in Active Directory"
        return $null
    }
    catch [System.Security.Authentication.AuthenticationException]
    {
        Write-Error "Authentication failed. Check your credentials and permissions."
        throw
    }
    catch
    {
        Write-Error "Unexpected error retrieving user '$UserName': $($_.Exception.Message)"
        Write-Debug "Full exception details: $($_ | Out-String)"
        throw
    }
}
```

---

## Development Resources

### Specialized PowerShell Documentation

This repository contains comprehensive documentation for advanced PowerShell development topics:

#### Core Development Guides

- **[Functions](functions.md)** - Advanced function development, parameter validation, pipeline input
- **[Scripts](scripts.md)** - Script structure, formatting standards, quality assurance
- **[Modules](modules.md)** - Module creation, distribution, and management
- **[Cmdlets](cmdlets.md)** - Custom cmdlet development and compilation

#### Advanced Topics

- **[Remote Execution](remoteexecution.md)** - PowerShell remoting, sessions, and distributed computing
- **[Runspaces](powershellrunspaces.md)** - Multi-threading and parallel processing
- **[Troubleshooting](troubleshooting.md)** - Debugging techniques and problem resolution
- **[Tips and Tricks](tipsandtricks.md)** - Advanced techniques and optimization strategies

#### Platform-Specific Guides

- **[Azure Examples](examples/azure.md)** - Azure resource management and automation
- **[Active Directory Examples](examples/activedirectory.md)** - AD administration and management
- **[Exchange Examples](examples/exchange.md)** - Exchange Server and Online management
- **[Entra ID Examples](examples/entraid.md)** - Modern identity management

### Official Microsoft Resources

#### PowerShell Documentation

- **[PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)** - Complete official documentation
- **[PowerShell Gallery](https://www.powershellgallery.com/)** - Community modules and scripts
- **[PowerShell GitHub Repository](https://github.com/PowerShell/PowerShell)** - Source code and issues
- **[PowerShell Community](https://docs.microsoft.com/en-us/powershell/scripting/community/community-support)** - Community resources

#### Learning Resources

- **[Microsoft Learn - PowerShell](https://docs.microsoft.com/en-us/learn/browse/?products=powershell)** - Interactive learning modules
- **[PowerShell in Action](https://www.manning.com/books/powershell-in-action-third-edition)** - Comprehensive book by Bruce Payette
- **[Learn PowerShell in a Month of Lunches](https://www.manning.com/books/learn-powershell-in-a-month-of-lunches)** - Beginner-friendly approach

### Development Tools

#### Editors and IDEs

- **[Visual Studio Code](https://code.visualstudio.com/)** with PowerShell Extension
- **[PowerShell ISE](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/ise/introducing-the-windows-powershell-ise)** (Windows only)
- **[Azure Cloud Shell](https://shell.azure.com/)** - Browser-based PowerShell environment

#### Quality Assurance Tools

- **[PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)** - Static code analysis
- **[Pester](https://pester.dev/)** - PowerShell testing framework  
- **[Plaster](https://github.com/PowerShell/Plaster)** - Template-based project scaffolding

### Community Resources

#### Forums and Discussion

- **[PowerShell.org Community](https://powershell.org/)** - Active PowerShell community
- **[Reddit r/PowerShell](https://www.reddit.com/r/PowerShell/)** - Community discussions
- **[Stack Overflow PowerShell Tag](https://stackoverflow.com/questions/tagged/powershell)** - Q&A platform
- **[PowerShell Discord](https://discord.gg/powershell)** - Real-time community chat

#### Blogs and Content

- **[PowerShell Team Blog](https://devblogs.microsoft.com/powershell/)** - Official team updates
- **[Hey, Scripting Guy! Blog](https://devblogs.microsoft.com/scripting/)** - Microsoft scripting resources
- **[PowerShell Magazine](https://powershellmagazine.com/)** - Community-driven content
- **[Adam the Automator](https://adamtheautomator.com/powershell/)** - Practical tutorials

---

## Footnotes and References

¹ **Jeffrey Snover Quote**: Snover, J. (2016). *The Monad Manifesto - The Origin of PowerShell*. Microsoft TechEd. Available at: [Monad Manifesto](https://www.jsnover.com/blog/2011/10/01/monad-manifesto/)

² **PowerShell Architecture**: Microsoft Corporation. (2024). *PowerShell Architecture and Components*. Available at: [PowerShell Architecture](https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/01-getting-started)

³ **Cross-Platform PowerShell**: Microsoft Corporation. (2024). *Installing PowerShell on Linux*. Available at: [Installing PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux)

⁴ **PowerShell Performance**: Microsoft Corporation. (2024). *PowerShell Performance Best Practices*. Available at: [Performance Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays)

⁵ **Error Handling**: Microsoft Corporation. (2024). *Everything you wanted to know about exceptions*. Available at: [Exception Handling](https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-exceptions)

⁶ **PowerShell Security**: Microsoft Corporation. (2024). *PowerShell Security Best Practices*. Available at: [Security Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/running-remote-commands)

### Additional References

- **[About Variables](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_variables)** - Microsoft documentation on PowerShell variables
- **[About Comparison Operators](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators)** - Complete operator reference  
- **[About Functions](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions)** - Function development guide
- **[Building Arrays and Collections in PowerShell](https://vexx32.github.io/2020/02/15/Building-Arrays-Collections/)** - Community guide to collections
- **[PowerShell Language Specification](https://docs.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-01)** - Official language specification
- **[PowerShell Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)** - Community style and best practices guide

---

*This comprehensive PowerShell guide serves as the foundation for all PowerShell development in this repository. For specialized topics, refer to the individual documentation files linked in the Development Resources section above.*
