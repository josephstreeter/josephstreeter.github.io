---
title: Container Networking
description: Complete guide to container networking concepts, configurations, and best practices for Docker and Kubernetes
author: Joseph Streeter
date: 2024-01-15
tags: [containers, networking, docker, kubernetes, overlay, bridge, CNI]
---

Container networking is a fundamental aspect of containerized applications that enables communication between containers, services, and external systems. This guide covers essential networking concepts, configurations, and best practices.

## Docker Networking

### Network Types

#### Bridge Network

The default network driver for containers.

```bash

```bash
# Create custom bridge network
docker network create --driver bridge my-bridge-network

# Run container with custom network
docker run -d --name web-server --network my-bridge-network nginx

# Inspect network
docker network inspect my-bridge-network
```

#### Host Network

Container shares the host's network stack.

```bash
# Run container with host networking
docker run -d --name app --network host nginx
```

#### Overlay Network

Enables communication between containers across multiple Docker hosts.

```bash
# Create overlay network (Swarm mode)
docker network create --driver overlay --attachable my-overlay

# Deploy service with overlay network
docker service create --name web --network my-overlay nginx
```

#### None Network

Container has no network access.

```bash
# Run isolated container
docker run -d --name isolated --network none alpine sleep 3600
```

### Network Configuration

#### Port Mapping

```bash
# Map container port to host port
docker run -d -p 8080:80 nginx

# Map to specific interface
docker run -d -p 127.0.0.1:8080:80 nginx

# Map multiple ports
docker run -d -p 8080:80 -p 8443:443 nginx
```

#### Environment Variables

```bash
# Set network-related environment variables
docker run -d \
  -e VIRTUAL_HOST=app.example.com \
  -e VIRTUAL_PORT=8080 \
  --name app nginx
```

#### DNS Configuration

```bash
# Custom DNS servers
docker run -d --dns 8.8.8.8 --dns 8.8.4.4 nginx

# Add custom host entries
docker run -d --add-host api.local:192.168.1.100 nginx
```

### Docker Compose Networking

#### Default Network

```yaml
version: '3.8'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
  
  app:
    image: node:alpine
    depends_on:
      - web
```

#### Custom Networks

```yaml
version: '3.8'
services:
  web:
    image: nginx
    networks:
      - frontend
      - backend
    ports:
      - "80:80"
  
  app:
    image: node:alpine
    networks:
      - backend
  
  db:
    image: postgres
    networks:
      - backend
    environment:
      POSTGRES_PASSWORD: secret

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true
```

#### External Networks

```yaml
version: '3.8'
services:
  app:
    image: nginx
    networks:
      - existing-network

networks:
  existing-network:
    external: true
```

## Kubernetes Networking

### CNI (Container Network Interface)

#### Popular CNI Plugins

**Flannel** - Simple overlay network

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "type": "flannel",
      "delegate": {
        "hairpinMode": true,
        "isDefaultGateway": true
      }
    }
```

**Calico** - Network policy and security

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: calico-config
  namespace: kube-system
data:
  calico_backend: "bird"
  cluster_type: "k8s,bgp"
```

**Weave Net** - Multi-host networking

```bash
# Install Weave Net
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

### Services

#### ClusterIP

Default service type for internal communication.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 8080
```

#### NodePort

Exposes service on each node's IP at a static port.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080
```

#### LoadBalancer

Exposes service externally using cloud provider's load balancer.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: public-service
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
```

#### ExternalName

Maps service to external DNS name.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-api
spec:
  type: ExternalName
  externalName: api.external.com
```

### Ingress

#### Basic Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
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
                name: web-service
                port:
                  number: 80
```

#### TLS Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
spec:
  tls:
    - hosts:
        - secure.example.com
      secretName: tls-secret
  rules:
    - host: secure.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: secure-service
                port:
                  number: 443
```

### Network Policies

#### Default Deny Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

#### Allow Specific Traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
```

#### Allow External Traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-web
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
  ingress:
    - ports:
        - protocol: TCP
          port: 80
        - protocol: TCP
          port: 443
```

### Pod Networking

#### Multi-Container Pods

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
    - name: main-app
      image: nginx
      ports:
        - containerPort: 80
    - name: sidecar
      image: busybox
      command: ['sh', '-c', 'while true; do echo sidecar; sleep 30; done']
```

#### Init Containers

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-container-pod
spec:
  initContainers:
    - name: init-networking
      image: busybox
      command: ['sh', '-c', 'until nslookup backend-service; do sleep 1; done']
  containers:
    - name: main-app
      image: nginx
```

## Network Troubleshooting

### Docker Networking Issues

#### Debug Container Connectivity

```bash
# Test connectivity between containers
docker exec -it container1 ping container2

# Check network configuration
docker exec -it container1 ip addr show

# Inspect network interfaces
docker exec -it container1 netstat -tuln

# Test DNS resolution
docker exec -it container1 nslookup google.com
```

#### Network Inspection

```bash
# List all networks
docker network ls

# Inspect specific network
docker network inspect bridge

# Check container network settings
docker inspect container_name | grep -A 20 NetworkSettings
```

### Kubernetes Networking Issues

#### Pod Connectivity

```bash
# Test pod-to-pod communication
kubectl exec -it pod1 -- ping pod2-ip

# Check pod network details
kubectl describe pod pod-name

# Test service connectivity
kubectl exec -it pod-name -- curl service-name:port

# Check DNS resolution
kubectl exec -it pod-name -- nslookup kubernetes.default
```

#### Service Discovery

```bash
# List services
kubectl get services

# Describe service
kubectl describe service service-name

# Check endpoints
kubectl get endpoints service-name

# Test service from within cluster
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside pod: wget -qO- service-name:port
```

#### Network Policy Debugging

```bash
# Check network policies
kubectl get networkpolicies

# Describe policy
kubectl describe networkpolicy policy-name

# Test connectivity with policy applied
kubectl exec -it source-pod -- curl target-service:port
```

## Network Monitoring

### Docker Network Monitoring

#### Container Statistics

```bash
# Real-time container stats
docker stats

# Network statistics for specific container
docker exec container_name cat /proc/net/dev

# Monitor network traffic
docker exec container_name ss -tuln
```

### Kubernetes Network Monitoring

#### Built-in Monitoring

```bash
# Node network status
kubectl describe nodes

# Pod network metrics
kubectl top pods --all-namespaces

# Service mesh metrics (if using Istio)
kubectl get destinationrules,virtualservices -A
```

#### Network Monitoring Tools

```yaml
# Example: Deploy network monitoring
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: network-monitor
spec:
  selector:
    matchLabels:
      app: network-monitor
  template:
    metadata:
      labels:
        app: network-monitor
    spec:
      hostNetwork: true
      containers:
        - name: monitor
          image: nicolaka/netshoot
          command: ["/bin/bash", "-c", "while true; do sleep 3600; done"]
```

## Security Best Practices

### Network Isolation

#### Docker Security

```bash
# Run container with limited network access
docker run -d --network none --name isolated-app app:latest

# Use user-defined networks
docker network create --driver bridge secure-network
docker run -d --network secure-network app:latest
```

#### Kubernetes Security

```yaml
# Network policy for micro-segmentation
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: micro-segmentation
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: application
      ports:
        - protocol: TCP
          port: 5432
```

### Encryption

#### TLS Configuration

```yaml
# TLS termination at ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls-secret
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-service
                port:
                  number: 80
```

### Network Scanning

#### Security Scanning Tools

```bash
# Scan for open ports
nmap -sS target-ip

# Check for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image nginx:latest

# Network policy testing
kubectl apply -f network-policy.yaml
kubectl exec -it test-pod -- curl -m 5 restricted-service:port
```

## Performance Optimization

### Network Performance

#### Docker Optimization

```bash
# Use host networking for high-performance apps
docker run -d --network host high-performance-app

# Optimize bridge network
docker network create --driver bridge \
  --opt com.docker.network.bridge.name=optimized-bridge \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  optimized-network
```

#### Kubernetes Optimization

```yaml
# Pod with optimized networking
apiVersion: v1
kind: Pod
metadata:
  name: high-performance-pod
  annotations:
    container.apparmor.security.beta.kubernetes.io/app: runtime/default
spec:
  containers:
    - name: app
      image: high-performance-app
      resources:
        requests:
          memory: "1Gi"
          cpu: "500m"
        limits:
          memory: "2Gi"
          cpu: "1000m"
```

### Load Balancing

#### Service Load Balancing

```yaml
apiVersion: v1
kind: Service
metadata:
  name: load-balanced-service
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 300
```

## Related Topics

- [Docker Fundamentals](~/docs/infrastructure/containers/docker/index.md)
- [Kubernetes Fundamentals](~/docs/infrastructure/containers/kubernetes/index.md)
- [Container Security](~/docs/infrastructure/containers/security/index.md)
- [Service Mesh](~/docs/infrastructure/containers/kubernetes/service-mesh.md)
- [Ingress Controllers](~/docs/infrastructure/containers/kubernetes/ingress.md)
- [Infrastructure Monitoring](~/docs/infrastructure/monitoring/index.md)
