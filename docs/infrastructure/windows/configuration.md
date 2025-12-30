---
title: Windows Configuration Overview
description: Quick-start guide to Windows configuration with links to comprehensive configuration management documentation
author: Joseph Streeter
ms.author: jstreeter
ms.date: 2024-12-30
ms.topic: overview
ms.service: windows-server
keywords: Windows configuration, quick start, overview, setup guide, Windows Server, workstation configuration
uid: docs.infrastructure.windows.configuration
---

This guide provides a quick-start overview of Windows configuration for both servers and workstations. For comprehensive configuration management including PowerShell DSC, automation, and package management, see [Configuration Management](configuration-management.md).

## Quick Configuration Paths

### For Windows Server Administrators

**Initial Server Setup** → [Configuration Management: Server Initial Configuration](configuration-management.md#server-initial-configuration-script)

Key topics:

- Post-installation configuration
- Network settings
- Domain join procedures
- Essential software installation

**Server Roles Configuration** → [Index: Server Roles and Features](index.md#server-roles-and-features)

Available roles:

- Active Directory Domain Services
- DNS Server
- DHCP Server
- File Services
- Hyper-V

**Group Policy Management** → [Configuration Management: Group Policy Management](configuration-management.md#group-policy-management)

Group Policy operations:

- Creating and linking GPOs
- Registry-based policies
- Audit policies
- Software deployment

### For Workstation Administrators

**Enterprise Workstation Setup** → [Configuration Management: Workstation Configuration](#windows-workstation-configuration)

Key areas:

- Automated deployment
- Software installation
- User profile management
- Default application associations

**Package Management** → [Configuration Management: winget](configuration-management.md#package-management-with-winget)

Package management:

- Installing applications
- Bulk deployment
- Configuration files
- Enterprise software distribution

## Core Configuration Areas

### Initial Server Setup

Basic server configuration after installation:

```powershell
# Set computer name and restart
Rename-Computer -NewName "SERVER01" -Restart

# Configure static IP address
$Adapter = Get-NetAdapter | Where-Object Status -eq "Up"
New-NetIPAddress -InterfaceIndex $Adapter.InterfaceIndex `
    -IPAddress "192.168.1.100" `
    -PrefixLength 24 `
    -DefaultGateway "192.168.1.1"

# Set DNS servers
Set-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex `
    -ServerAddresses "192.168.1.10","192.168.1.11"

# Join domain (credential prompt will appear)
Add-Computer -DomainName "contoso.com" -Credential (Get-Credential) -Restart
```

For detailed server configuration including Server Core setup, see [Configuration Management](configuration-management.md).

### Windows Features Management

Install common Windows features:

```powershell
# Install IIS with management tools
Install-WindowsFeature Web-Server -IncludeManagementTools

# Install Hyper-V
Install-WindowsFeature Hyper-V -IncludeManagementTools -Restart

# Install Active Directory tools
Install-WindowsFeature RSAT-ADDS -IncludeManagementTools
```

### PowerShell Configuration

Basic PowerShell setup:

```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install PowerShellGet and update modules
Install-Module -Name PowerShellGet -Force
Update-Module PowerShellGet
```

For advanced PowerShell configuration including DSC and remoting, see [Configuration Management: PowerShell](configuration-management.md#powershell-for-configuration-management).

## Windows Workstation Configuration

### Enterprise Workstation Setup

Quick workstation deployment script:

```powershell
# Basic workstation configuration
param(
    [Parameter(Mandatory)]
    [string]$ComputerName,
    
    [Parameter(Mandatory)]
    [string]$DomainName
)

# Rename computer
Rename-Computer -NewName $ComputerName -Force

# Configure network (DHCP)
$Adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex `
    -ServerAddresses "192.168.1.10","192.168.1.11"

# Install essential software via winget
$EssentialApps = @(
    "Microsoft.VisualStudioCode",
    "Google.Chrome",
    "7zip.7zip",
    "Adobe.Acrobat.Reader.64-bit"
)

foreach ($App in $EssentialApps) {
    winget install $App --silent --accept-source-agreements --accept-package-agreements
}

# Join domain
Add-Computer -DomainName $DomainName -Credential (Get-Credential) -Restart
```

### User Profile Management

Configure default user settings:

```powershell
# Set default desktop wallpaper
$WallpaperPath = "C:\Windows\Web\Wallpaper\Corporate\wallpaper.jpg"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -Name "Wallpaper" -Value $WallpaperPath

# Disable Windows Search indexing for better performance
Stop-Service -Name "WSearch" -Force
Set-Service -Name "WSearch" -StartupType Disabled
```

For comprehensive user profile management and Group Policy configuration, see [Configuration Management](configuration-management.md).

## Registry Management

### Common Registry Configurations

```powershell
# Performance optimizations
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
    -Name "Win32PrioritySeparation" -Value 2

# Security settings
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "LimitBlankPasswordUse" -Value 1

# Disable unnecessary services
$ServicesToDisable = @("Fax", "WSearch", "Themes")
foreach ($Service in $ServicesToDisable) {
    Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
}
```

### Registry Backup

> [!IMPORTANT]
> Always backup the registry before making changes. Test changes in a non-production environment first.

```powershell
# Export registry keys for backup
$BackupPath = "C:\Backup\Registry"
New-Item -ItemType Directory -Path $BackupPath -Force

$KeysToBackup = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SYSTEM\CurrentControlSet\Services"
)

foreach ($Key in $KeysToBackup) {
    $KeyName = ($Key -split "\\")[-1]
    $FileName = "$BackupPath\$KeyName-$(Get-Date -Format 'yyyyMMdd').reg"
    reg export $Key.Replace("HKLM:\", "HKEY_LOCAL_MACHINE\") $FileName /y
}
```

## Monitoring and Maintenance

### System Health Check

Quick system health assessment:

```powershell
function Get-SystemHealth {
    [CmdletBinding()]
    param()
    
    # CPU usage
    $CPU = Get-WmiObject -Class Win32_Processor | 
        Measure-Object -Property LoadPercentage -Average
    
    # Memory usage
    $OS = Get-WmiObject -Class Win32_OperatingSystem
    $MemoryUsedPercent = ($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / 
        $OS.TotalVisibleMemorySize * 100
    
    # Disk space
    $Disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object DriveType -eq 3
    
    # Failed services
    $FailedServices = Get-Service | 
        Where-Object {$_.Status -eq "Stopped" -and $_.StartType -eq "Automatic"}
    
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        CPUUsage = [math]::Round($CPU.Average, 2)
        MemoryUsage = [math]::Round($MemoryUsedPercent, 2)
        DiskSpace = $Disks | Select-Object DeviceID, 
            @{N='FreeGB';E={[math]::Round($_.FreeSpace/1GB,2)}},
            @{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}}
        FailedServices = $FailedServices.Count
    }
}

# Run health check
Get-SystemHealth
```

For comprehensive monitoring solutions, see [Configuration Management: Monitoring](configuration-management.md#monitoring-and-maintenance).

## Next Steps

### Essential Reading

- **[Configuration Management](configuration-management.md)** - Comprehensive PowerShell automation, DSC, winget, and package management
- **[Security Overview](security.md)** - Quick security hardening guide
- **[Security (Advanced)](security/index.md)** - Comprehensive security documentation
- **[Index](index.md)** - Windows Server overview and server roles

### Common Tasks

- **Automate configuration** → [Configuration Management: DSC](configuration-management.md#powershell-desired-state-configuration-dsc)
- **Deploy software** → [Configuration Management: winget](configuration-management.md#package-management-with-winget)
- **Manage policies** → [Configuration Management: Group Policy](configuration-management.md#group-policy-management)
- **Secure systems** → [Security Overview](security.md)

### External Resources

- **Microsoft Learn**: [Windows Server documentation](https://learn.microsoft.com/en-us/windows-server/)
- **PowerShell Gallery**: [PowerShell modules](https://www.powershellgallery.com/)
- **winget**: [Windows Package Manager](https://learn.microsoft.com/en-us/windows/package-manager/)

This overview provides quick reference for common configuration tasks. For detailed procedures, automation scripts, and advanced configuration management, refer to the comprehensive documentation linked throughout this guide.
