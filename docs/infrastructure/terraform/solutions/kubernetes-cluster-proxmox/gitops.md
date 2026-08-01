---
title: "GitOps Workflow"
description: "Managing the cluster declaratively with a GitOps workflow and automated reconciliation"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "gitops", "automation", "ci-cd"]
category: "infrastructure"
last_updated: "2026-08-01"
---
## GitOps Workflow Implementation

### GitOps Repository Structure

```text
k8s-infrastructure/
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.tf
│   │   ├── staging/
│   │   └── production/
│   ├── modules/
│   └── global/
├── kubernetes/
│   ├── base/
│   │   ├── namespaces/
│   │   ├── ingress/
│   │   └── monitoring/
│   ├── overlays/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── production/
│   └── apps/
├── ansible/
│   ├── playbooks/
│   └── roles/
└── .github/
    └── workflows/
        ├── terraform-plan.yml
        ├── terraform-apply.yml
        └── argocd-sync.yml
```

### GitHub Actions Terraform Workflow

Create `.github/workflows/terraform-plan.yml`:

```yaml
name: Terraform Plan

on:
  pull_request:
    branches: [main]
    paths:
      - 'terraform/**'

env:
  TF_VERSION: '1.6.0'

jobs:
  plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, production]
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        working-directory: terraform
      
      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/${{ matrix.environment }}
        env:
          TF_VAR_proxmox_api_token_secret: ${{ secrets.PROXMOX_API_TOKEN }}
      
      - name: Terraform Validate
        run: terraform validate
        working-directory: terraform/environments/${{ matrix.environment }}
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: terraform/environments/${{ matrix.environment }}
        env:
          TF_VAR_proxmox_api_token_secret: ${{ secrets.PROXMOX_API_TOKEN }}
      
      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: ${{ matrix.environment }}-tfplan
          path: terraform/environments/${{ matrix.environment }}/tfplan
```

Create `.github/workflows/terraform-apply.yml`:

```yaml
name: Terraform Apply

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - staging
          - production

jobs:
  apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'dev' }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      
      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/${{ github.event.inputs.environment || 'dev' }}
        env:
          TF_VAR_proxmox_api_token_secret: ${{ secrets.PROXMOX_API_TOKEN }}
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: terraform/environments/${{ github.event.inputs.environment || 'dev' }}
        env:
          TF_VAR_proxmox_api_token_secret: ${{ secrets.PROXMOX_API_TOKEN }}
      
      - name: Output Kubeconfig
        run: terraform output -raw kubeconfig > kubeconfig.yaml
        working-directory: terraform/environments/${{ github.event.inputs.environment || 'dev' }}
      
      - name: Upload Kubeconfig
        uses: actions/upload-artifact@v3
        with:
          name: kubeconfig-${{ github.event.inputs.environment || 'dev' }}
          path: kubeconfig.yaml
```

### ArgoCD Integration

Install ArgoCD on the cluster and configure GitOps:

```hcl
# Add to main.tf
resource "null_resource" "install_argocd" {
  count = var.enable_gitops ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Install ArgoCD
      kubectl create namespace argocd || true
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      
      # Wait for ArgoCD to be ready
      kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
      
      # Get initial admin password
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ${path.module}/argocd-password.txt
      
      # Configure ArgoCD to use Git repository
      kubectl apply -f - <<EOF
      apiVersion: v1
      kind: Secret
      metadata:
        name: repo-${var.git_repo_name}
        namespace: argocd
        labels:
          argocd.argoproj.io/secret-type: repository
      stringData:
        type: git
        url: ${var.git_repo_url}
        password: ${var.git_token}
        username: ${var.git_username}
      EOF
    EOT
  }
  
  depends_on = [null_resource.fetch_kubeconfig]
}

# Create ArgoCD Application
resource "null_resource" "argocd_apps" {
  count = var.enable_gitops ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      kubectl apply -f - <<EOF
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: ${var.cluster_name}-apps
        namespace: argocd
      spec:
        project: default
        source:
          repoURL: ${var.git_repo_url}
          targetRevision: HEAD
          path: kubernetes/overlays/${var.environment}
        destination:
          server: https://kubernetes.default.svc
          namespace: default
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=true
      EOF
    EOT
  }
  
  depends_on = [null_resource.install_argocd]
}
```

Add GitOps variables:

```hcl
variable "enable_gitops" {
  type        = bool
  description = "Enable GitOps with ArgoCD"
  default     = false
}

variable "git_repo_url" {
  type        = string
  description = "Git repository URL for GitOps"
  default     = ""
}

variable "git_repo_name" {
  type        = string
  description = "Git repository name"
  default     = "k8s-infrastructure"
}

variable "git_token" {
  type        = string
  description = "Git access token"
  sensitive   = true
  default     = ""
}

variable "git_username" {
  type        = string
  description = "Git username"
  default     = "git"
}
```

---

## Related Topics

- [Overview and Prerequisites](index.md)
- [Terraform Configuration](terraform-configuration.md)
- [Modules and Load Balancer](modules-and-load-balancer.md)
- [Packer Template Creation](packer-template.md)
- [Deployment and Kubernetes Installation](deployment.md)
- [GitOps Workflow](gitops.md)
- [Testing and Examples](testing.md)
- [Day-2 Operations](operations.md)
- [Monitoring](monitoring.md)
- [Security Considerations](security.md)
- [Capacity Planning and Cost](capacity-planning.md)
- [Troubleshooting](troubleshooting.md)
