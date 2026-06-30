---
title: "Cisco Device Configuration"
description: "Step-by-step configuration guides for Cisco IOS devices"
tags: ["cisco", "ios", "configuration", "networking"]
category: "networking"
difficulty: "intermediate"
last_updated: "2025-12-29"
author: "Joseph Streeter"
---

Step-by-step guides for configuring Cisco IOS devices including switches, routers, and essential network services.

## Console Connection

Use console access for first-time setup, password recovery, and break-glass troubleshooting when remote access is unavailable. This out-of-band method avoids dependency on IP connectivity and gives direct control from boot through full IOS operation.

### Connection Settings

These serial parameters must match your terminal emulator and the device console defaults. Incorrect values usually result in garbled output, no prompt response, or failed session establishment.

| Parameter | Value |
| --------- | ----- |
| Baud Rate | 9600 |
| Data Bits | 8 |
| Stop Bits | 1 |
| Parity | None |
| Flow Control | None |

### Initial Connection

Follow this sequence to establish a clean management session before making configuration changes. Once connected, confirm you can move between user EXEC and privileged EXEC modes before continuing.

1. Connect console cable to device and computer
2. Open terminal software (PuTTY, SecureCRT, etc.)
3. Configure serial port settings as shown above
4. Press Enter to activate console

## Initial Device Setup

Initial setup establishes identity, management defaults, and access controls that every production switch or router should have. Treat this as the baseline profile before enabling advanced features.

### Basic Configuration

This block sets hostname, domain context, and local authentication primitives. The goal is to provide secure administrative access while ensuring the device is uniquely identifiable in logs and monitoring platforms.

```cisco
! Enter privileged EXEC mode
enable

! Enter global configuration mode
configure terminal

! Set hostname
hostname SW-CORE-01

! Set domain name
ip domain-name yourdomain.com

! Configure enable password (encrypted)
enable secret YourSecurePassword123

! Configure console password
line console 0
 password ConPassword123
 login
 logging synchronous
 exit

! Configure VTY (Telnet/SSH) password
line vty 0 15
 password VTYPassword123
 login
 transport input ssh
 exit
```

### Save Configuration

Running configuration is volatile and is lost after a reboot unless saved. Use these commands after each validated change set so startup configuration remains aligned with the active state.

```cisco
! Save running config to startup config
copy running-config startup-config
! Or shortcut:
write memory
```

## Basic Switch Configuration

Switch baseline configuration enables predictable layer-2 and management behavior. The following sections focus on out-of-band reachability, secure remote administration, and optional protocol hardening.

### Management Interface

The management SVI provides an IP endpoint for administration and monitoring. Ensure the subnet, default gateway, and DNS settings match your management network design and routing boundaries.

```cisco
! Configure management VLAN
interface vlan 1
 description Management Interface
 ip address 192.168.1.10 255.255.255.0
 no shutdown
 exit

! Set default gateway
ip default-gateway 192.168.1.1

! Configure DNS servers
ip name-server 8.8.8.8 8.8.4.4
```

### SSH Configuration

SSH should be the default remote access method for Cisco infrastructure. This configuration enforces encrypted sessions, limits transport methods, and uses local accounts for role-separated administrative access.

```cisco
! Generate RSA keys for SSH
crypto key generate rsa
! Choose modulus size: 2048

! Configure SSH version 2
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3

! Configure VTY lines for SSH only
line vty 0 15
 transport input ssh
 login local
 exit

! Create local user accounts
username admin privilege 15 secret AdminPassword123
username readonly privilege 1 secret ReadOnlyPass123
```

### Disable CDP (Optional)

CDP is helpful for discovery and troubleshooting but may expose topology metadata. Disable it in untrusted segments or security-sensitive environments where device advertisement is not required.

```cisco
! Disable CDP globally
no cdp run

! Or disable on specific interface
interface GigabitEthernet0/1
 no cdp enable
 exit
```

## VLAN Configuration

VLAN design controls traffic segmentation, broadcast boundaries, and policy enforcement points. Use the dedicated guide for full implementation patterns across access, trunk, and inter-VLAN routing scenarios.

See the dedicated [Cisco VLAN Configuration](vlans.md) guide for comprehensive VLAN setup including:

- Creating and naming VLANs
- Assigning ports to VLANs
- Trunk configuration
- Inter-VLAN routing

## Network Services Configuration

Network services on the gateway device often include address assignment, translation, and policy enforcement. Configure these services carefully because they directly affect endpoint connectivity and application reachability.

### DHCP Server

Use local DHCP when the device serves as a branch or isolated-site gateway. Excluded addresses protect statically assigned infrastructure IPs, while scoped pools define client subnet options such as gateway and DNS.

```cisco
! Exclude addresses from DHCP pool
ip dhcp excluded-address 192.168.10.1 192.168.10.10

! Create DHCP pool
ip dhcp pool VLAN10
 network 192.168.10.0 255.255.255.0
 default-router 192.168.10.1
 dns-server 8.8.8.8 8.8.4.4
 domain-name yourdomain.com
 lease 7
 exit

! Create pool for another VLAN
ip dhcp pool VLAN20
 network 192.168.20.0 255.255.255.0
 default-router 192.168.20.1
 dns-server 8.8.8.8 8.8.4.4
 domain-name yourdomain.com
 lease 7
 exit

! Verify DHCP configuration
show ip dhcp pool
show ip dhcp binding
```

### NAT/PAT Configuration

PAT enables many private hosts to share a public or WAN-facing address by translating source ports. Proper inside/outside interface roles and ACL scope are critical to avoid over-translation or broken flows.

```cisco
! Define inside and outside interfaces
interface GigabitEthernet0/0
 description WAN Interface
 ip address dhcp
 ip nat outside
 no shutdown
 exit

interface GigabitEthernet0/1
 description LAN Interface
 ip address 192.168.1.1 255.255.255.0
 ip nat inside
 no shutdown
 exit

! Create access list for NAT
access-list 1 permit 192.168.0.0 0.0.255.255

! Configure PAT (Port Address Translation)
ip nat inside source list 1 interface GigabitEthernet0/0 overload

! Verify NAT configuration
show ip nat translations
show ip nat statistics
```

### Static NAT (Port Forwarding)

Static NAT maps specific inbound ports to internal services for controlled external access. Limit exposed ports to required services and pair this with ACLs or firewall policies for defense in depth.

```cisco
! Forward external port 80 to internal server
ip nat inside source static tcp 192.168.1.100 80 interface GigabitEthernet0/0 80

! Forward external port 443 to internal server
ip nat inside source static tcp 192.168.1.100 443 interface GigabitEthernet0/0 443

! Forward external port 3389 to RDP server
ip nat inside source static tcp 192.168.1.50 3389 interface GigabitEthernet0/0 3389
```

## Quality of Service (QoS)

QoS prioritizes delay-sensitive traffic such as voice and video during congestion. Effective QoS starts with correct traffic classification, followed by queueing and bandwidth policies at egress bottlenecks.

### Basic QoS Configuration

This example classifies voice and video by DSCP and applies differentiated treatment through a policy map. Reserve strict priority for real-time voice and assign bounded bandwidth to video and best-effort traffic.

```cisco
! Define class map for voice traffic
class-map match-any VOICE
 match ip dscp ef
 exit

! Define class map for video traffic
class-map match-any VIDEO
 match ip dscp af41
 exit

! Define policy map
policy-map QOS-POLICY
 class VOICE
  priority percent 30
  exit
 class VIDEO
  bandwidth percent 20
  exit
 class class-default
  fair-queue
  exit
 exit

! Apply policy to interface
interface GigabitEthernet0/1
 description LAN Interface
 service-policy output QOS-POLICY
 exit
```

### Voice VLAN Configuration

Voice VLANs separate phone traffic from endpoint data to improve security and policy control. This model also supports automatic QoS markings and simpler troubleshooting for converged access ports.

```cisco
! Configure voice VLAN on access port
interface GigabitEthernet0/1
 description IP Phone + PC
 switchport mode access
 switchport access vlan 30
 switchport voice vlan 60
 spanning-tree portfast
 exit
```

## Security Configuration

Security hardening reduces attack surface, limits lateral movement, and protects management access. Combine port controls, ACLs, AAA, and service minimization as a layered baseline.

### Port Security

Port security restricts learned MAC addresses and defines violation actions on access interfaces. Sticky learning is useful for user-edge ports but should be monitored and periodically reviewed during device moves.

```cisco
! Configure port security on access port
interface GigabitEthernet0/1
 description User Workstation
 switchport mode access
 switchport access vlan 30
 switchport port-security
 switchport port-security maximum 2
 switchport port-security violation restrict
 switchport port-security mac-address sticky
 switchport port-security aging time 10
 spanning-tree portfast
 exit

! Verify port security
show port-security interface GigabitEthernet0/1
show port-security address
```

### Access Control Lists (ACLs)

ACLs enforce traffic policy at management and data-plane boundaries. Keep ACLs explicit, ordered from specific to general matches, and document intent to simplify future troubleshooting.

#### Standard ACL

Standard ACLs filter only by source address and are typically used for management plane restrictions. Place them close to the destination to avoid unintentionally blocking unrelated traffic paths.

```cisco
! Create standard ACL (numbered)
access-list 10 permit 192.168.10.0 0.0.0.255
access-list 10 deny any

! Create standard ACL (named)
ip access-list standard ADMIN-ACCESS
 permit 192.168.10.0 0.0.0.255
 deny any
 exit

! Apply to VTY lines
line vty 0 15
 access-class 10 in
 exit
```

#### Extended ACL

Extended ACLs support source, destination, protocol, and port matching, making them suitable for application-aware filtering. Evaluate order of operations carefully because ACL evaluation stops at first match.

```cisco
! Create extended ACL (numbered)
access-list 100 permit tcp 192.168.10.0 0.0.0.255 any eq 80
access-list 100 permit tcp 192.168.10.0 0.0.0.255 any eq 443
access-list 100 deny ip any any

! Create extended ACL (named)
ip access-list extended WEB-TRAFFIC
 permit tcp 192.168.10.0 0.0.0.255 any eq 80
 permit tcp 192.168.10.0 0.0.0.255 any eq 443
 deny ip any any
 exit

! Apply to interface
interface vlan 10
 ip access-group 100 in
 exit
```

#### Guest Network Isolation

Guest isolation ACLs prevent access from untrusted VLANs to internal RFC1918 networks while still allowing internet-bound traffic. Apply guest policies inbound on the guest SVI for clear and deterministic enforcement.

```cisco
! Deny guest VLAN to internal networks
access-list 101 deny ip 172.16.40.0 0.0.0.255 10.0.0.0 0.255.255.255
access-list 101 deny ip 172.16.40.0 0.0.0.255 192.168.0.0 0.0.255.255
access-list 101 permit ip 172.16.40.0 0.0.0.255 any

! Apply to guest VLAN interface
interface vlan 40
 description Guest Network
 ip access-group 101 in
 exit
```

### AAA Configuration

AAA centralizes authentication and authorization controls and supports external identity systems such as RADIUS. Local fallback keeps access available during authentication server outages.

```cisco
! Enable AAA
aaa new-model

! Configure local authentication
aaa authentication login default local
aaa authorization exec default local

! Configure RADIUS (if using external server)
radius server AUTH-SERVER
 address ipv4 192.168.10.5 auth-port 1812 acct-port 1813
 key RadiusSecretKey123
 exit

! Configure authentication to use RADIUS with local fallback
aaa authentication login default group radius local
aaa authorization exec default group radius local
```

### Disable Unused Services

Disabling unused services removes unnecessary listening surfaces and legacy protocol exposure. Review this list against operational requirements before applying globally.

```cisco
! Disable unnecessary services
no ip http server
no ip http secure-server
no cdp run
no ip bootp server
no service finger
no service pad
no ip source-route

! Enable password encryption
service password-encryption

! Enable TCP keepalives
service tcp-keepalives-in
service tcp-keepalives-out
```

## Interface Configuration

Consistent interface templates improve operational reliability and reduce configuration drift. Separate access, trunk, and disabled-port patterns so deployments are repeatable across sites.

### Access Port

Access ports are intended for endpoint devices and should include edge protections such as PortFast and BPDU Guard. These controls reduce convergence delays and help prevent accidental layer-2 loops.

```cisco
interface GigabitEthernet0/1
 description User Workstation
 switchport mode access
 switchport access vlan 30
 spanning-tree portfast
 spanning-tree bpduguard enable
 no shutdown
 exit
```

### Trunk Port

Trunk ports carry multiple VLANs between network devices and should be tightly scoped. Restrict allowed VLANs and set a dedicated native VLAN to reduce leakage and misconfiguration risk.

```cisco
interface GigabitEthernet0/24
 description Trunk to Distribution Switch
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,30,40,50,60
 no shutdown
 exit
```

### Disable Unused Interfaces

Shutting down unused interfaces is a simple but high-value control that reduces physical attack opportunities and accidental connectivity. Apply this consistently with descriptive labels for operations visibility.

```cisco
! Disable unused interface
interface GigabitEthernet0/10
 description Unused Port
 shutdown
 exit

! Disable range of interfaces
interface range GigabitEthernet0/11-24
 description Unused Ports
 shutdown
 exit
```

## Routing Configuration

Routing configuration determines how traffic exits local VLANs and reaches remote networks. Choose static or dynamic protocols based on topology size, failover requirements, and administrative complexity.

### Static Routes

Static routing is predictable and lightweight, making it ideal for small or stable topologies. Use a default route for internet or upstream transit and explicit routes for known remote prefixes.

```cisco
! Add default route
ip route 0.0.0.0 0.0.0.0 192.168.1.1

! Add specific route
ip route 10.0.20.0 255.255.255.0 192.168.1.254
```

### OSPF Configuration

OSPF provides fast convergence and hierarchical design support for medium to large environments. Passive interfaces help reduce unnecessary adjacency formation while still advertising connected networks.

```cisco
! Enable OSPF
router ospf 1
 router-id 1.1.1.1
 network 192.168.1.0 0.0.0.255 area 0
 network 10.0.20.0 0.0.0.255 area 0
 passive-interface default
 no passive-interface GigabitEthernet0/1
 exit
```

### EIGRP Configuration

EIGRP offers efficient convergence and simple deployment in Cisco-centric environments. Disable auto-summary in modern discontiguous networks to avoid incorrect classful route advertisement.

```cisco
! Enable EIGRP
router eigrp 100
 network 192.168.1.0 0.0.0.255
 network 10.0.20.0 0.0.0.255
 no auto-summary
 exit
```

### BGP Configuration

BGP is commonly used for inter-domain routing, multi-homing, and policy-based path control. Validate peer AS values, advertised prefixes, and route-policy intent before enabling in production.

```cisco
! Enable BGP with local AS number
router bgp 65001
 bgp router-id 1.1.1.1

 ! Configure eBGP neighbor
 neighbor 203.0.113.2 remote-as 65002
 neighbor 203.0.113.2 description ISP-UPLINK

 ! Advertise local networks
 network 192.168.1.0 mask 255.255.255.0
 network 10.0.20.0 mask 255.255.255.0
 exit

! Verify BGP status
show ip bgp summary
show ip bgp
```

## Verification Commands

Verification should follow each change window to confirm expected state and detect regressions quickly. Use these commands to validate system health, interface behavior, and path reachability.

### System Information

System-level checks confirm software version, hardware platform, and current configuration state. Capture this output before and after major changes for audit and rollback readiness.

```cisco
! Show system version and hardware
show version

! Show running configuration
show running-config

! Show startup configuration
show startup-config

! Show hardware inventory
show inventory

! Show system environment (temperature, fans, power)
show environment
```

### Interface Status

Interface validation confirms link state, VLAN assignment, and operational counters. Focus on error rates, duplex mismatches, and unexpected interface flaps when troubleshooting.

```cisco
! Show brief interface status
show ip interface brief

! Show detailed interface information
show interfaces GigabitEthernet0/1

! Show interface switchport configuration
show interfaces GigabitEthernet0/1 switchport

! Show interface counters
show interfaces GigabitEthernet0/1 counters
```

### Troubleshooting

These commands provide fast insight into connectivity and neighbor relationships. Start with basic reachability and progressively inspect layer-2 and layer-3 tables to isolate fault domains.

```cisco
! Test connectivity
ping 8.8.8.8
traceroute 8.8.8.8

! Show CDP neighbors
show cdp neighbors detail

! Show LLDP neighbors
show lldp neighbors detail

! Show MAC address table
show mac address-table

! Show ARP table
show arp
```

## Backup and Recovery

Operational resilience depends on tested backup and recovery workflows. Keep copies of known-good configurations and document recovery procedures before emergency scenarios occur.

### Configuration Backup

Backups should be performed after approved changes and stored on managed systems with access controls. Maintain versioned configuration archives to support comparison, rollback, and audit requirements.

```cisco
! Save to startup-config
copy running-config startup-config

! Backup to TFTP server
copy running-config tftp://192.168.1.100/SW-CORE-01-config.txt

! Restore from TFTP server
copy tftp://192.168.1.100/SW-CORE-01-config.txt running-config
```

### Password Recovery

Password recovery restores administrative access when credentials are lost. Because this process temporarily bypasses startup behavior, execute it under change control and immediately resecure the device afterward.

1. Power cycle device and interrupt boot process
2. Enter rommon mode
3. Change configuration register: `confreg 0x2142`
4. Reset device: `reset`
5. Skip initial configuration
6. Enter privileged mode: `enable`
7. Copy startup to running: `copy startup-config running-config`
8. Change password: `configure terminal`, `enable secret NewPassword`
9. Reset config register: `config-register 0x2102`
10. Save configuration: `copy running-config startup-config`
11. Reload device: `reload`

## Related Topics

Use the links below for deeper implementation guidance and adjacent networking concepts that complement this baseline configuration reference.

- [Cisco VLANs](vlans.md) - VLAN configuration guide
- [Cisco Overview](index.md) - Main Cisco documentation
- [Network Fundamentals](../fundamentals.md) - Core networking concepts
- [Troubleshooting](../troubleshooting.md) - Problem resolution
