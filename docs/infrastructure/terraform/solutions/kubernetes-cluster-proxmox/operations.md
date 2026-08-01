---
title: "Day-2 Operations"
description: "Scaling, upgrades, backup, and ongoing maintenance of the cluster and its underlying VMs"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "operations", "maintenance", "scaling", "backup"]
category: "infrastructure"
last_updated: "2026-08-01"
---
## Day-2 Operations

### Kubernetes Version Upgrades

Upgrade control plane first, then workers. Always test in non-production first.

```bash
# On first control plane node
sudo apt-mark unhold kubeadm
sudo apt-get update && sudo apt-get install -y kubeadm=1.29.0-00
sudo apt-mark hold kubeadm

kubectl drain $(hostname) --ignore-daemonsets --delete-emptydir-data
sudo kubeadm upgrade apply v1.29.0

sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.29.0-00 kubectl=1.29.0-00
sudo apt-mark hold kubelet kubectl

sudo systemctl daemon-reload && sudo systemctl restart kubelet
kubectl uncordon $(hostname)
```

### Certificate Management

Monitor and renew certificates before expiration:

```bash
# Check expiration
sudo kubeadm certs check-expiration

# Renew all certificates
sudo kubeadm certs renew all

# Restart control plane
kubectl -n kube-system delete pod -l component=kube-apiserver
```

### etcd Maintenance

Regular defragmentation reclaims disk space:

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  defrag
```

---

## Management and Maintenance

### Scaling Operations

#### Add New Worker Node

1. Update `terraform.tfvars` to add new worker node:

```text
worker_nodes = {
  # ... existing workers ...
  "worker-04" = {
    vmid   = 204
    ip     = "192.168.100.23"
    cores  = 4
    memory = 8192
    disk   = "50G"
  }
}
```

1. Apply changes:

```bash
terraform plan
terraform apply
```

1. Join new node to cluster as shown above.

#### Remove Worker Node

```bash
# Drain node safely
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Delete node from cluster
kubectl delete node <node-name>

# Remove from Terraform configuration
# Update terraform.tfvars and apply
```

### Resource Updates

#### Modify VM Resources

Update node specifications in `terraform.tfvars`:

```text
master_nodes = {
  "master-01" = {
    vmid   = 101
    ip     = "192.168.100.10"
    cores  = 4  # Increased from 2
    memory = 8192  # Increased from 4096
    disk   = "30G"  # Increased from 20G
  }
}
```

**Note:** VM shutdowns required for CPU/memory changes.

### Backup and Recovery

#### Backup Strategy

Define RTO (Recovery Time Objective) and RPO (Recovery Point Objective):

- **RTO Target**: 2 hours for full cluster recovery
- **RPO Target**: Maximum 4 hours data loss for applications, 1 hour for infrastructure state

**Backup Components:**

```bash
# 1. Backup Terraform state (critical for infrastructure)
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)

# 2. Backup etcd (Kubernetes cluster state)
sudo ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup-$(date +%Y%m%d-%H%M%S).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# 3. Backup Kubernetes resources
kubectl get all --all-namespaces -o yaml > cluster-resources-$(date +%Y%m%d-%H%M%S).yaml

# 4. Backup persistent volumes data
# Use Velero or storage-specific snapshots

# 5. Backup certificates and secrets
sudo tar -czf k8s-pki-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  /etc/kubernetes/pki \
  /etc/kubernetes/admin.conf
```

#### Automated Backup Script

```bash
cat <<'EOF' > /usr/local/bin/k8s-backup.sh
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/kubernetes-backups"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting Kubernetes backup"

# Backup etcd
if ETCDCTL_API=3 etcdctl snapshot save "$BACKUP_DIR/etcd-$DATE.db" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key; then
  echo "[$(date)] etcd backup completed"
else
  echo "[$(date)] etcd backup FAILED" >&2
  exit 1
fi

# Backup all resources
kubectl get all --all-namespaces -o yaml > "$BACKUP_DIR/resources-$DATE.yaml"

# Cleanup old backups
find "$BACKUP_DIR" -name "*.db" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.yaml" -mtime +$RETENTION_DAYS -delete

echo "[$(date)] Backup completed: $BACKUP_DIR"
EOF

chmod +x /usr/local/bin/k8s-backup.sh
```

#### Recovery Procedures

##### Scenario 1: Single Node Failure

```bash
# Remove failed node from cluster
kubectl delete node <failed-node>

# Update Terraform to replace node
terraform taint proxmox_vm_qemu.k8s_workers["worker-01"]
terraform apply

# Node will automatically join cluster via cloud-init/Ansible
```

##### Scenario 2: Control Plane Failure (HA)

```bash
# If one master fails, cluster continues operating
# Remove failed master
kubectl delete node <failed-master>

# Recreate master with Terraform
terraform taint proxmox_vm_qemu.k8s_masters["master-02"]
terraform apply

# Join new master to cluster
kubeadm join <lb-ip>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane --certificate-key <key>
```

##### Scenario 3: Complete etcd Restore

```bash
# Stop all control plane components
sudo systemctl stop kubelet

# Restore etcd snapshot
sudo ETCDCTL_API=3 etcdctl snapshot restore /opt/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore \
  --name=$(hostname) \
  --initial-cluster=master-01=https://192.168.100.10:2380,master-02=https://192.168.100.11:2380,master-03=https://192.168.100.12:2380 \
  --initial-advertise-peer-urls=https://192.168.100.10:2380

# Update etcd data directory
sudo rm -rf /var/lib/etcd
sudo mv /var/lib/etcd-restore /var/lib/etcd

# Start kubelet
sudo systemctl start kubelet

# Verify cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

##### Scenario 4: Complete Cluster Rebuild

```bash
# 1. Restore Terraform state
cp terraform.tfstate.backup terraform.tfstate

# 2. Rebuild infrastructure
terraform apply

# 3. Restore etcd on first master (see Scenario 3)

# 4. Restore application data from persistent volume backups

# 5. Verify all services
kubectl get all --all-namespaces
```

#### Disaster Recovery Testing

Test DR procedures quarterly:

```bash
# DR Test Checklist
cat <<'EOF' > dr-test-checklist.md
# Disaster Recovery Test

## Pre-Test
- [ ] Notify team of DR test
- [ ] Document current cluster state
- [ ] Verify backups are available
- [ ] Prepare test environment

## Test Execution
- [ ] Simulate failure (controlled)
- [ ] Measure detection time
- [ ] Execute recovery procedures
- [ ] Measure recovery time
- [ ] Verify all services restored
- [ ] Check data integrity

## Post-Test
- [ ] Document actual RTO achieved
- [ ] Document actual RPO achieved
- [ ] Identify improvement areas
- [ ] Update runbooks
- [ ] Share lessons learned

## Metrics
- Detection Time: ___ minutes
- Recovery Time: ___ minutes
- Data Loss: ___ (transactions/records)
- Success Rate: ____%
EOF
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
