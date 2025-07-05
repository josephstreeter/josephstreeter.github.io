---
title: "SSH Configuration"
description: "Complete guide to SSH setup and configuration"
tags: ["security", "networking", "authentication"]
category: "infrastructure"
difficulty: "intermediate"
last_updated: "2025-01-20"
---

## Ansible

Ansible is an open-source automation platform that simplifies configuration management, application deployment, and task automation across multiple systems. It uses a declarative language to describe system configurations and automates complex IT tasks without requiring agents on target machines.

## What is Ansible?

Ansible is a powerful automation tool that allows you to:

- **Configure systems** consistently across your infrastructure
- **Deploy applications** to multiple environments
- **Orchestrate complex workflows** involving multiple systems
- **Manage cloud resources** and infrastructure as code
- **Automate repetitive tasks** to reduce human error

## Key Features

- **Agentless**: No need to install software on target machines
- **SSH-based**: Uses existing SSH connections for communication
- **Idempotent**: Runs can be repeated safely without unwanted changes
- **Human-readable**: Uses YAML syntax that's easy to read and write
- **Extensible**: Large library of modules for various systems and services

## Common Use Cases

- **Configuration Management**: Ensure servers are configured consistently
- **Application Deployment**: Automate deployment pipelines
- **Infrastructure Provisioning**: Create and manage cloud resources
- **Security Compliance**: Apply security policies across systems
- **Disaster Recovery**: Automate backup and recovery procedures

## How Ansible Works

1. **Inventory**: Define which hosts to manage
2. **Playbooks**: Write automation scripts in YAML
3. **Modules**: Use pre-built functions for specific tasks
4. **Execution**: Ansible connects via SSH and runs tasks

## Ansible Setup

### Installation

**Ubuntu/Debian:**

```bash
# Update package manager
sudo apt update && sudo apt upgrade -y

# Install Ansible
sudo apt install ansible -y

# Verify installation
ansible --version
```

**RHEL/CentOS/Fedora:**

```bash
# Enable EPEL repository (RHEL/CentOS)
sudo yum install epel-release -y

# Install Ansible
sudo yum install ansible -y

# Verify installation
ansible --version
```

**Using pip (all distributions):**

```bash
# Install pip if not available
sudo apt install python3-pip -y  # Ubuntu/Debian
# sudo yum install python3-pip -y  # RHEL/CentOS

# Install Ansible via pip
pip3 install ansible

# Verify installation
ansible --version
```

### Directory Structure Setup

Create the recommended Ansible directory structure:

[Ansible Sample Setup](https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html)

```bash
# Create main Ansible directory
sudo mkdir -p /etc/ansible

# Create recommended directory structure
sudo mkdir -p /etc/ansible/{inventories,group_vars,host_vars,roles,playbooks}

# Create subdirectories for different environments
sudo mkdir -p /etc/ansible/inventories/{production,staging,development}

# Set proper permissions (optional - use current user)
sudo chown -R $USER:$USER /etc/ansible
```

### Configuration File

Create a basic Ansible configuration file:

```bash
# Create ansible.cfg in /etc/ansible/
sudo tee /etc/ansible/ansible.cfg > /dev/null <<EOF
[defaults]
inventory = /etc/ansible/inventories/hosts
remote_user = ansible
ask_pass = false
host_key_checking = false
retry_files_enabled = false
gathering = smart
fact_caching = memory

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = true
EOF
```

## Populate Inventory

Enter hosts by role in an inventory file. The file can be in INI or YAML format.

### INI Format (Recommended for beginners)

```ini
# /etc/ansible/inventories/hosts

# Ungrouped hosts
mail.example.com

[webservers]
foo.example.com
bar.example.com

[dbservers]
one.example.com
two.example.com
three.example.com

[webservers:vars]
http_port=80
max_clients=200

[dbservers:vars]
mysql_port=3306
mysql_max_connections=100

# Group of groups
[production:children]
webservers
dbservers
```

### YAML Format

```yaml
# /etc/ansible/inventories/hosts.yml
all:
  hosts:
    mail.example.com:
  children:
    webservers:
      hosts:
        foo.example.com:
        bar.example.com:
      vars:
        http_port: 80
        max_clients: 200
    dbservers:
      hosts:
        one.example.com:
        two.example.com:
        three.example.com:
      vars:
        mysql_port: 3306
        mysql_max_connections: 100
    production:
      children:
        webservers:
        dbservers:
```

### Test Connectivity

Verify Ansible can connect to your hosts:

```bash
# Test connection to all hosts
ansible all -m ping

# Test connection to specific group
ansible webservers -m ping

# Get system information
ansible all -m setup --tree /tmp/facts
```

## Create Playbook

Ansible playbooks are YAML files that define a series of tasks to be executed on target hosts. They are the heart of Ansible automation and allow you to orchestrate complex deployments and configurations.

### Basic Playbook Structure

A playbook consists of one or more "plays" that map groups of hosts to tasks. Here's the basic structure:

```yaml
---
- name: Play name
  hosts: target_hosts
  become: yes  # Run with sudo privileges
  vars:
    variable_name: value
  tasks:
    - name: Task description
      module_name:
        parameter: value
```

### Example: Web Server Setup Playbook

Create a file named `webserver-setup.yml`:

```yaml
---
- name: Configure web servers
  hosts: webservers
  become: yes
  vars:
    http_port: 80
    max_clients: 200
  
  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
    
    - name: Install Apache web server
      apt:
        name: apache2
        state: present
    
    - name: Start and enable Apache service
      systemd:
        name: apache2
        state: started
        enabled: yes
    
    - name: Create custom index page
      copy:
        content: |
          <html>
            <head><title>Welcome</title></head>
            <body><h1>Server configured by Ansible!</h1></body>
          </html>
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'
    
    - name: Configure firewall for HTTP
      ufw:
        rule: allow
        port: "{{ http_port }}"
        proto: tcp
```

### Running the Playbook

Execute the playbook with the following command:

```bash
ansible-playbook -i inventory webserver-setup.yml
```

Options:

- `-i inventory`: Specify the inventory file
- `--check`: Dry run to see what would change
- `--limit webservers`: Run only on specific hosts/groups
- `-v`: Verbose output

### Example: Database Server Playbook

Create `database-setup.yml` for database servers:

```yaml
---
- name: Configure database servers
  hosts: dbservers
  become: yes
  vars:
    mysql_root_password: "secure_password_123"
  
  tasks:
    - name: Install MySQL server
      apt:
        name: mysql-server
        state: present
    
    - name: Start MySQL service
      systemd:
        name: mysql
        state: started
        enabled: yes
    
    - name: Set MySQL root password
      mysql_user:
        name: root
        password: "{{ mysql_root_password }}"
        login_unix_socket: /var/run/mysqld/mysqld.sock
    
    - name: Create application database
      mysql_db:
        name: webapp_db
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"
```

### Best Practices

- **Use descriptive names** for plays and tasks
- **Group related tasks** logically
- **Use variables** for values that might change
- **Test with `--check`** before running destructive operations
- **Use roles** for complex, reusable configurations
- **Keep sensitive data** in encrypted secrets management
