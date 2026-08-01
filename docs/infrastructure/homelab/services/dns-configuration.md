---
title: DNS Infrastructure for Home Lab
description: Complete DNS server configuration with BIND9, including forward/reverse zones, security, and high availability
author: Joseph Streeter
date: 2025-09-13
tags: [dns-server, bind9, dns-configuration, network-infrastructure]
---

Comprehensive DNS infrastructure setup for home lab environments with enterprise-grade features and security.

## 🎯 **DNS Architecture Overview**

### Design Goals

- **High Availability** - Primary/Secondary DNS servers with failover
- **Security** - DNS filtering, DNSSEC, and access controls
- **Performance** - Caching, forwarding, and optimized responses
- **Monitoring** - Comprehensive logging and metrics collection
- **Integration** - Seamless integration with home lab services

### DNS Server Topology

```text
DNS Infrastructure Layout:

Internet DNS (1.1.1.1, 8.8.8.8)
    ↑ (Upstream queries)
Home Router/Firewall
    ↓ (Local DNS queries)
┌─────────────────────────────────────┐
│         Home Lab DNS Cluster        │
├─────────────────┬───────────────────┤
│   Primary DNS   │   Secondary DNS   │
│  192.168.103.10  │  192.168.103.11    │
│   (Master)      │    (Slave)        │
└─────────────────┴───────────────────┘
    ↓ (Zone transfers and queries)
Internal Network Clients
├── Default VLAN (192.168.1.0/24)
├── Trusted VLAN (192.168.101.0/24)
├── Secure VLAN (192.168.103.0/24)
├── Device VLAN (192.168.106.0/24)
└── Servers VLAN (192.168.127.0/24)
```

## 🖥️ **Primary DNS Server Configuration**

### Initial Server Setup

#### System Requirements

- **VM Specifications**: 2 vCPU, 2GB RAM, 20GB storage
- **Operating System**: Ubuntu 22.04 LTS
- **Network**: Static IP 192.168.103.10/24
- **VLAN**: Secure VLAN (103)

#### Base Installation

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install BIND9 and utilities
sudo apt install -y bind9 bind9utils bind9-doc

# Install monitoring and security tools
sudo apt install -y fail2ban ufw prometheus-node-exporter

# Create DNS admin user
sudo useradd -m -s /bin/bash dnsadmin
sudo usermod -aG sudo dnsadmin
```

### BIND9 Configuration

#### Main Configuration (/etc/bind/named.conf)

```bash
# /etc/bind/named.conf
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";

# Logging configuration
include "/etc/bind/named.conf.logging";

# Security configurations
include "/etc/bind/named.conf.security";
```

#### Options Configuration (/etc/bind/named.conf.options)

```bash
# /etc/bind/named.conf.options
options {
    # Working directory
    directory "/var/cache/bind";
    
    # DNS port
    listen-on port 53 { 
        127.0.0.1; 
        192.168.103.10; 
    };
    listen-on-v6 { none; };
    
    # Allowed clients
    allow-query { 
        localhost; 
        192.168.0.0/16; 
        10.0.0.0/8;
    };
    
    # Allow recursion for internal networks
    allow-recursion { 
        localhost; 
        192.168.0.0/16; 
        10.0.0.0/8;
    };
    
    # Forwarders for external queries
    forwarders {
        1.1.1.1;        # Cloudflare
        1.0.0.1;        # Cloudflare
        8.8.8.8;        # Google
        8.8.4.4;        # Google
    };
    
    # Enable DNS forwarding
    forward first;
    
    # Cache settings
    max-cache-size 256M;
    max-cache-ttl 86400;
    max-ncache-ttl 3600;
    
    # Security settings
    dnssec-validation auto;
    auth-nxdomain no;
    
    # Performance tuning
    recursive-clients 1000;
    tcp-clients 100;
    
    # Disable version information
    version none;
    hostname none;
    server-id none;
};
```

#### Local Zones Configuration (/etc/bind/named.conf.local)

```bash
# /etc/bind/named.conf.local

# Forward zone for homelab.local
zone "homelab.local" {
    type master;
    file "/etc/bind/zones/db.homelab.local";
    allow-transfer { 192.168.103.11; };  # Secondary DNS
    notify yes;
    also-notify { 192.168.103.11; };
};

# Reverse zone for 192.168.103.0/24 (Secure VLAN)
zone "103.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.192.168.103";
    allow-transfer { 192.168.103.11; };
    notify yes;
    also-notify { 192.168.103.11; };
};

# Reverse zone for 192.168.127.0/24 (Servers VLAN)
zone "127.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.192.168.127";
    allow-transfer { 192.168.103.11; };
    notify yes;
    also-notify { 192.168.103.11; };
};

# Reverse zone for 192.168.1.0/24 (Default VLAN)
zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.192.168.1";
    allow-transfer { 192.168.103.11; };
    notify yes;
    also-notify { 192.168.103.11; };
};
```

### Zone File Configuration

#### Forward Zone (/etc/bind/zones/db.homelab.local)

```bash
# /etc/bind/zones/db.homelab.local
$TTL    86400
@       IN      SOA     dns-primary.homelab.local. admin.homelab.local. (
                        2024091301      ; Serial (YYYYMMDDNN)
                        3600            ; Refresh
                        1800            ; Retry
                        604800          ; Expire
                        86400 )         ; Negative Cache TTL

; Name servers
@       IN      NS      dns-primary.homelab.local.
@       IN      NS      dns-secondary.homelab.local.

; A records for infrastructure
dns-primary     IN      A       192.168.103.10
dns-secondary   IN      A       192.168.103.11
ntp             IN      A       192.168.103.12

; Management infrastructure
proxmox-01      IN      A       192.168.101.10
proxmox-02      IN      A       192.168.101.11
proxmox-03      IN      A       192.168.101.12
proxmox-cluster IN      A       192.168.101.10
                IN      A       192.168.101.11
                IN      A       192.168.101.12

; Network infrastructure
router          IN      A       192.168.1.1
switch-main     IN      A       192.168.101.20
switch-access   IN      A       192.168.101.21
ap-main         IN      A       192.168.101.30
ap-office       IN      A       192.168.101.31

; Core services
auth            IN      A       192.168.103.20
ca              IN      A       192.168.103.21
backup          IN      A       192.168.103.22
monitoring      IN      A       192.168.103.30

; Monitoring stack
prometheus      IN      A       192.168.103.30
grafana         IN      A       192.168.103.31
alertmanager    IN      A       192.168.103.32
loki            IN      A       192.168.103.33

; Application services
web-01          IN      A       192.168.104.10
web-02          IN      A       192.168.104.11
app-01          IN      A       192.168.104.20
app-02          IN      A       192.168.104.21
db-01           IN      A       192.168.106.30
db-02           IN      A       192.168.106.31

; Service aliases
www             IN      CNAME   web-01.homelab.local.
wiki            IN      CNAME   app-01.homelab.local.
files           IN      CNAME   app-02.homelab.local.
database        IN      CNAME   db-01.homelab.local.

; External services
external-web    IN      A       192.168.105.100
api             IN      A       192.168.105.101

; IoT and automation
homeassistant   IN      A       192.168.107.10
iot-hub         IN      A       192.168.107.11
security-cam-01 IN      A       192.168.107.20
security-cam-02 IN      A       192.168.107.21

; Wildcard for dynamic services
*.apps          IN      A       192.168.104.200
*.dev           IN      A       192.168.104.201
```

#### Reverse Zone for Services (/etc/bind/zones/db.192.168.103)

```bash
# /etc/bind/zones/db.192.168.103
$TTL    86400
@       IN      SOA     dns-primary.homelab.local. admin.homelab.local. (
                        2024091301      ; Serial
                        3600            ; Refresh
                        1800            ; Retry
                        604800          ; Expire
                        86400 )         ; Negative Cache TTL

; Name servers
@       IN      NS      dns-primary.homelab.local.
@       IN      NS      dns-secondary.homelab.local.

; PTR records for secure VLAN
10      IN      PTR     dns-primary.homelab.local.
11      IN      PTR     dns-secondary.homelab.local.
12      IN      PTR     ntp.homelab.local.
20      IN      PTR     auth.homelab.local.
21      IN      PTR     ca.homelab.local.
22      IN      PTR     backup.homelab.local.
30      IN      PTR     prometheus.homelab.local.
31      IN      PTR     grafana.homelab.local.
32      IN      PTR     alertmanager.homelab.local.
33      IN      PTR     loki.homelab.local.
```

### Security Configuration

#### BIND9 Security Settings (/etc/bind/named.conf.security)

```bash
# /etc/bind/named.conf.security

# Rate limiting to prevent abuse
rate-limit {
    responses-per-second 10;
    window 5;
    slip 2;
};

# Access control lists
acl "internal" {
    127.0.0.0/8;
    192.168.0.0/16;
    10.0.0.0/8;
};

acl "trusted" {
    127.0.0.1;
    192.168.103.0/24;   # Secure VLAN
    192.168.1.0/24;     # Default VLAN
    192.168.101.0/24;   # Trusted VLAN
};

# Disable unnecessary queries
allow-query-cache { "internal"; };
allow-transfer { "trusted"; };
allow-update { none; };

# Blackhole bad actors
blackhole {
    bogon-networks;
};
```

#### Firewall Configuration

```bash
# Configure UFW firewall
sudo ufw allow from 192.168.0.0/16 to any port 53
sudo ufw allow from 10.0.0.0/8 to any port 53
sudo ufw allow from 127.0.0.1 to any port 53

# Allow zone transfers from secondary
sudo ufw allow from 192.168.103.11 to any port 53

# SSH access from trusted networks
sudo ufw allow from 192.168.1.0/24 to any port 22
sudo ufw allow from 192.168.101.0/24 to any port 22

# Enable firewall
sudo ufw --force enable
```

## 🔄 **Secondary DNS Server Configuration**

### Secondary Server Setup

#### Configuration (/etc/bind/named.conf.local)

```bash
# /etc/bind/named.conf.local on secondary server

# Forward zone (slave)
zone "homelab.local" {
    type slave;
    file "/var/cache/bind/db.homelab.local";
    masters { 192.168.103.10; };
};

# Reverse zones (slave)
zone "103.168.192.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.192.168.103";
    masters { 192.168.103.10; };
};

zone "104.168.192.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.192.168.104";
    masters { 192.168.103.10; };
};

zone "101.168.192.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.192.168.101";
    masters { 192.168.103.10; };
};
```

## 📊 **Monitoring and Logging**

### Logging Configuration (/etc/bind/named.conf.logging)

```bash
# /etc/bind/named.conf.logging
logging {
    channel default_log {
        file "/var/log/bind/default.log" versions 3 size 5m;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
    };
    
    channel query_log {
        file "/var/log/bind/queries.log" versions 3 size 10m;
        severity info;
        print-time yes;
    };
    
    channel security_log {
        file "/var/log/bind/security.log" versions 3 size 5m;
        severity warning;
        print-time yes;
        print-severity yes;
    };
    
    category default { default_log; };
    category queries { query_log; };
    category security { security_log; };
    category lame-servers { null; };
};
```

### Monitoring with Prometheus

#### BIND Exporter Configuration

```bash
# Install BIND exporter
wget https://github.com/prometheus-community/bind_exporter/releases/download/v0.6.1/bind_exporter-0.6.1.linux-amd64.tar.gz
tar xzf bind_exporter-0.6.1.linux-amd64.tar.gz
sudo cp bind_exporter-0.6.1.linux-amd64/bind_exporter /usr/local/bin/

# Create systemd service
sudo tee /etc/systemd/system/bind-exporter.service > /dev/null <<EOF
[Unit]
Description=BIND Exporter
After=network.target

[Service]
Type=simple
User=bind
ExecStart=/usr/local/bin/bind_exporter --bind.stats-url=http://localhost:8053/
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable statistics in BIND
echo 'statistics-channels { inet 127.0.0.1 port 8053 allow { localhost; }; };' | \
    sudo tee -a /etc/bind/named.conf.options

sudo systemctl enable --now bind-exporter
```

### DNS Health Checks

```bash
#!/bin/bash
# /usr/local/bin/dns-health-check.sh

DNS_SERVERS=("192.168.103.10" "192.168.103.11")
TEST_DOMAINS=("homelab.local" "google.com" "cloudflare.com")
LOG_FILE="/var/log/dns-health.log"

for server in "${DNS_SERVERS[@]}"; do
    echo "Testing DNS server: $server" >> "$LOG_FILE"
    
    for domain in "${TEST_DOMAINS[@]}"; do
        if dig @"$server" "$domain" +short +time=5 >/dev/null 2>&1; then
            echo "$(date): SUCCESS - $server resolved $domain" >> "$LOG_FILE"
        else
            echo "$(date): FAILED - $server could not resolve $domain" >> "$LOG_FILE"
        fi
    done
done
```

## 🛠️ **Maintenance and Operations**

### Zone Management Scripts

#### Update Serial Number

```bash
#!/bin/bash
# /usr/local/bin/update-zone-serial.sh

ZONE_FILE="$1"
if [ -z "$ZONE_FILE" ]; then
    echo "Usage: $0 <zone-file>"
    exit 1
fi

# Generate new serial (YYYYMMDDNN format)
NEW_SERIAL=$(date +%Y%m%d01)

# Update serial in zone file
sed -i "s/[0-9]\{10\}.*; Serial/$NEW_SERIAL      ; Serial/" "$ZONE_FILE"

# Reload BIND
sudo systemctl reload bind9

echo "Zone file $ZONE_FILE updated with serial $NEW_SERIAL"
```

#### Backup Configuration

```bash
#!/bin/bash
# /usr/local/bin/backup-dns-config.sh

BACKUP_DIR="/backup/dns/$(date +%Y%m%d)"
BIND_DIR="/etc/bind"

mkdir -p "$BACKUP_DIR"

# Backup configuration files
cp -r "$BIND_DIR" "$BACKUP_DIR/"

# Backup zone files
cp -r /var/cache/bind "$BACKUP_DIR/"

# Create tarball
tar czf "/backup/dns-backup-$(date +%Y%m%d_%H%M%S).tar.gz" -C "$BACKUP_DIR" .

echo "DNS configuration backed up to $BACKUP_DIR"
```

### Automated Testing

```bash
#!/bin/bash
# /usr/local/bin/dns-validation.sh

# Test forward resolution
echo "Testing forward DNS resolution..."
dig @192.168.103.10 dns-primary.homelab.local +short
dig @192.168.103.10 www.homelab.local +short

# Test reverse resolution
echo "Testing reverse DNS resolution..."
dig @192.168.103.10 -x 192.168.103.10 +short
dig @192.168.103.10 -x 192.168.104.10 +short

# Test external resolution
echo "Testing external DNS resolution..."
dig @192.168.103.10 google.com +short
dig @192.168.103.10 cloudflare.com +short

# Check zone transfer
echo "Testing zone transfer..."
dig @192.168.103.11 homelab.local AXFR

echo "DNS validation completed"
```

---

> **💡 Pro Tip**: Implement automated zone serial number updates and regular configuration backups. Use monitoring to track DNS performance and query patterns for optimization.

*This DNS infrastructure provides a solid foundation for all home lab services with enterprise-grade reliability and security features.*
