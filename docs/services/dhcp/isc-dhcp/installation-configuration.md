---
title: ISC DHCP Installation & Configuration
description: Step-by-step guide to installing and configuring ISC DHCP Server on Linux systems
author: Joseph Streeter
date: 2025-09-12
tags: [isc-dhcp-installation, linux-dhcp-setup, dhcp-configuration]
---

Complete guide for installing and configuring ISC DHCP Server on various Linux distributions.

## 📦 Installation

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install isc-dhcp-server
```

### CentOS/RHEL/Rocky Linux

```bash
sudo dnf install dhcp-server
```

## ⚙️ Initial Configuration

### Edit Configuration File

```bash
sudo nano /etc/dhcp/dhcpd.conf
```

### Basic Configuration

```bash
# Global settings
default-lease-time 86400;
max-lease-time 172800;
authoritative;

# Subnet configuration
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 192.168.1.10;
    option domain-name "example.com";
}
```

### Start Service

```bash
sudo systemctl enable isc-dhcp-server
sudo systemctl start isc-dhcp-server
```

---

> **💡 Pro Tip**: Always validate configuration with `dhcpd -t` before starting the service.

*This installation guide covers the essential steps for deploying ISC DHCP Server in Linux environments.*
