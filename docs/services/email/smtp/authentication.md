---
title: "Email Authentication - DKIM, DMARC, and SPF"
description: "Documentation for email authentication protocols including DKIM, DMARC, and SPF implementation and configuration"
tags: ["dkim", "dmarc", "spf", "email-authentication", "email-security", "smtp"]
category: "services"
difficulty: "intermediate"
last_updated: "2026-01-13"
author: "Joseph Streeter"
---

This section covers email authentication protocols including DKIM, DMARC, and SPF for securing email communications and preventing spoofing.

## Overview

Email authentication protocols form the foundation of modern email security, working together to verify message authenticity and protect against phishing, spoofing, domain impersonation, and other email-based attacks. These protocols have become essential as email remains one of the primary attack vectors for cybercriminals.

The three primary protocols work in concert:

- **SPF** (Sender Policy Framework) - Validates that emails come from authorized sending servers for a domain
- **DKIM** (DomainKeys Identified Mail) - Cryptographically signs email messages to verify sender identity and message integrity
- **DMARC** (Domain-based Message Authentication, Reporting & Conformance) - Provides a policy framework and reporting mechanism that builds on SPF and DKIM

### Why Email Authentication Matters

Email was originally designed without authentication mechanisms, making it trivial for attackers to forge sender addresses. This fundamental security gap has led to:

- **Phishing attacks** - Criminals impersonating legitimate organizations
- **Business Email Compromise (BEC)** - Attackers posing as executives or partners
- **Brand reputation damage** - Fraudulent emails appearing to come from your domain
- **Email deliverability issues** - Legitimate emails being rejected or marked as spam

Modern email receivers increasingly require proper authentication, with major providers like Gmail, Yahoo, and Microsoft enforcing strict policies. Domains without proper authentication face significant deliverability challenges.

### The Three-Layer Defense

Email authentication uses a defense-in-depth approach:

1. **SPF (Infrastructure Layer)** - Verifies the sending server is authorized for the domain
2. **DKIM (Message Layer)** - Verifies the message hasn't been tampered with in transit
3. **DMARC (Policy Layer)** - Defines what to do when authentication fails and provides visibility

Each protocol addresses different attack vectors. SPF prevents unauthorized servers from sending mail for your domain. DKIM ensures message integrity and provides non-repudiation. DMARC ties them together with policy enforcement and reporting.

### Authentication Flow Overview

When an email is sent with full authentication:

1. **Sender** prepares message with proper headers
2. **Sending Server** adds DKIM signature using private key
3. **Message** travels through internet with SPF and DKIM data
4. **Receiving Server** checks SPF by querying DNS for authorized senders
5. **Receiving Server** verifies DKIM signature using public key from DNS
6. **Receiving Server** checks DMARC policy and alignment
7. **Action Taken** based on DMARC policy (deliver, quarantine, or reject)
8. **Report Sent** to domain owner about authentication results

## SPF (Sender Policy Framework)

### SPF Overview

SPF, defined in RFC 7208, allows domain owners to specify which mail servers are authorized to send email on behalf of their domain. It works by publishing a DNS TXT record listing authorized sending sources. Receiving mail servers check this record against the actual sending server's IP address.

### How SPF Works

The SPF verification process occurs during the SMTP transaction:

1. **Receiving server** accepts connection from sending server
2. **MAIL FROM** command specifies the envelope sender (return-path)
3. **Receiving server** extracts domain from envelope sender
4. **DNS query** retrieves SPF record from sender's domain
5. **IP comparison** checks if sending server IP matches SPF record
6. **Result determined** - pass, fail, softfail, neutral, or none
7. **Action taken** based on result and local policy

SPF checks happen before message content is transmitted, making it an efficient first line of defense.

### SPF Record Syntax

An SPF record is published as a DNS TXT record for the domain. Basic syntax:

```text
v=spf1 [mechanisms] [modifiers]
```

#### Required Elements

- `v=spf1` - Version identifier (always spf1, must be first)

#### Mechanisms

Mechanisms define authorized sending sources. Evaluated left to right, first match wins:

| Mechanism | Description | Example |
| --- | --- | --- |
| `all` | Matches all IPs (catch-all) | `v=spf1 -all` |
| `ip4` | IPv4 address or range | `ip4:192.0.2.0/24` |
| `ip6` | IPv6 address or range | `ip6:2001:db8::/32` |
| `a` | Domain's A record | `a:mail.example.com` |
| `mx` | Domain's MX records | `mx:example.com` |
| `include` | Include another domain's SPF | `include:_spf.google.com` |
| `exists` | Check if domain exists | `exists:%{i}.spf.example.com` |
| `ptr` | PTR record (deprecated) | `ptr:example.com` |

#### Qualifiers

Each mechanism can have a qualifier prefix:

| Qualifier | Symbol | Meaning | Result |
| --- | --- | --- | --- |
| Pass | `+` | Authorized (default) | Pass |
| Fail | `-` | Not authorized | Fail (hard fail) |
| SoftFail | `~` | Probably not authorized | SoftFail |
| Neutral | `?` | No assertion | Neutral |

Examples:

```text
+ip4:192.0.2.0/24    Explicitly pass
-all                 Fail all others (hard fail)
~all                 Soft fail all others (common)
?all                 Neutral (don't use)
```

#### Modifiers

Modifiers provide additional information:

| Modifier | Description | Example |
| --- | --- | --- |
| `redirect` | Redirect to another domain's SPF | `redirect=_spf.example.com` |
| `exp` | Explanation for failures | `exp=explain.example.com` |

### Creating SPF Records

#### Basic SPF Record

Simplest configuration - only allow domain's MX servers:

```text
example.com. IN TXT "v=spf1 mx -all"
```

This means:

- `v=spf1` - SPF version 1
- `mx` - Authorize servers listed in domain's MX records
- `-all` - Hard fail all others

#### Common SPF Configurations

**Company using own mail servers:**

```text
v=spf1 mx ip4:192.0.2.0/24 -all
```

**Using third-party email service (like Google Workspace):**

```text
v=spf1 include:_spf.google.com -all
```

**Multiple sending sources:**

```text
v=spf1 mx include:_spf.google.com include:servers.mcsv.net ip4:203.0.113.0/24 -all
```

**Subdomain delegation:**

```text
mail.example.com. IN TXT "v=spf1 ip4:192.0.2.10 -all"
```

**Complex organization:**

```text
v=spf1 mx include:_spf.google.com include:_spf.salesforce.com include:servers.mcsv.net ip4:192.0.2.0/24 ip4:198.51.100.0/24 -all
```

#### SPF for Subdomains

By default, subdomains don't inherit the parent domain's SPF record. You must create explicit records:

```text
# Parent domain
example.com. IN TXT "v=spf1 mx -all"

# Subdomain for marketing
marketing.example.com. IN TXT "v=spf1 include:servers.mcsv.net -all"

# Subdomain for transactional email
app.example.com. IN TXT "v=spf1 ip4:203.0.113.50 -all"

# Prevent subdomain spoofing (no legitimate email)
*.example.com. IN TXT "v=spf1 -all"
```

### SPF Mechanisms in Detail

#### IP4 and IP6 Mechanisms

Specify exact IP addresses or ranges:

```text
# Single IPv4 address
v=spf1 ip4:192.0.2.10 -all

# IPv4 CIDR range
v=spf1 ip4:192.0.2.0/24 -all

# Multiple IPv4 ranges
v=spf1 ip4:192.0.2.0/24 ip4:198.51.100.0/24 -all

# IPv6 address
v=spf1 ip6:2001:db8::1 -all

# IPv6 range
v=spf1 ip6:2001:db8::/32 -all

# Mixed IPv4 and IPv6
v=spf1 ip4:192.0.2.0/24 ip6:2001:db8::/32 -all
```

#### Include Mechanism

Include another domain's SPF policy. Most common for third-party services:

```text
v=spf1 include:_spf.google.com include:_spf.salesforce.com -all
```

Important: `include` only passes if the included domain returns Pass. If it returns Fail, evaluation continues.

Nesting depth limited to 10 DNS lookups total (see Limitations section).

#### A and MX Mechanisms

Reference DNS records:

```text
# Use domain's A record
v=spf1 a -all

# Use specific host's A record
v=spf1 a:mail.example.com -all

# Use domain's MX records
v=spf1 mx -all

# Use specific domain's MX records
v=spf1 mx:example.com -all

# With CIDR notation (IP must be in range)
v=spf1 a:mail.example.com/24 -all
```

#### Exists Mechanism

Advanced mechanism for conditional logic:

```text
v=spf1 exists:%{i}.spf.example.com -all
```

Passes if the constructed domain name exists (returns any A record). Used for complex conditional authorization.

### SPF Macros

Macros enable dynamic SPF record construction:

| Macro | Expands To |
| --- | --- |
| `%{s}` | Sender email address |
| `%{l}` | Local part of sender |
| `%{d}` | Domain of sender |
| `%{i}` | Sending IP address |
| `%{v}` | IP version (in-addr/ip6) |
| `%{h}` | HELO/EHLO domain |

Example using macro for per-IP validation:

```text
v=spf1 exists:%{i}.whitelist.example.com -all
```

If sending IP is 192.0.2.10, checks for `192.0.2.10.whitelist.example.com`.

### SPF Validation Process

#### Validation Steps

1. **Extract domain** from MAIL FROM (envelope sender)
2. **Query DNS** for TXT record at domain
3. **Parse SPF record** and evaluate mechanisms left to right
4. **Perform DNS lookups** for includes, mx, a, exists mechanisms
5. **Compare sending IP** against authorized sources
6. **Return result** - pass, fail, softfail, neutral, none, temperror, or permerror

#### SPF Results

| Result | Meaning | Recommended Action |
| --- | --- | --- |
| `Pass` | Sender is authorized | Accept message |
| `Fail` | Sender is not authorized | Reject message |
| `SoftFail` | Sender probably not authorized | Accept but mark |
| `Neutral` | No assertion made | Accept message |
| `None` | No SPF record found | Accept message |
| `TempError` | Temporary DNS error | Retry later |
| `PermError` | SPF record error | Accept with caution |

#### Authentication-Results Header

Receiving servers add authentication results to message headers:

```text
Authentication-Results: mx.example.com;
  spf=pass smtp.mailfrom=sender@example.com smtp.helo=mail.example.com
```

### SPF Limitations and Challenges

#### DNS Lookup Limit

SPF imposes a limit of **10 DNS lookups** per validation. This includes:

- Each `include` mechanism (1 lookup)
- Each `a` mechanism (1 lookup)
- Each `mx` mechanism (1 lookup + 1 per MX record)
- Each `exists` mechanism (1 lookup)

Exceeding this limit causes `PermError`, resulting in SPF failure.

Example exceeding limit:

```text
v=spf1 
  include:_spf.google.com        # Lookup 1 (may cause additional internal)
  include:_spf.salesforce.com    # Lookup 2
  include:servers.mcsv.net       # Lookup 3
  include:_spf.service4.com      # Lookup 4
  include:_spf.service5.com      # Lookup 5
  mx                             # Lookup 6 + per MX
  a:mail1.example.com            # Lookup 7
  a:mail2.example.com            # Lookup 8
  a:mail3.example.com            # Lookup 9
  a:mail4.example.com            # Lookup 10
  -all
```

**Solution**: Consolidate using IP addresses instead of mechanisms:

```text
v=spf1 
  include:_spf.google.com 
  ip4:192.0.2.0/24 
  ip4:198.51.100.0/24 
  -all
```

#### 255 Character Limit

DNS TXT records have soft limit of 255 characters per string. While multiple strings can be concatenated, keep records concise:

**Too long:**

```text
v=spf1 include:_spf.google.com include:_spf.salesforce.com include:servers.mcsv.net include:_spf.service4.com include:_spf.service5.com include:_spf.service6.com ip4:192.0.2.0/24 ip4:198.51.100.0/24 ip4:203.0.113.0/24 -all
```

**Better - use redirect or split:**

```text
example.com. IN TXT "v=spf1 include:_spf.example.com -all"
_spf.example.com. IN TXT "v=spf1 include:_spf.google.com include:_spf.salesforce.com ip4:192.0.2.0/24 -all"
```

**Redirect vs Include:**

For complex SPF architectures, you can use either `redirect` or `include` mechanisms:

- **`redirect`** - Replaces the entire SPF record with another domain's record (centralized management)
- **`include`** - Adds another domain's authorized sources to the current record (modular composition)

Basic example of redirect:

```text
example.com. IN TXT "v=spf1 redirect=_spf.example.com"
_spf.example.com. IN TXT "v=spf1 mx include:_spf.google.com ip4:192.0.2.0/24 -all"
```

Basic example of include:

```text
example.com. IN TXT "v=spf1 include:_spf-corp.example.com include:_spf-cloud.example.com -all"
_spf-corp.example.com. IN TXT "v=spf1 mx ip4:192.0.2.0/24 -all"
_spf-cloud.example.com. IN TXT "v=spf1 include:_spf.google.com -all"
```

**For detailed guidance on complex SPF architectures, enterprise patterns, and performance optimization, see [Advanced SPF Architecture Patterns](spf-advanced-patterns.md).**

#### Email Forwarding Problem

SPF breaks with email forwarding:

1. Alice sends from `alice@example.com` via authorized server
2. Bob's server receives and forwards to Charlie's server
3. Charlie's server sees Bob's IP, not example.com's authorized IP
4. SPF check fails

**Solutions:**

- **SRS (Sender Rewriting Scheme)** - Forwarding server rewrites envelope sender
- **DKIM** - Survives forwarding since signature stays with message
- **DMARC** - Can pass with DKIM even if SPF fails

For more details on handling forwarding scenarios, see [Advanced SPF Architecture Patterns](spf-advanced-patterns.md#troubleshooting-complex-spf).

### SPF Best Practices

#### Start with Soft Fail

When first implementing SPF, use soft fail to avoid breaking legitimate email:

```text
v=spf1 mx include:_spf.google.com ~all
```

Monitor for several weeks, then upgrade to hard fail:

```text
v=spf1 mx include:_spf.google.com -all
```

#### Document Sending Sources

Maintain an inventory of all legitimate sending sources:

- Corporate mail servers
- Marketing platforms (Mailchimp, SendGrid, etc.)
- Transactional email services
- CRM systems (Salesforce, HubSpot)
- Help desk software
- Application servers
- Third-party services sending on your behalf

#### Use Include for Third-Party Services

Don't list third-party IPs directly - they change frequently:

```text
# Bad - IPs change
v=spf1 ip4:192.0.2.10 ip4:192.0.2.11 -all

# Good - use provider's SPF
v=spf1 include:_spf.provider.com -all
```

#### Implement for All Domains and Subdomains

Every domain and subdomain should have an SPF record:

```text
# Main domain
example.com. IN TXT "v=spf1 mx -all"

# Subdomain that sends email
mail.example.com. IN TXT "v=spf1 a -all"

# Subdomains that never send email
*.example.com. IN TXT "v=spf1 -all"
```

#### Monitor DNS Lookup Count

Regularly audit your SPF record to stay under 10 lookups:

```bash
# Tools to check SPF lookup count
dig +short TXT example.com
# Manual count or use online tools
```

For strategies to reduce DNS lookup count through IP consolidation and other optimization techniques, see [Advanced SPF Architecture Patterns](spf-advanced-patterns.md#performance-optimization).

#### Advanced SPF Architectures

For complex multi-domain or enterprise SPF architectures, see the comprehensive guide: [Advanced SPF Architecture Patterns](spf-advanced-patterns.md).

This advanced guide covers:

- **Redirect vs Include Decision Matrix** - Detailed comparison and use cases
- **Enterprise Architecture Patterns** - Multi-domain, multi-region, multi-team structures
- **Performance Optimization** - IP consolidation, DNS lookup reduction strategies
- **Migration Patterns** - Step-by-step guides for restructuring SPF records
- **Troubleshooting Complex SPF** - DNS lookup counting, circular redirects, and more

#### Avoid ptr Mechanism

The `ptr` mechanism is deprecated due to performance and reliability issues:

```text
# Avoid this
v=spf1 ptr:example.com -all

# Use explicit mechanisms instead
v=spf1 ip4:192.0.2.0/24 -all
```

### SPF Testing and Validation

Thorough testing ensures your SPF configuration works correctly before deployment and helps identify issues in production.

#### Command-Line Testing

**Basic SPF Query:**

```bash
# Query SPF record
dig +short TXT example.com

# Expected output
"v=spf1 mx include:_spf.google.com -all"
```

**Detailed DNS Queries:**

```bash
# Query specific DNS server
dig @8.8.8.8 TXT example.com

# Verbose output with full trace
dig TXT example.com +trace

# Check for multiple TXT records
dig TXT example.com +short | grep -i spf
```

**Validate Included Records:**

```bash
# Check included SPF records
dig +short TXT _spf.google.com

# Verify MX records referenced in SPF
dig +short MX example.com

# Check A records
dig +short A mail.example.com
```

#### Practical Testing Scenarios

##### Scenario 1: Test from Known Good IP

```bash
# 1. Identify your mail server IP
dig +short A mail.example.com
# Output: 192.0.2.10

# 2. Verify this IP is in your SPF record
dig +short TXT example.com
# Output: "v=spf1 ip4:192.0.2.0/24 -all"

# 3. Send test email and verify headers
echo "SPF Test from authorized server" | mail -s "SPF Test" test@gmail.com
```

##### Scenario 2: Verify Third-Party Service**

```bash
# 1. Check your SPF includes third-party
dig +short TXT example.com
# Output: "v=spf1 include:_spf.google.com -all"

# 2. Verify third-party SPF exists
dig +short TXT _spf.google.com
# Output: "v=spf1 include:_netblocks.google.com ..."

# 3. Send test via Google Workspace
# Use Google Workspace webmail to send test message
```

##### Scenario 3: Test SPF Failures

```bash
# Send from unauthorized server (for testing only)
# This should result in SPF fail

# Check resulting authentication headers
# Look for: spf=fail or spf=softfail
```

#### Automated Testing Script

```bash
#!/bin/bash
# SPF Validation Test Script

DOMAIN=$1
TEST_EMAIL=$2

if [ -z "$DOMAIN" ] || [ -z "$TEST_EMAIL" ]; then
    echo "Usage: $0 <domain> <test-email>"
    exit 1
fi

echo "===== SPF Testing for $DOMAIN ====="
echo

# 1. Check SPF record exists
echo "1. Checking SPF record..."
SPF_RECORD=$(dig +short TXT $DOMAIN | grep "v=spf1")
if [ -z "$SPF_RECORD" ]; then
    echo "ERROR: No SPF record found!"
    exit 1
fi
echo "SPF Record: $SPF_RECORD"
echo

# 2. Count DNS lookups
echo "2. Counting DNS lookups..."
INCLUDES=$(echo $SPF_RECORD | grep -o "include:[^ ]*" | wc -l)
MX_COUNT=$(echo $SPF_RECORD | grep -o "\\bmx\\b" | wc -l)
A_COUNT=$(echo $SPF_RECORD | grep -o " a\\b\\|a:" | wc -l)

echo "Includes: $INCLUDES"
echo "MX mechanisms: $MX_COUNT"
echo "A mechanisms: $A_COUNT"
TOTAL=$((INCLUDES + MX_COUNT + A_COUNT))
echo "Estimated total lookups: $TOTAL"

if [ $TOTAL -gt 10 ]; then
    echo "WARNING: May exceed 10 lookup limit!"
fi
echo

# 3. Check record length
echo "3. Checking record length..."
LENGTH=${#SPF_RECORD}
echo "Record length: $LENGTH characters"
if [ $LENGTH -gt 255 ]; then
    echo "WARNING: Record exceeds 255 character soft limit"
fi
echo

# 4. Send test email
echo "4. Sending test email to $TEST_EMAIL..."
echo "SPF test from $DOMAIN at $(date)" | mail -s "SPF Test - $DOMAIN" $TEST_EMAIL
echo "Test email sent. Check authentication headers in received message."
echo

echo "===== Test Complete ====="
echo "Review received email headers for:"
echo "  Authentication-Results: ... spf=pass ..."
```

#### Online SPF Validators

Use these tools for comprehensive validation:

**MXToolbox SPF Record Check:**

- URL: <https://mxtoolbox.com/spf.aspx>
- Features: Syntax validation, DNS lookup counting, error detection
- Shows: All mechanisms, includes, and potential issues

**Kitterman SPF Validator:**

- URL: <https://www.kitterman.com/spf/validate.html>
- Features: Record syntax checking, policy simulation
- Test: Specific IP addresses against your SPF record

**DMARC Analyzer SPF Check:**

- URL: <https://www.dmarcanalyzer.com/spf/checker/>
- Features: Comprehensive analysis, recommendations
- Reports: DNS lookup count, syntax errors, best practices

**What These Tools Check:**

- ✅ Syntax correctness
- ✅ DNS lookup count (must be ≤10)
- ✅ Nested includes and their impact
- ✅ Record length
- ✅ Common misconfigurations
- ✅ Qualifier usage (-, ~, +, ?)
- ✅ Mechanism ordering
- ✅ Proper termination (all mechanism)

#### Email Header Analysis

After sending test emails, examine the authentication headers:

**Successful SPF Pass:**

```text
Authentication-Results: mx.google.com;
  spf=pass (google.com: domain of sender@example.com designates 192.0.2.10 as permitted sender)
  smtp.mailfrom=sender@example.com
  smtp.helo=mail.example.com
```

**SPF Failure:**

```text
Authentication-Results: mx.gmail.com;
  spf=fail (google.com: domain of example.com does not designate 203.0.113.50 as permitted sender)
  smtp.mailfrom=sender@example.com
```

**SPF SoftFail:**

```text
Authentication-Results: mx.outlook.com;
  spf=softfail (sender IP is 198.51.100.25)
  smtp.mailfrom=sender@example.com
```

**What to Look For:**

- `spf=pass` - Configuration working correctly
- `spf=fail` - Sending server not authorized
- `spf=softfail` - Using ~all, sender probably unauthorized
- `spf=neutral` - No policy assertion (using ?all)
- `spf=none` - No SPF record found
- `spf=temperror` - Temporary DNS failure
- `spf=permerror` - SPF record syntax error or too many lookups

#### Testing Checklist

Before deploying SPF to production, verify:

- [ ] SPF record exists and is syntactically correct
- [ ] DNS lookup count is under 10
- [ ] Record length is under 255 characters
- [ ] All mail servers are authorized (mx, ip4/ip6, include)
- [ ] Third-party services included correctly
- [ ] Test emails pass from all sending sources
- [ ] Headers show `spf=pass` for legitimate email
- [ ] Policy (-all vs ~all) is appropriate for current stage
- [ ] Subdomain SPF records configured
- [ ] Monitoring is in place for SPF failures

### SPF Troubleshooting Guide

Common SPF problems and their solutions.

#### Troubleshooting Workflow

```text
┌─────────────────────┐
│  Email not          │
│  delivered or       │
│  marked as spam     │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Check email        │
│  headers for SPF    │
│  result             │
└──────┬──────────────┘
       │
       ├─── spf=pass ────► SPF OK, check other factors (DKIM, DMARC)
       │
       ├─── spf=fail ────► Sending IP not authorized
       │                   └─► Add IP to SPF or use include
       │
       ├─── spf=softfail ► Using ~all, consider upgrading to -all
       │
       ├─── spf=permerror ► Syntax error or too many DNS lookups
       │                   └─► Validate syntax, count lookups
       │
       ├─── spf=temperror ► DNS issue, retry
       │
       └─── spf=none ────► No SPF record found
                           └─► Create SPF record
```

#### Problem: SPF PermError

**Symptoms:**

- Email rejected or marked as spam
- Headers show `spf=permerror`
- Log messages indicate SPF processing error

**Common Causes:**

1. **Too many DNS lookups (>10)**

   ```bash
   # Count your lookups
   dig +short TXT example.com | grep -o "include:" | wc -l
   ```

   **Solution:** Consolidate using IP addresses or redirect

   ```text
   # Before (12 lookups)
   v=spf1 include:vendor1.com include:vendor2.com include:vendor3.com mx a:mail1.example.com a:mail2.example.com -all

   # After (3 lookups)
   v=spf1 ip4:192.0.2.0/24 include:vendor1.com mx -all
   ```

2. **Syntax error in SPF record**

   ```text
   # Wrong - missing space after mechanism
   v=spf1 ip4:192.0.2.0/24include:_spf.google.com -all

   # Correct
   v=spf1 ip4:192.0.2.0/24 include:_spf.google.com -all
   ```

3. **Invalid mechanism format**

   ```text
   # Wrong - invalid CIDR notation
   v=spf1 ip4:192.0.2.0/35 -all

   # Correct
   v=spf1 ip4:192.0.2.0/24 -all
   ```

#### Problem: SPF Fail from Legitimate Source

**Symptoms:**

- Legitimate email rejected or quarantined
- Headers show `spf=fail`
- Sending IP not in SPF record

**Diagnosis:**

```bash
# 1. Identify sending IP from headers
# Look for: Received: from mail.example.com [192.0.2.50]

# 2. Check if IP is in SPF record
dig +short TXT example.com
```

**Solutions:**

1. **Add missing IP address:**

   ```text
   # Before
   v=spf1 ip4:192.0.2.0/24 -all

   # After
   v=spf1 ip4:192.0.2.0/24 ip4:192.0.2.50 -all
   ```

2. **Add missing third-party service:**

   ```text
   # Before
   v=spf1 mx -all

   # After - added SendGrid
   v=spf1 mx include:sendgrid.net -all
   ```

3. **Expand IP range:**

   ```text
   # Before - only /28 (16 IPs)
   v=spf1 ip4:192.0.2.0/28 -all

   # After - /24 (256 IPs)
   v=spf1 ip4:192.0.2.0/24 -all
   ```

#### Problem: Email Forwarding Breaks SPF

**Symptoms:**

- Forwarded emails fail SPF
- Original SPF-passing message now shows `spf=fail`
- Forwarding server's IP not in original domain's SPF

**Explanation:**

```text
1. alice@example.com sends to bob@forwarder.com  [SPF PASS]
2. bob@forwarder.com forwards to charlie@gmail.com
3. Gmail sees forwarder's IP, not example.com's IP  [SPF FAIL]
```

**Solutions:**

1. **Implement SRS (Sender Rewriting Scheme) on forwarding server**
   - Rewrites envelope sender to forwarding domain
   - Preserves original sender in headers

2. **Use DKIM instead of relying solely on SPF**
   - DKIM signatures survive forwarding
   - DMARC can pass with DKIM alone

3. **Add forwarder's IP to SPF (if you control it)**

   ```text
   v=spf1 mx ip4:203.0.113.50 -all  # forwarding server
   ```

#### Problem: Subdomain Email Failing

**Symptoms:**

- Email from `subdomain@sub.example.com` fails SPF
- Main domain SPF works fine
- Headers show `spf=none` for subdomain

**Diagnosis:**

```bash
# Check if subdomain has SPF record
dig +short TXT sub.example.com | grep spf
```

**Solution:**

Subdomains don't inherit parent SPF. Create explicit record:

```text
# Parent domain
example.com. IN TXT "v=spf1 mx -all"

# Subdomain needs its own SPF
sub.example.com. IN TXT "v=spf1 include:_spf.example.com -all"

# Or prevent subdomain email entirely
*.example.com. IN TXT "v=spf1 -all"
```

#### Problem: Third-Party Service Suddenly Failing

**Symptoms:**

- Previously working third-party service now fails SPF
- No changes made to your SPF record
- Service provider may have changed IPs

**Diagnosis:**

```bash
# Check if include still resolves
dig +short TXT _spf.provider.com

# Verify your record still includes it
dig +short TXT example.com
```

**Solutions:**

1. **Verify include is still in your SPF:**

   ```text
   v=spf1 mx include:_spf.provider.com -all
   ```

2. **Contact service provider for updated SPF include**

3. **Check provider's documentation for SPF changes**

#### Problem: Gmail/Yahoo Rejecting Email

**Symptoms:**

- Specific providers (Gmail, Yahoo) reject email
- Other providers accept same email
- May see "550 SPF check failed" errors

**Diagnosis:**

```bash
# Test SPF from recipient's perspective
# Use online validators with target provider selection

# Send test specifically to Gmail/Yahoo
echo "Test" | mail -s "SPF Test" yourtest@gmail.com
```

**Solutions:**

1. **Ensure hard fail (-all) is used:**

   ```text
   # Weak - some providers may reject ~all
   v=spf1 mx include:_spf.google.com ~all

   # Strong - use -all for major providers
   v=spf1 mx include:_spf.google.com -all
   ```

2. **Add all sending sources these providers see:**
   - Application servers
   - Marketing platforms
   - Ticketing systems
   - Any automated email senders

3. **Implement DKIM and DMARC:**
   - Gmail and Yahoo increasingly require all three
   - SPF alone may not be sufficient

#### Troubleshooting Commands Reference

```bash
# Check SPF record
dig +short TXT example.com | grep spf

# Trace DNS resolution
dig TXT example.com +trace

# Check from specific DNS server
dig @8.8.8.8 TXT example.com

# Count include mechanisms
dig +short TXT example.com | grep -o "include:" | wc -l

# Verify included record
dig +short TXT _spf.google.com

# Check MX records referenced in SPF
dig +short MX example.com

# Test with SPF testing service
curl "https://vamsoft.com/support/tools/spf-syntax-validator?domain=example.com"

# Send test email
echo "Test" | mail -s "SPF Test" test@example.com

# Monitor mail logs for SPF results (varies by mail server)
tail -f /var/log/mail.log | grep -i spf
```

### SPF Migration Checklist

Use this checklist when implementing or updating SPF records.

#### Pre-Implementation Phase

**Inventory Current State:**

- [ ] Document all current email sending sources
  - [ ] Corporate mail servers (IPs/hostnames)
  - [ ] Marketing platforms (Mailchimp, SendGrid, etc.)
  - [ ] CRM systems (Salesforce, HubSpot)
  - [ ] Help desk/ticketing systems (Zendesk, Freshdesk)
  - [ ] Transactional email services
  - [ ] Application servers sending email
  - [ ] Third-party services sending on your behalf

- [ ] Check existing SPF record (if any)
  - [ ] Current syntax and mechanisms
  - [ ] DNS lookup count
  - [ ] Current policy (-all, ~all, ?all)

- [ ] Identify all domains and subdomains sending email
  - [ ] Main domain
  - [ ] Marketing subdomains
  - [ ] Regional subdomains
  - [ ] Application subdomains

**Planning:**

- [ ] Design SPF record structure
  - [ ] Decide on flat vs modular approach
  - [ ] Plan use of include for third-parties
  - [ ] Consider redirect for multi-domain organizations

- [ ] Calculate DNS lookup budget
  - [ ] Count all includes
  - [ ] Count all mx and a mechanisms
  - [ ] Ensure total ≤ 10 lookups

- [ ] Determine rollout strategy
  - [ ] Start with soft fail (~all)
  - [ ] Set monitoring period (2-4 weeks)
  - [ ] Plan upgrade to hard fail (-all)

#### Implementation Phase

**Week 1: Initial Deployment with Soft Fail:**

- [ ] Create SPF record with all known sources
- [ ] Use soft fail policy (~all) for safety
- [ ] Set low DNS TTL (300-3600 seconds) for easy changes

**Example initial record:**

```text
example.com. 3600 IN TXT "v=spf1 mx include:_spf.google.com include:sendgrid.net ip4:192.0.2.0/24 ~all"
```

- [ ] Deploy to DNS
- [ ] Verify propagation with `dig +short TXT example.com`
- [ ] Test from known good sources
- [ ] Document deployment date and configuration

**Week 2-3: Monitoring Period:**

- [ ] Send test emails from all sources
- [ ] Monitor email headers for SPF results
  - [ ] Check for `spf=pass` from all legitimate sources
  - [ ] Identify any `spf=fail` from authorized senders

- [ ] Review email delivery reports
  - [ ] Check for increased spam classifications
  - [ ] Monitor bounce rates
  - [ ] Review user complaints

- [ ] Identify missing sources
  - [ ] Add any discovered senders to SPF
  - [ ] Update DNS record as needed

- [ ] Validate DNS lookup count remains ≤ 10

**Week 4: Upgrade to Hard Fail:**

- [ ] Verify all legitimate sources pass SPF
- [ ] Change from soft fail to hard fail
- [ ] Increase DNS TTL to normal (43200-86400 seconds)

**Final record:**

```text
example.com. 86400 IN TXT "v=spf1 mx include:_spf.google.com include:sendgrid.net ip4:192.0.2.0/24 -all"
```

- [ ] Monitor for 1 week after upgrade
- [ ] Document final configuration
- [ ] Update runbooks and documentation

#### Post-Implementation Phase

**Ongoing Maintenance:**

- [ ] Schedule quarterly SPF audits
- [ ] Review and update sending sources
- [ ] Monitor DNS lookup count
- [ ] Test SPF regularly
- [ ] Document all changes

**When Adding New Services:**

- [ ] Get SPF include or IP ranges from vendor
- [ ] Test in non-production if possible
- [ ] Add to SPF record
- [ ] Verify DNS propagation
- [ ] Send test emails
- [ ] Monitor for issues

**Example service addition:**

```text
# Before
v=spf1 mx include:_spf.google.com -all

# After adding SendGrid
v=spf1 mx include:_spf.google.com include:sendgrid.net -all
```

#### Subdomain Implementation Checklist

- [ ] Identify all subdomains sending email
- [ ] Create SPF records for each
- [ ] Create wildcard record for non-sending subdomains

**Example subdomain configuration:**

```text
# Main domain
example.com. IN TXT "v=spf1 mx -all"

# Marketing subdomain (uses SendGrid)
marketing.example.com. IN TXT "v=spf1 include:sendgrid.net -all"

# Application subdomain (uses specific IPs)
app.example.com. IN TXT "v=spf1 ip4:192.0.2.100/28 -all"

# Prevent spoofing of all other subdomains
*.example.com. IN TXT "v=spf1 -all"
```

#### Multi-Domain Migration Checklist

For organizations with multiple domains:

- [ ] Assess if domains share infrastructure
- [ ] Consider redirect pattern for centralized management
- [ ] Create shared SPF record
- [ ] Configure each domain to redirect

**Example multi-domain setup:**

```text
# All domains redirect to shared SPF
brand1.com. IN TXT "v=spf1 redirect=_spf.company.com"
brand2.com. IN TXT "v=spf1 redirect=_spf.company.com"
brand3.com. IN TXT "v=spf1 redirect=_spf.company.com"

# Shared SPF record
_spf.company.com. IN TXT "v=spf1 mx include:_spf.google.com include:sendgrid.net -all"
```

- [ ] Deploy shared record first
- [ ] Test with one domain
- [ ] Roll out to remaining domains
- [ ] Update DNS TTL after stabilization

#### Troubleshooting During Migration

If issues arise:

- [ ] Revert to soft fail (~all) if needed
- [ ] Reduce DNS TTL for faster propagation
- [ ] Add missing sources immediately
- [ ] Communicate with affected users
- [ ] Document the issue and resolution

#### Validation Checklist

Before considering migration complete:

- [ ] All domains have SPF records
- [ ] All subdomains configured
- [ ] Hard fail (-all) implemented
- [ ] DNS lookup count ≤ 10
- [ ] Test emails pass from all sources
- [ ] Third-party services working
- [ ] DMARC reports show SPF passing
- [ ] Documentation updated
- [ ] Team trained on SPF management
- [ ] Monitoring alerts configured

### SPF Quick Reference Card

```text
┌─────────────────────────────────────────────────────────┐
│ SPF QUICK REFERENCE                                      │
├─────────────────────────────────────────────────────────┤
│ Basic Syntax:                                            │
│   v=spf1 [mechanisms] [qualifier]all                     │
│                                                           │
│ Common Mechanisms:                                        │
│   ip4:192.0.2.0/24        IPv4 address/range            │
│   ip6:2001:db8::/32       IPv6 address/range            │
│   mx                      Domain's MX records            │
│   a:mail.example.com      A record lookup                │
│   include:_spf.vendor.com Include another SPF            │
│                                                           │
│ Qualifiers:                                               │
│   +  Pass (default)                                       │
│   -  Fail (hard fail)                                     │
│   ~  SoftFail                                             │
│   ?  Neutral                                              │
│                                                           │
│ Modifiers:                                                │
│   redirect=_spf.example.com  Replace SPF record          │
│   exp=explain.example.com    Failure explanation         │
│                                                           │
│ Limits:                                                   │
│   - Maximum 10 DNS lookups                                │
│   - 255 character soft limit per string                   │
│                                                           │
│ Best Practices:                                           │
│   ✓ Start with ~all (soft fail)                          │
│   ✓ Monitor for 2-4 weeks                                 │
│   ✓ Upgrade to -all (hard fail)                          │
│   ✓ Use include for third-parties                         │
│   ✓ Document all changes                                  │
│                                                           │
│ Testing Commands:                                         │
│   dig +short TXT example.com                              │
│   dig @8.8.8.8 TXT example.com                            │
│                                                           │
│ Common Records:                                           │
│   Simple: v=spf1 mx -all                                  │
│   Google: v=spf1 include:_spf.google.com -all             │
│   Complex: v=spf1 mx include:_spf.google.com \           │
│            ip4:192.0.2.0/24 -all                          │
└─────────────────────────────────────────────────────────┘
```

## DKIM (DomainKeys Identified Mail)

DKIM implementation guide coming soon. DKIM provides cryptographic authentication of email messages, ensuring message integrity and sender verification.

Key topics to be covered:

- DKIM Architecture and Overview
- Key Generation and Management
- DKIM-Signature Headers
- DNS TXT Record Configuration
- DKIM Signing Process
- DKIM Verification
- Key Rotation Best Practices
- Troubleshooting DKIM Issues

## DMARC (Domain-based Message Authentication, Reporting & Conformance)

DMARC implementation guide coming soon. DMARC builds on SPF and DKIM to provide policy enforcement and reporting.

Key topics to be covered:

- DMARC Policy Overview
- Creating DMARC Records
- DMARC Policies (none, quarantine, reject)
- Alignment Requirements (SPF and DKIM)
- DMARC Reporting (RUA and RUF)
- Gradual DMARC Deployment Strategy
- Analyzing DMARC Reports
- DMARC for Subdomains

## Getting Started

Before implementing email authentication, ensure you have:

1. **DNS Access** - Ability to create and modify TXT records
2. **Mail Server Access** - Configuration rights for DKIM signing
3. **Monitoring Tools** - For DMARC report analysis
4. **Testing Environment** - Validate configurations before production
5. **Documentation** - Track all sending sources and configurations

## Implementation Roadmap

### Phase 1: SPF (Week 1-4)

- Inventory all sending sources
- Create SPF record with soft fail (~all)
- Monitor and test for 2-4 weeks
- Upgrade to hard fail (-all)

### Phase 2: DKIM (Week 5-8)

- Generate DKIM keys
- Configure mail servers for signing
- Publish DKIM DNS records
- Verify DKIM signatures in headers

### Phase 3: DMARC (Week 9-12)

- Start with p=none policy
- Monitor DMARC reports
- Identify and fix failing sources
- Gradually increase policy to quarantine, then reject

### Phase 4: Optimization (Ongoing)

- Review DMARC reports monthly
- Rotate DKIM keys annually
- Audit SPF records quarterly
- Update documentation

## Quick Reference

### SPF Record Example

```text
v=spf1 ip4:192.0.2.0/24 include:_spf.google.com -all
```

### DKIM DNS Record Example

```text
default._domainkey.example.com IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA..."
```

### DMARC Record Example

```text
_dmarc.example.com IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com; pct=100"
```

## Authentication Flow

Complete email authentication flow:

1. **Sender Prepares** - Mail server prepares message with proper headers
2. **DKIM Signing** - Server signs message with private key
3. **Message Sent** - Email transmitted with SPF and DKIM data
4. **SPF Check** - Receiving server queries DNS for authorized senders
5. **DKIM Verification** - Receiving server verifies signature using public key
6. **DMARC Evaluation** - Server checks DMARC policy and alignment
7. **Policy Action** - Deliver, quarantine, or reject based on policy
8. **DMARC Reporting** - Reports sent to domain owner

## Best Practices Summary

### SPF Configuration Best Practices

- Start with soft fail (~all), upgrade to hard fail (-all)
- Keep DNS lookups under 10
- Use include for third-party services
- Document all sending sources
- Implement for all domains and subdomains

### DKIM Configuration Best Practices

- Use 2048-bit keys minimum
- Sign all outgoing mail
- Include key rotation schedule
- Monitor signature verification
- Sign important headers

### DMARC Best Practices

- Start with p=none for monitoring
- Implement SPF and DKIM first
- Monitor reports regularly
- Gradually increase policy strictness
- Use subdomain policies for granular control

### General Best Practices

- Document all configurations
- Monitor authentication results
- Test before deploying changes
- Train team on email authentication
- Review and update quarterly

## Troubleshooting Resources

- [Advanced SPF Architecture Patterns](spf-advanced-patterns.md) - Complex SPF configurations
- [SPF Testing Tools](#spf-testing-and-validation) - Validators and test commands
- [Troubleshooting Guide](#spf-troubleshooting-guide) - Common problems and solutions
- [Migration Checklist](#spf-migration-checklist) - Step-by-step implementation guide

## External Resources

### Specifications

- [RFC 7208: SPF Specification](https://www.rfc-editor.org/rfc/rfc7208)
- [RFC 6376: DKIM Specification](https://www.rfc-editor.org/rfc/rfc6376)
- [RFC 7489: DMARC Specification](https://www.rfc-editor.org/rfc/rfc7489)

### Tools and Services

- [MXToolbox](https://mxtoolbox.com/) - Comprehensive email testing tools
- [Kitterman SPF Validator](https://www.kitterman.com/spf/validate.html) - SPF testing
- [DMARC.org](https://dmarc.org/) - DMARC resources and documentation
- [Google Postmaster Tools](https://postmaster.google.com/) - Gmail delivery insights

### Learning Resources

- [DMARC Guide](https://dmarc.org/overview/) - Complete DMARC implementation guide
- [Email Authentication Best Practices](https://www.m3aawg.org/) - Industry best practices
- [Anti-Phishing Working Group](https://apwg.org/) - Phishing prevention resources

## Related Topics

- [SMTP Protocol](index.md) - Understanding SMTP fundamentals
- [Exchange](../exchange/index.md) - Microsoft Exchange configuration
- [Email Security](../../../security/networking/index.md) - Network and email security topics

## Glossary

**SPF (Sender Policy Framework)** - Email authentication method that validates authorized sending servers

**DKIM (DomainKeys Identified Mail)** - Cryptographic authentication that signs email messages

**DMARC (Domain-based Message Authentication, Reporting & Conformance)** - Policy framework building on SPF and DKIM

**DNS (Domain Name System)** - System that stores email authentication records

**Envelope Sender** - Return-path address used in SMTP transaction (checked by SPF)

**Hard Fail** - SPF policy (-all) that explicitly fails unauthorized senders

**Soft Fail** - SPF policy (~all) that marks but doesn't reject unauthorized senders

**DNS Lookup** - Query to DNS server (SPF limited to 10 per validation)

**Include Mechanism** - SPF mechanism that references another domain's SPF record

**Redirect Modifier** - SPF modifier that replaces entire SPF record with another domain's

**CIDR Notation** - IP address range notation (e.g., 192.0.2.0/24)

**Alignment** - DMARC requirement that SPF/DKIM domain matches From header domain
