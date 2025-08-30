---
title: "Terraform Proxmox Kubernetes Cluster"
description: "Complete guide to deploying a highly available Kubernetes cluster on Proxmox VE using Terraform infrastructure as code"
author: "josephstreeter"
ms.date: "2025-08-29"
ms.topic: "how-to-guide"
ms.service: "terraform"
keywords: ["Terraform", "Proxmox", "Kubernetes", "K8s", "Infrastructure as Code", "IaC", "Cloud-Init", "Automation"]
---

This guide demonstrates how to deploy a production-ready Kubernetes cluster on Proxmox VE using Terraform. The configuration creates multiple nodes with proper networking, security, and scalability considerations.

## Prerequisites

### Proxmox VE Requirements

- Proxmox VE 7.x or later
- API user with appropriate permissions
- Cloud-init enabled VM template (Ubuntu/Debian recommended)
- Sufficient resources for cluster nodes
- Network bridge configured (vmbr0)

### Required Proxmox API Permissions

Create a dedicated API user for Terraform:

```bash
# Create user
pveum user add terraform-prov@pve

# Create API token
pveum user token add terraform-prov@pve terraform_id -privsep 0

# Assign permissions
pveum aclmod / -user terraform-prov@pve -role Administrator
```

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

```terraform
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
  pm_parallel         = 3
  pm_timeout          = 600
}
```

### `variables.tf`

```terraform
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
```

### `main.tf`

```terraform
### Main Configuration

```terraform
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

```terraform
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

---

## Configuration Files

### `terraform.tfvars` Template

Create this file with your actual values (DO NOT commit to version control):

```terraform
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

```terraform
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

```terraform
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

```terraform
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

```terraform
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
