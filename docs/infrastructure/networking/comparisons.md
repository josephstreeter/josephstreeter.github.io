---
title: "Technology Comparisons"
description: "Side-by-side comparisons of networking technologies, protocols, and approaches"
tags: ["networking", "comparison", "reference", "decision-making"]
category: "networking"
difficulty: "intermediate"
last_updated: "2025-12-30"
---

## Overview

This guide provides side-by-side comparisons of common networking technologies to help you make informed decisions for your network design and implementation.

## Network Devices

### Switches vs Routers

| Feature | Switch (Layer 2) | Router (Layer 3) |
| --- | --- | --- |
| **OSI Layer** | Data Link (Layer 2) | Network (Layer 3) |
| **Addressing** | MAC addresses | IP addresses |
| **Function** | Forwards frames within network | Routes packets between networks |
| **Broadcast Domain** | Doesn't separate | Separates broadcast domains |
| **Collision Domain** | Separates per port | Separates per interface |
| **Speed** | Wire-speed (fast) | Varies (routing overhead) |
| **Intelligence** | MAC table | Routing table |
| **Use Case** | Connect devices in LAN | Connect different networks |
| **Example** | Connect computers in office | Connect office to internet |
| **Cost** | Lower | Higher |
| **Configuration** | Minimal (unmanaged) | Required |

**When to use Switch**: Connecting devices within same network/subnet

**When to use Router**: Connecting different networks, internet gateway, inter-VLAN routing

### Hub vs Switch vs Router

| Feature | Hub | Switch | Router |
| --- | --- | --- | --- |
| **OSI Layer** | Physical (Layer 1) | Data Link (Layer 2) | Network (Layer 3) |
| **Operation** | Broadcasts to all ports | Forwards to specific port | Routes between networks |
| **Intelligence** | None | MAC learning | Routing protocols |
| **Efficiency** | Very low (collisions) | High | Varies |
| **Security** | None (sniffing easy) | Port isolation | ACLs, firewall |
| **Use Today** | Obsolete | Primary LAN device | Gateway device |
| **Cost** | Lowest | Low-Medium | Medium-High |

**Recommendation**: Never use hubs. Use switches for LAN, routers for inter-network connectivity.

### Managed vs Unmanaged Switch

| Feature | Unmanaged Switch | Managed Switch |
| --- | --- | --- |
| **Configuration** | Plug-and-play | Web/CLI configuration |
| **VLANs** | No | Yes |
| **QoS** | No | Yes |
| **Port Mirroring** | No | Yes |
| **SNMP Monitoring** | No | Yes |
| **Link Aggregation** | No | Yes |
| **Spanning Tree** | Basic | Advanced (RSTP, MSTP) |
| **Port Security** | No | Yes (MAC filtering) |
| **Cost** | $20-100 | $100-5,000+ |
| **Use Case** | Home, small office | Enterprise, VLANs needed |
| **Complexity** | None | Requires knowledge |

**When to use Unmanaged**: Home, simple small office (< 10 devices), no VLANs

**When to use Managed**: VLANs required, traffic prioritization, monitoring needed, > 20 devices

## Transport Protocols

### TCP vs UDP

| Feature | TCP | UDP |
| --- | --- | --- |
| **Full Name** | Transmission Control Protocol | User Datagram Protocol |
| **Connection** | Connection-oriented | Connectionless |
| **Reliability** | Guaranteed delivery | Best-effort (no guarantee) |
| **Ordering** | Maintains packet order | No ordering |
| **Error Checking** | Yes (checksums + retransmission) | Basic checksum only |
| **Flow Control** | Yes (windowing) | No |
| **Congestion Control** | Yes | No |
| **Speed** | Slower (overhead) | Faster (minimal overhead) |
| **Header Size** | 20-60 bytes | 8 bytes |
| **Use Cases** | HTTP, HTTPS, FTP, SSH, Email | DNS, DHCP, VoIP, Streaming |
| **When packet loss acceptable** | No | Yes |
| **Real-time sensitive** | No (delays for retransmit) | Yes (prefers speed) |

**Use TCP when**: Reliability critical (file transfers, web browsing, email, financial transactions)

**Use UDP when**: Speed critical, small packet loss acceptable (VoIP, video streaming, gaming, DNS)

### IPv4 vs IPv6

| Feature | IPv4 | IPv6 |
| --- | --- | --- |
| **Address Length** | 32-bit | 128-bit |
| **Address Format** | Dotted decimal (192.168.1.1) | Hexadecimal (2001:db8::1) |
| **Address Space** | ~4.3 billion | 340 undecillion |
| **Address Types** | Unicast, Multicast, Broadcast | Unicast, Multicast, Anycast |
| **Header Size** | 20-60 bytes | 40 bytes (fixed) |
| **Fragmentation** | Routers and hosts | Hosts only |
| **NAT Required** | Yes (due to scarcity) | No (abundance of addresses) |
| **Configuration** | Manual or DHCP | SLAAC, DHCPv6, manual |
| **Security** | Optional (IPsec) | Built-in (IPsec mandatory) |
| **Adoption** | Universal | Growing (~40% traffic) |
| **ISP Support** | 100% | Varies (60-90%) |

**Current Status**: IPv4 still dominant, dual-stack (both IPv4 and IPv6) recommended

**Future**: IPv6 adoption increasing, IPv4 will coexist for decades

## Routing Protocols

### Distance-Vector vs Link-State

| Characteristic | Distance-Vector (RIP, EIGRP) | Link-State (OSPF, IS-IS) |
| --- | --- | --- |
| **Algorithm** | Bellman-Ford | Dijkstra (SPF) |
| **Knowledge** | Direction and distance to destination | Complete network topology |
| **Updates** | Periodic (full/incremental) | Event-triggered (only changes) |
| **Convergence** | Slow (seconds to minutes) | Fast (subsecond to seconds) |
| **CPU/Memory** | Lower | Higher |
| **Bandwidth Usage** | Higher (periodic updates) | Lower (only changes) |
| **Scalability** | Limited | Excellent (with areas) |
| **Loop Prevention** | Split horizon, poison reverse | Topology knowledge |
| **Metrics** | Simple (hop count, composite) | Cost (bandwidth-based) |
| **Configuration** | Easier | More complex |

**Use Distance-Vector**: Small networks, simple topologies, limited resources

**Use Link-State**: Large networks, fast convergence required, hierarchical design

### Interior Gateway Protocols (IGP) Comparison

| Feature | RIP | EIGRP | OSPF | IS-IS |
| --- | --- | --- | --- | --- |
| **Type** | Distance-vector | Advanced distance-vector | Link-state | Link-state |
| **Standard** | Open (RFC) | Cisco proprietary | Open (RFC) | Open (ISO) |
| **Metric** | Hop count | Composite (BW, delay) | Cost (bandwidth) | Cost |
| **Max Hops** | 15 | 255 | None | None |
| **Convergence** | Slow | Very fast | Fast | Fast |
| **VLSM Support** | RIPv2 yes | Yes | Yes | Yes |
| **Areas** | No | No | Yes (mandatory Area 0) | Yes (optional) |
| **Scalability** | Poor | Good | Excellent | Excellent |
| **CPU/Memory** | Low | Medium | Medium-High | Medium-High |
| **Multicast** | 224.0.0.9 | 224.0.0.10 | 224.0.0.5/6 | N/A (Layer 2) |
| **Use Case** | Legacy only | Cisco-only networks | Enterprise standard | Service providers |

**Recommendation**: OSPF for multi-vendor enterprise, EIGRP if all-Cisco, never use RIP for new deployments

## WiFi Standards

### 802.11 Generations

| Standard | Name | Year | Frequency | Max Speed | Range | Best Use |
| --- | --- | --- | --- | --- | --- | --- |
| **802.11b** | - | 1999 | 2.4 GHz | 11 Mbps | Good | Obsolete |
| **802.11g** | - | 2003 | 2.4 GHz | 54 Mbps | Good | Legacy IoT |
| **802.11n** | WiFi 4 | 2009 | 2.4/5 GHz | 600 Mbps | Good | Minimum today |
| **802.11ac** | WiFi 5 | 2014 | 5 GHz | 3.5 Gbps | Good | Current standard |
| **802.11ax** | WiFi 6 | 2019 | 2.4/5 GHz | 9.6 Gbps | Better | Recommended |
| **802.11ax** | WiFi 6E | 2020 | 6 GHz | 9.6 Gbps | Good | Future-proof |
| **802.11be** | WiFi 7 | 2024 | 2.4/5/6 GHz | 46 Gbps | Better | Cutting-edge |

**Minimum for new deployment**: WiFi 6 (802.11ax)

**Best value**: WiFi 6 for most, WiFi 6E for high-density or new builds

### 2.4 GHz vs 5 GHz vs 6 GHz

| Feature | 2.4 GHz | 5 GHz | 6 GHz (WiFi 6E) |
| --- | --- | --- | --- |
| **Range** | Best | Good | Good |
| **Wall Penetration** | Excellent | Moderate | Moderate |
| **Speed** | Lower | Higher | Highest |
| **Channels (Non-overlap)** | 3 (1, 6, 11) | 24 | 59 |
| **Interference** | High (BT, microwave) | Low | None |
| **Device Support** | Universal | Common | Latest devices only |
| **DFS Required** | No | Some channels | No |
| **Best For** | IoT, range | Clients, speed | High-density, future |
| **Congestion** | Very high | Medium | None |

**Recommendation**:

- **2.4 GHz**: IoT devices, long-range, legacy devices
- **5 GHz**: Laptops, phones, streaming, most clients
- **6 GHz**: Enterprise, new deployments, high-performance needs

## Security Protocols

### WPA2 vs WPA3

| Feature | WPA2 | WPA3 |
| --- | --- | --- |
| **Introduced** | 2004 | 2018 |
| **Encryption** | AES-CCMP | AES-GCM |
| **Key Exchange** | Pre-shared key (PSK) | SAE (Dragonfly) |
| **Forward Secrecy** | No | Yes |
| **Brute Force Protection** | Vulnerable | Protected |
| **Dictionary Attacks** | Vulnerable offline | Not possible offline |
| **Public WiFi** | Risky | Safer (individualized encryption) |
| **Device Support** | Universal | 2019+ devices |
| **Enterprise (802.1X)** | Available | Enhanced (192-bit) |
| **Status** | Still widely used | Recommended |

**Recommendation**: WPA3 if all devices support it, WPA2/WPA3 mixed mode for transition

**Never use**: WEP, WPA (original), Open networks (except guest with captive portal)

### VPN Protocols

| Protocol | Speed | Security | NAT Traversal | Mobile | Use Case |
| --- | --- | --- | --- | --- | --- |
| **OpenVPN** | Good | Excellent | Good | Yes | General purpose |
| **IPsec** | Fast | Excellent | Poor | Yes | Site-to-site |
| **WireGuard** | Very fast | Excellent | Excellent | Yes | Modern choice |
| **L2TP/IPsec** | Moderate | Good | Fair | Yes | Legacy clients |
| **PPTP** | Fast | Weak | Excellent | Yes | Obsolete (insecure) |
| **IKEv2/IPsec** | Fast | Excellent | Excellent | Yes | Mobile, MacOS/iOS |
| **SSTP** | Moderate | Good | Excellent | Limited | Windows-focused |

**Recommendation**:

- **Remote access**: WireGuard or OpenVPN
- **Site-to-site**: IPsec or WireGuard
- **Mobile**: IKEv2/IPsec or WireGuard
- **Never use**: PPTP (broken security)

## Cable Types

### Ethernet Cable Categories

| Category | Max Speed | Max Distance | Shielding | Use Case | Cost |
| --- | --- | --- | --- | --- | --- |
| **Cat5** | 100 Mbps | 100m | No | Obsolete | Lowest |
| **Cat5e** | 1 Gbps | 100m | Optional | Minimum today | Low |
| **Cat6** | 10 Gbps (55m) / 1 Gbps (100m) | 55m / 100m | Optional | Recommended | Medium |
| **Cat6a** | 10 Gbps | 100m | Yes | Data centers | Medium-High |
| **Cat7** | 10 Gbps | 100m | Yes | Specialized | High |
| **Cat8** | 25/40 Gbps | 30m | Yes | Data centers | Highest |

**Recommendation**:

- **Home/Office**: Cat6 (future-proof for 10 Gbps short runs)
- **New construction**: Cat6a (full 10 Gbps at 100m)
- **Data center**: Cat6a or fiber

### Copper vs Fiber

| Feature | Copper (Ethernet) | Fiber Optic |
| --- | --- | --- | --- |
| **Max Distance** | 100m (328 ft) | 2km-80km+ |
| **Speed** | Up to 40 Gbps (Cat8) | Up to 400 Gbps+ |
| **Interference** | Susceptible (EMI, crosstalk) | Immune |
| **Latency** | Standard | Slightly lower |
| **Weight** | Heavier | Lighter |
| **Flexibility** | More flexible | Fragile |
| **Installation** | Easy (RJ45 connectors) | Requires fusion splicing |
| **Cost (cable)** | Lower | Higher |
| **Cost (equipment)** | Lower | Higher (SFP modules) |
| **Security** | Can be tapped | Difficult to tap |
| **Power (PoE)** | Yes | No |
| **Use Case** | Desktop connections | Building uplinks, long runs |

**Use Copper**: Within buildings, device connections, PoE required

**Use Fiber**: Between buildings, long distances (>100m), high-speed uplinks, EMI environments

## Network Topologies

### Physical Topologies

| Topology | Description | Advantages | Disadvantages | Modern Use |
| --- | --- | --- | --- | --- |
| **Star** | All devices connect to central hub/switch | Easy to add devices, isolated failures | Single point of failure (hub) | Standard for LANs |
| **Bus** | All devices on single cable | Simple, low cost | Collisions, limited length | Obsolete |
| **Ring** | Each device connects to two neighbors | Equal access, predictable | Single break disrupts all | Obsolete (except SONET) |
| **Mesh** | Every device connects to every other | Redundancy, reliability | Expensive, complex | Data centers, wireless mesh |
| **Hybrid** | Combination of topologies | Flexible, scalable | Complex design | Enterprise networks |

**Recommendation**: Star topology for access layer, mesh or partial mesh for core/distribution

## Addressing

### Static vs DHCP

| Feature | Static IP | DHCP |
| --- | --- | --- |
| **Configuration** | Manual on each device | Automatic from server |
| **Management** | Difficult (must track) | Centralized |
| **IP Conflicts** | Possible if not tracked | Prevented |
| **DNS/Gateway Changes** | Update each device | Update once on server |
| **Reliability** | Always same IP | Can change (but unlikely) |
| **Security** | Slightly better | Good (with reservations) |
| **Use Case** | Servers, printers, infrastructure | Workstations, mobiles |
| **Troubleshooting** | Easier (predictable) | Requires checking DHCP |
| **Documentation** | Required | Optional (leases logged) |

**Best Practice**: Use DHCP reservations (static IP from DHCP) for best of both

**Static IPs for**: Network equipment (switches, routers, APs), servers, printers

**DHCP for**: Workstations, laptops, phones, guest devices

### Public vs Private IP

| Feature | Public IP | Private IP |
| --- | --- | --- |
| **Routable** | Internet-routable | Local network only |
| **Unique** | Globally unique | Reusable (many networks use same) |
| **Assignment** | ISP or IANA | Network administrator |
| **Cost** | Expensive (scarcity) | Free |
| **NAT Required** | No | Yes (for internet access) |
| **Security** | Exposed to internet | Protected behind NAT |
| **Ranges** | All except reserved | 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 |
| **Use Case** | Internet-facing servers | Internal networks |

**Recommendation**: Use private IPs internally, NAT to public IP(s) for internet access

## Related Topics

- [Network Fundamentals](fundamentals.md) - Core concepts
- [Routing Protocols](routing.md) - Detailed routing information
- [Wireless Networking](wireless.md) - WiFi technologies
- [Security](firewalls.md) - Network security
- [Scenarios](scenarios/index.md) - Real-world implementations

---

*These comparisons help guide technology selection decisions. Consider your specific requirements, budget, and expertise when choosing technologies.*
