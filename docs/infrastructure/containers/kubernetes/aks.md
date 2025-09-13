---
title: "Azure Kubernetes Service (AKS)"
description: "Complete guide to Azure Kubernetes Service deployment and management"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Azure Kubernetes Service (AKS)

Azure Kubernetes Service (AKS) is a managed Kubernetes service that simplifies deploying, managing, and operating Kubernetes clusters on Azure. This guide covers everything from initial setup to advanced cluster management.

## Overview

AKS reduces the complexity and operational overhead of managing Kubernetes by offloading much of the responsibility to Azure. Azure handles critical tasks like health monitoring, maintenance, and patching for you.

### Key Benefits

- **Managed Control Plane**: Azure manages the Kubernetes master components
- **Built-in Security**: Integration with Azure Active Directory and Azure RBAC
- **Scaling**: Automatic cluster scaling and node pool management
- **Monitoring**: Integration with Azure Monitor and Log Analytics
- **Cost Optimization**: Pay only for worker nodes, control plane is free

## Getting Started

### Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and configured
- kubectl command-line tool
- Basic understanding of Kubernetes concepts

### Quick Setup

```bash
# Create resource group
az group create --name myResourceGroup --location eastus

# Create AKS cluster
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --node-count 3 \
    --enable-addons monitoring \
    --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster

# Verify connection
kubectl get nodes
```

## Cluster Configuration

### Node Pools

AKS supports multiple node pools with different VM sizes and configurations:

```bash
# Add a new node pool
az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --node-count 3 \
    --node-vm-size Standard_DS3_v2

# Scale node pool
az aks nodepool scale \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --node-count 5
```

### Networking

Configure cluster networking based on your requirements:

```bash
# Create AKS with Azure CNI
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --network-plugin azure \
    --vnet-subnet-id <subnet-id> \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24
```

## Security Configuration

### Azure Active Directory Integration

```bash
# Create AKS with AAD integration
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --enable-aad \
    --aad-admin-group-object-ids <group-object-id>
```

### Role-Based Access Control (RBAC)

```yaml
# rbac-example.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: user@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

## Monitoring and Logging

### Azure Monitor Integration

```bash
# Enable monitoring on existing cluster
az aks enable-addons \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --addons monitoring
```

### Log Analytics Queries

Common KQL queries for AKS monitoring:

```kql
// Pod status overview
KubePodInventory
| where TimeGenerated > ago(1h)
| summarize count() by PodStatus

// Node resource utilization
Perf
| where ObjectName == "K8SNode"
| where CounterName == "cpuUsageNanoCores"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer
```

## Application Deployment

### Sample Application

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

Deploy the application:

```bash
kubectl apply -f nginx-deployment.yaml
kubectl get services --watch
```

## Scaling and Optimization

### Horizontal Pod Autoscaler

```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

### Cluster Autoscaler

```bash
# Enable cluster autoscaler
az aks update \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 10
```

## Troubleshooting

### Common Issues

1. **Pod stuck in Pending state**

   ```bash
   kubectl describe pod <pod-name>
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

2. **Network connectivity issues**

   ```bash
   kubectl exec -it <pod-name> -- nslookup kubernetes.default.svc.cluster.local
   ```

3. **Resource constraints**

   ```bash
   kubectl top nodes
   kubectl top pods
   ```

### Debugging Commands

```bash
# Get cluster information
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# View cluster events
kubectl get events --all-namespaces --sort-by=.metadata.creationTimestamp

# Check resource quotas
kubectl describe resourcequota --all-namespaces
```

## Best Practices

### Resource Management

- Set resource requests and limits for all containers
- Use namespaces to organize applications
- Implement proper resource quotas

### Security

- Use Azure Active Directory integration
- Implement network policies
- Regularly update cluster and node images
- Use Azure Key Vault for secrets management

### Monitoring

- Enable Azure Monitor for containers
- Set up proper alerting rules
- Monitor cluster and application metrics

## Related Documentation

- **[Kubernetes](index.md)** - Core Kubernetes concepts
- **[Container Registry](../docker/index.md)** - Container image management
- **[Monitoring](../../monitoring/index.md)** - Infrastructure monitoring

---

*This guide provides comprehensive coverage of AKS from basic setup to advanced enterprise scenarios. Each section includes practical examples and best practices for production deployments.*
