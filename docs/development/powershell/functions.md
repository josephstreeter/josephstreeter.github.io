# Functions

Functions in PowerShell allow you to group code into reusable blocks, making scripts easier to read, maintain, and test. Functions can accept parameters, return values, and support advanced features such as parameter validation and pipeline input. A simple function groups code for reuse.

Here's a basic example:

```powershell
function Get-Greeting
{
    param($Name)
    "Hello, $Name!"
}

Get-Greeting -Name "Alice"
```

- [PowerShell Functions: A Comprehensive Beginner’s Guide](https://www.sharepointdiary.com/2021/11/powershell-function.html)
- [PowerShell Function Parameters: A Beginner’s Guide](https://www.sharepointdiary.com/2021/02/powershell-function-parameters.html)

## Difference Between a Function and a Cmdlet

| Feature         | Function                          | Cmdlet                        |
|-----------------|-----------------------------------|-------------------------------|
| Implementation  | Written in PowerShell script      | Written in .NET (C#, VB.NET)  |
| Performance     | Slightly slower                   | Faster                        |
| Extensibility   | Easy to create and modify         | Requires compilation          |
| Naming          | Verb-Noun                         | Verb-Noun                     |
| Access to Common Parameters | Yes                   | Yes                           |

## Building a Function

### Verb-Noun Naming

PowerShell uses a Verb-Noun naming convention for functions and cmdlets to promote consistency and discoverability. Always use an approved verb for your function name. You can see the list of approved verbs with:

```powershell
Get-Verb | Sort-Object Verb
```

- [Approved Verbs for PowerShell Commands](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.4)

## Basic Function Example

A simple function groups code for reuse. Here’s a basic example:

```powershell
function Get-Greeting {
    param($Name)
    "Hello, $Name!"
}

Get-Greeting -Name "Alice"
```

## Advanced Functions

An **advanced function** in PowerShell is a function that uses the `[CmdletBinding()]` attribute and parameter attributes to provide features similar to compiled cmdlets. Advanced functions support common parameters (like `-Verbose` and `-ErrorAction`), parameter validation, pipeline input, parameter sets, and more. This allows you to write powerful, flexible, and robust functions using only PowerShell

[Learn - About_Functions_Advanced_Parameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters)

```powershell
function New-Employee()
{
    <#
    .Synopsis
    Creates a new employee

    .DESCRIPTION
    This function creates a new employee. It really just returns the information
    as an example of an Advanced Function.

    .PARAMETER FirstName
    Person's legal given name.
    
    .PARAMETER LastName
    Person's legal surname.

    .PARAMETER Initial
    Person's legal middle initial.

    .PARAMETER DateOfBirth
    Person's date of birth.

    .PARAMETER EmployeeType
    Employee Type. Acceptable values are "PartTime", "FullTime", "Contractor."

    .INPUTS
    None. You cannot pipe objects to this function.

    .OUTPUTS
    PSObject containing the new employee's information.

    .EXAMPLE
    New-Employee -FirstName Jon -LastName Dutton -Initial J -DateOfBirth 1957-10-12

    .EXAMPLE
    New-Employee -GivenName Jon -Surname Dutton -DoB J -DateOfBirth 1957-10-12

    .EXAMPLE
    New-Employee -FirstName Jon -LastName Dutton -DateOfBirth 1957-10-12

    .LINK
    http://www.company.com/PowerShell/Employee.html
    #>

    [CmdletBinding()]
    [OutputType([HashTable])] # <- Makes sure that a hashtable is returned by the function
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [Alias("GivenName")]
        [string]$FirstName,
        
        [Parameter(Mandatory=$true, Position=1)]
        [Alias("Surname")]
        [string]$LastName,
        
        [Parameter(Mandatory=$false, Position=2)]
        [Alias("MiddleName","MI")]
        [ValidateLength(0,2)]
        [string]$Initial,
        
        [Parameter(Mandatory=$true)]
        [datetime]$DateOfBirth,
        
        [Parameter(Mandatory=$false,ValueFromPipeline)]
        [ValidateSet('FullTime','PArtTime','Contractor')]
        [string]$EmployeeType
    )

    Try
    {
        $Results = @{
            FirstName = $FirstName
            LastName = $LastName
            DateOfBirth = $DateOfBirth
            EmployeeType = $EmployeeType
            UserID = ("{0}{1}" -f $FirstName.Substring(0,1),$LastName)
        }

        if ($Initial)
        {
            $Results.Add("Initial", $Initial)
            $Results.Add("DisplayName", ("{0}, {1} {2}" -f $LastName, $FirstName, $Initial))
        }
        else
        {
            $Results.Add("DisplayName", ("{0}, {1}" -f $LastName, $FirstName))
        }
    }
    Catch
    {
        Write-Error ("Error creating new employee: {0}" -f $_.Exception.Message)
    }

    Return $Results
}
```

### Output Type

```powershell
[OutputType([bool])]
```

```powershell
function Get-Something()
{
    [CmdletBinding()]
    [OutputType([string])] # <- Makes sure that a string is returned by the function
    Param
    (
        [Parameter(Mandatory=$true)][string]$Name
    )

    $Results = "This is a string"

    Return $Results
}
```

### Parameters

### Common Parameters

### Making a Parameter Mandatory

### Providing a Default Value

### Parameter Validation

Parameter validation attributes help ensure that input to your function meets specific requirements. These attributes can check for value ranges, patterns, allowed values, null or empty values, and more. This helps catch errors early and makes your functions more robust.

- **ValidateCount** - Specifies the minimum and maximum number of arguments that a parameter can accept.

    ```powershell
    Function Test-Validation
    {
        [cmdletbinding()]
        Param
        (
            [parameter(ValueFromPipeline)][ValidateCount(1,4)][string[]]$Value
        )
        
        Process 
        {
            $Value
        }
    }

    # This will pass validation because the count is within the range
    Test-Validation -Item 9,10

    # This will fail validation because the count is outide the range
    Test-Validation -Item 9,6,7,8,9
    ```

- **ValidateLength** - Specifies the minimum and maximum number of characters in the parameter argument.

    ```powershell

    ```

- **ValidatePattern** - Specifies a regular expression that validates the parameter argument.

    ```powershell
    Function Test-Validation 
    {
        [cmdletbinding()]
        Param
        (
            [parameter(ValueFromPipeline)]
            [ValidatePattern('^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')]
            [string[]]$Value
        )
        
        Process 
        {
            $Value
        }
    }
        
    # This will pass validation because the number is within the range
    Test-Validation -Value 192.168.1.101
    Test-Validation -Value 192.168.1.101,168.125.12.15

    # Will not work; note the error shows the regex, which only helps those that know regex
    Test-Validation -Value 'Day'
    Test-Validation -Value 1
    Test-Validation -Value 192.168.1
    ```

- **ValidateRange** - Specifies the minimum and maximum values of the parameter argument.

    ```powershell
    Function Test-Validation 
    {
        [cmdletbinding()]
        Param
        (
            [parameter(ValueFromPipeline)][ValidateRange(16,21)][int[]]$Value
        )

        Process 
        {
            $Value
        }
    }

    # This will pass validation because the number is within the range
    Test-Validation -Value 18

    # These will fail validation because the numbers are outside of the specified range
    Test-Validation -Value 1
    Test-Validation -Value 63
    ```

- **ValidateScript** - Specifies the valid values for the parameter argument. For more information.

    ```powershell

    ```

- **ValidateSet** - Specifies the valid values for the parameter argument.

    ```powershell
    Function Test-Validation 
    {
        [cmdletbinding()]
        Param
        (
            [parameter(ValueFromPipeline)][ValidateSet('Day','Hour','Minute')][string[]]$Value
        )
        
        Process 
        {
            $Value
        }
    }

    # This will pass validation because 'Day' is in the set
    Test-Validation -Value 'Day'

    # This will fail validation because 'Week' is not in the set
    Test-Validation -Value 'Week'

    # This will fail validation because neither 'Week' or 'Month' is in the set
    Test-Validation -Value 'Week', 'Month'
    ```

- **ValidateNotNull** - Checks to see if the value being passed to the parameter is a null value. Will an empty string.

    ```powershell
    Function Test-Validation 
    {
        [cmdletbinding()]
        Param
        (
            [parameter(ValueFromPipeline)][ValidateNotNull()][string]$Value
        )

        Process 
        {
            $Value
        }
    }

    # This will fail validation because of null value
    Test-Validation -Value $Null

    # This will pass validation because value is empty string, not a null value
    Test-Validation -Value ''

    # This will pass validation because value is empty collection, not a null value
    Test-Validation -Value @()
    ```

- **ValidateNotNullorEmpty** also checks to see if the value being passed is a null value and if it is an empty string or collection.

    ```powershell
    Function Test-Validation 
    {
        [cmdletbinding()]
        Param
        (
            [parameter(ValueFromPipeline)][ValidateNotNullOrEmpty()][string]$Value
        )

        Process 
        {
            $Value
        }
    }

    # All three of these will fail validation because of empty string or null values 
    Test-Validation -Value $Null
    Test-Validation -Value ''
    Test-Validation -Value @()
    ```

### Input Filter Parameters

- [Input Filter Parameters - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/input-filter-parameters?view=powershell-7.4)

### Parameter Sets

- [Cmdlet parameter sets](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-parameter-sets?view=powershell-7.4)

### General Common Parameters

[General Common Parameters - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/common-parameter-names?view=powershell-7.4)

## Accepting Pipeline Input

Functions can accept input from the pipeline, allowing you to process data passed from other commands. To enable this, use the `ValueFromPipeline` or `ValueFromPipelineByPropertyName` parameter attributes.

```powershell
function Show-Item
{
    param
    (
        [Parameter(ValueFromPipeline)]
        [string]$Name
    )
    process
    {
        Write-Host "Item: $Name"
    }
}

"Apple","Banana" | Show-Item
```

## Begin, Process, End Blocks

Advanced functions can use `begin`, `process`, and `end` blocks to handle pipeline input efficiently:

- **begin**: Runs once before any pipeline input is processed (setup).
- **process**: Runs once for each item received from the pipeline (main processing).
- **end**: Runs once after all pipeline input has been processed (cleanup).

Example:

```powershell
function ConvertTo-Upper
{
    [CmdletBinding()]
    param 
    (
        [Parameter(ValueFromPipeline)]
        [string[]]$InputString
    )

    begin
    {
        # This block runs once at the start
        Write-Host "Starting conversion to uppercase..."
    }

    process
    {
        # This block runs for each item in the pipeline
        $UpperString = $InputString.ToUpper()
        Write-Host "Converted: $UpperString"
    }

    end
    {
        # This block runs once at the end
        Write-Host "Conversion complete."
    }
}

"hello", "world" | ConvertTo-Upper
```

## References

- [about_Functions - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions)
- [about_Functions_Advanced - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced)
- [about_Functions_Advanced_Parameters - Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters)
