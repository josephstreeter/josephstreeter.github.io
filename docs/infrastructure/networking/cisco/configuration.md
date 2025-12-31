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

### Connection Settings

| Parameter | Value |
| --------- | ----- |
| Baud Rate | 9600 |
| Data Bits | 8 |
| Stop Bits | 1 |
| Parity | None |
| Flow Control | None |

### Initial Connection

1. Connect console cable to device and computer
2. Open terminal software (PuTTY, SecureCRT, etc.)
3. Configure serial port settings as shown above
4. Press Enter to activate console

## Initial Device Setup

### Basic Configuration

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

```cisco
! Save running config to startup config
copy running-config startup-config
! Or shortcut:
write memory
```

## Basic Switch Configuration

### Management Interface

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

```cisco
! Disable CDP globally
no cdp run

! Or disable on specific interface
interface GigabitEthernet0/1
 no cdp enable
 exit
```

## VLAN Configuration

See the dedicated [Cisco VLAN Configuration](vlans.md) guide for comprehensive VLAN setup including:

- Creating and naming VLANs
- Assigning ports to VLANs
- Trunk configuration
- Inter-VLAN routing

## Network Services Configuration

### DHCP Server

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

```cisco
! Forward external port 80 to internal server
ip nat inside source static tcp 192.168.1.100 80 interface GigabitEthernet0/0 80

! Forward external port 443 to internal server
ip nat inside source static tcp 192.168.1.100 443 interface GigabitEthernet0/0 443

! Forward external port 3389 to RDP server
ip nat inside source static tcp 192.168.1.50 3389 interface GigabitEthernet0/0 3389
```

## Quality of Service (QoS)

### Basic QoS Configuration

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

### Port Security

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

#### Standard ACL

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

### Access Port

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

### Static Routes

```cisco
! Add default route
ip route 0.0.0.0 0.0.0.0 192.168.1.1

! Add specific route
ip route 10.0.20.0 255.255.255.0 192.168.1.254
```

### OSPF Configuration

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

```cisco
! Enable EIGRP
router eigrp 100
 network 192.168.1.0 0.0.0.255
 network 10.0.20.0 0.0.0.255
 no auto-summary
 exit
```

## Verification Commands

### System Information

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

### Configuration Backup

```cisco
! Save to startup-config
copy running-config startup-config

! Backup to TFTP server
copy running-config tftp://192.168.1.100/SW-CORE-01-config.txt

! Restore from TFTP server
copy tftp://192.168.1.100/SW-CORE-01-config.txt running-config
```

### Password Recovery

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

- [Cisco VLANs](vlans.md) - VLAN configuration guide
- [Cisco Overview](index.md) - Main Cisco documentation
- [Network Fundamentals](../fundamentals.md) - Core networking concepts
- [Troubleshooting](../troubleshooting.md) - Problem resolution
