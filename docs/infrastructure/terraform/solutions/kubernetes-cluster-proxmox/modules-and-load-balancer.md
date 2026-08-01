---
title: "Modules and Load Balancer"
description: "HA API load balancer with HAProxy, variable files, and reusable Terraform modules for nodes and load balancers"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "haproxy", "load balancer", "modules", "tfvars"]
category: "infrastructure"
last_updated: "2026-08-01"
---
### Load Balancer for HA Kubernetes API

The load balancer is handled by the `module.k8s_lb` module in the main.tf configuration (see above). The module provides:

- **Conditional deployment**: Only created when `var.enable_ha = true`
- **VM provisioning**: Creates Proxmox VM for HAProxy load balancer
- **Cloud-init integration**: Uses `haproxy-cloud-init.yml` for automated HAProxy configuration

> **Important:** The module creates the VM infrastructure only. You must provide complete HAProxy configuration in your `cloud-init/haproxy-cloud-init.yml` file including:
>
> - Backend server pool (master node IPs and port 6443)
> - Frontend listener configuration
> - Health check settings
> - Load balancing algorithm (roundrobin recommended)
> - HAProxy statistics interface (optional)

**Required cloud-init configuration structure:**

```yaml
#cloud-config
package_update: true
packages:
  - haproxy

write_files:
  - path: /etc/haproxy/haproxy.cfg
    content: |
      global
        log /dev/log local0
        maxconn 4096
      
      defaults
        log global
        mode tcp
        option tcplog
        timeout connect 5000ms
        timeout client 50000ms
        timeout server 50000ms
      
      frontend kubernetes-api
        bind *:6443
        default_backend kubernetes-masters
      
      backend kubernetes-masters
        balance roundrobin
        option tcp-check
        # Add your master nodes here:
        server master-01 192.168.100.10:6443 check
        server master-02 192.168.100.11:6443 check
        server master-03 192.168.100.12:6443 check

runcmd:
  - systemctl enable haproxy
  - systemctl start haproxy
```

To enable the load balancer, configure these variables in `terraform.tfvars`:

```hcl
enable_ha = true
lb_ip_address = "192.168.100.5"
```

### Cloud-Init Configuration for HAProxy

Create `cloud-init/haproxy-cloud-init.yml` or use the templated version below:

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

Then generate the file in Terraform using the `templatefile()` function. This resource dynamically creates the HAProxy cloud-init configuration file by:

1. **Reading the template** from `templates/haproxy-cloud-init.tpl`
2. **Interpolating variables** (master_nodes, k8s_api_port, haproxy_stats_port) into the template
3. **Writing the output** to `generated/haproxy-cloud-init.yml`
4. **Conditional creation** - only creates the file when `var.enable_ha = true`

The generated file can then be uploaded to Proxmox as a cloud-init snippet or referenced directly in the VM configuration.

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

# High Availability Configuration
enable_ha = false  # Set to true to enable HAProxy load balancer
lb_ip_address = "192.168.100.5"  # Required if enable_ha = true

# Kubernetes Configuration
kubernetes_version = "1.28.3"
```

### `terraform.tfvars` Complete Example

Here's a complete `terraform.tfvars` file ready to customize:

```hcl
# Proxmox API Configuration
proxmox_api_url          = "https://192.168.1.100:8006/api2/json"
proxmox_api_token_id     = "terraform-prov@pve!terraform_id"
proxmox_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
proxmox_tls_insecure     = false  # Use true only for self-signed certificates in testing

# Proxmox Infrastructure Settings
target_node    = "pve-node-01"
template_name  = "debian12-cloudinit"
storage        = "local-lvm"
network_bridge = "vmbr0"

# Kubernetes Cluster Configuration
cluster_name = "k8s-prod"

cluster_network = {
  subnet  = "192.168.100.0/24"
  gateway = "192.168.100.1"
  dns     = ["8.8.8.8", "1.1.1.1"]
}

# SSH Access Configuration
ssh_public_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJxyz... user@hostname"
cloud_init_user = "ubuntu"

# Master Node Definitions
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

# Worker Node Definitions
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

# High Availability Configuration
enable_ha     = false  # Set to true to enable HAProxy load balancer
lb_ip_address = "192.168.100.5"

# Kubernetes Version
kubernetes_version = "1.28.3"

# Monitoring
enable_monitoring = true
```

### Environment Variables (Alternative)

```bash
export TF_VAR_proxmox_api_url="https://your-proxmox-host:8006/api2/json"
export TF_VAR_proxmox_api_token_id="terraform-prov@pve!terraform_id"  
export TF_VAR_proxmox_api_token_secret="your-api-token-secret"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
```

---

### Node Module: `modules/k8s-node/main.tf`

```hcl
resource "proxmox_vm_qemu" "node" {
  vmid        = var.vmid
  name        = var.name
  target_node = var.target_node
  
  cores  = var.cores
  memory = var.memory
  
  agent            = 1
  clone            = var.template_name
  full_clone       = false
  oncreate         = true
  
  # Cloud-init configuration
  cicustom   = "vendor=local:snippets/${var.cloud_init_file}"
  ciuser     = var.cloud_init_user
  sshkeys    = var.ssh_public_key
  nameserver = join(" ", var.dns_servers)
  ipconfig0  = "ip=${var.ip_address}/${var.ip_cidr},gw=${var.gateway}"
  
  # Disk configuration
  disk {
    type    = "scsi"
    storage = var.storage
    size    = var.disk_size
    cache   = "writethrough"
  }
  
  # Network configuration
  network {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  # Serial device for console access
  serial {
    id   = 0
    type = "socket"
  }
  
  lifecycle {
    ignore_changes = [network]
  }
}
```

### Node Module Variables

Complete variable definitions for `modules/k8s-node/variables.tf`:

```hcl
variable "vmid" {
  type        = number
  description = "VM ID in Proxmox"
}

variable "name" {
  type        = string
  description = "VM name"
}

variable "target_node" {
  type        = string
  description = "Proxmox node to deploy on"
}

variable "cores" {
  type        = number
  description = "Number of CPU cores"
  default     = 2
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 4096
}

variable "disk_size" {
  type        = string
  description = "Disk size (e.g., 20G, 50G)"
  default     = "20G"
}

variable "template_name" {
  type        = string
  description = "Name of the cloud-init template to clone"
}

variable "storage" {
  type        = string
  description = "Storage pool for VM disks"
}

variable "network_bridge" {
  type        = string
  description = "Network bridge for VM"
}

variable "ip_address" {
  type        = string
  description = "Static IP address for the VM"
}

variable "ip_cidr" {
  type        = string
  description = "CIDR notation for subnet (e.g., 24)"
}

variable "gateway" {
  type        = string
  description = "Network gateway"
}

variable "dns_servers" {
  type        = list(string)
  description = "List of DNS servers"
}

variable "cloud_init_file" {
  type        = string
  description = "Cloud-init configuration file name"
}

variable "cloud_init_user" {
  type        = string
  description = "Default user for cloud-init"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access"
}
```

### Node Module Outputs

Create `modules/k8s-node/outputs.tf`:

```hcl
output "vm_name" {
  description = "Name of the created VM"
  value       = proxmox_vm_qemu.node.name
}

output "vm_id" {
  description = "VM ID in Proxmox"
  value       = proxmox_vm_qemu.node.vmid
}

output "ip_address" {
  description = "IP address of the VM"
  value       = var.ip_address
}
```

**Copy this code** into `modules/k8s-node/versions.tf`:

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}
```

> **Why versions.tf is needed:** Modules must explicitly declare which providers they use. This file tells Terraform the module requires the `telmate/proxmox` provider. Provider authentication (credentials) is still configured only in the root `providers.tf` file.

### Load Balancer Module

**Copy this complete code** into `modules/load-balancer/main.tf`:

```hcl
resource "proxmox_vm_qemu" "lb" {
  vmid        = var.vmid
  name        = var.name
  target_node = var.target_node
  
  cores  = var.cores
  memory = var.memory
  
  agent      = 1
  clone      = var.template_name
  full_clone = false
  oncreate   = true
  
  # Cloud-init configuration
  cicustom   = "vendor=local:snippets/${var.cloud_init_file}"
  ciuser     = var.cloud_init_user
  sshkeys    = var.ssh_public_key
  nameserver = join(" ", var.dns_servers)
  ipconfig0  = "ip=${var.ip_address}/${var.ip_cidr},gw=${var.gateway}"
  
  # Disk configuration
  disk {
    type    = "scsi"
    storage = var.storage
    size    = var.disk_size
    cache   = "writethrough"
  }
  
  # Network configuration
  network {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  # Serial device for console access
  serial {
    id   = 0
    type = "socket"
  }
  
  lifecycle {
    ignore_changes = [network]
  }
}
```

Create `modules/load-balancer/variables.tf`:

```hcl
variable "vmid" {
  type        = number
  description = "VM ID in Proxmox"
}

variable "name" {
  type        = string
  description = "VM name"
}

variable "target_node" {
  type        = string
  description = "Proxmox node to deploy on"
}

variable "cores" {
  type        = number
  description = "Number of CPU cores"
  default     = 2
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 2048
}

variable "disk_size" {
  type        = string
  description = "Disk size"
  default     = "10G"
}

variable "template_name" {
  type        = string
  description = "Name of the cloud-init template to clone"
}

variable "storage" {
  type        = string
  description = "Storage pool for VM disks"
}

variable "network_bridge" {
  type        = string
  description = "Network bridge for VM"
}

variable "ip_address" {
  type        = string
  description = "Static IP address for the load balancer"
}

variable "ip_cidr" {
  type        = string
  description = "CIDR notation for subnet"
}

variable "gateway" {
  type        = string
  description = "Network gateway"
}

variable "dns_servers" {
  type        = list(string)
  description = "List of DNS servers"
}

variable "cloud_init_user" {
  type        = string
  description = "Default user for cloud-init"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access"
}

variable "cloud_init_file" {
  type        = string
  description = "Cloud-init configuration file"
  default     = "haproxy-cloud-init.yml"
}
```

**Copy this code** into `modules/load-balancer/outputs.tf`:

```hcl
output "vm_name" {
  description = "Name of the load balancer VM"
  value       = proxmox_vm_qemu.lb.name
}

output "vm_id" {
  description = "VM ID in Proxmox"
  value       = proxmox_vm_qemu.lb.vmid
}

output "ip_address" {
  description = "IP address of the load balancer"
  value       = var.ip_address
}
```

**Copy this code** into `modules/load-balancer/versions.tf`:

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}
```

> **Note:** This versions.tf file is identical to the one in k8s-node module. Each module must declare its provider dependencies to ensure Terraform uses the correct provider source.

### Understanding the Module Usage

> **Note:** The code shown above is an **example** of how the k8s-node module is called. This exact code is **already included in the main.tf** file shown earlier in the document. You do **NOT** need to add this code anywhere - it's provided here for reference only to help you understand how modules work.

**What this example demonstrates:**

- **Module source**: `source = "./modules/k8s-node"` tells Terraform where to find the module code
- **for_each loop**: Creates multiple VMs (one per master node defined in `var.master_nodes`)
- **Parameter mapping**: Shows how values from your `terraform.tfvars` are passed to the module
- **Module reusability**: The same module is used for both masters and workers with different parameters

**Key takeaway:** The module definitions you copied above (main.tf, variables.tf, outputs.tf) are the reusable building blocks. The main.tf file at the project root calls these modules to create your actual infrastructure.

---

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
