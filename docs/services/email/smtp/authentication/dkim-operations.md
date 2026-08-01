---
title: "DKIM Key Rotation and Operations"
description: "Rotating DKIM keys safely, operational best practices, migration checklist, and quick reference"
author: "Joseph Streeter"
tags: ["email", "authentication", "dkim", "key rotation", "operations"]
category: "services"
last_updated: "2026-08-01"
---
## DKIM Operations

DKIM is not set-and-forget. Keys need rotating, and the rotation has to overlap so
in-flight mail still verifies.

### DKIM Key Rotation

#### Why Rotate Keys

- **Security hygiene** - Limit exposure if key compromised
- **Compliance requirements** - Many standards require periodic rotation
- **Cryptographic best practice** - Reduces risk of successful attacks
- **Incident response** - Allows rapid key replacement

**Recommended rotation frequency:** Annually or when security incident occurs

#### Key Rotation Procedure

##### Phase 1: Generate New Key (Week 1)

```bash
# Generate new key with new selector
cd /etc/opendkim/keys/example.com
sudo opendkim-genkey -t -s 2024-07 -d example.com

# Set proper permissions
sudo chown opendkim:opendkim 2024-07.private
sudo chmod 600 2024-07.private

# View new DNS record
cat 2024-07.txt
```

##### Phase 2: Publish New DNS Record (Week 2)

```text
# Keep old key active
2024-01._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=OldPublicKey..."

# Add new key
2024-07._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=NewPublicKey..."
```

Verify propagation:

```bash
dig +short TXT 2024-07._domainkey.example.com
```

##### Phase 3: Update Signing Configuration (Week 3)

```ini
# /etc/opendkim.conf
# Change selector from 2024-01 to 2024-07
Selector    2024-07
KeyFile     /etc/opendkim/keys/example.com/2024-07.private
```

Restart service:

```bash
sudo systemctl restart opendkim
```

Send test email and verify new selector in headers:

```text
DKIM-Signature: v=1; a=rsa-sha256; ... s=2024-07; ...
```

##### Phase 4: Monitor (Week 4-16)

- Keep old DNS record published for 90 days
- Allows in-flight emails to validate
- Monitor DMARC reports for validation issues

##### Phase 5: Remove Old Key (Week 17+)

```bash
# Remove old DNS record
# Delete: 2024-01._domainkey.example.com

# Archive old private key
sudo mv /etc/opendkim/keys/example.com/2024-01.private \
        /etc/opendkim/keys/archive/2024-01.private.$(date +%F)
```

#### Automated Rotation Script

```bash
#!/bin/bash
# DKIM Key Rotation Script

DOMAIN="example.com"
NEW_SELECTOR="$(date +%Y-%m)"
KEY_DIR="/etc/opendkim/keys/${DOMAIN}"
CONFIG="/etc/opendkim.conf"

echo "=== DKIM Key Rotation for $DOMAIN ==="
echo "New selector: $NEW_SELECTOR"
echo

# 1. Generate new key
echo "1. Generating new key..."
sudo mkdir -p "$KEY_DIR"
cd "$KEY_DIR"
sudo opendkim-genkey -t -s "$NEW_SELECTOR" -d "$DOMAIN"

if [ $? -ne 0 ]; then
    echo "ERROR: Key generation failed!"
    exit 1
fi

# 2. Set permissions
sudo chown opendkim:opendkim "${NEW_SELECTOR}.private"
sudo chmod 600 "${NEW_SELECTOR}.private"
echo "✓ Key generated and secured"
echo

# 3. Display DNS record
echo "2. Publish this DNS record:"
echo
cat "${NEW_SELECTOR}.txt"
echo
echo "DNS record location: ${NEW_SELECTOR}._domainkey.${DOMAIN}"
echo

# 4. Wait for confirmation
read -p "Press Enter after DNS record is published and propagated..."

# 5. Verify DNS
echo
echo "3. Verifying DNS record..."
if dig +short TXT "${NEW_SELECTOR}._domainkey.${DOMAIN}" | grep -q "v=DKIM1"; then
    echo "✓ DNS record verified"
else
    echo "ERROR: DNS record not found or invalid!"
    exit 1
fi
echo

# 6. Update configuration
echo "4. Updating OpenDKIM configuration..."
sudo sed -i "s/^Selector.*/Selector    ${NEW_SELECTOR}/" "$CONFIG"
sudo sed -i "s|^KeyFile.*|KeyFile     ${KEY_DIR}/${NEW_SELECTOR}.private|" "$CONFIG"
echo "✓ Configuration updated"
echo

# 7. Restart OpenDKIM
echo "5. Restarting OpenDKIM..."
sudo systemctl restart opendkim

if [ $? -eq 0 ]; then
    echo "✓ OpenDKIM restarted successfully"
else
    echo "ERROR: OpenDKIM restart failed!"
    exit 1
fi
echo

# 8. Test
echo "6. Sending test email..."
echo "DKIM rotation test - Selector: ${NEW_SELECTOR}" | \
    mail -s "DKIM Test - ${NEW_SELECTOR}" admin@${DOMAIN}
echo "✓ Test email sent"
echo

echo "=== Rotation Complete ==="
echo
echo "Next steps:"
echo "1. Verify test email shows dkim=pass with selector=${NEW_SELECTOR}"
echo "2. Keep old DNS record published for 90 days"
echo "3. Monitor DMARC reports for any issues"
echo "4. Remove old DNS record after 90 days"
echo "5. Archive old private key"
```

### DKIM Best Practices

#### Key Management

- **Use 2048-bit keys minimum** - Balance security and compatibility
- **Secure private keys** - File permissions 600, owned by signing process
- **Rotate keys annually** - Or immediately if compromise suspected
- **Use unique keys per selector** - Don't reuse keys across selectors or domains
- **Archive old keys** - Keep for forensics, delete after retention period

#### Signing Configuration

- **Sign all outgoing mail** - No exceptions for internal or automated emails
- **Use relaxed canonicalization** - `relaxed/relaxed` handles forwarding better
- **Sign important headers** - Minimum: From, To, Subject, Date, Message-ID
- **Use descriptive selectors** - `2024-01`, `marketing`, not `k1`, `s1`
- **Test mode first** - Use `t=y` flag during initial deployment

#### DNS Configuration

- **Use adequate TTL** - 86400 (24 hours) for stable keys
- **Reduce TTL before rotation** - 3600 (1 hour) for faster updates
- **Split long records** - Use multiple strings for 4096-bit keys
- **Monitor DNS performance** - Ensure low latency for public key lookups
- **Use reliable DNS provider** - High uptime critical for email delivery

#### Monitoring and Maintenance

- **Review DMARC reports** - Check DKIM pass rates weekly
- **Monitor signing errors** - Alert on DKIM signing failures
- **Test regularly** - Send test emails monthly
- **Document selector strategy** - Maintain inventory of active keys
- **Plan key rotation** - Schedule annual rotations in advance

#### Multi-Domain Considerations

- **Separate keys per domain** - Don't share keys across domains
- **Consistent selector naming** - Use same scheme across all domains
- **Centralized key management** - Use configuration management tools
- **Staggered rotation** - Don't rotate all domains simultaneously

### DKIM Migration Checklist

#### DKIM Pre-Implementation Phase

**Assess Current State:**

- [ ] Identify all mail sending sources
  - [ ] Primary mail servers
  - [ ] Marketing platforms
  - [ ] Application servers
  - [ ] Third-party services

- [ ] Check if DKIM already configured
  - [ ] Query existing DNS records
  - [ ] Review current signing configuration

- [ ] Document domains and subdomains
  - [ ] Main domain
  - [ ] Subdomains sending email

**Planning:**

- [ ] Choose selector naming scheme
  - [ ] Time-based: `2024-01`
  - [ ] Purpose-based: `default`, `marketing`
  - [ ] Sequential: `k1`, `k2`, `k3`

- [ ] Select key size (2048-bit recommended)

- [ ] Plan key rotation schedule (annual recommended)

- [ ] Determine signing policy
  - [ ] Headers to sign
  - [ ] Canonicalization mode
  - [ ] Testing mode flag

#### DKIM Implementation Phase

##### Week 1: Generate and Publish Keys

- [ ] Generate DKIM key pairs for all domains

```bash
sudo opendkim-genkey -t -s default -d example.com
```

- [ ] Secure private keys

```bash
sudo chown opendkim:opendkim default.private
sudo chmod 600 default.private
```

- [ ] Publish public keys to DNS with testing flag

```text
default._domainkey.example.com. 3600 IN TXT (
  "v=DKIM1; k=rsa; t=y; "
  "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN..."
)
```

- [ ] Verify DNS propagation

```bash
dig +short TXT default._domainkey.example.com
```

##### Week 2: Configure Signing

- [ ] Install and configure signing software
  - [ ] OpenDKIM for Postfix
  - [ ] Enable DKIM in Exchange/Office 365
  - [ ] Configure DKIM in Google Workspace

- [ ] Update configuration files

```ini
# /etc/opendkim.conf
Mode                    sv
Selector                default
KeyFile                 /etc/opendkim/keys/example.com/default.private
Canonicalization        relaxed/relaxed
SignHeaders             From,To,Subject,Date,Message-ID
```

- [ ] Restart mail services

```bash
sudo systemctl restart opendkim
sudo systemctl restart postfix
```

##### Week 3: Testing

- [ ] Send test emails from all sources
- [ ] Verify DKIM-Signature headers present

```text
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;
  d=example.com; s=default; ...
```

- [ ] Check authentication results in received emails

```text
Authentication-Results: mx.google.com;
  dkim=pass header.i=@example.com header.s=default;
```

- [ ] Test from all mail sources
  - [ ] Corporate mail servers
  - [ ] Marketing platforms
  - [ ] Application emails

- [ ] Verify with online validators
  - [ ] Mail-Tester
  - [ ] DKIM Core
  - [ ] MXToolbox

##### Week 4: Production Deployment

- [ ] Remove testing flag from DNS records

```text
default._domainkey.example.com. 86400 IN TXT (
  "v=DKIM1; k=rsa; "
  "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN..."
)
```

- [ ] Increase DNS TTL to 86400 (24 hours)

- [ ] Enable signing for all outgoing email

- [ ] Document configuration

#### DKIM Post-Implementation Phase

**Ongoing Monitoring:**

- [ ] Review DMARC reports weekly
- [ ] Monitor DKIM pass rates
- [ ] Check for signing failures
- [ ] Test monthly with sample emails

**Quarterly Maintenance:**

- [ ] Audit active selectors
- [ ] Review key sizes and algorithms
- [ ] Verify DNS records still valid
- [ ] Update documentation

**Annual Rotation:**

- [ ] Generate new keys with new selectors
- [ ] Publish new DNS records
- [ ] Update signing configuration
- [ ] Monitor for 90 days
- [ ] Remove old DNS records
- [ ] Archive old private keys

#### Multi-Domain Checklist

- [ ] Generate separate keys for each domain
- [ ] Use consistent selector naming across domains
- [ ] Stagger deployment across domains
- [ ] Test each domain independently
- [ ] Document domain-specific configurations

### DKIM Quick Reference

```text
┌─────────────────────────────────────────────────────────┐
│ DKIM QUICK REFERENCE                                    │
├─────────────────────────────────────────────────────────┤
│ DNS Record Format:                                      │
│   [selector]._domainkey.[domain] IN TXT                 │
│   "v=DKIM1; k=rsa; p=<public-key>"                      │
│                                                         │
│ Common Selectors:                                       │
│   default          General purpose                      │
│   2024-01          Time-based rotation                  │
│   marketing        Purpose-specific                     │
│   google           Google Workspace                     │
│                                                         │
│ Key Generation:                                         │
│   openssl genrsa -out dkim_private.pem 2048             │
│   opendkim-genkey -t -s default -d example.com          │
│                                                         │
│ Signature Fields:                                       │
│   v=1              Version                              │
│   a=rsa-sha256     Algorithm                            │
│   c=relaxed/relaxed Canonicalization                    │
│   d=example.com    Signing domain                       │
│   s=default        Selector                             │
│   h=from:to:subject Signed headers                      │
│   b=<signature>    Signature value                      │
│                                                         │
│ Canonicalization:                                       │
│   simple/simple    Strict (no changes)                  │
│   relaxed/relaxed  Lenient (recommended)                │
│                                                         │
│ Best Practices:                                         │
│   ✓ Use 2048-bit keys minimum                           │
│   ✓ Rotate keys annually                                │
│   ✓ Sign all outgoing mail                              │
│   ✓ Use relaxed canonicalization                        │
│   ✓ Sign important headers (From, Subject, Date)        │
│   ✓ Test with t=y flag initially                        │
│                                                         │
│ Testing Commands:                                       │
│   dig +short TXT default._domainkey.example.com         │
│   opendkim-testkey -d example.com -s default -vvv       │
│                                                         │
│ Troubleshooting:                                        │
│   dkim=pass     ✓ Working correctly                     │
│   dkim=fail     ✗ Signature verification failed         │
│   dkim=temperror ⚠ DNS lookup failed                    │
│   dkim=none     - No DKIM signature present             │
└─────────────────────────────────────────────────────────┘
```

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
