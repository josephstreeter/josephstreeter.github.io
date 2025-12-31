---
title: "Network Troubleshooting Guide"
description: "Comprehensive guide to diagnosing and resolving common networking issues"
tags: ["networking", "troubleshooting", "diagnostics", "connectivity"]
category: "networking"
difficulty: "intermediate"
last_updated: "2025-12-30"
---

## Network Troubleshooting Guide

This guide provides a structured approach to diagnosing and resolving common network connectivity issues, from basic to advanced problems.

## Troubleshooting Methodology

### The OSI Model Approach

A systematic way to troubleshoot network issues is to work through the OSI model layers from bottom to top:

1. **Physical Layer (Layer 1)**
   - Check physical connections (cables, ports)
   - Verify power and link lights
   - Test alternative cables/ports

2. **Data Link Layer (Layer 2)**
   - Check interface status
   - Verify MAC addresses
   - Examine for switching loops

3. **Network Layer (Layer 3)**
   - Verify IP configuration
   - Check routing tables
   - Test basic connectivity

4. **Transport Layer (Layer 4)**
   - Verify port availability
   - Check for port filtering
   - Test service responsiveness

5. **Session/Presentation/Application Layers (Layers 5-7)**
   - Check application configurations
   - Verify DNS resolution
   - Test application-specific requirements

## Common Network Issues and Solutions

### Connectivity Problems

#### No Network Access

**Symptoms:**

- Unable to access any network resources
- "No internet" error messages

**Diagnostic Steps:**

1. Check physical connections (cables, Wi-Fi signal)
2. Verify network interface status:

   ```bash
   # Linux/macOS
   ifconfig
   # or
   ip addr show
   
   # Windows
   ipconfig /all
   ```

3. Test loopback interface:

   ```bash
   ping 127.0.0.1
   ```

**Common Solutions:**

- Reconnect or replace network cables
- Restart network interface
- Reset network adapter:

   ```bash
   # Linux
   sudo ifdown eth0 && sudo ifup eth0
   # or
   sudo ip link set eth0 down && sudo ip link set eth0 up
   
   # Windows
   ipconfig /release
   ipconfig /renew
   ```

#### Local Network Access Only

**Symptoms:**

- Can access local resources but not internet
- Ping to local IPs works but not to external domains

**Diagnostic Steps:**

1. Check default gateway configuration:

   ```bash
   # Linux/macOS
   ip route | grep default
   
   # Windows
   ipconfig | findstr Gateway
   ```

2. Try pinging the gateway:

   ```bash
   ping 192.168.1.1  # Replace with your gateway
   ```

3. Check DNS settings:

   ```bash
   # Linux
   cat /etc/resolv.conf
   
   # Windows
   ipconfig /all | findstr DNS
   ```

**Common Solutions:**

- Reset router/modem
- Correct gateway settings
- Set alternative DNS servers:

   ```bash
   # Linux
   echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
   
   # Windows
   netsh interface ip set dns "Wi-Fi" static 8.8.8.8
   ```

### DNS Issues

#### Cannot Resolve Domain Names

**Symptoms:**

- IP addresses work but domain names don't
- "DNS server not responding" errors

**Diagnostic Steps:**

1. Test DNS resolution:

   ```bash
   nslookup google.com
   # or
   dig google.com
   ```

2. Check DNS server configuration
3. Try alternative DNS servers

**Common Solutions:**

- Switch to public DNS servers (8.8.8.8, 1.1.1.1)
- Flush DNS cache:

   ```bash
   # Linux
   sudo systemd-resolve --flush-caches
   
   # macOS
   sudo killall -HUP mDNSResponder
   
   # Windows
   ipconfig /flushdns
   ```

- Check firewall rules for DNS traffic (port 53)

### Performance Issues

#### Slow Network Performance

**Symptoms:**

- High latency
- Slow file transfers
- Intermittent connectivity

**Diagnostic Steps:**

1. Test network speed:

   ```bash
   speedtest-cli
   ```

2. Check for network congestion:

   ```bash
   ping -c 100 8.8.8.8 | grep time
   ```

3. Monitor bandwidth usage:

   ```bash
   # Linux
   iftop
   # or
   nethogs
   
   # Windows
   netstat -e -t 5
   ```

**Common Solutions:**

- Identify and limit bandwidth-heavy applications
- Update network drivers
- Check for interference (Wi-Fi channels)
- Implement QoS settings on router

## Advanced Troubleshooting Tools

### Network Diagnostics

#### Traceroute

Traces the path packets take to a destination:

```bash
# Linux/macOS
traceroute google.com

# Windows
tracert google.com
```

#### MTR (My Traceroute)

Combines ping and traceroute functionality:

```bash
mtr google.com
```

#### Netstat

Displays network connections and routing tables:

```bash
# Show all connections
netstat -a

# Show listening ports
netstat -l

# Show statistics by protocol
netstat -s
```

### Packet Analysis

#### Tcpdump

Capture and analyze network traffic:

```bash
# Capture packets on interface eth0
sudo tcpdump -i eth0

# Capture packets to/from specific host
sudo tcpdump host 192.168.1.10

# Capture specific protocol
sudo tcpdump tcp port 80
```

#### Wireshark

For GUI-based packet analysis:

1. Capture traffic on the relevant interface
2. Apply display filters (e.g., `http`, `dns`, `ip.addr==192.168.1.10`)
3. Inspect packet details and conversations

## Network Configuration Validation

### Interface Configuration

Verify interface settings:

```bash
# Linux
ethtool eth0

# Windows
netsh interface show interface
```

### Routing Table

Check routing configuration:

```bash
# Linux/macOS
ip route
# or
route -n

# Windows
route print
```

### Firewall Rules

Verify firewall settings:

```bash
# Linux (iptables)
sudo iptables -L

# Linux (firewalld)
sudo firewall-cmd --list-all

# Windows
netsh advfirewall show allprofiles
```

## Related Topics

- [Unifi Configuration Guide](unifi/index.md) - For Unifi-specific troubleshooting
- [VLAN Setup and Configuration](unifi/vlans.md) - For segmentation issues
- [802.1x Authentication](unifi/802.1x.md) - For network access control problems
- [Network Security](../security/index.md) - For security-related network issues
