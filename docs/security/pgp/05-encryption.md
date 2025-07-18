---
title: "PGP Encryption"
description: "Guide to PGP Encryption"
category: "security"
tags: ["pgp", "encryption", "security"]
---

## PGP Encryption

PGP encryption allows you to secure your communications by encrypting files, messages, and emails. This guide covers the fundamental encryption and decryption operations using both command-line and GUI tools.

### Basic Encryption Concepts

PGP uses a hybrid encryption system that combines:

1. **Public-key (asymmetric) encryption**: Uses recipient's public key to encrypt data
2. **Symmetric encryption**: Uses a randomly generated session key for the actual file encryption
3. **Digital signatures**: Ensures authenticity and integrity of the message

### Encrypting Files

#### Command Line (GPG)

To encrypt a file for a specific recipient:

```bash
# Encrypt a file for a specific recipient
gpg --encrypt --recipient recipient@email.com document.txt

# This creates an encrypted file: document.txt.gpg
```

To encrypt and sign a file (recommended):

```bash
# Encrypt and sign a file
gpg --encrypt --sign --recipient recipient@email.com document.txt
```

#### Using GUI Applications

**Kleopatra/GPG4Win:**

1. Right-click the file in Explorer
2. Select "Sign and Encrypt"
3. Choose recipient(s)
4. Complete the encryption process

**GPG Suite (macOS):**

1. Right-click the file in Finder
2. Select "Services" → "OpenPGP: Encrypt File"
3. Choose recipient(s)

### Decrypting Files

#### Command Line Decryption

```bash
# Decrypt a file
gpg --decrypt encrypted-file.gpg > decrypted-file.txt

# If the file is signed, GPG will verify the signature automatically
```

#### GUI Decryption Applications

**Kleopatra/GPG4Win:**

1. Double-click the .gpg file
2. Enter your passphrase when prompted

**GPG Suite (macOS):**

1. Double-click the encrypted file
2. Enter your passphrase when prompted

### Text Encryption

To encrypt text messages (e.g., for secure messaging):

```bash
# Create a text file with your message
echo "Secret message" > message.txt

# Encrypt the message
gpg --encrypt --armor --recipient recipient@email.com message.txt

# The output file (message.txt.asc) contains ASCII-armored encrypted text
# that can be copied and pasted into emails or messaging apps
```

### Verifying Signatures

To verify a signed file:

```bash
# Verify a signature
gpg --verify document.txt.sig document.txt
```

### Best Practices

1. **Always verify signatures** when decrypting files from others
2. **Use trusted channels** for initially exchanging public keys
3. **Sign your encrypted messages** to provide authentication
4. **Keep your private key secure** and protected by a strong passphrase
5. **Use ASCII armor** (`--armor` flag) when sharing encrypted text via text channels

### Next Steps

- [Email Integration](06-email-integration.md) - Configure email clients for PGP
- [Best Practices](07-best-practices.md) - Advanced security considerations

## Overview

Content will be added soon.

## Key Points

- Important information about PGP Encryption
- Step-by-step instructions
- Best practices
