---
title: "Four Beginner-Friendly Kubernetes Projects to Build Confidence"
description: "Hands-on Kubernetes projects for home labs and learning by doing, based on Christian Lempa's beginner-friendly approach"
tags: ["kubernetes", "beginner", "projects", "hands-on", "learning", "containers", "homelab"]
category: "infrastructure"
difficulty: "beginner"
last_updated: "2025-07-26"
author: "Joseph Streeter"
---

Starting your Kubernetes journey can feel overwhelming, but hands-on projects are the best way to build practical skills. This guide walks through four beginner-friendly projects that build confidence through real-world practice, especially suitable for home labs and learning by doing.

> **Based on Christian Lempa's approach**: These projects emphasize hands-on experience from day one, with incremental learning that builds on each previous project, creating a realistic learning environment that reflects real-world scenarios.

## Prerequisites

Before starting these projects, ensure you have:

- **Home lab environment** - Proxmox VE, VMware, or similar virtualization platform
- **Multiple VMs** - At least 2-3 virtual machines for a proper cluster setup
- **kubectl installed** - [Installation guide](index.md#kubectl-installation)
- **Basic Docker knowledge** - Understanding of containers and images
- **Text editor** - VS Code, Vim, or your preferred editor
- **Network understanding** - Basic knowledge of IP addressing and DNS

## Why These Projects Matter

### 🛠️ Hands-On Experience from Day One

Rather than just theoretical concepts, these projects emphasize real-world practice—from bootstrapping a cluster to deploying real applications with ingress support. This builds familiarity with both the infrastructure and object-level Kubernetes concepts (Pods, Deployments, Services, Ingress).

### 📈 Incremental Learning Path

Each project builds on the previous. You begin with setting up infrastructure, then learn how to route traffic, deploy apps, and finally use tools for monitoring and maintenance. This structure is ideal for structured learning in a home lab.

### 🏠 Realistic Learning Environment

Running Kubernetes on VMs reflects many real-world scenarios (DIY homelab, cloud dev zones). You'll face practical issues like IP assignment, resource allocation, and pod scheduling—precisely the types of problems engineers confront in production.

## Project 1: Self-Hosted Kubernetes Cluster on Virtual Machines

**Difficulty**: ⭐⭐ (Beginner-Intermediate)  
**Time**: 2-3 hours  
**Learning Goals**: Cluster architecture, IP addressing, node management, VM-based deployment

This project gives you hands-on exposure to cluster architecture, IP addressing, and basic node management using an environment like Proxmox VE to create your own cluster across multiple VMs.

### Step 1: Prepare Your Virtual Environment

Set up your virtualization environment (we'll use Proxmox VE as recommended by Christian Lempa):

```bash
# Minimum requirements for your home lab:
# - 1 Controller node: 2 CPU, 4GB RAM, 40GB disk
# - 2 Worker nodes: 2 CPU, 2GB RAM, 20GB disk each
# - Network: Bridge network with internet access
```

### Step 2: Create Kubernetes VMs

Create three Ubuntu Server VMs:

```yaml
# VM Configuration for each node
VM Names:
  - k8s-controller-01 (192.168.1.10)
  - k8s-worker-01 (192.168.1.11)  
  - k8s-worker-02 (192.168.1.12)

Network Configuration:
  - Bridge: vmbr0 
  - VLAN: None (or your preferred VLAN)
  - Firewall: Disabled initially for learning
```

### Step 3: Install Container Runtime and Kubernetes

On all nodes, install the required components:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install containerd
sudo apt install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Install kubeadm, kubelet, and kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### Step 4: Initialize the Controller Node

On the controller node (k8s-controller-01):

```bash
# Initialize the cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.1.10

# Configure kubectl for regular user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel network plugin
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

### Step 5: Join Worker Nodes

Copy the join command from the controller initialization and run on worker nodes:

```bash
# Example join command (use the actual command from your controller)
sudo kubeadm join 192.168.1.10:6443 --token abc123.xyz789 \
    --discovery-token-ca-cert-hash sha256:your-actual-hash-here
```

### Step 6: Verify Your Cluster

```bash
# Check cluster status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Test cluster networking
kubectl run test-pod --image=nginx --restart=Never
kubectl get pods
kubectl delete pod test-pod
```

### Project 1 Key Learnings

- Setting up multi-node Kubernetes clusters from scratch
- Understanding cluster architecture and component interaction
- Managing VM-based infrastructure for Kubernetes
- Network configuration and troubleshooting
- Basic cluster validation and health checks

## Project 2: Install a Load Balancer & Ingress Controller

**Difficulty**: ⭐⭐⭐ (Intermediate)  
**Time**: 45 minutes  
**Learning Goals**: Network automation, DNS routing, HTTP traffic management, Ingress rules

Add networking automation with NGINX Ingress Controller to learn how to route external traffic into cluster services. This project covers DNS, HTTP routing, and exposes applications through configurable ingress rules.

### Step 1: Install MetalLB Load Balancer

Since you're running on VMs (not a cloud provider), you need MetalLB to provide LoadBalancer services:

```bash
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml

# Wait for MetalLB to be ready
kubectl wait --namespace metallb-system 
    --for=condition=ready pod 
    --selector=app=metallb 
    --timeout=90s
```

### Step 2: Configure MetalLB IP Pool

Create an IP pool for your home network:

```yaml
# metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.100-192.168.1.110  # Adjust to your network range

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
```

```bash
# Apply MetalLB configuration
kubectl apply -f metallb-config.yaml
```

### Step 3: Install NGINX Ingress Controller

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Wait for the ingress controller to be ready
kubectl wait --namespace ingress-nginx 
  --for=condition=ready pod 
  --selector=app.kubernetes.io/component=controller 
  --timeout=120s

# Check the LoadBalancer IP
kubectl get services -n ingress-nginx
```

### Step 4: Create a Test Application with Ingress

```yaml
# test-app-with-ingress.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-app
  template:
    metadata:
      labels:
        app: hello-app
    spec:
      containers:
      - name: hello-app
        image: hashicorp/http-echo:0.2.3
        args:
        - "-text=Hello from Kubernetes Ingress!"
        ports:
        - containerPort: 5678

---
apiVersion: v1
kind: Service
metadata:
  name: hello-service
spec:
  selector:
    app: hello-app
  ports:
  - port: 80
    targetPort: 5678

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: / 
spec:
  ingressClassName: nginx
  rules:
  - host: hello.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-service
            port:
              number: 80
```

### Step 5: Test the Ingress

```bash
# Deploy the application
kubectl apply -f test-app-with-ingress.yaml

# Get the ingress controller's external IP
kubectl get services -n ingress-nginx

# Add to your local hosts file (replace with actual LoadBalancer IP)
echo "192.168.1.100 hello.local" | sudo tee -a /etc/hosts

# Test the ingress
curl http://hello.local
# or visit http://hello.local in your browser
```

### Step 6: Create Multiple Applications with Path-Based Routing

```yaml
# multi-app-ingress.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: hashicorp/http-echo:0.2.3
        args: ["-text=App 1 - User Service"]
        ports:
        - containerPort: 5678

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: hashicorp/http-echo:0.2.3
        args: ["-text=App 2 - Order Service"]
        ports:
        - containerPort: 5678

---
apiVersion: v1
kind: Service
metadata:
  name: app1-service
spec:
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 5678

---
apiVersion: v1
kind: Service
metadata:
  name: app2-service
spec:
  selector:
    app: app2
  ports:
  - port: 80
    targetPort: 5678

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  ingressClassName: nginx
  rules:
  - host: apps.local
    http:
      paths:
      - path: /users/(.*)
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
      - path: /orders/(.*)
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

### Step 7: Test Path-Based Routing

```bash
# Deploy multi-app setup
kubectl apply -f multi-app-ingress.yaml

# Add to hosts file
echo "192.168.1.100 apps.local" | sudo tee -a /etc/hosts

# Test different paths
curl http://apps.local/users/
curl http://apps.local/orders/
```

### Ingress and Load Balancer Key Learnings

- Installing and configuring MetalLB for on-premises LoadBalancer services
- Setting up NGINX Ingress Controller for HTTP/HTTPS routing
- Creating ingress rules for host-based and path-based routing
- Understanding DNS configuration and /etc/hosts management
- Network troubleshooting in Kubernetes environments

## Project 3: Deploy Self-Hosted Web Applications

**Difficulty**: ⭐⭐⭐ (Intermediate)  
**Time**: 60 minutes  
**Learning Goals**: Manifest writing, scaling, updates, self-healing behavior

Host simple applications (static site, CMS, or microservice) on your locally managed cluster. Practice writing manifests (Deployment, Service, Ingress), scaling pods, and managing updates. Witness Kubernetes self-healing by killing pods and observing auto-recreation behavior.

### Step 1: Deploy a Static Website (NGINX)

```yaml
# static-website.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: website-content
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>My Kubernetes Website</title>
        <style>
            body { font-family: Arial; background: #f0f0f0; margin: 40px; }
            .container { background: white; padding: 40px; border-radius: 8px; }
            .header { color: #326ce5; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1 class="header">Welcome to My Kubernetes Website!</h1>
            <p>This static website is running on Kubernetes.</p>
            <p>Pod hostname: <span id="hostname"></span></p>
        </div>
        <script>
            document.getElementById('hostname').textContent = window.location.hostname;
        </script>
    </body>
    </html>

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: static-website
  labels:
    app: static-website
spec:
  replicas: 3
  selector:
    matchLabels:
      app: static-website
  template:
    metadata:
      labels:
        app: static-website
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: website-content
          mountPath: /usr/share/nginx/html
        resources:
          requests:
            memory: "32Mi"
            cpu: "50m"
          limits:
            memory: "64Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
      volumes:
      - name: website-content
        configMap:
          name: website-content

---
apiVersion: v1
kind: Service
metadata:
  name: static-website-service
spec:
  selector:
    app: static-website
  ports:
  - port: 80
    targetPort: 80

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: static-website-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: mywebsite.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: static-website-service
            port:
              number: 80
```

### Step 2: Deploy WordPress CMS

```yaml
# wordpress-stack.yaml
apiVersion: v1
kind: Secret
metadata:
  name: wordpress-secrets
type: Opaque
data:
  mysql-root-password: cm9vdHBhc3N3b3Jk  # rootpassword
  mysql-password: d29yZHByZXNz          # wordpress

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: wordpress-secrets
              key: mysql-root-password
        - name: MYSQL_DATABASE
          value: wordpress
        - name: MYSQL_USER
          value: wordpress
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: wordpress-secrets
              key: mysql-password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  selector:
    app: mysql
  ports:
  - port: 3306

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:php8.0-apache
        env:
        - name: WORDPRESS_DB_HOST
          value: mysql-service:3306
        - name: WORDPRESS_DB_NAME
          value: wordpress
        - name: WORDPRESS_DB_USER
          value: wordpress
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: wordpress-secrets
              key: mysql-password
        ports:
        - containerPort: 80
        volumeMounts:
        - name: wordpress-storage
          mountPath: /var/www/html
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "300m"
        livenessProbe:
          httpGet:
            path: /wp-admin/install.php
            port: 80
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /wp-admin/install.php
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
      volumes:
      - name: wordpress-storage
        persistentVolumeClaim:
          claimName: wordpress-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-service
spec:
  selector:
    app: wordpress
  ports:
  - port: 80

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: blog.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wordpress-service
            port:
              number: 80
```

### Step 3: Deploy and Test Applications

```bash
# Deploy static website
kubectl apply -f static-website.yaml

# Deploy WordPress
kubectl apply -f wordpress-stack.yaml

# Add hosts entries
echo "192.168.1.100 mywebsite.local" | sudo tee -a /etc/hosts
echo "192.168.1.100 blog.local" | sudo tee -a /etc/hosts

# Check deployments
kubectl get deployments
kubectl get pods
kubectl get services
kubectl get ingress

# Test websites
curl http://mywebsite.local
curl http://blog.local
```

### Step 4: Practice Scaling Operations

```bash
# Scale the static website
kubectl scale deployment static-website --replicas=5

# Watch the scaling in action
kubectl get pods -l app=static-website -w

# Scale down
kubectl scale deployment static-website --replicas=2
```

### Step 5: Test Self-Healing Behavior

```bash
# List running pods
kubectl get pods -l app=static-website

# Delete a pod manually (Kubernetes will recreate it)
kubectl delete pod <pod-name>

# Watch self-healing in action
kubectl get pods -l app=static-website -w

# Check deployment events
kubectl describe deployment static-website
```

### Step 6: Perform Rolling Updates

```bash
# Update the static website image
kubectl set image deployment/static-website nginx=nginx:1.22-alpine

# Watch the rolling update
kubectl rollout status deployment/static-website

# Check rollout history
kubectl rollout history deployment/static-website

# Rollback if needed
kubectl rollout undo deployment/static-website
```

### Step 7: Test Load Distribution

```bash
# Create a simple load test
for i in {1..50}; do
  curl -s http://mywebsite.local | grep hostname
  sleep 0.1
done

# You should see requests distributed across different pods
```

### Self-Hosted Web Apps Key Learnings

- Writing comprehensive Kubernetes manifests (Deployment, Service, Ingress)
- Using ConfigMaps to inject custom content
- Managing persistent storage with PVCs
- Implementing health checks for reliability
- Scaling applications manually and observing behavior
- Witnessing Kubernetes self-healing capabilities
- Performing rolling updates and rollbacks
- Understanding load distribution across pods

## Project 4: Explore Kubernetes Management Tools

**Difficulty**: ⭐⭐⭐⭐ (Advanced Beginner)  
**Time**: 45 minutes  
**Learning Goals**: GUI tools, dashboards, cluster monitoring, visualization

This project introduces GUI tools and third-party dashboards for easier cluster oversight. Gain comfort with continuous maintenance, cluster monitoring, and visualization.

### Step 1: Install Kubernetes Dashboard

```bash
# Install the official Kubernetes Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create a service account for dashboard access
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard

# Create cluster role binding
kubectl create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:dashboard-admin

# Get the token for login
kubectl -n kubernetes-dashboard create token dashboard-admin

# Start kubectl proxy
kubectl proxy &

# Access dashboard at:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### Step 2: Install K9s Terminal Dashboard

```bash
# Install K9s (terminal-based dashboard)
# On Ubuntu/Debian:
wget https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz
tar -xzf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/

# Run K9s
k9s

# K9s keyboard shortcuts:
# - 0: Show all namespaces
# - :pod: Go to pods view
# - :svc: Go to services view
# - :deploy: Go to deployments view
# - d: Describe resource
# - l: View logs
# - e: Edit resource
# - ctrl+d: Delete resource
```

### Step 3: Deploy Portainer for Container Management

```yaml
# portainer.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: portainer

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: portainer-sa
  namespace: portainer

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: portainer-crb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: portainer-sa
  namespace: portainer

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: portainer-pvc
  namespace: portainer
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portainer
  namespace: portainer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: portainer
  template:
    metadata:
      labels:
        app: portainer
    spec:
      serviceAccountName: portainer-sa
      containers:
      - name: portainer
        image: portainer/portainer-ce:latest
        ports:
        - containerPort: 9000
        - containerPort: 8000
        volumeMounts:
        - name: portainer-data
          mountPath: /data
        env:
        - name: PORTAINER_K8S_MODE
          value: "true"
      volumes:
      - name: portainer-data
        persistentVolumeClaim:
          claimName: portainer-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: portainer-service
  namespace: portainer
spec:
  selector:
    app: portainer
  ports:
  - name: web
    port: 9000
    targetPort: 9000
  - name: edge
    port: 8000
    targetPort: 8000
  type: LoadBalancer

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: portainer-ingress
  namespace: portainer
spec:
  ingressClassName: nginx
  rules:
  - host: portainer.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: portainer-service
            port:
              number: 9000
```

### Step 4: Install Lens (Desktop Application)

```bash
# Download and install Lens IDE (runs on your local machine)
# Visit https://k8slens.dev/ and download for your OS

# Or use snap on Ubuntu:
sudo snap install kontena-lens --classic

# Configure Lens:
# 1. Open Lens
# 2. Add cluster by importing your kubeconfig
# 3. Navigate to File > Preferences > Kubernetes to add your cluster
```

### Step 5: Deploy Simple Monitoring with Prometheus and Grafana

```yaml
# monitoring-stack.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
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
        args:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus'
        - '--web.console.libraries=/usr/share/prometheus/console_libraries'
        - '--web.console.templates=/usr/share/prometheus/consoles'

---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"

---
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: monitoring
spec:
  ingressClassName: nginx
  rules:
  - host: monitoring.local
    http:
      paths:
      - path: /prometheus
        pathType: Prefix
        backend:
          service:
            name: prometheus-service
            port:
              number: 9090
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana-service
            port:
              number: 3000
```

### Step 6: Deploy and Configure Management Tools

```bash
# Deploy Portainer
kubectl apply -f portainer.yaml

# Deploy monitoring stack
kubectl apply -f monitoring-stack.yaml

# Add host entries
echo "192.168.1.100 portainer.local" | sudo tee -a /etc/hosts
echo "192.168.1.100 monitoring.local" | sudo tee -a /etc/hosts

# Check all deployments
kubectl get pods -A
kubectl get services -A
kubectl get ingress -A
```

### Step 7: Explore Each Management Tool

**Kubernetes Dashboard:**

- Navigate to the dashboard URL in your browser
- Use the token from step 1 to log in
- Explore workloads, services, and config maps
- Try creating and deleting resources through the UI

**K9s Terminal Dashboard:**

- Run `k9s` in your terminal
- Use keyboard shortcuts to navigate
- Try viewing logs, editing resources, and monitoring resource usage
- Practice using filters and searches

**Portainer:**

- Visit your Portainer instance at the configured URL
- Create admin account on first login
- Explore the Kubernetes environment view
- Try deploying applications through the GUI
- Monitor resource usage and logs

**Grafana (if monitoring stack deployed):**

- Visit your Grafana instance
- Login with admin/admin123
- Add Prometheus as a data source
- Import Kubernetes monitoring dashboards

### Step 8: Practice Common Management Tasks

```bash
# Using kubectl (command line)
kubectl get nodes -o wide
kubectl top nodes
kubectl get events --sort-by=.metadata.creationTimestamp

# Using K9s
# Press 'shift+f' to show failed pods
# Press 'shift+r' to show running pods only
# Press 'y' to see YAML of selected resource

# Create a test deployment to practice management
kubectl create deployment test-nginx --image=nginx --replicas=3
kubectl expose deployment test-nginx --port=80 --type=ClusterIP

# Practice scaling through different tools:
# 1. CLI: kubectl scale deployment test-nginx --replicas=5
# 2. K9s: Navigate to deployment, press 's' to scale
# 3. Dashboard: Use the web UI to scale
# 4. Portainer: Use the GUI scaling options
```

### Management Tools Key Learnings

- Installing and configuring multiple Kubernetes management interfaces
- Using the official Kubernetes Dashboard for web-based cluster management
- Mastering K9s for efficient terminal-based cluster operations
- Setting up Portainer for comprehensive container and Kubernetes management
- Understanding different visualization approaches for cluster monitoring
- Gaining comfort with continuous maintenance workflows
- Learning keyboard shortcuts and efficient navigation techniques
- Comparing different tools for various administrative tasks

## 🚀 Quick-Start Step-by-Step Checklist

Follow this checklist to complete all four projects systematically:

### ✅ Set up your homelab

- [ ] **Create a cluster using Proxmox or alternatives** (Minikube, K3s)
- [ ] **Configure at least one control plane and one worker node**
- [ ] **Verify cluster connectivity and DNS resolution**
- [ ] **Test basic pod deployment and networking**

### ✅ Install essential components

- [ ] **Load balancer** (e.g., MetalLB if in bare-metal VM environment)
- [ ] **Ingress controller** (NGINX or Traefik)
- [ ] **Configure IP address pools for LoadBalancer services**
- [ ] **Test external access through ingress**

### ✅ Deploy sample applications

- [ ] **Write Kubernetes manifests:**
  - [ ] Deployment for your app
  - [ ] Service to expose it
  - [ ] Ingress for external traffic routing
- [ ] **Deploy static website with custom content**
- [ ] **Deploy multi-tier application (e.g., WordPress + MySQL)**
- [ ] **Test applications through ingress endpoints**

### ✅ Manage and scale your apps

- [ ] **Scale pods up/down using kubectl and GUI tools**
- [ ] **Delete a pod manually to trigger Kubernetes self-healing**
- [ ] **Perform rolling updates and rollbacks**
- [ ] **Monitor resource usage and performance**

### ✅ Add visibility and control tools

- [ ] **Install Kubernetes Dashboard for web-based management**
- [ ] **Set up K9s for terminal-based cluster operations**
- [ ] **Deploy Portainer for comprehensive container management**
- [ ] **Configure basic monitoring with Prometheus and Grafana**
- [ ] **Practice using different tools for various administrative tasks**

## 📚 Additional Project Ideas for Extended Learning

### Beginner Extensions

1. **Deploy a Simple Web App** (e.g. NGINX or Flask app) using Kubernetes to learn workloads and service exposure
2. **Create a multi-tier architecture**, like a front-end service connected to a database backend, to understand scaling and service interaction
3. **Implement RBAC and Secrets**, exploring ConfigMaps, secrets, and access control features of Kubernetes

### Intermediate Challenges

1. **Build a CI/CD pipeline** with Jenkins running inside Kubernetes to automate builds and deployments
2. **Use Prometheus and Grafana** to monitor pods and node performance in your cluster
3. **Implement Helm charts** for package management and templating
4. **Set up persistent storage** with dynamic provisioning

### Advanced Topics

1. **Deploy a service mesh** (Istio or Linkerd) for advanced networking and security
2. **Implement GitOps** with ArgoCD for automated deployment workflows
3. **Configure advanced networking** with Network Policies and ingress SSL/TLS
4. **Set up disaster recovery** with backup and restore procedures

## Next Steps and Advanced Projects

### Recommended Learning Path

Once you're comfortable with these four core projects, you can tackle more advanced workflows:

1. **Helm Charts** - Package management for Kubernetes applications
2. **CI/CD Integration** - Automated deployment pipelines with GitOps
3. **Network Policies** - Advanced security and traffic control
4. **Multi-Cluster Operations** - Managing multiple Kubernetes environments
5. **Custom Resources and Operators** - Extending Kubernetes functionality

### Tools to Explore Next

- **Helm** - Package manager for Kubernetes applications
- **Kustomize** - Configuration management without templates
- **ArgoCD** - GitOps continuous delivery tool for Kubernetes
- **Telepresence** - Local development with remote cluster integration
- **Falco** - Runtime security monitoring for containers and Kubernetes

### Certification Path

Consider pursuing these certifications to validate your skills:

- **CKAD** - Certified Kubernetes Application Developer
- **CKA** - Certified Kubernetes Administrator  
- **CKS** - Certified Kubernetes Security Specialist

## 🧠 Final Thoughts

Christian Lempa's approach offers a clear, actionable path for anyone new to Kubernetes. These projects are practical, approachable, and scalable in complexity. The hands-on experience you gain from building your own cluster, configuring networking, deploying real applications, and managing them with various tools creates a solid foundation for more advanced Kubernetes work.

### Why This Approach Works

- **Real Infrastructure Experience**: Setting up VMs and networking mirrors production scenarios
- **Incremental Complexity**: Each project builds naturally on the previous
- **Practical Skills**: You learn by solving real problems, not just theory
- **Tool Diversity**: Experience with both CLI and GUI management approaches
- **Self-Healing Understanding**: Witnessing Kubernetes automation in action

Once you're comfortable with these basics, you can tackle more advanced workflows like Helm charts, CI/CD integration, network policies, and multi-cluster operations.

> **Want help choosing tools or need YAML scaffolding for any of the steps above?** These projects provide the foundation, but there's always more to explore in the Kubernetes ecosystem!

## Troubleshooting Common Issues

### Pod Won't Start

```bash
# Check pod events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check resource availability
kubectl top nodes
kubectl describe node <node-name>
```

### Service Not Accessible

```bash
# Verify service endpoints
kubectl get endpoints <service-name>

# Check service configuration
kubectl describe service <service-name>

# Test internal connectivity
kubectl run test-pod --image=busybox --restart=Never -- wget -O- <service-name>
```

### Image Pull Errors

```bash
# Verify image exists
docker pull <image-name>

# Check image pull secrets
kubectl get secrets

# Verify registry access
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password>
```

## Resources and References

### Documentation

- [Official Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Practice Platforms

- [Play with Kubernetes](https://labs.play-with-k8s.com/)
- [Katacoda Kubernetes Scenarios](https://katacoda.com/courses/kubernetes)
- [Kubernetes Learning Path](https://kubernetes.io/training/)

### Community

- [Kubernetes Slack](https://kubernetes.slack.com/)
- [CNCF Community](https://www.cncf.io/community/)
- [KubeCon + CloudNativeCon](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/)

---

*Start with Project 1 and work your way through each project at your own pace. Each project builds on the previous ones, creating a comprehensive learning experience that will prepare you for real-world Kubernetes deployments.*

## Happy Kuberneting! 🚀
