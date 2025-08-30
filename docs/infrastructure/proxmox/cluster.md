---
title: "Proxmox VE Cluster Management"
description: "Complete guide to creating, configuring, and managing Proxmox VE clusters for high availability and scalability"
author: "josephstreeter"
ms.date: "2025-08-29"
ms.topic: "how-to-guide"
ms.service: "proxmox"
keywords: ["Proxmox", "Cluster", "High Availability", "HA", "Corosync", "Quorum", "Migration", "Fencing"]
---

## Proxmox VE Cluster Management

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Planning Your Cluster](#planning-your-cluster)
- [Creating a Cluster](#creating-a-cluster)
- [Adding Nodes to Cluster](#adding-nodes-to-cluster)
- [Network Configuration](#network-configuration)
- [Storage Configuration](#storage-configuration)
- [High Availability Setup](#high-availability-setup)
- [Live Migration](#live-migration)
- [Backup Strategies](#backup-strategies)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Overview

A Proxmox VE cluster is a group of physical servers that work together to provide high availability, load distribution, and centralized management of virtual machines and containers. Clustering enables:

- **High Availability (HA)**: Automatic failover of VMs/containers
- **Live Migration**: Move running VMs between nodes without downtime
- **Centralized Management**: Single web interface for all nodes
- **Shared Storage**: Access to common storage pools
- **Load Distribution**: Balanced resource utilization across nodes

### Cluster Architecture

Proxmox VE clusters use:

- **Corosync**: Cluster communication and membership
- **Quorum**: Prevents split-brain scenarios
- **pmxcfs**: Proxmox cluster file system for configuration
- **Fencing**: Ensures data integrity during failures

---

## Prerequisites

### Hardware Requirements

**Minimum Configuration:**

- 3 physical servers (for proper quorum)
- 8GB RAM per node (16GB+ recommended)
- 100GB+ storage per node
- Gigabit Ethernet (10GbE recommended for production)

**Recommended Configuration:**

- 3-16 nodes (practical limit)
- 32GB+ RAM per node
- SSD storage for better performance
- Redundant network connections
- UPS for power protection

### Network Requirements

- **Dedicated cluster network**: Separate from management/VM traffic
- **Low latency**: <5ms between nodes
- **Reliable connectivity**: Redundant network paths recommended
- **Multicast support**: Required for corosync communication

### Software Requirements

- All nodes must run the same Proxmox VE version
- Synchronized time (NTP configured)
- SSH access between all nodes
- Proper DNS resolution or /etc/hosts entries

---

## Planning Your Cluster

### Network Design

```text
Example 3-Node Cluster Network Layout:

Node 1 (pve1.domain.com)
├── Management: 192.168.1.11/24
├── Cluster: 10.0.0.11/24
└── Storage: 172.16.0.11/24

Node 2 (pve2.domain.com)
├── Management: 192.168.1.12/24
├── Cluster: 10.0.0.12/24
└── Storage: 172.16.0.12/24

Node 3 (pve3.domain.com)
├── Management: 192.168.1.13/24
├── Cluster: 10.0.0.13/24
└── Storage: 172.16.0.13/24
```

### Naming Convention

- **Hostnames**: Use descriptive names (pve1, pve2, pve3)
- **FQDN**: Ensure proper DNS resolution
- **Consistency**: Use consistent naming across all nodes

### Quorum Planning

- **Odd number of nodes**: Prevents split-brain scenarios
- **Minimum 3 nodes**: Required for automatic failover
- **QDevice**: Can be used for even-numbered clusters

---

## Creating a Cluster

### Step 1: Prepare All Nodes

Ensure all nodes are properly configured before clustering:

```bash
# Update all nodes
apt update && apt upgrade -y

# Synchronize time
systemctl enable ntp
systemctl start ntp

# Check time sync
timedatectl status

# Verify connectivity between nodes
ping pve2.domain.com
ping pve3.domain.com
```

### Step 2: Create the Cluster

On the first node (will become the cluster master):

```bash
# Create cluster
pvecm create mycluster

# Alternative with specific network
pvecm create mycluster --ring0_addr 10.0.0.11

# Verify cluster creation
pvecm status
pvecm nodes
```

**Example output:**

```text
Cluster information
-------------------
Name:             mycluster
Config Version:   1
Transport:        knet
Secure auth:      on

Quorum information
------------------
Date:             Thu Aug 29 10:00:00 2025
Quorum provider:  corosync_votequorum
Nodes:            1
Node ID:          0x00000001
Ring ID:          1.0
Quorate:          No
```

### Step 3: Verify Cluster Configuration

```bash
# Check cluster configuration
cat /etc/pve/corosync.conf

# Check cluster logs
journalctl -f -u corosync
```

---

## Adding Nodes to Cluster

### Step 1: Join Nodes to Cluster

On each additional node:

```bash
# Join cluster (from node 2 and 3)
pvecm add pve1.domain.com

# Alternative with specific network
pvecm add pve1.domain.com --ring0_addr 10.0.0.12

# Verify join
pvecm status
pvecm nodes
```

### Step 2: Verify Cluster Health

After adding all nodes:

```bash
# Check cluster status
pvecm status

# Expected output shows all nodes:
# Node ID: 1 (pve1)
# Node ID: 2 (pve2)  
# Node ID: 3 (pve3)
# Quorate: Yes

# Check corosync membership
corosync-quorumtool -s
corosync-quorumtool -l
```

### Step 3: Test Cluster Functionality

```bash
# Test file system replication
touch /etc/pve/test-file
# File should appear on all nodes

# Check web interface
# Access any node's web interface - should show all nodes
```

---

## Removing Nodes from Cluster

### Safety Considerations

**⚠️ CRITICAL WARNINGS:**

- Always migrate VMs/containers before removing nodes
- Ensure cluster maintains quorum (majority of nodes)
- Never remove multiple nodes simultaneously
- Have full backups before making cluster changes
- Plan for potential downtime

### Migration Procedures

#### Step 1: Migrate Virtual Machines

```bash
# List VMs on the node to be removed
qm list

# Migrate VMs to other nodes (online migration)
qm migrate <VMID> <target-node>

# For offline migration if needed
qm stop <VMID>
qm migrate <VMID> <target-node>
qm start <VMID>
```

#### Step 2: Migrate Containers

```bash
# List containers on the node
pct list

# Migrate containers (requires restart)
pct migrate <CTID> <target-node>
```

### Graceful Node Removal

#### Step 1: Prepare Node for Removal

```bash
# On the node to be removed - ensure no running VMs/containers
qm list
pct list

# Stop cluster services
systemctl stop pve-cluster
systemctl stop corosync
systemctl stop pvedaemon
```

#### Step 2: Remove Node from Cluster

**Execute from a remaining cluster node:**

```bash
# Check current cluster status
pvecm status

# Remove the node (replace 'node-name' with actual node name)
pvecm delnode <node-name>

# Verify removal
pvecm status
pvecm nodes
```

#### Step 3: Clean Up Node Configuration

**On the removed node:**

```bash
# Remove cluster configuration
rm /etc/corosync/corosync.conf
rm /etc/pve/corosync.conf
rm -rf /etc/pve/nodes/<node-name>

# Reset cluster configuration
systemctl stop pve-cluster
pmxcfs -l

# Clean up cluster database
rm /var/lib/pve-cluster/config.db

# Restart services
systemctl start pvedaemon
systemctl start pveproxy
```

### Emergency Node Removal

When a node fails and cannot be accessed:

#### Step 1: Force Remove Failed Node

```bash
# From a working cluster node
pvecm expected 2  # Set expected votes (adjust for remaining nodes)

# Remove the failed node
pvecm delnode <failed-node-name> --force

# Update quorum settings
pvecm expected <number-of-remaining-nodes>
```

#### Step 2: Clean Up Cluster References

```bash
# Remove node references from cluster
rm -rf /etc/pve/nodes/<failed-node-name>

# Update firewall rules if needed
# Check /etc/pve/firewall/cluster.fw
```

### Storage Considerations

#### Shared Storage

```bash
# Verify shared storage access from remaining nodes
pvesm status

# Check for any node-specific storage references
cat /etc/pve/storage.cfg
```

#### Local Storage

- VMs/containers on local storage will be lost
- Ensure critical data is backed up before removal
- Update backup schedules to exclude removed node

### Quorum Management

#### Understanding Quorum

```bash
# Check current quorum status
corosync-quorumtool -s

# View quorum configuration
corosync-quorumtool -i
```

#### Adjusting Expected Votes

```bash
# For 2-node cluster after removal (becomes single node)
pvecm expected 1

# For larger clusters, maintain majority
# 5 nodes -> remove 1 -> 4 nodes (expected: 4)
# 3 nodes -> remove 1 -> 2 nodes (expected: 2)
```

### Post-Removal Verification

#### Step 1: Cluster Health Check

```bash
# Verify cluster status
pvecm status
pvecm nodes

# Check corosync
corosync-quorumtool -s
corosync-cfgtool -s
```

#### Step 2: Service Validation

```bash
# Test cluster services
systemctl status pve-cluster
systemctl status corosync
systemctl status pvedaemon

# Access web interface to verify all remaining nodes visible
```

#### Step 3: High Availability Check

```bash
# If using HA, verify configuration
ha-manager status

# Check for orphaned HA resources
cat /etc/pve/ha/resources.cfg
cat /etc/pve/ha/groups.cfg
```

### Troubleshooting Node Removal

#### Common Issues

**Quorum Loss:**

```bash
# If cluster loses quorum
pvecm expected 1  # Emergency quorum override
```

**Corosync Configuration Issues:**

```bash
**Corosync Configuration Issues:**

```bash
# Restart corosync on all remaining nodes
systemctl restart corosync

# Force cluster configuration update
systemctl restart pve-cluster
```

**Web Interface Access:**

```bash
# If web interface shows removed node
systemctl restart pveproxy pvedaemon
```

#### Node Removal Recovery

**Restore Removed Node:**

```bash
# If node removal was accidental and node is still accessible
# Stop cluster services on the removed node
systemctl stop pve-cluster
systemctl stop corosync
systemctl stop pvedaemon

# Remove cluster configuration files
rm /etc/corosync/corosync.conf
rm /etc/pve/corosync.conf

# Clear cluster database
rm /var/lib/pve-cluster/config.db

# Restart services in standalone mode
pmxcfs -l
systemctl start pvedaemon
systemctl start pveproxy

# To rejoin the cluster (if desired):
# pvecm add <existing-cluster-node>
```

**Web Interface Access:**

```bash
# If web interface shows removed node
systemctl restart pveproxy pvedaemon
```

#### Recovery Procedures

**Restore Removed Node:**

```bash
# If node removal was accidental and node is still accessible
# 1. Rejoin the node to cluster (follow adding nodes procedure)
# 2. Restore cluster configuration
# 3. Migrate VMs/containers back if needed
```

---

## Network Configuration

### Cluster Network Separation

Configure dedicated cluster network for optimal performance:

```bash
# Edit corosync configuration
nano /etc/pve/corosync.conf
```

**Example corosync.conf:**

```text
totem {
    cluster_name: mycluster
    config_version: 3
    interface {
        linknumber: 0
        bindnetaddr: 10.0.0.0
        mcastaddr: 239.255.0.1
        mcastport: 5405
        ttl: 1
    }
    ip_version: ipv4
    secauth: on
    version: 2
}

nodelist {
    node {
        name: pve1
        nodeid: 1
        quorum_votes: 1
        ring0_addr: 10.0.0.11
    }
    node {
        name: pve2
        nodeid: 2
        quorum_votes: 1
        ring0_addr: 10.0.0.12
    }
    node {
        name: pve3
        nodeid: 3
        quorum_votes: 1
        ring0_addr: 10.0.0.13
    }
}

quorum {
    provider: corosync_votequorum
}

logging {
    to_logfile: yes
    logfile: /var/log/cluster/corosync.log
    to_syslog: yes
    debug: off
}
```

### Network Redundancy

Configure redundant cluster networks:

```bash
# Add second ring for redundancy
pvecm updatecerts --force
```

**Multi-ring configuration:**

```text
totem {
    interface {
        linknumber: 0
        bindnetaddr: 10.0.0.0
    }
    interface {
        linknumber: 1
        bindnetaddr: 10.1.0.0
    }
}
```

---

## Storage Configuration

### Shared Storage Types

Proxmox supports various shared storage options:

1. **Ceph RBD**: Distributed storage within cluster
2. **NFS**: Network File System
3. **iSCSI**: Internet Small Computer Systems Interface
4. **ZFS over iSCSI**: ZFS with iSCSI transport
5. **GlusterFS**: Distributed file system

### Configure Shared Storage

#### NFS Storage Example

```bash
# Add NFS storage to cluster
pvesm add nfs nfs-storage --server 192.168.1.100 --export /srv/nfs/proxmox --content images,iso,vztmpl

# Verify storage
pvesm status
pvesm list nfs-storage
```

#### Ceph Storage Example

```bash
# Install Ceph (on all nodes)
pveceph install

# Create Ceph cluster
pveceph init --network 172.16.0.0/24

# Create monitors (on all nodes)
pveceph mon create

# Create OSDs (adjust for your disks)
pveceph osd create /dev/sdb
pveceph osd create /dev/sdc

# Create storage pool
pveceph pool create vm-pool --size 3 --min_size 2

# Add Ceph storage to Proxmox
pvesm add cephfs ceph-storage --monhost 172.16.0.11,172.16.0.12,172.16.0.13 --pool vm-pool
```

---

## High Availability Setup

### Configure HA Manager

High Availability ensures VMs automatically restart on other nodes if a node fails:

```bash
# Enable HA on VMs
ha-manager add vm:100 --state started --group default

# Configure HA groups (optional)
ha-manager set vm:100 --group production --max_restart 3 --max_relocate 1

# Check HA status
ha-manager status
ha-manager config
```

### HA Configuration Options

- **state**: started, stopped, ignored
- **group**: HA group assignment
- **max_restart**: Maximum restart attempts
- **max_relocate**: Maximum relocation attempts

### Fencing Configuration

Configure fencing to prevent data corruption:

```bash
# Configure watchdog (hardware dependent)
echo "softdog" >> /etc/modules
modprobe softdog

# Add to systemd
systemctl enable watchdog
systemctl start watchdog

# Configure in cluster
pvecm expected 1  # Use only in emergency
```

---

## Live Migration

### Prerequisites for Migration

- Shared storage accessible from all nodes
- Same CPU type/features on all nodes
- Sufficient resources on target node

### Migrate VMs

#### Online Migration (VM running)

```bash
# Migrate VM to specific node
qm migrate 100 pve2

# Migrate with specific options
qm migrate 100 pve2 --online --targetstorage nfs-storage
```

#### Offline Migration (VM stopped)

```bash
# Offline migration
qm migrate 100 pve2 --offline
```

### Migration via Web Interface

1. Select VM in web interface
2. Right-click → Migrate
3. Choose target node
4. Select migration type (online/offline)
5. Monitor migration progress

### Migration Monitoring

```bash
# Monitor active migrations
qm list
journalctl -f -u qemu-server@100

# Check migration logs
cat /var/log/pve/tasks/active
```

---

## Backup Strategies

### Cluster-Wide Backup Configuration

```bash
# Create backup job via CLI
vzdump --compress gzip --storage nfs-storage --mode snapshot --all 1

# Schedule backup job
echo "0 2 * * * root vzdump --compress gzip --storage backup-storage --all 1" >> /etc/crontab
```

### Backup Best Practices

- **Schedule during low usage**: Typically 2-4 AM
- **Use snapshot mode**: For consistent backups
- **Distribute backup load**: Stagger backup times across nodes
- **Monitor backup jobs**: Check logs regularly
- **Test restore procedures**: Verify backup integrity

### Backup Storage Considerations

- **Off-site storage**: Store backups away from cluster
- **Retention policies**: Implement appropriate retention
- **Compression**: Use compression to save space
- **Encryption**: Encrypt sensitive backups

---

## Monitoring and Maintenance

### Cluster Health Monitoring

```bash
# Check cluster status
pvecm status
corosync-quorumtool -s

# Monitor node resources
pvesh get /nodes

# Check storage health
pvesm status

# Monitor logs
journalctl -f -u corosync
journalctl -f -u pve-ha-crm
journalctl -f -u pve-ha-lrm
```

### Regular Maintenance Tasks

#### Weekly Tasks

```bash
# Check cluster connectivity
pvecm nodes

# Verify backup completion
cat /var/log/pve/tasks/index

# Monitor disk usage
df -h
pvesm status
```

#### Monthly Tasks

```bash
# Update all nodes (during maintenance window)
apt update && apt upgrade

# Clean old logs
journalctl --vacuum-time=30d

# Check hardware health
dmesg | grep -i error
smartctl -a /dev/sda
```

### Performance Monitoring

```bash
# Resource usage across cluster
pvesh get /cluster/resources

# Individual node performance
top
iostat -x 1 5
sar -u 1 10

# Network performance
iftop
nethogs
```

---

## Troubleshooting

### Common Cluster Issues

#### Split-Brain Prevention

```bash
# Check quorum status
corosync-quorumtool -s

# If cluster lost quorum (emergency only):
pvecm expected 1  # On remaining node

# Restore proper quorum when nodes return
pvecm expected 3  # After all nodes rejoin
```

#### Node Communication Issues

```bash
# Check corosync status
systemctl status corosync

# Test multicast connectivity
corosync-quorumtool -l

# Check network connectivity
ping -c 4 pve2.domain.com
traceroute pve2.domain.com

# Restart corosync (if needed)
systemctl restart corosync
```

#### Configuration Sync Issues

```bash
# Check pmxcfs status
systemctl status pve-cluster

# Restart cluster filesystem
systemctl restart pve-cluster

# Force configuration reload
pvecm updatecerts --force
```

### Disaster Recovery Procedures

#### Remove Failed Node

```bash
# From working node, remove failed node
pvecm delnode pve2

# Clean up any remaining references
rm -rf /etc/pve/nodes/pve2/
```

#### Rejoin Node to Cluster

```bash
# On previously failed node
systemctl stop pve-cluster
systemctl stop corosync
rm -rf /etc/pve/corosync.conf
rm -rf /var/lib/corosync/*

# Rejoin cluster
pvecm add pve1.domain.com
```

---

## Best Practices

### Planning and Design

- **Start with 3 nodes**: Minimum for proper HA
- **Use dedicated networks**: Separate cluster, storage, and management traffic
- **Plan for growth**: Design network and storage to accommodate expansion
- **Document everything**: Maintain cluster topology and configuration docs

### Security

- **Network isolation**: Use VLANs to isolate cluster traffic
- **SSH key authentication**: Disable password authentication
- **Firewall rules**: Restrict access to cluster ports
- **Regular updates**: Keep all nodes updated with security patches

### Performance

- **Use SSDs**: For better VM performance and migration speed
- **10GbE networks**: For high-performance environments
- **CPU matching**: Ensure consistent CPU features across nodes
- **Memory planning**: Avoid memory overcommitment

### Operational

- **Monitoring**: Implement comprehensive monitoring
- **Backup testing**: Regularly test backup and restore procedures
- **Change management**: Plan and test changes in development first
- **Documentation**: Keep runbooks for common procedures

### Maintenance Windows

- **Schedule regularly**: Plan monthly maintenance windows
- **Update gradually**: Update one node at a time
- **Test after updates**: Verify cluster functionality after updates
- **Communication**: Notify users of planned maintenance

---

## Quick Reference

### Essential Commands

```bash
# Cluster management
pvecm status                    # Check cluster status
pvecm nodes                     # List cluster nodes
pvecm create <name>            # Create new cluster
pvecm add <node>               # Add node to cluster
pvecm delnode <node>           # Remove node from cluster

# Quorum management
corosync-quorumtool -s         # Check quorum status
corosync-quorumtool -l         # List cluster members
pvecm expected <n>             # Set expected votes (emergency)

# HA management
ha-manager status              # Check HA status
ha-manager add vm:<id>         # Add VM to HA
ha-manager remove vm:<id>      # Remove VM from HA
ha-manager config              # Show HA configuration

# Storage management
pvesm status                   # Check storage status
pvesm list <storage>           # List storage contents
pvesm add <type> <id>          # Add storage

# Migration
qm migrate <vmid> <node>       # Migrate VM
qm migrate <vmid> <node> --online  # Online migration
pct migrate <ctid> <node>      # Migrate container
```

### Important File Locations

- **Cluster config**: `/etc/pve/corosync.conf`
- **Node certificates**: `/etc/pve/nodes/<node>/`
- **Cluster logs**: `/var/log/cluster/corosync.log`
- **HA config**: `/etc/pve/ha/`
- **Storage config**: `/etc/pve/storage.cfg`

### Port Requirements

- **5404-5405**: Corosync multicast
- **22**: SSH
- **8006**: Proxmox web interface
- **3128**: Proxmox VE subscription check
- **5900-5999**: VNC console ports

---

> **Important**: Always test cluster operations in a development environment before implementing in production. Cluster changes can affect all VMs and should be performed during planned maintenance windows.
