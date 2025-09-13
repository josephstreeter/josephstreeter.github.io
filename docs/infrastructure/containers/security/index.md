---
title: "Container Security"
description: "Comprehensive guide to container security, Docker hardening, Kubernetes security policies, and secure container development"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Overview

Container security encompasses protecting containerized applications throughout their lifecycle, from image creation to runtime operations. This includes securing container images, runtime environments, orchestration platforms, and the underlying infrastructure.

## Container Security Fundamentals

### Security Principles

Core security concepts for containers:

#### Defense in Depth

- Image security scanning
- Runtime protection
- Network segmentation
- Access controls
- Monitoring and logging

#### Least Privilege

- Minimal base images
- Non-root user execution
- Limited capabilities
- Resource constraints
- Network policies

#### Zero Trust Architecture

- Verify every request
- Encrypt communications
- Monitor continuously
- Assume breach scenarios

## Docker Security

### Secure Dockerfile Practices

Best practices for secure container images:

```dockerfile
# Use official, minimal base images
FROM alpine:3.18 AS builder
# Avoid 'latest' tag in production

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Update packages and install only necessary components
RUN apk update && apk upgrade && \
    apk add --no-cache \
        ca-certificates \
        curl && \
    rm -rf /var/cache/apk/*

# Set secure working directory
WORKDIR /app

# Copy application with proper ownership
COPY --chown=appuser:appgroup ./app /app/

# Remove unnecessary packages after build
RUN apk del curl

# Multi-stage build for smaller final image
FROM alpine:3.18
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

COPY --from=builder --chown=appuser:appgroup /app /app

# Switch to non-root user
USER appuser

# Expose only necessary ports
EXPOSE 8080

# Use specific entrypoint
ENTRYPOINT ["/app/myapp"]

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1
```

### Container Image Scanning

Implement automated vulnerability scanning:

```bash
#!/bin/bash
# container-scan.sh - Image security scanning script

IMAGE_NAME="$1"
SEVERITY_THRESHOLD="HIGH"
SCAN_RESULTS_DIR="./scan-results"

# Create results directory
mkdir -p "$SCAN_RESULTS_DIR"

# Trivy security scan
echo "Running Trivy security scan..."
trivy image --severity "$SEVERITY_THRESHOLD" --format json \
    --output "$SCAN_RESULTS_DIR/trivy-$(date +%Y%m%d-%H%M%S).json" \
    "$IMAGE_NAME"

# Docker Scout scan (if available)
if command -v docker &> /dev/null; then
    echo "Running Docker Scout scan..."
    docker scout cves --format json \
        --output "$SCAN_RESULTS_DIR/scout-$(date +%Y%m%d-%H%M%S).json" \
        "$IMAGE_NAME"
fi

# Snyk scan (if available)
if command -v snyk &> /dev/null; then
    echo "Running Snyk container scan..."
    snyk container test "$IMAGE_NAME" \
        --json > "$SCAN_RESULTS_DIR/snyk-$(date +%Y%m%d-%H%M%S).json"
fi

# Check scan results
CRITICAL_VULNS=$(trivy image --severity CRITICAL --format json "$IMAGE_NAME" | jq '.Results[]?.Vulnerabilities // [] | length')

if [ "$CRITICAL_VULNS" -gt 0 ]; then
    echo "CRITICAL: Found $CRITICAL_VULNS critical vulnerabilities"
    exit 1
else
    echo "SUCCESS: No critical vulnerabilities found"
    exit 0
fi
```

### Docker Daemon Security

Secure Docker daemon configuration:

```json
// /etc/docker/daemon.json
{
    "icc": false,
    "userns-remap": "default",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "live-restore": true,
    "userland-proxy": false,
    "experimental": false,
    "selinux-enabled": true,
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ],
    "default-ulimits": {
        "nofile": {
            "name": "nofile",
            "hard": 65536,
            "soft": 65536
        }
    },
    "tls": true,
    "tlsverify": true,
    "tlscert": "/etc/docker/certs/server-cert.pem",
    "tlskey": "/etc/docker/certs/server-key.pem",
    "tlscacert": "/etc/docker/certs/ca.pem",
    "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"]
}
```

### Runtime Security Controls

Implement runtime security measures:

```bash
#!/bin/bash
# secure-container-run.sh - Secure container runtime script

IMAGE="$1"
CONTAINER_NAME="$2"

# Run container with security hardening
docker run -d \
    --name "$CONTAINER_NAME" \
    --user 1001:1001 \
    --read-only \
    --tmpfs /tmp:noexec,nosuid,size=100m \
    --tmpfs /var/run:noexec,nosuid,size=50m \
    --cap-drop ALL \
    --cap-add NET_BIND_SERVICE \
    --security-opt no-new-privileges:true \
    --security-opt seccomp=seccomp-profile.json \
    --security-opt apparmor=docker-default \
    --memory 256m \
    --memory-swap 256m \
    --cpu-shares 512 \
    --pids-limit 100 \
    --ulimit nofile=1024:1024 \
    --network custom-network \
    --restart unless-stopped \
    --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    "$IMAGE"

# Verify container security settings
echo "Container security verification:"
docker inspect "$CONTAINER_NAME" | jq '.[] | {
    User: .Config.User,
    ReadonlyRootfs: .HostConfig.ReadonlyRootfs,
    CapDrop: .HostConfig.CapDrop,
    CapAdd: .HostConfig.CapAdd,
    SecurityOpt: .HostConfig.SecurityOpt,
    Memory: .HostConfig.Memory,
    PidsLimit: .HostConfig.PidsLimit
}'
```

## Kubernetes Security

### Pod Security Standards

Implement Pod Security Standards (PSS):

```yaml
# pod-security-policy.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
# Secure pod example
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: secure-namespace
spec:
  serviceAccountName: restricted-sa
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    runAsGroup: 1001
    fsGroup: 1001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: myapp:v1.0
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1001
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "128Mi"
        cpu: "100m"
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: var-run
      mountPath: /var/run
  volumes:
  - name: tmp
    emptyDir:
      sizeLimit: 100Mi
  - name: var-run
    emptyDir:
      sizeLimit: 50Mi
```

### Network Policies

Implement network segmentation:

```yaml
# network-security-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Allow specific ingress traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
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
---
# Deny all egress except DNS and specific services
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
  # Allow HTTPS to external APIs
  - to: []
    ports:
    - protocol: TCP
      port: 443
  # Allow internal service communication
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

### RBAC Configuration

Implement Role-Based Access Control:

```yaml
# rbac-security.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: production
---
# Minimal role for application
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: app-role
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  resourceNames: ["app-secrets"]
---
# Bind role to service account
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-role-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: production
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
---
# ClusterRole for monitoring (read-only)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "pods", "services", "endpoints"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list"]
```

## Secret Management

### Kubernetes Secrets Security

Secure secret handling practices:

```yaml
# secure-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: production
  annotations:
    kubernetes.io/description: "Application secrets"
type: Opaque
data:
  database-password: <base64-encoded-password>
  api-key: <base64-encoded-api-key>
---
# Secret consumption in pod
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      serviceAccountName: app-service-account
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: app
        image: myapp:v1.0
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-password
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api-key
        volumeMounts:
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: secret-volume
        secret:
          secretName: app-secrets
          defaultMode: 0400
```

### External Secret Management

Integration with external secret stores:

```yaml
# external-secrets.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: production
spec:
  provider:
    vault:
      server: "https://vault.company.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "production-role"
          serviceAccountRef:
            name: "external-secrets-sa"
---
# External secret definition
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-external-secret
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: app-secrets
    creationPolicy: Owner
  data:
  - secretKey: database-password
    remoteRef:
      key: production/database
      property: password
  - secretKey: api-key
    remoteRef:
      key: production/api
      property: key
```

## Image Security

### Image Signing and Verification

Implement image signing with Cosign:

```bash
#!/bin/bash
# image-signing.sh - Image signing and verification

IMAGE="myapp:v1.0"
REGISTRY="registry.company.com"
FULL_IMAGE="$REGISTRY/$IMAGE"

# Generate key pair (one-time setup)
cosign generate-key-pair

# Sign the image
cosign sign --key cosign.key "$FULL_IMAGE"

# Verify signature
cosign verify --key cosign.pub "$FULL_IMAGE"

# Sign with keyless signing (OIDC)
cosign sign "$FULL_IMAGE"

# Create attestation
cosign attest --predicate attestation.json --key cosign.key "$FULL_IMAGE"

# Verify attestation
cosign verify-attestation --key cosign.pub "$FULL_IMAGE"
```

### Supply Chain Security

SLSA (Supply-chain Levels for Software Artifacts) implementation:

```yaml
# slsa-build-workflow.yml
name: SLSA Build and Sign
on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image: ${{ steps.build.outputs.image }}
      digest: ${{ steps.build.outputs.digest }}
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Docker Buildx
      uses: docker/setup-buildx-action@v3
      
    - name: Login to registry
      uses: docker/login-action@v3
      with:
        registry: registry.company.com
        username: ${{ secrets.REGISTRY_USERNAME }}
        password: ${{ secrets.REGISTRY_PASSWORD }}
        
    - name: Build and push
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: registry.company.com/myapp:${{ github.sha }}
        platforms: linux/amd64,linux/arm64
        provenance: true
        sbom: true
        
    - name: Generate SLSA provenance
      uses: slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@v1.9.0
      with:
        image: registry.company.com/myapp
        digest: ${{ steps.build.outputs.digest }}
        registry-username: ${{ secrets.REGISTRY_USERNAME }}
        registry-password: ${{ secrets.REGISTRY_PASSWORD }}
```

## Runtime Security

### Runtime Protection

Implement runtime security monitoring:

```yaml
# falco-security-rules.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-rules
  namespace: falco-system
data:
  custom_rules.yaml: |
    # Custom security rules
    - rule: Unexpected Network Traffic
      desc: Detect unexpected network connections
      condition: >
        outbound and
        not proc.name in (curl, wget, http) and
        not fd.net.sport in (80, 443, 53)
      output: >
        Unexpected network traffic (user=%user.name proc=%proc.name
        connection=%fd.name)
      priority: WARNING
      
    - rule: Sensitive File Access
      desc: Detect access to sensitive files
      condition: >
        open_read and
        fd.name in (/etc/passwd, /etc/shadow, /etc/ssh/sshd_config) and
        not proc.name in (sshd, systemd)
      output: >
        Sensitive file accessed (user=%user.name proc=%proc.name
        file=%fd.name)
      priority: CRITICAL
      
    - rule: Container Privilege Escalation
      desc: Detect privilege escalation attempts
      condition: >
        spawned_process and
        proc.name in (sudo, su, pkexec) and
        container
      output: >
        Privilege escalation in container (user=%user.name
        proc=%proc.name container=%container.name)
      priority: CRITICAL
---
# Falco deployment
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: falco
  namespace: falco-system
spec:
  selector:
    matchLabels:
      app: falco
  template:
    metadata:
      labels:
        app: falco
    spec:
      serviceAccount: falco
      hostNetwork: true
      hostPID: true
      containers:
      - name: falco
        image: falcosecurity/falco:0.36.1
        securityContext:
          privileged: true
        args:
        - /usr/bin/falco
        - --cri=/run/containerd/containerd.sock
        - --k8s-api=https://kubernetes.default.svc.cluster.local
        - --k8s-api-cert=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        - --k8s-api-token=/var/run/secrets/kubernetes.io/serviceaccount/token
        volumeMounts:
        - name: dev-fs
          mountPath: /host/dev
        - name: proc-fs
          mountPath: /host/proc
        - name: etc-fs
          mountPath: /host/etc
        - name: falco-rules
          mountPath: /etc/falco/rules.d
      volumes:
      - name: dev-fs
        hostPath:
          path: /dev
      - name: proc-fs
        hostPath:
          path: /proc
      - name: etc-fs
        hostPath:
          path: /etc
      - name: falco-rules
        configMap:
          name: falco-rules
```

### Container Isolation

Advanced isolation techniques:

```yaml
# gvisor-runtime-class.yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
---
# Pod using gVisor runtime
apiVersion: v1
kind: Pod
metadata:
  name: secure-isolated-pod
spec:
  runtimeClassName: gvisor
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: myapp:v1.0
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    resources:
      limits:
        memory: "128Mi"
        cpu: "100m"
      requests:
        memory: "64Mi"
        cpu: "50m"
```

## Compliance and Governance

### Security Policies

Policy as Code with Open Policy Agent (OPA):

```rego
# security-policies.rego
package kubernetes.security

# Deny containers running as root
deny[msg] {
    input.kind == "Pod"
    input.spec.securityContext.runAsUser == 0
    msg := "Container must not run as root user"
}

# Require security context
deny[msg] {
    input.kind == "Pod"
    not input.spec.securityContext
    msg := "Pod must have security context defined"
}

# Require resource limits
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.limits
    msg := sprintf("Container %s must have resource limits", [container.name])
}

# Deny privileged containers
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Privileged container %s is not allowed", [container.name])
}

# Require specific image registries
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not startswith(container.image, "registry.company.com/")
    msg := sprintf("Container %s must use approved registry", [container.name])
}

# Deny host network access
deny[msg] {
    input.kind == "Pod"
    input.spec.hostNetwork == true
    msg := "Host network access is not allowed"
}
```

### Admission Controllers

Custom admission controller for security enforcement:

```yaml
# admission-controller.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: security-validator
webhooks:
- name: security.company.com
  clientConfig:
    service:
      name: security-admission-controller
      namespace: security-system
      path: "/validate"
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  - operations: ["CREATE", "UPDATE"]
    apiGroups: ["apps"]
    apiVersions: ["v1"]
    resources: ["deployments", "replicasets"]
  failurePolicy: Fail
  admissionReviewVersions: ["v1", "v1beta1"]
---
# Mutating webhook for security defaults
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingAdmissionWebhook
metadata:
  name: security-mutator
webhooks:
- name: security-defaults.company.com
  clientConfig:
    service:
      name: security-admission-controller
      namespace: security-system
      path: "/mutate"
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  failurePolicy: Fail
  admissionReviewVersions: ["v1", "v1beta1"]
```

## Monitoring and Incident Response

### Security Monitoring

Comprehensive security monitoring setup:

```yaml
# security-monitoring.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: security-monitoring-config
  namespace: monitoring
data:
  prometheus-rules.yaml: |
    groups:
    - name: container-security
      rules:
      - alert: ContainerHighPrivileged
        expr: kube_pod_container_status_running{container!="POD"} * on(pod, namespace) kube_pod_spec_containers_security_context_privileged == 1
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: "Privileged container detected"
          description: "Container {{ $labels.container }} in pod {{ $labels.pod }} is running in privileged mode"
          
      - alert: ContainerRootUser
        expr: kube_pod_container_status_running{container!="POD"} * on(pod, namespace) kube_pod_spec_containers_security_context_run_as_user == 0
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: "Container running as root"
          description: "Container {{ $labels.container }} in pod {{ $labels.pod }} is running as root user"
          
      - alert: UnauthorizedImagePull
        expr: increase(kubernetes_build_info[5m]) and on(instance) kube_pod_container_info{image!~"registry.company.com/.*"}
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: "Unauthorized container image"
          description: "Pod {{ $labels.pod }} is using unauthorized image {{ $labels.image }}"
---
# Security incident response workflow
apiVersion: v1
kind: ConfigMap
metadata:
  name: incident-response-playbook
  namespace: security
data:
  playbook.yaml: |
    incident_types:
      privileged_container:
        severity: high
        actions:
          - isolate_pod
          - collect_logs
          - notify_security_team
          - create_incident_ticket
      unauthorized_image:
        severity: critical
        actions:
          - block_image
          - quarantine_pod
          - scan_for_malware
          - escalate_to_management
      suspicious_network_activity:
        severity: medium
        actions:
          - capture_network_traffic
          - analyze_connections
          - update_network_policies
```

### Automated Response

Automated incident response system:

```python
#!/usr/bin/env python3
# security-response-handler.py
import json
import subprocess
import logging
from kubernetes import client, config
from datetime import datetime

class SecurityIncidentHandler:
    def __init__(self):
        config.load_incluster_config()
        self.k8s_client = client.CoreV1Api()
        self.apps_client = client.AppsV1Api()
        
    def handle_privileged_container_alert(self, alert_data):
        """Handle privileged container detection"""
        namespace = alert_data.get('namespace')
        pod_name = alert_data.get('pod')
        
        logging.warning(f"Privileged container detected: {namespace}/{pod_name}")
        
        # Isolate the pod
        self.isolate_pod(namespace, pod_name)
        
        # Collect forensic data
        self.collect_pod_logs(namespace, pod_name)
        
        # Create security incident
        self.create_incident("PRIVILEGED_CONTAINER", alert_data)
        
    def isolate_pod(self, namespace, pod_name):
        """Apply network isolation to suspicious pod"""
        isolation_policy = {
            "apiVersion": "networking.k8s.io/v1",
            "kind": "NetworkPolicy",
            "metadata": {
                "name": f"isolate-{pod_name}",
                "namespace": namespace
            },
            "spec": {
                "podSelector": {
                    "matchLabels": {"security.company.com/isolated": "true"}
                },
                "policyTypes": ["Ingress", "Egress"]
            }
        }
        
        # Label the pod for isolation
        try:
            body = {"metadata": {"labels": {"security.company.com/isolated": "true"}}}
            self.k8s_client.patch_namespaced_pod(
                name=pod_name,
                namespace=namespace,
                body=body
            )
            logging.info(f"Pod {namespace}/{pod_name} isolated")
        except Exception as e:
            logging.error(f"Failed to isolate pod: {e}")
    
    def collect_pod_logs(self, namespace, pod_name):
        """Collect logs for forensic analysis"""
        try:
            logs = self.k8s_client.read_namespaced_pod_log(
                name=pod_name,
                namespace=namespace,
                tail_lines=1000
            )
            
            timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
            log_file = f"/var/log/security/forensics/{namespace}-{pod_name}-{timestamp}.log"
            
            with open(log_file, 'w') as f:
                f.write(logs)
                
            logging.info(f"Logs collected: {log_file}")
        except Exception as e:
            logging.error(f"Failed to collect logs: {e}")
    
    def create_incident(self, incident_type, alert_data):
        """Create security incident ticket"""
        incident = {
            "type": incident_type,
            "timestamp": datetime.now().isoformat(),
            "alert_data": alert_data,
            "status": "INVESTIGATING",
            "severity": self.get_severity(incident_type)
        }
        
        # Integration with incident management system
        self.send_to_incident_system(incident)
        
    def get_severity(self, incident_type):
        severity_map = {
            "PRIVILEGED_CONTAINER": "HIGH",
            "UNAUTHORIZED_IMAGE": "CRITICAL",
            "SUSPICIOUS_NETWORK": "MEDIUM"
        }
        return severity_map.get(incident_type, "LOW")
    
    def send_to_incident_system(self, incident):
        """Send incident to external system"""
        # Implementation depends on your incident management system
        logging.info(f"Incident created: {incident['type']} - {incident['severity']}")

if __name__ == "__main__":
    handler = SecurityIncidentHandler()
    # Process incoming alerts
    handler.handle_privileged_container_alert({
        "namespace": "production",
        "pod": "suspicious-pod-123"
    })
```

## Best Practices Summary

### Security Checklist

Essential security practices:

#### Image Security Checklist

- [ ] Use minimal, official base images
- [ ] Scan images for vulnerabilities
- [ ] Sign and verify images
- [ ] Implement supply chain security
- [ ] Regular image updates

#### Runtime Security Checklist

- [ ] Run containers as non-root
- [ ] Use read-only root filesystems
- [ ] Drop unnecessary capabilities
- [ ] Implement resource limits
- [ ] Enable security contexts

#### Network Security Checklist

- [ ] Implement network policies
- [ ] Use service mesh for encryption
- [ ] Segment network traffic
- [ ] Monitor network connections
- [ ] Restrict ingress/egress

#### Access Control Checklist

- [ ] Implement RBAC properly
- [ ] Use service accounts
- [ ] Rotate credentials regularly
- [ ] Audit access logs
- [ ] Follow least privilege

#### Monitoring Checklist

- [ ] Deploy security monitoring
- [ ] Set up alerting rules
- [ ] Implement incident response
- [ ] Regular security assessments
- [ ] Compliance reporting

## Related Documentation

- **[Kubernetes Ingress](../kubernetes/ingress.md)** - HTTP/HTTPS routing security
- **[Service Mesh](../kubernetes/service-mesh.md)** - Advanced traffic security
- **[Certificate Management](../kubernetes/certmanage.md)** - TLS certificate automation
- **[Infrastructure Security](../../security/index.md)** - Overall security practices
- **[Monitoring](../../monitoring/index.md)** - Security monitoring and alerting

---

*This guide provides comprehensive container security practices from development to production deployment. Security should be integrated throughout the entire container lifecycle.*
