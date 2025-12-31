---
title: "Networking Glossary"
description: "Comprehensive reference of networking terms, acronyms, and definitions"
tags: ["networking", "glossary", "reference", "terminology"]
category: "networking"
difficulty: "all-levels"
last_updated: "2025-12-30"
---

## A

**Access Control List (ACL)**: Rules that permit or deny network traffic based on source/destination IP, port, or protocol. Used in firewalls and routers for security.

**Access Point (AP)**: Wireless network device that allows WiFi-enabled devices to connect to a wired network.

**Active Directory (AD)**: Microsoft's directory service for Windows domain networks, providing centralized authentication and management.

**Address Resolution Protocol (ARP)**: Protocol that maps IP addresses to MAC (hardware) addresses on a local network.

**Administrative Distance (AD)**: Trustworthiness rating of routing protocol sources (0-255, lower is better). Static routes = 1, OSPF = 110, RIP = 120.

**Anycast**: Routing method where multiple servers share same IP address; client connects to nearest/best one. Used by DNS root servers, CDNs.

**Application Layer**: Layer 7 of the OSI model; handles protocols like HTTP, FTP, SMTP, DNS directly used by applications.

**ARP Spoofing**: Attack where attacker sends fake ARP messages to link their MAC address to another host's IP address, enabling man-in-the-middle attacks.

**Autonomous System (AS)**: Collection of IP networks under single administrative control, using unified routing policy. Identified by AS Number (ASN).

**Availability**: Network reliability measurement; percentage of time systems are operational. "Five nines" (99.999%) = ~5 minutes downtime per year.

## B

**Backbone**: High-capacity network connections that carry bulk of traffic between different network segments or regions.

**Bandwidth**: Maximum rate of data transfer across a network path, measured in bits per second (bps, Mbps, Gbps).

**BGP (Border Gateway Protocol)**: Path-vector routing protocol used to exchange routing information between autonomous systems on the internet.

**Bit**: Smallest unit of data in computing (0 or 1). 8 bits = 1 byte.

**Broadcast**: Transmission sent to all devices on a network segment (destination: 255.255.255.255 or FF:FF:FF:FF:FF:FF).

**Broadcast Domain**: Network segment where broadcast packets can reach. Routers separate broadcast domains; switches don't.

**Byte**: 8 bits of data. Common measurement for file sizes and data transfer.

## C

**Cable Categories**: Standards for twisted-pair Ethernet cables:

- **Cat5e**: Up to 1 Gbps, 100 meters
- **Cat6**: Up to 10 Gbps (55m), 100 meters for 1 Gbps
- **Cat6a**: Up to 10 Gbps, 100 meters
- **Cat7/Cat8**: Data center use, shorter distances, higher speeds

**Carrier Sense Multiple Access with Collision Detection (CSMA/CD)**: Ethernet method where devices listen before transmitting and detect collisions. Obsolete with modern switches.

**CIDR (Classless Inter-Domain Routing)**: IP addressing method using variable-length subnet masks (e.g., 192.168.1.0/24 instead of Class C).

**Client**: Device or software that requests services from a server.

**Collision Domain**: Network segment where collisions can occur. Switches create separate collision domain for each port; hubs don't.

**Core Layer**: Top tier of three-tier network architecture; high-speed backbone providing fast transport between distribution layer devices.

**CRC (Cyclic Redundancy Check)**: Error-detection code used in Ethernet frames to detect transmission errors.

## D

**Data Link Layer**: Layer 2 of OSI model; handles MAC addresses, frames, and physical transmission between adjacent nodes (switches operate here).

**Default Gateway**: Router IP address that devices use to send traffic to destinations outside their local subnet.

**DHCP (Dynamic Host Configuration Protocol)**: Automatically assigns IP addresses and network configuration to devices. See [DHCP Guide](dhcp.md).

**DHCP Lease**: Time period that IP address is assigned to device before requiring renewal (typically 8-24 hours).

**DHCP Relay**: Forwards DHCP broadcasts from clients to DHCP servers on different subnets (also called IP Helper).

**DHCP Scope**: Range of IP addresses available for DHCP assignment to clients.

**DMZ (Demilitarized Zone)**: Network segment isolated from both internal network and internet, hosting public-facing servers.

**DNS (Domain Name System)**: Translates domain names (google.com) to IP addresses (142.250.80.46). See [DNS Guide](dns.md).

**DORA**: DHCP process - Discover, Offer, Request, Acknowledge.

**DoS (Denial of Service)**: Attack that makes network resource unavailable by overwhelming it with traffic.

**DDoS (Distributed Denial of Service)**: DoS attack from multiple sources simultaneously, harder to mitigate.

**Duplex**: Communication mode:

- **Simplex**: One-way only (TV broadcast)
- **Half-Duplex**: Two-way but not simultaneous (walkie-talkie)
- **Full-Duplex**: Simultaneous two-way (telephone, modern Ethernet)

## E

**EAP (Extensible Authentication Protocol)**: Authentication framework used in wireless networks (WPA2/WPA3-Enterprise) and point-to-point connections.

**EIGRP (Enhanced Interior Gateway Routing Protocol)**: Cisco's advanced distance-vector routing protocol with fast convergence.

**Encapsulation**: Process of wrapping data with protocol headers at each OSI layer as it traverses the network stack.

**Encryption**: Converting data into coded format to prevent unauthorized access. Common types: AES, 3DES, RSA.

**Ethernet**: Most common LAN technology standard (IEEE 802.3), using twisted-pair or fiber cables with CSMA/CD.

**EtherType**: Field in Ethernet frame identifying which protocol is encapsulated (e.g., 0x0800 = IPv4, 0x86DD = IPv6).

## F

**Failover**: Automatic switching to redundant system when primary fails, ensuring continuous availability.

**Fiber Optic**: Cable using light pulses through glass/plastic fibers for high-speed, long-distance transmission. Types: single-mode (long), multi-mode (short).

**Firewall**: Security device that filters network traffic based on rules, blocking unauthorized access. See [Firewall Guide](firewalls.md).

**Frame**: Data unit at Layer 2 (Data Link), containing MAC addresses, payload, and error checking (CRC).

**FTP (File Transfer Protocol)**: Protocol for transferring files between computers (port 21 control, 20 data).

**FQDN (Fully Qualified Domain Name)**: Complete domain name including host and domain (<www.example.com>).

## G

**Gateway**: Device that connects two different networks, often with different protocols (commonly refers to default gateway/router).

**Gbps (Gigabits per second)**: Data transfer rate of 1 billion bits per second.

**Gigabit Ethernet**: Ethernet standard supporting 1 Gbps (1000BASE-T for copper, 1000BASE-X for fiber).

**GRE (Generic Routing Encapsulation)**: Tunneling protocol that encapsulates network layer protocols inside IP tunnels.

## H

**Handshake**: Process of establishing connection and negotiating parameters (e.g., TCP three-way handshake: SYN, SYN-ACK, ACK).

**Hop**: Each router or Layer 3 device a packet passes through between source and destination.

**Hop Count**: Number of routers packet must traverse; used as metric by RIP.

**Host**: Any device with IP address on network (computer, server, printer, phone, etc.).

**HTTP (HyperText Transfer Protocol)**: Protocol for web page transfer (port 80).

**HTTPS (HTTP Secure)**: Encrypted version of HTTP using TLS/SSL (port 443).

**Hub**: Legacy network device that broadcasts data to all connected ports (single collision domain). Replaced by switches.

## I

**ICMP (Internet Control Message Protocol)**: Protocol for diagnostic and error messages (used by ping and traceroute).

**IDS (Intrusion Detection System)**: Monitors network traffic for suspicious activity and alerts administrators.

**IEEE (Institute of Electrical and Electronics Engineers)**: Organization that develops networking standards (802.3 Ethernet, 802.11 WiFi).

**IGP (Interior Gateway Protocol)**: Routing protocol used within autonomous system (OSPF, EIGRP, RIP, IS-IS).

**Internet**: Global network of interconnected computer networks using TCP/IP protocols.

**Intranet**: Private network using internet protocols, accessible only within organization.

**IoT (Internet of Things)**: Network-connected devices (smart home, sensors, cameras, appliances).

**IP (Internet Protocol)**: Network layer protocol for addressing and routing packets (IPv4, IPv6).

**IP Address**: Numerical identifier assigned to device on IP network (e.g., 192.168.1.100 for IPv4, 2001:db8::1 for IPv6).

**IPsec (Internet Protocol Security)**: Protocol suite for securing IP communications through authentication and encryption, commonly used in VPNs.

**IPv4**: Internet Protocol version 4, using 32-bit addresses (e.g., 192.168.1.1), supporting ~4.3 billion addresses.

**IPv6**: Internet Protocol version 6, using 128-bit addresses (e.g., 2001:0db8:85a3::8a2e:0370:7334), supporting 340 undecillion addresses.

**ISP (Internet Service Provider)**: Company providing internet access to customers.

## J

**Jitter**: Variation in packet arrival times, critical for real-time applications like VoIP and video conferencing.

**Jumbo Frames**: Ethernet frames larger than standard 1500-byte MTU (typically 9000 bytes), used in data centers for efficiency.

## K

**Kerberos**: Network authentication protocol using secret-key cryptography, used in Active Directory and enterprise systems.

**Kilo (K)**: Prefix meaning 1,000 (in networking, 1 Kbps = 1,000 bits per second).

## L

**LAN (Local Area Network)**: Network within limited area (home, office, building), typically high-speed with low latency.

**Latency**: Time delay between data transmission and reception, measured in milliseconds (ms).

**Layer 2 Switch**: Operates at Data Link layer, forwarding frames based on MAC addresses.

**Layer 3 Switch**: Can perform routing functions in addition to switching, using IP addresses.

**LDAP (Lightweight Directory Access Protocol)**: Protocol for accessing and maintaining directory services (commonly used with Active Directory).

**Lease**: Duration that DHCP assigns IP address to client before renewal required.

**Link Aggregation**: Combining multiple network connections into single logical link for increased bandwidth and redundancy (also called bonding, teaming, LAG).

**Load Balancer**: Device distributing network traffic across multiple servers to optimize resource use and reliability.

**Localhost**: Loopback address referring to local computer (127.0.0.1 for IPv4, ::1 for IPv6).

**Loopback**: Virtual interface on device that always refers back to itself, used for testing.

## M

**MAC Address (Media Access Control)**: Unique 48-bit hardware identifier assigned to network interface (e.g., aa:bb:cc:dd:ee:ff). First 24 bits identify manufacturer.

**MAC Table**: Switch database mapping MAC addresses to physical ports.

**MAN (Metropolitan Area Network)**: Network covering city or metropolitan area, larger than LAN but smaller than WAN.

**Mbps (Megabits per second)**: Data transfer rate of 1 million bits per second.

**MDI/MDI-X**: Ethernet wiring configurations. Modern equipment auto-detects, eliminating need for crossover cables.

**Metric**: Value used by routing protocols to determine best path (hop count, bandwidth, delay, etc.).

**MIMO (Multiple Input Multiple Output)**: Wireless technology using multiple antennas to improve performance.

**Modem**: Device that modulates/demodulates signals for transmission over cable, DSL, or fiber lines to ISP.

**MTU (Maximum Transmission Unit)**: Largest packet size that can be transmitted without fragmentation (typically 1500 bytes for Ethernet).

**Multicast**: Transmission from one sender to specific group of receivers (destination: 224.0.0.0 - 239.255.255.255).

**Multiplexing**: Combining multiple signals into one for transmission over single medium.

**MX Record**: DNS Mail Exchange record specifying mail servers for domain.

## N

**NAT (Network Address Translation)**: Translates private IP addresses to public IP for internet access, conserving public IPs.

**NetBIOS**: Legacy Microsoft protocol for LAN name resolution and file sharing (gradually replaced by DNS/SMB).

**Network**: Collection of interconnected devices able to communicate and share resources.

**Network Layer**: Layer 3 of OSI model; handles IP addressing and routing (routers operate here).

**Next-Hop**: IP address of next router in path to destination.

**NIC (Network Interface Card)**: Hardware component that connects computer to network, has unique MAC address.

**NTP (Network Time Protocol)**: Protocol for synchronizing system clocks over network (port 123 UDP).

## O

**OFDM (Orthogonal Frequency-Division Multiplexing)**: Modulation technique used in WiFi for efficient spectrum use.

**OSI Model (Open Systems Interconnection)**: Seven-layer conceptual framework for understanding network communications. See [OSI Model Guide](osi-model.md).

**OSPF (Open Shortest Path First)**: Link-state IGP routing protocol, widely used in enterprise networks. See [Routing Guide](routing.md).

**OUI (Organizationally Unique Identifier)**: First 24 bits of MAC address identifying manufacturer.

## P

**Packet**: Data unit at Layer 3 (Network), containing source/destination IP addresses and payload.

**PAT (Port Address Translation)**: Type of NAT mapping multiple private IPs to single public IP using different ports.

**PDU (Protocol Data Unit)**: Data unit at specific layer (Frame at L2, Packet at L3, Segment at L4, Data at L7).

**Physical Layer**: Layer 1 of OSI model; handles electrical signals, cables, connectors (hubs, repeaters, cables operate here).

**Ping**: Diagnostic tool using ICMP to test connectivity and measure round-trip time.

**PoE (Power over Ethernet)**: Technology delivering electrical power over Ethernet cables (standards: 802.3af = 15.4W, 802.3at = 25.5W, 802.3bt = 51-73W).

**Port**: Logical endpoint for network communication. Physical port: connector on device. Logical port: number identifying service (HTTP=80, HTTPS=443, SSH=22).

**Port Forwarding**: NAT feature redirecting traffic from external port to internal IP/port, allowing internet access to internal servers.

**Port Security**: Switch feature limiting devices on port by MAC address, preventing unauthorized connections.

**Presentation Layer**: Layer 6 of OSI model; handles data formatting, encryption, compression.

**Private IP Addresses**: Reserved address ranges for local networks (not routable on internet):

- **10.0.0.0/8** (10.0.0.0 - 10.255.255.255)
- **172.16.0.0/12** (172.16.0.0 - 172.31.255.255)
- **192.168.0.0/16** (192.168.0.0 - 192.168.255.255)

**Protocol**: Set of rules governing network communication (TCP, UDP, IP, HTTP, etc.).

**Proxy**: Intermediary server between clients and destination servers, used for caching, filtering, anonymity.

**Public IP Address**: Globally unique IP address routable on the internet (assigned by ISPs, obtained from IANA).

## Q

**QoS (Quality of Service)**: Prioritizing certain traffic types (voice, video) over others (downloads, backups) for consistent performance.

**Queue**: Buffer holding packets awaiting transmission or processing.

## R

**RADIUS (Remote Authentication Dial-In User Service)**: Protocol for centralized authentication, authorization, and accounting. Used in WPA2/WPA3-Enterprise.

**RARP (Reverse Address Resolution Protocol)**: Maps MAC address to IP address (reverse of ARP). Largely obsolete (replaced by DHCP).

**RDP (Remote Desktop Protocol)**: Microsoft protocol for remote graphical access to Windows systems (port 3389).

**Redundancy**: Having backup systems/paths to maintain service during failures.

**RIP (Routing Information Protocol)**: Distance-vector IGP using hop count as metric (max 15 hops). Legacy protocol. See [Routing Guide](routing.md).

**RJ45**: Standard 8-pin modular connector used for Ethernet cables.

**Roaming**: Wireless client transitioning between access points while maintaining connection.

**Rogue Access Point**: Unauthorized wireless AP on network, creating security vulnerability.

**Round-Robin**: Load balancing method distributing requests sequentially across servers.

**Route Summarization**: Combining multiple routes into single advertisement to reduce routing table size.

**Router**: Layer 3 device that forwards packets between different networks using IP addresses.

**Routing**: Process of selecting paths for network traffic from source to destination across networks.

**Routing Protocol**: Protocol that automatically discovers routes and builds routing tables (OSPF, EIGRP, BGP, RIP).

**Routing Table**: Database in router listing networks, next-hops, and metrics for forwarding decisions.

**RSSI (Received Signal Strength Indicator)**: Measurement of wireless signal strength (typically -30 to -90 dBm).

**RTT (Round-Trip Time)**: Time for packet to travel from source to destination and back, measured by ping.

## S

**Segment**: Data unit at Layer 4 (Transport); TCP segment or UDP datagram.

**Server**: Computer or software providing services to clients (web server, file server, DHCP server).

**Session Layer**: Layer 5 of OSI model; manages sessions/connections between applications.

**SFTP (SSH File Transfer Protocol)**: Secure file transfer protocol using SSH encryption (port 22).

**SIEM (Security Information and Event Management)**: Centralized logging and analysis platform for security monitoring.

**SMTP (Simple Mail Transfer Protocol)**: Protocol for sending email (port 25, 587).

**SNMP (Simple Network Management Protocol)**: Protocol for monitoring and managing network devices (port 161 for queries, 162 for traps).

**Socket**: Combination of IP address and port number (e.g., 192.168.1.10:80).

**Spanning Tree Protocol (STP)**: Prevents loops in switched networks by blocking redundant paths (IEEE 802.1D).

**SSID (Service Set Identifier)**: WiFi network name broadcast by access points.

**SSH (Secure Shell)**: Encrypted protocol for remote command-line access (port 22), replacing insecure Telnet.

**SSL (Secure Sockets Layer)**: Deprecated encryption protocol (replaced by TLS). Term still commonly used.

**Subnet**: Division of larger IP network into smaller logical networks.

**Subnet Mask**: 32-bit number defining which portion of IP address is network vs. host (e.g., 255.255.255.0 or /24).

**Subnetting**: Dividing network into smaller subnetworks for better management and efficiency.

**Switch**: Layer 2 device that forwards frames based on MAC addresses, creating separate collision domain per port.

**SYN Flood**: DoS attack exploiting TCP handshake by sending many SYN packets without completing connection.

## T

**TCP (Transmission Control Protocol)**: Connection-oriented, reliable Layer 4 protocol ensuring ordered delivery (used by HTTP, FTP, SSH).

**TCP/IP**: Suite of protocols forming foundation of internet (TCP, IP, UDP, ICMP, etc.).

**Telnet**: Insecure protocol for remote command-line access (port 23). Replaced by SSH.

**TFTP (Trivial File Transfer Protocol)**: Simple file transfer protocol without authentication (port 69 UDP), used for network device firmware.

**Three-Way Handshake**: TCP connection establishment process (SYN → SYN-ACK → ACK).

**Throughput**: Actual data transfer rate achieved (lower than bandwidth due to overhead).

**TLS (Transport Layer Security)**: Cryptographic protocol for secure communication over networks, successor to SSL (HTTPS uses TLS).

**Topology**: Physical or logical layout of network devices and connections (star, mesh, ring, bus).

**Traceroute**: Diagnostic tool showing path packets take through network (traceroute on Linux/Mac, tracert on Windows).

**Transport Layer**: Layer 4 of OSI model; handles end-to-end communication (TCP, UDP).

**Trunk**: Switch port carrying traffic for multiple VLANs using 802.1Q tagging.

**TTL (Time To Live)**: Field in IP packet limiting lifetime (decremented at each hop, packet dropped at 0). Also: DNS record caching duration.

## U

**UDP (User Datagram Protocol)**: Connectionless, unreliable Layer 4 protocol for speed over reliability (used by DNS, DHCP, streaming).

**Unicast**: Transmission from one sender to one specific receiver (most common traffic type).

**Uplink**: Connection from lower-level device to higher-level (switch to router, branch to HQ, local to internet).

**URL (Uniform Resource Locator)**: Web address (e.g., <https://www.example.com/page>).

**UTM (Unified Threat Management)**: All-in-one security appliance combining firewall, VPN, IDS/IPS, antivirus, content filtering.

## V

**Virtual IP (VIP)**: IP address not tied to specific physical device, used for load balancing or high availability (VRRP, HSRP).

**VLAN (Virtual Local Area Network)**: Logical network segmentation within physical network, separating broadcast domains. See [VLAN Guide](vlans.md).

**VLAN Tagging**: Adding 802.1Q header to Ethernet frames to identify VLAN membership.

**VoIP (Voice over IP)**: Technology for voice calls over IP networks instead of traditional phone lines.

**VPN (Virtual Private Network)**: Encrypted tunnel over internet allowing secure remote access to private network.

**VRRP (Virtual Router Redundancy Protocol)**: Protocol providing automatic gateway failover for high availability.

## W

**WAN (Wide Area Network)**: Network spanning large geographic area, connecting multiple LANs (typically slower than LAN).

**WAP (Wireless Access Point)**: See Access Point.

**WEP (Wired Equivalent Privacy)**: Obsolete WiFi security protocol, easily broken. Never use.

**WiFi**: Wireless networking technology based on IEEE 802.11 standards. See [Wireless Guide](wireless.md).

**WiFi 6 (802.11ax)**: Latest WiFi standard offering improved speed, capacity, and efficiency.

**WINS (Windows Internet Name Service)**: Legacy Microsoft service for NetBIOS name resolution (replaced by DNS).

**Wireshark**: Popular open-source packet analyzer for network troubleshooting and analysis.

**WLAN (Wireless Local Area Network)**: Wireless network using WiFi technology.

**WPA (WiFi Protected Access)**: Wireless security protocol, replaced WEP. Versions: WPA, WPA2, WPA3 (current standard).

**WPA2**: WiFi security standard using AES encryption, minimum acceptable security for wireless networks.

**WPA3**: Latest WiFi security standard with improved encryption and protection against brute-force attacks.

## X

**x.509**: Standard format for public key certificates used in TLS/SSL and other security protocols.

## Y

**Yottabyte (YB)**: 1,000,000,000,000,000,000,000,000 bytes (1 septillion bytes). Largest data unit.

## Z

**Zero-Day**: Security vulnerability unknown to vendor, with no patch available.

**Zero Trust**: Security model assuming no implicit trust, requiring verification for every access request.

**Zeroconf (Zero Configuration Networking)**: Technologies enabling automatic network configuration without manual setup or DHCP (includes Bonjour, mDNS).

**Zone File**: DNS configuration file containing resource records for domain.

**Zone Transfer**: Replication of DNS zone data from primary to secondary nameserver.

---

## Related Topics

- [Network Fundamentals](fundamentals.md) - Core networking concepts
- [OSI Model](osi-model.md) - Seven-layer reference model
- [DNS Guide](dns.md) - Domain Name System details
- [DHCP Guide](dhcp.md) - Dynamic IP addressing
- [Routing Protocols](routing.md) - OSPF, EIGRP, BGP
- [VLANs](vlans.md) - Virtual network segmentation
- [Wireless Networking](wireless.md) - WiFi concepts and implementation
- [Firewalls](firewalls.md) - Security and filtering

## Contributing

This glossary is continuously updated. For corrections or additions, please refer to the documentation contribution guidelines.

---

*This glossary provides quick reference for networking terminology. For detailed explanations, see the linked comprehensive guides.*
