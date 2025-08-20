# PowerShell Module Development

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Module Structure](#module-structure)
- [Development Workflow](#development-workflow)
- [Module Manifest](#module-manifest)
- [Function Development](#function-development)
- [Testing with Pester](#testing-with-pester)
- [Code Analysis](#code-analysis)
- [Build and Packaging](#build-and-packaging)
- [Publishing Modules](#publishing-modules)
- [CI/CD Pipeline](#cicd-pipeline)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

## Overview

PowerShell modules are reusable packages of PowerShell code that provide specific functionality. This comprehensive guide covers the complete development lifecycle from initial project setup to publishing and maintenance.

### What You'll Learn

- **Module Architecture**: How to structure professional PowerShell modules
- **Development Practices**: Industry-standard development workflows
- **Testing Strategy**: Comprehensive testing with Pester framework
- **Quality Assurance**: Code analysis and linting standards
- **Publishing Process**: Deployment to public and private repositories
- **CI/CD Integration**: Automated build and deployment pipelines

### Module Types

- **Script Modules** (.psm1): Most common, contains PowerShell functions and variables
- **Binary Modules** (.dll): Compiled .NET assemblies containing PowerShell cmdlets
- **Manifest Modules** (.psd1): Contains metadata and can load other modules
- **Dynamic Modules**: Created in memory at runtime

## Prerequisites

### PowerShell Environment

This guide uses PowerShell 7.4+ for cross-platform compatibility and modern features:

```powershell
# Check your PowerShell version
$PSVersionTable.PSVersion

# Expected output: 7.4.0 or higher
```

### Development Tools

#### Required Software

1. **PowerShell 7.4+**: Latest stable version
2. **Visual Studio Code**: Primary development environment
3. **Git**: Version control system

#### Visual Studio Code Extensions

Install these essential extensions for PowerShell development:

```powershell
# PowerShell extension
code --install-extension ms-vscode.PowerShell

# GitLens for enhanced Git integration
code --install-extension eamodio.gitlens

# Bracket Pair Colorizer for better code readability
code --install-extension CoenraadS.bracket-pair-colorizer-2
```

#### Required PowerShell Modules

Install these modules for development, testing, and analysis:

```powershell
# Install required modules
$ModulesToInstall = @(
    'Pester',                 # Testing framework (5.5.0+)
    'PSScriptAnalyzer',       # Code analysis (1.22.0+)
    'platyPS',               # Documentation generation
    'ModuleBuilder',         # Module building utilities
    'PowerShellGet'          # Module publishing (2.2.5+)
)

foreach ($Module in $ModulesToInstall) 
{
    Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber
}

# Verify installations
Get-Module -Name $ModulesToInstall -ListAvailable | 
    Select-Object Name, Version | 
    Format-Table -AutoSize
```

### Development Environment Configuration

#### PowerShell Profile Setup

Configure your PowerShell profile for module development:

```powershell
# Create or edit your PowerShell profile
if (-not (Test-Path $PROFILE)) 
{
    New-Item -Type File -Path $PROFILE -Force
}

# Add helpful aliases and functions
Add-Content -Path $PROFILE -Value @"
# Module development shortcuts
function Import-ModuleForce { param([string]`$Name) Import-Module `$Name -Force }
Set-Alias -Name imf -Value Import-ModuleForce

# Quick Pester test runner
function Invoke-PesterQuick { param([string]`$Path = '.') Invoke-Pester `$Path -Output Detailed }
Set-Alias -Name test -Value Invoke-PesterQuick

# Script Analyzer shortcut
function Invoke-ScriptAnalyzerQuick { param([string]`$Path = '.') Invoke-ScriptAnalyzer `$Path -Recurse }
Set-Alias -Name analyze -Value Invoke-ScriptAnalyzerQuick
"@
```

## Module Structure

### Standard Directory Layout

Follow this proven directory structure for professional PowerShell modules:

```text
MyModule/
├── MyModule/                    # Module root directory
│   ├── Public/                 # Public functions (exported)
│   │   ├── Get-Something.ps1
│   │   ├── Set-Something.ps1
│   │   └── New-Something.ps1
│   ├── Private/                # Private functions (internal use)
│   │   ├── Helper-Function.ps1
│   │   └── Utility-Function.ps1
│   ├── Classes/                # PowerShell classes (optional)
│   │   └── CustomClass.ps1
│   ├── Data/                   # Module data files
│   │   ├── config.json
│   │   └── templates.xml
│   ├── Localization/           # Localized strings (optional)
│   │   ├── en-US/
│   │   └── es-ES/
│   ├── MyModule.psd1          # Module manifest
│   ├── MyModule.psm1          # Module script file
│   └── README.md              # Module documentation
├── Tests/                      # Pester tests
│   ├── Unit/
│   │   ├── Public/
│   │   └── Private/
│   ├── Integration/
│   ├── MyModule.Tests.ps1
│   └── TestHelper.psm1
├── Scripts/                    # Build and utility scripts
│   ├── Build.ps1
│   ├── Deploy.ps1
│   └── Clean.ps1
├── Docs/                       # Documentation
│   ├── en-US/
│   ├── CHANGELOG.md
│   └── CONTRIBUTING.md
├── Examples/                   # Usage examples
├── .gitignore                  # Git ignore file
├── .vscode/                    # VS Code settings
│   ├── settings.json
│   ├── tasks.json
│   └── launch.json
├── azure-pipelines.yml         # CI/CD pipeline
├── LICENSE                     # License file
└── README.md                   # Project readme

### Creating the Initial Structure

Use this script to create the standard module structure:

```powershell
function New-ModuleStructure 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        
        [Parameter()]
        [string]$Path = (Get-Location).Path,
        
        [Parameter()]
        [string]$Author = $env:USERNAME,
        
        [Parameter()]
        [string]$Description = "A PowerShell module"
    )
    
    $ModuleRoot = Join-Path $Path $ModuleName
    
    # Create directory structure
    $Directories = @(
        "$ModuleName",
        "$ModuleName/Public",
        "$ModuleName/Private", 
        "$ModuleName/Classes",
        "$ModuleName/Data",
        "$ModuleName/Localization/en-US",
        "Tests/Unit/Public",
        "Tests/Unit/Private", 
        "Tests/Integration",
        "Scripts",
        "Docs/en-US",
        "Examples",
        ".vscode"
    )
    
    foreach ($Directory in $Directories) 
    {
        $FullPath = Join-Path $ModuleRoot $Directory
        New-Item -Path $FullPath -ItemType Directory -Force | Out-Null
        Write-Verbose "Created directory: $FullPath"
    }
    
    Write-Output "Module structure created successfully at: $ModuleRoot"
}

# Usage example
New-ModuleStructure -ModuleName "MyAwesomeModule" -Author "Your Name" -Verbose
```

## Development Workflow

### 1. Initialize Module Project

```powershell
# Navigate to your development directory
Set-Location "C:\Dev\PowerShell"

# Create module structure
New-ModuleStructure -ModuleName "UserManagement" -Author "Your Name"

# Initialize Git repository
Set-Location "UserManagement"
git init
git add .
git commit -m "Initial module structure"
```

### 2. Create Module Manifest

Generate a proper module manifest with all required metadata:

```powershell
# Create module manifest
$ManifestParams = @{
    Path                = ".\UserManagement\UserManagement.psd1"
    RootModule          = "UserManagement.psm1"
    ModuleVersion       = "1.0.0"
    GUID                = [System.Guid]::NewGuid().ToString()
    Author              = "Your Name"
    CompanyName         = "Your Company"
    Copyright           = "(c) $(Get-Date -Format yyyy) Your Name. All rights reserved."
    Description         = "PowerShell module for user management operations"
    PowerShellVersion   = "7.0"
    FunctionsToExport   = @()  # Will be populated by build script
    CmdletsToExport     = @()
    VariablesToExport   = @()
    AliasesToExport     = @()
    RequiredModules     = @('ActiveDirectory')
    Tags                = @('UserManagement', 'ActiveDirectory', 'Security')
    LicenseUri          = "https://github.com/yourusername/UserManagement/blob/main/LICENSE"
    ProjectUri          = "https://github.com/yourusername/UserManagement"
    HelpInfoURI         = "https://github.com/yourusername/UserManagement/blob/main/README.md"
}

New-ModuleManifest @ManifestParams
```

### 3. Implement Module Functions

Create your first public function following best practices:

```powershell
# UserManagement/Public/Get-UserInformation.ps1
<#
.SYNOPSIS
    Retrieves comprehensive user information from Active Directory.

.DESCRIPTION
    The Get-UserInformation function retrieves detailed user information from Active Directory,
    including account status, group memberships, and last logon information.

.PARAMETER Identity
    Specifies the user identity. Can be SamAccountName, UserPrincipalName, or DistinguishedName.

.PARAMETER IncludeGroups
    Include group membership information in the output.

.PARAMETER IncludeLastLogon
    Include last logon information from all domain controllers.

.EXAMPLE
    Get-UserInformation -Identity "john.doe"
    
    Gets basic user information for john.doe.

.EXAMPLE
    Get-UserInformation -Identity "john.doe@contoso.com" -IncludeGroups -IncludeLastLogon
    
    Gets comprehensive user information including groups and last logon details.

.NOTES
    Requires ActiveDirectory module and appropriate permissions.
    
.LINK
    https://github.com/yourusername/UserManagement
#>
function Get-UserInformation 
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Identity,
        
        [Parameter()]
        [switch]$IncludeGroups,
        
        [Parameter()]
        [switch]$IncludeLastLogon
    )
    
    begin 
    {
        Write-Verbose "Starting Get-UserInformation"
        
        # Verify required module is available
        if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) 
        {
            throw "ActiveDirectory module is required but not available"
        }
        
        Import-Module ActiveDirectory -Force
    }
    
    process 
    {
        foreach ($User in $Identity) 
        {
            try 
            {
                Write-Verbose "Processing user: $User"
                
                # Get basic user information
                $ADUser = Get-ADUser -Identity $User -Properties * -ErrorAction Stop
                
                # Create base user object
                $UserInfo = [PSCustomObject]@{
                    SamAccountName    = $ADUser.SamAccountName
                    UserPrincipalName = $ADUser.UserPrincipalName
                    DisplayName       = $ADUser.DisplayName
                    EmailAddress      = $ADUser.EmailAddress
                    Enabled           = $ADUser.Enabled
                    LockedOut         = $ADUser.LockedOut
                    PasswordExpired   = $ADUser.PasswordExpired
                    LastPasswordSet   = $ADUser.PasswordLastSet
                    WhenCreated       = $ADUser.WhenCreated
                    WhenChanged       = $ADUser.WhenChanged
                    DistinguishedName = $ADUser.DistinguishedName
                }
                
                # Add group information if requested
                if ($IncludeGroups) 
                {
                    Write-Verbose "Including group membership for $User"
                    $Groups = Get-ADUser -Identity $User -Properties MemberOf |
                        Select-Object -ExpandProperty MemberOf |
                        ForEach-Object { (Get-ADGroup $_).Name }
                    
                    $UserInfo | Add-Member -MemberType NoteProperty -Name "GroupMembership" -Value $Groups
                }
                
                # Add last logon information if requested
                if ($IncludeLastLogon) 
                {
                    Write-Verbose "Including last logon information for $User"
                    $LastLogon = Get-LastLogonInfo -Identity $User
                    $UserInfo | Add-Member -MemberType NoteProperty -Name "LastLogonInfo" -Value $LastLogon
                }
                
                Write-Output $UserInfo
            }
            catch 
            {
                Write-Error "Failed to retrieve information for user '$User': $($_.Exception.Message)"
                continue
            }
        }
    }
    
    end 
    {
        Write-Verbose "Completed Get-UserInformation"
    }
}
```

### 4. Create Supporting Private Functions

```powershell
# UserManagement/Private/Get-LastLogonInfo.ps1
function Get-LastLogonInfo 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Identity
    )
    
    try 
    {
        # Get all domain controllers
        $DomainControllers = Get-ADDomainController -Filter *
        $LastLogonInfo = @()
        
        foreach ($DC in $DomainControllers) 
        {
            try 
            {
                $User = Get-ADUser -Identity $Identity -Server $DC.HostName -Properties LastLogon, LastLogonDate
                
                $LastLogonInfo += [PSCustomObject]@{
                    DomainController = $DC.HostName
                    LastLogon        = if ($User.LastLogon) { [DateTime]::FromFileTime($User.LastLogon) } else { $null }
                    LastLogonDate    = $User.LastLogonDate
                }
            }
            catch 
            {
                Write-Warning "Could not query $($DC.HostName) for user $Identity"
            }
        }
        
        # Return the most recent logon
        return ($LastLogonInfo | Sort-Object LastLogon -Descending | Select-Object -First 1)
    }
    catch 
    {
        Write-Error "Failed to get last logon information: $($_.Exception.Message)"
        return $null
    }
}
```

## Module Manifest

### Complete Manifest Example

A comprehensive module manifest with all important fields:

```powershell
@{
    # Module Information
    RootModule           = 'UserManagement.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '12345678-1234-1234-1234-123456789012'
    Author               = 'Your Name'
    CompanyName          = 'Your Company'
    Copyright            = '(c) 2024 Your Name. All rights reserved.'
    Description          = 'PowerShell module for comprehensive user management operations in Active Directory environments.'
    
    # PowerShell Requirements
    PowerShellVersion    = '7.0'
    PowerShellHostName   = ''
    PowerShellHostVersion = ''
    DotNetFrameworkVersion = ''
    CLRVersion           = ''
    ProcessorArchitecture = ''
    
    # Module Dependencies
    RequiredModules      = @(
        @{
            ModuleName    = 'ActiveDirectory'
            ModuleVersion = '1.0.0.0'
        }
    )
    RequiredAssemblies   = @()
    ScriptsToProcess     = @()
    TypesToProcess       = @()
    FormatsToProcess     = @()
    
    # Exports (populated by build script)
    FunctionsToExport    = @(
        'Get-UserInformation',
        'Set-UserPassword',
        'New-UserAccount',
        'Remove-UserAccount',
        'Enable-UserAccount',
        'Disable-UserAccount'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    
    # Module List and File List (for security)
    ModuleList           = @()
    FileList             = @()
    
    # Private Data
    PrivateData          = @{
        PSData = @{
            # Tags for PowerShell Gallery
            Tags         = @('UserManagement', 'ActiveDirectory', 'Security', 'Administration')
            
            # License and Project URLs
            LicenseUri   = 'https://github.com/yourusername/UserManagement/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/yourusername/UserManagement'
            IconUri      = 'https://github.com/yourusername/UserManagement/raw/main/icon.png'
            
            # Release Notes
            ReleaseNotes = @'
## 1.0.0
- Initial release
- Core user management functions
- Comprehensive error handling
- Full test coverage
'@
            
            # Prerelease identifier
            Prerelease   = ''
            
            # External dependencies
            ExternalModuleDependencies = @('ActiveDirectory')
        }
    }
    
    # Help and Documentation
    HelpInfoURI          = 'https://github.com/yourusername/UserManagement/blob/main/README.md'
    DefaultCommandPrefix = ''
}
```

## Function Development

### Function Template

Use this template for all module functions:

```powershell
<#
.SYNOPSIS
    Brief description of what the function does.

.DESCRIPTION
    Detailed description of the function's purpose and behavior.

.PARAMETER ParameterName
    Description of the parameter.

.EXAMPLE
    Example-Function -ParameterName "Value"
    
    Description of what this example does.

.INPUTS
    What objects can be piped to this function.

.OUTPUTS
    What this function returns.

.NOTES
    Additional information about the function.
    
.LINK
    Related links or documentation.
#>
function Verb-Noun 
{
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Identity,
        
        [Parameter()]
        [ValidateSet('Option1', 'Option2', 'Option3')]
        [string]$Option = 'Option1',
        
        [Parameter()]
        [switch]$Force
    )
    
    begin 
    {
        Write-Verbose "Starting $($MyInvocation.MyCommand.Name)"
        
        # Initialize variables
        $Results = @()
        
        # Validate prerequisites
        if (-not (Test-Prerequisites)) 
        {
            throw "Prerequisites not met"
        }
    }
    
    process 
    {
        foreach ($Item in $Identity) 
        {
            if ($PSCmdlet.ShouldProcess($Item, "Perform Action")) 
            {
                try 
                {
                    Write-Verbose "Processing: $Item"
                    
                    # Main function logic here
                    $Result = Invoke-SomeOperation -Target $Item -Option $Option
                    
                    $Results += $Result
                }
                catch 
                {
                    Write-Error "Failed to process '$Item': $($_.Exception.Message)"
                    continue
                }
            }
        }
    }
    
    end 
    {
        Write-Verbose "Completed $($MyInvocation.MyCommand.Name)"
        return $Results
    }
}
```

### Parameter Validation

Implement comprehensive parameter validation:

```powershell
param(
    # Required string with validation
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$UserName,
    
    # Validate against specific values
    [Parameter()]
    [ValidateSet('Create', 'Modify', 'Delete', 'Query')]
    [string]$Action = 'Query',
    
    # Validate string length
    [Parameter()]
    [ValidateLength(1, 50)]
    [string]$Description,
    
    # Validate number range
    [Parameter()]
    [ValidateRange(1, 100)]
    [int]$MaxResults = 10,
    
    # Validate script block result
    [Parameter()]
    [ValidateScript({
        if (Test-Path $_) 
        {
            return $true
        }
        else 
        {
            throw "Path '$_' does not exist"
        }
    })]
    [string]$ConfigPath,
    
    # Validate with regular expression
    [Parameter()]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$EmailAddress,
    
    # Custom validation attribute
    [Parameter()]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]$Credential
)
```

## Testing with Pester

### Test Structure

Create comprehensive tests for your module:

```powershell
# Tests/Unit/Public/Get-UserInformation.Tests.ps1
BeforeAll {
    # Import the module
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $ModulePath = Join-Path -Path $ModuleRoot -ChildPath "UserManagement"
    Import-Module $ModulePath -Force
    
    # Mock external dependencies
    Mock -CommandName Get-ADUser -MockWith {
        [PSCustomObject]@{
            SamAccountName    = 'testuser'
            UserPrincipalName = 'testuser@contoso.com'
            DisplayName       = 'Test User'
            EmailAddress      = 'testuser@contoso.com'
            Enabled           = $true
            LockedOut         = $false
            PasswordExpired   = $false
            PasswordLastSet   = (Get-Date).AddDays(-30)
            WhenCreated       = (Get-Date).AddDays(-100)
            WhenChanged       = (Get-Date).AddDays(-10)
            DistinguishedName = 'CN=Test User,OU=Users,DC=contoso,DC=com'
        }
    }
}

Describe 'Get-UserInformation' {
    Context 'When getting basic user information' {
        It 'Should return user object with required properties' {
            $Result = Get-UserInformation -Identity 'testuser'
            
            $Result | Should -Not -BeNullOrEmpty
            $Result.SamAccountName | Should -Be 'testuser'
            $Result.UserPrincipalName | Should -Be 'testuser@contoso.com'
            $Result.Enabled | Should -Be $true
        }
        
        It 'Should handle pipeline input' {
            $Users = @('user1', 'user2', 'user3')
            $Result = $Users | Get-UserInformation
            
            $Result | Should -HaveCount 3
        }
        
        It 'Should handle multiple users via parameter' {
            $Result = Get-UserInformation -Identity @('user1', 'user2')
            
            $Result | Should -HaveCount 2
        }
    }
    
    Context 'When including group information' {
        BeforeEach {
            Mock -CommandName Get-ADGroup -MockWith {
                [PSCustomObject]@{ Name = 'TestGroup' }
            }
        }
        
        It 'Should include group membership when switch is specified' {
            $Result = Get-UserInformation -Identity 'testuser' -IncludeGroups
            
            $Result.GroupMembership | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'When handling errors' {
        It 'Should handle user not found gracefully' {
            Mock -CommandName Get-ADUser -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new()
            }
            
            { Get-UserInformation -Identity 'nonexistentuser' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Should continue processing other users when one fails' {
            Mock -CommandName Get-ADUser -MockWith {
                if ($Identity -eq 'baduser') 
                {
                    throw "User not found"
                }
                return [PSCustomObject]@{ SamAccountName = $Identity }
            }
            
            $Result = Get-UserInformation -Identity @('gooduser', 'baduser', 'anothergooduser') -ErrorAction SilentlyContinue
            
            $Result | Should -HaveCount 2
        }
    }
}

AfterAll {
    Remove-Module UserManagement -Force -ErrorAction SilentlyContinue
}
```

### Integration Tests

```powershell
# Tests/Integration/UserManagement.Integration.Tests.ps1
BeforeAll {
    $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
    $ModulePath = Join-Path -Path $ModuleRoot -ChildPath "UserManagement"
    Import-Module $ModulePath -Force
    
    # Skip tests if not in AD environment
    $SkipTests = -not (Get-Module -Name ActiveDirectory -ListAvailable)
}

Describe 'UserManagement Integration Tests' -Skip:$SkipTests {
    Context 'Real Active Directory Integration' {
        BeforeAll {
            # Create test user for integration tests
            $TestUserName = "TestUser_$(Get-Random)"
            $TestUserParams = @{
                Name              = $TestUserName
                SamAccountName    = $TestUserName
                UserPrincipalName = "$TestUserName@$env:USERDNSDOMAIN"
                AccountPassword   = (ConvertTo-SecureString "TempPassword123!" -AsPlainText -Force)
                Enabled           = $true
                Path              = "OU=Test Users,DC=$($env:USERDOMAIN),DC=com"
            }
            
            try 
            {
                New-ADUser @TestUserParams -ErrorAction Stop
                $TestUserCreated = $true
            }
            catch 
            {
                $TestUserCreated = $false
                Write-Warning "Could not create test user: $($_.Exception.Message)"
            }
        }
        
        It 'Should retrieve real user information' -Skip:(-not $TestUserCreated) {
            $Result = Get-UserInformation -Identity $TestUserName
            
            $Result | Should -Not -BeNullOrEmpty
            $Result.SamAccountName | Should -Be $TestUserName
            $Result.Enabled | Should -Be $true
        }
        
        AfterAll {
            if ($TestUserCreated) 
            {
                Remove-ADUser -Identity $TestUserName -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
    }
}
```

### Running Tests

```powershell
# Run all tests
Invoke-Pester -Path .\Tests\ -Output Detailed

# Run specific test file
Invoke-Pester -Path .\Tests\Unit\Public\Get-UserInformation.Tests.ps1 -Output Detailed

# Run with code coverage
$Coverage = Invoke-Pester -Path .\Tests\ -CodeCoverage .\UserManagement\*.ps1 -PassThru
$Coverage.CodeCoverage
```

## Code Analysis

### PSScriptAnalyzer Configuration

Create a configuration file for consistent code analysis:

```powershell
# PSScriptAnalyzerSettings.psd1
@{
    # Include default rules
    IncludeDefaultRules = $true
    
    # Exclude specific rules if needed
    ExcludeRules = @(
        # 'PSUseShouldProcessForStateChangingFunctions'  # Uncomment to exclude
    )
    
    # Custom rules
    CustomRulePath = @()
    
    # Rule configuration
    Rules = @{
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $false  # Allman style braces
        }
        
        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $true
        }
        
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'tab'  # Use tabs for indentation
        }
        
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckSeparator = $true
        }
        
        PSAlignAssignmentStatement = @{
            Enable = $true
            CheckHashtable = $true
        }
        
        PSUseCorrectCasing = @{
            Enable = $true
        }
    }
}
```

### Analysis Script

Create a script to run comprehensive code analysis:

```powershell
# Scripts/Analyze.ps1
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Path = (Get-Location).Path,
    
    [Parameter()]
    [switch]$Fix
)

Write-Host "Running PSScriptAnalyzer on: $Path" -ForegroundColor Green

# Run analysis
$Results = Invoke-ScriptAnalyzer -Path $Path -Recurse -Settings PSScriptAnalyzerSettings.psd1

if ($Results) 
{
    Write-Host "Found $($Results.Count) issues:" -ForegroundColor Yellow
    
    # Group results by severity
    $ResultsBySeverity = $Results | Group-Object Severity
    
    foreach ($Group in $ResultsBySeverity) 
    {
        Write-Host "`n$($Group.Name) Issues: $($Group.Count)" -ForegroundColor Red
        
        foreach ($Issue in $Group.Group) 
        {
            Write-Host "  $($Issue.ScriptName):$($Issue.Line) - $($Issue.RuleName): $($Issue.Message)" -ForegroundColor Gray
        }
    }
    
    # Attempt to fix issues if requested
    if ($Fix) 
    {
        Write-Host "`nAttempting to fix issues..." -ForegroundColor Yellow
        
        $FixableIssues = $Results | Where-Object { $_.RuleName -in @(
            'PSUseConsistentIndentation',
            'PSUseConsistentWhitespace', 
            'PSAlignAssignmentStatement',
            'PSPlaceOpenBrace',
            'PSPlaceCloseBrace'
        )}
        
        if ($FixableIssues) 
        {
            Invoke-Formatter -ScriptDefinition (Get-Content -Raw -Path $_.ScriptName) -Settings PSScriptAnalyzerSettings.psd1 |
                Set-Content -Path $_.ScriptName -Encoding UTF8
            Write-Host "Fixed formatting issues" -ForegroundColor Green
        }
    }
    
    exit 1
}
else 
{
    Write-Host "No issues found! ✅" -ForegroundColor Green
    exit 0
}
```

## Build and Packaging

### Build Script

Create a comprehensive build script:

```powershell
# Scripts/Build.ps1
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Dev', 'Test', 'Prod')]
    [string]$Configuration = 'Dev',
    
    [Parameter()]
    [string]$OutputPath = '.\Output',
    
    [Parameter()]
    [switch]$UpdateVersion,
    
    [Parameter()]
    [switch]$Clean
)

# Build configuration
$BuildConfig = @{
    ModuleName    = 'UserManagement'
    SourcePath    = '.\UserManagement'
    OutputPath    = $OutputPath
    TestPath      = '.\Tests'
    DocsPath      = '.\Docs'
}

Write-Host "Starting build process..." -ForegroundColor Green
Write-Host "Configuration: $Configuration" -ForegroundColor Cyan

# Clean previous build
if ($Clean -or (Test-Path $BuildConfig.OutputPath)) 
{
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    Remove-Item -Path $BuildConfig.OutputPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Create output directory
New-Item -Path $BuildConfig.OutputPath -ItemType Directory -Force | Out-Null
$ModuleOutputPath = Join-Path $BuildConfig.OutputPath $BuildConfig.ModuleName
New-Item -Path $ModuleOutputPath -ItemType Directory -Force | Out-Null

# Update version if requested
if ($UpdateVersion) 
{
    Write-Host "Updating module version..." -ForegroundColor Yellow
    
    $ManifestPath = Join-Path $BuildConfig.SourcePath "$($BuildConfig.ModuleName).psd1"
    $Manifest = Import-PowerShellDataFile -Path $ManifestPath
    
    $Version = [Version]$Manifest.ModuleVersion
    $NewVersion = switch ($Configuration) 
    {
        'Dev'  { [Version]::new($Version.Major, $Version.Minor, $Version.Build + 1, 0) }
        'Test' { [Version]::new($Version.Major, $Version.Minor + 1, 0, 0) }
        'Prod' { [Version]::new($Version.Major + 1, 0, 0, 0) }
    }
    
    Write-Host "Version: $($Version.ToString()) → $($NewVersion.ToString())" -ForegroundColor Cyan
    
    # Update manifest
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewVersion.ToString()
}

# Run tests
Write-Host "Running tests..." -ForegroundColor Yellow
$TestResults = Invoke-Pester -Path $BuildConfig.TestPath -PassThru -Output Normal

if ($TestResults.FailedCount -gt 0) 
{
    Write-Host "Tests failed! Build cannot continue." -ForegroundColor Red
    exit 1
}

# Run code analysis
Write-Host "Running code analysis..." -ForegroundColor Yellow
& (Join-Path $PSScriptRoot "Analyze.ps1") -Path $BuildConfig.SourcePath

if ($LASTEXITCODE -ne 0) 
{
    Write-Host "Code analysis issues found! Build cannot continue." -ForegroundColor Red
    exit 1
}

# Build module
Write-Host "Building module..." -ForegroundColor Yellow

# Copy module files
Copy-Item -Path "$($BuildConfig.SourcePath)\*" -Destination $ModuleOutputPath -Recurse -Force

# Generate module file by combining all functions
$ModuleContent = @()

# Add module header
$ModuleContent += @"
# 
# Module: $($BuildConfig.ModuleName)
# Generated: $(Get-Date)
# Configuration: $Configuration
#

# Module variables
`$Script:ModuleRoot = `$PSScriptRoot

"@

# Add private functions
$PrivateFunctions = Get-ChildItem -Path (Join-Path $BuildConfig.SourcePath "Private") -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) 
{
    $ModuleContent += "`n# Private function: $($Function.BaseName)"
    $ModuleContent += Get-Content -Raw -Path $Function.FullName
}

# Add public functions
$PublicFunctions = Get-ChildItem -Path (Join-Path $BuildConfig.SourcePath "Public") -Filter "*.ps1" -ErrorAction SilentlyContinue
$ExportedFunctions = @()

foreach ($Function in $PublicFunctions) 
{
    $ModuleContent += "`n# Public function: $($Function.BaseName)"
    $ModuleContent += Get-Content -Raw -Path $Function.FullName
    $ExportedFunctions += $Function.BaseName
}

# Add module footer
$ModuleContent += @"

# Export public functions
Export-ModuleMember -Function @(
$($ExportedFunctions | ForEach-Object { "    '$_'" } | Join-String -Separator ",`n")
)
"@

# Write combined module file
$ModuleFilePath = Join-Path $ModuleOutputPath "$($BuildConfig.ModuleName).psm1"
$ModuleContent | Out-File -FilePath $ModuleFilePath -Encoding UTF8

# Update manifest with exported functions
$ManifestPath = Join-Path $ModuleOutputPath "$($BuildConfig.ModuleName).psd1"
Update-ModuleManifest -Path $ManifestPath -FunctionsToExport $ExportedFunctions

# Generate documentation
if (Get-Module -Name platyPS -ListAvailable) 
{
    Write-Host "Generating documentation..." -ForegroundColor Yellow
    
    Import-Module $ModuleOutputPath -Force
    New-MarkdownHelp -Module $BuildConfig.ModuleName -OutputFolder (Join-Path $BuildConfig.DocsPath "en-US") -Force
    Remove-Module $BuildConfig.ModuleName -Force
}

Write-Host "Build completed successfully! ✅" -ForegroundColor Green
Write-Host "Module output: $ModuleOutputPath" -ForegroundColor Cyan
```

## Publishing Modules

### Publishing to PowerShell Gallery

```powershell
# Scripts/Publish.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ApiKey,
    
    [Parameter()]
    [string]$Repository = 'PSGallery',
    
    [Parameter()]
    [string]$ModulePath = '.\Output\UserManagement',
    
    [Parameter()]
    [switch]$WhatIf
)

Write-Host "Publishing module to $Repository..." -ForegroundColor Green

# Validate module
Write-Host "Validating module..." -ForegroundColor Yellow
$Manifest = Test-ModuleManifest -Path (Join-Path $ModulePath "UserManagement.psd1")

if (-not $Manifest) 
{
    Write-Host "Module manifest validation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Module: $($Manifest.Name) v$($Manifest.Version)" -ForegroundColor Cyan

# Test import
try 
{
    Import-Module $ModulePath -Force -ErrorAction Stop
    Write-Host "Module import test passed ✅" -ForegroundColor Green
    Remove-Module $Manifest.Name -Force
}
catch 
{
    Write-Host "Module import test failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Publish module
$PublishParams = @{
    Path        = $ModulePath
    Repository  = $Repository
    NuGetApiKey = $ApiKey
    Force       = $true
    Verbose     = $true
}

if ($WhatIf) 
{
    Write-Host "WhatIf: Would publish module with parameters:" -ForegroundColor Yellow
    $PublishParams | Format-Table -AutoSize
}
else 
{
    try 
    {
        Publish-Module @PublishParams
        Write-Host "Module published successfully! 🚀" -ForegroundColor Green
    }
    catch 
    {
        Write-Host "Publishing failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
```

### Publishing to Private Repository

```powershell
# For private repositories like BaGet
$PrivateRepoParams = @{
    Path        = $ModulePath
    Repository  = 'MyPrivateRepo'  # Previously registered
    NuGetApiKey = $PrivateApiKey
    Force       = $true
}

Publish-Module @PrivateRepoParams
```

## CI/CD Pipeline

### Azure DevOps Pipeline

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - UserManagement/*
    - Tests/*
    - Scripts/*

pool:
  vmImage: 'windows-latest'

variables:
  ModuleName: 'UserManagement'
  BuildConfiguration: 'Release'

stages:
- stage: Build
  displayName: 'Build and Test'
  jobs:
  - job: BuildTest
    displayName: 'Build and Test Module'
    steps:
    - task: PowerShell@2
      displayName: 'Install Required Modules'
      inputs:
        targetType: 'inline'
        script: |
          Install-Module -Name Pester, PSScriptAnalyzer, platyPS -Force -Scope CurrentUser
          Get-Module -Name Pester, PSScriptAnalyzer, platyPS -ListAvailable
        
    - task: PowerShell@2
      displayName: 'Run Code Analysis'
      inputs:
        targetType: 'filePath'
        filePath: 'Scripts/Analyze.ps1'
        arguments: '-Path $(Build.SourcesDirectory)'
        
    - task: PowerShell@2
      displayName: 'Run Pester Tests'
      inputs:
        targetType: 'inline'
        script: |
          $TestResults = Invoke-Pester -Path './Tests' -OutputFile 'TestResults.xml' -OutputFormat NUnitXml -PassThru
          
          if ($TestResults.FailedCount -gt 0) {
            Write-Host "##vso[task.logissue type=error]$($TestResults.FailedCount) test(s) failed"
            exit 1
          }
          
    - task: PublishTestResults@2
      displayName: 'Publish Test Results'
      inputs:
        testResultsFormat: 'NUnit'
        testResultsFiles: 'TestResults.xml'
        failTaskOnFailedTests: true
        
    - task: PowerShell@2
      displayName: 'Build Module'
      inputs:
        targetType: 'filePath'
        filePath: 'Scripts/Build.ps1'
        arguments: '-Configuration $(BuildConfiguration) -UpdateVersion'
        
    - task: PublishPipelineArtifact@1
      displayName: 'Publish Build Artifacts'
      inputs:
        targetPath: 'Output'
        artifactName: 'ModuleBuild'

- stage: Publish
  displayName: 'Publish Module'
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  dependsOn: Build
  jobs:
  - deployment: PublishPSGallery
    displayName: 'Publish to PowerShell Gallery'
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: ModuleBuild
            
          - task: PowerShell@2
            displayName: 'Publish to PowerShell Gallery'
            inputs:
              targetType: 'filePath'
              filePath: 'Scripts/Publish.ps1'
              arguments: '-ApiKey $(PSGalleryApiKey) -ModulePath $(Pipeline.Workspace)/ModuleBuild/$(ModuleName)'
            env:
              PSGalleryApiKey: $(PSGalleryApiKey)
```

### GitHub Actions Workflow

```yaml
# .github/workflows/build-and-publish.yml
name: Build and Publish Module

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        
    steps:
    - uses: actions/checkout@v3
    
    - name: Install PowerShell modules
      shell: pwsh
      run: |
        Install-Module -Name Pester, PSScriptAnalyzer, platyPS -Force -Scope CurrentUser
        
    - name: Run PSScriptAnalyzer
      shell: pwsh
      run: |
        ./Scripts/Analyze.ps1 -Path .
        
    - name: Run Pester Tests
      shell: pwsh
      run: |
        $Results = Invoke-Pester -Path ./Tests -PassThru -CI
        if ($Results.FailedCount -gt 0) { 
          throw "$($Results.FailedCount) test(s) failed" 
        }

  build:
    needs: test
    runs-on: windows-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Module
      shell: pwsh
      run: |
        Install-Module -Name Pester, PSScriptAnalyzer, platyPS -Force -Scope CurrentUser
        ./Scripts/Build.ps1 -Configuration Release -UpdateVersion
        
    - name: Upload Build Artifact
      uses: actions/upload-artifact@v3
      with:
        name: module-build
        path: Output/
        
  publish:
    needs: build
    runs-on: windows-latest
    if: github.ref == 'refs/heads/main'
    environment: Production
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Download Build Artifact
      uses: actions/download-artifact@v3
      with:
        name: module-build
        path: Output/
        
    - name: Publish to PowerShell Gallery
      shell: pwsh
      run: |
        ./Scripts/Publish.ps1 -ApiKey $env:PSGALLERY_API_KEY -ModulePath ./Output/UserManagement
      env:
        PSGALLERY_API_KEY: ${{ secrets.PSGALLERY_API_KEY }}
```

## Best Practices

### Module Design Principles

1. **Single Responsibility**: Each function should do one thing well
2. **Consistent Naming**: Follow PowerShell verb-noun conventions
3. **Parameter Design**: Use standard parameter names and types
4. **Error Handling**: Implement comprehensive error handling
5. **Documentation**: Provide complete help documentation
6. **Testing**: Achieve high test coverage
7. **Performance**: Optimize for common scenarios

### Code Organization

```powershell
# Good: Clear, specific function names
function Get-UserAccountInformation { }
function Set-UserAccountPassword { }
function New-UserAccountRequest { }

# Bad: Vague, inconsistent naming
function GetUser { }
function ChangePassword { }
function CreateAccount { }
```

### Error Handling Strategy

```powershell
function Robust-Function 
{
    [CmdletBinding()]
    param([string]$Identity)
    
    try 
    {
        # Use -ErrorAction Stop to make cmdlets throw terminating errors
        $Result = Get-SomeResource -Identity $Identity -ErrorAction Stop
        
        # Validate results
        if (-not $Result) 
        {
            throw "No results found for identity: $Identity"
        }
        
        return $Result
    }
    catch [SpecificException] 
    {
        # Handle specific known exceptions
        Write-Error "Specific error occurred: $($_.Exception.Message)"
        throw
    }
    catch 
    {
        # Handle unexpected exceptions
        Write-Error "Unexpected error in $($MyInvocation.MyCommand.Name): $($_.Exception.Message)"
        throw
    }
}
```

### Performance Considerations

```powershell
# Efficient: Use ArrayList for dynamic arrays
$Results = [System.Collections.ArrayList]@()
foreach ($Item in $LargeCollection) 
{
    $null = $Results.Add($ProcessedItem)
}

# Inefficient: Using += operator
$Results = @()
foreach ($Item in $LargeCollection) 
{
    $Results += $ProcessedItem  # Creates new array each time
}

# Efficient: Filter early in pipeline
Get-Process | Where-Object CPU -GT 100 | Select-Object Name, CPU

# Inefficient: Filter after selection
Get-Process | Select-Object Name, CPU | Where-Object CPU -GT 100
```

## Troubleshooting

### Common Issues and Solutions

#### Module Import Issues

```powershell
# Problem: Module not loading
# Solution: Check module path and manifest
Get-Module -Name YourModule -ListAvailable
Test-ModuleManifest -Path .\YourModule.psd1

# Problem: Functions not exported
# Solution: Verify FunctionsToExport in manifest
$Manifest = Import-PowerShellDataFile .\YourModule.psd1
$Manifest.FunctionsToExport
```

#### Test Failures

```powershell
# Problem: Mocks not working
# Solution: Ensure mocks are in correct scope
BeforeEach {
    Mock -CommandName Get-ADUser -MockWith { return $MockUser }
}

# Problem: Integration tests failing
# Solution: Skip tests when dependencies unavailable  
BeforeAll {
    $SkipTests = -not (Get-Module -Name RequiredModule -ListAvailable)
}

Describe 'Tests' -Skip:$SkipTests {
    # Test content
}
```

#### Build Issues

```powershell
# Problem: Build script failing
# Solution: Check prerequisites and paths
if (-not (Get-Module -Name Pester -ListAvailable)) {
    throw "Pester module is required for build"
}

if (-not (Test-Path $SourcePath)) {
    throw "Source path not found: $SourcePath"
}
```

### Debug Techniques

```powershell
# Enable verbose output
$VerbosePreference = 'Continue'
Import-Module .\YourModule -Verbose

# Check module internals
Get-Module YourModule | Select-Object -ExpandProperty ExportedCommands
(Get-Module YourModule).PrivateData

# Trace command execution
Trace-Command -Name CommandDiscovery -Expression { Get-YourFunction } -PSHost
```

## Resources

### Official Documentation

- [PowerShell Module Documentation](https://docs.microsoft.com/powershell/scripting/developer/module/)
- [PowerShell Gallery Publishing Guide](https://docs.microsoft.com/powershell/scripting/gallery/)
- [Pester Testing Framework](https://pester.dev/)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)

### Community Resources

- [PowerShell Community Extensions](https://github.com/PowerShell/PowerShellCommunityExtensions)
- [Module Template Repository](https://github.com/PowerShell/ModuleTemplate)
- [Best Practices Guide](https://github.com/PoshCode/PowerShellPracticeAndStyle)

### Tools and Utilities

- [Plaster Templates](https://github.com/PowerShell/Plaster) - Project scaffolding
- [BuildHelpers](https://github.com/RamblingCookieMonster/BuildHelpers) - Build automation
- [PSDepend](https://github.com/RamblingCookieMonster/PSDepend) - Dependency management

---

*This document provides comprehensive guidance for PowerShell module development following industry best practices and Microsoft recommendations. For additional resources, see the [PowerShell documentation index](index.md).*
