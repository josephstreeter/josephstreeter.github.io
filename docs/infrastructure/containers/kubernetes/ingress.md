---
title: "Kubernetes Ingress"
description: "Comprehensive guide to Kubernetes Ingress controllers, routing, and load balancing"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Overview

Kubernetes Ingress provides HTTP and HTTPS routing to services within a cluster. An Ingress controller is required to fulfill an Ingress, typically with a load balancer, though it may also configure edge routers or additional frontends to help handle traffic.

## Understanding Ingress

### What is Ingress?

Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource.

Key components:

- **Ingress Resource** - API object that manages external access
- **Ingress Controller** - Daemon that fulfills Ingress resources
- **Load Balancer** - Entry point for external traffic
- **Backend Services** - Target services for routing

### Ingress vs Other Exposure Methods

Comparison with other service exposure methods:

| Method | Use Case | Pros | Cons |
|--------|----------|------|------|
| NodePort | Development/Testing | Simple setup | Limited port range |
| LoadBalancer | Cloud environments | Cloud integration | Cost per service |
| Ingress | Production HTTP/HTTPS | Advanced routing, SSL | Requires controller |

## Basic Ingress Configuration

### Simple Ingress Example

Basic HTTP routing to a single service:

```yaml
# basic-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
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

### Multiple Path Routing

Route different paths to different services:

```yaml
# multi-path-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-path-ingress
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
```

### Multiple Host Routing

Route different hosts to different services:

```yaml
# multi-host-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
  - host: web.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
```

## HTTPS and TLS Configuration

### TLS Termination

Configure HTTPS with TLS certificates:

```yaml
# tls-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
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
---
# TLS Secret (create separately or use cert-manager)
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi... # Base64 encoded certificate
  tls.key: LS0tLS1CRUdJTi... # Base64 encoded private key
```

### Automatic Certificate Management

Using cert-manager for automatic certificate provisioning:

```yaml
# cert-manager-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cert-manager-ingress
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - auto-ssl.example.com
    secretName: auto-ssl-tls
  rules:
  - host: auto-ssl.example.com
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

## Ingress Controllers

### NGINX Ingress Controller

Most popular ingress controller implementation:

```yaml
# nginx-ingress-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
    spec:
      serviceAccountName: nginx-ingress-serviceaccount
      containers:
      - name: nginx-ingress-controller
        image: k8s.gcr.io/ingress-nginx/controller:v1.8.1
        args:
        - /nginx-ingress-controller
        - --configmap=$(POD_NAMESPACE)/nginx-configuration
        - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
        - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
        - --publish-service=$(POD_NAMESPACE)/ingress-nginx
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        ports:
        - name: http
          containerPort: 80
        - name: https
          containerPort: 443
        livenessProbe:
          httpGet:
            path: /healthz
            port: 10254
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: 10254
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Traefik Ingress Controller

Alternative lightweight ingress controller:

```yaml
# traefik-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: traefik-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik-account
      containers:
      - name: traefik
        image: traefik:v3.0
        args:
        - --api.insecure=true
        - --providers.kubernetesingress
        - --entrypoints.web.address=:80
        - --entrypoints.websecure.address=:443
        - --certificatesresolvers.myresolver.acme.email=admin@example.com
        - --certificatesresolvers.myresolver.acme.storage=/data/acme.json
        - --certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web
        ports:
        - name: web
          containerPort: 80
        - name: websecure
          containerPort: 443
        - name: admin
          containerPort: 8080
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: traefik-data
```

## Advanced Ingress Features

### URL Rewriting

Modify request paths before forwarding:

```yaml
# rewrite-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rewrite-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: rewrite.example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /legacy/app(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: new-app-service
            port:
              number: 80
```

### Rate Limiting

Control request rates to protect backend services:

```yaml
# rate-limit-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rate-limit-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "10"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    nginx.ingress.kubernetes.io/rate-limit-status-code: "429"
spec:
  ingressClassName: nginx
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
```

### Authentication

Implement authentication at the ingress level:

```yaml
# auth-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: auth-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
spec:
  ingressClassName: nginx
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
---
# Basic auth secret
apiVersion: v1
kind: Secret
metadata:
  name: basic-auth
  namespace: default
type: Opaque
data:
  auth: YWRtaW46JGFwcjEkSDY1dnBSVVMkQnJWSjdIRzE3RGtWVHNZL09sbzJEMQ== # admin:password
```

### Custom Headers

Add or modify HTTP headers:

```yaml
# custom-headers-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: custom-headers-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Custom-Header: MyValue";
      more_set_headers "X-Request-ID: $request_id";
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Content-Type, Authorization"
spec:
  ingressClassName: nginx
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
```

## Load Balancing Strategies

### Session Affinity

Route requests from same client to same backend:

```yaml
# session-affinity-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: session-affinity-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/affinity-mode: "persistent"
    nginx.ingress.kubernetes.io/session-cookie-name: "session-cookie"
    nginx.ingress.kubernetes.io/session-cookie-expires: "86400"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "86400"
    nginx.ingress.kubernetes.io/session-cookie-path: "/"
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: stateful-app-service
            port:
              number: 80
```

### Weighted Routing

Distribute traffic based on weights for A/B testing:

```yaml
# weighted-routing-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: weighted-routing-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "20"
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v2-service
            port:
              number: 80
---
# Main traffic (80%)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v1-service
            port:
              number: 80
```

## Monitoring and Observability

### Ingress Metrics

Configure metrics collection:

```yaml
# metrics-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: metrics-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/enable-access-log: "true"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      access_log /var/log/nginx/access.log json_combined;
spec:
  ingressClassName: nginx
  rules:
  - host: monitored.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: monitored-service
            port:
              number: 80
```

### Health Checks

Configure backend health monitoring:

```yaml
# health-check-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: health-check-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/upstream-hash-by: "$remote_addr"
    nginx.ingress.kubernetes.io/custom-http-errors: "404,503"
    nginx.ingress.kubernetes.io/default-backend: error-page-service
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /health
        pathType: Exact
        backend:
          service:
            name: health-service
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

## Troubleshooting

### Common Issues

```bash
# Check ingress resource
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller

# Test connectivity
kubectl port-forward -n ingress-nginx service/nginx-ingress-controller 8080:80
curl -H "Host: myapp.example.com" http://localhost:8080

# Check backend service
kubectl get services
kubectl get endpoints <service-name>

# Verify DNS resolution
nslookup myapp.example.com
dig myapp.example.com

# Check TLS certificates
kubectl get secrets -A | grep tls
kubectl describe secret <tls-secret-name>
```

### Debug Annotations

```yaml
# debug-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: debug-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/enable-access-log: "true"
    nginx.ingress.kubernetes.io/enable-rewrite-log: "true"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      error_log /var/log/nginx/error.log debug;
      rewrite_log on;
spec:
  ingressClassName: nginx
  rules:
  - host: debug.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: debug-service
            port:
              number: 80
```

## Security Best Practices

### Network Policies

Restrict ingress controller network access:

```yaml
# ingress-network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-controller-policy
  namespace: ingress-nginx
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from: []  # Allow from anywhere (external traffic)
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 8080
```

### WAF Integration

Web Application Firewall configuration:

```yaml
# waf-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: waf-protected-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/enable-modsecurity: "true"
    nginx.ingress.kubernetes.io/modsecurity-snippet: |
      SecRuleEngine On
      SecRequestBodyAccess On
      SecRule REQUEST_HEADERS:Content-Type "(?:application(?:/soap\+|/)|text/)xml" \
        "id:'200000',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML"
    nginx.ingress.kubernetes.io/limit-rpm: "100"
spec:
  ingressClassName: nginx
  rules:
  - host: secure-app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: secure-app-service
            port:
              number: 80
```

## Related Documentation

- **[Kubernetes Networking](../networking/index.md)** - Network fundamentals
- **[Certificate Management](certmanage.md)** - TLS certificate automation
- **[Service Mesh](service-mesh.md)** - Advanced traffic management
- **[Container Security](../security/index.md)** - Security best practices
- **[Monitoring](../../monitoring/index.md)** - Observability and monitoring

---

*This guide covers Kubernetes Ingress from basic concepts to advanced configurations. Ingress provides powerful HTTP/HTTPS routing capabilities for exposing services to external traffic.*
