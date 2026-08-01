---
title: "Production Monitoring Stack"
description: "Deploying Prometheus, Grafana, and alerting for the Proxmox-hosted Kubernetes cluster"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "monitoring", "prometheus", "grafana", "alerting"]
category: "infrastructure"
last_updated: "2026-08-01"
---
## Production Monitoring Stack

### Complete Observability Suite

Deploy Prometheus, Grafana, Loki, and Alertmanager:

```hcl
resource "null_resource" "monitoring_stack" {
  count = var.enable_monitoring ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Add Helm repositories
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
      helm repo add grafana https://grafana.github.io/helm-charts
      helm repo update
      
      # Create monitoring namespace
      kubectl create namespace monitoring || true
      
      # Install kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
      helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set prometheus.prometheusSpec.retention=${var.prometheus_retention} \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=local-path \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
        --set grafana.adminPassword=${var.grafana_admin_password} \
        --set grafana.persistence.enabled=true \
        --set grafana.persistence.size=10Gi \
        --set alertmanager.config.global.slack_api_url=${var.slack_webhook_url} \
        --wait
      
      # Install Loki for log aggregation
      helm upgrade --install loki grafana/loki-stack \
        --namespace monitoring \
        --set loki.persistence.enabled=true \
        --set loki.persistence.size=30Gi \
        --set promtail.enabled=true \
        --set grafana.enabled=false \
        --wait
      
      # Install Grafana Dashboards
      kubectl apply -f - <<EOF
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: k8s-cluster-dashboard
        namespace: monitoring
        labels:
          grafana_dashboard: "1"
      data:
        k8s-cluster.json: |
          {
            "dashboard": {
              "title": "Kubernetes Cluster Overview",
              "panels": [
                {
                  "title": "Node CPU Usage",
                  "targets": [{"expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"}]
                },
                {
                  "title": "Node Memory Usage",
                  "targets": [{"expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"}]
                },
                {
                  "title": "Pod Count by Namespace",
                  "targets": [{"expr": "sum by (namespace) (kube_pod_info)"}]
                }
              ]
            }
          }
      EOF
    EOT
  }
  
  depends_on = [null_resource.fetch_kubeconfig]
}
```

### Alerting Rules

Create production alerting rules:

```yaml
# alertmanager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-kube-prometheus-alertmanager
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
      slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'critical-alerts'
      routes:
      - match:
          severity: critical
        receiver: 'critical-alerts'
      - match:
          severity: warning
        receiver: 'warning-alerts'
    
    receivers:
    - name: 'critical-alerts'
      slack_configs:
      - channel: '#prod-alerts-critical'
        title: 'CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        send_resolved: true
    
    - name: 'warning-alerts'
      slack_configs:
      - channel: '#prod-alerts-warning'
        title: 'WARNING: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        send_resolved: true
    
    inhibit_rules:
    - source_match:
        severity: 'critical'
      target_match:
        severity: 'warning'
      equal: ['alertname', 'cluster', 'service']
```

Apply Prometheus rules:

```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kubernetes-cluster-alerts
  namespace: monitoring
spec:
  groups:
  - name: kubernetes.rules
    interval: 30s
    rules:
    - alert: NodeDown
      expr: up{job="node-exporter"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Node {{ $labels.instance }} is down"
        description: "Node {{ $labels.instance }} has been down for more than 5 minutes."
    
    - alert: HighNodeCPU
      expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "High CPU on node {{ $labels.instance }}"
        description: "Node {{ $labels.instance }} has CPU usage above 80% for 10 minutes."
    
    - alert: HighNodeMemory
      expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "High memory on node {{ $labels.instance }}"
        description: "Node {{ $labels.instance }} has memory usage above 85% for 10 minutes."
    
    - alert: KubernetesPodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"
        description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been restarting frequently."
    
    - alert: KubernetesPodNotReady
      expr: kube_pod_status_phase{phase!="Running"} == 1
      for: 15m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} not ready"
        description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in non-ready state for 15 minutes."
    
    - alert: EtcdHighLatency
      expr: histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m])) > 0.5
      for: 10m
      labels:
        severity: critical
      annotations:
        summary: "etcd high latency on {{ $labels.instance }}"
        description: "etcd instance {{ $labels.instance }} has high WAL fsync latency (99th percentile > 500ms)."
```

### Backup and Disaster Recovery

Implement Velero for cluster backups:

```hcl
resource "null_resource" "velero_backup" {
  count = var.enable_backup ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Install Velero CLI
      wget -q https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
      tar -xzf velero-v1.12.0-linux-amd64.tar.gz
      sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/
      
      # Create credentials for backup storage
      cat <<EOF > /tmp/credentials-velero
      [default]
      aws_access_key_id=${var.backup_s3_access_key}
      aws_secret_access_key=${var.backup_s3_secret_key}
      EOF
      
      # Install Velero
      velero install \
        --provider aws \
        --plugins velero/velero-plugin-for-aws:v1.8.0 \
        --bucket ${var.backup_bucket_name} \
        --secret-file /tmp/credentials-velero \
        --backup-location-config region=${var.backup_region},s3ForcePathStyle="true",s3Url=${var.backup_s3_url} \
        --snapshot-location-config region=${var.backup_region} \
        --use-volume-snapshots=false
      
      # Create daily backup schedule
      velero schedule create daily-backup \
        --schedule="@daily" \
        --ttl 720h0m0s \
        --include-namespaces "*" \
        --exclude-namespaces velero,kube-system
      
      # Create hourly backup for critical namespaces
      velero schedule create hourly-critical \
        --schedule="@hourly" \
        --ttl 168h0m0s \
        --include-namespaces production,database
      
      rm /tmp/credentials-velero
    EOT
  }
  
  depends_on = [null_resource.fetch_kubeconfig]
}
```

### Service Mesh Integration

Deploy Istio for advanced traffic management:

```hcl
resource "null_resource" "istio_installation" {
  count = var.enable_service_mesh ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Download Istio
      curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.0 sh -
      cd istio-1.20.0
      
      # Install Istio with production profile
      ./bin/istioctl install --set profile=production \
        --set values.gateways.istio-ingressgateway.type=LoadBalancer \
        --set values.pilot.resources.requests.cpu=500m \
        --set values.pilot.resources.requests.memory=2Gi \
        --set values.global.proxy.resources.requests.cpu=100m \
        --set values.global.proxy.resources.requests.memory=128Mi \
        --set values.telemetry.enabled=true \
        -y
      
      # Enable automatic sidecar injection
      kubectl label namespace default istio-injection=enabled
      kubectl label namespace production istio-injection=enabled
      
      # Install Kiali for observability
      kubectl apply -f samples/addons/kiali.yaml
      kubectl apply -f samples/addons/jaeger.yaml
      
      cd ..
      rm -rf istio-1.20.0
    EOT
  }
  
  depends_on = [null_resource.monitoring_stack]
}
```

### Cost Optimization

Monitor and optimize resource usage:

```hcl
resource "null_resource" "cost_monitoring" {
  count = var.enable_cost_monitoring ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Install Kubecost
      helm repo add kubecost https://kubecost.github.io/cost-analyzer/
      helm repo update
      
      helm upgrade --install kubecost kubecost/cost-analyzer \
        --namespace kubecost --create-namespace \
        --set prometheus.server.global.external_labels.cluster_id=${var.cluster_name} \
        --set prometheus.nodeExporter.enabled=false \
        --set prometheus.serviceAccounts.nodeExporter.create=false \
        --set ingress.enabled=true \
        --set ingress.hosts[0]="kubecost.${var.domain_name}" \
        --wait
      
      # Configure resource recommendations
      kubectl apply -f - <<EOF
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: kubecost-cost-analyzer
        namespace: kubecost
      data:
        recommendations.yaml: |
          savings:
            recommendUnderutilizedNodes: true
            recommendRightSizing: true
            minSavingsThreshold: 10
            cpuUtilizationThreshold: 0.2
            memUtilizationThreshold: 0.2
      EOF
    EOT
  }
  
  depends_on = [null_resource.monitoring_stack]
}
```

### Security Hardening

Deploy Falco for runtime security:

```hcl
resource "null_resource" "security_monitoring" {
  count = var.enable_security_monitoring ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig/${var.cluster_name}.conf
      
      # Install Falco for runtime security
      helm repo add falcosecurity https://falcosecurity.github.io/charts
      helm repo update
      
      helm upgrade --install falco falcosecurity/falco \
        --namespace falco --create-namespace \
        --set falco.grpc.enabled=true \
        --set falco.grpcOutput.enabled=true \
        --set falco.json_output=true \
        --set falco.log_syslog=false \
        --set falco.priority=warning \
        --set falco.rules_file[0]=/etc/falco/falco_rules.yaml \
        --set falco.rules_file[1]=/etc/falco/k8s_audit_rules.yaml \
        --wait
      
      # Install Falcosidekick for alerts
      helm upgrade --install falcosidekick falcosecurity/falcosidekick \
        --namespace falco \
        --set config.slack.webhookurl=${var.slack_webhook_url} \
        --set config.slack.minimumpriority=warning \
        --wait
    EOT
  }
  
  depends_on = [null_resource.fetch_kubeconfig]
}
```

### Complete Production Variables

Add all required variables:

```hcl
# Monitoring
variable "prometheus_retention" {
  type        = string
  description = "Prometheus data retention period"
  default     = "15d"
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password"
  sensitive   = true
}

variable "slack_webhook_url" {
  type        = string
  description = "Slack webhook URL for alerts"
  sensitive   = true
  default     = ""
}

# Backup
variable "backup_bucket_name" {
  type        = string
  description = "S3 bucket name for Velero backups"
  default     = ""
}

variable "backup_region" {
  type        = string
  description = "S3 region for backups"
  default     = "us-east-1"
}

variable "backup_s3_url" {
  type        = string
  description = "S3-compatible storage URL"
  default     = ""
}

variable "backup_s3_access_key" {
  type        = string
  description = "S3 access key for backups"
  sensitive   = true
  default     = ""
}

variable "backup_s3_secret_key" {
  type        = string
  description = "S3 secret key for backups"
  sensitive   = true
  default     = ""
}

# Service Mesh
variable "enable_service_mesh" {
  type        = bool
  description = "Enable Istio service mesh"
  default     = false
}

# Cost Monitoring
variable "enable_cost_monitoring" {
  type        = bool
  description = "Enable Kubecost for cost monitoring"
  default     = false
}

variable "domain_name" {
  type        = string
  description = "Domain name for ingress"
  default     = "example.com"
}

# Security
variable "enable_security_monitoring" {
  type        = bool
  description = "Enable Falco runtime security monitoring"
  default     = false
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
