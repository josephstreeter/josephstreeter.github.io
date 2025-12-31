---
title: Terraform Infrastructure as Code
description: Complete guide to Terraform, an open-source Infrastructure as Code (IaC) tool for defining, provisioning, and managing cloud infrastructure using declarative configuration files.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: article
ms.service: terraform
keywords: Terraform, Infrastructure as Code, IaC, HCL, AWS, Azure, Google Cloud, DevOps, automation
uid: docs.infrastructure.terraform.index
---

Terraform is an open-source Infrastructure as Code (IaC) tool that allows you to define, provision, and manage cloud infrastructure and services using declarative configuration files written in HashiCorp Configuration Language (HCL).

> [!NOTE]
> Terraform enables you to safely and predictably create, change, and improve infrastructure. It's provider-agnostic and can manage both cloud and on-premises resources.

## Key Features

- **Multi-provider support**: AWS, Azure, Google Cloud, VMware, Proxmox, Kubernetes, and 3000+ providers
- **Declarative configuration**: Define desired state rather than step-by-step procedures
- **Version control friendly**: Human-readable HCL files work well with Git
- **Dependency management**: Automatically handles resource creation order and dependencies
- **State management**: Tracks infrastructure state and detects configuration drift
- **Plan and apply workflow**: Preview changes before execution
- **Modular and reusable**: Create and share infrastructure modules

## Installation

Use the built-in package management system for your Linux distribution to install Terraform.

Ensure that your system is up to date and that you have installed the gnupg and software-properties-common packages. You will use these packages to verify HashiCorp's GPG signature and install HashiCorp's Debian package repository.

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
```

Install HashiCorp's GPG key.

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
```

Verify the GPG key's fingerprint.

```bash
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
```

The gpg command reports the key fingerprint:

```text
/usr/share/keyrings/hashicorp-archive-keyring.gpg
-------------------------------------------------
pub   rsa4096 XXXX-XX-XX [SC]
AAAA AAAA AAAA AAAA
uid         [ unknown] HashiCorp Security (HashiCorp Package Signing) <security+packaging@hashicorp.com>
sub   rsa4096 XXXX-XX-XX [E]
```

Add the official HashiCorp repository to your system.

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

Update apt to download the package information from the HashiCorp repository.

```bash
sudo apt update
```

Install Terraform from the new repository.

```bash
sudo apt-get install terraform
```

## Core Concepts

### Configuration Files

Terraform configurations are written in HCL (HashiCorp Configuration Language) with `.tf` file extensions.

### State File

Terraform maintains a state file (`terraform.tfstate`) that maps real-world resources to your configuration.

### Providers

Providers are plugins that enable Terraform to interact with APIs of cloud providers and other services.

### Resources

Resources are the most important element in Terraform - they describe infrastructure objects like virtual machines, DNS records, or databases.

## Essential Workflow

> [!TIP]
> Always run `terraform plan` before `terraform apply` to review changes and avoid unintended modifications to your infrastructure.

### 1. Initialize Working Directory

```bash
terraform init
```

This downloads required providers and modules, initializes the backend, and sets up the working directory.

### 2. Create Execution Plan

```bash
terraform plan
```

Shows what actions Terraform will take to achieve the desired state defined in your configuration.

### 3. Apply Configuration

```bash
terraform apply
```

Executes the planned changes to create, modify, or destroy infrastructure resources.

### 4. Destroy Infrastructure

```bash
terraform destroy
```

Removes all resources defined in your Terraform configuration.

## Basic Configuration Example

Here's a simple Azure Virtual Machine configuration:

```text
# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Azure Provider features
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = "East US"
}

# Create a virtual network
resource "azurerm_virtual_network" "example" {
  name                = "vnet-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Create a subnet
resource "azurerm_subnet" "example" {
  name                 = "subnet-example"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "example" {
  name                = "vm-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  
  tags = {
    Environment = "Development"
  }
}
```

## Best Practices

> [!IMPORTANT]
> Following these best practices will help you maintain secure, scalable, and maintainable Terraform configurations.

### Security and State Management

- **Use remote state storage**: Store state files in remote backends (Azure Storage, AWS S3, etc.)
- **Enable state locking**: Prevent concurrent modifications using Azure Storage or similar
- **Never commit sensitive data**: Use `.gitignore` to exclude `.tfstate`, `.tfvars`, and sensitive files
- **Use environment variables**: Store secrets in environment variables, not in configuration files

### Code Organization

- **Use modules**: Create reusable infrastructure components
- **Follow naming conventions**: Use consistent, descriptive names for resources
- **Structure your code**: Organize files logically (`main.tf`, `variables.tf`, `outputs.tf`)
- **Version your modules**: Tag and version your modules for stability

### Development Workflow

- **Use workspaces**: Manage multiple environments (dev, staging, prod)
- **Run terraform fmt**: Format your code consistently
- **Validate configurations**: Use `terraform validate` to check syntax
- **Use terraform plan**: Always preview changes before applying

### Example Directory Structure

```text
terraform/
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vm/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
└── .gitignore
```

## Common Commands

### Essential Commands

```bash
# Initialize a working directory
terraform init

# Format code to canonical format
terraform fmt

# Validate configuration files
terraform validate

# Show current state
terraform show

# List resources in state
terraform state list

# Import existing infrastructure
terraform import azurerm_resource_group.example /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg

# Refresh state against real infrastructure
terraform refresh

# Create a plan and save it
terraform plan -out=tfplan

# Apply a saved plan
terraform apply tfplan
```

### Working with State

```bash
# Show resources in state
terraform state show azurerm_resource_group.example

# Move resource in state
terraform state mv azurerm_resource_group.example azurerm_resource_group.new_name

# Remove resource from state (without destroying)
terraform state rm azurerm_resource_group.example

# Pull remote state to local
terraform state pull

# Push local state to remote
terraform state push terraform.tfstate
```

## Variables and Outputs

### Variable Types

```text
# String variable
variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B1s"
}

# Number variable
variable "vm_count" {
  description = "Number of VMs"
  type        = number
  default     = 1
}

# Boolean variable
variable "enable_monitoring" {
  description = "Enable Azure Monitor"
  type        = bool
  default     = false
}

# List variable
variable "allowed_subnets" {
  description = "List of allowed subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Object variable
variable "vm_config" {
  description = "VM configuration"
  type = object({
    vm_size    = string
    image_sku  = string
    admin_user = string
  })
  default = {
    vm_size    = "Standard_B1s"
    image_sku  = "20_04-lts-gen2"
    admin_user = "adminuser"
  }
}
```

### Outputs

```text
# Output values
output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.example.id
}

output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.example.ip_address
  sensitive   = true
}

output "vm_fqdn" {
  description = "Fully qualified domain name of the VM"
  value       = azurerm_public_ip.example.fqdn
}
```

## Advanced Features

### Conditional Resources

```text
# Create resource only if condition is met
resource "azurerm_linux_virtual_machine" "conditional" {
  count = var.create_vm ? 1 : 0
  
  name                = "vm-conditional-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  size                = var.vm_size
  admin_username      = var.admin_username
  
  network_interface_ids = [
    azurerm_network_interface.example[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = var.vm_config.image_sku
    version   = "latest"
  }
}
```

### Dynamic Blocks

```text
# Dynamic network security group rules
resource "azurerm_network_security_group" "example" {
  name                = "nsg-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  
  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
```

### Data Sources

```text
# Get existing resource group
data "azurerm_resource_group" "existing" {
  name = "existing-rg"
}

# Get latest Ubuntu image
data "azurerm_platform_image" "ubuntu" {
  location  = "East US"
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-focal"
  sku       = "20_04-lts-gen2"
}

# Get client configuration
data "azurerm_client_config" "current" {}
```

## Troubleshooting

### Common Issues

> [!WARNING]
> Always backup your state file before performing manual state operations or major changes.

- **State lock errors**: Use `terraform force-unlock LOCK_ID` to release stuck locks
- **Resource conflicts**: Check for naming conflicts or resource limits
- **Provider version issues**: Pin provider versions in your configuration
- **Authentication errors**: Verify credentials and permissions

### Debugging

```bash
# Enable verbose logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run with detailed output
terraform plan -detailed-exitcode

# Validate with detailed errors
terraform validate -json

# Debug Azure authentication
az account show
az account list
```

## Next Steps

- Learn about [Terraform Modules](https://www.terraform.io/docs/modules/index.html)
- Explore [Terraform Cloud](https://www.terraform.io/cloud) for team collaboration
- Study [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) for Azure-specific resources
- Practice with [Azure Terraform Examples](https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples)
- Set up [Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/terraform) for CI/CD pipelines

## Related Resources

- [Terraform Registry](https://registry.terraform.io/index.md) - Find providers and modules
- [Terraform Best Practices](https://www.terraform.io/docs/configuration/style.html)
- [HashiCorp Learn](https://learn.hashicorp.com/terraform) - Interactive tutorials
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Terraform Examples](https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/index.md)
- [Azure Resource Manager Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/index.md)
