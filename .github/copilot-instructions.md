# GitHub Copilot Instructions for PowerShell Development

## Overview

When generating, reviewing, or modifying PowerShell code in this repository, strictly adhere to the PowerShell linting standards and best practices documented in `docs/development/powershell/index.md`. These instructions ensure consistent, maintainable, and professional PowerShell code.

## Code Style and Formatting Requirements

### Indentation and Spacing
- **Place open braces on the next line** for functions and control structures
- **Use tabs for indentation**
- **Add space around operators**: `$a -eq $b` not `$a-eq$b`
- **Add space after commas**: `$list = "a", "b", "c"`
- **Use consistent line breaks** and avoid overly long lines (80-120 characters max)

```powershell
# ✅ Good
$UserList = Get-ADUser -Filter * | Where-Object { $_.Enabled -eq $true }

# ❌ Avoid
$ul=Get-ADUser -Filter *|?{$_.Enabled-eq$true}
```

### Variable Naming Standards
- **Use descriptive names** that explain the variable's purpose
- **Use PascalCase** for readability: `$UserName`, `$ComputerList`, `$ServerConfiguration`
- **Avoid abbreviations**: Use `$ServerList` instead of `$sl`
- **Avoid special characters** except underscore
- **Don't use reserved words** as variable names

```powershell
# ✅ Good
$ActiveUsers = Get-ADUser -Filter * | Where-Object Enabled -eq $true
$DatabaseConnectionString = "Server=localhost;Database=MyDB"

# ❌ Avoid
$au = Get-ADUser -Filter * | Where-Object Enabled -eq $true
$db_conn = "Server=localhost;Database=MyDB"
```

## Function Development Standards

### Function Naming
- **Use approved verbs**: Follow PowerShell's approved verb list (Get-, Set-, New-, Remove-, Add-, Update-, etc.)
- **Use Verb-Noun pattern**: `Get-UserInformation`, `Set-ServerConfiguration`
- **Use PascalCase**: `Get-ComputerInfo` not `get-computerinfo`

### Function Structure Requirements
- **Always include comment-based help** with .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE
- **Use [CmdletBinding()]** for advanced functions
- **Implement parameter validation** using validation attributes
- **Support pipeline input** when appropriate with ValueFromPipeline
- **Return structured objects** instead of formatted text
- **Use Write-Output for returning data** to the pipeline
- **Use Write-Verbose for debugging information** and Write-Error for error messages
- **Use try/catch for error handling** with meaningful messages

```powershell
<#
.SYNOPSIS
    Gets computer information from remote machines.
.DESCRIPTION
    This function retrieves basic or detailed information from one or more computers.
.PARAMETER ComputerName
    One or more computer names to query.
.PARAMETER InfoLevel
    The level of information to retrieve (Basic or Detailed).
.EXAMPLE
    Get-ComputerInfo -ComputerName "Server01" -InfoLevel Basic
.NOTES
    Requires WinRM to be enabled on target computers.
#>
function Get-ComputerInfo
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,
        
        [Parameter()]
        [ValidateSet("Basic", "Detailed")]
        [string]$InfoLevel = "Basic"
    )
    
    # Function implementation
}
```

## Error Handling Requirements

### Always Use Structured Error Handling
- **Use try/catch blocks** for expected errors
- **Set -ErrorAction Stop** for cmdlets in try blocks
- **Handle specific exception types** when possible
- **Provide meaningful error messages** without exposing sensitive information
- **Use finally blocks** for cleanup when needed

```powershell
try 
{
    Get-ADUser $username -ErrorAction Stop
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
    Write-Warning "User '$username' not found in Active Directory"
}
catch [System.Security.Authentication.AuthenticationException]
{
    Write-Error "Authentication failed - check credentials"
}
catch
{
    Write-Error "Unexpected error: $($_.Exception.Message)"
    throw  # Re-throw if needed
}
```

## Performance Optimization Requirements

### Collection Handling
- **Never use += for arrays** - use ArrayList or Generic Lists instead
- **Filter early in pipelines** - apply Where-Object as early as possible
- **Use specific cmdlet parameters** instead of filtering with Where-Object when available
- **Minimize object creation** - reuse objects when possible

```powershell
# ✅ Efficient
$ProcessList = [System.Collections.Generic.List[object]]@()
Get-Process -Name "notepad" | ForEach-Object { $ProcessList.Add($_) }

# ❌ Inefficient
$ProcessList = @()
Get-Process | Where-Object Name -eq "notepad" | ForEach-Object { $ProcessList += $_ }
```

## Security Requirements

### Credential and Data Protection
- **Never hardcode passwords** or sensitive data
- **Use Get-Credential** or Read-Host -AsSecureString for password input
- **Validate all input parameters** using validation attributes
- **Set appropriate execution policies** for your environment
- **Use signed scripts** for production environments

```powershell
# ✅ Secure
$Credential = Get-Credential
$SecurePassword = Read-Host -AsSecureString "Enter password"

# ❌ Insecure
$Password = "MyPassword123"
$ConnectionString = "Server=db;User=admin;Password=secret"
```

## Documentation Requirements

### Comment-Based Help (Mandatory)
Every function must include:
- `.SYNOPSIS` - Brief description
- `.DESCRIPTION` - Detailed explanation
- `.PARAMETER` - For each parameter
- `.EXAMPLE` - At least one practical example
- `.NOTES` - Prerequisites or important information

### Code Comments
- **Document complex logic** - explain why, not just what
- **Use single-line comments** for brief explanations: `# Check if user exists`
- **Use multi-line comments** for detailed explanations:
```powershell
<#
This section handles the complex data transformation
required for the legacy system integration.
#>
```

## Output Stream Standards

### Use Appropriate Output Streams
- **Write-Output** for standard pipeline output
- **Write-Host** only for console-specific messages that shouldn't be captured
- **Write-Warning** for non-terminating warnings
- **Write-Error** for error messages
- **Write-Verbose** for detailed debugging information
- **Write-Debug** for development debugging

```powershell
Write-Output $results          # Standard output to pipeline
Write-Host "Processing..."      # Console message only
Write-Warning "Deprecated cmdlet used"
Write-Error "Failed to connect to server"
Write-Verbose "Querying Active Directory" -Verbose
```

## Data Type Guidelines

### Type Declarations
- **Use type accelerators** when specific types are required: `[string]`, `[int]`, `[datetime]`
- **Validate data types** using parameter attributes
- **Use appropriate collection types**: `[array]`, `[hashtable]`, `[System.Collections.Generic.List[]]`

```powershell
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$UserName,
    
    [Parameter()]
    [ValidateRange(1, 100)]
    [int]$MaxResults = 10,
    
    [Parameter()]
    [datetime]$StartDate = (Get-Date).AddDays(-30)
)
```

## Testing and Quality Assurance

### Required Practices
- **Test with various inputs** including edge cases
- **Use Write-Verbose** for debugging output
- **Implement Pester unit tests** for complex functions
- **Test in non-production environments** before deployment
- **Version control all scripts** and track changes

## Module Organization

### Structure Requirements
- **Group related functions** into modules
- **Use proper module manifests** (.psd1 files)
- **Export only necessary functions** using Export-ModuleMember
- **Include module-level help** and examples
- **Follow semantic versioning** for module versions

## Linting Enforcement

### Automated Checks
When possible, configure automated linting to enforce:
- PSScriptAnalyzer rules for code quality
- Consistent formatting standards
- Function and variable naming conventions
- Documentation completeness
- Security best practices compliance

### Code Review Requirements
All PowerShell code must be reviewed for:
- Allman formating
- Adherence to naming conventions
- Proper error handling implementation
- Security best practices compliance
- Performance optimization opportunities
- Documentation completeness

## Quick Reference Checklist

Before submitting PowerShell code, verify:
- ✅ tab indentation used consistently
- ✅ PascalCase naming for variables and functions
- ✅ Approved verbs used for function names
- ✅ Comment-based help included for all functions
- ✅ Parameter validation implemented
- ✅ Try/catch error handling used appropriately
- ✅ Performance optimizations applied (no += for arrays)
- ✅ Secure credential handling implemented
- ✅ Appropriate output streams used
- ✅ Code is readable and well-documented
- ✅ Open and close braces on separate lines

## Resources

- [PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)
- [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [PSScriptAnalyzer Rules](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme)

---

*These instructions ensure all PowerShell code in this repository maintains professional standards and follows industry best practices for maintainability, security, and performance.*
