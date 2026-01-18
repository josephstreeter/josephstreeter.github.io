---
title: "Azure Public DNS Service with Terraform"
description: "Complete guide to deploying and managing a production-ready Azure Public DNS service using Terraform infrastructure as code"
author: "josephstreeter"
ms.date: "2025-01-18"
ms.topic: "how-to-guide"
ms.service: "azure"
keywords: ["Azure", "DNS", "Domain Name System", "Terraform", "Infrastructure as Code", "Public DNS", "DNS Zone", "Name Resolution"]
---

This guide provides a comprehensive approach to deploying a production-ready Azure Public DNS service using Terraform. The configuration includes public DNS zones, proper security hardening, and operational considerations for internet-facing domain name resolution.

## Architecture Overview

### Azure Public DNS Zones

- **Globally distributed name servers** across Azure regions
- **Automatic zone replication** for high availability
- **Built-in DDoS protection** at the platform level
- **Low latency DNS resolution** with Anycast routing
- **Integration with Azure Traffic Manager** for global load balancing
- **Recommended for public-facing services** requiring internet accessibility

### Network Architecture

```text
┌───────────────────────────────────────────────────────────────┐
│                    Azure Subscription                         │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Public DNS Zone                             │ │
│  │  contoso.com                                             │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │  A Records: www, api, mail                         │  │ │
│  │  │  CNAME Records: cdn, blog                          │  │ │
│  │  │  MX Records: mail servers                          │  │ │
│  │  │  TXT Records: SPF, DKIM, verification              │  │ │
│  │  │  CAA Records: certificate authority authorization  │  │ │
│  │  └────────────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                               │
│  Global Azure DNS Name Servers (Anycast)                      │
│  • ns1-01.azure-dns.com                                       │
│  • ns2-01.azure-dns.net                                       │
│  • ns3-01.azure-dns.org                                       │
│  • ns4-01.azure-dns.info                                      │
└───────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Azure Requirements

- **Azure Subscription** with sufficient quotas
- **Resource Group** permissions (Contributor or Owner)
- **DNS Zone Contributor** role for DNS resources
- **Public IP addresses** for A/AAAA records (if applicable)

### Domain Registration

- **Domain registered** with a registrar (e.g., GoDaddy, Namecheap, Google Domains)
- **Access to registrar's DNS settings** to update name servers
- **Domain ownership verification** tokens if required
- **Understanding of DNS delegation** process

### Terraform Requirements

- **Terraform** >= 1.0
- **Azure CLI** installed and authenticated
- **AzureRM Provider** >= 3.0
- **DNS management tools** (dig, nslookup) for testing

### DNS Planning

- **Public DNS zone names** (e.g., `contoso.com`, `example.org`)
- **Record naming conventions** and TTL policies
- **Subdomain strategy** (www, api, mail, etc.)
- **Email routing** requirements (MX records)
- **Domain verification** needs (TXT records)

---

## Terraform Configuration

### Project Structure

```text
azure-public-dns/
├── main.tf                  # Main resource definitions
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── providers.tf             # Provider configurations
├── terraform.tfvars         # Variable values (DO NOT COMMIT)
├── modules/
│   ├── dns-zone/            # Public DNS zone module
│   └── dns-records/         # DNS record management
├── scripts/
│   ├── validate-dns.sh      # DNS validation script
│   ├── test-resolution.sh   # Resolution testing
│   └── export-records.py    # Record export utility
└── policies/
    ├── naming-standards.json # DNS naming conventions
    └── ttl-policies.json    # TTL policy configuration
```

### `providers.tf`

```text
terraform {
  required_version = ">= 1.0"
  
  # Remote state backend configuration
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate001"  # Must be globally unique
    container_name       = "tfstate"
    key                  = "azure-public-dns.tfstate"
    # Optional: Enable state locking
    use_azuread_auth     = true
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
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

variable "public_dns_zones" {
  type = map(object({
    soa_record_email        = string
    soa_record_expire_time  = number
    soa_record_minimum_ttl  = number
    soa_record_refresh_time = number
    soa_record_retry_time   = number
    soa_record_ttl          = number
    tags                    = map(string)
  }))
  description = "Public DNS zone configurations"
  default     = {}
}

variable "a_records" {
  type = map(object({
    zone_name = string
    ttl       = number
    records   = list(string)
  }))
  description = "A record configurations for IPv4 addresses"
  default     = {}
}

variable "aaaa_records" {
  type = map(object({
    zone_name = string
    ttl       = number
    records   = list(string)
  }))
  description = "AAAA record configurations for IPv6 addresses"
  default     = {}
}

variable "cname_records" {
  type = map(object({
    zone_name = string
    ttl       = number
    record    = string
  }))
  description = "CNAME record configurations for aliases"
  default     = {}
}

variable "mx_records" {
  type = map(object({
    zone_name = string
    ttl       = number
    records = list(object({
      preference = number
      exchange   = string
    }))
  }))
  description = "MX record configurations for mail routing"
  default     = {}
}

variable "txt_records" {
  type = map(object({
    zone_name = string
    ttl       = number
    records   = list(string)
  }))
  description = "TXT record configurations for verification, SPF, DKIM, etc."
  default     = {}
}

variable "srv_records" {
  type = map(object({
    zone_name = string
    ttl       = number
    records = list(object({
      priority = number
      weight   = number
      port     = number
      target   = string
    }))
  }))
  description = "SRV record configurations for service discovery"
  default     = {}
}

variable "ptr_records" {
  type = map(object({
    zone_name = string
    ttl       = number
    records   = list(string)
  }))
  description = "PTR record configurations for reverse DNS lookups"
  default     = {}
}

variable "caa_records" {
  type = map(object({
    zone_name = string
    ttl       = number
    records = list(object({
      flags = number
      tag   = string
      value = string
    }))
  }))
  description = "CAA record configurations for certificate authority authorization"
  default     = {}
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable Azure Monitor integration for DNS query logging and metrics"
  default     = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostic settings"
  default     = null
}

variable "alert_email_addresses" {
  type        = list(string)
  description = "Email addresses for DNS monitoring alerts"
  default     = []
}

variable "default_ttl" {
  type        = number
  description = "Default TTL for DNS records (in seconds)"
  default     = 3600
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Project     = "Public DNS"
    Environment = "Production"
    Owner       = "Network Team"
  }
}
```

### `main.tf`

```text
# Local variables
locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  )
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Log Analytics Workspace for DNS monitoring
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.resource_group_name}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# Public DNS Zones
resource "azurerm_dns_zone" "public" {
  for_each            = var.public_dns_zones
  name                = each.key
  resource_group_name = azurerm_resource_group.main.name

  soa_record {
    email        = each.value.soa_record_email
    expire_time  = each.value.soa_record_expire_time
    minimum_ttl  = each.value.soa_record_minimum_ttl
    refresh_time = each.value.soa_record_refresh_time
    retry_time   = each.value.soa_record_retry_time
    ttl          = each.value.soa_record_ttl
  }

  tags = merge(local.common_tags, each.value.tags)
}

# A Records (IPv4)
resource "azurerm_dns_a_record" "main" {
  for_each            = var.a_records

  name                = each.key
  zone_name           = each.value.zone_name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = local.common_tags

  depends_on = [azurerm_dns_zone.public]
}

# AAAA Records (IPv6)
resource "azurerm_dns_aaaa_record" "main" {
  for_each            = var.aaaa_records

  name                = each.key
  zone_name           = each.value.zone_name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = local.common_tags

  depends_on = [azurerm_dns_zone.public]
}

# CNAME Records
resource "azurerm_dns_cname_record" "main" {
  for_each            = var.cname_records

  name                = each.key
  zone_name           = each.value.zone_name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = each.value.ttl
  record              = each.value.record

  tags = local.common_tags

  depends_on = [azurerm_dns_zone.public]
}

# MX Records (Mail Exchange)
resource "azurerm_dns_mx_record" "main" {
  for_each            = var.mx_records

  name                = each.key
  zone_name           = each.value.zone_name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      preference = record.value.preference
      exchange   = record.value.exchange
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_dns_zone.public]
}

# TXT Records
resource "azurerm_dns_txt_record" "main" {
  for_each            = var.txt_records

  name                = each.key
  zone_name           = each.value.zone_name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      value = record.value
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_dns_zone.public]
}

# SRV Records
resource "azurerm_dns_srv_record" "main" {
  for_each            = var.srv_records

  name                = each.key
  zone_name           = each.value.zone_name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      priority = record.value.priority
      weight   = record.value.weight
      port     = record.value.port
      target   = record.value.target
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_dns_zone.public]
}

# PTR Records (Reverse DNS)
resource "azurerm_dns_ptr_record" "main" {
  for_each            = var.ptr_records

  name                = each.key
  zone_name           = each.value.zone_name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = local.common_tags

  depends_on = [azurerm_dns_zone.public]
}

# CAA Records (Certificate Authority Authorization)
resource "azurerm_dns_caa_record" "main" {
  for_each            = var.caa_records

  name                = each.key
  zone_name           = each.value.zone_name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      flags = record.value.flags
      tag   = record.value.tag
      value = record.value.value
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_dns_zone.public]
}

# Diagnostic settings for Public DNS Zones
resource "azurerm_monitor_diagnostic_setting" "dns" {
  for_each = var.enable_monitoring ? var.public_dns_zones : {}

  name                       = "${each.key}-diagnostics"
  target_resource_id         = azurerm_dns_zone.public[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  enabled_log {
    category = "QueryLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Action Group for DNS alerts
resource "azurerm_monitor_action_group" "dns_alerts" {
  count               = var.enable_monitoring && length(var.alert_email_addresses) > 0 ? 1 : 0
  name                = "public-dns-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "pdnsalert"

  dynamic "email_receiver" {
    for_each = toset(var.alert_email_addresses)
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  tags = local.common_tags
}

# Alert for high DNS query volume
resource "azurerm_monitor_metric_alert" "high_query_volume" {
  for_each = var.enable_monitoring ? var.public_dns_zones : {}

  name                = "${each.key}-high-query-volume"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_dns_zone.public[each.key].id]
  description         = "Alert when DNS query volume is abnormally high"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Network/dnszones"
    metric_name      = "QueryVolume"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 100000
  }

  frequency   = "PT5M"
  window_size = "PT15M"

  action {
    action_group_id = var.enable_monitoring && length(var.alert_email_addresses) > 0 ? azurerm_monitor_action_group.dns_alerts[0].id : null
  }

  tags = local.common_tags
}
```

### `outputs.tf`

```text
output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Name of the resource group"
}

output "public_dns_zones" {
  value = {
    for k, v in azurerm_dns_zone.public : k => {
      id              = v.id
      name_servers    = v.name_servers
      max_record_sets = v.max_number_of_record_sets
    }
  }
  description = "Public DNS zone details including name servers"
}

output "public_dns_name_servers" {
  value = {
    for k, v in azurerm_dns_zone.public : k => v.name_servers
  }
  description = "Name servers for public DNS zones - configure these at your domain registrar"
}

output "log_analytics_workspace_id" {
  value       = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null
  description = "Log Analytics workspace ID for DNS monitoring"
}

output "dns_record_counts" {
  value = {
    a_records    = length(var.a_records)
    aaaa_records = length(var.aaaa_records)
    cname_records = length(var.cname_records)
    mx_records   = length(var.mx_records)
    txt_records  = length(var.txt_records)
    srv_records  = length(var.srv_records)
    ptr_records  = length(var.ptr_records)
    caa_records  = length(var.caa_records)
  }
  description = "Count of DNS records by type"
}

output "zone_ids" {
  value = {
    for k, v in azurerm_dns_zone.public : k => v.id
  }
  description = "Map of zone names to resource IDs"
}
```

### `terraform.tfvars` (Example)

```text
resource_group_name = "rg-public-dns-prod"
location            = "East US"
environment         = "prod"

# Public DNS Zones
public_dns_zones = {
  "contoso.com" = {
    soa_record_email        = "admin.contoso.com"
    soa_record_expire_time  = 2419200
    soa_record_minimum_ttl  = 300
    soa_record_refresh_time = 3600
    soa_record_retry_time   = 300
    soa_record_ttl          = 3600
    tags = {
      Purpose = "Public Website"
      Domain  = "Primary"
    }
  }
  "example.org" = {
    soa_record_email        = "hostmaster.example.org"
    soa_record_expire_time  = 2419200
    soa_record_minimum_ttl  = 300
    soa_record_refresh_time = 3600
    soa_record_retry_time   = 300
    soa_record_ttl          = 3600
    tags = {
      Purpose = "Marketing Site"
      Domain  = "Secondary"
    }
  }
}

# A Records
a_records = {
  "www" = {
    zone_name = "contoso.com"
    ttl       = 3600
    records   = ["20.51.4.28"]
  }
  "api" = {
    zone_name = "contoso.com"
    ttl       = 300
    records   = ["20.51.4.29"]
  }
  "@" = {
    zone_name = "contoso.com"
    ttl       = 3600
    records   = ["20.51.4.28"]
  }
}

# AAAA Records (IPv6)
aaaa_records = {
  "www" = {
    zone_name = "contoso.com"
    ttl       = 3600
    records   = ["2001:0db8:85a3:0000:0000:8a2e:0370:7334"]
  }
}

# CNAME Records
cname_records = {
  "blog" = {
    zone_name = "contoso.com"
    ttl       = 3600
    record    = "contoso.azurewebsites.net"
  }
  "cdn" = {
    zone_name = "contoso.com"
    ttl       = 3600
    record    = "contoso.azureedge.net"
  }
}

# MX Records
mx_records = {
  "@" = {
    zone_name = "contoso.com"
    ttl       = 3600
    records = [
      {
        preference = 10
        exchange   = "mail1.contoso.com"
      },
      {
        preference = 20
        exchange   = "mail2.contoso.com"
      }
    ]
  }
}

# TXT Records (SPF, DKIM, verification)
txt_records = {
  "@" = {
    zone_name = "contoso.com"
    ttl       = 3600
    records = [
      "v=spf1 include:_spf.google.com ~all",
      "MS=ms12345678"
    ]
  }
  "_dmarc" = {
    zone_name = "contoso.com"
    ttl       = 3600
    records   = ["v=DMARC1; p=quarantine; rua=mailto:dmarc@contoso.com"]
  }
}

# CAA Records (Certificate Authority Authorization)
caa_records = {
  "@" = {
    zone_name = "contoso.com"
    ttl       = 3600
    records = [
      {
        flags = 0
        tag   = "issue"
        value = "letsencrypt.org"
      },
      {
        flags = 0
        tag   = "issuewild"
        value = "letsencrypt.org"
      }
    ]
  }
}

# Monitoring
enable_monitoring     = true
alert_email_addresses = ["dnsadmin@contoso.com", "ops@contoso.com"]

tags = {
  Project     = "Public DNS Infrastructure"
  Environment = "Production"
  Owner       = "Network Team"
  CostCenter  = "IT-001"
}
```

---

## Deployment Steps

### 1. Initialize Terraform

```bash
# Navigate to project directory
cd azure-public-dns

# Initialize Terraform and download providers
terraform init

# Validate configuration
terraform validate

# Review planned changes
terraform plan -out=tfplan
```

### 2. Deploy Public DNS Infrastructure

```bash
# Apply the configuration
terraform apply tfplan

# Save outputs for reference
terraform output -json > dns-outputs.json
```

### 3. Configure Domain Registrar

After deployment, update your domain registrar's name server settings:

```bash
# View Azure DNS name servers
terraform output public_dns_name_servers

# Example output:
# contoso.com = [
#   "ns1-01.azure-dns.com.",
#   "ns2-01.azure-dns.net.",
#   "ns3-01.azure-dns.org.",
#   "ns4-01.azure-dns.info."
# ]
```

**At your domain registrar:**

1. Log into your registrar's control panel
2. Navigate to DNS/Name Server settings
3. Replace existing name servers with Azure DNS name servers
4. Save changes (propagation takes 24-48 hours)

### 4. Verify DNS Resolution

```bash
# Test public DNS resolution against Azure name servers
dig @ns1-01.azure-dns.com www.contoso.com

# Test with Google DNS (after propagation)
dig @8.8.8.8 www.contoso.com

# Test CNAME records
dig @ns1-01.azure-dns.com blog.contoso.com

# Test MX records
dig @ns1-01.azure-dns.com contoso.com MX

# Test TXT records
dig @ns1-01.azure-dns.com contoso.com TXT

# Test CAA records
dig @ns1-01.azure-dns.com contoso.com CAA

# Check DNS propagation globally
dig +trace www.contoso.com
```

---

## Operations and Maintenance

### DNS Record Management

#### Adding New Records

Update `terraform.tfvars`:

```text
a_records = {
  # ... existing records ...
  "newapp" = {
    zone_name = "contoso.com"
    ttl       = 300
    records   = ["20.51.4.30"]
  }
}
```

Apply changes:

```bash
terraform plan
terraform apply
```

#### Updating TTL Values

Reduce TTL before major changes, then revert after:

```text
# Before change: reduce TTL
a_records = {
  "www" = {
    zone_name = "contoso.com"
    ttl       = 60  # Reduced from 3600
    records   = ["20.51.4.28"]
  }
}

# Wait for old TTL to expire (original TTL duration)
# Make the IP change
# After change stabilizes: restore TTL
ttl = 3600
```

#### Bulk Record Import

For migrating from another DNS provider:

```bash
# Export from old provider
# Create CSV or JSON file with records

# Generate Terraform configuration
python scripts/import-dns-records.py --input records.csv --output imported-records.tf

# Import existing records into Terraform state
terraform import azurerm_dns_a_record.www /subscriptions/xxx/resourceGroups/rg-dns-prod/providers/Microsoft.Network/dnszones/contoso.com/A/www
```

### Monitoring and Alerts

#### View DNS Query Logs

```bash
# Query Log Analytics workspace
az monitor log-analytics query \\
  --workspace <workspace-id> \\
  --analytics-query \"AzureDiagnostics | where ResourceType == 'DNSZONES' | take 100\"
```

#### Monitor Query Volume

```bash
# View metrics in Azure Portal
az monitor metrics list \\
  --resource <dns-zone-id> \\
  --metric QueryVolume \\
  --start-time 2025-01-17T00:00:00Z \\
  --end-time 2025-01-18T00:00:00Z
```

### Backup and Disaster Recovery

#### Export DNS Zone

```bash
# Export public DNS zone
az network dns zone export \\
  --resource-group rg-public-dns-prod \\
  --name contoso.com \\
  --file-name contoso.com.zone

# Store in version control
git add contoso.com.zone
git commit -m \"Backup DNS zone $(date +%Y-%m-%d)\"
git push
```

#### Version Control Best Practices

- **Store zone files in Git** for version history
- **Tag releases** when making significant changes
- **Use branches** for testing DNS changes
- **Automate backups** via scheduled pipelines

### Performance Optimization

#### TTL Recommendations

- **Static records**: 3600-86400 seconds (1-24 hours)
- **Dynamic records**: 300-900 seconds (5-15 minutes)
- **Load balanced**: 60-300 seconds (1-5 minutes)
- **During migration**: 60-300 seconds initially
- **Apex records**: Minimum 300 seconds

#### Caching Strategy

- Use **CNAME records** for flexibility in changing targets
- Implement **Azure Traffic Manager** for global load balancing
- Configure **Azure Front Door** for CDN and WAF integration
- Monitor **cache hit ratios** to optimize TTL values

---

## Advanced Configurations

### Traffic Manager Integration

For global load balancing:

```text
# Traffic Manager profile
resource \"azurerm_traffic_manager_profile\" \"main\" {
  name                   = \"tm-contoso\"
  resource_group_name    = azurerm_resource_group.main.name
  traffic_routing_method = \"Performance\"

  dns_config {
    relative_name = \"contoso-tm\"
    ttl           = 60
  }

  monitor_config {
    protocol                     = \"HTTPS\"
    port                         = 443
    path                         = \"/health\"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }
}

# CNAME pointing to Traffic Manager
resource \"azurerm_dns_cname_record\" \"tm\" {
  name                = \"www\"
  zone_name           = \"contoso.com\"
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_traffic_manager_profile.main.fqdn
}
```

### Azure Front Door Integration

For CDN and WAF:

```text
# Front Door endpoint
resource \"azurerm_cdn_frontdoor_profile\" \"main\" {
  name                = \"fd-contoso\"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = \"Premium_AzureFrontDoor\"
}

# DNS CNAME to Front Door
resource \"azurerm_dns_cname_record\" \"cdn\" {
  name                = \"cdn\"
  zone_name           = \"contoso.com\"
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.main.host_name
}
```

### DNSSEC Alternative - CAA Records

While DNSSEC isn't supported, use CAA records for certificate security:

```text
caa_records = {
  \"@\" = {
    zone_name = \"contoso.com\"
    ttl       = 3600
    records = [
      {
        flags = 0
        tag   = \"issue\"
        value = \"letsencrypt.org\"
      },
      {
        flags = 0
        tag   = \"issuewild\"
        value = \"letsencrypt.org\"
      },
      {
        flags = 0
        tag   = \"iodef\"
        value = \"mailto:security@contoso.com\"
      }
    ]
  }
}
```

---

## Troubleshooting

### Common Issues

#### DNS Resolution Failures

```bash
# Check DNS zone status
az network dns zone show \\
  --resource-group rg-public-dns-prod \\
  --name contoso.com

# Verify name servers are correctly delegated
dig +trace contoso.com

# Check query logs for errors
az monitor log-analytics query \\
  --workspace <workspace-id> \\
  --analytics-query \"AzureDiagnostics | where ResourceType == 'DNSZONES' and ResultCode != 'NOERROR'\"
```

#### Name Server Delegation Issues

```bash
# Check current name servers at registrar
dig NS contoso.com

# Compare with Azure DNS name servers
terraform output public_dns_name_servers

# Test resolution from each name server
for ns in $(dig NS contoso.com +short); do
  echo \"Testing $ns\"
  dig @$ns www.contoso.com +short
done
```

#### High Latency

- Verify **name server locations** are geographically distributed (Azure handles this)
- Check for **DNS query throttling** in metrics
- Review **TTL values** - too low causes excessive queries
- Consider **Azure Front Door** for global distribution
- Monitor **Anycast routing** performance

### Diagnostic Tools

```bash
# DNS lookup with detailed information
dig @ns1-01.azure-dns.com www.contoso.com +trace

# Query specific record types
nslookup -type=MX contoso.com ns1-01.azure-dns.com
nslookup -type=TXT contoso.com ns1-01.azure-dns.com
nslookup -type=CAA contoso.com ns1-01.azure-dns.com

# Test from different locations
curl \"https://www.whatsmydns.net/api/check?server=ns1-01.azure-dns.com&type=A&query=www.contoso.com\"

# Monitor DNS propagation
watch -n 5 'dig @8.8.8.8 www.contoso.com +short'

# Check DNS propagation globally
https://dnschecker.org/
```

---

## Security Best Practices

### Access Control

✅ **Implemented in this configuration:**

- **Azure RBAC** for DNS zone management
- **Resource locks** to prevent accidental deletion
- **Terraform state locking** prevents concurrent modifications
- **Version control** tracks all DNS changes

### DNS Security Extensions (DNSSEC)

⚠️ **Not currently supported** by Azure Public DNS

Workarounds:

- Use **Azure Front Door** with WAF for public-facing services
- Implement **Azure DDoS Protection Standard** for public IPs
- Monitor DNS query patterns for anomalies
- Use **CAA records** for certificate authority control

### Record Protection

✅ **Implemented in this configuration:**

- **Approval workflows** via PR reviews
- **Monitoring alerts** for unexpected changes
- **Audit logging** enabled
- **Immutable infrastructure** via Terraform

### Recommended Additional Security Measures

- **Azure Policy** for DNS naming standards enforcement
- **DDoS Protection Standard** for critical public zones
- **Regular zone exports** for disaster recovery
- **Multi-region redundancy** (Azure DNS provides this automatically)
- **Rate limiting** at application layer

### Compliance and Auditing

```bash
# Query DNS modification audit logs
az monitor activity-log list \\
  --resource-group rg-public-dns-prod \\
  --offset 7d \\
  --query \"[?contains(operationName.value, 'Microsoft.Network/dnszones')]\"

# Export audit logs to storage
az monitor diagnostic-settings create \\
  --name dns-audit-logs \\
  --resource <dns-zone-id> \\
  --logs '[{\"category\": \"AuditEvent\", \"enabled\": true}]' \\
  --storage-account <storage-account-id>
```

---

## Cost Optimization

### Pricing Overview

- **Hosted zone**: $0.50 per zone per month (first 25 zones)
- **Queries**: $0.40 per million queries (first billion)
- **Additional zones**: $0.10 per zone per month (zones 26+)

### Cost-Saving Strategies

1. **Consolidate zones** - Use subdomains instead of separate zones
2. **Optimize TTL** - Higher TTL reduces query volume
3. **Use CNAME records** - Reduces maintenance and record count
4. **Monitor query volume** - Identify and optimize high-volume queries
5. **Remove unused records** - Regular cleanup prevents waste
6. **Leverage Traffic Manager** - More cost-effective than multiple A records

### Cost Monitoring

```bash
# View DNS costs
az consumption usage list \\
  --start-date 2025-01-01 \\
  --end-date 2025-01-31 \\
  --query \"[?contains(instanceName, 'dns')]\"

# Set budget alert
az consumption budget create \\
  --budget-name dns-monthly-budget \\
  --amount 100 \\
  --category cost \\
  --time-grain monthly \\
  --time-period start-date=2025-01-01
```

---

## Migration Strategies

### Migrating from On-Premises DNS

1. **Export existing DNS zones**

   ```bash
   # Windows DNS Server
   dnscmd /ZoneExport contoso.com contoso.com.zone
   
   # BIND DNS
   cat /var/named/contoso.com.zone
   ```

2. **Convert to Azure DNS format**

   ```bash
   python scripts/convert-bind-to-azure.py contoso.com.zone
   ```

3. **Import into Terraform**

   ```bash
   # Create terraform configuration from zone file
   python scripts/zone-to-terraform.py --input contoso.com.zone --output dns-records.tf
   ```

4. **Gradual cutover**
   - Lower TTL to 300 seconds
   - Update NS records at registrar
   - Monitor for 24-48 hours
   - Restore original TTL

### Migrating from AWS Route 53

```bash
# Export Route 53 zone
aws route53 list-resource-record-sets \\
  --hosted-zone-id <zone-id> \\
  --output json > route53-records.json

# Convert to Azure format
python scripts/convert-route53-to-azure.py route53-records.json

# Import to Terraform
terraform import azurerm_dns_zone.main /subscriptions/xxx/resourceGroups/rg-dns/providers/Microsoft.Network/dnszones/contoso.com
```

### Migrating from Google Cloud DNS

```bash
# Export Cloud DNS zone
gcloud dns record-sets export contoso.com.zone \\
  --zone=contoso-com

# Import to Azure DNS
az network dns zone import \\
  --resource-group rg-public-dns-prod \\
  --name contoso.com \\
  --file-name contoso.com.zone
```

---

## Best Practices Summary

### Design Principles

1. **Use descriptive record names** following naming conventions
2. **Implement proper TTL strategy** based on record type and change frequency
3. **Document all DNS changes** in version control
4. **Use CNAME records** for flexibility in changing targets
5. **Monitor query volume** and set up appropriate alerts

### Operational Excellence

1. **Regular zone exports** for backup
2. **Test changes** in non-production first
3. **Use Traffic Manager** for load balancing
4. **Implement gradual rollout** for major changes
5. **Monitor propagation** after registrar updates

### Security

1. **Use Azure RBAC** for least privilege access
2. **Enable audit logging** for all zones
3. **Implement CAA records** for certificate control
4. **Regular security reviews** and compliance checks
5. **DDoS Protection** for critical public zones

### Cost Management

1. **Consolidate DNS zones** where possible
2. **Optimize query volume** with proper TTL
3. **Remove unused records** regularly
4. **Monitor costs** and set budget alerts
5. **Use tags** for cost allocation

---

## Additional Resources

- [Azure DNS Documentation](https://learn.microsoft.com/en-us/azure/dns/)
- [Terraform AzureRM Provider - DNS](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone)
- [DNS Best Practices](https://learn.microsoft.com/en-us/azure/dns/dns-best-practices)
- [Azure DNS Pricing](https://azure.microsoft.com/en-us/pricing/details/dns/)
- [DNS Migration Guide](https://learn.microsoft.com/en-us/azure/dns/dns-migration-guide)
- [Azure Traffic Manager](https://learn.microsoft.com/en-us/azure/traffic-manager/)

---

## Conclusion

This configuration provides a production-ready Azure Public DNS deployment with:

- ✅ Public DNS zone management with global distribution
- ✅ Comprehensive record type support (A, AAAA, CNAME, MX, TXT, SRV, PTR, CAA)
- ✅ Monitoring and alerting for query volumes
- ✅ Security best practices including CAA records
- ✅ Cost optimization strategies
- ✅ Migration guidance from other providers

**Remember to:**

- **Update name servers at your registrar** after deploying public zones
- **Test DNS resolution** before making live
- **Monitor query logs** for issues
- **Regular backups** of zone files
- **Follow change management** processes for production changes
- **Implement DDoS Protection** for critical zones
