---
title: "DMARC (Domain-based Message Authentication)"
description: "DMARC record syntax, alignment rules, and creating a policy record"
author: "Joseph Streeter"
tags: ["email", "authentication", "dmarc", "alignment", "policy", "dns"]
category: "services"
last_updated: "2026-08-01"
---
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
