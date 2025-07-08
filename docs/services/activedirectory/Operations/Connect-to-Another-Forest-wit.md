---
title: "Connect to Another Forest with PowerShell"
description: "Guide for connecting to and managing Active Directory domains in different forests using PowerShell PSDrives and remote connections"
author: "IT Operations"
ms.date: "07/05/2025"
ms.topic: "how-to"
ms.service: "active-directory"
keywords: PowerShell, Active Directory, forest, cross-forest, PSDrive, domain controller, authentication
---

This guide demonstrates how to establish PowerShell connections to Active Directory domains in different forests for cross-forest administration and management tasks.

## Overview

PowerShell automatically creates a PSDrive for the Active Directory domain that the client is a member of. However, administrators often need to manage resources in different domains or forests. This document covers multiple methods to establish these connections securely and efficiently.

## Prerequisites

Before attempting cross-forest connections, ensure:

- **PowerShell 5.1 or later** with Active Directory module installed
- **Network connectivity** to target domain controllers
- **Valid credentials** for the target forest/domain
- **DNS resolution** configured for target domain
- **Firewall rules** allow AD communication (ports 389, 636, 3268, 3269, 88, 53)
- **Trust relationships** (optional but recommended for production environments)

## Security Considerations

- **Use encrypted connections** (LDAPS on port 636) when possible
- **Store credentials securely** - avoid hardcoding passwords
- **Use least privilege accounts** for cross-forest operations
- **Implement credential rotation** policies
- **Log and monitor** cross-forest activities
- **Consider certificate-based authentication** for enhanced security

## Method 1: Creating PSDrives for Cross-Forest Access

### Basic PSDrive Creation

The following command creates a PSDrive for a different domain than the one the host is joined to:

```powershell
New-PSDrive -Name <PSDrive-Name> -PSProvider ActiveDirectory -Server "<Domain-Controller>" -Scope Global -Credential (Get-Credential "<User-Name>") -Root "//RootDSE/"
```

### Parameter Explanation

- **-Name**: Friendly name for the PSDrive (e.g., "TARGETFOREST")
- **-PSProvider**: Must be "ActiveDirectory" for AD connections
- **-Server**: FQDN or IP of target domain controller
- **-Scope Global**: Required when running from scripts to persist the drive
- **-Credential**: Authentication credentials for the target domain
- **-Root**: Starting point in the directory (//RootDSE/ for domain root)

### Example Implementation

Let's say you want to manage objects in a target forest from a host joined to your production domain:

```powershell
# Create a PSDrive for the target forest
New-PSDrive -Name TARGETFOREST -PSProvider ActiveDirectory -Server "dc01.target.domain.com" -Scope Global -Credential (Get-Credential "target\admin-user") -Root "//RootDSE/"
```

The `-Scope Global` switch is required when running this cmdlet from a script to ensure the drive persists across PowerShell scopes.

### Using the PSDrive

Once created, you can use the PSDrive in multiple ways:

#### Option 1: Navigate to the PSDrive

```powershell
# Navigate to the target forest PSDrive
PS C:\> Set-Location TARGETFOREST:

# Run AD commands in the context of the target forest
PS TARGETFOREST:\> Get-ADDomain
PS TARGETFOREST:\> Get-ADUser -Filter * -SearchBase "OU=Users,DC=target,DC=domain,DC=com"
PS TARGETFOREST:\> Get-ADGroup "Domain Admins"
```

#### Option 2: Use the -Server Parameter

Alternatively, specify the server directly with AD cmdlets:

```powershell
# Query the target domain without changing location
PS C:\> Get-ADDomain -Server "dc01.target.domain.com"
PS C:\> Get-ADUser -Filter * -Server "dc01.target.domain.com" -Credential $targetCredential
```

## Method 2: Direct Server Connections

For one-off operations, you can connect directly without creating a PSDrive:

```powershell
# Store credentials securely
$targetCredential = Get-Credential "target\admin-user"

# Connect directly to target domain
Get-ADDomain -Server "dc01.target.domain.com" -Credential $targetCredential
Get-ADUser jsmith -Server "dc01.target.domain.com" -Credential $targetCredential
```

## Best Practices and Error Handling

### Check for Existing PSDrives

Always verify if a PSDrive exists before attempting to create it:

```powershell
# Check if PSDrive already exists
$driveName = "TARGETFOREST"

if (-not (Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue)) {
    try {
        # Create the PSDrive with error handling
        $credential = Get-Credential "target\admin-user"
        New-PSDrive -Name $driveName -PSProvider ActiveDirectory -Server "dc01.target.domain.com" -Scope Global -Credential $credential -Root "//RootDSE/" -ErrorAction Stop
        Write-Host "Successfully created PSDrive: $driveName" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create PSDrive: $($_.Exception.Message)"
        return
    }
}
else {
    Write-Host "PSDrive '$driveName' already exists" -ForegroundColor Yellow
}
```

### Secure Credential Management

```powershell
# Method 1: Use Windows Credential Manager
$credential = Get-StoredCredential -Target "TargetForestAdmin"

# Method 2: Use secure string files (for automation)
$securePassword = Get-Content "C:\Scripts\SecurePassword.txt" | ConvertTo-SecureString
$credential = New-Object System.Management.Automation.PSCredential("target\admin-user", $securePassword)

# Method 3: Certificate-based authentication (most secure)
$certificate = Get-ChildItem Cert:\CurrentUser\My | Where-Object {$_.Subject -like "*admin-user*"}
```

### Connection Validation

```powershell
# Test the connection before performing operations
function Test-CrossForestConnection {
    param(
        [string]$Server,
        [PSCredential]$Credential
    )
    
    try {
        $domain = Get-ADDomain -Server $Server -Credential $Credential -ErrorAction Stop
        Write-Host "Successfully connected to domain: $($domain.DNSRoot)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Connection failed: $($_.Exception.Message)"
        return $false
    }
}

# Usage
if (Test-CrossForestConnection -Server "dc01.target.domain.com" -Credential $credential) {
    # Proceed with operations
    Get-ADUser -Filter * -Server "dc01.target.domain.com" -Credential $credential
}
```

## Advanced Scenarios

### Managing Multiple Forests

```powershell
# Configuration for multiple forests
$forestConfig = @{
    "FOREST-A" = @{
        Server = "dc01.foresta.com"
        Credential = Get-Credential "foresta\admin"
    }
    "FOREST-B" = @{
        Server = "dc01.forestb.com" 
        Credential = Get-Credential "forestb\admin"
    }
}

# Create PSDrives for all forests
foreach ($forestName in $forestConfig.Keys) {
    if (-not (Get-PSDrive -Name $forestName -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name $forestName -PSProvider ActiveDirectory -Server $forestConfig[$forestName].Server -Scope Global -Credential $forestConfig[$forestName].Credential -Root "//RootDSE/"
    }
}
```

### Cross-Forest User Management

```powershell
# Example: Copy user from one forest to another
function Copy-UserAcrossForests {
    param(
        [string]$SourceUser,
        [string]$SourceServer,
        [PSCredential]$SourceCredential,
        [string]$TargetServer,
        [PSCredential]$TargetCredential,
        [string]$TargetOU
    )
    
    try {
        # Get user from source forest
        $sourceUser = Get-ADUser $SourceUser -Properties * -Server $SourceServer -Credential $SourceCredential
        
        # Create user in target forest
        $newUserParams = @{
            Name = $sourceUser.Name
            GivenName = $sourceUser.GivenName
            Surname = $sourceUser.Surname
            SamAccountName = $sourceUser.SamAccountName
            UserPrincipalName = "$($sourceUser.SamAccountName)@target.domain.com"
            Path = $TargetOU
            Server = $TargetServer
            Credential = $TargetCredential
        }
        
        New-ADUser @newUserParams
        Write-Host "Successfully created user in target forest" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to copy user: $($_.Exception.Message)"
    }
}
```

## Troubleshooting

### Common Issues and Solutions

#### Authentication Failures

**Problem**: "Access is denied" or credential errors

**Solutions**:

- Verify credentials are correct and account is not locked
- Check if account has necessary permissions in target domain
- Ensure proper domain name format (domain\username)
- Test with a known working account first

#### Network Connectivity Issues

**Problem**: Cannot connect to domain controller

**Solutions**:

```powershell
# Test network connectivity
Test-NetConnection -ComputerName "dc01.target.domain.com" -Port 389
Test-NetConnection -ComputerName "dc01.target.domain.com" -Port 636

# Test DNS resolution
Resolve-DnsName "dc01.target.domain.com"
nslookup dc01.target.domain.com
```

#### Trust Relationship Problems

**Problem**: Operations fail due to trust issues

**Solutions**:

- Verify forest trust relationships exist
- Check trust direction and authentication scope
- Use explicit credentials for all operations
- Consider using certificate-based authentication

#### Performance Issues

**Problem**: Slow cross-forest operations

**Solutions**:

- Use Global Catalog servers (port 3268) for searches
- Implement connection pooling for multiple operations
- Cache credentials securely to avoid repeated authentication
- Use specific domain controllers geographically close to your location

### Diagnostic Commands

```powershell
# Check current PSDrives
Get-PSDrive -PSProvider ActiveDirectory

# View AD module commands
Get-Command -Module ActiveDirectory

# Test AD web services
Test-ADServiceAccount -Identity "target\service-account"

# View current AD connections
Get-ADDefaultDomainPasswordPolicy
```

## Security Best Practices

1. **Principle of Least Privilege**: Use accounts with minimal necessary permissions
2. **Credential Security**: Never store passwords in plain text
3. **Connection Encryption**: Use LDAPS (port 636) when possible
4. **Audit Logging**: Enable and monitor cross-forest activities
5. **Session Management**: Remove PSDrives when no longer needed
6. **Certificate Authentication**: Implement for high-security environments

### Cleanup

Always clean up connections when finished:

```powershell
# Remove specific PSDrive
Remove-PSDrive -Name "TARGETFOREST" -Force

# Remove all AD PSDrives except default
Get-PSDrive -PSProvider ActiveDirectory | Where-Object {$_.Name -ne "AD"} | Remove-PSDrive -Force
```

## Enterprise Deployment

### Group Policy Integration

For enterprise environments, consider deploying connection scripts via Group Policy:

1. Create PowerShell script with connection logic
2. Deploy via Group Policy Computer/User Scripts
3. Use Group Policy Preferences for credential management
4. Implement error logging and reporting

### Automation Examples

```powershell
# Scheduled task for cross-forest synchronization
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\CrossForestSync.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "2:00 AM"
Register-ScheduledTask -TaskName "CrossForestSync" -Action $action -Trigger $trigger
```

## References

- [Active Directory PowerShell Module Documentation](https://docs.microsoft.com/en-us/powershell/module/activedirectory/)
- [New-PSDrive Cmdlet Reference](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-psdrive)
- [Active Directory Forest Trusts](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/plan/forest-design-models)
- [PowerShell Security Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/security/powershell-security-best-practices)
- [Active Directory Authentication Protocols](https://docs.microsoft.com/en-us/windows-server/security/kerberos/kerberos-authentication-overview)
