---
title: SSH Keys - Complete Guide
description: A practical guide to SSH key generation, management, client configuration, and server hardening
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-05-23
ms.topic: conceptual
ms.service: security
---

SSH keys are asymmetric cryptographic keys that provide a more secure alternative to password-based authentication. A key pair consists of:

- **Private Key (Identification Key)**: Must be kept secure, optionally protected by a passphrase
- **Public Key (Authorization Key)**: Can be shared and placed on servers you need to access

## Quick Start

For most users, this is enough to get started safely:

```bash
ssh-keygen -t ed25519 -C "user@example.com" -f ~/.ssh/id_ed25519
ssh-copy-id -i ~/.ssh/id_ed25519.pub <user>@<servername>
ssh <user>@<servername>
```

Then optionally load the key into the local agent:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

For enterprise administration and security engineering contexts, continue to the server hardening and cryptographic policy guidance later in this document.

## SSH Key Types

Modern SSH implementations support several key types:

| Key Type | Description | Recommended Size | Notes |
| -------- | ----------- | ---------------- | ----- |
| ED25519 | Edwards-curve Digital Signature Algorithm | 256-bit | Recommended for modern systems, excellent security with small key size |
| RSA | Rivest-Shamir-Adleman | 3072 or 4096-bit | Widely compatible, good for legacy systems |
| ECDSA | Elliptic Curve Digital Signature Algorithm | 256, 384, or 521-bit | Good alternative, but less widely used than ED25519 or RSA |
| FIDO/U2F (`sk-ssh-ed25519`) | Hardware-backed key stored on security key | N/A | Strong phishing resistance, excellent for admin and enterprise access |

Hardware-backed key example:

```console
ssh-keygen -t ed25519-sk -C "user@example.com" -f ~/.ssh/id_ed25519_sk
```

## SSH Key Pair Creation

Generate a new modern SSH key pair (recommended for current systems):

```console
ssh-keygen -t ed25519 -C "user@example.com" -f ~/.ssh/id_ed25519
```

For legacy system compatibility, use RSA with at least 3072 bits:

```console
ssh-keygen -t rsa -b 4096 -C "user@example.com" -f ~/.ssh/id_rsa
```

Explanation of the options used in the examples above:

```text
-t - specifies the algorithm.
-b - sets key length (RSA only).
-C - adds a label (usually your email).
-f - specifies the file name and path for the key (omit for the default path).
```

**Set a Passphrase** — Use a strong passphrase. Avoid blank passphrases unless the key is short-lived automation-only and tightly controlled.

## File Permissions

SSH is strict about permissions and will refuse to use keys with incorrect settings.

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519        # private key
chmod 644 ~/.ssh/id_ed25519.pub    # public key
```

## Add Key to Agent

Start ssh-agent in background:

```bash
eval "$(ssh-agent -s)"
```

Add private key to agent:

```bash
ssh-add ~/.ssh/id_ed25519
```

To persist the agent across sessions, add the following to `~/.bashrc` or `~/.bash_profile`:

```bash
if [ -z "$SSH_AGENT_PID" ]; then
    eval "$(ssh-agent -s)"
fi
```

## Copy Key to Server

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub <user>@<servername>
```

If `ssh-copy-id` is unavailable:

```bash
PUBKEY="$(cat ~/.ssh/id_ed25519.pub)"
ssh <user>@<servername> "umask 077; mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; grep -qxF \"$PUBKEY\" ~/.ssh/authorized_keys || echo \"$PUBKEY\" >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
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
# First, validate the new host fingerprint out-of-band.

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

Create or edit the config file:

```bash
vi ~/.ssh/config
```

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
| ------ | ----------- | ------- |
| HostName | Real hostname to connect to | `HostName 192.168.1.100` |
| User | Username to login as | `User admin` |
| Port | Port to connect to | `Port 2222` |
| IdentityFile | Private key file to use | `IdentityFile ~/.ssh/id_rsa` |
| ForwardAgent | Enable SSH agent forwarding | `ForwardAgent yes` |
| ForwardX11 | Enable X11 forwarding | `ForwardX11 yes` |
| ServerAliveInterval | Seconds between keepalive packets | `ServerAliveInterval 60` |
| ProxyJump | Use a jump host | `ProxyJump jumphost` |
| StrictHostKeyChecking | Host key verification behavior | `StrictHostKeyChecking accept-new` |
| IdentitiesOnly | Only use specified keys | `IdentitiesOnly yes` |

Avoid `StrictHostKeyChecking no` unless this is a short-lived troubleshooting scenario in an isolated environment. It disables host key verification and increases man-in-the-middle risk.

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

Github uses SSH for authentication when pushing code. If you have multiple accounts (e.g., personal and work), you can configure them like this:

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
    ForwardX11 no
```

If GUI forwarding is required, enable it per host and avoid `ForwardX11Trusted yes` unless you fully trust the remote environment.

## Server Configuration

The SSH server configuration is typically found in `/etc/ssh/sshd_config`. Here are some important security-focused settings:

```text
# Basic Settings
Port 22
# Bind only required interfaces when possible
ListenAddress 192.168.1.10

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
AllowTcpForwarding local
AllowAgentForwarding no
PrintMotd no
AcceptEnv LANG
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

    > [!NOTE]
    > For general environments, OpenSSH defaults are often safer than aggressive manual pinning because defaults evolve with security updates. Pin algorithms only when policy requires it and test compatibility.
