---
title: Active Directory Firewall and Network Configuration
description: Comprehensive guide for configuring firewalls and network infrastructure to support Active Directory services, including port requirements, security considerations, and best practices
author: IT Operations Team
ms.date: 2025-01-01
ms.topic: reference
ms.service: active-directory
ms.subservice: networking
keywords: active directory, firewall, network, ports, security, domain controllers, infrastructure
---

## Active Directory Firewall and Network Configuration

## Overview

Active Directory requires specific network connectivity and firewall configurations to function properly. This guide provides comprehensive information about network requirements, port configurations, security considerations, and best practices for implementing firewall rules that support Active Directory services while maintaining security.

**Key Benefits:**

- **Security**: Proper firewall configuration protects AD infrastructure
- **Functionality**: Ensures all AD services operate correctly
- **Performance**: Optimizes network traffic flow for AD operations
- **Compliance**: Meets security frameworks and audit requirements

## Network Architecture Considerations

### Planning Requirements

Before implementing firewall rules, consider the following network architecture factors:

- **Domain Controller Placement**: Geographic distribution and site topology
- **Network Segmentation**: VLANs, subnets, and security zones
- **High Availability**: Redundancy and failover requirements
- **Performance**: Network latency and bandwidth considerations
- **Security**: Zero-trust principles and defense-in-depth strategies

### Common Network Topologies

#### Single-Site Deployment

```text
[Client Network] <---> [Firewall] <---> [Domain Controller Network]
     10.1.0.0/24              10.2.0.0/24
```

#### Multi-Site with WAN

```text
Site A: [Clients] <---> [DC-A] <---> [WAN] <---> [DC-B] <---> [Clients] :Site B
        10.1.0.0/24     10.2.0.0/24            10.3.0.0/24     10.4.0.0/24
```

#### DMZ and Perimeter Network

```text
[Internet] <---> [Edge FW] <---> [DMZ] <---> [Internal FW] <---> [AD Network]
                               (RODCs)                          (Full DCs)
```

## Domain Controller Network Configuration

### Network Planning Examples

The following examples show typical domain controller network configurations for different scenarios:

#### Production Environment Example

| **Domain/Site** | **Server Name** | **IP Address** | **Role** |
|----------------|-----------------|----------------|----------|
| **contoso.com (Site: HQ)** | DC01.contoso.com | 10.1.10.10 | PDC Emulator, DNS |
| | DC02.contoso.com | 10.1.10.11 | Infrastructure Master |
| | DC03.contoso.com | 10.1.10.12 | Global Catalog |
| **contoso.com (Site: Branch)** | DC04.contoso.com | 10.2.10.10 | Global Catalog, DNS |
| | DC05.contoso.com | 10.2.10.11 | Standard DC |

#### Test Environment Example

| **Domain/Site** | **Server Name** | **IP Address** | **Role** |
|----------------|-----------------|----------------|----------|
| **test.contoso.com** | TESTDC01.test.contoso.com | 10.100.10.10 | All FSMO Roles |
| | TESTDC02.test.contoso.com | 10.100.10.11 | Global Catalog |

### Network Addressing Best Practices

- **Subnet Planning**: Use dedicated subnets for domain controllers (e.g., 10.x.10.0/24)
- **IP Reservations**: Configure static IP addresses or DHCP reservations
- **DNS Configuration**: Ensure proper forward and reverse DNS zones
- **Gateway Configuration**: Configure appropriate default gateways for routing

## Active Directory Port Requirements

### Essential Ports for Active Directory

Active Directory requires multiple network ports for proper operation. The following table provides comprehensive port information:

| **Service Name** | **Ports** | **Direction** | **Purpose** | **Required** |
|------------------|-----------|---------------|-------------|--------------|
| **DNS** | 53/TCP, 53/UDP | Bi-directional | Domain name resolution | Critical |
| **Kerberos** | 88/TCP, 88/UDP | Bi-directional | Authentication protocol | Critical |
| **RPC Endpoint Mapper** | 135/TCP | Bi-directional | RPC service location | Critical |
| **NetBIOS Name Service** | 137/UDP | Bi-directional | NetBIOS name resolution | Legacy |
| **NetBIOS Datagram** | 138/UDP | Bi-directional | NetBIOS datagrams | Legacy |
| **NetBIOS Session** | 139/TCP | Bi-directional | NetBIOS sessions | Legacy |
| **LDAP** | 389/TCP, 389/UDP | Bi-directional | Directory queries | Critical |
| **SMB/CIFS** | 445/TCP | Bi-directional | File sharing, SYSVOL | Critical |
| **Kerberos Password Change** | 464/TCP, 464/UDP | Bi-directional | Password changes | Important |
| **IPSec IKE** | 500/UDP | Bi-directional | IPSec key exchange | Optional |
| **LDAPS** | 636/TCP | Bi-directional | Secure LDAP | Important |
| **RPC Dynamic Range** | 1024-65535/TCP | Bi-directional | Dynamic RPC services | Critical |
| **Global Catalog** | 3268/TCP | Client to DC | Global catalog queries | Important |
| **Global Catalog SSL** | 3269/TCP | Client to DC | Secure global catalog | Important |
| **IPSec NAT-T** | 4500/UDP | Bi-directional | IPSec NAT traversal | Optional |
| **WS-Management HTTP** | 5985/TCP | Client to DC | PowerShell remoting | Management |
| **WS-Management HTTPS** | 5986/TCP | Client to DC | Secure PowerShell | Management |
| **AD Web Services** | 9389/TCP | Client to DC | AD PowerShell module | Management |

### RPC Dynamic Port Ranges

Microsoft Windows uses dynamic port ranges for RPC communication. The ranges vary by Windows version:

| **Windows Version** | **Dynamic Port Range** |
|---------------------|------------------------|
| **Windows Server 2008 R2 and later** | 49152-65535/TCP |
| **Windows Server 2008 and earlier** | 1024-65535/TCP |

#### Configure Static RPC Ports (Recommended)

For better security, configure static RPC endpoint ports:

```powershell
# Configure AD DS to use specific RPC ports
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" /v "TCP/IP Port" /t REG_DWORD /d 38901
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NTFRS\Parameters" /v "RPC TCP/IP Port Assignment" /t REG_DWORD /d 38902

# Configure DNS to use specific RPC port
dnscmd /Config /RpcProtocol 5
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DNS\Parameters" /v "RpcProtocol" /t REG_DWORD /d 5
```

### IPv6 Considerations

Active Directory fully supports IPv6. Consider the following:

- **Dual Stack**: Configure both IPv4 and IPv6 where possible
- **IPv6 Addresses**: Ensure firewall rules cover IPv6 traffic
- **Transition Technologies**: Configure tunneling mechanisms if required
- **DNS**: Ensure AAAA records are properly configured

### Traffic Flow Analysis

#### Client to Domain Controller

```text
Client Authentication Flow:
1. DNS query (53/UDP) - Locate domain controllers
2. Kerberos (88/TCP) - Authentication request
3. LDAP (389/TCP) - Directory queries
4. SMB (445/TCP) - Group Policy retrieval
```

#### Domain Controller to Domain Controller

```text
AD Replication Flow:
1. RPC Endpoint Mapper (135/TCP) - Service location
2. RPC Dynamic Port (varies) - Replication data
3. DNS (53/TCP/UDP) - Name resolution
4. Kerberos (88/TCP) - Authentication
```

## Firewall Configuration Examples

### Windows Firewall Rules

#### PowerShell Script for Domain Controller Rules

```powershell
# Active Directory Domain Controller Firewall Rules
# Run with administrative privileges

# Enable Windows Firewall profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# DNS Services
New-NetFirewallRule -DisplayName "AD-DNS-In" -Direction Inbound -Protocol TCP -LocalPort 53 -Action Allow
New-NetFirewallRule -DisplayName "AD-DNS-In" -Direction Inbound -Protocol UDP -LocalPort 53 -Action Allow

# Kerberos Authentication
New-NetFirewallRule -DisplayName "AD-Kerberos-In" -Direction Inbound -Protocol TCP -LocalPort 88 -Action Allow
New-NetFirewallRule -DisplayName "AD-Kerberos-In" -Direction Inbound -Protocol UDP -LocalPort 88 -Action Allow

# RPC Endpoint Mapper
New-NetFirewallRule -DisplayName "AD-RPC-Endpoint-In" -Direction Inbound -Protocol TCP -LocalPort 135 -Action Allow

# LDAP Services
New-NetFirewallRule -DisplayName "AD-LDAP-In" -Direction Inbound -Protocol TCP -LocalPort 389 -Action Allow
New-NetFirewallRule -DisplayName "AD-LDAP-In" -Direction Inbound -Protocol UDP -LocalPort 389 -Action Allow

# LDAPS (Secure LDAP)
New-NetFirewallRule -DisplayName "AD-LDAPS-In" -Direction Inbound -Protocol TCP -LocalPort 636 -Action Allow

# SMB/CIFS
New-NetFirewallRule -DisplayName "AD-SMB-In" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow

# Kerberos Password Change
New-NetFirewallRule -DisplayName "AD-Kpasswd-In" -Direction Inbound -Protocol TCP -LocalPort 464 -Action Allow
New-NetFirewallRule -DisplayName "AD-Kpasswd-In" -Direction Inbound -Protocol UDP -LocalPort 464 -Action Allow

# Global Catalog
New-NetFirewallRule -DisplayName "AD-GC-In" -Direction Inbound -Protocol TCP -LocalPort 3268 -Action Allow
New-NetFirewallRule -DisplayName "AD-GC-SSL-In" -Direction Inbound -Protocol TCP -LocalPort 3269 -Action Allow

# AD Web Services
New-NetFirewallRule -DisplayName "AD-WebServices-In" -Direction Inbound -Protocol TCP -LocalPort 9389 -Action Allow

# RPC Dynamic Range (Windows Server 2008 R2+)
New-NetFirewallRule -DisplayName "AD-RPC-Dynamic-In" -Direction Inbound -Protocol TCP -LocalPort 49152-65535 -Action Allow
```

#### Client Workstation Rules

```powershell
# Client workstation firewall rules for AD connectivity
# Outbound rules (typically allowed by default)

New-NetFirewallRule -DisplayName "AD-Client-DNS-Out" -Direction Outbound -Protocol TCP -RemotePort 53 -Action Allow
New-NetFirewallRule -DisplayName "AD-Client-DNS-Out" -Direction Outbound -Protocol UDP -RemotePort 53 -Action Allow
New-NetFirewallRule -DisplayName "AD-Client-Kerberos-Out" -Direction Outbound -Protocol TCP -RemotePort 88 -Action Allow
New-NetFirewallRule -DisplayName "AD-Client-LDAP-Out" -Direction Outbound -Protocol TCP -RemotePort 389 -Action Allow
New-NetFirewallRule -DisplayName "AD-Client-SMB-Out" -Direction Outbound -Protocol TCP -RemotePort 445 -Action Allow
```

### Enterprise Firewall Examples

#### Cisco ASA Configuration

```cisco
! Active Directory firewall rules for Cisco ASA
! Allow traffic from client networks to domain controllers

object-group network AD_DOMAIN_CONTROLLERS
 network-object 10.1.10.0 255.255.255.0
 description Active Directory Domain Controllers

object-group network CLIENT_NETWORKS
 network-object 10.1.0.0 255.255.0.0
 description Client workstation networks

object-group service AD_PORTS tcp-udp
 port-object eq 53
 port-object eq 88
 port-object eq 135
 port-object eq 389
 port-object eq 445
 port-object eq 464
 port-object eq 636
 port-object eq 3268
 port-object eq 3269
 port-object eq 9389
 port-object range 49152 65535

access-list INSIDE_IN extended permit object-group AD_PORTS object-group CLIENT_NETWORKS object-group AD_DOMAIN_CONTROLLERS
access-list INSIDE_IN extended permit icmp object-group CLIENT_NETWORKS object-group AD_DOMAIN_CONTROLLERS
```

#### Palo Alto Networks Configuration

```paloalto
# Security policy for Active Directory
set rulebase security rules "Allow-AD-Services" from internal
set rulebase security rules "Allow-AD-Services" to dmz
set rulebase security rules "Allow-AD-Services" source "Client-Networks"
set rulebase security rules "Allow-AD-Services" destination "Domain-Controllers"
set rulebase security rules "Allow-AD-Services" application [ active-directory dns kerberos ldap ms-ds-smb ]
set rulebase security rules "Allow-AD-Services" service application-default
set rulebase security rules "Allow-AD-Services" action allow
```

### Network ACL Examples

#### Router/Switch ACL Configuration

```cisco
! Standard ACL for AD traffic
ip access-list extended AD_TRAFFIC
 permit tcp 10.1.0.0 0.0.255.255 10.1.10.0 0.0.0.255 eq 53
 permit udp 10.1.0.0 0.0.255.255 10.1.10.0 0.0.0.255 eq 53
 permit tcp 10.1.0.0 0.0.255.255 10.1.10.0 0.0.0.255 eq 88
 permit udp 10.1.0.0 0.0.255.255 10.1.10.0 0.0.0.255 eq 88
 permit tcp 10.1.0.0 0.0.255.255 10.1.10.0 0.0.0.255 eq 135
 permit tcp 10.1.0.0 0.0.255.255 10.1.10.0 0.0.0.255 eq 389
 permit tcp 10.1.0.0 0.0.255.255 10.1.10.0 0.0.0.255 eq 445
 permit tcp 10.1.0.0 0.0.255.255 10.1.10.0 0.0.0.255 eq 636
 permit tcp 10.1.0.0 0.0.255.255 10.1.10.0 0.0.0.255 range 49152 65535
 deny ip any any log
```

## Security Considerations

### Defense-in-Depth Strategy

#### Network Segmentation

- **VLAN Separation**: Isolate domain controllers in dedicated VLANs
- **DMZ Placement**: Consider Read-Only Domain Controllers (RODCs) in DMZ
- **Micro-segmentation**: Implement granular network controls
- **Zero Trust**: Verify every connection, even internal traffic

#### Access Control Best Practices

```text
Network Security Zones:
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Untrusted     │  │   Semi-Trusted  │  │    Trusted      │
│   (Internet)    │  │     (DMZ)       │  │   (Internal)    │
│                 │  │   - RODCs       │  │   - Full DCs    │
│                 │  │   - Web Apps    │  │   - File Servers│
└─────────────────┘  └─────────────────┘  └─────────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                        Firewall Rules
```

### Monitoring and Logging

#### Network Traffic Monitoring

```powershell
# PowerShell script to monitor AD network connections
$Connections = Get-NetTCPConnection | Where-Object {
    $_.LocalPort -in @(53,88,135,389,445,636,3268,3269,9389) -or
    $_.RemotePort -in @(53,88,135,389,445,636,3268,3269,9389)
}

$Connections | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State | 
    Format-Table -AutoSize
```

#### Firewall Log Analysis

```powershell
# Analyze Windows Firewall logs for AD traffic
$LogPath = "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log"
$ADPorts = @(53,88,135,389,445,464,636,3268,3269,9389)

Get-Content $LogPath | Where-Object {
    $_ -match "(\d+\.\d+\.\d+\.\d+).*?(\d+)" -and
    $ADPorts -contains [int]$Matches[2]
} | Select-Object -Last 100
```

### Compliance and Auditing

#### Common Security Frameworks

| **Framework** | **Requirements** | **Implementation** |
|---------------|------------------|-------------------|
| **NIST** | Network segmentation, access controls | Implement micro-segmentation |
| **CIS Controls** | Secure network configuration | Regular firewall rule audits |
| **ISO 27001** | Network security management | Documented network policies |
| **SOX** | IT controls and monitoring | Audit logging and review |

#### Audit Checklist

- [ ] Document all firewall rules and their purposes
- [ ] Regularly review and remove unused rules
- [ ] Monitor network traffic for anomalies
- [ ] Test firewall rules during maintenance windows
- [ ] Maintain change management for firewall modifications
- [ ] Implement automated compliance checking

## Troubleshooting Network Connectivity

### Common Issues and Solutions

| **Issue** | **Symptoms** | **Resolution** |
|-----------|--------------|----------------|
| **Authentication Failures** | Cannot log in to domain | Check Kerberos (88) and DNS (53) |
| **Group Policy Not Applying** | Policies not downloading | Verify SMB (445) and RPC (135+dynamic) |
| **Slow Logons** | Extended login times | Check RPC dynamic port range |
| **LDAP Query Failures** | Directory searches fail | Verify LDAP (389) and GC (3268) ports |

### Diagnostic Commands

```powershell
# Test network connectivity to domain controllers
Test-NetConnection -ComputerName dc01.contoso.com -Port 88
Test-NetConnection -ComputerName dc01.contoso.com -Port 389
Test-NetConnection -ComputerName dc01.contoso.com -Port 445

# Test AD functionality
Test-ComputerSecureChannel -Repair
nltest /dsgetdc:contoso.com
gpupdate /force

# Check firewall status
Get-NetFirewallProfile
Get-NetFirewallRule | Where-Object {$_.Enabled -eq "True"} | 
    Select-Object DisplayName, Direction, Action, Protocol
```

### Performance Optimization

#### Network Performance Tuning

```powershell
# Optimize network settings for AD traffic
netsh int tcp set global autotuninglevel=normal
netsh int tcp set global rss=enabled
netsh int tcp set global netdma=enabled

# Monitor network performance
Get-Counter -Counter "\Network Interface(*)\Bytes Total/sec" -SampleInterval 5 -MaxSamples 12
```

## Advanced Configuration

### Site-to-Site Connectivity

#### VPN Configuration for AD

```text
Site-to-Site VPN Requirements:
- Routing: Ensure proper routing tables for AD subnets
- DNS: Configure conditional forwarders
- Time Sync: Synchronize time across sites (NTP - port 123)
- Bandwidth: Plan for replication traffic requirements
```

#### SD-WAN Considerations

```text
Active Directory over SD-WAN:
1. Prioritize AD traffic (QoS)
2. Ensure reliable connections for authentication
3. Configure backup paths for critical AD services
4. Monitor latency and packet loss
```

### Cloud Integration

#### Hybrid Scenarios

```text
Azure AD Connect Requirements:
- HTTPS (443) for synchronization
- Azure service endpoints
- Certificate validation
- Proxy configuration (if applicable)
```

### Network Access Control

The implementation of network access control should follow organizational security policies and compliance requirements. Consider the following approaches:

- **Network Admission Control (NAC)**: Implement device compliance checking
- **Certificate-Based Access**: Use machine certificates for authentication
- **Conditional Access**: Integrate with modern identity platforms
- **Regular Access Reviews**: Periodically review and validate access requirements

## Additional Resources

### Microsoft Documentation

- [Microsoft Learn: Active Directory Network Requirements](https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/config-firewall-for-ad-domains-and-trusts)
- [Microsoft Learn: How to configure a firewall for Active Directory domains](https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/config-firewall-for-ad-domains-and-trusts)
- [Microsoft Learn: Service overview and network port requirements](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/service-overview-and-network-port-requirements)

### Network Security Resources

- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls](https://www.cisecurity.org/controls/)
- [Zero Trust Architecture (NIST SP 800-207)](https://csrc.nist.gov/publications/detail/sp/800-207/final)

### PowerShell and Automation

- [Microsoft Learn: Windows Firewall PowerShell Module](https://learn.microsoft.com/en-us/powershell/module/netsecurity/)
- [Microsoft Learn: Network Adapter PowerShell Module](https://learn.microsoft.com/en-us/powershell/module/netadapter/)

## Conclusion

Proper network and firewall configuration is critical for Active Directory security and functionality. This guide provides comprehensive information for implementing secure, reliable network connectivity while maintaining the necessary access for AD services.

**Key Takeaways:**

- **Plan network architecture** carefully considering security and performance
- **Implement defense-in-depth** with multiple layers of network security
- **Use least privilege** principles for firewall rule configuration
- **Monitor and audit** network traffic and firewall rules regularly
- **Document all configurations** for compliance and maintenance purposes

Regular review and updates of network configurations ensure continued security and optimal performance of Active Directory services.
