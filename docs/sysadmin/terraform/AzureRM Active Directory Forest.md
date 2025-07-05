# AzureRM Active Directory Forest

This page provides a reference to a community Terraform module for deploying an Active Directory Forest on Azure using the AzureRM provider.

For full documentation and usage examples, visit the module repository:

<https://github.com/kumarvna/terraform-azurerm-active-directory-forest/tree/master>

**Example usage:**

```hcl
module "ad_forest" {
  source  = "kumarvna/active-directory-forest/azurerm"
  version = "x.y.z"

  # ...set required variables here...
}
```

> **Note:**  
> Always review the module documentation for input variables, outputs, and best practices