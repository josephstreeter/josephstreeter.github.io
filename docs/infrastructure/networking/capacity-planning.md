---
title: "Network Capacity Planning"
description: "Guide to sizing, scaling, and planning network capacity for current and future needs"
tags: ["networking", "capacity-planning", "performance", "scaling"]
category: "networking"
difficulty: "intermediate"
last_updated: "2025-12-30"
---

## Overview

Capacity planning ensures your network can handle current workloads and scale for future growth. This guide covers bandwidth calculations, device capacity, performance monitoring, and growth planning.

## Key Capacity Metrics

### Bandwidth

**Definition**: Maximum data transfer rate

**Measurement**: bits per second (bps, Kbps, Mbps, Gbps)

**Types**:

- **Theoretical**: Maximum possible (e.g., 1 Gbps Ethernet)
- **Actual**: Real-world throughput (typically 70-95% of theoretical)
- **Available**: Unused capacity at any moment

### Throughput

**Definition**: Actual data successfully transferred

**Factors affecting**:

- Protocol overhead (TCP/IP headers)
- Errors and retransmissions
- Congestion
- Device processing capacity

**Rule of Thumb**: Expect 70-90% of rated bandwidth in real-world conditions

### Latency

**Definition**: Time for packet to travel from source to destination

**Measurement**: milliseconds (ms)

**Components**:

- **Propagation Delay**: Physical distance (light/electrical speed in medium)
- **Transmission Delay**: Time to push bits onto wire
- **Processing Delay**: Router/switch processing time
- **Queuing Delay**: Waiting in buffers

**Acceptable Latency**:

- **Web browsing**: < 100 ms
- **VoIP**: < 150 ms (preferably < 30 ms)
- **Video conferencing**: < 150 ms
- **Gaming**: < 50 ms
- **Trading/Real-time**: < 10 ms

### Packet Loss

**Definition**: Percentage of packets that fail to reach destination

**Acceptable Levels**:

- **Data applications**: < 1%
- **VoIP**: < 0.5%
- **Video**: < 0.1%

### Jitter

**Definition**: Variation in packet arrival times

**Impact**: Critical for VoIP and video

**Acceptable**: < 30 ms for VoIP

## Bandwidth Planning

### User Bandwidth Requirements

**Per-User Estimates** (typical):

| Activity | Bandwidth | Notes |
| --- | --- | --- |
| **Email** | 100-500 Kbps | Text-based, occasional attachments |
| **Web Browsing** | 1-5 Mbps | Modern websites with images/video |
| **VoIP Call** | 100 Kbps | Per concurrent call |
| **Video Conferencing** | 1-4 Mbps | HD quality, per participant |
| **Video Streaming** | 5-25 Mbps | HD to 4K |
| **File Downloads** | Varies | Peaks based on file size |
| **Cloud Applications** | 1-5 Mbps | Office 365, Google Workspace |
| **VDI/Remote Desktop** | 150 Kbps - 10 Mbps | Depends on use case |

### Calculating Internet Bandwidth

**Formula**:

```text
Total Bandwidth = (Users × Average per User) × Oversubscription Factor
```

**Example: Small Office (20 users)**

```text
Assumptions:
- 20 users
- Average: 2 Mbps per user during work hours
- Oversubscription: 4:1 (not all users at max simultaneously)
- Growth: 25% over 3 years

Calculation:
Base: 20 users × 2 Mbps = 40 Mbps
With oversubscription: 40 Mbps ÷ 4 = 10 Mbps minimum
With growth: 10 Mbps × 1.25 = 12.5 Mbps

Recommendation: 25 Mbps circuit (room for peaks and growth)
```

**Example: Medium Office (100 users)**

```text
Assumptions:
- 100 users
- Mix: 60% light (1 Mbps), 30% medium (3 Mbps), 10% heavy (10 Mbps)
- Oversubscription: 5:1
- Peak factor: 1.5× (spikes during lunch, start/end of day)

Calculation:
Light: 60 × 1 Mbps = 60 Mbps
Medium: 30 × 3 Mbps = 90 Mbps
Heavy: 10 × 10 Mbps = 100 Mbps
Total: 250 Mbps
With oversubscription: 250 ÷ 5 = 50 Mbps
With peak factor: 50 × 1.5 = 75 Mbps

Recommendation: 100 Mbps circuit minimum, 200 Mbps ideal
```

### Oversubscription Ratios

**Definition**: Ratio of total possible bandwidth to available bandwidth

**Common Ratios**:

- **Access Layer**: 20:1 to 40:1 (users to uplink)
- **Distribution Layer**: 4:1 to 8:1
- **Core Layer**: 1:1 to 2:1 (minimal oversubscription)
- **Internet**: 4:1 to 10:1 (depends on usage patterns)

**Example**:

```text
48-port gigabit switch with 10 Gbps uplink:
- Total capacity: 48 × 1 Gbps = 48 Gbps
- Uplink capacity: 10 Gbps
- Oversubscription: 48:10 or 4.8:1 ✅ (acceptable)

48-port gigabit switch with 1 Gbps uplink:
- Total capacity: 48 Gbps
- Uplink capacity: 1 Gbps
- Oversubscription: 48:1 ⚠️ (potential bottleneck)
```

## Device Capacity

### Switch Capacity

**Factors**:

**Port Count**: Number of devices supported

**Switching Capacity**: Internal bandwidth (measured in Gbps)

- Formula: Port Count × Port Speed × 2 (full-duplex)
- Example: 48-port gigabit = 48 × 1 × 2 = 96 Gbps

**Forwarding Rate**: Packets per second (pps)

- Gigabit port: ~1.488 million pps
- 10 Gbps port: ~14.88 million pps

**Buffer Size**: Packet queue capacity

- Larger buffers = handle bursts better
- Too large = increased latency

**MAC Address Table**: Maximum number of MAC addresses learned

- Typical: 8,000-32,000 entries
- Enterprise: 128,000+ entries

### Router Capacity

**Factors**:

**Throughput**: Packet forwarding rate (Mbps/Gbps)

- Often less than interface speed due to processing
- Varies by features enabled (firewall, VPN, etc.)

**Packets Per Second**: Processing capacity

- Small packets = more PPS required
- 1 Gbps with 64-byte packets = 1.488 Mpps

**Concurrent Sessions**: Number of simultaneous connections

- Residential: 10,000-50,000
- SMB: 100,000-500,000
- Enterprise: 1M-10M+

**VPN Throughput**: Encrypted traffic capacity

- Usually 30-60% of routing throughput
- Hardware acceleration improves performance

### Wireless Access Point Capacity

**Theoretical vs Real-World**:

| Standard | Theoretical | Real-World | Clients/AP | Notes |
| --- | --- | --- | --- | --- |
| **802.11n** | 600 Mbps | 200-300 Mbps | 25-30 | 2.4 GHz + 5 GHz |
| **802.11ac** | 1.3 Gbps | 500-800 Mbps | 30-50 | Wave 1 |
| **802.11ac** | 3.5 Gbps | 1-1.5 Gbps | 50-75 | Wave 2 |
| **802.11ax (WiFi 6)** | 9.6 Gbps | 2-4 Gbps | 75-200 | Better efficiency |

**Capacity Factors**:

- **Client count**: More clients = shared airtime
- **Client types**: WiFi 6 clients more efficient
- **Channel width**: Wider channels = more speed, less overlapping
- **Frequency**: 5 GHz faster but shorter range than 2.4 GHz

**Planning Guidelines**:

- **Office**: 1 AP per 2,000-3,000 sq ft, 30-50 users per AP
- **High-density** (conference room): 1 AP per 1,000 sq ft, 50-75 users per AP
- **Warehouse**: 1 AP per 10,000 sq ft, 10-20 users per AP

## Server Capacity

### Network Interface Requirements

**1 Gbps NICs**:

- Small office file servers
- Web servers (< 50 concurrent users)
- Most virtual machines

**10 Gbps NICs**:

- Medium enterprise file servers
- Database servers
- Virtualization hosts
- High-traffic web servers

**25/40/100 Gbps**:

- Data center storage
- High-performance computing
- Dense virtualization

### Application-Specific

**File Server**:

```text
Formula: (Users × Average Transfer Rate × Simultaneity Factor)

Example: 100 users
- Average transfer: 10 Mbps per user
- Simultaneity: 20% (20 users accessing simultaneously)

Calculation: 100 × 10 Mbps × 0.20 = 200 Mbps
Recommendation: 1 Gbps NIC (headroom for peaks)
```

**Database Server**:

```text
Consider:
- Transaction rate (transactions/second)
- Average transaction size
- Query complexity
- Number of concurrent connections

Recommendation: 10 Gbps for > 100 concurrent users
```

**Web Server**:

```text
Formula: (Concurrent Users × Page Size) / Page Load Time

Example:
- 500 concurrent users
- 2 MB average page size
- 2 second target load time

Calculation: (500 × 2 MB × 8 bits) / 2 sec = 4 Gbps
Recommendation: 10 Gbps NIC or load balancer across multiple 1 Gbps servers
```

## Growth Planning

### Forecasting Growth

**Historical Analysis**:

1. **Collect baseline data** (6-12 months):
   - Bandwidth utilization
   - User count
   - Application usage
   - Peak periods

2. **Calculate growth rate**:

   ```text
   Monthly Growth % = ((Current - Previous) / Previous) × 100
   Annual Growth % = Monthly Growth % × 12
   ```

3. **Project future needs**:

   ```text
   Future Capacity = Current Capacity × (1 + Growth Rate)^Years
   
   Example:
   Current: 100 Mbps
   Growth: 15% annually
   Planning: 3 years
   
   Future = 100 × (1.15)^3 = 152 Mbps
   Recommendation: 200 Mbps circuit (30% buffer)
   ```

### Planning Horizons

**Short-term (1 year)**:

- Monitor current utilization
- Address immediate bottlenecks
- Plan for known changes (new hires, applications)

**Medium-term (2-3 years)**:

- Equipment refresh cycles
- Technology upgrades (WiFi 6 → WiFi 7)
- Capacity expansion (more switches, APs)

**Long-term (5 years)**:

- Architectural changes
- New building/site additions
- Major technology shifts (10 Gbps → 25 Gbps)

### Capacity Triggers

**When to Upgrade**:

**Internet Connection**:

- Sustained > 70% utilization during peak hours
- Frequent complaints about slow access
- New applications require bandwidth

**Switches**:

- Ports exhausted (> 80% utilized)
- Uplink saturation (> 70% sustained)
- Switch CPU > 70%

**Wireless**:

- Client count approaching AP maximum
- RSSI < -70 dBm in coverage areas
- Frequent disconnections or roaming issues

**Servers**:

- NIC utilization > 70% sustained
- Packet drops due to buffer overflows
- Application response time degradation

## Performance Monitoring

### Key Performance Indicators (KPIs)

**Network Availability**:

```text
Availability % = (Total Time - Downtime) / Total Time × 100

Target: 99.9% (43.8 minutes downtime/month)
Enterprise: 99.99% (4.38 minutes downtime/month)
```

**Bandwidth Utilization**:

```text
Utilization % = (Current Traffic / Maximum Capacity) × 100

Healthy: < 70% peak
Warning: 70-85% peak
Critical: > 85% sustained
```

**Packet Loss**:

```text
Loss % = (Packets Lost / Packets Sent) × 100

Target: < 0.1%
```

**Latency (Ping)**:

```text
Target:
- LAN: < 10 ms
- Internet: < 100 ms
- VoIP: < 150 ms
```

### Monitoring Tools

**Open Source**:

- **PRTG** (free tier): SNMP monitoring, bandwidth sensors
- **Nagios**: Infrastructure monitoring, alerting
- **Zabbix**: Comprehensive monitoring
- **LibreNMS**: SNMP-based network monitoring
- **Cacti**: Graphing, trending

**Commercial**:

- **SolarWinds Network Performance Monitor**: Comprehensive, expensive
- **PRTG** (paid): User-friendly, scalable
- **Datadog**: Cloud-native, APM integration
- **Auvik**: Cloud-managed, MSP-focused

**Built-in**:

- Switch/router SNMP
- NetFlow/sFlow
- Syslog
- RMON

### Establishing Baselines

**Process**:

1. **Collect data** for 2-4 weeks (capture all patterns)
2. **Identify patterns**:
   - Peak usage times (morning login, lunch, end of day)
   - Day of week variations (Monday vs. Friday)
   - Monthly cycles (month-end reporting)
3. **Document normal ranges**:
   - Average utilization
   - 95th percentile (billing standard)
   - Peak utilization
4. **Set alerting thresholds**:
   - Warning: 70% of capacity
   - Critical: 85% of capacity

## Capacity Planning Checklist

### Assessment Phase

- ☐ Document current users and devices
- ☐ Measure current bandwidth utilization
- ☐ Identify applications and their requirements
- ☐ Review historical growth trends
- ☐ Survey user satisfaction and complaints

### Planning Phase

- ☐ Calculate bandwidth requirements per user/application
- ☐ Apply oversubscription ratios
- ☐ Factor in growth projections (3-5 years)
- ☐ Add buffer capacity (20-30%)
- ☐ Consider redundancy requirements

### Design Phase

- ☐ Select appropriate circuit sizes
- ☐ Design switch/router hierarchy with adequate uplinks
- ☐ Plan WiFi AP density and placement
- ☐ Size server NICs appropriately
- ☐ Document expected performance metrics

### Implementation Phase

- ☐ Deploy monitoring tools
- ☐ Establish performance baselines
- ☐ Configure alerting thresholds
- ☐ Document as-built capacity

### Ongoing Phase

- ☐ Monthly utilization reviews
- ☐ Quarterly capacity reports
- ☐ Annual growth assessment
- ☐ Proactive upgrades before saturation

## Real-World Examples

### Example 1: Small Office Internet Upgrade

**Scenario**: 25-user office, frequent complaints about slow internet

**Assessment**:

- Current: 50 Mbps cable internet
- Measured peak: 48 Mbps (96% utilization)
- Growth: 3 new hires planned this year

**Analysis**:

```text
Current per-user: 50 Mbps / 25 = 2 Mbps
With new hires: 50 Mbps / 28 = 1.79 Mbps (insufficient)
Target per-user: 3 Mbps (comfortable)
Required: 28 × 3 Mbps = 84 Mbps
With buffer (25%): 84 × 1.25 = 105 Mbps
```

**Solution**: Upgrade to 100 Mbps (available) or 150 Mbps (future-proof)

### Example 2: Enterprise Switch Uplink Bottleneck

**Scenario**: 48-port access switch, slow file transfers during peak hours

**Assessment**:

- Switch: 48× 1 Gbps ports, 1× 1 Gbps uplink to core
- Peak uplink utilization: 950 Mbps (95%)
- Oversubscription: 48:1 (problematic)

**Analysis**:

```text
Ideal oversubscription: 4:1 to 8:1
Required uplink: 48 Gbps / 6 = 8 Gbps
Available: 10 Gbps uplink port on switch
```

**Solution**: Upgrade uplink to 10 Gbps, improves oversubscription to 4.8:1

### Example 3: WiFi Capacity for Conference Room

**Scenario**: 100-person conference room, video-heavy presentations

**Assessment**:

- Current: 1× WiFi 5 AP (theoretical 1.3 Gbps, real-world 600 Mbps)
- Expected load: 75 concurrent clients streaming 1080p video
- Requirement: 5 Mbps per client for HD streaming

**Analysis**:

```text
Total required: 75 × 5 Mbps = 375 Mbps
Current capacity: 600 Mbps (sufficient for bandwidth)
BUT: WiFi 5 AP typically supports 30-50 clients efficiently

Client density problem: 75 clients on 1 AP = degraded performance
```

**Solution**:

- Option 1: 2× WiFi 6 APs (each supports 75 clients, provides redundancy)
- Option 2: 3× WiFi 5 APs (distributed load: 25 clients each)

Recommendation: Option 1 (WiFi 6 for efficiency and future-proofing)

## Related Topics

- [Network Fundamentals](fundamentals.md) - Core networking concepts
- [Architecture](architecture.md) - Network design principles
- [Scenarios](scenarios/index.md) - Real-world implementations
- [Troubleshooting](troubleshooting.md) - Performance diagnostics
- [Comparisons](comparisons.md) - Technology selection guidance

## Additional Resources

- **Cisco Network Design Guide**: Capacity planning best practices
- **PRTG Bandwidth Calculator**: Online bandwidth estimation tool
- **NetFlow Analyzers**: Baselining and trending tools

---

*Proper capacity planning prevents performance issues, reduces downtime, and ensures efficient resource utilization. Plan for growth, monitor continuously, and upgrade proactively.*
