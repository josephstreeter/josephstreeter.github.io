---
title: "PGP Email Integration"
description: "How to use PGP/GPG for secure email workflows across common clients"
tags: ["pgp", "gpg", "email", "security"]
category: "security"
difficulty: "intermediate"
last_updated: "2026-05-23"
---

## PGP Email Integration

PGP can be integrated with modern email workflows to provide message confidentiality and sender authentication. This chapter focuses on practical setup and daily use patterns that work reliably.

## What PGP Protects in Email

- Protects the **message body** and encrypted attachments
- Protects sender authenticity through **digital signatures**
- Does **not** protect most message metadata, including:
  - Subject line (unless your client supports protected subject conventions)
  - Sender and recipient addresses
  - Message timing and routing headers

> [!WARNING]
> PGP is not full transport anonymity. Even with encrypted content, email metadata can still reveal communication patterns.

## Integration Approaches

### Client-Native OpenPGP

Some email clients include built-in OpenPGP support. This is usually the easiest and most stable approach.

### Mail Client + GnuPG

Other clients rely on the local GnuPG keyring and helper tools. This approach is flexible but requires additional setup.

### Manual Inline Workflow

You can always encrypt and sign text manually with GPG, then paste armored output into email. This is the most portable fallback.

## Client Compatibility Snapshot

| Client | OpenPGP Support | Notes |
| --- | --- | --- |
| Thunderbird | Native (modern versions) | Recommended desktop option for OpenPGP email |
| Outlook | Varies by add-in and enterprise policy | Validate plugin support before rollout |
| Apple Mail | Usually via GPG tools/integration layer | Works well when GPG tooling is correctly installed |
| Webmail (Gmail/Outlook Web) | Usually no native OpenPGP | Use browser extensions or manual inline encryption |

## Before You Start

Complete these prerequisites first:

1. Install a trusted GPG implementation (see [Install Clients](03-install-clients.md)).
2. Generate your keypair and secure your private key (see [Key Management](04-key-management.md)).
3. Exchange and validate public keys with recipients.
4. Configure key trust levels where appropriate.

## Key Exchange and Validation for Email

### Preferred Key Exchange Methods

- Share public keys directly as `.asc` attachments
- Publish public keys on trusted profiles or organization directories
- Use key servers as an additional distribution channel

### Validation Checklist

- Confirm key fingerprint out-of-band (voice call, secure chat, in person)
- Verify key identity (email UID matches expected sender)
- Check expiration and revocation status before first use

> [!IMPORTANT]
> Importing a public key is not the same as trusting it. Always verify fingerprint and identity before relying on signatures or encrypting sensitive content.

## Recommended Sending Workflow

1. Compose message outside webmail draft boxes when content is sensitive.
2. Sign the message with your private key.
3. Encrypt to recipient public key(s).
4. Send armored text or encrypted MIME payload.
5. Confirm recipient can decrypt and verify signature.

## Inline Encryption Example

Use this when client integration is unavailable or unreliable.

```bash
# Encrypt and sign a plaintext file for a recipient
gpg --armor --encrypt --sign --recipient recipient@example.com message.txt

# Output is message.txt.asc
```

Open `message.txt.asc`, then paste the armored block into the email body.

## Attachment Encryption Example

```bash
# Encrypt and sign a file attachment
gpg --encrypt --sign --recipient recipient@example.com report.pdf

# Output is report.pdf.gpg
```

Attach `report.pdf.gpg` to your email. The recipient decrypts with their private key.

## Receiving and Verification Workflow

When you receive encrypted or signed email:

1. Decrypt using your private key and passphrase.
2. Verify signature result and key identity.
3. Treat warnings as security-relevant until resolved.
4. Archive encrypted originals for audit-sensitive workflows.

## Operational Best Practices

- Prefer sign + encrypt for confidential operational email
- Rotate keys according to policy, with planned overlap windows
- Publish revocation certificates for key-loss scenarios
- Back up private keys securely (offline encrypted storage)
- Use separate keys for personal and organizational contexts when possible

## Common Problems and Fixes

### Signature Shows as Untrusted

- Cause: Key imported but not validated/trusted
- Fix: Verify fingerprint and adjust trust locally

### Recipient Cannot Decrypt

- Cause: Encrypted to wrong key or missing recipient key
- Fix: Confirm recipient fingerprint and recipient UID before encrypting

### Message Appears Corrupted in Transit

- Cause: Mail gateways wrapped or altered inline armored text
- Fix: Send as attached `.asc`/`.gpg` file or switch to MIME-capable client integration

### Expired or Revoked Key Errors

- Cause: Stale key material in local keyring
- Fix: Refresh key from trusted source and revalidate fingerprint

## Security Notes for Email Metadata

Even when message contents are encrypted, assume the following are visible to providers and intermediaries:

- Who communicated with whom
- Approximate communication frequency
- Subject line in many workflows
- Timestamp and routing metadata

Use layered controls (separate channels, minimal metadata exposure, and organizational policy controls) when threat models require stronger privacy.

## Next Steps

- Review [PGP Encryption](05-encryption.md) for file and text workflows.
- Continue to [PGP Best Practices](07-best-practices.md) for operational hardening guidance.
