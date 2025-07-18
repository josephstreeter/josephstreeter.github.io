---
title: "PGP Key Management"
description: "Guide to PGP Key Management"
category: "security"
tags: ["pgp", "encryption", "security"]
---

## PGP Key Management

Managing your PGP keys effectively is crucial for maintaining security and ensuring smooth operation of your encrypted communications. This guide covers essential key management tasks including creation, backup, expiration, and revocation.

### Creating Your Key Pair

#### Using GPG Command Line

```bash
# Generate a new key pair
gpg --full-generate-key

# Use the following settings for best security:
# - Key type: RSA and RSA (default)
# - Key size: 4096 bits
# - Key validity: 2 years (or appropriate for your use case)
# - Provide your real name and email address
# - Set a strong passphrase
```

#### Using GUI Applications

- **Kleopatra**: Click "File" → "New Key Pair"
- **GPG4Win**: Use the Certificate Creation Wizard
- **GPG Suite**: Use the Key Creation Assistant

### Exporting Your Keys

```bash
# Export your public key to share with others
gpg --export --armor your@email.com > mypublickey.asc

# Export your private key for backup (keep secure!)
gpg --export-secret-keys --armor your@email.com > myprivatekey.asc
```

### Managing Key Expiration

Setting an expiration date on your key is recommended for security:

```bash
# Edit your key
gpg --edit-key your@email.com

# At the gpg> prompt:
gpg> key 0
gpg> expire
# Follow prompts to set new expiration
gpg> save
```

### Revoking Keys

If your key is compromised, you should revoke it immediately:

```bash
# Generate a revocation certificate (do this in advance)
gpg --gen-revoke your@email.com > revoke.asc

# To revoke your key
gpg --import revoke.asc
gpg --keyserver keys.gnupg.net --send-keys your_key_id
```

### Key Backup Best Practices

1. **Export both public and private keys** to secure offline storage
2. **Create a revocation certificate** and store it securely
3. **Use encrypted storage** for your private key backups
4. **Consider paper backups** for long-term storage
5. **Store copies in multiple physical locations** to prevent loss

### Next Steps

- [Encryption and Decryption](05-encryption.md) - Learn how to use your keys
- [Email Integration](06-email-integration.md) - Set up PGP with your email client

## Overview

Content will be added soon.

## Key Points

- Important information about PGP Key Management
- Step-by-step instructions
- Best practices
