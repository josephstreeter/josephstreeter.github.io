---
title: "Terraform with Azure"
description: "Complete guide to using Terraform with Microsoft Azure for cloud infrastructure automation and resource management"
author: "josephstreeter"
ms.date: "2025-12-30"
ms.topic: "how-to-guide"
ms.service: "terraform"
keywords: ["Terraform", "Azure", "Microsoft Azure", "Infrastructure as Code", "IaC", "Cloud", "AzureRM", "Automation", "DevOps"]
---

This guide demonstrates how to use Terraform with Microsoft Azure to automate cloud infrastructure provisioning, management, and deployment using infrastructure-as-code principles.

## Overview

Terraform's AzureRM provider enables comprehensive management of Azure resources including virtual machines, networking, storage, databases, Kubernetes clusters, and platform services. This provides a consistent workflow for multi-cloud and hybrid cloud deployments.

## Prerequisites

### Azure Requirements

- Active Azure subscription
- Azure CLI installed and configured
- Appropriate Azure RBAC permissions
- Service Principal or Managed Identity for authentication

### Install Azure CLI

**Linux:**

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify installation
az --version
```

**macOS:**

```bash
# Install using Homebrew
brew update && brew install azure-cli

# Verify installation
az --version
```

**Windows:**

```powershell
# Install using winget
winget install -e --id Microsoft.AzureCLI

# Verify installation
az --version
```

### Azure Authentication

Login to Azure:

```bash
# Interactive login
az login

# Login with specific tenant
az login --tenant TENANT_ID

# Verify current subscription
az account show

# List all subscriptions
az account list --output table

# Set active subscription
az account set --subscription "SUBSCRIPTION_NAME_OR_ID"
```

### Terraform Requirements

- Terraform >= 1.0
- Azure subscription with appropriate permissions
- Service Principal or authentication method configured

## Authentication Methods

### Method 1: Azure CLI Authentication (Development)

Simplest method for local development:

```hcl
terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 3.0"
        }
    }
}

provider "azurerm" {
    features {}
    
    # Uses Azure CLI authentication by default
}
```

### Method 2: Service Principal with Client Secret

Best for CI/CD pipelines:

```bash
# Create Service Principal
az ad sp create-for-rbac --name "terraform-sp" \
    --role="Contributor" \
    --scopes="/subscriptions/SUBSCRIPTION_ID"

# Output will contain:
# - appId (client_id)
# - password (client_secret)
# - tenant
```

Configure provider:

```hcl
provider "azurerm" {
    features {}
    
    subscription_id = var.subscription_id
    client_id       = var.client_id
    client_secret   = var.client_secret
    tenant_id       = var.tenant_id
}
```

### Method 3: Service Principal with Certificate

More secure than client secret:

```bash
# Create certificate
openssl req -newkey rsa:4096 -nodes -keyout "service-principal.key" \
    -out "service-principal.csr"

openssl x509 -signkey "service-principal.key" \
    -in "service-principal.csr" -req -days 365 -out "service-principal.crt"

# Create Service Principal with certificate
az ad sp create-for-rbac --name terraform-sp \
    --role Contributor \
    --scopes /subscriptions/SUBSCRIPTION_ID \
    --cert @service-principal.crt
```

```hcl
provider "azurerm" {
    features {}
    
    subscription_id            = var.subscription_id
    client_id                  = var.client_id
    client_certificate_path    = "./service-principal.crt"
    tenant_id                  = var.tenant_id
}
```

### Method 4: Managed Identity (Azure VMs)

For Terraform running on Azure resources:

```hcl
provider "azurerm" {
    features {}
    
    use_msi         = true
    subscription_id = var.subscription_id
    tenant_id       = var.tenant_id
}
```

### Method 5: Environment Variables

```bash
# Set environment variables
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

```hcl
provider "azurerm" {
    features {}
    # Automatically uses ARM_* environment variables
}
```

## Provider Configuration

### Basic Configuration

Create `providers.tf`:

```hcl
terraform {
    required_version = ">= 1.0"
    
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 3.85"
        }
        azuread = {
            source  = "hashicorp/azuread"
            version = "~> 2.47"
        }
    }
}

provider "azurerm" {
    features {
        resource_group {
            prevent_deletion_if_contains_resources = false
        }
        
        key_vault {
            purge_soft_delete_on_destroy    = true
            recover_soft_deleted_key_vaults = true
        }
        
        virtual_machine {
            delete_os_disk_on_deletion     = true
            graceful_shutdown              = false
            skip_shutdown_and_force_delete = false
        }
    }
    
    skip_provider_registration = false
}

provider "azuread" {
    tenant_id = var.tenant_id
}
```

### Variables File

Create `variables.tf`:

```hcl
variable "subscription_id" {
    description = "Azure subscription ID"
    type        = string
}

variable "tenant_id" {
    description = "Azure AD tenant ID"
    type        = string
}

variable "location" {
    description = "Azure region for resources"
    type        = string
    default     = "eastus"
}

variable "environment" {
    description = "Environment name (dev, test, prod)"
    type        = string
    default     = "dev"
}

variable "project_name" {
    description = "Project name for resource naming"
    type        = string
}

variable "tags" {
    description = "Common tags for all resources"
    type        = map(string)
    default     = {}
}
```

## Resource Group Management

### Basic Resource Group

```hcl
resource "azurerm_resource_group" "main" {
    name     = "rg-${var.project_name}-${var.environment}"
    location = var.location
    
    tags = merge(var.tags, {
        Environment = var.environment
        ManagedBy   = "Terraform"
    })
}
```

### Multiple Resource Groups

```hcl
locals {
    resource_groups = {
        network = {
            name     = "rg-network-${var.environment}"
            location = var.location
        }
        compute = {
            name     = "rg-compute-${var.environment}"
            location = var.location
        }
        data = {
            name     = "rg-data-${var.environment}"
            location = "eastus2"
        }
    }
}

resource "azurerm_resource_group" "rgs" {
    for_each = local.resource_groups
    
    name     = each.value.name
    location = each.value.location
    
    tags = var.tags
}
```

## Virtual Network Configuration

### Basic Virtual Network

```hcl
resource "azurerm_virtual_network" "main" {
    name                = "vnet-${var.project_name}-${var.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    address_space       = ["10.0.0.0/16"]
    
    tags = var.tags
}

resource "azurerm_subnet" "web" {
    name                 = "snet-web"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app" {
    name                 = "snet-app"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "data" {
    name                 = "snet-data"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.3.0/24"]
    
    service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
}
```

### Network Security Groups

```hcl
resource "azurerm_network_security_group" "web" {
    name                = "nsg-web-${var.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    
    security_rule {
        name                       = "AllowHTTPS"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
    }
    
    security_rule {
        name                       = "AllowHTTP"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
    }
    
    tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "web" {
    subnet_id                 = azurerm_subnet.web.id
    network_security_group_id = azurerm_network_security_group.web.id
}
```

## Virtual Machine Deployment

### Linux Virtual Machine

```hcl
resource "azurerm_public_ip" "vm" {
    name                = "pip-vm-${var.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    allocation_method   = "Static"
    sku                 = "Standard"
    
    tags = var.tags
}

resource "azurerm_network_interface" "vm" {
    name                = "nic-vm-${var.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.web.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.vm.id
    }
    
    tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
    name                  = "vm-linux-${var.environment}"
    location              = azurerm_resource_group.main.location
    resource_group_name   = azurerm_resource_group.main.name
    network_interface_ids = [azurerm_network_interface.vm.id]
    size                  = "Standard_B2s"
    
    admin_username = "azureuser"
    
    admin_ssh_key {
        username   = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }
    
    os_disk {
        name                 = "osdisk-vm-${var.environment}"
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 30
    }
    
    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
    }
    
    boot_diagnostics {
        storage_account_uri = null
    }
    
    custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
        hostname = "web-server"
    }))
    
    tags = var.tags
}
```

### Windows Virtual Machine

```hcl
resource "azurerm_windows_virtual_machine" "vm" {
    name                  = "vm-win-${var.environment}"
    location              = azurerm_resource_group.main.location
    resource_group_name   = azurerm_resource_group.main.name
    network_interface_ids = [azurerm_network_interface.vm.id]
    size                  = "Standard_D2s_v3"
    
    admin_username = "azureadmin"
    admin_password = var.admin_password
    
    os_disk {
        name                 = "osdisk-win-${var.environment}"
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }
    
    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-Datacenter"
        version   = "latest"
    }
    
    boot_diagnostics {
        storage_account_uri = null
    }
    
    tags = var.tags
}
```

### Virtual Machine Scale Set

```hcl
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
    name                = "vmss-${var.project_name}-${var.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    sku                 = "Standard_B2s"
    instances           = 2
    
    admin_username = "azureuser"
    
    admin_ssh_key {
        username   = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }
    
    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
    }
    
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }
    
    network_interface {
        name    = "nic-vmss"
        primary = true
        
        ip_configuration {
            name      = "internal"
            primary   = true
            subnet_id = azurerm_subnet.web.id
            
            load_balancer_backend_address_pool_ids = [
                azurerm_lb_backend_address_pool.vmss.id
            ]
        }
    }
    
    custom_data = base64encode(file("${path.module}/cloud-init.yaml"))
    
    upgrade_mode = "Automatic"
    
    automatic_os_upgrade_policy {
        disable_automatic_rollback  = false
        enable_automatic_os_upgrade = true
    }
    
    tags = var.tags
}
```

## Azure Kubernetes Service (AKS)

### Basic AKS Cluster

```hcl
resource "azurerm_kubernetes_cluster" "aks" {
    name                = "aks-${var.project_name}-${var.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    dns_prefix          = "aks-${var.project_name}"
    
    kubernetes_version = "1.28.3"
    
    default_node_pool {
        name                = "default"
        node_count          = 3
        vm_size             = "Standard_D2s_v3"
        vnet_subnet_id      = azurerm_subnet.aks.id
        enable_auto_scaling = true
        min_count           = 2
        max_count           = 5
        
        upgrade_settings {
            max_surge = "10%"
        }
    }
    
    identity {
        type = "SystemAssigned"
    }
    
    network_profile {
        network_plugin    = "azure"
        load_balancer_sku = "standard"
        network_policy    = "azure"
    }
    
    azure_active_directory_role_based_access_control {
        managed                = true
        azure_rbac_enabled     = true
    }
    
    oms_agent {
        log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    }
    
    tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
    name                  = "spot"
    kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
    vm_size               = "Standard_D2s_v3"
    node_count            = 2
    
    priority        = "Spot"
    eviction_policy = "Delete"
    spot_max_price  = -1
    
    node_labels = {
        "kubernetes.azure.com/scalesetpriority" = "spot"
    }
    
    node_taints = [
        "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
    ]
}
```

## Storage Accounts

### Storage Account with Containers

```hcl
resource "azurerm_storage_account" "main" {
    name                     = "st${lower(replace(var.project_name, "-", ""))}${var.environment}"
    resource_group_name      = azurerm_resource_group.main.name
    location                 = azurerm_resource_group.main.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind             = "StorageV2"
    
    min_tls_version                 = "TLS1_2"
    enable_https_traffic_only       = true
    allow_nested_items_to_be_public = false
    
    blob_properties {
        versioning_enabled = true
        
        delete_retention_policy {
            days = 7
        }
        
        container_delete_retention_policy {
            days = 7
        }
    }
    
    network_rules {
        default_action             = "Deny"
        ip_rules                   = ["YOUR_IP_ADDRESS"]
        virtual_network_subnet_ids = [azurerm_subnet.app.id]
        bypass                     = ["AzureServices"]
    }
    
    tags = var.tags
}

resource "azurerm_storage_container" "containers" {
    for_each = toset(["data", "logs", "backups"])
    
    name                  = each.value
    storage_account_name  = azurerm_storage_account.main.name
    container_access_type = "private"
}
```

## Azure SQL Database

### SQL Server and Database

```hcl
resource "azurerm_mssql_server" "main" {
    name                         = "sql-${var.project_name}-${var.environment}"
    resource_group_name          = azurerm_resource_group.main.name
    location                     = azurerm_resource_group.main.location
    version                      = "12.0"
    administrator_login          = "sqladmin"
    administrator_login_password = var.sql_admin_password
    
    minimum_tls_version = "1.2"
    
    azuread_administrator {
        login_username = "AzureAD Admin"
        object_id      = data.azuread_group.sql_admins.object_id
    }
    
    tags = var.tags
}

resource "azurerm_mssql_database" "main" {
    name         = "sqldb-${var.project_name}-${var.environment}"
    server_id    = azurerm_mssql_server.main.id
    collation    = "SQL_Latin1_General_CP1_CI_AS"
    license_type = "LicenseIncluded"
    sku_name     = "S1"
    
    short_term_retention_policy {
        retention_days = 7
    }
    
    long_term_retention_policy {
        weekly_retention  = "P1W"
        monthly_retention = "P1M"
        yearly_retention  = "P1Y"
        week_of_year      = 1
    }
    
    tags = var.tags
}

resource "azurerm_mssql_firewall_rule" "allow_azure" {
    name             = "AllowAzureServices"
    server_id        = azurerm_mssql_server.main.id
    start_ip_address = "0.0.0.0"
    end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_virtual_network_rule" "main" {
    name      = "sql-vnet-rule"
    server_id = azurerm_mssql_server.main.id
    subnet_id = azurerm_subnet.data.id
}
```

## Azure Key Vault

```hcl
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
    name                       = "kv-${var.project_name}-${var.environment}"
    location                   = azurerm_resource_group.main.location
    resource_group_name        = azurerm_resource_group.main.name
    tenant_id                  = data.azurerm_client_config.current.tenant_id
    sku_name                   = "standard"
    
    enabled_for_disk_encryption     = true
    enabled_for_deployment          = true
    enabled_for_template_deployment = true
    purge_protection_enabled        = true
    
    network_acls {
        default_action             = "Deny"
        bypass                     = "AzureServices"
        ip_rules                   = ["YOUR_IP_ADDRESS"]
        virtual_network_subnet_ids = [azurerm_subnet.app.id]
    }
    
    tags = var.tags
}

resource "azurerm_key_vault_access_policy" "terraform" {
    key_vault_id = azurerm_key_vault.main.id
    tenant_id    = data.azurerm_client_config.current.tenant_id
    object_id    = data.azurerm_client_config.current.object_id
    
    secret_permissions = [
        "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
    
    key_permissions = [
        "Get", "List", "Create", "Delete", "Purge", "Recover"
    ]
    
    certificate_permissions = [
        "Get", "List", "Create", "Delete", "Purge", "Recover"
    ]
}

resource "azurerm_key_vault_secret" "example" {
    name         = "database-connection-string"
    value        = "Server=${azurerm_mssql_server.main.fully_qualified_domain_name};..."
    key_vault_id = azurerm_key_vault.main.id
    
    depends_on = [azurerm_key_vault_access_policy.terraform]
}
```

## Application Insights and Monitoring

```hcl
resource "azurerm_log_analytics_workspace" "main" {
    name                = "log-${var.project_name}-${var.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    sku                 = "PerGB2018"
    retention_in_days   = 30
    
    tags = var.tags
}

resource "azurerm_application_insights" "main" {
    name                = "appi-${var.project_name}-${var.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    workspace_id        = azurerm_log_analytics_workspace.main.id
    application_type    = "web"
    
    tags = var.tags
}
```

## Azure Functions

```hcl
resource "azurerm_service_plan" "main" {
    name                = "asp-${var.project_name}-${var.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    os_type             = "Linux"
    sku_name            = "Y1"  # Consumption plan
    
    tags = var.tags
}

resource "azurerm_linux_function_app" "main" {
    name                       = "func-${var.project_name}-${var.environment}"
    location                   = azurerm_resource_group.main.location
    resource_group_name        = azurerm_resource_group.main.name
    service_plan_id            = azurerm_service_plan.main.id
    storage_account_name       = azurerm_storage_account.main.name
    storage_account_access_key = azurerm_storage_account.main.primary_access_key
    
    site_config {
        application_stack {
            python_version = "3.11"
        }
        
        application_insights_connection_string = azurerm_application_insights.main.connection_string
        application_insights_key               = azurerm_application_insights.main.instrumentation_key
    }
    
    app_settings = {
        "FUNCTIONS_WORKER_RUNTIME" = "python"
    }
    
    tags = var.tags
}
```

## Complete Multi-Tier Application Example

```hcl
locals {
    project      = "webapp"
    environment  = "prod"
    location     = "eastus"
    
    common_tags = {
        Environment = local.environment
        ManagedBy   = "Terraform"
        Project     = local.project
    }
}

# Resource Group
resource "azurerm_resource_group" "main" {
    name     = "rg-${local.project}-${local.environment}"
    location = local.location
    tags     = local.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
    name                = "vnet-${local.project}-${local.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    address_space       = ["10.0.0.0/16"]
    tags                = local.common_tags
}

# Subnets
resource "azurerm_subnet" "frontend" {
    name                 = "snet-frontend"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
    name                 = "snet-backend"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "database" {
    name                 = "snet-database"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.3.0/24"]
    service_endpoints    = ["Microsoft.Sql"]
}

# Application Gateway (Load Balancer)
resource "azurerm_subnet" "appgw" {
    name                 = "snet-appgw"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_public_ip" "appgw" {
    name                = "pip-appgw-${local.environment}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = local.common_tags
}

# Storage for application data
resource "azurerm_storage_account" "main" {
    name                     = "st${replace(local.project, "-", "")}${local.environment}"
    resource_group_name      = azurerm_resource_group.main.name
    location                 = azurerm_resource_group.main.location
    account_tier             = "Standard"
    account_replication_type = "GRS"
    min_tls_version          = "TLS1_2"
    tags                     = local.common_tags
}

# SQL Database
resource "azurerm_mssql_server" "main" {
    name                         = "sql-${local.project}-${local.environment}"
    resource_group_name          = azurerm_resource_group.main.name
    location                     = azurerm_resource_group.main.location
    version                      = "12.0"
    administrator_login          = "sqladmin"
    administrator_login_password = var.sql_admin_password
    minimum_tls_version          = "1.2"
    tags                         = local.common_tags
}

resource "azurerm_mssql_database" "main" {
    name      = "sqldb-${local.project}-${local.environment}"
    server_id = azurerm_mssql_server.main.id
    sku_name  = "S1"
    tags      = local.common_tags
}
```

## Remote State Management

### Azure Storage Backend

Create storage account for Terraform state:

```bash
# Create resource group
az group create --name rg-terraform-state --location eastus

# Create storage account
az storage account create \
    --resource-group rg-terraform-state \
    --name sttfstateunique123 \
    --sku Standard_LRS \
    --encryption-services blob

# Create blob container
az storage container create \
    --name tfstate \
    --account-name sttfstateunique123
```

Configure backend in `backend.tf`:

```hcl
terraform {
    backend "azurerm" {
        resource_group_name  = "rg-terraform-state"
        storage_account_name = "sttfstateunique123"
        container_name       = "tfstate"
        key                  = "prod.terraform.tfstate"
    }
}
```

Initialize with backend:

```bash
# Initialize with backend configuration
terraform init

# Or provide at init time
terraform init \
    -backend-config="resource_group_name=rg-terraform-state" \
    -backend-config="storage_account_name=sttfstateunique123" \
    -backend-config="container_name=tfstate" \
    -backend-config="key=prod.terraform.tfstate"
```

## Outputs

Create `outputs.tf`:

```hcl
output "resource_group_name" {
    description = "Name of the resource group"
    value       = azurerm_resource_group.main.name
}

output "virtual_network_id" {
    description = "ID of the virtual network"
    value       = azurerm_virtual_network.main.id
}

output "sql_server_fqdn" {
    description = "Fully qualified domain name of SQL server"
    value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "storage_account_primary_blob_endpoint" {
    description = "Primary blob endpoint for storage account"
    value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "application_insights_instrumentation_key" {
    description = "Instrumentation key for Application Insights"
    value       = azurerm_application_insights.main.instrumentation_key
    sensitive   = true
}

output "aks_cluster_name" {
    description = "Name of the AKS cluster"
    value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_kube_config" {
    description = "Kubernetes configuration"
    value       = azurerm_kubernetes_cluster.aks.kube_config_raw
    sensitive   = true
}
```

## Best Practices

### Naming Conventions

Follow Azure naming conventions:

```hcl
locals {
    # Azure resource abbreviations
    resource_abbreviations = {
        resource_group       = "rg"
        virtual_network      = "vnet"
        subnet               = "snet"
        network_interface    = "nic"
        public_ip            = "pip"
        virtual_machine      = "vm"
        storage_account      = "st"
        key_vault            = "kv"
        sql_server           = "sql"
        sql_database         = "sqldb"
        app_service          = "app"
        function_app         = "func"
        kubernetes_cluster   = "aks"
    }
    
    # Naming pattern: {resource_type}-{project}-{environment}-{region}-{instance}
    name_prefix = "${var.resource_type}-${var.project_name}-${var.environment}"
}
```

### Resource Tagging Strategy

```hcl
locals {
    mandatory_tags = {
        Environment    = var.environment
        Project        = var.project_name
        ManagedBy      = "Terraform"
        CostCenter     = var.cost_center
        Owner          = var.owner_email
        DataClass      = var.data_classification
    }
    
    resource_tags = merge(
        local.mandatory_tags,
        var.additional_tags,
        {
            CreatedDate = timestamp()
        }
    )
}

resource "azurerm_resource_group" "main" {
    name     = "rg-${var.project_name}-${var.environment}"
    location = var.location
    tags     = local.resource_tags
}
```

### Security Best Practices

1. **Use Managed Identities**

    ```hcl
    resource "azurerm_linux_function_app" "main" {
        # ... other configuration ...
        
        identity {
            type = "SystemAssigned"
        }
    }
    
    # Grant permissions using managed identity
    resource "azurerm_role_assignment" "function_storage" {
        scope                = azurerm_storage_account.main.id
        role_definition_name = "Storage Blob Data Contributor"
        principal_id         = azurerm_linux_function_app.main.identity[0].principal_id
    }
    ```

2. **Network Security**

    ```hcl
    # Enable DDoS protection
    resource "azurerm_network_ddos_protection_plan" "main" {
        name                = "ddos-${var.project_name}-${var.environment}"
        location            = azurerm_resource_group.main.location
        resource_group_name = azurerm_resource_group.main.name
    }
    
    # Apply to VNet
    resource "azurerm_virtual_network" "main" {
        # ... other configuration ...
        
        ddos_protection_plan {
            id     = azurerm_network_ddos_protection_plan.main.id
            enable = true
        }
    }
    ```

3. **Encrypt Everything**

    ```hcl
    resource "azurerm_storage_account" "main" {
        # ... other configuration ...
        
        # Encryption at rest
        infrastructure_encryption_enabled = true
        
        # Encryption in transit
        min_tls_version           = "TLS1_2"
        enable_https_traffic_only = true
    }
    ```

4. **Use Private Endpoints**

    ```hcl
    resource "azurerm_private_endpoint" "storage" {
        name                = "pe-storage-${var.environment}"
        location            = azurerm_resource_group.main.location
        resource_group_name = azurerm_resource_group.main.name
        subnet_id           = azurerm_subnet.private_endpoints.id
        
        private_service_connection {
            name                           = "psc-storage"
            private_connection_resource_id = azurerm_storage_account.main.id
            subresource_names              = ["blob"]
            is_manual_connection           = false
        }
    }
    ```

### Cost Optimization

1. **Use Azure Reservations**

    ```hcl
    # Reserve VM capacity
    resource "azurerm_capacity_reservation_group" "main" {
        name                = "crg-${var.project_name}-${var.environment}"
        resource_group_name = azurerm_resource_group.main.name
        location            = azurerm_resource_group.main.location
    }
    ```

2. **Auto-Shutdown for Dev/Test**

    ```hcl
    resource "azurerm_dev_test_schedule" "shutdown" {
        name                = "shutdown-${azurerm_linux_virtual_machine.vm.name}"
        location            = azurerm_resource_group.main.location
        resource_group_name = azurerm_resource_group.main.name
        
        task_type        = "ComputeVmShutdownTask"
        time_zone_id     = "Eastern Standard Time"
        daily_recurrence_time = "1900"
        
        notification_settings {
            enabled = true
            time_in_minutes = 30
            webhook_url = var.notification_webhook
        }
        
        target_resource_id = azurerm_linux_virtual_machine.vm.id
    }
    ```

3. **Use Spot Instances for Non-Critical Workloads**

    ```hcl
    resource "azurerm_linux_virtual_machine" "spot" {
        # ... other configuration ...
        
        priority        = "Spot"
        eviction_policy = "Deallocate"
        max_bid_price   = -1  # Pay up to on-demand price
    }
    ```

### Module Organization

Create reusable modules:

```text
modules/
├── networking/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── compute/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── database/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

Use modules:

```hcl
module "networking" {
    source = "./modules/networking"
    
    project_name = var.project_name
    environment  = var.environment
    location     = var.location
    tags         = local.common_tags
}

module "compute" {
    source = "./modules/compute"
    
    subnet_id = module.networking.subnet_ids["web"]
    tags      = local.common_tags
}
```

## CI/CD Integration

### Azure DevOps Pipeline

Create `azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: terraform-vars

stages:
  - stage: Validate
    jobs:
      - job: TerraformValidate
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: '1.6.0'
          
          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              backendServiceArm: 'Azure-Service-Connection'
              backendAzureRmResourceGroupName: 'rg-terraform-state'
              backendAzureRmStorageAccountName: 'sttfstateunique123'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'prod.terraform.tfstate'
          
          - task: TerraformTaskV4@4
            displayName: 'Terraform Validate'
            inputs:
              provider: 'azurerm'
              command: 'validate'

  - stage: Plan
    dependsOn: Validate
    jobs:
      - job: TerraformPlan
        steps:
          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              environmentServiceNameAzureRM: 'Azure-Service-Connection'
              commandOptions: '-out=tfplan'
          
          - task: PublishBuildArtifacts@1
            inputs:
              PathtoPublish: '$(System.DefaultWorkingDirectory)/tfplan'
              ArtifactName: 'terraform-plan'

  - stage: Apply
    dependsOn: Plan
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: TerraformApply
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: DownloadBuildArtifacts@0
                  inputs:
                    artifactName: 'terraform-plan'
                
                - task: TerraformTaskV4@4
                  displayName: 'Terraform Apply'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    environmentServiceNameAzureRM: 'Azure-Service-Connection'
                    commandOptions: 'tfplan'
```

### GitHub Actions Workflow

Create `.github/workflows/terraform.yml`:

```yaml
name: Terraform Azure Deploy

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      
      - name: Terraform Format
        run: terraform fmt -check
      
      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="resource_group_name=rg-terraform-state" \
            -backend-config="storage_account_name=sttfstateunique123" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=prod.terraform.tfstate"
      
      - name: Terraform Validate
        run: terraform validate
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
      
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve tfplan
```

## Troubleshooting

### Common Issues

#### Authentication Failures

```bash
# Clear Azure CLI cache
az account clear

# Re-login
az login

# Verify subscription
az account show

# Test Service Principal
az login --service-principal \
    -u $ARM_CLIENT_ID \
    -p $ARM_CLIENT_SECRET \
    --tenant $ARM_TENANT_ID
```

#### Provider Registration

```bash
# List provider registration status
az provider list --output table

# Register required providers
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage
```

#### State Lock Issues

```bash
# List state locks
az storage blob lease list \
    --container-name tfstate \
    --account-name sttfstateunique123

# Break lease if needed (use with caution)
az storage blob lease break \
    --blob-name prod.terraform.tfstate \
    --container-name tfstate \
    --account-name sttfstateunique123
```

### Enable Debug Logging

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH="./terraform-debug.log"

# Enable Azure CLI debug
export AZURE_CLI_DEBUG=1

# Run Terraform command
terraform apply

# Review logs
cat terraform-debug.log | grep -i error
```

### Validate Resources

```bash
# Validate Terraform configuration
terraform validate

# Check format
terraform fmt -check -recursive

# Analyze with tflint
tflint --init
tflint

# Security scanning with tfsec
tfsec .

# Cost estimation with Infracost
infracost breakdown --path .
```

## Tools and Extensions

### Recommended Tools

1. **Terraform Compliance** - Policy testing

    ```bash
    # Install
    pip install terraform-compliance
    
    # Run compliance tests
    terraform-compliance -f compliance/ -p tfplan
    ```

2. **Terragrunt** - DRY configurations

    ```hcl
    # terragrunt.hcl
    remote_state {
        backend = "azurerm"
        config = {
            resource_group_name  = "rg-terraform-state"
            storage_account_name = "sttfstateunique123"
            container_name       = "tfstate"
            key                  = "${path_relative_to_include()}/terraform.tfstate"
        }
    }
    ```

3. **Checkov** - Security and compliance

    ```bash
    # Install
    pip install checkov
    
    # Scan Terraform code
    checkov -d .
    ```

## Resources

### Official Documentation

- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Terraform Documentation](https://learn.microsoft.com/en-us/azure/developer/terraform/)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/)
- [Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/)

### Community Best Practices

- [Azure Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

## Summary

Terraform with Azure provides:

- ✅ Comprehensive infrastructure automation
- ✅ Multi-environment management
- ✅ Version-controlled infrastructure
- ✅ Consistent deployment patterns
- ✅ Integration with CI/CD pipelines
- ✅ Cost optimization through IaC
- ✅ Security and compliance enforcement

**Key Advantages:**

- Declarative infrastructure definition
- Idempotent operations
- Preview changes before applying
- Dependency management
- Reusable modules
- Multi-cloud capability

**Next Steps:**

1. Set up Azure authentication
2. Create remote state storage
3. Build modular infrastructure
4. Implement CI/CD pipelines
5. Add security scanning
6. Establish governance policies
7. Monitor and optimize costs
