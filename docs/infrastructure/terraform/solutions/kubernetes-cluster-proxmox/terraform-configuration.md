---
title: "Terraform Configuration"
description: "Core Terraform configuration for Proxmox Kubernetes nodes: providers, variables, data sources, resources, and outputs"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "providers", "variables", "cloud-init"]
category: "infrastructure"
last_updated: "2026-08-01"
---
## Terraform Configuration

### Project Structure

```text
kubernetes-cluster/
├── main.tf                    # Main resource definitions
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # Provider configurations
├── data.tf                    # Data sources for dynamic queries
├── terraform.tfvars           # Variable values (DO NOT COMMIT)
├── cloud-init/
│   ├── k8s-node.yaml          # Cloud-init configuration for K8s nodes
│   └── haproxy-cloud-init.yml # HAProxy load balancer cloud-init
├── modules/
│   ├── k8s-node/              # Reusable node module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   └── load-balancer/         # Load balancer module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── scripts/
│   └── k8s-setup.sh           # Post-deployment scripts
├── templates/
│   ├── haproxy-cloud-init.tpl # HAProxy cloud-init template
│   └── inventory.tpl          # Ansible inventory template
├── ansible/
│   └── playbooks/
│       └── k8s-cluster.yml    # Ansible Kubernetes setup
├── packer/
│   ├── debian-k8s-template.pkr.hcl  # Packer template
│   └── scripts/
│       └── k8s-prep.sh        # Packer provisioning script
└── .github/
    └── workflows/
        ├── terraform-plan.yml  # GitHub Actions plan workflow
        └── terraform-apply.yml # GitHub Actions apply workflow
```

### Initialize Project Structure

Use this script to create the complete directory structure and placeholder files:

```bash
#!/bin/bash
# Script to initialize Kubernetes-Cluster Terraform project structure

set -e

PROJECT_NAME="kubernetes-cluster"

echo "Creating project structure for $PROJECT_NAME..."

# Create project root
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create directories
echo "Creating directories..."
mkdir -p cloud-init
mkdir -p modules/k8s-node
mkdir -p modules/load-balancer
mkdir -p scripts
mkdir -p templates
mkdir -p ansible/playbooks
mkdir -p packer/scripts
mkdir -p .github/workflows

# Create root-level Terraform files
echo "Creating Terraform configuration files..."

cat > main.tf << 'EOF'
# Main resource definitions
# See documentation for complete configuration
EOF

cat > variables.tf << 'EOF'
# Input variables
# See documentation for complete variable definitions
EOF

cat > outputs.tf << 'EOF'
# Output values
# See documentation for complete output definitions
EOF

cat > providers.tf << 'EOF'
# Provider configurations
# See documentation for complete provider setup
EOF

cat > data.tf << 'EOF'
# Data sources for dynamic queries
# See documentation for data source examples
EOF

cat > terraform.tfvars.example << 'EOF'
# Variable values template
# Copy to terraform.tfvars and customize
# WARNING: Never commit terraform.tfvars to version control
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Terraform files
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
terraform.tfvars
*.auto.tfvars

# Sensitive files
*.pem
*.key
kubeconfig/
*.conf

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
EOF

# Create cloud-init files
echo "Creating cloud-init configurations..."

cat > cloud-init/k8s-node.yaml << 'EOF'
#cloud-config
# Kubernetes Node Preparation via Cloud-Init
# See documentation for complete configuration
EOF

cat > cloud-init/haproxy-cloud-init.yml << 'EOF'
#cloud-config
# HAProxy Load Balancer Cloud-Init
# See documentation for complete configuration
EOF

# Create templates
echo "Creating template files..."

cat > templates/haproxy-cloud-init.tpl << 'EOF'
# HAProxy cloud-init template
# See documentation for complete template configuration
EOF

cat > templates/inventory.tpl << 'EOF'
# Ansible inventory template
# See documentation for complete template configuration
EOF

# Create k8s-node module files
echo "Creating k8s-node module..."

cat > modules/k8s-node/main.tf << 'EOF'
# K8s node module resources
# See documentation for complete module configuration
EOF

cat > modules/k8s-node/variables.tf << 'EOF'
# K8s node module variables
# See documentation for variable definitions
EOF

cat > modules/k8s-node/outputs.tf << 'EOF'
# K8s node module outputs
# See documentation for output definitions
EOF

cat > modules/k8s-node/versions.tf << 'EOF'
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}
EOF

# Create load-balancer module files
echo "Creating load-balancer module..."

cat > modules/load-balancer/main.tf << 'EOF'
# Load balancer module resources
# See documentation for complete module configuration
EOF

cat > modules/load-balancer/variables.tf << 'EOF'
# Load balancer module variables
# See documentation for variable definitions
EOF

cat > modules/load-balancer/outputs.tf << 'EOF'
# Load balancer module outputs
# See documentation for output definitions
EOF

cat > modules/load-balancer/versions.tf << 'EOF'
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}
EOF

# Create scripts
echo "Creating scripts..."

cat > scripts/k8s-setup.sh << 'EOF'
#!/bin/bash
# Post-deployment Kubernetes setup script
# See documentation for usage instructions
EOF

chmod +x scripts/k8s-setup.sh

# Create Ansible playbooks
echo "Creating Ansible playbooks..."

cat > ansible/playbooks/k8s-cluster.yml << 'EOF'
---
# Ansible playbook for Kubernetes cluster setup
# See documentation for complete playbook configuration
EOF

# Create Packer files
echo "Creating Packer configuration..."

cat > packer/debian-k8s-template.pkr.hcl << 'EOF'
# Packer template for Debian-based K8s nodes
# See documentation for complete template configuration
EOF

cat > packer/scripts/k8s-prep.sh << 'EOF'
#!/bin/bash
# Packer provisioning script for K8s preparation
# See documentation for usage instructions
EOF

chmod +x packer/scripts/k8s-prep.sh

# Create GitHub Actions workflows
echo "Creating GitHub Actions workflows..."

cat > .github/workflows/terraform-plan.yml << 'EOF'
name: Terraform Plan
# See documentation for complete workflow configuration
EOF

cat > .github/workflows/terraform-apply.yml << 'EOF'
name: Terraform Apply
# See documentation for complete workflow configuration
EOF

# Create README
cat > README.md << 'EOF'
# Kubernetes Cluster on Proxmox with Terraform

This project provisions Kubernetes cluster infrastructure on Proxmox VE using Terraform.

## Getting Started

1. Review and customize `terraform.tfvars.example`
2. Copy to `terraform.tfvars` with your values
3. Initialize Terraform: `terraform init`
4. Plan deployment: `terraform plan`
5. Apply configuration: `terraform apply`

## Documentation

Refer to the complete documentation for detailed configuration examples and best practices.

## Security Notes

- Never commit `terraform.tfvars` or files containing secrets
- Use secure secret management for production deployments
- Generate unique SSH keys for each environment
- Enable TLS verification for Proxmox API connections

EOF

echo ""
echo "✅ Project structure created successfully!"
echo ""
echo "Next steps:"
echo "1. Copy terraform.tfvars.example to terraform.tfvars:"
echo "   cp terraform.tfvars.example terraform.tfvars"
echo "2. Edit terraform.tfvars with your actual values"
echo "3. Copy configuration examples from documentation into module files"
echo "4. Initialize Terraform: terraform init"
echo "5. Validate configuration: terraform validate"
echo "6. Plan deployment: terraform plan"
echo ""
echo "⚠️  IMPORTANT: Never commit terraform.tfvars or sensitive files to version control!"
```

Run the script to create the project structure:

```bash
chmod +x create-project-structure.sh
./create-project-structure.sh

# After running the script, copy and customize your configuration:
cd kubernetes-cluster
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual values
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

variable "lb_ip_address" {
  type        = string
  description = "Load balancer IP address"
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.lb_ip_address))
    error_message = "Load balancer IP must be a valid IPv4 address"
  }
  default     = "192.168.100.5"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to install"
  default     = "1.28.3"
}
```

### `data.tf`

Validate configuration and define dynamic values:

```hcl
# Local validations and computed values
locals {
  # Validate storage and network configuration
  valid_storage = var.storage != ""
  valid_network = var.network_bridge != ""
  
  # Validate that enable_ha requires lb_ip_address
  ha_config_valid = !var.enable_ha || (var.enable_ha && var.lb_ip_address != "")
}

# Validation checks
resource "null_resource" "validate_ha_config" {
  count = var.enable_ha && var.lb_ip_address == "" ? "ERROR: enable_ha requires lb_ip_address to be set" : 0
}
```

> **Note:** The telmate/proxmox provider doesn't support data sources for querying Proxmox nodes or versions. All configuration must be provided via variables.

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
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
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

Main configuration using modular approach for better organization and reusability:

```hcl
# Local values for common configurations
locals {
  all_nodes = merge(var.master_nodes, var.worker_nodes)
  
  # Kubernetes constants
  k8s_api_port              = 6443
  haproxy_stats_port        = 8404
  node_exporter_port        = 9100
  
  # Network configuration
  pod_network_cidr_default  = "10.244.0.0/16"
  service_cidr_default      = "10.96.0.0/12"
  
  # Common VM settings
  network_cidr = split("/", var.cluster_network.subnet)[1]
  cloud_init_snippet = "k8s-node.yaml"
}

# Master nodes using k8s-node module
module "k8s_masters" {
  source   = "./modules/k8s-node"
  for_each = var.master_nodes

  # VM identification
  vmid        = each.value.vmid
  name        = "${var.cluster_name}-${each.key}"
  target_node = var.target_node
  
  # Resource allocation
  cores  = each.value.cores
  memory = each.value.memory
  disk_size = each.value.disk
  
  # Template and storage
  template_name  = var.template_name
  storage        = var.storage
  
  # Network configuration
  network_bridge = var.network_bridge
  ip_address     = each.value.ip
  ip_cidr        = local.network_cidr
  gateway        = var.cluster_network.gateway
  dns_servers    = var.cluster_network.dns
  
  # Cloud-init
  cloud_init_file = local.cloud_init_snippet
  cloud_init_user = var.cloud_init_user
  ssh_public_key  = var.ssh_public_key
}

# Worker nodes using k8s-node module
module "k8s_workers" {
  source   = "./modules/k8s-node"
  for_each = var.worker_nodes

  # VM identification
  vmid        = each.value.vmid
  name        = "${var.cluster_name}-${each.key}"
  target_node = var.target_node
  
  # Resource allocation
  cores  = each.value.cores
  memory = each.value.memory
  disk_size = each.value.disk
  
  # Template and storage
  template_name  = var.template_name
  storage        = var.storage
  
  # Network configuration
  network_bridge = var.network_bridge
  ip_address     = each.value.ip
  ip_cidr        = local.network_cidr
  gateway        = var.cluster_network.gateway
  dns_servers    = var.cluster_network.dns
  
  # Cloud-init
  cloud_init_file = local.cloud_init_snippet
  cloud_init_user = var.cloud_init_user
  ssh_public_key  = var.ssh_public_key
}

# Optional: HAProxy Load Balancer for HA setup
module "k8s_lb" {
  count  = var.enable_ha ? 1 : 0
  source = "./modules/load-balancer"

  # VM identification
  vmid        = 100
  name        = "${var.cluster_name}-lb"
  target_node = var.target_node
  
  # Resource allocation
  cores  = 2
  memory = 2048
  disk_size = "10G"
  
  # Template and storage
  template_name  = var.template_name
  storage        = var.storage
  
  # Network configuration
  network_bridge = var.network_bridge
  ip_address     = var.lb_ip_address
  ip_cidr        = local.network_cidr
  gateway        = var.cluster_network.gateway
  dns_servers    = var.cluster_network.dns
  
  # Cloud-init
  cloud_init_file = "haproxy-cloud-init.yml"
  cloud_init_user = var.cloud_init_user
  ssh_public_key  = var.ssh_public_key
}
```

> **Note:** The load balancer module creates the VM infrastructure only. HAProxy configuration must be provided via the cloud-init file (`haproxy-cloud-init.yml`). The backend server list, health checks, and load balancing algorithm should be defined in your cloud-init configuration.

**Benefits of this modular approach:**

- **Reusability**: Same module handles masters and workers with different configurations
- **Maintainability**: Changes to VM configuration only need to be made in the module
- **Consistency**: All nodes are created with identical settings except for specified parameters
- **Scalability**: Easy to add more nodes by adding entries to variables
- **Testing**: Modules can be tested independently

### `outputs.tf`

Outputs for module-based configuration:

```hcl
output "master_nodes" {
  description = "Master node information"
  value = {
    for k, v in module.k8s_masters : k => {
      name      = v.vm_name
      vmid      = v.vm_id
      ip        = v.ip_address
      cores     = var.master_nodes[k].cores
      memory    = var.master_nodes[k].memory
    }
  }
}

output "worker_nodes" {
  description = "Worker node information"
  value = {
    for k, v in module.k8s_workers : k => {
      name      = v.vm_name
      vmid      = v.vm_id
      ip        = v.ip_address
      cores     = var.worker_nodes[k].cores
      memory    = var.worker_nodes[k].memory
    }
  }
}

output "load_balancer" {
  description = "Load balancer information (if HA enabled)"
  value = var.enable_ha ? {
    name = module.k8s_lb[0].vm_name
    vmid = module.k8s_lb[0].vm_id
    ip   = module.k8s_lb[0].ip_address
  } : null
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
    total_cores      = sum([for n in merge(var.master_nodes, var.worker_nodes) : n.cores])
    total_memory_mb  = sum([for n in merge(var.master_nodes, var.worker_nodes) : n.memory])
    kubernetes_version = var.kubernetes_version
    ha_enabled       = var.enable_ha
    api_endpoint     = var.enable_ha ? "${var.lb_ip_address}:${local.k8s_api_port}" : "${values(var.master_nodes)[0].ip}:${local.k8s_api_port}"
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

## Related Topics

- [Overview and Prerequisites](index.md)
- [Terraform Configuration](terraform-configuration.md)
- [Modules and Load Balancer](modules-and-load-balancer.md)
- [Packer Template Creation](packer-template.md)
- [Deployment and Kubernetes Installation](deployment.md)
- [GitOps Workflow](gitops.md)
- [Testing and Examples](testing.md)
- [Day-2 Operations](operations.md)
- [Monitoring](monitoring.md)
- [Security Considerations](security.md)
- [Capacity Planning and Cost](capacity-planning.md)
- [Troubleshooting](troubleshooting.md)
