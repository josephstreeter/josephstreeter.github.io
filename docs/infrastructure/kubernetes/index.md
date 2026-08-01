---
title: "Kubernetes"
description: "Complete guide to Kubernetes container orchestration"
tags: ["kubernetes", "containers", "orchestration", "devops", "microservices"]
category: "infrastructure"
difficulty: "advanced"
last_updated: "2025-01-20"
---

## Kubernetes

Kubernetes (K8s) is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. Originally developed by Google, it has become the de facto standard for container orchestration in production environments.

## What is Kubernetes?

Kubernetes provides a platform for:

- **Container orchestration** - Automatically deploy and manage containers
- **Service discovery** - Enable communication between application components
- **Load balancing** - Distribute traffic across multiple container instances
- **Auto-scaling** - Scale applications based on demand
- **Self-healing** - Automatically restart failed containers
- **Rolling updates** - Deploy new versions without downtime
- **Resource management** - Efficiently allocate compute resources

## Key Benefits

- **High availability** - Built-in redundancy and failover capabilities
- **Scalability** - Scale from single containers to thousands of nodes
- **Portability** - Run anywhere: on-premises, cloud, or hybrid
- **Declarative configuration** - Define desired state, Kubernetes maintains it
- **Extensibility** - Rich ecosystem of tools and integrations
- **Cost optimization** - Efficient resource utilization

## Core Concepts

### Pods

The smallest deployable unit in Kubernetes, containing one or more containers.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
```

### Services

Provide stable network endpoints for accessing pods.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

### Deployments

Manage replica sets and provide declarative updates for pods.

```yaml
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
        image: nginx:1.21
        ports:
        - containerPort: 80
```

### ConfigMaps and Secrets

Manage configuration data and sensitive information.

```yaml
# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_url: "postgresql://localhost:5432/myapp"
  debug: "true"

---
# Secret
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # base64 encoded
```

## Kubernetes Architecture

### Control Plane Components

- **API Server** - Central management point for all cluster operations
- **etcd** - Distributed key-value store for cluster state
- **Scheduler** - Assigns pods to nodes based on resource requirements
- **Controller Manager** - Runs controllers that manage cluster state

### Node Components

- **kubelet** - Agent that runs on each node and manages containers
- **kube-proxy** - Network proxy that maintains network rules
- **Container Runtime** - Software that runs containers (Docker, containerd, CRI-O)

### Cluster Architecture Diagram

```text
┌─────────────────────────────────────────────────────────┐
│                    Control Plane                        │
├─────────────┬─────────────┬─────────────┬──────────────┤
│  API Server │    etcd     │  Scheduler  │  Controller  │
│             │             │             │   Manager    │
└─────────────┴─────────────┴─────────────┴──────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
    ┌───────▼─────┐ ┌───────▼─────┐ ┌───────▼─────┐
    │   Node 1    │ │   Node 2    │ │   Node 3    │
    │             │ │             │ │             │
    │ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │
    │ │ kubelet │ │ │ │ kubelet │ │ │ │ kubelet │ │
    │ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │
    │ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │
    │ │kube-proxy│ │ │ │kube-proxy│ │ │ │kube-proxy│ │
    │ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │
    │ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │
    │ │Container│ │ │ │Container│ │ │ │Container│ │
    │ │Runtime  │ │ │ │Runtime  │ │ │ │Runtime  │ │
    │ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │
    └─────────────┘ └─────────────┘ └─────────────┘
```

## Installation Options

### Local Development

#### Minikube

Single-node cluster for local development:

```bash
# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster
minikube start

# Check status
minikube status

# Access dashboard
minikube dashboard
```

#### Kind (Kubernetes in Docker)

Multi-node clusters using Docker containers:

```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster --name dev-cluster

# Load custom config
kind create cluster --config kind-config.yaml
```

Kind configuration example:

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

### Production Clusters

#### Managed Services

- **Google GKE** - Google Kubernetes Engine
- **Amazon EKS** - Elastic Kubernetes Service
- **Azure AKS** - Azure Kubernetes Service
- **DigitalOcean DOKS** - DigitalOcean Kubernetes

#### Self-Managed

- **kubeadm** - Official cluster bootstrapping tool
- **Kubespray** - Ansible-based cluster deployment
- **Rancher** - Complete container management platform

### kubectl Installation

```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client

# Set up autocompletion
echo 'source <(kubectl completion bash)' >>~/.bashrc
```

## Basic Operations

### Cluster Management

```bash
# Check cluster info
kubectl cluster-info

# View nodes
kubectl get nodes

# Describe node details
kubectl describe node <node-name>

# Check cluster components
kubectl get componentstatuses
```

### Working with Resources

```bash
# Create resources
kubectl apply -f deployment.yaml

# Get resources
kubectl get pods
kubectl get services
kubectl get deployments

# Describe resources
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Execute commands in pods
kubectl exec -it <pod-name> -- /bin/bash

# Port forwarding
kubectl port-forward pod/<pod-name> 8080:80

# Delete resources
kubectl delete -f deployment.yaml
kubectl delete pod <pod-name>
```

### Namespace Management

```bash
# Create namespace
kubectl create namespace development

# List namespaces
kubectl get namespaces

# Set default namespace
kubectl config set-context --current --namespace=development

# View resources in namespace
kubectl get pods -n development
```

## Example Application Deployment

### Complete Web Application Stack

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: webapp

---
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: webapp-config
  namespace: webapp
data:
  DATABASE_HOST: "postgresql-service"
  DATABASE_PORT: "5432"
  DATABASE_NAME: "webapp"

---
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: webapp-secrets
  namespace: webapp
type: Opaque
data:
  DATABASE_PASSWORD: cGFzc3dvcmQxMjM=
  JWT_SECRET: bXlzZWNyZXRrZXk=

---
# postgresql-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  namespace: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:13
        env:
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: DATABASE_NAME
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: DATABASE_PASSWORD
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
# postgresql-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgresql-service
  namespace: webapp
spec:
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432

---
# webapp-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: myapp:latest
        env:
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: DATABASE_HOST
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: DATABASE_PASSWORD
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5

---
# webapp-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  namespace: webapp
spec:
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer

---
# persistent-volume-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: webapp
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### Deploy the Application

```bash
# Apply all configurations
kubectl apply -f webapp-stack.yaml

# Monitor deployment
kubectl get pods -n webapp -w

# Check services
kubectl get services -n webapp

# View application logs
kubectl logs -l app=webapp -n webapp

# Scale application
kubectl scale deployment webapp --replicas=5 -n webapp
```

## Best Practices

### Resource Management

```yaml
# Always specify resource requests and limits
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Health Checks

```yaml
# Implement liveness and readiness probes
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Security

```yaml
# Use non-root users
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000

# Enable read-only root filesystem
securityContext:
  readOnlyRootFilesystem: true
```

### Labels and Annotations

```yaml
metadata:
  labels:
    app: webapp
    version: v1.2.3
    environment: production
    tier: frontend
  annotations:
    description: "Main web application"
    maintainer: "team@company.com"
```

## Monitoring and Troubleshooting

### Common kubectl Commands

```bash
# Get events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource usage
kubectl top nodes
kubectl top pods

# Debug failing pods
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous

# Debug networking
kubectl exec -it <pod-name> -- nslookup <service-name>

# Check resource quotas
kubectl describe resourcequota -n <namespace>
```

### Common Issues and Solutions

1. **Pod Stuck in Pending State**

   ```bash
   # Check node resources
   kubectl describe nodes
   
   # Check pod events
   kubectl describe pod <pod-name>
   ```

2. **Image Pull Errors**

   ```bash
   # Verify image exists
   docker pull <image-name>
   
   # Check image pull secrets
   kubectl get secrets
   ```

3. **Service Not Accessible**

   ```bash
   # Check service endpoints
   kubectl get endpoints
   
   # Verify selector labels
   kubectl get pods --show-labels
   ```

## Next Steps

- **Advanced Topics**: StatefulSets, DaemonSets, Jobs, CronJobs
- **Networking**: Ingress Controllers, Network Policies
- **Storage**: Persistent Volumes, Storage Classes
- **Security**: RBAC, Pod Security Policies, Network Policies
- **Monitoring**: Prometheus, Grafana, Jaeger
- **CI/CD**: GitOps with ArgoCD, Tekton Pipelines
- **Service Mesh**: Istio, Linkerd

## Additional Resources

- **Official Documentation**: [kubernetes.io](https://kubernetes.io/docs/index.md)
- **Interactive Tutorial**: [katacoda.com](https://katacoda.com/courses/kubernetes)
- **Practice Platform**: [Play with Kubernetes](https://labs.play-with-k8s.com/index.md)
- **Community**: [CNCF Slack](https://slack.cncf.io/index.md)
- **Training**: [Certified Kubernetes Administrator (CKA)](https://www.cncf.io/certification/cka/index.md)

This guide provides a solid foundation for understanding and working with Kubernetes. Start with local development using Minikube or Kind, then progress to more complex deployments as you gain experience.
