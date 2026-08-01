---
title: "Testing and Examples"
description: "Validating the deployment and production-grade configuration examples"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "testing", "validation", "examples"]
category: "infrastructure"
last_updated: "2026-08-01"
---
## Comprehensive Testing

### Unit Tests with Terratest

Create `test/terraform_test.go`:

```go
package test

import (
    "testing"
    "time"
    
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/retry"
    "github.com/stretchr/testify/assert"
)

func TestTerraformProxmoxCluster(t *testing.T) {
    t.Parallel()
    
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../terraform",
        
        Vars: map[string]interface{}{
            "cluster_name": "test-cluster",
            "master_nodes": map[string]interface{}{
                "master-01": map[string]interface{}{
                    "vmid":   501,
                    "ip":     "192.168.100.50",
                    "cores":  2,
                    "memory": 4096,
                    "disk":   "20G",
                },
            },
            "worker_nodes": map[string]interface{}{
                "worker-01": map[string]interface{}{
                    "vmid":   601,
                    "ip":     "192.168.100.60",
                    "cores":  2,
                    "memory": 4096,
                    "disk":   "20G",
                },
            },
        },
        
        EnvVars: map[string]string{
            "TF_VAR_proxmox_api_token_secret": "<YOUR_TOKEN>",
        },
    })
    
    defer terraform.Destroy(t, terraformOptions)
    
    terraform.InitAndApply(t, terraformOptions)
    
    // Validate outputs
    masterNodes := terraform.OutputMap(t, terraformOptions, "master_nodes")
    assert.NotEmpty(t, masterNodes)
    assert.Equal(t, "192.168.100.50", masterNodes["master-01"].(map[string]interface{})["ip"])
    
    workerNodes := terraform.OutputMap(t, terraformOptions, "worker_nodes")
    assert.NotEmpty(t, workerNodes)
    
    // Test SSH connectivity
    masterIP := masterNodes["master-01"].(map[string]interface{})["ip"].(string)
    testSSHConnection(t, masterIP)
}

func testSSHConnection(t *testing.T, ip string) {
    maxRetries := 30
    timeBetweenRetries := 10 * time.Second
    
    retry.DoWithRetry(t, "SSH to VM", maxRetries, timeBetweenRetries, func() (string, error) {
        // SSH connection test logic
        return "", nil
    })
}
```

### Integration Tests

Create `test/integration_test.go`:

```go
package test

import (
    "testing"
    
    "github.com/gruntwork-io/terratest/modules/k8s"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestKubernetesClusterHealth(t *testing.T) {
    t.Parallel()
    
    terraformOptions := &terraform.Options{
        TerraformDir: "../terraform",
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    // Get kubeconfig
    kubeconfig := terraform.Output(t, terraformOptions, "kubeconfig_path")
    
    options := k8s.NewKubectlOptions("", kubeconfig, "default")
    
    // Test: All nodes should be Ready
    nodes := k8s.GetNodes(t, options)
    for _, node := range nodes {
        assert.True(t, k8s.IsNodeReady(node))
    }
    
    // Test: Core components should be running
    coreComponents := []string{
        "kube-apiserver",
        "kube-controller-manager",
        "kube-scheduler",
        "etcd",
    }
    
    for _, component := range coreComponents {
        pods := k8s.ListPods(t, options, metav1.ListOptions{
            LabelSelector: "component=" + component,
        })
        assert.NotEmpty(t, pods)
    }
    
    // Test: DNS should be working
    k8s.RunKubectl(t, options, "run", "test-dns",
        "--image=busybox:1.28",
        "--restart=Never",
        "--",
        "nslookup", "kubernetes.default")
    
    k8s.WaitUntilPodAvailable(t, options, "test-dns", 10, 3*time.Second)
}
```

### Security Scanning with tfsec

Add to CI/CD pipeline:

```yaml
- name: Run tfsec
  uses: aquasecurity/tfsec-action@v1.0.0
  with:
    working_directory: terraform
    soft_fail: false
    format: sarif
    output: tfsec-results.sarif

- name: Upload SARIF file
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: tfsec-results.sarif
```

### Policy as Code with OPA

Create `policies/terraform.rego`:

```rego
package terraform.policies

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "proxmox_vm_qemu"
    resource.change.after.memory < 4096
    msg = sprintf("VM %v has insufficient memory: %v MB (minimum 4096 MB)", [resource.address, resource.change.after.memory])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "proxmox_vm_qemu"
    not resource.change.after.agent
    msg = sprintf("VM %v must have QEMU agent enabled", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "proxmox_vm_qemu"
    contains(resource.change.after.tags, "production")
    not resource.change.after.automatic_reboot
    msg = sprintf("Production VM %v must have automatic_reboot enabled", [resource.address])
}
```

Test with OPA:

```bash
# Generate plan in JSON
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

# Test against policies
opa exec --decision terraform/policies/deny --bundle policies/ tfplan.json
```

---

## Production-Grade Examples

### Enterprise Production Cluster

Complete production configuration in `environments/production/main.tf`:

```hcl
module "production_cluster" {
  source = "../../modules/k8s-cluster"
  
  # Core configuration
  cluster_name    = "prod-k8s"
  environment     = "production"
  proxmox_api_url = var.proxmox_api_url
  target_node     = "pve-prod"
  
  # High-availability configuration
  enable_ha         = true
  enable_monitoring = true
  enable_gitops     = true
  enable_backup     = true
  
  # Network configuration
  cluster_network = {
    subnet  = "10.100.0.0/24"
    gateway = "10.100.0.1"
    dns     = ["10.100.0.2", "10.100.0.3"]  # Internal DNS
  }
  
  lb_ip = "10.100.0.10"
  
  # Master nodes - 3 for HA
  master_nodes = {
    "master-01" = {
      vmid   = 1001
      ip     = "10.100.0.11"
      cores  = 4
      memory = 16384
      disk   = "100G"
    }
    "master-02" = {
      vmid   = 1002
      ip     = "10.100.0.12"
      cores  = 4
      memory = 16384
      disk   = "100G"
    }
    "master-03" = {
      vmid   = 1003
      ip     = "10.100.0.13"
      cores  = 4
      memory = 16384
      disk   = "100G"
    }
  }
  
  # Worker nodes - scalable pool
  worker_nodes = {
    "worker-01" = {
      vmid   = 2001
      ip     = "10.100.0.21"
      cores  = 8
      memory = 32768
      disk   = "200G"
    }
    "worker-02" = {
      vmid   = 2002
      ip     = "10.100.0.22"
      cores  = 8
      memory = 32768
      disk   = "200G"
    }
    "worker-03" = {
      vmid   = 2003
      ip     = "10.100.0.23"
      cores  = 8
      memory = 32768
      disk   = "200G"
    }
    "worker-04" = {
      vmid   = 2004
      ip     = "10.100.0.24"
      cores  = 8
      memory = 32768
      disk   = "200G"
    }
    "worker-05" = {
      vmid   = 2005
      ip     = "10.100.0.25"
      cores  = 8
      memory = 32768
      disk   = "200G"
    }
  }
  
  # Storage configuration
  storage          = "nvme-pool"  # High-performance storage
  template_name    = "debian12-k8s-prod-template"
  
  # Kubernetes configuration
  kubernetes_version = "1.28.3"
  pod_network_cidr   = "10.244.0.0/16"
  service_cidr       = "10.96.0.0/12"
  
  # Security
  ssh_public_key  = file("~/.ssh/prod-k8s.pub")
  cloud_init_user = "k8s-admin"
  
  # GitOps
  git_repo_url  = "https://github.com/yourorg/k8s-infrastructure.git"
  git_repo_name = "k8s-infrastructure"
  git_username  = "argocd"
  git_token     = var.git_token
  
  # Monitoring and logging
  prometheus_retention   = "30d"
  enable_elasticsearch   = true
  enable_grafana        = true
  enable_alertmanager   = true
  
  # Backup configuration
  backup_schedule       = "0 2 * * *"  # Daily at 2 AM
  backup_retention_days = 30
  backup_storage        = "backup-pool"
  
  # Resource tagging
  tags = {
    Environment  = "production"
    Project      = "kubernetes"
    ManagedBy    = "terraform"
    CostCenter   = "engineering"
    Compliance   = "pci-dss"
    Owner        = "platform-team"
    Backup       = "daily"
  }
}
```

### Disaster Recovery Configuration

Add to production cluster:

```hcl
# Automated etcd backup
resource "null_resource" "etcd_backup_cron" {
  count = var.enable_backup ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      kubectl apply -f - <<EOF
      apiVersion: batch/v1
      kind: CronJob
      metadata:
        name: etcd-backup
        namespace: kube-system
      spec:
        schedule: "${var.backup_schedule}"
        jobTemplate:
          spec:
            template:
              spec:
                containers:
                - name: backup
                  image: bitnami/etcd:latest
                  command:
                  - /bin/sh
                  - -c
                  - |
                    ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot-\$(date +%Y%m%d-%H%M%S).db \
                      --endpoints=https://127.0.0.1:2379 \
                      --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                      --cert=/etc/kubernetes/pki/etcd/server.crt \
                      --key=/etc/kubernetes/pki/etcd/server.key
                    
                    # Upload to backup storage
                    rclone copy /backup/ proxmox-backup:etcd-backups/${var.cluster_name}/
                    
                    # Cleanup old backups
                    find /backup/ -name "etcd-snapshot-*.db" -mtime +${var.backup_retention_days} -delete
                  volumeMounts:
                  - name: etcd-certs
                    mountPath: /etc/kubernetes/pki/etcd
                    readOnly: true
                  - name: backup
                    mountPath: /backup
                volumes:
                - name: etcd-certs
                  hostPath:
                    path: /etc/kubernetes/pki/etcd
                - name: backup
                  hostPath:
                    path: /var/lib/etcd-backup
                restartPolicy: OnFailure
                hostNetwork: true
                nodeSelector:
                  node-role.kubernetes.io/control-plane: ""
                tolerations:
                - effect: NoSchedule
                  key: node-role.kubernetes.io/control-plane
      EOF
    EOT
  }
  
  depends_on = [null_resource.fetch_kubeconfig]
}
```

### Multi-Region Setup

```hcl
module "us_east_cluster" {
  source = "../../modules/k8s-cluster"
  
  cluster_name = "prod-us-east"
  region       = "us-east"
  # ... configuration ...
}

module "eu_west_cluster" {
  source = "../../modules/k8s-cluster"
  
  cluster_name = "prod-eu-west"
  region       = "eu-west"
  # ... configuration ...
}

# Cross-cluster service mesh with Istio
resource "null_resource" "multi_cluster_mesh" {
  provisioner "local-exec" {
    command = <<-EOT
      # Configure Istio multi-primary setup
      istioctl install --set values.global.meshID=prod-mesh \
        --set values.global.multiCluster.clusterName=us-east \
        --set values.global.network=network1
    EOT
  }
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
