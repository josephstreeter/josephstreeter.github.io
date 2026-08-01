---
title: "Security Hardening"
description: "Hardening DNS servers with DNSSEC, access control, query restriction, and secure updates"
author: "Joseph Streeter"
tags: ["dns", "enterprise", "hardening", "dnssec", "access control"]
category: "services"
last_updated: "2026-08-01"
---
## Security Hardening

Controls that reduce the attack surface described in
[DNS Security Threats](security.md).

### Security Hardening

Implementing defense-in-depth security measures protects DNS infrastructure from compromise.

#### DNSSEC Implementation

DNS Security Extensions (DNSSEC) provide cryptographic authentication of DNS data:

**DNSSEC Concepts**:

- **Digital Signatures**: Zone data signed with private key
- **Chain of Trust**: Parent zone signs child's public key (DS record)
- **Authentication**: Resolvers verify signatures using public keys
- **Integrity**: Detects tampering of DNS responses
- **Does NOT Provide**: Encryption, privacy, DDoS protection

**DNSSEC Record Types**:

- **DNSKEY**: Public key for zone
- **RRSIG**: Signature for record set
- **DS**: Delegation Signer (hash of child's DNSKEY)
- **NSEC/NSEC3**: Authenticated denial of existence

**Signing a Zone (BIND)**:

```bash
# Generate ZSK (Zone Signing Key)
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE example.com

# Generate KSK (Key Signing Key)
dnssec-keygen -a RSASHA256 -b 4096 -f KSK -n ZONE example.com

# Sign the zone
dnssec-signzone -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) \
    -N INCREMENT -o example.com -t example.com.zone

# Creates example.com.zone.signed
```

**BIND Configuration for DNSSEC**:

```text
zone "example.com" {
    type master;
    file "/var/named/example.com.zone.signed";
    key-directory "/var/named/keys";
    auto-dnssec maintain;
    inline-signing yes;
};
```

**Windows DNS DNSSEC**:

```powershell
# Enable DNSSEC for zone
Enable-DnsServerSigningKey -ZoneName "example.com" `
    -ComputerName "dns-server.example.com"

# Sign the zone
Invoke-DnsServerZoneSign -ZoneName "example.com" `
    -SigningKeys (Get-DnsServerSigningKey -ZoneName "example.com")

# Export DS record for parent zone
Get-DnsServerSigningKey -ZoneName "example.com" | 
    Where-Object {$_.Type -eq "KeySigningKey"} |
    Select-Object -ExpandProperty DelegationSignerRecord
```

**Parent Zone Configuration**:

Submit DS record to parent zone (registrar or parent DNS admin):

```text
# DS record in parent zone
example.com. IN DS 12345 8 2 ABC123...DEF456
```

**DNSSEC Validation (Resolver)**:

**BIND Resolver**:

```text
options {
    dnssec-enable yes;
    dnssec-validation auto;
    dnssec-lookaside auto;
};
```

**Windows DNS Resolver**:

```powershell
# Enable DNSSEC validation
Set-DnsServerDnsSecZoneSetting -ZoneName "." -EnableDnsSec $true
```

**Testing DNSSEC**:

```bash
# Test DNSSEC validation
dig +dnssec example.com

# Should show RRSIG records and ad (authenticated data) flag

# Use DNSViz for comprehensive analysis
dnsviz probe example.com
dnsviz graph example.com
```

**DNSSEC Best Practices**:

- **Key Rollover**: Schedule regular KSK/ZSK rotation (ZSK quarterly, KSK annually)
- **Automated Signing**: Use automated tools to prevent manual errors
- **Key Backup**: Securely backup private keys
- **Monitor Validation**: Alert on DNSSEC validation failures
- **Test Before Production**: Validate DNSSEC in test environment first
- **Parent Communication**: Coordinate DS record updates with parent zone

**Common DNSSEC Issues**:

- **Broken Chain of Trust**: Parent zone missing DS record
- **Expired Signatures**: RRSIG validity period passed
- **Clock Skew**: Server time incorrect causing validation failures
- **Missing NSEC/NSEC3**: Incomplete denial of existence records

#### DNS over HTTPS (DoH) and DNS over TLS (DoT)

Encrypted DNS transports protect query privacy from eavesdropping:

**DNS over TLS (DoT) - RFC 7858**:

- **Port**: 853
- **Protocol**: TLS encryption over TCP
- **Privacy**: Queries encrypted, observer sees encrypted traffic to port 853
- **Authentication**: TLS certificates validate server identity

**DNS over HTTPS (DoH) - RFC 8484**:

- **Port**: 443
- **Protocol**: HTTPS (DNS queries as HTTP requests)
- **Privacy**: Queries indistinguishable from other HTTPS traffic
- **Authentication**: Standard HTTPS certificate validation

**Comparison**:

| Feature | DoT | DoH |
| ------- | --- | --- |
| Port | 853 | 443 |
| Firewall Detection | Easily identified | Blends with HTTPS |
| Network Admin Control | Easy to block port 853 | Hard to distinguish from web traffic |
| Protocol Complexity | Simpler (TLS wrapper) | More complex (HTTP+DNS) |
| Browser Support | Limited | Wide (Chrome, Firefox) |
| Enterprise Control | Better | Challenging |

**Configuring DoT (BIND)**:

```text
# /etc/named.conf
options {
    listen-on port 853 tls tls-config-name { any; };
};

tls tls-config-name {
    key-file "/etc/pki/tls/private/dns.key";
    cert-file "/etc/pki/tls/certs/dns.crt";
    dhparam-file "/etc/pki/tls/dhparam.pem";
    protocols { TLSv1.2; TLSv1.3; };
};
```

**Testing DoT**:

```bash
# Using kdig
kdig -d @dns-server.example.com +tls example.com

# Using openssl
openssl s_client -connect dns-server.example.com:853
```

**Configuring DoH (Unbound)**:

```text
server:
    interface: 0.0.0.0@443
    tls-service-key: "/etc/unbound/unbound_server.key"
    tls-service-pem: "/etc/unbound/unbound_server.pem"
    tls-port: 443
    https-port: 443
```

**Enterprise Considerations**:

**Challenges**:

- **Visibility Loss**: Encrypted queries bypass enterprise monitoring
- **Policy Enforcement**: Cannot filter malicious domains
- **Shadow IT**: Users can configure DoH in browsers, bypassing enterprise DNS
- **Troubleshooting**: Harder to diagnose DNS issues

**Mitigation Strategies**:

- **Internal DoT/DoH**: Deploy internal encrypted DNS servers
- **Group Policy**: Configure organization DoH resolver in browsers
- **Block Public DoH**: Block public DoH providers (1.1.1.1, 8.8.8.8)
- **Network Policy**: Require enterprise DNS for security policy enforcement

**Windows Configuration**:

```powershell
# Configure DoH server (Windows 11+)
Add-DnsClientDohServerAddress -ServerAddress "10.0.0.1" `
    -DohTemplate "https://dns.example.com/dns-query" `
    -AllowFallbackToUdp $false
```

#### Access Control Lists (ACLs)

ACLs restrict who can query DNS servers and perform operations:

**BIND ACL Configuration**:

```text
# Define ACLs
acl "trusted-networks" {
    10.0.0.0/8;
    172.16.0.0/12;
    192.168.0.0/16;
    localhost;
    localnets;
};

acl "dmz-servers" {
    192.0.2.0/24;
};

acl "admin-hosts" {
    10.0.1.50;
    10.0.1.51;
};

# Apply ACLs
options {
    allow-query { trusted-networks; };
    allow-query-cache { trusted-networks; };
    allow-recursion { trusted-networks; };
    allow-transfer { none; };
    blackhole { bogons; };
};

# Zone-specific ACLs
zone "example.com" {
    type master;
    file "example.com.zone";
    allow-query { any; };
    allow-transfer { dmz-servers; };
    allow-update { admin-hosts; };
};
```

**Windows DNS ACLs**:

```powershell
# Restrict zone queries (not widely supported - use firewall instead)
# Windows DNS relies more on AD permissions and firewall rules

# Set zone transfer restrictions
Set-DnsServerPrimaryZone -Name "example.com" `
    -SecureSecondaries "TransferToZoneNameServer"

# Or specify IP addresses
Set-DnsServerPrimaryZone -Name "example.com" `
    -SecureSecondaries "TransferToSecureServers" `
    -SecondaryServers @("10.0.1.10", "10.0.1.11")
```

**Best Practices**:

- **Principle of Least Privilege**: Grant minimum necessary access
- **Separate Authoritative and Recursive**: Different servers, different ACLs
- **Restrict Zone Transfers**: Only to authorized secondaries
- **Block Bogons**: Prevent queries from invalid IP ranges
- **Geo-Fencing**: Block queries from unexpected geographic regions
- **Rate Limiting**: Prevent abuse from allowed networks

#### Rate Limiting and Query Filtering

Control query volume and prevent abuse:

**Response Rate Limiting (RRL)**:

Already covered in DDoS section, but critical for security:

```text
# BIND RRL
rate-limit {
    responses-per-second 10;
    errors-per-second 5;
    nxdomains-per-second 5;
    window 5;
    slip 2;  # Send truncated response every N dropped
};
```

**Query Filtering Strategies**:

**Block Malicious Domains**:

```text
# BIND - RPZ (Response Policy Zone)
zone "rpz.example.com" {
    type master;
    file "rpz.zone";
};

options {
    response-policy {
        zone "rpz.example.com";
    };
};
```

**RPZ Zone File**:

```text
$TTL 60
@   IN  SOA rpz.example.com. admin.example.com. (
        2024011301 3600 1800 604800 60 )
    IN  NS  localhost.

; Block specific malicious domains
malicious.com    CNAME .
*.malicious.com  CNAME .

; Redirect to warning page
phishing.net     CNAME walled-garden.example.com.

; Return NXDOMAIN
badsite.org      CNAME *.
```

**Query Type Filtering**:

```text
# BIND - Block ANY queries
options {
    minimal-any yes;
};

# Block specific query types
view "external" {
    match-clients { any; };
    allow-query { any; };
    # Only allow A, AAAA, CNAME queries
};
```

**DNS Firewall Rules**:

```bash
# iptables - Rate limit DNS queries per source
iptables -A INPUT -p udp --dport 53 -m recent --name DNS --rcheck --seconds 60 --hitcount 50 -j DROP
iptables -A INPUT -p udp --dport 53 -m recent --name DNS --set -j ACCEPT

# Block DNS amplification (large responses)
iptables -A OUTPUT -p udp --sport 53 -m length --length 512:65535 -j DROP
```

#### Disable Unnecessary Features

Reduce attack surface by disabling unused functionality:

**BIND Security Options**:

```text
options {
    version "not available";  # Hide version info
    hostname "not available"; # Hide hostname
    server-id "not available"; # Hide server ID
    
    recursion no;  # On authoritative servers
    
    empty-zones-enable no;  # If using custom empty zones
    
    dnssec-enable yes;
    dnssec-validation yes;
    
    max-cache-size 256M;
    max-cache-ttl 86400;
    max-ncache-ttl 3600;
    
    # Disable unused protocols
    listen-on-v6 { none; };  # If IPv6 not used
};
```

**Windows DNS Security**:

```powershell
# Disable recursion (authoritative servers only)
Set-DnsServerRecursion -Enable $false

# Enable socket pool
Set-DnsServerCache -SocketPool $true -SocketPoolSize 2500

# Disable NetBIOS queries
Set-DnsServer -EnableWinsR $false -EnableWins $false

# Configure event log size
Limit-EventLog -LogName "DNS Server" -MaximumSize 100MB
```

**Remove Unnecessary Services**:

- **BIND**: Disable statistics server, control channel if not needed
- **Windows**: Disable WINS integration, GlobalNames zone if unused
- **Both**: Remove test zones, old delegations, unused zone files

#### Regular Patching and Updates

Maintain security through timely updates:

**Vulnerability Management Process**:

1. **Subscribe to Security Advisories**:
   - BIND: ISC Security Advisories
   - Windows DNS: Microsoft Security Response Center (MSRC)
   - CVE databases and NVD

2. **Prioritize DNS Patches**: DNS vulnerabilities often critical

3. **Test Before Production**: Validate patches in test environment

4. **Maintenance Windows**: Schedule regular DNS maintenance

5. **Rollback Plan**: Prepare rollback procedures for failed updates

**Automated Patching**:

```bash
# Linux - Automated security updates (Ubuntu/Debian)
apt install unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades

# CentOS/RHEL
yum install yum-cron
systemctl enable yum-cron
```

```powershell
# Windows - Install updates
Install-WindowsUpdate -AcceptAll -AutoReboot

# Or use WSUS for centralized management
```

**Monitoring for Vulnerabilities**:

```bash
# Check BIND version
named -v

# Check for known vulnerabilities
nmap -sV --script vuln dns-server.example.com
```

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
