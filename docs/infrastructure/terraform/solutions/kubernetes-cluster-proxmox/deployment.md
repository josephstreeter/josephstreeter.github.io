---
title: "Deployment and Kubernetes Installation"
description: "Running the deployment, automating Kubernetes installation via cloud-init, and post-deployment cluster setup"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "deployment", "kubeadm", "cloud-init"]
category: "infrastructure"
last_updated: "2026-08-01"
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
    module.k8s_masters,
    module.k8s_workers,
    module.k8s_lb
  ]
}

# Run Ansible playbook after VM creation
resource "null_resource" "kubernetes_installation" {
  triggers = {
    cluster_instance_ids = join(",", concat(
      [for k, v in module.k8s_masters : v.vm_id],
      [for k, v in module.k8s_workers : v.vm_id]
    ))
    kubernetes_version = var.kubernetes_version
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/ansible
      
      # Wait for all VMs to have cloud-init complete
      echo "Waiting for cloud-init to complete on all nodes..."
      for ip in ${join(" ", concat(
        [for k, v in var.master_nodes : v.ip],
        [for k, v in var.worker_nodes : v.ip]
      ))}; do
        echo "Checking $ip..."
        timeout 600 bash -c 'until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.cloud_init_user}@'$ip' "cloud-init status --wait" 2>/dev/null; do sleep 10; done'
        if [ $? -ne 0 ]; then
          echo "ERROR: Cloud-init did not complete on $ip within 10 minutes"
          exit 1
        fi
        echo "Cloud-init completed on $ip"
      done
      
      ansible-playbook -i inventory/hosts.ini \
        -e kubernetes_version=${var.kubernetes_version} \
        -e pod_network_cidr=${var.pod_network_cidr} \
        -e service_cidr=${var.service_cidr} \
        -e cluster_name=${var.cluster_name} \
        playbooks/k8s-cluster.yml
    EOT
    
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
  
  depends_on = [
    local_file.ansible_inventory,
    module.k8s_masters,
    module.k8s_workers
  ]
}

# Retrieve kubeconfig
resource "null_resource" "fetch_kubeconfig" {
  triggers = {
    cluster_id = null_resource.kubernetes_installation.id
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      
      mkdir -p ${path.module}/kubeconfig
      
      echo "Waiting for Kubernetes API to be ready..."
      timeout 300 bash -c 'until kubectl --kubeconfig=/dev/null get --raw /healthz &>/dev/null; do sleep 5; done' || true
      
      echo "Fetching kubeconfig..."
      scp -o StrictHostKeyChecking=no \
        ${var.cloud_init_user}@${values(var.master_nodes)[0].ip}:~/.kube/config \
        ${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Update server address if using load balancer
      if [ "${var.enable_ha}" = "true" ]; then
        sed -i 's|server: https://.*:${local.k8s_api_port}|server: https://${var.lb_ip}:${local.k8s_api_port}|' \
          ${path.module}/kubeconfig/${var.cluster_name}.conf
      fi
      
      # Set proper permissions
      chmod 600 ${path.module}/kubeconfig/${var.cluster_name}.conf
      
      echo "Kubeconfig saved to: ${path.module}/kubeconfig/${var.cluster_name}.conf"
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
variable "enable_ha" {
  type        = bool
  description = "Enable high availability with HAProxy load balancer"
  default     = false
}

variable "lb_ip_address" {
  type        = string
  description = "IP address for HAProxy load balancer (required if enable_ha is true)"
  default     = ""
  validation {
    condition     = var.enable_ha ? var.lb_ip_address != "" : true
    error_message = "Load balancer IP address must be specified when HA is enabled"
  }
}

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
