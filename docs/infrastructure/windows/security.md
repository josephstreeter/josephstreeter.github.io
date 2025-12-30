---
title: Windows Server Security Quick Start
description: Essential Windows Server security hardening guide with quick wins and links to comprehensive security documentation
author: Joseph Streeter
ms.author: jstreeter
ms.date: 2024-12-30
ms.topic: quickstart
ms.service: windows-server
keywords: Windows Server security, hardening, quick start, security baseline, best practices
uid: docs.infrastructure.windows.security.quickstart
---

This quick-start guide provides essential security configurations for Windows Server. For comprehensive security documentation including advanced threat protection, compliance, and enterprise security architecture, see [Windows Infrastructure Security (Advanced)](security/index.md).

> [!TIP]
> **Time to secure**: 15-30 minutes for basic hardening
> **Skill level**: Intermediate
> **Prerequisites**: Administrator access to Windows Server

## Security Quick Wins

### 1. Initial Security Hardening (5 minutes)

Run this script immediately after installation:

```powershell
# Disable unnecessary services
$ServicesToDisable = @(
    'Fax',
    'Print Spooler',  # Only if not a print server
    'Remote Registry',
    'Windows Error Reporting Service',
    'Computer Browser'
)

foreach ($Service in $ServicesToDisable) {
    Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
}

# Configure automatic updates
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "NoAutoUpdate" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "AUOptions" -Value 4  # Auto download and schedule install
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "ScheduledInstallDay" -Value 0  # Every day
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "ScheduledInstallTime" -Value 3  # 3 AM

# Enable Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -DisableBehaviorMonitoring $false
Set-MpPreference -DisableIOAVProtection $false
Set-MpPreference -DisableScriptScanning $false
```

### 2. Configure Windows Firewall (5 minutes)

> [!CAUTION]
> Test firewall rules carefully to avoid blocking legitimate traffic. Keep a backup connection (console/ILO) available.

```powershell
# Enable firewall for all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Set default deny inbound, allow outbound
Set-NetFirewallProfile -Profile Domain -DefaultInboundAction Block -DefaultOutboundAction Allow
Set-NetFirewallProfile -Profile Public -DefaultInboundAction Block -DefaultOutboundAction Allow
Set-NetFirewallProfile -Profile Private -DefaultInboundAction Block -DefaultOutboundAction Allow

# Allow RDP (if needed)
New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound `
    -Protocol TCP -LocalPort 3389 -Action Allow -Profile Domain

# Allow WinRM for remote management
New-NetFirewallRule -DisplayName "Allow WinRM HTTP" -Direction Inbound `
    -Protocol TCP -LocalPort 5985 -Action Allow -Profile Domain
New-NetFirewallRule -DisplayName "Allow WinRM HTTPS" -Direction Inbound `
    -Protocol TCP -LocalPort 5986 -Action Allow -Profile Domain

# Enable firewall logging
Set-NetFirewallProfile -Profile Domain,Public,Private `
    -LogAllowed True -LogBlocked True `
    -LogMaxSizeKilobytes 32767 `
    -LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log"
```

For advanced firewall configuration including application-specific rules and IPSec, see [Network Security Controls](security/index.md#network-security-controls).

### 3. Secure Local Administrator Account (3 minutes)

> [!WARNING]
> Never use the built-in Administrator account for daily operations. Create a separate account and rename the default.

```powershell
# Rename built-in Administrator account
Rename-LocalUser -Name "Administrator" -NewName "ServerAdmin"

# Create decoy Administrator account (disabled)
New-LocalUser -Name "Administrator" -Description "Decoy Account" -NoPassword
Disable-LocalUser -Name "Administrator"

# Set strong password policy (if not using domain policies)
net accounts /minpwlen:14 /maxpwage:60 /minpwage:1 /uniquepw:24
```

For enterprise-scale privileged access management including tiered admin models and LAPS, see [Domain Controller Security Hardening](security/index.md#domain-controller-security-hardening).

### 4. Enable Security Auditing (5 minutes)

```powershell
# Enable advanced audit policies
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Account Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Account Management" /success:enable /failure:enable
auditpol /set /subcategory:"Directory Service Access" /success:enable /failure:enable
auditpol /set /subcategory:"Policy Change" /success:enable /failure:enable
auditpol /set /subcategory:"Privilege Use" /success:enable /failure:enable
auditpol /set /subcategory:"Object Access" /success:enable /failure:enable
auditpol /set /subcategory:"System" /success:enable /failure:enable

# Increase security log size to 1GB
wevtutil sl Security /ms:1073741824
wevtutil sl Security /rt:true  # Retain old events
```

For comprehensive security monitoring and SIEM integration, see [Endpoint Detection and Response](security/index.md#endpoint-detection-and-response-edr).

### 5. Disable SMBv1 (2 minutes)

> [!IMPORTANT]
> SMBv1 is insecure and vulnerable to ransomware. Disable it unless you have legacy systems that absolutely require it.

```powershell
# Disable SMBv1 completely
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# Configure SMB security
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
Set-SmbServerConfiguration -EnableSecuritySignature $true -Force

# Verify SMBv1 is disabled
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
```

For network security including IPSec and network segmentation, see [Network Security Controls](security/index.md#network-security-controls).

## Security Baselines by Server Role

### Domain Controller Security

**Critical actions**:

- Enable advanced audit policies ✓
- Implement privileged access workstations (PAWs)
- Configure fine-grained password policies
- Secure LDAP (enable LDAPS)
- Implement tiered administration

**Full guide**: [Domain Controller Security Hardening](security/index.md#domain-controller-security-hardening)

### File Server Security

**Critical actions**:

- Configure access-based enumeration
- Enable file screening (FSRM)
- Implement dynamic access control
- Configure audit policies for file access
- Enable SMB encryption for sensitive shares

```powershell
# Enable SMB encryption for a share
New-SmbShare -Name "SecureShare" -Path "C:\SecureData" `
    -EncryptData $true -FullAccess "Domain Admins" `
    -ReadAccess "Domain Users"
```

### Web Server Security

**Critical actions**:

- Remove unnecessary IIS features
- Configure SSL/TLS (disable weak protocols)
- Implement request filtering
- Configure URL rewrite rules
- Enable custom error pages

**Full guide**: See IIS security best practices in the comprehensive guide.

### SQL Server Security

**Critical actions**:

- Use Windows Authentication mode
- Disable SA account
- Enable encryption (TLS 1.2+)
- Configure SQL Server firewall rules
- Implement row-level security

## Password Policy Configuration

> [!IMPORTANT]
> Modern password policies should align with NIST SP 800-63B. Consider passwordless authentication where possible.

### Domain Password Policy

```powershell
# Configure default domain password policy
Set-ADDefaultDomainPasswordPolicy -Identity "contoso.local" `
    -MinPasswordLength 14 `
    -ComplexityEnabled $true `
    -MaxPasswordAge (New-TimeSpan -Days 90) `
    -MinPasswordAge (New-TimeSpan -Days 1) `
    -PasswordHistoryCount 24 `
    -LockoutDuration (New-TimeSpan -Minutes 30) `
    -LockoutObservationWindow (New-TimeSpan -Minutes 30) `
    -LockoutThreshold 5
```

### Fine-Grained Password Policy (for privileged accounts)

```powershell
# Create stricter policy for admins
New-ADFineGrainedPasswordPolicy -Name "AdminPasswordPolicy" `
    -MinPasswordLength 16 `
    -ComplexityEnabled $true `
    -MaxPasswordAge (New-TimeSpan -Days 60) `
    -MinPasswordAge (New-TimeSpan -Days 1) `
    -PasswordHistoryCount 24 `
    -LockoutDuration (New-TimeSpan -Minutes 30) `
    -LockoutObservationWindow (New-TimeSpan -Minutes 30) `
    -LockoutThreshold 3 `
    -Precedence 10

# Apply to Domain Admins
Add-ADFineGrainedPasswordPolicySubject -Identity "AdminPasswordPolicy" `
    -Subjects "Domain Admins"
```

For advanced password policies and passwordless authentication, see [Domain Controller Security](security/index.md#domain-controller-security-hardening).

## SSL/TLS Configuration

> [!WARNING]
> Modifying SSL/TLS settings can break applications. Test in non-production first and document all changes.

```powershell
# Disable weak protocols
$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"

# Disable SSL 2.0 and 3.0
foreach ($Protocol in @("SSL 2.0", "SSL 3.0")) {
    New-Item -Path "$RegPath\$Protocol\Server" -Force | Out-Null
    Set-ItemProperty -Path "$RegPath\$Protocol\Server" -Name "Enabled" -Value 0
}

# Disable TLS 1.0 and 1.1
foreach ($Protocol in @("TLS 1.0", "TLS 1.1")) {
    New-Item -Path "$RegPath\$Protocol\Server" -Force | Out-Null
    Set-ItemProperty -Path "$RegPath\$Protocol\Server" -Name "Enabled" -Value 0
}

# Enable TLS 1.2 and 1.3
foreach ($Protocol in @("TLS 1.2", "TLS 1.3")) {
    New-Item -Path "$RegPath\$Protocol\Server" -Force | Out-Null
    Set-ItemProperty -Path "$RegPath\$Protocol\Server" -Name "Enabled" -Value 1
}

# Configure strong cipher suites
$CipherSuites = @(
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384",
    "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
)
$CipherSuiteOrder = $CipherSuites -join ","
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002" `
    -Name "Functions" -Value $CipherSuiteOrder
```

For certificate services and PKI implementation, see [Advanced Security Guide](security/index.md).

## Security Monitoring Essentials

### Critical Events to Monitor

```powershell
# Create alert for failed logon attempts
$Query = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">
      *[System[(EventID=4625)]]
    </Select>
  </Query>
</QueryList>
"@

# Check for failed logons in last 24 hours
Get-WinEvent -FilterXml $Query -MaxEvents 50 | 
    Where-Object {$_.TimeCreated -gt (Get-Date).AddHours(-24)} |
    Select-Object TimeCreated, Message | Format-Table -AutoSize
```

**Critical Event IDs to monitor**:

- **4624**: Successful logon
- **4625**: Failed logon attempt
- **4648**: Logon with explicit credentials
- **4672**: Special privileges assigned
- **4720**: User account created
- **4726**: User account deleted
- **4740**: User account locked
- **4767**: User account unlocked

For automated monitoring and incident response, see [Endpoint Detection and Response](security/index.md#endpoint-detection-and-response-edr).

## Compliance Quick Check

### CIS Benchmark Critical Controls

```powershell
# Quick CIS compliance check script
function Test-CISCompliance {
    $Results = @{}
    
    # Check if guest account is disabled
    $Guest = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
    $Results.GuestDisabled = if ($Guest) { $Guest.Enabled -eq $false } else { $null }
    
    # Check if Windows Firewall is enabled
    $Firewall = Get-NetFirewallProfile
    $Results.FirewallEnabled = ($Firewall | Where-Object Enabled -eq $false).Count -eq 0
    
    # Check if Windows Defender is running
    $Defender = Get-MpComputerStatus
    $Results.DefenderEnabled = $Defender.RealTimeProtectionEnabled
    
    # Check if SMBv1 is disabled
    $SMB1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
    $Results.SMBv1Disabled = $SMB1.State -eq "Disabled"
    
    # Check audit policies
    $AuditPolicies = auditpol /get /category:* | Select-String "Success and Failure"
    $Results.AuditPoliciesConfigured = $AuditPolicies.Count -gt 5
    
    return [PSCustomObject]$Results
}

# Run compliance check
Test-CISCompliance | Format-List
```

For full CIS and STIG compliance implementation, see [Compliance and Audit Framework](security/index.md#compliance-and-audit-framework).

## Next Steps

### Immediate Actions (Today)

1. ✅ Run initial security hardening script (5 min)
2. ✅ Enable Windows Firewall (5 min)
3. ✅ Secure local administrator account (3 min)
4. ✅ Enable security auditing (5 min)
5. ✅ Disable SMBv1 (2 min)

**Total time**: ~20 minutes

### This Week

- Review and configure SSL/TLS settings
- Implement password policies
- Set up security monitoring
- Document security baseline
- Test disaster recovery procedures

### This Month

- Implement privileged access management
- Deploy Group Policy security baseline
- Configure BitLocker encryption
- Conduct security assessment
- Train administrators on security practices

## Essential Documentation

### Quick Reference Guides

- **[Configuration Overview](configuration.md)** - Basic Windows configuration
- **[Configuration Management](configuration-management.md)** - PowerShell automation and DSC

### Comprehensive Security Documentation

- **[Windows Infrastructure Security (Advanced)](security/index.md)** - Complete security guide including:
  - Domain controller hardening
  - Privileged access management
  - Advanced threat protection
  - Compliance frameworks (CIS, STIG)
  - Network security (IPSec, network segmentation)
  - Certificate services and PKI
  - BitLocker and data protection
  - Incident response procedures

### Server Administration

- **[Windows Server Index](index.md)** - Server roles and features overview

### External Resources

- **[Microsoft Security Baselines](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-security-baselines)**
- **[CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)**
- **[NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)**

---

This quick-start guide provides the minimum essential security configurations. For production environments, comprehensive security requires implementing all controls in the [Advanced Security Guide](security/index.md).
