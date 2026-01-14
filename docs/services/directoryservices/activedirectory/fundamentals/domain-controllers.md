---
title: "Active Directory Domain Controllers"
description: "Comprehensive guide to Active Directory Domain Controller deployment, management, and best practices"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---: "Active Directory Domain Controllers"
description: "Comprehensive guide to Active Directory Domain Controller deployment, management, and best practices"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Active Directory Domain Controllers

Domain Controllers (DCs) are the backbone of Active Directory infrastructure. They host the Active Directory Domain Services (AD DS) role and provide authentication, authorization, and directory services to clients in the domain.

## Domain Controller Fundamentals

### What is a Domain Controller?

A Domain Controller is a Windows Server that:

- **Hosts Active Directory** - Stores the directory database
- **Authenticates users** - Validates login credentials
- **Authorizes access** - Controls resource permissions
- **Replicates data** - Synchronizes with other domain controllers
- **Provides Global Catalog** - Enables forest-wide searches

### Types of Domain Controllers

- **Read-Write Domain Controller (RWDC)** - Full AD database with write permissions
- **Read-Only Domain Controller (RODC)** - Read-only copy for branch offices
- **Global Catalog Server** - Contains partial replica of all domains in forest
- **Primary Domain Controller (PDC) Emulator** - FSMO role holder with special functions

## Planning Domain Controller Deployment

### Sizing Requirements

Hardware recommendations based on organization size:

```powershell
# Small Organization (< 1,000 users)
$SmallOrgSpecs = @{
    CPU = "4 cores"
    RAM = "8 GB"
    Storage = "200 GB SSD"
    Network = "1 Gbps"
}

# Medium Organization (1,000 - 10,000 users)
$MediumOrgSpecs = @{
    CPU = "8 cores"
    RAM = "16 GB"
    Storage = "500 GB SSD"
    Network = "10 Gbps"
}

# Large Organization (> 10,000 users)
$LargeOrgSpecs = @{
    CPU = "16+ cores"
    RAM = "32+ GB"
    Storage = "1+ TB SSD"
    Network = "10 Gbps"
}
```

### Placement Strategy

Consider these factors for DC placement:

- **Geographic distribution** - Place DCs close to users
- **Network connectivity** - Ensure reliable WAN links
- **Physical security** - Secure server locations
- **Redundancy** - Multiple DCs per site for availability
- **Backup strategy** - Off-site backup capabilities

### Site Design

Configure sites for optimal replication:

```powershell
# Create new site
New-ADReplicationSite -Name "Branch-Office-1"

# Create subnet
New-ADReplicationSubnet -Name "192.168.100.0/24" -Site "Branch-Office-1"

# Create site link
New-ADReplicationSiteLink -Name "Main-to-Branch1" -SitesIncluded "Default-First-Site-Name", "Branch-Office-1" -Cost 100 -ReplicationFrequencyInMinutes 180
```

## Installing Domain Controllers

### First Domain Controller (New Forest)

Creating a new Active Directory forest:

```powershell
# Install AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Import AD deployment module
Import-Module ADDSDeployment

# Create new forest
Install-ADDSForest `
    -DomainName "contoso.com" `
    -DomainNetbiosName "CONTOSO" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns:$true `
    -DatabasePath "C:\NTDS" `
    -LogPath "C:\NTDS" `
    -SysvolPath "C:\SYSVOL" `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "ComplexPassword123!" -AsPlainText -Force) `
    -Force
```

### Additional Domain Controller

Adding a DC to existing domain:

```powershell
# Join server to domain first
Add-Computer -DomainName "contoso.com" -Credential (Get-Credential) -Restart

# Install AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to domain controller
Install-ADDSDomainController `
    -DomainName "contoso.com" `
    -InstallDns:$true `
    -DatabasePath "C:\NTDS" `
    -LogPath "C:\NTDS" `
    -SysvolPath "C:\SYSVOL" `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "ComplexPassword123!" -AsPlainText -Force) `
    -Credential (Get-Credential) `
    -Force
```

### Read-Only Domain Controller (RODC)

For branch offices with limited security:

```powershell
# Install RODC
Install-ADDSDomainController `
    -DomainName "contoso.com" `
    -ReadOnlyReplica:$true `
    -SiteName "Branch-Office-1" `
    -InstallDns:$true `
    -DatabasePath "C:\NTDS" `
    -LogPath "C:\NTDS" `
    -SysvolPath "C:\SYSVOL" `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "ComplexPassword123!" -AsPlainText -Force) `
    -Credential (Get-Credential) `
    -Force
```

## Domain Controller Configuration

### Global Catalog Configuration

Configure Global Catalog servers:

```powershell
# Enable Global Catalog on DC
$Server = Get-ADDomainController -Identity "DC01"
Set-ADObject -Identity $Server.NTDSSettingsObjectDN -Replace @{options = 1}

# Verify Global Catalog status
Get-ADDomainController -Filter * | Select-Object Name, IsGlobalCatalog
```

### DNS Configuration

Configure DNS settings for AD integration:

```powershell
# Configure DNS forwarders
Add-DnsServerForwarder -IPAddress 8.8.8.8, 8.8.4.4

# Enable DNS scavenging
Set-DnsServerScavenging -ScavengingState $true -ScavengingInterval 7:00:00:00

# Configure aging for zones
Set-DnsServerZoneAging -Name "contoso.com" -Aging $true -RefreshInterval 7:00:00:00 -NoRefreshInterval 7:00:00:00
```

### Time Synchronization

Configure reliable time sources:

```powershell
# Configure PDC emulator as authoritative time source
w32tm /config /manualpeerlist:"time.windows.com,0x1" /syncfromflags:manual /reliable:yes /update

# Configure other DCs to sync from domain hierarchy
w32tm /config /syncfromflags:domhier /update

# Start time service
Start-Service w32time

# Force time sync
w32tm /resync /force
```

## Domain Controller Maintenance

### Health Monitoring

Monitor DC health with built-in tools:

```powershell
# Check replication status
repadmin /showrepl

# Test domain controller
dcdiag /c /v

# Check Active Directory database
ntdsutil "activate instance ntds" "files" "info" quit quit

# Monitor event logs
Get-WinEvent -LogName "Directory Service" -MaxEvents 50 | Where-Object {$_.LevelDisplayName -eq "Error"}
```

### Performance Monitoring

Key performance counters to monitor:

```powershell
# NTDS performance counters
$NTDSCounters = @(
    "\NTDS\DRA Inbound Bytes Total/sec"
    "\NTDS\DRA Outbound Bytes Total/sec"
    "\NTDS\DS Directory Reads/sec"
    "\NTDS\DS Directory Writes/sec"
    "\NTDS\LDAP Client Sessions"
    "\NTDS\LDAP Searches/sec"
)

# Collect performance data
Get-Counter -Counter $NTDSCounters -SampleInterval 60 -MaxSamples 60
```

### Database Maintenance

Regular database maintenance tasks:

```powershell
# Offline defragmentation (requires reboot to Directory Services Restore Mode)
ntdsutil "activate instance ntds" "files" "compact to c:\temp" quit quit

# Online defragmentation is automatic but can be monitored
Get-WinEvent -LogName "Directory Service" | Where-Object {$_.Id -eq 700}

# Check database size
$DatabaseInfo = ntdsutil "activate instance ntds" "files" "info" quit quit
```

## FSMO Roles Management

### Understanding FSMO Roles

Five FSMO (Flexible Single Master Operations) roles:

- **Schema Master** - Controls schema modifications (forest-wide)
- **Domain Naming Master** - Controls domain creation/deletion (forest-wide)
- **PDC Emulator** - Primary time source, password changes (domain-wide)
- **RID Master** - Allocates RID pools (domain-wide)
- **Infrastructure Master** - Updates cross-domain references (domain-wide)

### Checking FSMO Role Holders

```powershell
# Check all FSMO roles
netdom query fsmo

# PowerShell method
Get-ADForest | Select-Object SchemaMaster, DomainNamingMaster
Get-ADDomain | Select-Object PDCEmulator, RIDMaster, InfrastructureMaster

# Specific role holders
Get-ADDomainController -Filter * | Select-Object Name, OperationMasterRoles
```

### Transferring FSMO Roles

Graceful transfer when source DC is online:

```powershell
# Transfer PDC Emulator role
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator

# Transfer multiple roles
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator, RIDMaster

# Transfer all domain roles
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator, RIDMaster, InfrastructureMaster
```

### Seizing FSMO Roles

Emergency seizure when source DC is offline:

```powershell
# Seize roles using ntdsutil (use with caution)
ntdsutil "roles" "connections" "connect to server DC02" quit "seize PDC" quit quit

# PowerShell method (newer versions)
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator -Force
```

## Backup and Recovery

### System State Backup

Backup essential AD components:

```powershell
# Create system state backup using Windows Server Backup
wbadmin start systemstatebackup -backuptarget:E: -quiet

# Schedule daily backups
$Action = New-ScheduledTaskAction -Execute "wbadmin" -Argument "start systemstatebackup -backuptarget:E: -quiet"
$Trigger = New-ScheduledTaskTrigger -Daily -At "2:00 AM"
Register-ScheduledTask -TaskName "AD Backup" -Action $Action -Trigger $Trigger -User "SYSTEM"
```

### Active Directory Database Backup

Backup AD database specifically:

```powershell
# Backup using ntdsutil
ntdsutil "activate instance ntds" "ifm" "create full c:\ADBackup" quit quit

# Verify backup integrity
ntdsutil "activate instance ntds" "files" "integrity" quit quit
```

### Authoritative Restore

Restore specific objects authoritatively:

```powershell
# Boot to Directory Services Restore Mode first
# Then restore system state
wbadmin start systemstaterecovery -version:01/01/2024-02:00 -quiet

# Mark objects as authoritative
ntdsutil "authoritative restore" "restore object CN=DeletedUser,OU=Users,DC=contoso,DC=com" quit quit
```

## Security Hardening

### Domain Controller Security

Essential security configurations:

```powershell
# Configure account policies
Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $true -MinPasswordLength 14 -MaxPasswordAge 60

# Enable advanced audit policies
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Directory Service Access" /success:enable /failure:enable

# Configure security settings via Group Policy
# - Restrict logon to domain controllers
# - Enable security event logging
# - Configure firewall rules
# - Disable unnecessary services
```

### Network Security

Secure DC network communications:

```powershell
# Configure IPSec for DC-to-DC communication
New-NetIPsecRule -DisplayName "AD Replication" -Direction Inbound -Protocol TCP -LocalPort 135, 139, 445, 389, 636, 3268, 3269, 53, 88, 464

# Configure Windows Firewall
Enable-NetFirewallRule -DisplayGroup "Active Directory Domain Services"
Enable-NetFirewallRule -DisplayGroup "DNS Service"
Enable-NetFirewallRule -DisplayGroup "Kerberos Key Distribution Center"
```

## Troubleshooting

### Common DC Issues

```powershell
# Replication issues
repadmin /showrepl * /csv > replication-status.csv
repadmin /replsummary

# Authentication problems
nltest /dsgetdc:contoso.com
nltest /sc_query:contoso.com

# DNS resolution issues
nslookup -type=SRV _ldap._tcp.contoso.com
dcdiag /test:dns /v

# Time synchronization problems
w32tm /query /status
w32tm /monitor /computers:DC01.contoso.com,DC02.contoso.com
```

### Performance Issues

```powershell
# Check LDAP performance
Get-Counter "\NTDS\LDAP Searches/sec" -SampleInterval 5 -MaxSamples 12

# Monitor database performance
Get-Counter "\LogicalDisk(C:)\Avg. Disk Queue Length" -SampleInterval 5 -MaxSamples 12

# Check memory usage
Get-Counter "\Process(lsass)\Working Set" -SampleInterval 5 -MaxSamples 12
```

## Best Practices

### Deployment Best Practices

- **Multiple DCs** - Deploy at least two DCs per domain
- **Geographic distribution** - Place DCs near user populations
- **Hardware redundancy** - Use reliable server hardware
- **Network reliability** - Ensure redundant network connections
- **Regular backups** - Implement automated backup procedures

### Operational Best Practices

- **Monitor health** - Regularly check DC health and replication
- **Keep updated** - Apply security updates promptly
- **Document changes** - Maintain configuration documentation
- **Test procedures** - Regularly test backup and recovery procedures
- **Capacity planning** - Monitor growth and plan for expansion

### Security Best Practices

- **Physical security** - Secure server locations
- **Administrative access** - Limit domain admin privileges
- **Service accounts** - Use managed service accounts
- **Regular audits** - Review and audit DC access
- **Incident response** - Maintain incident response procedures

## Related Documentation

- **[Getting Started](getting-started.md)** - AD fundamentals and basic setup
- **[Forests and Domains](forests-and-domains.md)** - AD structure and design
- **[Sites and Subnets](sites-and-subnets.md)** - Multi-site deployments
- **[Operations](../operations/index.md)** - Day-to-day DC management
- **[Security Best Practices](../security-best-practices.md)** - DC security hardening

---

*This guide covers Domain Controller deployment and management from initial installation to advanced troubleshooting. Proper DC management is critical for a healthy Active Directory environment.*
