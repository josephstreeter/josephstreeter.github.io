---
title: "Advanced PGP/GPG Security Practices"
description: "Advanced security techniques for PGP/GPG including metadata protection, operational security, and best practices"
tags: ["pgp", "gpg", "security", "opsec", "metadata", "advanced"]
category: "security"
difficulty: "advanced"
last_updated: "2025-01-20"
---

## Advanced PGP/GPG Security Practices

This guide covers advanced security techniques for PGP/GPG usage, focusing on operational security (OPSEC), metadata protection, and threat mitigation strategies.

## Understanding the Threat Model

Before implementing advanced security measures, it's crucial to understand your threat model:

- **State-level adversaries** - Government surveillance and intelligence agencies
- **Corporate surveillance** - Email providers, ISPs, and data brokers
- **Criminal actors** - Hackers, ransomware groups, and organized crime
- **Personal threats** - Stalkers, abusive partners, or targeted harassment

> [!IMPORTANT]
> PGP protects message content but cannot protect metadata. Understanding this limitation is crucial for proper operational security.

## Metadata Protection

### Understanding Email Metadata

Metadata provides context to email content. Even with PGP encryption, significant metadata remains exposed:

**Always Exposed:**

- **Subject line** - Completely visible to all intermediaries
- **To/From addresses** - Sender and recipient identities
- **Timestamps** - When messages were sent/received
- **IP addresses** - Location information of sender
- **Email client** - Software fingerprinting information
- **Message size** - Can reveal content type
- **Routing headers** - Path the email took through servers

**Sometimes Exposed:**

- **Recipient count** - Number of recipients (TO, CC, BCC)
- **Message threading** - Reply relationships
- **Attachment presence** - Whether files are attached
- **Key fingerprints** - Which PGP keys can decrypt (unless using `--throw-keyids`)

### Metadata Minimization Strategies

#### Subject Line Protection

The subject line is completely unprotected and should be treated as public information.

**Acceptable subjects (in order of preference):**

1. **(Empty)** - No subject line at all
2. **Single character** - `.` or `-` or `_`
3. **Generic strings** - `...` or `xxx` or `;;;` or `:::`
4. **Random characters** - `a7k9m` (but avoid patterns)

**Never use subjects that:**

- Reference message content
- Contain sensitive keywords
- Follow predictable patterns
- Reveal sender/recipient relationship context

> [!WARNING]
> **Example of fatal OPSEC failure**: "Subject: Your cocaine has shipped!" reveals criminal activity regardless of encrypted content.

**Configure your email client:**

```text
Disable: "Warn about empty subject"
Enable: "Allow empty subject lines"
```

#### IP Address Protection

Your IP address reveals your approximate location and ISP.

**Protection methods:**

1. **VPN services** - Commercial or self-hosted
2. **Tor network** - Use Tor Browser or configure email client through Tor
3. **Public WiFi** - Use networks not associated with your identity
4. **Proxy services** - HTTP/SOCKS proxies (less secure than VPN/Tor)

**Tor configuration for email:**

```bash
# Configure email client to use Tor SOCKS proxy
# SOCKS5 proxy: 127.0.0.1:9050
# Or use torsocks for command-line tools
torsocks gpg --send-keys KEYID
```

#### Email Account Isolation

Create dedicated email accounts for sensitive communications:

**Account creation guidelines:**

- Use different identity/pseudonym
- Register through Tor/VPN
- Use secure email providers (ProtonMail, Tutanota, etc.)
- Never link to existing accounts or personal information
- Use separate recovery information

## Secure Email Composition

### Writing Environment Security

#### Option 1: Maximum Security (Recommended)

```bash
# 1. Write message in secure text editor
nano secure_message.txt

# 2. Encrypt using command line
gpg --armor --encrypt --recipient friend@example.com secure_message.txt

# 3. Copy encrypted output to email client
cat secure_message.txt.asc

# 4. Securely delete original
shred -vfz -n 3 secure_message.txt
shred -vfz -n 3 secure_message.txt.asc
```

#### Option 2: Controlled Environment

- Write in email client but disable automatic saving
- Disable draft synchronization to server
- Use local-only email storage
- Encrypt before any network transmission

### Draft Management

Drafts represent a significant security risk and must be handled carefully.

**Security requirements:**

- **Never store in plaintext** - Always encrypt drafts
- **Store locally only** - Never synchronize to email servers
- **Delete after use** - Securely wipe draft files
- **Encrypt before writing** - Pre-encrypt before saving

**Email client configuration:**

```text
Drafts folder: Local folder only
Auto-save: Disabled
Server synchronization: Disabled
Draft encryption: Enabled (if available)
```

**Manual draft encryption:**

```bash
# Encrypt draft for yourself
gpg --armor --encrypt --recipient your@email.com draft.txt

# Edit encrypted draft
gpg --decrypt draft.txt.gpg | nano

# Re-encrypt after editing
gpg --armor --encrypt --recipient your@email.com updated_draft.txt
```

### Message Composition Best Practices

#### Information Minimization

- **Keep messages concise** - Reduce information density
- **Avoid context accumulation** - Don't include conversation history
- **Use references instead of details** - "The thing we discussed" vs. specific details
- **Implement information compartmentalization** - One topic per message

#### Reply Hygiene

```markdown
❌ BAD: Including full conversation history
> On Jan 15, Alice wrote:
> > The meeting about Project X is tomorrow
> > Location: Secret facility
> > Attendees: [full list]
> Thanks for confirming...

✅ GOOD: Minimal relevant context
Thanks for confirming tomorrow.
```

### Attachment Security

#### PGP File Encryption

Instead of sending `secret-documents.tar.gz.gpg`, use PGP's built-in compression:

```bash
# Bundle and encrypt multiple files
gpg-zip --tar --encrypt --recipient friend@example.com file1 file2 directory/

# Alternative using tar and gpg
tar -czf - file1 file2 directory/ | gpg --armor --encrypt --recipient friend@example.com > bundle.asc

# Decrypt bundled files
gpg --decrypt bundle.asc | tar -xzf -
```

#### Filename Obfuscation

```bash
# Rename sensitive files before encryption
cp "NSA_surveillance_docs.pdf" "report.pdf"
gpg --armor --encrypt --recipient journalist@example.com report.pdf
rm report.pdf  # Clean up
```

## Advanced Encryption Techniques

### Hiding Recipient Information

By default, PGP includes recipient key IDs in encrypted messages, revealing who can decrypt the message.

```bash
# Hide recipient key IDs (anonymous encryption)
gpg --armor --encrypt --throw-keyids --recipient friend@example.com message.txt

# Multiple recipients with hidden IDs
gpg --armor --encrypt --throw-keyids \
    --recipient alice@example.com \
    --recipient bob@example.com \
    message.txt
```

### Perfect Forward Secrecy Considerations

Standard PGP doesn't provide perfect forward secrecy. If your private key is compromised, all past messages can be decrypted.

**Mitigation strategies:**

1. **Regular key rotation** - Generate new keys periodically
2. **Ephemeral subkeys** - Use short-lived signing/encryption subkeys
3. **Modern alternatives** - Consider Signal for real-time communication

### Steganography Integration

Hide encrypted messages within other data:

```bash
# Hide PGP message in image file
steghide embed -cf cover_image.jpg -ef encrypted_message.asc

# Extract hidden message
steghide extract -sf image_with_message.jpg
```

## Operational Security (OPSEC)

### Default Security Configurations

#### Always Encrypt by Default

Configure your email client to encrypt all outgoing messages by default:

```text
Default encryption: ON
Require manual override: YES
Warn on plaintext: ENABLED
```

#### Signing Considerations

Digital signatures provide authentication but also provide positive identification.

**When to sign:**

- ✅ **Public statements** - When you want attribution
- ✅ **Legal documents** - When non-repudiation is required
- ✅ **Software releases** - For integrity verification

**When NOT to sign:**

- ❌ **Anonymous communications** - Defeats anonymity
- ❌ **Sensitive operations** - Provides positive identification
- ❌ **Routine messages** - Unnecessary operational signature

**Configuration:**

```text
Default signing: OFF
Require manual override: YES
Sign only when explicitly chosen: ENABLED
```

### Message Lifecycle Management

#### Secure Deletion Policy

Implement a comprehensive deletion strategy:

```bash
# Secure deletion commands
shred -vfz -n 3 filename        # Linux
rm -P filename                  # macOS
sdelete -p 3 -z filename       # Windows (SysInternals)
```

**Email folder management:**

- **INBOX ZERO** - Process and delete all incoming messages
- **OUTBOX ZERO** - Delete sent messages after confirmation
- **DRAFTS ZERO** - Never retain draft messages
- **TRASH ZERO** - Empty trash regularly with secure deletion

#### Automated Cleanup

```bash
# Cron job for automatic cleanup (Linux/macOS)
# Add to crontab: 0 2 * * * /path/to/cleanup.sh

#!/bin/bash
# cleanup.sh
find ~/.thunderbird -name "*.msf" -mtime +7 -delete
find ~/.thunderbird -name "*Trash*" -exec rm -rf {} \;
gpgconf --kill all
```

### Server-Side Security

#### Local Storage Configuration

```text
Message storage: Local folders only
Server synchronization: Disabled
IMAP expunge: Immediate
POP3 deletion: Delete from server immediately
```

#### Email Provider Selection

Choose providers with:

- **No logging policies** - Minimal metadata retention
- **Onion service support** - .onion addresses for Tor access
- **Forward secrecy** - For transport encryption
- **No cooperation agreements** - Avoid Five Eyes jurisdictions

## Advanced Configuration

### GPG Configuration Hardening

Create a secure `~/.gnupg/gpg.conf`:

```bash
# ~/.gnupg/gpg.conf - Advanced security configuration

# Use strong algorithms
personal-cipher-preferences AES256 AES192 AES
personal-digest-preferences SHA512 SHA384 SHA256
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed

# Disable weak algorithms
disable-cipher-algo 3DES
disable-cipher-algo CAST5
disable-cipher-algo BLOWFISH
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
keyserver-options no-auto-key-retrieve

# Trust model
trust-model tofu+pgp
tofu-default-policy unknown

# Network security
use-tor
```

### Agent Configuration

Configure `~/.gnupg/gpg-agent.conf`:

```bash
# ~/.gnupg/gpg-agent.conf

# Cache settings (shorter for security)
default-cache-ttl 300          # 5 minutes
max-cache-ttl 900             # 15 minutes

# Pinentry settings
pinentry-program /usr/bin/pinentry-curses
no-allow-external-cache
no-allow-mark-trusted

# Security
disable-scdaemon
```

## Threat-Specific Mitigations

### State-Level Adversaries

**Additional precautions:**

- **Hardware security modules** - Yubikey, Nitrokey for key storage
- **Air-gapped systems** - Offline key generation and signing
- **Multiple identity isolation** - Separate key pairs for different contexts
- **Decoy traffic** - Regular dummy communications to obscure real messages

### Traffic Analysis Resistance

```bash
# Generate decoy traffic
for i in {1..10}; do
    echo "Decoy message $i $(date)" | \
    gpg --armor --encrypt --recipient decoy@example.com > /dev/null
    sleep $((RANDOM % 3600))  # Random delay up to 1 hour
done
```

### Forensic Resistance

**System-level protections:**

- **Full disk encryption** - LUKS, FileVault, BitLocker
- **RAM encryption** - Cold boot attack protection
- **Secure boot** - Prevent tampering
- **Memory wiping** - Clear sensitive data from RAM

```bash
# Clear bash history
history -c && history -w

# Clear swap files
sudo swapoff -a
sudo swapon -a

# Clear system caches
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

## Recommended Tools and Configurations

### Secure Email Clients

1. **Thunderbird + Enigmail/Built-in PGP**
   - Open source
   - Extensive PGP integration
   - Good security features

2. **Mutt + GnuPG**
   - Command-line interface
   - Maximum control
   - Minimal attack surface

3. **Sylpheed/Claws Mail**
   - Lightweight
   - Good PGP support
   - Cross-platform

### Alternative Communication Channels

For real-time communication with forward secrecy:

1. **Signal** - Mobile messaging with PGP-like security
2. **Session** - Onion routing + Signal protocol
3. **Briar** - Peer-to-peer messaging
4. **Ricochet** - Anonymous instant messaging over Tor

## Compliance and Legal Considerations

### Legal Frameworks

Be aware of relevant laws in your jurisdiction:

- **Export controls** - Cryptography export restrictions
- **Key disclosure laws** - Mandatory key surrender requirements
- **Data retention** - Legal requirements for message preservation
- **Evidence tampering** - Secure deletion implications

### Audit and Documentation

For organizational use:

- **Security audit trails** - Log security-relevant events
- **Key management procedures** - Documented key lifecycle
- **Incident response plans** - Compromise response procedures
- **Training documentation** - User education materials

## Monitoring and Maintenance

### Security Monitoring

```bash
# Monitor for key compromise indicators
gpg --check-sigs

# Verify key fingerprints regularly
gpg --fingerprint

# Check for key revocations
gpg --refresh-keys

# Monitor keyserver submissions
gpg --search-keys your@email.com
```

### Regular Security Audits

Monthly security checklist:

- [ ] Review and update threat model
- [ ] Check for software updates
- [ ] Verify backup integrity
- [ ] Review message deletion compliance
- [ ] Audit key trust relationships
- [ ] Test emergency procedures

## Emergency Procedures

### Key Compromise Response

1. **Immediate actions:**

   ```bash
   # Revoke compromised key
   gpg --gen-revoke KEYID > revocation.asc
   gpg --import revocation.asc
   gpg --send-keys KEYID
   ```

2. **Notification procedures:**
   - Notify all correspondents
   - Post revocation to websites/profiles
   - Submit to multiple keyservers

3. **Recovery procedures:**
   - Generate new key pair
   - Re-establish trusted relationships
   - Update all services and contacts

### Data Breach Response

If encrypted messages are exposed:

- Assess what keys could decrypt the data
- Determine if those keys remain secure
- Consider key rotation even if keys weren't compromised
- Notify affected parties as appropriate

## Conclusion

Advanced PGP security requires a comprehensive approach that goes beyond basic encryption. Success depends on:

1. **Understanding your threat model**
2. **Implementing comprehensive OPSEC**
3. **Maintaining security discipline**
4. **Regular security audits and updates**
5. **Balancing security with usability**

Remember that security is a process, not a destination. The techniques in this guide should be adapted to your specific threat model and operational requirements.

> [!WARNING]
> No security measure is perfect. Sophisticated adversaries may have capabilities beyond what these measures can protect against. Always consider using multiple layers of security and alternative communication methods for the most sensitive communications.
