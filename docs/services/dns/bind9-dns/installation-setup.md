---
title: BIND9 Installation & Setup
description: Complete installation and initial configuration guide for BIND9 DNS Server on Linux systems
author: Joseph Streeter
date: 2025-09-12
tags: [bind9-installation, dns-setup, linux-dns, bind-configuration]
---

Step-by-step installation and configuration guide for BIND9 DNS Server on Linux systems.

## 📦 Installation

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install bind9 bind9utils bind9-doc
```

### CentOS/RHEL/Rocky Linux

```bash
sudo dnf install bind bind-utils
```

## ⚙️ Initial Configuration

### Main Configuration File

```bash
# Edit main configuration
sudo nano /etc/bind/named.conf.options

# Basic configuration
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-recursion { 192.168.1.0/24; };
    listen-on { 192.168.1.10; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    dnssec-validation auto;
};
```

### Service Management

```bash
# Start and enable BIND9
sudo systemctl start named
sudo systemctl enable named

# Check service status
sudo systemctl status named
```

---

> **💡 Pro Tip**: Always test configuration with `named-checkconf` before restarting the service to avoid service disruption.

*Proper installation and initial configuration provide a solid foundation for BIND9 DNS services.*
