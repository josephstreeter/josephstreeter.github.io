---
title: ISC DHCP Server
description: Comprehensive guide to Internet Systems Consortium (ISC) DHCP Server implementation and management on Linux systems
author: Joseph Streeter
date: 2025-09-12
tags: [isc-dhcp, linux-dhcp, dhcp-server, dhcp-configuration, enterprise-networking]
---

ISC DHCP Server is the most widely used DHCP server implementation for Unix and Linux systems, providing robust and flexible DHCP services.

## 🚀 Quick Start

### Installation

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install isc-dhcp-server

# CentOS/RHEL/Rocky Linux
sudo dnf install dhcp-server

# Verify installation
dhcpd --version
```

### Basic Configuration

```bash
# Edit main configuration file
sudo nano /etc/dhcp/dhcpd.conf

# Basic subnet configuration
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 192.168.1.10, 192.168.1.11;
    option domain-name "example.com";
    default-lease-time 86400;
    max-lease-time 172800;
}
```

## 📋 Core Topics

### 🛠️ **Installation & Configuration**

- [**Installation & Configuration**](installation-configuration.md) - Complete setup guide
- Package installation and initial setup
- Service configuration and startup
- Basic subnet configuration

### 🌐 **Subnet Management**

- [**Subnet Management**](subnet-management.md) - Network configuration
- Subnet declarations and pools
- Address range management
- Multi-subnet configurations

### ⚙️ **Advanced Configuration**

- [**Advanced Configuration**](advanced-configuration.md) - Enterprise features
- Host reservations and classes
- Custom DHCP options
- Failover and clustering

### 🔧 **Troubleshooting**

- [**Troubleshooting**](troubleshooting.md) - Diagnostic procedures
- Log analysis and debugging
- Common configuration issues
- Performance optimization

## 🏗️ **Configuration Structure**

### Global Configuration

```bash
# Global options apply to all subnets
default-lease-time 86400;
max-lease-time 172800;
authoritative;

# DNS settings
option domain-name "example.com";
option domain-name-servers 192.168.1.10, 192.168.1.11;

# Logging
log-facility local7;
```

### Subnet Declaration

```bash
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option broadcast-address 192.168.1.255;
    default-lease-time 86400;
}
```

## 📊 **Management Commands**

### Service Management

```bash
# Start/stop/restart service
sudo systemctl start isc-dhcp-server
sudo systemctl stop isc-dhcp-server
sudo systemctl restart isc-dhcp-server

# Enable auto-start
sudo systemctl enable isc-dhcp-server

# Check service status
sudo systemctl status isc-dhcp-server
```

### Lease Management

```bash
# View active leases
sudo dhcp-lease-list

# Check lease file
sudo cat /var/lib/dhcp/dhcpd.leases

# Monitor DHCP logs
sudo tail -f /var/log/syslog | grep dhcpd
```

## 🔧 **Common Configurations**

### Host Reservations

```bash
host printer-01 {
    hardware ethernet 00:11:22:33:44:55;
    fixed-address 192.168.1.50;
    option host-name "printer-01";
}
```

### Multiple Subnets

```bash
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
}

subnet 192.168.2.0 netmask 255.255.255.0 {
    range 192.168.2.100 192.168.2.200;
    option routers 192.168.2.1;
}
```

---

> **💡 Pro Tip**: Always test configuration changes with `dhcpd -t -cf /etc/dhcp/dhcpd.conf` before restarting the service to avoid service disruption.

*ISC DHCP Server provides enterprise-grade DHCP services with extensive configuration flexibility for Linux environments.*
