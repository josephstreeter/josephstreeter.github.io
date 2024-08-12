# Terraform Proxmox

Main.tf

```terraform
resource "proxmox_vm_qemu" "OC-VM-01" {
  name        = "OC-TS-01"
  desc        = "Terraform created VM"
  target_node = "OC-VH-02"
  clone       = "Ubuntu-Server-VM-Template"
  cores       = 2
  memory      = 2048
  
  ipconfig0 = "ip=192.168.254.21/24,gw=192.168.254.1"
  
  
  disk {1
    size     = "16G"
    type     = "sata"
    storage  = "local-lvm"
  }

  network {
    model     = "e1000"
    bridge    = "vmbr0"
    firewall  = false
    link_down = false
  }
}
```

providers.tf

```terraform
terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc3"
    }
  }
}

provider "proxmox" {
    pm_api_url = var.pm_api_url
    pm_user    = var.pm_api_id
    pm_password = "iw2slep!"
    pm_tls_insecure = true
    pm_debug = true
    #pm_api_token_id = var.pm_api_token_id
    #pm_api_token_secret = var.pm_api_token_secret
}
```

varables.tf

```terraform
# Sensitive Variables to Pass as Terrafrom CLI Args or ENV Vars
variable "pm_api_token_id" {
  sensitive = true
  nullable  = false
}

variable "pm_api_token_secret" {
  sensitive = true
  nullable  = false
}

variable "pm_api_secret" {
  sensitive = true
  nullable  = false
}

variable "pm_api_id" {
  sensitive = true
  nullable  = false
}

# Sensitive Variables
variable "pm_api_url" {
  description = "Proxmox API Endpoint, e.g. 'https://192.168.254.150:8006/api2/json'"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("(?i)^https://.*/api2/json$", var.pm_api_url))
    error_message = "Proxmox API Endpoint Invalid. Check URL - HTTPS and PATH req."
  }
}
```

terraform.tfvars

```terraform
pm_api_url = "https://<hostname>:8006/api2/json"
pm_api_id = <username>
pm_api_secret = <password>
#pm_api_token_secret = "360c616e-ad16-45b6-a000-1bf48eedba22"
#pm_api_token_id = "root@pam!terraform"
#ssh_key_public = "~/.ssh/id_rsa_ado.pub"
```
