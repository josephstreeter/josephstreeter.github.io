---
title: Container Orchestration
description: Comprehensive guide to container orchestration with Kubernetes, Docker Swarm, and modern deployment strategies
author: Joseph Streeter
date: 2024-01-15
tags: [containers, orchestration, kubernetes, docker-swarm, deployment, scaling]
---

Container orchestration automates the deployment, management, scaling, and networking of containers across clusters of hosts. This guide covers modern orchestration platforms and deployment strategies for production environments.

## Container Orchestration Overview

### What is Container Orchestration?

Container orchestration platforms manage the lifecycle of containers, especially in large, dynamic environments. They handle:

- **Container deployment** and scheduling
- **Service discovery** and load balancing
- **Scaling** applications up and down
- **Health monitoring** and self-healing
- **Resource management** and optimization
- **Network** and **storage** management

```text
┌─────────────────────────────────────────────────────────────────┐
│                Container Orchestration Stack                    │
├─────────────────────────────────────────────────────────────────┤
│  Applications    │ Microservices, Web Apps, Databases         │
│  Orchestration   │ Kubernetes, Docker Swarm, Nomad            │
│  Container Runtime│ Docker, containerd, CRI-O                 │
│  Host OS         │ Linux, Windows Server                       │
│  Infrastructure  │ Physical, Virtual, Cloud                    │
└─────────────────────────────────────────────────────────────────┘
```

### Orchestration Platforms Comparison

| Platform | Complexity | Scalability | Ecosystem | Best For |
|----------|------------|-------------|-----------|----------|
| **Kubernetes** | High | Excellent | Massive | Enterprise, complex apps |
| **Docker Swarm** | Low | Good | Docker-focused | Simple deployments |
| **Nomad** | Medium | Excellent | HashiCorp stack | Multi-workload |
| **Amazon ECS** | Medium | Excellent | AWS services | AWS-native apps |

## Kubernetes (K8s)

### Kubernetes Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                           │
├─────────────────────────────────────────────────────────────────┤
│  Control Plane                                                  │
│  ├── API Server      │ REST API for cluster management         │
│  ├── etcd            │ Distributed key-value store             │
│  ├── Scheduler       │ Assigns pods to nodes                   │
│  └── Controller Mgr  │ Manages cluster state                   │
│                                                                 │
│  Worker Nodes                                                   │
│  ├── kubelet         │ Node agent                              │
│  ├── kube-proxy      │ Network proxy                           │
│  └── Container Runtime│ Docker, containerd                     │
└─────────────────────────────────────────────────────────────────┘
```

### Installing Kubernetes

#### Local Development with Minikube

```bash
# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start local cluster
minikube start --driver=docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl cluster-info
kubectl get nodes
```

#### Production Cluster with kubeadm

```bash
# On all nodes - install container runtime
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

# Install kubeadm, kubelet, kubectl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# On master node - initialize cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl for user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install pod network (Flannel)
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Join worker nodes (run on each worker)
# sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

### Essential Kubernetes Objects

#### Pods

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

#### Deployments

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
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
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### Services

```yaml
# service.yaml
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

#### ConfigMaps and Secrets

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_url: "postgres://localhost:5432/mydb"
  redis_url: "redis://localhost:6379"
  app_env: "production"

---
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  db_password: cGFzc3dvcmQxMjM=  # base64 encoded
  api_key: YWJjZGVmZ2hpams=        # base64 encoded
```

### Application Deployment Example

```yaml
# Complete application stack
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: myapp:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database_url
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db_password
        volumeMounts:
        - name: app-storage
          mountPath: /app/data
      volumes:
      - name: app-storage
        persistentVolumeClaim:
          claimName: app-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

### Kubernetes Management Commands

```bash
# Cluster information
kubectl cluster-info
kubectl get nodes
kubectl describe node <node-name>

# Pod management
kubectl get pods
kubectl get pods -n kube-system
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Deployment management
kubectl create deployment nginx --image=nginx
kubectl get deployments
kubectl scale deployment nginx --replicas=5
kubectl rollout status deployment nginx
kubectl rollout history deployment nginx
kubectl rollout undo deployment nginx

# Service management
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get services
kubectl describe service nginx

# ConfigMap and Secret management
kubectl create configmap app-config --from-literal=key1=value1
kubectl create secret generic app-secret --from-literal=password=secret123
kubectl get configmaps
kubectl get secrets

# Apply manifests
kubectl apply -f deployment.yaml
kubectl apply -f .
kubectl delete -f deployment.yaml

# Namespace management
kubectl create namespace production
kubectl get namespaces
kubectl config set-context --current --namespace=production
```

## Docker Swarm

### Docker Swarm Setup

```bash
# Initialize swarm on manager node
docker swarm init --advertise-addr <manager-ip>

# Join worker nodes
docker swarm join --token <worker-token> <manager-ip>:2377

# Add additional managers
docker swarm join-token manager

# View swarm nodes
docker node ls

# Promote worker to manager
docker node promote <node-id>
```

### Docker Swarm Services

```bash
# Create service
docker service create --name web --replicas 3 --publish 80:80 nginx

# List services
docker service ls

# Inspect service
docker service inspect web

# Scale service
docker service scale web=5

# Update service
docker service update --image nginx:1.21 web

# Remove service
docker service rm web
```

### Docker Stack (Compose for Swarm)

```yaml
# docker-stack.yml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    networks:
      - frontend

  app:
    image: myapp:latest
    deploy:
      replicas: 2
      placement:
        constraints:
          - node.role == worker
    networks:
      - frontend
      - backend
    secrets:
      - db_password
    configs:
      - app_config

  db:
    image: postgres:13
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.labels.database == true
    networks:
      - backend
    volumes:
      - db_data:/var/lib/postgresql/data
    secrets:
      - db_password

networks:
  frontend:
    driver: overlay
  backend:
    driver: overlay
    internal: true

volumes:
  db_data:
    driver: local

secrets:
  db_password:
    external: true

configs:
  app_config:
    external: true
```

```bash
# Deploy stack
docker stack deploy -c docker-stack.yml myapp

# List stacks
docker stack ls

# List stack services
docker stack services myapp

# Remove stack
docker stack rm myapp

# Create secrets and configs
echo "password123" | docker secret create db_password -
docker config create app_config app.conf
```

## Container Networking

### Kubernetes Networking

```yaml
# Network Policy example
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-api
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 8080
```

### Service Mesh with Istio

```bash
# Install Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Install Istio on cluster
istioctl install --set values.defaultRevision=default

# Enable sidecar injection
kubectl label namespace default istio-injection=enabled

# Install addons
kubectl apply -f samples/addons
```

## Storage and Persistence

### Persistent Volumes

```yaml
# Persistent Volume
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-storage
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: fast-ssd
  hostPath:
    path: /data/pv-storage

---
# Persistent Volume Claim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: fast-ssd
```

### StatefulSets for Databases

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

## Monitoring and Logging

### Prometheus and Grafana

```yaml
# prometheus-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        - name: storage
          mountPath: /prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
      - name: storage
        emptyDir: {}
```

### Centralized Logging with ELK Stack

```yaml
# elasticsearch.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
spec:
  serviceName: elasticsearch
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:7.15.0
        env:
        - name: discovery.type
          value: single-node
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        ports:
        - containerPort: 9200
        volumeMounts:
        - name: elasticsearch-storage
          mountPath: /usr/share/elasticsearch/data
  volumeClaimTemplates:
  - metadata:
      name: elasticsearch-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

## Best Practices

### Security

```yaml
# Security Context example
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
  - name: app
    image: myapp:latest
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

### Resource Management

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: production
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "10"
    persistentvolumeclaims: "5"

---
apiVersion: v1
kind: LimitRange
metadata:
  name: limit-range
  namespace: production
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
```

## Related Topics

- [Container Security](../security/index.md)
- [Docker Quickstart](../docker/quickstart.md)
- [Working with Docker Containers](../docker/containers.md)
- [Infrastructure Monitoring](../../monitoring/index.md)
