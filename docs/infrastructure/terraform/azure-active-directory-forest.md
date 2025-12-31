---
title: "Azure Active Directory Forest with Terraform"
description: "Complete guide to deploying and managing a production-ready Active Directory Forest on Azure using Terraform infrastructure as code"
author: "josephstreeter"
ms.date: "2025-08-30"
ms.topic: "how-to-guide"
ms.service: "azure"
keywords: ["Azure", "Active Directory", "AD", "Forest", "Domain Controller", "Terraform", "Infrastructure as Code", "Windows Server", "DNS", "LDAP"]
---

This guide provides a comprehensive approach to deploying a production-ready Active Directory Forest on Azure using Terraform. The configuration includes domain controllers, proper networking, security hardening, and operational considerations.

## Architecture Overview

### Deployment Options

#### Option 1: Azure AD Domain Services (Managed)

- **Recommended for most scenarios**
- Microsoft-managed domain controllers
- Automatic patching and maintenance
- Built-in high availability
- Limited customization options

#### Option 2: Self-Managed AD Forest (This Guide)

- **Full control** over AD configuration
- **Custom schema extensions** and policies
- **Advanced DNS configurations**
- **Complete administrative access**
- **Higher operational overhead**

### Network Architecture

```text
┌───────────────────────────────────────────────────────┐
│                    Azure Region                       │
│  ┌──────────────────────────────────────────────────┐ │
│  │              Virtual Network                     │ │
│  │  ┌─────────────────┐  ┌─────────────────────────┐│ │
│  │  │  AD Subnet      │  │    Client Subnet        ││ │
│  │  │  10.0.1.0/24    │  │    10.0.2.0/24          ││ │
│  │  │                 │  │                         ││ │
│  │  │ ┌─────────────┐ │  │ ┌─────────────────────┐ ││ │
│  │  │ │     DC-01   │ │  │ │   Client VMs        │ ││ │
│  │  │ │ Primary DC  │ │  │ │                     │ ││ │
│  │  │ └─────────────┘ │  │ └─────────────────────┘ ││ │
│  │  │ ┌─────────────┐ │  │                         ││ │
│  │  │ │     DC-02   │ │  │                         ││ │
│  │  │ │ Secondary   │ │  │                         ││ │
│  │  │ └─────────────┘ │  │                         ││ │
│  │  └─────────────────┘  └─────────────────────────┘│ │
│  └──────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Azure Requirements

- **Azure Subscription** with sufficient quotas
- **Resource Group** permissions (Contributor or Owner)
- **Network Contributor** role for networking resources
- **Virtual Machine Contributor** role for compute resources

### Windows Server Licensing

- **Windows Server Datacenter** licenses (recommended for Azure)
- **Active Directory** services included with Windows Server
- Consider **Azure Hybrid Benefit** for cost savings

### Terraform Requirements

- **Terraform** >= 1.0
- **Azure CLI** installed and authenticated
- **AzureRM Provider** >= 3.0
- **SSH access** or **Azure Bastion** for management

### Domain Planning

- **Domain name** (e.g., `contoso.local`, `ad.company.com`)
- **NetBIOS name** (e.g., `CONTOSO`)
- **IP address ranges** for subnets
- **DNS forwarder** configuration

---

## Terraform Configuration

### Project Structure

```text
azure-ad-forest/
├── main.tf                    # Main resource definitions
├── variables.tf              # Input variables
├── outputs.tf               # Output values
├── providers.tf             # Provider configurations
├── terraform.tfvars        # Variable values (DO NOT COMMIT)
├── modules/
│   ├── networking/          # VNet and subnet configuration
│   ├── domain-controller/   # DC VM configuration
│   └── security/           # NSG and firewall rules
├── scripts/
│   ├── install-ad.ps1      # AD installation script
│   ├── promote-dc.ps1      # DC promotion script
│   └── configure-dns.ps1   # DNS configuration
└── policies/
    ├── password-policy.json # Password policy configuration
    └── group-policies/     # Group policy templates
```

### `providers.tf`

```text
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = true
      skip_shutdown_and_force_delete = false
    }
  }
}
```

### `variables.tf`

```text
variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group"
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "East US"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "domain_name" {
  type        = string
  description = "Active Directory domain name"
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid FQDN format."
  }
}

variable "netbios_name" {
  type        = string
  description = "NetBIOS name for the domain"
  validation {
    condition     = can(regex("^[A-Z0-9]{1,15}$", var.netbios_name))
    error_message = "NetBIOS name must be 1-15 uppercase alphanumeric characters."
  }
}

variable "admin_username" {
  type        = string
  description = "Administrator username for domain controllers"
  default     = "azureadmin"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{2,19}$", var.admin_username))
    error_message = "Admin username must be 3-20 characters, start with letter."
  }
}

variable "admin_password" {
  type        = string
  description = "Administrator password for domain controllers"
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Password must be at least 12 characters long."
  }
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  default     = ["10.0.0.0/16"]
}

variable "ad_subnet_prefix" {
  type        = string
  description = "Address prefix for Active Directory subnet"
  default     = "10.0.1.0/24"
}

variable "client_subnet_prefix" {
  type        = string
  description = "Address prefix for client subnet"
  default     = "10.0.2.0/24"
}

variable "domain_controllers" {
  type = map(object({
    vm_size             = string
    availability_zone   = string
    private_ip_address  = string
    data_disk_size_gb   = number
  }))
  description = "Domain controller configurations"
  default = {
    "dc01" = {
      vm_size             = "Standard_D2s_v3"
      availability_zone   = "1"
      private_ip_address  = "10.0.1.4"
      data_disk_size_gb   = 128
    }
    "dc02" = {
      vm_size             = "Standard_D2s_v3"
      availability_zone   = "2"
      private_ip_address  = "10.0.1.5"
      data_disk_size_gb   = 128
    }
  }
}

variable "dns_forwarders" {
  type        = list(string)
  description = "DNS forwarder IP addresses"
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain VM backups"
  default     = 30
}

variable "enable_backup" {
  type        = bool
  description = "Enable Azure Backup for domain controllers"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Project     = "ActiveDirectory"
    Environment = "Production"
    Owner       = "ITOps"
  }
}
```

### `main.tf`

```text
# Local values for computed configurations
locals {
  common_tags = merge(var.tags, {
    DeployedBy = "Terraform"
    Domain     = var.domain_name
  })
  
  # DNS server addresses (domain controllers)
  dns_servers = [for dc in var.domain_controllers : dc.private_ip_address]
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Network Security Group for AD
resource "azurerm_network_security_group" "ad_nsg" {
  name                = "${var.resource_group_name}-ad-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # AD Web Services
  security_rule {
    name                       = "AD-Web-Services"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9389"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  # LDAP
  security_rule {
    name                       = "LDAP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "389"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  # LDAPS
  security_rule {
    name                       = "LDAPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "636"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  # Global Catalog
  security_rule {
    name                       = "Global-Catalog"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3268"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  # Global Catalog SSL
  security_rule {
    name                       = "Global-Catalog-SSL"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3269"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  # Kerberos
  security_rule {
    name                       = "Kerberos"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  # DNS
  security_rule {
    name                       = "DNS"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  # SMB
  security_rule {
    name                       = "SMB"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  # RPC Endpoint Mapper
  security_rule {
    name                       = "RPC-Endpoint-Mapper"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "135"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  # Dynamic RPC
  security_rule {
    name                       = "Dynamic-RPC"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "49152-65535"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  # RDP (Management)
  security_rule {
    name                       = "RDP"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_servers         = local.dns_servers

  tags = local.common_tags
}

# Active Directory Subnet
resource "azurerm_subnet" "ad_subnet" {
  name                 = "ad-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.ad_subnet_prefix]
}

# Client Subnet
resource "azurerm_subnet" "client_subnet" {
  name                 = "client-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.client_subnet_prefix]
}

# Associate NSG with AD subnet
resource "azurerm_subnet_network_security_group_association" "ad_nsg_association" {
  subnet_id                 = azurerm_subnet.ad_subnet.id
  network_security_group_id = azurerm_network_security_group.ad_nsg.id
}

# Recovery Services Vault for backups
resource "azurerm_recovery_services_vault" "main" {
  count               = var.enable_backup ? 1 : 0
  name                = "${var.resource_group_name}-rsv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  soft_delete_enabled = true

  tags = local.common_tags
}

# Backup policy
resource "azurerm_backup_policy_vm" "main" {
  count               = var.enable_backup ? 1 : 0
  name                = "ad-backup-policy"
  resource_group_name = azurerm_resource_group.main.name
  recovery_vault_name = azurerm_recovery_services_vault.main[0].name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = var.backup_retention_days
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

# Generate random password for DSRM
resource "random_password" "dsrm_password" {
  length  = 16
  special = true
}

# Domain Controllers
resource "azurerm_windows_virtual_machine" "domain_controllers" {
  for_each = var.domain_controllers

  name                = "${var.resource_group_name}-${each.key}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = each.value.vm_size
  zone                = each.value.availability_zone
  
  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.dc_nic[each.key].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = merge(local.common_tags, {
    Role = "DomainController"
    Name = each.key
  })
}

# Network interfaces for domain controllers
resource "azurerm_network_interface" "dc_nic" {
  for_each = var.domain_controllers

  name                = "${var.resource_group_name}-${each.key}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ad_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip_address
  }

  tags = local.common_tags
}

# Data disks for SYSVOL and NTDS
resource "azurerm_managed_disk" "dc_data_disk" {
  for_each = var.domain_controllers

  name                 = "${var.resource_group_name}-${each.key}-data-disk"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = each.value.data_disk_size_gb

  tags = local.common_tags
}

# Attach data disks to VMs
resource "azurerm_virtual_machine_data_disk_attachment" "dc_data_disk_attachment" {
  for_each = var.domain_controllers

  managed_disk_id    = azurerm_managed_disk.dc_data_disk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.domain_controllers[each.key].id
  lun                = "0"
  caching            = "ReadWrite"
}

# VM Extensions for AD installation
resource "azurerm_virtual_machine_extension" "install_ad" {
  for_each = var.domain_controllers

  name                 = "install-ad"
  virtual_machine_id   = azurerm_windows_virtual_machine.domain_controllers[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    fileUris = [
      "https://raw.githubusercontent.com/your-repo/scripts/install-ad.ps1"
    ]
  })

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File install-ad.ps1 -DomainName '${var.domain_name}' -NetBiosName '${var.netbios_name}' -SafeModePassword '${random_password.dsrm_password.result}' -IsFirstDC ${each.key == "dc01" ? "true" : "false"}"
  })

  depends_on = [azurerm_virtual_machine_data_disk_attachment.dc_data_disk_attachment]

  tags = local.common_tags
}

# Backup protection for domain controllers
resource "azurerm_backup_protected_vm" "dc_backup" {
  for_each = var.enable_backup ? var.domain_controllers : {}

  resource_group_name = azurerm_resource_group.main.name
  recovery_vault_name = azurerm_recovery_services_vault.main[0].name
  source_vm_id        = azurerm_windows_virtual_machine.domain_controllers[each.key].id
  backup_policy_id    = azurerm_backup_policy_vm.main[0].id
}
```

### `outputs.tf`

```text
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "domain_controllers" {
  description = "Domain controller information"
  value = {
    for k, v in azurerm_windows_virtual_machine.domain_controllers : k => {
      name               = v.name
      private_ip_address = azurerm_network_interface.dc_nic[k].private_ip_address
      zone               = v.zone
      size               = v.size
      computer_name      = v.computer_name
    }
  }
}

output "dns_servers" {
  description = "DNS server IP addresses (domain controllers)"
  value       = local.dns_servers
}

output "domain_info" {
  description = "Active Directory domain information"
  value = {
    domain_name    = var.domain_name
    netbios_name   = var.netbios_name
    dns_servers    = local.dns_servers
    admin_username = var.admin_username
  }
}

output "network_info" {
  description = "Network configuration information"
  value = {
    vnet_address_space   = var.vnet_address_space
    ad_subnet_prefix     = var.ad_subnet_prefix
    client_subnet_prefix = var.client_subnet_prefix
    ad_subnet_id         = azurerm_subnet.ad_subnet.id
    client_subnet_id     = azurerm_subnet.client_subnet.id
  }
}

output "backup_info" {
  description = "Backup configuration information"
  value = var.enable_backup ? {
    vault_name           = azurerm_recovery_services_vault.main[0].name
    backup_policy_name   = azurerm_backup_policy_vm.main[0].name
    retention_days       = var.backup_retention_days
  } : null
}

output "dsrm_password" {
  description = "Directory Services Restore Mode password"
  value       = random_password.dsrm_password.result
  sensitive   = true
}

output "connection_info" {
  description = "Information for connecting to the domain"
  value = {
    rdp_command     = "mstsc /v:${values(azurerm_network_interface.dc_nic)[0].private_ip_address}"
    domain_join_dns = local.dns_servers
    admin_account   = "${var.netbios_name}\\${var.admin_username}"
  }
}
```

---

## Configuration Files

### `terraform.tfvars` Template

Create this file with your values (DO NOT commit to version control):

```text
# Resource Configuration
resource_group_name = "rg-ad-prod-eus"
location           = "East US"
environment        = "prod"

# Domain Configuration
domain_name    = "contoso.com"
netbios_name   = "CONTOSO"
admin_username = "azureadmin"
admin_password = "YourSecurePassword123!"

# Network Configuration
vnet_address_space    = ["10.0.0.0/16"]
ad_subnet_prefix      = "10.0.1.0/24"
client_subnet_prefix  = "10.0.2.0/24"

# Domain Controller Configuration
domain_controllers = {
  "dc01" = {
    vm_size             = "Standard_D4s_v3"
    availability_zone   = "1"
    private_ip_address  = "10.0.1.4"
    data_disk_size_gb   = 256
  }
  "dc02" = {
    vm_size             = "Standard_D4s_v3"
    availability_zone   = "2"  
    private_ip_address  = "10.0.1.5"
    data_disk_size_gb   = 256
  }
}

# DNS Configuration
dns_forwarders = ["8.8.8.8", "1.1.1.1"]

# Backup Configuration
enable_backup          = true
backup_retention_days  = 30

# Tags
tags = {
  Project     = "ActiveDirectory"
  Environment = "Production"
  Owner       = "IT-Operations"
  CostCenter  = "IT-001"
}
```

---

## PowerShell Scripts

### `install-ad.ps1`

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    
    [Parameter(Mandatory=$true)]
    [string]$NetBiosName,
    
    [Parameter(Mandatory=$true)]
    [string]$SafeModePassword,
    
    [Parameter(Mandatory=$true)]
    [string]$IsFirstDC
)

# Configure logging
Start-Transcript -Path "C:\Scripts\ad-install.log" -Append

try
{
    Write-Host "Starting Active Directory installation for domain: $DomainName"
    
    # Initialize and format data disk
    Write-Host "Configuring data disk..."
    Get-Disk | Where-Object PartitionStyle -eq "RAW" | Initialize-Disk -PartitionStyle MBR
    New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem NTFS -NewFileSystemLabel "AD-Data" -Confirm:$false
    
    # Install AD DS role
    Write-Host "Installing Active Directory Domain Services role..."
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    
    # Convert secure string password
    $SecurePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
    
    if ($IsFirstDC -eq "true")
    {
        # Install first domain controller (create new forest)
        Write-Host "Installing first domain controller and creating forest..."
        
        Install-ADDSForest `
            -DomainName $DomainName `
            -DomainNetbiosName $NetBiosName `
            -SafeModeAdministratorPassword $SecurePassword `
            -DatabasePath "F:\NTDS" `
            -LogPath "F:\NTDS" `
            -SysvolPath "F:\SYSVOL" `
            -InstallDns:$true `
            -CreateDnsDelegation:$false `
            -NoRebootOnCompletion:$false `
            -Force:$true
    }
    else
    {
        # Install additional domain controller
        Write-Host "Installing additional domain controller..."
        
        # Wait for first DC to be ready
        do
        {
            Start-Sleep -Seconds 30
            $dnsResult = nslookup $DomainName 2>$null
        } while (!$dnsResult)
        
        Install-ADDSDomainController `
            -DomainName $DomainName `
            -SafeModeAdministratorPassword $SecurePassword `
            -DatabasePath "F:\NTDS" `
            -LogPath "F:\NTDS" `
            -SysvolPath "F:\SYSVOL" `
            -InstallDns:$true `
            -CreateDnsDelegation:$false `
            -NoRebootOnCompletion:$false `
            -Force:$true
    }
    
    Write-Host "Active Directory installation completed successfully"
    
}
catch
{
    Write-Error "Failed to install Active Directory: $_"
    throw
}
finally
{
    Stop-Transcript
}
```

### `configure-dns.ps1`

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string[]]$Forwarders
)

Start-Transcript -Path "C:\Scripts\dns-config.log" -Append

try
{
    Write-Host "Configuring DNS forwarders..."
    
    # Wait for DNS service to be ready
    do
    {
        Start-Sleep -Seconds 10
        $DnsService = Get-Service -Name DNS -ErrorAction SilentlyContinue
    } while ($DnsService.Status -ne "Running")
    
    # Configure DNS forwarders
    Set-DnsServerForwarder -IPAddress $Forwarders
    
    # Configure scavenging
    Set-DnsServerScavenging -ScavengingState $true -ScavengingInterval 7.00:00:00
    
    Write-Host "DNS configuration completed successfully"
    
}
catch
{
    Write-Error "Failed to configure DNS: $_"
    throw
}
finally
{
    Stop-Transcript
}
```

---

**Important Security Notes:**

- **Never commit sensitive values** (passwords, keys) to version control
- **Use Azure Key Vault** for secret management in production
- **Implement proper RBAC** and conditional access policies
- **Regular security assessments** and penetration testing
- **Keep systems updated** with latest security patches
- **Monitor for unusual activities** and implement alerting
- **Follow Microsoft security baselines** for Windows Server and Active Directory
