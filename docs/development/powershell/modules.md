---
title: "PowerShell Modules"
description: "Comprehensive guide to creating, managing, and using PowerShell modules"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## PowerShell Modules

PowerShell modules are packages that contain PowerShell functions, cmdlets, variables, and other resources. They provide a way to organize and share reusable code, making PowerShell development more efficient and maintainable.

## Module Types

### Script Modules (.psm1)

Script modules contain PowerShell functions and are the most common type:

```powershell
# MyModule.psm1
function Get-ComputerInfo 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )
    
    try 
    {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $ComputerName
        $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName
        
        [PSCustomObject]@{
            ComputerName = $ComputerName
            Manufacturer = $computerSystem.Manufacturer
            Model = $computerSystem.Model
            TotalMemoryGB = [Math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
            OperatingSystem = $operatingSystem.Caption
            LastBootTime = $operatingSystem.LastBootUpTime
        }
    }
    catch 
    {
        Write-Error "Failed to get computer information: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Get-ComputerInfo
```

### Binary Modules (.dll)

Binary modules are compiled .NET assemblies that contain PowerShell cmdlets.

### Manifest Modules (.psd1)

Module manifests describe the module and its requirements:

```powershell
# MyModule.psd1
@{
    RootModule = 'MyModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'Your Name'
    CompanyName = 'Your Company'
    Copyright = '(c) 2025 Your Company. All rights reserved.'
    Description = 'Module for computer information retrieval'
    
    PowerShellVersion = '5.1'
    RequiredModules = @()
    RequiredAssemblies = @()
    
    FunctionsToExport = @('Get-ComputerInfo')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('Computer', 'Information', 'Admin')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial release'
        }
    }
}
```

## Creating Modules

### Basic Module Structure

```text
MyModule/
├── MyModule.psd1       # Module manifest
├── MyModule.psm1       # Main module file
├── Public/             # Public functions
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
├── Private/            # Private functions
│   └── Helper-Function.ps1
├── Classes/            # PowerShell classes
│   └── MyClass.ps1
├── Data/              # Data files
│   └── config.json
├── Tests/             # Pester tests
│   └── MyModule.Tests.ps1
└── README.md          # Documentation
```

### Module Template

```powershell
# MyModule.psm1
# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) 
{
    try 
    {
        . $import.FullName
    }
    catch 
    {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName
```

## Module Installation

### From PowerShell Gallery

```powershell
# Find modules
Find-Module -Name "*Azure*"

# Install module
Install-Module -Name Az -Scope CurrentUser

# Update module
Update-Module -Name Az

# Remove module
Uninstall-Module -Name Az
```

### Manual Installation

```powershell
# Get module paths
$env:PSModulePath -split ';'

# Copy module to user modules folder
$userModulesPath = [Environment]::GetFolderPath('MyDocuments') + '\PowerShell\Modules'
Copy-Item -Path "C:\Source\MyModule" -Destination $userModulesPath -Recurse
```

## Module Management

### Loading Modules

```powershell
# Import module
Import-Module -Name MyModule

# Import with specific version
Import-Module -Name MyModule -RequiredVersion 2.0.0

# Import from specific path
Import-Module -Name "C:\Modules\MyModule\MyModule.psd1"

# Auto-load modules (PowerShell 3.0+)
Get-ComputerInfo  # Automatically imports module containing this function
```

### Module Information

```powershell
# List loaded modules
Get-Module

# List available modules
Get-Module -ListAvailable

# Get module information
Get-Module -Name MyModule | Format-List *

# Get module commands
Get-Command -Module MyModule
```

### Removing Modules

```powershell
# Remove from current session
Remove-Module -Name MyModule

# Force remove
Remove-Module -Name MyModule -Force
```

## Advanced Module Features

### Module Initialization

```powershell
# In MyModule.psm1 - runs when module is imported
Write-Host "MyModule loaded successfully" -ForegroundColor Green

# Module removal cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Host "MyModule removed" -ForegroundColor Yellow
    # Cleanup code here
}
```

### Using Classes in Modules

```powershell
# Classes/ComputerInfo.ps1
class ComputerInfo 
{
    [string]$Name
    [string]$OperatingSystem
    [double]$MemoryGB
    
    ComputerInfo([string]$computerName) 
    {
        $this.Name = $computerName
        $this.GetSystemInfo()
    }
    
    [void]GetSystemInfo() 
    {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $this.Name
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $this.Name
        
        $this.OperatingSystem = $os.Caption
        $this.MemoryGB = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    }
}
```

### Module Configuration

```powershell
# Store module configuration
$script:ModuleConfig = @{
    DefaultTimeout = 30
    LogLevel = 'Information'
    LogPath = "$env:TEMP\MyModule.log"
}

function Get-ModuleConfiguration 
{
    return $script:ModuleConfig
}

function Set-ModuleConfiguration 
{
    param(
        [hashtable]$Configuration
    )
    
    $script:ModuleConfig = $Configuration
}
```

## Best Practices

### Function Design

```powershell
function Get-UserAccount 
{
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$UserName,
        
        [Parameter()]
        [string]$Domain = $env:USERDOMAIN
    )
    
    begin 
    {
        Write-Verbose "Starting user account retrieval"
        $results = @()
    }
    
    process 
    {
        foreach ($user in $UserName) 
        {
            try 
            {
                Write-Verbose "Processing user: $user"
                $adUser = Get-ADUser -Identity $user -Server $Domain -ErrorAction Stop
                
                $results += [PSCustomObject]@{
                    UserName = $adUser.SamAccountName
                    DisplayName = $adUser.DisplayName
                    Enabled = $adUser.Enabled
                    LastLogon = $adUser.LastLogonDate
                    Domain = $Domain
                }
            }
            catch 
            {
                Write-Warning "Failed to get user '$user': $($_.Exception.Message)"
            }
        }
    }
    
    end 
    {
        Write-Verbose "Retrieved $($results.Count) user accounts"
        return $results
    }
}
```

### Error Handling

```powershell
function Invoke-SafeOperation 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Operation,
        
        [Parameter()]
        [string]$ErrorMessage = "Operation failed"
    )
    
    try 
    {
        & $Operation
    }
    catch [System.UnauthorizedAccessException] 
    {
        Write-Error "$ErrorMessage - Access denied: $($_.Exception.Message)"
    }
    catch [System.IO.IOException] 
    {
        Write-Error "$ErrorMessage - IO error: $($_.Exception.Message)"
    }
    catch 
    {
        Write-Error "$ErrorMessage - Unexpected error: $($_.Exception.Message)"
        throw
    }
}
```

## Testing Modules

### Pester Tests

```powershell
# Tests/MyModule.Tests.ps1
Describe "MyModule Tests" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\MyModule.psd1" -Force
    }
    
    Context "Get-ComputerInfo Tests" {
        It "Should return computer information" {
            $result = Get-ComputerInfo -ComputerName $env:COMPUTERNAME
            $result | Should -Not -BeNullOrEmpty
            $result.ComputerName | Should -Be $env:COMPUTERNAME
        }
        
        It "Should handle invalid computer name" {
            { Get-ComputerInfo -ComputerName "InvalidComputer" } | Should -Throw
        }
    }
    
    AfterAll {
        Remove-Module MyModule -Force
    }
}
```

### Running Tests

```powershell
# Install Pester
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run tests
Invoke-Pester -Path ".\Tests\MyModule.Tests.ps1"

# Run with coverage
Invoke-Pester -Path ".\Tests\" -CodeCoverage ".\MyModule.psm1"
```

## Publishing Modules

### PowerShell Gallery

```powershell
# Get API key from PowerShell Gallery
# Register repository (if not already done)
Register-PSRepository -Name PSGallery -SourceLocation https://www.powershellgallery.com/api/v2

# Publish module
Publish-Module -Path ".\MyModule" -NuGetApiKey $apiKey

# Update published module
Publish-Module -Path ".\MyModule" -NuGetApiKey $apiKey -Force
```

### Private Repository

```powershell
# Register private repository
Register-PSRepository -Name "CompanyRepo" -SourceLocation "\\server\share\repo" -InstallationPolicy Trusted

# Publish to private repository
Publish-Module -Path ".\MyModule" -Repository CompanyRepo
```

## Module Troubleshooting

### Common Issues

```powershell
# Check module paths
$env:PSModulePath -split [System.IO.Path]::PathSeparator

# Check execution policy
Get-ExecutionPolicy -List

# View module loading errors
$Error | Where-Object { $_.CategoryInfo.Category -eq 'InvalidOperation' }

# Force reload module
Remove-Module MyModule -Force; Import-Module MyModule -Force
```

### Debug Module Loading

```powershell
# Enable module logging
$VerbosePreference = 'Continue'
Import-Module MyModule -Verbose

# Trace module execution
Set-PSDebug -Trace 2
Import-Module MyModule
Set-PSDebug -Trace 0
```

## Related Documentation

- **[PowerShell Functions](functions.md)** - Creating reusable functions
- **[PowerShell Classes](classes.md)** - Object-oriented programming
- **[Pester Testing](testing.md)** - Unit testing framework

---

*This guide covers PowerShell modules from basic concepts to advanced publishing scenarios. Modules are essential for creating maintainable and reusable PowerShell code.*
