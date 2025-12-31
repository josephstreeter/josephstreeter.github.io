---
title: "Terraform with Hyper-V"
description: "Complete guide to using Terraform with Hyper-V for infrastructure automation and virtual machine management"
author: "josephstreeter"
ms.date: "2025-12-30"
ms.topic: "how-to-guide"
ms.service: "terraform"
keywords: ["Terraform", "Hyper-V", "Windows", "Infrastructure as Code", "IaC", "Virtualization", "PowerShell", "Automation"]
---

This guide demonstrates how to use Terraform with Hyper-V to automate virtual machine provisioning and infrastructure management on Windows Server and Windows 10/11 Pro.

## Overview

Terraform can manage Hyper-V infrastructure through the **hyperv** provider, which uses PowerShell remoting to interact with Hyper-V hosts. This enables infrastructure-as-code practices for Windows-based virtualization environments.

## Prerequisites

### Hyper-V Requirements

- Windows Server 2016+ or Windows 10/11 Pro with Hyper-V enabled
- Administrator privileges on the Hyper-V host
- PowerShell 5.1 or later
- Hyper-V PowerShell module installed

### Enable Hyper-V

**On Windows 10/11 Pro:**

```powershell
# Enable Hyper-V feature
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Restart required
Restart-Computer
```

**On Windows Server:**

```powershell
# Install Hyper-V role
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
```

### Configure PowerShell Remoting

For remote Hyper-V management, enable PowerShell remoting on the Hyper-V host:

```powershell
# Enable PS Remoting on Hyper-V host
Enable-PSRemoting -Force

# Configure WinRM
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

# Verify configuration
Get-Service WinRM | Select-Object Status
```

### Terraform Requirements

- Terraform >= 1.0
- Hyper-V Terraform provider (taliesins/hyperv)
- Network access to Hyper-V host
- Valid credentials for Hyper-V host

## Provider Configuration

### Local Hyper-V Host

For managing Hyper-V on the local machine:

```hcl
terraform {
    required_providers {
        hyperv = {
            source  = "taliesins/hyperv"
            version = "~> 1.0"
        }
    }
}

provider "hyperv" {
    user     = "Administrator"
    password = var.hyperv_password
    host     = "127.0.0.1"
    port     = 5985
    https    = false
    insecure = true
    use_ntlm = true
    timeout  = "30s"
}
```

### Remote Hyper-V Host

For managing a remote Hyper-V server:

```hcl
provider "hyperv" {
    user     = "DOMAIN\\Administrator"
    password = var.hyperv_password
    host     = "hyperv-host.example.com"
    port     = 5986  # HTTPS port
    https    = true
    insecure = false
    use_ntlm = true
    tls_server_name = "hyperv-host.example.com"
    cacert_path     = "./certs/ca.pem"
    cert_path       = "./certs/client.pem"
    key_path        = "./certs/client-key.pem"
    script_path     = "C:/Temp/terraform_%RAND%.ps1"
    timeout         = "60s"
}
```

### Variables File

Create `variables.tf`:

```hcl
variable "hyperv_password" {
    description = "Password for Hyper-V host administrator"
    type        = string
    sensitive   = true
}

variable "hyperv_host" {
    description = "Hyper-V host address"
    type        = string
    default     = "127.0.0.1"
}

variable "vm_memory" {
    description = "Memory allocation for VMs in MB"
    type        = number
    default     = 2048
}

variable "vm_processor_count" {
    description = "Number of virtual processors"
    type        = number
    default     = 2
}
```

## Virtual Machine Configuration

### Basic VM Deployment

Create `main.tf`:

```hcl
resource "hyperv_machine_instance" "web_server" {
    name               = "web-server-01"
    generation         = 2
    automatic_start    = false
    automatic_stop     = "Save"
    checkpoint_type    = "Production"
    dynamic_memory     = true
    guest_controlled_cache_types = false
    high_memory_mapped_io_space  = 536870912
    lock_on_disconnect = "Off"
    low_memory_mapped_io_space   = 134217728
    memory_maximum_bytes         = 4294967296
    memory_minimum_bytes         = 536870912
    memory_startup_bytes         = var.vm_memory * 1024 * 1024
    notes              = "Web server managed by Terraform"
    processor_count    = var.vm_processor_count
    smart_paging_file_path = "C:\\ProgramData\\Microsoft\\Windows\\Hyper-V"
    snapshot_file_location = "C:\\ProgramData\\Microsoft\\Windows\\Hyper-V"
    static_memory      = false
    state              = "Running"

    # VM hard disk
    vm_firmware {
        enable_secure_boot = "On"
        secure_boot_template = "MicrosoftWindows"
        preferred_network_boot_protocol = "IPv4"
        console_mode = "None"
        pause_after_boot_failure = "Off"
    }

    # VM processor features
    vm_processor {
        compatibility_for_migration_enabled               = false
        compatibility_for_older_operating_systems_enabled = false
        hw_thread_count_per_core                          = 0
        maximum                                           = 100
        reserve                                           = 0
        relative_weight                                   = 100
        maximum_count_per_numa_node                       = 0
        maximum_count_per_numa_socket                     = 0
        enable_host_resource_protection                   = false
        expose_virtualization_extensions                  = false
    }

    # Integration services
    integration_services = {
        "Guest Service Interface" = true
        "Heartbeat"              = true
        "Key-Value Pair Exchange" = true
        "Shutdown"               = true
        "Time Synchronization"   = true
        "VSS"                    = true
    }
}
```

### Network Configuration

Add network adapter:

```hcl
resource "hyperv_network_switch" "external_switch" {
    name                                    = "External-Switch"
    notes                                   = "External network switch"
    allow_management_os                     = true
    enable_embedded_teaming                 = false
    enable_iov                              = false
    enable_packet_direct                    = false
    minimum_bandwidth_mode                  = "None"
    switch_type                             = "External"
    net_adapter_names                       = ["Ethernet"]
    default_flow_minimum_bandwidth_absolute = 0
    default_flow_minimum_bandwidth_weight   = 0
    default_queue_vmmq_enabled              = false
    default_queue_vmmq_queue_pairs          = 16
    default_queue_vrss_enabled              = false
}

resource "hyperv_network_adapter" "web_server_nic" {
    vm_name                                = hyperv_machine_instance.web_server.name
    name                                   = "Network Adapter"
    switch_name                            = hyperv_network_switch.external_switch.name
    management_os                          = false
    is_legacy                              = false
    dynamic_mac_address                    = true
    device_naming                          = "Off"
    dhcp_guard                             = "Off"
    router_guard                           = "Off"
    port_mirroring                         = "None"
    ieee_priority_tag                      = "Off"
    vmq_weight                             = 100
    iov_queue_pairs_requested              = 1
    iov_interrupt_moderation               = "Off"
    iov_weight                             = 100
    ipsec_offload_maximum_security_association = 512
    maximum_bandwidth                      = 0
    minimum_bandwidth_absolute             = 0
    minimum_bandwidth_weight               = 0
    mandatory_feature_id                   = []
    resource_pool_name                     = ""
    test_replica_pool_name                 = ""
    test_replica_switch_name               = ""
    virtual_subnet_id                      = 0
    allow_teaming                          = "On"
    not_monitored_in_cluster               = false
    storm_limit                            = 0
    dynamic_ip_address_limit               = 0
    fixed_speed_10g                        = "Off"
    packet_direct_num_procs                = 0
    packet_direct_moderation_count         = 0
    packet_direct_moderation_interval      = 0
    vrss_enabled                           = true
    vmmq_enabled                           = false
    vmmq_queue_pairs                       = 16
}
```

### Hard Drive Configuration

Add VHD/VHDX:

```hcl
resource "hyperv_vhd" "os_disk" {
    path                 = "C:\\Hyper-V\\Virtual Hard Disks\\web-server-01-os.vhdx"
    size                 = 68719476736  # 64GB
    source               = ""
    source_vm            = ""
    source_disk          = 0
    vhd_type             = "Dynamic"
    parent_path          = ""
    block_size           = 0
    logical_sector_size  = 0
    physical_sector_size = 0
}

resource "hyperv_machine_hard_disk_drive" "os_drive" {
    vm_name                 = hyperv_machine_instance.web_server.name
    path                    = hyperv_vhd.os_disk.path
    controller_type         = "Scsi"
    controller_number       = 0
    controller_location     = 0
    resource_pool_name      = ""
    support_persistent_reservations = false
    maximum_iops            = 0
    minimum_iops            = 0
    qos_policy_id           = ""
    override_cache_attributes = "Default"
}
```

### DVD Drive for ISO Installation

```hcl
resource "hyperv_machine_dvd_drive" "os_install" {
    vm_name             = hyperv_machine_instance.web_server.name
    controller_number   = 0
    controller_location = 1
    path                = "C:\\ISOs\\ubuntu-22.04-server.iso"
    resource_pool_name  = ""
}
```

## Complete Example: Multiple VMs

Create a complete infrastructure with multiple VMs:

```hcl
locals {
    vms = {
        "web-01" = {
            memory     = 4096
            processors = 2
            role       = "web"
        }
        "app-01" = {
            memory     = 8192
            processors = 4
            role       = "application"
        }
        "db-01" = {
            memory     = 16384
            processors = 8
            role       = "database"
        }
    }
}

resource "hyperv_vhd" "vm_disks" {
    for_each = local.vms

    path     = "C:\\Hyper-V\\Virtual Hard Disks\\${each.key}-os.vhdx"
    size     = 137438953472  # 128GB
    vhd_type = "Dynamic"
}

resource "hyperv_machine_instance" "vms" {
    for_each = local.vms

    name                  = each.key
    generation            = 2
    automatic_start       = true
    automatic_stop        = "ShutDown"
    checkpoint_type       = "ProductionOnly"
    dynamic_memory        = true
    memory_startup_bytes  = each.value.memory * 1024 * 1024
    memory_minimum_bytes  = (each.value.memory / 2) * 1024 * 1024
    memory_maximum_bytes  = each.value.memory * 2 * 1024 * 1024
    processor_count       = each.value.processors
    notes                 = "Role: ${each.value.role} | Managed by Terraform"
    state                 = "Running"

    vm_firmware {
        enable_secure_boot           = "On"
        secure_boot_template         = "MicrosoftUEFICertificateAuthority"
        preferred_network_boot_protocol = "IPv4"
    }

    vm_processor {
        compatibility_for_migration_enabled = false
        maximum                             = 100
        reserve                             = 0
        relative_weight                     = 100
    }

    integration_services = {
        "Guest Service Interface" = true
        "Heartbeat"              = true
        "Key-Value Pair Exchange" = true
        "Shutdown"               = true
        "Time Synchronization"   = true
        "VSS"                    = true
    }
}

resource "hyperv_machine_hard_disk_drive" "vm_os_drives" {
    for_each = local.vms

    vm_name             = hyperv_machine_instance.vms[each.key].name
    path                = hyperv_vhd.vm_disks[each.key].path
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
}

resource "hyperv_network_adapter" "vm_nics" {
    for_each = local.vms

    vm_name             = hyperv_machine_instance.vms[each.key].name
    name                = "Network Adapter"
    switch_name         = "External-Switch"
    management_os       = false
    is_legacy           = false
    dynamic_mac_address = true
}
```

## Using Existing VHD Templates

Clone from a prepared template:

```hcl
resource "hyperv_vhd" "template_clone" {
    path        = "C:\\Hyper-V\\Virtual Hard Disks\\new-vm.vhdx"
    source      = "C:\\Hyper-V\\Templates\\ubuntu-template.vhdx"
    vhd_type    = "Dynamic"
    parent_path = ""
}
```

## Outputs

Define outputs for VM information:

```hcl
output "vm_names" {
    description = "Names of created VMs"
    value       = [for vm in hyperv_machine_instance.vms : vm.name]
}

output "vm_states" {
    description = "States of created VMs"
    value = {
        for name, vm in hyperv_machine_instance.vms : name => vm.state
    }
}

output "vm_details" {
    description = "Detailed VM information"
    value = {
        for name, vm in hyperv_machine_instance.vms : name => {
            memory     = vm.memory_startup_bytes / 1024 / 1024
            processors = vm.processor_count
            state      = vm.state
        }
    }
}
```

## Deployment Workflow

### Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Create terraform.tfvars for sensitive variables
cat > terraform.tfvars <<EOF
hyperv_password = "YourSecurePassword"
hyperv_host     = "hyperv-server.local"
EOF

# Plan deployment
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# Check VM status
terraform show
```

### Destroy Resources

```bash
# Destroy specific VM
terraform destroy -target=hyperv_machine_instance.web_server

# Destroy all resources
terraform destroy
```

## Best Practices

### Security

1. **Use Secure Credentials**

    ```hcl
    # Store passwords in environment variables
    export TF_VAR_hyperv_password="SecurePassword"
    
    # Or use encrypted secrets management
    data "external" "hyperv_creds" {
        program = ["powershell", "-File", "./get-creds.ps1"]
    }
    ```

2. **Enable HTTPS for Remote Management**

    ```powershell
    # Configure HTTPS listener
    New-WSManInstance -ResourceURI winrm/config/Listener `
        -SelectorSet @{Address="*";Transport="HTTPS"} `
        -ValueSet @{CertificateThumbprint="YOUR_CERT_THUMBPRINT"}
    ```

3. **Use Least Privilege**
    - Create dedicated service account for Terraform
    - Grant only necessary Hyper-V permissions
    - Avoid using Domain Admin for automation

### Resource Management

1. **Use Resource Pools**

    ```hcl
    resource "hyperv_machine_instance" "vm" {
        # ... other configuration ...
        
        # Assign to resource pool for better management
        notes = "Environment: Production | Owner: DevOps | Project: WebApp"
    }
    ```

2. **Implement Naming Conventions**

    ```hcl
    locals {
        environment = "prod"
        project     = "webapp"
        
        vm_name = "${local.environment}-${local.project}-${var.vm_role}"
    }
    ```

3. **Tag Resources**

    ```hcl
    resource "hyperv_machine_instance" "vm" {
        name  = "web-server-01"
        notes = jsonencode({
            environment = "production"
            managed_by  = "terraform"
            project     = "web-application"
            cost_center = "engineering"
        })
    }
    ```

### Performance Optimization

1. **Dynamic Memory Configuration**

    ```hcl
    resource "hyperv_machine_instance" "vm" {
        dynamic_memory       = true
        memory_startup_bytes = 2147483648   # 2GB start
        memory_minimum_bytes = 536870912    # 512MB minimum
        memory_maximum_bytes = 8589934592   # 8GB maximum
    }
    ```

2. **NUMA Configuration** for large VMs

    ```hcl
    vm_processor {
        maximum_count_per_numa_node   = 8
        maximum_count_per_numa_socket = 16
    }
    ```

3. **Use Generation 2 VMs** for better performance

    ```hcl
    resource "hyperv_machine_instance" "vm" {
        generation = 2  # Better performance, UEFI support
        
        vm_firmware {
            enable_secure_boot           = "On"
            secure_boot_template         = "MicrosoftUEFICertificateAuthority"
        }
    }
    ```

### Backup and Recovery

1. **Enable Production Checkpoints**

    ```hcl
    resource "hyperv_machine_instance" "vm" {
        checkpoint_type = "ProductionOnly"
        # Production checkpoints use VSS for application-consistent snapshots
    }
    ```

2. **External Backup Integration**

    ```powershell
    # Create pre-deployment backup
    $vmName = "web-server-01"
    Checkpoint-VM -Name $vmName -SnapshotName "Pre-Terraform-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    ```

## Automation Examples

### Jenkins Pipeline Integration

```groovy
pipeline {
    agent any
    
    environment {
        TF_VAR_hyperv_password = credentials('hyperv-admin-password')
    }
    
    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }
        
        stage('Terraform Apply') {
            when {
                branch 'main'
            }
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'tfplan', allowEmptyArchive: true
        }
    }
}
```

### PowerShell Wrapper Script

```powershell
<#
.SYNOPSIS
    Terraform Hyper-V deployment wrapper
.DESCRIPTION
    Automates Terraform deployment with validation and logging
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('plan', 'apply', 'destroy')]
    [string]$Action,
    
    [Parameter()]
    [string]$ConfigPath = ".\terraform"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Verify Hyper-V is available
if (-not (Get-Command Get-VM -ErrorAction SilentlyContinue)) {
    throw "Hyper-V PowerShell module not available"
}

# Change to Terraform directory
Push-Location $ConfigPath

try {
    # Initialize if needed
    if (-not (Test-Path ".terraform")) {
        Write-Host "Initializing Terraform..." -ForegroundColor Cyan
        terraform init
    }
    
    # Execute action
    switch ($Action) {
        'plan' {
            Write-Host "Creating Terraform plan..." -ForegroundColor Cyan
            terraform plan -out=tfplan
        }
        'apply' {
            if (-not (Test-Path "tfplan")) {
                Write-Warning "No plan file found. Creating plan first..."
                terraform plan -out=tfplan
            }
            
            Write-Host "Applying Terraform configuration..." -ForegroundColor Green
            terraform apply tfplan
            Remove-Item tfplan
        }
        'destroy' {
            Write-Warning "This will destroy all Terraform-managed resources!"
            $confirm = Read-Host "Type 'yes' to confirm"
            
            if ($confirm -eq 'yes') {
                terraform destroy -auto-approve
            } else {
                Write-Host "Destruction cancelled" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "`nOperation completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Terraform operation failed: $_"
    exit 1
}
finally {
    Pop-Location
}
```

## Troubleshooting

### Common Issues

#### PowerShell Remoting Failures

```powershell
# Test WinRM connectivity
Test-WSMan -ComputerName hyperv-host.local

# Check firewall rules
Get-NetFirewallRule -DisplayName "Windows Remote Management*" | 
    Select-Object Name, Enabled, Direction

# Enable WinRM firewall rules
Enable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"
```

#### Authentication Issues

```powershell
# Verify credentials work
$cred = Get-Credential
Invoke-Command -ComputerName hyperv-host.local -Credential $cred -ScriptBlock {
    Get-VM
}

# For domain authentication, use full domain name
# DOMAIN\username, not just username
```

#### Provider Installation Issues

```bash
# Manually install provider if auto-install fails
terraform init -upgrade

# Verify provider installation
terraform providers

# Check provider version
terraform version
```

### Enable Detailed Logging

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH="./terraform-debug.log"

# Run Terraform command
terraform apply

# Review logs
cat terraform-debug.log | grep -i error
```

### Validate Configuration

```bash
# Validate Terraform syntax
terraform validate

# Format configuration files
terraform fmt -recursive

# Check for provider-specific issues
terraform plan -detailed-exitcode
```

## Limitations

### Current Hyper-V Provider Limitations

1. **No Cloud-Init Support** - Manual configuration required for guest OS
2. **Limited Guest OS Integration** - No automated IP address retrieval
3. **No Snapshot Management** - Cannot manage checkpoints via Terraform
4. **Windows Management Only** - Provider uses PowerShell, requires Windows host
5. **No Live Migration** - Cannot move VMs between hosts
6. **Limited Networking** - Complex network configurations require manual setup

### Workarounds

#### Automated Guest Configuration

Use PowerShell Direct for guest configuration:

```hcl
resource "null_resource" "configure_vm" {
    depends_on = [hyperv_machine_instance.web_server]
    
    provisioner "local-exec" {
        command = <<-EOT
            Invoke-Command -VMName ${hyperv_machine_instance.web_server.name} `
                -Credential $guestCreds `
                -ScriptBlock {
                    # Configure guest OS
                    Set-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.100
                }
        EOT
        interpreter = ["PowerShell", "-Command"]
    }
}
```

#### IP Address Retrieval

```hcl
data "external" "vm_ip" {
    depends_on = [hyperv_machine_instance.web_server]
    
    program = ["powershell", "-Command", <<-EOT
        $vm = Get-VM -Name ${hyperv_machine_instance.web_server.name}
        $ip = ($vm.NetworkAdapters | Get-VMNetworkAdapter)[0].IPAddresses[0]
        @{ ip = $ip } | ConvertTo-Json
    EOT
    ]
}

output "vm_ip_address" {
    value = data.external.vm_ip.result.ip
}
```

## Alternative Solutions

### Vagrant with Hyper-V

For simpler VM management:

```ruby
Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    config.vm.provider "hyperv" do |h|
        h.vmname = "ubuntu-dev"
        h.memory = 4096
        h.cpus = 2
    end
end
```

### PowerShell DSC

For configuration management:

```powershell
Configuration HyperVVMs {
    Import-DscResource -ModuleName xHyper-V
    
    Node "localhost" {
        xVMHyperV WebServer {
            Ensure        = "Present"
            Name          = "WebServer01"
            VhdPath       = "C:\VMs\WebServer01.vhdx"
            Generation    = 2
            StartupMemory = 4GB
            ProcessorCount = 2
        }
    }
}
```

## Resources

### Official Documentation

- [Terraform Hyper-V Provider](https://registry.terraform.io/providers/taliesins/hyperv/latest/docs)
- [Hyper-V PowerShell Reference](https://learn.microsoft.com/en-us/powershell/module/hyper-v/)
- [Windows Server Hyper-V](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/hyper-v-on-windows-server)

### Community Resources

- [Terraform Hyper-V Provider GitHub](https://github.com/taliesins/terraform-provider-hyperv)
- [Hyper-V Best Practices](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/best-practices-for-running-linux-on-hyper-v)
- [PowerShell Remoting Guide](https://learn.microsoft.com/en-us/powershell/scripting/learn/remoting/running-remote-commands)

## Summary

Terraform can effectively manage Hyper-V infrastructure for:

- ✅ VM provisioning and lifecycle management
- ✅ Network configuration and virtual switches
- ✅ Storage management with VHD/VHDX
- ✅ Infrastructure as code for Windows environments
- ✅ Integration with existing DevOps pipelines

**Key Considerations:**

- Requires PowerShell remoting for management
- Limited compared to cloud providers (AWS, Azure)
- Best suited for on-premises Windows infrastructure
- Combine with configuration management tools for complete automation
- Consider alternatives (Vagrant, PowerShell DSC) for simpler use cases

**Next Steps:**

1. Set up PowerShell remoting on Hyper-V hosts
2. Create VM templates for faster provisioning
3. Implement automated guest OS configuration
4. Integrate with CI/CD pipelines
5. Establish backup and disaster recovery procedures
