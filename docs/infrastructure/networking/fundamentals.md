---
title: "Network Fundamentals"
description: "Core networking concepts, protocols, addressing, and the TCP/IP stack"
tags: ["networking", "fundamentals", "tcp-ip", "protocols", "addressing"]
category: "networking"
difficulty: "beginner"
last_updated: "2025-12-29"
author: "Joseph Streeter"
---

Learn the fundamental concepts that form the foundation of modern networking.

## Core Concepts

### TCP/IP Stack

The TCP/IP stack is the practical implementation of networking protocols used on the internet and is organized into four layers:

1. **Link Layer** - Physical and logical connection between devices
   - Examples: Ethernet, Wi-Fi, PPP
   - Handles: MAC addressing, frame formatting

2. **Internet Layer** - Addressing, routing, and packaging data
   - Examples: IP, ICMP, ARP
   - Handles: IP addressing, routing, fragmentation

3. **Transport Layer** - End-to-end communication services
   - Examples: TCP, UDP
   - Handles: Port numbers, flow control, reliability

4. **Application Layer** - Process-to-process data communications
   - Examples: HTTP, FTP, SMTP, DNS
   - Handles: Application-specific protocols

### IP Addressing

#### IPv4 Addressing

- **Format**: Four octets (0-255) separated by dots
- **Example**: `192.168.1.100`
- **Private Ranges**:
  - `10.0.0.0/8` (Class A) - 16,777,216 addresses
  - `172.16.0.0/12` (Class B) - 1,048,576 addresses
  - `192.168.0.0/16` (Class C) - 65,536 addresses

#### IPv6 Addressing

- **Format**: Eight groups of four hexadecimal digits
- **Example**: `2001:0db8:85a3:0000:0000:8a2e:0370:7334`
- **Simplified**: `2001:db8:85a3::8a2e:370:7334`

#### Subnetting

| CIDR | Subnet Mask       | Hosts   | Use Case      |
| ---- | ----------------- | ------- | ------------- |
| /24  | 255.255.255.0     | 254     | Small office  |
| /23  | 255.255.254.0     | 510     | Medium office |
| /22  | 255.255.252.0     | 1,022   | Large office  |
| /16  | 255.255.0.0       | 65,534  | Enterprise    |

### Common Protocols

| Protocol     | Layer       | Port      | Purpose                  |
| ------------ | ----------- | --------- | ------------------------ |
| **HTTP**     | Application | 80        | Web traffic              |
| **HTTPS**    | Application | 443       | Secure web traffic       |
| **FTP**      | Application | 20,21     | File transfer            |
| **SFTP**     | Application | 22        | Secure file transfer     |
| **DNS**      | Application | 53        | Name resolution          |
| **DHCP**     | Application | 67,68     | IP address assignment    |
| **SMTP**     | Application | 25        | Email sending            |
| **SSH**      | Application | 22        | Secure remote access     |
| **RDP**      | Application | 3389      | Remote desktop           |
| **TCP**      | Transport   | -         | Reliable connection      |
| **UDP**      | Transport   | -         | Fast connectionless      |
| **ICMP**     | Network     | -         | Diagnostics (ping)       |

## Basic Troubleshooting

### Common Commands

```bash
# Test connectivity
ping 192.168.1.1

# Trace route
traceroute google.com  # Linux/Mac
tracert google.com     # Windows

# Check DNS resolution
nslookup google.com
dig google.com         # Linux/Mac

# Display network configuration
ip addr show           # Linux
ipconfig /all          # Windows

# Show routing table
ip route show          # Linux
route print            # Windows
```

## Related Topics

- [OSI Model](osi-model.md) - Seven-layer model deep dive
- [Architecture](architecture.md) - Network design principles
- [Troubleshooting](troubleshooting.md) - Systematic problem solving
