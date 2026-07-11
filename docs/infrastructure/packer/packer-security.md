---
uid: infrastructure.packer.security
title: Packer Security Considerations
description: Comprehensive guide to security best practices for Packer including credential management, image hardening, vulnerability scanning, and compliance
ms.date: 01/18/2026
---

This section covers security best practices when working with Packer, ensuring your machine images are secure from build time through deployment.

## Credential Management

Proper credential management is critical for securing Packer builds and preventing unauthorized access.

### Environment Variables

Use environment variables to avoid hardcoding credentials in templates:

```bash
# Set AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Set Azure credentials
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="your-tenant-id"
export ARM_SUBSCRIPTION_ID="your-subscription-id"

# Packer automatically uses these environment variables
packer build template.pkr.hcl
```

### Packer Variable Files

Store non-sensitive configuration in variable files, reference secrets from secure sources:

```hcl
# variables.pkrvars.hcl - Safe to commit
region        = "us-east-1"
instance_type = "t3.micro"
project_name  = "myproject"

# Do NOT include credentials here
```

```hcl
# template.pkr.hcl - Reference environment variables
variable "aws_access_key" {
    type      = string
    sensitive = true
    default   = env("AWS_ACCESS_KEY_ID")
}

variable "aws_secret_key" {
    type      = string
    sensitive = true
    default   = env("AWS_SECRET_ACCESS_KEY")
}

source "amazon-ebs" "secure" {
    access_key    = var.aws_access_key
    secret_key    = var.aws_secret_key
    region        = var.region
    # ... other configuration
}
```

### HashiCorp Vault Integration

Retrieve credentials dynamically from Vault:

```hcl
# Use Vault data source
data "vault" "aws_creds" {
    path = "aws/creds/packer-role"
}

source "amazon-ebs" "vault" {
    access_key = data.vault.aws_creds.data.access_key
    secret_key = data.vault.aws_creds.data.secret_key
    
    # Vault-provided credentials have limited lifetime
    region        = var.region
    ami_name      = var.ami_name
    instance_type = var.instance_type
}
```

```bash
# Set Vault token
export VAULT_TOKEN="your-vault-token"
export VAULT_ADDR="https://vault.example.com"

# Run Packer
packer build template.pkr.hcl
```

### AWS IAM Roles

Use IAM roles for EC2 instances instead of long-lived credentials:

```hcl
# When running Packer on EC2 instance
source "amazon-ebs" "iam-role" {
    # No access_key or secret_key needed
    # Packer uses instance profile automatically
    
    region        = var.region
    ami_name      = var.ami_name
    instance_type = var.instance_type
    
    source_ami_filter {
        filters = {
            name = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
        }
        most_recent = true
        owners      = ["099720109477"]
    }
    
    ssh_username = "ubuntu"
}
```

### AWS Secrets Manager

Retrieve secrets from AWS Secrets Manager:

```bash
#!/bin/bash
# scripts/get-secrets.sh

# Retrieve secret from Secrets Manager
SECRET=$(aws secretsmanager get-secret-value \
    --secret-id packer/credentials \
    --query SecretString \
    --output text)

# Parse JSON secret
export DB_PASSWORD=$(echo "$SECRET" | jq -r '.db_password')
export API_KEY=$(echo "$SECRET" | jq -r '.api_key')

# Run Packer with secrets
packer build template.pkr.hcl
```

### Azure Key Vault

Use Azure Key Vault for credential management:

```bash
# Retrieve secrets from Key Vault
export CLIENT_SECRET=$(az keyvault secret show \
    --vault-name my-keyvault \
    --name packer-client-secret \
    --query value -o tsv)

# Use in Packer build
packer build \
    -var="client_secret=$CLIENT_SECRET" \
    template.pkr.hcl
```

### Credential Rotation

Implement automated credential rotation:

```bash
#!/bin/bash
# scripts/rotate-credentials.sh

# Generate new access key
NEW_KEY=$(aws iam create-access-key --user-name packer-user --output json)

# Extract key details
NEW_ACCESS_KEY=$(echo "$NEW_KEY" | jq -r '.AccessKey.AccessKeyId')
NEW_SECRET_KEY=$(echo "$NEW_KEY" | jq -r '.AccessKey.SecretAccessKey')

# Update secrets in Vault/Secrets Manager
aws secretsmanager update-secret \
    --secret-id packer/aws-credentials \
    --secret-string "{\"access_key\":\"$NEW_ACCESS_KEY\",\"secret_key\":\"$NEW_SECRET_KEY\"}"

# Delete old access key (after verification)
# aws iam delete-access-key --user-name packer-user --access-key-id OLD_KEY_ID
```

## Secrets in Templates

Never commit secrets to version control or expose them in templates.

### Sensitive Variable Declaration

Mark variables containing secrets as sensitive:

```hcl
variable "database_password" {
    type        = string
    description = "Database password"
    sensitive   = true  # Prevents logging
    default     = env("DB_PASSWORD")
}

variable "api_token" {
    type        = string
    description = "API authentication token"
    sensitive   = true
}

# Use sensitive variables safely
provisioner "shell" {
    environment_vars = [
        "DB_PASSWORD=${var.database_password}",
        "API_TOKEN=${var.api_token}"
    ]
    
    inline = [
        "echo 'Configuring application...'",
        # Password won't be logged due to sensitive flag
        "echo \"db_password=$DB_PASSWORD\" > /etc/app/config"
    ]
}
```

### .gitignore Configuration

Ensure secrets are never committed:

```gitignore
# .gitignore for Packer projects

# Variable files with secrets
*.auto.pkrvars.hcl
secrets.pkrvars.hcl
*-secrets.pkrvars.hcl

# Credentials
*.pem
*.key
credentials.json

# Environment files
.env
.env.local

# Build artifacts
packer_cache/
output-*/
manifest.json
crash.log

# OS files
.DS_Store
Thumbs.db
```

### Pre-commit Hooks

Prevent accidental secret commits:

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check for potential secrets
if git diff --cached --name-only | xargs grep -E "AKIA|aws_secret|password.*=|token.*=" ; then
    echo "ERROR: Potential secret detected in staged files"
    echo "Please remove secrets before committing"
    exit 1
fi

# Check for sensitive variable files
if git diff --cached --name-only | grep -E "secrets|credentials" ; then
    echo "ERROR: Sensitive file in staged changes"
    exit 1
fi

exit 0
```

### Secret Scanning Tools

Use automated tools to detect secrets:

```bash
# Install git-secrets
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
make install

# Configure git-secrets
git secrets --install
git secrets --register-aws

# Scan repository
git secrets --scan

# Scan history
git secrets --scan-history
```

## Image Hardening

Implement security hardening during image creation.

### System Hardening

```bash
#!/bin/bash
# scripts/harden-system.sh

set -e

echo "==> System Hardening"

# Update system packages
apt-get update
apt-get upgrade -y

# Remove unnecessary packages
apt-get autoremove -y
apt-get autoclean

# Disable unnecessary services
systemctl disable bluetooth
systemctl disable cups

# Configure firewall
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp  # SSH
ufw allow 443/tcp # HTTPS

# Disable root login
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Set strong password policy
cat > /etc/security/pwquality.conf <<EOF
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
EOF

# Configure automatic security updates
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Set file permissions
chmod 600 /etc/shadow
chmod 600 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group

# Disable core dumps
echo "* hard core 0" >> /etc/security/limits.conf
echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf

# Enable kernel protections
cat >> /etc/sysctl.conf <<EOF
# IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Syn flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
EOF

sysctl -p

echo "==> System hardening complete"
```

### CIS Benchmark Compliance

Apply CIS (Center for Internet Security) benchmarks:

```hcl
provisioner "ansible" {
    playbook_file = "ansible/cis-hardening.yml"
    
    extra_arguments = [
        "--extra-vars",
        "cis_level=2 cis_audit_only=false"
    ]
    
    user = "ubuntu"
}
```

```yaml
# ansible/cis-hardening.yml
---
- name: Apply CIS Ubuntu Hardening
  hosts: all
  become: yes
  
  roles:
    - role: ansible-cis-ubuntu
      vars:
        cis_level: 2
        cis_audit_mode: false
```

### Security Tools Installation

```bash
#!/bin/bash
# scripts/install-security-tools.sh

echo "==> Installing security tools"

# Install security monitoring tools
apt-get install -y \
    aide \
    auditd \
    fail2ban \
    rkhunter \
    lynis

# Configure AIDE (Advanced Intrusion Detection)
aideinit
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Configure fail2ban
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Configure auditd
cat >> /etc/audit/rules.d/audit.rules <<EOF
# Monitor authentication
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity

# Monitor sudo
-w /etc/sudoers -p wa -k sudoers
-w /var/log/sudo.log -p wa -k sudolog

# Monitor network changes
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network_modifications
EOF

systemctl enable auditd
systemctl restart auditd

echo "==> Security tools installed"
```

## Vulnerability Scanning

Scan images for vulnerabilities before deployment.

### Trivy Scanner Integration

```bash
#!/bin/bash
# scripts/scan-vulnerabilities.sh

set -e

AMI_ID=$1

echo "==> Scanning AMI: $AMI_ID"

# Launch temporary instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Launched instance: $INSTANCE_ID"

# Wait for instance
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

# Get instance IP
INSTANCE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

# Wait for SSH
sleep 30

# Install Trivy on instance
ssh ubuntu@"$INSTANCE_IP" 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -'

# Run vulnerability scan
ssh ubuntu@"$INSTANCE_IP" 'trivy fs --severity HIGH,CRITICAL /' > vulnerability-report.txt

# Check for critical vulnerabilities
CRITICAL_COUNT=$(grep -c "CRITICAL" vulnerability-report.txt || true)

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "ERROR: Found $CRITICAL_COUNT critical vulnerabilities"
    cat vulnerability-report.txt
    exit 1
fi

echo "==> Scan complete. No critical vulnerabilities found"

# Cleanup
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
```

### Packer Integration

```hcl
build {
    sources = ["source.amazon-ebs.ubuntu"]
    
    provisioner "shell" {
        script = "scripts/harden-system.sh"
    }
    
    # Run vulnerability scan
    post-processor "shell-local" {
        inline = [
            "AMI_ID=$(jq -r '.builds[0].artifact_id' manifest.json | cut -d':' -f2)",
            "./scripts/scan-vulnerabilities.sh $AMI_ID"
        ]
    }
    
    # Only proceed if scan passes
    error_cleanup_provisioner {
        inline = [
            "echo 'Build failed security scan'",
            "# Cleanup and notifications"
        ]
    }
}
```

### Anchore Engine Integration

```yaml
# .github/workflows/packer-scan.yml
- name: Scan with Anchore
  uses: anchore/scan-action@v3
  with:
    image: "ami:${{ steps.build.outputs.ami_id }}"
    fail-build: true
    severity-cutoff: high
```

### AWS Inspector Integration

```bash
#!/bin/bash
# scripts/run-inspector.sh

AMI_ID=$1

# Create assessment target
TARGET_ARN=$(aws inspector create-assessment-target \
    --assessment-target-name "packer-ami-$AMI_ID" \
    --query 'assessmentTargetArn' \
    --output text)

# Create assessment template
TEMPLATE_ARN=$(aws inspector create-assessment-template \
    --assessment-target-arn "$TARGET_ARN" \
    --assessment-template-name "security-scan" \
    --duration-in-seconds 3600 \
    --rules-package-arns \
        "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-gEjTy7T7" \
    --query 'assessmentTemplateArn' \
    --output text)

# Run assessment
RUN_ARN=$(aws inspector start-assessment-run \
    --assessment-template-arn "$TEMPLATE_ARN" \
    --query 'assessmentRunArn' \
    --output text)

# Wait for completion
aws inspector wait assessment-run-completed \
    --assessment-run-arns "$RUN_ARN"

# Get findings
aws inspector list-findings \
    --assessment-run-arns "$RUN_ARN" \
    --query 'findingArns' \
    --output text | \
    xargs aws inspector describe-findings \
    --finding-arns > inspector-report.json
```

## Secure Build Environments

Ensure the build environment itself is secure.

### Isolated Build Networks

```hcl
source "amazon-ebs" "isolated" {
    region = var.region
    
    # Use dedicated VPC for builds
    vpc_filter {
        filters = {
            "tag:Purpose" = "packer-builds"
            "isDefault"   = "false"
        }
    }
    
    # Use private subnet with NAT gateway
    subnet_filter {
        filters = {
            "tag:Type" = "private"
        }
        random = false
    }
    
    # Dedicated security group
    security_group_filter {
        filters = {
            "tag:Name" = "packer-builds"
        }
    }
    
    # Disable public IP
    associate_public_ip_address = false
    
    # Use SSH through bastion
    ssh_bastion_host = var.bastion_host
    ssh_bastion_username = "ubuntu"
}
```

### Temporary Build Resources

```hcl
source "amazon-ebs" "temporary" {
    # Generate temporary SSH key
    # Packer creates and destroys automatically
    
    # Temporary security group
    temporary_security_group_source_cidrs = ["10.0.0.0/16"]
    
    # Instance profile with minimal permissions
    iam_instance_profile = "packer-builder-role"
    
    # Encrypted EBS volumes
    encrypt_boot = true
    kms_key_id   = var.kms_key_id
    
    # Cleanup on completion
    force_deregister = false
    force_delete_snapshot = false
}
```

### Build Environment Validation

```bash
#!/bin/bash
# scripts/validate-build-environment.sh

set -e

echo "==> Validating build environment"

# Check network isolation
if curl -s --max-time 5 http://169.254.169.254/latest/meta-data/ > /dev/null; then
    echo "WARNING: Instance metadata accessible"
fi

# Verify encryption
DEVICE=$(lsblk -o NAME,TYPE | grep disk | head -1 | awk '{print $1}')
if ! cryptsetup status /dev/"$DEVICE" &> /dev/null; then
    echo "WARNING: Root volume not encrypted"
fi

# Check for unnecessary services
RUNNING_SERVICES=$(systemctl list-units --type=service --state=running | wc -l)
echo "Running services: $RUNNING_SERVICES"

# Verify security tools
command -v aide || echo "WARNING: AIDE not installed"
command -v fail2ban-client || echo "WARNING: fail2ban not installed"

echo "==> Environment validation complete"
```

## Compliance and Auditing

Maintain compliance and audit trails for image builds.

### Build Metadata Tracking

```hcl
locals {
    build_metadata = {
        build_date       = timestamp()
        builder_version  = packer.version
        git_commit       = var.git_commit
        git_branch       = var.git_branch
        build_number     = var.build_number
        builder_user     = env("USER")
        compliance_level = var.compliance_level
    }
}

source "amazon-ebs" "audited" {
    ami_name = var.ami_name
    
    tags = merge(local.build_metadata, {
        Name        = var.ami_name
        Project     = var.project_name
        Environment = var.environment
        CostCenter  = var.cost_center
        Compliance  = var.compliance_level
    })
}

build {
    sources = ["source.amazon-ebs.audited"]
    
    post-processor "manifest" {
        output = "manifest.json"
        custom_data = local.build_metadata
    }
    
    # Store audit log
    post-processor "shell-local" {
        inline = [
            "aws s3 cp manifest.json s3://audit-logs/packer/${local.build_metadata.build_date}/",
            "aws s3 cp packer.log s3://audit-logs/packer/${local.build_metadata.build_date}/"
        ]
    }
}
```

### Compliance Scanning

```bash
#!/bin/bash
# scripts/compliance-check.sh

set -e

echo "==> Running compliance checks"

# OpenSCAP scan for STIG compliance
oscap xccdf eval \
    --profile stig-rhel7-disa \
    --results-arf compliance-results.xml \
    --report compliance-report.html \
    /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml

# Check compliance score
SCORE=$(oscap info compliance-results.xml | grep "Score" | awk '{print $2}')

if (( $(echo "$SCORE < 80" | bc -l) )); then
    echo "ERROR: Compliance score below threshold: $SCORE"
    exit 1
fi

echo "==> Compliance check passed: $SCORE"
```

### Audit Logging

```hcl
provisioner "shell" {
    inline = [
        "# Enable comprehensive audit logging",
        "cat >> /etc/audit/rules.d/audit.rules <<EOF",
        "# Log all sudo commands",
        "-a always,exit -F arch=b64 -C euid!=uid -F euid=0 -S execve -k sudo_commands",
        "",
        "# Log all file deletions",
        "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete",
        "",
        "# Log privilege escalation",
        "-w /bin/su -p x -k priv_esc",
        "-w /usr/bin/sudo -p x -k priv_esc",
        "EOF",
        "",
        "service auditd restart"
    ]
}
```

## Access Control

Implement proper access controls for Packer operations.

### IAM Policy for Packer

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PackerImageBuilding",
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CopyImage",
                "ec2:CreateImage",
                "ec2:CreateKeypair",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSnapshot",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:DeleteKeyPair",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteSnapshot",
                "ec2:DeleteVolume",
                "ec2:DeregisterImage",
                "ec2:DescribeImageAttribute",
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeRegions",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DetachVolume",
                "ec2:GetPasswordData",
                "ec2:ModifyImageAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:ModifySnapshotAttribute",
                "ec2:RegisterImage",
                "ec2:RunInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances"
            ],
            "Resource": "*"
        },
        {
            "Sid": "PackerIAMPassRole",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::ACCOUNT-ID:role/packer-*"
        },
        {
            "Sid": "PackerKMSAccess",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey",
                "kms:Encrypt",
                "kms:GenerateDataKey",
                "kms:ReEncrypt*"
            ],
            "Resource": "arn:aws:kms:*:ACCOUNT-ID:key/*"
        }
    ]
}
```

### Least Privilege Principles

```hcl
# Use dedicated IAM role for build instances
source "amazon-ebs" "least-privilege" {
    iam_instance_profile = "packer-build-instance"
    
    # Instance can only access specific S3 buckets
    # Instance cannot modify IAM
    # Instance has read-only access to secrets
}
```

### Resource Tagging for Access Control

```hcl
source "amazon-ebs" "tagged" {
    tags = {
        Owner       = var.team_name
        Project     = var.project_name
        CostCenter  = var.cost_center
        Environment = var.environment
        ManagedBy   = "Packer"
    }
    
    run_tags = {
        Name       = "Packer Build Instance"
        Temporary  = "true"
        AutoDelete = "true"
    }
}
```

### Multi-Account Strategy

```hcl
# Build in dedicated account
source "amazon-ebs" "cross-account" {
    # Assume role in build account
    assume_role {
        role_arn     = "arn:aws:iam::BUILD-ACCOUNT:role/PackerBuilder"
        session_name = "packer-build-${local.timestamp}"
    }
    
    # Copy to target accounts
    ami_users = [
        "PROD-ACCOUNT-ID",
        "DEV-ACCOUNT-ID"
    ]
    
    # Encrypt with target account KMS key
    encrypt_boot = true
    kms_key_id   = "arn:aws:kms:us-east-1:TARGET-ACCOUNT:key/KEY-ID"
}
```

## Security Checklist

Before deploying images to production:

- ✅ **Credentials**: No hardcoded secrets, using secure credential management
- ✅ **Encryption**: All volumes encrypted at rest
- ✅ **Hardening**: System hardening applied (CIS benchmarks)
- ✅ **Updates**: Latest security patches installed
- ✅ **Scanning**: Vulnerability scan completed with acceptable results
- ✅ **Services**: Unnecessary services disabled
- ✅ **Firewall**: Firewall configured and enabled
- ✅ **SSH**: Root login disabled, key-based auth only
- ✅ **Auditing**: Audit logging configured
- ✅ **Monitoring**: Security monitoring tools installed
- ✅ **Compliance**: Compliance requirements met
- ✅ **Documentation**: Security configuration documented
- ✅ **Testing**: Security tests passed
- ✅ **Access Control**: Proper IAM policies applied

## Summary

Security best practices for Packer:

- **Never hardcode credentials**: Use environment variables, Vault, or IAM roles
- **Mark sensitive data**: Use `sensitive = true` for variables containing secrets
- **Harden images**: Apply security hardening during provisioning
- **Scan for vulnerabilities**: Implement automated vulnerability scanning
- **Isolate build environments**: Use dedicated VPCs and security groups
- **Maintain audit trails**: Track all builds with comprehensive metadata
- **Apply least privilege**: Use minimal IAM permissions for Packer operations
- **Encrypt everything**: Enable encryption for all volumes and snapshots
- **Automate compliance**: Use tools like OpenSCAP for compliance validation
- **Regular updates**: Schedule regular image rebuilds with latest patches

Security is not a one-time task but an ongoing process that should be integrated into every stage of your image building pipeline
