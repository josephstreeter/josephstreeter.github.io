---
title: "Cisco VLAN Configuration"
description: "VLAN implementation and management for Cisco IOS switches"
tags: ["cisco", "vlan", "ios", "switching"]
category: "networking"
difficulty: "intermediate"
last_updated: "2025-12-29"
author: "Joseph Streeter"
---

Comprehensive VLAN configuration guide for Cisco IOS switches including creation, trunk configuration, and inter-VLAN routing.

## Creating VLANs

### Basic VLAN Creation

```cisco
! Create VLAN
vlan 20
 name Servers
 state active
 exit

! Create multiple VLANs
vlan 10
 name Management
 exit
vlan 20
 name Servers
 exit
vlan 30
 name Workstations
 exit
vlan 40
 name Guest
 exit
vlan 50
 name IoT
 exit
vlan 60
 name VoIP
 exit

! Verify VLANs
show vlan brief
```

### Configure SVI (Switched Virtual Interface)

```cisco
! Configure management VLAN interface
interface vlan 20
 description Application Servers
 ip address 10.0.20.1 255.255.255.0
 no shutdown
 exit

! Configure multiple SVIs
interface vlan 10
 description Management
 ip address 192.168.10.1 255.255.255.0
 no shutdown
 exit

interface vlan 30
 description Workstations
 ip address 10.0.30.1 255.255.252.0
 no shutdown
 exit
```

## Assigning Ports to VLANs

### Access Port Configuration

```cisco
! Assign single port to VLAN
interface GigabitEthernet0/1
 description Server Port
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
 exit

! Assign range of ports to VLAN
interface range GigabitEthernet0/1-10
 description Server Ports
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
 exit

! Verify port VLAN assignment
show interfaces GigabitEthernet0/1 switchport
```

### Voice VLAN Configuration

```cisco
! Configure port for IP phone + PC
interface GigabitEthernet0/5
 description IP Phone + Workstation
 switchport mode access
 switchport access vlan 30
 switchport voice vlan 60
 spanning-tree portfast
 exit
```

## Trunk Configuration

### Basic Trunk Setup

```cisco
! Configure trunk port
interface GigabitEthernet0/24
 description Trunk to Distribution Switch
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,30,40,50,60
 exit

! Verify trunk configuration
show interfaces trunk
show interfaces GigabitEthernet0/24 switchport
```

### Trunk Best Practices

```cisco
! Configure trunk with security best practices
interface GigabitEthernet0/24
 description Trunk to Distribution Switch
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,30,40,50,60
 switchport nonegotiate
 spanning-tree guard root
 exit
```

### Dynamic Trunking Protocol (DTP)

```cisco
! Disable DTP (recommended for security)
interface GigabitEthernet0/24
 switchport nonegotiate
 exit

! Configure DTP modes (if needed)
interface GigabitEthernet0/24
 ! Force trunk
 switchport mode trunk
 ! Or negotiate trunk
 switchport mode dynamic desirable
 exit
```

### Trunk Allowed VLANs

```cisco
! Add VLANs to trunk
interface GigabitEthernet0/24
 switchport trunk allowed vlan add 70,80
 exit

! Remove VLANs from trunk
interface GigabitEthernet0/24
 switchport trunk allowed vlan remove 80
 exit

! Set specific VLANs only
interface GigabitEthernet0/24
 switchport trunk allowed vlan 10,20,30
 exit

! Allow all VLANs (not recommended)
interface GigabitEthernet0/24
 switchport trunk allowed vlan all
 exit
```

## Inter-VLAN Routing

### Router-on-a-Stick

```cisco
! Router configuration
interface GigabitEthernet0/0
 description Trunk to Switch
 no shutdown
 exit

! Configure subinterfaces for each VLAN
interface GigabitEthernet0/0.10
 description Management VLAN
 encapsulation dot1Q 10
 ip address 192.168.10.1 255.255.255.0
 exit

interface GigabitEthernet0/0.20
 description Servers VLAN
 encapsulation dot1Q 20
 ip address 10.0.20.1 255.255.255.0
 exit

interface GigabitEthernet0/0.30
 description Workstations VLAN
 encapsulation dot1Q 30
 ip address 10.0.30.1 255.255.252.0
 exit

interface GigabitEthernet0/0.40
 description Guest VLAN
 encapsulation dot1Q 40
 ip address 172.16.40.1 255.255.255.0
 exit

! Verify routing
show ip interface brief
show ip route
```

### Layer 3 Switch Configuration

```cisco
! Enable IP routing on switch
ip routing

! Configure SVIs for each VLAN
interface vlan 10
 description Management
 ip address 192.168.10.1 255.255.255.0
 no shutdown
 exit

interface vlan 20
 description Servers
 ip address 10.0.20.1 255.255.255.0
 no shutdown
 exit

interface vlan 30
 description Workstations
 ip address 10.0.30.1 255.255.252.0
 no shutdown
 exit

interface vlan 40
 description Guest Network
 ip address 172.16.40.1 255.255.255.0
 no shutdown
 exit

! Verify routing
show ip interface brief
show ip route
```

### Routed Port (SVI Alternative)

```cisco
! Convert switchport to routed port
interface GigabitEthernet0/1
 description Routed Port to Router
 no switchport
 ip address 10.1.1.2 255.255.255.252
 no shutdown
 exit
```

## VLAN Security

### Private VLANs

```cisco
! Configure primary VLAN
vlan 100
 private-vlan primary
 private-vlan association 101,102
 exit

! Configure isolated VLAN
vlan 101
 private-vlan isolated
 exit

! Configure community VLAN
vlan 102
 private-vlan community
 exit

! Configure promiscuous port
interface GigabitEthernet0/1
 description Gateway Port
 switchport mode private-vlan promiscuous
 switchport private-vlan mapping 100 101,102
 exit

! Configure isolated port
interface GigabitEthernet0/2
 description Isolated Server
 switchport mode private-vlan host
 switchport private-vlan host-association 100 101
 exit
```

### VLAN Access Control Lists

```cisco
! Create VLAN access map
vlan access-map BLOCK-TRAFFIC 10
 match ip address 100
 action drop
 exit

vlan access-map BLOCK-TRAFFIC 20
 action forward
 exit

! Create access list
access-list 100 permit tcp any host 10.0.20.100 eq 23

! Apply VLAN access map
vlan filter BLOCK-TRAFFIC vlan-list 20,30
```

### Guest VLAN Isolation

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

## VLAN Trunking Protocol (VTP)

### VTP Configuration

```cisco
! Configure VTP domain
vtp domain COMPANY
vtp password SecureVTPPass123

! Configure VTP mode
! Server mode (can create/modify/delete VLANs)
vtp mode server

! Client mode (receives VLAN info, cannot modify)
vtp mode client

! Transparent mode (forwards VTP, maintains own VLAN database)
vtp mode transparent

! Verify VTP status
show vtp status
```

### VTP Best Practices

```cisco
! Use VTP version 2
vtp version 2

! Use VTP transparent mode for better control
vtp mode transparent

! Or disable VTP completely
vtp mode off
```

## Troubleshooting VLANs

### Common Issues and Solutions

| Problem | Verification Command | Solution |
| ------- | -------------------- | -------- |
| No connectivity within VLAN | `show vlan brief` | Verify port VLAN assignment |
| No connectivity between VLANs | `show ip route` | Configure inter-VLAN routing |
| Trunk not passing traffic | `show interfaces trunk` | Add VLAN to allowed list |
| Native VLAN mismatch | `show interfaces trunk` | Match native VLAN on both ends |
| Port security violation | `show port-security interface` | Clear violation or add MAC |

### Verification Commands

```cisco
! Show all VLANs
show vlan brief

! Show specific VLAN
show vlan id 20

! Show VLAN on interface
show interfaces GigabitEthernet0/1 switchport

! Show trunk ports
show interfaces trunk

! Show MAC address table
show mac address-table

! Show MAC addresses for specific VLAN
show mac address-table vlan 20

! Show spanning tree for VLAN
show spanning-tree vlan 20

! Show IP routing (Layer 3 switch)
show ip route
show ip interface brief
```

### Debug Commands

```cisco
! Enable VLAN debugging (use with caution)
debug vlan packets
debug vlan events

! Disable debugging
undebug all
```

### Clear Commands

```cisco
! Clear MAC address table
clear mac address-table dynamic

! Clear MAC for specific VLAN
clear mac address-table dynamic vlan 20

! Clear MAC for specific interface
clear mac address-table dynamic interface GigabitEthernet0/1
```

## VLAN Best Practices

### Design Recommendations

1. **Native VLAN**: Change from default VLAN 1 to unused VLAN (e.g., 99)
2. **Management VLAN**: Use separate VLAN for device management
3. **Voice VLAN**: Separate voice traffic for QoS
4. **Guest VLAN**: Isolate guest traffic from internal network
5. **Trunk Pruning**: Only allow necessary VLANs on trunks
6. **VTP**: Use transparent mode or disable VTP for better control

### Security Best Practices

```cisco
! Disable unused ports and assign to unused VLAN
vlan 999
 name Unused
 exit

interface range GigabitEthernet0/11-24
 description Unused Ports
 switchport mode access
 switchport access vlan 999
 shutdown
 exit

! Change native VLAN on trunks
interface GigabitEthernet0/24
 switchport trunk native vlan 99
 exit

! Disable DTP
interface GigabitEthernet0/24
 switchport nonegotiate
 exit

! Enable port security on access ports
interface GigabitEthernet0/1
 switchport port-security
 switchport port-security maximum 2
 switchport port-security violation restrict
 switchport port-security mac-address sticky
 exit
```

### Performance Optimization

```cisco
! Enable rapid spanning tree
spanning-tree mode rapid-pvst

! Enable portfast on access ports
interface range GigabitEthernet0/1-10
 spanning-tree portfast
 exit

! Enable BPDU guard
interface range GigabitEthernet0/1-10
 spanning-tree bpduguard enable
 exit

! Disable spanning tree on trunk to server
interface GigabitEthernet0/5
 spanning-tree portfast trunk
 exit
```

## VLAN Naming Conventions

### Recommended VLAN Assignments

| VLAN ID | Name | Purpose |
| ------- | ---- | ------- |
| 1 | Default | Do not use (security) |
| 10 | Management | Device management |
| 20 | Servers | Application servers |
| 30 | Workstations | User devices |
| 40 | Guest | Guest network (isolated) |
| 50 | IoT | Internet of Things |
| 60 | VoIP | Voice over IP |
| 70 | DMZ | Demilitarized zone |
| 80 | Lab | Testing/lab environment |
| 90 | Transit | Inter-switch links |
| 99 | Native | Trunk native VLAN |
| 999 | Unused | Disabled ports |

## Related Topics

- [Cisco Configuration](configuration.md) - General device configuration
- [Cisco Overview](index.md) - Main Cisco documentation
- [VLAN Strategy](../vlans.md) - General VLAN concepts and design
- [Network Security](../security/index.md) - Security implementation
