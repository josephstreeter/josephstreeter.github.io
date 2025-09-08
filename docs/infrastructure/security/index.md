---
title: "Infrastructure Security"
description: "Comprehensive infrastructure security hardening, best practices, and compliance guidelines"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Infrastructure Security

Infrastructure security is the foundation of any secure computing environment. This guide covers security hardening, monitoring, and compliance practices for servers, networks, and cloud infrastructure.

## Security Framework

### Defense in Depth

Implement multiple layers of security controls:

- **Physical Security** - Secure data centers and hardware access
- **Network Security** - Firewalls, segmentation, and traffic monitoring
- **Host Security** - Server hardening and access controls
- **Application Security** - Secure coding and configuration practices
- **Data Security** - Encryption, backup, and access management
- **Identity Security** - Authentication and authorization controls

### Security Principles

- **Least Privilege** - Grant minimum necessary access
- **Zero Trust** - Verify every user and device
- **Fail Secure** - Default to deny when systems fail
- **Security by Design** - Build security into architecture
- **Continuous Monitoring** - Monitor and respond to threats

## Server Hardening

### Linux Server Security

Essential hardening steps for Linux systems:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Configure automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades

# Disable unnecessary services
sudo systemctl disable telnet
sudo systemctl disable rsh
sudo systemctl disable rlogin

# Configure SSH security
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Configure firewall
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
```

### Windows Server Security

PowerShell hardening script:

```powershell
# Enable Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $false

# Configure Windows Update
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 4

# Disable unnecessary services
$services = @('Telnet', 'RemoteRegistry', 'Messenger')
foreach ($service in $services) {
    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
}

# Configure account policies
net accounts /maxpwage:90 /minpwage:1 /minpwlen:12 /uniquepw:5

# Enable audit policies
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
```

## Network Security

### Firewall Configuration

Configure iptables for Linux systems:

```bash
#!/bin/bash
# Basic firewall script

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (change port as needed)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Rate limiting for SSH
iptables -A INPUT -p tcp --dport 22 -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### Network Segmentation

Implement network segmentation using VLANs:

```bash
# VLAN configuration example
vconfig add eth0 100  # Create VLAN 100 for DMZ
vconfig add eth0 200  # Create VLAN 200 for internal network

ifconfig eth0.100 192.168.100.1 netmask 255.255.255.0 up
ifconfig eth0.200 192.168.200.1 netmask 255.255.255.0 up
```

## Access Control

### SSH Security

Advanced SSH configuration:

```bash
# /etc/ssh/sshd_config
Protocol 2
Port 2222                          # Change default port
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 2
Banner /etc/ssh/banner

# Allow only specific users/groups
AllowUsers admin backup
AllowGroups sshusers

# Restrict source IPs
Match Address 192.168.1.0/24
    PasswordAuthentication yes
    MaxAuthTries 6
```

### sudo Configuration

Secure sudo configuration:

```bash
# /etc/sudoers.d/custom
# Allow admin group to run all commands
%admin ALL=(ALL:ALL) ALL

# Allow backup user to run specific commands without password
backup ALL=(root) NOPASSWD: /usr/bin/rsync, /bin/tar

# Log all sudo commands
Defaults logfile="/var/log/sudo.log"
Defaults log_input, log_output

# Require password re-entry
Defaults timestamp_timeout=15
```

## Encryption and PKI

### SSL/TLS Configuration

Secure web server configuration (Apache):

```apache
# /etc/apache2/sites-available/secure-site.conf
<VirtualHost *:443>
    ServerName example.com
    DocumentRoot /var/www/html
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/example.com.crt
    SSLCertificateKeyFile /etc/ssl/private/example.com.key
    SSLCertificateChainFile /etc/ssl/certs/intermediate.crt
    
    # Modern SSL configuration
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    
    # Security headers
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</VirtualHost>
```

### Certificate Management

Automated certificate renewal with Let's Encrypt:

```bash
#!/bin/bash
# Certificate renewal script

# Install certbot
sudo apt install certbot python3-certbot-apache -y

# Obtain certificate
sudo certbot --apache -d example.com -d www.example.com

# Set up automatic renewal
sudo crontab -e
# Add line: 0 12 * * * /usr/bin/certbot renew --quiet
```

## Security Monitoring

### Intrusion Detection

Configure AIDE (Advanced Intrusion Detection Environment):

```bash
# Install and configure AIDE
sudo apt install aide -y

# Initialize database
sudo aideinit

# Create monitoring script
cat << 'EOF' > /usr/local/bin/aide-check.sh
#!/bin/bash
/usr/bin/aide --check | /usr/bin/logger -t aide
EOF

chmod +x /usr/local/bin/aide-check.sh

# Schedule daily checks
echo "0 2 * * * root /usr/local/bin/aide-check.sh" >> /etc/crontab
```

### Log Monitoring with Fail2Ban

```bash
# Install fail2ban
sudo apt install fail2ban -y

# Configure jail for SSH
sudo tee /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

sudo systemctl restart fail2ban
```

## Vulnerability Management

### Automated Vulnerability Scanning

```bash
#!/bin/bash
# Vulnerability assessment script

# Update system
sudo apt update && sudo apt upgrade -y

# Run security audits
sudo apt install lynis -y
sudo lynis audit system

# Check for known vulnerabilities
sudo apt install debsums -y
sudo debsums -c

# Network security scan
nmap -sS -O -PI localhost

# Generate report
echo "Security audit completed on $(date)" > /var/log/security-audit.log
```

### Patch Management

Automated patch management script:

```bash
#!/bin/bash
# Automated patch management

LOG_FILE="/var/log/patch-management.log"

# Function to log messages
log_message() {
    echo "$(date): $1" >> $LOG_FILE
}

# Update package lists
log_message "Starting package update"
apt update

# Check for security updates
SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)

if [ $SECURITY_UPDATES -gt 0 ]; then
    log_message "Found $SECURITY_UPDATES security updates"
    
    # Apply security updates
    DEBIAN_FRONTEND=noninteractive apt upgrade -y
    
    # Check if reboot is required
    if [ -f /var/run/reboot-required ]; then
        log_message "Reboot required after security updates"
        # Schedule reboot during maintenance window
        at 2:00 AM tomorrow <<< "reboot"
    fi
else
    log_message "No security updates available"
fi
```

## Compliance and Auditing

### CIS Benchmarks

Implement CIS (Center for Internet Security) benchmarks:

```bash
#!/bin/bash
# CIS Ubuntu 20.04 benchmark implementation

# 1.1.1.1 Ensure mounting of cramfs filesystems is disabled
echo "install cramfs /bin/true" >> /etc/modprobe.d/CIS.conf

# 1.1.1.2 Ensure mounting of freevxfs filesystems is disabled
echo "install freevxfs /bin/true" >> /etc/modprobe.d/CIS.conf

# 1.1.1.3 Ensure mounting of jffs2 filesystems is disabled
echo "install jffs2 /bin/true" >> /etc/modprobe.d/CIS.conf

# 3.3.1 Ensure source routed packets are not accepted
echo "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.d/99-CIS.conf
echo "net.ipv6.conf.all.accept_source_route = 0" >> /etc/sysctl.d/99-CIS.conf

# 3.3.2 Ensure ICMP redirects are not accepted
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.d/99-CIS.conf
echo "net.ipv6.conf.all.accept_redirects = 0" >> /etc/sysctl.d/99-CIS.conf

# Apply settings
sysctl --system
```

### SOC 2 Compliance

Security controls for SOC 2 compliance:

```yaml
# Security monitoring configuration
soc2_controls:
  access_control:
    - multi_factor_authentication
    - privileged_access_management
    - regular_access_reviews
    
  change_management:
    - version_control
    - change_approval_process
    - rollback_procedures
    
  monitoring:
    - security_event_logging
    - intrusion_detection
    - vulnerability_scanning
    
  data_protection:
    - encryption_at_rest
    - encryption_in_transit
    - data_classification
```

## Container Security

### Docker Security

Secure Docker configuration:

```bash
# Docker daemon security configuration
cat << EOF > /etc/docker/daemon.json
{
  "icc": false,
  "userns-remap": "default",
  "log-driver": "syslog",
  "disable-legacy-registry": true,
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF

# Restart Docker
systemctl restart docker
```

### Kubernetes Security

Pod Security Standards:

```yaml
# pod-security-policy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

## Security Automation

### Security Configuration Management

Ansible playbook for security hardening:

```yaml
# security-hardening.yml
---
- hosts: all
  become: yes
  tasks:
    - name: Update all packages
      apt:
        upgrade: dist
        update_cache: yes
        
    - name: Install security tools
      apt:
        name:
          - fail2ban
          - aide
          - rkhunter
          - lynis
        state: present
        
    - name: Configure SSH security
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      with_items:
        - { regexp: '^PermitRootLogin', line: 'PermitRootLogin no' }
        - { regexp: '^PasswordAuthentication', line: 'PasswordAuthentication no' }
      notify: restart ssh
      
  handlers:
    - name: restart ssh
      service:
        name: ssh
        state: restarted
```

## Best Practices

### Security Policies

- **Password Policy**: Enforce strong passwords and regular changes
- **Access Control Policy**: Define roles and permissions clearly
- **Incident Response**: Maintain documented response procedures
- **Security Training**: Regular security awareness training
- **Vendor Management**: Assess third-party security practices

### Security Operations

- **Regular Updates**: Keep systems and software current
- **Backup Strategy**: Implement and test backup procedures
- **Monitoring**: Continuous monitoring and alerting
- **Documentation**: Maintain accurate security documentation
- **Testing**: Regular security testing and assessments

## Related Documentation

- **[SSH Security](../../security/ssh/index.md)** - Secure remote access configuration
- **[Container Security](../containers/index.md)** - Container-specific security practices
- **[Monitoring](../monitoring/index.md)** - Security monitoring and alerting
- **[Disaster Recovery](../disaster-recovery/index.md)** - Business continuity planning

---

*This guide provides comprehensive infrastructure security practices from basic hardening to advanced compliance frameworks. Security is an ongoing process that requires continuous monitoring and improvement.*
