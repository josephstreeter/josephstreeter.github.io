---
title: "Postfix with OpenDKIM - Complete Integration Guide"
description: "Comprehensive guide for implementing DKIM email authentication with Postfix using OpenDKIM for improved email deliverability and security"
author: "Joseph Streeter"
ms.date: 01/13/2026
ms.topic: guide
keywords: postfix, opendkim, dkim, email authentication, mail security, email signing, deliverability
---

This comprehensive guide covers implementing DomainKeys Identified Mail (DKIM) with Postfix using OpenDKIM to cryptographically sign outgoing emails, improving deliverability and preventing email spoofing.

## Overview

### What is DKIM?

DKIM (DomainKeys Identified Mail) is an email authentication method that allows the receiving mail server to verify that an email claiming to come from a specific domain was actually authorized by that domain's administrators. It works by adding a digital signature to the email headers that can be verified using a public key published in DNS.

### Why Use DKIM?

**Security Benefits:**

- Prevents email spoofing and domain impersonation
- Verifies email integrity (message hasn't been modified in transit)
- Protects your domain reputation
- Required for DMARC policy enforcement

**Deliverability Benefits:**

- Improves email deliverability and inbox placement
- Reduces likelihood of emails being marked as spam
- Required by major email providers (Gmail, Yahoo, Microsoft)
- Builds sender reputation over time

### DKIM Authentication Flow

```text
┌─────────────────────────────────────────────────────────────────┐
│                     DKIM Signing Process                        │
└─────────────────────────────────────────────────────────────────┘

Outbound Email Flow:
───────────────────

1. User sends email
        ↓
2. Postfix receives email
        ↓
3. OpenDKIM signs email with private key
   • Hashes email headers and body
   • Encrypts hash with private key
   • Adds DKIM-Signature header
        ↓
4. Email delivered with signature
        ↓
5. Receiving server retrieves public key from DNS
   • Queries selector._domainkey.example.com TXT record
        ↓
6. Receiving server verifies signature
   • Decrypts signature with public key
   • Recalculates hash and compares
        ↓
7. DKIM verification result: pass/fail/neutral
```

### DKIM Components

**OpenDKIM:**

- Milter (Mail Filter) that integrates with Postfix
- Signs outgoing emails with private key
- Can verify incoming DKIM signatures
- Supports multiple domains and selectors

**Key Pair:**

- **Private Key** - Stored securely on mail server, used for signing
- **Public Key** - Published in DNS TXT record, used for verification

**DNS Record:**

- TXT record at `selector._domainkey.yourdomain.com`
- Contains public key and DKIM parameters
- Must be accessible to receiving mail servers

## Prerequisites

Before beginning, ensure you have:

- ✅ Working Postfix installation (see [Postfix Guide](index.md))
- ✅ Root or sudo access to the mail server
- ✅ DNS control for your domain(s)
- ✅ Domain names configured in Postfix
- ✅ Basic understanding of DNS and email systems

## Installation

### Ubuntu/Debian Installation

```bash
# Update package lists
sudo apt update

# Install OpenDKIM and tools
sudo apt install opendkim opendkim-tools -y

# Verify installation
opendkim -V
# Expected output: OpenDKIM Filter v2.x.x

# Check service status
systemctl status opendkim
```

### RHEL/CentOS/Rocky Linux Installation

```bash
# Install EPEL repository (if not already installed)
sudo dnf install epel-release -y

# Install OpenDKIM
sudo dnf install opendkim -y

# Enable and start service
sudo systemctl enable opendkim
sudo systemctl start opendkim

# Verify installation
opendkim -V

# Check service status
systemctl status opendkim
```

### Post-Installation Setup

```bash
# Create directory structure
sudo mkdir -p /etc/opendkim/keys
sudo chmod 750 /etc/opendkim
sudo chmod 700 /etc/opendkim/keys

# Set ownership
sudo chown -R opendkim:opendkim /etc/opendkim

# Verify directories
ls -ld /etc/opendkim /etc/opendkim/keys
```

## Basic Configuration

### Step 1: Configure OpenDKIM

```bash
# Backup original configuration
sudo cp /etc/opendkim.conf /etc/opendkim.conf.backup

# Edit main configuration file
sudo nano /etc/opendkim.conf
```

**Basic OpenDKIM Configuration:**

```bash
# /etc/opendkim.conf

# Logging
Syslog                  yes
SyslogSuccess           yes
LogWhy                  yes

# Common settings
Canonicalization        relaxed/simple
Mode                    sv
SubDomains              no
AutoRestart             yes
AutoRestartRate         10/1h
Background              yes
DNSTimeout              5
SignatureAlgorithm      rsa-sha256

# Milter settings
Socket                  inet:8891@localhost
PidFile                 /var/run/opendkim/opendkim.pid
UserID                  opendkim:opendkim
UMask                   002

# Signing and verification
ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable

# Security
RequireSafeKeys         yes
```

**Configuration Parameters Explained:**

- `Canonicalization relaxed/simple` - How to handle whitespace (header/body)
- `Mode sv` - Sign and verify messages
- `Socket inet:8891@localhost` - Postfix will connect here
- `ExternalIgnoreList` - Hosts to not verify signatures from
- `InternalHosts` - Hosts to sign mail from
- `KeyTable` - Maps key names to key file locations
- `SigningTable` - Maps email addresses/domains to keys

### Step 2: Create Configuration Files

#### TrustedHosts File

```bash
# /etc/opendkim/TrustedHosts
# Hosts that are trusted to send mail as your domains

127.0.0.1
localhost
192.168.1.0/24
::1

# Add your mail server's hostname and IP
mail.example.com
203.0.113.10

# Add any other trusted mail servers
```

#### KeyTable File

The KeyTable maps signing keys to their locations:

```bash
# /etc/opendkim/KeyTable
# Format: keyname domain:selector:keyfile

# Single domain example
default._domainkey.example.com example.com:default:/etc/opendkim/keys/example.com/default.private

# Multiple domains
default._domainkey.example.com example.com:default:/etc/opendkim/keys/example.com/default.private
default._domainkey.example.net example.net:default:/etc/opendkim/keys/example.net/default.private
default._domainkey.example.org example.org:default:/etc/opendkim/keys/example.org/default.private

# Multiple selectors per domain
mail._domainkey.example.com example.com:mail:/etc/opendkim/keys/example.com/mail.private
marketing._domainkey.example.com example.com:marketing:/etc/opendkim/keys/example.com/marketing.private
```

#### SigningTable File

The SigningTable maps email addresses/domains to keys:

```bash
# /etc/opendkim/SigningTable
# Format: pattern keyname

# Sign all mail from example.com with default key
*@example.com default._domainkey.example.com

# Sign mail from multiple domains
*@example.net default._domainkey.example.net
*@example.org default._domainkey.example.org

# Specific user with different key
marketing@example.com marketing._domainkey.example.com

# Wildcard for all subdomains
*@*.example.com default._domainkey.example.com
```

### Step 3: Generate DKIM Keys

#### Generate Keys for a Single Domain

```bash
# Create directory for domain keys
sudo mkdir -p /etc/opendkim/keys/example.com

# Generate 2048-bit RSA key pair
sudo opendkim-genkey -b 2048 -d example.com -D /etc/opendkim/keys/example.com -s default -v

# This creates two files:
# - default.private (private key - keep secure!)
# - default.txt (DNS record to publish)

# Set proper ownership and permissions
sudo chown -R opendkim:opendkim /etc/opendkim/keys/example.com
sudo chmod 600 /etc/opendkim/keys/example.com/default.private
sudo chmod 644 /etc/opendkim/keys/example.com/default.txt

# View the DNS record
sudo cat /etc/opendkim/keys/example.com/default.txt
```

**Expected Output:**

```text
default._domainkey      IN      TXT     ( "v=DKIM1; h=sha256; k=rsa; "
          "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
          "..." )  ; ----- DKIM key default for example.com
```

#### Generate Keys for Multiple Domains

```bash
# Script to generate keys for multiple domains
for domain in example.com example.net example.org; do
    echo "Generating keys for $domain"
    sudo mkdir -p /etc/opendkim/keys/$domain
    sudo opendkim-genkey -b 2048 -d $domain -D /etc/opendkim/keys/$domain -s default -v
    sudo chown -R opendkim:opendkim /etc/opendkim/keys/$domain
    sudo chmod 600 /etc/opendkim/keys/$domain/default.private
    echo "DNS record for $domain:"
    sudo cat /etc/opendkim/keys/$domain/default.txt
    echo ""
done
```

### Step 4: Publish DNS Records

#### Extract and Format DNS Record

```bash
# View the generated DNS record
cat /etc/opendkim/keys/example.com/default.txt

# Extract just the key value (remove quotes and parentheses)
cat /etc/opendkim/keys/example.com/default.txt | grep -v '^;' | tr -d '\n' | sed 's/[[:space:]]//g' | sed 's/.*p=/p=/' | sed 's/".*//'
```

#### Create DNS TXT Record

Add a TXT record to your DNS zone:

**Hostname:** `default._domainkey.example.com`

**Value:**

```text
v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
```

**Important:**

- Remove all quotes, parentheses, and extra whitespace
- Some DNS providers require the value on a single line
- Others split long values automatically

**Common DNS Provider Examples:**

**Cloudflare:**

```text
Type: TXT
Name: default._domainkey
Content: v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
TTL: Auto
```

**BIND (Zone File):**

```text
default._domainkey.example.com. IN TXT "v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
```

**AWS Route 53:**

```text
Name: default._domainkey.example.com
Type: TXT
Value: "v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
TTL: 300
```

#### Verify DNS Record

```bash
# Wait for DNS propagation (5-60 minutes typically)
# Verify the record is published

# Using dig
dig TXT default._domainkey.example.com +short

# Using nslookup
nslookup -type=TXT default._domainkey.example.com

# Using host
host -t TXT default._domainkey.example.com

# Expected output should show your public key:
# "v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
```

### Step 5: Configure Postfix Integration

```bash
# Edit Postfix main configuration
sudo nano /etc/postfix/main.cf
```

**Add Milter Configuration:**

```bash
# /etc/postfix/main.cf
# Add to existing configuration

# OpenDKIM milter
milter_default_action = accept
milter_protocol = 6
smtpd_milters = inet:127.0.0.1:8891
non_smtpd_milters = $smtpd_milters

# Optional: timeout settings
milter_connect_timeout = 30s
milter_command_timeout = 30s
```

**Configuration Parameters:**

- `milter_default_action = accept` - Accept mail if milter fails (prevents mail loss)
- `milter_protocol = 6` - Milter protocol version
- `smtpd_milters` - Milters for SMTP-received mail
- `non_smtpd_milters` - Milters for locally-generated mail

### Step 6: Restart Services

```bash
# Validate OpenDKIM configuration
sudo opendkim -n

# Should output: opendkim: /etc/opendkim.conf: No such key or value: ...
# If no errors, configuration is valid

# Restart OpenDKIM
sudo systemctl restart opendkim

# Check OpenDKIM status
sudo systemctl status opendkim

# Restart Postfix
sudo postfix check
sudo systemctl restart postfix

# Check Postfix status
sudo systemctl status postfix

# Verify OpenDKIM is listening
ss -tlnp | grep 8891
# Should show opendkim listening on port 8891
```

## Testing DKIM Signing

### Test 1: Send Test Email

```bash
# Send test email
echo "This is a DKIM test email" | mail -s "DKIM Test" user@gmail.com

# Or use swaks (Swiss Army Knife for SMTP)
sudo apt install swaks -y
swaks --to user@gmail.com --from test@example.com --server localhost --body "DKIM test"
```

### Test 2: Check Email Headers

After sending, check the received email headers for DKIM signature:

```text
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/simple; d=example.com;
    s=default; t=1705176123;
    bh=frcCV1k9oG9oKj3dpUqdJg1PxRT2RSN/XKdLCPjaYaY=;
    h=From:To:Subject:Date;
    b=abc123...
```

**Key Fields:**

- `d=example.com` - Domain that signed
- `s=default` - Selector used
- `a=rsa-sha256` - Algorithm
- `b=...` - The actual signature

### Test 3: Verify with Online Tools

Send test emails to these verification services:

**1. Port25 Verifier:**

```bash
echo "DKIM test" | mail -s "Test" check-auth@verifier.port25.com
```

You'll receive an automated reply showing:

- SPF result
- DKIM result
- DMARC result

**2. Mail-Tester:**

- Send email to the address shown at <https://www.mail-tester.com>
- View comprehensive report including DKIM status

**3. Gmail:**

- Send to your Gmail account
- View original message (Show original)
- Look for: `dkim=pass header.d=example.com`

### Test 4: Check Logs

```bash
# Check OpenDKIM logs
sudo journalctl -u opendkim -f

# Look for:
# - "DKIM-Signature header added" (success)
# - "key not found" (configuration error)
# - "private key not found" (file permission issue)

# Check Postfix logs
sudo tail -f /var/log/mail.log | grep -i dkim

# Successful signing shows:
# opendkim[12345]: DKIM-Signature header added (s=default, d=example.com)
```

### Test 5: Command-Line Verification

```bash
# Save a test email with DKIM signature to file
cat > /tmp/test-email.txt << 'EOF'
From: test@example.com
To: recipient@example.com
Subject: Test
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/simple; d=example.com; s=default; ...

Test message body
EOF

# Verify the signature
opendkim-testkey -d example.com -s default -vvv
# Should output: key OK

# Test with actual key file
opendkim-testkey -d example.com -s default -k /etc/opendkim/keys/example.com/default.private
```

## Advanced Configuration

### Multiple Domains

For hosting multiple domains with separate DKIM keys:

```bash
# Directory structure
/etc/opendkim/keys/
├── example.com/
│   ├── default.private
│   └── default.txt
├── example.net/
│   ├── default.private
│   └── default.txt
└── example.org/
    ├── default.private
    └── default.txt

# /etc/opendkim/KeyTable
default._domainkey.example.com example.com:default:/etc/opendkim/keys/example.com/default.private
default._domainkey.example.net example.net:default:/etc/opendkim/keys/example.net/default.private
default._domainkey.example.org example.org:default:/etc/opendkim/keys/example.org/default.private

# /etc/opendkim/SigningTable
*@example.com default._domainkey.example.com
*@example.net default._domainkey.example.net
*@example.org default._domainkey.example.org
```

### Subdomain Signing

Sign mail from subdomains with parent domain key:

```bash
# /etc/opendkim/SigningTable
# Sign all subdomains with main domain key
*@*.example.com default._domainkey.example.com
*@example.com default._domainkey.example.com

# Or use subdomain-specific keys
*@mail.example.com mail._domainkey.example.com
*@marketing.example.com marketing._domainkey.example.com
```

### Selector Rotation Strategy

Rotate selectors periodically for security:

```bash
# Generate new key with different selector
sudo mkdir -p /etc/opendkim/keys/example.com
sudo opendkim-genkey -b 2048 -d example.com -D /etc/opendkim/keys/example.com -s 202601 -v

# Add to KeyTable
# /etc/opendkim/KeyTable
202601._domainkey.example.com example.com:202601:/etc/opendkim/keys/example.com/202601.private
default._domainkey.example.com example.com:default:/etc/opendkim/keys/example.com/default.private

# Publish new DNS record
default._domainkey.example.com IN TXT "v=DKIM1; ... (old key)"
202601._domainkey.example.com IN TXT "v=DKIM1; ... (new key)"

# Update SigningTable to use new selector
# /etc/opendkim/SigningTable
*@example.com 202601._domainkey.example.com

# Wait 48 hours for DNS propagation and email in transit
# Then remove old DNS record and old key files
```

### Per-User or Per-Department Signing

```bash
# /etc/opendkim/SigningTable
# Different keys for different purposes

# Marketing emails
*@marketing.example.com marketing._domainkey.example.com

# Transactional emails
noreply@example.com noreply._domainkey.example.com

# Sales department
*sales*@example.com sales._domainkey.example.com

# Default for everything else
*@example.com default._domainkey.example.com
```

### Signing and Verification Mode

```bash
# /etc/opendkim.conf

# Mode options:
# s = sign only
# v = verify only
# sv = sign and verify (recommended)

Mode sv

# Verification settings
On-BadSignature reject
On-DNSError tempfail
On-InternalError tempfail
On-NoSignature accept
On-Security reject

# Log verification results
SoftwareHeader yes
```

### Large Key Size (4096-bit)

For enhanced security, use larger keys:

```bash
# Generate 4096-bit key
sudo opendkim-genkey -b 4096 -d example.com -D /etc/opendkim/keys/example.com -s default -v

# Note: 4096-bit keys create longer DNS records
# Some DNS providers may have issues with very long TXT records
# Split across multiple strings if needed:
default._domainkey IN TXT (
    "v=DKIM1; h=sha256; k=rsa; "
    "p=MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA..."
    "..."
)
```

## Security Best Practices

### Key Security

```bash
# Proper file permissions
sudo chmod 600 /etc/opendkim/keys/*/default.private
sudo chmod 644 /etc/opendkim/keys/*/default.txt
sudo chown -R opendkim:opendkim /etc/opendkim/keys

# Verify permissions
find /etc/opendkim/keys -type f -name "*.private" -ls
# Should show: -rw------- opendkim opendkim

# Restrict directory access
sudo chmod 750 /etc/opendkim
sudo chmod 700 /etc/opendkim/keys

# Never commit private keys to version control!
# Add to .gitignore if using git
echo "*.private" >> /etc/opendkim/.gitignore
```

### Key Rotation

```bash
# Rotate keys every 6-12 months
# Recommended rotation schedule:

# Month 1: Generate new key with new selector
# Month 1: Publish new DNS record alongside old
# Month 1: Start signing with new key
# Month 2: Remove old DNS record (after propagation)
# Month 2: Remove old private key

# Automation script
#!/bin/bash
# /usr/local/bin/rotate-dkim-key.sh

DOMAIN="example.com"
SELECTOR="$(date +%Y%m)"
KEYDIR="/etc/opendkim/keys/$DOMAIN"

# Generate new key
opendkim-genkey -b 2048 -d $DOMAIN -D $KEYDIR -s $SELECTOR -v
chown opendkim:opendkim $KEYDIR/$SELECTOR.private
chmod 600 $KEYDIR/$SELECTOR.private

echo "New key generated with selector: $SELECTOR"
echo "DNS record to publish:"
cat $KEYDIR/$SELECTOR.txt
echo ""
echo "After DNS propagation, update:"
echo "1. /etc/opendkim/KeyTable"
echo "2. /etc/opendkim/SigningTable"
echo "3. Restart OpenDKIM"
```

### Backup Strategy

```bash
# Backup script
#!/bin/bash
# /usr/local/bin/backup-dkim.sh

BACKUP_DIR="/backup/opendkim"
DATE=$(date +%Y%m%d)

mkdir -p $BACKUP_DIR

# Backup configuration
tar -czf $BACKUP_DIR/opendkim-config-$DATE.tar.gz /etc/opendkim/

# Backup keys securely
tar -czf $BACKUP_DIR/opendkim-keys-$DATE.tar.gz /etc/opendkim/keys/
chmod 600 $BACKUP_DIR/opendkim-keys-$DATE.tar.gz

# Keep last 30 days
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $(date)"
```

### Monitoring

```bash
# Monitor OpenDKIM status
#!/bin/bash
# /usr/local/bin/check-dkim-health.sh

echo "=== OpenDKIM Health Check ==="

# Check service
if systemctl is-active --quiet opendkim; then
    echo "✓ OpenDKIM service: Running"
else
    echo "✗ OpenDKIM service: Stopped"
    exit 1
fi

# Check socket
if ss -tlnp | grep -q 8891; then
    echo "✓ OpenDKIM socket: Listening on port 8891"
else
    echo "✗ OpenDKIM socket: Not listening"
fi

# Check DNS records
for domain in example.com example.net; do
    if dig TXT default._domainkey.$domain +short | grep -q "v=DKIM1"; then
        echo "✓ DNS record for $domain: Published"
    else
        echo "⚠ DNS record for $domain: Missing or invalid"
    fi
done

# Check recent signatures
RECENT_SIGS=$(journalctl -u opendkim --since "1 hour ago" | grep -c "DKIM-Signature header added")
echo "ℹ DKIM signatures in last hour: $RECENT_SIGS"

# Check for errors
ERROR_COUNT=$(journalctl -u opendkim --since "1 hour ago" | grep -c "error")
if [ $ERROR_COUNT -eq 0 ]; then
    echo "✓ Recent errors: None"
else
    echo "⚠ Recent errors: $ERROR_COUNT"
fi

echo ""
echo "Health check completed: $(date)"
```

## Troubleshooting

### Common Issues

#### Issue 1: DKIM Signature Not Added

**Symptoms:**

- No DKIM-Signature header in outgoing emails
- Logs show: "key not found"

**Diagnosis:**

```bash
# Check if OpenDKIM is running
systemctl status opendkim

# Check socket connection
ss -tlnp | grep 8891

# Check Postfix is connecting to milter
grep milter /etc/postfix/main.cf

# Test configuration
opendkim -n

# Check logs
journalctl -u opendkim -n 50
```

**Solutions:**

```bash
# Verify KeyTable and SigningTable match
cat /etc/opendkim/KeyTable
cat /etc/opendkim/SigningTable

# Ensure key file exists and is readable
ls -l /etc/opendkim/keys/example.com/default.private

# Fix permissions
sudo chown opendkim:opendkim /etc/opendkim/keys/example.com/default.private
sudo chmod 600 /etc/opendkim/keys/example.com/default.private

# Restart services
sudo systemctl restart opendkim postfix
```

#### Issue 2: DKIM Verification Fails

**Symptoms:**

- Receiving servers show `dkim=fail`
- Emails marked as spam

**Diagnosis:**

```bash
# Verify DNS record is published
dig TXT default._domainkey.example.com +short

# Test key
opendkim-testkey -d example.com -s default -vvv

# Check if key matches DNS record
cat /etc/opendkim/keys/example.com/default.txt
```

**Solutions:**

```bash
# Common causes:

# 1. DNS record not published or incorrect
# - Re-publish the correct record from default.txt

# 2. DNS record contains extra characters
# - Remove quotes, spaces, parentheses from DNS value

# 3. Key mismatch (private key doesn't match public key)
# - Regenerate keys and update DNS

# 4. Selector mismatch
# - Ensure DNS record matches selector in SigningTable

# 5. Email modified in transit
# - Check for content filters modifying messages
# - Use relaxed canonicalization
```

#### Issue 3: Permission Denied

**Symptoms:**

- OpenDKIM fails to start
- Logs show: "permission denied" or "cannot open key file"

**Solutions:**

```bash
# Check ownership
ls -lR /etc/opendkim/keys/

# Fix ownership recursively
sudo chown -R opendkim:opendkim /etc/opendkim/

# Fix permissions
find /etc/opendkim/keys -type f -name "*.private" -exec chmod 600 {} \;
find /etc/opendkim/keys -type d -exec chmod 700 {} \;

# Verify SELinux context (RHEL/CentOS)
ls -Z /etc/opendkim/keys/
sudo restorecon -Rv /etc/opendkim/

# Restart service
sudo systemctl restart opendkim
```

#### Issue 4: Socket Connection Failed

**Symptoms:**

- Postfix logs show: "milter connect failed"
- OpenDKIM logs show: "socket bind failed"

**Solutions:**

```bash
# Check if socket is in use
ss -tlnp | grep 8891

# Check OpenDKIM socket configuration
grep Socket /etc/opendkim.conf
# Should be: Socket inet:8891@localhost

# Check Postfix milter configuration
postconf smtpd_milters
# Should include: inet:127.0.0.1:8891

# Check firewall (if using unix socket)
sudo systemctl status opendkim
# Verify socket path and permissions

# Test connection
telnet localhost 8891

# Restart services in order
sudo systemctl restart opendkim
sleep 2
sudo systemctl restart postfix
```

#### Issue 5: DNS Record Too Long

**Symptoms:**

- DNS provider rejects TXT record (too long)
- DKIM verification fails due to incomplete key

**Solutions:**

```bash
# Option 1: Use 2048-bit key instead of 4096-bit
sudo opendkim-genkey -b 2048 -d example.com -D /etc/opendkim/keys/example.com -s default -v

# Option 2: Split DNS record into multiple strings
default._domainkey IN TXT (
    "v=DKIM1; h=sha256; k=rsa; "
    "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
    "..."
)

# Option 3: Use DNS provider that supports long TXT records
# Cloudflare, AWS Route 53, and most modern DNS providers support this

# Verify split record works
dig TXT default._domainkey.example.com +short
```

### Debug Mode

```bash
# Enable verbose logging
# /etc/opendkim.conf
LogWhy yes
Syslog yes
SyslogSuccess yes

# Restart OpenDKIM
sudo systemctl restart opendkim

# Watch logs in real-time
sudo journalctl -u opendkim -f

# Send test email
echo "Debug test" | mail -s "DKIM Debug" test@example.com

# Review detailed logs
sudo journalctl -u opendkim --since "5 minutes ago" | less
```

### Verification Commands

```bash
# Test DKIM key from DNS
opendkim-testkey -d example.com -s default -vvv

# Expected output for valid key:
# opendkim-testkey: using default configfile /etc/opendkim.conf
# opendkim-testkey: checking key 'default._domainkey.example.com'
# opendkim-testkey: key OK

# Test with specific nameserver
opendkim-testkey -d example.com -s default -n 8.8.8.8 -vvv

# Verify DKIM signature manually
# Save email to file and run:
opendkim-testmsg -d /path/to/email.txt

# Check configuration syntax
sudo opendkim -n

# Dump current configuration
sudo opendkim -T
```

## Integration with DMARC

DKIM is a prerequisite for DMARC. For comprehensive email authentication:

```bash
# Ensure DKIM is working
dig TXT default._domainkey.example.com +short

# Add DMARC policy
# DNS TXT record for _dmarc.example.com:
v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com; ruf=mailto:dmarc@example.com; fo=1; adkim=r; aspf=r; pct=100

# Test complete authentication
echo "Test" | mail -s "Auth Test" check-auth@verifier.port25.com
```

For complete DMARC implementation, see [Email Authentication Guide](../smtp/authentication.md#dmarc-domain-based-message-authentication-reporting--conformance).

## Monitoring and Maintenance

### Regular Checks

```bash
# Daily monitoring script
#!/bin/bash
# /usr/local/bin/dkim-daily-check.sh

# Check service health
if ! systemctl is-active --quiet opendkim; then
    echo "ALERT: OpenDKIM service is down" | mail -s "DKIM Alert" admin@example.com
fi

# Check signing rate
SIGS=$(journalctl -u opendkim --since "24 hours ago" | grep -c "DKIM-Signature header added")
echo "DKIM signatures in last 24 hours: $SIGS"

# Check for errors
ERRORS=$(journalctl -u opendkim --since "24 hours ago" | grep -c "error")
if [ $ERRORS -gt 0 ]; then
    echo "WARNING: $ERRORS DKIM errors in last 24 hours"
fi

# Check DNS records
for domain in example.com example.net; do
    if ! dig TXT default._domainkey.$domain +short | grep -q "v=DKIM1"; then
        echo "ALERT: DKIM DNS record missing for $domain" | mail -s "DKIM DNS Alert" admin@example.com
    fi
done
```

### Performance Metrics

```bash
# Monitor OpenDKIM performance
# Check signing speed
journalctl -u opendkim --since "1 hour ago" | grep "DKIM-Signature header added" | wc -l

# Check memory usage
ps aux | grep opendkim

# Check file descriptors
lsof -p $(pgrep opendkim) | wc -l

# Monitor socket connections
ss -tn | grep :8891 | wc -l
```

## Quick Reference

### Essential Commands

```bash
# Service Management
systemctl status opendkim          # Check status
systemctl start opendkim           # Start service
systemctl stop opendkim            # Stop service
systemctl restart opendkim         # Restart service
systemctl reload opendkim          # Reload configuration

# Key Generation
opendkim-genkey -b 2048 -d example.com -D /path -s selector -v

# Testing
opendkim-testkey -d example.com -s default -vvv    # Test DNS key
opendkim-testmsg -d /path/to/email.txt             # Test signature
opendkim -n                                         # Test config syntax

# Verification
dig TXT default._domainkey.example.com +short      # Check DNS record
journalctl -u opendkim -f                           # Watch logs
ss -tlnp | grep 8891                                # Check socket
```

### Configuration File Locations

| File | Purpose |
| ---- | ------- |
| `/etc/opendkim.conf` | Main OpenDKIM configuration |
| `/etc/opendkim/TrustedHosts` | Trusted hosts list |
| `/etc/opendkim/KeyTable` | Key to file mapping |
| `/etc/opendkim/SigningTable` | Email to key mapping |
| `/etc/opendkim/keys/` | Directory containing private keys |
| `/etc/postfix/main.cf` | Postfix milter configuration |

### DNS Record Format

```text
Hostname: default._domainkey.example.com
Type: TXT
Value: v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
TTL: 300 (or default)
```

### Troubleshooting Checklist

- [ ] OpenDKIM service is running
- [ ] OpenDKIM is listening on port 8891
- [ ] Postfix milter configuration is correct
- [ ] KeyTable and SigningTable are properly configured
- [ ] Private key files exist and have correct permissions (600)
- [ ] Private key files are owned by opendkim user
- [ ] DNS TXT record is published and propagated
- [ ] DNS record contains correct public key
- [ ] No extra characters in DNS record
- [ ] Selector in KeyTable matches DNS record
- [ ] Test email shows DKIM-Signature header
- [ ] DKIM verification passes (check online tools)

## Related Documentation

- [Postfix Mail Server Guide](index.md) - Complete Postfix configuration
- [Email Authentication (SPF, DKIM, DMARC)](../smtp/authentication.md) - Comprehensive authentication guide
- [SMTP Protocol Overview](../smtp/index.md) - SMTP fundamentals

## External Resources

### Official Documentation

- [OpenDKIM Documentation](http://www.opendkim.org/docs.html)
- [OpenDKIM Configuration](http://www.opendkim.org/opendkim.conf.5.html)
- [DKIM Specification (RFC 6376)](https://www.rfc-editor.org/rfc/rfc6376.html)

### Tools and Validators

- [MXToolbox DKIM Checker](https://mxtoolbox.com/dkim.aspx)
- [Port25 Email Verifier](https://www.port25.com/dkim-wizard/)
- [Mail-Tester](https://www.mail-tester.com/)
- [DMARC Analyzer](https://www.dmarcanalyzer.com/dkim-check/)

### Community Resources

- [OpenDKIM Mailing List](http://www.opendkim.org/lists.html)
- [Postfix Users Mailing List](http://www.postfix.org/lists.html)
- [Stack Overflow - DKIM](https://stackoverflow.com/questions/tagged/dkim)

---

**Last Updated:** January 13, 2026

> This comprehensive guide covers OpenDKIM integration with Postfix for production email authentication. Properly configured DKIM significantly improves email deliverability and protects your domain reputation.
