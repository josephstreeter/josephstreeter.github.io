---
title: Network Security
description: Comprehensive guide to network security hardening, monitoring, and threat detection
author: Joseph Streeter
date: 2024-01-15
tags: [network, security, firewall, monitoring, intrusion-detection]
---

Network security involves protecting the integrity, confidentiality, and availability of computer networks and their data. This guide covers essential network security concepts, tools, and best practices for securing network infrastructure.

## Network Security Fundamentals

### Network Security Architecture

#### Defense in Depth

Multiple layers of security controls to protect against various attack vectors.

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Defense in Depth Model                      │
├─────────────────────────────────────────────────────────────────┤
│  Perimeter Security     │ Firewalls, IDS/IPS, DMZ             │
│  Network Segmentation   │ VLANs, Subnets, ACLs                │
│  Access Control        │ Authentication, Authorization        │
│  Endpoint Security     │ Antivirus, EDR, Device Management    │
│  Data Protection       │ Encryption, DLP, Backup             │
│  Monitoring & Logging  │ SIEM, Network Monitoring, Analytics │
└─────────────────────────────────────────────────────────────────┘
```

#### Network Zones

Segmenting networks into security zones based on trust levels.

- **External Zone**: Internet and untrusted networks
- **DMZ (Demilitarized Zone)**: Public-facing services
- **Internal Zone**: Corporate network and resources
- **Secure Zone**: Critical systems and sensitive data

### Common Network Threats

#### External Threats

- **DDoS Attacks**: Overwhelming network resources
- **Port Scanning**: Reconnaissance for vulnerabilities
- **Man-in-the-Middle**: Intercepting communications
- **DNS Poisoning**: Redirecting traffic to malicious sites

#### Internal Threats

- **Lateral Movement**: Spreading within the network
- **Data Exfiltration**: Unauthorized data transfer
- **Privilege Escalation**: Gaining elevated access
- **Insider Threats**: Malicious or negligent insiders

## Firewall Configuration

### Linux iptables

#### Basic Firewall Rules

```bash
#!/bin/bash
# Basic iptables firewall configuration

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (port 22)
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Allow HTTP and HTTPS
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Allow DNS
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT

# Drop invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Log and drop everything else
iptables -A INPUT -j LOG --log-prefix "iptables-dropped: "
iptables -A INPUT -j DROP

# Save rules
iptables-save > /etc/iptables/rules.v4
```

#### Advanced Protection Rules

```bash
# Protection against common attacks
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP  # Null packets
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP   # XMAS packets
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP  # SYN-FIN packets

# Rate limiting for SSH
iptables -A INPUT -p tcp --dport 22 -m recent --name ssh --update --seconds 60 --hitcount 4 -j DROP
iptables -A INPUT -p tcp --dport 22 -m recent --name ssh --set -j ACCEPT

# Protection against port scanning
iptables -A INPUT -m recent --name portscan --rcheck --seconds 86400 -j DROP
iptables -A INPUT -m recent --name portscan --remove
iptables -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "portscan: "
iptables -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP

# SYN flood protection
iptables -A INPUT -p tcp --syn -m limit --limit 1/second --limit-burst 3 -j RETURN
iptables -A INPUT -p tcp --syn -j DROP
```

### UFW (Uncomplicated Firewall)

#### Basic UFW Configuration

```bash
# Reset UFW to defaults
ufw --force reset

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow ssh

# Allow specific ports
ufw allow 80/tcp
ufw allow 443/tcp

# Allow from specific IP
ufw allow from 192.168.1.100

# Allow specific port from specific IP
ufw allow from 192.168.1.100 to any port 22

# Enable UFW
ufw enable

# Check status
ufw status verbose
```

#### Application Profiles

```bash
# List available application profiles
ufw app list

# Allow application
ufw allow 'Nginx Full'
ufw allow 'OpenSSH'

# Create custom application profile
cat > /etc/ufw/applications.d/myapp << EOF
[MyApp]
title=My Custom Application
description=Custom application on port 8080
ports=8080/tcp
EOF

# Reload and allow custom app
ufw app update MyApp
ufw allow MyApp
```

### pfSense Configuration

#### Basic Setup

```php
# pfSense firewall rules (via Web GUI or CLI)

# WAN Rules (typically restrictive)
- Block all by default
- Allow established connections
- Allow specific services if needed

# LAN Rules (typically permissive)
- Allow all LAN to any
- Block LAN to WAN on specific ports if needed

# DMZ Rules (selective)
- Allow DMZ to Internet
- Block DMZ to LAN
- Allow specific LAN to DMZ services
```

## Network Monitoring

### Network Traffic Analysis

#### tcpdump

```bash
# Capture all traffic on interface
tcpdump -i eth0

# Capture with filters
tcpdump -i eth0 host 192.168.1.100
tcpdump -i eth0 port 80
tcpdump -i eth0 tcp and port 443

# Save to file
tcpdump -i eth0 -w capture.pcap

# Read from file
tcpdump -r capture.pcap

# Advanced filtering
tcpdump -i eth0 'tcp[tcpflags] & (tcp-syn|tcp-fin) != 0'
tcpdump -i eth0 'icmp or arp'
```

#### Wireshark (Command Line)

```bash
# Capture with tshark
tshark -i eth0 -c 100 -w capture.pcapng

# Display filters
tshark -r capture.pcapng -Y "http.request.method == GET"
tshark -r capture.pcapng -Y "tcp.port == 443"
tshark -r capture.pcapng -Y "ip.addr == 192.168.1.100"

# Extract specific fields
tshark -r capture.pcapng -T fields -e ip.src -e ip.dst -e tcp.port

# Statistics
tshark -r capture.pcapng -z conv,ip
tshark -r capture.pcapng -z http,stat
```

### Network Scanning and Discovery

#### Nmap Security Scanning

```bash
# Basic host discovery
nmap -sn 192.168.1.0/24

# Port scanning
nmap -sS 192.168.1.100  # SYN scan
nmap -sU 192.168.1.100  # UDP scan
nmap -sA 192.168.1.100  # ACK scan

# Service detection
nmap -sV 192.168.1.100

# OS detection
nmap -O 192.168.1.100

# Aggressive scan
nmap -A 192.168.1.100

# Script scanning
nmap --script vuln 192.168.1.100
nmap --script ssl-enum-ciphers -p 443 192.168.1.100

# Stealth scanning
nmap -sS -T2 -f 192.168.1.100
```

#### Network Discovery Tools

```bash
# ARP scanning
arp-scan -I eth0 -l
arp-scan 192.168.1.0/24

# Ping sweep
for i in {1..254}; do
    ping -c 1 -W 1 192.168.1.$i > /dev/null 2>&1 && echo "192.168.1.$i is up"
done

# DNS enumeration
dig @8.8.8.8 example.com
nslookup example.com
host example.com

# Reverse DNS lookup
dig -x 8.8.8.8
```

## Intrusion Detection and Prevention

### Suricata IDS/IPS

#### Installation and Configuration

```bash
# Install Suricata on Ubuntu
apt update
apt install suricata

# Configuration file: /etc/suricata/suricata.yaml
```

```yaml
# Basic Suricata configuration
%YAML 1.1
---
vars:
  address-groups:
    HOME_NET: "[192.168.1.0/24]"
    EXTERNAL_NET: "!$HOME_NET"
    
default-log-dir: /var/log/suricata/

outputs:
  - fast:
      enabled: yes
      filename: fast.log
  - eve-log:
      enabled: yes
      filetype: json
      filename: eve.json
      types:
        - alert
        - http
        - dns
        - tls

af-packet:
  - interface: eth0
    cluster-id: 99
    cluster-type: cluster_flow
```

#### Custom Rules

```bash
# Custom Suricata rules (/etc/suricata/rules/local.rules)

# Detect SSH brute force
alert tcp $EXTERNAL_NET any -> $HOME_NET 22 (msg:"SSH Brute Force Attempt"; flow:to_server,established; content:"SSH"; threshold:type threshold, track by_src, count 5, seconds 60; sid:1000001; rev:1;)

# Detect port scanning
alert tcp $EXTERNAL_NET any -> $HOME_NET any (msg:"Port Scan Detected"; flags:S,12; threshold:type threshold, track by_src, count 10, seconds 60; sid:1000002; rev:1;)

# Detect suspicious DNS queries
alert dns $HOME_NET any -> $EXTERNAL_NET 53 (msg:"Suspicious DNS Query"; dns_query; content:".bit"; sid:1000003; rev:1;)

# Detect file downloads
alert http $EXTERNAL_NET any -> $HOME_NET any (msg:"Executable Download"; flow:to_client,established; file_data; content:"|4D 5A|"; within:2; sid:1000004; rev:1;)
```

### Fail2Ban

#### Fail2Ban Installation and Configuration

```bash
# Install Fail2Ban
apt install fail2ban

# Configuration file: /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[apache-auth]
enabled = true
filter = apache-auth
logpath = /var/log/apache2/error.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3

[postfix-sasl]
enabled = true
filter = postfix-sasl
logpath = /var/log/mail.log
maxretry = 3
```

#### Custom Filters

```bash
# Custom filter for application logs
# /etc/fail2ban/filter.d/myapp.conf

[Definition]
failregex = ^.*\[error\].*authentication failed for user.*from <HOST>$
            ^.*\[warning\].*failed login attempt from <HOST>$

ignoreregex =
```

## VPN Security

### OpenVPN Configuration

#### Server Configuration

```bash
# Server configuration file: /etc/openvpn/server.conf
port 1194
proto udp
dev tun

ca ca.crt
cert server.crt
key server.key
dh dh2048.pem

server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt

push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

keepalive 10 120
cipher AES-256-CBC
auth SHA256
comp-lzo

user nobody
group nogroup
persist-key
persist-tun

status openvpn-status.log
log-append /var/log/openvpn.log
verb 3
```

#### WireGuard Client Configuration

```bash
# Client configuration file: client.ovpn
client
dev tun
proto udp

remote vpn.example.com 1194
resolv-retry infinite
nobind

persist-key
persist-tun

ca ca.crt
cert client.crt
key client.key

cipher AES-256-CBC
auth SHA256
comp-lzo

verb 3
```

### WireGuard Configuration

#### Server Setup

```bash
# Install WireGuard
apt install wireguard

# Generate server keys
wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey

# Server configuration: /etc/wireguard/wg0.conf
[Interface]
PrivateKey = SERVER_PRIVATE_KEY
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
```

#### Client Configuration

```bash
# Client configuration
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = 10.0.0.2/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

## Network Forensics

### Log Analysis

#### Centralized Logging with rsyslog

```bash
# Server configuration: /etc/rsyslog.conf
$ModLoad imudp
$UDPServerRun 514
$UDPServerAddress 0.0.0.0

$template RemoteLogs,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~

# Client configuration
*.* @log-server:514
```

#### ELK Stack for Network Logs

```yaml
# Docker Compose for ELK stack
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:7.15.0
    ports:
      - "5000:5000"
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:7.15.0
    ports:
      - "5601:5601"
    environment:
      ELASTICSEARCH_URL: http://elasticsearch:9200
    depends_on:
      - elasticsearch

volumes:
  elasticsearch_data:
```

### Traffic Analysis Scripts

#### Python Network Analysis

```python
#!/usr/bin/env python3
import scapy.all as scapy
from collections import defaultdict
import matplotlib.pyplot as plt

def analyze_pcap(filename):
    """Analyze network traffic from pcap file"""
    packets = scapy.rdpcap(filename)
    
    # Traffic statistics
    protocol_stats = defaultdict(int)
    ip_stats = defaultdict(int)
    port_stats = defaultdict(int)
    
    for packet in packets:
        if packet.haslayer(scapy.IP):
            protocol = packet[scapy.IP].proto
            protocol_stats[protocol] += 1
            
            src_ip = packet[scapy.IP].src
            dst_ip = packet[scapy.IP].dst
            ip_stats[src_ip] += 1
            ip_stats[dst_ip] += 1
            
            if packet.haslayer(scapy.TCP):
                port_stats[packet[scapy.TCP].dport] += 1
            elif packet.haslayer(scapy.UDP):
                port_stats[packet[scapy.UDP].dport] += 1
    
    # Generate reports
    print("Protocol Statistics:")
    for proto, count in protocol_stats.items():
        print(f"  Protocol {proto}: {count} packets")
    
    print("\nTop 10 IP Addresses:")
    top_ips = sorted(ip_stats.items(), key=lambda x: x[1], reverse=True)[:10]
    for ip, count in top_ips:
        print(f"  {ip}: {count} packets")
    
    print("\nTop 10 Destination Ports:")
    top_ports = sorted(port_stats.items(), key=lambda x: x[1], reverse=True)[:10]
    for port, count in top_ports:
        print(f"  Port {port}: {count} packets")

if __name__ == "__main__":
    analyze_pcap("capture.pcap")
```

## Security Automation

### Automated Security Monitoring

#### Network Health Check Script

```bash
#!/bin/bash
# Network security health check script

LOG_FILE="/var/log/network-security-check.log"
ALERT_EMAIL="admin@example.com"

log_message() {
    echo "$(date): $1" | tee -a $LOG_FILE
}

check_firewall() {
    log_message "Checking firewall status..."
    
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            log_message "UFW firewall is active"
        else
            log_message "WARNING: UFW firewall is inactive"
            return 1
        fi
    elif command -v iptables >/dev/null 2>&1; then
        if iptables -L | grep -q "Chain INPUT"; then
            log_message "iptables firewall rules are present"
        else
            log_message "WARNING: No iptables rules found"
            return 1
        fi
    else
        log_message "ERROR: No firewall found"
        return 1
    fi
}

check_failed_logins() {
    log_message "Checking for failed login attempts..."
    
    failed_logins=$(grep "Failed password" /var/log/auth.log | wc -l)
    if [ $failed_logins -gt 10 ]; then
        log_message "WARNING: $failed_logins failed login attempts found"
        return 1
    else
        log_message "Failed login attempts: $failed_logins (normal)"
    fi
}

check_network_connections() {
    log_message "Checking suspicious network connections..."
    
    # Check for connections to suspicious ports
    suspicious_ports=(1337 4444 6667 31337)
    for port in "${suspicious_ports[@]}"; do
        if netstat -an | grep ":$port"; then
            log_message "WARNING: Connection to suspicious port $port detected"
            return 1
        fi
    done
    
    log_message "No suspicious network connections found"
}

check_dns_integrity() {
    log_message "Checking DNS integrity..."
    
    # Test DNS resolution
    if nslookup google.com > /dev/null 2>&1; then
        log_message "DNS resolution working normally"
    else
        log_message "ERROR: DNS resolution failed"
        return 1
    fi
}

send_alert() {
    if [ $1 -ne 0 ]; then
        echo "Network security check failed. Check $LOG_FILE for details." | \
            mail -s "Network Security Alert" $ALERT_EMAIL
    fi
}

# Main execution
main() {
    log_message "Starting network security health check"
    
    overall_status=0
    
    check_firewall || overall_status=1
    check_failed_logins || overall_status=1
    check_network_connections || overall_status=1
    check_dns_integrity || overall_status=1
    
    if [ $overall_status -eq 0 ]; then
        log_message "All network security checks passed"
    else
        log_message "Some network security checks failed"
    fi
    
    send_alert $overall_status
    log_message "Network security health check completed"
    
    return $overall_status
}

main "$@"
```

### Incident Response Automation

#### Automatic Threat Response

```bash
#!/bin/bash
# Automated threat response script

BLOCKED_IPS_FILE="/etc/security/blocked_ips.txt"
WHITELIST_FILE="/etc/security/whitelist.txt"

block_ip() {
    local ip=$1
    local reason=$2
    
    # Check if IP is whitelisted
    if grep -q "^$ip$" "$WHITELIST_FILE" 2>/dev/null; then
        echo "IP $ip is whitelisted, not blocking"
        return 1
    fi
    
    # Check if already blocked
    if grep -q "^$ip$" "$BLOCKED_IPS_FILE" 2>/dev/null; then
        echo "IP $ip is already blocked"
        return 0
    fi
    
    # Block with iptables
    iptables -A INPUT -s "$ip" -j DROP
    
    # Add to blocked IPs file
    echo "$ip" >> "$BLOCKED_IPS_FILE"
    
    # Log the action
    logger "SECURITY: Blocked IP $ip - Reason: $reason"
    echo "$(date): Blocked $ip - $reason" >> /var/log/security-blocks.log
    
    echo "Successfully blocked IP: $ip"
}

detect_ssh_bruteforce() {
    # Find IPs with multiple failed SSH attempts in last hour
    grep "$(date '+%b %d %H')" /var/log/auth.log | \
    grep "Failed password" | \
    awk '{print $11}' | \
    sort | uniq -c | \
    while read count ip; do
        if [ "$count" -gt 5 ]; then
            block_ip "$ip" "SSH brute force ($count attempts)"
        fi
    done
}

detect_port_scan() {
    # Analyze recent iptables logs for port scanning
    journalctl -u iptables --since "1 hour ago" | \
    grep "iptables-dropped" | \
    awk '{print $8}' | cut -d'=' -f2 | \
    sort | uniq -c | \
    while read count ip; do
        if [ "$count" -gt 20 ]; then
            block_ip "$ip" "Port scanning ($count packets)"
        fi
    done
}

# Main execution
echo "Starting automated threat detection..."
detect_ssh_bruteforce
detect_port_scan
echo "Threat detection completed"
```

## Compliance and Standards

### Security Frameworks

#### NIST Cybersecurity Framework

```bash
# NIST CSF implementation checklist
cat > /etc/security/nist-csf-checklist.txt << EOF
IDENTIFY (ID):
- [ ] Asset Management (ID.AM)
- [ ] Business Environment (ID.BE)
- [ ] Governance (ID.GV)
- [ ] Risk Assessment (ID.RA)
- [ ] Risk Management Strategy (ID.RM)

PROTECT (PR):
- [ ] Access Control (PR.AC)
- [ ] Awareness and Training (PR.AT)
- [ ] Data Security (PR.DS)
- [ ] Information Protection Processes (PR.IP)
- [ ] Maintenance (PR.MA)
- [ ] Protective Technology (PR.PT)

DETECT (DE):
- [ ] Anomalies and Events (DE.AE)
- [ ] Security Continuous Monitoring (DE.CM)
- [ ] Detection Processes (DE.DP)

RESPOND (RS):
- [ ] Response Planning (RS.RP)
- [ ] Communications (RS.CO)
- [ ] Analysis (RS.AN)
- [ ] Mitigation (RS.MI)
- [ ] Improvements (RS.IM)

RECOVER (RC):
- [ ] Recovery Planning (RC.RP)
- [ ] Improvements (RC.IM)
- [ ] Communications (RC.CO)
EOF
```

#### ISO 27001 Network Controls

```bash
# ISO 27001 Annex A network security controls
cat > /etc/security/iso27001-network-controls.txt << EOF
A.13 Communications security:
- A.13.1.1 Network controls management
- A.13.1.2 Security of network services
- A.13.1.3 Segregation in networks
- A.13.2.1 Information transfer policies
- A.13.2.2 Agreements on information transfer
- A.13.2.3 Electronic messaging

A.12 Operations security:
- A.12.6.1 Management of technical vulnerabilities
- A.12.6.2 Restrictions on software installation

A.9 Access control:
- A.9.1.2 Access to networks and network services
- A.9.4.1 Information access restriction
EOF
```

## Best Practices

### Network Security Guidelines

1. **Network Segmentation**
   - Implement VLANs and subnets
   - Use firewalls between segments
   - Apply least privilege access

2. **Monitoring and Logging**
   - Enable comprehensive logging
   - Implement real-time monitoring
   - Regular log analysis

3. **Access Control**
   - Strong authentication mechanisms
   - Regular access reviews
   - Principle of least privilege

4. **Encryption**
   - Encrypt data in transit
   - Use VPNs for remote access
   - Implement TLS/SSL properly

### Incident Response Plan

1. **Preparation**
   - Document procedures
   - Train incident response team
   - Prepare tools and resources

2. **Detection and Analysis**
   - Monitor security events
   - Analyze potential incidents
   - Determine scope and impact

3. **Containment and Eradication**
   - Isolate affected systems
   - Remove threats
   - Patch vulnerabilities

4. **Recovery and Lessons Learned**
   - Restore services
   - Monitor for reoccurrence
   - Update procedures

## Related Topics

- [Windows Security](~/docs/security/windows/index.md)
- [Container Security](~/docs/infrastructure/containers/security/index.md)
- [Infrastructure Monitoring](~/docs/infrastructure/monitoring/index.md)
- [Container Networking](~/docs/infrastructure/containers/networking/index.md)
- [SSH Security](~/docs/security/ssh/index.md)
