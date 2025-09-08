---
title: "Kubernetes Certificate Management"
description: "Comprehensive guide to certificate management in Kubernetes environments"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Kubernetes Certificate Management

Certificate management is crucial for securing Kubernetes clusters and the applications running within them. This guide covers various approaches to managing certificates in Kubernetes, from manual processes to automated solutions.

## Overview

Kubernetes certificate management involves several components:

- **Cluster certificates** - TLS certificates for cluster components
- **Application certificates** - TLS certificates for applications and services
- **Ingress certificates** - TLS certificates for external traffic
- **Service mesh certificates** - mTLS certificates for service-to-service communication

## Certificate Types

### Cluster Certificates

Kubernetes clusters use multiple certificates for internal communication:

- **API Server Certificate** - Secures the Kubernetes API
- **etcd Certificates** - Secures etcd cluster communication
- **Node Certificates** - Authenticates kubelet to API server
- **Service Account Tokens** - JWT tokens for pod authentication

### Application Certificates

Applications running in Kubernetes may need certificates for:

- **HTTPS endpoints** - Web applications and APIs
- **Database connections** - Secure database communication
- **Inter-service communication** - Service-to-service TLS

## cert-manager

cert-manager is the most popular solution for automated certificate management in Kubernetes.

### Installation

Install cert-manager using Helm:

```bash
# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true
```

### ClusterIssuer Configuration

Create a ClusterIssuer for Let's Encrypt:

```yaml
# letsencrypt-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

### Certificate Resources

Request certificates using Certificate resources:

```yaml
# app-certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app-tls
  namespace: default
spec:
  secretName: app-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - app.example.com
  - api.example.com
```

## Ingress Integration

### Automatic Certificate Provisioning

Use annotations for automatic certificate management:

```yaml
# ingress-with-tls.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
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

## Manual Certificate Management

### Creating Self-Signed Certificates

For development or internal services:

```bash
# Generate private key
openssl genrsa -out tls.key 2048

# Generate certificate signing request
openssl req -new -key tls.key -out tls.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=app.example.local"

# Generate self-signed certificate
openssl x509 -req -in tls.csr -signkey tls.key -out tls.crt -days 365

# Create Kubernetes secret
kubectl create secret tls app-tls-secret \
  --cert=tls.crt \
  --key=tls.key
```

### External Certificate Authority

For enterprise environments with internal CAs:

```bash
# Submit CSR to your CA and get signed certificate
# Then create the secret
kubectl create secret tls enterprise-tls-secret \
  --cert=signed-certificate.crt \
  --key=private-key.key \
  --ca-cert=ca-certificate.crt
```

## Service Mesh Certificates

### Istio Certificate Management

Istio provides automatic mTLS certificate management:

```yaml
# istio-destination-rule.yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: app-destination-rule
spec:
  host: app-service
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
```

### Linkerd Certificate Management

Linkerd uses its own certificate authority:

```bash
# Install Linkerd with automatic certificate rotation
linkerd install --cluster-name=my-cluster | kubectl apply -f -

# Verify certificate status
linkerd check --proxy
```

## Certificate Rotation

### Automated Rotation with cert-manager

cert-manager automatically renews certificates:

```yaml
# certificate-with-rotation.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app-cert
spec:
  secretName: app-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - app.example.com
  renewBefore: 720h  # 30 days before expiry
  duration: 2160h    # 90 days validity
```

### Manual Rotation Process

For manually managed certificates:

```bash
# Check certificate expiry
kubectl get secret app-tls-secret -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | openssl x509 -noout -dates

# Update certificate
kubectl delete secret app-tls-secret
kubectl create secret tls app-tls-secret \
  --cert=new-certificate.crt \
  --key=private-key.key

# Restart pods to pick up new certificate
kubectl rollout restart deployment/app-deployment
```

## Monitoring and Alerting

### Certificate Expiry Monitoring

Monitor certificate expiry with Prometheus:

```yaml
# certificate-monitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: cert-manager-metrics
spec:
  selector:
    matchLabels:
      app: cert-manager
  endpoints:
  - port: tcp-prometheus-servicemonitor
```

### Grafana Dashboard

Create alerts for certificate expiry:

```yaml
# certificate-expiry-alert.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: certificate-expiry
spec:
  groups:
  - name: certificate.rules
    rules:
    - alert: CertificateExpiringSoon
      expr: certmanager_certificate_expiration_timestamp_seconds - time() < 604800
      for: 1h
      labels:
        severity: warning
      annotations:
        summary: "Certificate expiring soon"
        description: "Certificate {{ $labels.name }} expires in less than 7 days"
```

## Best Practices

### Security Considerations

- **Use strong encryption** - RSA 2048+ or ECDSA P-256+
- **Rotate certificates regularly** - Automate rotation where possible
- **Secure private keys** - Use Kubernetes secrets with proper RBAC
- **Monitor expiry dates** - Set up alerts for certificate expiration

### Operational Guidelines

- **Standardize on cert-manager** - Use consistent certificate management
- **Document certificate dependencies** - Track which applications use which certificates
- **Test certificate renewal** - Regularly test automated renewal processes
- **Backup certificates** - Ensure certificate recovery procedures

### Development Workflow

- **Use development issuers** - Separate issuers for dev/staging/prod
- **Test certificate changes** - Validate certificates in staging first
- **Automate certificate deployment** - Include certificates in CI/CD pipelines

## Troubleshooting

### Common Issues

1. **Certificate not issued**

   ```bash
   kubectl describe certificate app-cert
   kubectl describe certificaterequest
   kubectl logs -n cert-manager deployment/cert-manager
   ```

2. **HTTP-01 challenge fails**

   ```bash
   kubectl describe challenge
   kubectl get ingress
   ```

3. **Certificate not trusted**

   ```bash
   kubectl get secret app-tls -o jsonpath='{.data.tls\.crt}' | \
     base64 -d | openssl x509 -noout -text
   ```

### Debugging Commands

```bash
# Check cert-manager status
kubectl get certificates
kubectl get certificaterequests
kubectl get challenges

# View certificate details
kubectl describe certificate <certificate-name>

# Check issuer status
kubectl describe clusterissuer <issuer-name>

# Monitor cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager -f
```

## Related Documentation

- **[Kubernetes Security](../security/index.md)** - Cluster security practices
- **[Ingress Controllers](ingress.md)** - Traffic routing and TLS termination
- **[Service Mesh](service-mesh.md)** - Service-to-service communication

---

*This guide covers certificate management from basic manual processes to advanced automated solutions. Choose the approach that best fits your security requirements and operational capabilities.*
