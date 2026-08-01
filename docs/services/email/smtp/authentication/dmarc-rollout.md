---
title: "DMARC Policy Rollout"
description: "Phased DMARC deployment from p=none to p=reject, with a migration checklist and quick reference"
author: "Joseph Streeter"
tags: ["email", "authentication", "dmarc", "rollout", "deployment", "policy"]
category: "services"
last_updated: "2026-08-01"
---
## DMARC Policy Rollout

Moving from monitoring to enforcement is the whole point of DMARC, and also the
easiest way to start dropping legitimate mail. Do it in stages.

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
