---
title: "DMARC Testing and Troubleshooting"
description: "Validating DMARC records and alignment, and diagnosing DMARC failures"
author: "Joseph Streeter"
tags: ["email", "authentication", "dmarc", "testing", "troubleshooting"]
category: "services"
last_updated: "2026-08-01"
---
## DMARC Testing and Troubleshooting

Checking that a DMARC record parses is easy; checking that alignment actually holds
for every sending source is the real work.

### DMARC Testing and Validation

#### DMARC Command-Line Testing

**Query DMARC records:**

```bash
# Basic DMARC query
dig +short TXT _dmarc.example.com

# Expected output
"v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"

# Detailed query
dig TXT _dmarc.example.com

# Check subdomain DMARC
dig +short TXT _dmarc.mail.example.com

# Check from multiple DNS servers
dig @8.8.8.8 TXT _dmarc.example.com
dig @1.1.1.1 TXT _dmarc.example.com
```

**Verify parent domain lookup:**

```bash
# If subdomain has no DMARC record, it checks parent
dig +short TXT _dmarc.sub.example.com  # Empty
dig +short TXT _dmarc.example.com      # Returns parent policy
```

#### Online DMARC Validators

**MXToolbox DMARC Check:**

- URL: <https://mxtoolbox.com/dmarc.aspx>
- Validates syntax and policy
- Checks DNS propagation
- Explains policy implications

**Dmarcian Inspector:**

- URL: <https://dmarcian.com/dmarc-inspector/>
- Comprehensive validation
- Policy recommendations
- Alignment checking

**DMARC Analyzer:**

- URL: <https://www.dmarcanalyzer.com/dmarc/dmarc-check/>
- Free DMARC checker
- Syntax validation
- Best practice recommendations

**What validators check:**

- ✅ Record exists at `_dmarc.domain`
- ✅ Starts with `v=DMARC1`
- ✅ Has policy tag (`p=none|quarantine|reject`)
- ✅ Valid email addresses in `rua=` and `ruf=`
- ✅ Percentage (`pct=`) between 0-100
- ✅ Alignment tags (`adkim=`, `aspf=`) valid
- ✅ No syntax errors

#### Sending Test Emails

**Basic test:**

```bash
# Send from your domain
echo "DMARC test message" | mail -s "DMARC Test" test@gmail.com

# Check authentication headers in received email
```

**Expected headers - all pass:**

```text
Authentication-Results: mx.google.com;
  dmarc=pass (p=QUARANTINE sp=QUARANTINE dis=NONE) header.from=example.com
  spf=pass (google.com: domain of sender@example.com designates 192.0.2.10 as permitted sender) smtp.mailfrom=sender@example.com
  dkim=pass header.i=@example.com header.s=default header.b=dzdVyOfA
```

**Expected headers - DMARC fail:**

```text
Authentication-Results: mx.google.com;
  dmarc=fail (p=QUARANTINE dis=QUARANTINE) header.from=example.com
  spf=fail smtp.mailfrom=spoofed@example.com
  dkim=fail header.i=@example.com
```

#### DMARC Testing Script

```bash
#!/bin/bash
# DMARC Validation Script

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

echo "===== DMARC Validation for $DOMAIN ====="
echo

# 1. Check DMARC record
echo "1. Checking DMARC DNS record..."
DMARC_RECORD=$(dig +short TXT _dmarc.${DOMAIN})

if [ -z "$DMARC_RECORD" ]; then
    echo "ERROR: No DMARC record found!"
    echo "Expected location: _dmarc.${DOMAIN}"
    exit 1
fi

echo "DMARC Record:"
echo "$DMARC_RECORD"
echo

# 2. Validate record structure
echo "2. Validating record structure..."

if echo "$DMARC_RECORD" | grep -q "v=DMARC1"; then
    echo "✓ Version tag present (v=DMARC1)"
else
    echo "✗ Missing v=DMARC1 tag!"
fi

POLICY=$(echo "$DMARC_RECORD" | grep -o 'p=[^;]*' | cut -d= -f2 | tr -d ' "')
if [ -n "$POLICY" ]; then
    echo "✓ Policy tag present: p=$POLICY"
    
    case "$POLICY" in
        none)
            echo "  ⚠ Monitoring only - no enforcement"
            ;;
        quarantine)
            echo "  ⚠ Failures marked as spam"
            ;;
        reject)
            echo "  ✓ Failures rejected - full enforcement"
            ;;
        *)
            echo "  ✗ Invalid policy value!"
            ;;
    esac
else
    echo "✗ Missing policy tag (p=)!"
fi

if echo "$DMARC_RECORD" | grep -q "rua="; then
    RUA=$(echo "$DMARC_RECORD" | grep -o 'rua=[^;]*' | cut -d= -f2-)
    echo "✓ Aggregate reporting configured: $RUA"
else
    echo "⚠ No aggregate reporting (rua=) - won't receive reports"
fi

if echo "$DMARC_RECORD" | grep -q "ruf="; then
    RUF=$(echo "$DMARC_RECORD" | grep -o 'ruf=[^;]*' | cut -d= -f2-)
    echo "✓ Forensic reporting configured: $RUF"
fi

ADKIM=$(echo "$DMARC_RECORD" | grep -o 'adkim=[^;]*' | cut -d= -f2 | tr -d ' "')
if [ -n "$ADKIM" ]; then
    echo "✓ DKIM alignment: $ADKIM (r=relaxed, s=strict)"
else
    echo "  Default DKIM alignment: relaxed"
fi

ASPF=$(echo "$DMARC_RECORD" | grep -o 'aspf=[^;]*' | cut -d= -f2 | tr -d ' "')
if [ -n "$ASPF" ]; then
    echo "✓ SPF alignment: $ASPF (r=relaxed, s=strict)"
else
    echo "  Default SPF alignment: relaxed"
fi

PCT=$(echo "$DMARC_RECORD" | grep -o 'pct=[^;]*' | cut -d= -f2 | tr -d ' "')
if [ -n "$PCT" ]; then
    echo "✓ Policy applies to: $PCT% of messages"
else
    echo "  Default percentage: 100%"
fi

echo

# 3. Check subdomain policy
echo "3. Checking subdomain configuration..."
if echo "$DMARC_RECORD" | grep -q "sp="; then
    SP=$(echo "$DMARC_RECORD" | grep -o 'sp=[^;]*' | cut -d= -f2 | tr -d ' "')
    echo "✓ Subdomain policy: sp=$SP"
else
    echo "  No explicit subdomain policy (inherits main policy)"
fi

echo

# 4. Check prerequisites
echo "4. Checking SPF and DKIM..."

SPF=$(dig +short TXT ${DOMAIN} | grep "v=spf1")
if [ -n "$SPF" ]; then
    echo "✓ SPF record found"
else
    echo "✗ No SPF record - DMARC requires SPF or DKIM!"
fi

# Check for common DKIM selectors
for selector in default google mail dkim; do
    DKIM=$(dig +short TXT ${selector}._domainkey.${DOMAIN} | grep "v=DKIM1")
    if [ -n "$DKIM" ]; then
        echo "✓ DKIM record found (selector: $selector)"
        break
    fi
done

if [ -z "$DKIM" ]; then
    echo "⚠ No DKIM record found (checked common selectors)"
    echo "  DMARC requires SPF or DKIM to function"
fi

echo
echo "===== Validation Complete ====="
echo
echo "Recommendations:"
if [ "$POLICY" = "none" ]; then
    echo "  - Monitor reports for 4+ weeks"
    echo "  - Fix any SPF/DKIM issues discovered"
    echo "  - Upgrade to p=quarantine when ready"
elif [ "$POLICY" = "quarantine" ]; then
    echo "  - Monitor for false positives"
    echo "  - Ensure pass rate > 95%"
    echo "  - Consider upgrading to p=reject after 2-3 months"
elif [ "$POLICY" = "reject" ]; then
    echo "  - Full enforcement active"
    echo "  - Continue monitoring reports"
    echo "  - Address any new failures promptly"
fi
```

#### Pre-Deployment Testing Checklist

Before deploying DMARC:

- [ ] SPF configured and passing
- [ ] DKIM configured and signing all mail
- [ ] DMARC record syntax validated
- [ ] Reporting email address configured and monitored
- [ ] Test emails sent and headers checked
- [ ] All sending sources identified and authenticated
- [ ] Alignment mode chosen (relaxed recommended)
- [ ] Subdomain policy configured
- [ ] Monitoring tools/processes in place

During monitoring phase (p=none):

- [ ] Receive and review aggregate reports daily
- [ ] Identify all legitimate sending sources
- [ ] Fix any SPF or DKIM failures
- [ ] Achieve > 95% pass rate
- [ ] Document all authorized sources
- [ ] Maintain monitoring for minimum 4 weeks

Before moving to quarantine:

- [ ] All legitimate sources passing DMARC
- [ ] Pass rate stable at > 95%
- [ ] No unknown legitimate sources appearing
- [ ] Team prepared for potential false positives
- [ ] Escalation process documented

Before moving to reject:

- [ ] Quarantine phase completed (2-3 months minimum)
- [ ] Pass rate consistently > 98%
- [ ] No recent issues or false positives
- [ ] Business stakeholders informed
- [ ] Rollback plan documented

### DMARC Troubleshooting Guide

#### Problem: No DMARC Reports Received

**Symptoms:**

- DMARC record published
- No aggregate or forensic reports arriving
- Reporting address configured correctly

**Diagnosis:**

```bash
# Verify DMARC record
dig +short TXT _dmarc.example.com

# Check rua and ruf tags present
# v=DMARC1; p=none; rua=mailto:dmarc@example.com
```

**Solutions:**

1. **Verify email address is valid:**

   ```bash
   # Test if mailbox accepts mail
   echo "Test" | mail -s "Test" dmarc@example.com
   ```

2. **Check spam filters:**

   - DMARC reports may be filtered as spam
   - Add sender addresses to allowlist:
     - `*@google.com` (Gmail DMARC reports)
     - `*@yahoo.com` (Yahoo DMARC reports)
     - `*@microsoft.com` (Outlook DMARC reports)

3. **Verify record propagation:**

   ```bash
   # Check from multiple locations
   dig @8.8.8.8 TXT _dmarc.example.com
   dig @1.1.1.1 TXT _dmarc.example.com
   ```

4. **Wait for report cycle:**

   - Reports sent daily (typically)
   - First reports may take 24-48 hours
   - Some senders batch reports weekly

5. **Check for receiving domain verification:**

   Some receivers require external reporting domain verification:

   ```text
   # If rua=mailto:reports@monitoring.com
   # Must publish verification record:
   example.com._report._dmarc.monitoring.com. IN TXT "v=DMARC1"
   ```

#### Problem: DMARC Fails But SPF and DKIM Pass

**Symptoms:**

- SPF passes
- DKIM passes
- DMARC fails
- Headers show alignment issue

**Example headers:**

```text
Authentication-Results: mx.google.com;
  dmarc=fail (p=QUARANTINE dis=NONE) header.from=example.com
  spf=pass smtp.mailfrom=sendgrid.net
  dkim=pass header.i=@sendgrid.net header.s=s1
```

**Diagnosis:**

Alignment failure - authenticated domain doesn't match From header:

- **From header:** `user@example.com`
- **SPF domain:** `sendgrid.net` (doesn't align)
- **DKIM domain:** `sendgrid.net` (doesn't align)

**Solutions:**

1. **Configure third-party to use your domain:**

   **SendGrid example:**

   Enable "Custom Return Path" to use your domain:

   ```text
   # SendGrid configuration
   Return-Path: bounce@mail.example.com
   
   # Update SPF
   example.com. IN TXT "v=spf1 include:sendgrid.net -all"
   
   # Add CNAME for bounces
   mail.example.com. IN CNAME sendgrid.net.
   ```

   **Result:** SPF now authenticates as `mail.example.com`, which aligns with `example.com`

2. **Configure third-party DKIM with your domain:**

   **SendGrid example:**

   ```bash
   # SendGrid generates DKIM records for your domain
   s1._domainkey.example.com. CNAME s1.domainkey.u12345.wl.sendgrid.net.
   s2._domainkey.example.com. CNAME s2.domainkey.u12345.wl.sendgrid.net.
   ```

   **Result:** DKIM signature uses `d=example.com`, which aligns

3. **Use relaxed alignment:**

   ```text
   _dmarc.example.com. IN TXT "v=DMARC1; p=quarantine; adkim=r; aspf=r; ..."
   ```

   Relaxed alignment allows organizational domain match.

#### Problem: Legitimate Email Quarantined/Rejected

**Symptoms:**

- Business-critical emails not delivered
- Headers show DMARC fail
- Recipients see emails in spam or rejected

**Diagnosis:**

```bash
# Review DMARC reports for source
# Identify sending IP and authentication results

# Check authentication for that source
dig +short TXT example.com | grep spf
dig +short TXT default._domainkey.example.com
```

**Solutions:**

1. **Add missing source to SPF:**

   ```text
   # Before
   v=spf1 mx -all
   
   # After - added forgotten application server
   v=spf1 mx ip4:192.0.2.100 -all
   ```

2. **Enable DKIM signing for source:**

   Configure mail server or application to sign with DKIM.

3. **Temporary policy relaxation:**

   ```text
   # If critical, temporarily reduce policy
   _dmarc.example.com. IN TXT "v=DMARC1; p=quarantine; pct=50; ..."
   
   # Or revert to monitoring
   _dmarc.example.com. IN TXT "v=DMARC1; p=none; ..."
   ```

4. **Fast-track fix:**

   ```bash
   # Reduce DNS TTL for quick propagation
   _dmarc.example.com. 300 IN TXT "v=DMARC1; p=none; ..."
   #                   ^^^
   #                   5 minutes
   ```

#### Problem: DMARC Reports Show High Failure Rate

**Symptoms:**

- Aggregate reports show < 90% pass rate
- Multiple source IPs failing
- Mixture of SPF and DKIM failures

**Analysis workflow:**

1. **Export report data:**

   ```bash
   # Use parsedmarc or manual extraction
   parsedmarc -i dmarc-reports/*.xml -o failures.json
   ```

2. **Categorize failures:**

   - **Known sources failing** - Fix authentication
   - **Unknown sources** - Investigate (could be legitimate or abuse)
   - **Third-party services** - Configure alignment
   - **Forwarded email** - Expected, acceptable failures

3. **Prioritize by volume:**

   Focus on sources sending highest volume first.

**Solutions:**

**For corporate mail servers:**

```bash
# Verify SPF includes all servers
v=spf1 ip4:192.0.2.0/24 mx -all

# Enable DKIM signing
# Configure OpenDKIM or equivalent
```

**For third-party services:**

```bash
# Add to SPF
v=spf1 mx include:_spf.service.com -all

# Configure service DKIM with your domain
```

**For application servers:**

```bash
# Add application server IPs to SPF
v=spf1 mx ip4:192.0.2.100 ip4:192.0.2.101 -all

# Or configure applications to relay through authenticated SMTP
```

#### Problem: Subdomain Email Failing DMARC

**Symptoms:**

- Email from `user@sub.example.com` fails DMARC
- Main domain DMARC passes
- Subdomain has no DMARC record

**Diagnosis:**

```bash
# Check subdomain DMARC
dig +short TXT _dmarc.sub.example.com  # Empty

# Check parent DMARC
dig +short TXT _dmarc.example.com  # p=reject
```

**Explanation:**

Subdomains inherit parent DMARC policy if no specific record exists. If subdomain uses different infrastructure, may fail parent's policy.

**Solutions:**

1. **Create subdomain-specific DMARC:**

   ```text
   _dmarc.sub.example.com. IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"
   ```

2. **Configure subdomain SPF:**

   ```text
   sub.example.com. IN TXT "v=spf1 ip4:203.0.113.0/24 -all"
   ```

3. **Enable DKIM for subdomain:**

   ```text
   default._domainkey.sub.example.com. IN TXT "v=DKIM1; k=rsa; p=..."
   ```

4. **Use subdomain policy tag on parent:**

   ```text
   _dmarc.example.com. IN TXT "v=DMARC1; p=reject; sp=quarantine; ..."
   #                                               ^^^^^^^^^^^^^^
   #                                               More lenient for subdomains
   ```

#### Problem: DMARC Reports Too Large/Numerous

**Symptoms:**

- Mailbox overwhelmed with reports
- Hundreds of reports daily
- Difficult to process manually

**Solutions:**

1. **Implement automated processing:**

   ```bash
   # Install parsedmarc
   pip3 install parsedmarc
   
   # Create configuration
   cat > /etc/parsedmarc.conf << 'EOF'
   [general]
   save_aggregate = True
   save_forensic = True
   
   [imap]
   host = imap.example.com
   user = dmarc-reports@example.com
   password = <password>
   
   [elasticsearch]
   hosts = localhost:9200
   index_prefix = dmarc
   EOF
   
   # Run as cron job
   0 * * * * /usr/local/bin/parsedmarc -c /etc/parsedmarc.conf
   ```

2. **Use commercial DMARC service:**

   - Dmarcian
   - Valimail
   - Agari
   - Proofpoint

   These services process reports and provide dashboard.

3. **Set up email filtering:**

   ```text
   # Filter rules
   From: *@google.com AND Subject: "Report domain: example.com"
   → Move to folder: DMARC Reports/Google
   
   From: *@yahoo.com AND Subject: "Report Domain: example.com"
   → Move to folder: DMARC Reports/Yahoo
   ```

4. **Adjust reporting interval:**

   ```text
   # Request daily reports instead of default
   _dmarc.example.com. IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com; ri=86400"
   #                                                                                   ^^^^^^^^
   #                                                                                   24 hours
   ```

   Note: Receivers may ignore `ri=` tag and send on their own schedule.

#### DMARC Troubleshooting Commands Reference

```bash
# Check DMARC record
dig +short TXT _dmarc.example.com

# Detailed DMARC query
dig TXT _dmarc.example.com

# Check subdomain DMARC
dig +short TXT _dmarc.sub.example.com

# Check from multiple DNS servers
dig @8.8.8.8 TXT _dmarc.example.com
dig @1.1.1.1 TXT _dmarc.example.com

# Verify reporting domain (external receiver)
dig +short TXT example.com._report._dmarc.monitoring.com

# Check SPF (required for DMARC)
dig +short TXT example.com | grep spf

# Check DKIM (required for DMARC)
dig +short TXT default._domainkey.example.com

# Parse DMARC XML reports
parsedmarc -i /path/to/reports/*.xml

# Extract source IPs from report
xmllint --xpath "//record/row/source_ip/text()" report.xml | sort | uniq

# Count pass vs fail
xmllint --xpath "//policy_evaluated/dkim/text()" report.xml | sort | uniq -c
xmllint --xpath "//policy_evaluated/spf/text()" report.xml | sort | uniq -c

# Test email and check headers
echo "DMARC test" | mail -s "DMARC Test" test@gmail.com
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
