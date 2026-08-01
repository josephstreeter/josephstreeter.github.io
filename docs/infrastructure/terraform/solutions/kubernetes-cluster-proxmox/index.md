---
title: "Kubernetes Cluster on Proxmox with Terraform"
description: "Deploying VM infrastructure on Proxmox VE with Terraform for a Kubernetes cluster: configuration, Packer templates, GitOps, operations, and monitoring"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "cluster", "ha"]
category: "infrastructure"
difficulty: "advanced"
last_updated: "2026-08-01"
---
## Kubernetes Cluster on Proxmox with Terraform

This guide demonstrates how to deploy VM infrastructure on Proxmox VE using Terraform for Kubernetes clusters. Terraform handles VM provisioning with cloud-init integration, while Kubernetes installation can be automated through cloud-init scripts, Ansible, or manual setup. The configuration creates multiple nodes with proper networking, security, and scalability considerations.

> **⚠️ SECURITY WARNING:** This guide contains example configurations with placeholder values. NEVER use these examples directly in production. Always:
>
> - Generate unique SSH keys for each environment
> - Use strong, randomly generated passwords and tokens
> - Enable TLS verification (set `proxmox_tls_insecure = false`)
> - Store sensitive values in secure secret management systems (HashiCorp Vault, AWS Secrets Manager, etc.)
> - Never commit `terraform.tfvars` or any files containing credentials to version control
> - Implement regular secret rotation policies

---

> **Note:** This guide focuses on infrastructure provisioning. Kubernetes installation is covered through cloud-init automation. For production deployments, consider using Packer for template creation and GitOps workflows.

This guide is long enough to work through in stages. Each page below is self-contained:

| Page | Covers |
|------|--------|
| [Terraform Configuration](terraform-configuration.md) | Providers, variables, data sources, node resources, outputs |
| [Modules and Load Balancer](modules-and-load-balancer.md) | HAProxy for the HA API endpoint, `tfvars`, reusable modules |
| [Packer Template Creation](packer-template.md) | Building the Debian base image the nodes are cloned from |
| [Deployment and Kubernetes Installation](deployment.md) | Applying the plan and bootstrapping the cluster |
| [GitOps Workflow](gitops.md) | Declarative cluster management |
| [Testing and Examples](testing.md) | Validation and production-grade configurations |
| [Day-2 Operations](operations.md) | Scaling, upgrades, backup, maintenance |
| [Monitoring](monitoring.md) | Prometheus, Grafana, and alerting |
| [Security Considerations](security.md) | Network security, access control, secret rotation |
| [Capacity Planning and Cost](capacity-planning.md) | Sizing and performance tuning |
| [Troubleshooting](troubleshooting.md) | Provisioning, cloud-init, and bootstrap failures |

> [!TIP]
> Start with the [Packer template](packer-template.md) if you do not already have a Proxmox
> VM template — the Terraform configuration clones from one. Otherwise begin with
> [Terraform Configuration](terraform-configuration.md).

## Prerequisites

### Proxmox VE Requirements

- Proxmox VE 7.x or later
- API user with appropriate permissions
- Cloud-init enabled VM template (Ubuntu/Debian recommended)
- Sufficient resources for cluster nodes
- Network bridge configured (vmbr0)

### Required Proxmox API Permissions

Create a dedicated API user with least-privilege permissions:

```bash
# Create user
pveum user add terraform-prov@pve

# Create custom role with required permissions
pveum role add TerraformProvisioner -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit SDN.Use"

# Assign role to user
pveum aclmod / -user terraform-prov@pve -role TerraformProvisioner

# Create API token (non-privileged separation)
pveum user token add terraform-prov@pve terraform_id -privsep 1

# Alternative: Create token without privilege separation for testing
# pveum user token add terraform-prov@pve terraform_id -privsep 0
```

> **Security Best Practice:** Use `-privsep 1` for privilege separation. This ensures the API token has the same permissions as the user, not elevated privileges.

### Terraform Requirements

- Terraform >= 1.0
- Proxmox Terraform provider
- SSH key pair for VM access

### Cloud-Init Template Preparation

Ensure your template includes:

```bash
# Install cloud-init and qemu-guest-agent
sudo apt update && sudo apt install -y cloud-init qemu-guest-agent

# Enable services
sudo systemctl enable qemu-guest-agent
sudo systemctl enable cloud-init

# Clean template before conversion
sudo cloud-init clean --logs
sudo rm -rf /var/lib/cloud/instances/*
```

---

## Best Practices

### Infrastructure as Code

- **Version Control**: Always use Git for Terraform configurations
- **State Management**: Use remote state backends (S3, Consul, etc.)
- **Environment Separation**: Use workspaces or separate directories
- **Documentation**: Keep README files updated with deployment procedures

### Security Best Practices

- **Secrets Management**: Never commit sensitive values to Git
- **Least Privilege**: Grant minimum necessary permissions
- **Regular Updates**: Keep Terraform provider and Kubernetes versions current
- **Monitoring**: Implement logging and monitoring for security events

### Operational Best Practices

- **Resource Tagging**: Use consistent tagging for resource organization
- **Backup Strategy**: Automated backups of both infrastructure state and cluster data
- **Disaster Recovery**: Document and test recovery procedures
- **Change Management**: Use pull request workflows for infrastructure changes

---

**Important Security Notes:**

- **Never commit `terraform.tfvars`** or any files containing sensitive data to version control
- **Use environment variables** or encrypted secret management for sensitive values  
- **Rotate API tokens** and SSH keys regularly
- **Implement proper network segmentation** and firewall rules
- **Keep Proxmox and Kubernetes** updated with latest security patches

## Related Topics

- [Terraform Solutions](../index.md) — other reference deployments
- [Terraform](../../index.md) — provider setup, state, and workflow
- [Packer](../../../packer/index.md) — general Packer usage and other builders
- [Proxmox](../../../proxmox/index.md) — the virtualization platform
- [Kubernetes](../../../kubernetes/index.md) — working with the cluster once it exists
