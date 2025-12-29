---
title: OSI Model - Comprehensive Guide
description: "Complete guide to the OSI (Open Systems Interconnection) model: seven layers, protocols, encapsulation, and practical troubleshooting."
ms.topic: reference
ms.date: 2025-11-29
---

The OSI (Open Systems Interconnection) model is a conceptual framework that standardizes the functions of a communication system into seven distinct layers. It helps network professionals understand, design, and troubleshoot network communications.

## Quick Start

- OSI model has 7 layers: Physical, Data Link, Network, Transport, Session, Presentation, Application
- Each layer provides services to the layer above and uses services from the layer below
- Data is encapsulated as it moves down the stack and de-encapsulated moving up
- Mnemonic: "Please Do Not Throw Sausage Pizza Away" (Physical to Application)
- Understanding the OSI model helps with systematic network troubleshooting

## The Seven Layers Overview

| Layer | Number | Name | Function | Protocol Data Unit (PDU) |
|-------|--------|------|----------|--------------------------|
| 7 | Application | User Interface | Network services to applications | Data |
| 6 | Presentation | Data Translation | Data formatting, encryption | Data |
| 5 | Session | Session Management | Establish/manage connections | Data |
| 4 | Transport | Reliable Delivery | End-to-end communication | Segment/Datagram |
| 3 | Network | Routing | Logical addressing, routing | Packet |
| 2 | Data Link | MAC Addressing | Physical addressing, error detection | Frame |
| 1 | Physical | Transmission | Physical transmission of bits | Bits |

## Layer 1: Physical Layer

The Physical layer deals with the physical connection between devices and the transmission of raw bit streams over a physical medium.

### Physical Layer Functions

- **Bit Transmission:** Convert data into electrical, optical, or radio signals
- **Physical Topology:** Define how devices are physically connected (bus, star, ring, mesh)
- **Media Types:** Specify cable types, connectors, and transmission modes
- **Signal Encoding:** Define how bits are represented (voltage levels, light pulses, radio waves)
- **Bit Synchronization:** Ensure sender and receiver clocks are synchronized
- **Data Rate:** Define transmission speed (bandwidth)
- **Physical Configuration:** Simplex, half-duplex, or full-duplex transmission

### Physical Layer Technologies and Protocols

- **Cables:** Ethernet cables (Cat5e, Cat6, Cat7), fiber optic, coaxial
- **Wireless:** Wi-Fi radio frequencies (2.4 GHz, 5 GHz, 6 GHz)
- **Connectors:** RJ45, BNC, SC/LC (fiber), SFP/SFP+
- **Standards:** IEEE 802.3 (Ethernet), RS-232, USB physical specifications
- **Devices:** Hubs, repeaters, cables, network interface cards (physical component)

### Specifications

```text
Cable Type        | Max Distance | Speed          | Use Case
------------------|--------------|----------------|------------------
Cat5e             | 100m         | 1 Gbps         | General purpose
Cat6              | 100m         | 10 Gbps (55m)  | High-speed LAN
Cat6a             | 100m         | 10 Gbps        | Data centers
Cat7              | 100m         | 10 Gbps        | Shielded environments
Fiber (MM)        | 550m         | 10 Gbps        | Building backbone
Fiber (SM)        | 40km+        | 100 Gbps+      | Long distance
```

### Troubleshooting Physical Layer

- Check cable connections and integrity
- Verify cable is within maximum distance limits
- Test with cable tester for breaks, shorts, or improper termination
- Check for electromagnetic interference (EMI)
- Verify port lights and link status LEDs
- Replace suspected faulty cables, connectors, or NICs
- Check for proper grounding

## Layer 2: Data Link Layer

The Data Link layer provides node-to-node data transfer and handles error detection and correction from the Physical layer.

### Data Link Layer Functions

- **Physical Addressing:** Use MAC addresses for device identification
- **Frame Formation:** Encapsulate network layer data into frames
- **Error Detection:** Use CRC (Cyclic Redundancy Check) to detect transmission errors
- **Flow Control:** Manage data transmission rate between devices
- **Access Control:** Determine which device has control of the link (CSMA/CD, CSMA/CA)
- **Frame Synchronization:** Identify frame boundaries

### Sublayers

**MAC (Media Access Control):**

- Controls how devices access the medium
- Manages physical addressing (MAC addresses)
- Implements CSMA/CD (Ethernet) or CSMA/CA (Wi-Fi)

**LLC (Logical Link Control):**

- Provides interface to Network layer
- Handles error control and flow control
- Multiplexing for multiple network protocols

### Data Link Layer Technologies and Protocols

- **Ethernet (IEEE 802.3):** Most common LAN protocol
- **Wi-Fi (IEEE 802.11):** Wireless LAN
- **PPP (Point-to-Point Protocol):** WAN connections
- **HDLC (High-Level Data Link Control):** Synchronous data link protocol
- **Frame Relay:** Legacy WAN protocol
- **ARP (Address Resolution Protocol):** Maps IP to MAC addresses
- **Devices:** Switches, bridges, wireless access points, NICs (logical component)

### Frame Structure (Ethernet)

```text
| Preamble | Dest MAC | Src MAC | Type/Length | Data (Payload) | FCS |
|  7 bytes |  6 bytes | 6 bytes |   2 bytes   |   46-1500 B    | 4 B |

Preamble: Synchronization pattern
Dest MAC: Destination hardware address
Src MAC: Source hardware address
Type/Length: EtherType (e.g., 0x0800 for IPv4) or frame length
Data: Layer 3 packet
FCS: Frame Check Sequence (CRC-32)
```

### MAC Address Format

```text
AA:BB:CC:DD:EE:FF (48 bits / 6 bytes)
│  │  │  └─┬──┘
│  │  │    └──── Device specific (NIC)
│  └──┴───────── Manufacturer OUI (Organizationally Unique Identifier)

Special Addresses:
FF:FF:FF:FF:FF:FF - Broadcast (all devices)
01:00:5E:xx:xx:xx - Multicast (group)
```

### Troubleshooting Data Link Layer

- Check MAC address tables on switches
- Verify VLANs are configured correctly
- Look for duplicate MAC addresses
- Check for spanning tree issues
- Monitor for excessive collisions or CRC errors
- Verify switch port configuration and status
- Check for broadcast storms

## Layer 3: Network Layer

The Network layer handles routing and forwarding of packets across different networks using logical addressing.

### Network Layer Functions

- **Logical Addressing:** Use IP addresses for network identification
- **Routing:** Determine best path for packet delivery
- **Packet Forwarding:** Move packets from source to destination across networks
- **Fragmentation and Reassembly:** Break large packets into smaller ones if needed
- **Quality of Service (QoS):** Prioritize traffic based on requirements
- **Error Handling:** Report delivery errors (ICMP)

### Network Layer Technologies and Protocols

**Routing Protocols:**

- **Static Routing:** Manually configured routes
- **RIP (Routing Information Protocol):** Distance-vector, hop count metric
- **OSPF (Open Shortest Path First):** Link-state, used within autonomous systems
- **EIGRP (Enhanced Interior Gateway Routing Protocol):** Cisco proprietary, hybrid
- **BGP (Border Gateway Protocol):** Path-vector, used between autonomous systems (Internet backbone)

**Protocols:**

- **IPv4:** 32-bit addressing, most common
- **IPv6:** 128-bit addressing, next generation
- **ICMP (Internet Control Message Protocol):** Error reporting, ping, traceroute
- **IPsec:** Secure IP communications
- **IGMP (Internet Group Management Protocol):** Multicast group management

**Devices:** Routers, Layer 3 switches, firewalls

### IPv4 Packet Header

```text
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|Version|  IHL  |Type of Service|          Total Length         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|         Identification        |Flags|      Fragment Offset    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Time to Live |    Protocol   |         Header Checksum       |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                       Source IP Address                       |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Destination IP Address                     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Options (if IHL > 5)                       |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

### IP Address Classes and CIDR

```text
Class A: 1.0.0.0    - 126.255.255.255  (0.0.0.0/8)     - Large networks
Class B: 128.0.0.0  - 191.255.255.255  (128.0.0.0/16)  - Medium networks
Class C: 192.0.0.0  - 223.255.255.255  (192.0.0.0/24)  - Small networks
Class D: 224.0.0.0  - 239.255.255.255                  - Multicast
Class E: 240.0.0.0  - 255.255.255.255                  - Experimental

Private IP Ranges:
10.0.0.0/8        (10.0.0.0      - 10.255.255.255)
172.16.0.0/12     (172.16.0.0    - 172.31.255.255)
192.168.0.0/16    (192.168.0.0   - 192.168.255.255)

CIDR Notation:
192.168.1.0/24    - /24 = 255.255.255.0 (256 addresses, 254 usable)
192.168.1.0/25    - /25 = 255.255.255.128 (128 addresses, 126 usable)
192.168.1.0/26    - /26 = 255.255.255.192 (64 addresses, 62 usable)
```

### Troubleshooting Network Layer

- Verify IP address configuration (address, subnet mask, gateway)
- Check routing tables (`route print`, `netstat -r`, `ip route`)
- Use `ping` to test connectivity
- Use `traceroute`/`tracert` to identify routing path
- Verify routing protocol convergence
- Check for IP conflicts
- Verify firewall rules aren't blocking traffic
- Check NAT/PAT configuration

## Layer 4: Transport Layer

The Transport layer provides end-to-end communication services for applications, including reliability, flow control, and error correction.

### Transport Layer Functions

- **Segmentation:** Divide application data into smaller segments
- **Reassembly:** Reconstruct data at destination
- **Connection Management:** Establish, maintain, and terminate connections
- **Error Detection and Recovery:** Detect and retransmit lost or corrupted segments
- **Flow Control:** Prevent sender from overwhelming receiver
- **Multiplexing:** Multiple applications use network simultaneously via ports
- **Quality of Service:** Prioritize certain traffic

### Protocols

**TCP (Transmission Control Protocol):**

- **Connection-oriented:** Three-way handshake establishes connection
- **Reliable:** Acknowledgments and retransmissions ensure delivery
- **Ordered:** Data arrives in correct sequence
- **Flow Control:** Sliding window mechanism
- **Error Checking:** Checksums verify data integrity
- **Use Cases:** HTTP, HTTPS, FTP, SMTP, SSH, Telnet

**UDP (User Datagram Protocol):**

- **Connectionless:** No connection establishment
- **Unreliable:** No acknowledgments or retransmissions
- **No ordering:** Packets may arrive out of order
- **Low overhead:** Faster than TCP
- **Use Cases:** DNS, DHCP, SNMP, VoIP, streaming media, online gaming

### TCP Three-Way Handshake

```text
Client                          Server
  |                               |
  |--- SYN (seq=x) ------------->|  1. Client initiates connection
  |                               |
  |<-- SYN-ACK (seq=y, ack=x+1) -|  2. Server acknowledges and responds
  |                               |
  |--- ACK (ack=y+1) ------------>|  3. Client acknowledges
  |                               |
  |<===== Connection Established =====>|
```

### TCP Segment Header

```text
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|          Source Port          |       Destination Port        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        Sequence Number                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Acknowledgment Number                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Data |     |N|C|E|U|A|P|R|S|F|                               |
| Offset| Res |S|W|C|R|C|S|S|Y|I|            Window             |
|       |     | |R|E|G|K|H|T|N|N|                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|           Checksum            |         Urgent Pointer        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

### Common Port Numbers

```text
Well-Known Ports (0-1023):
20/21   - FTP (Data/Control)
22      - SSH
23      - Telnet
25      - SMTP
53      - DNS
67/68   - DHCP (Server/Client)
80      - HTTP
110     - POP3
143     - IMAP
443     - HTTPS
3389    - RDP (Remote Desktop)

Registered Ports (1024-49151):
3306    - MySQL
5432    - PostgreSQL
27017   - MongoDB

Dynamic/Private Ports (49152-65535):
Used for client-side ephemeral ports
```

### Troubleshooting Transport Layer

- Check listening ports (`netstat -an`, `ss -tuln`)
- Verify firewalls allow required ports
- Check for port conflicts
- Monitor for excessive retransmissions
- Verify TCP window size isn't too small
- Check for SYN flood attacks
- Test with telnet or nc (netcat) to specific ports
- Analyze packet captures with Wireshark

## Layer 5: Session Layer

The Session layer establishes, manages, and terminates sessions between applications.

### Session Layer Functions

- **Session Establishment:** Set up communication sessions
- **Session Maintenance:** Keep sessions alive during data transfer
- **Session Termination:** Gracefully close sessions
- **Dialog Control:** Manage who can transmit when (simplex, half-duplex, full-duplex)
- **Synchronization:** Add checkpoints to data stream for recovery
- **Token Management:** Control who has access to resources

### Session Layer Technologies and Protocols

- **NetBIOS:** Network Basic Input/Output System
- **RPC (Remote Procedure Call):** Execute procedures on remote systems
- **PPTP (Point-to-Point Tunneling Protocol):** VPN protocol
- **PAP/CHAP:** Authentication protocols
- **SQL Sessions:** Database connection management
- **SMB/CIFS:** File sharing protocol sessions

### Session Management Examples

```text
Web Session:
1. Client sends HTTP request
2. Server creates session ID
3. Session cookie sent to client
4. Client includes session ID in subsequent requests
5. Server maintains session state
6. Session expires or explicitly logged out

Database Session:
1. Application connects to database
2. Authentication and authorization
3. Session established with transaction context
4. Multiple queries executed within session
5. Commit or rollback transactions
6. Connection pooling for efficiency
```

### Troubleshooting Session Layer

- Check session timeouts
- Verify authentication credentials
- Monitor for session hijacking
- Check session state synchronization
- Verify session IDs are unique and secure
- Monitor for resource exhaustion from too many sessions

## Layer 6: Presentation Layer

The Presentation layer translates data between the application layer and the network format, handling data representation, encryption, and compression.

### Presentation Layer Functions

- **Data Translation:** Convert between application and network formats
- **Data Encryption/Decryption:** Secure data transmission
- **Data Compression/Decompression:** Reduce data size for transmission
- **Character Encoding:** Handle different character sets (ASCII, Unicode, EBCDIC)
- **Data Formatting:** Manage data structure (XML, JSON, binary)
- **Graphics Formatting:** Handle image formats (JPEG, GIF, PNG)

### Presentation Layer Technologies and Protocols

- **SSL/TLS:** Encryption for secure communications
- **JPEG, GIF, PNG, TIFF:** Image formats
- **MPEG, QuickTime:** Video formats
- **ASCII, EBCDIC, Unicode:** Character encodings
- **MIME:** Email attachment encoding
- **XDR (External Data Representation):** Data serialization
- **Encryption Standards:** AES, DES, RSA

### Data Representation

```text
Character Encoding:
ASCII  (7-bit): 0-127 characters
UTF-8  (variable): 1-4 bytes per character
UTF-16 (variable): 2-4 bytes per character
UTF-32 (fixed): 4 bytes per character

Serialization Formats:
JSON   - Text-based, human-readable
XML    - Text-based, verbose, hierarchical
Protobuf - Binary, efficient, requires schema
MessagePack - Binary, efficient, schemaless

Compression:
gzip   - General purpose compression
bzip2  - Higher compression ratio
LZ4    - Fast compression/decompression
Zstandard - Modern, flexible compression
```

### TLS Handshake

```text
Client                                Server
  |                                     |
  |--- ClientHello ------------------>|  1. Supported cipher suites
  |                                     |
  |<-- ServerHello -------------------|  2. Selected cipher suite
  |<-- Certificate -------------------|  3. Server certificate
  |<-- ServerHelloDone ---------------|
  |                                     |
  |--- ClientKeyExchange ------------>|  4. Encrypted pre-master secret
  |--- ChangeCipherSpec ------------->|  5. Activate encryption
  |--- Finished --------------------->|  6. Verification
  |                                     |
  |<-- ChangeCipherSpec --------------|  7. Server activates encryption
  |<-- Finished ----------------------|  8. Server verification
  |                                     |
  |<===== Encrypted Communication =========>|
```

### Troubleshooting Presentation Layer

- Check character encoding mismatches
- Verify SSL/TLS certificate validity
- Check cipher suite compatibility
- Verify compression is supported on both ends
- Check for data corruption during translation
- Monitor for failed encryption/decryption

## Layer 7: Application Layer

The Application layer provides network services directly to end-user applications and implements protocols for specific application functions.

### Application Layer Functions

- **Network Virtual Terminal:** Remote login (SSH, Telnet)
- **File Transfer:** FTP, SFTP, TFTP
- **Email:** SMTP, POP3, IMAP
- **Directory Services:** LDAP, Active Directory
- **Web Services:** HTTP, HTTPS
- **Network Management:** SNMP, NetFlow
- **Name Resolution:** DNS

### Common Protocols

**Web Protocols:**

- **HTTP:** Hypertext Transfer Protocol (port 80)
- **HTTPS:** HTTP Secure with TLS/SSL (port 443)
- **WebSocket:** Full-duplex communication
- **HTTP/2:** Multiplexed streams, server push
- **HTTP/3:** QUIC-based, improved performance

**Email Protocols:**

- **SMTP:** Simple Mail Transfer Protocol (port 25, 587)
- **POP3:** Post Office Protocol v3 (port 110, 995)
- **IMAP:** Internet Message Access Protocol (port 143, 993)

**File Transfer:**

- **FTP:** File Transfer Protocol (ports 20, 21)
- **SFTP:** SSH File Transfer Protocol (port 22)
- **TFTP:** Trivial FTP (port 69)
- **SMB/CIFS:** Server Message Block (port 445)

**Other Protocols:**

- **DNS:** Domain Name System (port 53)
- **DHCP:** Dynamic Host Configuration Protocol (ports 67, 68)
- **SNMP:** Simple Network Management Protocol (ports 161, 162)
- **LDAP:** Lightweight Directory Access Protocol (port 389)
- **NTP:** Network Time Protocol (port 123)
- **SSH:** Secure Shell (port 22)
- **Telnet:** Terminal emulation (port 23)

### HTTP Request/Response

```text
HTTP Request:
GET /index.html HTTP/1.1
Host: www.example.com
User-Agent: Mozilla/5.0
Accept: text/html
Connection: keep-alive

HTTP Response:
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 1234
Date: Fri, 29 Nov 2025 10:00:00 GMT

<html>...</html>
```

### DNS Resolution Process

```text
1. User enters www.example.com in browser
2. Browser checks local DNS cache
3. If not cached, query local DNS resolver
4. Resolver checks its cache
5. If not cached, query root DNS server
6. Root returns .com TLD nameserver
7. Query .com TLD nameserver
8. TLD returns authoritative nameserver for example.com
9. Query authoritative nameserver
10. Returns IP address (e.g., 93.184.216.34)
11. Browser connects to IP address
```

### Troubleshooting Application Layer

- Test with application-specific tools (web browser, curl, telnet)
- Check DNS resolution (`nslookup`, `dig`)
- Verify application is listening on correct port
- Check application logs for errors
- Test with different clients to isolate issue
- Verify credentials and permissions
- Check for service outages or maintenance
- Monitor response times and performance

## Data Encapsulation

As data moves down the OSI stack, each layer adds its own header (and sometimes trailer) to the data. This process is called encapsulation.

### Encapsulation Process

```text
Layer 7 (Application)  : Data
                         ↓
Layer 6 (Presentation) : Data (formatted/encrypted)
                         ↓
Layer 5 (Session)      : Data (with session info)
                         ↓
Layer 4 (Transport)    : [TCP/UDP Header | Data] = Segment/Datagram
                         ↓
Layer 3 (Network)      : [IP Header | Segment] = Packet
                         ↓
Layer 2 (Data Link)    : [Frame Header | Packet | Frame Trailer] = Frame
                         ↓
Layer 1 (Physical)     : 01010110101... = Bits
```

### PDU Names by Layer

```text
Application/Presentation/Session: Data
Transport: Segment (TCP) or Datagram (UDP)
Network: Packet
Data Link: Frame
Physical: Bits
```

### Example: Sending an Email

```text
Layer 7: User composes email in client (Application)
         SMTP protocol formats the message

Layer 6: Email content encoded (UTF-8, MIME) (Presentation)
         Attachments converted to base64

Layer 5: SMTP session established with mail server (Session)

Layer 4: TCP segments created with source/dest ports (Transport)
         Port 25 or 587 for SMTP

Layer 3: IP packets created with source/dest IP addresses (Network)
         Routing decisions made

Layer 2: Ethernet frames created with source/dest MAC addresses (Data Link)
         CRC added for error detection

Layer 1: Electrical signals transmitted over cable (Physical)
         Or radio waves if Wi-Fi
```

## OSI vs TCP/IP Model

### Comparison

| OSI Model | TCP/IP Model | Function |
|-----------|--------------|----------|
| Application | Application | User interface and application services |
| Presentation | Application | Data formatting and encryption |
| Session | Application | Session management |
| Transport | Transport | End-to-end connections (TCP/UDP) |
| Network | Internet | Routing and logical addressing (IP) |
| Data Link | Network Access | Physical addressing (MAC) |
| Physical | Network Access | Physical transmission |

### TCP/IP Model Layers

**Application Layer (OSI 5-7):**

- Combines OSI Application, Presentation, and Session layers
- Protocols: HTTP, FTP, SMTP, DNS, DHCP, SSH

**Transport Layer (OSI 4):**

- Same as OSI Transport layer
- Protocols: TCP, UDP

**Internet Layer (OSI 3):**

- Same as OSI Network layer
- Protocols: IP, ICMP, ARP, IGMP

**Network Access Layer (OSI 1-2):**

- Combines OSI Data Link and Physical layers
- Protocols: Ethernet, Wi-Fi, PPP

## Practical Troubleshooting with OSI Model

### Bottom-Up Approach

Start at Layer 1 and work up:

```text
Layer 1 (Physical):
✓ Is the cable plugged in?
✓ Are the link lights on?
✓ Is the cable damaged?
✓ Is the port enabled?

Layer 2 (Data Link):
✓ Is the NIC working?
✓ Is the MAC address correct?
✓ Is the switch port configured correctly?
✓ Are we seeing the device in the MAC table?

Layer 3 (Network):
✓ Is the IP address configured correctly?
✓ Is the subnet mask correct?
✓ Is the default gateway reachable?
✓ Can we ping the default gateway?

Layer 4 (Transport):
✓ Is the service listening on the correct port?
✓ Is the firewall blocking the port?
✓ Are we seeing TCP retransmissions?

Layer 5-7 (Session/Presentation/Application):
✓ Is the application configured correctly?
✓ Are credentials valid?
✓ Is the service running?
✓ Are there application-specific errors?
```

### Top-Down Approach

Start at Layer 7 and work down:

```text
Layer 7: Application not working
         ↓
         Check application configuration and logs
         ↓
Layer 4: Check if service is listening on port
         ↓
         Verify firewall rules
         ↓
Layer 3: Can we reach the server IP?
         ↓
         Ping and traceroute
         ↓
Layer 2: Is the MAC address in the ARP table?
         ↓
         Check switch configuration
         ↓
Layer 1: Is there physical connectivity?
         ↓
         Check cables and ports
```

### Divide and Conquer

Test at the middle layer (typically Layer 3):

```text
1. Ping the destination IP
   - Success? Problem is above Layer 3
   - Failure? Problem is at or below Layer 3

2. If ping works, test Layer 4
   - Check if port is open (telnet, nc)
   - Success? Problem is Layer 5-7
   - Failure? Check firewall and service status

3. If ping fails, test Layer 2
   - Check ARP table
   - Check MAC address reachability
   - Success? Problem is Layer 3
   - Failure? Check Layer 1
```

## Common Tools by Layer

### Layer 1 Tools

- Cable tester
- Multimeter
- Light meter (fiber)
- OTDR (Optical Time-Domain Reflectometer)
- Toner/probe

### Layer 2 Tools

- `arp -a` - View ARP cache
- `show mac address-table` - On switches
- Wireshark - Analyze frames
- `tcpdump` - Capture packets

### Layer 3 Tools

- `ping` - Test connectivity
- `traceroute`/`tracert` - Trace routing path
- `route` - View routing table
- `ip route` - Linux routing
- `pathping` - Windows combined ping/trace
- Wireshark - Analyze packets

### Layer 4 Tools

- `netstat` - View connections and ports
- `ss` - Socket statistics (Linux)
- `telnet host port` - Test port connectivity
- `nc` (netcat) - Port testing and data transfer
- `nmap` - Port scanning
- Wireshark - Analyze segments

### Layer 7 Tools

- `nslookup`/`dig` - DNS queries
- `curl`/`wget` - HTTP testing
- `telnet` - Protocol testing
- Browser developer tools
- Application-specific clients
- Wireshark - Analyze application data

## Real-World Scenarios

### Scenario 1: Website Not Loading

**Problem:** User cannot access <www.example.com>

**Troubleshooting:**

```text
Layer 7: Try different browser
         → Works in different browser: Browser issue
         → Fails in all browsers: Continue

Layer 4: Test port 80/443
         → telnet www.example.com 80
         → Connection refused: Web server not listening
         → Connection timeout: Continue

Layer 3: Ping www.example.com
         → Success: Problem is Layer 4+
         → Failure: Continue

Layer 3: DNS resolution
         → nslookup www.example.com
         → No response: DNS issue
         → IP returned: Continue with ping

Layer 2/1: Check local connectivity
         → Ping default gateway
         → Success: Problem upstream
         → Failure: Local network issue
```

### Scenario 2: File Share Not Accessible

**Problem:** Cannot access \\\\fileserver\\share

**Troubleshooting:**

```text
Layer 7: Test SMB service
         → net use \\fileserver\share
         → Access denied: Permission issue
         → Network error: Continue

Layer 4: Check port 445
         → telnet fileserver 445
         → Connected: SMB responding
         → Failed: Port blocked or service down

Layer 3: Ping fileserver
         → By name: Tests DNS + connectivity
         → By IP: Tests connectivity only

Layer 2: Check ARP
         → arp -a | grep fileserver-ip
         → Entry exists: Layer 2 working
         → No entry: ARP issue
```

### Scenario 3: VoIP Call Quality Issues

**Problem:** Poor VoIP call quality, choppy audio

**Troubleshooting:**

```text
Layer 7/6: Codec issues
         → Check codec compatibility
         → Verify compression settings

Layer 4: UDP packet loss
         → Wireshark: Look for dropped packets
         → Check jitter and latency
         → QoS not configured

Layer 3: Network congestion
         → Traceroute: Check hop latency
         → High latency or packet loss
         → Need QoS or bandwidth upgrade

Layer 2: Switch buffer overflow
         → Check switch statistics
         → Interface errors or drops

Layer 1: Bandwidth limitation
         → Speed test
         → Physical medium inadequate
```

## Quick Reference

### OSI Layers Mnemonic

**Physical → Application (Bottom to Top):**

- **P**lease **D**o **N**ot **T**hrow **S**ausage **P**izza **A**way
- **P**eople **D**o **N**eed **T**o **S**ee **P**amela **A**nderson

**Application → Physical (Top to Bottom):**

- **A**ll **P**eople **S**eem **T**o **N**eed **D**ata **P**rocessing
- **A**way **P**izza **S**ausage **T**hrow **N**ot **D**o **P**lease

### Layer Summary Table

| # | Layer | Key Devices | Protocols | PDU |
|---|-------|-------------|-----------|-----|
| 7 | Application | Firewalls, Gateways | HTTP, FTP, SMTP, DNS | Data |
| 6 | Presentation | Gateways | SSL/TLS, JPEG, MPEG | Data |
| 5 | Session | Gateways | NetBIOS, RPC | Data |
| 4 | Transport | Firewalls | TCP, UDP | Segment/Datagram |
| 3 | Network | Routers, L3 Switches | IP, ICMP, OSPF, BGP | Packet |
| 2 | Data Link | Switches, Bridges | Ethernet, PPP, ARP | Frame |
| 1 | Physical | Hubs, Repeaters | Ethernet physical, Wi-Fi | Bits |

## Further Reading

- [OSI Model - Wikipedia](https://en.wikipedia.org/wiki/OSI_model) - Comprehensive overview
- [RFC 1122](https://tools.ietf.org/html/rfc1122) - Requirements for Internet Hosts
- [Cisco Networking Academy](https://www.netacad.com/) - Structured networking courses
- [Network+](https://www.comptia.org/certifications/network) - CompTIA certification
- [TCP/IP Illustrated](https://en.wikipedia.org/wiki/TCP/IP_Illustrated) - W. Richard Stevens classic book series
- [Wireshark Documentation](https://www.wireshark.org/docs/) - Packet analysis tool
