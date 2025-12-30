---
title: "Network Diagram Standards"
description: "Standardized conventions for creating clear, consistent network diagrams using Mermaid"
tags: ["networking", "documentation", "diagrams", "mermaid", "standards"]
category: "networking"
difficulty: "beginner"
last_updated: "2025-12-30"
---

## Overview

Consistent network diagrams improve communication, troubleshooting, and documentation quality. This guide establishes standardized conventions for creating network diagrams using Mermaid syntax in our documentation.

## Mermaid Diagram Types

### Graph (Network Topology)

**Use for**: Physical and logical network layouts

```mermaid
graph TD
    Internet[Internet] --> Router[Core Router]
    Router --> Switch[Distribution Switch]
    Switch --> PC[Workstation]
```

### Sequence (Protocol Flows)

**Use for**: DHCP, DNS, authentication sequences

```mermaid
sequenceDiagram
    participant Client
    participant DHCP Server
    Client->>DHCP Server: DISCOVER
    DHCP Server->>Client: OFFER
    Client->>DHCP Server: REQUEST
    DHCP Server->>Client: ACK
```

### Flowchart (Troubleshooting)

**Use for**: Decision trees, troubleshooting guides

```mermaid
flowchart TD
    Start[No Internet?] --> Ping{Can ping 8.8.8.8?}
    Ping -->|Yes| DNS[DNS Issue]
    Ping -->|No| Gateway{Can ping gateway?}
    Gateway -->|Yes| ISP[ISP Problem]
    Gateway -->|No| Local[Local Network Issue]
```

## Color Scheme Standards

### Device Type Colors

Use `classDef` to define consistent colors for device categories:

```mermaid
graph TD
    Internet[Internet]:::internet
    Router[Router]:::infrastructure
    Switch[Switch]:::infrastructure
    Server[Server]:::server
    PC[Workstation]:::device
    Printer[Printer]:::device
    AP[WiFi AP]:::wireless
    
    classDef internet fill:#f9d5e5,stroke:#c83349,stroke-width:2px,color:#000
    classDef infrastructure fill:#5b9aa0,stroke:#2c5f66,stroke-width:2px,color:#fff
    classDef server fill:#c83349,stroke:#8b2332,stroke-width:2px,color:#fff
    classDef device fill:#d6e5fa,stroke:#5b9bd5,stroke-width:2px,color:#000
    classDef wireless fill:#e0aaaa,stroke:#b87777,stroke-width:2px,color:#000
```

**Result**:

```mermaid
graph TD
    Internet[Internet]:::internet
    Router[Router]:::infrastructure
    Switch[Switch]:::infrastructure
    Server[Server]:::server
    PC[Workstation]:::device
    Printer[Printer]:::device
    AP[WiFi AP]:::wireless
    
    classDef internet fill:#f9d5e5,stroke:#c83349,stroke-width:2px,color:#000
    classDef infrastructure fill:#5b9aa0,stroke:#2c5f66,stroke-width:2px,color:#fff
    classDef server fill:#c83349,stroke:#8b2332,stroke-width:2px,color:#fff
    classDef device fill:#d6e5fa,stroke:#5b9bd5,stroke-width:2px,color:#000
    classDef wireless fill:#e0aaaa,stroke:#b87777,stroke-width:2px,color:#000
```

### VLAN/Segment Colors

Use subgraphs with consistent colors for network segments:

```mermaid
graph TD
    subgraph Users [User VLAN 10]
        PC1[PC 1]
        PC2[PC 2]
    end
    
    subgraph Servers [Server VLAN 20]
        DB[(Database)]
        Web[Web Server]
    end
    
    Switch[Core Switch] --> Users
    Switch --> Servers
    
    style Users fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style Servers fill:#fff3e0,stroke:#f57c00,stroke-width:2px
```

**Result**:

```mermaid
graph TD
    subgraph Users [User VLAN 10]
        PC1[PC 1]
        PC2[PC 2]
    end
    
    subgraph Servers [Server VLAN 20]
        DB[(Database)]
        Web[Web Server]
    end
    
    Switch[Core Switch] --> Users
    Switch --> Servers
    
    style Users fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style Servers fill:#fff3e0,stroke:#f57c00,stroke-width:2px
```

### Standard Color Palette

| Category | Fill Color | Stroke Color | Text Color | Use Case |
| --- | --- | --- | --- | --- |
| **Internet/Cloud** | `#f9d5e5` | `#c83349` | `#000` | External connectivity |
| **Infrastructure** | `#5b9aa0` | `#2c5f66` | `#fff` | Routers, switches, firewalls |
| **Servers** | `#c83349` | `#8b2332` | `#fff` | File, web, database servers |
| **Devices** | `#d6e5fa` | `#5b9bd5` | `#000` | Workstations, laptops |
| **Wireless** | `#e0aaaa` | `#b87777` | `#000` | Access points, wireless controllers |
| **Printers/IoT** | `#d5e8d4` | `#82b366` | `#000` | Network printers, IoT devices |
| **Management** | `#fff2cc` | `#d6b656` | `#000` | Management interfaces, OOB |
| **User VLAN** | `#e3f2fd` | `#1976d2` | `#000` | User network segments |
| **Server VLAN** | `#fff3e0` | `#f57c00` | `#000` | Server network segments |
| **Guest VLAN** | `#f3e5f5` | `#8e24aa` | `#000` | Guest/isolated networks |

## Node Shape Standards

### Device Shapes

Use consistent shapes to represent device types:

```mermaid
graph LR
    Rectangle[Standard Device]
    Round(Network Device)
    Circle((Endpoint))
    DB[(Database)]
    Cloud{{Cloud Service}}
    Hex>Edge Device]
    
    style Rectangle fill:#d6e5fa,stroke:#5b9bd5
    style Round fill:#5b9aa0,stroke:#2c5f66,color:#fff
    style Circle fill:#e0aaaa,stroke:#b87777
    style DB fill:#c83349,stroke:#8b2332,color:#fff
    style Cloud fill:#f9d5e5,stroke:#c83349
    style Hex fill:#d5e8d4,stroke:#82b366
```

**Shape Guidelines**:

| Shape | Syntax | Device Type | Example |
| --- | --- | --- | --- |
| **Rectangle** | `Node[Label]` | Generic devices, workstations | `PC[Workstation]` |
| **Round** | `Node(Label)` | Network infrastructure | `Router(Core Router)` |
| **Circle** | `Node((Label))` | Wireless, endpoints | `AP((WiFi AP))` |
| **Cylinder** | `Node[(Label)]` | Databases, storage | `DB[(Database)]` |
| **Cloud** | `Node{{Label}}` | Internet, cloud services | `Internet{{Internet}}` |
| **Hexagon** | `Node>Label]` | Firewalls, edge devices | `FW>Firewall]` |
| **Diamond** | `Node{Label}` | Decision points | `Check{Condition?}` |

## Labeling Standards

### Device Labels

**Format**: `DeviceType<br/>Additional Info`

Use `<br/>` for multi-line labels with supplementary information:

```mermaid
graph TD
    Router[Core Router<br/>192.168.1.1<br/>Cisco 4331]
    Switch[Access Switch<br/>192.168.1.2<br/>24 ports PoE+]
    AP[WiFi AP<br/>192.168.1.10<br/>UniFi AC Pro]
    
    Router --> Switch
    Switch --> AP
    
    classDef infrastructure fill:#5b9aa0,stroke:#2c5f66,stroke-width:2px,color:#fff
    classDef wireless fill:#e0aaaa,stroke:#b87777,stroke-width:2px,color:#000
    
    class Router,Switch infrastructure
    class AP wireless
```

**Include**:
- Device name/type (first line)
- IP address (if relevant)
- Model or key specs

### Link Labels

Use link labels to show bandwidth, VLAN, or connection type:

```mermaid
graph TD
    Router[Core Router] -->|1 Gbps| Switch[Access Switch]
    Switch -->|VLAN 10| Users[User Devices]
    Switch -->|VLAN 20| Servers[Servers]
    
    classDef infrastructure fill:#5b9aa0,stroke:#2c5f66,stroke-width:2px,color:#fff
    classDef device fill:#d6e5fa,stroke:#5b9bd5,stroke-width:2px,color:#000
    
    class Router,Switch infrastructure
    class Users,Servers device
```

### Arrow Styles

Differentiate connection types:

```mermaid
graph LR
    A[Device A] -->|Physical| B[Device B]
    C[Device C] -.->|Wireless| D[Device D]
    E[Device E] ==>|Trunk/10G| F[Device F]
    G[Device G] ~~~ H[Device H]
    
    classDef device fill:#d6e5fa,stroke:#5b9bd5,stroke-width:2px,color:#000
    class A,B,C,D,E,F,G,H device
```

| Arrow Style | Syntax | Meaning |
| --- | --- | --- |
| **Solid** | `-->` | Physical wired connection |
| **Dotted** | `-.->` | Wireless or logical connection |
| **Thick** | `==>` | High-bandwidth link (10G+) or trunk |
| **No arrow** | `~~~` | Proximity/grouping (no connection) |

## Layout Guidelines

### Top-to-Bottom Flow

**Standard**: Internet/WAN at top, devices at bottom

```mermaid
graph TD
    Internet{{Internet}}:::internet
    Router[Edge Router]:::infrastructure
    Switch[Core Switch]:::infrastructure
    Devices[User Devices]:::device
    
    Internet --> Router
    Router --> Switch
    Switch --> Devices
    
    classDef internet fill:#f9d5e5,stroke:#c83349,stroke-width:2px,color:#000
    classDef infrastructure fill:#5b9aa0,stroke:#2c5f66,stroke-width:2px,color:#fff
    classDef device fill:#d6e5fa,stroke:#5b9bd5,stroke-width:2px,color:#000
```

### Left-to-Right Flow (Sequences)

**Standard**: Client on left, server on right

```mermaid
sequenceDiagram
    participant Client
    participant DNS Server
    Client->>DNS Server: Query example.com
    DNS Server->>Client: Response 93.184.216.34
```

### Hierarchical Layouts

Use subgraphs to group related components:

```mermaid
graph TD
    Internet{{Internet}}:::internet --> Router[Edge Router]:::infrastructure
    
    Router --> CoreSW[Core Switch]:::infrastructure
    
    subgraph Floor1 [First Floor]
        SW1[Switch 1]:::infrastructure
        AP1((WiFi AP 1)):::wireless
        PC1[Devices 1-20]:::device
        SW1 --> AP1
        SW1 --> PC1
    end
    
    subgraph Floor2 [Second Floor]
        SW2[Switch 2]:::infrastructure
        AP2((WiFi AP 2)):::wireless
        PC2[Devices 21-40]:::device
        SW2 --> AP2
        SW2 --> PC2
    end
    
    CoreSW --> Floor1
    CoreSW --> Floor2
    
    style Floor1 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style Floor2 fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    classDef internet fill:#f9d5e5,stroke:#c83349,stroke-width:2px,color:#000
    classDef infrastructure fill:#5b9aa0,stroke:#2c5f66,stroke-width:2px,color:#fff
    classDef wireless fill:#e0aaaa,stroke:#b87777,stroke-width:2px,color:#000
    classDef device fill:#d6e5fa,stroke:#5b9bd5,stroke-width:2px,color:#000
```

## Reusable Templates

### Basic Network Topology

```markdown
\`\`\`mermaid
graph TD
    Internet{{Internet}}:::internet
    Router[Edge Router<br/>192.168.1.1]:::infrastructure
    Switch[Core Switch<br/>192.168.1.2]:::infrastructure
    AP((WiFi AP<br/>192.168.1.10)):::wireless
    Server[File Server<br/>192.168.1.20]:::server
    PC[Workstations]:::device
    
    Internet --> Router
    Router --> Switch
    Switch --> AP
    Switch --> Server
    Switch --> PC
    
    classDef internet fill:#f9d5e5,stroke:#c83349,stroke-width:2px,color:#000
    classDef infrastructure fill:#5b9aa0,stroke:#2c5f66,stroke-width:2px,color:#fff
    classDef server fill:#c83349,stroke:#8b2332,stroke-width:2px,color:#fff
    classDef device fill:#d6e5fa,stroke:#5b9bd5,stroke-width:2px,color:#000
    classDef wireless fill:#e0aaaa,stroke:#b87777,stroke-width:2px,color:#000
\`\`\`
```

### VLAN Segmentation

```markdown
\`\`\`mermaid
graph TD
    Router[Core Router]:::infrastructure
    
    subgraph VLAN10 [VLAN 10 - Users<br/>192.168.10.0/24]
        PC1[Workstation 1]
        PC2[Workstation 2]
    end
    
    subgraph VLAN20 [VLAN 20 - Servers<br/>192.168.20.0/24]
        Web[Web Server]
        DB[(Database)]
    end
    
    subgraph VLAN30 [VLAN 30 - Guest<br/>192.168.30.0/24]
        Guest[Guest Devices]
    end
    
    Router --> VLAN10
    Router --> VLAN20
    Router --> VLAN30
    
    style VLAN10 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style VLAN20 fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style VLAN30 fill:#f3e5f5,stroke:#8e24aa,stroke-width:2px
    
    classDef infrastructure fill:#5b9aa0,stroke:#2c5f66,stroke-width:2px,color:#fff
    class Router infrastructure
\`\`\`
```

### DHCP Process Flow

```markdown
\`\`\`mermaid
sequenceDiagram
    participant Client
    participant DHCP Server
    
    Note over Client: No IP Address
    Client->>DHCP Server: DHCPDISCOVER (broadcast)
    DHCP Server->>Client: DHCPOFFER (192.168.1.100)
    Client->>DHCP Server: DHCPREQUEST (192.168.1.100)
    DHCP Server->>Client: DHCPACK
    Note over Client: IP: 192.168.1.100<br/>Gateway: 192.168.1.1<br/>DNS: 8.8.8.8
\`\`\`
```

### Troubleshooting Decision Tree

```markdown
\`\`\`mermaid
flowchart TD
    Start[No Internet Connection?] --> Local{Can access local resources?}
    Local -->|Yes| Gateway{Can ping gateway?}
    Local -->|No| Cable[Check cable/WiFi]
    
    Gateway -->|Yes| DNS{Can ping 8.8.8.8?}
    Gateway -->|No| RouterIssue[Router problem]
    
    DNS -->|Yes| DNSIssue[DNS issue - check settings]
    DNS -->|No| ISPIssue[ISP/WAN problem]
    
    style Start fill:#c83349,stroke:#8b2332,stroke-width:2px,color:#fff
    style DNSIssue fill:#d5e8d4,stroke:#82b366,stroke-width:2px
    style ISPIssue fill:#f9d5e5,stroke:#c83349,stroke-width:2px
    style RouterIssue fill:#fff2cc,stroke:#d6b656,stroke-width:2px
\`\`\`
```

## Best Practices

### Diagram Simplicity

**DO**:
- Group similar devices: `Users[10 Workstations]` instead of 10 individual nodes
- Use subgraphs for logical grouping (floors, VLANs, sites)
- Limit diagrams to one logical concept (physical topology OR VLAN design, not both)

**DON'T**:
- Overload with every device (show representative samples)
- Mix abstraction levels (don't show cables on a logical VLAN diagram)
- Use more than 15-20 nodes per diagram

### Consistency

- **Always** define color classes when using device categories
- **Always** include IP addresses for infrastructure devices
- **Always** label bandwidth on key links (1 Gbps, 10 Gbps)
- **Always** use the same color/shape for the same device type across all diagrams

### Accessibility

- **Use high-contrast colors** (avoid pastels on white backgrounds)
- **Include text labels** (don't rely solely on color)
- **Test diagrams in dark mode** (if documentation supports it)

### Documentation Integration

**In each diagram, include**:
- **Title**: "Network Topology - Branch Office"
- **Legend** (if using custom symbols):
  ```
  Legend:
  - Blue = Infrastructure
  - Red = Servers
  - Light Blue = User Devices
  - Pink = Wireless
  ```
- **Date/Version**: Last updated information in YAML frontmatter

## Common Patterns

### Site-to-Site VPN

```mermaid
graph LR
    subgraph Site A
        RouterA[Router A<br/>192.168.1.1]:::infrastructure
        SwitchA[Switch A]:::infrastructure
        UsersA[Users A]:::device
        RouterA --> SwitchA
        SwitchA --> UsersA
    end
    
    subgraph Site B
        RouterB[Router B<br/>192.168.2.1]:::infrastructure
        SwitchB[Switch B]:::infrastructure
        UsersB[Users B]:::device
        RouterB --> SwitchB
        SwitchB --> UsersB
    end
    
    RouterA -.->|VPN Tunnel<br/>Encrypted| RouterB
    
    Internet{{Internet}}:::internet
    RouterA --> Internet
    Internet --> RouterB
    
    style Site A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style Site B fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    classDef internet fill:#f9d5e5,stroke:#c83349,stroke-width:2px,color:#000
    classDef infrastructure fill:#5b9aa0,stroke:#2c5f66,stroke-width:2px,color:#fff
    classDef device fill:#d6e5fa,stroke:#5b9bd5,stroke-width:2px,color:#000
```

### Redundant Core

```mermaid
graph TD
    Internet1{{Internet ISP 1}}:::internet
    Internet2{{Internet ISP 2}}:::internet
    
    Router1[Core Router 1]:::infrastructure
    Router2[Core Router 2]:::infrastructure
    
    Internet1 --> Router1
    Internet2 --> Router2
    Router1 -.->|VRRP/HSRP| Router2
    
    Switch1[Distribution Switch 1]:::infrastructure
    Switch2[Distribution Switch 2]:::infrastructure
    
    Router1 ==> Switch1
    Router1 ==> Switch2
    Router2 ==> Switch1
    Router2 ==> Switch2
    
    Access1[Access Switch 1]:::infrastructure
    Access2[Access Switch 2]:::infrastructure
    
    Switch1 --> Access1
    Switch1 --> Access2
    Switch2 --> Access1
    Switch2 --> Access2
    
    classDef internet fill:#f9d5e5,stroke:#c83349,stroke-width:2px,color:#000
    classDef infrastructure fill:#5b9aa0,stroke:#2c5f66,stroke-width:2px,color:#fff
```

## Review Checklist

Before publishing a diagram:

- ☐ All devices have clear labels
- ☐ IP addresses included for infrastructure
- ☐ Color scheme applied consistently
- ☐ Links labeled with bandwidth/VLAN where relevant
- ☐ Diagram follows left-to-right or top-to-bottom flow
- ☐ No more than 20 nodes (or grouped appropriately)
- ☐ Legend included if using custom symbols/colors
- ☐ Mermaid syntax validated (renders correctly)
- ☐ Alternative text provided for accessibility

## Related Topics

- [Network Fundamentals](fundamentals.md) - Understanding network components
- [Architecture](architecture.md) - Network design principles
- [Scenarios](scenarios/index.md) - Real-world topology examples
- [Troubleshooting](troubleshooting.md) - Using diagrams for diagnosis

## Tools and Resources

- **Mermaid Live Editor**: [mermaid.live](https://mermaid.live) - Test diagrams before adding to docs
- **Mermaid Documentation**: [mermaid.js.org](https://mermaid.js.org) - Full syntax reference
- **Color Picker**: Use ColorBrewer or similar for accessible color schemes

---

*Standardized diagrams reduce confusion, improve collaboration, and make network documentation more professional and maintainable.*
