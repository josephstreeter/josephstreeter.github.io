---
title: "Network Configuration Guides"
description: "Step-by-step guides for common network configuration tasks"
tags: ["networking", "configuration", "guides", "tutorials"]
category: "networking"
difficulty: "intermediate"
last_updated: "2025-12-29"
author: "Joseph Streeter"
---

Step-by-step guides for configuring network devices and implementing common network configurations.

## Overview

This section provides platform-agnostic configuration guides for common networking tasks. For platform-specific implementations, see:

- [Cisco Configuration](cisco/index.md) - Cisco IOS devices
- [Unifi Configuration](unifi/index.md) - Ubiquiti UniFi equipment
- HPE/Aruba Configuration (Coming soon)
- Juniper Configuration (Coming soon)

## Initial Device Setup

### Console Connection

Most network devices use serial console connections for initial configuration:

| Parameter | Common Value |
| --------- | ------------ |
| Baud Rate | 9600 or 115200 |
| Data Bits | 8 |
| Stop Bits | 1 |
| Parity | None |
| Flow Control | None |

### Basic Configuration Steps

1. **Physical Connection**
   - Connect console cable to device
   - Power on device and wait for boot

2. **Initial Access**
   - Use terminal software (PuTTY, SecureCRT, screen, minicom)
   - Configure serial port settings
   - Press Enter to activate console

3. **Essential Configuration**
   - Set hostname for device identification
   - Configure management IP address
   - Set strong passwords
   - Configure secure remote access (SSH)
   - Set timezone and NTP servers
   - Save configuration

### Platform-Specific Guides

- **Cisco IOS**: [Initial Device Setup](cisco/configuration.md#initial-device-setup)
- **UniFi**: [UniFi Controller Setup](unifi/index.md)

## VLAN Configuration

### VLAN Planning

Before implementing VLANs, plan your network segmentation:

1. **Identify Requirements**
   - Security zones (management, servers, users, guests)
   - Traffic types (data, voice, video)
   - Departmental or functional groups

2. **Assign VLAN IDs**
   - Document VLAN ID, name, subnet, and purpose
   - Reserve VLAN 1 (typically avoid using)
   - Use consistent naming across devices

3. **Design Inter-VLAN Routing**
   - Router-on-a-stick for small networks
   - Layer 3 switch for larger networks
   - Firewall for security policies

### Common VLAN Assignments

| VLAN ID | Name | Typical Use |
| ------- | ---- | ----------- |
| 10 | Management | Network device management |
| 20 | Servers | Application and file servers |
| 30 | Workstations | User computers |
| 40 | Guest | Guest network (isolated) |
| 50 | IoT | Internet of Things devices |
| 60 | VoIP | Voice over IP phones |
| 70 | DMZ | Public-facing servers |
| 99 | Native | Trunk native VLAN |

### VLAN Implementation Steps

1. **Create VLANs**
   - Define VLAN ID and name
   - Configure VLAN on all switches

2. **Assign Ports to VLANs**
   - Configure access ports for end devices
   - Assign appropriate VLAN to each port

3. **Configure Trunk Ports**
   - Connect switches with trunk links
   - Specify allowed VLANs on trunks
   - Set native VLAN (recommend non-default)

4. **Configure Inter-VLAN Routing**
   - Set up routing between VLANs
   - Configure IP addresses for each VLAN
   - Test connectivity between VLANs

### Platform-Specific Implementation

- **Cisco IOS**: [VLAN Configuration](cisco/vlans.md)
- **UniFi**: [UniFi VLANs](unifi/index.md)

For detailed VLAN strategy and design principles, see [VLAN Strategy](vlans.md).

## Home Lab Setup

### Equipment Needed

#### Minimum Setup

- 1x Managed switch (with VLAN support)
- 1x Router or firewall
- 2x Computers for testing

#### Recommended Setup

- 2x Managed switches
- 1x Router with multiple interfaces
- 1x Wireless access point
- 3+ Computers/devices

### Network Diagram

```text
Internet
   │
   ▼
[Router/Firewall]
   │
   ├─── VLAN 10: Management (192.168.10.0/24)
   ├─── VLAN 20: Servers (192.168.20.0/24)
   ├─── VLAN 30: Workstations (192.168.30.0/24)
   └─── VLAN 40: Guest (192.168.40.0/24)
```

### Configuration Steps

1. **Configure Router**
   - Set up WAN connection
   - Create VLAN subinterfaces or SVIs
   - Configure DHCP servers per VLAN
   - Set up NAT/masquerading

2. **Configure Switches**
   - Create VLANs on all switches
   - Configure trunk ports between switches
   - Assign access ports to appropriate VLANs

3. **Test Connectivity**
   - Verify VLAN assignment on each port
   - Test inter-VLAN routing
   - Verify internet access from each VLAN
   - Test isolation (guest VLAN shouldn't access internal)

## Platform-Specific Configuration

### Cisco Devices

Comprehensive Cisco IOS configuration guides:

- [Initial Device Setup](cisco/configuration.md#initial-device-setup)
- [VLAN Configuration](cisco/vlans.md)
- [Network Services](cisco/configuration.md#network-services-configuration)
- [Security Configuration](cisco/configuration.md#security-configuration)
- [Full Cisco Guide](cisco/index.md)

### UniFi Equipment

See the comprehensive [Unifi Configuration Guide](unifi/index.md) for:

- UniFi Dream Machine setup
- UniFi switches configuration
- UniFi access points
- Network application management

### HPE/Aruba

Coming soon: HPE ProCurve and Aruba configuration guides.

### Juniper

Coming soon: Juniper EX switches and SRX firewalls configuration guides.

## Network Services

### DHCP Server

Most networks require DHCP for automatic IP address assignment. Configure DHCP servers to:

- Assign IP addresses automatically
- Provide default gateway information
- Configure DNS servers
- Set lease duration
- Reserve addresses for static devices

See platform-specific guides for implementation:

- [Cisco DHCP Configuration](cisco/configuration.md#dhcp-server)

### DNS Configuration

DNS translates domain names to IP addresses. For DNS server setup, see:

- [Windows DNS](../../services/networkservices/dns/windows-dns/index.md)
- [BIND9](../../services/networkservices/dns/bind9-dns/index.md)

### NAT/PAT Configuration

Network Address Translation (NAT) allows private IP addresses to access the internet:

- **Static NAT**: One-to-one mapping
- **Dynamic NAT**: Pool of public IPs
- **PAT (Port Address Translation)**: Many-to-one with port mapping

See platform-specific guides:

- [Cisco NAT/PAT Configuration](cisco/configuration.md#natpat-configuration)

## Quality of Service (QoS)

QoS prioritizes network traffic to ensure critical applications receive adequate bandwidth:

- **Voice traffic**: Highest priority (typically 30% bandwidth)
- **Video traffic**: Medium-high priority (typically 20% bandwidth)
- **Data traffic**: Best effort

See platform-specific implementation:

- [Cisco QoS Configuration](cisco/configuration.md#quality-of-service-qos)

## Security Configuration

### Port Security

Restrict MAC addresses allowed on switch ports:

- Limit number of MAC addresses per port
- Define violation actions (restrict, shutdown, protect)
- Use sticky MAC learning for known devices

### Access Control Lists (ACLs)

Control traffic flow with ACLs:

- **Standard ACLs**: Filter by source IP address
- **Extended ACLs**: Filter by source/destination IP, protocol, port
- Apply inbound or outbound on interfaces

See platform-specific implementation:

- [Cisco Port Security](cisco/configuration.md#port-security)
- [Cisco ACLs](cisco/configuration.md#access-control-lists-acls)

## Related Topics

- [Network Fundamentals](fundamentals.md) - Core concepts
- [VLAN Strategy](vlans.md) - VLAN design and configuration
- [Network Architecture](architecture.md) - Design principles
- [Troubleshooting](troubleshooting.md) - Problem resolution
- [Automation](automation.md) - Automate configurations
