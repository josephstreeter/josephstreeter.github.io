---
uid: infrastructure.packer.provisioners
title: Packer Provisioners
description: Comprehensive guide to Packer provisioners including Shell, PowerShell, Ansible, Chef, Puppet, and File provisioners for configuring machine images
ms.date: 01/18/2026
---

This section covers Packer provisioners for configuring machine images.

## What are Provisioners?

Provisioners are Packer components that install and configure software on running machines before they are turned into images. They prepare the machine image by executing scripts, transferring files, running configuration management tools, and performing other setup tasks.

### How Provisioners Work

The provisioning process occurs during the build phase:

1. **Builder Creates Instance**: A temporary instance is launched
2. **Connection Established**: Packer connects via SSH (Linux) or WinRM (Windows)
3. **Provisioners Execute**: Each provisioner runs in sequence
4. **Image Created**: Builder snapshots the configured instance
5. **Cleanup**: Temporary instance is terminated

### Provisioner Types

Packer supports several categories of provisioners:

- **Shell-Based**: Execute shell scripts and commands (Shell, PowerShell)
- **File Transfer**: Upload files and directories (File)
- **Configuration Management**: Apply configuration tools (Ansible, Chef, Puppet, Salt)
- **Cloud-Specific**: Cloud init, Windows-Update
- **Custom**: Breakpoint, Sleep, and custom provisioners

### Provisioner Order

Provisioners execute in the order they appear in the template. Use this to:

- Install base packages first
- Apply configuration management tools
- Run custom scripts last
- Clean up temporary files at the end

### Common Use Cases

- Install and configure software packages
- Apply security hardening
- Set up user accounts and permissions
- Configure networking and firewall rules
- Download application code and dependencies
- Run database migrations
- Apply configuration management policies
- Clean up installation artifacts

## Shell Provisioner

The Shell provisioner executes shell scripts on Linux and macOS systems. It's one of the most commonly used provisioners due to its simplicity and flexibility.

### Basic Usage

#### Shell Inline Commands

Execute commands directly in the template:

```hcl
provisioner "shell" {
  inline = [
    "sudo apt-get update",
    "sudo apt-get install -y nginx",
    "sudo systemctl enable nginx"
  ]
}
```

#### Script Files

Execute an external script:

```hcl
provisioner "shell" {
  script = "scripts/setup.sh"
}
```

#### Multiple Scripts

Execute multiple scripts in sequence:

```hcl
provisioner "shell" {
  scripts = [
    "scripts/update-system.sh",
    "scripts/install-packages.sh",
    "scripts/configure-app.sh",
    "scripts/cleanup.sh"
  ]
}
```

### Configuration Options

#### Shell Environment Variables

Pass environment variables to scripts:

```hcl
provisioner "shell" {
  environment_vars = [
    "APP_VERSION=1.2.3",
    "ENVIRONMENT=production",
    "DB_HOST=database.example.com"
  ]
  script = "scripts/install-app.sh"
}
```

#### Execute Command

Customize the shell interpreter:

```hcl
provisioner "shell" {
  execute_command = "echo 'packer' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
  inline = [
    "apt-get update",
    "apt-get install -y nginx"
  ]
}
```

#### Remote Path

Specify where to upload the script:

```hcl
provisioner "shell" {
  script      = "scripts/setup.sh"
  remote_path = "/tmp/custom-script.sh"
}
```

#### Elevated Execution

Run with sudo privileges:

```hcl
provisioner "shell" {
  inline = [
    "apt-get update",
    "apt-get install -y nginx"
  ]
  execute_command = "sudo sh '{{ .Path }}'"
}
```

### Advanced Features

#### Expecting Disconnections

Handle reboots and network changes:

```hcl
provisioner "shell" {
  inline = ["sudo reboot"]
  expect_disconnect = true
}

provisioner "shell" {
  pause_before = "30s"
  inline = [
    "echo 'System rebooted, continuing setup'"
  ]
}
```

#### Pausing Before Execution

Wait before running provisioner:

```hcl
provisioner "shell" {
  pause_before = "10s"
  inline = ["echo 'Waited 10 seconds'"]
}
```

#### Start Retry Timeout

Retry connection after disconnect:

```hcl
provisioner "shell" {
  inline              = ["sudo reboot"]
  expect_disconnect   = true
  start_retry_timeout = "5m"
}
```

### Best Practices

#### Error Handling

Use proper error handling in scripts:

```bash
#!/bin/bash
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Your provisioning logic
apt-get update || { echo "Failed to update"; exit 1; }
apt-get install -y nginx
```

#### Idempotency

Make scripts idempotent (safe to run multiple times):

```bash
#!/bin/bash

# Check if package is already installed
if ! command -v nginx &> /dev/null; then
    apt-get update
    apt-get install -y nginx
fi

# Configure only if not already configured
if [ ! -f /etc/nginx/sites-available/myapp ]; then
    cp /tmp/myapp.conf /etc/nginx/sites-available/myapp
    ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
fi
```

#### Logging

Add logging for troubleshooting:

```bash
#!/bin/bash

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting system update"
apt-get update
log "Installing packages"
apt-get install -y nginx
log "Configuration complete"
```

### Example: Complete Setup Script

```hcl
provisioner "shell" {
  environment_vars = [
    "APP_VERSION=1.2.3",
    "DEBIAN_FRONTEND=noninteractive"
  ]
  scripts = [
    "scripts/00-update-system.sh",
    "scripts/10-install-docker.sh",
    "scripts/20-configure-firewall.sh",
    "scripts/30-setup-app.sh",
    "scripts/99-cleanup.sh"
  ]
}
```

## File Provisioner

The File provisioner uploads files and directories from the local machine to the remote machine.

### File Provisioner Usage

#### Upload Single File

```hcl
provisioner "file" {
  source      = "configs/app.conf"
  destination = "/tmp/app.conf"
}
```

#### Upload Directory

```hcl
provisioner "file" {
  source      = "configs/"
  destination = "/tmp/configs"
}
```

#### Upload Multiple Files

```hcl
provisioner "file" {
  sources = [
    "files/config.yml",
    "files/secrets.env",
    "files/startup.sh"
  ]
  destination = "/tmp/"
}
```

### Generated Content

Upload content generated during build:

```hcl
provisioner "file" {
  content     = <<EOF
[app]
version = ${var.app_version}
environment = ${var.environment}
timestamp = ${timestamp()}
EOF
  destination = "/tmp/app-config.ini"
}
```

### Directory Handling

#### Trailing Slashes Matter

```hcl
# Uploads directory contents
provisioner "file" {
  source      = "myapp/"
  destination = "/opt/myapp"
}

# Uploads directory itself
provisioner "file" {
  source      = "myapp"
  destination = "/opt/"
}
```

### Permissions

Set file permissions after upload:

```hcl
provisioner "file" {
  source      = "scripts/startup.sh"
  destination = "/tmp/startup.sh"
}

provisioner "shell" {
  inline = [
    "chmod +x /tmp/startup.sh",
    "sudo mv /tmp/startup.sh /usr/local/bin/"
  ]
}
```

### File Transfer Best Practices

- Upload to `/tmp` first, then move with shell provisioner
- Avoid uploading large files (use download scripts instead)
- Use `.gitignore` patterns to exclude unnecessary files
- Set proper permissions after upload
- Verify file transfers with checksums

## Ansible Provisioner

The Ansible provisioner runs Ansible playbooks to configure the machine.

### Ansible Provisioner Usage

#### Local Ansible

Run Ansible from the Packer host:

```hcl
provisioner "ansible" {
  playbook_file = "playbooks/main.yml"
}
```

#### With Inventory

Use custom inventory:

```hcl
provisioner "ansible" {
  playbook_file   = "playbooks/main.yml"
  inventory_file  = "inventory/hosts"
  user            = "ubuntu"
}
```

### Ansible Configuration Options

#### Extra Arguments

Pass additional Ansible arguments:

```hcl
provisioner "ansible" {
  playbook_file = "playbooks/main.yml"
  extra_arguments = [
    "--extra-vars", "env=production app_version=1.2.3",
    "--tags", "configuration,deployment",
    "-v"
  ]
}
```

#### Ansible Environment Variables

Set Ansible-specific variables:

```hcl
provisioner "ansible" {
  playbook_file = "playbooks/main.yml"
  ansible_env_vars = [
    "ANSIBLE_HOST_KEY_CHECKING=False",
    "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'",
    "ANSIBLE_NOCOLOR=True"
  ]
}
```

#### Groups

Add host to Ansible groups:

```hcl
provisioner "ansible" {
  playbook_file = "playbooks/main.yml"
  groups        = ["webservers", "production"]
}
```

### Ansible Local

Run Ansible on the remote machine:

```hcl
provisioner "ansible-local" {
  playbook_file = "playbooks/main.yml"
  role_paths = [
    "roles/common",
    "roles/webserver"
  ]
  staging_directory = "/tmp/ansible"
}
```

### Example Playbook

```yaml
---
- name: Configure web server
  hosts: all
  become: yes
  
  vars:
    app_version: "{{ lookup('env', 'APP_VERSION') | default('1.0.0') }}"
  
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
    
    - name: Install packages
      apt:
        name:
          - nginx
          - python3-pip
          - git
        state: present
    
    - name: Configure nginx
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/sites-available/default
      notify: Restart nginx
    
    - name: Enable nginx
      systemd:
        name: nginx
        enabled: yes
        state: started
  
  handlers:
    - name: Restart nginx
      systemd:
        name: nginx
        state: restarted
```

### Ansible Best Practices

- Use `ansible-local` for airgapped environments
- Pin Ansible version for reproducibility
- Use Ansible Galaxy roles for common tasks
- Structure playbooks with roles
- Use variables for configuration values
- Test playbooks independently before using with Packer

## PowerShell Provisioner

The PowerShell provisioner executes PowerShell scripts on Windows systems.

### PowerShell Provisioner Usage

#### Inline Commands

```hcl
provisioner "powershell" {
  inline = [
    "Write-Host 'Installing IIS'",
    "Install-WindowsFeature -Name Web-Server -IncludeManagementTools",
    "New-Item -ItemType Directory -Path C:\\inetpub\\myapp -Force"
  ]
}
```

#### PowerShell Script Files

```hcl
provisioner "powershell" {
  script = "scripts/setup-windows.ps1"
}
```

#### Multiple PowerShell Scripts

```hcl
provisioner "powershell" {
  scripts = [
    "scripts/01-install-features.ps1",
    "scripts/02-configure-iis.ps1",
    "scripts/03-install-app.ps1"
  ]
}
```

### PowerShell Configuration Options

#### Environment Variables

```hcl
provisioner "powershell" {
  environment_vars = [
    "APP_VERSION=1.2.3",
    "ENVIRONMENT=Production"
  ]
  script = "scripts/install-app.ps1"
}
```

#### Elevated Privileges

```hcl
provisioner "powershell" {
  elevated_user     = "Administrator"
  elevated_password = "${var.admin_password}"
  script           = "scripts/install-drivers.ps1"
}
```

#### Execution Policy

```hcl
provisioner "powershell" {
  execution_policy = "Bypass"
  inline = [
    "Set-ExecutionPolicy Bypass -Scope Process -Force",
    "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force"
  ]
}
```

### PowerShell Advanced Features

#### Validating Exit Codes

```hcl
provisioner "powershell" {
  valid_exit_codes = [0, 3010]  # 3010 = reboot required
  inline = [
    "choco install googlechrome -y"
  ]
}
```

#### PowerShell Remote Path

```hcl
provisioner "powershell" {
  script      = "scripts/setup.ps1"
  remote_path = "C:/Temp/packer-setup.ps1"
}
```

### Example Scripts

#### Install Software

```powershell
# install-software.ps1

$ErrorActionPreference = "Stop"

Write-Host "Installing Chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

Write-Host "Installing packages"
choco install -y git
choco install -y nodejs-lts
choco install -y docker-desktop

Write-Host "Installation complete"
```

#### Configure Windows Features

```powershell
# configure-windows.ps1

$ErrorActionPreference = "Stop"

# Install Windows features
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Install-WindowsFeature -Name Web-Asp-Net45
Install-WindowsFeature -Name Web-Windows-Auth

# Configure Windows Firewall
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

# Set timezone
Set-TimeZone -Id "Eastern Standard Time"

Write-Host "Configuration complete"
```

### PowerShell Best Practices

- Use `$ErrorActionPreference = "Stop"` for error handling
- Check for existing installations before installing
- Use try/catch blocks for error handling
- Log actions for troubleshooting
- Use `-Force` flag to avoid prompts
- Test scripts locally before using with Packer

## Chef Provisioner

The Chef provisioner runs Chef cookbooks to configure the machine.

### Chef Solo

Run Chef without a Chef Server:

```hcl
provisioner "chef-solo" {
  cookbook_paths  = ["cookbooks"]
  roles_path      = "roles"
  data_bags_path  = "data_bags"
  environments_path = "environments"
  
  run_list = [
    "recipe[base]",
    "recipe[nginx]",
    "recipe[myapp]"
  ]
  
  json = {
    myapp = {
      version = "1.2.3"
      environment = "production"
    }
  }
}
```

### Chef Client

Use with Chef Server:

```hcl
provisioner "chef-client" {
  server_url      = "https://chef.example.com/organizations/myorg"
  validation_key_path = "chef-validator.pem"
  validation_client_name = "myorg-validator"
  
  run_list = [
    "role[web]",
    "recipe[myapp]"
  ]
  
  node_name = "packer-build-{{timestamp}}"
}
```

### Chef Configuration Options

- **cookbook_paths**: Paths to cookbook directories
- **run_list**: Chef recipes and roles to apply
- **json**: JSON attributes for Chef run
- **chef_environment**: Chef environment name
- **encrypted_data_bag_secret_path**: Path to encryption key
- **prevent_sudo**: Don't use sudo for Chef commands

## Puppet Provisioner

The Puppet provisioner applies Puppet manifests to configure the machine.

### Puppet Apply

Apply Puppet manifests locally:

```hcl
provisioner "puppet-masterless" {
  manifest_file = "manifests/site.pp"
  module_paths  = ["modules"]
  
  facter = {
    environment = "production"
    app_version = "1.2.3"
  }
}
```

### With Hiera

Use Hiera for configuration data:

```hcl
provisioner "puppet-masterless" {
  manifest_file = "manifests/site.pp"
  module_paths  = ["modules"]
  hiera_config_path = "hiera.yaml"
  
  facter = {
    environment = "production"
  }
}
```

### Puppet Agent

Use with Puppet Server:

```hcl
provisioner "puppet-server" {
  puppet_server = "puppet.example.com"
  puppet_node   = "webserver-{{timestamp}}"
  
  facter = {
    environment = "production"
  }
}
```

### Example Manifest

```puppet
# site.pp

node default {
  # Update package cache
  exec { 'apt-update':
    command => '/usr/bin/apt-get update',
  }
  
  # Install packages
  package { ['nginx', 'git', 'curl']:
    ensure  => installed,
    require => Exec['apt-update'],
  }
  
  # Configure nginx
  file { '/etc/nginx/sites-available/myapp':
    ensure  => file,
    content => template('myapp/nginx.conf.erb'),
    notify  => Service['nginx'],
  }
  
  # Ensure nginx is running
  service { 'nginx':
    ensure => running,
    enable => true,
  }
}
```

## Provisioner Best Practices

### General Guidelines

1. **Keep Provisioners Simple**: Break complex provisioning into multiple steps
2. **Use Configuration Management**: Prefer Ansible/Chef/Puppet over shell scripts for complex setups
3. **Make Idempotent**: Ensure provisioners can run multiple times safely
4. **Test Independently**: Test scripts/playbooks outside Packer first
5. **Log Everything**: Add logging for troubleshooting
6. **Handle Errors**: Use proper error handling in all scripts
7. **Clean Up**: Remove temporary files and caches at the end
8. **Version Control**: Store provisioning code in Git

### Performance Tips

- **Minimize Package Updates**: Only update necessary packages
- **Use Package Caching**: Configure package manager caches
- **Parallelize When Possible**: Some provisioners support parallel execution
- **Optimize Downloads**: Use local mirrors or caches
- **Clean Caches**: Remove package manager caches to reduce image size

### Security Practices

- **Don't Hardcode Secrets**: Use variables and environment variables
- **Validate Downloads**: Check checksums for downloaded files
- **Use HTTPS**: Always use secure connections
- **Apply Updates**: Install security updates during provisioning
- **Remove Credentials**: Clean up any temporary credentials
- **Disable Unnecessary Services**: Reduce attack surface

### Troubleshooting

- **Enable Verbose Logging**: Use `-v` or debug flags
- **Use Breakpoint Provisioner**: Pause builds for inspection
- **Test Connections**: Verify SSH/WinRM connectivity
- **Check File Paths**: Ensure paths are correct for the OS
- **Verify Permissions**: Check file and execution permissions
- **Review Logs**: Examine provisioner output carefully

## Next Steps

Now that you understand provisioners, learn about:

- [Packer Post-Processors](packer-post-processors.md) - Handle build artifacts
- [Best Practices](packer-best-practices.md) - Professional template development
- [Troubleshooting](packer-troubleshooting.md) - Solve common provisioning issues
