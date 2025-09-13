---
title: Home Lab Network Topology
description: Detailed network design with VLAN segmentation, security zones, and traffic flow for home lab infrastructure
author: Joseph Streeter
date: 2025-09-13
tags: [network-topology, vlan-design, network-security, unifi-networking]
---

Comprehensive network topology design for home lab infrastructure with security-focused VLAN segmentation and traffic controls.

## 🌐 Network Overview

### Design Principles

- **Security by Segmentation** - Isolate different service types
- **Performance Optimization** - Minimize broadcast domains
- **Scalability** - Room for growth and additional services
- **Manageability** - Clear naming and documentation standards
- **Cost Effectiveness** - Leverage UniFi ecosystem efficiently

### Physical Network Layout

```text
Internet (ISP)
    ↓ (WAN Connection)
UniFi Dream Machine Pro
    ├── Built-in Switch (8 ports)
    │   ├── Port 1: Uplink to Switch-24
    │   ├── Port 2: NAS Direct Connection
    │   ├── Port 3: Management Console
    │   └── Ports 4-8: Reserved
    ├── UniFi Switch 24-Port (Main Distribution)
    │   ├── Ports 1-4: Mini-PC Cluster (Proxmox Nodes)
    │   ├── Ports 5-8: Infrastructure Servers
    │   ├── Ports 9-16: Access Point Uplinks
    │   └── Ports 17-24: Future Expansion
    └── UniFi Switch 8-Port (Secondary)
        ├── Ports 1-4: IoT Devices
        ├── Ports 5-6: Security Cameras
        └── Ports 7-8: Additional Equipment
```

## 🏷️ VLAN Design

### Fall River Site Configuration

| VLAN ID | Name | Subnet | Purpose | Access Level |
|---------|------|--------|---------|--------------|
| 1 | Default | 192.168.1.0/24 | Native VLAN (Management) | Admin Only |
| 101 | Trusted | 192.168.101.0/24 | Administrative Workstations | Controlled |
| 103 | Secure | 192.168.103.0/24 | Core Infrastructure Services | Restricted |
| 104 | Guest | 192.168.104.0/24 | Guest Network | Internet Only |
| 105 | VPN | 192.168.105.0/24 | VPN Client Connections | Controlled |
| 106 | Device | 192.168.106.0/24 | Home Automation/IoT | Isolated |
| 107 | Cameras | 192.168.107.0/24 | Security Camera System | Isolated |
| 108 | Gaming | 192.168.108.0/24 | Gaming Consoles/Devices | Limited |
| 127 | Servers | 192.168.127.0/24 | Home Lab Servers | Internal |

### VLAN 1 - Default Network

**Purpose**: Native VLAN and network management

**Devices**:

- UniFi Dream Machine Pro management
- Network infrastructure management
- Initial device provisioning
- Emergency administrative access

**Security**:

- Administrative access only
- Default gateway for network equipment
- HTTPS management interfaces
- SSH access with key-based authentication

### VLAN 101 - Trusted Network

**Purpose**: Administrative workstations and trusted devices

**Devices**:

- Administrative laptops/workstations
- IT management devices
- Privileged user equipment
- Network administration tools

**Security**:

- Full network access (with firewall rules)
- Access to all VLANs for administration
- MFA required for sensitive operations
- Enhanced monitoring and logging

### VLAN 103 - Secure Network

**Purpose**: Core infrastructure and security services

**Services**:

- DNS servers (Primary/Secondary)
- Certificate Authority services
- Identity Management (Authentik)
- Security monitoring tools
- Critical infrastructure services
- Backup and recovery systems

**Security**:

- Highly restricted access
- Service-specific firewall rules
- No direct internet access
- Comprehensive audit logging
- Regular security assessments

### VLAN 104 - Guest Network

**Purpose**: Visitor and guest device access

**Features**:

- Internet access only
- Isolated from internal networks
- Captive portal authentication
- Bandwidth limitations
- Time-based access controls

**Security**:

- Complete isolation from internal VLANs
- No lateral movement capabilities
- Content filtering enabled
- Guest session logging

### VLAN 105 - VPN Network

**Purpose**: Remote access VPN client connections

**Services**:

- WireGuard VPN endpoint
- Remote user connectivity
- Site-to-site VPN connections
- Secure remote administration

**Security**:

- Controlled access based on user roles
- Certificate-based authentication
- Traffic encryption end-to-end
- Connection logging and monitoring

### VLAN 106 - Device Network

**Purpose**: IoT devices and home automation

**Devices**:

- Smart home devices
- IoT sensors and controllers
- Home automation hubs
- Environmental monitoring

**Security**:

- Isolated from other networks
- Internet access for updates only
- Device-specific firewall rules
- Network segmentation by device type

### VLAN 107 - Camera Network

**Purpose**: Security camera system

**Devices**:

- IP security cameras
- NVR (Network Video Recorder)
- Camera management systems
- Motion detection systems

**Security**:

- Completely isolated network
- No internet access for cameras
- Dedicated storage and recording
- Encrypted video streams

### VLAN 108 - Gaming Network

**Purpose**: Gaming consoles and entertainment devices

**Devices**:

- Gaming consoles (PlayStation, Xbox, etc.)
- Gaming PCs
- Streaming devices
- Entertainment systems

**Features**:

- Optimized for low latency
- QoS prioritization for gaming traffic
- UPnP enabled for console features
- Streaming service access

### VLAN 127 - Server Network

**Purpose**: Home lab servers and compute resources

**Services**:

- Proxmox virtualization cluster
- Docker container hosts
- Application servers
- Development and testing environments
- Media servers
- File and storage services

**Security**:

- Internal network access only
- Service-specific external access via reverse proxy
- Regular backup and disaster recovery
- Performance monitoring and alerting

## 🔥 Firewall Rules

### Inter-VLAN Communication Matrix

| Source → Target | Default | Trusted | Secure | Guest | VPN | Device | Cameras | Gaming | Servers |
|-----------------|---------|---------|--------|-------|-----|--------|---------|--------|---------|
| **Default (1)** | ✅ Full | ✅ Admin | ✅ Admin | ❌ Block | ✅ Admin | ✅ Admin | ✅ Admin | ✅ Admin | ✅ Admin |
| **Trusted (101)** | ✅ Admin | ✅ Full | ✅ Admin | ❌ Block | ✅ Admin | ✅ Admin | ✅ Admin | ✅ Full | ✅ Admin |
| **Secure (103)** | ✅ Limited | ❌ Block | ✅ Service | ❌ Block | ❌ Block | ❌ Block | ❌ Block | ❌ Block | ✅ Service |
| **Guest (104)** | ❌ Block | ❌ Block | ✅ DNS | ✅ Full | ❌ Block | ❌ Block | ❌ Block | ❌ Block | ❌ Block |
| **VPN (105)** | ❌ Block | ✅ Limited | ✅ Service | ❌ Block | ✅ Full | ❌ Block | ❌ Block | ❌ Block | ✅ Service |
| **Device (106)** | ❌ Block | ❌ Block | ✅ DNS/NTP | ❌ Block | ❌ Block | ✅ Full | ❌ Block | ❌ Block | ❌ Block |
| **Cameras (107)** | ❌ Block | ❌ Block | ❌ Block | ❌ Block | ❌ Block | ❌ Block | ✅ Full | ❌ Block | ✅ NVR |
| **Gaming (108)** | ❌ Block | ❌ Block | ✅ DNS | ❌ Block | ❌ Block | ❌ Block | ❌ Block | ✅ Full | ❌ Block |
| **Servers (127)** | ❌ Block | ✅ Admin | ✅ Service | ❌ Block | ✅ Service | ❌ Block | ❌ Block | ❌ Block | ✅ Full |

### Firewall Rule Examples

```bash
# Default VLAN (1) - Management access to all networks
allow from 192.168.1.0/24 to any port any

# Trusted VLAN (101) - Administrative workstations
allow from 192.168.101.0/24 to any port 22,80,443,3389
allow from 192.168.101.0/24 to 192.168.127.0/24 port any

# Secure VLAN (103) - Core services
allow from 192.168.103.0/24 to 192.168.127.0/24 port 53,389,443,636
allow from 192.168.103.0/24 to any port 80,443,53 # Internet for updates

# Guest VLAN (104) - Internet only
allow from 192.168.104.0/24 to 192.168.103.0/24 port 53
allow from 192.168.104.0/24 to any port 80,443 # Internet access
deny from 192.168.104.0/24 to 192.168.0.0/16 port any # Block internal

# VPN VLAN (105) - Remote access
allow from 192.168.105.0/24 to 192.168.103.0/24 port 53,389
allow from 192.168.105.0/24 to 192.168.127.0/24 port 22,80,443

# Device VLAN (106) - IoT devices
allow from 192.168.106.0/24 to 192.168.103.0/24 port 53,123
deny from 192.168.106.0/24 to 192.168.0.0/16 port any except 103

# Cameras VLAN (107) - Security cameras
allow from 192.168.107.0/24 to 192.168.127.0/24 port 554,80,443 # NVR access
deny from 192.168.107.0/24 to any port any # No internet

# Gaming VLAN (108) - Gaming devices
allow from 192.168.108.0/24 to 192.168.103.0/24 port 53
allow from 192.168.108.0/24 to any port 80,443,3074,1935 # Gaming ports

# Servers VLAN (127) - Home lab servers
allow from 192.168.127.0/24 to 192.168.103.0/24 port 53,389,443
allow from 192.168.127.0/24 to any port 80,443,53 # Internet for updates
```

## 📡 Wireless Network Design

### Access Point Placement

```text
Fall River Home Layout
Main Floor
├── AP-1 (Living Room) - Primary coverage
├── AP-2 (Kitchen) - High-density area
└── AP-3 (Home Office) - Administrative access

Floor 2 (if applicable)
├── AP-4 (Master Bedroom) - Extended coverage
└── AP-5 (Guest Room) - Guest access

Each AP broadcasts:
├── HomeNet-Trusted (VLAN 101) - Administrative devices
├── HomeNet-Secure (VLAN 103) - Infrastructure access
├── HomeNet-IoT (VLAN 106) - Smart home devices
├── HomeNet-Gaming (VLAN 108) - Gaming devices
└── HomeNet-Guest (VLAN 104) - Guest access
```

### SSID Configuration

| SSID Name | VLAN | Security | Purpose |
|-----------|------|----------|---------|
| HomeNet-Trusted | 101 | WPA3-Enterprise + MAC filtering | Administrative devices |
| HomeNet-Secure | 103 | WPA3-Enterprise + Certificates | Infrastructure access |
| HomeNet-IoT | 106 | WPA3-PSK | Smart home devices |
| HomeNet-Gaming | 108 | WPA3-PSK | Gaming consoles |
| HomeNet-Guest | 104 | WPA3-PSK + Captive Portal | Guest access |
| HomeNet-VPN | 105 | WPA3-Enterprise | VPN client access |

## 🔄 Traffic Flow Patterns

### Typical Traffic Flows

1. **Administrative Access**

   ```text
   Admin Device (VLAN 101) → Proxmox Node (VLAN 127) → VM Management
   ```

2. **IoT Device → Smart Home Hub**

   ```text
   IoT Device (VLAN 106) → Home Assistant (VLAN 127) → Database (VLAN 103)
   ```

3. **Gaming Console → Internet**

   ```text
   Gaming Device (VLAN 108) → DNS (VLAN 103) → Internet Gateway
   ```

4. **VPN Client → Internal Services**

   ```text
   VPN Client (VLAN 105) → Authentication (VLAN 103) → Server (VLAN 127)
   ```

5. **Security Camera → NVR**

   ```text
   IP Camera (VLAN 107) → NVR Server (VLAN 127) → Storage
   ```

### Load Balancing Strategy

- **DNS Round Robin** - For multiple instances of services
- **Nginx Load Balancing** - For web applications
- **Proxmox HA** - For VM failover
- **UniFi Load Balancing** - For wireless clients

## 📊 Monitoring and Visibility

### Network Monitoring Points

- **UniFi Controller** - Wireless and switch monitoring
- **Prometheus/Grafana** - Network metrics and alerting
- **PRTG or LibreNMS** - SNMP monitoring
- **Wazuh** - Security event correlation

### Key Metrics

- **Bandwidth Utilization** - Per VLAN and interface
- **Connection Counts** - Active sessions and flows
- **Error Rates** - Packet loss and retransmissions
- **Security Events** - Blocked connections and intrusions

## 🔧 Implementation Notes

### Fall River Site Specifics

- **Location**: Fall River home lab
- **Network Range**: 192.168.x.0/24 (where x = VLAN ID)
- **Gateway**: UniFi Dream Machine Pro
- **Primary DNS**: 192.168.103.1 (Internal)
- **Secondary DNS**: 8.8.8.8, 1.1.1.1 (External)

### Security Considerations

- **Default Deny**: All inter-VLAN communication blocked by default
- **Explicit Allow**: Only required services permitted
- **Monitoring**: All traffic logged and monitored
- **Updates**: Regular security patching and updates

---

> **💡 Pro Tip**: Start with a simple VLAN design and add complexity gradually. Proper documentation and labeling are crucial for troubleshooting and maintenance.

*This network topology provides security through segmentation while maintaining flexibility for growth and experimentation in the Fall River home lab environment.*
