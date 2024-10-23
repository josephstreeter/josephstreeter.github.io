# Secure Shell - SSH

Secure Shell Protocol, or SSH, is a remote administration protocol that allows users to securly access a remote system for tasks such as adminstration and file copy.

SSH was created to replace insecure administrative protocols like telnet. SSH uses cryptographic techniques to autheticate users and ensure that communications between hosts are encrypted. User authentication in SSH can be performed using username and password or cryptographic key pairs.

## Uses for SSH

SSH is primarily known for providing remote termial access to a host for administration. SSH can also be used to create seocure tunnels and to transfer files.

## SSH Configuration

### Server Configuration

#### Execute Graphical Applications Remotely

Enabling X11 Forwarding and Agent Forwarding will allow a user to execute a graphical application on the remote host.

```text
ForwardAgent yes
ForwardX11 yes
```

### Client Configuration

#### SSH Configuration File

> Configuration for different hosts

```text

```

## Authentiction

### SSH Keys

SSH Keys are asymetric cryprographic keys, or key pairs, that are used for authorization and authentication.
A key pair consists of a private key (Identification key) and a public key (Authorization key). The owner of a key pair is authorized access to a resource by installing that user's public key (Authorization) on that resource.
The user then uses the private key (Identity) to authenticate to that resource. The private key is protected by a passowrd or passphrase that only the owner knows. A users private key's are to be protected the same as passwords.

SSH keys may be used to interactivly access a host or service or can be used to privide authorization and authentication to automated processes.
This is typically accomplised by creating a key pair without a password.

#### Host Keys

Host keys represent a server's identity and are used by the client to authenticate that server's identity.
The first time a client accesses a server, the client will prompt the user, displaying a hash of the server's host key and asking the user to expliicitly accept it.

```bash
$ ssh -t git@ssh.github.com
The authenticity of host 'ssh.github.com (140.82.114.36)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

If the host key stored in 'known_hosts' does not match the one presented to the client by the server the client will promp the usuer, asking if the user wants to continue.

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
Add correct host key in /home/hostname /.ssh/known_hosts to get rid of this message.
Offending RSA key in /var/lib/sss/pubconf/known_hosts:4
RSA host key for pong has changed and you have requested strict checking.
Host key verification failed.
```

#### Change Host Key

Follow these steps to regenerate OpenSSH Host Keys

- Delete old ssh host keys

```bash
rm /etc/ssh/ssh_host_*
```

- Reconfigure OpenSSH Server

```bash
dpkg-reconfigure openssh-server
```

- Update ssh client(s) ~/.ssh/known_hosts files with the new hash

### SSH Key pair Creation

Enter the following command to generate a new SSH key pair

```bash
ssh-keygen -t ed25519 -C "alias@example.com"
```

or the following for legacy systems

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

```text
The authenticity of host 'ssh.github.com (140.82.113.35)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'ssh.github.com' (ED25519) to the list of known hosts.
```

### Authenticate with a Specific Key

A specific key can be specified in the SSH command.

```bash
ssh -i ~/.ssh/id_rsa_host username@host.domain.com
```

### Compare Public Key Fingerprint

If you are having trouble logging into a host or a service you can confirm that the fingerprint of your public key matches what was uploaded.

```bash
ssh-keygen -l -E md5 -f ~/.ssh/id_rsa_ado.pub
```

## Test Authentication

The following command will test authentiction to a specific host.

```bash
ssh -T git@ssh.github.com
```

In the case of source control services, you may get the following error. This is simply because the service is not intended for shell access and is completely normal.

```text
remote: Shell access is not supported.
```
