---
title: "Packer Template Creation"
description: "Building a reusable Debian VM template for Proxmox with Packer, including preseed and Kubernetes preparation"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "packer", "templates", "debian", "preseed"]
category: "infrastructure"
last_updated: "2026-08-01"
---
## Packer Template Creation

Automate VM template creation with Packer for consistent, pre-configured images.

> [!NOTE]
> This page covers the Proxmox-specific `proxmox-iso` builder. For Packer generally —
> installation, provisioners, post-processors, other builders, and CI/CD integration — see
> the [Packer](../../../packer/index.md) section.

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

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

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
