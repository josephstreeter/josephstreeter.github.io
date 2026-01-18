---
title: "Terraform Patterns"
description: "Common Terraform patterns and best practices for Infrastructure as Code including for_each loops, resource management, and modular configurations"
author: "josephstreeter"
ms.date: "2026-01-18"
ms.topic: "reference"
ms.service: "terraform"
keywords: ["Terraform", "Patterns", "for_each", "Infrastructure as Code", "IaC", "Best Practices", "Azure VMs", "Resource Management"]
---

This page contains some useful examples that can be used in solutions.

## For Each

This example demonstrates how to use Terraform's `for_each` meta-argument to create multiple Azure Virtual Machines with different configurations from a single resource block. This approach follows Infrastructure as Code (IaC) best practices by making the infrastructure repeatable, maintainable, and scalable.

### Overview

The configuration creates three VMs:

- **web01** and **web02**: Web server VMs in different availability zones for high availability
- **db01**: Database server VM with larger disk capacity

Each VM is defined with its own attributes (size, disk configuration, zone, tags) while sharing common infrastructure code.

### How It Works

#### Step 1: Define VM Configurations

The `virtual_machines` variable is a map where each key represents a unique VM identifier, and the value contains that VM's specific configuration. This data-driven approach allows you to add or remove VMs by simply modifying the variable values without changing the Terraform code.

#### Step 2: Create Network Interfaces

The `azurerm_network_interface` resource uses `for_each` to iterate over the `virtual_machines` map, creating one network interface per VM. The `each.key` gives you the map key (like "web01"), and `each.value` gives you the entire configuration object for that VM.

#### Step 3: Create Virtual Machines

The `azurerm_linux_virtual_machine` resource also uses `for_each` to create VMs. Each VM references its corresponding network interface using `azurerm_network_interface.vm_nic[each.key].id`, establishing the relationship between resources.

#### Step 4: Output Results

The outputs use `for` expressions to create maps of VM IDs and private IP addresses, making it easy to reference these values in other Terraform configurations or for documentation purposes.

### Variables (terraform.tfvars)

```hcl
resource_group_name = "rg-production-vms"
location            = "Central US"

virtual_machines = {
  web01 = {
    name               = "vm-web-prod-01"
    size               = "Standard_D2s_v3"
    admin_username     = "azureadmin"
    os_disk_size_gb    = 128
    os_disk_type       = "Premium_LRS"
    availability_zone  = "1"
    tags = {
      Environment = "Production"
      Role        = "WebServer"
      Department  = "IT"
    }
  }
  web02 = {
    name               = "vm-web-prod-02"
    size               = "Standard_D2s_v3"
    admin_username     = "azureadmin"
    os_disk_size_gb    = 128
    os_disk_type       = "Premium_LRS"
    availability_zone  = "2"
    tags = {
      Environment = "Production"
      Role        = "WebServer"
      Department  = "IT"
    }
  }
  db01 = {
    name               = "vm-db-prod-01"
    size               = "Standard_D4s_v3"
    admin_username     = "azureadmin"
    os_disk_size_gb    = 256
    os_disk_type       = "Premium_LRS"
    availability_zone  = "1"
    tags = {
      Environment = "Production"
      Role        = "Database"
      Department  = "IT"
    }
  }
}
```

**Key Points:**

- **resource_group_name**: The Azure resource group where all resources will be created
- **location**: Azure region for resource deployment
- **virtual_machines**: A map data structure where:
  - **Keys** (web01, web02, db01) serve as unique identifiers for each VM
  - **Values** contain object configurations with all necessary VM attributes
  - **name**: The actual Azure resource name for the VM
  - **size**: Azure VM SKU (Standard_D2s_v3 = 2 vCPUs, 8 GB RAM; Standard_D4s_v3 = 4 vCPUs, 16 GB RAM)
  - **admin_username**: Local admin account for SSH access
  - **os_disk_size_gb**: OS disk size in gigabytes
  - **os_disk_type**: Storage type (Premium_LRS = Premium SSD with local redundancy)
  - **availability_zone**: Azure availability zone (1, 2, or 3) for high availability
  - **tags**: Metadata for resource organization and cost tracking

### Main Terraform Configuration (main.tf)

```hcl
# Create Network Interface for each VM
resource "azurerm_network_interface" "vm_nic" {
  for_each            = var.virtual_machines
  name                = "nic-${each.value.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = each.value.tags
}

# Create Azure Virtual Machines using for_each
resource "azurerm_linux_virtual_machine" "vm" {
  for_each            = var.virtual_machines
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = each.value.size
  admin_username      = each.value.admin_username
  zone                = each.value.availability_zone

  network_interface_ids = [
    azurerm_network_interface.vm_nic[each.key].id
  ]

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "osdisk-${each.value.name}"
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = each.value.tags
}

# Output the VM IDs and Private IPs
output "vm_ids" {
  description = "IDs of the created virtual machines"
  value = {
    for key, vm in azurerm_linux_virtual_machine.vm : key => vm.id
  }
}

output "vm_private_ips" {
  description = "Private IP addresses of the virtual machines"
  value = {
    for key, nic in azurerm_network_interface.vm_nic : key => nic.private_ip_address
  }
}
```

**Detailed Explanation:**

#### Network Interface Resource (`azurerm_network_interface`)

```hcl
resource "azurerm_network_interface" "vm_nic" {
  for_each            = var.virtual_machines
  name                = "nic-${each.value.name}"
  # ...
}
```

- **for_each = var.virtual_machines**: Iterates over the map, creating one NIC per VM
- **each.key**: The map key ("web01", "web02", "db01")
- **each.value**: The entire configuration object for that VM
- **name = "nic-${each.value.name}"**: Generates unique NIC names like "nic-vm-web-prod-01"
- **ip_configuration**: Configures the NIC with a dynamic private IP from the subnet
- **subnet_id**: References a subnet resource (assumes `azurerm_subnet.main` exists)

#### Virtual Machine Resource (`azurerm_linux_virtual_machine`)

```hcl
resource "azurerm_linux_virtual_machine" "vm" {
  for_each            = var.virtual_machines
  name                = each.value.name
  size                = each.value.size
  # ...
}
```

- **for_each = var.virtual_machines**: Creates one VM per entry in the map
- **name, size, admin_username**: Pulled directly from the variable values
- **zone**: Places VMs in specified availability zones for redundancy
- **network_interface_ids**: Links to the corresponding NIC using `[each.key]` to match the correct NIC
- **admin_ssh_key**: Configures SSH authentication using public key from local file
- **os_disk**: Defines the operating system disk with specified size and storage type
- **source_image_reference**: Specifies Ubuntu 22.04 LTS from Canonical
- **tags**: Applies the tags from the variable for resource management

#### Resource Dependencies

Terraform automatically understands that VMs depend on NICs because of the reference:

```hcl
network_interface_ids = [
  azurerm_network_interface.vm_nic[each.key].id
]
```

This ensures NICs are created before VMs during `terraform apply`.

#### Outputs

```hcl
output "vm_ids" {
  value = {
    for key, vm in azurerm_linux_virtual_machine.vm : key => vm.id
  }
}
```

- **for key, vm in azurerm_linux_virtual_machine.vm**: Iterates over all created VMs
- **key => vm.id**: Creates a map like `{ web01 = "/subscriptions/.../vm-web-prod-01", ... }`
- Similar logic applies to `vm_private_ips`, pulling IP addresses from NICs

### Variable Definitions (variables.tf)

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "virtual_machines" {
  description = "Map of virtual machine configurations"
  type = map(object({
    name               = string
    size               = string
    admin_username     = string
    os_disk_size_gb    = number
    os_disk_type       = string
    availability_zone  = string
    tags               = map(string)
  }))
}
```

**Variable Type Definitions:**

- **string**: Simple text values (resource_group_name, location)
- **map(object({...}))**: A map where each value is a structured object with defined properties
  - **name, size, admin_username, os_disk_type, availability_zone**: String types
  - **os_disk_size_gb**: Number type for numeric values
  - **tags**: Nested map of strings for key-value metadata

This strict typing ensures:

- Type validation at plan time
- IDE autocomplete support
- Clear documentation of expected inputs
- Prevention of configuration errors

### Benefits of This Approach

#### 1. DRY (Don't Repeat Yourself)

Instead of writing separate resource blocks for each VM, you define the resource once and let `for_each` handle the iteration.

#### 2. Scalability

Adding a new VM requires only updating the `virtual_machines` variable - no code changes needed:

```hcl
app01 = {
  name               = "vm-app-prod-01"
  size               = "Standard_D2s_v3"
  # ... other attributes
}
```

#### 3. Consistency

All VMs are created using the same template, ensuring consistent configuration patterns.

#### 4. Maintainability

Changes to the VM configuration template automatically apply to all VMs on the next `terraform apply`.

#### 5. Resource Relationships

Using `each.key` to reference related resources (like NICs) ensures proper resource linking and dependency management.

### Usage Example

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply configuration
terraform apply

# View outputs
terraform output vm_ids
terraform output vm_private_ips

# Destroy resources
terraform destroy
```

### Advanced Considerations

#### Selective Resource Updates

To modify only specific VMs:

```bash
terraform apply -target=azurerm_linux_virtual_machine.vm[\"web01\"]
```

#### Adding Data Disks

Extend the configuration with additional `for_each` resources:

```hcl
resource "azurerm_managed_disk" "data_disk" {
  for_each             = var.virtual_machines
  name                 = "datadisk-${each.value.name}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 512
}
```

#### Conditional Creation

Use dynamic values in the map to conditionally configure resources:

```hcl
# In variables
web01 = {
  # ... other attributes
  create_public_ip = true
}
```

This pattern demonstrates Infrastructure as Code best practices for managing multiple similar resources efficiently in Azure using Terraform.
