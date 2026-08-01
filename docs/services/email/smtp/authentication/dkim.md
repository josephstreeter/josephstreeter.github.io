---
title: "DKIM (DomainKeys Identified Mail)"
description: "DKIM signature components, key generation, DNS records, signing configuration, and selector strategy"
author: "Joseph Streeter"
tags: ["email", "authentication", "dkim", "signing", "cryptography", "dns"]
category: "services"
last_updated: "2026-08-01"
---
## DKIM (DomainKeys Identified Mail)

### DKIM Overview

DKIM, defined in RFC 6376, uses cryptographic signatures to verify that an email message hasn't been tampered with during transit and confirms the sender's identity. Unlike SPF which validates the sending server, DKIM validates the message itself, making it more resistant to email forwarding issues.

### How DKIM Works

DKIM adds a digital signature to the email headers:

1. **Sending server** prepares email message with all headers
2. **DKIM signing** server calculates cryptographic hash of specified headers and body
3. **Private key** signs the hash, creating DKIM-Signature header
4. **Signature added** to message headers before transmission
5. **Message sent** through internet with DKIM-Signature intact
6. **Receiving server** extracts DKIM-Signature header
7. **Public key retrieved** from sender's DNS records
8. **Signature verified** by recalculating hash and comparing with signature
9. **Result determined** - pass, fail, neutral, or temperror
10. **Action taken** based on result and DMARC policy

DKIM signatures survive email forwarding since they travel with the message, unlike SPF which checks the immediate sending server.

### DKIM Signature Components

A DKIM signature appears in the email headers as a structured field:

```text
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;
  d=example.com; s=default; t=1673543210;
  h=from:to:subject:date:message-id;
  bh=2jUSOH9NhtVGCQWNr9BrIAPreKQjO6Sn7XIkfJVOzv8=;
  b=dzdVyOfAKCdLXdJOc9G2q8LoXSlEniSb...
```

#### DKIM Signature Fields

| Field | Description | Example |
| --- | --- | --- |
| `v` | DKIM version (always 1) | `v=1` |
| `a` | Signing algorithm | `a=rsa-sha256` |
| `c` | Canonicalization algorithm | `c=relaxed/relaxed` |
| `d` | Signing domain | `d=example.com` |
| `s` | Selector (key identifier) | `s=default` |
| `t` | Signature timestamp | `t=1673543210` |
| `h` | Signed headers | `h=from:to:subject:date` |
| `bh` | Body hash | `bh=2jUSOH9NhtVGCQWNr9...` |
| `b` | Signature of headers | `b=dzdVyOfAKCdLXdJOc9...` |
| `i` | Agent or User Identifier | `i=@example.com` |
| `l` | Body length count | `l=1234` |
| `q` | Query method | `q=dns/txt` |
| `x` | Signature expiration | `x=1673629610` |

#### Canonicalization Algorithms

Canonicalization determines how the email is normalized before hashing:

| Algorithm | Description | Use Case |
| --- | --- | --- |
| `simple/simple` | No modification allowed | Strict integrity checking |
| `simple/relaxed` | Simple headers, relaxed body | Common compromise |
| `relaxed/simple` | Relaxed headers, simple body | Rare configuration |
| `relaxed/relaxed` | Whitespace changes allowed | Most common, handles forwarding better |

**Simple Canonicalization:**

- Exact character-by-character match required
- Whitespace preserved exactly
- May break if email passes through servers that modify formatting

**Relaxed Canonicalization:**

- Allows whitespace changes
- Lowercases header field names
- Compresses whitespace in header field values
- Removes trailing whitespace from body lines
- More resilient to email system modifications

### DKIM Key Generation

#### Generate RSA Key Pair

**Using OpenSSL (Linux/Mac):**

```bash
# Generate 2048-bit private key
openssl genrsa -out dkim_private.pem 2048

# Extract public key
openssl rsa -in dkim_private.pem -pubout -out dkim_public.pem

# Display public key for DNS (remove headers and newlines)
awk '/^[^-]/ {printf "%s", $0}' dkim_public.pem
```

**Using PowerShell (Windows):**

```powershell
# Generate 2048-bit RSA key pair
$Rsa = [System.Security.Cryptography.RSA]::Create(2048)

# Export private key
$PrivateKey = $Rsa.ExportRSAPrivateKey()
[System.IO.File]::WriteAllBytes("dkim_private.der", $PrivateKey)

# Export public key
$PublicKey = $Rsa.ExportSubjectPublicKeyInfo()
$PublicKeyBase64 = [Convert]::ToBase64String($PublicKey)
$PublicKeyBase64 | Out-File -FilePath "dkim_public.txt"

Write-Host "Public key for DNS:"
Write-Host $PublicKeyBase64
```

**Using opendkim-genkey (Linux):**

```bash
# Generate key with selector "default" for domain "example.com"
opendkim-genkey -t -s default -d example.com

# Creates two files:
# default.private - Private key file
# default.txt - DNS record ready to publish

# View the DNS record
cat default.txt
```

#### Key Size Recommendations

| Key Size | Security Level | Compatibility | Recommendation |
| --- | --- | --- | --- |
| 1024-bit | Weak | Universal | ❌ Deprecated, don't use |
| 2048-bit | Strong | Excellent | ✅ Recommended standard |
| 4096-bit | Very Strong | Some limitations | ⚠️ May exceed DNS limits |

**Use 2048-bit keys** for the best balance of security and compatibility.

### DKIM DNS Records

#### DNS Record Format

DKIM public keys are published as TXT records at:

```text
[selector]._domainkey.[domain]
```

**Basic format:**

```text
default._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC..."
```

#### DNS Record Fields

| Field | Description | Required | Example |
| --- | --- | --- | --- |
| `v` | DKIM version | Yes | `v=DKIM1` |
| `k` | Key type | Optional | `k=rsa` (default) |
| `p` | Public key (base64) | Yes | `p=MIGfMA0GCSqG...` |
| `t` | Flags | Optional | `t=s` (strict mode) |
| `s` | Service type | Optional | `s=email` (default) |
| `n` | Notes | Optional | `n=DKIM key for example.com` |
| `h` | Acceptable hash algorithms | Optional | `h=sha256` |

#### Complete DNS Record Examples

**Basic DKIM record:**

```text
default._domainkey.example.com. 3600 IN TXT (
  "v=DKIM1; k=rsa; "
  "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC5N3lnvvrYgPCRSoqn+awTpkNkHI7ozzI4zQPzOHm8+hjc5c5qPqGh7FRvLFr8KX6mHmKr9StP0k+HpZhJLbvmPOi62mJ9yHKLvPQP4XPZC7DqLj0WMBEbR3U+EWiEJqQUL/fvJN6h5qJxlYuJR8LkXKOlqKlWVJpnVYPZJCkF1QIDAQAB"
)
```

**DKIM record with testing mode:**

```text
default._domainkey.example.com. IN TXT (
  "v=DKIM1; k=rsa; t=y; "
  "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC5N3lnvvrYgPCRSoqn+awTpkNkHI7ozzI4zQPzOHm8+hjc5c5qPqGh7FRvLFr8KX6mHmKr9StP0k+HpZhJLbvmPOi62mJ9yHKLvPQP4XPZC7DqLj0WMBEbR3U+EWiEJqQUL/fvJN6h5qJxlYuJR8LkXKOlqKlWVJpnVYPZJCkF1QIDAQAB"
)
```

The `t=y` flag indicates testing mode - signatures will be verified but not enforced.

**DKIM record with strict domain matching:**

```text
default._domainkey.example.com. IN TXT (
  "v=DKIM1; k=rsa; t=s; "
  "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC5N3lnvvrYgPCRSoqn+awTpkNkHI7ozzI4zQPzOHm8+hjc5c5qPqGh7FRvLFr8KX6mHmKr9StP0k+HpZhJLbvmPOi62mJ9yHKLvPQP4XPZC7DqLj0WMBEbR3U+EWiEJqQUL/fvJN6h5qJxlYuJR8LkXKOlqKlWVJpnVYPZJCkF1QIDAQAB"
)
```

The `t=s` flag restricts signing to exact domain match (no subdomains).

**DKIM record with notes:**

```text
default._domainkey.example.com. IN TXT (
  "v=DKIM1; k=rsa; "
  "n=DKIM key for example.com mail servers; "
  "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC5N3lnvvrYgPCRSoqn+awTpkNkHI7ozzI4zQPzOHm8+hjc5c5qPqGh7FRvLFr8KX6mHmKr9StP0k+HpZhJLbvmPOi62mJ9yHKLvPQP4XPZC7DqLj0WMBEbR3U+EWiEJqQUL/fvJN6h5qJxlYuJR8LkXKOlqKlWVJpnVYPZJCkF1QIDAQAB"
)
```

#### Multiple DKIM Selectors

Using multiple selectors enables key rotation and different keys for different purposes:

```text
# Default key for general email
default._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqG..."

# Marketing campaigns
marketing._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIIBIjANBgkq..."

# Transactional email
transactional._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCS..."

# Key rotation - new key while old still valid
default2024._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIIBIjANBgk..."
```

### DKIM Signing Configuration

#### Postfix with OpenDKIM

**1. Install OpenDKIM:**

```bash
# Debian/Ubuntu
sudo apt-get install opendkim opendkim-tools

# RHEL/CentOS
sudo yum install opendkim opendkim-tools
```

**2. Generate keys:**

```bash
sudo mkdir -p /etc/opendkim/keys/example.com
cd /etc/opendkim/keys/example.com
sudo opendkim-genkey -t -s default -d example.com
sudo chown opendkim:opendkim default.private
sudo chmod 600 default.private
```

**3. Configure OpenDKIM (`/etc/opendkim.conf`):**

```ini
# Basic settings
Mode                    sv
Canonicalization        relaxed/relaxed
Socket                  inet:8891@localhost

# Signing domain
Domain                  example.com
Selector                default
KeyFile                 /etc/opendkim/keys/example.com/default.private

# Security
PidFile                 /var/run/opendkim/opendkim.pid
UserID                  opendkim:opendkim
UMask                   002

# Signing options
SignatureAlgorithm      rsa-sha256
SignHeaders             From,To,Subject,Date,Message-ID

# Verification
ExternalIgnoreList      /etc/opendkim/TrustedHosts
InternalHosts           /etc/opendkim/TrustedHosts
```

**4. Configure trusted hosts (`/etc/opendkim/TrustedHosts`):**

```text
127.0.0.1
localhost
192.168.1.0/24
example.com
*.example.com
```

**5. Configure Postfix (`/etc/postfix/main.cf`):**

```ini
# DKIM via OpenDKIM
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
milter_default_action = accept
milter_protocol = 6
```

**6. Restart services:**

```bash
sudo systemctl restart opendkim
sudo systemctl restart postfix
```

#### Microsoft Exchange (Office 365)

**Enable DKIM for Exchange Online:**

```powershell
# Connect to Exchange Online
Connect-ExchangeOnline

# Create DKIM signing configuration
New-DkimSigningConfig -DomainName "example.com" -Enabled $true

# Enable DKIM signing
Set-DkimSigningConfig -Identity "example.com" -Enabled $true

# View DKIM configuration
Get-DkimSigningConfig -Identity "example.com" | Format-List
```

**Get DNS records to publish:**

```powershell
Get-DkimSigningConfig -Identity "example.com" | Select-Object Selector1CNAME, Selector2CNAME
```

**Publish the CNAMEs:**

```text
selector1._domainkey.example.com CNAME selector1-example-com._domainkey.contoso.onmicrosoft.com
selector2._domainkey.example.com CNAME selector2-example-com._domainkey.contoso.onmicrosoft.com
```

#### Google Workspace

**Enable DKIM in Google Admin Console:**

1. Navigate to **Apps** → **Google Workspace** → **Gmail**
2. Click **Authenticate email**
3. Select your domain
4. Click **Generate new record**
5. Choose **2048-bit key** (recommended)
6. Copy the generated DNS TXT record

**DNS record example from Google:**

```text
google._domainkey.example.com. IN TXT (
  "v=DKIM1; k=rsa; "
  "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAraC3pqvqTkAfXhUn7Kn3JUNMwDkZ+v2X9z8..."
)
```

**Turn on DKIM signing:**

1. In Admin Console, click **Start Authentication**
2. Wait 24-48 hours for DNS propagation
3. Verify with test email

#### SendGrid Configuration

**Configure DKIM via SendGrid UI:**

1. Go to **Settings** → **Sender Authentication**
2. Click **Authenticate Your Domain**
3. Enter your domain name
4. Choose **DNS host** provider
5. Follow wizard to get DNS records

**Example SendGrid DKIM records:**

```text
s1._domainkey.example.com. CNAME s1.domainkey.u12345.wl.sendgrid.net
s2._domainkey.example.com. CNAME s2.domainkey.u12345.wl.sendgrid.net
```

**Verify DKIM setup:**

```bash
dig +short CNAME s1._domainkey.example.com
dig +short TXT s1.domainkey.u12345.wl.sendgrid.net
```

### DKIM Selector Strategy

#### What Are Selectors?

Selectors allow multiple DKIM keys for a single domain. They appear in the DNS record name:

```text
[selector]._domainkey.[domain]
```

Common selector names:

- `default` - General purpose key
- `google` - Google Workspace key
- `k1`, `k2`, `k3` - Rotation series
- `2024-01` - Date-based rotation
- `marketing` - Purpose-specific key
- `server1` - Server-specific key

#### Selector Rotation Strategy

**Time-based rotation (recommended):**

```text
# January 2024
2024-01._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqG..."

# July 2024 - generate new key, both valid
2024-07._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIIBIjANBgkq..."

# Configuration uses new selector
# Old key remains valid for 90 days for in-flight emails
```

**Rotation procedure:**

1. **Week 1:** Generate new key with new selector
2. **Week 2:** Publish new DNS record alongside old
3. **Week 3:** Update mail server to use new selector
4. **Week 4-16:** Monitor, keep old key published
5. **Week 17+:** Remove old DNS record

**Sequential rotation:**

```text
k1._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=..." # Current
k2._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=..." # Next
k3._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=..." # Future
```

Rotate through k1 → k2 → k3 → k1 on annual schedule.

#### Multi-Selector Architecture

**Purpose-based selectors:**

```text
corporate._domainkey.example.com.     # Corporate email
marketing._domainkey.example.com.     # Marketing campaigns
support._domainkey.example.com.       # Help desk system
api._domainkey.example.com.           # Application emails
```

**Benefits:**

- Isolate key compromise to specific service
- Different key sizes for different needs
- Easier troubleshooting
- Granular key rotation

## Related Topics

- [Email Authentication Overview](index.md)
- [SPF (Sender Policy Framework)](spf.md)
- [SPF Subdomain Protection and Attack Vectors](spf-security.md)
- [SPF Testing and Validation](spf-testing.md)
- [SPF Troubleshooting and Migration](spf-troubleshooting.md)
- [DKIM (DomainKeys Identified Mail)](dkim.md)
- [DKIM Testing and Troubleshooting](dkim-testing.md)
- [DKIM Key Rotation and Operations](dkim-operations.md)
- [DMARC (Domain-based Message Authentication)](dmarc.md)
- [DMARC Reports and Analysis](dmarc-reports.md)
- [DMARC Policy Rollout](dmarc-rollout.md)
- [DMARC Testing and Troubleshooting](dmarc-testing.md)
