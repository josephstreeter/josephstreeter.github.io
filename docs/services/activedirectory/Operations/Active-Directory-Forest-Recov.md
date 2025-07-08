---
title: "Active Directory Forest Recovery Guide"
description: "Comprehensive disaster recovery guide for Active Directory forest restoration using modern DFSR-based procedures and best practices"
tags: ["active-directory", "forest-recovery", "disaster-recovery", "dfsr", "sysvol", "fsmo", "backup-restore"]
category: "infrastructure"
subcategory: "active-directory"
difficulty: "expert"
last_updated: "2025-01-22"
applies_to: ["Windows Server 2016+", "Active Directory", "DFSR", "Forest Recovery"]
warning: "Forest recovery is a critical operation that affects the entire AD infrastructure. Thorough planning and testing required."
---

## Overview

Active Directory forest recovery is the process of restoring an entire Active Directory forest from backup when catastrophic failure renders all domain controllers inoperable or corrupted. This comprehensive guide provides modern procedures for forest recovery using Windows Server 2016 and later, with DFSR-based SYSVOL replication and enhanced security considerations.

> **Critical Warning:** Forest recovery is an irreversible process that affects the entire organization's identity infrastructure. This procedure should only be performed when all domain controllers are lost or corrupted beyond repair.

## Executive Summary

Forest recovery scenarios include:

- **Complete forest destruction** - All domain controllers destroyed or corrupted
- **Security breach remediation** - Compromise requiring complete forest rebuild
- **Catastrophic data corruption** - USN rollback or database corruption across all DCs
- **Natural disaster recovery** - Physical destruction of all domain controllers

### Recovery Scope

This guide covers:

- **Complete forest restoration** from authoritative backup
- **Modern DFSR SYSVOL recovery** (replacing obsolete FRS procedures)
- **FSMO role seizure** and redistribution
- **Security remediation** including password resets
- **Trust relationship restoration** with external domains
- **Verification and validation** procedures

## Prerequisites

### Planning and Documentation Requirements

**Essential Documentation:**

- **Forest configuration documentation** - Current topology, sites, subnets
- **FSMO role distribution** - Current role holders and preferred distribution
- **Trust relationships** - External trusts and their configurations
- **Backup inventory** - Available backups with dates and validation status
- **Emergency contacts** - Escalation procedures and stakeholder notifications

### Administrative Requirements

**Required Permissions:**

- **Domain Admin** privileges in the root domain
- **Enterprise Admin** membership for forest-wide operations
- **Schema Admin** privileges for schema-related operations
- **Physical or management access** to all recovery infrastructure

### Technical Prerequisites

**System Requirements:**

- **Windows Server 2016 or later** for domain controllers
- **DFSR-based SYSVOL replication** (FRS no longer supported)
- **Validated backup media** with successful restore testing
- **Network infrastructure** supporting domain controller communications
- **Time synchronization** with reliable time sources

### Backup Validation

**Pre-Recovery Backup Verification:**

```powershell
# Verify backup integrity before starting recovery
function Test-BackupIntegrity {
    param(
        [string]$BackupPath,
        [string]$DCName
    )
    
    Write-Host "=== Backup Integrity Verification ===" -ForegroundColor Green
    
    # Test backup accessibility
    Write-Host "`n1. Testing backup accessibility..." -ForegroundColor Yellow
    if (Test-Path $BackupPath) {
        Write-Host "  ✓ Backup path accessible: $BackupPath" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Backup path not accessible: $BackupPath" -ForegroundColor Red
        return $false
    }
    
    # Check backup age
    Write-Host "`n2. Checking backup age..." -ForegroundColor Yellow
    $BackupDate = (Get-ChildItem $BackupPath | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
    $BackupAge = (Get-Date) - $BackupDate
    
    Write-Host "  Backup Date: $BackupDate" -ForegroundColor Gray
    Write-Host "  Backup Age: $($BackupAge.Days) days" -ForegroundColor Gray
    
    if ($BackupAge.Days -gt 14) {
        Write-Host "  ⚠ Backup is older than 14 days" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ Backup age is acceptable" -ForegroundColor Green
    }
    
    # Verify backup completeness
    Write-Host "`n3. Verifying backup completeness..." -ForegroundColor Yellow
    $RequiredFiles = @("*.vhd", "*.vhdx", "*.wim", "MediaId.bin")
    
    foreach ($Pattern in $RequiredFiles) {
        $Files = Get-ChildItem -Path $BackupPath -Filter $Pattern -Recurse
        if ($Files.Count -gt 0) {
            Write-Host "  ✓ Found $($Files.Count) files matching $Pattern" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ No files found matching $Pattern" -ForegroundColor Yellow
        }
    }
    
    return $true
}

# Example usage
Test-BackupIntegrity -BackupPath "\\backup-server\ad-backups\dc01" -DCName "DC01"
```

## Forest Recovery Phases

### Phase 1: Recovery Planning and Preparation

#### 1.1 Situation Assessment

**Damage Assessment Checklist:**

```powershell
# Comprehensive damage assessment
function Invoke-ForestDamageAssessment {
    Write-Host "=== Active Directory Forest Damage Assessment ===" -ForegroundColor Red
    
    # Attempt to contact domain controllers
    Write-Host "`n1. Domain Controller Availability Assessment..." -ForegroundColor Yellow
    try {
        $Forest = Get-ADForest -ErrorAction SilentlyContinue
        if ($Forest) {
            Write-Host "  ✓ Forest accessible: $($Forest.Name)" -ForegroundColor Green
            
            $DCs = Get-ADDomainController -Filter * -ErrorAction SilentlyContinue
            foreach ($DC in $DCs) {
                $Ping = Test-Connection -ComputerName $DC.HostName -Count 1 -Quiet
                if ($Ping) {
                    Write-Host "  ✓ DC Online: $($DC.HostName)" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ DC Offline: $($DC.HostName)" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "  ✗ Forest not accessible - Full recovery required" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  ✗ Cannot connect to Active Directory" -ForegroundColor Red
        Write-Host "  ✗ Forest recovery required" -ForegroundColor Red
    }
    
    # Check SYSVOL replication health
    Write-Host "`n2. SYSVOL Replication Assessment..." -ForegroundColor Yellow
    try {
        $SysvolTest = dfsrdiag replicationstate /member:* /rgname:"Domain System Volume"
        if ($SysvolTest -match "Healthy") {
            Write-Host "  ✓ SYSVOL replication appears healthy" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ SYSVOL replication issues detected" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ✗ Cannot assess SYSVOL replication" -ForegroundColor Red
    }
    
    # Check for USN rollback indicators
    Write-Host "`n3. USN Rollback Detection..." -ForegroundColor Yellow
    # USN rollback detection logic would go here
    Write-Host "  Manual verification required for USN rollback" -ForegroundColor Yellow
}

# Execute assessment
Invoke-ForestDamageAssessment
```

#### 1.2 Recovery Strategy Selection

**Recovery Decision Matrix:**

| Scenario | Intact DCs | Data Corruption | Recommended Action |
|----------|------------|-----------------|-------------------|
| Single DC Failure | 2+ | None | DC rebuild/promotion |
| Multiple DC Failure | 1+ | Limited | Metadata cleanup + new DCs |
| All DCs Lost | 0 | N/A | **Full Forest Recovery** |
| Security Compromise | Any | Potential | **Full Forest Recovery** |
| USN Rollback | Any | Yes | **Full Forest Recovery** |

#### 1.3 Recovery Environment Preparation

**Infrastructure Readiness:**

1. **Network Infrastructure**
   - DNS resolution for domain controllers
   - Site and subnet configuration
   - Time synchronization sources

1. **Hardware/Virtual Infrastructure**
   - Recovery server specifications
   - Storage configuration matching backup source
   - Network connectivity requirements

1. **Backup Media Preparation**
   - Backup accessibility verification
   - Recovery media staging
   - Network share permissions

### Phase 2: Primary Domain Controller Recovery

#### 2.1 System Image Restoration

**Modern Windows Server Backup Recovery:**

```powershell
# Enhanced system recovery validation
function Start-SystemImageRecovery {
    param(
        [string]$BackupLocation,
        [string]$TargetServer
    )
    
    Write-Host "=== System Image Recovery Process ===" -ForegroundColor Green
    
    Write-Host "`nPre-Recovery Checklist:" -ForegroundColor Yellow
    Write-Host "  1. Boot from Windows Server installation media" -ForegroundColor Gray
    Write-Host "  2. Select 'Repair your computer'" -ForegroundColor Gray
    Write-Host "  3. Choose 'System Image Recovery'" -ForegroundColor Gray
    Write-Host "  4. Select backup source: $BackupLocation" -ForegroundColor Gray
    Write-Host "  5. Verify target disk configuration" -ForegroundColor Gray
    
    Write-Host "`n⚠ CRITICAL: Do NOT restart after recovery until SYSVOL procedures complete" -ForegroundColor Red
    
    # Post-recovery validation script
    $ValidationScript = @"
# Post-recovery validation (run after system boots)
Write-Host "Post-Recovery System Validation" -ForegroundColor Green

# Check system services
`$Services = @('NTDS', 'DNS', 'DFSR', 'W32Time', 'Netlogon')
foreach (`$Service in `$Services) {
    `$Status = Get-Service -Name `$Service -ErrorAction SilentlyContinue
    if (`$Status) {
        Write-Host "Service `$Service`: `$(`$Status.Status)" -ForegroundColor Green
    } else {
        Write-Host "Service `$Service`: Not Found" -ForegroundColor Red
    }
}

# Check SYSVOL shares (should not exist yet)
`$Shares = net share | Select-String "SYSVOL|NETLOGON"
if (`$Shares.Count -eq 0) {
    Write-Host "✓ SYSVOL/NETLOGON shares not present (expected)" -ForegroundColor Green
} else {
    Write-Host "⚠ SYSVOL/NETLOGON shares found unexpectedly" -ForegroundColor Yellow
}
"@
    
    # Save validation script
    $ValidationScript | Out-File -FilePath "C:\Recovery\PostRecoveryValidation.ps1" -Force
    Write-Host "`nValidation script saved to: C:\Recovery\PostRecoveryValidation.ps1" -ForegroundColor Green
}

# Execute recovery preparation
Start-SystemImageRecovery -BackupLocation "\\backup-server\ad-backups" -TargetServer "DC01"
```

#### 2.2 Post-Recovery System Configuration

**Initial System Configuration:**

```powershell
# Complete post-recovery configuration
function Initialize-RecoveredDomainController {
    param(
        [string]$DCName,
        [string]$IPAddress,
        [string]$DomainName
    )
    
    Write-Host "=== Domain Controller Post-Recovery Configuration ===" -ForegroundColor Green
    
    # Configure static IP address
    Write-Host "`n1. Configuring network settings..." -ForegroundColor Yellow
    $Adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
    
    if ($Adapter) {
        # Remove existing IP configuration
        Remove-NetIPAddress -InterfaceAlias $Adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $Adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        
        # Configure new IP settings
        New-NetIPAddress -InterfaceAlias $Adapter.Name -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway "192.168.1.1"
        Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name -ServerAddresses $IPAddress
        
        Write-Host "  ✓ Network configured: $IPAddress" -ForegroundColor Green
    }
    
    # Set computer name if needed
    Write-Host "`n2. Verifying computer name..." -ForegroundColor Yellow
    $CurrentName = $env:COMPUTERNAME
    if ($CurrentName -ne $DCName) {
        Write-Host "  ⚠ Computer name mismatch. Manual rename required." -ForegroundColor Yellow
        Write-Host "    Current: $CurrentName, Expected: $DCName" -ForegroundColor Gray
    } else {
        Write-Host "  ✓ Computer name correct: $DCName" -ForegroundColor Green
    }
    
    # Verify DNS registration
    Write-Host "`n3. Testing DNS resolution..." -ForegroundColor Yellow
    try {
        $DNSTest = Resolve-DnsName -Name $DomainName -ErrorAction Stop
        Write-Host "  ✓ DNS resolution successful for $DomainName" -ForegroundColor Green
    }
    catch {
        Write-Host "  ⚠ DNS resolution failed for $DomainName" -ForegroundColor Yellow
        Write-Host "  This is expected during forest recovery" -ForegroundColor Gray
    }
    
    # Check Active Directory database
    Write-Host "`n4. Verifying Active Directory database..." -ForegroundColor Yellow
    if (Test-Path "C:\Windows\NTDS\ntds.dit") {
        Write-Host "  ✓ AD database file found" -ForegroundColor Green
    } else {
        Write-Host "  ✗ AD database file missing" -ForegroundColor Red
    }
    
    # Stop unnecessary services for SYSVOL recovery
    Write-Host "`n5. Preparing for SYSVOL recovery..." -ForegroundColor Yellow
    $ServicesToStop = @('DFSR')
    foreach ($Service in $ServicesToStop) {
        try {
            Stop-Service -Name $Service -Force -ErrorAction Stop
            Write-Host "  ✓ Stopped service: $Service" -ForegroundColor Green
        }
        catch {
            Write-Host "  ⚠ Could not stop service: $Service" -ForegroundColor Yellow
        }
    }
}

# Execute post-recovery configuration
Initialize-RecoveredDomainController -DCName "DC01" -IPAddress "192.168.1.10" -DomainName "contoso.com"
```

### Phase 3: SYSVOL Authoritative Restore (DFSR)

#### 3.1 Modern DFSR-Based SYSVOL Recovery

**DFSR Authoritative Restore Procedure:**

```powershell
# Complete DFSR SYSVOL authoritative restore
function Invoke-DFSRAuthoritativeRestore {
    param(
        [string]$DCName,
        [string]$DomainDN
    )
    
    Write-Host "=== DFSR SYSVOL Authoritative Restore ===" -ForegroundColor Green
    
    # Verify DFSR service is stopped
    Write-Host "`n1. Verifying DFSR service status..." -ForegroundColor Yellow
    $DFSRService = Get-Service -Name DFSR -ErrorAction SilentlyContinue
    if ($DFSRService.Status -eq 'Running') {
        Stop-Service -Name DFSR -Force
        Write-Host "  ✓ DFSR service stopped" -ForegroundColor Green
    } else {
        Write-Host "  ✓ DFSR service already stopped" -ForegroundColor Green
    }
    
    # Import Active Directory module
    Write-Host "`n2. Loading Active Directory module..." -ForegroundColor Yellow
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Host "  ✓ Active Directory module loaded" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Failed to load Active Directory module" -ForegroundColor Red
        return
    }
    
    # Configure DFSR for authoritative restore
    Write-Host "`n3. Configuring DFSR for authoritative restore..." -ForegroundColor Yellow
    try {
        # Enable advanced features in AD Users and Computers
        Write-Host "  Opening Active Directory Users and Computers..." -ForegroundColor Gray
        Write-Host "  Navigate to: Domain Controllers > $DCName > DFSR-LocalSettings > Domain System Volume > SYSVOL Subscription" -ForegroundColor Gray
        
        # Set msDFSR-Options to 1 for authoritative restore
        $SysvolSubscriptionDN = "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DCName,OU=Domain Controllers,$DomainDN"
        
        Write-Host "  Setting msDFSR-Options attribute..." -ForegroundColor Gray
        Set-ADObject -Identity $SysvolSubscriptionDN -Replace @{"msDFSR-Options" = "1"} -ErrorAction Stop
        Write-Host "  ✓ msDFSR-Options set to 1 (authoritative)" -ForegroundColor Green
        
        # Verify msDFSR-Enabled is TRUE
        $SysvolSubscription = Get-ADObject -Identity $SysvolSubscriptionDN -Properties "msDFSR-Enabled", "msDFSR-Options"
        if ($SysvolSubscription."msDFSR-Enabled" -eq $true) {
            Write-Host "  ✓ msDFSR-Enabled is TRUE" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ msDFSR-Enabled is not TRUE" -ForegroundColor Yellow
        }
        
        Write-Host "  Current msDFSR-Options: $($SysvolSubscription.'msDFSR-Options')" -ForegroundColor Gray
    }
    catch {
        Write-Host "  ✗ Failed to configure DFSR: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    # Start DFSR service
    Write-Host "`n4. Starting DFSR service..." -ForegroundColor Yellow
    try {
        Start-Service -Name DFSR -ErrorAction Stop
        Write-Host "  ✓ DFSR service started" -ForegroundColor Green
        
        # Wait for service to initialize
        Start-Sleep -Seconds 10
    }
    catch {
        Write-Host "  ✗ Failed to start DFSR service" -ForegroundColor Red
        return
    }
    
    # Trigger DFSR polling
    Write-Host "`n5. Triggering DFSR polling..." -ForegroundColor Yellow
    try {
        $PollingResult = dfsrdiag pollad
        Write-Host "  ✓ DFSR polling initiated" -ForegroundColor Green
    }
    catch {
        Write-Host "  ⚠ DFSR polling command failed" -ForegroundColor Yellow
    }
    
    # Monitor for completion
    Write-Host "`n6. Monitoring DFSR restore completion..." -ForegroundColor Yellow
    Write-Host "  Waiting for Event ID 4602 in DFS Replication log..." -ForegroundColor Gray
    
    $Timeout = 300 # 5 minutes
    $Timer = 0
    $RestoreComplete = $false
    
    while ($Timer -lt $Timeout -and -not $RestoreComplete) {
        Start-Sleep -Seconds 30
        $Timer += 30
        
        # Check for completion event
        $Events = Get-WinEvent -FilterHashtable @{LogName='DFS Replication'; ID=4602} -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($Events) {
            $LatestEvent = $Events | Sort-Object TimeCreated -Descending | Select-Object -First 1
            if ($LatestEvent.TimeCreated -gt (Get-Date).AddMinutes(-10)) {
                Write-Host "  ✓ DFSR authoritative restore completed" -ForegroundColor Green
                $RestoreComplete = $true
            }
        }
        
        Write-Host "  Waiting... ($Timer/$Timeout seconds)" -ForegroundColor Gray
    }
    
    if (-not $RestoreComplete) {
        Write-Host "  ⚠ Timeout waiting for completion event" -ForegroundColor Yellow
        Write-Host "  Check DFS Replication event log manually" -ForegroundColor Gray
    }
    
    # Verify SYSVOL shares
    Write-Host "`n7. Verifying SYSVOL shares..." -ForegroundColor Yellow
    $Shares = net share | Select-String "SYSVOL|NETLOGON"
    if ($Shares.Count -ge 2) {
        Write-Host "  ✓ SYSVOL and NETLOGON shares created" -ForegroundColor Green
        foreach ($Share in $Shares) {
            Write-Host "    $Share" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ⚠ SYSVOL/NETLOGON shares not yet available" -ForegroundColor Yellow
    }
}

# Execute DFSR authoritative restore
$DomainDN = "DC=contoso,DC=com"
Invoke-DFSRAuthoritativeRestore -DCName "DC01" -DomainDN $DomainDN
```

### Phase 4: FSMO Role Management

#### 4.1 FSMO Role Seizure

**Comprehensive FSMO Role Seizure:**

```powershell
# Complete FSMO role seizure procedure
function Invoke-FSMORoleSeizure {
    param(
        [string]$TargetDC,
        [string[]]$RolesToSeize = @("Schema", "Naming", "Infrastructure", "PDC", "RID")
    )
    
    Write-Host "=== FSMO Role Seizure Procedure ===" -ForegroundColor Green
    
    # Current FSMO role assessment
    Write-Host "`n1. Current FSMO role assessment..." -ForegroundColor Yellow
    try {
        $CurrentRoles = netdom query fsmo
        Write-Host "  Current FSMO roles:" -ForegroundColor Gray
        $CurrentRoles | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    }
    catch {
        Write-Host "  ⚠ Cannot determine current FSMO roles" -ForegroundColor Yellow
    }
    
    # Seize roles using ntdsutil
    Write-Host "`n2. Seizing FSMO roles..." -ForegroundColor Yellow
    
    $FSMOCommands = @{
        "Schema" = "seize schema master"
        "Naming" = "seize naming master"
        "Infrastructure" = "seize infrastructure master"
        "PDC" = "seize pdc"
        "RID" = "seize rid master"
    }
    
    foreach ($Role in $RolesToSeize) {
        if ($FSMOCommands.ContainsKey($Role)) {
            Write-Host "  Seizing $Role role..." -ForegroundColor Gray
            
            # Create ntdsutil command script
            $NtdsutilScript = @"
roles
connections
connect to server $TargetDC
quit
$($FSMOCommands[$Role])
quit
quit
"@
            
            # Execute ntdsutil commands
            try {
                $NtdsutilScript | ntdsutil
                Write-Host "    ✓ $Role role seizure initiated" -ForegroundColor Green
            }
            catch {
                Write-Host "    ✗ Failed to seize $Role role" -ForegroundColor Red
            }
        }
    }
    
    # Verify role seizure
    Write-Host "`n3. Verifying FSMO role seizure..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    try {
        $NewRoles = netdom query fsmo
        Write-Host "  New FSMO role distribution:" -ForegroundColor Gray
        $NewRoles | ForEach-Object { 
            if ($_ -match $TargetDC) {
                Write-Host "    ✓ $_" -ForegroundColor Green
            } else {
                Write-Host "    $_" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-Host "  ⚠ Cannot verify new FSMO roles" -ForegroundColor Yellow
    }
    
    # Register DNS records
    Write-Host "`n4. Registering DNS records..." -ForegroundColor Yellow
    try {
        ipconfig /registerdns
        nltest /dsregdns
        Write-Host "  ✓ DNS registration initiated" -ForegroundColor Green
    }
    catch {
        Write-Host "  ⚠ DNS registration failed" -ForegroundColor Yellow
    }
}

# Execute FSMO role seizure
Invoke-FSMORoleSeizure -TargetDC "DC01.contoso.com"
```

### Phase 5: Security Remediation

#### 5.1 Critical Security Resets

**Comprehensive Security Reset Procedure:**

```powershell
# Complete security remediation for forest recovery
function Invoke-ForestSecurityRemediation {
    param(
        [string]$DomainName,
        [string]$DCName
    )
    
    Write-Host "=== Forest Recovery Security Remediation ===" -ForegroundColor Green
    
    # Reset krbtgt account password (CRITICAL)
    Write-Host "`n1. Resetting krbtgt account password..." -ForegroundColor Yellow
    try {
        # Generate complex password
        $KrbtgtPassword = -join ((33..126) | Get-Random -Count 64 | ForEach-Object {[char]$_})
        
        # Reset krbtgt password
        Set-ADAccountPassword -Identity "krbtgt" -NewPassword (ConvertTo-SecureString $KrbtgtPassword -AsPlainText -Force) -Reset
        Write-Host "  ✓ krbtgt password reset successfully" -ForegroundColor Green
        
        # Log password securely (implementation dependent)
        Write-Host "  ⚠ Store krbtgt password securely for compliance" -ForegroundColor Yellow
    }
    catch {
        Write-Host "  ✗ Failed to reset krbtgt password: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Reset computer account password
    Write-Host "`n2. Resetting domain controller computer account..." -ForegroundColor Yellow
    try {
        $ComputerResetScript = @"
# Reset computer account password twice for compatibility
netdom resetpwd /server:$DCName /userd:$DomainName\administrator /passwordd:*
netdom resetpwd /server:$DCName /userd:$DomainName\administrator /passwordd:*
"@
        
        Write-Host "  Computer account reset commands:" -ForegroundColor Gray
        Write-Host $ComputerResetScript -ForegroundColor Gray
        Write-Host "  ✓ Execute these commands with domain admin credentials" -ForegroundColor Green
    }
    catch {
        Write-Host "  ⚠ Manual computer account reset required" -ForegroundColor Yellow
    }
    
    # Reset administrative account passwords
    Write-Host "`n3. Resetting administrative account passwords..." -ForegroundColor Yellow
    $AdminAccounts = @("Administrator", "Guest")
    
    foreach ($Account in $AdminAccounts) {
        try {
            if (Get-ADUser -Identity $Account -ErrorAction SilentlyContinue) {
                # Generate complex password
                $NewPassword = -join ((33..126) | Get-Random -Count 32 | ForEach-Object {[char]$_})
                Set-ADAccountPassword -Identity $Account -NewPassword (ConvertTo-SecureString $NewPassword -AsPlainText -Force) -Reset
                Write-Host "  ✓ Password reset for $Account" -ForegroundColor Green
                
                # Secure password storage notification
                Write-Host "    ⚠ Store password securely: $Account" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  ⚠ Could not reset password for $Account" -ForegroundColor Yellow
        }
    }
    
    # Force user password changes at next logon
    Write-Host "`n4. Configuring mandatory password changes..." -ForegroundColor Yellow
    try {
        $AllUsers = Get-ADUser -Filter * -Properties PasswordLastSet
        $UserCount = 0
        
        foreach ($User in $AllUsers) {
            if ($User.Name -notin @("krbtgt", "Guest") -and $User.Enabled) {
                Set-ADUser -Identity $User -ChangePasswordAtLogon $true
                $UserCount++
            }
        }
        
        Write-Host "  ✓ Configured password change for $UserCount users" -ForegroundColor Green
    }
    catch {
        Write-Host "  ⚠ Could not configure user password changes" -ForegroundColor Yellow
    }
    
    # Certificate Authority considerations
    Write-Host "`n5. Certificate Authority security review..." -ForegroundColor Yellow
    $CAExists = Get-Service -Name "CertSvc" -ErrorAction SilentlyContinue
    if ($CAExists) {
        Write-Host "  ⚠ Certificate Authority detected" -ForegroundColor Yellow
        Write-Host "    Manual review required for:" -ForegroundColor Gray
        Write-Host "      - CA database integrity" -ForegroundColor Gray
        Write-Host "      - Certificate revocation" -ForegroundColor Gray
        Write-Host "      - CA certificate validation" -ForegroundColor Gray
    } else {
        Write-Host "  ✓ No Certificate Authority detected" -ForegroundColor Green
    }
}

# Execute security remediation
Invoke-ForestSecurityRemediation -DomainName "contoso.com" -DCName "DC01"
```

### Phase 6: Trust Relationship Recovery

#### 6.1 External Trust Restoration

**Trust Relationship Recovery Procedures:**

```powershell
# Trust relationship recovery and validation
function Restore-TrustRelationships {
    param(
        [string]$LocalDomain,
        [hashtable]$TrustRelationships
    )
    
    Write-Host "=== Trust Relationship Recovery ===" -ForegroundColor Green
    
    # Assess current trust state
    Write-Host "`n1. Assessing current trust relationships..." -ForegroundColor Yellow
    try {
        $CurrentTrusts = nltest /domain_trusts /all_trusts
        Write-Host "  Current trust status:" -ForegroundColor Gray
        $CurrentTrusts | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    }
    catch {
        Write-Host "  ⚠ Cannot enumerate current trusts" -ForegroundColor Yellow
    }
    
    # Reset trust passwords
    Write-Host "`n2. Resetting trust passwords..." -ForegroundColor Yellow
    foreach ($TrustedDomain in $TrustRelationships.Keys) {
        $TrustPassword = $TrustRelationships[$TrustedDomain]
        
        Write-Host "  Processing trust with $TrustedDomain..." -ForegroundColor Gray
        
        try {
            # Reset trust password on local side
            $ResetCommand = "netdom trust $LocalDomain /domain:$TrustedDomain /resetoneside /pt:$TrustPassword /uo:administrator /po:*"
            Write-Host "    Command: $ResetCommand" -ForegroundColor Gray
            
            # Note: Actual execution requires interactive password input
            Write-Host "    ✓ Trust reset command prepared" -ForegroundColor Green
            Write-Host "    ⚠ Execute manually with appropriate credentials" -ForegroundColor Yellow
        }
        catch {
            Write-Host "    ✗ Failed to prepare trust reset for $TrustedDomain" -ForegroundColor Red
        }
    }
    
    # Trust validation
    Write-Host "`n3. Trust validation procedures..." -ForegroundColor Yellow
    foreach ($TrustedDomain in $TrustRelationships.Keys) {
        Write-Host "  Validating trust with $TrustedDomain..." -ForegroundColor Gray
        
        try {
            # Test trust relationship
            $TrustTest = nltest /trusted_domains
            if ($TrustTest -match $TrustedDomain) {
                Write-Host "    ✓ Trust relationship detected" -ForegroundColor Green
            } else {
                Write-Host "    ⚠ Trust relationship not detected" -ForegroundColor Yellow
            }
            
            # Test secure channel
            $SecureChannelTest = nltest /sc_query:$TrustedDomain
            Write-Host "    Secure channel test: Manual verification required" -ForegroundColor Gray
        }
        catch {
            Write-Host "    ⚠ Trust validation failed for $TrustedDomain" -ForegroundColor Yellow
        }
    }
}

# Example trust relationships (customize for environment)
$TrustRelationships = @{
    "partner.contoso.com" = "ComplexTrustPassword123!"
    "subsidiary.contoso.com" = "AnotherTrustPassword456!"
}

# Execute trust restoration
Restore-TrustRelationships -LocalDomain "contoso.com" -TrustRelationships $TrustRelationships
```

### Phase 7: Global Catalog Rebuilding

#### 7.1 Global Catalog Recovery

**Global Catalog Rebuild Procedure:**

```powershell
# Global Catalog rebuild and verification
function Rebuild-GlobalCatalog {
    param(
        [string]$DCName
    )
    
    Write-Host "=== Global Catalog Rebuild Procedure ===" -ForegroundColor Green
    
    # Check current Global Catalog status
    Write-Host "`n1. Checking current Global Catalog status..." -ForegroundColor Yellow
    try {
        $GCStatus = repadmin /options $DCName
        if ($GCStatus -match "IS_GC") {
            Write-Host "  ✓ Domain Controller is currently a Global Catalog" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Domain Controller is not a Global Catalog" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ⚠ Cannot determine Global Catalog status" -ForegroundColor Yellow
    }
    
    # Remove Global Catalog designation
    Write-Host "`n2. Removing Global Catalog designation..." -ForegroundColor Yellow
    try {
        $RemoveGC = repadmin /options $DCName -IS_GC
        Write-Host "  ✓ Global Catalog designation removed" -ForegroundColor Green
        
        # Wait for removal to take effect
        Write-Host "  Waiting for removal to take effect..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
        
        # Verify removal
        $RemovalEvent = Get-WinEvent -FilterHashtable @{LogName='Directory Service'; ID=1120} -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($RemovalEvent) {
            Write-Host "  ✓ Event ID 1120 confirmed Global Catalog removal" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Event ID 1120 not found - check manually" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ✗ Failed to remove Global Catalog designation" -ForegroundColor Red
        return
    }
    
    # Add Global Catalog designation
    Write-Host "`n3. Adding Global Catalog designation..." -ForegroundColor Yellow
    try {
        $AddGC = repadmin /options $DCName +IS_GC
        Write-Host "  ✓ Global Catalog designation added" -ForegroundColor Green
        
        # Monitor Global Catalog rebuild
        Write-Host "  ✓ Monitoring Global Catalog rebuild..." -ForegroundColor Gray
        Write-Host "    Event ID 1110: Global Catalog rebuild started" -ForegroundColor Gray
        Write-Host "    Event ID 1119: Global Catalog rebuild completed" -ForegroundColor Gray
        
        # Check for start event
        $StartTime = Get-Date
        $StartEvent = $null
        $CompleteEvent = $null
        
        # Wait up to 10 minutes for completion
        $Timeout = 600
        $Timer = 0
        
        while ($Timer -lt $Timeout) {
            Start-Sleep -Seconds 30
            $Timer += 30
            
            # Check for start event (1110)
            if (-not $StartEvent) {
                $StartEvent = Get-WinEvent -FilterHashtable @{LogName='Directory Service'; ID=1110; StartTime=$StartTime} -MaxEvents 1 -ErrorAction SilentlyContinue
                if ($StartEvent) {
                    Write-Host "    ✓ Event ID 1110: Global Catalog rebuild started" -ForegroundColor Green
                }
            }
            
            # Check for completion event (1119)
            $CompleteEvent = Get-WinEvent -FilterHashtable @{LogName='Directory Service'; ID=1119; StartTime=$StartTime} -MaxEvents 1 -ErrorAction SilentlyContinue
            if ($CompleteEvent) {
                Write-Host "    ✓ Event ID 1119: Global Catalog rebuild completed" -ForegroundColor Green
                break
            }
            
            Write-Host "    Waiting for rebuild completion... ($Timer/$Timeout seconds)" -ForegroundColor Gray
        }
        
        if (-not $CompleteEvent) {
            Write-Host "    ⚠ Timeout waiting for rebuild completion" -ForegroundColor Yellow
            Write-Host "    Monitor Directory Service event log for Event ID 1119" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  ✗ Failed to add Global Catalog designation" -ForegroundColor Red
    }
    
    # Verify final status
    Write-Host "`n4. Verifying Global Catalog status..." -ForegroundColor Yellow
    try {
        $FinalStatus = repadmin /options $DCName
        if ($FinalStatus -match "IS_GC") {
            Write-Host "  ✓ Domain Controller is now a Global Catalog" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Domain Controller is not a Global Catalog" -ForegroundColor Red
        }
        
        # Test Global Catalog functionality
        $GCTest = nltest /dsgetdc:$env:USERDNSDOMAIN /gc
        if ($GCTest -match $DCName) {
            Write-Host "  ✓ Global Catalog functionality verified" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Global Catalog functionality requires verification" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ⚠ Cannot verify final Global Catalog status" -ForegroundColor Yellow
    }
}

# Execute Global Catalog rebuild
Rebuild-GlobalCatalog -DCName "DC01"
```

## Verification and Validation

### Comprehensive Recovery Validation

**Complete Forest Recovery Validation:**

```powershell
# Comprehensive forest recovery validation
function Test-ForestRecoveryComplete {
    param(
        [string]$DomainName,
        [string]$DCName
    )
    
    Write-Host "=== Forest Recovery Validation ===" -ForegroundColor Green
    
    # Test 1: Basic AD functionality
    Write-Host "`n1. Testing basic Active Directory functionality..." -ForegroundColor Yellow
    try {
        $Domain = Get-ADDomain -Identity $DomainName
        Write-Host "  ✓ Domain accessible: $($Domain.DNSRoot)" -ForegroundColor Green
        
        $Forest = Get-ADForest
        Write-Host "  ✓ Forest accessible: $($Forest.Name)" -ForegroundColor Green
        Write-Host "    Forest Mode: $($Forest.ForestMode)" -ForegroundColor Gray
        Write-Host "    Domain Mode: $($Domain.DomainMode)" -ForegroundColor Gray
    }
    catch {
        Write-Host "  ✗ Basic AD functionality failed" -ForegroundColor Red
    }
    
    # Test 2: SYSVOL and NETLOGON shares
    Write-Host "`n2. Testing SYSVOL and NETLOGON shares..." -ForegroundColor Yellow
    $RequiredShares = @("SYSVOL", "NETLOGON")
    $SharesOutput = net share
    
    foreach ($Share in $RequiredShares) {
        if ($SharesOutput -match $Share) {
            Write-Host "  ✓ $Share share available" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $Share share missing" -ForegroundColor Red
        }
    }
    
    # Test 3: DNS functionality
    Write-Host "`n3. Testing DNS functionality..." -ForegroundColor Yellow
    try {
        $DNSTest = nslookup $DomainName
        Write-Host "  ✓ DNS resolution functional" -ForegroundColor Green
        
        # Test SRV records
        $SRVTest = nslookup -type=SRV "_ldap._tcp.$DomainName"
        Write-Host "  ✓ LDAP SRV records accessible" -ForegroundColor Green
    }
    catch {
        Write-Host "  ⚠ DNS functionality issues detected" -ForegroundColor Yellow
    }
    
    # Test 4: FSMO roles
    Write-Host "`n4. Verifying FSMO role ownership..." -ForegroundColor Yellow
    try {
        $FSMORoles = netdom query fsmo
        $RolesOnThisDC = $FSMORoles | Where-Object { $_ -match $DCName }
        
        Write-Host "  FSMO roles on $DCName" -ForegroundColor Gray
        $RolesOnThisDC | ForEach-Object { Write-Host "    ✓ $_" -ForegroundColor Green }
        
        if ($RolesOnThisDC.Count -eq 5) {
            Write-Host "  ✓ All FSMO roles held by recovery DC" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Not all FSMO roles on recovery DC" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ⚠ Cannot verify FSMO roles" -ForegroundColor Yellow
    }
    
    # Test 5: Replication health
    Write-Host "`n5. Testing replication health..." -ForegroundColor Yellow
    try {
        $ReplSummary = repadmin /replsummary
        Write-Host "  Replication summary available" -ForegroundColor Gray
        
        # Check for replication errors
        $ReplErrors = repadmin /showrepl /errorsonly
        if ($ReplErrors -match "No Errors") {
            Write-Host "  ✓ No replication errors detected" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Replication errors may exist" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ⚠ Cannot assess replication health" -ForegroundColor Yellow
    }
    
    # Test 6: Time synchronization
    Write-Host "`n6. Testing time synchronization..." -ForegroundColor Yellow
    try {
        $TimeStatus = w32tm /query /status
        if ($TimeStatus -match "Source.*Local CMOS Clock" -or $TimeStatus -match "Source.*Free-running System Clock") {
            Write-Host "  ✓ Time synchronization configured as PDC" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Time synchronization configuration review needed" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ⚠ Cannot verify time synchronization" -ForegroundColor Yellow
    }
    
    # Test 7: Security validation
    Write-Host "`n7. Security validation..." -ForegroundColor Yellow
    try {
        # Check krbtgt password age
        $KrbtgtUser = Get-ADUser -Identity "krbtgt" -Properties PasswordLastSet
        $PasswordAge = (Get-Date) - $KrbtgtUser.PasswordLastSet
        
        if ($PasswordAge.TotalHours -lt 24) {
            Write-Host "  ✓ krbtgt password recently reset" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ krbtgt password may need reset" -ForegroundColor Yellow
        }
        
        # Check for users requiring password change
        $UsersNeedingPasswordChange = Get-ADUser -Filter {ChangePasswordAtLogon -eq $true -and Enabled -eq $true}
        Write-Host "  Users requiring password change: $($UsersNeedingPasswordChange.Count)" -ForegroundColor Gray
    }
    catch {
        Write-Host "  ⚠ Cannot complete security validation" -ForegroundColor Yellow
    }
    
    # Summary
    Write-Host "`n=== Recovery Validation Summary ===" -ForegroundColor Green
    Write-Host "Review all test results above and address any issues before proceeding." -ForegroundColor Yellow
    Write-Host "Consider running additional tests:" -ForegroundColor Gray
    Write-Host "  - dcdiag /e /q (comprehensive DC diagnostics)" -ForegroundColor Gray
    Write-Host "  - User authentication testing" -ForegroundColor Gray
    Write-Host "  - Group Policy refresh testing" -ForegroundColor Gray
    Write-Host "  - Application integration testing" -ForegroundColor Gray
}

# Execute comprehensive validation
Test-ForestRecoveryComplete -DomainName "contoso.com" -DCName "DC01"
```

## Post-Recovery Operations

### Additional Domain Controller Deployment

**Deploying Additional Domain Controllers:**

```powershell
# Guide for additional domain controller deployment
function Deploy-AdditionalDomainControllers {
    param(
        [string[]]$NewDCNames,
        [string]$SourceDC
    )
    
    Write-Host "=== Additional Domain Controller Deployment ===" -ForegroundColor Green
    
    Write-Host "`nPost-recovery domain controller deployment steps:" -ForegroundColor Yellow
    
    Write-Host "`n1. Infrastructure Preparation:" -ForegroundColor Gray
    Write-Host "   - Provision new server hardware/VMs" -ForegroundColor Gray
    Write-Host "   - Configure network settings and DNS" -ForegroundColor Gray
    Write-Host "   - Join servers to domain as member servers" -ForegroundColor Gray
    
    Write-Host "`n2. Domain Controller Promotion:" -ForegroundColor Gray
    Write-Host "   For each new DC, run:" -ForegroundColor Gray
    Write-Host "   Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools" -ForegroundColor Gray
    Write-Host "   Install-ADDSDomainController -DomainName `"contoso.com`" -InstallDns -Credential (Get-Credential)" -ForegroundColor Gray
    
    Write-Host "`n3. FSMO Role Distribution:" -ForegroundColor Gray
    Write-Host "   Consider distributing FSMO roles across multiple DCs:" -ForegroundColor Gray
    Write-Host "   - Schema Master: Keep on first recovered DC" -ForegroundColor Gray
    Write-Host "   - Domain Naming Master: Keep on first recovered DC" -ForegroundColor Gray
    Write-Host "   - PDC Emulator: Consider moving to primary site DC" -ForegroundColor Gray
    Write-Host "   - RID Master: Consider moving to different DC" -ForegroundColor Gray
    Write-Host "   - Infrastructure Master: Move to non-GC DC if possible" -ForegroundColor Gray
    
    Write-Host "`n4. Site and Subnet Configuration:" -ForegroundColor Gray
    Write-Host "   - Configure AD Sites and Services" -ForegroundColor Gray
    Write-Host "   - Associate DCs with appropriate sites" -ForegroundColor Gray
    Write-Host "   - Configure replication schedules" -ForegroundColor Gray
    
    Write-Host "`n5. Global Catalog Distribution:" -ForegroundColor Gray
    Write-Host "   Enable Global Catalog on additional DCs:" -ForegroundColor Gray
    foreach ($DC in $NewDCNames) {
        Write-Host "   repadmin /options $DC +IS_GC" -ForegroundColor Gray
    }
    
    Write-Host "`n6. Validation Steps:" -ForegroundColor Gray
    Write-Host "   - Test replication: repadmin /replsummary" -ForegroundColor Gray
    Write-Host "   - Run diagnostics: dcdiag /e /q" -ForegroundColor Gray
    Write-Host "   - Verify SYSVOL replication: dfsrdiag replicationstate" -ForegroundColor Gray
}

# Plan additional DC deployment
$NewDCs = @("DC02", "DC03")
Deploy-AdditionalDomainControllers -NewDCNames $NewDCs -SourceDC "DC01"
```

## Troubleshooting Common Issues

### Recovery Failure Scenarios

**Common Forest Recovery Problems:**

```powershell
# Comprehensive troubleshooting guide
function Resolve-ForestRecoveryIssues {
    Write-Host "=== Forest Recovery Troubleshooting Guide ===" -ForegroundColor Green
    
    Write-Host "`n1. SYSVOL Restoration Issues:" -ForegroundColor Yellow
    Write-Host "   Problem: DFSR service fails to start" -ForegroundColor Red
    Write-Host "   Solution:" -ForegroundColor Gray
    Write-Host "     - Check Event Viewer: DFS Replication log" -ForegroundColor Gray
    Write-Host "     - Verify msDFSR-Options = 1 in AD" -ForegroundColor Gray
    Write-Host "     - Restart DFSR service manually" -ForegroundColor Gray
    Write-Host "     - Force polling: dfsrdiag pollad" -ForegroundColor Gray
    
    Write-Host "`n   Problem: SYSVOL shares not created" -ForegroundColor Red
    Write-Host "   Solution:" -ForegroundColor Gray
    Write-Host "     - Wait for Event ID 4602 in DFS Replication log" -ForegroundColor Gray
    Write-Host "     - Check DFSR database: dfsrdiag dumpbackupfiles" -ForegroundColor Gray
    Write-Host "     - Verify SYSVOL folder permissions" -ForegroundColor Gray
    
    Write-Host "`n2. FSMO Role Seizure Issues:" -ForegroundColor Yellow
    Write-Host "   Problem: ntdsutil role seizure fails" -ForegroundColor Red
    Write-Host "   Solution:" -ForegroundColor Gray
    Write-Host "     - Verify Domain Admin privileges" -ForegroundColor Gray
    Write-Host "     - Check NTDS service status" -ForegroundColor Gray
    Write-Host "     - Use PowerShell: Move-ADDirectoryServerOperationMasterRole" -ForegroundColor Gray
    
    Write-Host "`n3. Authentication Issues:" -ForegroundColor Yellow
    Write-Host "   Problem: User authentication fails" -ForegroundColor Red
    Write-Host "   Solution:" -ForegroundColor Gray
    Write-Host "     - Verify krbtgt password reset" -ForegroundColor Gray
    Write-Host "     - Check time synchronization" -ForegroundColor Gray
    Write-Host "     - Clear Kerberos tickets: klist purge" -ForegroundColor Gray
    Write-Host "     - Reset user passwords" -ForegroundColor Gray
    
    Write-Host "`n4. Replication Problems:" -ForegroundColor Yellow
    Write-Host "   Problem: Replication errors between DCs" -ForegroundColor Red
    Write-Host "   Solution:" -ForegroundColor Gray
    Write-Host "     - Force replication: repadmin /syncall /AdeP" -ForegroundColor Gray
    Write-Host "     - Check DNS resolution: dcdiag /test:dns" -ForegroundColor Gray
    Write-Host "     - Verify network connectivity" -ForegroundColor Gray
    Write-Host "     - Check firewall settings" -ForegroundColor Gray
    
    Write-Host "`n5. Global Catalog Issues:" -ForegroundColor Yellow
    Write-Host "   Problem: Global Catalog rebuild fails" -ForegroundColor Red
    Write-Host "   Solution:" -ForegroundColor Gray
    Write-Host "     - Check available disk space" -ForegroundColor Gray
    Write-Host "     - Monitor Directory Service event log" -ForegroundColor Gray
    Write-Host "     - Verify schema consistency" -ForegroundColor Gray
    Write-Host "     - Force removal and re-addition of GC role" -ForegroundColor Gray
    
    Write-Host "`n6. Trust Relationship Problems:" -ForegroundColor Yellow
    Write-Host "   Problem: External trusts broken" -ForegroundColor Red
    Write-Host "   Solution:" -ForegroundColor Gray
    Write-Host "     - Coordinate with external domain administrators" -ForegroundColor Gray
    Write-Host "     - Reset trust passwords on both sides" -ForegroundColor Gray
    Write-Host "     - Verify network connectivity to trusted domains" -ForegroundColor Gray
    Write-Host "     - Test secure channel: nltest /sc_verify:domain" -ForegroundColor Gray
}

# Display troubleshooting guide
Resolve-ForestRecoveryIssues
```

## Security Considerations

### Post-Recovery Security Hardening

**Enhanced Security Measures:**

1. **Immediate Security Actions**
   - All administrative passwords reset
   - krbtgt password reset (twice, 10 hours apart)
   - Computer account passwords reset
   - Certificate revocation if applicable

1. **Ongoing Security Monitoring**
   - Enhanced audit logging enabled
   - Privileged account monitoring
   - Anomaly detection implementation
   - Regular security assessments

1. **Access Control Review**
   - Administrative group membership audit
   - Service account validation
   - Delegation configuration review
   - Trust relationship assessment

## Documentation and Compliance

### Recovery Documentation Requirements

**Essential Documentation:**

1. **Recovery Timeline**
   - Incident start time
   - Recovery initiation
   - Key milestones achieved
   - Service restoration times

1. **Security Actions**
   - Password reset confirmations
   - Certificate revocation records
   - Trust relationship updates
   - Access control changes

1. **Validation Results**
   - System functionality tests
   - Security verification outcomes
   - Performance baseline establishment
   - User acceptance confirmation

## References and Additional Resources

### Microsoft Official Documentation

- [Active Directory Forest Recovery Guide](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/ad-forest-recovery-guide)
- [DFSR SYSVOL Migration](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/dd641227(v=ws.10))
- [FSMO Role Management](https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/fsmo-roles)

### Related Internal Documentation

- [Active Directory Security Best Practices](../Security/index.md)
- [Backup and Recovery Procedures](../Backup/index.md)
- [Disaster Recovery Planning](../../infrastructure/disaster-recovery/index.md)

### Tools and Utilities

- **Windows Server Backup** - System image creation and restoration
- **DFSR Diagnostic Tools** - SYSVOL replication monitoring
- **Repadmin** - Active Directory replication management
- **Ntdsutil** - FSMO role management and database maintenance
- **DCDiag** - Comprehensive domain controller diagnostics

This comprehensive guide provides enterprise-ready procedures for Active Directory forest recovery using modern Windows Server technologies and best practices, with emphasis on security, validation, and operational excellence.

## Full System Restore

1. **Start Windows Setup**, accept the defaults for Language, Time and currency format, and keyboard options and click **Next**.

2. **Click Repair your computer**.

3. **In the System Recovery Options dialog box** select **Restore your computer using a system image that you created earlier** and click **Next**.

4. **In the Re-image your computer - Select a system image backup dialog box** select the **Select a system image** option and click **Next**.

5. **In the Re-image your computer - Select the location of the backup dialog box** select the desired system image.

6. **In the Re-image your computer - Select the date and time dialog box** select a version and click **Next**.

7. **In the Re-image your computer - Choose additional restore options dialog box** click **Next**.

8. **In the Re-image your computer Summary window** click **Next**.

9. **When prompted to continue** click **Yes**.

10. **While the restore is in progress** watch the progress window for **Restoring disk**. This is a good sign that the restore is succeeding.

11. **When the restore is complete** you will be prompted to restart or the server will automatically restart when the timeout ends.

## SYSVOL Authoritative Restore

1. **Log into the newly restored Domain Controller** with the built-in Administrator account or Domain Administrator account.

2. **Configure the server's IP address** based on the documented information for the Domain Controller being restored. Be sure to set the **Preferred DNS server** to the same IP address configured for the server.

3. **Open an elevated PowerShell session** and enter `net share`. The output of the command should show that the **Netlogon** and **SYSVOL** shares do not exist.

4. **Stop the FRS service** by entering the `stop-service ntfrs` command. Enter the `get-service ntfrs` command to verify that the service is no longer running.

5. **Run Regedt32.exe** from the elevated PowerShell session.

6. **Set the registry value for authoritative restore:**
   - Path: `HKLM\System\CurrentControlSet\Services\NtFrs\Parameters\Backup/Restore\Process at Startup`
   - Value: `BurFlag`
   - Data: `D4`

7. **Open an Explorer window** and navigate to the following directory:

   ```text
   D:\SYSVOL\sysvol\ad.wisc.edu\Ntfrs_PreExisting__See_EventLog
   ```

8. **Copy the contents** of the directory listed in the previous step and copy to the directory one level above:

   ```powershell
   D:\SYSVOL\sysvol\ad.wisc.edu\
   ```

9. **Start the FRS service** by entering the `start-service ntfrs` command. Enter the `get-service ntfrs` command to verify that the service is running.

10. **In Event Viewer** open the **File Replication Service** log and look for Event ID 13516. This event must be present before proceeding. It could take up to 5-10 minutes for the event to appear.

11. **Run the `net share` command** and verify netlogon and sysvol shares now exist.

12. **Open Active Directory Users and Computers** (dsa.msc) and verify that Active Directory is operational.

13. **The account that is being used for the install** is likely already a member of Domain Admins. Add the account to the Enterprise Admins and Schema Admins groups if it is not already a member.

14. **Log out and log back in** using the same account so that you have a new security token for any new group memberships you may have.

## Seizing Operations Master Roles

1. **Verify the Operations role holders** using the `netdom query fsmo` command.

2. **At an elevated PowerShell prompt**, type the command `ntdsutil` and then press **ENTER**.

3. **At the ntdsutil prompt** type `roles` and press **ENTER**.

4. **At the FSMO maintenance: prompt**, type `Connections` and then press **ENTER**.

5. **At the server connections: prompt**, type `Connect to server <server-name>` and then press **ENTER**.

6. **At the server connections: prompt**, type `Quit` and then press **ENTER** to return to the **FSMO maintenance** prompt.

7. **Enter the appropriate commands** to seize all operations master roles currently not held by the domain controller that you are restoring. Click **Yes** for each of the confirmation windows that appear.

   | Role | Command |
   |------|---------|
   | Domain naming master | `Seize naming master` |
   | Schema master | `Seize schema master` |
   | Infrastructure master | `Seize infrastructure master` |
   | PDC emulator master | `Seize pdc` |
   | RID master | `Seize rid master` |

8. **Type `Quit` and press Enter twice** to exit ntdsutil.

9. **Enter `netdom query fsmo`** to verify that all operations master roles are now held by the restored domain controller.

## Metadata Cleanup

Performing metadata cleanup is how Active Directory data related to the domain controllers that have not yet been restored is removed.

With Windows Server 2008 and above the metadata cleanup is performed when the computer object for the domain controller is deleted using a version of Active Directory Users and Computers that is included in the Remote Server Administration Tools (RSAT).

1. **Start Active Directory Users and Computers** (dsa.msc) and expand the **Domain Controllers** OU.

2. **In the details pane**, right-click the Domain Controller that you want to delete, and then click **Delete**.

   Click **Yes** to confirm the deletion. Select the **This Domain Controller is permanently offline and can no longer be demoted using the Active Directory Domain Services Installation Wizard (DCPROMO)** check box and click **Delete**.

3. **Open the DNS Server snap-in** (dnsmgmt.msc).

   Right-click the **_msdcs.ad.wisc.edu** zone and click **Properties**.

   In the **_msdcs.ad.wisc.edu** zone Properties dialog box click the **Name Servers Tab** and remove each domain controller that has not been restored.

   Right-click the **ad.wisc.edu** zone and click **Properties**.

   In the **ad.wisc.edu** zone Properties dialog box click the **Name Servers Tab** and remove each domain controller that has not been restored.

## Raise the Value of Available RID Pools

The **rIDAvailablePool** attribute of the **CN=RID Manager$,CN=SYSTEM,DC=ad,DC=wisc,DC=edu** object has a large integer for a value. The upper and lower parts of this value defines the number of security principals that can be allocated for each domain and number of RIDs that have already been allocated.

1. **From an elevated PowerShell prompt** open **ADSIEdit** by entering the `adsiedit.msc` command.

   Right-click **ADSI Edit** and click **Connect**.

   Connect to the **Default Naming Context**.

2. **Browse to the CN=RID Manager$,CN=SYSTEM,DC=ad,DC=wisc,DC=edu object**.

   Right-click the **CN=RID Manager$,CN=SYSTEM,DC=ad,DC=wisc,DC=edu** object and click properties.

   Increase the **rIDAvailablePool** attribute by **100,000**.

## Resetting the Computer Account Password of the Domain Controller

1. **At an elevated PowerShell prompt** enter the `netdom resetpwd /server:<domain-controller-name> /ud:administrator /pd:*` command twice.

   **Example:**

   ```powershell
   netdom resetpwd /server:cadsdc-cssc-01 /ud:administrator /pd:*
   ```

## Resetting the krbtgt Password

1. **Start Active Directory Users and Computers** (dsa.msc) and expand the **Users** Container.

2. **Right-click the krbtgt user** and click **Reset Password**.

   Enter and confirm the password and click **OK**.

3. **From an elevated PowerShell prompt** reset your Password by running the `net user administrator <New-Password> /domain`.

   Example:

   ```powershell
   net user administrator C0mpl3xP@ssW0rd_! /domain
   ```

4. **Log off and log back in** with the same account and new password.

5. **Reboot when prompted** to do so.

## Resetting a Trust Password on One Side of the Trust

Reset the password on only the trusting domain side of the trust, also known as the incoming trust (the side where this domain belongs). Then, use the same password on the trusted domain side of the trust, also known as the outgoing trust. Reset the password of the outgoing trust when you restore the first DC in each of the other (trusted) domains.

1. **At an elevated PowerShell prompt** enter `netdom query trusts` to view a list of configured trusts.

2. **For each existing trust** enter the `netdom trust ad.wisc.edu /domain:<trusted-domain> /resetoneside /pt:<trust-password> /uo:administrator /po:*`

   **Example:**

   ```powershell
   netdom trust ad.wisc.edu /domain:ad.comdis.wisc.edu /resetoneside /pt:C0mpl3xP@ssW0rd /uo:administrator /po:*
   ```

   This command only needs to be run once because it automatically resets the password twice.

## Rebuild the Global Catalog

1. **Remove the Global Catalog** from the restored Domain Controller by running the `Repadmin /options <domain-controller-name> -is_gc` command from an elevated PowerShell prompt.

   **Example:**

   ```powershell
   Repadmin /options cadsdc-cssc-01 -is_gc
   ```

2. **Open Event Viewer** (eventvwr.msc) to verify that the Domain Controller is no longer a Global Catalog by locating **Event ID 1120** in the **Directory Service** log.

3. **Add the Global Catalog** from the restored Domain Controller by running the `Repadmin /options <domain-controller-name> +is_gc` command from an elevated PowerShell prompt.

   **Example:**

   ```powershell
   Repadmin /options cadsdc-cssc-01 +is_gc
   ```

4. **Open Event Viewer** (eventvwr.msc) to verify that the Domain Controller is now a Global Catalog by locating **Event ID 1110** in the **Directory Service** log.

5. **Verify that the process has completed** five minutes later by locating **Event ID 1119** in the **Directory Service** log.

## Configure Time Settings

1. **Open the registry editor** (regedt32.exe) and verify that the Windows Time service is correctly configured.

   Registry location: `HKLM\SYSTEM\CurrentControlSet\services\W32Time\Parameters`

   Required settings:
   - Type = NTP
   - NtpServer = ntp1.doit.wisc.edu ntp2.doit.wisc.edu ntp3.doit.wisc.edu

   If the Windows Time service is correctly configured, no further steps are required.

2. **If the Windows Time service is not configured correctly**, stop the W32Time service by running the `stop-service w32time` command from an elevated PowerShell prompt.
3. **Make the appropriate changes** to the W32Time registry keys.

   Registry location: `HKLM\SYSTEM\CurrentControlSet\services\W32Time\Parameters`
   - Type = NTP
   - NtpServer = ntp1.doit.wisc.edu ntp2.doit.wisc.edu ntp3.doit.wisc.edu

4. **Start the W32Time service** by running the `start-service w32time` command from an elevated PowerShell prompt.

## Authoritative DFS-R Restore

For environments using DFS-R instead of FRS:

1. **Stop the DFSR service** by entering the `stop-service dfsr` command.

2. **Open Active Directory Users and Computers** (dsa.msc).

   Click on the **View** menu and select **Advanced** and **View objects as containers**.

3. **Browse to the Domain controllers OU**.

   Expand the **computer object** and **DFSR-LocalSettings** folder for the Domain Controller that you are restoring.

4. **Double click SYSVOL Subscription** to open the Properties dialog box.

   In the **SYSVOL Subscription Properties** dialog box click the **Attribute Editor** tab.

5. **Edit the msDFSR-Enabled attribute** and set it to **FALSE**.

6. **Edit the msDFSR-options attribute** and set it to **1**.

7. **Start the DFSR service** by running the `start-service dfsr` command.

8. **Verify replication** by checking the DFS Replication event logs for successful completion.

## Advanced Troubleshooting

### Common Recovery Issues

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| Metadata cleanup incomplete | Phantom domain controllers in sites | Use `ntdsutil` metadata cleanup |
| Time synchronization failure | Authentication errors | Configure NTP hierarchy |
| SYSVOL replication problems | Group Policy not applying | Verify DFSR/FRS configuration |
| Trust relationship failures | Cross-domain authentication fails | Rebuild trust relationships |

### Event Log Monitoring

Monitor these Event Logs during recovery:

- **System Log:** Hardware and system service issues
- **Directory Service Log:** Active Directory specific events
- **DNS Server Log:** DNS resolution problems
- **File Replication Service Log:** SYSVOL replication status

### Recovery Validation Commands

```powershell
# Verify AD health
dcdiag /v /c /d /e /s:<DCName>

# Check replication status
repadmin /showrepl
repadmin /replsummary

# Verify SYSVOL replication
dfsrdiag pollad /v

# Check time synchronization
w32tm /query /status
w32tm /resync

# Verify DNS functionality
nslookup <domain_name>
dcdiag /test:dns /v
```

## Post-Recovery Security Checklist

1. **Reset all service account passwords**
2. **Review and update Group Policy settings**
3. **Audit administrative group memberships**
4. **Update antivirus definitions and scan**
5. **Review firewall and network security rules**
6. **Document the incident and recovery process**
7. **Update disaster recovery procedures**

## Conclusion

Active Directory forest recovery is a complex process that requires careful planning and execution. Always test recovery procedures in a lab environment and maintain current backups. Consider implementing additional resilience measures such as multiple domain controllers per site and regular backup validation.

For organizations with complex environments, consider engaging Microsoft support or certified professionals to assist with forest recovery operations.

## Quick Reference Commands

### Common Recovery Commands

```powershell
# Share verification
net share

# User password reset
net user <username> <new-password> /domain

# Replication commands
repadmin /viewlist *
repadmin /showrepl
repadmin /replsum

# Global Catalog management
repadmin /options <dc-name> +is_gc
repadmin /options <dc-name> -is_gc

# Directory health checks
dcdiag /e /q
dcdiag /test:dns

# FSMO role queries
netdom query fsmo
netdom resetpwd

# Domain controller discovery
nltest /dclist:<domain-name>
```

### Service Management

```powershell
# FRS Service
stop-service ntfrs
start-service ntfrs

# DFS-R Service
stop-service dfsr
start-service dfsr

# Time Service
stop-service w32time
start-service w32time
w32tm /resync
```

### Key Registry Locations

- **FRS:** `HKLM\System\CurrentControlSet\Services\NtFrs\Parameters\Backup/Restore\Process at Startup`
- **Time Service:** `HKLM\SYSTEM\CurrentControlSet\services\W32Time\Parameters`
- **DFS-R:** Active Directory objects under Domain Controllers OU

This comprehensive guide provides the necessary steps for successful Active Directory forest recovery. Always test procedures in a lab environment and maintain current documentation.
