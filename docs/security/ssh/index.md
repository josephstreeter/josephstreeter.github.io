# Secure Shell - SSH

Secure Shell Protocol, or SSH, is a remote administration protocol that allows users to securely access a remote system for tasks such as administration and file copy.

SSH was created to replace insecure administrative protocols like telnet. SSH uses cryptographic techniques to authenticate users and ensure that communications between hosts are encrypted. User authentication in SSH can be performed using username and password or cryptographic key pairs.

## Uses for SSH

SSH is primarily known for providing remote terminal access to a host for administration. SSH can also be used to create secure tunnels and to transfer files.

## Server Configuration

To execute graphical applications remotely, enable X11 Forwarding and Agent Forwarding. This allows a user to execute a graphical application on the remote host.

```text
ForwardAgent yes
ForwardX11 yes
```

## Client Configuration

A configuration file can be used to configure the SSH client for different hosts without having to provide the settings each time the command is executed.

```text
Host vs-ssh.visualstudio.com
    HostName vs-ssh.visualstudio.com
    IdentityFile ~/.ssh/id_rsa_ado
    HostkeyAlgorithms +ssh-rsa
    PubkeyAcceptedAlgorithms +ssh-rsa
    IdentitiesOnly yes
```

## Authentication

Authentication can be satisfied by providing a password or by using cryptographic keys. Using a password is self-explanatory, but leveraging keys can be a little more complicated.

## SSH Keys

SSH keys are asymmetric cryptographic keys, or key pairs, that are used for authorization and authentication.
A key pair consists of a private key (identification key) and a public key (authorization key). The owner of a key pair is authorized access to a resource by installing that user's public key (authorization) on that resource.
The user then uses the private key (identity) to authenticate to that resource. The private key is protected by a password or passphrase that only the owner knows. A user's private keys are to be protected the same as passwords.

SSH keys may be used to interactively access a host or service or can be used to provide authorization and authentication to automated processes.
This is typically accomplished by creating a key pair without a password.

## Host Keys

Host keys represent a server's identity and are used by the client to authenticate that server's identity.
The first time a client accesses a server, the client will prompt the user, displaying a hash of the server's host key and asking the user to explicitly accept it.

```console
$ ssh -t git@ssh.github.com
The authenticity of host 'ssh.github.com (140.82.114.36)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

If the host key stored in `known_hosts` does not match the one presented to the client by the server, the client will prompt the user, asking if the user wants to continue.

```text
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the RSA key sent by the remote host is
6e:45:f9:a8:af:38:3d:a1:a5:c7:76:1d:02:f8:77:00.
Please contact your system administrator.
Add correct host key in /home/hostname/.ssh/known_hosts to get rid of this message.
Offending RSA key in /var/lib/sss/pubconf/known_hosts:4
RSA host key for pong has changed and you have requested strict checking.
Host key verification failed.
```

## Change Host Key

Follow these steps to regenerate OpenSSH Host Keys:

- Delete old ssh host keys:

    ```console
    rm /etc/ssh/ssh_host_*
    ```

- Reconfigure OpenSSH Server:

    ```console
    dpkg-reconfigure openssh-server
    ```

- Update ssh client(s) `~/.ssh/known_hosts` files with the new hash.

## SSH Key Pair Creation

Enter the following command to generate a new SSH key pair:

```console
ssh-keygen -t ed25519 -C "alias@example.com"
```

Or the following for legacy systems:

```console
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

```text
The authenticity of host 'ssh.github.com (140.82.113.35)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'ssh.github.com' (ED25519) to the list of known hosts.
```

## Authenticate with a Specific Key

A specific key can be specified in the SSH command.

```console
ssh -i ~/.ssh/id_rsa_host username@host.domain.com
```

## Compare Public Key Fingerprint

If you are having trouble logging into a host or a service, you can confirm that the fingerprint of your public key matches what was uploaded.

```console
ssh-keygen -l -E md5 -f ~/.ssh/id_rsa_ado.pub
```

## Test Authentication

The following command will test authentication to a specific host.

```console
ssh -T git@ssh.github.com
```

In the case of source control services, you may get the following error. This is simply because the service is not intended for shell access and is completely normal.

```text
remote: Shell access is not supported.
```

## Quick Reference

### Essential SSH Commands

```bash
# Connect to remote host
ssh username@hostname

# Connect with specific port
ssh -p 2222 username@hostname

# Connect with specific key
ssh -i ~/.ssh/id_rsa username@hostname

# Copy files to remote host
scp file.txt username@hostname:/path/to/destination/

# Copy files from remote host
scp username@hostname:/path/to/file.txt ./local/path/

# Sync directories
rsync -avz local/directory/ username@hostname:/remote/directory/
```

### Key Management

```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add key to SSH agent
ssh-add ~/.ssh/id_ed25519

# List loaded keys
ssh-add -l

# Copy public key to remote host
ssh-copy-id username@hostname

# Test SSH connection
ssh -T username@hostname
```

### SSH Configuration

```bash
# Edit SSH client config
nano ~/.ssh/config

# Check SSH configuration
ssh -F ~/.ssh/config -T username@hostname

# Generate host key fingerprint
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
```

## Configuration

### Client Configuration (~/.ssh/config)

```text
# Global settings
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    
# Specific host configuration
Host myserver
    HostName server.example.com
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_rsa_myserver
    
# Jump host configuration
Host target
    HostName 192.168.1.100
    User user
    ProxyJump jumphost
    
# GitHub configuration
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_github
```

### Server Configuration (/etc/ssh/sshd_config)

```text
# Security settings
Port 2222
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
