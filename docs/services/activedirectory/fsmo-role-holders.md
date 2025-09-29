---
title: "FSMO Roles - Planning, Management, and Best Practices"
description: "Comprehensive guide for planning, managing, and maintaining Flexible Single Master Operations (FSMO) roles in Active Directory environments"
author: "Enterprise IT Documentation"
ms.author: "itdocs"
ms.date: "2024-01-15"
ms.topic: "conceptual"
ms.service: "active-directory"
keywords: ["FSMO", "Active Directory", "Domain Controllers", "Schema Master", "PDC Emulator", "RID Master", "Infrastructure Master", "Domain Naming Master"]
---

## FSMO Roles - Planning, Management, and Best Practices

Flexible Single Master Operations (FSMO) roles are critical components of Active Directory that ensure consistency and prevent conflicts in a multi-master environment. Understanding and properly managing these roles is essential for a healthy Active Directory infrastructure.

## Overview of FSMO Roles

Active Directory uses five specialized FSMO roles to handle operations that cannot tolerate conflicts in a multi-master replication environment:

### Forest-Wide Roles (One per Forest)

1. **Schema Master**: Controls all updates and modifications to the Active Directory schema
2. **Domain Naming Master**: Controls the addition and removal of domains in the forest

### Domain-Wide Roles (One per Domain)

1. **PDC Emulator**: Provides backward compatibility and serves as the primary time source
2. **RID Master**: Allocates relative identifier (RID) pools to domain controllers
3. **Infrastructure Master**: Maintains cross-domain object references

## Prerequisites and Planning

### Planning Considerations

Before deploying FSMO roles, consider the following factors:

- **Network topology and site design**
- **Domain controller placement and hardware specifications**
- **Disaster recovery and business continuity requirements**
- **Administrative boundaries and delegation needs**
- **Performance and availability requirements**

### Hardware and Performance Requirements

| Role | CPU | Memory | Network | Storage | Availability |
|------|-----|---------|---------|---------|--------------|
| Schema Master | 2+ cores | 4GB+ | Standard | Standard | Medium |
| Domain Naming Master | 2+ cores | 4GB+ | Standard | Standard | Medium |
| PDC Emulator | 4+ cores | 8GB+ | High bandwidth | Fast storage | High |
| RID Master | 2+ cores | 4GB+ | Standard | Standard | High |
| Infrastructure Master | 2+ cores | 4GB+ | Standard | Standard | Medium |

## FSMO Role Placement Best Practices

### Single Domain Forest

In a single domain forest, FSMO role placement is straightforward:

```text
┌─────────────────────────────────────────┐
│            Single Domain Forest         │
├─────────────────────────────────────────┤
│ Primary DC (Site 1):                    │
│ • Schema Master                         │
│ • Domain Naming Master                  │
│ • PDC Emulator                          │
│ • RID Master                            │
│ • Infrastructure Master                 │
│ • Global Catalog: Yes                   │
├─────────────────────────────────────────┤
│ Secondary DC (Site 1):                  │
│ • Global Catalog: Yes                   │
├─────────────────────────────────────────┤
│ Remote Site DC:                         │
│ • Global Catalog: Yes (recommended)     │
└─────────────────────────────────────────┘
```

### Multi-Domain Forest

In multi-domain environments, strategic placement is critical:

```text
┌─────────────────────────────────────────┐
│          Forest Root Domain             │
├─────────────────────────────────────────┤
│ Forest Root DC 1:                       │
│ • Schema Master                         │
│ • Domain Naming Master                  │
│ • PDC Emulator (Root Domain)            │
│ • RID Master (Root Domain)              │
│ • Global Catalog: Yes                   │
├─────────────────────────────────────────┤
│ Forest Root DC 2:                       │
│ • Infrastructure Master (Root Domain)   │
│ • Global Catalog: No                    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│            Child Domain                 │
├─────────────────────────────────────────┤
│ Child Domain DC 1:                      │
│ • PDC Emulator (Child Domain)           │
│ • RID Master (Child Domain)             │
│ • Global Catalog: Yes                   │
├─────────────────────────────────────────┤
│ Child Domain DC 2:                      │
│ • Infrastructure Master (Child Domain)  │
│ • Global Catalog: No                    │
└─────────────────────────────────────────┘
```

### Infrastructure Master and Global Catalog Placement

> [!IMPORTANT]
> **Critical Rule**: In multi-domain environments, the Infrastructure Master should NOT be placed on a Global Catalog server unless ALL domain controllers in the domain are Global Catalogs.

**Why this matters**:

- Infrastructure Master updates cross-domain object references
- Global Catalog servers cache objects from other domains
- If Infrastructure Master is on a GC, it won't detect phantoms (outdated references)
- This can lead to stale cross-domain references

## FSMO Role Management

### Viewing Current FSMO Role Holders

Use PowerShell to identify current FSMO role holders:

```powershell
<#
.SYNOPSIS
    Retrieves and displays all FSMO role holders in the forest.
.DESCRIPTION
    This function displays forest-wide and domain-specific FSMO role holders
    with color-coded output for easy identification.
.EXAMPLE
    Get-FSMORoles
    Displays all FSMO role holders in the current forest.
#>
function Get-FSMORoles
{
    Write-Host "Forest-wide FSMO Roles:" -ForegroundColor Green
    $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    Write-Host "Schema Master: $($Forest.SchemaRoleOwner)" -ForegroundColor Yellow
    Write-Host "Domain Naming Master: $($Forest.NamingRoleOwner)" -ForegroundColor Yellow
    
    Write-Host "`nDomain-specific FSMO Roles:" -ForegroundColor Green
    foreach ($Domain in $Forest.Domains)
    {
        Write-Host "Domain: $($Domain.Name)" -ForegroundColor Cyan
        Write-Host "  PDC Emulator: $($Domain.PdcRoleOwner)" -ForegroundColor Yellow
        Write-Host "  RID Master: $($Domain.RidRoleOwner)" -ForegroundColor Yellow
        Write-Host "  Infrastructure Master: $($Domain.InfrastructureRoleOwner)" -ForegroundColor Yellow
    }
}

# Execute the function
Get-FSMORoles
```

**Alternative methods**:

```powershell
# Using netdom (legacy but still useful)
netdom query fsmo

# Using dcdiag for health check
dcdiag /test:fsmocheck

# Using Active Directory module
Get-ADForest | Select-Object DomainNamingMaster, SchemaMaster
Get-ADDomain | Select-Object PDCEmulator, RIDMaster, InfrastructureMaster
```

### Transferring FSMO Roles (Graceful)

**Transfer roles when the current holder is online and healthy:**

```powershell
<#
.SYNOPSIS
    Transfers FSMO roles to a target domain controller.
.DESCRIPTION
    This function gracefully transfers specified FSMO roles to a target domain controller
    when the current role holder is online and healthy.
.PARAMETER TargetDC
    The fully qualified domain name of the target domain controller.
.PARAMETER Roles
    Array of FSMO roles to transfer. Valid values: SchemaRole, NamingRole, PDCRole, RIDRole, InfrastructureRole.
.EXAMPLE
    Transfer-FSMORoles -TargetDC "DC02.contoso.com" -Roles @("PDCRole", "RIDRole")
    Transfers PDC Emulator and RID Master roles to DC02.
#>
function Transfer-FSMORoles
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetDC,
        [string[]]$Roles
    )
    
    # Available roles: SchemaRole, NamingRole, PDCRole, RIDRole, InfrastructureRole
    foreach ($Role in $Roles)
    {
        try
        {
            Move-ADDirectoryServerOperationMasterRole -Identity $TargetDC -OperationMasterRole $Role -Force
            Write-Host "Successfully transferred $Role to $TargetDC" -ForegroundColor Green
        }
        catch
        {
            Write-Error "Failed to transfer $Role to $TargetDC`: $($_.Exception.Message)"
        }
    }
}

# Example: Transfer PDC Emulator and RID Master to DC02
Transfer-FSMORoles -TargetDC "DC02.contoso.com" -Roles @("PDCRole", "RIDRole")
```

**Transfer using GUI tools**:

```powershell
# Open FSMO management tools
# For Schema Master
regsvr32 schmmgmt.dll
mmc  # Add Schema snap-in

# For Domain Naming Master
dsa.msc  # Active Directory Domains and Trusts

# For PDC, RID, and Infrastructure
dsa.msc  # Active Directory Users and Computers
```

### Seizing FSMO Roles (Forced)

**Only use when the current role holder is permanently offline:**

> [!WARNING]
> Role seizure should only be performed when the current role holder is permanently offline and will never return to the network. Improper seizure can cause replication conflicts.

```powershell
<#
.SYNOPSIS
    Forcibly seizes FSMO roles when the current holder is permanently offline.
.DESCRIPTION
    This function seizes FSMO roles using ntdsutil when graceful transfer is not possible.
    Should only be used when the current role holder is permanently offline.
.PARAMETER TargetDC
    The fully qualified domain name of the target domain controller to seize roles to.
.PARAMETER Roles
    Array of FSMO roles to seize.
.EXAMPLE
    Seize-FSMORoles -TargetDC "DC02.contoso.com" -Roles @("pdc", "rid master")
    Seizes PDC and RID Master roles to DC02.
.NOTES
    WARNING: Only use when the current role holder will never return to the network.
#>
function Seize-FSMORoles
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetDC,
        [string[]]$Roles
    )
    
    Write-Warning "CAUTION: Only seize roles if the current holder is permanently offline!"
    $Confirmation = Read-Host "Type 'CONFIRM' to proceed with role seizure"
    
    if ($Confirmation -eq "CONFIRM")
    {
        foreach ($Role in $Roles)
        {
            $NtdsutilCmd = @"
ntdsutil
roles
connections
connect to server $TargetDC
quit
seize $Role
quit
quit
"@
            Write-Host "Seizing $Role on $TargetDC..." -ForegroundColor Yellow
            $NtdsutilCmd | cmd
        }
    }
    else
    {
        Write-Host "Operation cancelled" -ForegroundColor Red
    }
}

# Manual ntdsutil commands for reference:
<#
ntdsutil
roles
connections
connect to server TargetServerName
quit
seize schema master
seize naming master
seize pdc
seize rid master
seize infrastructure master
quit
quit
#>
```

## Monitoring and Maintenance

### FSMO Role Health Monitoring

```powershell
<#
.SYNOPSIS
    Performs comprehensive FSMO role health check.
.DESCRIPTION
    This function tests the availability and health of all FSMO role holders
    in the forest and returns a detailed status report.
.EXAMPLE
    Test-FSMOHealth
    Returns health status of all FSMO role holders.
.NOTES
    Exports results to CSV file in C:\Reports directory.
#>
function Test-FSMOHealth
{
    $Report = @()
    $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    
    # Test Schema Master
    try
    {
        $SchemaMaster = $Forest.SchemaRoleOwner
        $SchemaTest = Test-NetConnection -ComputerName $SchemaMaster.Name -Port 389 -WarningAction SilentlyContinue
        $Report += [PSCustomObject]@{
            Role = "Schema Master"
            Server = $SchemaMaster.Name
            Status = if ($SchemaTest.TcpTestSucceeded) { "Online" } else { "Offline" }
            LastCheck = Get-Date
        }
    }
    catch
    {
        $Report += [PSCustomObject]@{
            Role = "Schema Master"
            Server = "Unknown"
            Status = "Error"
            LastCheck = Get-Date
        }
    }
    
    # Test Domain Naming Master
    try
    {
        $NamingMaster = $Forest.NamingRoleOwner
        $NamingTest = Test-NetConnection -ComputerName $NamingMaster.Name -Port 389 -WarningAction SilentlyContinue
        $Report += [PSCustomObject]@{
            Role = "Domain Naming Master"
            Server = $NamingMaster.Name
            Status = if ($NamingTest.TcpTestSucceeded) { "Online" } else { "Offline" }
            LastCheck = Get-Date
        }
    }
    catch
    {
        $Report += [PSCustomObject]@{
            Role = "Domain Naming Master"
            Server = "Unknown"
            Status = "Error"
            LastCheck = Get-Date
        }
    }
    
    # Test domain-specific roles
    foreach ($Domain in $Forest.Domains)
    {
        # PDC Emulator
        try
        {
            $PdcTest = Test-NetConnection -ComputerName $Domain.PdcRoleOwner.Name -Port 389 -WarningAction SilentlyContinue
            $Report += [PSCustomObject]@{
                Role = "PDC Emulator ($($Domain.Name))"
                Server = $Domain.PdcRoleOwner.Name
                Status = if ($PdcTest.TcpTestSucceeded) { "Online" } else { "Offline" }
                LastCheck = Get-Date
            }
        }
        catch
        {
            $Report += [PSCustomObject]@{
                Role = "PDC Emulator ($($Domain.Name))"
                Server = "Unknown"
                Status = "Error"
                LastCheck = Get-Date
            }
        }
        
        # RID Master
        try
        {
            $RidTest = Test-NetConnection -ComputerName $Domain.RidRoleOwner.Name -Port 389 -WarningAction SilentlyContinue
            $Report += [PSCustomObject]@{
                Role = "RID Master ($($Domain.Name))"
                Server = $Domain.RidRoleOwner.Name
                Status = if ($RidTest.TcpTestSucceeded) { "Online" } else { "Offline" }
                LastCheck = Get-Date
            }
        }
        catch
        {
            $Report += [PSCustomObject]@{
                Role = "RID Master ($($Domain.Name))"
                Server = "Unknown"
                Status = "Error"
                LastCheck = Get-Date
            }
        }
        
        # Infrastructure Master
        try
        {
            $InfraTest = Test-NetConnection -ComputerName $Domain.InfrastructureRoleOwner.Name -Port 389 -WarningAction SilentlyContinue
            $Report += [PSCustomObject]@{
                Role = "Infrastructure Master ($($Domain.Name))"
                Server = $Domain.InfrastructureRoleOwner.Name
                Status = if ($InfraTest.TcpTestSucceeded) { "Online" } else { "Offline" }
                LastCheck = Get-Date
            }
        }
        catch
        {
            $Report += [PSCustomObject]@{
                Role = "Infrastructure Master ($($Domain.Name))"
                Server = "Unknown"
                Status = "Error"
                LastCheck = Get-Date
            }
        }
    }
    
    return $Report
}

# Run health check and export results
$HealthReport = Test-FSMOHealth
$HealthReport | Format-Table -AutoSize
$HealthReport | Export-Csv -Path "C:\Reports\FSMO-Health-$(Get-Date -Format 'yyyyMMdd-HHmm').csv" -NoTypeInformation
```

### Automated Monitoring with Scheduled Tasks

```powershell
# Create scheduled task for FSMO monitoring
$taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Test-FSMOHealth.ps1"
$taskTrigger = New-ScheduledTaskTrigger -Daily -At "6:00 AM"
$taskSettings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -StartWhenAvailable
$taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "FSMO Health Check" -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Principal $taskPrincipal -Description "Daily FSMO role health monitoring"
```

## Disaster Recovery Planning

### FSMO Role Recovery Procedures

**Priority Order for Role Recovery**:

1. **PDC Emulator** (Highest Priority)
   - Time synchronization
   - Password changes
   - Account lockouts
   - Group Policy processing

2. **RID Master** (High Priority)
   - Required for creating new security principals
   - Monitor RID pool allocation

3. **Infrastructure Master** (Medium Priority)
   - Cross-domain reference updates
   - Important for multi-domain environments

4. **Domain Naming Master** (Low Priority - Forest Operations)
   - Required only for adding/removing domains

5. **Schema Master** (Low Priority - Forest Operations)
   - Required only for schema modifications

### Recovery Scenarios and Procedures

#### Scenario 1: Single FSMO Role Holder Failure

```powershell
<#
.SYNOPSIS
    Handles emergency FSMO role transfer procedures.
.DESCRIPTION
    This function determines whether to perform graceful transfer or role seizure
    based on the availability of the current role holder.
.PARAMETER FailedDC
    The fully qualified domain name of the failed domain controller.
.PARAMETER TargetDC
    The fully qualified domain name of the target domain controller.
.EXAMPLE
    Emergency-FSMOTransfer -FailedDC "DC01.contoso.com" -TargetDC "DC02.contoso.com"
    Evaluates DC01 status and determines appropriate transfer method to DC02.
#>
function Emergency-FSMOTransfer
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$FailedDC,
        [Parameter(Mandatory = $true)]
        [string]$TargetDC
    )
    
    Write-Host "Emergency FSMO Role Transfer Procedure" -ForegroundColor Red
    Write-Host "Failed DC: $FailedDC" -ForegroundColor Yellow
    Write-Host "Target DC: $TargetDC" -ForegroundColor Green
    
    # Check if failed DC is reachable
    $DcTest = Test-NetConnection -ComputerName $FailedDC -Port 389 -WarningAction SilentlyContinue
    
    if ($DcTest.TcpTestSucceeded)
    {
        Write-Host "Source DC is reachable - performing graceful transfer" -ForegroundColor Green
        # Perform graceful transfer
    }
    else
    {
        Write-Host "Source DC is unreachable - role seizure required" -ForegroundColor Red
        Write-Warning "Ensure the failed DC will NEVER return to the network before proceeding"
        # Perform role seizure
    }
}
```

#### Scenario 2: Multiple FSMO Role Holder Failures

```text
Recovery Priority Matrix:
┌─────────────────┬──────────┬────────────────┬─────────────────┐
│ FSMO Role       │ Priority │ Impact         │ Recovery Time   │
├─────────────────┼──────────┼────────────────┼─────────────────┤
│ PDC Emulator    │ 1        │ Immediate      │ < 1 hour        │
│ RID Master      │ 2        │ Within days    │ < 4 hours       │
│ Infrastructure  │ 3        │ Gradual        │ < 24 hours      │
│ Domain Naming   │ 4        │ Only for ops   │ < 48 hours      │
│ Schema Master   │ 5        │ Only for ops   │ < 48 hours      │
└─────────────────┴──────────┴────────────────┴─────────────────┘
```

## Troubleshooting Common Issues

### Issue 1: FSMO Role Holder Not Responding

**Symptoms**:

- Authentication delays
- Group Policy processing issues
- Unable to create new security principals

**Diagnosis**:

```powershell
# Test FSMO connectivity
dcdiag /test:fsmocheck
dcdiag /test:ridmanager
dcdiag /test:intersite

# Check replication health
repadmin /replsummary
repadmin /showrepl

# Verify time synchronization (especially for PDC)
w32tm /monitor
```

**Resolution**:

1. Check network connectivity
2. Verify DNS resolution
3. Check Windows Time service
4. Review event logs for specific errors
5. Consider role transfer if issues persist

### Issue 2: Infrastructure Master and Global Catalog Conflict

**Symptoms**:

- Outdated cross-domain group memberships
- Inconsistent security descriptors
- Phantom object references

**Diagnosis**:

```powershell
# Check if Infrastructure Master is on a Global Catalog
$InfraMaster = (Get-ADDomain).InfrastructureMaster
$IsGC = (Get-ADDomainController -Identity $InfraMaster).IsGlobalCatalog

if ($IsGC)
{
    Write-Warning "Infrastructure Master is on a Global Catalog server!"
    
    # Check if ALL DCs in domain are GCs
    $AllDCs = Get-ADDomainController -Filter *
    $AllGCs = $AllDCs | Where-Object { $_.IsGlobalCatalog -eq $true }
    
    if ($AllDCs.Count -eq $AllGCs.Count)
    {
        Write-Host "All DCs are GCs - configuration is acceptable" -ForegroundColor Green
    }
    else
    {
        Write-Warning "Not all DCs are GCs - Infrastructure Master should be moved"
    }
}
```

**Resolution**:

1. Move Infrastructure Master to a non-GC server, OR
2. Make all DCs in the domain Global Catalogs

### Issue 3: RID Pool Depletion

**Symptoms**:

- Cannot create new users, groups, or computers
- Event ID 16650 in System log

**Diagnosis**:

```powershell
# Check RID pool status
dcdiag /test:ridmanager /v

# View current RID allocation
Get-ADDomainController | ForEach-Object {
    $RidInfo = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "RID Set References" -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        DC = $_.Name
        RIDInfo = $RidInfo
    }
}
```

**Resolution**:

1. Contact RID Master to request new RID pool
2. If RID Master is unavailable, transfer or seize the role
3. Monitor RID consumption patterns

## Security Considerations

### FSMO Role Security Best Practices

1. **Administrative Access Control**:
   - Limit Schema Admins group membership
   - Control Enterprise Admins group access
   - Use Just-in-Time (JIT) administration
   - Implement privileged access workstations (PAWs)

2. **Physical and Network Security**:
   - Place FSMO role holders in secure locations
   - Implement network segmentation
   - Use dedicated management networks
   - Deploy endpoint protection

3. **Monitoring and Auditing**:
   - Enable security auditing for FSMO operations
   - Monitor role transfer events
   - Implement SIEM integration
   - Regular security assessments

```powershell
# Enable FSMO-related auditing
auditpol /set /subcategory:"Directory Service Changes" /success:enable /failure:enable
auditpol /set /subcategory:"Directory Service Access" /success:enable /failure:enable

# Key event IDs to monitor:
# 4742: Computer account changed
# 4743: Computer account deleted
# 5136: Directory service object modified
# 5137: Directory service object created
# 5141: Directory service object deleted
```

## Performance Optimization

### PDC Emulator Optimization

```powershell
# Optimize PDC Emulator for time synchronization
w32tm /config /manualpeerlist:"time.nist.gov,0x8" /syncfromflags:manual /reliable:yes /update

# Configure high-performance time synchronization
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" -Name "MaxPosPhaseCorrection" -Value 3600
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" -Name "MaxNegPhaseCorrection" -Value 3600

# Restart time service
Restart-Service W32Time
```

### RID Master Optimization

```powershell
<#
.SYNOPSIS
    Monitors RID pool allocation status for domain controllers.
.DESCRIPTION
    This function retrieves RID pool allocation information from all domain controllers
    to help monitor RID consumption and prevent pool depletion.
.EXAMPLE
    Get-RIDPoolStatus
    Returns RID pool status for all domain controllers.
.NOTES
    Helps identify potential RID pool depletion issues before they occur.
#>
function Get-RIDPoolStatus
{
    $RidMaster = (Get-ADDomain).RIDMaster
    $Computer = Get-ADComputer -Identity $RidMaster
    
    # Get RID allocation information
    $RidSet = Get-ADObject -Filter { objectClass -eq "rIDSet" } -Properties rIDAllocationPool, rIDPreviousAllocationPool, rIDUsedPool
    
    foreach ($Rid in $RidSet)
    {
        [PSCustomObject]@{
            DistinguishedName = $Rid.DistinguishedName
            AllocationPool = $Rid.rIDAllocationPool
            PreviousPool = $Rid.rIDPreviousAllocationPool
            UsedPool = $Rid.rIDUsedPool
        }
    }
}

# Run RID status check
Get-RIDPoolStatus | Format-Table -AutoSize
```

## Best Practices Summary

1. **Planning and Design**:
   - Document FSMO role placement decisions
   - Plan for disaster recovery scenarios
   - Consider geographic distribution
   - Implement proper network topology

2. **Operational Management**:
   - Regular health monitoring
   - Planned role transfers during maintenance
   - Proper change management procedures
   - Documentation of all role transfers

3. **Security and Compliance**:
   - Principle of least privilege
   - Regular security audits
   - Compliance with organizational policies
   - Incident response procedures

4. **Performance and Availability**:
   - Adequate hardware resources
   - Network optimization
   - Regular performance monitoring
   - Proactive capacity planning

## Additional Resources

- [Microsoft FSMO Best Practices](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/plan/planning-operations-master-role-placement)
- [Active Directory Disaster Recovery Guide](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/ad-forest-recovery-guide)
- [FSMO Role Seizure Documentation](https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/seize-or-transfer-fsmo-roles)
- [Time Synchronization Best Practices](https://docs.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-top)
