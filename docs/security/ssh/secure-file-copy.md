---
title: Secure File Copy (SCP) and SFTP - Complete Guide
description: A comprehensive guide to securely transferring files between systems using SCP and SFTP protocols
author: josephstreeter
ms.author: josephstreeter
ms.date: 2025-09-22
ms.topic: conceptual
ms.service: security
---

Secure file transfer is essential for protecting sensitive data when copying files between systems. This guide covers the two primary secure file transfer protocols that leverage SSH for encryption and authentication: SCP (Secure Copy Protocol) and SFTP (SSH File Transfer Protocol).

## Secure Copy Protocol (SCP)

SCP is a network protocol that uses SSH for data transfer and provides the same authentication and security as SSH. It helps users securely transfer files between a local and remote host or between two remote hosts.

### Key Features

- **Encryption**: All data transfers are encrypted using SSH
- **Authentication**: Uses the same authentication mechanisms as SSH (passwords, keys)
- **Simplicity**: Straightforward command-line syntax for basic file transfers
- **Integration**: Typically included with most SSH implementations

### Basic SCP Commands

#### Copy a File from Local to Remote

To copy a file from your local system to a remote server:

```bash
scp [options] source_file user@host:destination_path
```

For example:

```bash
scp document.pdf admin@server.example.com:/home/admin/documents/
```

#### Copy a File from Remote to Local

To copy a file from a remote server to your local system:

```bash
scp [options] user@host:source_file destination_path
```

For example:

```bash
scp admin@server.example.com:/var/log/system.log local-system-log.log
```

#### Copy Between Two Remote Systems

SCP can also transfer files directly between two remote systems:

```bash
scp [options] user1@host1:source_file user2@host2:destination_path
```

For example:

```bash
scp admin@server1.example.com:/home/admin/file.txt user@server2.example.com:/home/user/
```

### Common SCP Options

| Option | Description |
|--------|-------------|
| `-r` | Recursively copy entire directories |
| `-p` | Preserve file modification and access times |
| `-P port` | Specify an alternate port (uppercase P) |
| `-l limit` | Limit bandwidth used (in Kbit/s) |
| `-C` | Enable compression during file transfer |
| `-q` | Quiet mode (suppress progress meter and warnings) |
| `-v` | Verbose mode (display debugging information) |
| `-i identity_file` | Specify an identity (private key) file |

### Examples with Options

#### Copy Directory Recursively

```bash
scp -r /local/directory admin@server.example.com:/remote/path/
```

#### Preserve File Attributes

```bash
scp -p important.conf admin@server.example.com:/etc/
```

#### Use a Non-Standard Port

```bash
scp -P 2222 file.txt admin@server.example.com:/home/admin/
```

#### Limit Bandwidth Usage

```bash
scp -l 1000 large-file.iso admin@server.example.com:/home/admin/
```

#### Enable Compression

```bash
scp -C large-file.tar.gz admin@server.example.com:/home/admin/
```

#### Use Specific Identity File

```bash
scp -i ~/.ssh/special_key file.txt admin@server.example.com:/home/admin/
```

## SSH File Transfer Protocol (SFTP)

SFTP is a more feature-rich secure file transfer protocol that also runs over SSH. Unlike SCP, SFTP supports a full range of file operations and is more resilient.

### Advantages of SFTP over SCP

1. **Interactive shell**: Provides an interactive interface for file operations
2. **Resume capability**: Can resume interrupted transfers
3. **Directory listings**: View remote directories before transferring
4. **Advanced operations**: Rename, delete, create directories, and set permissions
5. **Better error recovery**: More robust handling of network issues
6. **File locking**: Better support for file locking mechanisms

### Using SFTP

#### Connect to an SFTP Server

```bash
sftp [options] user@host
```

For example:

```bash
sftp admin@server.example.com
```

#### Interactive SFTP Commands

Once connected to an SFTP server, you'll have access to an interactive shell with commands similar to FTP:

| Command | Description | Example |
|---------|-------------|---------|
| `ls` | List directory contents | `ls /var/log` |
| `cd` | Change directory | `cd /home/user` |
| `get` | Download file | `get report.pdf` |
| `put` | Upload file | `put local-file.txt` |
| `mget` | Download multiple files | `mget *.txt` |
| `mput` | Upload multiple files | `mput *.jpg` |
| `mkdir` | Create directory | `mkdir new-folder` |
| `rmdir` | Remove directory | `rmdir old-folder` |
| `rm` | Delete file | `rm unwanted-file.tmp` |
| `pwd` | Print working directory | `pwd` |
| `lcd` | Change local directory | `lcd ~/Downloads` |
| `lls` | List local directory | `lls` |
| `rename` | Rename file | `rename old.txt new.txt` |
| `chmod` | Change permissions | `chmod 644 file.txt` |
| `help` | Display help | `help` |
| `exit` or `quit` | Exit SFTP | `exit` |

#### Non-Interactive SFTP (Batch Mode)

You can run SFTP in non-interactive mode using a batch file:

```bash
sftp -b batch_file.txt user@host
```

Example batch file content:

```text
cd /remote/directory
get important.pdf
put local-file.txt
quit
```

### SFTP Options

| Option | Description |
|--------|-------------|
| `-b batch_file` | Batch mode using specified file |
| `-P port` | Connect to specified port |
| `-i identity_file` | Specify private key file |
| `-r` | Recursively copy directories |
| `-v` | Verbose mode |
| `-C` | Enable compression |

## SCP vs SFTP: When to Use Which

| Feature | SCP | SFTP |
|---------|-----|------|
| **Ease of use** | Simpler for basic transfers | More complex, but more powerful |
| **Command-line use** | Single command execution | Interactive shell or batch mode |
| **Resume capability** | No | Yes |
| **Directory operations** | Limited (copy only) | Full (list, create, delete) |
| **Remote file manipulation** | No | Yes (rename, change permissions) |
| **Performance** | Generally faster for simple transfers | Might be slower due to protocol overhead |
| **Error recovery** | Limited | More robust |
| **Platform support** | Widely supported | Widely supported |

## Security Best Practices

1. **Use Key-Based Authentication**: Avoid password authentication when possible

   ```bash
   scp -i ~/.ssh/id_ed25519 file.txt user@host:/path/
   ```

2. **Verify Host Fingerprints**: Always verify new host keys before accepting them

3. **Use Strong Encryption**: Configure SSH to use modern encryption algorithms

4. **Enable Compression for Large Transfers**: Use the `-C` option for better performance

   ```bash
   scp -C large-file.tar.gz user@host:/path/
   ```

5. **Limit Bandwidth When Necessary**: Use the `-l` option to avoid network congestion

   ```bash
   scp -l 2000 backup.tar.gz user@host:/path/
   ```

6. **Consider Port Forwarding or Jump Hosts** for accessing hosts behind firewalls

## Troubleshooting Common Issues

### Permission Denied

```text
Permission denied (publickey,password)
```

**Solutions:**

- Verify username and credentials
- Check SSH key permissions (should be 600)
- Ensure the remote directory is writable

### Connection Refused

```text
ssh: connect to host server.example.com port 22: Connection refused
```

**Solutions:**

- Verify SSH service is running on the remote host
- Check firewall settings
- Confirm the correct hostname and port

### Host Key Verification Failed

```text
Host key verification failed
```

**Solutions:**

- If the server's host key has legitimately changed, update your known_hosts file:

  ```bash
  ssh-keygen -R hostname
  ```

- If unexpected, investigate potential security issues

## Graphical SCP/SFTP Clients

For users who prefer graphical interfaces, several clients provide SCP/SFTP functionality:

- **FileZilla**: Cross-platform client with SFTP support
- **WinSCP**: Windows-only client with both SCP and SFTP support
- **Cyberduck**: macOS and Windows client with extensive protocol support
- **MobaXterm**: Windows terminal with integrated SFTP browser

## Scripting File Transfers

### Automated SCP Transfer

```bash
#!/bin/bash
# Script to securely copy log files to a backup server

SOURCE_DIR="/var/log/"
DEST_USER="backup"
DEST_HOST="backup-server.example.com"
DEST_PATH="/backup/logs/$(date +%Y-%m-%d)"

# Create remote directory
ssh $DEST_USER@$DEST_HOST "mkdir -p $DEST_PATH"

# Copy logs
scp -r $SOURCE_DIR/*.log $DEST_USER@$DEST_HOST:$DEST_PATH

# Check status
if [ $? -eq 0 ]; then
    echo "Log transfer completed successfully"
else
    echo "Error transferring logs"
fi
```

### SFTP Batch Transfer

```bash
#!/bin/bash
# Script to transfer files using SFTP batch mode

# Create temporary batch file
BATCH_FILE=$(mktemp)

cat > $BATCH_FILE << EOF
cd /remote/directory
put -r /local/files/*.txt
get -r reports/*.pdf /local/reports/
quit
EOF

# Execute SFTP with batch file
sftp -b $BATCH_FILE user@server.example.com

# Clean up
rm $BATCH_FILE
```

## Additional Resources

- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [SFTP Protocol Specification](https://datatracker.ietf.org/doc/html/draft-ietf-secsh-filexfer-13)
- [SSH Key Management Guide](https://www.ssh.com/academy/ssh/keygen)
