---
title: "PGP/GPG Command Line Reference"
description: "Comprehensive command-line reference for GnuPG operations including key management, encryption, and signing"
tags: ["pgp", "gpg", "command-line", "cli", "gnupg", "terminal"]
category: "security"
difficulty: "intermediate"
last_updated: "2025-01-20"
---

## PGP/GPG Command Line Reference

This comprehensive guide covers essential GnuPG command-line operations for encryption, decryption, signing, and key management.

## Prerequisites

Before using these commands, ensure you have:

- GnuPG installed on your system
- Basic understanding of PGP concepts
- Terminal/command prompt access

## Installation

### Linux (Debian/Ubuntu)

```bash
# Install GnuPG
sudo apt update
sudo apt install gnupg

# Verify installation
gpg --version
```

### Linux (Red Hat/CentOS/Fedora)

```bash
# RHEL/CentOS 7
sudo yum install gnupg2

# RHEL/CentOS 8+ and Fedora
sudo dnf install gnupg2

# Verify installation
gpg --version
```

### macOS

```bash
# Using Homebrew
brew install gnupg

# Using MacPorts
sudo port install gnupg2

# Verify installation
gpg --version
```

### Windows

```powershell
# Using Chocolatey
choco install gnupg

# Using Scoop
scoop install gpg

# Verify installation
gpg --version
```

## Key Management

### Create New Key Pair

**Interactive key generation (recommended for beginners):**

```bash
# Start interactive key generation
gpg --gen-key

# Follow prompts:
# - Choose key type (RSA recommended)
# - Choose key size (4096 bits recommended)
# - Set expiration (2-4 years recommended)
# - Enter name and email
# - Set strong passphrase
```

**Full key generation with all options:**

```bash
# Advanced key generation with more options
gpg --full-generate-key

# Options include:
# (1) RSA and RSA (default) - recommended
# (2) DSA and Elgamal
# (3) DSA (sign only)
# (4) RSA (sign only)
# (9) ECC and ECC
```

**Batch key generation:**

```bash
# Create batch file for automated generation
cat > keygen.batch << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Your Name
Name-Email: your.email@example.com
Expire-Date: 2y
Passphrase: YourSecurePassphrase123!
%commit
EOF

# Generate key using batch file
gpg --batch --generate-key keygen.batch

# Securely delete batch file
shred -vfz -n 3 keygen.batch
```

### List Keys

```bash
# List all public keys in keyring
gpg --list-keys

# List with key fingerprints
gpg --list-keys --fingerprint

# List secret/private keys
gpg --list-secret-keys

# List specific key
gpg --list-keys your.email@example.com

# Detailed key information
gpg --list-keys --with-colons
```

### Export Keys

**Export public key:**

```bash
# Export public key to file (ASCII armored)
gpg --armor --export your.email@example.com > public-key.asc

# Export public key to stdout
gpg --armor --export your.email@example.com

# Export specific key by ID
gpg --armor --export A1B2C3D4E5F6 > public-key.asc

# Export all public keys
gpg --armor --export-all > all-public-keys.asc
```

**Export private key:**

```bash
# Export private key (requires passphrase)
gpg --armor --export-secret-keys your.email@example.com > private-key.asc

# Export specific private key by ID
gpg --armor --export-secret-keys A1B2C3D4E5F6 > private-key.asc

# Export secret subkeys only
gpg --armor --export-secret-subkeys your.email@example.com > subkeys.asc
```

### Import Keys

```bash
# Import public key from file
gpg --import public-key.asc

# Import private key from file
gpg --import private-key.asc

# Import from multiple files
gpg --import key1.asc key2.asc key3.asc

# Import with verbose output
gpg --import --verbose public-key.asc

# Import and show fingerprint
gpg --import --import-options show-only public-key.asc
```

### Key Server Operations

**Search for keys:**

```bash
# Search for key by email
gpg --keyserver hkps://keys.openpgp.org --search-keys friend@example.com

# Search by name
gpg --keyserver hkps://keys.openpgp.org --search-keys "John Doe"

# Search by key ID
gpg --keyserver hkps://keys.openpgp.org --search-keys A1B2C3D4E5F6
```

**Receive keys:**

```bash
# Download key by ID
gpg --keyserver hkps://keys.openpgp.org --recv-keys A1B2C3D4E5F6

# Download key by email
gpg --keyserver hkps://keys.openpgp.org --recv-keys friend@example.com
```

**Send keys:**

```bash
# Send your public key to keyserver
gpg --keyserver hkps://keys.openpgp.org --send-keys your.email@example.com

# Send specific key by ID
gpg --keyserver hkps://keys.openpgp.org --send-keys A1B2C3D4E5F6

# Send to multiple keyservers
gpg --keyserver hkps://keyserver.ubuntu.com --send-keys your.email@example.com
```

**Refresh keys:**

```bash
# Refresh all keys from keyserver
gpg --refresh-keys

# Refresh specific key
gpg --refresh-keys friend@example.com
```

## Encryption and Decryption

### Encrypt Files

**Encrypt for single recipient:**

```bash
# Encrypt file for specific recipient
gpg --encrypt --recipient friend@example.com document.txt

# Encrypt with ASCII armor (for text transmission)
gpg --armor --encrypt --recipient friend@example.com document.txt

# Specify output file
gpg --armor --encrypt --recipient friend@example.com --output document.asc document.txt
```

**Encrypt for multiple recipients:**

```bash
# Encrypt for multiple recipients
gpg --armor --encrypt \
    --recipient alice@example.com \
    --recipient bob@example.com \
    --recipient charlie@example.com \
    document.txt
```

**Encrypt and sign:**

```bash
# Encrypt and sign in one operation
gpg --armor --encrypt --sign \
    --recipient friend@example.com \
    --local-user your.email@example.com \
    document.txt
```

**Symmetric encryption:**

```bash
# Encrypt with passphrase only (no public key needed)
gpg --symmetric --armor document.txt

# Specify cipher algorithm
gpg --symmetric --armor --cipher-algo AES256 document.txt
```

### Decrypt Files

```bash
# Decrypt file (will prompt for passphrase)
gpg --decrypt document.txt.gpg

# Decrypt and save to specific file
gpg --decrypt --output decrypted.txt document.txt.gpg

# Decrypt and verify signature
gpg --decrypt --verify document.txt.gpg
```

### Encrypt/Decrypt from Standard Input

```bash
# Encrypt text from command line
echo "Secret message" | gpg --armor --encrypt --recipient friend@example.com

# Encrypt file contents
cat secret.txt | gpg --armor --encrypt --recipient friend@example.com > encrypted.asc

# Decrypt from standard input
cat encrypted.asc | gpg --decrypt
```

## Digital Signatures

### Create Signatures

**Detached signature:**

```bash
# Create detached signature file
gpg --armor --detach-sign document.txt

# Creates document.txt.asc containing signature
# Original file remains unchanged
```

**Inline signature:**

```bash
# Create signed file with signature embedded
gpg --armor --sign document.txt

# Creates document.txt.asc with signature and content
```

**Clear signature:**

```bash
# Create human-readable signed message
gpg --armor --clearsign message.txt

# Message remains readable with signature attached
```

### Verify Signatures

```bash
# Verify detached signature
gpg --verify document.txt.asc document.txt

# Verify inline signature
gpg --verify signed-document.asc

# Verify and extract clear-signed message
gpg --verify clear-signed.asc
```

## Advanced Operations

### Key Editing and Trust

**Edit key properties:**

```bash
# Enter key editing mode
gpg --edit-key your.email@example.com

# Common commands in edit mode:
# trust    - Change trust level
# expire   - Change expiration date
# passwd   - Change passphrase
# adduid   - Add user ID
# deluid   - Delete user ID
# addkey   - Add subkey
# delkey   - Delete subkey
# revkey   - Revoke subkey
# save     - Save changes
# quit     - Exit without saving
```

**Set key trust:**

```bash
gpg --edit-key friend@example.com
# In GPG prompt:
gpg> trust
# Choose trust level (1-5):
# 1 = I don't know or won't say
# 2 = I do NOT trust
# 3 = I trust marginally
# 4 = I trust fully
# 5 = I trust ultimately
gpg> save
```

### Key Revocation

**Generate revocation certificate:**

```bash
# Generate revocation certificate
gpg --output revoke.asc --gen-revoke your.email@example.com

# Store safely! This can permanently revoke your key
```

**Revoke a key:**

```bash
# Import and apply revocation certificate
gpg --import revoke.asc

# Send revocation to keyserver
gpg --keyserver hkps://keys.openpgp.org --send-keys your.email@example.com
```

### Backup and Restore

**Complete backup:**

```bash
# Backup entire keyring
gpg --export-all > all-public-keys.gpg
gpg --export-secret-keys > all-private-keys.gpg
gpg --export-ownertrust > ownertrust.txt

# Backup to specific directory
mkdir gpg-backup
gpg --export-all > gpg-backup/public-keys.gpg
gpg --export-secret-keys > gpg-backup/private-keys.gpg
gpg --export-ownertrust > gpg-backup/ownertrust.txt
```

**Restore from backup:**

```bash
# Restore keys
gpg --import gpg-backup/public-keys.gpg
gpg --import gpg-backup/private-keys.gpg
gpg --import-ownertrust gpg-backup/ownertrust.txt
```

## Configuration and Optimization

### Configuration File

Create `~/.gnupg/gpg.conf` for custom settings:

```bash
# Security-focused configuration
cat > ~/.gnupg/gpg.conf << EOF
# Use strong algorithms
personal-cipher-preferences AES256 AES192 AES
personal-digest-preferences SHA512 SHA384 SHA256
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed

# Disable weak algorithms
disable-cipher-algo 3DES
disable-cipher-algo CAST5
weak-digest SHA1

# Security settings
require-cross-certification
no-symkey-cache
throw-keyids
no-emit-version
no-comments
keyid-format 0xlong
with-fingerprint
list-options show-uid-validity
verify-options show-uid-validity

# Keyserver settings
keyserver hkps://keys.openpgp.org
keyserver-options no-honor-keyserver-url
keyserver-options include-revoked
EOF
```

### Performance Options

```bash
# Speed up operations with multiple cores
gpg --compress-level 1 --cipher-algo AES128 --digest-algo SHA256

# Disable compression for large files
gpg --compress-level 0

# Use faster algorithms for testing
gpg --cipher-algo AES128 --digest-algo SHA1
```

## Batch Operations and Scripting

### Batch Processing

```bash
# Process multiple files
for file in *.txt; do
    gpg --armor --encrypt --recipient friend@example.com "$file"
done

# Decrypt multiple files
for file in *.gpg; do
    gpg --batch --yes --decrypt "$file" > "${file%.gpg}"
done
```

### Automated Operations

```bash
# Non-interactive mode (for scripts)
gpg --batch --yes --armor --encrypt --recipient friend@example.com document.txt

# Use passphrase from file (security risk!)
gpg --batch --yes --passphrase-file passfile --decrypt secret.gpg

# Use GPG agent for passphrase caching
eval $(gpg-agent --daemon)
```

## Troubleshooting

### Common Issues

**GPG Agent problems:**

```bash
# Restart GPG agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

# Check agent status
gpg-connect-agent 'getinfo version' /bye
```

**Permission issues:**

```bash
# Fix GPG directory permissions
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*
```

**Key import failures:**

```bash
# Import with detailed error output
gpg --import --verbose --debug-level basic key.asc

# Check key format
file key.asc
```

### Debugging

```bash
# Enable verbose output
gpg --verbose --decrypt message.gpg

# Debug mode
gpg --debug-level basic --decrypt message.gpg

# List detailed key information
gpg --list-keys --with-colons --with-fingerprint
```

## Security Best Practices

### Secure Key Generation

```bash
# Generate keys on secure, offline system
# Use hardware random number generator if available
gpg --gen-key --expert

# Generate with additional entropy
sudo apt install rng-tools
sudo rngd -r /dev/urandom
gpg --gen-key
```

### Secure Operations

```bash
# Always verify signatures
gpg --verify --verbose signature.asc

# Use secure deletion for sensitive files
shred -vfz -n 3 private-key.asc

# Check key fingerprints
gpg --fingerprint friend@example.com
```

## Quick Reference

### Most Common Commands

```bash
# Generate new key
gpg --gen-key

# List keys
gpg --list-keys

# Export public key
gpg --armor --export your@email.com

# Import key
gpg --import key.asc

# Encrypt file
gpg --armor --encrypt --recipient friend@email.com file.txt

# Decrypt file
gpg --decrypt file.txt.gpg

# Sign file
gpg --armor --detach-sign file.txt

# Verify signature
gpg --verify file.txt.asc file.txt
```

### Key Shortcuts

```bash
# Short key ID format
gpg --keyid-format SHORT --list-keys

# Long key ID format
gpg --keyid-format LONG --list-keys

# Use key ID instead of email
gpg --encrypt --recipient 0xABCD1234 file.txt
```

This command-line reference provides comprehensive coverage of GnuPG operations. For GUI alternatives, see our [Usage Guide](02-usage.md), and for advanced security practices, consult the [Advanced Security Guide](10-advanced.md).
