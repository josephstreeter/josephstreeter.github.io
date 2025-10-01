---
title: "Active Directory Reference"
description: "Quick reference materials, command references, event IDs, performance counters, and PowerShell scripts for Active Directory administration."
tags: ["active-directory", "reference", "commands", "event-ids", "performance-counters", "powershell"]
category: "Services"
subcategory: "Active Directory"
difficulty: "All Levels"
last_updated: "2025-09-25"
author: "Documentation Team"
---

## Overview

This section provides quick reference materials for Active Directory administrators, including command references, event ID lookups, performance counters, and reusable PowerShell scripts. These materials are designed for quick lookup during troubleshooting and daily administration tasks.

## What's Available

- **DCDiag and Repadmin Reports**: Understanding diagnostic tool outputs
- **Event ID Reference**: Common Active Directory event IDs and their meanings  
- **Performance Counters**: Key performance indicators for monitoring AD health
- **PowerShell Scripts**: Reusable scripts for common administrative tasks
- **Command Reference**: Quick lookup for common AD administration commands

## Reference Categories

### Diagnostic Tool References

**🔍 [DCDiag and Repadmin Reports](dcdiag-and-repadmin-report.md)**

Comprehensive guide to interpreting diagnostic tool outputs:

- DCDiag test descriptions and common failures
- Repadmin output interpretation
- Common error codes and resolutions
- Best practices for diagnostic tool usage
- Automated report analysis scripts

### Event Log Reference

**📊 Event IDs and Descriptions:**

Complete reference for Active Directory event IDs:

- Critical event IDs and their meanings
- Warning events and recommended actions

*See [DCDiag and Repadmin Reports](dcdiag-and-repadmin-report.md) for diagnostic event information*

- Informational events for monitoring
- Security audit events
- Troubleshooting event log correlation

### Performance Monitoring

**📈 Performance Counters:**

Essential performance counters for Active Directory monitoring:

- Domain controller performance counters
- Database performance indicators
- Replication performance metrics
- Authentication and search performance
- Threshold recommendations and alerting

*See [Monitoring and Alerting](../operations/monitoring-and-alerting.md) for performance monitoring details*

### Script Library

**💻 PowerShell Scripts:**

Collection of tested PowerShell scripts for AD administration:

- Health check and monitoring scripts
- Bulk operation scripts
- Reporting and auditing scripts
- Maintenance automation scripts
- Troubleshooting diagnostic scripts

*See [DCDiag and Repadmin Reports](dcdiag-and-repadmin-report.md) for diagnostic PowerShell scripts*

## Quick Lookup Tables

### Critical Event IDs

| Event ID | Source | Severity | Description |
|----------|--------|----------|-------------|
| 1058 | Microsoft-Windows-ActiveDirectory_DomainService | Error | Knowledge Consistency Checker errors |
| 1311 | Microsoft-Windows-ActiveDirectory_DomainService | Error | Replication errors |
| 1645 | Microsoft-Windows-ActiveDirectory_DomainService | Warning | Database space low |
| 2042 | Microsoft-Windows-ActiveDirectory_DomainService | Error | Replication hasn't occurred for tombstone lifetime |
| 5805 | NETLOGON | Warning | Authentication failures |

### Essential Commands

| Purpose | Command | Example Usage |
|---------|---------|---------------|
| Domain controller health | `dcdiag /v` | `dcdiag /v /c /d /e /s:DC01` |
| Replication status | `repadmin /replsummary` | `repadmin /replsummary /bysrc /bydest` |
| Test secure channel | `nltest /sc_query` | `nltest /sc_query:domain.com` |
| Forest/domain info | `Get-ADForest` | `Get-ADForest \| Select-Object Name,ForestMode` |
| Find FSMO roles | `netdom query fsmo` | `netdom query fsmo` |

### Performance Counter Thresholds

| Counter | Threshold | Action |
|---------|-----------|--------|
| NTDS\DRA Pending Replication Synchronizations | > 10 | Investigate replication issues |
| NTDS\DS Directory Reads/sec | > 1000 | Monitor database performance |
| NTDS\DS Directory Writes/sec | > 100 | Monitor write load |
| PhysicalDisk\Avg. Disk Queue Length | > 2 | Check disk performance |
| Memory\Available MBytes | < 1024 | Add memory to domain controller |

## PowerShell Quick Reference

### Common Active Directory Cmdlets

```powershell
# User Management
Get-ADUser -Filter "Enabled -eq $true"
New-ADUser -Name "John Doe" -SamAccountName "jdoe"
Set-ADUser -Identity "jdoe" -Department "IT"
Disable-ADAccount -Identity "jdoe"

# Group Management
Get-ADGroup -Filter "GroupScope -eq 'Global'"
New-ADGroup -Name "IT-Team" -GroupScope Global
Add-ADGroupMember -Identity "IT-Team" -Members "jdoe"
Get-ADGroupMember -Identity "Domain Admins"

# Computer Management
Get-ADComputer -Filter "OperatingSystem -like '*Server*'"
Test-ComputerSecureChannel -Repair
Reset-ComputerMachinePassword

# Domain and Forest Information
Get-ADDomain | Select-Object Name, DomainMode, PDCEmulator
Get-ADForest | Select-Object Name, ForestMode, SchemaMaster
Get-ADDomainController -Filter *
```

### Health Check Scripts

```powershell
# Quick domain controller health check
function Test-DCHealth
{
    param([string]$DomainController)
    
    $Results = @()
    
    # Test services
    $Services = @('NTDS', 'DNS', 'KDC', 'Netlogon')
    foreach ($Service in $Services)
    {
        $ServiceStatus = Get-Service -Name $Service -ComputerName $DomainController
        $Results += [PSCustomObject]@{
            Test = "Service: $Service"
            Result = $ServiceStatus.Status
            Status = if ($ServiceStatus.Status -eq 'Running') { 'Pass' } else { 'Fail' }
        }
    }
    
    # Test connectivity
    $Ping = Test-NetConnection -ComputerName $DomainController -Port 389
    $Results += [PSCustomObject]@{
        Test = "LDAP Connectivity"
        Result = $Ping.TcpTestSucceeded
        Status = if ($Ping.TcpTestSucceeded) { 'Pass' } else { 'Fail' }
    }
    
    return $Results
}
```

### Bulk Operations

```powershell
# Bulk user creation from CSV
$Users = Import-Csv "C:\Users.csv"
foreach ($User in $Users)
{
    $UserParams = @{
        Name = "$($User.FirstName) $($User.LastName)"
        GivenName = $User.FirstName
        Surname = $User.LastName
        SamAccountName = $User.Username
        UserPrincipalName = "$($User.Username)@contoso.com"
        Path = $User.OU
        Department = $User.Department
        AccountPassword = (ConvertTo-SecureString "TempPass123!" -AsPlainText -Force)
        Enabled = $true
    }
    New-ADUser @UserParams
}

# Bulk group membership update
$GroupMembers = Get-Content "C:\GroupMembers.txt"
Add-ADGroupMember -Identity "IT-Team" -Members $GroupMembers
```

## Troubleshooting Reference

### Common Error Codes

| Error | Description | Resolution |
|-------|-------------|------------|
| 0x80070005 | Access Denied | Check permissions, run as administrator |
| 0x80070002 | File Not Found | Verify file paths, check network connectivity |
| 0x800706BA | RPC Server Unavailable | Check firewall, verify RPC services |
| 0x80072030 | No Such Object | Verify distinguished names, check object existence |
| 0x8007203A | Server Down | Check domain controller availability |

### Replication Error Codes

| Error | Description | Common Causes |
|-------|-------------|---------------|
| 8524 | DSA operation unable to proceed | Network connectivity, DNS issues |
| 8452 | Naming violation | Schema or naming context issues |
| 8446 | Replication access denied | Insufficient permissions |
| 8614 | Directory service shutdown | Service stopped, system restart |
| 1722 | RPC server unavailable | Firewall, network connectivity |

## Integration Examples

### Azure AD Connect Reference

```powershell
# Common Azure AD Connect PowerShell commands
Import-Module ADSync

# Get sync connector information  
Get-ADSyncConnector

# Start sync cycle
Start-ADSyncSyncCycle -PolicyType Initial
Start-ADSyncSyncCycle -PolicyType Delta

# Check sync status
Get-ADSyncScheduler
```

### Exchange Integration

```powershell
# Common Exchange-related AD operations
# Enable mailbox for user
Enable-Mailbox -Identity "jdoe" -Database "Mailbox Database 01"

# Get mail-enabled groups
Get-ADGroup -Filter "mail -like '*'" -Properties mail

# Check Exchange schema version
Get-ADObject "CN=ms-Exch-Schema-Version-Pt,CN=Schema,CN=Configuration,$((Get-ADRootDSE).configurationNamingContext)" -Properties rangeUpper
```

## Related Sections

- **🔧 [Operations](../operations/index.md)**: Detailed operational procedures
- **🛠️ [Procedures](../procedures/index.md)**: Step-by-step administrative procedures
- **📖 [Fundamentals](../fundamentals/index.md)**: Core Active Directory concepts
- **⚙️ [Configuration](../configuration/index.md)**: Configuration and setup guidance

## Additional Resources

### Microsoft Documentation

- [Active Directory PowerShell Module Reference](https://docs.microsoft.com/en-us/powershell/module/addsadministration/)
- [Active Directory Event ID Reference](https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/active-directory-event-ids)
- [Performance Counter Reference](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/component-updates/directory-services-component-updates)

### Community Resources

- [Active Directory Best Practices](https://social.technet.microsoft.com/wiki/contents/articles/52587.active-directory-best-practices.aspx)
- [PowerShell Gallery AD Scripts](https://www.powershellgallery.com/packages?q=ActiveDirectory)
- [TechNet Active Directory Forum](https://social.technet.microsoft.com/Forums/en-US/home?category=activedirectory)

---

*Keep this reference section bookmarked for quick access during troubleshooting and daily administration tasks. Regular updates ensure accuracy and relevance.*
