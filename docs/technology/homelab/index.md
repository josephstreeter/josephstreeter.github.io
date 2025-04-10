# Home Lab

## Proxmox

Proxmox makes of the base of the lab. Three compact PCs with Proxmox 8.3 installed and configured as a cluster. The following helper scripts help set up Proxmox.

The pve_setup.sh script:

- Sets the non-enterprise apt repositories for pve and ceph
- Removes the enterprise repositories for pve and ceph
- Removes the "No Subscription" pop-up
- Upgrades installed packages
- Creates a ```snippets``` directory used for install time scripts in templates
- Creates a script in ```snippets``` that will run on new templates

```bash
# pve_setup.sh

echo "Configure the 'non-subscription' repositories for pve and ceph...."
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | tee -a /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription" | tee -a /etc/apt/sources.list

echo "Disable the Enterprise repositories for pve and ceph...."
sed -i '/^deb/s/^/# /' /etc/apt/sources.list.d/pve-enterprise.list
sed -i '/^deb/s/^/# /' /etc/apt/sources.list.d/ceph.list

echo "Disable the subscription pop-up...."
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy.service

echo "Upgrade installed sources...."
apt update
apt upgrade -y

echo "Set up 'snippets' for VM configuration...."
mkdir /var/lib/vz/snippets

tee /var/lib/vz/snippets/qemu-guest-agent.yml <<EOF
#cloud-config
runcmd:
  - apt update
  - apt install -y qemu-guest-agent
  - systemctl start qemu-guest-agent
EOF

echo "Install Terraform...."
pushd /tmp
apt install -y lsb-release
wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update && apt install terraform -y
popd
```

The pve_terraform_setup.sh script:

- Creates a role for terraform to clone VMs from templates
- Creates a user to authenticate Terraform
- Adds Terraform user to the new role
- Applies role to the root
- Creates API token for the user

```bash
# pve_terraform_setup.sh

pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"

pveum user add terraform-prov@pve --password "<password>"
pveum aclmod / -user terraform-prov@pve -role TerraformProv


pveum user token add terraform-prov@pve terraform
```

The pve_template_create.sh script:

- Downloads the cloud image if it doesn't exist
- Creates a VM using the cloud image
- Converts the VM to a template

```bash
# pve_template_create.sh

VMID=9000
TEMPLATENAME="debian12-cloudinit"
TEMPLATEURL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
FILE="debian-12-genericcloud-amd64.qcow2"

pushd /root/
if [ -f $FILE ]; then
   echo "Image ($FILE) exists."
else
   echo "image ($FILE) does not exist. Downloading...."
   wget $TEMPLATEURL
fi
popd

qm create $VMID --name $TEMPLATENAME
qm create $VMID --name $TEMPLATENAME
qm set $VMID --scsi0 local-lvm:0,import-from=/root/$file
qm template $VMID
```

## Kubernetes

A three node K8S cluster deployed with Teraform and configured with Ansible.

Teraform files:

```hcl
# providers.tf

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc7"
    }
  }
}
```

```hcl
# main.tf

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "cloudinit-example" {
  count       = 3
  name        = "k8s-node-${count.index + 1}"
  target_node = var.proxmox_host
  vmid        = 200 + count.index + 1
  agent       = 1
  cores       = 2
  memory      = 4096
  boot        = "order=scsi0" # has to be the same as the OS disk of the template
  clone       = var.template_name # The name of the template
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"
  automatic_reboot = true

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml" # /var/lib/vz/snippets/qemu-guest-agent.yml
  ciupgrade  = true
  nameserver = "192.168.127.1 8.8.8.8"
  ipconfig0  = "ip=192.168.127.2${count.index + 1}/24,gw=192.168.127.1,ip6=dhcp"
  skip_ipv6  = true
  ciuser     = var.ciuser
  cipassword = var.password
  sshkeys    = var.ssh_key

  # Most cloud-init images require a serial device for their display
  serial {
    id = 0
  }

  disks {
    scsi {
      scsi0 {
        # We have to specify the disk from our template, else Terraform will think it's not supposed to be there
        disk {
          storage = var.storage
          size    = "3G" # The size of the disk should be at least as big as the disk in the template. If it's smaller, the disk will be recreated
        }
      }
    }
    ide {
      # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
      ide1 {
        cloudinit {
          storage = var.storage
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

```hcl
# output.tf

output "cloudinit-example" {
  value = proxmox_vm_qemu.cloudinit-example[*].ipconfig0
  description = "IP addresses assigned to the K8s nodes"
}
```

```hcl
#variables.tf

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
}

variable "proxmox_host" {
  type        = string
  default     = "FR-VH-01"  # Replace with your Proxmox node name
  description = "Target Proxmox node for VM deployment"
}

variable "template_name" {
  type        = string
  default     = "debian12-cloudinit"  # Replace with your Ubuntu 24.04 template name
  description = "Name of the cloud-init template"
}

variable "ssh_key" {
  type        = string
  description = "SSH public key for VM access"
}

variable "ciuser" {
  type        = string
  description = "Local user for cloud-init configuration"
  default     = "ubuntu"  # Replace with your desired username
}

variable "password" {
  type        = string
  description = "local user password for VM access"
}

variable "storage" {
  type        = string
  default     = "local-zfs"
  description = "Name of the Proxmox storage for VM disks"
}
```

```hcl
# terraform.tfvars

proxmox_api_url          = "https://<host or ip>:8006/api2/json"
proxmox_api_token_id     = "<token id>" 
proxmox_api_token_secret = "<token secret>"
proxmox_host             = "<host>"
template_name            = "<template name>"
ciuser                   = "<username>"
password                 = "<password>"
ssh_key                  = "<ssh key>"
storage                  = "local-lvm"

```

## Ansible

```text
# hosts

[master]
master1 ansible_host=192.168.127.21

[workers]
worker1 ansible_host=192.168.127.22
worker2 ansible_host=192.168.127.23

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_extra_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_user=hades
```

```yaml
# kube-depends.yml

- hosts: all
  become: yes
  tasks:
    - name: update APT packages
      apt:
        update_cache: yes

    - name: reboot and wait for reboot to complete
      reboot:

    - name: disable SWAP (Kubeadm requirement)
      shell: |
        swapoff -a

    - name: disable SWAP in fstab (Kubeadm requirement)
      replace:
        path: /etc/fstab
        regexp: '^([^#].*?\sswap\s+sw\s+.*)$'
        replace: '# \1'

    - name: create an empty file for the Containerd module
      copy:
        content: ""
        dest: /etc/modules-load.d/containerd.conf
        force: no

    - name: configure modules for Containerd
      blockinfile:
        path: /etc/modules-load.d/containerd.conf
        block: |
             overlay
             br_netfilter

    - name: create an empty file for Kubernetes sysctl params
      copy:
        content: ""
        dest: /etc/sysctl.d/99-kubernetes-cri.conf
        force: no

    - name: configure sysctl params for Kubernetes
      lineinfile:
        path: /etc/sysctl.d/99-kubernetes-cri.conf
        line: "{{ item }}"
      with_items:
        - 'net.bridge.bridge-nf-call-iptables  = 1'
        - 'net.ipv4.ip_forward                 = 1'
        - 'net.bridge.bridge-nf-call-ip6tables = 1'

    - name: apply sysctl params without reboot
      command: sysctl --system

    - name: install APT Transport HTTPS
      apt:
        name: apt-transport-https
        state: present

    - name: add Docker apt-key
      get_url:
        url: https://download.docker.com/linux/ubuntu/gpg
        dest: /etc/apt/keyrings/docker-apt-keyring.asc
        mode: '0644'
        force: true

    - name: add Docker's APT repository
      apt_repository:
        repo: "deb [arch={{ 'amd64' if ansible_architecture == 'x86_64' else 'arm64' }} signed-by=/etc/apt/keyrings/docker-apt-keyring.asc] https://download.docker.com/linux/debian {{ ansible_distribution_release }} stable"
        state: present
        update_cache: yes

    - name: add Kubernetes apt-key
      get_url:
        url: https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key
        dest: /etc/apt/keyrings/kubernetes-apt-keyring.asc
        mode: '0644'
        force: true

    - name: add Kubernetes' APT repository
      apt_repository:
        repo: "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /"
        state: present
        update_cache: yes

    - name: install Containerd
      apt:
        name: containerd.io
        state: present

    - name: create Containerd directory
      file:
        path: /etc/containerd
        state: directory

    - name: add Containerd configuration
      shell: /usr/bin/containerd config default > /etc/containerd/config.toml

    - name: configuring the systemd cgroup driver for Containerd
      lineinfile:
        path: /etc/containerd/config.toml
        regexp: '            SystemdCgroup = false'
        line: '            SystemdCgroup = true'

    - name: enable the Containerd service and start it
      systemd:
        name: containerd
        state: restarted
        enabled: yes
        daemon-reload: yes

    - name: install Kubelet
      apt:
        name: kubelet=1.29.*
        state: present
        update_cache: true

    - name: install Kubeadm
      apt:
        name: kubeadm=1.29.*
        state: present

    - name: enable the Kubelet service, and enable it persistently
      service:
        name: kubelet
        enabled: yes

    - name: load br_netfilter kernel module
      modprobe:
        name: br_netfilter
        state: present

    - name: set bridge-nf-call-iptables
      sysctl:
        name: net.bridge.bridge-nf-call-iptables
        value: 1

    - name: set ip_forward
      sysctl:
        name: net.ipv4.ip_forward
        value: 1

    - name: reboot and wait for reboot to complete
      reboot:

- hosts: master
  become: yes
  tasks:
    - name: install Kubectl
      apt:
        name: kubectl=1.29.*
        state: present
        force: yes # allow downgrades

```

```yaml
# master.yml

- hosts: master
  become: yes
  tasks:
    - name: create an empty file for Kubeadm configuring
      copy:
        content: ""
        dest: /etc/kubernetes/kubeadm-config.yaml
        force: no

    - name: configuring the container runtime including its cgroup driver
      blockinfile:
        path: /etc/kubernetes/kubeadm-config.yaml
        block: |
             kind: ClusterConfiguration
             apiVersion: kubeadm.k8s.io/v1beta3
             networking:
               podSubnet: "10.244.0.0/16"
             ---
             kind: KubeletConfiguration
             apiVersion: kubelet.config.k8s.io/v1beta1
             runtimeRequestTimeout: "15m"
             cgroupDriver: "systemd"
             systemReserved:
               cpu: 100m
               memory: 350M
             kubeReserved:
               cpu: 100m
               memory: 50M
             enforceNodeAllocatable:
             - pods

    - name: initialize the cluster (this could take some time)
      shell: kubeadm init --config /etc/kubernetes/kubeadm-config.yaml >> cluster_initialized.log
      args:
        chdir: /home/hades
        creates: cluster_initialized.log

    - name: create .kube directory
      become: yes
      become_user: hades
      file:
        path: $HOME/.kube
        state: directory
        mode: 0755

    - name: copy admin.conf to user's kube config
      copy:
        src: /etc/kubernetes/admin.conf
        dest: /home/hades/.kube/config
        remote_src: yes
        owner: hades

    - name: install Pod network
      become: yes
      become_user: hades
      shell: kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml >> pod_network_setup.log
      args:
        chdir: $HOME
        creates: pod_network_setup.log
```

```yaml
# workers.yml

- hosts: master
  become: yes
  #gather_facts: false
  tasks:
    - name: get join command
      shell: kubeadm token create --print-join-command
      register: join_command_raw

    - name: set join command
      set_fact:
        join_command: "{{ join_command_raw.stdout_lines[0] }}"


- hosts: workers
  become: yes
  tasks:
    - name: TCP port 6443 on master is reachable from worker
      wait_for: "host={{ hostvars['master1']['ansible_default_ipv4']['address'] }} port=6443 timeout=1"

    - name: join cluster
      shell: "{{ hostvars['master1'].join_command }} >> node_joined.log"
      args:
        chdir: /home/hades
        creates: node_joined.log

```

- Proxmox
- Docker
- Terraform
- Ansible
- Grafana
- Bind9
- OwnCloud
