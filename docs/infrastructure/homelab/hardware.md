---
title: "Home Lab Hardware Requirements and Setup"
description: "Comprehensive guide to hardware selection, specifications, and setup procedures for home lab infrastructure"
author: "Joseph Streeter"
tags: ["hardware-requirements", "mini-pc-cluster", "network-hardware", "storage-planning"]
category: "infrastructure"
last_updated: "2025-09-13"
---

Complete hardware selection and setup guide for building a production-ready home lab with enterprise features on a budget.

## 🖥️ **Compute Infrastructure**

### Mini PC Cluster Specifications

### Primary Configuration (2-4 Node Cluster)

| Component | Specification | Quantity | Purpose |
|-----------|---------------|----------|---------|
| **CPU** | Intel i5-12th Gen or AMD Ryzen 5 5600G | 2-4 units | Proxmox compute nodes |
| **RAM** | 32GB DDR4-3200 (2x16GB) | 2-4 sets | VM workloads + overhead |
| **Storage** | 1TB NVMe SSD (primary) | 2-4 drives | OS + VM storage |
| **Storage** | 2TB NVMe SSD (secondary) | Optional | Additional VM storage |
| **Network** | Gigabit Ethernet (onboard) | Built-in | Cluster networking |

### Recommended Mini PC Models

#### Budget Option ($400-600 per unit)

- **Beelink SER5 Max** - AMD Ryzen 5 5560U, upgradeable to 64GB RAM
- **GEEKOM Mini IT11** - Intel i5-1135G7, dual NVMe slots  
- **NiPoGi AK1 PLUS** - Intel N95, good for lightweight workloads

#### Performance Option ($700-1000 per unit)

- **Minisforum EliteMini UM690** - AMD Ryzen 9 6900HX, 64GB RAM support
- **Intel NUC 12 Pro** - Intel i7-1260P, excellent build quality
- **ASUS PN52** - AMD Ryzen 7 5700U, compact and reliable

#### Enterprise Option ($1000+ per unit)

- **Intel NUC 13 Extreme** - Desktop-class performance
- **Lenovo ThinkCentre M75q Tiny** - Enterprise support and warranty
- **HP EliteDesk 805 G8** - vPro features and management

### Memory Configuration Strategy

```text
Memory Allocation Guidelines:

Node Configuration (32GB Total):
├── Proxmox Host: 4-6GB
├── VM Overhead: 2-4GB
├── Available for VMs: 22-26GB
└── Emergency Reserve: 2GB

Typical VM Allocations:
├── Linux Services: 1-4GB each
├── Windows VMs: 4-8GB each
├── Container Hosts: 2-6GB each
└── Database/Storage: 4-16GB each
```

### Storage Planning

**Local Storage Strategy:**

- **500GB NVMe** - Proxmox OS and system VMs
- **1TB NVMe** - Application VMs and containers
- **External NAS** - Backup, templates, and bulk storage

**Performance Considerations:**

- **IOPS Requirements** - 3000+ for database workloads
- **Throughput** - 200MB/s+ for file operations
- **Latency** - <10ms for interactive applications

## 🌐 **Network Infrastructure**

### UniFi Equipment Selection

**Core Network Components:**

| Device | Model | Price Range | Purpose |
|--------|-------|-------------|---------|
| **Gateway** | UDM Pro / UDM SE | $350-500 | Router, firewall, controller |
| **Main Switch** | USW-24-PoE | $400-500 | Primary distribution |
| **Access Switch** | USW-Flex-Mini | $30-50 | Small device connections |
| **Access Points** | U6-Lite / U6-LR | $100-150 | Wireless coverage |
| **Security** | UniFi Protect cameras | $100-300 | Video surveillance |

### Network Topology Design

```text
Physical Network Layout:

Internet (ISP Modem)
    ↓ (Ethernet WAN)
UDM Pro (Router/Firewall/Controller)
    ├── Built-in Switch (8 ports)
    │   ├── Port 1: Uplink to USW-24-PoE
    │   ├── Port 2: NAS Direct Connection
    │   └── Ports 3-8: Critical devices
    │
    ├── USW-24-PoE (Main Distribution)
    │   ├── Ports 1-4: Mini-PC Cluster
    │   ├── Ports 5-8: Access Point uplinks
    │   ├── Ports 9-16: Server connections
    │   └── Ports 17-24: Future expansion
    │
    └── Wireless Networks
        ├── HomeNet-Trusted (VLAN 101)
        ├── HomeNet-IoT (VLAN 106)
        ├── HomeNet-Gaming (VLAN 108)
        └── HomeNet-Guest (VLAN 104)
```

### Cable Management and Organization

**Structured Cabling Plan:**

- **Cat6A cables** for all permanent connections
- **Keystone patch panel** for organized terminations
- **Cable management** with proper labeling
- **Spare capacity** for 50% growth

## 💾 **Storage Solutions**

### NAS Configuration

**Recommended NAS Options:**

| Option | Specification | Capacity | Use Case |
|--------|---------------|----------|----------|
| **Synology DS920+** | 4-bay, Intel Celeron | 16-64TB | Home/small office |
| **QNAP TS-464** | 4-bay, Intel Celeron | 16-64TB | Performance focus |
| **TrueNAS Mini** | 4-bay, custom build | 16-128TB | Enterprise features |

### Drive Configuration

**Primary Storage Pool:**

- **2x 4TB WD Red Pro** - RAID 1 for reliability
- **Purpose** - VM storage, backups, file shares
- **Performance** - 180MB/s sustained, <15ms latency

**Backup Storage Pool:**

- **1x 8TB WD Elements** - USB 3.0 external
- **Purpose** - Offline backups, archive storage
- **Rotation** - Weekly backup cycles

### Storage Network Design

```text
Storage Architecture:

Mini PC Cluster
    ├── Local NVMe (Fast, Ephemeral)
    ├── NFS/iSCSI to NAS (Persistent)
    └── Backup to External (Archive)

NAS Services:
├── NFS exports for VM storage
├── iSCSI LUNs for databases
├── SMB shares for file access
└── Backup targets for VMs
```

## ⚡ **Power and Cooling**

### Power Requirements

**Power Consumption Analysis:**

| Component | Idle Power | Max Power | Annual Cost* |
|-----------|------------|-----------|--------------|
| Mini PC (each) | 15W | 45W | $35-50 |
| UDM Pro | 25W | 45W | $45-65 |
| Switch 24-PoE | 35W | 150W | $60-180 |
| NAS 4-bay | 30W | 80W | $50-95 |
| **Total System** | **140W** | **470W** | **$250-500** |

*Based on $0.12/kWh electricity rate

### UPS Recommendations

**APC Smart-UPS SMC1500** (1440VA/980W)

- **Runtime** - 15-20 minutes at full load
- **Features** - Network management, USB monitoring
- **Cost** - $300-400

**CyberPower CP1500PFCLCD** (1500VA/1000W)

- **Runtime** - 20-25 minutes at full load
- **Features** - Pure sine wave, LCD display
- **Cost** - $200-300

### Cooling Considerations

**Rack Cooling Strategy:**

- **Ambient Temperature** - Maintain 65-75°F
- **Airflow** - Front-to-back ventilation
- **Hot Aisle/Cold Aisle** - Even in small setups
- **Monitoring** - Temperature sensors and alerts

## 🔧 **Assembly and Setup**

### Hardware Assembly Checklist

**Pre-Assembly Preparation:**

- [ ] Verify all components and compatibility
- [ ] Prepare assembly workspace with proper lighting
- [ ] Gather necessary tools (screwdrivers, anti-static)
- [ ] Download latest firmware and drivers

**Mini PC Setup Sequence:**

1. **Memory Installation**
   - Install RAM in dual-channel configuration
   - Verify compatibility with CPU and motherboard
   - Test with memory diagnostic tools

2. **Storage Installation**
   - Install primary NVMe SSD in slot 1
   - Install secondary storage if available
   - Verify secure mounting and connections

3. **Initial Boot and BIOS**
   - Configure boot order and security settings
   - Enable virtualization extensions (VT-x/AMD-V)
   - Set memory and CPU performance profiles

4. **Network Configuration**
   - Test Ethernet connectivity
   - Verify link speed (1Gbps)
   - Configure static IP for management

### Rack Planning

**42U Rack Layout Example:**

```text
Rack Unit Allocation:

 42U ┌─────────────────────┐
     │     Future Space    │
 35U ├─────────────────────┤
     │   Patch Panel 24    │
 34U ├─────────────────────┤
     │   Switch USW-24     │
 33U ├─────────────────────┤
     │     UDM Pro        │
 32U ├─────────────────────┤
     │   Shelf (Mini PCs)  │
 31U ├─────────────────────┤
     │   Shelf (Mini PCs)  │
 30U ├─────────────────────┤
     │      NAS Unit      │
 29U ├─────────────────────┤
     │    UPS Battery     │
 28U ├─────────────────────┤
     │     UPS Unit       │
 27U ├─────────────────────┤
     │   Cable Mgmt       │
  1U └─────────────────────┘
```

## 💰 **Budget Planning**

### Cost Breakdown by Phase

**Phase 1 - Core Infrastructure ($1,500-2,500):**

- 2x Mini PCs with 32GB RAM each
- UDM Pro or equivalent
- Basic switch (8-16 ports)
- Essential cables and rack

**Phase 2 - Enhanced Services ($1,000-1,500):**

- Additional Mini PC for HA
- 24-port managed switch
- NAS with initial storage
- UPS for power protection

**Phase 3 - Advanced Features ($800-1,200):**

- Additional access points
- Security cameras
- Monitoring hardware
- Backup storage expansion

### Cost Optimization Strategies

**Money-Saving Tips:**

- **Buy used enterprise equipment** - HP/Dell mini PCs
- **Bulk purchases** - RAM and storage upgrades
- **Sales timing** - Black Friday, end-of-fiscal-year
- **Modular approach** - Start small and expand

**Long-term Investment:**

- **Quality networking** - UniFi gear holds value
- **Expandable storage** - Plan for growth
- **Standardization** - Consistent hardware reduces complexity

---

> **💡 Pro Tip**: Start with a 2-node cluster and expand as you learn. Focus on getting the networking foundation right first - everything else builds on top of that.

*This hardware foundation provides the reliability and performance needed for serious home lab projects while maintaining reasonable costs.*
