---
title: "Security Considerations"
description: "Network security, access control, SSH key management, secret rotation, and Kubernetes hardening"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "security", "hardening", "secrets"]
category: "infrastructure"
last_updated: "2026-08-01"
---
## Security Considerations

### Network Security

- Use private network ranges for cluster communication
- Implement firewall rules for API access
- Consider VPN for management access
- Isolate cluster network from other VLANs

### Access Control

```bash
# Create restricted Proxmox user for Terraform
pveum user add terraform-prov@pve --comment "Terraform provisioning user"
pveum aclmod /vms -user terraform-prov@pve -role PVEVMAdmin
pveum aclmod /storage -user terraform-prov@pve -role PVEDatastoreUser
```

### SSH Key Management

```bash
# Generate dedicated SSH key for cluster
ssh-keygen -t ed25519 -f ~/.ssh/k8s-cluster -C "k8s-cluster@$(hostname)"

# Use in terraform.tfvars
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... k8s-cluster@hostname"
```

### Secret Rotation Strategy

Implement regular rotation of all sensitive credentials to maintain security:

#### 1. Proxmox API Token Rotation

Rotate Proxmox API tokens every 90 days:

```bash
# Generate new API token
NEW_TOKEN_ID="terraform-prov@pve!terraform_id_$(date +%Y%m%d)"
pveum user token add terraform-prov@pve "terraform_id_$(date +%Y%m%d)" -privsep 1

# Update terraform.tfvars with new token
# Test deployment with new token
terraform plan

# After successful test, delete old token
pveum user token remove terraform-prov@pve terraform_id_old
```

**Automation with script:**

```bash
#!/bin/bash
# proxmox-token-rotation.sh
set -euo pipefail

OLD_TOKEN_NAME="${1:?Usage: $0 <old_token_name>}"
NEW_TOKEN_NAME="terraform_id_$(date +%Y%m%d)"
USER="terraform-prov@pve"

echo "Creating new token: $NEW_TOKEN_NAME"
pveum user token add "$USER" "$NEW_TOKEN_NAME" -privsep 1

echo "Update your terraform.tfvars with the new token:"
echo "proxmox_api_token_id = \"$USER!$NEW_TOKEN_NAME\""
echo ""
echo "After testing, delete old token with:"
echo "pveum user token remove $USER $OLD_TOKEN_NAME"
```

#### 2. SSH Key Rotation

Rotate SSH keys every 6 months:

```bash
# Generate new SSH key pair
ssh-keygen -t ed25519 -f ~/.ssh/k8s-cluster-new -C "k8s-cluster-$(date +%Y%m%d)"

# Add new key to all nodes
for node_ip in 192.168.100.10 192.168.100.11 192.168.100.12 192.168.100.20 192.168.100.21 192.168.100.22; do
  echo "Adding new key to $node_ip"
  ssh-copy-id -i ~/.ssh/k8s-cluster-new.pub ubuntu@$node_ip
done

# Test new key access
for node_ip in 192.168.100.10 192.168.100.11 192.168.100.12 192.168.100.20 192.168.100.21 192.168.100.22; do
  ssh -i ~/.ssh/k8s-cluster-new -o PasswordAuthentication=no ubuntu@$node_ip "echo 'Connection successful to $node_ip'"
done

# Update terraform.tfvars
# ssh_public_key = file("~/.ssh/k8s-cluster-new.pub")

# Remove old keys from nodes after verification
for node_ip in 192.168.100.10 192.168.100.11 192.168.100.12 192.168.100.20 192.168.100.21 192.168.100.22; do
  ssh -i ~/.ssh/k8s-cluster-new ubuntu@$node_ip "sed -i '/k8s-cluster@/d' ~/.ssh/authorized_keys"
done
```

#### 3. Kubernetes Certificate Rotation

Kubernetes certificates expire after 1 year by default. Rotate before expiration:

```bash
# Check certificate expiration
kubeadm certs check-expiration

# Renew all certificates
kubeadm certs renew all

# Restart control plane components
kubectl -n kube-system delete pod -l component=kube-apiserver
kubectl -n kube-system delete pod -l component=kube-controller-manager
kubectl -n kube-system delete pod -l component=kube-scheduler

# Update kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

**Automated certificate renewal:**

```bash
# Add to crontab on master nodes: 0 2 1 * * /usr/local/bin/k8s-cert-renew.sh
cat <<'EOF' | sudo tee /usr/local/bin/k8s-cert-renew.sh
#!/bin/bash
set -euo pipefail

LOGFILE="/var/log/k8s-cert-renewal.log"

echo "[$(date)] Starting certificate renewal" >> "$LOGFILE"

if kubeadm certs renew all >> "$LOGFILE" 2>&1; then
  echo "[$(date)] Certificate renewal successful" >> "$LOGFILE"
  
  # Restart control plane
  kubectl -n kube-system delete pod -l component=kube-apiserver --grace-period=30
  kubectl -n kube-system delete pod -l component=kube-controller-manager --grace-period=30
  kubectl -n kube-system delete pod -l component=kube-scheduler --grace-period=30
  
  echo "[$(date)] Control plane restarted" >> "$LOGFILE"
else
  echo "[$(date)] Certificate renewal failed!" >> "$LOGFILE"
  exit 1
fi
EOF

sudo chmod +x /usr/local/bin/k8s-cert-renew.sh
```

#### 4. Secrets Management Best Practices

**Use External Secret Management:**

```hcl
# Example: HashiCorp Vault integration
variable "vault_addr" {
  type        = string
  description = "Vault server address"
  default     = "https://vault.example.com:8200"
}

data "vault_generic_secret" "proxmox_credentials" {
  path = "secret/proxmox/terraform"
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = data.vault_generic_secret.proxmox_credentials.data["token_id"]
  pm_api_token_secret = data.vault_generic_secret.proxmox_credentials.data["token_secret"]
  pm_tls_insecure     = false
}
```

**Kubernetes Secrets with External Secrets Operator:**

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: proxmox-credentials
  namespace: terraform
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: proxmox-credentials
    creationPolicy: Owner
  data:
    - secretKey: api_token_id
      remoteRef:
        key: secret/proxmox/terraform
        property: token_id
    - secretKey: api_token_secret
      remoteRef:
        key: secret/proxmox/terraform
        property: token_secret
```

#### 5. Rotation Schedule

Implement this rotation schedule:

| Secret Type            | Rotation Frequency | Priority |
| ---------------------- | ------------------ | -------- |
| Proxmox API Tokens     | 90 days            | High     |
| SSH Keys               | 180 days           | High     |
| Kubernetes Certificates| 365 days (auto)    | Critical |
| Database Passwords     | 90 days            | High     |
| Service Account Tokens | 30 days            | Medium   |
| TLS Certificates       | Before expiration  | Critical |

**Create rotation reminders:**

```bash
# Add to main.tf
resource "time_rotating" "proxmox_token_rotation" {
  rotation_days = 90
}

resource "time_rotating" "ssh_key_rotation" {
  rotation_days = 180
}

# Output warnings when rotation is needed
output "security_warnings" {
  value = {
    proxmox_token_rotated = time_rotating.proxmox_token_rotation.rfc3339
    ssh_key_rotated      = time_rotating.ssh_key_rotation.rfc3339
    rotation_due_days    = {
      proxmox_token = max(0, 90 - parseint(formatdate("DD", timestamp()), 10))
      ssh_key       = max(0, 180 - parseint(formatdate("DD", timestamp()), 10))
    }
  }
}
```

### Kubernetes Security

- Enable RBAC (default in modern Kubernetes)
- Use network policies for pod communication
- Implement admission controllers (PSP/PSA/OPA)
- Regular security updates and patching
- Enable audit logging
- Use pod security standards
- Implement image scanning with Trivy or Clair

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
