---
title: "Terraform with VMware vSphere"
description: "Complete guide to using Terraform with VMware vSphere for enterprise infrastructure automation and virtual machine management"
author: "josephstreeter"
ms.date: "2026-01-18"
ms.topic: "how-to-guide"
ms.service: "terraform"
keywords: ["Terraform", "VMware", "vSphere", "ESXi", "Infrastructure as Code", "IaC", "Virtualization", "Automation", "vCenter"]
---

This guide demonstrates how to use Terraform to automate infrastructure provisioning and management on VMware vSphere. VMware vSphere is an enterprise-class virtualization platform that combines ESXi hypervisors with vCenter Server for centralized management of virtual infrastructure.

## Overview

Terraform enables Infrastructure as Code (IaC) for VMware vSphere environments, allowing you to:

- **Automate VM provisioning** - Create and manage virtual machines, templates, and clones programmatically
- **Manage vSphere infrastructure** - Configure resource pools, folders, datastores, and networks
- **Version control infrastructure** - Track all infrastructure changes in Git
- **Ensure consistency** - Deploy identical environments across data centers
- **Scale efficiently** - Provision multiple VMs and infrastructure components with minimal configuration
- **Integrate with CI/CD** - Automate infrastructure deployment pipelines
- **Multi-datacenter management** - Manage resources across multiple vCenter instances

The vSphere provider for Terraform leverages VMware's robust API to provide comprehensive control over your virtualization infrastructure.

## Prerequisites

### vSphere Environment Requirements

- VMware vSphere 6.5 or later (vSphere 7.x+ recommended)
- vCenter Server or standalone ESXi host
- At least one ESXi host with available resources
- VM templates or ISO images for provisioning
- Network connectivity to vCenter/ESXi management interface
- Valid vSphere license (Standard edition minimum for full features)

### Storage and Networking

- At least one datastore with sufficient free space
- Network port groups or distributed virtual port groups configured
- DHCP server or IP address management strategy
- DNS resolution (recommended for VM names)

### Local Development Requirements

- Terraform >= 1.0 installed
- Network access to vCenter Server or ESXi host (HTTPS/443)
- vSphere user credentials with appropriate permissions
- govc CLI tool (optional, for debugging and validation)

### Install Terraform

**Linux:**

```bash
# Download and install Terraform
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version
```

**macOS:**

```bash
# Using Homebrew
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform --version
```

**Windows:**

```powershell
# Using Chocolatey
choco install terraform

# Or download from HashiCorp website
# https://www.terraform.io/downloads
```

### Install govc (Optional)

The govc CLI tool is useful for debugging and validating vSphere configurations:

```bash
# Linux/macOS
curl -L -o - "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz" | tar -C /usr/local/bin -xvzf - govc

# Verify installation
govc version
```

## vSphere User and Permissions Setup

### Create Dedicated Service Account

For production environments, create a dedicated service account for Terraform with least-privilege permissions:

**Using vSphere Web Client:**

1. Navigate to **Administration** → **Users and Groups**
2. Click **Add User**
3. Enter username (e.g., `terraform-svc`)
4. Set a strong password
5. Click **OK**

**Using PowerCLI:**

```powershell
# Connect to vCenter
Connect-VIServer -Server vcenter.example.com

# Create local vCenter user
New-VIPermission -Entity (Get-Folder -NoRecursion) -Principal "terraform-svc@vsphere.local" -Role "Terraform-Role" -Propagate:$true
```

### Create Custom Role

Create a custom role with minimum required permissions:

**Required Permissions:**

- **Datastore:**
  - Allocate space
  - Browse datastore
  - Low level file operations

- **Network:**
  - Assign network

- **Resource:**
  - Assign virtual machine to resource pool

- **Virtual Machine:**
  - Configuration (all)
  - Interaction (all)
  - Inventory (all)
  - Provisioning (all)
  - Snapshot management (all)

**Create Role via vSphere Web Client:**

1. Navigate to **Administration** → **Roles**
2. Click **Create Role**
3. Name: `Terraform-Provisioner`
4. Select the permissions listed above
5. Click **OK**

**Create Role via govc:**

```bash
# Set environment variables
export GOVC_URL="vcenter.example.com"
export GOVC_USERNAME="administrator@vsphere.local"
export GOVC_PASSWORD="your-password"
export GOVC_INSECURE=1

# Create custom role
govc role.create Terraform-Provisioner \
  Datastore.AllocateSpace \
  Datastore.Browse \
  Datastore.FileManagement \
  Network.Assign \
  Resource.AssignVMToPool \
  VirtualMachine.Config.AddExistingDisk \
  VirtualMachine.Config.AddNewDisk \
  VirtualMachine.Config.AddRemoveDevice \
  VirtualMachine.Config.AdvancedConfig \
  VirtualMachine.Config.CPUCount \
  VirtualMachine.Config.Memory \
  VirtualMachine.Config.Network \
  VirtualMachine.Config.RawDevice \
  VirtualMachine.Config.Settings \
  VirtualMachine.Interact.PowerOff \
  VirtualMachine.Interact.PowerOn \
  VirtualMachine.Interact.Reset \
  VirtualMachine.Inventory.Create \
  VirtualMachine.Inventory.CreateFromExisting \
  VirtualMachine.Inventory.Delete \
  VirtualMachine.Inventory.Register \
  VirtualMachine.Inventory.Unregister \
  VirtualMachine.Provisioning.Clone \
  VirtualMachine.Provisioning.DeployTemplate \
  VirtualMachine.Provisioning.CloneTemplate \
  VirtualMachine.Provisioning.CreateTemplateFromVM \
  VirtualMachine.Provisioning.Customize \
  VirtualMachine.Provisioning.ReadCustSpecs \
  VirtualMachine.SnapshotManagement.CreateSnapshot \
  VirtualMachine.SnapshotManagement.RemoveSnapshot \
  VirtualMachine.SnapshotManagement.RevertToSnapshot
```

### Assign Permissions

Assign the custom role to the service account:

```bash
# Assign role to user on datacenter (propagates to child objects)
govc permissions.set -principal terraform-svc@vsphere.local -role Terraform-Provisioner /Datacenter-Name

# Verify permissions
govc permissions.ls /Datacenter-Name
```

### Security Best Practices

- **Never use administrator account** (`administrator@vsphere.local`) for Terraform automation
- **Use domain accounts** (Active Directory) for better auditing
- **Enable MFA** on privileged accounts when possible
- **Rotate credentials regularly** (every 90 days minimum)
- **Store credentials securely** using Terraform Cloud, Vault, or encrypted backends
- **Apply least-privilege principle** - only grant necessary permissions
- **Use separate accounts** for different environments (dev, staging, prod)
- **Enable vCenter audit logging** to track all API calls

## Terraform Provider Configuration

### Provider Installation

Create a `versions.tf` file to specify the vSphere provider:

```hcl
terraform {
 required_version = ">= 1.0"
 
 required_providers {
  vsphere = {
   source  = "hashicorp/vsphere"
   version = "~> 2.6"
  }
 }
}
```

### Basic Provider Configuration

Create a `provider.tf` file with vSphere connection details:

```hcl
provider "vsphere" {
 user                 = var.vsphere_user
 password             = var.vsphere_password
 vsphere_server       = var.vsphere_server
 allow_unverified_ssl = var.allow_unverified_ssl
}
```

### Variable Configuration

Create a `variables.tf` file for provider configuration:

```hcl
variable "vsphere_user" {
 description = "vSphere username"
 type        = string
 sensitive   = true
}

variable "vsphere_password" {
 description = "vSphere password"
 type        = string
 sensitive   = true
}

variable "vsphere_server" {
 description = "vSphere server address"
 type        = string
}

variable "allow_unverified_ssl" {
 description = "Allow unverified SSL certificates"
 type        = bool
 default     = false
}

variable "datacenter" {
 description = "vSphere datacenter name"
 type        = string
}

variable "cluster" {
 description = "vSphere cluster name"
 type        = string
 default     = ""
}

variable "resource_pool" {
 description = "vSphere resource pool name"
 type        = string
 default     = ""
}
```

### Credential Management

#### Option 1: Environment Variables (Recommended for Development)

```bash
# Set environment variables
export TF_VAR_vsphere_user="terraform-svc@vsphere.local"
export TF_VAR_vsphere_password="your-secure-password"
export TF_VAR_vsphere_server="vcenter.example.com"
export TF_VAR_datacenter="DC01"
export TF_VAR_cluster="Cluster01"

# Run Terraform
terraform init
terraform plan
```

#### Option 2: terraform.tfvars File (Development Only - DO NOT Commit)

Create `terraform.tfvars`:

```hcl
vsphere_user           = "terraform-svc@vsphere.local"
vsphere_password       = "your-secure-password"
vsphere_server         = "vcenter.example.com"
allow_unverified_ssl   = true
datacenter             = "DC01"
cluster                = "Cluster01"
resource_pool          = "Terraform-Pool"
```

Add to `.gitignore`:

```gitignore
# Terraform files
*.tfvars
*.tfvars.json
.terraform/
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.backup
*.tfstate
*.tfstate.*
```

#### Option 3: HashiCorp Vault (Production)

```hcl
data "vault_generic_secret" "vsphere_creds" {
 path = "secret/terraform/vsphere"
}

provider "vsphere" {
 user           = data.vault_generic_secret.vsphere_creds.data["username"]
 password       = data.vault_generic_secret.vsphere_creds.data["password"]
 vsphere_server = data.vault_generic_secret.vsphere_creds.data["server"]
}
```

#### Option 4: Terraform Cloud (Production)

Configure workspace variables in Terraform Cloud:

- `vsphere_user` (sensitive)
- `vsphere_password` (sensitive)
- `vsphere_server`
- `datacenter`

### Provider Configuration with API Timeout

For large environments, increase API timeout:

```hcl
provider "vsphere" {
 user                 = var.vsphere_user
 password             = var.vsphere_password
 vsphere_server       = var.vsphere_server
 allow_unverified_ssl = var.allow_unverified_ssl
 
 # Increase timeout for large environments
 api_timeout          = 30
 
 # Enable request/response logging for debugging
 # vim_keep_alive     = 10
}
```

### Multiple Provider Instances

Manage multiple vCenter instances or datacenters:

```hcl
provider "vsphere" {
 alias                = "primary"
 user                 = var.vsphere_user
 password             = var.vsphere_password
 vsphere_server       = "vcenter-primary.example.com"
 allow_unverified_ssl = false
}

provider "vsphere" {
 alias                = "dr"
 user                 = var.vsphere_user_dr
 password             = var.vsphere_password_dr
 vsphere_server       = "vcenter-dr.example.com"
 allow_unverified_ssl = false
}

# Use specific provider
resource "vsphere_virtual_machine" "vm_primary" {
 provider = vsphere.primary
 # ... configuration
}

resource "vsphere_virtual_machine" "vm_dr" {
 provider = vsphere.dr
 # ... configuration
}
```

## Data Sources

Data sources allow you to reference existing vSphere infrastructure components. These are essential for building VMs as they provide IDs for networks, datastores, templates, and other resources.

### Common Data Sources

Create a `data.tf` file to define your infrastructure references:

```hcl
# Datacenter
data "vsphere_datacenter" "dc" {
 name = var.datacenter
}

# Compute Cluster
data "vsphere_compute_cluster" "cluster" {
 name          = var.cluster
 datacenter_id = data.vsphere_datacenter.dc.id
}

# Resource Pool (optional - use cluster default if not specified)
data "vsphere_resource_pool" "pool" {
 name          = var.resource_pool != "" ? var.resource_pool : "${var.cluster}/Resources"
 datacenter_id = data.vsphere_datacenter.dc.id
}

# Datastore
data "vsphere_datastore" "datastore" {
 name          = var.datastore
 datacenter_id = data.vsphere_datacenter.dc.id
}

# Network
data "vsphere_network" "network" {
 name          = var.network_name
 datacenter_id = data.vsphere_datacenter.dc.id
}

# VM Template
data "vsphere_virtual_machine" "template" {
 name          = var.template_name
 datacenter_id = data.vsphere_datacenter.dc.id
}
```

### Additional Variables for Data Sources

Add to `variables.tf`:

```hcl
variable "datastore" {
 description = "Datastore name"
 type        = string
}

variable "network_name" {
    description = "Network name"
    type        = string
    default     = "VM Network"
}

variable "template_name" {
    description = "VM template name"
    type        = string
}
```

### Multiple Datastores

For environments with multiple datastores:

```hcl
# Primary datastore
data "vsphere_datastore" "datastore" {
 name          = var.datastore
 datacenter_id = data.vsphere_datacenter.dc.id
}

# Datastore cluster (for automatic datastore selection)
data "vsphere_datastore_cluster" "datastore_cluster" {
 name          = var.datastore_cluster_name
 datacenter_id = data.vsphere_datacenter.dc.id
}

# Find datastore by tag
data "vsphere_tag" "tier_gold" {
 name        = "tier:gold"
 category_id = data.vsphere_tag_category.tier.id
}

data "vsphere_datastores" "tagged_datastores" {
 datacenter_id = data.vsphere_datacenter.dc.id
 
 filter {
  tag_ids = [data.vsphere_tag.tier_gold.id]
 }
}
```

### Distributed Virtual Switch

For environments using distributed virtual switches:

```hcl
# Distributed Virtual Switch
data "vsphere_distributed_virtual_switch" "dvs" {
 name          = var.dvs_name
 datacenter_id = data.vsphere_datacenter.dc.id
}

# Distributed Port Group
data "vsphere_distributed_virtual_portgroup" "dvpg" {
 name                = var.portgroup_name
 datacenter_id       = data.vsphere_datacenter.dc.id
 distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id
}
```

### Content Library

For templates in vSphere Content Library:

```hcl
# Content Library
data "vsphere_content_library" "library" {
 name = var.content_library_name
}

# Content Library Item (Template)
data "vsphere_content_library_item" "template" {
 name       = var.content_library_item_name
 library_id = data.vsphere_content_library.library.id
 type       = "vm-template"
}
```

## Creating VM Templates

VM templates are essential for efficient provisioning. You can create templates from scratch or convert existing VMs.

### Method 1: Create Template from Ubuntu Cloud Image

```bash
# Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.ova

# Import using govc
govc import.ova -ds=datastore1 -pool=/DC01/host/Cluster01/Resources -name=ubuntu-22.04-template ubuntu-22.04-server-cloudimg-amd64.ova

# Convert to template
govc vm.markastemplate ubuntu-22.04-template
```

### Method 2: Create Template Using Packer

Create `ubuntu-template.pkr.hcl`:

```hcl
packer {
  required_plugins {
    vsphere = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

source "vsphere-iso" "ubuntu" {
  vcenter_server      = "vcenter.example.com"
  username            = "administrator@vsphere.local"
  password            = "password"
  insecure_connection = true
  
  datacenter = "DC01"
  cluster    = "Cluster01"
  datastore  = "datastore1"
  
  vm_name              = "ubuntu-22.04-template"
  guest_os_type        = "ubuntu64Guest"
  CPUs                 = 2
  RAM                  = 4096
  disk_controller_type = ["pvscsi"]
  
  storage {
    disk_size             = 32768
    disk_thin_provisioned = true
  }
  
  network_adapters {
    network      = "VM Network"
    network_card = "vmxnet3"
  }
  
  iso_paths = ["[datastore1] ISO/ubuntu-22.04-server-amd64.iso"]
  
  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_timeout  = "20m"
  
  boot_command = [
    "<wait><wait><wait><esc><wait>",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' ",
    "<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
  
  shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
  
  convert_to_template = true
}

build {
  sources = ["source.vsphere-iso.ubuntu"]
}
```

### Method 3: Manual Template Creation

1. Deploy a base VM with your desired OS
2. Install VMware Tools
3. Configure the OS (updates, packages, etc.)
4. Run sysprep (Windows) or cloud-init cleanup (Linux)
5. Shut down the VM
6. Right-click → **Template** → **Convert to Template**

### Template Best Practices

- **Install VMware Tools** or open-vm-tools for guest customization
- **Keep templates minimal** - install only essential software
- **Use cloud-init** for Linux templates (automatic configuration)
- **Regular updates** - rebuild templates monthly with latest patches
- **Version templates** - use naming like `ubuntu-22.04-v1`, `ubuntu-22.04-v2`
- **Test templates** before using in production
- **Document requirements** in template notes/annotations

## Basic VM Provisioning

### Simple VM from Template

Create `main.tf`:

```hcl
resource "vsphere_virtual_machine" "vm" {
  name             = "terraform-test-01"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder
  
  num_cpus = 2
  memory   = 4096
  guest_id = data.vsphere_virtual_machine.template.guest_id
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  
  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "terraform-test-01"
        domain    = "example.com"
      }
      
      network_interface {
        ipv4_address = "192.168.1.100"
        ipv4_netmask = 24
      }
      
      ipv4_gateway = "192.168.1.1"
      dns_server_list = ["8.8.8.8", "8.8.4.4"]
    }
  }
}
```

### VM with Cloud-Init

For Linux VMs with cloud-init support:

```hcl
resource "vsphere_virtual_machine" "vm" {
  name             = "ubuntu-vm-01"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  num_cpus = 2
  memory   = 4096
  guest_id = "ubuntu64Guest"
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  
  disk {
    label            = "disk0"
    size             = 32
    thin_provisioned = true
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  
  # Cloud-init configuration
  extra_config = {
    "guestinfo.metadata"          = base64encode(file("${path.module}/metadata.yaml"))
    "guestinfo.metadata.encoding" = "base64"
    "guestinfo.userdata"          = base64encode(file("${path.module}/userdata.yaml"))
    "guestinfo.userdata.encoding" = "base64"
  }
}
```

Create `metadata.yaml`:

```yaml
instance-id: ubuntu-vm-01
local-hostname: ubuntu-vm-01
network:
  version: 2
  ethernets:
    ens192:
      dhcp4: false
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

Create `userdata.yaml`:

```yaml
#cloud-config
users:
  - name: admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2E...

packages:
  - curl
  - wget
  - git
  - vim

runcmd:
  - apt update
  - apt upgrade -y
```

## Advanced VM Configuration

### Windows VM with Customization

```hcl
resource "vsphere_virtual_machine" "windows_vm" {
  name             = "windows-server-01"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Production/Windows"
  
  num_cpus  = 4
  memory    = 8192
  guest_id  = "windows2019srv_64Guest"
  firmware  = "efi"
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  
  disk {
    label            = "disk0"
    size             = 100
    thin_provisioned = true
    unit_number      = 0
  }
  
  # Additional data disk
  disk {
    label            = "disk1"
    size             = 500
    thin_provisioned = true
    unit_number      = 1
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.windows_template.id
    
    customize {
      windows_options {
        computer_name         = "WIN-SRV-01"
        workgroup            = "WORKGROUP"
        admin_password       = var.admin_password
        auto_logon           = false
        auto_logon_count     = 1
        time_zone            = 20  # Pacific Standard Time
        
        # Run commands after first boot
        run_once_command_list = [
          "powershell.exe -Command \"Set-ExecutionPolicy Bypass -Force\"",
          "powershell.exe -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools\""
        ]
      }
      
      network_interface {
        ipv4_address = "192.168.1.200"
        ipv4_netmask = 24
      }
      
      ipv4_gateway    = "192.168.1.1"
      dns_server_list = ["192.168.1.10", "192.168.1.11"]
      dns_suffix_list = ["example.com"]
    }
  }
  
  # Wait for guest customization to complete
  wait_for_guest_net_timeout = 10
}
```

### VM with Multiple Network Interfaces

```hcl
resource "vsphere_virtual_machine" "multi_nic_vm" {
  name             = "multi-nic-vm"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  num_cpus = 2
  memory   = 4096
  guest_id = "ubuntu64Guest"
  
  # Management network
  network_interface {
    network_id   = data.vsphere_network.management.id
    adapter_type = "vmxnet3"
  }
  
  # Data network
  network_interface {
    network_id   = data.vsphere_network.data.id
    adapter_type = "vmxnet3"
  }
  
  # Storage network
  network_interface {
    network_id   = data.vsphere_network.storage.id
    adapter_type = "vmxnet3"
  }
  
  disk {
    label            = "disk0"
    size             = 50
    thin_provisioned = true
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "multi-nic-vm"
        domain    = "example.com"
      }
      
      # Configure first NIC
      network_interface {
        ipv4_address = "192.168.1.100"
        ipv4_netmask = 24
      }
      
      # Configure second NIC
      network_interface {
        ipv4_address = "10.0.1.100"
        ipv4_netmask = 24
      }
      
      # Configure third NIC
      network_interface {
        ipv4_address = "10.0.2.100"
        ipv4_netmask = 24
      }
      
      ipv4_gateway    = "192.168.1.1"
      dns_server_list = ["8.8.8.8", "8.8.4.4"]
    }
  }
}
```

### VM with Custom Hardware Configuration

```hcl
resource "vsphere_virtual_machine" "custom_hardware" {
  name             = "custom-hardware-vm"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  # CPU configuration
  num_cpus                   = 8
  num_cores_per_socket       = 4
  cpu_hot_add_enabled        = true
  cpu_hot_remove_enabled     = true
  cpu_reservation            = 4000
  cpu_share_level            = "high"
  
  # Memory configuration
  memory                     = 16384
  memory_hot_add_enabled     = true
  memory_reservation         = 8192
  memory_share_level         = "high"
  
  # VM hardware version
  hardware_version           = 19  # vSphere 7.0 U2
  
  # Boot configuration
  firmware                   = "efi"
  efi_secure_boot_enabled    = true
  boot_delay                 = 5000
  
  # Enable vApp properties
  enable_disk_uuid           = true
  
  guest_id = "ubuntu64Guest"
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  
  # Boot disk with specific controller
  disk {
    label            = "disk0"
    size             = 100
    thin_provisioned = true
    eagerly_scrub    = false
    unit_number      = 0
  }
  
  # SCSI controller configuration
  scsi_type = "pvscsi"
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  
  # Custom attributes
  custom_attributes = {
    "Application" = "Web Server"
    "Environment" = "Production"
    "Owner"       = "DevOps Team"
  }
  
  # Tags
  tags = [
    data.vsphere_tag.environment_prod.id,
    data.vsphere_tag.application_web.id
  ]
  
  # Anti-affinity rule (don't run on same host as other VMs)
  # Defined separately as vsphere_compute_cluster_vm_anti_affinity_rule
}
```

### VM with vGPU

```hcl
resource "vsphere_virtual_machine" "gpu_vm" {
  name             = "gpu-workstation"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  num_cpus = 8
  memory   = 32768
  guest_id = "ubuntu64Guest"
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  
  disk {
    label            = "disk0"
    size             = 200
    thin_provisioned = false
  }
  
  # vGPU configuration
  pci_device_id = [
    data.vsphere_vgpu_profile.profile.id
  ]
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}

# vGPU profile data source
data "vsphere_vgpu_profile" "profile" {
  host_id = data.vsphere_host.esxi.id
  
  filter {
    name = "grid_p40-2q"
  }
}
```

## Complete Example: Multi-Tier Application

```hcl
# variables.tf
variable "vm_count" {
  description = "Number of web servers to create"
  type        = number
  default     = 3
}

# main.tf
# Web Server VMs
resource "vsphere_virtual_machine" "web" {
  count = var.vm_count
  
  name             = "web-${count.index + 1}"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Production/Web"
  
  num_cpus = 2
  memory   = 4096
  guest_id = data.vsphere_virtual_machine.template.guest_id
  
  network_interface {
    network_id   = data.vsphere_network.web.id
    adapter_type = "vmxnet3"
  }
  
  disk {
    label            = "disk0"
    size             = 50
    thin_provisioned = true
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "web-${count.index + 1}"
        domain    = "example.com"
      }
      
      network_interface {
        ipv4_address = "192.168.10.${count.index + 10}"
        ipv4_netmask = 24
      }
      
      ipv4_gateway    = "192.168.10.1"
      dns_server_list = ["8.8.8.8"]
    }
  }
  
  tags = [
    data.vsphere_tag.tier_web.id,
    data.vsphere_tag.environment_prod.id
  ]
}

# Application Server VM
resource "vsphere_virtual_machine" "app" {
  name             = "app-server-01"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Production/App"
  
  num_cpus = 4
  memory   = 8192
  guest_id = data.vsphere_virtual_machine.template.guest_id
  
  network_interface {
    network_id   = data.vsphere_network.app.id
    adapter_type = "vmxnet3"
  }
  
  disk {
    label            = "disk0"
    size             = 100
    thin_provisioned = true
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "app-server-01"
        domain    = "example.com"
      }
      
      network_interface {
        ipv4_address = "192.168.20.10"
        ipv4_netmask = 24
      }
      
      ipv4_gateway    = "192.168.20.1"
      dns_server_list = ["8.8.8.8"]
    }
  }
  
  tags = [
    data.vsphere_tag.tier_app.id,
    data.vsphere_tag.environment_prod.id
  ]
}

# Database Server VM
resource "vsphere_virtual_machine" "db" {
  name             = "db-server-01"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Production/Database"
  
  num_cpus = 8
  memory   = 16384
  guest_id = data.vsphere_virtual_machine.template.guest_id
  
  network_interface {
    network_id   = data.vsphere_network.db.id
    adapter_type = "vmxnet3"
  }
  
  disk {
    label            = "disk0"
    size             = 100
    thin_provisioned = true
  }
  
  # Database data disk
  disk {
    label            = "disk1"
    size             = 500
    thin_provisioned = false
    unit_number      = 1
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "db-server-01"
        domain    = "example.com"
      }
      
      network_interface {
        ipv4_address = "192.168.30.10"
        ipv4_netmask = 24
      }
      
      ipv4_gateway    = "192.168.30.1"
      dns_server_list = ["8.8.8.8"]
    }
  }
  
  tags = [
    data.vsphere_tag.tier_db.id,
    data.vsphere_tag.environment_prod.id
  ]
}

# Anti-affinity rule for web servers (spread across hosts)
resource "vsphere_compute_cluster_vm_anti_affinity_rule" "web_anti_affinity" {
  name                = "web-servers-anti-affinity"
  compute_cluster_id  = data.vsphere_compute_cluster.cluster.id
  virtual_machine_ids = vsphere_virtual_machine.web[*].id
}
```

## Storage Configuration

### Selecting from Multiple Datastores

```hcl
# Select datastore based on available space
data "vsphere_datastore" "available" {
  count = length(var.datastore_names)
  
  name          = var.datastore_names[count.index]
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Use datastore with most free space
locals {
  datastore_id = data.vsphere_datastore.available[
    index(
      data.vsphere_datastore.available[*].free_space,
      max(data.vsphere_datastore.available[*].free_space...)
    )
  ].id
}

resource "vsphere_virtual_machine" "vm" {
  name             = "auto-datastore-vm"
  datastore_id     = local.datastore_id
  # ... rest of configuration
}
```

### Storage DRS (Datastore Cluster)

```hcl
data "vsphere_datastore_cluster" "cluster" {
  name          = "DatastoreCluster01"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name                 = "storage-drs-vm"
  resource_pool_id     = data.vsphere_resource_pool.pool.id
  datastore_cluster_id = data.vsphere_datastore_cluster.cluster.id
  
  # Storage DRS will automatically select datastore
  
  num_cpus = 2
  memory   = 4096
  guest_id = "ubuntu64Guest"
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  
  disk {
    label            = "disk0"
    size             = 50
    thin_provisioned = true
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}
```

### Different Disk Types

```hcl
resource "vsphere_virtual_machine" "mixed_storage" {
  name             = "mixed-storage-vm"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.ssd.id
  
  num_cpus = 4
  memory   = 8192
  guest_id = "ubuntu64Guest"
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  
  # OS disk on SSD storage (thin provisioned)
  disk {
    label            = "disk0"
    size             = 100
    thin_provisioned = true
    datastore_id     = data.vsphere_datastore.ssd.id
  }
  
  # Data disk on HDD storage (thick provisioned, eager zeroed)
  disk {
    label            = "disk1"
    size             = 1000
    thin_provisioned = false
    eagerly_scrub    = true
    datastore_id     = data.vsphere_datastore.hdd.id
    unit_number      = 1
  }
  
  # Temp disk on NVMe storage
  disk {
    label            = "disk2"
    size             = 200
    thin_provisioned = true
    datastore_id     = data.vsphere_datastore.nvme.id
    unit_number      = 2
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}
```

### Attach Existing VMDK

```hcl
resource "vsphere_virtual_machine" "vm_with_existing_disk" {
  name             = "vm-with-existing-disk"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  num_cpus = 2
  memory   = 4096
  guest_id = "ubuntu64Guest"
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  
  # New boot disk
  disk {
    label            = "disk0"
    size             = 50
    thin_provisioned = true
  }
  
  # Attach existing VMDK
  disk {
    label        = "disk1"
    attach       = true
    path         = "existing-disk/data.vmdk"
    datastore_id = data.vsphere_datastore.datastore.id
    unit_number  = 1
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}
```

## Networking Configuration

### Standard Port Group

```hcl
# Create a standard port group
resource "vsphere_host_port_group" "pg" {
  name                = "Terraform-PG"
  host_system_id      = data.vsphere_host.host.id
  virtual_switch_name = "vSwitch0"
  
  vlan_id = 100
  
  active_nics  = ["vmnic0", "vmnic1"]
  standby_nics = ["vmnic2"]
}

# Use the port group
resource "vsphere_virtual_machine" "vm" {
  # ... other configuration
  
  network_interface {
    network_id   = vsphere_host_port_group.pg.id
    adapter_type = "vmxnet3"
  }
}
```

### Distributed Port Group

```hcl
# Create distributed port group
resource "vsphere_distributed_port_group" "dpg" {
  name                            = "Terraform-DPG"
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id
  
  vlan_id = 100
  
  # VLAN range (optional)
  # vlan_range {
  #   min_vlan = 100
  #   max_vlan = 200
  # }
  
  # Port binding
  port_config_reset_at_disconnect = true
  
  # Teaming and failover
  active_uplinks  = ["uplink1", "uplink2"]
  standby_uplinks = ["uplink3"]
  
  # Security policies
  allow_promiscuous      = false
  allow_forged_transmits = false
  allow_mac_changes      = false
  
  # Traffic shaping
  ingress_shaping_enabled = false
  egress_shaping_enabled  = false
}
```

### NSX-T Logical Switch

```hcl
# For environments using NSX-T
data "vsphere_network" "nsx_segment" {
  name          = "nsx-segment-web"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "nsx_vm" {
  name             = "nsx-vm"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  num_cpus = 2
  memory   = 4096
  guest_id = "ubuntu64Guest"
  
  network_interface {
    network_id   = data.vsphere_network.nsx_segment.id
    adapter_type = "vmxnet3"
  }
  
  disk {
    label            = "disk0"
    size             = 50
    thin_provisioned = true
  }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}
```

## Outputs

Define outputs to capture important VM information:

```hcl
# outputs.tf
output "vm_ip_addresses" {
  description = "IP addresses of all VMs"
  value = {
    web = vsphere_virtual_machine.web[*].default_ip_address
    app = vsphere_virtual_machine.app.default_ip_address
    db  = vsphere_virtual_machine.db.default_ip_address
  }
}

output "vm_ids" {
  description = "VM IDs for reference"
  value = {
    web = vsphere_virtual_machine.web[*].id
    app = vsphere_virtual_machine.app.id
    db  = vsphere_virtual_machine.db.id
  }
}

output "vm_uuids" {
  description = "VM UUIDs"
  value = {
    web = vsphere_virtual_machine.web[*].uuid
    app = vsphere_virtual_machine.app.uuid
    db  = vsphere_virtual_machine.db.uuid
  }
}

output "vm_names" {
  description = "VM names"
  value = {
    web = vsphere_virtual_machine.web[*].name
    app = vsphere_virtual_machine.app.name
    db  = vsphere_virtual_machine.db.name
  }
}

output "vm_guest_info" {
  description = "Guest OS information"
  value = {
    web_hostname = vsphere_virtual_machine.web[*].guest_ip_addresses
    app_hostname = vsphere_virtual_machine.app.guest_ip_addresses
    db_hostname  = vsphere_virtual_machine.db.guest_ip_addresses
  }
}

# For Ansible inventory
output "ansible_inventory" {
  description = "Ansible inventory format"
  value = templatefile("${path.module}/inventory.tpl", {
    web_ips = vsphere_virtual_machine.web[*].default_ip_address
    app_ip  = vsphere_virtual_machine.app.default_ip_address
    db_ip   = vsphere_virtual_machine.db.default_ip_address
  })
}
```

Example `inventory.tpl`:

```ini
[web_servers]
%{ for ip in web_ips ~}
${ip}
%{ endfor ~}

[app_servers]
${app_ip}

[db_servers]
${db_ip}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

## State Management

### Local State

Basic local state for development:

```hcl
# No backend configuration - uses local state
terraform {
  required_version = ">= 1.0"
}
```

### Remote State with Terraform Cloud

```hcl
terraform {
  cloud {
    organization = "your-org"
    
    workspaces {
      name = "vmware-production"
    }
  }
}
```

### Remote State with S3

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "vmware/prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Remote State with Azure Storage

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstate"
    container_name       = "tfstate"
    key                  = "vmware.terraform.tfstate"
  }
}
```

## Deployment Workflow

### Initial Setup

```bash
# 1. Initialize Terraform
terraform init

# 2. Validate configuration
terraform validate

# 3. Format code
terraform fmt -recursive

# 4. Review execution plan
terraform plan -out=tfplan

# 5. Apply changes
terraform apply tfplan

# 6. View outputs
terraform output
```

### Updating Infrastructure

```bash
# Make changes to .tf files

# Check what will change
terraform plan

# Apply changes
terraform apply

# Target specific resources if needed
terraform apply -target=vsphere_virtual_machine.web[0]
```

### Destroying Infrastructure

```bash
# Destroy all resources
terraform destroy

# Destroy specific resources
terraform destroy -target=vsphere_virtual_machine.web[2]

# Preview destroy
terraform plan -destroy
```

### Working with State

```bash
# List resources in state
terraform state list

# Show resource details
terraform state show vsphere_virtual_machine.web[0]

# Remove resource from state (doesn't destroy)
terraform state rm vsphere_virtual_machine.old_vm

# Import existing VM
terraform import vsphere_virtual_machine.imported /DC01/vm/folder/vm-name

# Move resource in state
terraform state mv vsphere_virtual_machine.old vsphere_virtual_machine.new
```

## Module Organization

### Create Reusable VM Module

```hcl
# modules/vsphere-vm/main.tf
variable "vm_name" {
  type = string
}

variable "vm_count" {
  type    = number
  default = 1
}

variable "num_cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

variable "disk_size" {
  type    = number
  default = 50
}

variable "network_id" {
  type = string
}

variable "datastore_id" {
  type = string
}

variable "resource_pool_id" {
  type = string
}

variable "template_id" {
  type = string
}

variable "folder" {
  type    = string
  default = ""
}

variable "tags" {
  type    = list(string)
  default = []
}

resource "vsphere_virtual_machine" "vm" {
  count = var.vm_count
  
  name             = var.vm_count > 1 ? "${var.vm_name}-${count.index + 1}" : var.vm_name
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  folder           = var.folder
  
  num_cpus = var.num_cpus
  memory   = var.memory
  guest_id = "ubuntu64Guest"
  
  network_interface {
    network_id   = var.network_id
    adapter_type = "vmxnet3"
  }
  
  disk {
    label            = "disk0"
    size             = var.disk_size
    thin_provisioned = true
  }
  
  clone {
    template_uuid = var.template_id
  }
  
  tags = var.tags
}

output "vm_ids" {
  value = vsphere_virtual_machine.vm[*].id
}

output "vm_ips" {
  value = vsphere_virtual_machine.vm[*].default_ip_address
}
```

### Use Module

```hcl
# main.tf
module "web_servers" {
  source = "./modules/vsphere-vm"
  
  vm_name           = "web-server"
  vm_count          = 3
  num_cpus          = 2
  memory            = 4096
  disk_size         = 50
  network_id        = data.vsphere_network.web.id
  datastore_id      = data.vsphere_datastore.datastore.id
  resource_pool_id  = data.vsphere_resource_pool.pool.id
  template_id       = data.vsphere_virtual_machine.template.id
  folder            = "Production/Web"
  tags              = [data.vsphere_tag.web.id]
}

module "app_servers" {
  source = "./modules/vsphere-vm"
  
  vm_name           = "app-server"
  vm_count          = 2
  num_cpus          = 4
  memory            = 8192
  disk_size         = 100
  network_id        = data.vsphere_network.app.id
  datastore_id      = data.vsphere_datastore.datastore.id
  resource_pool_id  = data.vsphere_resource_pool.pool.id
  template_id       = data.vsphere_virtual_machine.template.id
  folder            = "Production/App"
  tags              = [data.vsphere_tag.app.id]
}

output "web_server_ips" {
  value = module.web_servers.vm_ips
}

output "app_server_ips" {
  value = module.app_servers.vm_ips
}
```

## Best Practices

### General Best Practices

- **Use version control** - Track all Terraform code in Git
- **Remote state** - Use remote backends (Terraform Cloud, S3, Azure) for team collaboration
- **State locking** - Enable state locking to prevent concurrent modifications
- **Workspaces** - Use workspaces or separate state files for different environments
- **Modules** - Create reusable modules for common VM configurations
- **Variables** - Externalize all environment-specific values
- **Outputs** - Capture important information for other tools/processes
- **Tags** - Use vSphere tags for organization and cost tracking
- **Naming conventions** - Implement consistent naming across all resources

### Security Practices

- **Credential management** - Never commit credentials to version control
- **Use service accounts** - Create dedicated accounts with minimum required permissions
- **Rotate credentials** - Regularly update API credentials and passwords
- **Enable audit logging** - Track all vCenter API calls for compliance
- **Secure state files** - Encrypt state files and restrict access
- **Sensitive outputs** - Mark sensitive outputs appropriately
- **Template security** - Keep VM templates updated with security patches

### Performance Best Practices

- **Resource pools** - Use resource pools for better resource allocation
- **Thin provisioning** - Use thin provisioning for storage efficiency
- **Storage DRS** - Enable Storage DRS for automatic load balancing
- **Anti-affinity rules** - Spread critical VMs across hosts
- **VM hardware version** - Use latest compatible VM hardware version
- **PVSCSI adapters** - Use paravirtual SCSI for better performance
- **VMXNET3 adapters** - Use VMXNET3 network adapters for better network performance

### Automation Best Practices

- **CI/CD integration** - Automate deployment with GitLab CI, GitHub Actions, or Jenkins
- **Plan before apply** - Always review execution plans before applying
- **Incremental changes** - Make small, incremental changes rather than large updates
- **Testing** - Test changes in development environment first
- **Documentation** - Document complex configurations and dependencies
- **Drift detection** - Regularly run `terraform plan` to detect configuration drift

### Code Organization

```text
terraform-vsphere/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   └── ...
│   └── prod/
│       └── ...
├── modules/
│   ├── vm/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── network/
│   │   └── ...
│   └── storage/
│       └── ...
├── .gitignore
└── README.md
```

## Troubleshooting

### Common Issues and Solutions

#### Connection Issues

**Problem:** Unable to connect to vCenter

```text
Error: Post "https://vcenter.example.com/sdk": dial tcp: lookup vcenter.example.com: no such host
```

**Solutions:**

```bash
# Verify DNS resolution
nslookup vcenter.example.com

# Verify network connectivity
ping vcenter.example.com
nc -zv vcenter.example.com 443

# Check firewall rules
telnet vcenter.example.com 443

# Try with IP address instead
export TF_VAR_vsphere_server="192.168.1.10"
```

#### Authentication Failures

**Problem:** Invalid credentials

```text
Error: ServerFaultCode: Cannot complete login due to an incorrect user name or password.
```

**Solutions:**

```bash
# Verify credentials manually with govc
export GOVC_URL="vcenter.example.com"
export GOVC_USERNAME="administrator@vsphere.local"
export GOVC_PASSWORD="your-password"
export GOVC_INSECURE=1
govc about

# Check for special characters in password
# URL encode if necessary

# Verify account is not locked
# Check vCenter audit logs
```

#### Template Not Found

**Problem:** Template doesn't exist

```text
Error: virtual machine or template "ubuntu-template" not found in datacenter "DC01"
```

**Solutions:**

```bash
# List all VMs and templates
govc find -type m

# Check specific template
govc vm.info ubuntu-template

# Verify datacenter name
govc datacenter.info DC01

# Use full path if in folder
data "vsphere_virtual_machine" "template" {
  name          = "/DC01/vm/Templates/ubuntu-template"
  datacenter_id = data.vsphere_datacenter.dc.id
}
```

#### Insufficient Permissions

**Problem:** Permission denied

```text
Error: ServerFaultCode: The method is disabled by 'your-user@vsphere.local'
```

**Solutions:**

```bash
# Check user permissions
govc permissions.ls -i /DC01

# Verify role assignments
govc role.ls

# Grant missing permissions
# See "Create Custom Role" section

# Use account with proper permissions
```

#### Network Not Found

**Problem:** Network doesn't exist

```text
Error: network "VM Network" not found in datacenter "DC01"
```

**Solutions:**

```bash
# List all networks
govc find / -type n

# List networks in specific datacenter
govc ls /DC01/network/

# For distributed port groups
govc dvs.portgroup.info /DC01/network/DPG-Name

# Verify exact name (case sensitive)
```

#### Customization Failures

**Problem:** Guest customization fails

```text
Error: error reconfiguring virtual machine: A specified parameter was not correct: spec.identity
```

**Solutions:**

- **Verify VMware Tools installed** in template
- **Check template is properly sysprepped** (Windows) or has cloud-init (Linux)
- **Verify network configuration** is valid
- **Use cloud-init instead** of guest customization for Linux

```hcl
# Skip customization and use cloud-init
clone {
  template_uuid = data.vsphere_virtual_machine.template.id
}

extra_config = {
  "guestinfo.userdata"          = base64encode(file("userdata.yaml"))
  "guestinfo.userdata.encoding" = "base64"
}
```

#### Storage Issues

**Problem:** Insufficient datastore space

```text
Error: ServerFaultCode: There is not enough space on the datastore
```

**Solutions:**

```bash
# Check datastore space
govc datastore.info datastore1

# Use different datastore
# Enable thin provisioning
disk {
  label            = "disk0"
  size             = 50
  thin_provisioned = true  # Use thin provisioning
}

# Use Storage DRS
datastore_cluster_id = data.vsphere_datastore_cluster.cluster.id
```

#### State Lock Issues

**Problem:** State file locked

```text
Error: Error acquiring the state lock
```

**Solutions:**

```bash
# Check who has lock
terraform force-unlock <LOCK_ID>

# If using S3 backend, check DynamoDB table
aws dynamodb get-item --table-name terraform-locks --key '{"LockID": {"S": "terraform-state-bucket/path/to/terraform.tfstate"}}'

# Last resort - manually remove lock (dangerous!)
# Only if you're SURE no one else is running Terraform
```

### Debugging Tips

#### Enable Debug Logging

```bash
# Set debug level
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

# Run Terraform
terraform plan

# Review logs
grep -i error terraform-debug.log
```

#### Use govc for Validation

```bash
# Verify data sources
govc find / -type ClusterComputeResource
govc find / -type Datastore
govc find / -type Network

# Check resource details
govc cluster.info Cluster01
govc datastore.info datastore1
govc network.info "VM Network"

# VM operations
govc vm.info vm-name
govc vm.ip vm-name
```

#### Terraform Console

```bash
# Test expressions interactively
terraform console

# Try data source queries
> data.vsphere_datacenter.dc.name
> data.vsphere_compute_cluster.cluster.id
> data.vsphere_datastore.datastore.free_space
```

#### State Inspection

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show vsphere_virtual_machine.vm

# Check for drift
terraform plan -refresh-only
```

## Advanced Topics

### Using Terraform with vRealize Automation

Integrate Terraform with vRealize Automation for advanced workflows:

```hcl
# Use vRA as orchestration layer
# Terraform manages actual resources
# vRA handles approvals, CMDB updates, etc.

resource "vsphere_virtual_machine" "vra_managed" {
  name             = var.vra_deployment_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  # ... configuration
  
  # Tag with vRA deployment ID
  custom_attributes = {
    "vra_deployment_id" = var.vra_deployment_id
    "vra_project"       = var.vra_project
  }
}
```

### Multi-Region Deployment

Deploy across multiple vCenter instances:

```hcl
# providers.tf
provider "vsphere" {
  alias        = "us_west"
  user         = var.vsphere_user
  password     = var.vsphere_password
  vsphere_server = "vcenter-us-west.example.com"
}

provider "vsphere" {
  alias        = "us_east"
  user         = var.vsphere_user
  password     = var.vsphere_password
  vsphere_server = "vcenter-us-east.example.com"
}

# Deploy to multiple regions
module "web_us_west" {
  source = "./modules/web-tier"
  providers = {
    vsphere = vsphere.us_west
  }
  region = "us-west"
}

module "web_us_east" {
  source = "./modules/web-tier"
  providers = {
    vsphere = vsphere.us_east
  }
  region = "us-east"
}
```

### Automated DR with Cross-vCenter vMotion

```hcl
# Primary site VM
resource "vsphere_virtual_machine" "primary" {
  provider = vsphere.primary
  # ... configuration
}

# DR site configuration (for failover)
resource "vsphere_virtual_machine" "dr" {
  provider = vsphere.dr
  # ... configuration
  
  # Only create if DR failover is triggered
  count = var.dr_failover_enabled ? 1 : 0
}
```

### Integration with Ansible

Export Terraform outputs for Ansible automation:

```hcl
# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    web_servers = {
      for vm in vsphere_virtual_machine.web : vm.name => vm.default_ip_address
    }
    app_servers = {
      for vm in vsphere_virtual_machine.app : vm.name => vm.default_ip_address
    }
  })
  filename = "${path.module}/inventory.ini"
}

# Run Ansible after VM creation
resource "null_resource" "ansible_provisioner" {
  depends_on = [vsphere_virtual_machine.web]
  
  provisioner "local-exec" {
    command = "ansible-playbook -i inventory.ini site.yml"
  }
}
```

### Disaster Recovery Automation

```hcl
# Snapshot before changes
resource "vsphere_virtual_machine_snapshot" "pre_change" {
  count              = var.create_snapshot ? 1 : 0
  virtual_machine_id = vsphere_virtual_machine.app.id
  snapshot_name      = "pre-terraform-change-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  description        = "Snapshot before Terraform changes"
  memory             = true
  quiesce            = true
}
```

### Cost Optimization

```hcl
# Auto-shutdown for dev VMs
resource "vsphere_virtual_machine" "dev_vm" {
  # ... configuration
  
  # Tag for automated shutdown
  custom_attributes = {
    "auto_shutdown" = "enabled"
    "shutdown_time" = "18:00"
    "timezone"      = "America/Los_Angeles"
  }
}

# Use resource pools for cost allocation
resource "vsphere_resource_pool" "dev_team" {
  name                    = "DevTeam"
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  
  cpu_share_level = "low"
  memory_share_level = "low"
  
  cpu_limit = 20000  # MHz
  memory_limit = 32768  # MB
}
```

## Additional Resources

### Official Documentation

- [Terraform vSphere Provider Documentation](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs)
- [VMware vSphere Documentation](https://docs.vmware.com/en/VMware-vSphere/index.html)
- [VMware vCenter API Reference](https://developer.vmware.com/apis/1355/vsphere)
- [Terraform Documentation](https://www.terraform.io/docs)
- [HashiCorp Learn - vSphere Provider](https://learn.hashicorp.com/tutorials/terraform/vsphere-provider)

### Tools and Utilities

- [govc - vSphere CLI](https://github.com/vmware/govmomi/tree/master/govc)
- [Packer - Template Builder](https://www.packer.io/)
- [Terraform Cloud](https://cloud.hashicorp.com/products/terraform)
- [HashiCorp Vault](https://www.vaultproject.io/)

### Community Resources

- [Terraform Registry - vSphere Modules](https://registry.terraform.io/search/modules?q=vsphere)
- [VMware Code Samples](https://github.com/vmware)
- [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform-core)
- [r/Terraform Subreddit](https://www.reddit.com/r/Terraform/)

### Example Repositories

- [Terraform vSphere Examples](https://github.com/hashicorp/terraform-provider-vsphere/tree/main/examples)
- [VMware Terraform Examples](https://github.com/vmware-samples/terraform-provider-vsphere-examples)

### Learning Resources

- [VMware Hands-on Labs](https://hol.vmware.com/)
- [HashiCorp Certification](https://www.hashicorp.com/certification/terraform-associate)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## Summary

This guide covered comprehensive Terraform usage with VMware vSphere:

- **Provider Setup** - Authentication, permissions, and configuration
- **Data Sources** - Referencing existing vSphere infrastructure
- **VM Provisioning** - From simple VMs to complex multi-tier applications
- **Advanced Features** - Custom hardware, multiple NICs, vGPU support
- **Storage & Networking** - Datastores, Storage DRS, DVS, NSX-T integration
- **Automation** - Modules, CI/CD, and workflow optimization
- **Best Practices** - Security, performance, and organizational standards
- **Troubleshooting** - Common issues and debugging techniques

Terraform provides powerful infrastructure-as-code capabilities for VMware vSphere environments, enabling consistent, repeatable, and version-controlled infrastructure deployment at scale. Combined with proper planning, security practices, and automation workflows, it becomes an essential tool for modern VMware infrastructure management.
