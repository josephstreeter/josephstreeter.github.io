---
title: "PGP Best Practices"
description: "Operational best practices for safe, reliable PGP/GPG usage"
tags: ["pgp", "gpg", "security", "best-practices"]
category: "security"
difficulty: "intermediate"
last_updated: "2026-05-23"
---

## PGP Best Practices

PGP is only as strong as the operational discipline around keys, endpoints, and workflows. These practices help reduce avoidable failures and improve trust in encrypted communications.

## Core Security Principles

Use these principles as a baseline:

- Protect private keys as high-value secrets
- Verify identities before trusting public keys
- Sign and encrypt sensitive content by default
- Keep endpoints clean and patched
- Plan for key loss, compromise, and rotation

## Key Lifecycle Management

### Generate Strong Keys

- Use modern GnuPG defaults, typically RSA 3072/4096 or approved ECC profiles
- Set an expiration date so stale keys age out naturally
- Use separate subkeys for signing and encryption when possible

### Use Strong Passphrases

- Use long, unique passphrases (prefer passphrases over short passwords)
- Avoid reuse across services
- Store in a trusted password manager when policy allows

### Rotate Keys on a Schedule

- Rotate based on organizational policy and risk tolerance
- Maintain overlap windows so counterparties can transition cleanly
- Announce new fingerprints through trusted channels

### Create Revocation Certificates Early

Create and store a revocation certificate immediately after key creation.

- Keep revocation certs offline and protected
- Document when and how revocation should be published

## Trust and Identity Verification

### Verify Fingerprints Out-of-Band

Before using a key for sensitive data:

1. Validate full fingerprint over an independent channel.
2. Confirm expected identity and email UID.
3. Check expiration and revocation status.

### Apply Trust Deliberately

- Importing a key is not equivalent to trusting the identity
- Assign owner trust only after identity verification
- Revalidate trust when users change organizations or roles

## Secure Endpoint Practices

### Keep Private Key Material Local and Minimal

- Prefer local key storage on managed endpoints
- Avoid copying private keys between many machines
- Use hardware-backed storage (smartcard/token) when available

### Harden Hosts Used for Decryption

- Apply OS and browser patches promptly
- Use endpoint protection and anti-malware controls
- Reduce high-risk plugin/extension surface on machines handling secrets

> [!WARNING]
> PGP cannot protect plaintext captured before encryption or after decryption. A compromised endpoint can bypass otherwise correct cryptography.

## Messaging and File Handling Practices

### Sign and Encrypt Appropriately

- **Encrypt** for confidentiality
- **Sign** for authenticity and integrity
- For sensitive business workflows, prefer **sign + encrypt**

### Avoid Metadata Leaks

- Do not place sensitive details in subject lines
- Keep recipient lists minimal
- Be aware that headers, timing, and routing metadata remain visible

### Prefer Reliable Formats

- Use ASCII armor for copy/paste channels
- Use attachments when mail gateways mangle inline armored blocks
- Test interoperability for each recipient environment

## Backup and Recovery

### Backup Strategy

- Maintain encrypted offline backups of private keys
- Keep at least one tested recovery path for critical roles
- Restrict backup access with least privilege

### Recovery Drills

- Periodically test key restore in a controlled environment
- Validate that restored keys can decrypt historical data where required
- Confirm revocation + replacement process works end-to-end

## Team and Organization Practices

### Standardize Policy

Define and document:

- Approved algorithms and key lengths
- Key expiration and rotation intervals
- Identity verification process for public key onboarding
- Revocation handling and incident response ownership

### Train Users on Common Failure Modes

- Encrypting to wrong recipient key
- Ignoring invalid/untrusted signature warnings
- Sending sensitive plaintext in subject/body drafts
- Losing private keys without backup or revocation plan

## Operational Checklist

Use this checklist before high-sensitivity exchanges:

1. Recipient fingerprint verified out-of-band.
2. Recipient key not expired or revoked.
3. Message signed and encrypted.
4. No sensitive content in subject line.
5. Local private key backup and revocation readiness confirmed.

## Common Mistakes to Avoid

- Treating key server presence as identity proof
- Reusing old keys long past intended lifecycle
- Sharing private keys over chat/email for convenience
- Skipping signature verification when decrypt succeeds
- Assuming encryption hides all metadata

## Next Steps

- Review [Command Line Usage](08-command-line.md) for repeatable CLI workflows.
- Continue to [Advanced Security](10-advanced.md) for deeper hardening patterns.
