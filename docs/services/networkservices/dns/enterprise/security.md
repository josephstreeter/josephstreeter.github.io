---
title: "DNS Security Threats"
description: "Cache poisoning, spoofing, amplification, tunnelling, and the other attacks that target DNS"
author: "Joseph Streeter"
tags: ["dns", "enterprise", "security", "threats", "attacks"]
category: "services"
last_updated: "2026-08-01"
---
## Security

DNS security is paramount in enterprise environments. DNS infrastructure is a critical target for attackers and a potential vector for data exfiltration, service disruption, and network compromise. Implementing comprehensive security measures protects the integrity, availability, and confidentiality of DNS services.

### DNS Security Threats

Understanding common DNS threats enables organizations to implement appropriate defenses.

#### DNS Spoofing and Cache Poisoning

**DNS Spoofing**:

Attackers send forged DNS responses to clients or recursive resolvers:

- **Man-in-the-Middle**: Intercept queries and inject false responses
- **Response Manipulation**: Modify legitimate responses in transit
- **Impact**: Redirect users to malicious sites, intercept credentials, deliver malware

**Cache Poisoning**:

Attackers inject malicious data into DNS resolver caches:

- **Birthday Attack**: Exploit predictable transaction IDs and source ports
- **Kaminsky Attack**: Query non-existent names to increase success probability
- **Persistent**: Poisoned cache serves bad data until TTL expires
- **Amplification**: One poisoned resolver affects all its clients

**Attack Example**:

```text
1. Attacker queries resolver for www.bank.com
2. Attacker floods resolver with forged responses
3. One forged response matches query ID and source port
4. Resolver accepts forged response (www.bank.com = attacker-ip)
5. Resolver caches poisoned record
6. All clients receive malicious IP for www.bank.com
```

**Mitigation Strategies**:

- **Source Port Randomization**: Use random source ports (0-65535) for queries
- **Transaction ID Randomization**: Cryptographically random query IDs
- **0x20 Encoding**: Randomize case in query name for additional entropy
- **DNSSEC**: Cryptographically sign DNS responses
- **Query Minimization**: Send only necessary information in queries
- **Response Validation**: Strict adherence to DNS standards

**Windows DNS Configuration**:

```powershell
# Enable socket pool (source port randomization)
Set-DnsServerGlobalQueryBlockList -Enable $true
Set-DnsServerCache -MaxNegativeTtl 900

# View current configuration
Get-DnsServerSetting | Select-Object EnableSocketPool, SocketPoolSize
```

**BIND Configuration**:

```text
options {
    use-v4-udp-ports { range 1024 65535; };
    avoid-v4-udp-ports { 53; };
    query-source port *;
    query-source-v6 port *;
};
```

#### DDoS Attacks on DNS Infrastructure

DNS servers are high-value targets for Distributed Denial of Service attacks:

**Volumetric Attacks**:

- **UDP Flood**: Overwhelm server with UDP packets
- **TCP SYN Flood**: Exhaust TCP connection resources
- **Impact**: Server unable to process legitimate queries

**Amplification Attacks**:

- **ANY Query Amplification**: Small query generates large response
- **DNSSEC Amplification**: Signed responses much larger than queries
- **Reflection**: Attacker spoofs victim IP, server sends responses to victim
- **Amplification Factor**: Response can be 50-100x larger than query

**Application-Layer Attacks**:

- **Random Subdomain Attack**: Query random non-existent subdomains
- **NXDOMAIN Flood**: Overwhelm server with queries for non-existent domains
- **Slow Queries**: Craft queries that require extensive processing

**Mitigation Strategies**:

**Infrastructure Level**:

- **Anycast DNS**: Distribute load across multiple locations
- **Over-Provisioning**: Maintain capacity headroom (3-10x normal load)
- **Cloud-Based DDoS Protection**: Services like Cloudflare, Akamai, AWS Shield
- **Rate Limiting**: Limit queries per source IP
- **Geo-Blocking**: Block queries from suspicious regions

**DNS Server Configuration**:

```text
# BIND - Rate limiting
rate-limit {
    responses-per-second 10;
    errors-per-second 5;
    nxdomains-per-second 5;
    window 5;
};
```

```powershell
# Windows DNS - Response rate limiting (Server 2016+)
Set-DnsServerResponseRateLimiting -Mode Enable `
    -ResponsesPerSec 10 `
    -ErrorsPerSec 5 `
    -WindowInSec 5
```

**Query Filtering**:

- **Disable Recursion**: On authoritative servers
- **ACLs**: Restrict recursion to known networks only
- **Block ANY Queries**: Prevent amplification attacks

```text
# BIND - Restrict recursion
options {
    recursion no;  # For authoritative-only servers
};

view "internal" {
    match-clients { trusted-networks; };
    recursion yes;
};

view "external" {
    match-clients { any; };
    recursion no;
};
```

#### DNS Tunneling and Data Exfiltration

Attackers use DNS as a covert channel to bypass firewall restrictions:

**How DNS Tunneling Works**:

1. Malware on compromised host encodes data in DNS queries
2. Queries sent to attacker-controlled DNS server
3. Data extracted from query names (labels)
4. Responses can send commands back to malware

**Example DNS Tunnel Query**:

```text
# Encoded data in subdomain labels
aGVsbG8gd29ybGQ.data.attacker.com
# "aGVsbG8gd29ybGQ" = Base64 encoded data
```

**Common Tunneling Tools**:

- **Iodine**: IP over DNS tunneling
- **Dnscat2**: Encrypted DNS tunnel
- **DNS2TCP**: TCP over DNS
- **Custom Malware**: APT groups use proprietary tools

**Indicators of DNS Tunneling**:

- Unusually long domain names (>50 characters)
- High volume of DNS queries from single host
- Queries to suspicious or newly registered domains
- Unusual character patterns (Base64, hex encoding)
- DNS queries with abnormal frequency or timing
- Queries to uncommon record types (TXT, NULL)

**Detection and Mitigation**:

**Query Analysis**:

```powershell
# PowerShell - Analyze DNS query logs for anomalies
$logs = Get-DnsServerQueryResolutionLog -Zone "." -MaxRecords 10000
$logs | Group-Object ClientIP | 
    Where-Object {$_.Count -gt 100} | 
    Select-Object Name, Count |
    Sort-Object Count -Descending
```

**Monitoring Tools**:

- **Passive DNS**: Monitor and baseline normal DNS behavior
- **SIEM Integration**: Correlate DNS logs with other security events
- **Machine Learning**: Detect anomalous query patterns
- **Threat Intelligence**: Block known malicious domains

**Preventive Controls**:

- **DNS Filtering**: Block newly registered domains (NRDs)
- **Allowlist-Based Policies**: Only permit queries to approved domains
- **Query Length Limits**: Reject excessively long queries
- **Rate Limiting**: Limit queries per host
- **Split DNS**: Internal hosts use internal DNS, limited external resolution

**BIND Configuration**:

```text
# Limit maximum query length
options {
    max-query-length 256;
};
```

#### Subdomain Takeover Risks

Subdomain takeover occurs when an attacker claims an abandoned subdomain:

**Common Scenario**:

1. Company creates CNAME: `blog.company.com` → `company.platform.com`
2. Company cancels platform service
3. `company.platform.com` becomes available
4. Attacker registers `company.platform.com`
5. Attacker now controls `blog.company.com`

**Vulnerable Services**:

- **Cloud Hosting**: AWS S3, Azure Websites, GitHub Pages
- **CDNs**: CloudFront, Fastly, Cloudflare
- **SaaS Platforms**: Heroku, Shopify, WordPress.com
- **Marketing Tools**: HubSpot, Marketo, Pardot

**Impact**:

- Phishing campaigns using legitimate domain
- Malware distribution from trusted domain
- Reputation damage
- Cookie theft (if session cookies not scoped properly)
- SSL certificate issuance for subdomain

**Detection**:

**Automated Scanning**:

```bash
#!/bin/bash
# Check for dangling CNAMEs

for subdomain in $(dig +short -f subdomains.txt CNAME); do
    if ! host "$subdomain" > /dev/null 2>&1; then
        echo "Potential takeover: $subdomain"
    fi
done
```

**Tools**:

- **Subjack**: Subdomain takeover scanner
- **SubOver**: Check for subdomain takeovers
- **Nuclei**: Security scanner with subdomain takeover templates

**Prevention**:

- **Inventory Management**: Maintain complete subdomain inventory
- **Automated Monitoring**: Scan for dangling DNS records
- **Cleanup Procedures**: Remove DNS records when decommissioning services
- **Verification Before Deletion**: Ensure external resources exist before creating CNAME
- **Cloud Resource Tags**: Tag DNS records with service information
- **Regular Audits**: Quarterly review of all subdomains and CNAMEs

**Remediation**:

```powershell
# Remove dangling CNAME record
Remove-DnsServerResourceRecord -ZoneName "company.com" `
    -Name "blog" -RRType CNAME -Force
```

#### DNS Amplification Attacks

DNS amplification exploits open DNS resolvers to amplify attack traffic:

**Attack Mechanics**:

1. Attacker sends DNS query with spoofed source IP (victim's IP)
2. Query requests large response (ANY, DNSSEC records)
3. DNS server sends large response to victim
4. Small query (60 bytes) generates large response (3000+ bytes)
5. Amplification factor: 50x or higher

**Example Attack**:

```text
Attacker → [Query: ANY example.com, SrcIP: victim-ip] → Open Resolver
Open Resolver → [Response: 3000 bytes] → Victim
```

**Mitigation for DNS Operators**:

**Disable Open Recursion**:

```text
# BIND
options {
    recursion no;
};

acl trusted {
    10.0.0.0/8;
    172.16.0.0/12;
    192.168.0.0/16;
};

view "internal" {
    match-clients { trusted; };
    recursion yes;
};

view "external" {
    match-clients { any; };
    recursion no;
};
```

```powershell
# Windows DNS - Disable recursion
Set-DnsServerRecursion -Enable $false
```

**Response Rate Limiting (RRL)**:

Limit identical responses to same client:

```text
# BIND RRL configuration
rate-limit {
    responses-per-second 10;
    errors-per-second 5;
    nxdomains-per-second 5;
    referrals-per-second 5;
    all-per-second 20;
    slip 2;
    window 15;
    log-only no;
};
```

**Disable ANY Queries**:

```text
# BIND - Block ANY queries
options {
    minimal-any yes;
};
```

**Network-Level Protection**:

- **BCP 38**: Implement ingress/egress filtering to prevent IP spoofing
- **Firewall Rules**: Block DNS from untrusted sources
- **Cloud DDoS Protection**: Use cloud-based scrubbing services

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
