---
uid: infrastructure.packer.troubleshooting
title: Troubleshooting Packer Builds
description: Comprehensive guide to diagnosing and resolving common Packer build issues including errors, debugging techniques, and log analysis
ms.date: 01/18/2026
---

This section covers common issues encountered during Packer builds and provides practical troubleshooting techniques to diagnose and resolve them effectively.

## Common Build Errors

### Template Syntax Errors

#### Invalid HCL Syntax

**Error Message:**

```text
Error: Invalid expression

on template.pkr.hcl line 15, in source "amazon-ebs" "ubuntu":
Expected the start of an expression, but found an invalid expression token.
```

**Cause:** Syntax errors in HCL configuration, such as missing brackets, quotes, or incorrect formatting.

**Solution:**

```bash
# Validate template syntax
packer validate template.pkr.hcl

# Format template to fix minor issues
packer fmt template.pkr.hcl

# Check for common syntax issues
packer validate -syntax-only template.pkr.hcl
```

#### Undefined Variables

**Error Message:**

```text
Error: Reference to undeclared input variable

on template.pkr.hcl line 23:
There is no variable named "instance_type".
```

**Cause:** Variable used in template but not declared in variables block.

**Solution:**

```hcl
# Add variable declaration
variable "instance_type" {
  type        = string
  description = "EC2 instance type for building"
  default     = "t2.micro"
}
```

#### Missing Required Plugins

**Error Message:**

```text
Error: Failed to discover plugin

Could not find compatible versions for provider "amazon".
```

**Cause:** Required plugins not installed or incompatible versions.

**Solution:**

```hcl
# Add required_plugins block
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
```

```bash
# Initialize plugins
packer init template.pkr.hcl
```

### Source AMI Not Found

**Error Message:**

```text
Error: No matching AMI found

The source AMI filter returned no results.
```

**Cause:** AMI filter criteria don't match any available images, or searching in wrong region.

**Solution:**

```hcl
# Verify filter criteria
source "amazon-ebs" "ubuntu" {
  region = "us-east-1"
  
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]  # Canonical's AWS account
  }
}
```

**Debugging Tips:**

```bash
# Search for AMIs manually
aws ec2 describe-images \
  --region us-east-1 \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images[*].[ImageId,Name,CreationDate]' \
  --output table
```

### Timeout Errors

**Error Message:**

```text
Error: Timeout waiting for SSH

Timeout waiting for SSH to become available.
```

**Cause:** Instance not accessible via SSH within timeout period, security group restrictions, or networking issues.

**Solution:**

```hcl
source "amazon-ebs" "ubuntu" {
  # Increase timeout
  ssh_timeout = "10m"
  
  # Ensure proper security group
  security_group_filter {
    filters = {
      "tag:Name" = "packer-ssh-access"
    }
  }
  
  # Verify SSH settings
  ssh_username = "ubuntu"
  ssh_interface = "public_ip"
  
  # Enable detailed logging
  ssh_handshake_attempts = 50
}
```

**Additional Checks:**

```bash
# Test SSH connectivity manually
ssh -i key.pem ubuntu@instance-ip

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Verify instance is running
aws ec2 describe-instances --instance-ids i-xxxxx
```

### Insufficient Permissions

**Error Message:**

```text
Error: AuthFailure

You are not authorized to perform this operation.
```

**Cause:** AWS credentials lack necessary permissions for Packer operations.

**Required IAM Permissions:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
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
    }
  ]
}
```

## Debugging Templates

### Enable Debug Mode

Run Packer with detailed logging to diagnose issues:

```bash
# Set PACKER_LOG environment variable
export PACKER_LOG=1
export PACKER_LOG_PATH="packer-debug.log"

# Run build with debug output
packer build template.pkr.hcl

# Review the log file
less packer-debug.log
```

### Inspect Mode

Use inspect mode to view template configuration without building:

```bash
# Display parsed template configuration
packer inspect template.pkr.hcl

# View specific section
packer inspect -var-file=variables.pkrvars.hcl template.pkr.hcl
```

### Console Mode

Use Packer console for interactive debugging:

```bash
# Start interactive console
packer console template.pkr.hcl

# Test expressions interactively
> var.instance_type
"t2.micro"

> local.timestamp
"20260118-1430"

> source.amazon-ebs.ubuntu
{
  "region" = "us-east-1"
  "instance_type" = "t2.micro"
  ...
}
```

### Step-by-Step Debugging

Break down provisioning into smaller steps:

```hcl
# Add debug provisioner between steps
provisioner "shell" {
  inline = ["echo 'Step 1 complete'"]
}

provisioner "shell" {
  inline = ["sleep 5"]  # Pause to inspect
}

provisioner "shell" {
  inline = ["echo 'Step 2 starting'"]
}
```

### Pause Before Provisioning

Add a pause to manually inspect the instance:

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]
  
  # Pause before provisioning
  provisioner "breakpoint" {
    note = "Paused for manual inspection"
  }
  
  provisioner "shell" {
    scripts = ["provision.sh"]
  }
}
```

### Remote Shell Access

Connect to the build instance during execution:

```bash
# In terminal 1: Start build with -on-error flag
PACKER_LOG=1 packer build -on-error=ask template.pkr.hcl

# When error occurs, choose to keep instance running
# In terminal 2: SSH to the instance
ssh -i /tmp/packer-key ubuntu@instance-ip

# Inspect the system
cat /var/log/syslog
ps aux
df -h
```

## Network Issues

### VPC and Subnet Configuration

**Error Message:**

```text
Error: InvalidSubnet

The subnet 'subnet-xxxxx' does not exist.
```

**Cause:** Subnet not available or incorrect VPC configuration.

**Solution:**

```hcl
source "amazon-ebs" "ubuntu" {
  region = "us-east-1"
  
  # Specify VPC settings explicitly
  vpc_filter {
    filters = {
      "tag:Environment" = "production"
      "isDefault"       = "false"
    }
  }
  
  subnet_filter {
    filters = {
      "tag:Class" = "build"
    }
    most_free = true
    random    = false
  }
  
  # Ensure instance has internet access
  associate_public_ip_address = true
}
```

### Internet Connectivity

**Issue:** Provisioners fail to download packages or access external resources.

**Diagnosis:**

```hcl
# Add connectivity test
provisioner "shell" {
  inline = [
    "echo 'Testing internet connectivity...'",
    "ping -c 4 8.8.8.8",
    "curl -I https://www.google.com",
    "nslookup ubuntu.com"
  ]
}
```

**Solutions:**

1. **NAT Gateway Required:**

```hcl
# Use subnet with NAT gateway for private subnet builds
subnet_filter {
  filters = {
    "tag:Type" = "private-with-nat"
  }
}
```

1. **Use Public Subnet:**

```hcl
source "amazon-ebs" "ubuntu" {
  # Build in public subnet
  associate_public_ip_address = true
  
  subnet_filter {
    filters = {
      "tag:Type" = "public"
    }
  }
}
```

### Proxy Configuration

**Issue:** Build fails behind corporate proxy.

**Solution:**

```hcl
provisioner "shell" {
  environment_vars = [
    "http_proxy=${var.http_proxy}",
    "https_proxy=${var.https_proxy}",
    "no_proxy=169.254.169.254,localhost"
  ]
  inline = [
    "export http_proxy=${var.http_proxy}",
    "export https_proxy=${var.https_proxy}",
    "apt-get update"
  ]
}
```

```bash
# Set proxy for Packer itself
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
export NO_PROXY=169.254.169.254

packer build template.pkr.hcl
```

### DNS Resolution Issues

**Error Message:**

```text
Error: Could not resolve host: archive.ubuntu.com
```

**Solution:**

```hcl
provisioner "shell" {
  inline = [
    "echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf.new",
    "echo 'nameserver 8.8.4.4' | sudo tee -a /etc/resolv.conf.new",
    "sudo mv /etc/resolv.conf.new /etc/resolv.conf",
    "apt-get update"
  ]
}
```

## Authentication Problems

### AWS Credentials Issues

**Error Message:**

```text
Error: NoCredentialProviders

No valid credential sources found.
```

**Diagnosis:**

```bash
# Check AWS CLI configuration
aws sts get-caller-identity

# Verify credentials are set
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
echo $AWS_SESSION_TOKEN  # For assumed roles
```

**Solutions:**

1. **Use AWS Profile:**

```bash
# Set profile before running Packer
export AWS_PROFILE=packer-user
packer build template.pkr.hcl
```

```hcl
# Or specify in template
source "amazon-ebs" "ubuntu" {
  profile = "packer-user"
  region  = "us-east-1"
}
```

1. **Use Environment Variables:**

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

1. **Use IAM Role (Recommended):**

```bash
# When running on EC2 instance
# Attach IAM role with required permissions
# Packer automatically uses instance profile
```

### Azure Authentication

**Error Message:**

```text
Error: Authorization failed for this request.
```

**Solutions:**

```bash
# Login with Azure CLI
az login

# Set subscription
az account set --subscription "subscription-id"

# Verify authentication
az account show
```

```hcl
# Use service principal
source "azure-arm" "ubuntu" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
```

### SSH Key Issues

**Error Message:**

```text
Error: Permission denied (publickey)
```

**Solutions:**

1. **Generate Temporary Key Pair:**

```hcl
source "amazon-ebs" "ubuntu" {
  # Packer generates temporary key pair
  ssh_username = "ubuntu"
  # Don't specify ssh_keypair_name or ssh_private_key_file
}
```

1. **Use Existing Key Pair:**

```hcl
source "amazon-ebs" "ubuntu" {
  ssh_username         = "ubuntu"
  ssh_keypair_name     = "my-keypair"
  ssh_private_key_file = "~/.ssh/my-keypair.pem"
}
```

## Resource Constraints

### Disk Space Issues

**Error Message:**

```text
Error: No space left on device
```

**Diagnosis:**

```hcl
provisioner "shell" {
  inline = [
    "df -h",
    "du -sh /tmp/*",
    "du -sh /var/*"
  ]
}
```

**Solutions:**

1. **Increase Volume Size:**

```hcl
source "amazon-ebs" "ubuntu" {
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 30  # Increased from default 8GB
    volume_type           = "gp3"
    delete_on_termination = true
  }
}
```

1. **Clean Up During Provisioning:**

```hcl
provisioner "shell" {
  inline = [
    "sudo apt-get clean",
    "sudo rm -rf /tmp/*",
    "sudo rm -rf /var/tmp/*"
  ]
}
```

### Memory Issues

**Error Message:**

```text
Error: Cannot allocate memory
```

**Solution:**

```hcl
source "amazon-ebs" "ubuntu" {
  # Use larger instance type
  instance_type = "t3.large"  # 2 vCPU, 8GB RAM
  
  # Or use memory-optimized instance
  instance_type = "r5.large"  # 2 vCPU, 16GB RAM
}
```

### Instance Limit Exceeded

**Error Message:**

```text
Error: InstanceLimitExceeded

You have reached your instance limit.
```

**Solutions:**

1. **Request Limit Increase:** Contact AWS Support to increase EC2 instance limits.

1. **Use Different Instance Type:**

```hcl
source "amazon-ebs" "ubuntu" {
  # Try different instance family
  instance_type = "t3.micro"
}
```

1. **Clean Up Old Instances:**

```bash
# Terminate old build instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Packer Builder" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text | xargs -I {} aws ec2 terminate-instances --instance-ids {}
```

## Provisioner Failures

### Shell Provisioner Errors

**Error Message:**

```text
Error: Script exited with non-zero exit status: 127
```

**Cause:** Command not found or script failure.

**Debugging:**

```hcl
provisioner "shell" {
  # Add error handling
  inline = [
    "set -x",  # Enable debug output
    "set -e",  # Exit on error
    "command -v docker || echo 'Docker not found'",
    "which python3 || echo 'Python3 not found'"
  ]
}
```

**Solutions:**

1. **Add Error Handling:**

```hcl
provisioner "shell" {
  inline = [
    "#!/bin/bash",
    "set -euo pipefail",
    "if ! command -v nginx &> /dev/null; then",
    "  echo 'Installing nginx...'",
    "  sudo apt-get update && sudo apt-get install -y nginx",
    "fi"
  ]
}
```

1. **Use Valid On Error:**

```hcl
provisioner "shell" {
  valid_exit_codes = [0, 2]  # Accept multiple exit codes
  inline = [
    "command_that_might_fail || exit 2"
  ]
}
```

1. **Continue On Error:**

```hcl
build {
  error_cleanup_provisioner {
    inline = [
      "echo 'Cleaning up after error...'",
      "sudo rm -f /tmp/failed-build"
    ]
  }
}
```

### Ansible Provisioner Issues

**Error Message:**

```text
Error: Failed to execute ansible-playbook
```

**Debugging:**

```hcl
provisioner "ansible" {
  playbook_file = "playbook.yml"
  
  # Enable verbose output
  extra_arguments = [
    "-vvv",
    "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
  ]
  
  # Use specific Ansible version
  ansible_env_vars = [
    "ANSIBLE_HOST_KEY_CHECKING=False",
    "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'"
  ]
}
```

### File Upload Failures

**Error Message:**

```text
Error: Failed to upload file
```

**Solution:**

```hcl
provisioner "file" {
  source      = "files/config.yaml"
  destination = "/tmp/config.yaml"
  
  # Ensure proper permissions
  direction = "upload"
}

provisioner "shell" {
  inline = [
    "sudo mv /tmp/config.yaml /etc/myapp/config.yaml",
    "sudo chown root:root /etc/myapp/config.yaml",
    "sudo chmod 644 /etc/myapp/config.yaml"
  ]
}
```

## Log Analysis

### Finding Log Files

**Packer Logs:**

```bash
# Enable logging
export PACKER_LOG=1
export PACKER_LOG_PATH="packer-$(date +%Y%m%d-%H%M%S).log"

# View logs in real-time
tail -f $PACKER_LOG_PATH
```

**System Logs on Build Instance:**

```hcl
# Capture system logs before cleanup
provisioner "shell" {
  inline = [
    "sudo journalctl > /tmp/system.log",
    "sudo dmesg > /tmp/dmesg.log"
  ]
}

# Download logs
post-processor "shell-local" {
  inline = [
    "scp -i key.pem ubuntu@${build.Host}:/tmp/system.log ./logs/",
    "scp -i key.pem ubuntu@${build.Host}:/tmp/dmesg.log ./logs/"
  ]
}
```

### Common Log Patterns

**Connection Issues:**

```text
# SSH timeout
Waiting for SSH to become available...
Timeout waiting for SSH
```

**Permission Errors:**

```text
# AWS permissions
Error: UnauthorizedOperation
You are not authorized to perform this operation
```

**Network Problems:**

```text
# DNS or network failure
Could not resolve host: archive.ubuntu.com
Connection timed out
```

### Analyzing Build Performance

```bash
# Enable timestamps in logs
export PACKER_LOG=1
export PACKER_LOG_PATH="packer.log"

# Analyze build duration
grep "Starting build" packer.log
grep "Build finished" packer.log

# Find slow provisioners
grep "Starting provisioner" packer.log
grep "Provisioning step had errors" packer.log
```

### Debug Output Filtering

```bash
# Filter specific components
grep "amazon-ebs.ubuntu" packer.log

# Show only errors
grep -i "error" packer.log

# Show warnings
grep -i "warning" packer.log

# Find authentication issues
grep -i "auth" packer.log
```

## Recovery Strategies

### Save Failed Build State

```bash
# Keep instance running on error
packer build -on-error=ask template.pkr.hcl

# Options when error occurs:
# - cleanup: Terminate instance (default)
# - abort: Exit Packer but leave instance running
# - ask: Prompt for action
# - run-cleanup-provisioner: Run cleanup steps then ask
```

### Manual Intervention

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]
  
  # Add breakpoint for manual intervention
  provisioner "breakpoint" {
    note = "Check intermediate state"
  }
  
  error_cleanup_provisioner {
    inline = [
      "echo 'Saving debug information...'",
      "sudo tar czf /tmp/debug-info.tar.gz /var/log /tmp/*.log"
    ]
  }
}
```

### Incremental Builds

Break complex builds into stages:

```hcl
# Stage 1: Base image with OS updates
build {
  name = "base"
  sources = ["source.amazon-ebs.ubuntu"]
  
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y"
    ]
  }
}

# Stage 2: Application installation (uses base image)
build {
  name = "application"
  sources = ["source.amazon-ebs.app"]
  
  provisioner "shell" {
    scripts = ["install-app.sh"]
  }
}
```

## Summary

Effective troubleshooting requires:

- **Systematic approach**: Enable logging, isolate issues, test incrementally
- **Understanding errors**: Read error messages carefully, check documentation
- **Proper debugging**: Use Packer's built-in debugging tools and techniques
- **Prevention**: Follow best practices, validate templates, test regularly
- **Documentation**: Keep logs, document solutions, share knowledge

Common troubleshooting workflow:

1. **Enable debug logging** with `PACKER_LOG=1`
2. **Validate template syntax** with `packer validate`
3. **Test connectivity** and permissions before building
4. **Use breakpoints** to inspect intermediate state
5. **Analyze logs** for specific error patterns
6. **Isolate failures** by testing provisioners individually
7. **Document solutions** for future reference

With these troubleshooting techniques, you can quickly diagnose and resolve most Packer build issues
