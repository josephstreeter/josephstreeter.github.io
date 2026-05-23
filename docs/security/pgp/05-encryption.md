---
title: "PGP Encryption"
description: "Practical PGP encryption and decryption workflows for files and messages"
category: "security"
tags: ["pgp", "gpg", "encryption", "security"]
difficulty: "intermediate"
last_updated: "2026-05-23"
---

## PGP Encryption

PGP encryption secures message and file contents so only intended recipients can read them. This chapter covers practical encryption and decryption patterns with both CLI and GUI workflows.

### Basic Encryption Concepts

PGP uses a hybrid encryption system that combines:

1. **Public-key (asymmetric) encryption**: Uses recipient's public key to encrypt data
2. **Symmetric encryption**: Uses a randomly generated session key for the actual file encryption
3. **Digital signatures**: Ensures authenticity and integrity of the message

## Pre-Encryption Checklist

Before encrypting sensitive data:

1. Verify recipient fingerprint out-of-band.
2. Confirm recipient key is not expired/revoked.
3. Confirm you selected the correct recipient key ID.
4. Decide whether to sign + encrypt (recommended for most sensitive workflows).

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

To encrypt for multiple recipients:

```bash
gpg --encrypt --sign \
  --recipient alice@example.com \
  --recipient bob@example.com \
  document.txt
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

If signature verification fails, do not trust the decrypted content until the key and message integrity are validated.

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

For interactive terminal use:

```bash
# Encrypt text from stdin
echo "Secret message" | gpg --armor --encrypt --recipient recipient@email.com
```

### Verifying Signatures

To verify a signed file:

```bash
# Verify a signature
gpg --verify document.txt.sig document.txt
```

Expected outcomes:

- Good signature from trusted key: accept.
- Good signature from unknown/untrusted key: verify fingerprint before trust.
- Bad signature: treat as tampering or wrong key.

### Best Practices

1. **Always verify signatures** when decrypting files from others
2. **Use trusted channels** for initially exchanging public keys
3. **Sign your encrypted messages** to provide authentication
4. **Keep your private key secure** and protected by a strong passphrase
5. **Use ASCII armor** (`--armor` flag) when sharing encrypted text via text channels

## Common Encryption Errors

### Encrypted to Wrong Recipient

- Symptom: intended recipient cannot decrypt.
- Fix: check recipient key ID/fingerprint before encrypting.

### Untrusted Signature Warning

- Symptom: signature validates cryptographically but trust is low.
- Fix: verify fingerprint and set trust deliberately.

### Corrupted Armored Block

- Symptom: decryption fails after copy/paste.
- Fix: send as attached `.asc`/`.gpg` file instead of inline paste.

### Next Steps

- [Email Integration](06-email-integration.md) - Configure email clients for PGP
- [Best Practices](07-best-practices.md) - Advanced security considerations
