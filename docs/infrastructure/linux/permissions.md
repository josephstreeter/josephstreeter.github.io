---
title: Linux Permissions - Comprehensive Guide
description: "Complete guide to Linux file permissions, ownership, and access control: understanding modes, chmod, chown, ACLs, and special permissions."
ms.topic: reference
ms.date: 2025-11-29
---

Linux file permissions control who can read, write, and execute files and directories. Understanding permissions is fundamental to system security and proper file management.

## Quick Start

- Every file and directory has an owner, a group, and permission settings
- Three permission types: read (r), write (w), execute (x)
- Three permission categories: owner (u), group (g), others (o)
- Permissions displayed as: `-rwxr-xr--` (file type + 3 sets of rwx)
- Use `chmod` to change permissions, `chown` to change ownership

## Understanding Permission Display

When you run `ls -l`, you see permissions like this:

```bash
-rwxr-xr-- 1 user group 4096 Nov 29 10:00 filename
│││││││││
│└┬┘└┬┘└┬┘
│ │  │  └─── Others permissions (r--)
│ │  └────── Group permissions (r-x)
│ └───────── Owner permissions (rwx)
└─────────── File type (- = file, d = directory, l = link)
```

### File Type Indicators

| Symbol | Type |
|--------|------|
| `-` | Regular file |
| `d` | Directory |
| `l` | Symbolic link |
| `c` | Character device |
| `b` | Block device |
| `s` | Socket |
| `p` | Named pipe (FIFO) |

### Permission Meanings

#### For Files

| Permission | Symbol | Numeric | Meaning |
|------------|--------|---------|---------|
| Read | r | 4 | View file contents |
| Write | w | 2 | Modify file contents |
| Execute | x | 1 | Run file as program/script |
| None | - | 0 | No permission |

#### For Directories

| Permission | Symbol | Numeric | Meaning |
|------------|--------|---------|---------|
| Read | r | 4 | List directory contents |
| Write | w | 2 | Create/delete files in directory |
| Execute | x | 1 | Enter directory (cd into it) |
| None | - | 0 | No permission |

**Important:** For directories, execute (x) permission is required to access the directory at all. Without it, you cannot cd into the directory or access files within it, even if you have read permission.

## Numeric (Octal) Permissions

Permissions are represented by three-digit octal numbers (0-7), where each digit is the sum of:

- Read (r) = 4
- Write (w) = 2
- Execute (x) = 1

### Common Permission Values

| Octal | Binary | Symbolic | Meaning |
|-------|--------|----------|---------|
| 0 | 000 | --- | No permission |
| 1 | 001 | --x | Execute only |
| 2 | 010 | -w- | Write only |
| 3 | 011 | -wx | Write and execute |
| 4 | 100 | r-- | Read only |
| 5 | 101 | r-x | Read and execute |
| 6 | 110 | rw- | Read and write |
| 7 | 111 | rwx | Read, write, and execute |

### Common Permission Sets

| Octal | Symbolic | Typical Use |
|-------|----------|-------------|
| 644 | rw-r--r-- | Regular files (owner can modify, others can read) |
| 664 | rw-rw-r-- | Group-writable files |
| 600 | rw------- | Private files (owner only) |
| 755 | rwxr-xr-x | Executable files and directories |
| 775 | rwxrwxr-x | Group-writable directories |
| 700 | rwx------ | Private directories/executables |
| 777 | rwxrwxrwx | World-writable (avoid - security risk) |

## Changing Permissions with chmod

### Symbolic Mode

```bash
# Add execute permission for owner
chmod u+x filename

# Remove write permission for group
chmod g-w filename

# Add read permission for others
chmod o+r filename

# Set exact permissions for all
chmod a=rx filename

# Multiple changes
chmod u+x,g-w,o-r filename

# Recursive changes
chmod -R u+w directory/
```

#### Symbolic Mode Reference

| Symbol | Meaning |
|--------|---------|
| u | User (owner) |
| g | Group |
| o | Others |
| a | All (u+g+o) |
| + | Add permission |
| - | Remove permission |
| = | Set exact permission |

### Numeric (Octal) Mode

```bash
# Set permissions to 755 (rwxr-xr-x)
chmod 755 filename

# Set permissions to 644 (rw-r--r--)
chmod 644 filename

# Set permissions to 600 (rw-------)
chmod 600 private-file

# Recursive
chmod -R 755 directory/
```

### chmod Examples

```bash
# Make script executable
chmod +x script.sh
chmod 755 script.sh

# Make file readable by all
chmod a+r document.txt
chmod 644 document.txt

# Secure private key file
chmod 600 ~/.ssh/id_rsa

# Set directory for shared group work
chmod 770 /shared/project/

# Remove all permissions for others
chmod o-rwx sensitive-file

# Make file read-only for everyone
chmod 444 readonly-file

# Set web server directory permissions
chmod 755 /var/www/html/
chmod 644 /var/www/html/*.html
```

## Changing Ownership with chown

### Basic Usage

```bash
# Change owner
chown newowner filename

# Change owner and group
chown newowner:newgroup filename

# Change group only
chown :newgroup filename
# Or use chgrp
chgrp newgroup filename

# Recursive
chown -R user:group directory/

# Follow symbolic links
chown -L user:group symlink
```

### chown Examples

```bash
# Change owner of web files to www-data
sudo chown www-data:www-data /var/www/html/index.html

# Change ownership recursively
sudo chown -R username:username /home/username/project/

# Change group only
sudo chown :developers project-file

# Change owner, keep existing group
sudo chown newuser filename

# Change based on reference file
sudo chown --reference=ref-file target-file

# Preview changes (show what would change)
chown --changes user:group filename
```

## Special Permissions

### Setuid (Set User ID)

When set on an executable, the file runs with the permissions of the file owner, not the user running it.

```bash
# Numeric: 4 prefix (4755)
chmod 4755 executable

# Symbolic
chmod u+s executable

# Display: 's' or 'S' in owner execute position
-rwsr-xr-x  # setuid is set and file is executable
-rwSr-xr-x  # setuid is set but file is not executable
```

**Example:** `/usr/bin/passwd` has setuid set so regular users can change their password (which requires writing to `/etc/shadow`, a root-owned file).

### Setgid (Set Group ID)

**On executables:** File runs with the group of the file, not the user's group.

**On directories:** New files created inherit the directory's group, not the creator's primary group.

```bash
# Numeric: 2 prefix (2755)
chmod 2755 directory

# Symbolic
chmod g+s directory

# Display: 's' or 'S' in group execute position
drwxr-sr-x  # setgid is set and directory is executable
drwxr-Sr-x  # setgid is set but directory is not executable
```

**Common use:** Shared project directories where all files should belong to the project group.

```bash
# Create shared directory
sudo mkdir /shared/project
sudo chown :developers /shared/project
sudo chmod 2775 /shared/project

# Now all files created inside inherit the 'developers' group
```

### Sticky Bit

On directories, only the file owner (or root) can delete or rename files, even if others have write permission to the directory.

```bash
# Numeric: 1 prefix (1777)
chmod 1777 directory

# Symbolic
chmod +t directory

# Display: 't' or 'T' in others execute position
drwxrwxrwt  # sticky bit set and directory is executable
drwxrwxrwT  # sticky bit set but directory is not executable
```

**Example:** `/tmp` directory has sticky bit set so users can create files but can't delete others' files.

```bash
ls -ld /tmp
drwxrwxrwt 15 root root 4096 Nov 29 10:00 /tmp
```

### Combining Special Permissions

```bash
# Setuid + standard permissions
chmod 4755 file    # -rwsr-xr-x

# Setgid + standard permissions
chmod 2755 dir     # drwxr-sr-x

# Sticky bit + standard permissions
chmod 1777 dir     # drwxrwxrwt

# All special permissions
chmod 7755 file    # -rwsr-sr-t (unusual combination)
```

## Default Permissions and umask

The `umask` value determines default permissions for newly created files and directories by **subtracting** from the maximum permissions.

### Understanding umask

- Maximum file permissions: 666 (rw-rw-rw-)
- Maximum directory permissions: 777 (rwxrwxrwx)
- Default permissions = Maximum - umask

```bash
# View current umask
umask
# Output: 0022

# View in symbolic form
umask -S
# Output: u=rwx,g=rx,o=rx

# Set umask (current session)
umask 0027

# Set umask (add to ~/.bashrc for persistence)
echo "umask 0027" >> ~/.bashrc
```

### Common umask Values

| umask | Files | Directories | Use Case |
|-------|-------|-------------|----------|
| 0022 | 644 (rw-r--r--) | 755 (rwxr-xr-x) | Default for most systems |
| 0027 | 640 (rw-r-----) | 750 (rwxr-x---) | More restrictive, group-readable |
| 0077 | 600 (rw-------) | 700 (rwx------) | Private, owner-only access |
| 0002 | 664 (rw-rw-r--) | 775 (rwxrwxr-x) | Group collaboration |

### Calculating Permissions

```bash
# Example: umask 0022
# New file: 666 - 022 = 644 (rw-r--r--)
# New directory: 777 - 022 = 755 (rwxr-xr-x)

# Example: umask 0027
# New file: 666 - 027 = 640 (rw-r-----)
# New directory: 777 - 027 = 750 (rwxr-x---)
```

## Access Control Lists (ACLs)

ACLs provide fine-grained permission control beyond standard owner/group/others.

### Checking ACL Support

```bash
# Check if filesystem supports ACLs
tune2fs -l /dev/sda1 | grep "Default mount options"

# Mount with ACL support (if needed)
sudo mount -o remount,acl /
```

### Viewing ACLs

```bash
# View ACLs for a file
getfacl filename

# Example output:
# file: filename
# owner: user
# group: group
# user::rw-
# user:alice:rwx
# group::r--
# mask::rwx
# other::r--
```

### Setting ACLs

```bash
# Give user 'alice' read and execute permissions
setfacl -m u:alice:rx filename

# Give group 'developers' write permission
setfacl -m g:developers:rw filename

# Remove ACL for user 'bob'
setfacl -x u:bob filename

# Remove all ACLs
setfacl -b filename

# Set default ACL for directory (inherited by new files)
setfacl -d -m u:alice:rwx directory/

# Recursive ACL
setfacl -R -m u:alice:rx directory/

# Copy ACLs from one file to another
getfacl file1 | setfacl --set-file=- file2
```

### ACL Mask

The mask defines the maximum permissions that can be granted via ACLs:

```bash
# Set mask
setfacl -m m::rx filename

# This limits ACL permissions to read and execute maximum
# Even if a user ACL grants write, the mask restricts it
```

### Backup and Restore ACLs

```bash
# Backup ACLs
getfacl -R directory/ > acls.txt

# Restore ACLs
setfacl --restore=acls.txt
```

## Extended Attributes

Extended attributes provide additional metadata storage beyond permissions.

### File Attributes (chattr/lsattr)

```bash
# View attributes
lsattr filename

# Make file immutable (cannot be modified or deleted, even by root)
sudo chattr +i filename

# Remove immutable attribute
sudo chattr -i filename

# Make file append-only
sudo chattr +a logfile

# Common attributes:
# i = immutable
# a = append-only
# d = no dump (excluded from backups)
# A = no atime updates (performance)
```

### SELinux Context (if enabled)

```bash
# View SELinux context
ls -Z filename

# Change SELinux context
chcon -t httpd_sys_content_t /var/www/html/index.html

# Restore default context
restorecon -v filename
```

## Practical Permission Scenarios

### Web Server Files

```bash
# HTML/CSS/JS files
sudo chown -R www-data:www-data /var/www/html/
sudo find /var/www/html/ -type f -exec chmod 644 {} \;
sudo find /var/www/html/ -type d -exec chmod 755 {} \;

# Upload directory (writable)
sudo chmod 775 /var/www/html/uploads/
sudo chmod g+s /var/www/html/uploads/
```

### Shared Project Directory

```bash
# Create shared directory for team
sudo mkdir /projects/team-alpha
sudo chown :team-alpha /projects/team-alpha
sudo chmod 2775 /projects/team-alpha

# Set default ACLs for new files
sudo setfacl -d -m g:team-alpha:rwx /projects/team-alpha
sudo setfacl -d -m o::rx /projects/team-alpha
```

### SSH Keys

```bash
# Private key must be readable only by owner
chmod 600 ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_ed25519

# Public keys
chmod 644 ~/.ssh/id_rsa.pub
chmod 644 ~/.ssh/authorized_keys

# SSH directory
chmod 700 ~/.ssh/
```

### Script Files

```bash
# Make script executable
chmod +x script.sh
chmod 755 script.sh

# System-wide script (in /usr/local/bin)
sudo chmod 755 /usr/local/bin/myscript
sudo chown root:root /usr/local/bin/myscript
```

### Log Files

```bash
# Application log (append-only)
sudo touch /var/log/myapp.log
sudo chown myapp:myapp /var/log/myapp.log
sudo chmod 640 /var/log/myapp.log

# Rotate old logs
sudo chattr +i /var/log/myapp.log.old
```

### Database Files

```bash
# MySQL/PostgreSQL data directory
sudo chown -R mysql:mysql /var/lib/mysql/
sudo chmod 750 /var/lib/mysql/
sudo chmod 660 /var/lib/mysql/*
```

## Troubleshooting Permissions

### Check Current Permissions

```bash
# Detailed listing
ls -la filename

# Numeric permissions
stat -c '%a %n' filename

# Full file info
stat filename

# Check effective permissions
sudo -u username test -r filename && echo "readable" || echo "not readable"
```

### Common Permission Issues

**Permission denied when executing script:**

```bash
# Check if executable
ls -l script.sh

# Add execute permission
chmod +x script.sh
```

**Cannot access directory:**

```bash
# Need execute permission on directory
chmod +x directory/

# Check parent directory permissions
ls -ld /path/to/directory
```

**Cannot delete file in writable directory:**

```bash
# Check directory ownership and sticky bit
ls -ld directory/

# If sticky bit is set, only owner can delete
```

**Web server cannot read files:**

```bash
# Check ownership
ls -l /var/www/html/

# Fix ownership
sudo chown -R www-data:www-data /var/www/html/

# Fix permissions
sudo chmod -R 755 /var/www/html/
```

### Find Files with Specific Permissions

```bash
# Find world-writable files (security risk)
find /path -type f -perm -002

# Find setuid files
find /path -type f -perm -4000

# Find files owned by specific user
find /path -user username

# Find files with exact permissions
find /path -type f -perm 644

# Find directories without execute for owner
find /path -type d ! -perm -u+x
```

## Best Practices

### Security Guidelines

1. **Principle of Least Privilege:** Grant minimum necessary permissions
2. **Avoid 777:** Never use world-writable permissions unless absolutely necessary
3. **Protect Private Keys:** SSH keys should be 600 (owner read/write only)
4. **Regular Audits:** Periodically check for overly permissive files
5. **Use Groups:** Leverage groups for shared access instead of opening to all

### Recommended Patterns

```bash
# User home directories
chmod 750 /home/username/

# Configuration files (sensitive)
chmod 600 /etc/app/config

# Configuration files (non-sensitive)
chmod 644 /etc/app/defaults

# System binaries
chmod 755 /usr/local/bin/*

# Shared data directory
chmod 2775 /shared/data/

# Temporary working directory
chmod 1777 /tmp/
```

### Automation

```bash
# Script to fix web permissions
#!/bin/bash
WEB_ROOT="/var/www/html"
WEB_USER="www-data"
WEB_GROUP="www-data"

sudo chown -R $WEB_USER:$WEB_GROUP $WEB_ROOT
sudo find $WEB_ROOT -type f -exec chmod 644 {} \;
sudo find $WEB_ROOT -type d -exec chmod 755 {} \;
sudo chmod 775 $WEB_ROOT/uploads/
sudo chmod g+s $WEB_ROOT/uploads/
```

## Quick Reference

### Permission Cheat Sheet

```bash
# View permissions
ls -l file              # Long format
ls -ld directory        # Directory itself
stat file               # Detailed info
getfacl file            # ACLs

# Change permissions
chmod 755 file          # Numeric
chmod u+x file          # Symbolic
chmod -R 755 dir/       # Recursive

# Change ownership
chown user file         # Owner only
chown user:group file   # Owner and group
chown :group file       # Group only
chgrp group file        # Group only
chown -R user:group dir/  # Recursive

# Special permissions
chmod u+s file          # Setuid
chmod g+s dir           # Setgid
chmod +t dir            # Sticky bit
chmod 4755 file         # Setuid + 755
chmod 2775 dir          # Setgid + 775
chmod 1777 dir          # Sticky + 777

# ACLs
setfacl -m u:user:rwx file    # Add user ACL
setfacl -m g:group:rx file    # Add group ACL
setfacl -x u:user file        # Remove user ACL
setfacl -b file               # Remove all ACLs
getfacl file                  # View ACLs

# Default permissions
umask                   # View umask
umask 0022             # Set umask

# Extended attributes
lsattr file            # View attributes
chattr +i file         # Immutable
chattr +a file         # Append-only
```

### Common Commands

| Task | Command |
|------|---------|
| Make executable | `chmod +x file` |
| Readable by all | `chmod a+r file` |
| Private file | `chmod 600 file` |
| Shared directory | `chmod 2775 dir` |
| Web file | `chmod 644 file` |
| Script | `chmod 755 script.sh` |
| Change owner | `chown user file` |
| Change group | `chgrp group file` |
| Recursive ownership | `chown -R user:group dir/` |

## Further Reading

- [man chmod](https://man7.org/linux/man-pages/man1/chmod.1.html) - Change file permissions
- [man chown](https://man7.org/linux/man-pages/man1/chown.1.html) - Change file ownership
- [man umask](https://man7.org/linux/man-pages/man2/umask.2.html) - Set default permissions
- [man acl](https://man7.org/linux/man-pages/man5/acl.5.html) - Access Control Lists
- [man setfacl](https://man7.org/linux/man-pages/man1/setfacl.1.html) - Set ACLs
- [man getfacl](https://man7.org/linux/man-pages/man1/getfacl.1.html) - Get ACLs
- [man chattr](https://man7.org/linux/man-pages/man1/chattr.1.html) - Change file attributes
- [Linux File Permissions](https://wiki.archlinux.org/title/File_permissions_and_attributes) - Arch Wiki
