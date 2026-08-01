---
title: "SPF Troubleshooting and Migration"
description: "Diagnosing SPF failures, a step-by-step migration checklist, and a syntax quick reference"
author: "Joseph Streeter"
tags: ["email", "authentication", "spf", "troubleshooting", "migration"]
category: "services"
last_updated: "2026-08-01"
---
## SPF Troubleshooting and Migration

What to do when SPF fails, and how to roll out or change a record without breaking
delivery.

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
