# Terraform

Terraform is an open-source Infrastructure as Code (IaC) tool that allows you to define, provision, and manage cloud infrastructure and services using declarative configuration files.

## Key Features

- Supports multiple providers (AWS, Azure, Google Cloud, VMware, Proxmox, and more)
- Enables reproducible, version-controlled infrastructure
- Uses a simple, human-readable language (HCL)
- Manages dependencies and resource ordering automatically

## Typical Workflow

1. Write configuration files describing your infrastructure.
2. Initialize the working directory:

    ```bash
    terraform init
    ```

3. Preview changes before applying:

    ```bash
    terraform plan
    ```

4. Apply the configuration to provision resources:

    ```bash
    terraform apply
    ```

5. Destroy resources when no longer needed:

    ```bash
    terraform destroy
    ```

## Best Practices

- Use a `.gitignore` file to exclude sensitive files like `.tfstate` and `.tfvars` from version control.
- Store secrets securely (never commit real secrets to your repository).
- Use modules to organize and reuse code.
- Use remote state storage for team collaboration.

## References

- [Terraform Documentation](https://www.terraform.io/docs/index.html)
- [Terraform GitHub Repository](https://github.com/hashicorp/terraform)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Google Cloud Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
