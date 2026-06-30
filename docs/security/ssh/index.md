---
title: Secure Shell (SSH) - Comprehensive Guide
description: A comprehensive guide to SSH protocol, configuration, security best practices, and advanced usage scenarios
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-05-23
ms.topic: conceptual
ms.service: security
---

Secure Shell (SSH) is a cryptographic network protocol that provides secure communication over an unsecured network. It enables users to securely access remote systems, execute commands, transfer files, and tunnel other network services. SSH was designed as a replacement for insecure protocols like Telnet, rlogin, and FTP, which transmit data (including authentication credentials) in plaintext.

This section is written for a general audience first, with advanced notes for enterprise administrators and security engineers where deeper control is needed.

## Quick Start

Use these defaults for most users:

1. Generate a key pair: `ssh-keygen -t ed25519 -C "you@example.com"`.
2. Install your public key on the target: `ssh-copy-id user@host`.
3. Connect with key auth: `ssh user@host`.
4. Verify host key fingerprints before first trust.

If this is your first time using SSH, start with [SSH Keys](ssh-keys.md), then continue to [Secure File Copy](secure-file-copy.md).

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
3. Server sends data that must be signed by the client
4. Client signs the data using the private key
5. Client returns the signature to the server
6. Server verifies the signature using the public key and grants access if valid

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
    - Verify the new host fingerprint through a trusted out-of-band channel first
    - If legitimate host key change: `ssh-keygen -R hostname`
    - If unexpected, investigate potential security issues

4. **Slow Connection**
    - Check DNS latency and name resolution behavior
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

> [!NOTE]
> Modern OpenSSH already uses SSH protocol version 2 by default, so `Protocol 2` is usually unnecessary.

## Additional Resources

- [OpenSSH Documentation](https://www.openssh.com/)
- [SSH Key Management Best Practices](https://www.ssh.com/academy/ssh/keygen)
- [SSH Protocol Specification](https://datatracker.ietf.org/doc/html/rfc4251)
