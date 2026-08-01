---
title: "Capacity Planning and Cost"
description: "Sizing the cluster, estimating cost, and tuning performance of the underlying Proxmox infrastructure"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "capacity planning", "cost", "performance", "sizing"]
category: "infrastructure"
last_updated: "2026-08-01"
---
## Cost Estimation and Capacity Planning

### Resource Cost Calculator

Estimate infrastructure costs based on node configuration:

```bash
cat <<'EOF' > cost-calculator.sh
#!/bin/bash
# Kubernetes Cluster Cost Estimator for Proxmox

# Proxmox host specifications
TOTAL_CPU_CORES=64
TOTAL_RAM_GB=256
TOTAL_STORAGE_TB=4

# Cost assumptions (adjust for your region/provider)
COST_PER_CORE_MONTHLY=5.00
COST_PER_GB_RAM_MONTHLY=2.00
COST_PER_GB_STORAGE_MONTHLY=0.10
POWER_COST_PER_KWH=0.12
WATTS_PER_CORE=10
HOURS_PER_MONTH=730

# Cluster configuration
MASTER_COUNT=3
MASTER_CORES=2
MASTER_RAM_GB=4
MASTER_DISK_GB=20

WORKER_COUNT=3
WORKER_CORES=4
WORKER_RAM_GB=8
WORKER_DISK_GB=50

# Calculate resources
TOTAL_CLUSTER_CORES=$((MASTER_COUNT * MASTER_CORES + WORKER_COUNT * WORKER_CORES))
TOTAL_CLUSTER_RAM=$((MASTER_COUNT * MASTER_RAM_GB + WORKER_COUNT * WORKER_RAM_GB))
TOTAL_CLUSTER_STORAGE=$((MASTER_COUNT * MASTER_DISK_GB + WORKER_COUNT * WORKER_DISK_GB))

# Calculate costs
COMPUTE_COST=$(echo "$TOTAL_CLUSTER_CORES * $COST_PER_CORE_MONTHLY" | bc)
MEMORY_COST=$(echo "$TOTAL_CLUSTER_RAM * $COST_PER_GB_RAM_MONTHLY" | bc)
STORAGE_COST=$(echo "$TOTAL_CLUSTER_STORAGE * $COST_PER_GB_STORAGE_MONTHLY" | bc)
POWER_COST=$(echo "$TOTAL_CLUSTER_CORES * $WATTS_PER_CORE * $HOURS_PER_MONTH * $POWER_COST_PER_KWH / 1000" | bc)

TOTAL_MONTHLY_COST=$(echo "$COMPUTE_COST + $MEMORY_COST + $STORAGE_COST + $POWER_COST" | bc)
TOTAL_YEARLY_COST=$(echo "$TOTAL_MONTHLY_COST * 12" | bc)

# Calculate utilization
CPU_UTILIZATION=$(echo "scale=2; $TOTAL_CLUSTER_CORES / $TOTAL_CPU_CORES * 100" | bc)
RAM_UTILIZATION=$(echo "scale=2; $TOTAL_CLUSTER_RAM / $TOTAL_RAM_GB * 100" | bc)
STORAGE_UTILIZATION=$(echo "scale=2; $TOTAL_CLUSTER_STORAGE / ($TOTAL_STORAGE_TB * 1024) * 100" | bc)

# Display results
cat <<REPORT
=== Kubernetes Cluster Cost Estimation ===

Cluster Configuration:
  Masters: $MASTER_COUNT × ${MASTER_CORES}C/${MASTER_RAM_GB}GB/${MASTER_DISK_GB}GB
  Workers: $WORKER_COUNT × ${WORKER_CORES}C/${WORKER_RAM_GB}GB/${WORKER_DISK_GB}GB
  
  Total Cores: $TOTAL_CLUSTER_CORES
  Total RAM: ${TOTAL_CLUSTER_RAM}GB
  Total Storage: ${TOTAL_CLUSTER_STORAGE}GB

Monthly Costs:
  Compute: \$${COMPUTE_COST}
  Memory: \$${MEMORY_COST}
  Storage: \$${STORAGE_COST}
  Power: \$${POWER_COST}
  ─────────────────
  Total: \$${TOTAL_MONTHLY_COST}

Annual Cost: \$${TOTAL_YEARLY_COST}

Resource Utilization:
  CPU: ${CPU_UTILIZATION}%
  RAM: ${RAM_UTILIZATION}%
  Storage: ${STORAGE_UTILIZATION}%

Cost per Node: \$$(echo "$TOTAL_MONTHLY_COST / ($MASTER_COUNT + $WORKER_COUNT)" | bc)
Cost per Core: \$$(echo "$TOTAL_MONTHLY_COST / $TOTAL_CLUSTER_CORES" | bc)
Cost per GB RAM: \$$(echo "$TOTAL_MONTHLY_COST / $TOTAL_CLUSTER_RAM" | bc)

REPORT

# Recommendations
if (( $(echo "$CPU_UTILIZATION > 80" | bc -l) )); then
  echo "⚠️  WARNING: CPU utilization is high. Consider adding Proxmox nodes."
fi

if (( $(echo "$RAM_UTILIZATION > 80" | bc -l) )); then
  echo "⚠️  WARNING: RAM utilization is high. Consider adding memory."
fi

if (( $(echo "$STORAGE_UTILIZATION > 70" | bc -l) )); then
  echo "⚠️  WARNING: Storage utilization is high. Consider adding storage."
fi
EOF

chmod +x cost-calculator.sh
./cost-calculator.sh
```

### Capacity Planning

#### Right-Sizing Workloads

Analyze actual vs requested resources:

```bash
# Install metrics-server if not already present
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check actual vs requested resources
cat <<'EOF' > capacity-analysis.sh
#!/bin/bash

echo "=== Pod Resource Analysis ==="
echo ""

kubectl get pods --all-namespaces -o json | jq -r '
.items[] | 
{
  namespace: .metadata.namespace,
  name: .metadata.name,
  containers: [.spec.containers[] | {
    name: .name,
    cpu_request: .resources.requests.cpu,
    cpu_limit: .resources.limits.cpu,
    mem_request: .resources.requests.memory,
    mem_limit: .resources.limits.memory
  }]
} | 
"\(.namespace)/\(.name): CPU: \(.containers[0].cpu_request) → \(.containers[0].cpu_limit), MEM: \(.containers[0].mem_request) → \(.containers[0].mem_limit)"
' | column -t

echo ""
echo "=== Actual Usage ==="
kubectl top pods --all-namespaces --sort-by=cpu | head -20

echo ""
echo "=== Over-provisioned Pods (>50% unused) ==="
kubectl top pods --all-namespaces -o json | jq -r '
.items[] | 
select(.containers[0].usage.cpu != null) |
{
  namespace: .metadata.namespace,
  name: .metadata.name,
  cpu_usage: .containers[0].usage.cpu,
  mem_usage: .containers[0].usage.memory
}
'
EOF

chmod +x capacity-analysis.sh
./capacity-analysis.sh
```

#### Growth Planning

Project resource needs based on growth:

```bash
cat <<'EOF' > growth-planning.sh
#!/bin/bash

CURRENT_WORKERS=3
CURRENT_CORES_PER_WORKER=4
CURRENT_RAM_PER_WORKER=8

MONTHLY_GROWTH_RATE=10  # Percentage
MONTHS_TO_PROJECT=12

echo "=== Capacity Growth Projection ==="
echo ""
echo "Current Configuration:"
echo "  Workers: $CURRENT_WORKERS"
echo "  Cores per worker: $CURRENT_CORES_PER_WORKER"
echo "  RAM per worker: ${CURRENT_RAM_PER_WORKER}GB"
echo ""

TOTAL_CORES=$((CURRENT_WORKERS * CURRENT_CORES_PER_WORKER))
TOTAL_RAM=$((CURRENT_WORKERS * CURRENT_RAM_PER_WORKER))

echo "Month | Workers | Cores | RAM(GB) | Action"
echo "------|---------|-------|---------|------------------"

for month in $(seq 1 $MONTHS_TO_PROJECT); do
  GROWTH_FACTOR=$(echo "1 + ($MONTHLY_GROWTH_RATE / 100 * $month)" | bc -l)
  NEEDED_CORES=$(echo "$TOTAL_CORES * $GROWTH_FACTOR / 1" | bc)
  NEEDED_RAM=$(echo "$TOTAL_RAM * $GROWTH_FACTOR / 1" | bc)
  NEEDED_WORKERS=$(echo "($NEEDED_CORES + $CURRENT_CORES_PER_WORKER - 1) / $CURRENT_CORES_PER_WORKER" | bc)
  
  if [ $NEEDED_WORKERS -gt $CURRENT_WORKERS ]; then
    ACTION="⚠️  Add $((NEEDED_WORKERS - CURRENT_WORKERS)) worker(s)"
    CURRENT_WORKERS=$NEEDED_WORKERS
  else
    ACTION="✓ Sufficient"
  fi
  
  printf "%5d | %7d | %5d | %7d | %s\n" \
    $month $NEEDED_WORKERS $NEEDED_CORES $NEEDED_RAM "$ACTION"
done

echo ""
echo "Recommendations:"
echo "  - Plan hardware procurement for month $(echo "scale=0; 100 / $MONTHLY_GROWTH_RATE" | bc)"
echo "  - Review capacity quarterly"
echo "  - Monitor utilization trends"
EOF

chmod +x growth-planning.sh
./growth-planning.sh
```

#### Cluster Sizing Recommendations

| Workload Type        | Master Nodes | Master Specs      | Worker Nodes | Worker Specs       | Use Case                 |
| -------------------- | ------------ | ----------------- | ------------ | ------------------ | ------------------------ |
| Development/Testing  | 1            | 2C / 4GB / 20GB   | 2            | 2C / 4GB / 50GB    | Local dev, CI/CD         |
| Small Production     | 3            | 2C / 4GB / 20GB   | 3            | 4C / 8GB / 100GB   | Small apps, < 100 pods   |
| Medium Production    | 3            | 4C / 8GB / 50GB   | 5            | 8C / 16GB / 200GB  | Medium apps, < 500 pods  |
| Large Production     | 5            | 8C / 16GB / 100GB | 10+          | 16C / 32GB / 500GB | Large scale, > 1000 pods |

### Resource Optimization Strategies

```bash
# 1. Implement Horizontal Pod Autoscaling
cat <<'EOF' > hpa-example.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

# 2. Set Resource Quotas per Namespace
cat <<'EOF' > resource-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: development
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
EOF

# 3. Implement Limit Ranges
cat <<'EOF' > limit-range.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
spec:
  limits:
  - max:
      cpu: "2"
      memory: 4Gi
    min:
      cpu: 50m
      memory: 64Mi
    default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
EOF

# 4. Use Vertical Pod Autoscaler for recommendations
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/vertical-pod-autoscaler/deploy/vpa-v1-crd-gen.yaml

# 5. Monitor and act on recommendations
kubectl describe vpa <vpa-name>
```

---

## Performance Optimization

### VM Performance

```text
# Optimized disk configuration for better I/O
disks {
  scsi {
    scsi0 {
      disk {
        storage    = "nvme-storage"  # Use faster storage
        size       = "50G"
        cache      = "writethrough"
        iothread   = 1
        discard    = "on"
        ssd        = 1
      }
    }
  }
}

# Enable NUMA for larger VMs
numa = true
```

### Network Performance

```text
network {
  id       = 0
  bridge   = "vmbr0"
  model    = "virtio"
  queues   = 4        # Multi-queue support
  mtu      = 9000     # Jumbo frames if supported
}
```

### Kubernetes Optimization

- Use node affinity for workload placement
- Implement resource quotas and limits
- Configure horizontal pod autoscaling
- Use persistent volume claims for storage

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
