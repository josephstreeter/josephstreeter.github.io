---
title: "PGP Key Management"
description: "Practical lifecycle management for PGP keys, trust, backup, and revocation"
category: "security"
tags: ["pgp", "gpg", "key-management", "security"]
difficulty: "intermediate"
last_updated: "2026-05-23"
---

## PGP Key Management

Key management is the most important part of using PGP safely. Most real-world failures are operational, not cryptographic. This chapter focuses on the complete key lifecycle: creation, validation, usage, rotation, backup, and revocation.

## Lifecycle Overview

1. Generate key pair with expiration.
2. Protect private key with strong passphrase.
3. Share public key and verify fingerprints out-of-band.
4. Encrypt/sign during normal operations.
5. Rotate keys on policy schedule.
6. Revoke immediately on compromise.

## Create a Key Pair

### Command Line

```bash
# Generate key pair interactively
gpg --full-generate-key

# Recommended defaults for most users:
# - Key type: RSA and RSA
# - Key size: 4096
# - Expiration: 1y to 3y
# - Strong passphrase
```

### GUI Options

- Kleopatra: File -> New Certificate
- GPG Suite: Key creation wizard
- GPA: Keys -> New Key

## Share and Validate Public Keys

```bash
# Export your public key
gpg --armor --export your@email.com > mypublickey.asc

# Show fingerprint for out-of-band verification
gpg --fingerprint your@email.com
```

Validation checklist:

- Confirm full fingerprint over a second channel.
- Confirm UID/email matches intended recipient.
- Confirm key is not expired or revoked.

## Protect Private Keys

```bash
# Export private key for encrypted offline backup only
gpg --armor --export-secret-keys your@email.com > myprivatekey.asc

# Export owner trust values for recovery
gpg --export-ownertrust > ownertrust.txt
```

Private key safeguards:

- Keep private keys on minimal trusted endpoints.
- Back up offline using encrypted storage.
- Avoid storing key backups in shared cloud folders.

## Manage Expiration and Rotation

```bash
# Update expiration date
gpg --edit-key your@email.com
# gpg> key 0
# gpg> expire
# gpg> save
```

Rotation guidance:

- Rotate on a schedule (for example every 1-3 years).
- Publish new key before old key expires.
- Keep overlap window so contacts can transition.

## Generate Revocation Certificate

Create this immediately after key creation and store it offline.

```bash
# Generate revocation certificate
gpg --output revoke.asc --gen-revoke your@email.com
```

If compromised:

```bash
# Import revocation and publish it
gpg --import revoke.asc
gpg --keyserver hkps://keys.openpgp.org --send-keys your_key_id
```

## Useful Key Maintenance Commands

```bash
# List public keys
gpg --list-keys

# List private keys
gpg --list-secret-keys

# Refresh key metadata from keyserver
gpg --refresh-keys

# Edit key trust, UID, expiration, subkeys
gpg --edit-key your@email.com
```

## Operational Pitfalls to Avoid

- Trusting a key only because it appears on a keyserver.
- Using a key with no expiration date.
- Skipping revocation certificate creation.
- Failing to test backup restore workflows.

## Next Steps

- [Encryption and Decryption](05-encryption.md) - Apply your keys in daily workflows.
- [Email Integration](06-email-integration.md) - Configure secure email operations.
