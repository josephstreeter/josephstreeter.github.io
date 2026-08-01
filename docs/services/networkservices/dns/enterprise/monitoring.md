---
title: "Monitoring and Auditing"
description: "DNS query logging, audit trails, metrics, and alerting for enterprise DNS infrastructure"
author: "Joseph Streeter"
tags: ["dns", "enterprise", "monitoring", "auditing", "logging"]
category: "services"
last_updated: "2026-08-01"
---
## Monitoring and Auditing

DNS logs are one of the highest-value telemetry sources on a network — both for
operational health and for detecting the attacks above.

### Monitoring and Auditing

Continuous monitoring detects attacks and validates security controls:

#### Query Logging and Analysis

Comprehensive logging enables threat detection and forensic analysis:

**BIND Query Logging**:

```text
logging {
    channel querylog {
        file "/var/log/named/queries.log" versions 5 size 50m;
        severity info;
        print-time yes;
        print-category yes;
        print-severity yes;
    };
    
    category queries { querylog; };
    category security { querylog; };
};
```

**Windows DNS Logging**:

```powershell
# Enable query logging
Set-DnsServerDiagnostics -Queries $true -QueryLog $true

# Configure debug logging
Set-DnsServerDiagnostics -FullPackets $true -LogFilePath "C:\DNSLogs\dns.log"

# View diagnostic settings
Get-DnsServerDiagnostics
```

**Query Log Analysis**:

```bash
# Top queried domains
awk '{print $NF}' /var/log/named/queries.log | sort | uniq -c | sort -rn | head -20

# Queries from specific IP
grep "10.0.1.50" /var/log/named/queries.log

# Unusual query types
grep -E "(AXFR|ANY|TXT)" /var/log/named/queries.log
```

```powershell
# PowerShell - Analyze DNS event logs
Get-WinEvent -FilterHashtable @{LogName='DNS Server'; ID=257} -MaxEvents 1000 |
    Group-Object Message |
    Sort-Object Count -Descending |
    Select-Object Count, Name -First 20
```

**Centralized Logging**:

Send logs to SIEM for correlation and alerting:

```bash
# rsyslog configuration to forward to SIEM
*.* @@siem-server.example.com:514

# Or use filebeat for ELK stack
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/named/queries.log
  fields:
    log_type: dns_query

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
```

#### Anomaly Detection

Detect abnormal DNS behavior indicating attacks:

**Baseline Normal Behavior**:

- Typical query volume per hour/day
- Common query types ratio (A: 70%, AAAA: 15%, MX: 5%, etc.)
- Expected source IP ranges
- Normal response time distribution
- Typical NXDOMAIN rate

**Anomalies to Detect**:

- **Query Volume Spikes**: Sudden increase may indicate DDoS
- **NXDOMAIN Spikes**: Random subdomain attacks
- **Long Query Names**: Potential DNS tunneling (>50 chars)
- **Unusual Query Types**: Excessive ANY, TXT, or NULL queries
- **New/Unknown Domains**: Queries to newly registered domains
- **Geographic Anomalies**: Queries from unexpected locations
- **Time-Based Anomalies**: Queries during unusual hours

**Automated Detection (Python Example)**:

```python
#!/usr/bin/env python3
import re
from collections import Counter

def analyze_dns_log(logfile):
    queries = []
    query_lengths = []
    
    with open(logfile, 'r') as f:
        for line in f:
            match = re.search(r'query: (\S+)', line)
            if match:
                query = match.group(1)
                queries.append(query)
                query_lengths.append(len(query))
    
    # Analysis
    avg_length = sum(query_lengths) / len(query_lengths)
    long_queries = [q for q in queries if len(q) > 50]
    
    top_queries = Counter(queries).most_common(20)
    
    print(f"Total queries: {len(queries)}")
    print(f"Average query length: {avg_length:.2f}")
    print(f"Long queries (>50 chars): {len(long_queries)}")
    print("\nTop 20 queries:")
    for query, count in top_queries:
        print(f"{count:6d} {query}")
    
    if long_queries:
        print("\nSuspicious long queries:")
        for query in long_queries[:10]:
            print(f"  {query}")

if __name__ == "__main__":
    analyze_dns_log("/var/log/named/queries.log")
```

**Machine Learning Approaches**:

- **Clustering**: Group similar queries, flag outliers
- **Time Series Analysis**: Detect volume anomalies
- **String Analysis**: Identify encoded/encrypted domains
- **Behavioral Analysis**: Profile normal per-host behavior

#### Security Event Monitoring

Monitor DNS-specific security events:

**Critical Events to Monitor**:

**Zone Transfer Attempts**:

```bash
# BIND log monitoring
grep "zone transfer" /var/log/named/security.log

# Alert on unauthorized transfer attempts
```

```powershell
# Windows - Zone transfer events (Event ID 6004)
Get-WinEvent -FilterHashtable @{LogName='DNS Server'; ID=6004}
```

**Dynamic Update Attempts**:

```text
# BIND - Log dynamic updates
logging {
    category update { update_log; };
    category update-security { update_log; };
};
```

```powershell
# Windows - Dynamic update events (Event ID 512, 513)
Get-WinEvent -FilterHashtable @{LogName='DNS Server'; ID=512,513}
```

**DNSSEC Validation Failures**:

```bash
# BIND - DNSSEC validation errors
grep "DNSSEC validation failed" /var/log/named/security.log
```

```powershell
# Windows - DNSSEC events (Event ID 407, 408)
Get-WinEvent -FilterHashtable @{LogName='DNS Server'; ID=407,408}
```

**Server Start/Stop**:

```powershell
# Windows DNS service events (Event ID 2, 4)
Get-WinEvent -FilterHashtable @{LogName='DNS Server'; ID=2,4}
```

**Configuration Changes**:

Track changes to DNS configuration:

```bash
# Monitor /etc/named.conf for changes
auditctl -w /etc/named.conf -p wa -k dns_config_change

# Review audit log
ausearch -k dns_config_change
```

```powershell
# Windows - Audit DNS configuration changes
# Enable Object Access auditing, then:
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4663} |
    Where-Object {$_.Message -like "*DNS*"}
```

#### Compliance Requirements

DNS monitoring supports regulatory compliance:

**SOX (Sarbanes-Oxley)**:

- Log access to financial systems (DNS resolution logs)
- Change management tracking (zone updates)
- Access controls audit (who can modify DNS)

**HIPAA**:

- Access logs for healthcare systems
- Integrity monitoring (detect unauthorized changes)
- Encryption of DNS queries (DoT/DoH)

**PCI-DSS**:

- Network segmentation monitoring (DNS zones for cardholder environment)
- Log retention (1 year online, 3 years archived)
- Regular security assessments (DNS vulnerability scans)

**GDPR**:

- DNS query logs contain PII (IP addresses)
- Data retention policies
- Right to erasure considerations

**Compliance Logging Requirements**:

```powershell
# Ensure sufficient log retention
Set-DnsServerDiagnostics -SaveLogsToPersistentStorage $true

# Configure log rotation
$logPath = "C:\DNSLogs"
$retentionDays = 365
Get-ChildItem $logPath -Recurse -File |
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-$retentionDays)} |
    Remove-Item -Force
```

#### Incident Response Procedures

Prepare for DNS security incidents:

**Incident Response Plan**:

1. **Detection**: Alerts trigger investigation
2. **Analysis**: Determine scope and impact
3. **Containment**: Isolate affected systems
4. **Eradication**: Remove threat (malicious records, compromised servers)
5. **Recovery**: Restore normal operations
6. **Lessons Learned**: Post-incident review

**Common DNS Incidents**:

**Cache Poisoning Detected**:

```bash
# Flush cache immediately
rndc flush

# Restart DNS service
systemctl restart named

# Investigate source of poisoning
grep "FORMERR\|invalid" /var/log/named/security.log
```

**Unauthorized Zone Changes**:

```powershell
# Restore zone from backup
Restore-DnsServerZone -Name "example.com" -BackupPath "C:\DNSBackup"

# Review recent changes
Get-WinEvent -FilterHashtable @{LogName='DNS Server'; ID=513} -MaxEvents 100

# Identify compromised accounts
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624,4625}
```

**DDoS Attack**:

```bash
# Enable aggressive rate limiting
rndc reconfig  # After updating rate-limit config

# Block attack sources at firewall
iptables -A INPUT -s attacker-ip -j DROP

# Activate cloud DDoS protection
# (vendor-specific procedures)
```

**DNS Tunneling Discovered**:

```bash
# Block malicious domain
# Add to RPZ or firewall blocklist

# Isolate compromised host
# Network quarantine

# Forensic analysis
# Capture packets, analyze malware
```

**Playbook Documentation**:

Maintain runbooks for each incident type:

- Detection criteria
- Analysis steps
- Containment actions
- Communication plan (stakeholders to notify)
- Recovery procedures
- Evidence preservation

This comprehensive security section provides enterprise DNS administrators with the knowledge to protect DNS infrastructure from modern threats.

## Related Topics

- [Enterprise DNS Overview](index.md)
- [DNS Architecture Types](architecture.md)
- [Split-Brain DNS](split-brain.md)
- [DNS Delegation](delegation.md)
- [Zone and Record Management](zones-and-records.md)
- [DNS Server Configuration](server-configuration.md)
- [Automation and Tools](automation.md)
- [DNS Security Threats](security.md)
- [Security Hardening](hardening.md)
- [Monitoring and Auditing](monitoring.md)
