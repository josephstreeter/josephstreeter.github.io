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
│ SPF QUICK REFERENCE                                     │
├─────────────────────────────────────────────────────────┤
│ Basic Syntax:                                           │
│   v=spf1 [mechanisms] [qualifier]all                    │
│                                                         │
│ Common Mechanisms:                                      │
│   ip4:192.0.2.0/24        IPv4 address/range            │
│   ip6:2001:db8::/32       IPv6 address/range            │
│   mx                      Domain's MX records           │
│   a:mail.example.com      A record lookup               │
│   include:_spf.vendor.com Include another SPF           │
│                                                         │
│ Qualifiers:                                             │
│   +  Pass (default)                                     │
│   -  Fail (hard fail)                                   │
│   ~  SoftFail                                           │
│   ?  Neutral                                            │
│                                                         │
│ Modifiers:                                              │
│   redirect=_spf.example.com  Replace SPF record         │
│   exp=explain.example.com    Failure explanation        │
│                                                         │
│ Limits:                                                 │
│   - Maximum 10 DNS lookups                              │
│   - 255 character soft limit per string                 │
│                                                         │
│ Best Practices:                                         │
│   ✓ Start with ~all (soft fail)                         │
│   ✓ Monitor for 2-4 weeks                               │
│   ✓ Upgrade to -all (hard fail)                         │
│   ✓ Use include for third-parties                       │
│   ✓ Document all changes                                │
│                                                         │
│ Testing Commands:                                       │
│   dig +short TXT example.com                            │
│   dig @8.8.8.8 TXT example.com                          │
│                                                         │
│ Common Records:                                         │
│   Simple: v=spf1 mx -all                                │
│   Google: v=spf1 include:_spf.google.com -all           │
│   Complex: v=spf1 mx include:_spf.google.com \          │
│            ip4:192.0.2.0/24 -all                        │
└─────────────────────────────────────────────────────────┘
```

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

## DMARC (Domain-based Message Authentication, Reporting & Conformance)

### DMARC Overview

DMARC, defined in RFC 7489, builds upon SPF and DKIM by adding a policy framework and reporting mechanism. It tells receiving mail servers what to do when SPF or DKIM authentication fails and provides feedback to domain owners about authentication results and potential abuse.

DMARC solves three key problems:

1. **Policy enforcement** - Specify how receivers should handle authentication failures
2. **Alignment verification** - Ensure From header matches authenticated domain
3. **Visibility** - Receive reports about who is sending email from your domain

### How DMARC Works

DMARC evaluation process:

1. **Receiving server** gets email claiming to be from example.com
2. **SPF check** performed on envelope sender
3. **DKIM check** performed on signature
4. **DMARC query** retrieves policy from `_dmarc.example.com`
5. **Alignment check** verifies From domain matches SPF/DKIM domain
6. **Policy applied** based on DMARC record (none, quarantine, reject)
7. **Report generated** sent to address specified in DMARC record
8. **Action taken** - deliver, quarantine, or reject message

DMARC requires at least one authentication method (SPF or DKIM) to pass **and** be aligned with the From header domain.

### DMARC Record Syntax

DMARC records are published as DNS TXT records at:

```text
_dmarc.[domain]
```

**Basic format:**

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=none; rua=mailto:dmarc@example.com"
```

#### DMARC Tags

| Tag | Description | Required | Example |
| --- | --- | --- | --- |
| `v` | DMARC version | Yes | `v=DMARC1` |
| `p` | Policy for domain | Yes | `p=none`, `p=quarantine`, or `p=reject` |
| `sp` | Policy for subdomains | No | `sp=quarantine` |
| `rua` | Aggregate report email | No | `rua=mailto:dmarc@example.com` |
| `ruf` | Forensic report email | No | `ruf=mailto:forensic@example.com` |
| `pct` | Percentage of emails policy applies to | No | `pct=100` (default) |
| `adkim` | DKIM alignment mode | No | `adkim=r` (relaxed) or `adkim=s` (strict) |
| `aspf` | SPF alignment mode | No | `aspf=r` (relaxed) or `aspf=s` (strict) |
| `rf` | Forensic report format | No | `rf=afrf` (default) |
| `ri` | Report interval (seconds) | No | `ri=86400` (24 hours) |
| `fo` | Forensic report options | No | `fo=0`, `fo=1`, `fo=d`, or `fo=s` |

#### DMARC Policies

| Policy | Description | Action | Use Case |
| --- | --- | --- | --- |
| `p=none` | Monitor only | Deliver all mail | Initial deployment, monitoring |
| `p=quarantine` | Suspicious | Mark as spam/junk | Intermediate enforcement |
| `p=reject` | Reject failures | Reject at SMTP | Full enforcement |

### DMARC Alignment

DMARC introduces the concept of "identifier alignment" - the From header domain must align with the authenticated domain from SPF or DKIM.

#### SPF Alignment

**Relaxed alignment (default):**

Organizational domains must match:

```text
From: user@mail.example.com
SPF authenticates: mail.example.com
Result: PASS (example.com matches)
```

**Strict alignment:**

Exact domain match required:

```text
From: user@mail.example.com
SPF authenticates: mail.example.com
Result: PASS (exact match)

From: user@mail.example.com
SPF authenticates: example.com
Result: FAIL (not exact match)
```

#### DKIM Alignment

**Relaxed alignment (default):**

Organizational domains must match:

```text
From: user@example.com
DKIM d=: mail.example.com
Result: PASS (example.com matches)
```

**Strict alignment:**

Exact domain match required:

```text
From: user@example.com
DKIM d=: example.com
Result: PASS (exact match)

From: user@example.com
DKIM d=: mail.example.com
Result: FAIL (not exact match)
```

#### Alignment Configuration

```text
# Relaxed alignment (default, recommended)
v=DMARC1; p=quarantine; adkim=r; aspf=r; rua=mailto:dmarc@example.com

# Strict alignment (more restrictive)
v=DMARC1; p=quarantine; adkim=s; aspf=s; rua=mailto:dmarc@example.com

# Mixed (DKIM strict, SPF relaxed)
v=DMARC1; p=quarantine; adkim=s; aspf=r; rua=mailto:dmarc@example.com
```

**Recommendation:** Start with relaxed alignment (`adkim=r; aspf=r`) for easier deployment.

### Creating DMARC Records

#### Phase 1: Monitoring (p=none)

Start with monitoring-only policy to understand email landscape:

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com; ruf=mailto:dmarc-forensic@example.com; pct=100"
```

**Explanation:**

- `v=DMARC1` - DMARC version 1
- `p=none` - Monitor only, don't enforce policy
- `rua=mailto:...` - Send aggregate reports daily
- `ruf=mailto:...` - Send forensic (failure) reports
- `pct=100` - Apply to 100% of email

**Duration:** 2-4 weeks minimum, monitor reports

#### Phase 2: Quarantine (p=quarantine)

After reviewing reports and fixing issues:

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=quarantine; pct=10; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r"
```

**Gradual rollout:**

```text
# Week 1: 10% enforcement
pct=10

# Week 2: 25% enforcement
pct=25

# Week 3: 50% enforcement
pct=50

# Week 4: 100% enforcement
pct=100
```

**Final quarantine policy:**

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r"
```

**Duration:** 4-8 weeks with gradual pct increase

#### Phase 3: Reject (p=reject)

Full enforcement - failed emails rejected:

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=reject; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r"
```

**Best practice:** Monitor quarantine phase for several months before moving to reject.

#### Subdomain Policy

Configure separate policy for subdomains:

```text
# Main domain rejects failures
_dmarc.example.com. IN TXT "v=DMARC1; p=reject; sp=quarantine; rua=mailto:dmarc@example.com"
```

**Explanation:**

- `p=reject` - Main domain emails that fail are rejected
- `sp=quarantine` - Subdomain emails that fail are quarantined
- Allows more lenient policy for subdomains during migration

#### Multiple Reporting Addresses

Send reports to multiple destinations:

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com,mailto:dmarc@monitoring.com; ruf=mailto:security@example.com"
```

Can also use HTTPS endpoints:

```text
rua=https://dmarc.example.com/reports
```

### DMARC Reports

DMARC provides two types of reports:

#### Aggregate Reports (RUA)

**Format:** XML files sent daily (typically)

**Contains:**

- Summary of authentication results
- Volume of emails by source IP
- SPF and DKIM authentication results
- Policy evaluation outcomes
- Sending infrastructure information

**Example aggregate report structure:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<feedback>
  <report_metadata>
    <org_name>google.com</org_name>
    <email>noreply-dmarc-support@google.com</email>
    <report_id>12345678901234567890</report_id>
    <date_range>
      <begin>1673481600</begin>
      <end>1673567999</end>
    </date_range>
  </report_metadata>
  <policy_published>
    <domain>example.com</domain>
    <p>quarantine</p>
    <sp>none</sp>
    <pct>100</pct>
  </policy_published>
  <record>
    <row>
      <source_ip>192.0.2.10</source_ip>
      <count>150</count>
      <policy_evaluated>
        <disposition>none</disposition>
        <dkim>pass</dkim>
        <spf>pass</spf>
      </policy_evaluated>
    </row>
    <identifiers>
      <header_from>example.com</header_from>
    </identifiers>
    <auth_results>
      <dkim>
        <domain>example.com</domain>
        <result>pass</result>
        <selector>default</selector>
      </dkim>
      <spf>
        <domain>example.com</domain>
        <result>pass</result>
      </spf>
    </auth_results>
  </record>
</feedback>
```

**Key metrics to monitor:**

- **Pass rate** - Percentage of emails passing DMARC
- **Source IPs** - All servers sending from your domain
- **Failure reasons** - SPF fail, DKIM fail, alignment issues
- **Volume trends** - Changes in email volume by source

#### Forensic Reports (RUF)

**Format:** Individual email samples sent in real-time

**Contains:**

- Copy of failed email headers
- Authentication failure details
- Immediate notification of issues

**Warning:** Forensic reports contain email content and may have privacy implications. Many receivers don't send them due to privacy concerns.

**Configuration:**

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=quarantine; rua=mailto:aggregate@example.com; ruf=mailto:forensic@example.com; fo=1"
```

**Forensic options (fo tag):**

| Value | Meaning |
| --- | --- |
| `fo=0` | Report if all auth mechanisms fail (default) |
| `fo=1` | Report if any auth mechanism fails |
| `fo=d` | Report if DKIM fails |
| `fo=s` | Report if SPF fails |

Can combine: `fo=1:d:s`

### Analyzing DMARC Reports

#### Manual Analysis

**Extract and parse XML:**

```bash
# Extract DMARC report from email
munpack dmarc-report.eml

# Parse XML with xmllint
xmllint --format google.com\!example.com\!1673481600\!1673567999.xml

# Extract source IPs
xmllint --xpath "//record/row/source_ip/text()" report.xml

# Count passing vs failing
xmllint --xpath "//policy_evaluated/disposition" report.xml | \
  grep -o "none\|quarantine\|reject" | sort | uniq -c
```

#### DMARC Report Analyzers

**Open-source tools:**

**Parsedmarc:**

```bash
# Install parsedmarc
pip3 install parsedmarc

# Parse reports and output to console
parsedmarc -i /path/to/reports/*.xml

# Parse and store in Elasticsearch
parsedmarc -c config.ini
```

**Example parsedmarc output:**

```json
{
  "xml_schema": "1.0",
  "report_metadata": {
    "org_name": "google.com",
    "report_id": "12345678901234567890",
    "begin_date": "2024-01-12",
    "end_date": "2024-01-13"
  },
  "policy_published": {
    "domain": "example.com",
    "p": "quarantine",
    "pct": 100
  },
  "records": [
    {
      "source_ip": "192.0.2.10",
      "count": 150,
      "policy_evaluated": {
        "disposition": "none",
        "dkim": "pass",
        "spf": "pass"
      },
      "auth_results": {
        "dkim": {
          "domain": "example.com",
          "result": "pass"
        },
        "spf": {
          "domain": "example.com",
          "result": "pass"
        }
      }
    }
  ]
}
```

**Commercial DMARC services:**

- **Dmarcian** - <https://dmarcian.com/>
  - User-friendly dashboard
  - Threat intelligence
  - Guidance for compliance

- **Valimail** - <https://www.valimail.com/>
  - Automated DMARC management
  - Authentication monitoring
  - Enforcement automation

- **Agari** - <https://www.agari.com/>
  - Enterprise-grade reporting
  - Brand protection
  - Phishing detection

- **Proofpoint** - <https://www.proofpoint.com/>
  - Integrated email security
  - DMARC analytics
  - Incident response

**Self-hosted solutions:**

**DMARC Visualizer:**

Open-source web-based analyzer with visualization:

```bash
# Clone repository
git clone https://github.com/techsneeze/dmarcts-report-viewer.git
cd dmarcts-report-viewer

# Install dependencies (LAMP stack required)
# Configure database and web server
# Access via browser
```

**Features:**

- Visual dashboard
- Historical trends
- Source IP tracking
- Authentication pass/fail rates

#### Key Metrics to Track

**Pass rate:**

```text
(Emails passing DMARC / Total emails) × 100

Target: > 95%
```

**Authentication breakdown:**

- SPF pass + DKIM pass: Ideal
- SPF pass only: Vulnerable to forwarding
- DKIM pass only: More resilient
- Both fail: Spoofing or misconfiguration

**Source identification:**

- Known IPs: Corporate servers, authorized services
- Unknown IPs: Investigate - could be abuse or forgotten sources

**Policy evaluation:**

- None: Emails delivered regardless
- Quarantine: Emails marked as spam
- Reject: Emails blocked

**Trend analysis:**

- Increasing failures: Investigate new sources
- Spikes in volume: Potential abuse
- Changes in source IPs: Infrastructure changes

### DMARC Best Practices

#### Deployment Strategy

##### Phase 1: Preparation (Week 1-2)

- [ ] Ensure SPF configured correctly
- [ ] Ensure DKIM signing enabled
- [ ] Verify alignment (relaxed recommended)
- [ ] Set up reporting email address
- [ ] Document all authorized sending sources

##### Phase 2: Monitoring (Week 3-6)

- [ ] Deploy `p=none` policy
- [ ] Collect aggregate reports
- [ ] Identify all legitimate sending sources
- [ ] Fix SPF/DKIM issues discovered
- [ ] Monitor daily for 4+ weeks

##### Phase 3: Enforcement - Quarantine (Week 7-18)

- [ ] Change to `p=quarantine`
- [ ] Start with `pct=10`
- [ ] Gradually increase to `pct=100` over 4 weeks
- [ ] Monitor feedback closely
- [ ] Address any false positives immediately
- [ ] Maintain quarantine for 2-3 months minimum

##### Phase 4: Full Enforcement - Reject (Week 19+)

- [ ] Change to `p=reject`
- [ ] Optional: Start with `pct=10` again
- [ ] Gradually increase to `pct=100`
- [ ] Monitor continuously
- [ ] Document final configuration

#### Configuration Recommendations

**Standard configuration:**

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=reject; pct=100; rua=mailto:dmarc@example.com; adkim=r; aspf=r; fo=1"
```

**High-security configuration:**

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=reject; pct=100; rua=mailto:dmarc@example.com; adkim=s; aspf=s"
```

**With subdomain policy:**

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=reject; sp=quarantine; pct=100; rua=mailto:dmarc@example.com; adkim=r; aspf=r"
```

**Testing configuration:**

```text
_dmarc.example.com. IN TXT "v=DMARC1; p=none; pct=100; rua=mailto:dmarc@example.com; ruf=mailto:dmarc-forensic@example.com; fo=1"
```

#### Subdomain Considerations

**Explicit subdomain DMARC:**

```text
# Main domain
_dmarc.example.com. IN TXT "v=DMARC1; p=reject; ..."

# Subdomain with own policy
_dmarc.mail.example.com. IN TXT "v=DMARC1; p=quarantine; ..."

# Subdomain inherits parent if no specific record
_dmarc.app.example.com. [no record - inherits from example.com]
```

**Subdomain policy tag:**

```text
# Main domain reject, subdomains quarantine
_dmarc.example.com. IN TXT "v=DMARC1; p=reject; sp=quarantine; ..."
```

**Non-sending subdomains:**

```text
# Prevent subdomain abuse
_dmarc.*.example.com. IN TXT "v=DMARC1; p=reject"
```

Note: Wildcard DMARC records are supported but have mixed implementation.

#### Reporting Best Practices

- **Set up dedicated mailbox** - `dmarc-reports@example.com`
- **Implement email filtering** - DMARC reports can be high volume
- **Automate parsing** - Use tools to process XML reports
- **Set up alerting** - Notify on sudden changes or failures
- **Review weekly minimum** - During monitoring/enforcement phases
- **Archive reports** - Keep for compliance and forensics

#### Alignment Recommendations

- **Start with relaxed alignment** - `adkim=r; aspf=r`
- **Use relaxed for most organizations** - Handles subdomains and third-parties better
- **Consider strict alignment only if:**
  - Single mail infrastructure
  - No third-party senders
  - No subdomains sending email
  - Enhanced security requirements

#### Common Pitfalls to Avoid

- **Rushing to p=reject** - Take time to monitor and fix issues
- **Ignoring reports** - Reports are critical for identifying problems
- **Not documenting sources** - Maintain inventory of authorized senders
- **Forgetting subdomains** - Configure subdomain policy or explicit records
- **Missing third-party services** - Include marketing, CRM, support systems
- **No testing** - Always test with p=none first
- **Setting pct too low** - Use pct=100 unless gradual rollout needed

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

### DMARC Migration Checklist

#### Pre-Implementation Assessment

**Current State Analysis:**

- [ ] Document all domains and subdomains sending email
- [ ] Identify all email sending sources
  - [ ] Corporate mail servers
  - [ ] Marketing platforms
  - [ ] CRM systems
  - [ ] Application servers
  - [ ] Third-party services
- [ ] Verify SPF records exist for all domains
- [ ] Verify DKIM signing enabled for all sources
- [ ] Check current authentication pass rates (if available)

**Preparation:**

- [ ] Set up DMARC reporting email address
  - [ ] Create mailbox: `dmarc-reports@example.com`
  - [ ] Configure spam filtering for DMARC reports
  - [ ] Set up automated processing (parsedmarc or commercial tool)
- [ ] Document rollback plan
- [ ] Identify business-critical email flows
- [ ] Communicate plans to stakeholders
- [ ] Schedule implementation windows

#### Phase 1: Monitoring (Week 1-6)

##### Week 1: Deploy p=none

- [ ] Create DMARC record with monitoring policy

```text
_dmarc.example.com. 3600 IN TXT "v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com; ruf=mailto:dmarc-forensic@example.com; pct=100; fo=1"
```

- [ ] Verify DNS propagation

```bash
dig +short TXT _dmarc.example.com
```

- [ ] Wait for first reports (24-48 hours)

##### Week 2-3: Collect and Analyze

- [ ] Review aggregate reports daily
- [ ] Identify all sending sources
- [ ] Calculate pass rate (target > 95%)
- [ ] Document authentication failures
- [ ] Categorize failures:
  - [ ] Corporate infrastructure issues
  - [ ] Third-party service alignment
  - [ ] Unknown/unauthorized senders

##### Week 4-6: Remediate Issues

- [ ] Fix SPF records for failing sources

```text
# Add missing IPs or includes
v=spf1 mx ip4:192.0.2.100 include:_spf.service.com -all
```

- [ ] Enable DKIM signing where missing
- [ ] Configure third-party service alignment
- [ ] Resolve any authentication errors
- [ ] Achieve > 95% pass rate
- [ ] Verify pass rate stable for 2 weeks

#### Phase 2: Quarantine (Week 7-18)

##### Week 7-8: Gradual Rollout

- [ ] Update DMARC policy to quarantine with low percentage

```text
_dmarc.example.com. 3600 IN TXT "v=DMARC1; p=quarantine; pct=10; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r"
```

- [ ] Monitor for false positives daily
- [ ] Address any new issues immediately

##### Week 9-10: Increase Coverage

- [ ] Increase to 25%

```text
pct=25
```

- [ ] Continue monitoring
- [ ] Verify no legitimate email quarantined

##### Week 11-12: Further Increase

- [ ] Increase to 50%

```text
pct=50
```

- [ ] Monitor business-critical flows
- [ ] Document any patterns in failures

##### Week 13-14: Full Quarantine

- [ ] Increase to 100%

```text
_dmarc.example.com. 86400 IN TXT "v=DMARC1; p=quarantine; pct=100; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r"
```

- [ ] Increase DNS TTL to 86400 (24 hours)
- [ ] Monitor closely for 1 week

##### Week 15-18: Stabilization

- [ ] Maintain quarantine policy
- [ ] Review weekly reports
- [ ] Address any new sending sources
- [ ] Verify pass rate remains > 98%
- [ ] Document lessons learned

#### Phase 3: Reject (Week 19+)

##### Week 19-20: Gradual Reject Rollout (Optional)

- [ ] Optional: Start with low percentage

```text
_dmarc.example.com. 3600 IN TXT "v=DMARC1; p=reject; pct=10; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r"
```

- [ ] Monitor very closely
- [ ] Gradually increase pct to 100 over 2-4 weeks

##### Week 21+: Full Enforcement

- [ ] Deploy full reject policy

```text
_dmarc.example.com. 86400 IN TXT "v=DMARC1; p=reject; pct=100; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r"
```

- [ ] Monitor continuously
- [ ] Celebrate achievement!

#### Post-Implementation Maintenance

**Ongoing Monitoring:**

- [ ] Review DMARC reports weekly
- [ ] Monitor pass rates
- [ ] Investigate new failure sources
- [ ] Update documentation

**Quarterly Reviews:**

- [ ] Audit all sending sources
- [ ] Verify SPF and DKIM configurations
- [ ] Review and optimize SPF records
- [ ] Rotate DKIM keys (if due)
- [ ] Update runbooks

**When Adding New Services:**

- [ ] Configure SPF to include new service
- [ ] Enable DKIM signing
- [ ] Verify alignment
- [ ] Test before production use
- [ ] Monitor DMARC reports for new source

#### Subdomain Implementation

- [ ] Identify all subdomains sending email
- [ ] Create DMARC records for each (or use sp tag)
- [ ] Follow same phase process for each subdomain
- [ ] Consider more lenient policy for subdomains initially

```text
# Main domain reject, subdomains quarantine
_dmarc.example.com. IN TXT "v=DMARC1; p=reject; sp=quarantine; ..."

# Or explicit subdomain records
_dmarc.mail.example.com. IN TXT "v=DMARC1; p=quarantine; ..."
```

#### Rollback Procedures

**If Critical Issues Arise:**

1. **Immediate action:**

   ```bash
   # Reduce DNS TTL for fast updates
   _dmarc.example.com. 300 IN TXT "v=DMARC1; p=none; ..."
   ```

2. **Revert policy:**

   - From reject → quarantine
   - From quarantine → none
   - Or reduce pct value

3. **Communicate:**

   - Notify stakeholders
   - Document issue and resolution
   - Plan remediation

4. **Fix and retry:**

   - Address root cause
   - Return to previous phase
   - Monitor longer before advancing

#### Success Criteria

**Phase 1 Complete:**

- [ ] Pass rate > 95%
- [ ] All legitimate sources identified
- [ ] All authentication issues resolved
- [ ] Reports reviewed for minimum 4 weeks

**Phase 2 Complete:**

- [ ] Pass rate > 98%
- [ ] Quarantine at pct=100 for 2-3 months
- [ ] No false positives
- [ ] Business stakeholders comfortable

**Phase 3 Complete:**

- [ ] Reject policy deployed
- [ ] Pass rate maintained > 98%
- [ ] Continuous monitoring in place
- [ ] Documentation complete

### DMARC Quick Reference

```text
┌─────────────────────────────────────────────────────────┐
│ DMARC QUICK REFERENCE                                   │
├─────────────────────────────────────────────────────────┤
│ DNS Record Format:                                      │
│   _dmarc.[domain] IN TXT                                │
│   "v=DMARC1; p=policy; rua=mailto:..."                  │
│                                                         │
│ Policy Values:                                          │
│   p=none        Monitor only (no enforcement)           │
│   p=quarantine  Mark as spam                            │
│   p=reject      Block delivery                          │
│                                                         │
│ Essential Tags:                                         │
│   v=DMARC1      Version (required)                      │
│   p=            Policy (required)                       │
│   rua=          Aggregate reports                       │
│   ruf=          Forensic reports                        │
│   pct=          Percentage (0-100)                      │
│   adkim=        DKIM alignment (r/s)                    │
│   aspf=         SPF alignment (r/s)                     │
│   sp=           Subdomain policy                        │
│                                                         │
│ Alignment Modes:                                        │
│   adkim=r       DKIM relaxed (default, recommended)     │
│   adkim=s       DKIM strict                             │
│   aspf=r        SPF relaxed (default, recommended)      │
│   aspf=s        SPF strict                              │
│                                                         │
│ Common Configurations:                                  │
│   Monitoring:                                           │
│   v=DMARC1; p=none; rua=mailto:dmarc@example.com        │
│                                                         │
│   Quarantine:                                           │
│   v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com  │
│                                                         │
│   Reject (full enforcement):                            │
│   v=DMARC1; p=reject; rua=mailto:dmarc@example.com      │
│                                                         │
│   With subdomain policy:                                │
│   v=DMARC1; p=reject; sp=quarantine; ...                │
│                                                         │
│ Deployment Phases:                                      │
│   1. p=none (4-6 weeks) - Monitor and fix               │
│   2. p=quarantine (2-3 months) - Gradual enforcement    │
│   3. p=reject - Full protection                         │
│                                                         │
│ Testing Commands:                                       │
│   dig +short TXT _dmarc.example.com                     │
│   parsedmarc -i reports/*.xml                           │
│                                                         │
│ Report Types:                                           │
│   Aggregate (rua) - Daily XML summary                   │
│   Forensic (ruf) - Individual failure samples           │
│                                                         │
│ Success Metrics:                                        │
│   Pass rate > 95% before quarantine                     │
│   Pass rate > 98% before reject                         │
│   Continuous monitoring required                        │
└─────────────────────────────────────────────────────────┘
```

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

#### DMARC Configuration Best Practices

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
