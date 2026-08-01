---
title: "DMARC Reports and Analysis"
description: "Aggregate and forensic DMARC reports, and how to read them to find unauthenticated sources"
author: "Joseph Streeter"
tags: ["email", "authentication", "dmarc", "reporting", "rua", "analysis"]
category: "services"
last_updated: "2026-08-01"
---
## DMARC Reports

Reporting is the part of DMARC that earns its keep — it tells you who is sending as
your domain before you start rejecting anything.

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
