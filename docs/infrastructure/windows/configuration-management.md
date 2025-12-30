---
title: Windows Server Configuration Management
description: Comprehensive guide to Windows Server configuration management using PowerShell, winget, and automation tools for efficient server administration.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: article
ms.service: windows-server
keywords: PowerShell, winget, configuration management, automation, Windows Server, DSC, package management
uid: docs.infrastructure.windows.configuration-management
---

Configuration management is essential for maintaining consistent, secure, and efficient Windows Server environments. This guide covers PowerShell automation, package management with winget, and configuration management best practices.

## PowerShell for Configuration Management

### PowerShell Execution Policy

Configure execution policy for secure script execution:

```powershell
# View current execution policy
Get-ExecutionPolicy

# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Set execution policy for local machine
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### PowerShell Modules Management

#### Installing PowerShell Modules

```powershell
# Install modules from PowerShell Gallery
Install-Module -Name PowerShellGet -Force
Install-Module -Name PackageManagement -Force
Install-Module -Name PSWindowsUpdate -Force
Install-Module -Name ActiveDirectory -Force

# Install specific version
Install-Module -Name Az -RequiredVersion 9.0.0

# Install for all users
Install-Module -Name SqlServer -Scope AllUsers
```

#### Module Management Commands

```powershell
# List installed modules
Get-InstalledModule

# Update modules
Update-Module

# Uninstall modules
Uninstall-Module -Name ModuleName

# Import modules
Import-Module -Name ActiveDirectory
```

### PowerShell Desired State Configuration (DSC)

#### DSC Configuration Example

```powershell
Configuration WebServerConfig {
    param(
        [string[]]$NodeName = 'localhost'
    )

    Node $NodeName {
        # Enable IIS
        WindowsFeature IIS {
            Name = 'IIS-WebServer'
            Ensure = 'Present'
        }

        # Configure website
        File WebContent {
            DestinationPath = 'C:\inetpub\wwwroot\index.html'
            Contents = '<h1>Hello World</h1>'
            Ensure = 'Present'
            Type = 'File'
        }

        # Configure service
        Service W3SVC {
            Name = 'W3SVC'
            State = 'Running'
            StartupType = 'Automatic'
            DependsOn = '[WindowsFeature]IIS'
        }
    }
}

# Compile configuration
WebServerConfig -NodeName 'Server01'

# Apply configuration
Start-DscConfiguration -Path .\WebServerConfig -Wait -Verbose
```

#### DSC Resource Management

```powershell
# Install DSC resources
Install-Module -Name PSDscResources
Install-Module -Name xWebAdministration
Install-Module -Name SqlServerDsc

# List available DSC resources
Get-DscResource

# Get specific resource information
Get-DscResource -Name File
```

### PowerShell Remoting

#### Enable PowerShell Remoting

```powershell
# Enable PS Remoting
Enable-PSRemoting -Force

# Configure trusted hosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*"

# Test connection
Test-WSMan -ComputerName Server01
```

#### Remote Session Management

```powershell
# Create persistent session
$session = New-PSSession -ComputerName Server01 -Credential (Get-Credential)

# Execute commands remotely
Invoke-Command -Session $session -ScriptBlock {
    Get-Service | Where-Object Status -eq 'Running'
}

# Import remote module
Import-PSSession -Session $session -Module ActiveDirectory

# Close session
Remove-PSSession -Session $session
```

## Package Management with winget

### winget Installation and Setup

```powershell
# Install winget (if not already installed)
# Download from Microsoft Store or GitHub

# Update winget
winget upgrade --id Microsoft.AppInstaller

# Configure winget settings
winget settings --enable LocalManifestFiles
```

### Basic winget Commands

```powershell
# Search for packages
winget search "Visual Studio Code"
winget search --source msstore

# Install packages
winget install Microsoft.VisualStudioCode
winget install --id Git.Git
winget install --source msstore Microsoft.PowerToys

# List installed packages
winget list

# Upgrade packages
winget upgrade --all
winget upgrade Microsoft.VisualStudioCode

# Uninstall packages
winget uninstall Microsoft.VisualStudioCode
```

### Advanced winget Usage

#### Package Configuration Files

Create a `winget-packages.json` file:

```json
{
    "Sources": [
        {
            "Packages": [
                {
                    "PackageIdentifier": "Microsoft.VisualStudioCode"
                },
                {
                    "PackageIdentifier": "Git.Git"
                },
                {
                    "PackageIdentifier": "Microsoft.PowerToys"
                },
                {
                    "PackageIdentifier": "7zip.7zip"
                },
                {
                    "PackageIdentifier": "Microsoft.WindowsTerminal"
                }
            ],
            "SourceDetails": {
                "Argument": "https://cdn.winget.microsoft.com/cache",
                "Identifier": "Microsoft.Winget.Source_8wekyb3d8bbwe",
                "Name": "winget",
                "Type": "Microsoft.PreIndexed.Package"
            }
        }
    ]
}
```

#### Bulk Installation

```powershell
# Install from configuration file
winget import --import-file winget-packages.json

# Export current packages
winget export --output installed-packages.json

# Install essential development tools
$packages = @(
    "Microsoft.VisualStudioCode",
    "Git.Git",
    "Microsoft.PowerToys",
    "7zip.7zip",
    "Microsoft.WindowsTerminal",
    "Microsoft.Sysinternals.ProcessExplorer"
)

foreach ($package in $packages)
{
    winget install --id $package --silent
}
```

### winget for Server Management

#### Server Software Installation

```powershell
# Install server management tools
winget install Microsoft.Sysinternals.ProcessMonitor
winget install Microsoft.Sysinternals.ProcessExplorer
winget install Microsoft.Sysinternals.TCPView
winget install WiresharkFoundation.Wireshark

# Install development tools
winget install Microsoft.VisualStudio.2022.Professional
winget install Microsoft.SQLServerManagementStudio
winget install Microsoft.dotnet
```

## Configuration Management Scripts

### Server Initial Configuration Script

```powershell
# Server-Initial-Config.ps1
[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,
    [string]$TimeZone = "Eastern Standard Time",
    [string]$DomainName = $null
)

# Set timezone
Set-TimeZone -Name $TimeZone

# Enable RDP
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Configure Windows Update
Install-Module PSWindowsUpdate -Force
Get-WindowsUpdate -Install -AcceptAll -AutoReboot

# Install essential software
$essentialPackages = @(
    "Microsoft.Sysinternals.ProcessExplorer",
    "Microsoft.Sysinternals.ProcessMonitor",
    "7zip.7zip",
    "Microsoft.PowerToys"
)

foreach ($package in $essentialPackages)
{
    try
    {
        winget install --id $package --silent
        Write-Host "Installed: $package" -ForegroundColor Green
    }
    catch
    {
        Write-Warning "Failed to install: $package"
    }
}

# Configure firewall
New-NetFirewallRule -DisplayName "Allow ICMP" -Direction Inbound -Protocol ICMPv4 -Action Allow

# Join domain if specified
if ($DomainName)
{
    Add-Computer -DomainName $DomainName -Credential (Get-Credential) -Restart
}
```

### Software Deployment Script

```powershell
# Deploy-Software.ps1
[CmdletBinding()]
param(
    [string[]]$ComputerName = @($env:COMPUTERNAME),
    [string[]]$Packages = @()
)

$scriptBlock = {
    param($PackageList)
    
    foreach ($package in $PackageList)
    {
        try
        {
            $result = winget install --id $package --silent
            [PSCustomObject]@{
                Package = $package
                Status = "Success"
                Message = "Installed successfully"
            }
        }
        catch
        {
            [PSCustomObject]@{
                Package = $package
                Status = "Failed"
                Message = $_.Exception.Message
            }
        }
    }
}

$results = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList (,$Packages)

# Display results
$results | Format-Table -AutoSize
```

## Group Policy Management

### PowerShell Group Policy Module

```powershell
# Install Group Policy module
Import-Module GroupPolicy

# Create new GPO
New-GPO -Name "Server Security Policy" -Comment "Security settings for servers"

# Link GPO to OU
New-GPLink -Name "Server Security Policy" -Target "OU=Servers,DC=domain,DC=com"

# Configure GPO settings
Set-GPRegistryValue -Name "Server Security Policy" -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "EnableLUA" -Type DWord -Value 1
```

### Common GPO Configurations

```powershell
# Disable unnecessary services
$gpoName = "Server Security Policy"
$services = @(
    "Fax",
    "Spooler",
    "Themes",
    "TabletInputService"
)

foreach ($service in $services)
{
    Set-GPRegistryValue -Name $gpoName -Key "HKLM\System\CurrentControlSet\Services\$service" -ValueName "Start" -Type DWord -Value 4
}

# Configure audit policies
Set-GPRegistryValue -Name $gpoName -Key "HKLM\System\CurrentControlSet\Control\Lsa" -ValueName "AuditBaseObjects" -Type DWord -Value 1
Set-GPRegistryValue -Name $gpoName -Key "HKLM\System\CurrentControlSet\Control\Lsa" -ValueName "FullPrivilegeAuditing" -Type DWord -Value 1
```

## Registry Management

### Registry Automation

```powershell
# Registry backup
$backupPath = "C:\Backups\Registry"
if (-not (Test-Path $backupPath))
{
    New-Item -Path $backupPath -ItemType Directory
}

reg export HKLM "$backupPath\HKLM-$(Get-Date -Format 'yyyyMMdd-HHmmss').reg"
reg export HKCU "$backupPath\HKCU-$(Get-Date -Format 'yyyyMMdd-HHmmss').reg"

# Registry modifications
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 5
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -Value 3
```

## Service Management

### Service Configuration Scripts

```powershell
# Configure-Services.ps1
$serviceConfigs = @(
    @{Name = "Spooler"; StartupType = "Disabled"; Status = "Stopped"},
    @{Name = "Fax"; StartupType = "Disabled"; Status = "Stopped"},
    @{Name = "W32Time"; StartupType = "Automatic"; Status = "Running"},
    @{Name = "EventLog"; StartupType = "Automatic"; Status = "Running"}
)

foreach ($config in $serviceConfigs)
{
    $service = Get-Service -Name $config.Name -ErrorAction SilentlyContinue
    if ($service)
    {
        Set-Service -Name $config.Name -StartupType $config.StartupType
        if ($config.Status -eq "Running")
        {
            Start-Service -Name $config.Name
        }
        else
        {
            Stop-Service -Name $config.Name -Force
        }
        Write-Host "Configured service: $($config.Name)" -ForegroundColor Green
    }
}
```

## Automated Configuration Management

### Configuration Management Framework

```powershell
# ConfigMgmt-Framework.ps1
class ConfigManager {
    [string]$ConfigPath
    [hashtable]$Configuration
    
    ConfigManager([string]$configPath) {
        $this.ConfigPath = $configPath
        $this.LoadConfiguration()
    }
    
    [void]LoadConfiguration()
    {
        if (Test-Path $this.ConfigPath)
        {
            $this.Configuration = Get-Content $this.ConfigPath | ConvertFrom-Json -AsHashtable
        }
    }
    
    [void]ApplyConfiguration() {
        # Apply services configuration
        if ($this.Configuration.Services)
        {
            foreach ($service in $this.Configuration.Services)
            {
                Set-Service -Name $service.Name -StartupType $service.StartupType
            }
        }
        
        # Apply registry settings
        if ($this.Configuration.Registry)
        {
            foreach ($reg in $this.Configuration.Registry)
            {
                Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value
            }
        }
        
        # Install software
        if ($this.Configuration.Software)
        {
            foreach ($package in $this.Configuration.Software)
            {
                winget install --id $package --silent
            }
        }
    }
}

# Usage
$configManager = [ConfigManager]::new("C:\Config\server-config.json")
$configManager.ApplyConfiguration()
```

### Configuration File Example

```json
{
    "Services": [
        {
            "Name": "Spooler",
            "StartupType": "Disabled"
        },
        {
            "Name": "W32Time",
            "StartupType": "Automatic"
        }
    ],
    "Registry": [
        {
            "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System",
            "Name": "ConsentPromptBehaviorAdmin",
            "Value": 5
        }
    ],
    "Software": [
        "Microsoft.Sysinternals.ProcessExplorer",
        "7zip.7zip",
        "Microsoft.PowerToys"
    ]
}
```

## Monitoring and Maintenance

### System Health Monitoring

```powershell
# System-Health-Monitor.ps1
function Get-SystemHealth
{
    $health = @{
        ComputerName = $env:COMPUTERNAME
        Timestamp = Get-Date
        CPU = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
        Memory = Get-WmiObject -Class Win32_OperatingSystem
        Disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object DriveType -eq 3
        Services = Get-Service | Where-Object Status -eq "Stopped" | Where-Object StartType -eq "Automatic"
        EventLogs = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2,3; StartTime=(Get-Date).AddHours(-24)} -MaxEvents 10
    }
    
    return $health
}

# Generate health report
$health = Get-SystemHealth
$health | ConvertTo-Json -Depth 3 | Out-File "C:\Reports\HealthReport-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
```

## Best Practices

### Security Best Practices

1. **Least Privilege Access**
   - Use dedicated service accounts
   - Implement Just-In-Time access
   - Regular access reviews

2. **Configuration Management**
   - Use version control for scripts
   - Implement change management
   - Document all configurations

3. **Automation Security**
   - Secure credential storage
   - Code signing for scripts
   - Regular security audits

### Performance Optimization

1. **PowerShell Performance**
   - Use built-in cmdlets over external tools
   - Implement proper error handling
   - Use PowerShell profiles efficiently

2. **Package Management**
   - Use package repositories
   - Implement caching strategies
   - Regular package updates

### Maintenance Procedures

1. **Regular Tasks**
   - Monthly security updates
   - Quarterly configuration reviews
   - Annual disaster recovery testing

2. **Documentation**
   - Maintain configuration baselines
   - Document custom scripts
   - Keep runbooks updated

## Troubleshooting

### Common Issues

1. **PowerShell Execution Policy**

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   ```

2. **winget Package Installation Failures**

   ```powershell
   winget install --id PackageName --source winget --force
   ```

3. **DSC Configuration Failures**

   ```powershell
   Get-DscConfigurationStatus
   Start-DscConfiguration -UseExisting -Force
   ```

### Diagnostic Commands

```powershell
# System diagnostics
Get-ComputerInfo
Get-HotFix
Get-WindowsFeature | Where-Object InstallState -eq "Installed"

# PowerShell diagnostics
$PSVersionTable
Get-ExecutionPolicy -List
Get-Module -ListAvailable
```

## Related Topics

### Windows Documentation

- **[Windows Server Overview](index.md)** - Server roles, features, and editions
- **[Configuration Overview](configuration.md)** - Quick configuration reference
- **[Security Quick Start](security.md)** - Essential security hardening
- **[Security (Advanced)](security/index.md)** - Comprehensive security guide

### Development and Automation

- **[PowerShell Development](~/docs/development/powershell/index.md)** - PowerShell coding standards and best practices
- **[Ansible](~/docs/infrastructure/ansible/index.md)** - Cross-platform automation
- **[Terraform](~/docs/infrastructure/terraform/index.md)** - Infrastructure as code

### Infrastructure Management

- **[Monitoring](~/docs/infrastructure/monitoring/index.md)** - Infrastructure monitoring and alerting
- **[Disaster Recovery](~/docs/infrastructure/disaster-recovery/index.md)** - Backup and recovery strategies

## Conclusion

Effective configuration management is crucial for maintaining secure, efficient, and consistent Windows Server environments. By leveraging PowerShell, winget, and automation tools, administrators can streamline server management tasks while maintaining security and compliance standards.

Regular monitoring, proper documentation, and adherence to best practices ensure that your Windows Server infrastructure remains reliable and secure over time.
