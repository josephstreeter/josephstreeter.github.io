---
title: "Terraform Proxmox VM Infrastructure for Kubernetes"
description: "Complete guide to deploying VM infrastructure on Proxmox VE using Terraform for Kubernetes clusters with automation and best practices"
author: "josephstreeter"
ms.date: "2025-12-30"
ms.topic: "how-to-guide"
ms.service: "terraform"
keywords: ["Terraform", "Proxmox", "Kubernetes", "K8s", "Infrastructure as Code", "IaC", "Cloud-Init", "Automation", "VMs"]
---

This guide demonstrates how to deploy VM infrastructure on Proxmox VE using Terraform for Kubernetes clusters. Terraform handles VM provisioning with cloud-init integration, while Kubernetes installation can be automated through cloud-init scripts, Ansible, or manual setup. The configuration creates multiple nodes with proper networking, security, and scalability considerations.

> **⚠️ SECURITY WARNING:** This guide contains example configurations with placeholder values. NEVER use these examples directly in production. Always:
>
> - Generate unique SSH keys for each environment
> - Use strong, randomly generated passwords and tokens
> - Enable TLS verification (set `proxmox_tls_insecure = false`)
> - Store sensitive values in secure secret management systems (HashiCorp Vault, AWS Secrets Manager, etc.)
> - Never commit `terraform.tfvars` or any files containing credentials to version control
> - Implement regular secret rotation policies

---

> **Note:** This guide focuses on infrastructure provisioning. Kubernetes installation is covered through cloud-init automation. For production deployments, consider using Packer for template creation and GitOps workflows.

## Prerequisites

### Proxmox VE Requirements

- Proxmox VE 7.x or later
- API user with appropriate permissions
- Cloud-init enabled VM template (Ubuntu/Debian recommended)
- Sufficient resources for cluster nodes
- Network bridge configured (vmbr0)

### Required Proxmox API Permissions

Create a dedicated API user with least-privilege permissions:

```bash
# Create user
pveum user add terraform-prov@pve

# Create custom role with required permissions
pveum role add TerraformProvisioner -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit SDN.Use"

# Assign role to user
pveum aclmod / -user terraform-prov@pve -role TerraformProvisioner

# Create API token (non-privileged separation)
pveum user token add terraform-prov@pve terraform_id -privsep 1

# Alternative: Create token without privilege separation for testing
# pveum user token add terraform-prov@pve terraform_id -privsep 0
```

> **Security Best Practice:** Use `-privsep 1` for privilege separation. This ensures the API token has the same permissions as the user, not elevated privileges.

### Terraform Requirements

- Terraform >= 1.0
- Proxmox Terraform provider
- SSH key pair for VM access

### Cloud-Init Template Preparation

Ensure your template includes:

```bash
# Install cloud-init and qemu-guest-agent
sudo apt update && sudo apt install -y cloud-init qemu-guest-agent

# Enable services
sudo systemctl enable qemu-guest-agent
sudo systemctl enable cloud-init

# Clean template before conversion
sudo cloud-init clean --logs
sudo rm -rf /var/lib/cloud/instances/*
```

---

## Terraform Configuration

### Project Structure

```text
kubernetes-cluster/
├── main.tf                 # Main resource definitions
├── variables.tf           # Input variables
├── outputs.tf            # Output values
├── providers.tf          # Provider configurations
├── terraform.tfvars     # Variable values (DO NOT COMMIT)
├── modules/
│   └── k8s-node/        # Reusable node module
└── scripts/
    └── k8s-setup.sh     # Post-deployment scripts
```

### `providers.tf`

```hcl
terraform {
  required_version = ">= 1.0"
  
  # Remote state backend (recommended for production)
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "proxmox/k8s-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    
    # Enable state locking
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
  
  # Alternative: Consul backend
  # backend "consul" {
  #   address = "consul.example.com:8500"
  #   path    = "proxmox/k8s-cluster/terraform.tfstate"
  #   lock    = true
  # }
  
  # Alternative: HTTP backend
  # backend "http" {
  #   address        = "https://api.example.com/terraform/state/k8s-cluster"
  #   lock_address   = "https://api.example.com/terraform/state/k8s-cluster/lock"
  #   unlock_address = "https://api.example.com/terraform/state/k8s-cluster/lock"
  # }
  
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure = var.proxmox_tls_insecure
  
}
```

> **Note:** This configuration uses the `telmate/proxmox` provider which is stable and widely used. For the latest features, consider the `bpg/proxmox` fork, but note that resource names and configuration differ significantly.

### `variables.tf`

```hcl
variable "proxmox_api_url" {
  type        = string
  description = "URL of the Proxmox API"
  validation {
    condition     = can(regex("^https://", var.proxmox_api_url))
    error_message = "Proxmox API URL must start with https://"
  }
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API token ID"
  sensitive   = true
  validation {
    condition     = can(regex("@pve!", var.proxmox_api_token_id))
    error_message = "API token ID must be in format: user@pve!token-name"
  }
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  type        = bool
  description = "Skip TLS verification for Proxmox API (only use for testing with self-signed certificates)"
  default     = false
}

variable "target_node" {
  type        = string
  description = "Target Proxmox node for VM deployment"
}

variable "template_name" {
  type        = string
  description = "Name of the cloud-init template"
  default     = "debian12-cloudinit"
}

variable "storage" {
  type        = string
  description = "Storage pool for VM disks"
  default     = "local-lvm"
}

variable "network_bridge" {
  type        = string
  description = "Network bridge for VMs"
  default     = "vmbr0"
}

variable "cluster_name" {
  type        = string
  description = "Name of the Kubernetes cluster"
  default     = "k8s-cluster"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "cluster_network" {
  type = object({
    subnet  = string
    gateway = string
    dns     = list(string)
  })
  description = "Network configuration for the cluster"
  validation {
    condition     = can(cidrhost(var.cluster_network.subnet, 0))
    error_message = "Subnet must be a valid CIDR notation (e.g., 192.168.100.0/24)"
  }
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.cluster_network.gateway))
    error_message = "Gateway must be a valid IPv4 address"
  }
  validation {
    condition = alltrue([
      for dns in var.cluster_network.dns : 
      can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", dns))
    ])
    error_message = "All DNS servers must be valid IPv4 addresses"
  }
  default = {
    subnet  = "192.168.100.0/24"
    gateway = "192.168.100.1"
    dns     = ["8.8.8.8", "1.1.1.1"]
  }
}

variable "master_nodes" {
  type = map(object({
    vmid   = number
    ip     = string
    cores  = number
    memory = number
    disk   = string
  }))
  description = "Master node configurations"
  validation {
    condition = alltrue([
      for k, v in var.master_nodes : 
      can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", v.ip))
    ])
    error_message = "All master node IP addresses must be valid IPv4 addresses"
  }
  validation {
    condition = alltrue([
      for k, v in var.master_nodes : 
      v.vmid >= 100 && v.vmid <= 999999
    ])
    error_message = "All master node VMIDs must be between 100 and 999999"
  }
  validation {
    condition = length(var.master_nodes) == length(distinct([for k, v in var.master_nodes : v.vmid]))
    error_message = "All master node VMIDs must be unique"
  }
  validation {
    condition = length(var.master_nodes) == length(distinct([for k, v in var.master_nodes : v.ip]))
    error_message = "All master node IP addresses must be unique"
  }
  default = {
    "master-01" = {
      vmid   = 101
      ip     = "192.168.100.10"
      cores  = 2
      memory = 4096
      disk   = "20G"
    }
    "master-02" = {
      vmid   = 102
      ip     = "192.168.100.11"
      cores  = 2
      memory = 4096
      disk   = "20G"
    }
    "master-03" = {
      vmid   = 103
      ip     = "192.168.100.12"
      cores  = 2
      memory = 4096
      disk   = "20G"
    }
  }
}

variable "worker_nodes" {
  type = map(object({
    vmid   = number
    ip     = string
    cores  = number
    memory = number
    disk   = string
  }))
  description = "Worker node configurations"
  validation {
    condition = alltrue([
      for k, v in var.worker_nodes : 
      can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", v.ip))
    ])
    error_message = "All worker node IP addresses must be valid IPv4 addresses"
  }
  validation {
    condition = alltrue([
      for k, v in var.worker_nodes : 
      v.vmid >= 100 && v.vmid <= 999999
    ])
    error_message = "All worker node VMIDs must be between 100 and 999999"
  }
  validation {
    condition = length(var.worker_nodes) == length(distinct([for k, v in var.worker_nodes : v.vmid]))
    error_message = "All worker node VMIDs must be unique"
  }
  validation {
    condition = length(var.worker_nodes) == length(distinct([for k, v in var.worker_nodes : v.ip]))
    error_message = "All worker node IP addresses must be unique"
  }
  default = {
    "worker-01" = {
      vmid   = 201
      ip     = "192.168.100.20"
      cores  = 4
      memory = 8192
      disk   = "50G"
    }
    "worker-02" = {
      vmid   = 202
      ip     = "192.168.100.21"
      cores  = 4
      memory = 8192
      disk   = "50G"
    }
    "worker-03" = {
      vmid   = 203
      ip     = "192.168.100.22"
      cores  = 4
      memory = 8192
      disk   = "50G"
    }
  }
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access"
  sensitive   = true
}

variable "cloud_init_user" {
  type        = string
  description = "Default user for cloud-init"
  default     = "ubuntu"
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable Prometheus node exporter on VMs"
  default     = true
}

variable "enable_ha" {
  type        = bool
  description = "Enable HA with load balancer"
  default     = true
}

variable "lb_ip" {
  type        = string
  description = "Load balancer IP address"
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.lb_ip))
    error_message = "Load balancer IP must be a valid IPv4 address"
  }
  default     = "192.168.100.5"
}
```

### `data.tf`

Query Proxmox for dynamic values:

```hcl
# Get available nodes in the cluster
data "proxmox_virtual_environment_nodes" "available" {}

# Get current Proxmox version
data "proxmox_virtual_environment_version" "current" {}

# Output available storage for validation
locals {
  # Validate storage and network configuration
  valid_storage = var.storage != ""
  valid_network = var.network_bridge != ""
}
```

### Cloud-Init Kubernetes Preparation

Create `cloud-init/k8s-node.yaml` for automated Kubernetes node setup:

```yaml
#cloud-config
# Kubernetes Node Preparation via Cloud-Init

package_update: true
package_upgrade: true

packages:
  - qemu-guest-agent
  - curl
  - apt-transport-https
  - ca-certificates
  - gnupg
  - lsb-release

write_files:
  # Kernel modules for Kubernetes
  - path: /etc/modules-load.d/k8s.conf
    content: |
      overlay
      br_netfilter
  
  # Sysctl parameters for Kubernetes
  - path: /etc/sysctl.d/k8s.conf
    content: |
      net.bridge.bridge-nf-call-iptables  = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      net.ipv4.ip_forward                 = 1
      net.ipv4.conf.all.forwarding        = 1
      vm.overcommit_memory                = 1
      kernel.panic                        = 10
      kernel.panic_on_oops                = 1
  
  # Prometheus Node Exporter service
  - path: /etc/systemd/system/node_exporter.service
    content: |
      [Unit]
      Description=Node Exporter
      After=network.target
      
      [Service]
      Type=simple
      User=node_exporter
      ExecStart=/usr/local/bin/node_exporter
      Restart=always
      
      [Install]
      WantedBy=multi-user.target

runcmd:
  # Load kernel modules
  - modprobe overlay
  - modprobe br_netfilter
  
  # Apply sysctl params
  - sysctl --system
  
  # Disable swap permanently
  - swapoff -a
  - sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
  
  # Install containerd
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y containerd.io
  
  # Configure containerd for Kubernetes
  - mkdir -p /etc/containerd
  - containerd config default | tee /etc/containerd/config.toml
  - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
  - systemctl restart containerd
  - systemctl enable containerd
  
  # Install kubeadm, kubelet, kubectl (v1.28)
  - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
  - apt-get update
  - apt-get install -y kubelet kubeadm kubectl
  - apt-mark hold kubelet kubeadm kubectl
  - systemctl enable kubelet
  
  # Install Prometheus Node Exporter
  - wget -q https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
  - tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
  - cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
  - useradd -rs /bin/false node_exporter
  - chown node_exporter:node_exporter /usr/local/bin/node_exporter
  - systemctl daemon-reload
  - systemctl enable node_exporter
  - systemctl start node_exporter
  
  # Enable and start qemu-guest-agent
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent

final_message: "Kubernetes node preparation complete after $UPTIME seconds"
```

Upload to Proxmox:

```bash
# Upload cloud-init config to Proxmox snippets storage
scp cloud-init/k8s-node.yaml root@proxmox-host:/var/lib/vz/snippets/
```

### `main.tf`

```hcl
# Local values for common configurations
locals {
  all_nodes = merge(var.master_nodes, var.worker_nodes)
  
  # Kubernetes constants
  k8s_api_port              = 6443
  haproxy_stats_port        = 8404
  node_exporter_port        = 9100
  
  # Default resource allocations
  default_master_memory_mb  = 4096
  default_master_cores      = 2
  default_master_disk_gb    = 20
  default_worker_memory_mb  = 8192
  default_worker_cores      = 4
  default_worker_disk_gb    = 50
  
  # Network configuration
  pod_network_cidr_default  = "10.244.0.0/16"
  service_cidr_default      = "10.96.0.0/12"
  
  common_vm_config = {
    agent               = 1
    boot                = "order=scsi0"
    clone               = var.template_name
    scsihw              = "virtio-scsi-single"
    vm_state            = "running"
    automatic_reboot    = true
    ciupgrade           = true
    skip_ipv6           = true
    ciuser              = var.cloud_init_user
    sshkeys             = var.ssh_public_key
    nameserver          = join(" ", var.cluster_network.dns)
  }
}

# Master nodes for Kubernetes control plane
resource "proxmox_vm_qemu" "k8s_masters" {
  for_each = var.master_nodes

  vmid        = each.value.vmid
  name        = "${var.cluster_name}-${each.key}"
  target_node = var.target_node
  
  # Resource allocation
  cores  = each.value.cores
  memory = each.value.memory
  
  # Apply common configuration
  agent               = local.common_vm_config.agent
  boot                = local.common_vm_config.boot
  clone               = local.common_vm_config.clone
  scsihw              = local.common_vm_config.scsihw
  vm_state            = local.common_vm_config.vm_state
  automatic_reboot    = local.common_vm_config.automatic_reboot
  
  # Cloud-init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml"
  ciupgrade  = local.common_vm_config.ciupgrade
  ciuser     = local.common_vm_config.ciuser
  sshkeys    = local.common_vm_config.sshkeys
  nameserver = local.common_vm_config.nameserver
  skip_ipv6  = local.common_vm_config.skip_ipv6
  
  # Network configuration
  ipconfig0 = "ip=${each.value.ip}/${split("/", var.cluster_network.subnet)[1]},gw=${var.cluster_network.gateway}"
  
  # Tags for organization
  tags = "kubernetes,master,${var.cluster_name}"

  # Serial console for cloud-init
  serial {
    id = 0
  }

  # Disk configuration
  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.storage
          size    = each.value.disk
          cache   = "writethrough"
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = var.storage
        }
      }
    }
  }

  # Network interface
  network {
    id     = 0
    bridge = var.network_bridge
    model  = "virtio"
  }

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      clone,
      full_clone,
    ]
  }
}

# Worker nodes for Kubernetes workloads
resource "proxmox_vm_qemu" "k8s_workers" {
  for_each = var.worker_nodes

  vmid        = each.value.vmid
  name        = "${var.cluster_name}-${each.key}"
  target_node = var.target_node
  
  # Resource allocation
  cores  = each.value.cores
  memory = each.value.memory
  
  # Apply common configuration
  agent               = local.common_vm_config.agent
  boot                = local.common_vm_config.boot
  clone               = local.common_vm_config.clone
  scsihw              = local.common_vm_config.scsihw
  vm_state            = local.common_vm_config.vm_state
  automatic_reboot    = local.common_vm_config.automatic_reboot
  
  # Cloud-init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml"
  ciupgrade  = local.common_vm_config.ciupgrade
  ciuser     = local.common_vm_config.ciuser
  sshkeys    = local.common_vm_config.sshkeys
  nameserver = local.common_vm_config.nameserver
  skip_ipv6  = local.common_vm_config.skip_ipv6
  
  # Network configuration
  ipconfig0 = "ip=${each.value.ip}/${split("/", var.cluster_network.subnet)[1]},gw=${var.cluster_network.gateway}"
  
  # Tags for organization
  tags = "kubernetes,worker,${var.cluster_name}"

  # Serial console for cloud-init
  serial {
    id = 0
  }

  # Disk configuration
  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.storage
          size    = each.value.disk
          cache   = "writethrough"
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = var.storage
        }
      }
    }
  }

  # Network interface
  network {
    id     = 0
    bridge = var.network_bridge
    model  = "virtio"
  }

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      clone,
      full_clone,
    ]
  }
}
```

### `outputs.tf`

```hcl
output "master_nodes" {
  description = "Master node information"
  value = {
    for k, v in proxmox_vm_qemu.k8s_masters : k => {
      name      = v.name
      vmid      = v.vmid
      ip        = var.master_nodes[k].ip
      cores     = v.cores
      memory    = v.memory
      status    = v.vm_state
    }
  }
}

output "worker_nodes" {
  description = "Worker node information"
  value = {
    for k, v in proxmox_vm_qemu.k8s_workers : k => {
      name      = v.name
      vmid      = v.vmid
      ip        = var.worker_nodes[k].ip
      cores     = v.cores
      memory    = v.memory
      status    = v.vm_state
    }
  }
}

output "cluster_endpoints" {
  description = "Kubernetes cluster connection information"
  sensitive   = true
  value = {
    api_servers    = [for k, v in var.master_nodes : "${v.ip}:${local.k8s_api_port}"]
    master_ips     = [for k, v in var.master_nodes : v.ip]
    worker_ips     = [for k, v in var.worker_nodes : v.ip]
    # SSH connection info removed from output for security
    # Use: terraform output -raw cluster_endpoints | jq -r '.master_ips[0]'
  }
}

output "connection_info" {
  description = "Safe connection information for cluster access"
  value = {
    cluster_name     = var.cluster_name
    master_count     = length(var.master_nodes)
    worker_count     = length(var.worker_nodes)
    kubernetes_version = var.kubernetes_version
    ha_enabled       = var.enable_ha
    api_endpoint     = var.enable_ha ? "${var.lb_ip}:${local.k8s_api_port}" : "${values(var.master_nodes)[0].ip}:${local.k8s_api_port}"
  }
}

output "next_steps" {
  description = "Commands to run after deployment"
  value = {
    ssh_to_master = "ssh ${var.cloud_init_user}@${values(var.master_nodes)[0].ip}"
    kubeadm_init  = "sudo kubeadm init --apiserver-advertise-address=${values(var.master_nodes)[0].ip} --pod-network-cidr=${local.pod_network_cidr_default}"
    setup_kubectl = "mkdir -p $HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config"
  }
}
```

### Load Balancer for HA Kubernetes API

For highly available Kubernetes control plane, add HAProxy load balancer:

```hcl
# HAProxy Load Balancer for K8s API (optional - enabled via var.enable_ha)
resource "proxmox_vm_qemu" "k8s_lb" {
  count = var.enable_ha ? 1 : 0
  
  vmid        = 100
  name        = "${var.cluster_name}-lb"
  target_node = var.target_node
  
  cores  = 2
  memory = 2048
  
  agent               = local.common_vm_config.agent
  boot                = local.common_vm_config.boot
  clone               = local.common_vm_config.clone
  scsihw              = local.common_vm_config.scsihw
  vm_state            = local.common_vm_config.vm_state
  automatic_reboot    = local.common_vm_config.automatic_reboot
  
  # Cloud-init with HAProxy configuration
  cicustom   = "vendor=local:snippets/haproxy-cloud-init.yml"
  ciupgrade  = local.common_vm_config.ciupgrade
  ciuser     = local.common_vm_config.ciuser
  sshkeys    = local.common_vm_config.sshkeys
  nameserver = local.common_vm_config.nameserver
  skip_ipv6  = local.common_vm_config.skip_ipv6
  
  ipconfig0 = "ip=${var.lb_ip}/${split("/", var.cluster_network.subnet)[1]},gw=${var.cluster_network.gateway}"
  
  tags = "kubernetes,loadbalancer,${var.cluster_name}"
  
  serial {
    id = 0
  }
  
  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.storage
          size    = "20G"
          cache   = "writethrough"
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = var.storage
        }
      }
    }
  }
  
  network {
    id     = 0
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  lifecycle {
    ignore_changes = [clone, full_clone]
  }
}
```

Create `cloud-init/haproxy-cloud-init.yml`:

> **Note:** This should be generated dynamically using Terraform's `templatefile()` function for production use.

```yaml
#cloud-config
package_update: true
packages:
  - haproxy
  - keepalived

write_files:
  - path: /etc/haproxy/haproxy.cfg
    content: |
      global
        log /dev/log local0
        log /dev/log local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin
        stats timeout 30s
        user haproxy
        group haproxy
        daemon
      
      defaults
        log     global
        mode    tcp
        option  tcplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
      
      frontend k8s_api_frontend
        bind *:${K8S_API_PORT}
        mode tcp
        option tcplog
        default_backend k8s_api_backend
      
      backend k8s_api_backend
        mode tcp
        option tcp-check
        balance roundrobin
        # NOTE: These IPs should be dynamically generated from Terraform
        # Use: templatefile("haproxy-cloud-init.tpl", { master_nodes = var.master_nodes })
        server master-01 ${MASTER_01_IP}:${K8S_API_PORT} check fall 3 rise 2
        server master-02 ${MASTER_02_IP}:${K8S_API_PORT} check fall 3 rise 2
        server master-03 ${MASTER_03_IP}:${K8S_API_PORT} check fall 3 rise 2
      
      listen stats
        bind *:${HAPROXY_STATS_PORT}
        stats enable
        stats uri /
        stats refresh 30s

runcmd:
  - systemctl enable haproxy
  - systemctl restart haproxy
```

**Better approach using Terraform template:**

Create `templates/haproxy-cloud-init.tpl`:

```yaml
#cloud-config
package_update: true
packages:
  - haproxy
  - keepalived

write_files:
  - path: /etc/haproxy/haproxy.cfg
    content: |
      global
        log /dev/log local0
        log /dev/log local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin
        stats timeout 30s
        user haproxy
        group haproxy
        daemon
      
      defaults
        log     global
        mode    tcp
        option  tcplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
      
      frontend k8s_api_frontend
        bind *:${k8s_api_port}
        mode tcp
        option tcplog
        default_backend k8s_api_backend
      
      backend k8s_api_backend
        mode tcp
        option tcp-check
        balance roundrobin
        %{ for name, node in master_nodes ~}
        server ${name} ${node.ip}:${k8s_api_port} check fall 3 rise 2
        %{ endfor ~}
      
      listen stats
        bind *:${haproxy_stats_port}
        stats enable
        stats uri /
        stats refresh 30s

runcmd:
  - systemctl enable haproxy
  - systemctl restart haproxy
```

Then generate the file in Terraform:

```hcl
# Generate HAProxy cloud-init configuration
resource "local_file" "haproxy_cloud_init" {
  count = var.enable_ha ? 1 : 0
  
  content = templatefile("${path.module}/templates/haproxy-cloud-init.tpl", {
    master_nodes       = var.master_nodes
    k8s_api_port      = local.k8s_api_port
    haproxy_stats_port = local.haproxy_stats_port
  })
  filename = "${path.module}/generated/haproxy-cloud-init.yml"
}

# Upload to Proxmox requires manual step or automation
# Consider using Terraform's null_resource with local-exec
resource "null_resource" "upload_haproxy_config" {
  count = var.enable_ha ? 1 : 0
  
  triggers = {
    config_hash = local_file.haproxy_cloud_init[0].content
  }
  
  provisioner "local-exec" {
    command = "scp ${local_file.haproxy_cloud_init[0].filename} root@${var.proxmox_host}:/var/lib/vz/snippets/haproxy-cloud-init.yml"
  }
  
  depends_on = [local_file.haproxy_cloud_init]
}
```

Update outputs for load balancer:

```hcl
output "load_balancer" {
  description = "Load balancer information"
  value = var.enable_ha ? {
    ip            = var.lb_ip
    api_endpoint  = "${var.lb_ip}:${local.k8s_api_port}"
    stats_url     = "http://${var.lb_ip}:${local.haproxy_stats_port}"
  } : null
}
```

---

## Configuration Files

### `terraform.tfvars` Template

Create this file with your actual values (DO NOT commit to version control):

> **⚠️ CRITICAL SECURITY REMINDER:**
>
> - Add `terraform.tfvars` to your `.gitignore` file immediately
> - Use unique credentials for each environment (dev, staging, production)
> - Enable TLS verification in production (`proxmox_tls_insecure = false`)
> - Consider using `terraform.tfvars.example` as a template and `.tfvars` for actual values
> - For CI/CD pipelines, use environment variables or secret management tools instead

```hcl
# Proxmox connection
proxmox_api_url          = "https://your-proxmox-host:8006/api2/json"
proxmox_api_token_id     = "terraform-prov@pve!terraform_id"
proxmox_api_token_secret = "your-api-token-secret"
proxmox_tls_insecure     = false  # Set to true only for testing with self-signed certs

# Infrastructure settings  
target_node     = "your-node-name"
template_name   = "debian12-cloudinit"
storage         = "local-lvm"
network_bridge  = "vmbr0"

# Cluster configuration
cluster_name = "production-k8s"
cluster_network = {
  subnet  = "192.168.100.0/24"
  gateway = "192.168.100.1"
  dns     = ["8.8.8.8", "1.1.1.1"]
}

# HA and Monitoring
enable_ha         = true
enable_monitoring = true
lb_ip             = "192.168.100.5"

# SSH access
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-public-key"
cloud_init_user = "ubuntu"

# Master nodes (adjust as needed)
master_nodes = {
  "master-01" = {
    vmid   = 101
    ip     = "192.168.100.10"
    cores  = 2
    memory = 4096
    disk   = "20G"
  }
  "master-02" = {
    vmid   = 102
    ip     = "192.168.100.11" 
    cores  = 2
    memory = 4096
    disk   = "20G"
  }
  "master-03" = {
    vmid   = 103
    ip     = "192.168.100.12"
    cores  = 2
    memory = 4096
    disk   = "20G"
  }
}

# Worker nodes (adjust as needed)
worker_nodes = {
  "worker-01" = {
    vmid   = 201
    ip     = "192.168.100.20"
    cores  = 4
    memory = 8192
    disk   = "50G"
  }
  "worker-02" = {
    vmid   = 202
    ip     = "192.168.100.21"
    cores  = 4
    memory = 8192
    disk   = "50G"  
  }
  "worker-03" = {
    vmid   = 203
    ip     = "192.168.100.22"
    cores  = 4
    memory = 8192
    disk   = "50G"
  }
}
```

### Environment Variables (Alternative)

```bash
export TF_VAR_proxmox_api_url="https://your-proxmox-host:8006/api2/json"
export TF_VAR_proxmox_api_token_id="terraform-prov@pve!terraform_id"  
export TF_VAR_proxmox_api_token_secret="your-api-token-secret"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
```

---

## Modular Architecture (Recommended)

For better maintainability, organize infrastructure using modules.

### Module Structure

```text
kubernetes-cluster/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
└── modules/
    ├── k8s-node/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── load-balancer/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Node Module: `modules/k8s-node/main.tf`

```hcl
resource "proxmox_vm_qemu" "node" {
  vmid        = var.vmid
  name        = var.name
  target_node = var.target_node
  
  cores  = var.cores
  memory = var.memory
  
  agent            = 1
  boot             = "order=scsi0"
  clone            = var.template_name
  scsihw           = "virtio-scsi-single"
  vm_state         = "running"
  automatic_reboot = true
  
  cicustom   = "vendor=local:snippets/${var.cloud_init_file}"
  ciupgrade  = true
  ciuser     = var.cloud_init_user
  sshkeys    = var.ssh_public_key
  nameserver = join(" ", var.dns_servers)
  skip_ipv6  = true
  
  ipconfig0 = "ip=${var.ip_address}/${var.ip_cidr},gw=${var.gateway}"
  tags = join(",", concat(["kubernetes", var.node_type], var.additional_tags))
  
  serial {
    id = 0
  }
  
  disks {
    scsi {
      scsi0 {
        disk {
          storage  = var.storage
          size     = var.disk_size
          cache    = "writethrough"
          iothread = var.enable_iothread ? 1 : 0
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = var.storage
        }
      }
    }
  }
  
  network {
    id     = 0
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  lifecycle {
    ignore_changes = [clone, full_clone]
  }
}
```

### Node Module Variables

Key variables for the module in `modules/k8s-node/variables.tf`:

```hcl
variable "vmid" { type = number }
variable "name" { type = string }
variable "target_node" { type = string }
variable "cores" { type = number; default = 2 }
variable "memory" { type = number; default = 4096 }
variable "disk_size" { type = string; default = "20G" }
variable "node_type" {
  type = string
  validation {
    condition     = contains(["master", "worker"], var.node_type)
    error_message = "Node type must be master or worker"
  }
}
```

### Using the Module

```hcl
# Master nodes using module
module "k8s_masters" {
  source   = "./modules/k8s-node"
  for_each = var.master_nodes
  
  vmid            = each.value.vmid
  name            = "${var.cluster_name}-${each.key}"
  target_node     = var.target_node
  cores           = each.value.cores
  memory          = each.value.memory
  disk_size       = each.value.disk
  template_name   = var.template_name
  storage         = var.storage
  network_bridge  = var.network_bridge
  ip_address      = each.value.ip
  ip_cidr         = split("/", var.cluster_network.subnet)[1]
  gateway         = var.cluster_network.gateway
  dns_servers     = var.cluster_network.dns
  cloud_init_user = var.cloud_init_user
  ssh_public_key  = var.ssh_public_key
  cloud_init_file = "k8s-node.yaml"
  node_type       = "master"
  additional_tags = [var.cluster_name]
}
```

---

## Deployment Process

### Step 1: Initialize Terraform

```bash
# Initialize Terraform workspace
terraform init

# Validate configuration
terraform validate

# Format configuration files
terraform fmt
```

### Step 2: Plan Deployment

```bash
# Review planned changes
terraform plan

# Save plan to file for review
terraform plan -out=k8s-cluster.tfplan

# Review specific resource changes
terraform show k8s-cluster.tfplan
```

### Step 3: Deploy Infrastructure

```bash
# Apply configuration
terraform apply k8s-cluster.tfplan

# Or apply with auto-approval (use with caution)
terraform apply -auto-approve
```

### Step 4: Verify Deployment

```bash
# Check deployed resources
terraform show

# Verify outputs
terraform output

# Test SSH connectivity to first master
terraform output -json cluster_endpoints | jq -r '.value.ssh_command'
```

---

## Automated Kubernetes Installation

### Using Terraform Provisioners with Ansible

Automate complete Kubernetes installation using Terraform's local-exec provisioner with Ansible.

#### Ansible Inventory Generation

Add to `main.tf`:

```hcl
# Generate Ansible inventory dynamically
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    master_nodes = {
      for k, v in var.master_nodes : k => {
        ip       = v.ip
        hostname = "${var.cluster_name}-${k}"
      }
    }
    worker_nodes = {
      for k, v in var.worker_nodes : k => {
        ip       = v.ip
        hostname = "${var.cluster_name}-${k}"
      }
    }
    lb_ip        = var.enable_ha ? var.lb_ip : null
    ssh_user     = var.cloud_init_user
    cluster_name = var.cluster_name
  })
  filename = "${path.module}/ansible/inventory/hosts.ini"
  
  depends_on = [
    proxmox_vm_qemu.k8s_masters,
    proxmox_vm_qemu.k8s_workers,
    proxmox_vm_qemu.k8s_lb
  ]
}

# Run Ansible playbook after VM creation
resource "null_resource" "kubernetes_installation" {
  triggers = {
    cluster_instance_ids = join(",", concat(
      [for k, v in proxmox_vm_qemu.k8s_masters : v.vmid],
      [for k, v in proxmox_vm_qemu.k8s_workers : v.vmid]
    ))
    kubernetes_version = var.kubernetes_version
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/ansible
      
      # Wait for all VMs to have cloud-init complete
      echo "Waiting for cloud-init to complete on all nodes..."
      for ip in ${join(" ", concat(
        [for k, v in var.master_nodes : v.ip],
        [for k, v in var.worker_nodes : v.ip]
      ))}; do
        echo "Checking $ip..."
        timeout 600 bash -c 'until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.cloud_init_user}@'$ip' "cloud-init status --wait" 2>/dev/null; do sleep 10; done'
        if [ $? -ne 0 ]; then
          echo "ERROR: Cloud-init did not complete on $ip within 10 minutes"
          exit 1
        fi
        echo "Cloud-init completed on $ip"
      done
      
      ansible-playbook -i inventory/hosts.ini \
        -e kubernetes_version=${var.kubernetes_version} \
        -e pod_network_cidr=${var.pod_network_cidr} \
        -e service_cidr=${var.service_cidr} \
        -e cluster_name=${var.cluster_name} \
        playbooks/k8s-cluster.yml
    EOT
    
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
  
  depends_on = [
    local_file.ansible_inventory,
    proxmox_vm_qemu.k8s_masters,
    proxmox_vm_qemu.k8s_workers
  ]
}

# Retrieve kubeconfig
resource "null_resource" "fetch_kubeconfig" {
  triggers = {
    cluster_id = null_resource.kubernetes_installation.id
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      
      mkdir -p ${path.module}/kubeconfig
      
      echo "Waiting for Kubernetes API to be ready..."
      timeout 300 bash -c 'until kubectl --kubeconfig=/dev/null get --raw /healthz &>/dev/null; do sleep 5; done' || true
      
      echo "Fetching kubeconfig..."
      scp -o StrictHostKeyChecking=no \
        ${var.cloud_init_user}@${values(var.master_nodes)[0].ip}:~/.kube/config \
        ${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Update server address if using load balancer
      if [ "${var.enable_ha}" = "true" ]; then
        sed -i 's|server: https://.*:${local.k8s_api_port}|server: https://${var.lb_ip}:${local.k8s_api_port}|' \
          ${path.module}/kubeconfig/${var.cluster_name}.conf
      fi
      
      # Set proper permissions
      chmod 600 ${path.module}/kubeconfig/${var.cluster_name}.conf
      
      echo "Kubeconfig saved to: ${path.module}/kubeconfig/${var.cluster_name}.conf"
    EOT
  }
  
  depends_on = [null_resource.kubernetes_installation]
}
```

#### Ansible Inventory Template

Create `templates/inventory.tpl`:

```ini
[k8s_masters]
%{ for k, v in master_nodes ~}
${v.hostname} ansible_host=${v.ip} ansible_user=${ssh_user}
%{ endfor ~}

[k8s_workers]
%{ for k, v in worker_nodes ~}
${v.hostname} ansible_host=${v.ip} ansible_user=${ssh_user}
%{ endfor ~}

%{ if lb_ip != null ~}
[k8s_loadbalancer]
${cluster_name}-lb ansible_host=${lb_ip} ansible_user=${ssh_user}
%{ endif ~}

[k8s_cluster:children]
k8s_masters
k8s_workers

[k8s_all:children]
k8s_cluster
%{ if lb_ip != null ~}
k8s_loadbalancer
%{ endif ~}

[k8s_all:vars]
ansible_python_interpreter=/usr/bin/python3
```

#### Ansible Playbook

Create `ansible/playbooks/k8s-cluster.yml`:

```yaml
---
- name: Initialize Kubernetes Cluster
  hosts: k8s_masters[0]
  become: yes
  tasks:
    - name: Initialize first master node
      shell: |
        kubeadm init \
          --apiserver-advertise-address={{ ansible_host }} \
          --pod-network-cidr={{ pod_network_cidr }} \
          --service-cidr={{ service_cidr }} \
          --control-plane-endpoint={{ groups['k8s_loadbalancer'][0] if groups['k8s_loadbalancer'] is defined else ansible_host }}:6443 \
          --upload-certs
      args:
        creates: /etc/kubernetes/admin.conf
      register: kubeadm_init
    
    - name: Create .kube directory
      file:
        path: /home/{{ ansible_user }}/.kube
        state: directory
        owner: "{{ ansible_user }}"
        group: "{{ ansible_user }}"
    
    - name: Copy admin.conf to user's kube config
      copy:
        src: /etc/kubernetes/admin.conf
        dest: /home/{{ ansible_user }}/.kube/config
        remote_src: yes
        owner: "{{ ansible_user }}"
        group: "{{ ansible_user }}"
    
    - name: Install Calico network plugin
      become_user: "{{ ansible_user }}"
      shell: |
        kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
      args:
        creates: /tmp/calico-installed
    
    - name: Get join command
      shell: kubeadm token create --print-join-command
      register: join_command
    
    - name: Get certificate key for control plane
      shell: kubeadm init phase upload-certs --upload-certs | tail -1
      register: certificate_key
    
    - name: Save join commands
      set_fact:
        worker_join_command: "{{ join_command.stdout }}"
        master_join_command: "{{ join_command.stdout }} --control-plane --certificate-key {{ certificate_key.stdout }}"

- name: Join additional master nodes
  hosts: k8s_masters[1:]
  become: yes
  tasks:
    - name: Join master node to cluster
      shell: "{{ hostvars[groups['k8s_masters'][0]]['master_join_command'] }}"
      args:
        creates: /etc/kubernetes/kubelet.conf

- name: Join worker nodes
  hosts: k8s_workers
  become: yes
  tasks:
    - name: Join worker node to cluster
      shell: "{{ hostvars[groups['k8s_masters'][0]]['worker_join_command'] }}"
      args:
        creates: /etc/kubernetes/kubelet.conf

- name: Install core cluster components
  hosts: k8s_masters[0]
  become_user: "{{ ansible_user }}"
  tasks:
    - name: Install MetalLB for LoadBalancer services
      shell: |
        kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
      args:
        creates: /tmp/metallb-installed
    
    - name: Configure MetalLB IP pool
      shell: |
        kubectl apply -f - <<EOF
        apiVersion: metallb.io/v1beta1
        kind: IPAddressPool
        metadata:
          name: default-pool
          namespace: metallb-system
        spec:
          addresses:
          - 192.168.100.50-192.168.100.99
        ---
        apiVersion: metallb.io/v1beta1
        kind: L2Advertisement
        metadata:
          name: default-l2
          namespace: metallb-system
        EOF
    
    - name: Install metrics-server
      shell: |
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

#### Add Required Variables

```hcl
variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to install"
  default     = "1.28.3"
}

variable "pod_network_cidr" {
  type        = string
  description = "Pod network CIDR for CNI"
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = "Service network CIDR"
  default     = "10.96.0.0/12"
}

variable "install_kubernetes" {
  type        = bool
  description = "Automatically install Kubernetes after VM provisioning"
  default     = true
}
```

---

## Packer Template Creation

Automate VM template creation with Packer for consistent, pre-configured images.

### Packer Configuration

Create `packer/debian-k8s-template.pkr.hcl`:

```hcl
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "kubernetes_version" {
  type    = string
  default = "1.28.3"
}

variable "containerd_version" {
  type    = string
  default = "1.7.11"
}

source "proxmox-iso" "debian-k8s" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true
  
  node                 = var.proxmox_node
  vm_id                = 9000
  vm_name              = "debian12-k8s-template"
  template_description = "Debian 12 with Kubernetes ${var.kubernetes_version} prerequisites"
  
  iso_file         = "local:iso/debian-12.4.0-amd64-netinst.iso"
  iso_storage_pool = "local"
  unmount_iso      = true
  
  qemu_agent = true
  
  scsi_controller = "virtio-scsi-single"
  
  disks {
    disk_size         = "20G"
    storage_pool      = "local-lvm"
    type              = "scsi"
    cache_mode        = "writethrough"
    io_thread         = true
  }
  
  cores   = 2
  memory  = 4096
  
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"
  
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    "<enter>"
  ]
  
  boot_wait = "10s"
  
  http_directory = "packer/http"
  
  ssh_username = "packer"
  ssh_password = "packer"
  ssh_timeout  = "30m"
}

build {
  sources = ["source.proxmox-iso.debian-k8s"]
  
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent cloud-init",
      "sudo systemctl enable qemu-guest-agent",
    ]
  }
  
  provisioner "file" {
    source      = "packer/scripts/k8s-prep.sh"
    destination = "/tmp/k8s-prep.sh"
  }
  
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/k8s-prep.sh",
      "sudo /tmp/k8s-prep.sh ${var.kubernetes_version} ${var.containerd_version}",
    ]
  }
  
  provisioner "shell" {
    inline = [
      "sudo cloud-init clean --logs",
      "sudo rm -rf /var/lib/cloud/instances/*",
      "sudo rm -rf /tmp/*",
      "sudo rm -f /etc/machine-id",
      "sudo touch /etc/machine-id",
      "history -c"
    ]
  }
}
```

### Kubernetes Preparation Script

Create `packer/scripts/k8s-prep.sh`:

```bash
#!/bin/bash
# Kubernetes Node Preparation Script
# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Trap errors and report line number
trap 'echo "Error on line $LINENO. Exit code: $?" >&2' ERR

K8S_VERSION=${1:-"1.28.3"}
CONTAINERD_VERSION=${2:-"1.7.11"}

echo "=== Installing Kubernetes prerequisites ==="
echo "Kubernetes version: ${K8S_VERSION}"
echo "Containerd version: ${CONTAINERD_VERSION}"

# Disable swap
echo "Disabling swap..."
swapoff -a || { echo "Failed to disable swap" >&2; exit 1; }
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
echo "Loading kernel modules..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay || { echo "Failed to load overlay module" >&2; exit 1; }
modprobe br_netfilter || { echo "Failed to load br_netfilter module" >&2; exit 1; }

# Set sysctl parameters
echo "Configuring sysctl parameters..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.forwarding        = 1
vm.overcommit_memory                = 1
kernel.panic                        = 10
kernel.panic_on_oops                = 1
EOF

sysctl --system || { echo "Failed to apply sysctl parameters" >&2; exit 1; }

echo "=== Installing containerd ==="

# Install dependencies
apt-get update || { echo "Failed to update package list" >&2; exit 1; }
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release || {
  echo "Failed to install dependencies" >&2
  exit 1
}

# Add Docker repository
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || {
  echo "Failed to add Docker GPG key" >&2
  exit 1
}

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install containerd
apt-get update || { echo "Failed to update package list" >&2; exit 1; }
apt-get install -y containerd.io || { echo "Failed to install containerd" >&2; exit 1; }

# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd || { echo "Failed to restart containerd" >&2; exit 1; }
systemctl enable containerd || { echo "Failed to enable containerd" >&2; exit 1; }

echo "=== Installing Kubernetes components ==="

# Add Kubernetes repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION%.*}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || {
  echo "Failed to add Kubernetes GPG key" >&2
  exit 1
}

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION%.*}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

# Install kubeadm, kubelet, kubectl
apt-get update || { echo "Failed to update package list" >&2; exit 1; }
apt-get install -y kubelet kubeadm kubectl || {
  echo "Failed to install Kubernetes components" >&2
  exit 1
}

apt-mark hold kubelet kubeadm kubectl || {
  echo "Failed to hold Kubernetes packages" >&2
  exit 1
}

systemctl enable kubelet || { echo "Failed to enable kubelet" >&2; exit 1; }

echo "=== Installing monitoring tools ==="

# Install Prometheus Node Exporter
NODE_EXPORTER_VERSION="1.7.0"
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" || {
  echo "Failed to download node_exporter" >&2
  exit 1
}

tar xvfz "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/

if ! id -u node_exporter > /dev/null 2>&1; then
  useradd -rs /bin/false node_exporter
fi

chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat <<EOF | tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter || { echo "Failed to enable node_exporter" >&2; exit 1; }

# Cleanup
rm -rf "node_exporter-${NODE_EXPORTER_VERSION}"*

echo "=== Kubernetes prerequisites installation complete ==="
echo "Installed versions:"
kubelet --version
kubeadm version
kubectl version --client
```

### Debian Preseed File

Create `packer/http/preseed.cfg`:

```text
d-i debian-installer/locale string en_US
d-i keyboard-configuration/xkb-keymap select us
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string debian-k8s
d-i netcfg/get_domain string local
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string
d-i passwd/user-fullname string Packer
d-i passwd/username string packer
d-i passwd/user-password password packer
d-i passwd/user-password-again password packer
d-i clock-setup/utc boolean true
d-i time/zone string UTC
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string sudo qemu-guest-agent cloud-init
d-i pkgsel/upgrade select full-upgrade
d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string /dev/sda
d-i finish-install/reboot_in_progress note
d-i preseed/late_command string \
    echo 'packer ALL=(ALL) NOPASSWD: ALL' > /target/etc/sudoers.d/packer ; \
    in-target chmod 440 /etc/sudoers.d/packer
```

### Build Template

```bash
# Build Packer template
cd packer
packer init .
packer build \
  -var "proxmox_api_url=https://proxmox:8006/api2/json" \
  -var "proxmox_api_token_id=terraform-prov@pve!terraform_id" \
  -var "proxmox_api_token_secret=your-secret" \
  -var "kubernetes_version=1.28.3" \
  debian-k8s-template.pkr.hcl
```

---

## GitOps Workflow Implementation

### GitOps Repository Structure

```text
k8s-infrastructure/
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.tf
│   │   ├── staging/
│   │   └── production/
│   ├── modules/
│   └── global/
├── kubernetes/
│   ├── base/
│   │   ├── namespaces/
│   │   ├── ingress/
│   │   └── monitoring/
│   ├── overlays/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── production/
│   └── apps/
├── ansible/
│   ├── playbooks/
│   └── roles/
└── .github/
    └── workflows/
        ├── terraform-plan.yml
        ├── terraform-apply.yml
        └── argocd-sync.yml
```

### GitHub Actions Terraform Workflow

Create `.github/workflows/terraform-plan.yml`:

```yaml
name: Terraform Plan

on:
  pull_request:
    branches: [main]
    paths:
      - 'terraform/**'

env:
  TF_VERSION: '1.6.0'

jobs:
  plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, production]
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        working-directory: terraform
      
      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/${{ matrix.environment }}
        env:
          TF_VAR_proxmox_api_token_secret: ${{ secrets.PROXMOX_API_TOKEN }}
      
      - name: Terraform Validate
        run: terraform validate
        working-directory: terraform/environments/${{ matrix.environment }}
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: terraform/environments/${{ matrix.environment }}
        env:
          TF_VAR_proxmox_api_token_secret: ${{ secrets.PROXMOX_API_TOKEN }}
      
      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: ${{ matrix.environment }}-tfplan
          path: terraform/environments/${{ matrix.environment }}/tfplan
```

Create `.github/workflows/terraform-apply.yml`:

```yaml
name: Terraform Apply

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - staging
          - production

jobs:
  apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'dev' }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      
      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/${{ github.event.inputs.environment || 'dev' }}
        env:
          TF_VAR_proxmox_api_token_secret: ${{ secrets.PROXMOX_API_TOKEN }}
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: terraform/environments/${{ github.event.inputs.environment || 'dev' }}
        env:
          TF_VAR_proxmox_api_token_secret: ${{ secrets.PROXMOX_API_TOKEN }}
      
      - name: Output Kubeconfig
        run: terraform output -raw kubeconfig > kubeconfig.yaml
        working-directory: terraform/environments/${{ github.event.inputs.environment || 'dev' }}
      
      - name: Upload Kubeconfig
        uses: actions/upload-artifact@v3
        with:
          name: kubeconfig-${{ github.event.inputs.environment || 'dev' }}
          path: kubeconfig.yaml
```

### ArgoCD Integration

Install ArgoCD on the cluster and configure GitOps:

```hcl
# Add to main.tf
resource "null_resource" "install_argocd" {
  count = var.enable_gitops ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Install ArgoCD
      kubectl create namespace argocd || true
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      
      # Wait for ArgoCD to be ready
      kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
      
      # Get initial admin password
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ${path.module}/argocd-password.txt
      
      # Configure ArgoCD to use Git repository
      kubectl apply -f - <<EOF
      apiVersion: v1
      kind: Secret
      metadata:
        name: repo-${var.git_repo_name}
        namespace: argocd
        labels:
          argocd.argoproj.io/secret-type: repository
      stringData:
        type: git
        url: ${var.git_repo_url}
        password: ${var.git_token}
        username: ${var.git_username}
      EOF
    EOT
  }
  
  depends_on = [null_resource.fetch_kubeconfig]
}

# Create ArgoCD Application
resource "null_resource" "argocd_apps" {
  count = var.enable_gitops ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      kubectl apply -f - <<EOF
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: ${var.cluster_name}-apps
        namespace: argocd
      spec:
        project: default
        source:
          repoURL: ${var.git_repo_url}
          targetRevision: HEAD
          path: kubernetes/overlays/${var.environment}
        destination:
          server: https://kubernetes.default.svc
          namespace: default
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=true
      EOF
    EOT
  }
  
  depends_on = [null_resource.install_argocd]
}
```

Add GitOps variables:

```hcl
variable "enable_gitops" {
  type        = bool
  description = "Enable GitOps with ArgoCD"
  default     = false
}

variable "git_repo_url" {
  type        = string
  description = "Git repository URL for GitOps"
  default     = ""
}

variable "git_repo_name" {
  type        = string
  description = "Git repository name"
  default     = "k8s-infrastructure"
}

variable "git_token" {
  type        = string
  description = "Git access token"
  sensitive   = true
  default     = ""
}

variable "git_username" {
  type        = string
  description = "Git username"
  default     = "git"
}
```

---

## Comprehensive Testing

### Unit Tests with Terratest

Create `test/terraform_test.go`:

```go
package test

import (
    "testing"
    "time"
    
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/retry"
    "github.com/stretchr/testify/assert"
)

func TestTerraformProxmoxCluster(t *testing.T) {
    t.Parallel()
    
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../terraform",
        
        Vars: map[string]interface{}{
            "cluster_name": "test-cluster",
            "master_nodes": map[string]interface{}{
                "master-01": map[string]interface{}{
                    "vmid":   501,
                    "ip":     "192.168.100.50",
                    "cores":  2,
                    "memory": 4096,
                    "disk":   "20G",
                },
            },
            "worker_nodes": map[string]interface{}{
                "worker-01": map[string]interface{}{
                    "vmid":   601,
                    "ip":     "192.168.100.60",
                    "cores":  2,
                    "memory": 4096,
                    "disk":   "20G",
                },
            },
        },
        
        EnvVars: map[string]string{
            "TF_VAR_proxmox_api_token_secret": "<YOUR_TOKEN>",
        },
    })
    
    defer terraform.Destroy(t, terraformOptions)
    
    terraform.InitAndApply(t, terraformOptions)
    
    // Validate outputs
    masterNodes := terraform.OutputMap(t, terraformOptions, "master_nodes")
    assert.NotEmpty(t, masterNodes)
    assert.Equal(t, "192.168.100.50", masterNodes["master-01"].(map[string]interface{})["ip"])
    
    workerNodes := terraform.OutputMap(t, terraformOptions, "worker_nodes")
    assert.NotEmpty(t, workerNodes)
    
    // Test SSH connectivity
    masterIP := masterNodes["master-01"].(map[string]interface{})["ip"].(string)
    testSSHConnection(t, masterIP)
}

func testSSHConnection(t *testing.T, ip string) {
    maxRetries := 30
    timeBetweenRetries := 10 * time.Second
    
    retry.DoWithRetry(t, "SSH to VM", maxRetries, timeBetweenRetries, func() (string, error) {
        // SSH connection test logic
        return "", nil
    })
}
```

### Integration Tests

Create `test/integration_test.go`:

```go
package test

import (
    "testing"
    
    "github.com/gruntwork-io/terratest/modules/k8s"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestKubernetesClusterHealth(t *testing.T) {
    t.Parallel()
    
    terraformOptions := &terraform.Options{
        TerraformDir: "../terraform",
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    // Get kubeconfig
    kubeconfig := terraform.Output(t, terraformOptions, "kubeconfig_path")
    
    options := k8s.NewKubectlOptions("", kubeconfig, "default")
    
    // Test: All nodes should be Ready
    nodes := k8s.GetNodes(t, options)
    for _, node := range nodes {
        assert.True(t, k8s.IsNodeReady(node))
    }
    
    // Test: Core components should be running
    coreComponents := []string{
        "kube-apiserver",
        "kube-controller-manager",
        "kube-scheduler",
        "etcd",
    }
    
    for _, component := range coreComponents {
        pods := k8s.ListPods(t, options, metav1.ListOptions{
            LabelSelector: "component=" + component,
        })
        assert.NotEmpty(t, pods)
    }
    
    // Test: DNS should be working
    k8s.RunKubectl(t, options, "run", "test-dns",
        "--image=busybox:1.28",
        "--restart=Never",
        "--",
        "nslookup", "kubernetes.default")
    
    k8s.WaitUntilPodAvailable(t, options, "test-dns", 10, 3*time.Second)
}
```

### Security Scanning with tfsec

Add to CI/CD pipeline:

```yaml
- name: Run tfsec
  uses: aquasecurity/tfsec-action@v1.0.0
  with:
    working_directory: terraform
    soft_fail: false
    format: sarif
    output: tfsec-results.sarif

- name: Upload SARIF file
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: tfsec-results.sarif
```

### Policy as Code with OPA

Create `policies/terraform.rego`:

```rego
package terraform.policies

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "proxmox_vm_qemu"
    resource.change.after.memory < 4096
    msg = sprintf("VM %v has insufficient memory: %v MB (minimum 4096 MB)", [resource.address, resource.change.after.memory])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "proxmox_vm_qemu"
    not resource.change.after.agent
    msg = sprintf("VM %v must have QEMU agent enabled", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "proxmox_vm_qemu"
    contains(resource.change.after.tags, "production")
    not resource.change.after.automatic_reboot
    msg = sprintf("Production VM %v must have automatic_reboot enabled", [resource.address])
}
```

Test with OPA:

```bash
# Generate plan in JSON
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

# Test against policies
opa exec --decision terraform/policies/deny --bundle policies/ tfplan.json
```

---

## Production-Grade Examples

### Enterprise Production Cluster

Complete production configuration in `environments/production/main.tf`:

```hcl
module "production_cluster" {
  source = "../../modules/k8s-cluster"
  
  # Core configuration
  cluster_name    = "prod-k8s"
  environment     = "production"
  proxmox_api_url = var.proxmox_api_url
  target_node     = "pve-prod"
  
  # High-availability configuration
  enable_ha         = true
  enable_monitoring = true
  enable_gitops     = true
  enable_backup     = true
  
  # Network configuration
  cluster_network = {
    subnet  = "10.100.0.0/24"
    gateway = "10.100.0.1"
    dns     = ["10.100.0.2", "10.100.0.3"]  # Internal DNS
  }
  
  lb_ip = "10.100.0.10"
  
  # Master nodes - 3 for HA
  master_nodes = {
    "master-01" = {
      vmid   = 1001
      ip     = "10.100.0.11"
      cores  = 4
      memory = 16384
      disk   = "100G"
    }
    "master-02" = {
      vmid   = 1002
      ip     = "10.100.0.12"
      cores  = 4
      memory = 16384
      disk   = "100G"
    }
    "master-03" = {
      vmid   = 1003
      ip     = "10.100.0.13"
      cores  = 4
      memory = 16384
      disk   = "100G"
    }
  }
  
  # Worker nodes - scalable pool
  worker_nodes = {
    "worker-01" = {
      vmid   = 2001
      ip     = "10.100.0.21"
      cores  = 8
      memory = 32768
      disk   = "200G"
    }
    "worker-02" = {
      vmid   = 2002
      ip     = "10.100.0.22"
      cores  = 8
      memory = 32768
      disk   = "200G"
    }
    "worker-03" = {
      vmid   = 2003
      ip     = "10.100.0.23"
      cores  = 8
      memory = 32768
      disk   = "200G"
    }
    "worker-04" = {
      vmid   = 2004
      ip     = "10.100.0.24"
      cores  = 8
      memory = 32768
      disk   = "200G"
    }
    "worker-05" = {
      vmid   = 2005
      ip     = "10.100.0.25"
      cores  = 8
      memory = 32768
      disk   = "200G"
    }
  }
  
  # Storage configuration
  storage          = "nvme-pool"  # High-performance storage
  template_name    = "debian12-k8s-prod-template"
  
  # Kubernetes configuration
  kubernetes_version = "1.28.3"
  pod_network_cidr   = "10.244.0.0/16"
  service_cidr       = "10.96.0.0/12"
  
  # Security
  ssh_public_key  = file("~/.ssh/prod-k8s.pub")
  cloud_init_user = "k8s-admin"
  
  # GitOps
  git_repo_url  = "https://github.com/yourorg/k8s-infrastructure.git"
  git_repo_name = "k8s-infrastructure"
  git_username  = "argocd"
  git_token     = var.git_token
  
  # Monitoring and logging
  prometheus_retention   = "30d"
  enable_elasticsearch   = true
  enable_grafana        = true
  enable_alertmanager   = true
  
  # Backup configuration
  backup_schedule       = "0 2 * * *"  # Daily at 2 AM
  backup_retention_days = 30
  backup_storage        = "backup-pool"
  
  # Resource tagging
  tags = {
    Environment  = "production"
    Project      = "kubernetes"
    ManagedBy    = "terraform"
    CostCenter   = "engineering"
    Compliance   = "pci-dss"
    Owner        = "platform-team"
    Backup       = "daily"
  }
}
```

### Disaster Recovery Configuration

Add to production cluster:

```hcl
# Automated etcd backup
resource "null_resource" "etcd_backup_cron" {
  count = var.enable_backup ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      kubectl apply -f - <<EOF
      apiVersion: batch/v1
      kind: CronJob
      metadata:
        name: etcd-backup
        namespace: kube-system
      spec:
        schedule: "${var.backup_schedule}"
        jobTemplate:
          spec:
            template:
              spec:
                containers:
                - name: backup
                  image: bitnami/etcd:latest
                  command:
                  - /bin/sh
                  - -c
                  - |
                    ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot-\$(date +%Y%m%d-%H%M%S).db \
                      --endpoints=https://127.0.0.1:2379 \
                      --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                      --cert=/etc/kubernetes/pki/etcd/server.crt \
                      --key=/etc/kubernetes/pki/etcd/server.key
                    
                    # Upload to backup storage
                    rclone copy /backup/ proxmox-backup:etcd-backups/${var.cluster_name}/
                    
                    # Cleanup old backups
                    find /backup/ -name "etcd-snapshot-*.db" -mtime +${var.backup_retention_days} -delete
                  volumeMounts:
                  - name: etcd-certs
                    mountPath: /etc/kubernetes/pki/etcd
                    readOnly: true
                  - name: backup
                    mountPath: /backup
                volumes:
                - name: etcd-certs
                  hostPath:
                    path: /etc/kubernetes/pki/etcd
                - name: backup
                  hostPath:
                    path: /var/lib/etcd-backup
                restartPolicy: OnFailure
                hostNetwork: true
                nodeSelector:
                  node-role.kubernetes.io/control-plane: ""
                tolerations:
                - effect: NoSchedule
                  key: node-role.kubernetes.io/control-plane
      EOF
    EOT
  }
  
  depends_on = [null_resource.fetch_kubeconfig]
}
```

### Multi-Region Setup

```hcl
module "us_east_cluster" {
  source = "../../modules/k8s-cluster"
  
  cluster_name = "prod-us-east"
  region       = "us-east"
  # ... configuration ...
}

module "eu_west_cluster" {
  source = "../../modules/k8s-cluster"
  
  cluster_name = "prod-eu-west"
  region       = "eu-west"
  # ... configuration ...
}

# Cross-cluster service mesh with Istio
resource "null_resource" "multi_cluster_mesh" {
  provisioner "local-exec" {
    command = <<-EOT
      # Configure Istio multi-primary setup
      istioctl install --set values.global.meshID=prod-mesh \
        --set values.global.multiCluster.clusterName=us-east \
        --set values.global.network=network1
    EOT
  }
}
```

---

## Post-Deployment Kubernetes Setup

### Initialize Kubernetes Cluster

SSH to the first master node and initialize the cluster:

```bash
# SSH to first master node
ssh ubuntu@192.168.100.10

# Initialize Kubernetes cluster
sudo kubeadm init \
  --apiserver-advertise-address=192.168.100.10 \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --control-plane-endpoint=192.168.100.10:6443

# Set up kubectl for current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install network plugin (Flannel)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

### Join Additional Master Nodes (HA Setup)

```bash
# Generate join command for control plane nodes
kubeadm token create --print-join-command --certificate-key $(kubeadm init phase upload-certs --upload-certs | tail -1)

# SSH to additional master nodes and run join command with --control-plane flag
```

### Join Worker Nodes

```bash
# Generate join command for worker nodes
kubeadm token create --print-join-command

# SSH to each worker node and run the join command
```

### Verify Cluster Status

```bash
# Check node status
kubectl get nodes

# Check system pods
kubectl get pods -A

# Check cluster info
kubectl cluster-info
```

---

## Day-2 Operations

### Kubernetes Version Upgrades

Upgrade control plane first, then workers. Always test in non-production first.

```bash
# On first control plane node
sudo apt-mark unhold kubeadm
sudo apt-get update && sudo apt-get install -y kubeadm=1.29.0-00
sudo apt-mark hold kubeadm

kubectl drain $(hostname) --ignore-daemonsets --delete-emptydir-data
sudo kubeadm upgrade apply v1.29.0

sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.29.0-00 kubectl=1.29.0-00
sudo apt-mark hold kubelet kubectl

sudo systemctl daemon-reload && sudo systemctl restart kubelet
kubectl uncordon $(hostname)
```

### Certificate Management

Monitor and renew certificates before expiration:

```bash
# Check expiration
sudo kubeadm certs check-expiration

# Renew all certificates
sudo kubeadm certs renew all

# Restart control plane
kubectl -n kube-system delete pod -l component=kube-apiserver
```

### etcd Maintenance

Regular defragmentation reclaims disk space:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  defrag
```

---

## Management and Maintenance

### Scaling Operations

#### Add New Worker Node

1. Update `terraform.tfvars` to add new worker node:

```text
worker_nodes = {
  # ... existing workers ...
  "worker-04" = {
    vmid   = 204
    ip     = "192.168.100.23"
    cores  = 4
    memory = 8192
    disk   = "50G"
  }
}
```

1. Apply changes:

```bash
terraform plan
terraform apply
```

1. Join new node to cluster as shown above.

#### Remove Worker Node

```bash
# Drain node safely
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Delete node from cluster
kubectl delete node <node-name>

# Remove from Terraform configuration
# Update terraform.tfvars and apply
```

### Resource Updates

#### Modify VM Resources

Update node specifications in `terraform.tfvars`:

```text
master_nodes = {
  "master-01" = {
    vmid   = 101
    ip     = "192.168.100.10"
    cores  = 4  # Increased from 2
    memory = 8192  # Increased from 4096
    disk   = "30G"  # Increased from 20G
  }
}
```

**Note:** VM shutdowns required for CPU/memory changes.

### Backup and Recovery

#### Backup Strategy

Define RTO (Recovery Time Objective) and RPO (Recovery Point Objective):

- **RTO Target**: 2 hours for full cluster recovery
- **RPO Target**: Maximum 4 hours data loss for applications, 1 hour for infrastructure state

**Backup Components:**

```bash
# 1. Backup Terraform state (critical for infrastructure)
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)

# 2. Backup etcd (Kubernetes cluster state)
sudo ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup-$(date +%Y%m%d-%H%M%S).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# 3. Backup Kubernetes resources
kubectl get all --all-namespaces -o yaml > cluster-resources-$(date +%Y%m%d-%H%M%S).yaml

# 4. Backup persistent volumes data
# Use Velero or storage-specific snapshots

# 5. Backup certificates and secrets
sudo tar -czf k8s-pki-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  /etc/kubernetes/pki \
  /etc/kubernetes/admin.conf
```

#### Automated Backup Script

```bash
cat <<'EOF' > /usr/local/bin/k8s-backup.sh
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/kubernetes-backups"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting Kubernetes backup"

# Backup etcd
if ETCDCTL_API=3 etcdctl snapshot save "$BACKUP_DIR/etcd-$DATE.db" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key; then
  echo "[$(date)] etcd backup completed"
else
  echo "[$(date)] etcd backup FAILED" >&2
  exit 1
fi

# Backup all resources
kubectl get all --all-namespaces -o yaml > "$BACKUP_DIR/resources-$DATE.yaml"

# Cleanup old backups
find "$BACKUP_DIR" -name "*.db" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.yaml" -mtime +$RETENTION_DAYS -delete

echo "[$(date)] Backup completed: $BACKUP_DIR"
EOF

chmod +x /usr/local/bin/k8s-backup.sh
```

#### Recovery Procedures

##### Scenario 1: Single Node Failure

```bash
# Remove failed node from cluster
kubectl delete node <failed-node>

# Update Terraform to replace node
terraform taint proxmox_vm_qemu.k8s_workers["worker-01"]
terraform apply

# Node will automatically join cluster via cloud-init/Ansible
```

##### Scenario 2: Control Plane Failure (HA)

```bash
# If one master fails, cluster continues operating
# Remove failed master
kubectl delete node <failed-master>

# Recreate master with Terraform
terraform taint proxmox_vm_qemu.k8s_masters["master-02"]
terraform apply

# Join new master to cluster
kubeadm join <lb-ip>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane --certificate-key <key>
```

##### Scenario 3: Complete etcd Restore

```bash
# Stop all control plane components
sudo systemctl stop kubelet

# Restore etcd snapshot
sudo ETCDCTL_API=3 etcdctl snapshot restore /opt/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore \
  --name=$(hostname) \
  --initial-cluster=master-01=https://192.168.100.10:2380,master-02=https://192.168.100.11:2380,master-03=https://192.168.100.12:2380 \
  --initial-advertise-peer-urls=https://192.168.100.10:2380

# Update etcd data directory
sudo rm -rf /var/lib/etcd
sudo mv /var/lib/etcd-restore /var/lib/etcd

# Start kubelet
sudo systemctl start kubelet

# Verify cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

##### Scenario 4: Complete Cluster Rebuild

```bash
# 1. Restore Terraform state
cp terraform.tfstate.backup terraform.tfstate

# 2. Rebuild infrastructure
terraform apply

# 3. Restore etcd on first master (see Scenario 3)

# 4. Restore application data from persistent volume backups

# 5. Verify all services
kubectl get all --all-namespaces
```

#### Disaster Recovery Testing

Test DR procedures quarterly:

```bash
# DR Test Checklist
cat <<'EOF' > dr-test-checklist.md
# Disaster Recovery Test

## Pre-Test
- [ ] Notify team of DR test
- [ ] Document current cluster state
- [ ] Verify backups are available
- [ ] Prepare test environment

## Test Execution
- [ ] Simulate failure (controlled)
- [ ] Measure detection time
- [ ] Execute recovery procedures
- [ ] Measure recovery time
- [ ] Verify all services restored
- [ ] Check data integrity

## Post-Test
- [ ] Document actual RTO achieved
- [ ] Document actual RPO achieved
- [ ] Identify improvement areas
- [ ] Update runbooks
- [ ] Share lessons learned

## Metrics
- Detection Time: ___ minutes
- Recovery Time: ___ minutes
- Data Loss: ___ (transactions/records)
- Success Rate: ____%
EOF
```

---

## Troubleshooting

### Common Issues

#### VM Creation Failures

```bash
# Check Proxmox logs
tail -f /var/log/pve/tasks/active

# Verify template exists
qm list | grep template

# Check storage space
pvesm status

# Verify user permissions
pveum user list
pveum acl list
```

#### Network Connectivity Issues

```bash
# Test from Terraform host
ping 192.168.100.10

# Check Proxmox network configuration
cat /etc/network/interfaces

# Verify bridge configuration
brctl show vmbr0

# Check firewall rules
iptables -L -n -v

# Test DNS resolution
nslookup kubernetes.default.svc.cluster.local 10.96.0.10
```

#### Cloud-Init Problems

```bash
# Check cloud-init logs on VM
sudo cloud-init status --long
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log

# Verify cloud-init configuration
sudo cloud-init query -all

# Regenerate cloud-init
sudo cloud-init clean --logs
sudo cloud-init init
sudo cloud-init modules --mode=config
sudo cloud-init modules --mode=final

# Check qemu-guest-agent
sudo systemctl status qemu-guest-agent
```

### Kubernetes Troubleshooting

#### Cluster Issues

```bash
# Check node status
kubectl get nodes -o wide

# Examine system pods
kubectl get pods -A --field-selector=status.phase!=Running

# Check cluster events
kubectl get events --sort-by='.lastTimestamp' -A

# View component logs
kubectl logs -n kube-system -l component=kube-apiserver
kubectl logs -n kube-system -l component=kube-controller-manager
kubectl logs -n kube-system -l component=kube-scheduler

# Check etcd health
kubectl exec -n kube-system etcd-master-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint health
```

#### Network Plugin Issues

```bash
# Check CNI pods (Calico/Flannel)
kubectl get pods -n kube-system -l k8s-app=calico-node
kubectl get pods -n kube-flannel

# Restart CNI daemonset
kubectl rollout restart daemonset/calico-node -n kube-system
# or
kubectl rollout restart daemonset/kube-flannel-ds -n kube-flannel

# Check node network configuration
ip route show
ip addr show
sysctl net.ipv4.ip_forward
```

#### Pod Scheduling Failures

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl describe nodes | grep -A 5 "Allocated resources"

# View taints and tolerations
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Check resource quotas
kubectl get resourcequota --all-namespaces
kubectl describe resourcequota -n <namespace>
```

#### Certificate Issues

```bash
# Check certificate expiration
sudo kubeadm certs check-expiration

# Verify certificate chain
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# Check API server certificate
echo | openssl s_client -connect localhost:6443 2>/dev/null | openssl x509 -noout -dates

# Renew expired certificates
sudo kubeadm certs renew all
sudo systemctl restart kubelet
```

#### etcd Issues

```bash
# Check etcd cluster members
kubectl exec -n kube-system etcd-master-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member list

# Check etcd alarms
kubectl exec -n kube-system etcd-master-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  alarm list

# Disarm space quota alarm
kubectl exec -n kube-system etcd-master-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  alarm disarm
```

#### Split-Brain Scenario

```bash
# Identify split-brain condition
kubectl get nodes
# Some nodes show NotReady with different cluster states

# Check etcd membership from each master
for master in master-01 master-02 master-03; do
  echo "=== $master ==="
  ssh ubuntu@$master "sudo ETCDCTL_API=3 etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/peer.crt \
    --key=/etc/kubernetes/pki/etcd/peer.key \
    member list"
done

# Remove stale etcd members
kubectl exec -n kube-system etcd-master-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member remove <member-id>

# Re-add healthy member
sudo kubeadm join <lb-ip>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane --certificate-key <key>
```

#### API Server Unresponsive

```bash
# Check API server process
ssh ubuntu@master-01 "ps aux | grep kube-apiserver"

# Check API server logs
ssh ubuntu@master-01 "sudo journalctl -u kubelet -f"

# Restart API server
ssh ubuntu@master-01 "sudo systemctl restart kubelet"

# Force recreate API server pod
kubectl delete pod -n kube-system kube-apiserver-master-01

# Check load balancer health (if HA)
curl -k https://192.168.100.5:8404  # HAProxy stats
```

#### Storage Issues

```bash
# Check PV status
kubectl get pv
kubectl describe pv <pv-name>

# Check PVC binding
kubectl get pvc --all-namespaces
kubectl describe pvc <pvc-name> -n <namespace>

# Check storage class
kubectl get storageclass
kubectl describe storageclass <sc-name>

# Identify pods with volume issues
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.status.phase != "Running") | 
  select(.spec.volumes != null) | 
  "\(.metadata.namespace)/\(.metadata.name)"'
```

### Terraform State Issues

```bash
# Import existing resource
terraform import proxmox_vm_qemu.k8s_masters["master-01"] <node-name>/<vmid>

# Refresh state
terraform refresh

# Remove resource from state (dangerous)
terraform state rm proxmox_vm_qemu.k8s_masters["master-01"]

# Show state
terraform state list
terraform state show proxmox_vm_qemu.k8s_masters["master-01"]

# Move resource in state
terraform state mv proxmox_vm_qemu.old_name proxmox_vm_qemu.new_name

# Recover from state corruption
terraform state pull > terraform.tfstate.backup
# Edit state file carefully
terraform state push terraform.tfstate.backup
```

### Performance Troubleshooting

#### High CPU Usage

```bash
# Identify high CPU pods
kubectl top pods --all-namespaces --sort-by=cpu

# Check node CPU
kubectl top nodes

# Analyze CPU throttling
for pod in $(kubectl get pods -A -o jsonpath='{.items[*].metadata.name}'); do
  kubectl get pod $pod -o jsonpath='{.metadata.name}{"\t"}{.spec.containers[*].resources.limits.cpu}{"\n"}'
done

# Check CPU limits vs requests
kubectl describe nodes | grep -A 10 "Allocated resources"
```

#### Memory Issues

```bash
# Check OOM killed pods
kubectl get pods --all-namespaces --field-selector=status.phase=Failed
kubectl describe pod <pod-name> | grep -A 10 "Last State"

# Check node memory pressure
kubectl describe nodes | grep MemoryPressure

# Identify memory-hungry pods
kubectl top pods --all-namespaces --sort-by=memory | head -20

# Check swap (should be disabled)
ssh ubuntu@<node-ip> "free -h"
```

#### Network Latency

```bash
# Test pod-to-pod communication
kubectl run test-pod --image=nicolaka/netshoot --rm -it -- bash
# Inside pod: ping <other-pod-ip>

# Check CNI performance
kubectl run test1 --image=nicolaka/netshoot -- sleep 3600
kubectl run test2 --image=nicolaka/netshoot -- sleep 3600
kubectl exec test1 -- iperf3 -s &
kubectl exec test2 -- iperf3 -c <test1-ip>

# Check DNS latency
kubectl run dnstest --image=tutum/dnsutils --rm -it -- bash
# Inside pod: time nslookup kubernetes.default
```

---

## Security Considerations

### Network Security

- Use private network ranges for cluster communication
- Implement firewall rules for API access
- Consider VPN for management access
- Isolate cluster network from other VLANs

### Access Control

```bash
# Create restricted Proxmox user for Terraform
pveum user add terraform-prov@pve --comment "Terraform provisioning user"
pveum aclmod /vms -user terraform-prov@pve -role PVEVMAdmin
pveum aclmod /storage -user terraform-prov@pve -role PVEDatastoreUser
```

### SSH Key Management

```bash
# Generate dedicated SSH key for cluster
ssh-keygen -t ed25519 -f ~/.ssh/k8s-cluster -C "k8s-cluster@$(hostname)"

# Use in terraform.tfvars
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... k8s-cluster@hostname"
```

### Secret Rotation Strategy

Implement regular rotation of all sensitive credentials to maintain security:

#### 1. Proxmox API Token Rotation

Rotate Proxmox API tokens every 90 days:

```bash
# Generate new API token
NEW_TOKEN_ID="terraform-prov@pve!terraform_id_$(date +%Y%m%d)"
pveum user token add terraform-prov@pve "terraform_id_$(date +%Y%m%d)" -privsep 1

# Update terraform.tfvars with new token
# Test deployment with new token
terraform plan

# After successful test, delete old token
pveum user token remove terraform-prov@pve terraform_id_old
```

**Automation with script:**

```bash
#!/bin/bash
# proxmox-token-rotation.sh
set -euo pipefail

OLD_TOKEN_NAME="${1:?Usage: $0 <old_token_name>}"
NEW_TOKEN_NAME="terraform_id_$(date +%Y%m%d)"
USER="terraform-prov@pve"

echo "Creating new token: $NEW_TOKEN_NAME"
pveum user token add "$USER" "$NEW_TOKEN_NAME" -privsep 1

echo "Update your terraform.tfvars with the new token:"
echo "proxmox_api_token_id = \"$USER!$NEW_TOKEN_NAME\""
echo ""
echo "After testing, delete old token with:"
echo "pveum user token remove $USER $OLD_TOKEN_NAME"
```

#### 2. SSH Key Rotation

Rotate SSH keys every 6 months:

```bash
# Generate new SSH key pair
ssh-keygen -t ed25519 -f ~/.ssh/k8s-cluster-new -C "k8s-cluster-$(date +%Y%m%d)"

# Add new key to all nodes
for node_ip in 192.168.100.10 192.168.100.11 192.168.100.12 192.168.100.20 192.168.100.21 192.168.100.22; do
  echo "Adding new key to $node_ip"
  ssh-copy-id -i ~/.ssh/k8s-cluster-new.pub ubuntu@$node_ip
done

# Test new key access
for node_ip in 192.168.100.10 192.168.100.11 192.168.100.12 192.168.100.20 192.168.100.21 192.168.100.22; do
  ssh -i ~/.ssh/k8s-cluster-new -o PasswordAuthentication=no ubuntu@$node_ip "echo 'Connection successful to $node_ip'"
done

# Update terraform.tfvars
# ssh_public_key = file("~/.ssh/k8s-cluster-new.pub")

# Remove old keys from nodes after verification
for node_ip in 192.168.100.10 192.168.100.11 192.168.100.12 192.168.100.20 192.168.100.21 192.168.100.22; do
  ssh -i ~/.ssh/k8s-cluster-new ubuntu@$node_ip "sed -i '/k8s-cluster@/d' ~/.ssh/authorized_keys"
done
```

#### 3. Kubernetes Certificate Rotation

Kubernetes certificates expire after 1 year by default. Rotate before expiration:

```bash
# Check certificate expiration
kubeadm certs check-expiration

# Renew all certificates
kubeadm certs renew all

# Restart control plane components
kubectl -n kube-system delete pod -l component=kube-apiserver
kubectl -n kube-system delete pod -l component=kube-controller-manager
kubectl -n kube-system delete pod -l component=kube-scheduler

# Update kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

**Automated certificate renewal:**

```bash
# Add to crontab on master nodes: 0 2 1 * * /usr/local/bin/k8s-cert-renew.sh
cat <<'EOF' | sudo tee /usr/local/bin/k8s-cert-renew.sh
#!/bin/bash
set -euo pipefail

LOGFILE="/var/log/k8s-cert-renewal.log"

echo "[$(date)] Starting certificate renewal" >> "$LOGFILE"

if kubeadm certs renew all >> "$LOGFILE" 2>&1; then
  echo "[$(date)] Certificate renewal successful" >> "$LOGFILE"
  
  # Restart control plane
  kubectl -n kube-system delete pod -l component=kube-apiserver --grace-period=30
  kubectl -n kube-system delete pod -l component=kube-controller-manager --grace-period=30
  kubectl -n kube-system delete pod -l component=kube-scheduler --grace-period=30
  
  echo "[$(date)] Control plane restarted" >> "$LOGFILE"
else
  echo "[$(date)] Certificate renewal failed!" >> "$LOGFILE"
  exit 1
fi
EOF

sudo chmod +x /usr/local/bin/k8s-cert-renew.sh
```

#### 4. Secrets Management Best Practices

**Use External Secret Management:**

```hcl
# Example: HashiCorp Vault integration
variable "vault_addr" {
  type        = string
  description = "Vault server address"
  default     = "https://vault.example.com:8200"
}

data "vault_generic_secret" "proxmox_credentials" {
  path = "secret/proxmox/terraform"
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = data.vault_generic_secret.proxmox_credentials.data["token_id"]
  pm_api_token_secret = data.vault_generic_secret.proxmox_credentials.data["token_secret"]
  pm_tls_insecure     = false
}
```

**Kubernetes Secrets with External Secrets Operator:**

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: proxmox-credentials
  namespace: terraform
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: proxmox-credentials
    creationPolicy: Owner
  data:
    - secretKey: api_token_id
      remoteRef:
        key: secret/proxmox/terraform
        property: token_id
    - secretKey: api_token_secret
      remoteRef:
        key: secret/proxmox/terraform
        property: token_secret
```

#### 5. Rotation Schedule

Implement this rotation schedule:

| Secret Type            | Rotation Frequency | Priority |
| ---------------------- | ------------------ | -------- |
| Proxmox API Tokens     | 90 days            | High     |
| SSH Keys               | 180 days           | High     |
| Kubernetes Certificates| 365 days (auto)    | Critical |
| Database Passwords     | 90 days            | High     |
| Service Account Tokens | 30 days            | Medium   |
| TLS Certificates       | Before expiration  | Critical |

**Create rotation reminders:**

```bash
# Add to main.tf
resource "time_rotating" "proxmox_token_rotation" {
  rotation_days = 90
}

resource "time_rotating" "ssh_key_rotation" {
  rotation_days = 180
}

# Output warnings when rotation is needed
output "security_warnings" {
  value = {
    proxmox_token_rotated = time_rotating.proxmox_token_rotation.rfc3339
    ssh_key_rotated      = time_rotating.ssh_key_rotation.rfc3339
    rotation_due_days    = {
      proxmox_token = max(0, 90 - parseint(formatdate("DD", timestamp()), 10))
      ssh_key       = max(0, 180 - parseint(formatdate("DD", timestamp()), 10))
    }
  }
}
```

### Kubernetes Security

- Enable RBAC (default in modern Kubernetes)
- Use network policies for pod communication
- Implement admission controllers (PSP/PSA/OPA)
- Regular security updates and patching
- Enable audit logging
- Use pod security standards
- Implement image scanning with Trivy or Clair

---

## Cost Estimation and Capacity Planning

### Resource Cost Calculator

Estimate infrastructure costs based on node configuration:

```bash
cat <<'EOF' > cost-calculator.sh
#!/bin/bash
# Kubernetes Cluster Cost Estimator for Proxmox

# Proxmox host specifications
TOTAL_CPU_CORES=64
TOTAL_RAM_GB=256
TOTAL_STORAGE_TB=4

# Cost assumptions (adjust for your region/provider)
COST_PER_CORE_MONTHLY=5.00
COST_PER_GB_RAM_MONTHLY=2.00
COST_PER_GB_STORAGE_MONTHLY=0.10
POWER_COST_PER_KWH=0.12
WATTS_PER_CORE=10
HOURS_PER_MONTH=730

# Cluster configuration
MASTER_COUNT=3
MASTER_CORES=2
MASTER_RAM_GB=4
MASTER_DISK_GB=20

WORKER_COUNT=3
WORKER_CORES=4
WORKER_RAM_GB=8
WORKER_DISK_GB=50

# Calculate resources
TOTAL_CLUSTER_CORES=$((MASTER_COUNT * MASTER_CORES + WORKER_COUNT * WORKER_CORES))
TOTAL_CLUSTER_RAM=$((MASTER_COUNT * MASTER_RAM_GB + WORKER_COUNT * WORKER_RAM_GB))
TOTAL_CLUSTER_STORAGE=$((MASTER_COUNT * MASTER_DISK_GB + WORKER_COUNT * WORKER_DISK_GB))

# Calculate costs
COMPUTE_COST=$(echo "$TOTAL_CLUSTER_CORES * $COST_PER_CORE_MONTHLY" | bc)
MEMORY_COST=$(echo "$TOTAL_CLUSTER_RAM * $COST_PER_GB_RAM_MONTHLY" | bc)
STORAGE_COST=$(echo "$TOTAL_CLUSTER_STORAGE * $COST_PER_GB_STORAGE_MONTHLY" | bc)
POWER_COST=$(echo "$TOTAL_CLUSTER_CORES * $WATTS_PER_CORE * $HOURS_PER_MONTH * $POWER_COST_PER_KWH / 1000" | bc)

TOTAL_MONTHLY_COST=$(echo "$COMPUTE_COST + $MEMORY_COST + $STORAGE_COST + $POWER_COST" | bc)
TOTAL_YEARLY_COST=$(echo "$TOTAL_MONTHLY_COST * 12" | bc)

# Calculate utilization
CPU_UTILIZATION=$(echo "scale=2; $TOTAL_CLUSTER_CORES / $TOTAL_CPU_CORES * 100" | bc)
RAM_UTILIZATION=$(echo "scale=2; $TOTAL_CLUSTER_RAM / $TOTAL_RAM_GB * 100" | bc)
STORAGE_UTILIZATION=$(echo "scale=2; $TOTAL_CLUSTER_STORAGE / ($TOTAL_STORAGE_TB * 1024) * 100" | bc)

# Display results
cat <<REPORT
=== Kubernetes Cluster Cost Estimation ===

Cluster Configuration:
  Masters: $MASTER_COUNT × ${MASTER_CORES}C/${MASTER_RAM_GB}GB/${MASTER_DISK_GB}GB
  Workers: $WORKER_COUNT × ${WORKER_CORES}C/${WORKER_RAM_GB}GB/${WORKER_DISK_GB}GB
  
  Total Cores: $TOTAL_CLUSTER_CORES
  Total RAM: ${TOTAL_CLUSTER_RAM}GB
  Total Storage: ${TOTAL_CLUSTER_STORAGE}GB

Monthly Costs:
  Compute: \$${COMPUTE_COST}
  Memory: \$${MEMORY_COST}
  Storage: \$${STORAGE_COST}
  Power: \$${POWER_COST}
  ─────────────────
  Total: \$${TOTAL_MONTHLY_COST}

Annual Cost: \$${TOTAL_YEARLY_COST}

Resource Utilization:
  CPU: ${CPU_UTILIZATION}%
  RAM: ${RAM_UTILIZATION}%
  Storage: ${STORAGE_UTILIZATION}%

Cost per Node: \$$(echo "$TOTAL_MONTHLY_COST / ($MASTER_COUNT + $WORKER_COUNT)" | bc)
Cost per Core: \$$(echo "$TOTAL_MONTHLY_COST / $TOTAL_CLUSTER_CORES" | bc)
Cost per GB RAM: \$$(echo "$TOTAL_MONTHLY_COST / $TOTAL_CLUSTER_RAM" | bc)

REPORT

# Recommendations
if (( $(echo "$CPU_UTILIZATION > 80" | bc -l) )); then
  echo "⚠️  WARNING: CPU utilization is high. Consider adding Proxmox nodes."
fi

if (( $(echo "$RAM_UTILIZATION > 80" | bc -l) )); then
  echo "⚠️  WARNING: RAM utilization is high. Consider adding memory."
fi

if (( $(echo "$STORAGE_UTILIZATION > 70" | bc -l) )); then
  echo "⚠️  WARNING: Storage utilization is high. Consider adding storage."
fi
EOF

chmod +x cost-calculator.sh
./cost-calculator.sh
```

### Capacity Planning

#### Right-Sizing Workloads

Analyze actual vs requested resources:

```bash
# Install metrics-server if not already present
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check actual vs requested resources
cat <<'EOF' > capacity-analysis.sh
#!/bin/bash

echo "=== Pod Resource Analysis ==="
echo ""

kubectl get pods --all-namespaces -o json | jq -r '
.items[] | 
{
  namespace: .metadata.namespace,
  name: .metadata.name,
  containers: [.spec.containers[] | {
    name: .name,
    cpu_request: .resources.requests.cpu,
    cpu_limit: .resources.limits.cpu,
    mem_request: .resources.requests.memory,
    mem_limit: .resources.limits.memory
  }]
} | 
"\(.namespace)/\(.name): CPU: \(.containers[0].cpu_request) → \(.containers[0].cpu_limit), MEM: \(.containers[0].mem_request) → \(.containers[0].mem_limit)"
' | column -t

echo ""
echo "=== Actual Usage ==="
kubectl top pods --all-namespaces --sort-by=cpu | head -20

echo ""
echo "=== Over-provisioned Pods (>50% unused) ==="
kubectl top pods --all-namespaces -o json | jq -r '
.items[] | 
select(.containers[0].usage.cpu != null) |
{
  namespace: .metadata.namespace,
  name: .metadata.name,
  cpu_usage: .containers[0].usage.cpu,
  mem_usage: .containers[0].usage.memory
}
'
EOF

chmod +x capacity-analysis.sh
./capacity-analysis.sh
```

#### Growth Planning

Project resource needs based on growth:

```bash
cat <<'EOF' > growth-planning.sh
#!/bin/bash

CURRENT_WORKERS=3
CURRENT_CORES_PER_WORKER=4
CURRENT_RAM_PER_WORKER=8

MONTHLY_GROWTH_RATE=10  # Percentage
MONTHS_TO_PROJECT=12

echo "=== Capacity Growth Projection ==="
echo ""
echo "Current Configuration:"
echo "  Workers: $CURRENT_WORKERS"
echo "  Cores per worker: $CURRENT_CORES_PER_WORKER"
echo "  RAM per worker: ${CURRENT_RAM_PER_WORKER}GB"
echo ""

TOTAL_CORES=$((CURRENT_WORKERS * CURRENT_CORES_PER_WORKER))
TOTAL_RAM=$((CURRENT_WORKERS * CURRENT_RAM_PER_WORKER))

echo "Month | Workers | Cores | RAM(GB) | Action"
echo "------|---------|-------|---------|------------------"

for month in $(seq 1 $MONTHS_TO_PROJECT); do
  GROWTH_FACTOR=$(echo "1 + ($MONTHLY_GROWTH_RATE / 100 * $month)" | bc -l)
  NEEDED_CORES=$(echo "$TOTAL_CORES * $GROWTH_FACTOR / 1" | bc)
  NEEDED_RAM=$(echo "$TOTAL_RAM * $GROWTH_FACTOR / 1" | bc)
  NEEDED_WORKERS=$(echo "($NEEDED_CORES + $CURRENT_CORES_PER_WORKER - 1) / $CURRENT_CORES_PER_WORKER" | bc)
  
  if [ $NEEDED_WORKERS -gt $CURRENT_WORKERS ]; then
    ACTION="⚠️  Add $((NEEDED_WORKERS - CURRENT_WORKERS)) worker(s)"
    CURRENT_WORKERS=$NEEDED_WORKERS
  else
    ACTION="✓ Sufficient"
  fi
  
  printf "%5d | %7d | %5d | %7d | %s\n" \
    $month $NEEDED_WORKERS $NEEDED_CORES $NEEDED_RAM "$ACTION"
done

echo ""
echo "Recommendations:"
echo "  - Plan hardware procurement for month $(echo "scale=0; 100 / $MONTHLY_GROWTH_RATE" | bc)"
echo "  - Review capacity quarterly"
echo "  - Monitor utilization trends"
EOF

chmod +x growth-planning.sh
./growth-planning.sh
```

#### Cluster Sizing Recommendations

| Workload Type        | Master Nodes | Master Specs      | Worker Nodes | Worker Specs       | Use Case                 |
| -------------------- | ------------ | ----------------- | ------------ | ------------------ | ------------------------ |
| Development/Testing  | 1            | 2C / 4GB / 20GB   | 2            | 2C / 4GB / 50GB    | Local dev, CI/CD         |
| Small Production     | 3            | 2C / 4GB / 20GB   | 3            | 4C / 8GB / 100GB   | Small apps, < 100 pods   |
| Medium Production    | 3            | 4C / 8GB / 50GB   | 5            | 8C / 16GB / 200GB  | Medium apps, < 500 pods  |
| Large Production     | 5            | 8C / 16GB / 100GB | 10+          | 16C / 32GB / 500GB | Large scale, > 1000 pods |

### Resource Optimization Strategies

```bash
# 1. Implement Horizontal Pod Autoscaling
cat <<'EOF' > hpa-example.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

# 2. Set Resource Quotas per Namespace
cat <<'EOF' > resource-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: development
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
EOF

# 3. Implement Limit Ranges
cat <<'EOF' > limit-range.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
spec:
  limits:
  - max:
      cpu: "2"
      memory: 4Gi
    min:
      cpu: 50m
      memory: 64Mi
    default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
EOF

# 4. Use Vertical Pod Autoscaler for recommendations
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/vertical-pod-autoscaler/deploy/vpa-v1-crd-gen.yaml

# 5. Monitor and act on recommendations
kubectl describe vpa <vpa-name>
```

---

## Performance Optimization

### VM Performance

```text
# Optimized disk configuration for better I/O
disks {
  scsi {
    scsi0 {
      disk {
        storage    = "nvme-storage"  # Use faster storage
        size       = "50G"
        cache      = "writethrough"
        iothread   = 1
        discard    = "on"
        ssd        = 1
      }
    }
  }
}

# Enable NUMA for larger VMs
numa = true
```

### Network Performance

```text
network {
  id       = 0
  bridge   = "vmbr0"
  model    = "virtio"
  queues   = 4        # Multi-queue support
  mtu      = 9000     # Jumbo frames if supported
}
```

### Kubernetes Optimization

- Use node affinity for workload placement
- Implement resource quotas and limits
- Configure horizontal pod autoscaling
- Use persistent volume claims for storage

---

## Production Monitoring Stack

### Complete Observability Suite

Deploy Prometheus, Grafana, Loki, and Alertmanager:

```hcl
resource "null_resource" "monitoring_stack" {
  count = var.enable_monitoring ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Add Helm repositories
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
      helm repo add grafana https://grafana.github.io/helm-charts
      helm repo update
      
      # Create monitoring namespace
      kubectl create namespace monitoring || true
      
      # Install kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
      helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set prometheus.prometheusSpec.retention=${var.prometheus_retention} \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=local-path \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
        --set grafana.adminPassword=${var.grafana_admin_password} \
        --set grafana.persistence.enabled=true \
        --set grafana.persistence.size=10Gi \
        --set alertmanager.config.global.slack_api_url=${var.slack_webhook_url} \
        --wait
      
      # Install Loki for log aggregation
      helm upgrade --install loki grafana/loki-stack \
        --namespace monitoring \
        --set loki.persistence.enabled=true \
        --set loki.persistence.size=30Gi \
        --set promtail.enabled=true \
        --set grafana.enabled=false \
        --wait
      
      # Install Grafana Dashboards
      kubectl apply -f - <<EOF
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: k8s-cluster-dashboard
        namespace: monitoring
        labels:
          grafana_dashboard: "1"
      data:
        k8s-cluster.json: |
          {
            "dashboard": {
              "title": "Kubernetes Cluster Overview",
              "panels": [
                {
                  "title": "Node CPU Usage",
                  "targets": [{"expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"}]
                },
                {
                  "title": "Node Memory Usage",
                  "targets": [{"expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"}]
                },
                {
                  "title": "Pod Count by Namespace",
                  "targets": [{"expr": "sum by (namespace) (kube_pod_info)"}]
                }
              ]
            }
          }
      EOF
    EOT
  }
  
  depends_on = [null_resource.fetch_kubeconfig]
}
```

### Alerting Rules

Create production alerting rules:

```yaml
# alertmanager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-kube-prometheus-alertmanager
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
      slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'critical-alerts'
      routes:
      - match:
          severity: critical
        receiver: 'critical-alerts'
      - match:
          severity: warning
        receiver: 'warning-alerts'
    
    receivers:
    - name: 'critical-alerts'
      slack_configs:
      - channel: '#prod-alerts-critical'
        title: 'CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        send_resolved: true
    
    - name: 'warning-alerts'
      slack_configs:
      - channel: '#prod-alerts-warning'
        title: 'WARNING: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        send_resolved: true
    
    inhibit_rules:
    - source_match:
        severity: 'critical'
      target_match:
        severity: 'warning'
      equal: ['alertname', 'cluster', 'service']
```

Apply Prometheus rules:

```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kubernetes-cluster-alerts
  namespace: monitoring
spec:
  groups:
  - name: kubernetes.rules
    interval: 30s
    rules:
    - alert: NodeDown
      expr: up{job="node-exporter"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Node {{ $labels.instance }} is down"
        description: "Node {{ $labels.instance }} has been down for more than 5 minutes."
    
    - alert: HighNodeCPU
      expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "High CPU on node {{ $labels.instance }}"
        description: "Node {{ $labels.instance }} has CPU usage above 80% for 10 minutes."
    
    - alert: HighNodeMemory
      expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "High memory on node {{ $labels.instance }}"
        description: "Node {{ $labels.instance }} has memory usage above 85% for 10 minutes."
    
    - alert: KubernetesPodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"
        description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been restarting frequently."
    
    - alert: KubernetesPodNotReady
      expr: kube_pod_status_phase{phase!="Running"} == 1
      for: 15m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} not ready"
        description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in non-ready state for 15 minutes."
    
    - alert: EtcdHighLatency
      expr: histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m])) > 0.5
      for: 10m
      labels:
        severity: critical
      annotations:
        summary: "etcd high latency on {{ $labels.instance }}"
        description: "etcd instance {{ $labels.instance }} has high WAL fsync latency (99th percentile > 500ms)."
```

### Backup and Disaster Recovery

Implement Velero for cluster backups:

```hcl
resource "null_resource" "velero_backup" {
  count = var.enable_backup ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Install Velero CLI
      wget -q https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
      tar -xzf velero-v1.12.0-linux-amd64.tar.gz
      sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/
      
      # Create credentials for backup storage
      cat <<EOF > /tmp/credentials-velero
      [default]
      aws_access_key_id=${var.backup_s3_access_key}
      aws_secret_access_key=${var.backup_s3_secret_key}
      EOF
      
      # Install Velero
      velero install \
        --provider aws \
        --plugins velero/velero-plugin-for-aws:v1.8.0 \
        --bucket ${var.backup_bucket_name} \
        --secret-file /tmp/credentials-velero \
        --backup-location-config region=${var.backup_region},s3ForcePathStyle="true",s3Url=${var.backup_s3_url} \
        --snapshot-location-config region=${var.backup_region} \
        --use-volume-snapshots=false
      
      # Create daily backup schedule
      velero schedule create daily-backup \
        --schedule="@daily" \
        --ttl 720h0m0s \
        --include-namespaces "*" \
        --exclude-namespaces velero,kube-system
      
      # Create hourly backup for critical namespaces
      velero schedule create hourly-critical \
        --schedule="@hourly" \
        --ttl 168h0m0s \
        --include-namespaces production,database
      
      rm /tmp/credentials-velero
    EOT
  }
  
  depends_on = [null_resource.fetch_kubeconfig]
}
```

### Service Mesh Integration

Deploy Istio for advanced traffic management:

```hcl
resource "null_resource" "istio_installation" {
  count = var.enable_service_mesh ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Download Istio
      curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.0 sh -
      cd istio-1.20.0
      
      # Install Istio with production profile
      ./bin/istioctl install --set profile=production \
        --set values.gateways.istio-ingressgateway.type=LoadBalancer \
        --set values.pilot.resources.requests.cpu=500m \
        --set values.pilot.resources.requests.memory=2Gi \
        --set values.global.proxy.resources.requests.cpu=100m \
        --set values.global.proxy.resources.requests.memory=128Mi \
        --set values.telemetry.enabled=true \
        -y
      
      # Enable automatic sidecar injection
      kubectl label namespace default istio-injection=enabled
      kubectl label namespace production istio-injection=enabled
      
      # Install Kiali for observability
      kubectl apply -f samples/addons/kiali.yaml
      kubectl apply -f samples/addons/jaeger.yaml
      
      cd ..
      rm -rf istio-1.20.0
    EOT
  }
  
  depends_on = [null_resource.monitoring_stack]
}
```

### Cost Optimization

Monitor and optimize resource usage:

```hcl
resource "null_resource" "cost_monitoring" {
  count = var.enable_cost_monitoring ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Install Kubecost
      helm repo add kubecost https://kubecost.github.io/cost-analyzer/
      helm repo update
      
      helm upgrade --install kubecost kubecost/cost-analyzer \
        --namespace kubecost --create-namespace \
        --set prometheus.server.global.external_labels.cluster_id=${var.cluster_name} \
        --set prometheus.nodeExporter.enabled=false \
        --set prometheus.serviceAccounts.nodeExporter.create=false \
        --set ingress.enabled=true \
        --set ingress.hosts[0]="kubecost.${var.domain_name}" \
        --wait
      
      # Configure resource recommendations
      kubectl apply -f - <<EOF
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: kubecost-cost-analyzer
        namespace: kubecost
      data:
        recommendations.yaml: |
          savings:
            recommendUnderutilizedNodes: true
            recommendRightSizing: true
            minSavingsThreshold: 10
            cpuUtilizationThreshold: 0.2
            memUtilizationThreshold: 0.2
      EOF
    EOT
  }
  
  depends_on = [null_resource.monitoring_stack]
}
```

### Security Hardening

Deploy Falco for runtime security:

```hcl
resource "null_resource" "security_monitoring" {
  count = var.enable_security_monitoring ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Install Falco for runtime security
      helm repo add falcosecurity https://falcosecurity.github.io/charts
      helm repo update
      
      helm upgrade --install falco falcosecurity/falco \
        --namespace falco --create-namespace \
        --set falco.grpc.enabled=true \
        --set falco.grpcOutput.enabled=true \
        --set falco.json_output=true \
        --set falco.log_syslog=false \
        --set falco.priority=warning \
        --set falco.rules_file[0]=/etc/falco/falco_rules.yaml \
        --set falco.rules_file[1]=/etc/falco/k8s_audit_rules.yaml \
        --wait
      
      # Install Falcosidekick for alerts
      helm upgrade --install falcosidekick falcosecurity/falcosidekick \
        --namespace falco \
        --set config.slack.webhookurl=${var.slack_webhook_url} \
        --set config.slack.minimumpriority=warning \
        --wait
    EOT
  }
  
  depends_on = [null_resource.fetch_kubeconfig]
}
```

### Complete Production Variables

Add all required variables:

```hcl
# Monitoring
variable "prometheus_retention" {
  type        = string
  description = "Prometheus data retention period"
  default     = "15d"
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password"
  sensitive   = true
}

variable "slack_webhook_url" {
  type        = string
  description = "Slack webhook URL for alerts"
  sensitive   = true
  default     = ""
}

# Backup
variable "backup_bucket_name" {
  type        = string
  description = "S3 bucket name for Velero backups"
  default     = ""
}

variable "backup_region" {
  type        = string
  description = "S3 region for backups"
  default     = "us-east-1"
}

variable "backup_s3_url" {
  type        = string
  description = "S3-compatible storage URL"
  default     = ""
}

variable "backup_s3_access_key" {
  type        = string
  description = "S3 access key for backups"
  sensitive   = true
  default     = ""
}

variable "backup_s3_secret_key" {
  type        = string
  description = "S3 secret key for backups"
  sensitive   = true
  default     = ""
}

# Service Mesh
variable "enable_service_mesh" {
  type        = bool
  description = "Enable Istio service mesh"
  default     = false
}

# Cost Monitoring
variable "enable_cost_monitoring" {
  type        = bool
  description = "Enable Kubecost for cost monitoring"
  default     = false
}

variable "domain_name" {
  type        = string
  description = "Domain name for ingress"
  default     = "example.com"
}

# Security
variable "enable_security_monitoring" {
  type        = bool
  description = "Enable Falco runtime security monitoring"
  default     = false
}
```

---

## Best Practices

### Infrastructure as Code

- **Version Control**: Always use Git for Terraform configurations
- **State Management**: Use remote state backends (S3, Consul, etc.)
- **Environment Separation**: Use workspaces or separate directories
- **Documentation**: Keep README files updated with deployment procedures

### Security Best Practices

- **Secrets Management**: Never commit sensitive values to Git
- **Least Privilege**: Grant minimum necessary permissions
- **Regular Updates**: Keep Terraform provider and Kubernetes versions current
- **Monitoring**: Implement logging and monitoring for security events

### Operational Best Practices

- **Resource Tagging**: Use consistent tagging for resource organization
- **Backup Strategy**: Automated backups of both infrastructure state and cluster data
- **Disaster Recovery**: Document and test recovery procedures
- **Change Management**: Use pull request workflows for infrastructure changes

---

**Important Security Notes:**

- **Never commit `terraform.tfvars`** or any files containing sensitive data to version control
- **Use environment variables** or encrypted secret management for sensitive values  
- **Rotate API tokens** and SSH keys regularly
- **Implement proper network segmentation** and firewall rules
- **Keep Proxmox and Kubernetes** updated with latest security patches
