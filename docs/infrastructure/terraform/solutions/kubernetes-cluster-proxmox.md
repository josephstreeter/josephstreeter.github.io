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
      source  = "bpg/proxmox"
      version = "~> 0.46"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = var.proxmox_tls_insecure
  
  # Optional: SSH connection for operations requiring it
  ssh {
    agent    = true
    username = "root"
  }
  
  # Logging configuration
  tmp_dir = "/tmp"
}
```

> **Note:** The provider has changed from `telmate/proxmox` to `bpg/proxmox` (community-maintained fork with active development). Update your existing configurations accordingly.

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
  description = "Skip TLS verification for Proxmox API"
  default     = true
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
  value = {
    api_servers    = [for k, v in var.master_nodes : "${v.ip}:6443"]
    master_ips     = [for k, v in var.master_nodes : v.ip]
    worker_ips     = [for k, v in var.worker_nodes : v.ip]
    ssh_command    = "ssh ${var.cloud_init_user}@<node_ip>"
  }
}

output "next_steps" {
  description = "Commands to run after deployment"
  value = {
    ssh_to_master = "ssh ${var.cloud_init_user}@${values(var.master_nodes)[0].ip}"
    kubeadm_init  = "sudo kubeadm init --apiserver-advertise-address=${values(var.master_nodes)[0].ip} --pod-network-cidr=10.244.0.0/16"
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
        bind *:6443
        mode tcp
        option tcplog
        default_backend k8s_api_backend
      
      backend k8s_api_backend
        mode tcp
        option tcp-check
        balance roundrobin
        server master-01 192.168.100.10:6443 check fall 3 rise 2
        server master-02 192.168.100.11:6443 check fall 3 rise 2
        server master-03 192.168.100.12:6443 check fall 3 rise 2
      
      listen stats
        bind *:8404
        stats enable
        stats uri /
        stats refresh 30s

runcmd:
  - systemctl enable haproxy
  - systemctl restart haproxy
```

Upload to Proxmox:

```bash
scp cloud-init/haproxy-cloud-init.yml root@proxmox-host:/var/lib/vz/snippets/
```

Update outputs for load balancer:

```hcl
output "load_balancer" {
  description = "Load balancer information"
  value = var.enable_ha ? {
    ip            = var.lb_ip
    api_endpoint  = "${var.lb_ip}:6443"
    stats_url     = "http://${var.lb_ip}:8404"
  } : null
}
```

---

## Configuration Files

### `terraform.tfvars` Template

Create this file with your actual values (DO NOT commit to version control):

```hcl
# Proxmox connection
proxmox_api_url          = "https://your-proxmox-host:8006/api2/json"
proxmox_api_token_id     = "terraform-prov@pve!terraform_id"
proxmox_api_token_secret = "your-api-token-secret"
proxmox_tls_insecure     = true

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
    proxmox_vm_qemu.k8s_workers
  ]
}

# Run Ansible playbook after VM creation
resource "null_resource" "kubernetes_installation" {
  triggers = {
    cluster_instance_ids = join(",", concat(
      [for k, v in proxmox_vm_qemu.k8s_masters : v.vmid],
      [for k, v in proxmox_vm_qemu.k8s_workers : v.vmid]
    ))
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/ansible
      sleep 60  # Wait for cloud-init to complete
      ansible-playbook -i inventory/hosts.ini \
        -e kubernetes_version=1.28.3 \
        -e pod_network_cidr=10.244.0.0/16 \
        -e service_cidr=10.96.0.0/12 \
        -e cluster_name=${var.cluster_name} \
        playbooks/k8s-cluster.yml
    EOT
    
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
  
  depends_on = [local_file.ansible_inventory]
}

# Retrieve kubeconfig
resource "null_resource" "fetch_kubeconfig" {
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/kubeconfig
      scp -o StrictHostKeyChecking=no \
        ${var.cloud_init_user}@${values(var.master_nodes)[0].ip}:~/.kube/config \
        ${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Update server address if using load balancer
      ${var.enable_ha ? "sed -i 's|server: https://.*:6443|server: https://${var.lb_ip}:6443|' ${path.module}/kubeconfig/${var.cluster_name}.conf" : ""}
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
set -e

K8S_VERSION=$1
CONTAINERD_VERSION=$2

echo "=== Installing Kubernetes prerequisites ==="

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Set sysctl parameters
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.forwarding        = 1
vm.overcommit_memory                = 1
kernel.panic                        = 10
kernel.panic_on_oops                = 1
EOF

sysctl --system

echo "=== Installing containerd ==="

# Install dependencies
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker repository
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install containerd
apt-get update
apt-get install -y containerd.io

# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

echo "=== Installing Kubernetes components ==="

# Add Kubernetes repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION%.*}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION%.*}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# Install kubeadm, kubelet, kubectl
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

echo "=== Installing monitoring tools ==="

# Install Prometheus Node Exporter
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
useradd -rs /bin/false node_exporter
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
systemctl enable node_exporter

# Cleanup
rm -rf node_exporter-*

echo "=== Kubernetes prerequisites installation complete ==="
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

```bash
# Backup Terraform state
cp terraform.tfstate terraform.tfstate.backup

# Backup Kubernetes cluster
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Backup etcd (from master node)
sudo ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

#### Recovery Procedures

```bash
# Restore from Terraform state backup
cp terraform.tfstate.backup terraform.tfstate

# Restore infrastructure
terraform plan
terraform apply

# Restore Kubernetes resources
kubectl apply -f cluster-backup.yaml
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
```

#### Network Connectivity Issues

```bash
# Test from Terraform host
ping 192.168.100.10

# Check Proxmox network configuration
cat /etc/network/interfaces

# Verify bridge configuration
brctl show vmbr0
```

#### Cloud-Init Problems

```bash
# Check cloud-init logs on VM
sudo cloud-init status --long
sudo cat /var/log/cloud-init.log

# Regenerate cloud-init
sudo cloud-init clean --logs
sudo cloud-init init
```

### Kubernetes Troubleshooting

#### Cluster Issues

```bash
# Check node status
kubectl get nodes -o wide

# Examine system pods
kubectl get pods -A --field-selector=status.phase!=Running

# Check cluster events
kubectl get events --sort-by='.lastTimestamp'
```

#### Network Plugin Issues

```bash
# Check Flannel pods
kubectl get pods -n kube-flannel

# Restart Flannel daemonset
kubectl rollout restart daemonset/kube-flannel-ds -n kube-flannel

# Check node network configuration
ip route show
```

### Terraform State Issues

```bash
# Import existing resource
terraform import proxmox_vm_qemu.k8s_masters["master-01"] <node-name>/<vmid>

# Refresh state
terraform refresh

# Remove resource from state (dangerous)
terraform state rm proxmox_vm_qemu.k8s_masters["master-01"]
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

### Kubernetes Security

- Enable RBAC (default in modern Kubernetes)
- Use network policies for pod communication
- Implement admission controllers
- Regular security updates and patching

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
