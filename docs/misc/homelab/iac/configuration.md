---
title: Infrastructure as Code Configuration
description: Terraform and Ansible configurations for automated home lab infrastructure deployment and management
author: Joseph Streeter
date: 2025-09-13
tags: [infrastructure-as-code, terraform, ansible, automation, configuration-management]
---

Complete Infrastructure as Code implementation for home lab using Terraform for provisioning and Ansible for configuration management.

## 🎯 **IaC Strategy Overview**

### Tool Selection and Responsibilities

| Tool | Purpose | Scope | Configuration |
|------|---------|-------|---------------|
| **Terraform** | Infrastructure provisioning | Proxmox VMs, networks, storage | HCL declarative |
| **Ansible** | Configuration management | OS setup, services, applications | YAML playbooks |
| **Git** | Version control | All configurations | Branching strategy |
| **CI/CD** | Automation pipeline | Testing, deployment | GitHub Actions |

### Design Principles

- **Idempotency** - Safe to run multiple times
- **Modularity** - Reusable components and patterns
- **Documentation** - Self-documenting code with comments
- **Testing** - Validation and verification at each stage
- **Security** - Secrets management and least privilege
- **Disaster Recovery** - Complete infrastructure rebuild capability

## 🏗️ **Terraform Configuration**

### Project Structure

```text
homelab-terraform/
├── main.tf                 # Root configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars        # Variable values
├── versions.tf             # Provider versions
├── modules/
│   ├── proxmox-vm/         # VM creation module
│   ├── proxmox-template/   # Template management
│   └── networking/         # Network configuration
├── environments/
│   ├── dev/                # Development environment
│   ├── staging/            # Staging environment
│   └── prod/               # Production environment
└── scripts/
    ├── deploy.sh           # Deployment automation
    └── destroy.sh          # Cleanup automation
```

### Core Terraform Configuration

#### Provider Configuration

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "~> 2.9.0"
    }
  }

  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "proxmox" {
  pm_api_url = var.proxmox_api_url
  pm_user = var.proxmox_user
  pm_password = var.proxmox_password
  pm_tls_insecure = true
}
```

#### Virtual Machine Module

```hcl
# modules/proxmox-vm/main.tf
resource "proxmox_vm_qemu" "vm" {
  name = var.vm_name
  target_node = var.target_node
  clone = var.template_name
  
  # Hardware Configuration
  cores = var.cpu_cores
  memory = var.memory_mb
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  # Network Configuration
  network {
    bridge = var.network_bridge
    model = "virtio"
    tag = var.vlan_tag
  }
  
  # Storage Configuration
  disk {
    slot = 0
    size = var.disk_size
    type = "scsi"
    storage = var.storage_pool
    iothread = 1
    ssd = 1
  }
  
  # Cloud-init Configuration
  os_type = "cloud-init"
  ipconfig0 = "ip=${var.ip_address}/${var.subnet_mask},gw=${var.gateway}"
  nameserver = var.nameserver
  
  # SSH Configuration
  sshkeys = var.ssh_public_key
  ciuser = var.default_user
  
  # Lifecycle Management
  lifecycle {
    ignore_changes = [
      network,
      desc,
      numa,
      tablet,
      vmid
    ]
  }
  
  tags = var.tags
}
```

#### Service-Specific Configurations

```hcl
# DNS Server Configuration
module "dns_primary" {
  source = "./modules/proxmox-vm"
  
  vm_name = "dns-primary"
  target_node = "proxmox-01"
  template_name = "ubuntu-22.04-cloud"
  
  cpu_cores = 2
  memory_mb = 2048
  disk_size = "20G"
  
  ip_address = "192.168.103.10"
  subnet_mask = "24"
  gateway = "192.168.103.1"
  nameserver = "1.1.1.1"
  vlan_tag = 20
  
  tags = "dns,infrastructure,critical"
}

# Web Server Configuration
module "web_server" {
  source = "./modules/proxmox-vm"
  
  vm_name = "web-01"
  target_node = "proxmox-02"
  template_name = "ubuntu-22.04-cloud"
  
  cpu_cores = 4
  memory_mb = 8192
  disk_size = "50G"
  
  ip_address = "192.168.104.20"
  subnet_mask = "24"
  gateway = "192.168.104.1"
  nameserver = "192.168.103.10"
  vlan_tag = 30
  
  tags = "web,application,nginx"
}
```

### Terraform Variables

```hcl
# variables.tf
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type = string
  default = "https://proxmox.homelab.local:8006/api2/json"
}

variable "proxmox_user" {
  description = "Proxmox username"
  type = string
  default = "terraform@pve"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type = string
  sensitive = true
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type = string
}

variable "default_storage" {
  description = "Default storage pool"
  type = string
  default = "local-lvm"
}
```

## 🤖 **Ansible Configuration**

### Inventory Structure

```yaml
# inventory/homelab.yml
all:
  children:
    infrastructure:
      children:
        dns_servers:
          hosts:
            dns-primary:
              ansible_host: 192.168.103.10
              ansible_user: ubuntu
            dns-secondary:
              ansible_host: 192.168.103.11
              ansible_user: ubuntu
        
        monitoring:
          hosts:
            prometheus:
              ansible_host: 192.168.103.20
              ansible_user: ubuntu
            grafana:
              ansible_host: 192.168.103.21
              ansible_user: ubuntu
    
    applications:
      children:
        web_servers:
          hosts:
            web-01:
              ansible_host: 192.168.104.20
              ansible_user: ubuntu
            web-02:
              ansible_host: 192.168.104.21
              ansible_user: ubuntu
        
        databases:
          hosts:
            postgres-01:
              ansible_host: 192.168.106.30
              ansible_user: ubuntu

  vars:
    ansible_ssh_private_key_file: ~/.ssh/homelab_rsa
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
```

### Playbook Structure

```text
homelab-ansible/
├── ansible.cfg
├── inventory/
│   └── homelab.yml
├── group_vars/
│   ├── all.yml
│   ├── infrastructure.yml
│   └── applications.yml
├── host_vars/
│   ├── dns-primary.yml
│   └── web-01.yml
├── roles/
│   ├── common/
│   ├── dns/
│   ├── nginx/
│   ├── monitoring/
│   └── security/
├── playbooks/
│   ├── site.yml
│   ├── infrastructure.yml
│   └── applications.yml
└── scripts/
    ├── deploy.sh
    └── check.sh
```

### Core Playbooks

#### Site-wide Configuration

```yaml
# playbooks/site.yml
---
- name: Configure Home Lab Infrastructure
  hosts: all
  become: yes
  gather_facts: yes
  
  pre_tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 86400
      when: ansible_os_family == "Debian"
    
    - name: Install basic packages
      apt:
        name:
          - curl
          - wget
          - vim
          - htop
          - git
          - unzip
        state: present
      when: ansible_os_family == "Debian"

  roles:
    - common
    - security

- import_playbook: infrastructure.yml
- import_playbook: applications.yml
```

#### DNS Server Configuration

```yaml
# roles/dns/tasks/main.yml
---
- name: Install BIND9 DNS server
  apt:
    name:
      - bind9
      - bind9utils
      - bind9-doc
    state: present

- name: Configure BIND9 named.conf
  template:
    src: named.conf.j2
    dest: /etc/bind/named.conf
    backup: yes
  notify: restart bind9

- name: Configure forward zone
  template:
    src: forward-zone.j2
    dest: "/etc/bind/db.{{ dns_domain }}"
    backup: yes
  notify: restart bind9

- name: Configure reverse zone
  template:
    src: reverse-zone.j2
    dest: "/etc/bind/db.{{ dns_reverse_zone }}"
    backup: yes
  notify: restart bind9

- name: Start and enable BIND9
  systemd:
    name: bind9
    state: started
    enabled: yes

- name: Configure firewall for DNS
  ufw:
    rule: allow
    port: "53"
    proto: "{{ item }}"
  loop:
    - tcp
    - udp
```

### Role-based Configuration

#### Common System Configuration

```yaml
# roles/common/tasks/main.yml
---
- name: Set timezone
  timezone:
    name: "{{ system_timezone | default('America/New_York') }}"

- name: Configure NTP
  template:
    src: timesyncd.conf.j2
    dest: /etc/systemd/timesyncd.conf
  notify: restart systemd-timesyncd

- name: Create admin user
  user:
    name: "{{ admin_user }}"
    groups: sudo
    shell: /bin/bash
    create_home: yes
    state: present

- name: Add SSH key for admin user
  authorized_key:
    user: "{{ admin_user }}"
    key: "{{ admin_ssh_key }}"
    state: present

- name: Configure sudo access
  lineinfile:
    path: /etc/sudoers.d/{{ admin_user }}
    line: "{{ admin_user }} ALL=(ALL) NOPASSWD:ALL"
    create: yes
    mode: '0440'

- name: Configure system logging
  template:
    src: rsyslog.conf.j2
    dest: /etc/rsyslog.conf
  notify: restart rsyslog
```

#### Security Hardening

```yaml
# roles/security/tasks/main.yml
---
- name: Configure SSH security
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
  loop:
    - { regexp: '^#?PermitRootLogin', line: 'PermitRootLogin no' }
    - { regexp: '^#?PasswordAuthentication', line: 'PasswordAuthentication no' }
    - { regexp: '^#?PubkeyAuthentication', line: 'PubkeyAuthentication yes' }
    - { regexp: '^#?Port', line: 'Port 22' }
  notify: restart ssh

- name: Enable UFW firewall
  ufw:
    state: enabled
    policy: deny
    direction: incoming

- name: Allow SSH through firewall
  ufw:
    rule: allow
    port: 22
    proto: tcp

- name: Install fail2ban
  apt:
    name: fail2ban
    state: present

- name: Configure fail2ban
  template:
    src: jail.local.j2
    dest: /etc/fail2ban/jail.local
  notify: restart fail2ban

- name: Enable automatic security updates
  apt:
    name: unattended-upgrades
    state: present

- name: Configure automatic updates
  template:
    src: 50unattended-upgrades.j2
    dest: /etc/apt/apt.conf.d/50unattended-upgrades
```

## 🔄 **CI/CD Pipeline**

### GitHub Actions Workflow

```yaml
# .github/workflows/infrastructure.yml
name: Infrastructure Deployment

on:
  push:
    branches: [ main, develop ]
    paths: [ 'terraform/**', 'ansible/**' ]
  pull_request:
    branches: [ main ]

jobs:
  terraform-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        working-directory: terraform/
      
      - name: Terraform Validate
        run: |
          terraform init
          terraform validate
        working-directory: terraform/

  ansible-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Install dependencies
        run: |
          pip install ansible ansible-lint
      
      - name: Ansible Lint
        run: ansible-lint playbooks/
        working-directory: ansible/

  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    needs: [terraform-validate, ansible-lint]
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Staging
        run: ./scripts/deploy.sh staging
        env:
          PROXMOX_PASSWORD: ${{ secrets.PROXMOX_PASSWORD }}
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}

  deploy-production:
    if: github.ref == 'refs/heads/main'
    needs: [terraform-validate, ansible-lint]
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Production
        run: ./scripts/deploy.sh production
        env:
          PROXMOX_PASSWORD: ${{ secrets.PROXMOX_PASSWORD }}
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
```

### Deployment Scripts

```bash
#!/bin/bash
# scripts/deploy.sh

set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="terraform/environments/${ENVIRONMENT}"
ANSIBLE_DIR="ansible"

echo "Deploying to ${ENVIRONMENT} environment..."

# Terraform deployment
cd "${TERRAFORM_DIR}"
terraform init
terraform plan
terraform apply -auto-approve

# Extract outputs for Ansible
terraform output -json > ../../../ansible/terraform_outputs.json

# Wait for VMs to be ready
sleep 60

# Ansible configuration
cd "../../../${ANSIBLE_DIR}"
ansible-playbook -i inventory/${ENVIRONMENT}.yml playbooks/site.yml

echo "Deployment to ${ENVIRONMENT} completed successfully!"
```

## 📊 **Monitoring and Maintenance**

### Infrastructure Monitoring

```yaml
# roles/monitoring/tasks/main.yml
---
- name: Install node_exporter
  get_url:
    url: "https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz"
    dest: /tmp/node_exporter.tar.gz

- name: Extract node_exporter
  unarchive:
    src: /tmp/node_exporter.tar.gz
    dest: /opt/
    remote_src: yes
    creates: /opt/node_exporter-1.6.0.linux-amd64

- name: Create node_exporter user
  user:
    name: node_exporter
    system: yes
    shell: /bin/false
    home: /dev/null

- name: Install node_exporter binary
  copy:
    src: /opt/node_exporter-1.6.0.linux-amd64/node_exporter
    dest: /usr/local/bin/node_exporter
    mode: '0755'
    owner: root
    group: root
    remote_src: yes

- name: Create node_exporter service
  template:
    src: node_exporter.service.j2
    dest: /etc/systemd/system/node_exporter.service
  notify:
    - reload systemd
    - restart node_exporter

- name: Start and enable node_exporter
  systemd:
    name: node_exporter
    state: started
    enabled: yes
```

### Backup Configuration

```yaml
# roles/backup/tasks/main.yml
---
- name: Install backup tools
  apt:
    name:
      - borgmatic
      - borgbackup
    state: present

- name: Create backup directories
  file:
    path: "{{ item }}"
    state: directory
    mode: '0700'
  loop:
    - /etc/borgmatic
    - /var/backups/configs

- name: Configure borgmatic
  template:
    src: borgmatic.yml.j2
    dest: /etc/borgmatic/config.yml
    mode: '0600'

```yaml

- name: Schedule backup cron job
  cron:
    name: "Daily system backup"
    minute: "0"
    hour: "2"
    job: "/usr/bin/borgmatic"
    user: root
```

---

> **💡 Pro Tip**: Start with simple configurations and gradually add complexity. Use version control for all configurations and test changes in a development environment first.

## 🐳 **Docker and Container Management**

### Docker Installation and Configuration

#### Automated Docker Installation via Ansible

```yaml
# roles/docker/tasks/main.yml
---
- name: Install Docker dependencies
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
    state: present
    update_cache: yes

- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present

- name: Install Docker Engine
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    state: present
    update_cache: yes

- name: Start and enable Docker service
  systemd:
    name: docker
    state: started
    enabled: yes

- name: Add users to docker group
  user:
    name: "{{ item }}"
    groups: docker
    append: yes
  loop: "{{ docker_users | default(['homelab']) }}"

- name: Configure Docker daemon
  template:
    src: daemon.json.j2
    dest: /etc/docker/daemon.json
    backup: yes
  notify: restart docker

- name: Create Docker networks
  docker_network:
    name: "{{ item.name }}"
    driver: "{{ item.driver | default('bridge') }}"
    ipam_config:
      - subnet: "{{ item.subnet }}"
        gateway: "{{ item.gateway }}"
  loop: "{{ docker_networks }}"
```

#### Docker Daemon Configuration

```json
# templates/daemon.json.j2
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "data-root": "/var/lib/docker",
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "features": {
    "buildkit": true
  },
  "default-address-pools": [
    {
      "base": "172.80.0.0/12",
      "size": 24
    }
  ],
  "bip": "172.17.0.1/16",
  "fixed-cidr": "172.17.0.0/16"
}
```

### Docker Compose Services Configuration

#### Directory Structure for Container Services

```text
/opt/homelab-containers/
├── docker-compose.yml              # Main compose file
├── .env                           # Environment variables
├── configs/                       # Configuration files
│   ├── nginx/
│   ├── prometheus/
│   ├── grafana/
│   └── loki/
├── data/                          # Persistent data
│   ├── prometheus/
│   ├── grafana/
│   ├── loki/
│   └── databases/
├── logs/                          # Application logs
└── scripts/
    ├── backup.sh
    ├── restore.sh
    └── maintenance.sh
```

#### Main Docker Compose Configuration

```yaml
# /opt/homelab-containers/docker-compose.yml
version: '3.8'

networks:
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
  web:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.0.0/16
  secure:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/16

volumes:
  prometheus_data:
  grafana_data:
  loki_data:
  postgres_data:
  redis_data:
  nginx_cache:

services:
  # Reverse Proxy and Load Balancer
  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./configs/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./configs/nginx/conf.d:/etc/nginx/conf.d:ro
      - ./data/nginx/ssl:/etc/nginx/ssl:ro
      - nginx_cache:/var/cache/nginx
      - ./logs/nginx:/var/log/nginx
    networks:
      - web
    depends_on:
      - grafana
      - prometheus
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Monitoring Stack
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    user: "1000:1000"
    ports:
      - "9090:9090"
    volumes:
      - ./configs/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./configs/prometheus/rules:/etc/prometheus/rules:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--storage.tsdb.retention.size=10GB'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    networks:
      - monitoring
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3

  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana
    restart: unless-stopped
    user: "1000:1000"
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SERVER_DOMAIN=${GRAFANA_DOMAIN}
      - GF_SERVER_ROOT_URL=https://${GRAFANA_DOMAIN}
      - GF_DATABASE_TYPE=postgres
      - GF_DATABASE_HOST=postgres:5432
      - GF_DATABASE_NAME=grafana
      - GF_DATABASE_USER=grafana
      - GF_DATABASE_PASSWORD=${POSTGRES_GRAFANA_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./configs/grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - monitoring
      - web
    depends_on:
      - postgres
      - prometheus
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  loki:
    image: grafana/loki:latest
    container_name: loki
    restart: unless-stopped
    user: "1000:1000"
    ports:
      - "3100:3100"
    volumes:
      - ./configs/loki/loki.yml:/etc/loki/local-config.yaml:ro
      - loki_data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - monitoring
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3100/ready"]
      interval: 30s
      timeout: 10s
      retries: 3

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    restart: unless-stopped
    volumes:
      - ./configs/promtail/promtail.yml:/etc/promtail/config.yml:ro
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - monitoring
    depends_on:
      - loki

  # Database Services
  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=homelab
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./configs/postgres/init:/docker-entrypoint-initdb.d:ro
    ports:
      - "5432:5432"
    networks:
      - secure
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d homelab"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    volumes:
      - redis_data:/data
      - ./configs/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
    ports:
      - "6379:6379"
    networks:
      - secure
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Backup Service
  backup:
    image: alpine:latest
    container_name: backup-service
    restart: "no"
    volumes:
      - prometheus_data:/backup/prometheus:ro
      - grafana_data:/backup/grafana:ro
      - loki_data:/backup/loki:ro
      - postgres_data:/backup/postgres:ro
      - redis_data:/backup/redis:ro
      - ./scripts:/scripts:ro
      - ./backups:/backups
    command: ["/scripts/backup.sh"]
    networks:
      - monitoring
    profiles:
      - backup

  # Network Tools and Utilities
  netshoot:
    image: nicolaka/netshoot
    container_name: netshoot
    restart: "no"
    network_mode: host
    profiles:
      - debug
    command: ["sleep", "infinity"]

  # SNMP Exporter for Network Monitoring
  snmp-exporter:
    image: prom/snmp-exporter:latest
    container_name: snmp-exporter
    restart: unless-stopped
    ports:
      - "9116:9116"
    volumes:
      - ./configs/snmp-exporter/snmp.yml:/etc/snmp_exporter/snmp.yml:ro
    networks:
      - monitoring
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9116/metrics"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Blackbox Exporter for Endpoint Monitoring
  blackbox-exporter:
    image: prom/blackbox-exporter:latest
    container_name: blackbox-exporter
    restart: unless-stopped
    ports:
      - "9115:9115"
    volumes:
      - ./configs/blackbox-exporter/blackbox.yml:/etc/blackbox_exporter/config.yml:ro
    networks:
      - monitoring
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9115/metrics"]
      interval: 30s
      timeout: 10s
      retries: 3
```

#### Environment Variables Configuration

```bash
# /opt/homelab-containers/.env
# Grafana Configuration
GRAFANA_ADMIN_PASSWORD=secure_admin_password_here
GRAFANA_DOMAIN=grafana.homelab.local

# Database Configuration
POSTGRES_USER=homelab_admin
POSTGRES_PASSWORD=secure_postgres_password_here
POSTGRES_GRAFANA_PASSWORD=secure_grafana_db_password_here

# Redis Configuration
REDIS_PASSWORD=secure_redis_password_here

# Network Configuration
DOCKER_SUBNET_MONITORING=172.20.0.0/16
DOCKER_SUBNET_WEB=172.21.0.0/16
DOCKER_SUBNET_SECURE=172.22.0.0/16

# Backup Configuration
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE="0 2 * * *"

# Resource Limits
PROMETHEUS_MEMORY_LIMIT=2G
GRAFANA_MEMORY_LIMIT=1G
LOKI_MEMORY_LIMIT=1G
POSTGRES_MEMORY_LIMIT=2G
```

### Container Management Scripts

#### Service Management Script

```bash
#!/bin/bash
# /opt/homelab-containers/scripts/manage-services.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running or not accessible"
        exit 1
    fi
}

# Function to validate compose file
validate_compose() {
    log "Validating docker-compose configuration..."
    if ! docker-compose -f "$COMPOSE_FILE" config -q; then
        error "Docker-compose configuration is invalid"
        exit 1
    fi
    log "Docker-compose configuration is valid"
}

# Function to start services
start_services() {
    log "Starting homelab services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    log "Services started successfully"
}

# Function to stop services
stop_services() {
    log "Stopping homelab services..."
    docker-compose -f "$COMPOSE_FILE" down
    log "Services stopped successfully"
}

# Function to restart services
restart_services() {
    log "Restarting homelab services..."
    docker-compose -f "$COMPOSE_FILE" restart
    log "Services restarted successfully"
}

# Function to show status
show_status() {
    log "Checking service status..."
    docker-compose -f "$COMPOSE_FILE" ps
}

# Function to show logs
show_logs() {
    local service="${1:-}"
    if [[ -n "$service" ]]; then
        docker-compose -f "$COMPOSE_FILE" logs -f "$service"
    else
        docker-compose -f "$COMPOSE_FILE" logs -f
    fi
}

# Function to update services
update_services() {
    log "Updating homelab services..."
    docker-compose -f "$COMPOSE_FILE" pull
    docker-compose -f "$COMPOSE_FILE" up -d --remove-orphans
    docker image prune -f
    log "Services updated successfully"
}

# Function to backup data
backup_data() {
    log "Starting backup process..."
    docker-compose -f "$COMPOSE_FILE" --profile backup run --rm backup
    log "Backup completed successfully"
}

# Function to cleanup unused resources
cleanup() {
    log "Cleaning up unused Docker resources..."
    docker container prune -f
    docker image prune -f
    docker volume prune -f
    docker network prune -f
    log "Cleanup completed"
}

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    start       Start all services
    stop        Stop all services
    restart     Restart all services
    status      Show service status
    logs        Show logs (optionally for specific service)
    update      Update all services to latest versions
    backup      Run backup process
    cleanup     Clean up unused Docker resources
    validate    Validate docker-compose configuration
    help        Show this help message

Examples:
    $0 start
    $0 logs grafana
    $0 update
    $0 backup

EOF
}

# Main script logic
main() {
    cd "$COMPOSE_DIR"
    
    case "${1:-help}" in
        start)
            check_docker
            validate_compose
            start_services
            ;;
        stop)
            check_docker
            stop_services
            ;;
        restart)
            check_docker
            restart_services
            ;;
        status)
            check_docker
            show_status
            ;;
        logs)
            check_docker
            show_logs "${2:-}"
            ;;
        update)
            check_docker
            validate_compose
            update_services
            ;;
        backup)
            check_docker
            backup_data
            ;;
        cleanup)
            check_docker
            cleanup
            ;;
        validate)
            validate_compose
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
```

#### Backup Script

```bash
#!/bin/bash
# /opt/homelab-containers/scripts/backup.sh

set -euo pipefail

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup volume data
backup_volume() {
    local volume_path="$1"
    local backup_name="$2"
    
    if [[ -d "$volume_path" ]]; then
        echo "Backing up $backup_name..."
        tar -czf "$BACKUP_DIR/${backup_name}_${DATE}.tar.gz" -C "$volume_path" .
        echo "Backup of $backup_name completed"
    else
        echo "Warning: $volume_path does not exist, skipping $backup_name backup"
    fi
}

# Backup each service data
backup_volume "/backup/prometheus" "prometheus"
backup_volume "/backup/grafana" "grafana"
backup_volume "/backup/loki" "loki"
backup_volume "/backup/postgres" "postgres"
backup_volume "/backup/redis" "redis"

# Create a combined backup manifest
cat > "$BACKUP_DIR/backup_manifest_${DATE}.txt" << EOF
Homelab Container Backup Manifest
Generated: $(date)
Backup ID: ${DATE}

Files included:
$(ls -la "$BACKUP_DIR"/*_${DATE}.tar.gz 2>/dev/null || echo "No backup files found")

Backup completed at: $(date)
EOF

# Cleanup old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "backup_manifest_*.txt" -mtime +$RETENTION_DAYS -delete

echo "Backup process completed successfully"
```

### Service Configuration Files

#### Prometheus Configuration

```yaml
# /opt/homelab-containers/configs/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']

  - job_name: 'loki'
    static_configs:
      - targets: ['loki:3100']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']

  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://grafana.homelab.local
        - http://prometheus:9090
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115

  - job_name: 'snmp-unifi'
    static_configs:
      - targets:
        - 192.168.101.1  # UniFi Dream Machine
    metrics_path: /snmp
    params:
      module: [ubiquiti_unifi]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
```

#### Nginx Configuration

```nginx
# /opt/homelab-containers/configs/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript
               application/javascript application/xml+rss application/json;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # Include additional configurations
    include /etc/nginx/conf.d/*.conf;
}
```

#### Grafana Proxy Configuration

```nginx
# /opt/homelab-containers/configs/nginx/conf.d/grafana.conf
upstream grafana {
    server grafana:3000;
    keepalive 32;
}

server {
    listen 80;
    server_name grafana.homelab.local;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name grafana.homelab.local;

    # SSL configuration
    ssl_certificate /etc/nginx/ssl/grafana.crt;
    ssl_certificate_key /etc/nginx/ssl/grafana.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
        proxy_pass http://grafana;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /api/health {
        proxy_pass http://grafana;
        access_log off;
    }
}
```

### Container Deployment Automation

#### Ansible Playbook for Container Deployment

```yaml
# /opt/homelab-ansible/playbooks/deploy-containers.yml
---
- name: Deploy Homelab Container Services
  hosts: container_hosts
  become: yes
  vars:
    container_dir: /opt/homelab-containers
    container_user: homelab
    
  tasks:
    - name: Create container directory structure
      file:
        path: "{{ item }}"
        state: directory
        owner: "{{ container_user }}"
        group: "{{ container_user }}"
        mode: '0755'
      loop:
        - "{{ container_dir }}"
        - "{{ container_dir }}/configs"
        - "{{ container_dir }}/data"
        - "{{ container_dir }}/logs"
        - "{{ container_dir }}/scripts"
        - "{{ container_dir }}/backups"

    - name: Copy docker-compose configuration
      template:
        src: docker-compose.yml.j2
        dest: "{{ container_dir }}/docker-compose.yml"
        owner: "{{ container_user }}"
        group: "{{ container_user }}"
        mode: '0644'
      notify: restart containers

    - name: Copy environment configuration
      template:
        src: env.j2
        dest: "{{ container_dir }}/.env"
        owner: "{{ container_user }}"
        group: "{{ container_user }}"
        mode: '0600'
      notify: restart containers

    - name: Copy service configurations
      copy:
        src: "{{ item.src }}"
        dest: "{{ container_dir }}/configs/{{ item.dest }}"
        owner: "{{ container_user }}"
        group: "{{ container_user }}"
        mode: '0644'
      loop:
        - { src: prometheus.yml, dest: prometheus/prometheus.yml }
        - { src: nginx.conf, dest: nginx/nginx.conf }
        - { src: grafana.conf, dest: nginx/conf.d/grafana.conf }
      notify: restart containers

    - name: Copy management scripts
      copy:
        src: "{{ item }}"
        dest: "{{ container_dir }}/scripts/"
        owner: "{{ container_user }}"
        group: "{{ container_user }}"
        mode: '0755'
      loop:
        - manage-services.sh
        - backup.sh

    - name: Set up systemd service for containers
      template:
        src: homelab-containers.service.j2
        dest: /etc/systemd/system/homelab-containers.service
        mode: '0644'
      notify:
        - reload systemd
        - enable container service

    - name: Set up backup cron job
      cron:
        name: "Homelab container backup"
        minute: "0"
        hour: "2"
        job: "{{ container_dir }}/scripts/manage-services.sh backup"
        user: "{{ container_user }}"

  handlers:
    - name: restart containers
      systemd:
        name: homelab-containers
        state: restarted
        daemon_reload: yes

    - name: reload systemd
      systemd:
        daemon_reload: yes

    - name: enable container service
      systemd:
        name: homelab-containers
        enabled: yes
        state: started
```

#### Systemd Service Template

```ini
# /opt/homelab-ansible/templates/homelab-containers.service.j2
[Unit]
Description=Homelab Container Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory={{ container_dir }}
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

### Container Monitoring and Maintenance

#### Health Check Script

```bash
#!/bin/bash
# /opt/homelab-containers/scripts/health-check.sh

set -euo pipefail

COMPOSE_FILE="/opt/homelab-containers/docker-compose.yml"
ALERT_EMAIL="admin@homelab.local"

# Function to check container health
check_container_health() {
    local container_name="$1"
    local health_status
    
    health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-health-check")
    
    case "$health_status" in
        "healthy")
            echo "✅ $container_name: Healthy"
            return 0
            ;;
        "unhealthy")
            echo "❌ $container_name: Unhealthy"
            return 1
            ;;
        "starting")
            echo "🔄 $container_name: Starting"
            return 0
            ;;
        "no-health-check")
            # Check if container is running
            if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
                echo "⚪ $container_name: Running (no health check)"
                return 0
            else
                echo "❌ $container_name: Not running"
                return 1
            fi
            ;;
        *)
            echo "❓ $container_name: Unknown status ($health_status)"
            return 1
            ;;
    esac
}

# Get list of containers from docker-compose
containers=$(docker-compose -f "$COMPOSE_FILE" ps --services)
failed_containers=()

echo "🔍 Checking container health..."
echo "================================"

for container in $containers; do
    if ! check_container_health "$container"; then
        failed_containers+=("$container")
    fi
done

echo "================================"

if [[ ${#failed_containers[@]} -eq 0 ]]; then
    echo "✅ All containers are healthy!"
    exit 0
else
    echo "❌ Failed containers: ${failed_containers[*]}"
    
    # Send alert email (if mail is configured)
    if command -v mail >/dev/null 2>&1; then
        echo "Container health check failed for: ${failed_containers[*]}" | \
            mail -s "Homelab Container Alert" "$ALERT_EMAIL"
    fi
    
    exit 1
fi
```

---

*This Infrastructure as Code approach provides reproducible, scalable, and maintainable infrastructure management for your home lab.*

---

*This Infrastructure as Code approach provides reproducible, scalable, and maintainable infrastructure management for your home lab.*
