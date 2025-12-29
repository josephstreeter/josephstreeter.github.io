---
title: Secure Shell (SSH) - Comprehensive Guide
description: A comprehensive guide to SSH protocol, configuration, security best practices, and advanced usage scenarios
author: josephstreeter
ms.author: josephstreeter
ms.date: 2025-09-22
ms.topic: conceptual
ms.service: security
---

Secure Shell (SSH) is a cryptographic network protocol that provides secure communication over an unsecured network. It enables users to securely access remote systems, execute commands, transfer files, and tunnel other network services. SSH was designed as a replacement for insecure protocols like Telnet, rlogin, and FTP, which transmit data (including authentication credentials) in plaintext.

## Key Features and Benefits

- **Strong Encryption**: All communications are encrypted using industry-standard algorithms
- **Robust Authentication**: Supports various authentication methods including passwords and public key cryptography
- **Data Integrity**: Ensures transferred data remains unaltered during transit
- **Port Forwarding**: Allows tunneling of network services through the encrypted connection
- **SFTP Capability**: Secure alternative to FTP for file transfers
- **Cross-Platform Support**: Available on virtually all operating systems

## SSH Protocol Versions

- **SSH-1**: Original version, now deprecated due to security vulnerabilities
- **SSH-2**: Current standard with improved security, features multiple cryptographic layers:
  - Transport Layer: Handles initial connection, encryption, and server authentication
  - Authentication Layer: Manages user authentication methods
  - Connection Layer: Handles SSH channels within a single connection

## Common Use Cases

SSH is used for various purposes in modern computing environments:

- **Remote Administration**: Securely manage servers and network devices
- **Secure File Transfers**: Move files between systems using SCP or SFTP
- **Tunneling and Port Forwarding**: Create secure channels for other applications
- **Automated Operations**: Enable secure connections for scripts and automation tools
- **Git Operations**: Authenticate to remote repositories securely
- **Database Access**: Secure connections to remote database systems
- **Container and Cloud Management**: Securely access cloud infrastructure and containers

## Authentication Methods

SSH supports multiple authentication methods, with the most common being:

### Password Authentication

The simplest form of authentication where users provide their credentials interactively. While convenient, it's vulnerable to brute force attacks and is generally less secure than key-based authentication.

### Public Key Authentication

A more secure method using asymmetric cryptography with a public-private key pair:

- **Private Key**: Kept secret by the user, protected with an optional passphrase
- **Public Key**: Distributed to servers the user needs to access

The authentication process works as follows:

1. Client sends the public key identifier to the server
2. Server checks if the public key is authorized
3. Server generates a challenge encrypted with the public key
4. Client decrypts the challenge using the private key
5. Client responds to the server with the decrypted information
6. Server verifies the response and grants access if correct

### SSH Keys

SSH keys are asymmetric cryptographic keys that provide a more secure alternative to password-based authentication. A key pair consists of:

- **Private Key (Identification Key)**: Must be kept secure, optionally protected by a passphrase
- **Public Key (Authorization Key)**: Can be shared and placed on servers you need to access

#### SSH Key Types

Modern SSH implementations support several key types:

| Key Type | Description | Recommended Size | Notes |
|----------|-------------|------------------|-------|
| ED25519 | Edwards-curve Digital Signature Algorithm | 256-bit | Recommended for modern systems, excellent security with small key size |
| RSA | Rivest-Shamir-Adleman | 3072 or 4096-bit | Widely compatible, good for legacy systems |
| ECDSA | Elliptic Curve Digital Signature Algorithm | 256, 384, or 521-bit | Good alternative, but less widely used than ED25519 or RSA |

#### SSH Key Pair Creation

Generate a new modern SSH key pair (recommended for current systems):

```console
ssh-keygen -t ed25519 -C "user@example.com"
```

For legacy system compatibility, use RSA with at least 3072 bits:

```console
ssh-keygen -t rsa -b 4096 -C "user@example.com"
```

During key generation, you'll be prompted to:

1. Specify a file location (default is usually fine)
2. Create an optional passphrase (highly recommended for additional security)

#### Key Management

```bash
# List your existing keys
ls -la ~/.ssh/

# Add key to SSH agent (avoids typing passphrase repeatedly)
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# List keys loaded in the agent
ssh-add -l

# Copy public key to remote server
ssh-copy-id -i ~/.ssh/id_ed25519.pub username@remote-host

# Remove a key from the agent
ssh-add -d ~/.ssh/id_ed25519
```

### Host Keys

Host keys establish the server's identity and protect against man-in-the-middle attacks. Each SSH server has its own set of host keys.

When a client connects to a server for the first time, the server presents its host key. The client displays the key's fingerprint and asks for confirmation:

```console
$ ssh -t user@example.com
The authenticity of host 'example.com (192.168.1.10)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

After confirming, the host key is stored in the `~/.ssh/known_hosts` file. On subsequent connections, the client verifies the server's identity against this stored key.

If the host key changes, you'll see a warning:

```text
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
```

This could indicate:

- A legitimate server reconfiguration or OS reinstallation
- A DNS spoofing attack
- A man-in-the-middle attack

#### Managing Host Keys

To update a changed host key:

```bash
# Remove the old key for a specific host
ssh-keygen -R hostname

# Or edit the known_hosts file directly
vi ~/.ssh/known_hosts
```

#### Regenerating Server Host Keys

If you're administering an SSH server and need to regenerate host keys:

```console
# Debian/Ubuntu
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server

# RHEL/CentOS
sudo rm /etc/ssh/ssh_host_*
sudo ssh-keygen -A
sudo systemctl restart sshd
```

## Client Configuration

SSH client behavior can be customized through the `~/.ssh/config` file, which allows defining host-specific settings.

### Basic Configuration Structure

```text
# Default settings for all hosts
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    
# Specific host configuration
Host myserver
    HostName server.example.com
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_rsa_myserver
```

### Common Client Configuration Options

| Option | Description | Example |
|--------|-------------|---------|
| HostName | Real hostname to connect to | `HostName 192.168.1.100` |
| User | Username to login as | `User admin` |
| Port | Port to connect to | `Port 2222` |
| IdentityFile | Private key file to use | `IdentityFile ~/.ssh/id_rsa` |
| ForwardAgent | Enable SSH agent forwarding | `ForwardAgent yes` |
| ForwardX11 | Enable X11 forwarding | `ForwardX11 yes` |
| ServerAliveInterval | Seconds between keepalive packets | `ServerAliveInterval 60` |
| ProxyJump | Use a jump host | `ProxyJump jumphost` |
| StrictHostKeyChecking | Host key verification behavior | `StrictHostKeyChecking yes` |
| IdentitiesOnly | Only use specified keys | `IdentitiesOnly yes` |

### Advanced Configuration Examples

#### Jump Host Configuration

```text
# Jump through bastion host to reach internal servers
Host internal-server
    HostName 10.0.0.5
    User admin
    ProxyJump bastion.example.com
```

#### Multiple GitHub Accounts

```text
# Personal GitHub account
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github_personal
    
# Work GitHub account
Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github_work
```

#### X11 Forwarding for GUI Applications

```text
Host dev-server
    HostName dev.example.com
    User developer
    ForwardX11 yes
    ForwardX11Trusted yes
```

## Server Configuration

The SSH server configuration is typically found in `/etc/ssh/sshd_config`. Here are some important security-focused settings:

```text
# Basic Settings
Port 22
Protocol 2
ListenAddress 0.0.0.0

# Authentication
PermitRootLogin no
MaxAuthTries 3
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Security
X11Forwarding no
AllowTcpForwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
```

### Security Best Practices for SSH Servers

1. **Disable Root Login**:

   ```text
   PermitRootLogin no
   ```

2. **Use Key Authentication Only**:

   ```text
   PasswordAuthentication no
   ```

3. **Limit User Access**:

   ```text
   AllowUsers user1 user2
   ```

4. **Change Default Port** (obscurity, not security):

   ```text
   Port 2222
   ```

5. **Implement Fail2Ban** to protect against brute force attacks

6. **Enable Two-Factor Authentication** for additional security

7. **Disable Unused Features**:

   ```text
   X11Forwarding no
   AllowAgentForwarding no
   ```

8. **Tighten Cryptographic Settings**:

   ```text
   Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
   MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
   KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
   ```

## Advanced SSH Techniques

### Port Forwarding

SSH can tunnel other services through its encrypted connection:

#### Local Port Forwarding

Makes a remote service appear as if it's running locally:

```bash
# Access remote MySQL server as if it were on localhost
ssh -L 3306:localhost:3306 user@remote-server
```

#### Remote Port Forwarding

Makes a local service accessible from the remote machine:

```bash
# Share local web server with remote machine
ssh -R 8080:localhost:80 user@remote-server
```

#### Dynamic Port Forwarding (SOCKS Proxy)

Creates a SOCKS proxy for routing traffic:

```bash
# Create a SOCKS proxy on port 1080
ssh -D 1080 user@remote-server
```

### SSH Agent Forwarding

Allows you to use your local SSH keys on a remote server:

```bash
# Enable agent forwarding for a single connection
ssh -A user@remote-server

# Or in config file
Host remote-server
    ForwardAgent yes
```

**Security Note**: Only use agent forwarding with trusted servers, as it gives the remote system access to your local SSH agent.

### Certificate-Based Authentication

For environments with many servers, SSH certificates provide a more scalable alternative to managing authorized_keys files:

```bash
# Create a certificate authority
ssh-keygen -t ed25519 -f ssh_ca

# Sign a user's public key
ssh-keygen -s ssh_ca -I user_id -n username id_ed25519.pub

# Configure server to trust the CA
TrustedUserCAKeys /etc/ssh/ca.pub
```

## Troubleshooting SSH Connections

### Common Issues and Solutions

1. **Connection Refused**
   - Verify SSH service is running
   - Check firewall settings
   - Confirm correct hostname and port

2. **Permission Denied**
   - Verify username and credentials
   - Check key permissions (private key should be 600)
   - Ensure public key is properly added to authorized_keys

3. **Host Key Verification Failed**
   - If legitimate host key change: `ssh-keygen -R hostname`
   - If unexpected, investigate potential security issues

4. **Slow Connection**
   - Check DNS settings (UseDNS no)
   - Review GSSAPI authentication settings
   - Test with verbose output: `ssh -vvv user@host`

### Debugging Commands

```bash
# Test SSH connection with verbose output
ssh -vvv user@hostname

# Check SSH key permissions
ls -la ~/.ssh/

# Verify public key fingerprint
ssh-keygen -l -f ~/.ssh/id_ed25519.pub

# Test specific authentication method
ssh -o PreferredAuthentications=publickey user@hostname

# Check if server allows password authentication
ssh -o PreferredAuthentications=password user@hostname
```

## Quick Reference

### Essential SSH Commands

```bash
# Connect to remote host
ssh username@hostname

# Connect with specific port
ssh -p 2222 username@hostname

# Connect with specific key
ssh -i ~/.ssh/id_ed25519 username@hostname

# Copy files to remote host
scp file.txt username@hostname:/path/to/destination/

# Copy files from remote host
scp username@hostname:/path/to/file.txt ./local/path/

# Sync directories
rsync -avz local/directory/ username@hostname:/remote/directory/

# Mount remote filesystem locally (requires SSHFS)
sshfs username@hostname:/remote/path /local/mount/point
```

### SSH Configuration Examples

**Client Config (~/.ssh/config)**:

```text
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github
    IdentitiesOnly yes
    
Host bastion
    HostName bastion.example.com
    User admin
    Port 2222
    
Host internal
    HostName 10.0.0.10
    User admin
    ProxyJump bastion
```

**Server Config (/etc/ssh/sshd_config)**:

```text
# Security settings
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no

# Authentication settings
MaxAuthTries 3
LoginGraceTime 30
MaxStartups 5

# Logging
LogLevel INFO
SyslogFacility AUTH
```

## Additional Resources

- [OpenSSH Documentation](https://www.openssh.com/)
- [SSH Key Management Best Practices](https://www.ssh.com/academy/ssh/keygen)
- [SSH Protocol Specification](https://datatracker.ietf.org/doc/html/rfc4251)
