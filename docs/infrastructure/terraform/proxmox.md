---
title: "Terraform with Proxmox VE"
description: "Complete guide to using Terraform for infrastructure automation with Proxmox Virtual Environment"
author: "josephstreeter"
ms.date: "2025-12-30"
ms.topic: "how-to-guide"
ms.service: "terraform"
keywords: ["Terraform", "Proxmox", "Virtualization", "Infrastructure as Code", "IaC", "VM Automation", "Cloud-Init"]
---

This guide demonstrates how to use Terraform to automate infrastructure provisioning on Proxmox Virtual Environment (VE). Proxmox is an open-source server virtualization platform that combines KVM hypervisor and LXC containers with an intuitive web interface and REST API.

## Overview

Terraform enables Infrastructure as Code (IaC) for Proxmox, allowing you to:

- **Automate VM provisioning** - Create and manage virtual machines programmatically
- **Version control infrastructure** - Track changes to your infrastructure in Git
- **Ensure consistency** - Deploy identical environments across development, staging, and production
- **Scale efficiently** - Provision multiple VMs with minimal configuration
- **Integrate cloud-init** - Automate guest OS configuration and initialization

## Prerequisites

### Proxmox VE Requirements

- Proxmox VE 7.x or later installed and configured
- API access enabled
- VM template with cloud-init support (recommended)
- Network bridge configured (typically vmbr0)
- Sufficient storage for VM disks

### Local Development Requirements

- Terraform >= 1.0 installed
- Network connectivity to Proxmox host
- API credentials (token authentication recommended)

### Install Terraform

```bash
# Download and install Terraform (Linux)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version
```

## Proxmox API Setup

### Create API User and Token

Create a dedicated user and API token for Terraform:

```bash
# Create Terraform provisioning user
pveum user add terraform-prov@pve --comment "Terraform Provisioning User"

# Create API token
pveum user token add terraform-prov@pve terraform_id --privsep=0

# Output will include:
# ┌──────────────┬──────────────────────────────────────┐
# │ key          │ value                                │
# ╞══════════════╪══════════════════════════════════════╡
# │ full-tokenid │ terraform-prov@pve!terraform_id      │
# ├──────────────┼──────────────────────────────────────┤
# │ info         │ {"privsep":"0"}                      │
# ├──────────────┼──────────────────────────────────────┤
# │ value        │ xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx │
# └──────────────┴──────────────────────────────────────┘

# Save the token value - it will only be displayed once!
```

### Grant Permissions

Grant necessary permissions to the Terraform user:

```bash
# Create custom role with minimal required permissions (REQUIRED for production)
pveum role add TerraformProvisioner -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify SDN.Use"

# Assign role to user at root level
pveum aclmod / -user terraform-prov@pve -role TerraformProvisioner
```

> **Security Warning:** Never use Administrator or PVEAdmin roles for Terraform automation. Always follow least-privilege principles by creating custom roles with only the permissions required for your specific use case.

## Terraform Provider Configuration

### Provider Setup

Create `provider.tf`:

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.5"  # Pin exact version for production
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  
  # Token format: username@realm!tokenid=secret
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  
  # Set to false in production with valid SSL certificate
  insecure = var.insecure_skip_tls_verify
  
  # Optional: SSH access for certain operations
  ssh {
    agent    = true
    username = "root"
  }
}
```

### Variables Configuration

Create `variables.tf`:

```hcl
variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API URL (e.g., https://proxmox.example.com:8006/api2/json)"
  
  validation {
    condition     = can(regex("^https?://", var.proxmox_api_url))
    error_message = "API URL must start with http:// or https://"
  }
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API token ID (e.g., terraform-prov@pve!terraform_id)"
  
  validation {
    condition     = can(regex("^[^@]+@[^!]+![^=]+$", var.proxmox_api_token_id))
    error_message = "Token ID must be in format: username@realm!tokenid"
  }
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
  
  validation {
    condition     = length(var.proxmox_api_token_secret) >= 16
    error_message = "Token secret must be at least 16 characters"
  }
}

variable "insecure_skip_tls_verify" {
  type        = bool
  description = "Skip TLS certificate verification (only for development)"
  default     = false
}

variable "target_node" {
  type        = string
  description = "Proxmox node name"
  default     = "pve"
  
  validation {
    condition     = length(var.target_node) > 0
    error_message = "Target node name cannot be empty"
  }
}

variable "datastore_id" {
  type        = string
  description = "Proxmox datastore ID for VM disks"
  default     = "local-lvm"
}

variable "template_name" {
  type        = string
  description = "Name of the VM template to clone"
  default     = "ubuntu-cloud-template"
}

variable "template_id" {
  type        = number
  description = "Template VM ID to clone from"
  default     = 9000
  
  validation {
    condition     = var.template_id >= 100 && var.template_id <= 999999999
    error_message = "Template ID must be between 100 and 999999999"
  }
}

variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
  default     = 1
  
  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 100
    error_message = "VM count must be between 1 and 100"
  }
}

variable "vm_name_prefix" {
  type        = string
  description = "Prefix for VM names"
  default     = "terraform-vm"
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.vm_name_prefix))
    error_message = "VM name prefix must start with alphanumeric and contain only lowercase letters, numbers, and hyphens"
  }
}

variable "vm_memory" {
  type        = number
  description = "VM memory in MB"
  default     = 2048
  
  validation {
    condition     = var.vm_memory >= 512 && var.vm_memory <= 524288
    error_message = "Memory must be between 512MB and 512GB"
  }
}

variable "vm_cores" {
  type        = number
  description = "Number of CPU cores"
  default     = 2
  
  validation {
    condition     = var.vm_cores >= 1 && var.vm_cores <= 128
    error_message = "CPU cores must be between 1 and 128"
  }
}

variable "vm_disk_size" {
  type        = string
  description = "VM disk size (e.g., 20G)"
  default     = "20G"
  
  validation {
    condition     = can(regex("^[0-9]+[KMGT]$", var.vm_disk_size))
    error_message = "Disk size must be in format: number followed by K, M, G, or T (e.g., 20G, 500M)"
  }
}

variable "network_bridge" {
  type        = string
  description = "Network bridge name"
  default     = "vmbr0"
  
  validation {
    condition     = can(regex("^vmbr[0-9]+$", var.network_bridge))
    error_message = "Network bridge must be in format: vmbr followed by number (e.g., vmbr0)"
  }
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for cloud-init"
  
  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256) ", var.ssh_public_key))
    error_message = "Must be a valid SSH public key (ssh-rsa, ssh-ed25519, or ecdsa-sha2-nistp256)"
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, production)"
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production"
  }
}
```

Create `terraform.tfvars` (never commit this file):

```hcl
proxmox_api_url           = "https://192.168.1.100:8006/api2/json"
proxmox_api_token_id      = "terraform-prov@pve!terraform_id"
proxmox_api_token_secret  = "your-secret-token-here"
target_node               = "pve"
template_name             = "ubuntu-cloud-template"
vm_count                  = 3
vm_name_prefix            = "web-server"
vm_memory                 = 4096
vm_cores                  = 2
vm_disk_size              = "30G"
ssh_public_key            = "ssh-rsa AAAAB3NzaC1yc2E... user@host"
```

## Creating VM Templates

### Ubuntu Cloud Image Template

Create a cloud-init enabled template:

```bash
# Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create VM
qm create 9000 --name ubuntu-cloud-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Configure VM
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000

# Verify template exists
qm list
```

### Debian Cloud Image Template

```bash
# Download Debian cloud image
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Create and configure VM
qm create 9001 --name debian-cloud-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9001 debian-12-generic-amd64.qcow2 local-lvm
qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9001-disk-0
qm set 9001 --boot c --bootdisk scsi0
qm set 9001 --ide2 local-lvm:cloudinit
qm set 9001 --serial0 socket --vga serial0
qm set 9001 --agent enabled=1
qm template 9001
```

## Basic VM Provisioning

### Single VM Example

Create `main.tf`:

```hcl
resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.vm_name_prefix
  node_name   = var.target_node
  vm_id       = 100
  
  clone {
    vm_id = var.template_id
    full  = true
  }
  
  agent {
    enabled = true
    timeout = "60s"  # Wait for agent to be ready
  }
  
  cpu {
    cores = var.vm_cores
    type  = "host"
  }
  
  memory {
    dedicated = var.vm_memory
  }
  
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.vm_disk_size
    iothread     = true
    cache        = "writethrough"
  }
  
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
  
  operating_system {
    type = "l26"  # Linux 2.6+ kernel
  }
  
  on_boot = true
  
  lifecycle {
    ignore_changes = [
      initialization,  # Cloud-init changes don't trigger recreation
    ]
  }
  
  tags = [var.environment, "terraform-managed"]
}
```

### Multiple VMs with Count

```hcl
resource "proxmox_virtual_environment_vm" "vms" {
  count = var.vm_count
  
  name      = "${var.vm_name_prefix}-${format("%02d", count.index + 1)}"
  node_name = var.target_node
  vm_id     = 100 + count.index
  
  clone {
    vm_id = var.template_id
    full  = true
  }
  
  agent {
    enabled = true
    timeout = "60s"
  }
  
  cpu {
    cores = var.vm_cores
    type  = "host"
  }
  
  memory {
    dedicated = var.vm_memory
  }
  
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.vm_disk_size
    iothread     = true
    cache        = "writethrough"
  }
  
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
  
  operating_system {
    type = "l26"
  }
  
  on_boot = true
  
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [initialization]
    prevent_destroy       = var.environment == "production"
  }
  
  tags = [var.environment, "terraform-managed", "vm-${count.index + 1}"]
  
  # Wait for VM to be ready before continuing
  timeouts {
    create = "10m"
    update = "10m"
    delete = "5m"
  }
}
```

## Advanced VM Configuration

### Static IP Configuration

```hcl
variable "vm_ips" {
  type = map(object({
    ip      = string
    gateway = string
    vm_id   = number
  }))
  description = "Map of VM names to their network configuration"
  
  default = {
    "vm-1" = {
      ip      = "192.168.1.101/24"
      gateway = "192.168.1.1"
      vm_id   = 101
    }
    "vm-2" = {
      ip      = "192.168.1.102/24"
      gateway = "192.168.1.1"
      vm_id   = 102
    }
    "vm-3" = {
      ip      = "192.168.1.103/24"
      gateway = "192.168.1.1"
      vm_id   = 103
    }
  }
  
  validation {
    condition = alltrue([
      for k, v in var.vm_ips : can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", v.ip))
    ])
    error_message = "All IP addresses must be in CIDR format (e.g., 192.168.1.101/24)"
  }
}

resource "proxmox_virtual_environment_vm" "static_ip_vms" {
  for_each = var.vm_ips
  
  name      = each.key
  node_name = var.target_node
  vm_id     = each.value.vm_id
  
  clone {
    vm_id = var.template_id
    full  = true
  }
  
  agent {
    enabled = true
    timeout = "60s"
  }
  
  cpu {
    cores = var.vm_cores
    type  = "host"
  }
  
  memory {
    dedicated = var.vm_memory
  }
  
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.vm_disk_size
    iothread     = true
    cache        = "writethrough"
  }
  
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = each.value.gateway
      }
    }
    
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
    }
    
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
  
  operating_system {
    type = "l26"
  }
  
  on_boot = true
  
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [initialization]
    prevent_destroy       = var.environment == "production"
  }
  
  tags = [var.environment, "terraform-managed", "static-ip"]
}
```

### Cloud-Init User Data

```hcl
resource "proxmox_virtual_environment_vm" "cloudinit_vm" {
  name      = "web-server"
  node_name = var.target_node
  vm_id     = 200
  
  clone {
    vm_id = 9000
    full  = true
  }
  
  agent {
    enabled = true
  }
  
  cpu {
    cores = 4
    type  = "host"
  }
  
  memory {
    dedicated = 8192
  }
  
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = "50G"
  }
  
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.150/24"
        gateway = "192.168.1.1"
      }
    }
    
    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
      domain  = "example.com"
    }
    
    user_account {
      username = "admin"
      keys     = [var.ssh_public_key]
      # SECURITY: Never use passwords - SSH keys only!
      # To set password: use cloud-init user_data with hashed password
    }
    
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_config.id
  }
  
  operating_system {
    type = "l26"
  }
  
  on_boot = true
}

resource "proxmox_virtual_environment_file" "cloud_init_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node
  
  source_raw {
    data = templatefile("${path.module}/cloud-init-config.tftpl", {
      hostname    = "web-server"
      environment = var.environment
      ssh_keys    = [var.ssh_public_key]
    })
    
    file_name = "cloud-init-${var.environment}-config.yaml"
  }
}

# Create cloud-init-config.tftpl file with:
locals {
  cloud_init_template = <<-EOF
    #cloud-config
    hostname: ${hostname}
    manage_etc_hosts: true
    
    # Security hardening
    ssh_pwauth: false
    disable_root: true
    
    packages:
      - qemu-guest-agent
      - nginx
      - curl
      - htop
      - vim
      - fail2ban
      - ufw
    
    package_update: true
    package_upgrade: true
    
    runcmd:
      # Start QEMU guest agent
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      # Configure firewall
      - ufw allow 22/tcp
      - ufw allow 80/tcp
      - ufw allow 443/tcp
      - ufw --force enable
      # Configure nginx
      - systemctl enable nginx
      - systemctl start nginx
      - echo "Welcome to Terraform-provisioned VM (${environment})" > /var/www/html/index.html
    
    users:
      - name: admin
        groups: sudo
        shell: /bin/bash
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh_authorized_keys: %{ for key in ssh_keys }
          - ${key}
        %{ endfor }
    
    timezone: UTC
    
    write_files:
      - path: /etc/motd
        content: |
          ****************************************************
          * This VM is managed by Terraform                 *
          * Environment: ${environment}                     *
          * Do not make manual changes without documenting  *
          ****************************************************
  EOF
}
```

## Storage Configuration

### Multiple Disks

```hcl
resource "proxmox_virtual_environment_vm" "multi_disk_vm" {
  name      = "database-server"
  node_name = var.target_node
  vm_id     = 300
  
  clone {
    vm_id = 9000
    full  = true
  }
  
  agent {
    enabled = true
  }
  
  cpu {
    cores = 8
    type  = "host"
  }
  
  memory {
    dedicated = 16384
  }
  
  # OS disk
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = "50G"
    cache        = "writethrough"
    iothread     = true
  }
  
  # Data disk (consider using separate datastore for better performance)
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi1"
    size         = "200G"
    cache        = "writethrough"
    iothread     = true
    discard      = "on"  # Enable TRIM for SSD
  }
  
  # Backup disk
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi2"
    size         = "100G"
    cache        = "writethrough"
    iothread     = true
  }
  
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.200/24"
        gateway = "192.168.1.1"
      }
    }
    
    user_account {
      username = "dbadmin"
      keys     = [var.ssh_public_key]
    }
  }
  
  operating_system {
    type = "l26"
  }
  
  on_boot = true
}
```

## Networking Configuration

### Multiple Network Interfaces

```hcl
resource "proxmox_virtual_environment_vm" "multi_nic_vm" {
  name      = "firewall-vm"
  node_name = var.target_node
  vm_id     = 400
  
  clone {
    vm_id = 9000
    full  = true
  }
  
  agent {
    enabled = true
  }
  
  cpu {
    cores = 4
    type  = "host"
  }
  
  memory {
    dedicated = 4096
  }
  
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = "30G"
  }
  
  # WAN interface
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  
  # LAN interface
  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }
  
  # DMZ interface
  network_device {
    bridge = "vmbr2"
    model  = "virtio"
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.254/24"
        gateway = "192.168.1.1"
      }
    }
    
    ip_config {
      ipv4 {
        address = "10.0.0.1/24"
      }
    }
    
    ip_config {
      ipv4 {
        address = "172.16.0.1/24"
      }
    }
    
    user_account {
      username = "admin"
      keys     = [var.ssh_public_key]
    }
  }
  
  operating_system {
    type = "l26"
  }
  
  on_boot = true
}
```

## Outputs

Create `outputs.tf`:

```hcl
output "vm_ids" {
  description = "IDs of created VMs"
  value       = [for vm in proxmox_virtual_environment_vm.vms : vm.vm_id]
}

output "vm_names" {
  description = "Names of created VMs"
  value       = [for vm in proxmox_virtual_environment_vm.vms : vm.name]
}

output "vm_details" {
  description = "Detailed information about created VMs"
  value = {
    for vm in proxmox_virtual_environment_vm.vms :
    vm.name => {
      vm_id         = vm.vm_id
      node          = vm.node_name
      # DHCP may take time to assign IP - check after cloud-init completes
      ipv4_addresses = length(vm.ipv4_addresses) > 1 ? vm.ipv4_addresses[1] : ["IP not yet assigned"]
      mac_addresses  = vm.mac_addresses
      status        = vm.started ? "running" : "stopped"
    }
  }
}

output "static_ip_vms" {
  description = "Static IP VM information"
  value = {
    for vm in proxmox_virtual_environment_vm.static_ip_vms :
    vm.name => {
      vm_id      = vm.vm_id
      ip_address = split("/", var.vm_ips[vm.name].ip)[0]
      ssh_command = "ssh ubuntu@${split("/", var.vm_ips[vm.name].ip)[0]}"
    }
  }
  sensitive = false
}

output "connection_info" {
  description = "Quick reference for connecting to VMs"
  value = <<-EOT
    To connect to VMs:
    
    Static IP VMs:
    %{ for name, config in var.vm_ips ~}
    - ${name}: ssh ubuntu@${split("/", config.ip)[0]}
    %{ endfor ~}
    
    DHCP VMs: Run 'terraform output vm_details' to see assigned IPs
    
    Note: VMs may take 1-2 minutes after creation for cloud-init to complete.
  EOT
}
```

## State Management

### Remote State with S3

Create `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "proxmox/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:ACCOUNT:key/KEY-ID"  # Optional: KMS encryption
    dynamodb_table = "terraform-state-lock"
    
    # Enable workspace support
    workspace_key_prefix = "workspaces"
  }
}
```

### Remote State with Consul

```hcl
terraform {
  backend "consul" {
    address = "consul.example.com:8500"
    scheme  = "https"
    path    = "terraform/proxmox"
  }
}
```

## Deployment Workflow

### Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format configuration files
terraform fmt

# Plan infrastructure changes
terraform plan -out=tfplan

# Review plan output carefully

# Apply changes
terraform apply tfplan

# Verify deployment
terraform show

# Test SSH connectivity
ssh ubuntu@<vm-ip-address>
```

### Update Infrastructure

```bash
# Modify variables or configuration

# Plan changes
terraform plan -out=tfplan

# Review changes

# Apply updates
terraform apply tfplan
```

### Destroy Infrastructure

```bash
# Preview destruction
terraform plan -destroy

# Destroy all resources
terraform destroy

# Or destroy specific resource
terraform destroy -target=proxmox_virtual_environment_vm.vms[0]
```

## Module Organization

### Reusable VM Module

Create `modules/proxmox-vm/main.tf`:

```hcl
variable "node_name" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "template_id" {
  type    = number
  default = 9000
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2048
}

variable "disk_size" {
  type    = string
  default = "20G"
}

variable "ip_address" {
  type = string
}

variable "gateway" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "datastore_id" {
  type        = string
  description = "Datastore ID for VM disks"
  default     = "local-lvm"
}

variable "network_bridge" {
  type        = string
  description = "Network bridge"
  default     = "vmbr0"
}

variable "environment" {
  type        = string
  description = "Environment tag"
  default     = "dev"
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.node_name
  vm_id     = var.vm_id
  
  clone {
    vm_id = var.template_id
    full  = true
  }
  
  agent {
    enabled = true
    timeout = "60s"
  }
  
  cpu {
    cores = var.cores
    type  = "host"
  }
  
  memory {
    dedicated = var.memory
  }
  
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size
    iothread     = true
    cache        = "writethrough"
  }
  
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }
    
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
  
  operating_system {
    type = "l26"
  }
  
  on_boot = true
  
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [initialization]
    prevent_destroy       = var.environment == "production"
  }
  
  tags = [var.environment, "terraform-managed", "module-created"]
}

output "vm_id" {
  description = "VM ID"
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.vm.name
}

output "ip_address" {
  description = "Configured IP address"
  value       = var.ip_address
}

output "actual_ipv4_addresses" {
  description = "Actual IPv4 addresses assigned to VM"
  value       = length(proxmox_virtual_environment_vm.vm.ipv4_addresses) > 1 ? proxmox_virtual_environment_vm.vm.ipv4_addresses[1] : []
}
```

Create `modules/proxmox-vm/variables.tf` and `modules/proxmox-vm/outputs.tf` as needed.

### Using the Module

In your root `main.tf`:

```hcl
module "web_servers" {
  source = "./modules/proxmox-vm"
  
  for_each = {
    "web-01" = { ip = "192.168.1.101/24", vm_id = 101 }
    "web-02" = { ip = "192.168.1.102/24", vm_id = 102 }
    "web-03" = { ip = "192.168.1.103/24", vm_id = 103 }
  }
  
  node_name      = var.target_node
  vm_name        = each.key
  vm_id          = each.value.vm_id
  cores          = 4
  memory         = 8192
  disk_size      = "50G"
  ip_address     = each.value.ip
  gateway        = "192.168.1.1"
  ssh_public_key = var.ssh_public_key
}

output "web_servers" {
  value = {
    for k, v in module.web_servers :
    k => {
      vm_id = v.vm_id
      ip    = v.ip_address
    }
  }
}
```

## Best Practices

### Security

- **Use API tokens** instead of password authentication
- **Apply least privilege** - create custom roles with minimal permissions
- **Never commit secrets** - use environment variables or secret management tools
- **Enable SSL/TLS** - use valid certificates in production environments
- **Rotate credentials** regularly
- **Use SSH keys** instead of passwords for VM access

### Infrastructure Management

- **Version control** - store Terraform code in Git
- **Use remote state** - S3, Consul, or Terraform Cloud for state storage
- **Enable state locking** - prevent concurrent modifications
- **Use workspaces** - separate dev, staging, and production environments
- **Implement CI/CD** - automate terraform plan/apply in pipelines
- **Tag resources** - use consistent naming and tagging conventions

### Performance Optimization

- **Use cloud-init** for faster provisioning
- **Enable QEMU agent** for better VM management
- **Use virtio drivers** for optimal disk and network performance
- **Set appropriate I/O threads** for disk-intensive workloads
- **Configure CPU type** - "host" for best performance
- **Use SSD storage pools** for database and high-IOPS workloads

### Maintenance

- **Regular backups** - use Proxmox backup solutions
- **Monitor resources** - track CPU, memory, disk usage
- **Update templates** - keep base images current with security patches
- **Test disaster recovery** - validate restore procedures
- **Document infrastructure** - maintain README and runbooks
- **Review logs** - check Terraform and Proxmox logs regularly

## Troubleshooting

### Common Issues

**Issue:** Authentication failures

```text
Error: authentication failed
```

Solution:

- Verify API token is correct
- Check token has not expired
- Ensure user has proper permissions
- Test API access with curl

```bash
curl -k -H "Authorization: PVEAPIToken=terraform-prov@pve!terraform_id=your-token" \
  https://proxmox:8006/api2/json/version
```

**Issue:** Template not found

```text
Error: VM template 9000 not found
```

Solution:

- Verify template exists: `qm list`
- Check template ID in configuration
- Ensure template is on correct node
- Verify storage is accessible

**Issue:** IP address conflicts

```text
Error: IP address already in use
```

Solution:

- Check for duplicate IP assignments
- Use DHCP for dynamic environments
- Maintain IP address inventory
- Use Terraform data sources to query existing VMs

**Issue:** Disk space errors

```text
Error: not enough space on datastore
```

Solution:

- Check storage capacity: `pvesm status`
- Clean up old VM disks
- Use different storage pool
- Reduce disk size allocation

**Issue:** Slow provisioning

Solution:

- Use cloud-init for faster configuration
- Optimize template images (remove unnecessary packages)
- Use local storage instead of NFS for better performance
- Enable thin provisioning
- Use SSD storage pools

### Debug Mode

Enable detailed logging:

```bash
# Set Terraform debug mode
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

terraform apply

# Review debug log
less terraform-debug.log
```

## Advanced Topics

### Import Existing VMs

```bash
# Import existing VM into Terraform state
terraform import proxmox_virtual_environment_vm.imported_vm <node>/<vmid>

# Example
terraform import proxmox_virtual_environment_vm.imported_vm pve/105
```

### Using Data Sources

```hcl
# Query existing template
data "proxmox_virtual_environment_vms" "templates" {
  node_name = var.target_node
  
  filter {
    name   = "template"
    values = [true]
  }
}

# Use template in resource
resource "proxmox_virtual_environment_vm" "vm_from_data" {
  name      = "data-source-vm"
  node_name = var.target_node
  
  clone {
    vm_id = data.proxmox_virtual_environment_vms.templates.vms[0].vm_id
    full  = true
  }
  
  # ... rest of configuration
}
```

### Provisioners for Post-Deployment

```hcl
resource "proxmox_virtual_environment_vm" "provisioned_vm" {
  name      = "app-server"
  node_name = var.target_node
  
  # ... configuration ...
  
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo systemctl enable docker",
      "sudo systemctl start docker"
    ]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.ipv4_addresses[1][0]
    }
  }
}
```

## Additional Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Terraform Proxmox Provider (bpg)](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

**Important Notes:**

- Always test in a non-production environment first
- Maintain backups before making infrastructure changes
- Document custom configurations and network topology
- Use version control for all Terraform code
- Never commit sensitive credentials to version control
