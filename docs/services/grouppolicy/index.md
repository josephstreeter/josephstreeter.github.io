---
title: Group Policy Management
description: Complete guide to Windows Group Policy configuration, deployment, and troubleshooting
author: Joseph Streeter
date: 2024-01-15
tags: [windows, group-policy, active-directory, gpo, management]
---

Windows Group Policy provides centralized management and configuration of users and computers in an Active Directory environment. This guide covers essential Group Policy concepts, implementation, and best practices.

## Group Policy Overview

### What is Group Policy?

Group Policy is a feature of Windows that allows administrators to manage the working environment of users and computers through centralized configuration. It enables:

- Centralized configuration management
- Security policy enforcement  
- Software deployment
- Desktop environment control
- System settings standardization

### Group Policy Components

#### Group Policy Objects (GPOs)

- **Domain GPOs**: Applied at domain level
- **Site GPOs**: Applied to Active Directory sites
- **OU GPOs**: Applied to Organizational Units
- **Local GPOs**: Applied locally to individual computers

#### Group Policy Container (GPC)

Stored in Active Directory, contains:

- GPO properties and version information
- Links to Group Policy Templates
- Access control information

#### Group Policy Template (GPT)

Stored in SYSVOL, contains:

- Administrative templates
- Security settings
- Scripts and software installation packages

## Creating and Managing GPOs

### Creating a New GPO

```powershell
# Import Group Policy module
Import-Module GroupPolicy

# Create new GPO
New-GPO -Name "Corporate Security Policy" -Domain "contoso.com"

# Create and link GPO to OU
$OU = "OU=Workstations,DC=contoso,DC=com"
New-GPO -Name "Workstation Settings" | New-GPLink -Target $OU
```

### GPO Management Commands

```powershell
# List all GPOs
Get-GPO -All

# Get specific GPO
Get-GPO -Name "Default Domain Policy"

# Get GPO by GUID
Get-GPO -Guid "{12345678-1234-1234-1234-123456789012}"

# Copy GPO
Copy-GPO -SourceName "Template Policy" -TargetName "New Policy"

# Remove GPO
Remove-GPO -Name "Old Policy" -Confirm:$false
```

### Linking GPOs

```powershell
# Link GPO to domain
New-GPLink -Name "Domain Security Policy" -Target "DC=contoso,DC=com"

# Link GPO to OU
New-GPLink -Name "OU Policy" -Target "OU=Sales,DC=contoso,DC=com"

# Set link order
Set-GPLink -Name "Priority Policy" -Target "OU=Users,DC=contoso,DC=com" -Order 1

# Enable/Disable link
Set-GPLink -Name "Disabled Policy" -Target "OU=Test,DC=contoso,DC=com" -LinkEnabled No
```

## Group Policy Processing

### Processing Order

1. **Local Computer Policy**
2. **Site-linked GPOs**
3. **Domain-linked GPOs**
4. **OU-linked GPOs** (processed from parent to child)

### Processing Rules

#### Last Writer Wins

When multiple policies configure the same setting, the last applied policy takes precedence.

#### Block Inheritance

```powershell
# Block inheritance on OU
Set-GPInheritance -Target "OU=Isolated,DC=contoso,DC=com" -IsBlocked Yes

# View inheritance settings
Get-GPInheritance -Target "OU=Isolated,DC=contoso,DC=com"
```

#### Enforced Links

```powershell
# Enforce GPO link
Set-GPLink -Name "Security Policy" -Target "DC=contoso,DC=com" -Enforced Yes

# View enforced links
Get-GPLink -Target "DC=contoso,DC=com" | Where-Object {$_.Enforced -eq "Yes"}
```

### Loopback Processing

#### Replace Mode

User settings from computer GPOs completely replace user GPOs.

```powershell
# Configure loopback processing
$GPO = Get-GPO -Name "Computer Policy"
Set-GPRegistryValue -Name "Computer Policy" -Key "HKLM\Software\Policies\Microsoft\Windows\System" -ValueName "UserPolicyMode" -Type DWord -Value 2
```

#### Merge Mode

User settings from computer GPOs are processed after user GPOs.

```powershell
# Set merge mode
Set-GPRegistryValue -Name "Computer Policy" -Key "HKLM\Software\Policies\Microsoft\Windows\System" -ValueName "UserPolicyMode" -Type DWord -Value 1
```

## Security Settings

### Password Policy

```powershell
# Configure password policy
$GPO = "Default Domain Policy"

# Minimum password length
Set-GPRegistryValue -Name $GPO -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "MinimumPasswordLength" -Type DWord -Value 12

# Password complexity
Set-GPRegistryValue -Name $GPO -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "PasswordComplexity" -Type DWord -Value 1

# Maximum password age
Set-GPRegistryValue -Name $GPO -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "MaxPasswordAge" -Type DWord -Value 90
```

### Account Lockout Policy

```powershell
# Account lockout threshold
Set-GPRegistryValue -Name $GPO -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "LockoutBadCount" -Type DWord -Value 5

# Account lockout duration (minutes)
Set-GPRegistryValue -Name $GPO -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "LockoutDuration" -Type DWord -Value 30

# Reset account lockout counter (minutes)
Set-GPRegistryValue -Name $GPO -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "ResetLockoutCount" -Type DWord -Value 30
```

### User Rights Assignment

```powershell
# Grant logon as service right
$SID = (Get-ADUser -Identity "ServiceAccount").SID
Set-GPRegistryValue -Name $GPO -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "SeServiceLogonRight" -Type String -Value $SID

# Deny network logon
$SID = (Get-ADGroup -Identity "Restricted Users").SID
Set-GPRegistryValue -Name $GPO -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" -ValueName "SeDenyNetworkLogonRight" -Type String -Value $SID
```

## Administrative Templates

### Registry-Based Settings

```powershell
# Disable Windows Store
Set-GPRegistryValue -Name "Desktop Policy" -Key "HKLM\Software\Policies\Microsoft\WindowsStore" -ValueName "DisableStoreApps" -Type DWord -Value 1

# Configure Internet Explorer security
Set-GPRegistryValue -Name "Security Policy" -Key "HKCU\Software\Policies\Microsoft\Internet Explorer\Security" -ValueName "DisableSecuritySettingsCheck" -Type DWord -Value 1

# Set desktop wallpaper
Set-GPRegistryValue -Name "Desktop Policy" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "Wallpaper" -Type String -Value "\\server\share\wallpaper.jpg"
```

### Custom Administrative Templates

```xml
<!-- Custom ADMX template -->
<?xml version="1.0" encoding="utf-8"?>
<policyDefinitions xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                   revision="1.0" 
                   schemaVersion="1.0" 
                   xmlns="http://schemas.microsoft.com/GroupPolicy/2006/07/PolicyDefinitions">
  <policyNamespaces>
    <target prefix="company" namespace="Company.Policies" />
  </policyNamespaces>
  <resources minRequiredRevision="1.0" />
  <categories>
    <category name="CAT_Company" displayName="$(string.CAT_Company)">
      <parentCategory ref="windows:WindowsComponents" />
    </category>
  </categories>
  <policies>
    <policy name="POL_CompanySettings" class="Machine" displayName="$(string.POL_CompanySettings)" 
            explainText="$(string.POL_CompanySettings_Help)" key="Software\Company\Settings" 
            valueName="EnableFeature">
      <parentCategory ref="CAT_Company" />
      <supportedOn ref="windows:SUPPORTED_Windows7" />
      <enabledValue>
        <decimal value="1" />
      </enabledValue>
      <disabledValue>
        <decimal value="0" />
      </disabledValue>
    </policy>
  </policies>
</policyDefinitions>
```

## Software Deployment

### MSI Package Deployment

```powershell
# Deploy software via GPO
$GPO = "Software Deployment Policy"
$MsiPath = "\\server\share\software\application.msi"

# Add software installation
Add-GPSoftwareInstallation -Name $GPO -Path $MsiPath -AssignmentType Published

# Remove software installation
Remove-GPSoftwareInstallation -Name $GPO -PackageName "Application"
```

### Script Deployment

#### Startup Scripts

```powershell
# Add computer startup script
Set-GPRegistryValue -Name "Startup Scripts" -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Startup\0" -ValueName "Script" -Type String -Value "\\server\scripts\startup.cmd"

# Add parameters
Set-GPRegistryValue -Name "Startup Scripts" -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Startup\0" -ValueName "Parameters" -Type String -Value "/silent"
```

#### Logon Scripts

```powershell
# Add user logon script
Set-GPRegistryValue -Name "Logon Scripts" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Logon\0" -ValueName "Script" -Type String -Value "\\server\scripts\logon.vbs"
```

## Troubleshooting Group Policy

### Group Policy Result

```powershell
# Generate Group Policy Results report
Invoke-GPResult -ReportType HTML -Path "C:\Reports\GPResult.html"

# Generate for remote computer
Invoke-GPResult -Computer "Workstation01" -ReportType HTML -Path "C:\Reports\RemoteGPResult.html"

# Generate for specific user
Invoke-GPResult -User "Domain\Username" -ReportType HTML -Path "C:\Reports\UserGPResult.html"
```

### Group Policy Modeling

```powershell
# Model Group Policy for what-if scenarios
Invoke-GPModel -Computer "Workstation01" -User "Domain\TestUser" -ReportType HTML -Path "C:\Reports\GPModel.html"

# Model with loopback processing
Invoke-GPModel -Computer "Workstation01" -User "Domain\TestUser" -LoopbackMode Replace -ReportType HTML -Path "C:\Reports\GPModelLoopback.html"
```

### Event Log Analysis

```powershell
# Get Group Policy events
Get-WinEvent -LogName "Microsoft-Windows-GroupPolicy/Operational" | Where-Object {$_.Id -eq 4001}

# Get Group Policy errors
Get-WinEvent -LogName "System" | Where-Object {$_.Id -eq 1085 -or $_.Id -eq 1086}

# Export Group Policy events
Get-WinEvent -LogName "Microsoft-Windows-GroupPolicy/Operational" | Export-Csv "C:\Logs\GPEvents.csv"
```

### Manual Group Policy Processing

```powershell
# Force Group Policy update
gpupdate /force

# Update computer policy only
gpupdate /target:computer /force

# Update user policy only
gpupdate /target:user /force

# Remote Group Policy update
Invoke-Command -ComputerName "Workstation01" -ScriptBlock {gpupdate /force}
```

## Group Policy Backup and Restore

### Backup Operations

```powershell
# Backup single GPO
Backup-GPO -Name "Critical Policy" -Path "C:\GPOBackups"

# Backup all GPOs
Backup-GPO -All -Path "C:\GPOBackups"

# Backup with comment
Backup-GPO -Name "Security Policy" -Path "C:\GPOBackups" -Comment "Monthly backup"
```

### Restore Operations

```powershell
# Restore GPO from backup
Restore-GPO -Name "Critical Policy" -Path "C:\GPOBackups"

# Restore to different name
Restore-GPO -BackupId "{12345678-1234-1234-1234-123456789012}" -Path "C:\GPOBackups" -TargetName "Restored Policy"

# Import GPO settings
Import-GPO -BackupId "{12345678-1234-1234-1234-123456789012}" -Path "C:\GPOBackups" -TargetName "Target Policy"
```

### Migration Tables

```powershell
# Create migration table for cross-domain GPO migration
$MigTable = @{
    "OLD-DOMAIN\OldGroup" = "NEW-DOMAIN\NewGroup"
    "OLD-DOMAIN\OldUser" = "NEW-DOMAIN\NewUser"
}

# Use migration table during import
Import-GPO -BackupId "{12345678-1234-1234-1234-123456789012}" -Path "C:\GPOBackups" -TargetName "Migrated Policy" -MigrationTable $MigTable
```

## Performance and Optimization

### Group Policy Processing Time

```powershell
# Measure Group Policy processing time
Measure-Command {gpupdate /force}

# Enable verbose Group Policy logging
Set-GPRegistryValue -Name "Diagnostic Policy" -Key "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -ValueName "UserEnvDebugLevel" -Type DWord -Value 0x30002
```

### Optimization Strategies

#### Reduce GPO Scope

```powershell
# Use security filtering
Set-GPPermissions -Name "Limited Policy" -PermissionLevel GpoApply -TargetName "Specific Group" -TargetType Group

# Remove Authenticated Users if using security filtering
Set-GPPermissions -Name "Limited Policy" -PermissionLevel None -TargetName "Authenticated Users" -TargetType WellKnownGroup
```

#### Optimize WMI Filters

```powershell
# Create WMI filter for specific OS
$WMIFilter = "SELECT * FROM Win32_OperatingSystem WHERE Version LIKE '10.%'"
New-GPWmiFilter -Name "Windows 10 Only" -Expression $WMIFilter
```

## Best Practices

### Naming Conventions

- Use descriptive names: "SEC-Password-Policy"
- Include purpose: "APP-Office365-Settings"
- Version control: "USR-Desktop-v2.1"

### GPO Organization

```powershell
# Create OU structure for GPO management
New-ADOrganizationalUnit -Name "Group Policy Objects" -Path "DC=contoso,DC=com"
New-ADOrganizationalUnit -Name "Computer Policies" -Path "OU=Group Policy Objects,DC=contoso,DC=com"
New-ADOrganizationalUnit -Name "User Policies" -Path "OU=Group Policy Objects,DC=contoso,DC=com"
```

### Testing Strategy

1. Create test OUs
2. Apply policies to test groups
3. Use Group Policy Modeling
4. Monitor event logs
5. Gradual rollout

### Documentation

```powershell
# Document GPO settings
Get-GPO -All | ForEach-Object {
    Get-GPOReport -Name $_.DisplayName -ReportType HTML -Path "C:\Documentation\$($_.DisplayName).html"
}
```

## Security Considerations

### GPO Security

```powershell
# Audit GPO permissions
Get-GPO -All | Get-GPPermissions

# Set secure permissions
Set-GPPermissions -Name "Security Policy" -PermissionLevel GpoEditDeleteModifySecurity -TargetName "Domain Admins" -TargetType Group

# Remove default permissions
Set-GPPermissions -Name "Security Policy" -PermissionLevel None -TargetName "Authenticated Users" -TargetType WellKnownGroup
```

### Change Control

```powershell
# Enable GPO version tracking
Set-GPRegistryValue -Name "Audit Policy" -Key "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -ValueName "UserEnvDebugLevel" -Type DWord -Value 0x00020000
```

## Related Topics

- [Active Directory Fundamentals](../activedirectory/fundamentals/index.md)
- [Active Directory Delegation](../activedirectory/procedures/delegation.md)
- [Active Directory Troubleshooting](../activedirectory/operations/troubleshooting-guide.md)
- [PowerShell Administration](../../development/powershell/index.md)
- [Windows Security](../../security/windows/index.md)
