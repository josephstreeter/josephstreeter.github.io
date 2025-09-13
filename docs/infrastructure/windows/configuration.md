---
title: Windows Configuration
description: Comprehensive guide to Windows server and workstation configuration, including PowerShell automation, Group Policy, and enterprise management
author: Joseph Streeter
date: 2024-01-15
tags: [windows, configuration, powershell, group-policy, enterprise, server]
---

This guide provides comprehensive Windows configuration management strategies for both servers and workstations in enterprise environments. It covers PowerShell automation, Group Policy management, and modern Windows administration techniques.

## Windows Server Configuration

### Initial Server Setup

#### Core Server Configuration

```powershell
# Set computer name and join domain
$ComputerName = "SRV-WEB-01"
$DomainName = "contoso.com"
$Credential = Get-Credential

# Rename computer
Rename-Computer -NewName $ComputerName -Force

# Configure network settings
$NetworkAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
New-NetIPAddress -InterfaceIndex $NetworkAdapter.InterfaceIndex -IPAddress "192.168.1.100" -PrefixLength 24 -DefaultGateway "192.168.1.1"
Set-DnsClientServerAddress -InterfaceIndex $NetworkAdapter.InterfaceIndex -ServerAddresses "192.168.1.10","192.168.1.11"

# Join domain
Add-Computer -DomainName $DomainName -Credential $Credential -Restart
```

#### Windows Features Management

```powershell
# Install IIS with common features
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent

# Install Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Install Windows Subsystem for Linux
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

#### PowerShell Configuration

```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Install PowerShell modules
Install-Module -Name Az -Force -AllowClobber
Install-Module -Name ActiveDirectory -Force
Install-Module -Name GroupPolicy -Force
Install-Module -Name DnsServer -Force

# Configure PowerShell profile
$ProfilePath = $PROFILE.AllUsersAllHosts
New-Item -ItemType File -Path $ProfilePath -Force

@"
# Global PowerShell Profile
Set-Location C:\
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
Import-Module GroupPolicy -ErrorAction SilentlyContinue

# Custom functions
function Get-ServerInfo {
    Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory, CsProcessors
}

function Test-Services {
    Get-Service | Where-Object {$_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic'}
}

# Set prompt
function prompt {
    "PS [$([Environment]::UserName)@$([Environment]::MachineName)] $($ExecutionContext.SessionState.Path.CurrentLocation)> "
}
"@ | Out-File -FilePath $ProfilePath -Encoding UTF8
```

### Windows Server Roles Configuration

#### Active Directory Domain Services

```powershell
# Install AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to domain controller
$SafeModePassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
Install-ADDSForest -DomainName "contoso.com" -SafeModeAdministratorPassword $SafeModePassword -Force

# Configure additional domain controllers
Install-ADDSDomainController -DomainName "contoso.com" -SafeModeAdministratorPassword $SafeModePassword -Force
```

#### DNS Server Configuration

```powershell
# Install DNS Server role
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Configure DNS zones
Add-DnsServerPrimaryZone -Name "contoso.com" -ZoneFile "contoso.com.dns"
Add-DnsServerPrimaryZone -Name "1.168.192.in-addr.arpa" -ZoneFile "192.168.1.dns"

# Add DNS records
Add-DnsServerResourceRecordA -ZoneName "contoso.com" -Name "web" -IPv4Address "192.168.1.100"
Add-DnsServerResourceRecordCName -ZoneName "contoso.com" -Name "www" -HostNameAlias "web.contoso.com"

# Configure forwarders
Add-DnsServerForwarder -IPAddress "8.8.8.8","8.8.4.4"
```

#### DHCP Server Configuration

```powershell
# Install DHCP Server role
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# Configure DHCP scope
Add-DhcpServerv4Scope -Name "Main Network" -StartRange "192.168.1.50" -EndRange "192.168.1.150" -SubnetMask "255.255.255.0"

# Set DHCP options
Set-DhcpServerv4OptionValue -ScopeId "192.168.1.0" -DnsServer "192.168.1.10","192.168.1.11" -Router "192.168.1.1"

# Authorize DHCP server
Add-DhcpServerInDC -DnsName "dhcp.contoso.com" -IPAddress "192.168.1.10"
```

## Group Policy Management

### Creating and Managing GPOs

```powershell
# Create new GPO
New-GPO -Name "Security Baseline" -Domain "contoso.com"

# Link GPO to OU
New-GPLink -Name "Security Baseline" -Target "OU=Servers,DC=contoso,DC=com"

# Set registry-based policy
Set-GPRegistryValue -Name "Security Baseline" -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "EnableLUA" -Type DWord -Value 1

# Set security policy
$GPO = Get-GPO -Name "Security Baseline"
Set-GPPermissions -Guid $GPO.Id -TargetName "Domain Computers" -TargetType Group -PermissionLevel GpoApply
```

### Security Baseline GPO Settings

```powershell
# Password policy
Set-GPRegistryValue -Name "Security Baseline" -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "RequireSignOrSeal" -Type DWord -Value 1

# Account lockout policy
Set-GPRegistryValue -Name "Security Baseline" -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "LockoutThreshold" -Type DWord -Value 5

# Audit policy
Set-GPRegistryValue -Name "Security Baseline" -Key "HKLM\SYSTEM\CurrentControlSet\Services\eventlog\Security" -ValueName "AuditLogonEvents" -Type DWord -Value 3

# Windows Firewall
Set-GPRegistryValue -Name "Security Baseline" -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile" -ValueName "EnableFirewall" -Type DWord -Value 1
```

### Administrative Templates

```powershell
# Download and install administrative templates
$AdminTemplatesPath = "C:\Windows\PolicyDefinitions"

# Configure Windows Update settings
Set-GPRegistryValue -Name "Windows Update Policy" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AUOptions" -Type DWord -Value 4
Set-GPRegistryValue -Name "Windows Update Policy" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallDay" -Type DWord -Value 0
Set-GPRegistryValue -Name "Windows Update Policy" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallTime" -Type DWord -Value 3
```

## PowerShell DSC (Desired State Configuration)

### Basic DSC Configuration

```powershell
# DSC Configuration for web server
Configuration WebServer {
    param (
        [Parameter(Mandatory)]
        [String[]]$ComputerName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $ComputerName {
        WindowsFeature IIS {
            Ensure = "Present"
            Name   = "Web-Server"
        }

        WindowsFeature ASPNet45 {
            Ensure = "Present"
            Name   = "Web-Asp-Net45"
        }

        File WebContent {
            Ensure          = "Present"
            SourcePath      = "\\server\share\webcontent"
            DestinationPath = "C:\inetpub\wwwroot"
            Recurse         = $true
            Type            = "Directory"
            DependsOn       = "[WindowsFeature]IIS"
        }

        Service W3SVC {
            Ensure = "Running"
            Name   = "W3SVC"
            State  = "Running"
            DependsOn = "[WindowsFeature]IIS"
        }
    }
}

# Compile configuration
WebServer -ComputerName "WEB01","WEB02" -OutputPath "C:\DSC\WebServer"

# Apply configuration
Start-DscConfiguration -Path "C:\DSC\WebServer" -Wait -Verbose
```

### Advanced DSC Configuration

```powershell
# DSC Configuration with custom resources
Configuration ADDomainController {
    param (
        [Parameter(Mandatory)]
        [String]$DomainName,
        
        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )

    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node localhost {
        WindowsFeature ADDSInstall {
            Ensure = "Present"
            Name   = "AD-Domain-Services"
        }

        ADDomain CreateDomain {
            DomainName = $DomainName
            Credential = $Credential
            SafemodeAdministratorPassword = $Credential
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        ADOrganizationalUnit Servers {
            Name = "Servers"
            Path = "DC=contoso,DC=com"
            Ensure = "Present"
            DependsOn = "[ADDomain]CreateDomain"
        }

        ADOrganizationalUnit Workstations {
            Name = "Workstations"
            Path = "DC=contoso,DC=com"
            Ensure = "Present"
            DependsOn = "[ADDomain]CreateDomain"
        }
    }
}
```

## Windows Workstation Configuration

### Enterprise Workstation Setup

```powershell
# Automated workstation configuration script
param(
    [Parameter(Mandatory)]
    [string]$ComputerName,
    
    [Parameter(Mandatory)]
    [string]$DomainName,
    
    [Parameter(Mandatory)]
    [PSCredential]$DomainCredential
)

# Configure network settings
$NetworkAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.Physical -eq $true} | Select-Object -First 1

if ($NetworkAdapter) {
    # Remove existing IP configuration
    Remove-NetIPAddress -InterfaceIndex $NetworkAdapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $NetworkAdapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
    
    # Set static IP (customize as needed)
    New-NetIPAddress -InterfaceIndex $NetworkAdapter.InterfaceIndex -IPAddress "192.168.1.200" -PrefixLength 24 -DefaultGateway "192.168.1.1"
    Set-DnsClientServerAddress -InterfaceIndex $NetworkAdapter.InterfaceIndex -ServerAddresses "192.168.1.10","192.168.1.11"
}

# Rename computer
Rename-Computer -NewName $ComputerName -Force

# Install essential software
$SoftwareList = @(
    "Microsoft.VisualStudioCode",
    "Google.Chrome",
    "7zip.7zip",
    "Adobe.Acrobat.Reader.64-bit"
)

foreach ($Software in $SoftwareList) {
    try {
        winget install $Software --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Installed: $Software" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to install: $Software"
    }
}

# Configure Windows features
$FeaturesToEnable = @(
    "Microsoft-Windows-Subsystem-Linux",
    "VirtualMachinePlatform"
)

foreach ($Feature in $FeaturesToEnable) {
    Enable-WindowsOptionalFeature -Online -FeatureName $Feature -All -NoRestart
}

# Join domain
Add-Computer -DomainName $DomainName -Credential $DomainCredential -Restart
```

### User Profile Management

```powershell
# Configure default user profile
$DefaultUserProfile = "C:\Users\Default"
$ProfileRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

# Set default desktop wallpaper
$WallpaperPath = "C:\Windows\Web\Wallpaper\Corporate\corporate-wallpaper.jpg"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "Wallpaper" -Value $WallpaperPath

# Configure default applications
$DefaultAppsXML = @"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".pdf" ProgId="AcroExch.Document.DC" ApplicationName="Adobe Acrobat Reader DC" />
  <Association Identifier=".txt" ProgId="txtfile" ApplicationName="Notepad" />
  <Association Identifier="http" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="https" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
</DefaultAssociations>
"@

$DefaultAppsXML | Out-File -FilePath "C:\Windows\System32\DefaultAssociations.xml" -Encoding UTF8
```

## Registry Management

### Common Registry Configurations

```powershell
# Security settings
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netbt\Parameters" -Name "NoNameReleaseOnDemand" -Value 1

# Performance optimizations
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 2
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1

# Disable unnecessary services
$ServicesToDisable = @("Fax", "WSearch", "Themes")
foreach ($Service in $ServicesToDisable) {
    Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
}

# Configure Windows Update
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 4
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "ScheduledInstallDay" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "ScheduledInstallTime" -Value 3
```

### Registry Backup and Restore

```powershell
# Backup registry keys
$BackupPath = "C:\Backup\Registry"
New-Item -ItemType Directory -Path $BackupPath -Force

$KeysToBackup = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SYSTEM\CurrentControlSet\Services",
    "HKLM:\SOFTWARE\Policies"
)

foreach ($Key in $KeysToBackup) {
    $KeyName = ($Key -split "\\")[-1]
    $FileName = "$BackupPath\$KeyName-$(Get-Date -Format 'yyyyMMdd').reg"
    reg export $Key.Replace("HKLM:\", "HKEY_LOCAL_MACHINE\") $FileName /y
}

# Restore registry key
function Restore-RegistryKey {
    param(
        [Parameter(Mandatory)]
        [string]$BackupFile
    )
    
    if (Test-Path $BackupFile) {
        reg import $BackupFile
        Write-Host "Registry restored from: $BackupFile" -ForegroundColor Green
    } else {
        Write-Error "Backup file not found: $BackupFile"
    }
}
```

## Monitoring and Maintenance

### System Health Monitoring

```powershell
# System health check script
function Get-SystemHealth {
    [CmdletBinding()]
    param()
    
    $HealthReport = @{}
    
    # CPU usage
    $CPU = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
    $HealthReport.CPUUsage = [math]::Round($CPU.Average, 2)
    
    # Memory usage
    $Memory = Get-WmiObject -Class Win32_OperatingSystem
    $MemoryUsed = ($Memory.TotalVisibleMemorySize - $Memory.FreePhysicalMemory) / $Memory.TotalVisibleMemorySize * 100
    $HealthReport.MemoryUsage = [math]::Round($MemoryUsed, 2)
    
    # Disk space
    $Disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
    $HealthReport.DiskUsage = @{}
    foreach ($Disk in $Disks) {
        $UsedPercent = ($Disk.Size - $Disk.FreeSpace) / $Disk.Size * 100
        $HealthReport.DiskUsage[$Disk.DeviceID] = [math]::Round($UsedPercent, 2)
    }
    
    # Services status
    $CriticalServices = @("Spooler", "DHCP", "DNS", "W3SVC")
    $HealthReport.Services = @{}
    foreach ($Service in $CriticalServices) {
        $ServiceStatus = Get-Service -Name $Service -ErrorAction SilentlyContinue
        if ($ServiceStatus) {
            $HealthReport.Services[$Service] = $ServiceStatus.Status
        }
    }
    
    # Event log errors
    $ErrorEvents = Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddDays(-1) | Measure-Object
    $HealthReport.RecentErrors = $ErrorEvents.Count
    
    return $HealthReport
}

# Automated maintenance tasks
function Start-SystemMaintenance {
    Write-Host "Starting system maintenance..." -ForegroundColor Yellow
    
    # Clean temporary files
    Get-ChildItem -Path $env:TEMP -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem -Path "C:\Windows\Temp" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    
    # Clear event logs older than 30 days
    $EventLogs = @("Application", "System", "Security")
    foreach ($Log in $EventLogs) {
        Get-EventLog -LogName $Log | Where-Object {$_.TimeGenerated -lt (Get-Date).AddDays(-30)} | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    # Update Windows Defender signatures
    Update-MpSignature
    
    # Run disk cleanup
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait
    
    Write-Host "System maintenance completed." -ForegroundColor Green
}
```

### Automated Reporting

```powershell
# Generate system report
function New-SystemReport {
    param(
        [string]$OutputPath = "C:\Reports"
    )
    
    New-Item -ItemType Directory -Path $OutputPath -Force
    
    $ReportFile = "$OutputPath\SystemReport-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    
    $SystemInfo = Get-ComputerInfo
    $HealthInfo = Get-SystemHealth
    
    $HTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>System Report - $($SystemInfo.CsName)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .header { background-color: #4CAF50; color: white; padding: 10px; }
        .section { margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>System Report for $($SystemInfo.CsName)</h1>
        <p>Generated: $(Get-Date)</p>
    </div>
    
    <div class="section">
        <h2>System Information</h2>
        <table>
            <tr><th>Property</th><th>Value</th></tr>
            <tr><td>Computer Name</td><td>$($SystemInfo.CsName)</td></tr>
            <tr><td>Operating System</td><td>$($SystemInfo.WindowsProductName)</td></tr>
            <tr><td>Version</td><td>$($SystemInfo.WindowsVersion)</td></tr>
            <tr><td>Total Memory</td><td>$([math]::Round($SystemInfo.TotalPhysicalMemory/1GB, 2)) GB</td></tr>
            <tr><td>Processor</td><td>$($SystemInfo.CsProcessors[0].Name)</td></tr>
        </table>
    </div>
    
    <div class="section">
        <h2>Performance Metrics</h2>
        <table>
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>CPU Usage</td><td>$($HealthInfo.CPUUsage)%</td></tr>
            <tr><td>Memory Usage</td><td>$($HealthInfo.MemoryUsage)%</td></tr>
            <tr><td>Recent Errors</td><td>$($HealthInfo.RecentErrors)</td></tr>
        </table>
    </div>
</body>
</html>
"@
    
    $HTML | Out-File -FilePath $ReportFile -Encoding UTF8
    Write-Host "Report generated: $ReportFile" -ForegroundColor Green
    
    # Email report (optional)
    # Send-MailMessage -To "admin@company.com" -From "server@company.com" -Subject "System Report" -Attachments $ReportFile -SmtpServer "smtp.company.com"
}
```

## Related Topics

- [Windows Security](~/docs/infrastructure/windows/security.md)
- [Windows Configuration Management](~/docs/infrastructure/windows/configuration-management.md)
- [Active Directory Services](~/docs/services/activedirectory/index.md)
- [PowerShell Scripting](~/docs/development/powershell/index.md)

## Topics

Add topics here.
