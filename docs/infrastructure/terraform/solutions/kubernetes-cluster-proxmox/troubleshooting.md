---
title: "Troubleshooting"
description: "Diagnosing provisioning failures, cloud-init problems, networking issues, and cluster bootstrap errors"
author: "josephstreeter"
tags: ["terraform", "proxmox", "kubernetes", "iac", "troubleshooting", "debugging"]
category: "infrastructure"
last_updated: "2026-08-01"
---
## Troubleshooting

### Common Issues

#### VM Creation Failures

```bash
# Check Proxmox logs
tail -f /var/log/pve/tasks/active

# Verify template exists
qm list | grep template

# Check storage space
pvesm status

# Verify user permissions
pveum user list
pveum acl list
```

#### Network Connectivity Issues

```bash
# Test from Terraform host
ping 192.168.100.10

# Check Proxmox network configuration
cat /etc/network/interfaces

# Verify bridge configuration
brctl show vmbr0

# Check firewall rules
iptables -L -n -v

# Test DNS resolution
nslookup kubernetes.default.svc.cluster.local 10.96.0.10
```

#### Cloud-Init Problems

```bash
# Check cloud-init logs on VM
sudo cloud-init status --long
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log

# Verify cloud-init configuration
sudo cloud-init query -all

# Regenerate cloud-init
sudo cloud-init clean --logs
sudo cloud-init init
sudo cloud-init modules --mode=config
sudo cloud-init modules --mode=final

# Check qemu-guest-agent
sudo systemctl status qemu-guest-agent
```

### Kubernetes Troubleshooting

#### Cluster Issues

```bash
# Check node status
kubectl get nodes -o wide

# Examine system pods
kubectl get pods -A --field-selector=status.phase!=Running

# Check cluster events
kubectl get events --sort-by='.lastTimestamp' -A

# View component logs
kubectl logs -n kube-system -l component=kube-apiserver
kubectl logs -n kube-system -l component=kube-controller-manager
kubectl logs -n kube-system -l component=kube-scheduler

# Check etcd health
kubectl exec -n kube-system etcd-master-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  endpoint health
```

#### Network Plugin Issues

```bash
# Check CNI pods (Calico/Flannel)
kubectl get pods -n kube-system -l k8s-app=calico-node
kubectl get pods -n kube-flannel

# Restart CNI daemonset
kubectl rollout restart daemonset/calico-node -n kube-system
# or
kubectl rollout restart daemonset/kube-flannel-ds -n kube-flannel

# Check node network configuration
ip route show
ip addr show
sysctl net.ipv4.ip_forward
```

#### Pod Scheduling Failures

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl describe nodes | grep -A 5 "Allocated resources"

# View taints and tolerations
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Check resource quotas
kubectl get resourcequota --all-namespaces
kubectl describe resourcequota -n <namespace>
```

#### Certificate Issues

```bash
# Check certificate expiration
sudo kubeadm certs check-expiration

# Verify certificate chain
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# Check API server certificate
echo | openssl s_client -connect localhost:6443 2>/dev/null | openssl x509 -noout -dates

# Renew expired certificates
sudo kubeadm certs renew all
sudo systemctl restart kubelet
```

#### etcd Issues

```bash
# Check etcd cluster members
kubectl exec -n kube-system etcd-master-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member list

# Check etcd alarms
kubectl exec -n kube-system etcd-master-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  alarm list

# Disarm space quota alarm
kubectl exec -n kube-system etcd-master-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  alarm disarm
```

#### Split-Brain Scenario

```bash
# Identify split-brain condition
kubectl get nodes
# Some nodes show NotReady with different cluster states

# Check etcd membership from each master
for master in master-01 master-02 master-03; do
  echo "=== $master ==="
  ssh ubuntu@$master "sudo ETCDCTL_API=3 etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/peer.crt \
    --key=/etc/kubernetes/pki/etcd/peer.key \
    member list"
done

# Remove stale etcd members
kubectl exec -n kube-system etcd-master-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member remove <member-id>

# Re-add healthy member
sudo kubeadm join <lb-ip>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane --certificate-key <key>
```

#### API Server Unresponsive

```bash
# Check API server process
ssh ubuntu@master-01 "ps aux | grep kube-apiserver"

# Check API server logs
ssh ubuntu@master-01 "sudo journalctl -u kubelet -f"

# Restart API server
ssh ubuntu@master-01 "sudo systemctl restart kubelet"

# Force recreate API server pod
kubectl delete pod -n kube-system kube-apiserver-master-01

# Check load balancer health (if HA)
curl -k https://192.168.100.5:8404  # HAProxy stats
```

#### Storage Issues

```bash
# Check PV status
kubectl get pv
kubectl describe pv <pv-name>

# Check PVC binding
kubectl get pvc --all-namespaces
kubectl describe pvc <pvc-name> -n <namespace>

# Check storage class
kubectl get storageclass
kubectl describe storageclass <sc-name>

# Identify pods with volume issues
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.status.phase != "Running") | 
  select(.spec.volumes != null) | 
  "\(.metadata.namespace)/\(.metadata.name)"'
```

### Terraform State Issues

```bash
# Import existing resource
terraform import proxmox_vm_qemu.k8s_masters["master-01"] <node-name>/<vmid>

# Refresh state
terraform refresh

# Remove resource from state (dangerous)
terraform state rm proxmox_vm_qemu.k8s_masters["master-01"]

# Show state
terraform state list
terraform state show proxmox_vm_qemu.k8s_masters["master-01"]

# Move resource in state
terraform state mv proxmox_vm_qemu.old_name proxmox_vm_qemu.new_name

# Recover from state corruption
terraform state pull > terraform.tfstate.backup
# Edit state file carefully
terraform state push terraform.tfstate.backup
```

### Performance Troubleshooting

#### High CPU Usage

```bash
# Identify high CPU pods
kubectl top pods --all-namespaces --sort-by=cpu

# Check node CPU
kubectl top nodes

# Analyze CPU throttling
for pod in $(kubectl get pods -A -o jsonpath='{.items[*].metadata.name}'); do
  kubectl get pod $pod -o jsonpath='{.metadata.name}{"\t"}{.spec.containers[*].resources.limits.cpu}{"\n"}'
done

# Check CPU limits vs requests
kubectl describe nodes | grep -A 10 "Allocated resources"
```

#### Memory Issues

```bash
# Check OOM killed pods
kubectl get pods --all-namespaces --field-selector=status.phase=Failed
kubectl describe pod <pod-name> | grep -A 10 "Last State"

# Check node memory pressure
kubectl describe nodes | grep MemoryPressure

# Identify memory-hungry pods
kubectl top pods --all-namespaces --sort-by=memory | head -20

# Check swap (should be disabled)
ssh ubuntu@<node-ip> "free -h"
```

#### Network Latency

```bash
# Test pod-to-pod communication
kubectl run test-pod --image=nicolaka/netshoot --rm -it -- bash
# Inside pod: ping <other-pod-ip>

# Check CNI performance
kubectl run test1 --image=nicolaka/netshoot -- sleep 3600
kubectl run test2 --image=nicolaka/netshoot -- sleep 3600
kubectl exec test1 -- iperf3 -s &
kubectl exec test2 -- iperf3 -c <test1-ip>

# Check DNS latency
kubectl run dnstest --image=tutum/dnsutils --rm -it -- bash
# Inside pod: time nslookup kubernetes.default
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
