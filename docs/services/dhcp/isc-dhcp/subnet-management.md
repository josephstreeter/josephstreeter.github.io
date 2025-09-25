---
title: ISC DHCP Subnet Management
description: Managing subnets, pools, and address ranges in ISC DHCP Server configurations
author: Joseph Streeter
date: 2025-09-12
tags: [isc-dhcp-subnets, dhcp-pools, network-management]
---

Comprehensive guide to managing subnets and address pools in ISC DHCP Server.

## 🌐 Subnet Declarations

### Basic Subnet Configuration

```bash
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 192.168.1.10, 192.168.1.11;
    option domain-name "example.com";
    default-lease-time 86400;
    max-lease-time 172800;
}
```

### Multiple Address Ranges

```bash
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.150;
    range 192.168.1.200 192.168.1.250;
    option routers 192.168.1.1;
}
```

---

> **💡 Pro Tip**: Use multiple ranges to exclude static IP addresses while maintaining continuous DHCP service.

*Effective subnet management ensures optimal IP address distribution and network organization.*
