# Terraform Proxmox

Main.tf

```terraform
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url           # e.g., "https://your-proxmox-host:8006/api2/json"
  pm_api_token_id     = var.proxmox_api_token_id      # e.g., "user@pve!token-name"
  pm_api_token_secret = var.proxmox_api_token_secret  # Your API token secret
  pm_tls_insecure     = true                          # Set to true if using self-signed certificates
}

resource "proxmox_vm_qemu" "cloudinit-example" {
  vmid        = 100
  name        = "K8S-01"
  target_node = "FR-TST-01"
  agent       = 1
  cores       = 2
  memory      = 1024
  boot        = "order=scsi0" # has to be the same as the OS disk of the template
  clone       = "debian12-cloudinit" # The name of the template
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"
  automatic_reboot = true

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml" # /var/lib/vz/snippets/qemu-guest-agent.yml
  ciupgrade  = true
  nameserver = "192.168.127.1 8.8.8.8"
  ipconfig0  = "ip=192.168.127.10/24,gw=192.168.127.1,ip6=dhcp"
  skip_ipv6  = true
  ciuser     = "hades"
  cipassword = "iw2slep!"
  sshkeys    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/Pjg7YXZ8Yau9heCc4YWxFlzhThnI+IhUx2hLJRxYE Cloud-Init@Terraform"

  # Most cloud-init images require a serial device for their display
  serial {
    id = 0
  }

  disks {
    scsi {
      scsi0 {
        # We have to specify the disk from our template, else Terraform will think it's not supposed to be there
        disk {
          storage = "local-lvm"
          size    = "3G" # The size of the disk should be at least as big as the disk in the template. If it's smaller, the disk will be recreated
        }
      }
    }
    ide {
      # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
      ide1 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }
}
```

providers.tf

```terraform
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc7"
    }
  }
}
```

varables.tf

```terraform
variable "proxmox_api_url" {
  type        = string
  description = "URL of the Proxmox API"
  default = "https://192.168.127.113:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API token ID"
  sensitive   = true
  default = "terraform-prov@pve!terraform_id"
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
  default = "969c6faaa-dd13-4903-8c42-8868b516a6d8"
}

variable "proxmox_host" {
  type        = string
  default     = "FR-TST-01"  # Replace with your Proxmox node name
  description = "Target Proxmox node for VM deployment"
}
```

terraform.tfvars

```terraform
proxmox_api_url          = "https://<hostname>:8006/api2/json"
proxmox_api_token_id     = "<user>@pve!<api_id>"
proxmox_api_token_secret = "<secret>"
proxmox_host             = "<Proxmox Node>"
```
