---
title: "DKIM Testing and Troubleshooting"
description: "Verifying DKIM signatures and diagnosing signature failures"
author: "Joseph Streeter"
tags: ["email", "authentication", "dkim", "testing", "troubleshooting"]
category: "services"
last_updated: "2026-08-01"
---
## DKIM Testing and Troubleshooting

Confirming that signing works, and finding out why it does not.

### DKIM Testing and Validation

#### DKIM Command-Line Testing

**Query DKIM DNS records:**

```bash
# Basic DKIM query
dig +short TXT default._domainkey.example.com

# Expected output
"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC5N3ln..."

# Detailed query
dig TXT default._domainkey.example.com

# Check specific selector
dig +short TXT google._domainkey.example.com
```

**Verify key format:**

```bash
# Extract public key and validate
dig +short TXT default._domainkey.example.com | \
  grep -o 'p=[^;]*' | \
  cut -d= -f2 | \
  base64 -d | \
  openssl rsa -pubin -inform DER -text -noout
```

#### Send Test Emails

**Basic test:**

```bash
# Send test email to yourself
echo "DKIM test message" | mail -s "DKIM Test" test@gmail.com

# Send with specific from address
echo "DKIM test" | mail -s "DKIM Test" -r sender@example.com test@gmail.com
```

**Check authentication headers in received email:**

```text
Authentication-Results: mx.google.com;
  dkim=pass header.i=@example.com header.s=default header.b=dzdVyOfA;
```

#### DKIM Verification Script

```bash
#!/bin/bash
# DKIM Validation Script

DOMAIN=$1
SELECTOR=${2:-default}

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain> [selector]"
    exit 1
fi

echo "===== DKIM Validation for $DOMAIN ====="
echo "Selector: $SELECTOR"
echo

# 1. Check DNS record
echo "1. Checking DKIM DNS record..."
DKIM_RECORD=$(dig +short TXT ${SELECTOR}._domainkey.${DOMAIN})

if [ -z "$DKIM_RECORD" ]; then
    echo "ERROR: No DKIM record found!"
    echo "Expected location: ${SELECTOR}._domainkey.${DOMAIN}"
    exit 1
fi

echo "DKIM Record found:"
echo "$DKIM_RECORD"
echo

# 2. Validate record structure
echo "2. Validating record structure..."
if echo "$DKIM_RECORD" | grep -q "v=DKIM1"; then
    echo "✓ Version tag present"
else
    echo "✗ Missing v=DKIM1 tag"
fi

if echo "$DKIM_RECORD" | grep -q "k=rsa"; then
    echo "✓ Key type specified (RSA)"
else
    echo "⚠ Key type not specified (defaults to RSA)"
fi

if echo "$DKIM_RECORD" | grep -q "p="; then
    echo "✓ Public key present"
    KEY_LENGTH=$(echo "$DKIM_RECORD" | grep -o 'p=[^;]*' | cut -d= -f2 | wc -c)
    echo "  Key length (base64): ~$KEY_LENGTH characters"
else
    echo "✗ Missing public key!"
    exit 1
fi

echo

# 3. Test key extraction
echo "3. Testing public key extraction..."
PUBLIC_KEY=$(echo "$DKIM_RECORD" | grep -o 'p=[^"]*' | cut -d= -f2 | tr -d ' "')

if [ -n "$PUBLIC_KEY" ]; then
    echo "✓ Public key extracted successfully"
    echo "  First 50 chars: ${PUBLIC_KEY:0:50}..."
else
    echo "✗ Failed to extract public key"
fi

echo
echo "===== Validation Complete ====="
echo
echo "Next steps:"
echo "1. Send test email from $DOMAIN"
echo "2. Check received email headers for:"
echo "   dkim=pass header.i=@$DOMAIN header.s=$SELECTOR"
```

#### Online DKIM Validators

**MXToolbox DKIM Checker:**

- URL: <https://mxtoolbox.com/dkim.aspx>
- Features: DNS record validation, key extraction, syntax checking
- Tests: Record existence, proper formatting, key validity

**DKIM Core Validator:**

- URL: <https://dkimcore.org/tools/>
- Features: Comprehensive DKIM testing
- Tests: Send email to test address, receive detailed analysis

**Mail-Tester:**

- URL: <https://www.mail-tester.com/>
- Features: Complete email authentication testing
- Tests: SPF, DKIM, DMARC, spam score

**What to verify:**

- ✅ DNS record exists at correct location
- ✅ Record contains v=DKIM1
- ✅ Public key (p=) is present and valid
- ✅ Key type (k=rsa) specified or implied
- ✅ Selector matches signing configuration
- ✅ No syntax errors in record
- ✅ Test emails show dkim=pass

#### DKIM Email Header Analysis

**Successful DKIM Pass:**

```text
Authentication-Results: mx.google.com;
  dkim=pass header.i=@example.com header.s=default header.b=dzdVyOfA;
  dkim=pass header.i=@example.com header.s=google header.b=K8xPmL9Q;
```

Multiple DKIM signatures can pass (using different selectors).

**DKIM Failure:**

```text
Authentication-Results: mx.gmail.com;
  dkim=fail (signature verification failed) header.i=@example.com header.s=default header.b=dzdVyOfA;
```

**DKIM TempError:**

```text
Authentication-Results: mx.outlook.com;
  dkim=temperror (temporary DNS failure retrieving public key) header.i=@example.com;
```

**DKIM Neutral:**

```text
Authentication-Results: mail.example.com;
  dkim=neutral (body hash did not verify) header.i=@example.com;
```

**What to check:**

- `dkim=pass` - Configuration working correctly
- `dkim=fail` - Signature verification failed (wrong key, modified message)
- `dkim=temperror` - DNS issue retrieving public key
- `dkim=neutral` - Signature present but validation inconclusive
- `dkim=none` - No DKIM signature found
- `dkim=policy` - Signing policy violation

#### DKIM Testing Checklist

Before deploying DKIM to production:

- [ ] DKIM keys generated (minimum 2048-bit)
- [ ] Private key secured with proper permissions
- [ ] Public key published in DNS at correct selector
- [ ] DNS record propagated (check with dig)
- [ ] Mail server configured for DKIM signing
- [ ] Test emails sent from all mail sources
- [ ] Headers show `dkim=pass` for test emails
- [ ] Multiple selectors configured (if using rotation)
- [ ] Key rotation schedule documented
- [ ] Monitoring alerts configured

### DKIM Troubleshooting Guide

#### Problem: DKIM Signature Not Added

**Symptoms:**

- Email headers missing DKIM-Signature
- Recipients show `dkim=none`
- No signature verification attempted

**Diagnosis:**

```bash
# Check if OpenDKIM is running
sudo systemctl status opendkim

# Check OpenDKIM logs
sudo tail -f /var/log/mail.log | grep opendkim

# Verify Postfix milter configuration
postconf | grep milter
```

**Solutions:**

1. **Verify OpenDKIM service running:**

   ```bash
   sudo systemctl start opendkim
   sudo systemctl enable opendkim
   ```

2. **Check Postfix milter configuration:**

   ```ini
   # /etc/postfix/main.cf should have:
   smtpd_milters = inet:localhost:8891
   non_smtpd_milters = inet:localhost:8891
   milter_default_action = accept
   ```

3. **Verify socket connection:**

   ```bash
   # Check if OpenDKIM listening
   netstat -ln | grep 8891
   
   # Test connection
   telnet localhost 8891
   ```

4. **Check key file permissions:**

   ```bash
   ls -l /etc/opendkim/keys/example.com/default.private
   # Should be: -rw------- opendkim opendkim
   
   sudo chown opendkim:opendkim /etc/opendkim/keys/example.com/default.private
   sudo chmod 600 /etc/opendkim/keys/example.com/default.private
   ```

#### Problem: DKIM Signature Verification Fails

**Symptoms:**

- Headers show `dkim=fail`
- Signature present but doesn't verify
- Recipients reject or quarantine email

**Diagnosis:**

```bash
# Verify DNS public key matches private key
dig +short TXT default._domainkey.example.com

# Check OpenDKIM logs for errors
sudo grep -i dkim /var/log/mail.log
```

**Common causes:**

1. **Public/private key mismatch:**

   ```bash
   # Regenerate keys and ensure matching pair
   cd /etc/opendkim/keys/example.com
   sudo opendkim-genkey -t -s default -d example.com
   
   # Publish the new public key from default.txt
   cat default.txt
   ```

2. **DNS record not propagated:**

   ```bash
   # Check multiple DNS servers
   dig @8.8.8.8 TXT default._domainkey.example.com
   dig @1.1.1.1 TXT default._domainkey.example.com
   
   # Wait 24-48 hours for full propagation
   ```

3. **Selector mismatch:**

   Signing configuration uses selector "default" but DNS published as "mail":

   ```bash
   # Check OpenDKIM config
   grep Selector /etc/opendkim.conf
   # Selector   default
   
   # Verify DNS matches
   dig +short TXT default._domainkey.example.com  # Must exist
   ```

4. **Message modified in transit:**

   - Email gateway or filter changed message body/headers
   - Solution: Use `relaxed/relaxed` canonicalization
   - Update `/etc/opendkim.conf`:

   ```ini
   Canonicalization    relaxed/relaxed
   ```

5. **Signed headers missing:**

   ```bash
   # Ensure critical headers are signed
   grep SignHeaders /etc/opendkim.conf
   # Should include: From,To,Subject,Date,Message-ID
   ```

#### Problem: DNS Record Too Long

**Symptoms:**

- DNS query returns truncated record
- `dkim=permerror` in headers
- Public key incomplete

**Explanation:**

DNS TXT records have a 255-character limit per string, but can contain multiple strings.

**Solution - Split long records:**

```text
# Single string (may cause issues)
default._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAraC3pqvqTkAfXhUn7Kn3JUNMwDkZ+v2X9z8..."

# Multiple strings (better)
default._domainkey.example.com. IN TXT (
  "v=DKIM1; k=rsa; "
  "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAraC3pqvqTkAfXhUn7Kn3JUNMwDkZ+v2X9z8..."
  "...continuing long key..."
)
```

**Verify proper concatenation:**

```bash
dig +short TXT default._domainkey.example.com
# Should show full key without truncation
```

**Alternative - Use 2048-bit instead of 4096-bit:**

4096-bit keys often exceed DNS limits. Use 2048-bit for best compatibility.

#### Problem: DKIM Fails After Email Forwarding

**Symptoms:**

- Original email passes DKIM
- Forwarded email fails DKIM
- `dkim=fail` on forwarded copy

**Explanation:**

Some forwarding servers modify message headers or body, breaking DKIM signature.

**Solutions:**

1. **Use relaxed canonicalization:**

   ```ini
   # /etc/opendkim.conf
   Canonicalization relaxed/relaxed
   ```

   This tolerates whitespace and minor formatting changes.

2. **Don't sign entire body (use l= tag):**

   ```text
   DKIM-Signature: ... l=1234 ...
   ```

   Signs only first 1234 bytes of body, allowing footer additions. Not recommended for security reasons.

3. **Implement ARC (Authenticated Received Chain):**

   ARC preserves authentication results through forwarding:

   ```bash
   # Install OpenARC alongside OpenDKIM
   sudo apt-get install openarc
   ```

4. **Rely on DMARC alignment:**

   DKIM failure on forwarded mail is acceptable if DMARC has:
   - `aspf=r` (relaxed SPF alignment)
   - Alternative DKIM signature from forwarding server

#### Problem: DKIM TempError

**Symptoms:**

- Headers show `dkim=temperror`
- Intermittent validation failures
- DNS timeout errors

**Diagnosis:**

```bash
# Test DNS resolution speed
time dig TXT default._domainkey.example.com

# Check DNS server response
dig TXT default._domainkey.example.com +trace
```

**Solutions:**

1. **DNS server performance:**

   - Move to faster DNS provider (Cloudflare, AWS Route 53)
   - Increase DNS TTL to reduce lookups:

   ```text
   default._domainkey.example.com. 86400 IN TXT "v=DKIM1; ..."
   #                               ^^^^^
   #                               24 hours
   ```

2. **Verify DNS record syntax:**

   ```bash
   # Should return clean record
   dig +short TXT default._domainkey.example.com
   
   # No errors in detailed output
   dig TXT default._domainkey.example.com
   ```

3. **Check for DNS rate limiting:**

   High email volume may trigger DNS rate limits. Use DNS provider with higher limits.

#### Problem: Multiple DKIM Signatures, Some Fail

**Symptoms:**

- Email has multiple DKIM signatures
- Some pass, some fail
- Email still delivered

**Example headers:**

```text
Authentication-Results: mx.google.com;
  dkim=pass header.i=@example.com header.s=default header.b=dzdVyOfA;
  dkim=fail header.i=@sendgrid.net header.s=s1 header.b=K8xPmL9Q;
```

**Explanation:**

Multiple DKIM signatures are normal when:

- Using third-party email service (SendGrid, Mailchimp)
- Email gateway adds signature
- Multiple mail servers in path

**Action required:**

**None**, if at least one DKIM signature passes. DMARC requires only one passing DKIM signature aligned with From domain.

**If all signatures fail:**

1. Check private/public key pairs for each
2. Verify each selector's DNS record
3. Confirm signing configurations

#### SPF Troubleshooting Commands Reference

```bash
# Check DKIM DNS record
dig +short TXT default._domainkey.example.com

# Detailed DNS query with trace
dig TXT default._domainkey.example.com +trace

# Check from multiple DNS servers
dig @8.8.8.8 TXT default._domainkey.example.com
dig @1.1.1.1 TXT default._domainkey.example.com

# Verify OpenDKIM service
sudo systemctl status opendkim
sudo systemctl restart opendkim

# Check OpenDKIM configuration
sudo opendkim-testkey -d example.com -s default -vvv

# View OpenDKIM logs
sudo tail -f /var/log/mail.log | grep -i dkim

# Check Postfix milter configuration
postconf | grep milter

# Test milter connection
telnet localhost 8891

# Verify key file permissions
ls -l /etc/opendkim/keys/example.com/default.private

# Send test email
echo "DKIM Test" | mail -s "DKIM Test" test@gmail.com

# Extract and validate public key
dig +short TXT default._domainkey.example.com | \
  grep -o 'p=[^"]*' | cut -d= -f2 | base64 -d | \
  openssl rsa -pubin -inform DER -text -noout
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
