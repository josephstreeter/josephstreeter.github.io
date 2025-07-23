# PowerShell Script Writing Guide

This document provides guidelines for writing PowerShell scripts in a consistent and maintainable manner. It covers naming conventions, script structure, and best practices to ensure clarity and efficiency in your scripts.

## Script Structure

PowerShell scripts should follow a clear and consistent structure to enhance readability and maintainability. A typical script structure includes the following elements:

1. **Header Comments**: Include a comment block at the beginning of the script to describe its purpose, author, and date. This helps others (and your future self) understand the script's intent quickly.

2. **Param Block**: If your script accepts parameters, define them in a `param` block at the beginning. This makes it clear what inputs the script expects.

3. **Function Definitions**: Organize your code into functions to promote reusability and clarity. Each function should have a clear purpose and be documented with comments.

4. **Main Script Logic**: After defining functions, include the main logic of your script. This is where you call your functions and implement the core functionality.

5. **Error Handling**: Implement error handling throughout your script to manage exceptions gracefully. Use `try/catch` blocks where appropriate.

6. **Footer Comments**: Include a comment block at the end of the script to summarize its functionality and any important notes.

By following this structure, you can create PowerShell scripts that are easier to read, understand, and maintain.

## Code Formatting Standards

### Allman Formatting Style

PowerShell scripts should follow the **Allman formatting style** (also known as BSD style) for consistent code structure and readability:

#### Brace Placement

- **Opening braces on new line**: Place opening braces `{` on a new line, aligned with the statement
- **Closing braces aligned**: Closing braces `}` align with the opening statement
- **Consistent indentation**: Use tabs for indentation (as specified in coding instructions)

```powershell
# ✅ Correct Allman style
function Get-UserInformation
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    
    if ($UserName -eq "admin")
    {
        Write-Output "Administrator account detected"
    }
    else
    {
        Write-Output "Regular user account"
    }
}

# ❌ Avoid - Inline braces
function Get-UserInformation {
    param([string]$UserName)
    if ($UserName -eq "admin") {
        Write-Output "Administrator account detected"
    } else {
        Write-Output "Regular user account"
    }
}
```

#### Control Structures

Apply Allman style to all control structures:

```powershell
# If statements
if ($condition)
{
    # Code block
}
elseif ($otherCondition)
{
    # Code block
}
else
{
    # Code block
}

# Loops
foreach ($item in $collection)
{
    # Process item
}

while ($condition)
{
    # Loop body
}

# Try-catch blocks
try
{
    # Risky operation
}
catch
{
    # Error handling
}
finally
{
    # Cleanup
}
```

#### Benefits of Allman Style

- **Visual clarity**: Clear separation between statement and code block
- **Easier debugging**: Easier to set breakpoints on opening braces
- **Consistent readability**: Uniform appearance across all scripts
- **Industry standard**: Widely adopted in PowerShell community

## Naming Conventions

When naming scripts, functions, and variables, adhere to the following conventions:

1. **Use Descriptive Names**: Choose names that clearly describe the purpose or functionality of the script, function, or variable. Avoid vague names like `Script1` or `TempVar`.

2. **CamelCase for Functions and Variables**: Use CamelCase for function names and variable names (e.g., `Get-UserInfo`, `$userName`).

3. **Prefix Script Names**: Prefix script names with a category or module name to avoid naming conflicts (e.g., `Networking_Get-IPAddress.ps1`).

4. **Use Verb-Noun Pairs for Functions**: Name functions using a verb-noun pair to indicate their action (e.g., `Get-User`, `Set-Configuration`).

5. **Avoid Abbreviations**: Use full words instead of abbreviations to enhance readability (e.g., use `Configuration` instead of `Config`).

6. **Consistent Naming Patterns**: Stick to a consistent naming pattern throughout your scripts to make them easier to understand and maintain.

By following these naming conventions, you can create PowerShell scripts that are more intuitive and easier to work with.

## Step-by-Step Script Example

Let's walk through creating a complete PowerShell script that follows all the best practices outlined in this guide. We'll create a script that manages user accounts and demonstrates proper structure, formatting, and documentation.

### Step 1: Create the Script Header

Start with comprehensive header comments that describe the script's purpose:

```powershell
<#
.SYNOPSIS
    Manages Active Directory user accounts with comprehensive validation and logging.

.DESCRIPTION
    This script provides functionality to create, modify, and validate user accounts
    in Active Directory. It includes proper error handling, logging, and follows
    PowerShell best practices for enterprise environments.

.PARAMETER UserName
    The username for the account to be managed.

.PARAMETER Action
    The action to perform: Create, Modify, or Validate.

.PARAMETER LogPath
    Path to the log file. Defaults to script directory.

.EXAMPLE
    .\Manage-UserAccounts.ps1 -UserName "jdoe" -Action "Create"
    Creates a new user account for John Doe.

.EXAMPLE
    .\Manage-UserAccounts.ps1 -UserName "jsmith" -Action "Validate" -LogPath "C:\Logs"
    Validates an existing user account and logs to specified path.

.NOTES
    Author: Your Name
    Date: $(Get-Date -Format 'yyyy-MM-dd')
    Version: 1.0
    Requires: ActiveDirectory module, appropriate permissions

.LINK
    https://docs.microsoft.com/en-us/powershell/module/activedirectory/
#>
```

### Step 2: Define Parameters with Validation

Use the `[CmdletBinding()]` attribute and proper parameter validation:

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Enter the username")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(3, 20)]
    [string]$UserName,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create", "Modify", "Validate")]
    [string]$Action,
    
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
    [string]$LogPath = "$PSScriptRoot\UserManagement.log"
)
```

### Step 3: Create Helper Functions

Organize code into reusable functions with proper documentation:

```powershell
function Write-LogMessage
{
    <#
    .SYNOPSIS
        Writes timestamped messages to log file and console.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$TimeStamp] [$Level] $Message"
    
    # Write to console with appropriate stream
    switch ($Level)
    {
        "Info" { Write-Host $LogEntry -ForegroundColor Green }
        "Warning" { Write-Warning $LogEntry }
        "Error" { Write-Error $LogEntry }
    }
    
    # Write to log file
    try
    {
        Add-Content -Path $LogPath -Value $LogEntry -ErrorAction Stop
    }
    catch
    {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
}

function Test-UserAccountExists
{
    <#
    .SYNOPSIS
        Checks if a user account exists in Active Directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    
    try
    {
        $User = Get-ADUser -Identity $UserName -ErrorAction Stop
        return $true
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        return $false
    }
    catch
    {
        Write-LogMessage -Message "Error checking user existence: $($_.Exception.Message)" -Level "Error"
        throw
    }
}

function New-UserAccount
{
    <#
    .SYNOPSIS
        Creates a new Active Directory user account.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    
    Write-LogMessage -Message "Starting user creation process for: $UserName"
    
    try
    {
        if (Test-UserAccountExists -UserName $UserName)
        {
            Write-LogMessage -Message "User already exists: $UserName" -Level "Warning"
            return $false
        }
        
        $SecurePassword = ConvertTo-SecureString "TempPassword123!" -AsPlainText -Force
        
        $UserParams = @{
            Name = $UserName
            SamAccountName = $UserName
            UserPrincipalName = "$UserName@$env:USERDNSDOMAIN"
            AccountPassword = $SecurePassword
            Enabled = $true
            ChangePasswordAtLogon = $true
        }
        
        New-ADUser @UserParams -ErrorAction Stop
        Write-LogMessage -Message "Successfully created user: $UserName"
        return $true
    }
    catch
    {
        Write-LogMessage -Message "Failed to create user $UserName`: $($_.Exception.Message)" -Level "Error"
        throw
    }
}
```

### Step 4: Implement Main Script Logic

Use proper error handling and clear logic flow:

```powershell
# Main script execution
Write-LogMessage -Message "Script started with Action: $Action, UserName: $UserName"

try
{
    # Import required module
    if (-not (Get-Module -Name ActiveDirectory -ListAvailable))
    {
        throw "ActiveDirectory module is not available. Please install RSAT tools."
    }
    
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-LogMessage -Message "ActiveDirectory module imported successfully"
    
    # Execute based on action parameter
    switch ($Action)
    {
        "Create"
        {
            $Result = New-UserAccount -UserName $UserName
            if ($Result)
            {
                Write-LogMessage -Message "User creation completed successfully"
            }
        }
        
        "Validate"
        {
            $Exists = Test-UserAccountExists -UserName $UserName
            if ($Exists)
            {
                Write-LogMessage -Message "User validation successful: $UserName exists"
            }
            else
            {
                Write-LogMessage -Message "User validation failed: $UserName does not exist" -Level "Warning"
            }
        }
        
        "Modify"
        {
            if (Test-UserAccountExists -UserName $UserName)
            {
                Write-LogMessage -Message "User modification functionality not yet implemented" -Level "Warning"
            }
            else
            {
                Write-LogMessage -Message "Cannot modify non-existent user: $UserName" -Level "Error"
            }
        }
    }
}
catch
{
    Write-LogMessage -Message "Script execution failed: $($_.Exception.Message)" -Level "Error"
    exit 1
}
finally
{
    Write-LogMessage -Message "Script execution completed"
}
```

### Step 5: Add Footer Comments

Complete the script with summary information:

```powershell
<#
.FOOTER
    This script demonstrates PowerShell best practices including:
    - Comprehensive parameter validation
    - Proper error handling with try/catch blocks
    - Allman formatting style for readability
    - Detailed logging and user feedback
    - Modular function design for reusability
    - Complete comment-based help documentation
    
    For production use, consider adding:
    - Configuration file support
    - More robust credential handling
    - Additional user property management
    - Integration with company policies
#>
```

## Using PSScriptAnalyzer for Code Quality

### What is PSScriptAnalyzer?

**PSScriptAnalyzer** is a static code analysis tool for PowerShell that checks scripts against best practices and coding standards. It helps identify potential issues, security problems, and style violations before deployment.

### Installing PSScriptAnalyzer

```powershell
# Install from PowerShell Gallery
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force

# Verify installation
Get-Module PSScriptAnalyzer -ListAvailable
```

### Basic Usage

#### Analyzing a Single Script

```powershell
# Analyze a script file
Invoke-ScriptAnalyzer -Path "C:\Scripts\MyScript.ps1"

# Get detailed output
Invoke-ScriptAnalyzer -Path "C:\Scripts\MyScript.ps1" -Severity @('Error', 'Warning', 'Information')

# Save results to file
Invoke-ScriptAnalyzer -Path "C:\Scripts\MyScript.ps1" | Out-File "C:\Reports\Analysis.txt"
```

#### Analyzing Multiple Scripts

```powershell
# Analyze all scripts in a directory
Invoke-ScriptAnalyzer -Path "C:\Scripts\" -Recurse

# Analyze with specific rules
Invoke-ScriptAnalyzer -Path "C:\Scripts\" -IncludeRule @('PSAvoidUsingPlainTextForPassword', 'PSUseDeclaredVarsMoreThanAssignments')

# Exclude specific rules
Invoke-ScriptAnalyzer -Path "C:\Scripts\" -ExcludeRule @('PSAvoidUsingWriteHost')
```

### Common Rules and Fixes

#### Security Rules

```powershell
# ❌ Problematic - Plain text password
$Password = "MySecretPassword"

# ✅ Correct - Secure string
$SecurePassword = Read-Host -AsSecureString "Enter password"
$SecurePassword = ConvertTo-SecureString "Password" -AsPlainText -Force

# ❌ Problematic - Hardcoded credentials
$Credential = New-Object System.Management.Automation.PSCredential("user", "password")

# ✅ Correct - Proper credential handling
$Credential = Get-Credential
```

#### Performance Rules

```powershell
# ❌ Problematic - Using Where-Object when not needed
Get-Process | Where-Object ProcessName -eq "notepad"

# ✅ Correct - Using specific parameters
Get-Process -Name "notepad"

# ❌ Problematic - Array addition in loop
$Results = @()
foreach ($item in $collection)
{
    $Results += $item
}

# ✅ Correct - Using ArrayList or Generic List
$Results = [System.Collections.Generic.List[object]]@()
foreach ($item in $collection)
{
    $Results.Add($item)
}
```

#### Best Practice Rules

```powershell
# ❌ Problematic - Using aliases in scripts
gci | ? Name -like "*.txt" | % { $_.FullName }

# ✅ Correct - Using full cmdlet names
Get-ChildItem | Where-Object Name -like "*.txt" | ForEach-Object { $_.FullName }

# ❌ Problematic - Missing parameter validation
function Get-UserInfo($UserName) { }

# ✅ Correct - Proper parameter validation
function Get-UserInfo
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName
    )
}
```

### Integration with Development Workflow

#### VS Code Integration

Add PSScriptAnalyzer settings to VS Code:

```json
{
    "powershell.scriptAnalysis.enable": true,
    "powershell.scriptAnalysis.settingsPath": ".vscode/PSScriptAnalyzerSettings.psd1"
}
```

#### Custom Rules Configuration

Create a PSScriptAnalyzer settings file:

```powershell
# PSScriptAnalyzerSettings.psd1
@{
    Severity = @('Error', 'Warning')
    IncludeRules = @(
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidGlobalVars',
        'PSAvoidUsingPlainTextForPassword',
        'PSUseDeclaredVarsMoreThanAssignments'
    )
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'  # Allow Write-Host for user interaction
    )
}
```

#### Pre-commit Analysis

Create a PowerShell function for pre-commit checks:

```powershell
function Test-ScriptQuality
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    $Issues = Invoke-ScriptAnalyzer -Path $ScriptPath -Severity @('Error', 'Warning')
    
    if ($Issues)
    {
        Write-Host "Script analysis found issues:" -ForegroundColor Red
        $Issues | Format-Table -AutoSize
        return $false
    }
    else
    {
        Write-Host "Script analysis passed!" -ForegroundColor Green
        return $true
    }
}
```

## Best Practices

1. **Comment Your Code**: Use comments to explain complex logic or important decisions in your script. This helps others understand your thought process and makes it easier to maintain the code.

2. **Use Consistent Indentation**: Maintain consistent indentation throughout your script to improve readability. Use tabs for indentation as specified in the Allman formatting style.

3. **Follow Allman Formatting**: Use the Allman style with opening braces on new lines for better readability and debugging.

4. **Avoid Hardcoding Values**: Use variables or configuration files for values that may change, such as file paths or server names. This makes your script more flexible and easier to update.

5. **Test Your Scripts**: Before deploying scripts in a production environment, thoroughly test them in a safe environment. This helps catch errors and ensures the script behaves as expected.

6. **Use Version Control**: Store your scripts in a version control system (e.g., Git) to track changes, collaborate with others, and roll back to previous versions if needed.

7. **Follow Security Best Practices**: Be cautious with sensitive information, such as passwords or API keys. Use secure methods to handle credentials, such as the `Get-Credential` cmdlet or secure strings.

8. **Keep Scripts Modular**: Break down large scripts into smaller, reusable functions or modules. This promotes code reuse and makes it easier to test and maintain individual components.

9. **Use Verbose Output**: Implement verbose output in your scripts to provide additional information during execution. This can be helpful for debugging and understanding script behavior.

10. **Document Your Scripts**: Maintain comprehensive comment-based help for your scripts, including usage instructions, parameter descriptions, and examples. This helps users understand how to use the script effectively.

11. **Use PSScriptAnalyzer**: Regularly analyze your scripts with PSScriptAnalyzer to identify potential issues, security problems, and style violations before deployment.

12. **Implement Proper Error Handling**: Use try/catch blocks for expected errors and provide meaningful error messages without exposing sensitive information.

13. **Use Parameter Validation**: Implement comprehensive parameter validation using validation attributes to ensure input data meets requirements.

14. **Review and Refactor**: Regularly review your scripts for opportunities to improve performance, readability, and maintainability. Refactor code as needed to keep it clean and efficient.

By adhering to these best practices, you can create PowerShell scripts that are robust, maintainable, and easy to understand.

## Conclusion

In conclusion, following a structured approach to PowerShell scripting can greatly enhance the quality and maintainability of your scripts. By adhering to best practices, naming conventions, and a clear script structure, you can create scripts that are not only functional but also easy to read and understand. This ultimately leads to more efficient development and a smoother experience for both script authors and users.

## Additional Resources

- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/best-practices?view=powershell-7.1)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation)
