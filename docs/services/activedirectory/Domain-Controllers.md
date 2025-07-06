---
title: "Domain Controllers - Configuration and Security Standards"
description: "Comprehensive guide for configuring and securing Active Directory Domain Controllers with modern best practices for enterprise environments"
author: "Enterprise IT Documentation"
ms.author: "itdocs"
ms.date: "2024-01-15"
ms.topic: "conceptual"
ms.service: "active-directory"
keywords: ["Active Directory", "Domain Controllers", "Security", "Configuration", "IPSec", "Replication", "Windows Server"]
---

## Domain Controllers - Configuration and Security Standards

A Domain Controller (DC) is a server that responds to authentication and authorization requests within the domain. Domain Controllers should be dedicated servers that perform only domain controller and DNS server functions for optimal security and performance.

## Prerequisites and Planning

Before deploying domain controllers, ensure the following prerequisites are met:

- **Hardware Requirements**: Minimum 4 CPU cores, 8GB RAM, sufficient storage for OS, database, and logs
- **Network Configuration**: Static IP addresses, proper DNS configuration, network connectivity to other DCs
- **Operating System**: Supported Windows Server version (2019, 2022) with latest updates
- **Security Planning**: Certificate infrastructure, IPSec policies, firewall rules
- **Backup Strategy**: System state backup procedures and recovery plans

## Domain Controller Configuration Standards

Domain Controllers within Active Directory should be configured per the following guidelines.

### Storage Configuration Recommendations

For physical and virtualized environments, domain controllers should have separate volumes optimized for different workloads:

- **System Volume**: >80GB for OS and applications
- **Database Volume**: >25GB for NTDS database (larger for extensive directories)
- **Log Volume**: >4GB for transaction logs

Separating database files from the system drive prevents the operating system from disabling write caching on the system drive and reduces the risk of system file corruption during unexpected shutdowns. For optimal performance, log files should be placed on dedicated storage with appropriate IOPS capabilities.

#### Physical Server Storage Layout

| Volume | Purpose | Recommended Size | Performance Requirements |
|--------|---------|------------------|-------------------------|
| C: | Operating System | 80GB+ | Standard performance |
| D: | NTDS Database | 25GB+ | High IOPS, fast reads |
| E: | Log Files | 4GB+ | High IOPS, fast writes |

#### Virtual Machine Storage Configuration

For VMware environments, follow these guidelines:

| Controller | Virtual Disk | Purpose | Size |
|------------|-------------|---------|------|
| SCSI 0:0 | System Drive (C:) | OS and Applications | 80GB+ |
| SCSI 1:0 | Database Drive (D:) | NTDS Database | 25GB+ |
| SCSI 1:1 | Log Drive (E:) | Transaction Logs | 4GB+ |

**File Location Mapping:**

| Component | Recommended Location |
|-----------|---------------------|
| NTDS Database | D:\NTDS |
| SYSVOL | D:\SYSVOL |
| Transaction Logs | E:\Logs |

> [!TIP]
> For cloud environments (Azure, AWS), use premium storage tiers for database and log volumes to ensure adequate IOPS and low latency.

### Active Directory Replication

#### Secure Replication over IPSec

Modern Active Directory environments should implement secure replication between domain controllers. RPC replication traditionally requires many ports to be opened in firewalls, creating potential security vulnerabilities. To enhance security, configure replication to use static ports and encrypt traffic with IPSec.

##### Configuring Static Ports for Replication

Use PowerShell to configure static ports for AD replication services:

```powershell
# Configure static RPC port for Active Directory
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "TCP/IP Port" -Value 50000 -Type DWord

# Configure static DFSR port
dfsrdiag StaticRPC /port:50001 /Member:$env:COMPUTERNAME

# Restart services to apply changes
Restart-Service NTDS -Force
Restart-Service DFSR -Force
```

##### Alternative: Windows Server 2022 Secure RPC

For Windows Server 2022 and later, consider using the built-in secure RPC authentication instead of IPSec:

```powershell
# Enable secure RPC for AD replication
Set-ADReplicationSite -Identity "Default-First-Site-Name" -ManagedBy "Domain Admins" -EncryptionMethod AES256
```

#### IPSec Configuration for Legacy Environments

> [!WARNING]
> IPSec policies should be applied locally to avoid potentially isolating domain controllers from replication. Test thoroughly in a non-production environment before implementation.

##### IPSec Policy Configuration

**Main Policy Settings:**

| Setting | Value | Purpose |
|---------|-------|---------|
| Policy Name | Domain Controllers | Identifies the IPSec policy |
| Default Response Rule | Disabled | Prevents unintended blocking |
| Check for Policy Changes | 180 minutes | Policy refresh interval |
| Master Key PFS | Disabled | Performance optimization |
| Key Regeneration | 480 minutes / 0 sessions | Security vs performance balance |
| IKE Security Methods | AES256/SHA256/DH Group 14 | Modern cryptographic standards |

**IPSec Rules Configuration:**

| Rule Name | Description | Mode | IP Filter List | Filter Action | Authentication |
|-----------|-------------|------|----------------|---------------|----------------|
| DC Replication | Inter-DC replication traffic | Transport | DC_Replication_Ports | ESP-AES256-SHA256 | Kerberos |

**IP Filter List Configuration:**

| Filter Name | Source | Destination | Protocol | Source Port | Destination Port | Mirrored |
|-------------|--------|-------------|----------|-------------|-----------------|----------|
| AD_RPC | My IP | Any | TCP | Any | 50000 | Yes |
| DFSR | My IP | Any | TCP | Any | 50001 | Yes |
| DNS | My IP | Any | TCP/UDP | Any | 53 | Yes |
| Kerberos | My IP | Any | TCP/UDP | Any | 88 | Yes |
| LDAP | My IP | Any | TCP | Any | 389 | Yes |
| LDAPS | My IP | Any | TCP | Any | 636 | Yes |
| Global Catalog | My IP | Any | TCP | Any | 3268 | Yes |

##### IPSec Filter Actions

| Action Name | Description | Security Method | Encryption | Authentication | Session Lifetime |
|-------------|-------------|-----------------|------------|----------------|------------------|
| ESP-AES256-SHA256 | Require AES256 encryption with SHA256 authentication | Custom ESP | AES256 | SHA256 | 3600 seconds |

> [!NOTE]
> Modern implementations should use AES256 and SHA256 instead of legacy 3DES and MD5/SHA1 for better security.

### Firewall Configuration

Modern domain controllers require specific network ports for proper operation. The following table provides comprehensive port requirements for domain controller services:

#### Required Ports for Domain Controller Services

| Service | Port/Protocol | Direction | Purpose | Security Notes |
|---------|---------------|-----------|---------|----------------|
| RPC Endpoint Mapper | 135/TCP | Inbound | Service discovery | Required for all RPC operations |
| RPC Dynamic (Legacy) | 1024-65535/TCP | Inbound | Dynamic RPC endpoints | Use static ports instead |
| RPC Static (Recommended) | 50000/TCP | Inbound | AD replication | Configured via registry |
| DFSR Static | 50001/TCP | Inbound | SYSVOL replication | Configured via dfsrdiag |
| Kerberos | 88/TCP, 88/UDP | Bidirectional | Authentication | Configure TCP-only for security |
| Kerberos Password Change | 464/TCP, 464/UDP | Bidirectional | Password changes | Required for domain operations |
| LDAP | 389/TCP | Inbound | Directory queries | Consider LDAPS instead |
| LDAPS (Secure) | 636/TCP | Inbound | Encrypted directory queries | Preferred over LDAP |
| Global Catalog | 3268/TCP | Inbound | Forest-wide queries | Required for multi-domain forests |
| Global Catalog SSL | 3269/TCP | Inbound | Encrypted GC queries | Preferred for security |
| AD Web Services | 9389/TCP | Inbound | PowerShell AD module | Required for modern management |
| SMB | 445/TCP | Inbound | File sharing (SYSVOL, NETLOGON) | Block legacy NetBIOS ports |
| DNS | 53/TCP, 53/UDP | Bidirectional | Name resolution | Critical for AD operation |
| WinRM | 5985/TCP | Inbound | Remote management | Use HTTPS (5986) in production |
| WinRM HTTPS | 5986/TCP | Inbound | Secure remote management | Preferred for production |
| Remote Desktop | 3389/TCP | Inbound | Remote administration | Restrict to admin networks |
| NetBIOS Name Service | 137/TCP, 137/UDP | Block | Legacy name resolution | Not used in modern AD |
| NetBIOS Datagram | 138/UDP | Block | Legacy service | Not used in modern AD |
| NetBIOS Session | 139/TCP | Block | Legacy file sharing | Use SMB (445) instead |
| IKE | 500/UDP | Bidirectional | IPSec key exchange | For encrypted replication |
| IPSec NAT-T | 4500/UDP | Bidirectional | IPSec through NAT | When NAT devices present |
| ESP | IP Protocol 50 | Bidirectional | IPSec data encryption | Required for IPSec traffic |

#### Firewall Rule Examples

**Windows Firewall with Advanced Security:**

```powershell
# Enable required inbound rules for domain controller
New-NetFirewallRule -DisplayName "Domain Controller - LDAPS" -Direction Inbound -Protocol TCP -LocalPort 636 -Action Allow -Profile Domain
New-NetFirewallRule -DisplayName "Domain Controller - Global Catalog SSL" -Direction Inbound -Protocol TCP -LocalPort 3269 -Action Allow -Profile Domain
New-NetFirewallRule -DisplayName "Domain Controller - AD Replication" -Direction Inbound -Protocol TCP -LocalPort 50000 -Action Allow -Profile Domain
New-NetFirewallRule -DisplayName "Domain Controller - DFSR" -Direction Inbound -Protocol TCP -LocalPort 50001 -Action Allow -Profile Domain

# Block legacy NetBIOS ports
New-NetFirewallRule -DisplayName "Block NetBIOS Name Service" -Direction Inbound -Protocol TCP -LocalPort 137 -Action Block
New-NetFirewallRule -DisplayName "Block NetBIOS Datagram" -Direction Inbound -Protocol UDP -LocalPort 138 -Action Block
New-NetFirewallRule -DisplayName "Block NetBIOS Session" -Direction Inbound -Protocol TCP -LocalPort 139 -Action Block
```

**Third-Party Firewall Configuration:**

For enterprise firewalls (Palo Alto, Fortinet, etc.), create application-based rules when possible:

```text
# Example firewall rules (generic syntax)
allow tcp from domain-controllers to domain-controllers port 50000   # AD Replication
allow tcp from domain-controllers to domain-controllers port 50001   # DFSR
allow tcp from domain-controllers to domain-controllers port 636     # LDAPS
allow tcp from domain-controllers to domain-controllers port 3269    # GC SSL
allow udp from domain-controllers to domain-controllers port 88      # Kerberos
allow tcp/udp from clients to domain-controllers port 53             # DNS
```

> [!WARNING]
> IPSec does not work through Network Address Translation (NAT) devices. IPSec uses IP addresses when computing packet checksums, and packets whose source addresses are altered by NAT are discarded at the destination.

> [!TIP]
> Configure Kerberos to use TCP-only and block UDP to improve security and reduce potential attack vectors. This can be configured via Group Policy.

## Security Configuration Standards

### Basic Security Requirements

- Servers must be installed with a currently supported Operating System with all the latest Service Packs and patches applied
- Servers must have enterprise antivirus installed with current definitions and real-time protection enabled
- Domain Controller computer objects are automatically created in the root of the "Domain Controllers" OU and should not be moved
- Domain Controllers should not be multi-homed (multiple network interfaces should be avoided)
- DNS settings: Primary DNS entry should point to itself, secondary DNS entry should point to another domain controller in the same site
- Domain suffixes should be added to network interfaces for each domain in the forest
- A scheduled task should perform daily System State backups with retention policies
- Enterprise security templates and Group Policies must be applied consistently

### Backup and Recovery Requirements

```powershell
# Create daily system state backup task
$BackupAction = New-ScheduledTaskAction -Execute "wbadmin.exe" -Argument "start systemstatebackup -backupTarget:E:\Backups -quiet"
$BackupTrigger = New-ScheduledTaskTrigger -Daily -At "2:00 AM"
$BackupSettings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -StartWhenAvailable
Register-ScheduledTask -TaskName "Daily System State Backup" -Action $BackupAction -Trigger $BackupTrigger -Settings $BackupSettings -RunLevel Highest
```

## Advanced Security Policies

The following security settings implement modern security best practices for Active Directory domain controllers.

### LDAP Signing and Encryption Requirements

**Requirement**: All domain controllers must be configured to require signed and encrypted LDAP communications.

**Implementation**:

```powershell
# Configure LDAP server signing requirements
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "LDAPServerIntegrity" -Value 2 -Type DWord

# Configure LDAP client signing requirements  
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\ldap" -Name "LDAPClientIntegrity" -Value 2 -Type DWord

# Restart NTDS service to apply changes
Restart-Service NTDS -Force
```

**Impact Considerations**:

- All LDAP clients must support signing and encryption
- Legacy devices (printers, appliances) may require reconfiguration or replacement
- Test thoroughly before implementing in production

### Authentication Protocol Security

**Requirement**: Eliminate legacy authentication protocols and enforce modern secure authentication.

**LAN Manager Authentication Level Configuration**:

```powershell
# Set authentication level to NTLMv2 and Kerberos only
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel" -Value 5 -Type DWord

# Disable LM hash storage
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "NoLMHash" -Value 1 -Type DWord
```

**Authentication Levels Explained**:

- Level 5: Send NTLMv2 response only, refuse LM and NTLM
- This eliminates weak LM and NTLM protocols while maintaining compatibility

**Legacy Protocol Elimination**:

```powershell
# Disable SMBv1 (security risk)
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

# Configure Kerberos to use AES encryption
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters" -Name "SupportedEncryptionTypes" -Value 24 -Type DWord
```

### Network Interface Security

**IPv6 Configuration**:

- Evaluate IPv6 requirements for your environment
- If not using IPv6, disable it properly (not just unbind)
- Consider IPv6 for future-proofing and security features

```powershell
# Properly disable IPv6 if not in use (requires reboot)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xFF -Type DWord

# Configure DNS settings programmatically
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "127.0.0.1","<Secondary_DC_IP>"
```

**DNS Search Suffix Configuration**:

```powershell
# Configure DNS suffixes for domain resolution
$suffixes = @("contoso.com", "subdomain.contoso.com", "partners.contoso.com")
Set-DnsClientGlobalSetting -SuffixSearchList $suffixes
```

### Update Management

**Windows Update Configuration**:

```powershell
# Configure Windows Update to prevent simultaneous reboots
$updateConfig = @{
    "AUOptions" = 4  # Download and schedule install
    "ScheduledInstallDay" = 1  # Sunday = 1, Monday = 2, etc.
    "ScheduledInstallTime" = 3  # 3 AM
    "RescheduleWaitTime" = 60  # Reschedule failed installs after 60 minutes
}

foreach ($setting in $updateConfig.GetEnumerator()) {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name $setting.Key -Value $setting.Value -Type DWord
}
```

### User Rights Assignment Security

**Critical User Rights Configuration**:

```powershell
# Configure critical user rights (requires Security Policy module)
Import-Module SecurityPolicy

# Allow logon as a service (for service accounts only)
Grant-UserRight -Account "NT SERVICE\*" -Right "SeServiceLogonRight"

# Deny interactive logon to service accounts
Revoke-UserRight -Account "Domain Users" -Right "SeInteractiveLogonRight"
Grant-UserRight -Account "Domain Admins" -Right "SeInteractiveLogonRight"

# Backup and restore privileges
Grant-UserRight -Account "Backup Operators" -Right "SeBackupPrivilege"
Grant-UserRight -Account "Backup Operators" -Right "SeRestorePrivilege"
```

**Security Baseline Compliance**:

Follow industry security baselines:

- CIS (Center for Internet Security) Controls
- Microsoft Security Compliance Toolkit
- DISA STIG (Defense Information Systems Agency)

```powershell
# Download and apply Microsoft Security Baseline
# This should be done through Group Policy in production
Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/details.aspx?id=55319" -OutFile "SecurityBaseline.zip"
```

### Role Separation and Least Privilege

**Domain Controller Role Restrictions**:

- Domain controllers should only run AD DS and DNS services
- No additional server roles (file server, print server, web server, etc.)
- Dedicated service accounts for each service
- Regular audit of installed software and services

```powershell
# Audit installed server roles and features
Get-WindowsFeature | Where-Object {$_.InstallState -eq "Installed"} | Select-Object Name, DisplayName

# Remove unnecessary features (example)
Remove-WindowsFeature -Name "Web-Server" -Remove
```

### Static Port Configuration

**RPC and DFSR Static Ports**:

```powershell
# Configure static ports for RPC and DFSR
function Set-ADStaticPorts {
    param(
        [int]$RPCPort = 50000,
        [int]$DFSRPort = 50001
    )
    
    # Set RPC static port
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "TCP/IP Port" -Value $RPCPort -Type DWord
    
    # Set DFSR static port
    dfsrdiag StaticRPC /port:$DFSRPort /Member:$env:COMPUTERNAME
    
    # Restart services
    Restart-Service NTDS -Force
    Restart-Service DFSR -Force
    
    Write-Output "Static ports configured: RPC=$RPCPort, DFSR=$DFSRPort"
}

# Apply static port configuration
Set-ADStaticPorts
```

## Remote Management Security

### Secure Remote Desktop Configuration

**Enhanced RDP Security**:

```powershell
# Configure secure RDP settings
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "SecurityLayer" -Value 2
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "fEnableWinStation" -Value 1

# Enable RDP firewall rule for domain networks only
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -Profile Domain
Disable-NetFirewallRule -DisplayGroup "Remote Desktop" -Profile Public,Private
```

### Windows Remote Management (WinRM) Configuration

**Secure WinRM Setup**:

```powershell
# Configure WinRM for HTTPS
# First, ensure a proper SSL certificate is installed
$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*$env:COMPUTERNAME*"}

if ($cert) {
    # Configure HTTPS listener
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="$env:COMPUTERNAME"; CertificateThumbprint="$($cert.Thumbprint)"}
    
    # Configure WinRM service
    Set-WSManInstance -ResourceURI winrm/config/service -ValueSet @{
        MaxConcurrentOperationsPerUser = "100"
        MaxConnections = "25"
        AllowUnencrypted = "false"
        Auth = @{
            Basic = "false"
            Kerberos = "true"
            Negotiate = "true"
            Certificate = "true"
            CredSSP = "false"
        }
    }
    
    # Start and configure WinRM service
    Start-Service WinRM
    Set-Service WinRM -StartupType Automatic
    
    Write-Output "WinRM configured for secure HTTPS access"
} else {
    Write-Warning "No suitable SSL certificate found. Install a certificate first."
}
```

## Monitoring and Compliance

### Security Monitoring

**Event Log Configuration**:

```powershell
# Configure security event log size and retention
wevtutil sl Security /ms:1073741824  # 1GB max size
wevtutil sl Security /rt:false       # Archive when full

# Enable advanced audit policies
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Directory Service Access" /success:enable /failure:enable
```

### Compliance Verification

**Regular Security Audits**:

```powershell
# Create security audit script
function Invoke-DCSecurityAudit {
    $report = @()
    
    # Check LDAP signing configuration
    $ldapSigning = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "LDAPServerIntegrity" -ErrorAction SilentlyContinue
    $report += [PSCustomObject]@{
        Check = "LDAP Signing"
        Status = if ($ldapSigning.LDAPServerIntegrity -eq 2) { "Compliant" } else { "Non-Compliant" }
        Value = $ldapSigning.LDAPServerIntegrity
    }
    
    # Check LM Hash storage
    $lmHash = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "NoLMHash" -ErrorAction SilentlyContinue
    $report += [PSCustomObject]@{
        Check = "LM Hash Disabled"
        Status = if ($lmHash.NoLMHash -eq 1) { "Compliant" } else { "Non-Compliant" }
        Value = $lmHash.NoLMHash
    }
    
    # Check authentication level
    $authLevel = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel" -ErrorAction SilentlyContinue
    $report += [PSCustomObject]@{
        Check = "Authentication Level"
        Status = if ($authLevel.LmCompatibilityLevel -ge 5) { "Compliant" } else { "Non-Compliant" }
        Value = $authLevel.LmCompatibilityLevel
    }
    
    return $report
}

# Run security audit
Invoke-DCSecurityAudit | Format-Table -AutoSize
```

## Troubleshooting and Verification

### Common Issues and Solutions

**LDAP Signing Issues**:

- **Problem**: Clients cannot authenticate after enabling LDAP signing
- **Solution**: Update client LDAP libraries or configure client-side signing
- **Verification**: Use `ldp.exe` to test LDAP connectivity with signing

**Authentication Protocol Issues**:

- **Problem**: Legacy applications fail after disabling NTLM
- **Solution**: Identify applications using NTLM and update or configure for Kerberos
- **Tools**: Use `netsh trace` and Event Viewer to identify NTLM usage

**Static Port Configuration**:

- **Problem**: Replication fails after configuring static ports
- **Solution**: Verify firewall rules allow the configured ports
- **Verification**: Use `portqry` to test port connectivity

### Verification Commands

```powershell
# Verify AD replication health
repadmin /replsummary
repadmin /showrepl

# Test LDAP connectivity with signing
ldp.exe  # Use GUI to test LDAP bind with signing required

# Verify Kerberos functionality
klist tickets
nltest /sc_verify:domain.com

# Check static port configuration
netstat -an | findstr :50000
netstat -an | findstr :50001
```

### Performance Monitoring

```powershell
# Key performance counters for domain controllers
$counters = @(
    "\NTDS\DRA Inbound Values (DNs only)/sec"
    "\NTDS\DRA Outbound Values (DNs only)/sec"
    "\NTDS\LDAP Searches/sec"
    "\NTDS\LDAP Successful Binds/sec"
    "\Database ==> Instances(lsass/NTDSA)\Database Cache % Hit"
)

# Collect performance data
Get-Counter -Counter $counters -SampleInterval 5 -MaxSamples 12
```

## Best Practices Summary

1. **Security First**: Implement defense-in-depth with multiple security layers
2. **Regular Updates**: Maintain current patch levels and security updates
3. **Monitoring**: Implement comprehensive logging and monitoring
4. **Testing**: Test all changes in non-production environments first
5. **Documentation**: Maintain current documentation of configurations and procedures
6. **Backup**: Ensure reliable backup and recovery procedures
7. **Compliance**: Regular audits against security baselines
8. **Segregation**: Keep domain controllers dedicated to AD DS and DNS only

## Additional Resources

- [Microsoft Security Compliance Toolkit](https://www.microsoft.com/en-us/download/details.aspx?id=55319)
- [CIS Controls for Active Directory](https://www.cisecurity.org/controls/)
- [Active Directory Security Best Practices](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/)
- [DISA STIG for Windows Server](https://public.cyber.mil/stigs/)
