# Infrastructure

This section covers infrastructure topics such as virtualization, containers, and operating systems.

## Cloud Infrastructure Architecture

Modern infrastructure typically follows patterns of high availability, security, and scalability. Below are visualizations of common cloud infrastructure architectures.

### Basic Cloud Infrastructure

The following diagram illustrates a basic three-tier web application hosted in the cloud:

```mermaid
flowchart TB
    subgraph Internet
        client[Client Devices]
    end

    subgraph Cloud Provider
        subgraph "Public Subnet"
            lb[Load Balancer]
            waf[Web Application Firewall]
        end
        
        subgraph "Private Subnet"
            web1[Web Server 1]
            web2[Web Server 2]
            web3[Web Server 3]
        end
        
        subgraph "Database Subnet"
            db[(Database)]
            cache[(Cache)]
        end
    end
    
    client --> lb
    lb --> waf
    waf --> web1
    waf --> web2
    waf --> web3
    web1 --> db
    web2 --> db
    web3 --> db
    web1 --> cache
    web2 --> cache
    web3 --> cache
    
    classDef public fill:#ffcccc,stroke:#ff0000
    classDef private fill:#ccffcc,stroke:#00cc00
    classDef database fill:#ccccff,stroke:#0000ff
    
    class lb,waf public
    class web1,web2,web3 private
    class db,cache database
```

### High Availability Architecture

For critical applications, a multi-availability zone architecture ensures high availability:

```mermaid
flowchart TB
    subgraph Internet
        client[Client Devices]
        cdn[Content Delivery Network]
    end

    subgraph "Cloud Region"
        subgraph "Availability Zone 1"
            subgraph "Public Subnet AZ1"
                lb1[Load Balancer]
                waf1[WAF]
            end
            
            subgraph "Private Subnet AZ1"
                web1[Web Server]
                app1[App Server]
            end
            
            subgraph "Data Subnet AZ1"
                db1[(Primary DB)]
                cache1[(Cache)]
            end
        end
        
        subgraph "Availability Zone 2"
            subgraph "Public Subnet AZ2"
                lb2[Load Balancer]
                waf2[WAF]
            end
            
            subgraph "Private Subnet AZ2"
                web2[Web Server]
                app2[App Server]
            end
            
            subgraph "Data Subnet AZ2"
                db2[(Replica DB)]
                cache2[(Cache)]
            end
        end
        
        glb[Global Load Balancer]
    end
    
    client --> cdn
    cdn --> glb
    glb --> lb1
    glb --> lb2
    lb1 --> waf1
    lb2 --> waf2
    waf1 --> web1
    waf2 --> web2
    web1 --> app1
    web2 --> app2
    app1 --> db1
    app2 --> db1
    app1 --> cache1
    app2 --> cache2
    db1 <--> db2
    
    classDef public fill:#ffcccc,stroke:#ff0000
    classDef private fill:#ccffcc,stroke:#00cc00
    classDef database fill:#ccccff,stroke:#0000ff
    classDef global fill:#ffffcc,stroke:#ffcc00
    
    class lb1,lb2,waf1,waf2 public
    class web1,web2,app1,app2 private
    class db1,db2,cache1,cache2 database
    class cdn,glb global
```

## Topics

- [Containers](containers/index.md) - Docker and Kubernetes
- [Home Lab](homelab/index.md) - Home lab notes
- [Proxmox](proxmox/index.md) - Managing Proxmox for a home lab environment

## Getting Started

### Prerequisites

Before diving into infrastructure management, ensure you have the following:

1. **Basic Knowledge Requirements**:
   - Familiarity with command-line interfaces
   - Understanding of networking concepts (IP addressing, subnets, DNS)
   - Basic virtualization concepts

2. **Hardware for Home Lab** (if applicable):
   - Server or high-performance PC (8+ CPU cores recommended)
   - 32GB+ RAM for multiple VMs/containers
   - SSD storage (500GB+ recommended)
   - Stable network connection

3. **Software Tools**:
   - SSH client for remote management
   - Git for version control
   - Terminal emulator

### First Steps

#### 1. Choose Your Infrastructure Path

- **Containers**: Start with [Docker](containers/docker/index.md) for single-host container deployment
- **Virtualization**: Begin with [Proxmox](proxmox/index.md) for a comprehensive virtualization platform
- **Home Lab**: Follow the [Home Lab](homelab/index.md) guide for a complete lab setup

#### 2. Setup Your Environment

For containerization with Docker:

```bash
# Install Docker on Ubuntu/Debian
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker

# Verify installation
docker --version
```

For Proxmox virtualization:

```bash
# Download Proxmox VE ISO and create bootable USB
# Then follow installation steps in the Proxmox guide
```

### Common Tasks

#### Managing Containers

```bash
# Run a container
docker run -d --name nginx -p 80:80 nginx

# List running containers
docker ps

# Stop a container
docker stop nginx
```

#### Managing Virtual Machines in Proxmox

1. Access the Proxmox web interface (`https://your-proxmox-ip:8006`)
2. Navigate to the Create VM button
3. Follow the wizard to set up resources and install an OS
4. See detailed instructions in the [Proxmox guide](proxmox/index.md)

### Next Steps

- Learn about [container orchestration with Kubernetes](containers/kubernetes/index.md)
- Explore [infrastructure as code](containers/terraform/index.md) with Terraform
- Set up a [complete home lab environment](homelab/index.md) with multiple services
