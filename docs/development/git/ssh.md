# SSH Authentication for Git: Complete Guide

SSH (Secure Shell) authentication is the gold standard for secure Git operations, providing cryptographic authentication without transmitting passwords over the network. This comprehensive guide covers SSH key management, configuration strategies, and advanced security practices for professional Git workflows across multiple platforms and services.

## Understanding SSH Authentication

### SSH Fundamentals for Git

SSH authentication uses public-key cryptography to establish secure connections between your local machine and Git hosting services¹. This method offers several advantages over HTTPS authentication:

#### Benefits of SSH Authentication

- **Enhanced Security**: Eliminates password transmission over networks
- **Convenience**: No repeated password prompts after initial setup
- **Multi-Account Support**: Easy management of multiple Git service accounts
- **Corporate Compliance**: Meets enterprise security requirements
- **Automation Friendly**: Ideal for CI/CD pipelines and scripts

#### SSH vs HTTPS Comparison

| Aspect | SSH | HTTPS |
| ------ | --- | ----- |
| **Security** | Public key cryptography | Token/password based |
| **Setup Complexity** | Moderate (key generation required) | Simple (username/token) |
| **Multi-Account** | Excellent (config-based) | Limited (credential switching) |
| **Corporate Firewalls** | May be blocked (port 22) | Usually allowed (port 443) |
| **CI/CD Integration** | Excellent | Good with tokens |

### SSH Key Types and Algorithms

#### Modern Key Algorithms

**Ed25519 (Recommended)**: Modern elliptic curve algorithm offering excellent security and performance²

```bash
# Generate Ed25519 key (preferred)
ssh-keygen -t ed25519 -C "your.email@example.com"
```

**RSA**: Legacy algorithm, use 4096-bit keys minimum for adequate security

```bash
# Generate RSA key (legacy compatibility)
ssh-keygen -t rsa -b 4096 -C "your.email@example.com"
```

**ECDSA**: Elliptic curve alternative, less preferred than Ed25519

```bash
# Generate ECDSA key (alternative)
ssh-keygen -t ecdsa -b 521 -C "your.email@example.com"
```

#### Key Security Considerations

- **Ed25519**: 256-bit security, fastest performance, smallest key size
- **RSA 4096**: Equivalent security but larger keys and slower operations
- **Avoid RSA < 2048**: Considered cryptographically weak
- **ECDSA concerns**: Potential implementation vulnerabilities

## SSH Key Generation and Management

### Advanced Key Generation

#### Secure Key Generation Process

```bash
# Create SSH directory with proper permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate Ed25519 key with custom filename
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -C "github-work-account"

# Generate key with increased KDF rounds for additional security
ssh-keygen -t ed25519 -a 200 -f ~/.ssh/id_ed25519_secure -C "high-security-key"

# Generate key with passphrase for additional protection
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_protected -C "protected-key"
```

#### Passphrase Best Practices

```bash
# Generate key with strong passphrase
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_work -C "work@company.com"
# Enter secure passphrase when prompted

# Use SSH agent to cache passphrase
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_work
# Enter passphrase once per session

# Configure SSH agent to persist across sessions (macOS)
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_work
```

#### Key Naming Conventions

Adopt consistent naming patterns for easy management:

```bash
# Service-based naming
~/.ssh/id_ed25519_github_personal
~/.ssh/id_ed25519_github_work  
~/.ssh/id_ed25519_gitlab_company
~/.ssh/id_ed25519_azure_devops

# Purpose-based naming
~/.ssh/id_ed25519_development
~/.ssh/id_ed25519_production
~/.ssh/id_ed25519_ci_cd
```

### SSH Agent Configuration

#### Starting and Managing SSH Agent

```bash
# Start SSH agent (Linux/macOS)
eval "$(ssh-agent -s)"

# Add keys to agent
ssh-add ~/.ssh/id_ed25519_github
ssh-add ~/.ssh/id_ed25519_gitlab

# List loaded keys
ssh-add -l

# Remove specific key from agent
ssh-add -d ~/.ssh/id_ed25519_github

# Remove all keys from agent
ssh-add -D

# Kill SSH agent
ssh-agent -k
```

#### Persistent SSH Agent (Linux/macOS)

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Auto-start SSH agent
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! "$SSH_AUTH_SOCK" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

# Auto-add keys
ssh-add -l >/dev/null || ssh-add ~/.ssh/id_ed25519_default
```

#### Windows SSH Agent (OpenSSH)

```powershell
# Enable SSH Agent service (run as Administrator)
Get-Service ssh-agent | Set-Service -StartupType Automatic -PassThru | Start-Service

# Add key to agent
ssh-add C:\Users\YourName\.ssh\id_ed25519

# Configure PowerShell profile for auto-start
Add-Content $PROFILE @'
if (Get-Service ssh-agent | Where-Object {$_.Status -eq "Stopped"}) {
    Start-Service ssh-agent
}
'@
```

## SSH Configuration Management

### Comprehensive SSH Config

The SSH configuration file (`~/.ssh/config`) is crucial for managing multiple accounts and services³:

#### Basic Multi-Service Configuration

```ssh-config
# GitHub Personal Account
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_personal
    IdentitiesOnly yes
    AddKeysToAgent yes

# GitHub Work Account (using alias)
Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_work
    IdentitiesOnly yes
    AddKeysToAgent yes

# GitLab Company
Host gitlab.company.com
    HostName gitlab.company.com
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
    IdentitiesOnly yes
    Port 2222

# Azure DevOps
Host ssh.dev.azure.com
    HostName ssh.dev.azure.com
    User git
    IdentityFile ~/.ssh/id_ed25519_azure
    IdentitiesOnly yes
    PubkeyAcceptedKeyTypes +ssh-rsa
    HostkeyAlgorithms +ssh-rsa
```

#### Advanced Configuration Options

```ssh-config
# High-security configuration
Host secure-git
    HostName git.secure-company.com
    User git
    Port 443
    IdentityFile ~/.ssh/id_ed25519_secure
    IdentitiesOnly yes
    
    # Security settings
    PubkeyAuthentication yes
    PasswordAuthentication no
    ChallengeResponseAuthentication no
    
    # Connection settings
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 30
    
    # Cipher preferences
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512

# Jump host configuration for corporate environments
Host internal-git
    HostName git.internal.company.com
    User git
    ProxyJump bastion.company.com
    IdentityFile ~/.ssh/id_ed25519_internal
    IdentitiesOnly yes

# Development environment with custom port
Host dev-git
    HostName dev.git.local
    User git
    Port 2222
    IdentityFile ~/.ssh/id_ed25519_dev
    IdentitiesOnly yes
    StrictHostKeyChecking no  # Only for development!
```

#### File Permissions and Security

```bash
# Set correct permissions for SSH directory and files
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub
chmod 644 ~/.ssh/config
chmod 644 ~/.ssh/known_hosts

# Verify permissions
ls -la ~/.ssh/
```

### Multi-Account Workflow Examples

#### GitHub Multiple Accounts

```ssh-config
# Personal GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes

# Work GitHub
Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes
```

**Usage Examples:**

```bash
# Clone personal repository
git clone git@github.com:username/personal-repo.git

# Clone work repository using alias
git clone git@github-work:company/work-repo.git

# Change existing repository remote
cd existing-work-repo
git remote set-url origin git@github-work:company/work-repo.git
```

## Platform-Specific Configuration

### GitHub Configuration

#### GitHub-Specific Settings

```ssh-config
Host *.github.com
    User git
    Protocol 2
    
    # GitHub-specific optimizations
    Compression yes
    TCPKeepAlive yes
    
    # GitHub supports these key types
    PubkeyAcceptedKeyTypes ssh-ed25519,ecdsa-sha2-nistp256,ssh-rsa
```

#### GitHub Enterprise Configuration

```ssh-config
Host github.enterprise.com
    HostName github.enterprise.com  
    User git
    Port 443  # If using HTTPS port
    IdentityFile ~/.ssh/id_ed25519_enterprise
    IdentitiesOnly yes
    
    # Enterprise-specific settings
    StrictHostKeyChecking yes
    UserKnownHostsFile ~/.ssh/known_hosts_enterprise
```

### GitLab Configuration

#### GitLab.com and Self-Hosted

```ssh-config
# GitLab.com
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
    IdentitiesOnly yes
    PreferredAuthentications publickey

# Self-hosted GitLab
Host gitlab.mycompany.com
    HostName gitlab.mycompany.com
    User git
    Port 2222
    IdentityFile ~/.ssh/id_ed25519_company_gitlab
    IdentitiesOnly yes
    
    # Custom CA certificates if needed
    CertificateFile ~/.ssh/company-ca.pem
```

### Azure DevOps Configuration

#### Azure DevOps SSH Setup

```ssh-config
Host ssh.dev.azure.com
    HostName ssh.dev.azure.com
    User git
    IdentityFile ~/.ssh/id_ed25519_azure
    IdentitiesOnly yes
    
    # Azure DevOps still requires RSA for some operations
    PubkeyAcceptedKeyTypes +ssh-rsa
    HostkeyAlgorithms +ssh-rsa
    
    # Connection optimization
    ServerAliveInterval 15
    ServerAliveCountMax 3
```

#### Visual Studio Team Services (Legacy)

```ssh-config
Host vs-ssh.visualstudio.com
    HostName vs-ssh.visualstudio.com
    User git
    IdentityFile ~/.ssh/id_rsa_vsts
    
    # Legacy VSTS requires RSA
    PubkeyAcceptedKeyTypes ssh-rsa
    HostkeyAlgorithms +ssh-rsa
    IdentitiesOnly yes
```

## SSH Key Deployment and Management

### Adding Public Keys to Services

#### GitHub Key Management

```bash
# Copy public key to clipboard (macOS)
pbcopy < ~/.ssh/id_ed25519_github.pub

# Copy public key to clipboard (Linux)
xclip -sel clip < ~/.ssh/id_ed25519_github.pub

# Copy public key to clipboard (Windows)
Get-Content ~/.ssh/id_ed25519_github.pub | Set-Clipboard
```

**GitHub Web Interface Steps:**

1. Navigate to **Settings** → **SSH and GPG keys**
2. Click **New SSH key**
3. Provide descriptive title (e.g., "Development Laptop - Ed25519")
4. Paste public key content
5. Click **Add SSH key**

#### GitLab Key Management

```bash
# Display public key for copying
cat ~/.ssh/id_ed25519_gitlab.pub
```

**GitLab Web Interface Steps:**

1. Navigate to **User Settings** → **SSH Keys**
2. Paste public key in **Key** field
3. Add descriptive title
4. Set expiration date (recommended)
5. Click **Add key**

#### Azure DevOps Key Management

```bash
# Display public key
cat ~/.ssh/id_ed25519_azure.pub
```

**Azure DevOps Steps:**

1. Navigate to **User Settings** → **SSH public keys**
2. Click **New Key**
3. Provide key name and paste public key
4. Click **Add**

### Automated Key Deployment

#### Script for Multiple Services

```bash
#!/bin/bash
# deploy-ssh-keys.sh

SERVICES=("github.com" "gitlab.com" "ssh.dev.azure.com")
KEY_FILE="$HOME/.ssh/id_ed25519.pub"

if [ ! -f "$KEY_FILE" ]; then
    echo "Public key not found: $KEY_FILE"
    exit 1
fi

PUBLIC_KEY=$(cat "$KEY_FILE")

echo "Public Key to deploy:"
echo "$PUBLIC_KEY"
echo
echo "Deploy this key to the following services:"

for service in "${SERVICES[@]}"; do
    echo "- $service"
done

echo
echo "Key fingerprint:"
ssh-keygen -lf "$KEY_FILE"
```

## Connection Testing and Troubleshooting

### Comprehensive Connection Testing

#### Basic Connection Tests

```bash
# Test GitHub connection
ssh -T git@github.com

# Test GitLab connection  
ssh -T git@gitlab.com

# Test Azure DevOps connection
ssh -T git@ssh.dev.azure.com

# Expected successful responses:
# GitHub: "Hi username! You've successfully authenticated..."
# GitLab: "Welcome to GitLab, @username!"
# Azure DevOps: "remote: Shell access is not supported."
```

#### Advanced Debugging

```bash
# Verbose SSH debugging
ssh -vvv -T git@github.com

# Test specific key file
ssh -i ~/.ssh/id_ed25519_specific -T git@github.com

# Test with specific configuration
ssh -F ~/.ssh/config_test -T git@github.com

# Test connection with specific algorithm
ssh -o PubkeyAcceptedKeyTypes=ssh-ed25519 -T git@github.com
```

#### Connection Analysis Tools

```bash
# Check SSH agent status
ssh-add -l

# Test key loading
ssh-add -T ~/.ssh/id_ed25519.pub

# Verify key format
ssh-keygen -l -f ~/.ssh/id_ed25519

# Check SSH client version
ssh -V

# Test DNS resolution
nslookup github.com
dig github.com
```

### Common Issues and Solutions

#### Authentication Failures

**Problem**: Permission denied (publickey)

```bash
# Diagnosis steps
ssh-add -l  # Check loaded keys
ssh -vvv -T git@github.com  # Verbose debugging

# Common solutions
ssh-add ~/.ssh/id_ed25519  # Add key to agent
chmod 600 ~/.ssh/id_ed25519  # Fix permissions
```

#### Key Format Issues

**Problem**: Invalid key format

```bash
# Check key format
file ~/.ssh/id_ed25519
ssh-keygen -l -f ~/.ssh/id_ed25519

# Convert OpenSSH format if needed
ssh-keygen -p -m OpenSSH -f ~/.ssh/id_ed25519
```

#### Connection Timeouts

**Problem**: Connection timeouts or refused connections

```bash
# Test different ports
ssh -p 443 -T git@ssh.github.com  # GitHub HTTPS port
ssh -p 2222 -T git@gitlab.example.com  # Common alternate port

# Configure timeout settings in ~/.ssh/config
Host *
    ConnectTimeout 30
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

#### Multiple Key Conflicts

**Problem**: Wrong key being used

```bash
# Use IdentitiesOnly in config
Host github.com
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id_ed25519_github

# Clear agent and re-add specific key
ssh-add -D
ssh-add ~/.ssh/id_ed25519_github
```

## Advanced SSH Security

### Security Hardening

#### SSH Client Hardening

```ssh-config
# Global security settings in ~/.ssh/config
Host *
    # Disable weak authentication methods
    PasswordAuthentication no
    ChallengeResponseAuthentication no
    GSSAPIAuthentication no
    
    # Enable public key authentication only
    PubkeyAuthentication yes
    
    # Strict host key checking
    StrictHostKeyChecking ask
    
    # Modern cipher preferences
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
    
    # Connection security
    Protocol 2
    Compression no
    TCPKeepAlive no
    ServerAliveInterval 300
    ServerAliveCountMax 2
```

#### Key Rotation Strategy

```bash
#!/bin/bash
# key-rotation.sh

OLD_KEY="$HOME/.ssh/id_ed25519_old"
NEW_KEY="$HOME/.ssh/id_ed25519_new"

# Generate new key
ssh-keygen -t ed25519 -f "$NEW_KEY" -C "rotated-$(date +%Y%m%d)"

# Test new key
ssh-add "$NEW_KEY"
ssh -T git@github.com

echo "New key generated and tested successfully"
echo "1. Add new public key to all services"
echo "2. Test all repositories"
echo "3. Remove old key from services"
echo "4. Remove old key files"

cat "$NEW_KEY.pub"
```

#### Certificate-Based Authentication

```bash
# Generate SSH certificate (advanced)
ssh-keygen -s ca_key -I user_identifier -n principal ~/.ssh/id_ed25519.pub

# Configure certificate authentication
Host secure-git
    CertificateFile ~/.ssh/id_ed25519-cert.pub
    IdentityFile ~/.ssh/id_ed25519
```

### Monitoring and Auditing

#### SSH Connection Logging

```bash
# Enable SSH client logging
ssh -o LogLevel=DEBUG3 -T git@github.com 2>&1 | tee ssh-debug.log

# Monitor SSH agent activity  
SSH_AUTH_SOCK=/tmp/ssh-monitor ssh-agent -D -d
```

#### Key Usage Auditing

```bash
#!/bin/bash
# audit-ssh-usage.sh

echo "=== SSH Key Audit Report ==="
echo "Generated: $(date)"
echo

# List all SSH keys
echo "SSH Keys Found:"
find ~/.ssh -name "id_*" -not -name "*.pub" | while read key; do
    echo "Key: $key"
    ssh-keygen -l -f "$key"
    echo "Created: $(stat -c %y "$key")"
    echo
done

# Check SSH agent status
echo "SSH Agent Status:"
ssh-add -l 2>/dev/null || echo "SSH agent not running"
echo

# Test key connections
echo "Connection Tests:"
for host in github.com gitlab.com ssh.dev.azure.com; do
    echo -n "Testing $host: "
    timeout 10 ssh -o ConnectTimeout=5 -T git@"$host" 2>/dev/null && echo "✓ Success" || echo "✗ Failed"
done
```

## CI/CD and Automation

### SSH in CI/CD Pipelines

#### GitHub Actions SSH Setup

```yaml
# .github/workflows/deploy.yml
name: Deploy with SSH

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup SSH
        uses: webfactory/ssh-agent@v0.7.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
      
      - name: Test SSH connection
        run: ssh -T git@github.com
        
      - name: Deploy
        run: |
          git clone git@github.com:company/deployment-repo.git
          # Deployment steps here
```

#### GitLab CI SSH Configuration

```yaml
# .gitlab-ci.yml
before_script:
  - 'command -v ssh-agent >/dev/null || ( apt-get update -y && apt-get install openssh-client -y )'
  - eval $(ssh-agent -s)
  - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
  - mkdir -p ~/.ssh
  - chmod 700 ~/.ssh
  - ssh-keyscan gitlab.com >> ~/.ssh/known_hosts
  - chmod 644 ~/.ssh/known_hosts

deploy:
  script:
    - ssh -T git@gitlab.com
    - git clone git@gitlab.com:group/project.git
```

#### Jenkins SSH Integration

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        SSH_KEY = credentials('ssh-deploy-key')
    }
    
    stages {
        stage('Setup SSH') {
            steps {
                sh '''
                    eval $(ssh-agent -s)
                    ssh-add $SSH_KEY
                    ssh-keyscan github.com >> ~/.ssh/known_hosts
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                sh 'git clone git@github.com:company/repo.git'
            }
        }
    }
}
```

### Docker and Containerized Environments

#### SSH in Docker Builds

```dockerfile
# Dockerfile with SSH support
FROM alpine:latest

RUN apk add --no-cache openssh-client git

# Copy SSH configuration
COPY --chmod=600 id_ed25519 /root/.ssh/
COPY --chmod=644 id_ed25519.pub /root/.ssh/
COPY --chmod=644 config /root/.ssh/

RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

# Test SSH connection during build
RUN ssh -T git@github.com || true

CMD ["sh"]
```

#### Multi-stage Docker Build with SSH

```dockerfile
# syntax = docker/dockerfile:1.4
FROM alpine:latest as ssh-base

RUN apk add --no-cache openssh-client git

# Mount SSH key during build
RUN --mount=type=ssh \
    ssh-keyscan github.com >> /root/.ssh/known_hosts && \
    git clone git@github.com:private/repo.git /app

FROM alpine:latest
COPY --from=ssh-base /app /app
```

## Enterprise and Corporate Environments

### Corporate SSH Policies

#### Compliance Requirements

```bash
# Generate keys with corporate standards
ssh-keygen -t ed25519 -a 200 -f ~/.ssh/id_ed25519_corp -C "employee@company.com"

# Corporate hardening script
#!/bin/bash
# corporate-ssh-hardening.sh

# Set restrictive permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub
chmod 644 ~/.ssh/config

# Configure corporate settings
cat >> ~/.ssh/config << EOF
Host *.company.com
    User git
    IdentitiesOnly yes
    StrictHostKeyChecking yes
    UserKnownHostsFile ~/.ssh/known_hosts_company
    
    # Corporate security requirements
    PubkeyAuthentication yes
    PasswordAuthentication no
    ChallengeResponseAuthentication no
    
    # Approved algorithms only
    PubkeyAcceptedKeyTypes ssh-ed25519,ecdsa-sha2-nistp256
    KexAlgorithms curve25519-sha256@libssh.org
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
EOF
```

#### Centralized Key Management

```bash
# Corporate key management script
#!/bin/bash
# corporate-key-manager.sh

LDAP_USER=$(whoami)
KEY_SERVER="keys.company.com"
CORPORATE_CA="/etc/ssh/company_ca.pub"

# Fetch user's authorized keys from corporate directory
curl -s "https://$KEY_SERVER/api/users/$LDAP_USER/keys" \
    > ~/.ssh/authorized_keys_company

# Verify keys are signed by corporate CA
ssh-keygen -L -f ~/.ssh/authorized_keys_company

# Configure SSH to use corporate CA
echo "TrustedUserCAKeys $CORPORATE_CA" | sudo tee -a /etc/ssh/sshd_config
```

### Jump Hosts and Bastion Servers

#### Bastion Host Configuration

```ssh-config
# Bastion host setup
Host bastion
    HostName bastion.company.com
    User jumpuser
    Port 2222
    IdentityFile ~/.ssh/id_ed25519_bastion
    ControlMaster auto
    ControlPath ~/.ssh/cm_socket/%r@%h:%p
    ControlPersist 10m

# Internal Git server via bastion
Host internal-git
    HostName git.internal.company.com
    User git
    ProxyJump bastion
    IdentityFile ~/.ssh/id_ed25519_internal
    
# Alternative ProxyCommand syntax
Host legacy-git
    HostName git.legacy.company.com
    User git
    ProxyCommand ssh -W %h:%p bastion
    IdentityFile ~/.ssh/id_ed25519_legacy
```

#### SSH Tunneling for Git

```bash
# Create SSH tunnel for Git operations
ssh -L 9999:git.internal.com:22 bastion.company.com

# Use tunnel in separate terminal
export GIT_SSH_COMMAND="ssh -p 9999 -o StrictHostKeyChecking=no"
git clone git@localhost:company/repo.git

# Or configure permanent tunnel
Host git-tunnel
    HostName localhost
    Port 9999
    User git
    IdentityFile ~/.ssh/id_ed25519_internal
    StrictHostKeyChecking no
```

## Performance Optimization

### SSH Connection Optimization

#### Connection Multiplexing

```ssh-config
# Enable connection multiplexing for performance
Host *
    ControlMaster auto
    ControlPath ~/.ssh/cm_socket/%r@%h:%p
    ControlPersist 600
    
# Create control socket directory
Host github.com gitlab.com *.company.com
    ControlMaster auto
    ControlPath ~/.ssh/multiplexing-%r@%h:%p
    ControlPersist 10m
```

#### Compression and Keep-Alive

```ssh-config
Host *
    # Enable compression for slow connections
    Compression yes
    CompressionLevel 6
    
    # Keep connections alive
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    
    # Optimize for Git operations
    IPQoS lowdelay throughput
```

#### DNS and Connection Caching

```bash
# Configure SSH connection caching
mkdir -p ~/.ssh/cm_socket

# DNS caching for faster connections
cat >> /etc/hosts << EOF
140.82.112.3 github.com
140.82.112.4 api.github.com
172.65.251.78 gitlab.com
EOF
```

### Large Repository Optimization

#### Git-Specific SSH Tuning

```ssh-config
# Optimized configuration for large Git operations
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
    
    # Optimize for large transfers
    Compression yes
    CompressionLevel 4
    
    # Connection persistence
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 1h
    
    # Buffer sizes for large operations
    SendEnv GIT_SSH_VARIANT
    RequestTTY no
```

## Troubleshooting and Maintenance

### Comprehensive Diagnostics

#### SSH Health Check Script

```bash
#!/bin/bash
# ssh-health-check.sh

echo "=== SSH Health Check ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "SSH Client: $(ssh -V 2>&1)"
echo

# Check SSH directory permissions
echo "SSH Directory Permissions:"
ls -la ~/.ssh/ | head -10

# Check SSH agent
echo -e "\nSSH Agent Status:"
if ssh-add -l 2>/dev/null; then
    echo "✓ SSH agent running with loaded keys"
else
    echo "⚠ SSH agent not running or no keys loaded"
fi

# Test key files
echo -e "\nSSH Key Validation:"
find ~/.ssh -name "id_*" -not -name "*.pub" | while read key; do
    echo -n "Testing $key: "
    if ssh-keygen -l -f "$key" >/dev/null 2>&1; then
        echo "✓ Valid"
        ssh-keygen -l -f "$key"
    else
        echo "✗ Invalid or encrypted"
    fi
done

# Connection tests
echo -e "\nConnection Tests:"
for host in github.com gitlab.com ssh.dev.azure.com; do
    echo -n "Testing $host: "
    if timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -T git@"$host" 2>/dev/null | grep -q "successfully\|Welcome\|Shell access"; then
        echo "✓ Connected"
    else
        echo "✗ Failed"
    fi
done

echo -e "\n=== Health check complete ==="
```

#### Configuration Validation

```bash
#!/bin/bash
# validate-ssh-config.sh

CONFIG_FILE="$HOME/.ssh/config"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "SSH config file not found: $CONFIG_FILE"
    exit 1
fi

echo "Validating SSH configuration..."

# Check syntax
if ssh -F "$CONFIG_FILE" -G github.com >/dev/null 2>&1; then
    echo "✓ SSH configuration syntax is valid"
else
    echo "✗ SSH configuration has syntax errors"
    ssh -F "$CONFIG_FILE" -G github.com
    exit 1
fi

# Check for common issues
echo "Checking for common configuration issues..."

# Check for duplicate hosts
if grep -i "^Host " "$CONFIG_FILE" | sort | uniq -d | grep -q .; then
    echo "⚠ Duplicate Host entries found:"
    grep -i "^Host " "$CONFIG_FILE" | sort | uniq -d
fi

# Check for missing IdentityFile references
grep -i "IdentityFile" "$CONFIG_FILE" | while read line; do
    file=$(echo "$line" | awk '{print $2}' | sed 's/~/$HOME/')
    if [ ! -f "$file" ]; then
        echo "⚠ Missing identity file: $file"
    fi
done

echo "Configuration validation complete"
```

### Recovery Procedures

#### SSH Key Recovery

```bash
#!/bin/bash
# ssh-recovery.sh

echo "SSH Key Recovery Procedure"
echo "========================="

# Backup existing SSH directory
BACKUP_DIR="$HOME/.ssh.backup.$(date +%Y%m%d-%H%M%S)"
if [ -d ~/.ssh ]; then
    cp -r ~/.ssh "$BACKUP_DIR"
    echo "✓ Backup created: $BACKUP_DIR"
fi

# Create fresh SSH directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate new emergency key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_emergency -C "emergency-recovery-$(date +%Y%m%d)"
echo "✓ Emergency key generated"

# Create basic config
cat > ~/.ssh/config << EOF
# Emergency recovery configuration
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_emergency
    IdentitiesOnly yes

Host gitlab.com  
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_emergency
    IdentitiesOnly yes
EOF

chmod 644 ~/.ssh/config

echo "✓ Basic SSH configuration created"
echo
echo "Next steps:"
echo "1. Add the following public key to your Git services:"
echo
cat ~/.ssh/id_ed25519_emergency.pub
echo
echo "2. Test connections:"
echo "   ssh -T git@github.com"
echo "   ssh -T git@gitlab.com"
echo
echo "3. Restore from backup if needed:"
echo "   cp -r $BACKUP_DIR/* ~/.ssh/"
```

---

## Footnotes and References

¹ **SSH Public Key Authentication**: OpenSSH Team. (2024). *OpenSSH Manual - SSH Protocol Version 2*. Available at: [OpenSSH Manual Pages](https://man.openbsd.org/ssh.1)

² **Ed25519 Algorithm Security**: Bernstein, D. J., et al. (2012). *High-speed high-security signatures*. Available at: [Ed25519 Cryptographic Signature System](https://ed25519.cr.yp.to/)

³ **SSH Configuration Management**: OpenSSH Team. (2024). *SSH Config File Format*. Available at: [SSH Config Manual](https://man.openbsd.org/ssh_config.5)

⁴ **Git SSH Transport Security**: Git Development Community. (2024). *Git SSH Transport Documentation*. Available at: [Git SSH Transport](https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols#_the_ssh_protocol)

⁵ **Enterprise SSH Security**: NIST. (2022). *Guidelines for the Secure Configuration of SSH*. Available at: [NIST SSH Guidelines](https://nvlpubs.nist.gov/nistpubs/ir/2022/NIST.IR.8270.pdf)

## Additional Resources

### Official Documentation

- [OpenSSH Manual Pages](https://man.openbsd.org/) - Complete SSH documentation
- [Git SSH Documentation](https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols) - Git-specific SSH configuration
- [SSH Protocol Specifications](https://www.ssh.com/academy/ssh/protocol) - Technical protocol details
- [OpenSSH Security Advisories](https://www.openssh.com/security.html) - Security updates and patches

### Platform-Specific Guides

- [GitHub SSH Documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) - GitHub SSH setup and troubleshooting
- [GitLab SSH Keys Guide](https://docs.gitlab.com/ee/ssh/) - GitLab SSH configuration and management
- [Azure DevOps SSH Authentication](https://docs.microsoft.com/en-us/azure/devops/repos/git/use-ssh-keys-to-authenticate) - Azure DevOps SSH setup
- [Bitbucket SSH Key Management](https://support.atlassian.com/bitbucket-cloud/docs/set-up-an-ssh-key/) - Bitbucket SSH configuration

### Security and Best Practices

- [SSH Security Best Practices](https://www.ssh.com/academy/ssh/security) - Comprehensive security guidelines
- [Mozilla SSH Guidelines](https://infosec.mozilla.org/guidelines/openssh) - Mozilla's SSH security recommendations  
- [NSA SSH Hardening Guide](https://github.com/hardening-linux/ubuntu-hardening) - Government security standards
- [SSH Audit Tool](https://github.com/jtesta/ssh-audit) - Automated SSH security assessment

### Tools and Utilities

- [SSH Config Editor](https://github.com/dbrady/ssh-config) - GUI SSH configuration management
- [SSH Key Manager](https://github.com/beautifulcode/ssh-copy-id) - Automated key deployment
- [Keychain](https://github.com/funtoo/keychain) - SSH agent management utility
- [SSH Tunneling Tools](https://github.com/sshuttle/sshuttle) - Advanced SSH tunneling solutions

### Advanced Topics and Tutorials

- [SSH Certificates Tutorial](https://smallstep.com/blog/use-ssh-certificates/) - Certificate-based authentication
- [SSH Bastion Patterns](https://aws.amazon.com/quickstart/architecture/linux-bastion/) - Jump host architecture
- [SSH Performance Tuning](https://blog.packagecloud.io/eng/2017/02/06/monitoring-tuning-linux-networking-stack-sending-data/) - Network optimization
- [Corporate SSH Policies](https://www.cisecurity.org/controls/secure-configuration-for-hardware-and-software) - Enterprise security frameworks
