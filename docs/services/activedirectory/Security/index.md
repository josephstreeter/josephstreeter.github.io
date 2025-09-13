---
title: Active Directory Security Best Practices
description: Comprehensive guide to securing Active Directory infrastructure including hardening, access controls, monitoring, and threat detection
author: Joseph Streeter
date: 2024-01-15
tags: [active-directory, security, hardening, access-control, privileged-access, powershell]
---

Securing Active Directory is critical for enterprise infrastructure protection. This comprehensive guide covers security hardening, access controls, monitoring, and threat detection strategies for AD environments.

## Security Architecture Overview

### Defense in Depth Strategy

```text
┌─────────────────────────────────────────────────────────────────┐
│                AD Security Layers                               │
├─────────────────────────────────────────────────────────────────┤
│  Layer           │ Components                                   │
│  ├─ Perimeter    │ Firewalls, Network Segmentation             │
│  ├─ Network      │ IPsec, VLANs, Network Access Control        │
│  ├─ Host         │ OS Hardening, AV, HIPS, Patching           │
│  ├─ Application  │ AD Hardening, Service Accounts, GPOs       │
│  ├─ Data         │ Encryption, Access Controls, Auditing      │
│  └─ Physical     │ Data Center Security, Device Controls      │
└─────────────────────────────────────────────────────────────────┘
```

### Core Security Principles

- **Least Privilege**: Grant minimum necessary permissions
- **Zero Trust**: Verify every access request
- **Defense in Depth**: Multiple security layers
- **Continuous Monitoring**: Real-time threat detection
- **Incident Response**: Rapid containment and recovery

## Domain Controller Hardening

### PowerShell Security Hardening Script

```powershell
<#
.SYNOPSIS
    Comprehensive Active Directory domain controller security hardening.
.DESCRIPTION
    Implements security best practices for domain controllers including
    service hardening, registry settings, and security policies.
.EXAMPLE
    .\Harden-DomainController.ps1 -ApplySettings -GenerateReport
.NOTES
    Requires local administrator privileges on domain controllers.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$ApplySettings,
    
    [Parameter()]
    [switch]$GenerateReport,
    
    [Parameter()]
    [string]$ReportPath = "C:\Security\DC-Hardening-Report.html"
)

# Import required modules
Import-Module ActiveDirectory -ErrorAction Stop

function Set-DCSecurityConfiguration
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$WhatIf
    )
    
    $SecuritySettings = @()
    
    # Disable unnecessary services
    $ServicesToDisable = @(
        'Fax',
        'SNMP',
        'TelNet',
        'RemoteRegistry',
        'Messenger',
        'Alerter',
        'ClipSrv',
        'Browser'
    )
    
    foreach ($ServiceName in $ServicesToDisable)
    {
        try
        {
            $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($Service -and $Service.Status -eq 'Running')
            {
                if (!$WhatIf)
                {
                    Stop-Service -Name $ServiceName -Force
                    Set-Service -Name $ServiceName -StartupType Disabled
                }
                
                $SecuritySettings += [PSCustomObject]@{
                    Category = "Service Hardening"
                    Setting = "Disable $ServiceName"
                    Status = if ($WhatIf) { "Would Apply" } else { "Applied" }
                    Impact = "Reduced attack surface"
                }
            }
        }
        catch
        {
            Write-Warning "Failed to process service $ServiceName : $($_.Exception.Message)"
        }
    }
    
    # Configure registry security settings
    $RegistrySettings = @(
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
            Name = "RestrictAnonymous"
            Value = 2
            Type = "DWORD"
            Description = "Restrict anonymous access"
        },
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
            Name = "RestrictAnonymousSAM"
            Value = 1
            Type = "DWORD"
            Description = "Restrict anonymous SAM enumeration"
        },
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
            Name = "DisableDomainCreds"
            Value = 1
            Type = "DWORD"
            Description = "Disable domain credential storage"
        },
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
            Name = "LmCompatibilityLevel"
            Value = 5
            Type = "DWORD"
            Description = "Force NTLMv2 only"
        },
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
            Name = "RequireSignOrSeal"
            Value = 1
            Type = "DWORD"
            Description = "Require SMB signing"
        },
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
            Name = "SealSecureChannel"
            Value = 1
            Type = "DWORD"
            Description = "Seal secure channel"
        },
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
            Name = "SignSecureChannel"
            Value = 1
            Type = "DWORD"
            Description = "Sign secure channel"
        }
    )
    
    foreach ($Setting in $RegistrySettings)
    {
        try
        {
            if (!(Test-Path $Setting.Path))
            {
                if (!$WhatIf)
                {
                    New-Item -Path $Setting.Path -Force | Out-Null
                }
            }
            
            $CurrentValue = Get-ItemProperty -Path $Setting.Path -Name $Setting.Name -ErrorAction SilentlyContinue
            
            if (!$CurrentValue -or $CurrentValue.($Setting.Name) -ne $Setting.Value)
            {
                if (!$WhatIf)
                {
                    Set-ItemProperty -Path $Setting.Path -Name $Setting.Name -Value $Setting.Value -Type $Setting.Type
                }
                
                $SecuritySettings += [PSCustomObject]@{
                    Category = "Registry Security"
                    Setting = "$($Setting.Name) = $($Setting.Value)"
                    Status = if ($WhatIf) { "Would Apply" } else { "Applied" }
                    Impact = $Setting.Description
                }
            }
        }
        catch
        {
            Write-Warning "Failed to apply registry setting $($Setting.Name): $($_.Exception.Message)"
        }
    }
    
    # Configure Windows Firewall for domain controllers
    $FirewallRules = @(
        @{
            DisplayName = "AD-LDAP-In"
            Direction = "Inbound"
            Protocol = "TCP"
            LocalPort = 389
            Action = "Allow"
            Profile = "Domain"
        },
        @{
            DisplayName = "AD-LDAPS-In"
            Direction = "Inbound"
            Protocol = "TCP"
            LocalPort = 636
            Action = "Allow"
            Profile = "Domain"
        },
        @{
            DisplayName = "AD-GlobalCatalog-In"
            Direction = "Inbound"
            Protocol = "TCP"
            LocalPort = 3268
            Action = "Allow"
            Profile = "Domain"
        },
        @{
            DisplayName = "AD-GlobalCatalogSSL-In"
            Direction = "Inbound"
            Protocol = "TCP"
            LocalPort = 3269
            Action = "Allow"
            Profile = "Domain"
        },
        @{
            DisplayName = "AD-Kerberos-In"
            Direction = "Inbound"
            Protocol = "TCP"
            LocalPort = 88
            Action = "Allow"
            Profile = "Domain"
        },
        @{
            DisplayName = "AD-KerberosUDP-In"
            Direction = "Inbound"
            Protocol = "UDP"
            LocalPort = 88
            Action = "Allow"
            Profile = "Domain"
        }
    )
    
    foreach ($Rule in $FirewallRules)
    {
        try
        {
            $ExistingRule = Get-NetFirewallRule -DisplayName $Rule.DisplayName -ErrorAction SilentlyContinue
            
            if (!$ExistingRule)
            {
                if (!$WhatIf)
                {
                    New-NetFirewallRule -DisplayName $Rule.DisplayName -Direction $Rule.Direction -Protocol $Rule.Protocol -LocalPort $Rule.LocalPort -Action $Rule.Action -Profile $Rule.Profile | Out-Null
                }
                
                $SecuritySettings += [PSCustomObject]@{
                    Category = "Firewall Configuration"
                    Setting = "Created rule: $($Rule.DisplayName)"
                    Status = if ($WhatIf) { "Would Apply" } else { "Applied" }
                    Impact = "Controlled network access"
                }
            }
        }
        catch
        {
            Write-Warning "Failed to create firewall rule $($Rule.DisplayName): $($_.Exception.Message)"
        }
    }
    
    return $SecuritySettings
}

function Test-ADSecurityCompliance
{
    [CmdletBinding()]
    param()
    
    $ComplianceResults = @()
    
    # Check for default passwords
    $DefaultPasswords = @('Password123', 'Admin123', 'P@ssw0rd', 'password')
    
    try
    {
        $Users = Get-ADUser -Filter {Enabled -eq $true} -Properties PasswordLastSet, PasswordNeverExpires
        
        foreach ($User in $Users)
        {
            # Check password age
            if ($User.PasswordLastSet -lt (Get-Date).AddDays(-90))
            {
                $ComplianceResults += [PSCustomObject]@{
                    Category = "Password Policy"
                    Issue = "Password older than 90 days"
                    User = $User.SamAccountName
                    Details = "Last changed: $($User.PasswordLastSet)"
                    Severity = "Medium"
                }
            }
            
            # Check for passwords that never expire
            if ($User.PasswordNeverExpires)
            {
                $ComplianceResults += [PSCustomObject]@{
                    Category = "Password Policy"
                    Issue = "Password never expires"
                    User = $User.SamAccountName
                    Details = "Password set to never expire"
                    Severity = "High"
                }
            }
        }
    }
    catch
    {
        Write-Warning "Failed to check password compliance: $($_.Exception.Message)"
    }
    
    # Check for privileged accounts
    try
    {
        $PrivilegedGroups = @(
            'Domain Admins',
            'Enterprise Admins',
            'Schema Admins',
            'Administrators'
        )
        
        foreach ($GroupName in $PrivilegedGroups)
        {
            $Group = Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue
            if ($Group)
            {
                $Members = Get-ADGroupMember -Identity $Group -Recursive
                
                if ($Members.Count -gt 5)
                {
                    $ComplianceResults += [PSCustomObject]@{
                        Category = "Privileged Access"
                        Issue = "Too many privileged users"
                        Group = $GroupName
                        Details = "Group has $($Members.Count) members"
                        Severity = "High"
                    }
                }
                
                foreach ($Member in $Members)
                {
                    if ($Member.objectClass -eq 'user')
                    {
                        $User = Get-ADUser -Identity $Member.SamAccountName -Properties LastLogonDate
                        
                        if ($User.LastLogonDate -lt (Get-Date).AddDays(-30))
                        {
                            $ComplianceResults += [PSCustomObject]@{
                                Category = "Privileged Access"
                                Issue = "Inactive privileged account"
                                User = $User.SamAccountName
                                Group = $GroupName
                                Details = "Last logon: $($User.LastLogonDate)"
                                Severity = "High"
                            }
                        }
                    }
                }
            }
        }
    }
    catch
    {
        Write-Warning "Failed to check privileged accounts: $($_.Exception.Message)"
    }
    
    # Check for service accounts
    try
    {
        $ServiceAccounts = Get-ADUser -Filter {ServicePrincipalName -like "*"} -Properties ServicePrincipalName, PasswordLastSet
        
        foreach ($Account in $ServiceAccounts)
        {
            if ($Account.PasswordLastSet -lt (Get-Date).AddDays(-365))
            {
                $ComplianceResults += [PSCustomObject]@{
                    Category = "Service Accounts"
                    Issue = "Service account password old"
                    User = $Account.SamAccountName
                    Details = "Password last set: $($Account.PasswordLastSet)"
                    Severity = "Medium"
                }
            }
        }
    }
    catch
    {
        Write-Warning "Failed to check service accounts: $($_.Exception.Message)"
    }
    
    return $ComplianceResults
}

function New-SecurityAuditReport
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$SecuritySettings,
        
        [Parameter(Mandatory)]
        [array]$ComplianceResults,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    $ReportHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Active Directory Security Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #2E86AB; color: white; padding: 15px; text-align: center; }
        .section { margin: 20px 0; }
        .summary { background-color: #f8f9fa; padding: 15px; border-left: 4px solid #2E86AB; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .high { background-color: #ffebee; }
        .medium { background-color: #fff3e0; }
        .low { background-color: #e8f5e8; }
        .applied { color: green; }
        .pending { color: orange; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Active Directory Security Audit Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Domain Controller: $env:COMPUTERNAME</p>
    </div>
    
    <div class="section">
        <h2>Executive Summary</h2>
        <div class="summary">
            <ul>
                <li>Security Settings Applied: $($SecuritySettings.Count)</li>
                <li>Compliance Issues Found: $($ComplianceResults.Count)</li>
                <li>High Severity Issues: $(($ComplianceResults | Where-Object Severity -eq 'High').Count)</li>
                <li>Medium Severity Issues: $(($ComplianceResults | Where-Object Severity -eq 'Medium').Count)</li>
            </ul>
        </div>
    </div>
    
    <div class="section">
        <h2>Security Hardening Applied</h2>
        <table>
            <tr>
                <th>Category</th>
                <th>Setting</th>
                <th>Status</th>
                <th>Impact</th>
            </tr>
"@
    
    foreach ($Setting in $SecuritySettings)
    {
        $StatusClass = if ($Setting.Status -eq "Applied") { "applied" } else { "pending" }
        
        $ReportHTML += @"
            <tr>
                <td>$($Setting.Category)</td>
                <td>$($Setting.Setting)</td>
                <td class="$StatusClass">$($Setting.Status)</td>
                <td>$($Setting.Impact)</td>
            </tr>
"@
    }
    
    $ReportHTML += @"
        </table>
    </div>
    
    <div class="section">
        <h2>Compliance Issues</h2>
        <table>
            <tr>
                <th>Category</th>
                <th>Issue</th>
                <th>Details</th>
                <th>Severity</th>
            </tr>
"@
    
    foreach ($Issue in $ComplianceResults)
    {
        $SeverityClass = switch ($Issue.Severity)
        {
            "High" { "high" }
            "Medium" { "medium" }
            "Low" { "low" }
        }
        
        $ReportHTML += @"
            <tr class="$SeverityClass">
                <td>$($Issue.Category)</td>
                <td>$($Issue.Issue)</td>
                <td>$($Issue.Details)</td>
                <td>$($Issue.Severity)</td>
            </tr>
"@
    }
    
    $ReportHTML += @"
        </table>
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
            <li>Review and remediate all high-severity issues immediately</li>
            <li>Implement regular password rotation for service accounts</li>
            <li>Monitor privileged group membership changes</li>
            <li>Enable advanced audit policies for sensitive operations</li>
            <li>Implement multi-factor authentication for privileged accounts</li>
        </ul>
    </div>
    
    <p><em>Generated by AD Security Audit Tool</em></p>
</body>
</html>
"@
    
    $ReportHTML | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Security audit report saved to: $OutputPath" -ForegroundColor Green
}

# Main execution
if ($ApplySettings)
{
    Write-Host "Applying domain controller security hardening..." -ForegroundColor Green
    $SecuritySettings = Set-DCSecurityConfiguration
}
else
{
    Write-Host "Running security assessment (WhatIf mode)..." -ForegroundColor Yellow
    $SecuritySettings = Set-DCSecurityConfiguration -WhatIf
}

Write-Host "Running compliance checks..." -ForegroundColor Green
$ComplianceResults = Test-ADSecurityCompliance

if ($GenerateReport)
{
    $ReportDir = Split-Path $ReportPath -Parent
    if (!(Test-Path $ReportDir))
    {
        New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
    }
    
    New-SecurityAuditReport -SecuritySettings $SecuritySettings -ComplianceResults $ComplianceResults -OutputPath $ReportPath
}

# Display summary
Write-Host "`n=== Security Audit Summary ===" -ForegroundColor Cyan
Write-Host "Security settings processed: $($SecuritySettings.Count)" -ForegroundColor Green
Write-Host "Compliance issues found: $($ComplianceResults.Count)" -ForegroundColor $(if ($ComplianceResults.Count -gt 0) { "Yellow" } else { "Green" })

if ($ComplianceResults.Count -gt 0)
{
    Write-Host "`nTop Issues:" -ForegroundColor Yellow
    $ComplianceResults | Where-Object Severity -eq "High" | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.Issue): $($_.Details)" -ForegroundColor Red
    }
}
```

## Privileged Access Management (PAM)

### Just-In-Time (JIT) Administration

```powershell
<#
.SYNOPSIS
    Implements Just-In-Time privileged access management for Active Directory.
.DESCRIPTION
    Provides temporary elevation of user privileges with automated revocation
    and comprehensive auditing of privileged operations.
#>

function Request-PrivilegedAccess
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,
        
        [Parameter(Mandatory)]
        [string]$PrivilegedGroup,
        
        [Parameter(Mandatory)]
        [string]$Justification,
        
        [Parameter()]
        [int]$DurationMinutes = 120,
        
        [Parameter()]
        [string]$ApproverEmail = "security@company.com"
    )
    
    # Validate user and group
    try
    {
        $User = Get-ADUser -Identity $UserName -ErrorAction Stop
        $Group = Get-ADGroup -Identity $PrivilegedGroup -ErrorAction Stop
    }
    catch
    {
        Write-Error "Invalid user or group specified: $($_.Exception.Message)"
        return
    }
    
    # Create access request
    $RequestID = [Guid]::NewGuid().ToString()
    $Request = [PSCustomObject]@{
        RequestID = $RequestID
        UserName = $UserName
        UserDN = $User.DistinguishedName
        PrivilegedGroup = $PrivilegedGroup
        GroupDN = $Group.DistinguishedName
        Justification = $Justification
        RequestTime = Get-Date
        ExpirationTime = (Get-Date).AddMinutes($DurationMinutes)
        Status = "Pending"
        ApprovalRequired = $true
    }
    
    # Store request in database or file
    $RequestPath = "C:\PAM\Requests\$RequestID.json"
    $RequestDir = Split-Path $RequestPath -Parent
    if (!(Test-Path $RequestDir))
    {
        New-Item -ItemType Directory -Path $RequestDir -Force | Out-Null
    }
    
    $Request | ConvertTo-Json | Out-File -FilePath $RequestPath -Encoding UTF8
    
    # Send approval request
    $EmailBody = @"
A privileged access request has been submitted:

Request ID: $RequestID
User: $UserName
Group: $PrivilegedGroup
Justification: $Justification
Duration: $DurationMinutes minutes
Requested: $(Get-Date)

To approve this request, run:
Approve-PrivilegedAccess -RequestID $RequestID

To deny this request, run:
Deny-PrivilegedAccess -RequestID $RequestID
"@
    
    Send-MailMessage -From "pam@company.com" -To $ApproverEmail -Subject "PAM: Privileged Access Request - $UserName" -Body $EmailBody -SmtpServer "smtp.company.com"
    
    Write-Host "Privileged access request submitted. Request ID: $RequestID" -ForegroundColor Green
    return $RequestID
}

function Approve-PrivilegedAccess
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RequestID,
        
        [Parameter()]
        [string]$ApproverName = $env:USERNAME
    )
    
    $RequestPath = "C:\PAM\Requests\$RequestID.json"
    
    if (!(Test-Path $RequestPath))
    {
        Write-Error "Request ID $RequestID not found"
        return
    }
    
    try
    {
        $Request = Get-Content $RequestPath | ConvertFrom-Json
        
        if ($Request.Status -ne "Pending")
        {
            Write-Error "Request $RequestID is not in pending status (Current: $($Request.Status))"
            return
        }
        
        # Add user to privileged group
        Add-ADGroupMember -Identity $Request.PrivilegedGroup -Members $Request.UserName
        
        # Update request status
        $Request.Status = "Approved"
        $Request.ApproverName = $ApproverName
        $Request.ApprovalTime = Get-Date
        $Request | ConvertTo-Json | Out-File -FilePath $RequestPath -Encoding UTF8
        
        # Schedule automatic removal
        $TaskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command `"Remove-ADGroupMember -Identity '$($Request.PrivilegedGroup)' -Members '$($Request.UserName)' -Confirm:`$false`""
        $TaskTrigger = New-ScheduledTaskTrigger -Once -At $Request.ExpirationTime
        $TaskName = "PAM-Revoke-$RequestID"
        
        Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Description "Auto-revoke privileged access for $($Request.UserName)"
        
        # Log approval
        Write-EventLog -LogName Application -Source "PAM" -EventId 2001 -EntryType Information -Message "Privileged access approved for user $($Request.UserName) to group $($Request.PrivilegedGroup) by $ApproverName"
        
        Write-Host "Privileged access approved for $($Request.UserName). Access will expire at $($Request.ExpirationTime)" -ForegroundColor Green
        
        # Notify user
        $User = Get-ADUser -Identity $Request.UserName -Properties EmailAddress
        if ($User.EmailAddress)
        {
            $NotificationBody = @"
Your privileged access request has been approved.

Request ID: $RequestID
Group: $($Request.PrivilegedGroup)
Expires: $($Request.ExpirationTime)
Approved by: $ApproverName

Your access will be automatically revoked at the expiration time.
"@
            Send-MailMessage -From "pam@company.com" -To $User.EmailAddress -Subject "PAM: Access Approved - $($Request.PrivilegedGroup)" -Body $NotificationBody -SmtpServer "smtp.company.com"
        }
    }
    catch
    {
        Write-Error "Failed to approve privileged access: $($_.Exception.Message)"
    }
}

function Revoke-PrivilegedAccess
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RequestID,
        
        [Parameter()]
        [string]$Reason = "Manual revocation"
    )
    
    $RequestPath = "C:\PAM\Requests\$RequestID.json"
    
    if (!(Test-Path $RequestPath))
    {
        Write-Error "Request ID $RequestID not found"
        return
    }
    
    try
    {
        $Request = Get-Content $RequestPath | ConvertFrom-Json
        
        # Remove user from privileged group
        Remove-ADGroupMember -Identity $Request.PrivilegedGroup -Members $Request.UserName -Confirm:$false
        
        # Update request status
        $Request.Status = "Revoked"
        $Request.RevocationTime = Get-Date
        $Request.RevocationReason = $Reason
        $Request | ConvertTo-Json | Out-File -FilePath $RequestPath -Encoding UTF8
        
        # Remove scheduled task
        $TaskName = "PAM-Revoke-$RequestID"
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        
        # Log revocation
        Write-EventLog -LogName Application -Source "PAM" -EventId 2002 -EntryType Information -Message "Privileged access revoked for user $($Request.UserName) from group $($Request.PrivilegedGroup). Reason: $Reason"
        
        Write-Host "Privileged access revoked for $($Request.UserName)" -ForegroundColor Yellow
    }
    catch
    {
        Write-Error "Failed to revoke privileged access: $($_.Exception.Message)"
    }
}
```

## Advanced Threat Detection

### Suspicious Activity Monitoring

```powershell
function Start-ADThreatDetection
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MonitoringIntervalMinutes = 5,
        
        [Parameter()]
        [string]$AlertEmail = "security@company.com"
    )
    
    # Define threat detection rules
    $ThreatRules = @{
        "Unusual Logon Patterns" = @{
            EventID = 4624
            Logic = {
                param($Events)
                # Detect logons outside business hours
                $SuspiciousLogons = $Events | Where-Object {
                    $LogonTime = $_.TimeCreated
                    $Hour = $LogonTime.Hour
                    ($Hour -lt 6 -or $Hour -gt 22) -and $LogonTime.DayOfWeek -in @('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
                }
                return $SuspiciousLogons
            }
            Severity = "Medium"
        }
        
        "Multiple Failed Logons" = @{
            EventID = 4625
            Logic = {
                param($Events)
                # Group by account and detect accounts with > 10 failed logons
                $FailedLogons = $Events | Group-Object {$_.Properties[5].Value} | Where-Object Count -gt 10
                return $FailedLogons
            }
            Severity = "High"
        }
        
        "Privileged Group Changes" = @{
            EventID = @(4728, 4732, 4756)
            Logic = {
                param($Events)
                # Detect changes to privileged groups
                $PrivilegedGroups = @('Domain Admins', 'Enterprise Admins', 'Schema Admins')
                $SuspiciousChanges = $Events | Where-Object {
                    $GroupName = $_.Properties[2].Value
                    $GroupName -in $PrivilegedGroups
                }
                return $SuspiciousChanges
            }
            Severity = "Critical"
        }
        
        "Service Account Abuse" = @{
            EventID = 4648
            Logic = {
                param($Events)
                # Detect explicit credential use by service accounts
                $ServiceAccounts = Get-ADUser -Filter {ServicePrincipalName -like "*"} | Select-Object -ExpandProperty SamAccountName
                $SuspiciousActivity = $Events | Where-Object {
                    $AccountName = $_.Properties[1].Value
                    $AccountName -in $ServiceAccounts
                }
                return $SuspiciousActivity
            }
            Severity = "High"
        }
    }
    
    while ($true)
    {
        $StartTime = (Get-Date).AddMinutes(-$MonitoringIntervalMinutes)
        $Alerts = @()
        
        foreach ($RuleName in $ThreatRules.Keys)
        {
            $Rule = $ThreatRules[$RuleName]
            
            try
            {
                # Get events based on rule
                $FilterHashtable = @{
                    LogName = 'Security'
                    StartTime = $StartTime
                }
                
                if ($Rule.EventID -is [array])
                {
                    $FilterHashtable.ID = $Rule.EventID
                }
                else
                {
                    $FilterHashtable.ID = $Rule.EventID
                }
                
                $Events = Get-WinEvent -FilterHashtable $FilterHashtable -ErrorAction SilentlyContinue
                
                if ($Events.Count -gt 0)
                {
                    # Apply rule logic
                    $SuspiciousEvents = & $Rule.Logic $Events
                    
                    if ($SuspiciousEvents)
                    {
                        $Alerts += [PSCustomObject]@{
                            RuleName = $RuleName
                            Severity = $Rule.Severity
                            EventCount = if ($SuspiciousEvents -is [array]) { $SuspiciousEvents.Count } else { 1 }
                            Events = $SuspiciousEvents
                            DetectionTime = Get-Date
                        }
                    }
                }
            }
            catch
            {
                Write-Warning "Error processing rule $RuleName : $($_.Exception.Message)"
            }
        }
        
        # Process alerts
        if ($Alerts.Count -gt 0)
        {
            $AlertHTML = @"
<html>
<head>
    <title>Active Directory Threat Detection Alert</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .critical { background-color: #ffebee; border-left: 4px solid #f44336; }
        .high { background-color: #fff3e0; border-left: 4px solid #ff9800; }
        .medium { background-color: #e3f2fd; border-left: 4px solid #2196f3; }
        .alert { margin: 15px 0; padding: 15px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Active Directory Threat Detection Alert</h1>
    <p>Detection Time: $(Get-Date)</p>
    <p>Total Alerts: $($Alerts.Count)</p>
"@
            
            foreach ($Alert in $Alerts)
            {
                $SeverityClass = $Alert.Severity.ToLower()
                
                $AlertHTML += @"
    <div class="alert $SeverityClass">
        <h3>$($Alert.RuleName) - $($Alert.Severity)</h3>
        <p>Event Count: $($Alert.EventCount)</p>
        <p>Detection Time: $($Alert.DetectionTime)</p>
    </div>
"@
            }
            
            $AlertHTML += "</body></html>"
            
            # Send alert email
            Send-MailMessage -From "ad-security@company.com" -To $AlertEmail -Subject "AD Threat Detection: $($Alerts.Count) Alerts" -Body $AlertHTML -BodyAsHtml -SmtpServer "smtp.company.com"
            
            Write-Host "Threat detection alerts sent: $($Alerts.Count) alerts" -ForegroundColor Red
        }
        
        Start-Sleep -Seconds ($MonitoringIntervalMinutes * 60)
    }
}
```

## Security Auditing and Compliance

### Advanced Audit Policy Configuration

```powershell
function Set-ADAdvancedAuditPolicy
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$ApplySettings
    )
    
    # Define advanced audit policies
    $AuditPolicies = @(
        @{
            Category = "Account Logon"
            Subcategory = "Credential Validation"
            Setting = "Success,Failure"
            Reason = "Monitor authentication attempts"
        },
        @{
            Category = "Account Management"
            Subcategory = "User Account Management"
            Setting = "Success,Failure"
            Reason = "Track user account changes"
        },
        @{
            Category = "Account Management"
            Subcategory = "Security Group Management"
            Setting = "Success,Failure"
            Reason = "Monitor group membership changes"
        },
        @{
            Category = "DS Access"
            Subcategory = "Directory Service Access"
            Setting = "Success,Failure"
            Reason = "Monitor AD object access"
        },
        @{
            Category = "DS Access"
            Subcategory = "Directory Service Changes"
            Setting = "Success,Failure"
            Reason = "Track AD modifications"
        },
        @{
            Category = "Logon/Logoff"
            Subcategory = "Logon"
            Setting = "Success,Failure"
            Reason = "Monitor interactive logons"
        },
        @{
            Category = "Privilege Use"
            Subcategory = "Sensitive Privilege Use"
            Setting = "Success,Failure"
            Reason = "Track privilege elevation"
        },
        @{
            Category = "System"
            Subcategory = "Security System Extension"
            Setting = "Success,Failure"
            Reason = "Monitor security subsystem changes"
        }
    )
    
    $Results = @()
    
    foreach ($Policy in $AuditPolicies)
    {
        try
        {
            if ($ApplySettings)
            {
                # Apply audit policy using auditpol.exe
                $Command = "auditpol.exe /set /subcategory:`"$($Policy.Subcategory)`" /success:enable /failure:enable"
                Invoke-Expression $Command | Out-Null
                
                $Results += [PSCustomObject]@{
                    Category = $Policy.Category
                    Subcategory = $Policy.Subcategory
                    Setting = $Policy.Setting
                    Status = "Applied"
                    Reason = $Policy.Reason
                }
            }
            else
            {
                # Check current setting
                $CurrentSetting = auditpol.exe /get /subcategory:"$($Policy.Subcategory)" /r | ConvertFrom-Csv | Select-Object -ExpandProperty "Inclusion Setting"
                
                $Results += [PSCustomObject]@{
                    Category = $Policy.Category
                    Subcategory = $Policy.Subcategory
                    CurrentSetting = $CurrentSetting
                    RecommendedSetting = $Policy.Setting
                    Compliant = ($CurrentSetting -eq $Policy.Setting)
                    Reason = $Policy.Reason
                }
            }
        }
        catch
        {
            Write-Warning "Failed to process audit policy $($Policy.Subcategory): $($_.Exception.Message)"
        }
    }
    
    return $Results
}
```

## Related Topics

- [Active Directory Monitoring](../ad-monitoring/index.md)
- [Group Policy Management](../GroupPolicy/index.md)
- [Privileged Access Management](../PrivilegedAccess/index.md)
- [Infrastructure Security](../../../infrastructure/security/index.md)
- [Windows Security](../../../infrastructure/windows/security/index.md)
