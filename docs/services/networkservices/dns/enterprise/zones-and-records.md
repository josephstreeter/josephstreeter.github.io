---
title: "Zone and Record Management"
description: "Creating and maintaining DNS zones and resource records across Windows DNS and BIND"
author: "Joseph Streeter"
tags: ["dns", "enterprise", "zones", "records", "management"]
category: "services"
last_updated: "2026-08-01"
---
## DNS Management

Effective DNS management is crucial for maintaining reliable name resolution services in enterprise environments. This section covers zone management, record types, server configuration, and automation strategies that enable efficient DNS operations at scale.

### Zone Management

DNS zones are administrative containers for DNS records. Understanding different zone types and their management is fundamental to DNS operations.

#### Primary and Secondary Zones

**Primary (Master) Zones**:

Primary zones contain the authoritative, writable copy of zone data:

- **Read-Write**: Administrators can add, modify, or delete records
- **SOA Record**: Contains zone metadata including serial number, refresh intervals, and responsible party
- **Single Master**: Traditional model has one primary zone where all changes are made
- **Zone File Storage**: Zone data stored in zone files (BIND) or AD database (Windows AD-integrated)

**Creating Primary Zone (Windows)**:

```powershell
Add-DnsServerPrimaryZone -Name "company.com" -ZoneFile "company.com.dns" -DynamicUpdate Secure
```

**Creating Primary Zone (BIND)**:

```text
# /etc/named.conf
zone "company.com" {
    type master;
    file "/var/named/company.com.zone";
    allow-update { none; };
    allow-transfer { secondary-servers; };
};
```

**Secondary (Slave) Zones**:

Secondary zones contain read-only copies of zone data transferred from primary:

- **Read-Only**: No direct modifications allowed; must change primary
- **Zone Transfers**: Receive updates from primary via AXFR (full) or IXFR (incremental)
- **Redundancy**: Provide high availability if primary fails
- **Load Distribution**: Share query load with primary server
- **Geographic Distribution**: Place secondaries near user populations

**Creating Secondary Zone (Windows)**:

```powershell
Add-DnsServerSecondaryZone -Name "company.com" -ZoneFile "company.com.dns" `
    -MasterServers "10.1.1.10","10.1.1.11"
```

**Creating Secondary Zone (BIND)**:

```text
zone "company.com" {
    type slave;
    file "slaves/company.com.zone";
    masters { 10.1.1.10; 10.1.1.11; };
};
```

**Zone Transfer Process**:

1. Secondary queries primary's SOA record
2. Compares serial numbers
3. If primary serial higher, requests transfer (AXFR or IXFR)
4. Primary sends zone data
5. Secondary updates local copy and increments serial

**Best Practices**:

- Deploy at least two secondary servers per zone for redundancy
- Distribute secondaries geographically
- Configure NOTIFY for immediate transfer notification
- Use TSIG to secure zone transfers
- Monitor zone transfer success/failure

#### Active Directory-Integrated Zones

AD-integrated zones provide enhanced features for Windows environments:

**Key Features**:

- **Multi-Master Replication**: All DCs can accept updates; changes replicate via Active Directory
- **Secure Dynamic Updates**: Only domain members can update their records
- **Automatic Replication**: Zone data replicates with AD replication, no separate zone transfers
- **Granular Replication Scope**: Choose domain-wide or forest-wide replication
- **Enhanced Security**: Integrated with AD security model and Kerberos authentication

**Replication Scopes**:

1. **To all DNS servers in the domain**: Most common for domain zones
2. **To all DNS servers in the forest**: Used for forest-wide zones like `_msdcs`
3. **To all domain controllers in the domain**: Legacy option
4. **Custom application directory partition**: Advanced scenarios

**Creating AD-Integrated Zone**:

```powershell
# Convert existing primary to AD-integrated
ConvertTo-DnsServerPrimaryZone -Name "company.com" -ReplicationScope Domain

# Create new AD-integrated zone
Add-DnsServerPrimaryZone -Name "company.com" -ReplicationScope Domain -DynamicUpdate Secure
```

**Advantages Over Standard Primary/Secondary**:

- Eliminates single point of failure (multi-master)
- Simplified management (no manual zone transfer configuration)
- Better security (AD-integrated security)
- Automatic updates and replication
- Reduced administrative overhead

**Considerations**:

- Requires Active Directory infrastructure
- All DNS servers must be domain controllers
- Replication depends on AD replication health
- More complex troubleshooting (AD + DNS)

#### Zone Transfer Configuration (AXFR/IXFR)

Zone transfers synchronize zone data between primary and secondary servers.

**AXFR (Full Zone Transfer)**:

Transfers entire zone contents:

- **Complete Copy**: All records transferred regardless of changes
- **Bandwidth Intensive**: Large zones consume significant bandwidth
- **Used For**: Initial secondary configuration, after major changes, or IXFR failure
- **Protocol**: TCP port 53

**IXFR (Incremental Zone Transfer)**:

Transfers only changed records:

- **Efficient**: Only transfers differences since last transfer
- **Bandwidth Saving**: Reduces transfer size for zones with few changes
- **Serial Number Based**: Uses SOA serial to identify changes
- **Fallback**: Falls back to AXFR if incremental data unavailable

**Configuring Zone Transfers (Windows)**:

```powershell
# Restrict zone transfers to specific servers
Set-DnsServerPrimaryZone -Name "company.com" `
    -SecondaryServers "10.2.2.10","10.2.2.11" `
    -SecureSecondaries TransferToSecureServers

# Enable NOTIFY to alert secondaries of changes
Set-DnsServerPrimaryZone -Name "company.com" -Notify NotifyServers `
    -NotifyServers "10.2.2.10","10.2.2.11"
```

**Configuring Zone Transfers (BIND)**:

```text
zone "company.com" {
    type master;
    file "/var/named/company.com.zone";
    
    # Allow transfers only to secondaries
    allow-transfer { 10.2.2.10; 10.2.2.11; };
    
    # Send NOTIFY to secondaries
    also-notify { 10.2.2.10; 10.2.2.11; };
    notify yes;
    
    # Enable IXFR
    ixfr-from-differences yes;
};
```

**Security Considerations**:

- **Restrict Transfers**: Only allow to authorized secondaries
- **TSIG Authentication**: Use TSIG keys to authenticate transfers
- **Encrypted Transfers**: Consider VPN or TLS for sensitive zones
- **Monitor Transfer Activity**: Log and alert on unauthorized transfer attempts

**TSIG Configuration**:

```text
# Generate TSIG key
key "transfer-key" {
    algorithm hmac-sha256;
    secret "base64encodedkeyhere==";
};

# Configure on primary
zone "company.com" {
    type master;
    allow-transfer { key transfer-key; };
};

# Configure on secondary
server 10.1.1.10 {
    keys { transfer-key; };
};
```

#### Zone File Maintenance

Proper zone file management ensures consistency and recoverability:

**Zone File Location**:

- **Windows**: `%SystemRoot%\System32\dns\`
- **BIND**: `/var/named/` or `/etc/bind/zones/`

**Zone File Format**:

```text
$TTL 3600
$ORIGIN company.com.
@   IN  SOA ns1.company.com. admin.company.com. (
        2024011301 ; Serial (YYYYMMDDNN)
        3600       ; Refresh (1 hour)
        1800       ; Retry (30 minutes)
        604800     ; Expire (7 days)
        86400 )    ; Minimum TTL (1 day)

; Name servers
@       IN  NS  ns1.company.com.
@       IN  NS  ns2.company.com.

; A records
ns1     IN  A   10.1.1.10
ns2     IN  A   10.1.1.11
www     IN  A   10.1.1.20
mail    IN  A   10.1.1.30

; MX records
@       IN  MX  10 mail.company.com.

; CNAME records
webmail IN  CNAME mail.company.com.
```

**Serial Number Management**:

Critical for zone transfers - secondary uses serial to detect updates:

- **Format**: Typically YYYYMMDDNN (Year/Month/Day/Revision)
- **Must Increase**: Each change must increment serial
- **32-bit Integer**: Maximum value 4294967295
- **Rollover Handling**: Plan for serial number wraparound

**Backup Strategies**:

```bash
# Backup zone files (BIND)
cp /var/named/company.com.zone /backup/company.com.zone.$(date +%Y%m%d)

# Backup Windows DNS zones
dnscmd /ZoneExport company.com company.com.backup.dns
```

```powershell
# PowerShell backup script
$zones = Get-DnsServerZone
foreach ($zone in $zones) {
    Export-DnsServerZone -Name $zone.ZoneName -FileName "backup_$($zone.ZoneName).dns"
}
```

**Change Control**:

- Use version control (Git) for zone files
- Document all changes with commit messages
- Test changes in development environment first
- Implement peer review for production changes
- Maintain rollback procedures

#### Stub Zones

Stub zones contain only NS records, SOA record, and glue records for delegated zones:

**Purpose**:

- Maintain current list of authoritative name servers for delegated zones
- Keep delegation information up-to-date automatically
- Improve resolution efficiency for delegated domains

**Use Cases**:

- Track delegation changes in child domains
- Ensure resolvers always query correct name servers
- Active Directory parent-child domain scenarios

**Creating Stub Zone (Windows)**:

```powershell
Add-DnsServerStubZone -Name "subsidiary.company.com" `
    -MasterServers "10.10.10.10","10.10.10.11" `
    -ReplicationScope Domain
```

**How Stub Zones Work**:

1. Stub zone server queries master for zone's NS records
2. Updates local stub zone with NS records
3. When client queries name in stub zone, server returns NS records
4. Client queries authoritative servers directly

**Stub Zone vs. Delegation**:

- **Delegation**: NS records in parent zone point to child servers
- **Stub Zone**: Automatically maintains updated NS records from child
- **Benefit**: Delegation information stays current without manual updates

#### Conditional Forwarding Zones

Conditional forwarders direct queries for specific domains to designated DNS servers:

**Purpose**:

- Route queries for specific domains to optimal resolvers
- Integrate with partner networks
- Improve resolution performance
- Support split-brain architectures

**Creating Conditional Forwarder (Windows)**:

```powershell
Add-DnsServerConditionalForwarderZone -Name "partner.com" `
    -MasterServers "192.0.2.10","192.0.2.11" `
    -ReplicationScope Forest
```

**Creating Conditional Forwarder (BIND)**:

```text
zone "partner.com" {
    type forward;
    forwarders { 192.0.2.10; 192.0.2.11; };
    forward only;
};
```

**Forward Only vs. Forward First**:

- **Forward Only**: Only query specified forwarders; fail if they don't respond
- **Forward First**: Try forwarders first, fall back to normal resolution if they fail

**Common Use Cases**:

- Forest trusts: Forward queries for trusted forest domains
- Partner integration: Route partner domain queries to partner DNS
- Cloud integration: Forward cloud domain queries to cloud DNS servers
- Geographic optimization: Forward queries to region-specific resolvers

**Best Practices**:

- Use replication scope "Forest" for forest-wide availability
- Configure redundant forwarder IP addresses
- Monitor forwarder availability and performance
- Document conditional forwarder purposes and ownership

### Record Management

DNS records map domain names to various resource types. Understanding record types and their proper use is essential for DNS management.

#### A and AAAA Records

Address records map hostnames to IP addresses:

**A Records (IPv4)**:

```text
www.company.com.    IN  A   203.0.113.10
mail.company.com.   IN  A   203.0.113.20
```

```powershell
# Windows
Add-DnsServerResourceRecordA -Name "www" -ZoneName "company.com" `
    -IPv4Address "203.0.113.10" -TimeToLive (New-TimeSpan -Hours 1)
```

**AAAA Records (IPv6)**:

```text
www.company.com.    IN  AAAA    2001:db8::1
mail.company.com.   IN  AAAA    2001:db8::2
```

```powershell
# Windows
Add-DnsServerResourceRecordAAAA -Name "www" -ZoneName "company.com" `
    -IPv6Address "2001:db8::1"
```

**Multiple A Records**:

Used for load distribution (round-robin DNS):

```text
www.company.com.    IN  A   203.0.113.10
www.company.com.    IN  A   203.0.113.11
www.company.com.    IN  A   203.0.113.12
```

**Best Practices**:

- Use AAAA records alongside A records for dual-stack support
- Set appropriate TTL values (3600 seconds / 1 hour common)
- Lower TTL before planned changes for faster propagation
- Avoid excessive round-robin entries (3-4 maximum)

#### CNAME Records and Aliases

CNAME (Canonical Name) creates aliases pointing to other names:

**Format**:

```text
www.company.com.        IN  A       203.0.113.10
webmail.company.com.    IN  CNAME   www.company.com.
portal.company.com.     IN  CNAME   www.company.com.
```

```powershell
# Windows
Add-DnsServerResourceRecordCName -Name "webmail" -ZoneName "company.com" `
    -HostNameAlias "www.company.com"
```

**CNAME Restrictions**:

- **Cannot coexist with other records at same name**: CNAME must be only record for that name
- **Zone apex restriction**: Cannot create CNAME at zone apex (@)
- **Performance impact**: Additional query required to resolve CNAME target

**When to Use CNAME**:

- Creating aliases for services on different hosts
- Simplifying record management (one A record, many CNAMEs)
- Load balancer endpoints (CNAME to LB address)
- CDN integration (CNAME to CDN endpoint)

**When NOT to Use CNAME**:

- At zone apex (use A/AAAA records or ALIAS records)
- For MX records (MX must point to A/AAAA, not CNAME)
- Where other records needed at same name
- High-query-volume scenarios (adds resolution hop)

**Alternative - ALIAS Records** (CloudFlare, Azure DNS):

Some providers offer ALIAS records that act like CNAMEs but can exist at zone apex and resolve to IP addresses.

#### MX Records for Mail Routing

MX (Mail Exchanger) records direct email to mail servers:

**Format**:

```text
company.com.    IN  MX  10  mail1.company.com.
company.com.    IN  MX  20  mail2.company.com.
mail1.company.com.  IN  A   203.0.113.10
mail2.company.com.  IN  A   203.0.113.11
```

```powershell
# Windows
Add-DnsServerResourceRecordMX -Name "@" -ZoneName "company.com" `
    -MailExchange "mail1.company.com" -Preference 10

Add-DnsServerResourceRecordMX -Name "@" -ZoneName "company.com" `
    -MailExchange "mail2.company.com" -Preference 20
```

**Priority Values**:

- Lower values = higher priority
- Mail servers try lowest priority first
- Equal priorities = load balancing between servers
- Common pattern: 10, 20, 30 for primary, secondary, tertiary

**Best Practices**:

- Always use multiple MX records for redundancy
- MX records must point to A/AAAA records, never CNAME
- Ensure mail servers accept mail for the domain
- Configure reverse DNS (PTR) for mail server IPs
- Implement SPF, DKIM, and DMARC records

**Common Configurations**:

**Single Mail Server with Backup**:

```text
@   IN  MX  10  mail.company.com.
@   IN  MX  20  backup-mail.company.com.
```

**Cloud Email Service** (Office 365, Google Workspace):

```text
@   IN  MX  0   company-com.mail.protection.outlook.com.
```

#### TXT Records (SPF, DKIM, DMARC)

TXT records store text data, commonly used for email authentication:

**SPF (Sender Policy Framework)**:

Specifies authorized mail servers for domain:

```text
company.com.    IN  TXT  "v=spf1 mx ip4:203.0.113.0/24 include:_spf.google.com ~all"
```

- `v=spf1`: SPF version
- `mx`: Allow servers in MX records
- `ip4:`: Allow specific IPv4 addresses/ranges
- `include:`: Include another domain's SPF policy
- `~all`: Soft fail for others (mark as suspicious)
- `-all`: Hard fail for others (reject)

```powershell
# Windows
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "@" -Txt `
    -DescriptiveText "v=spf1 mx include:_spf.google.com ~all"
```

**DKIM (DomainKeys Identified Mail)**:

Public key for verifying email signatures:

```text
selector._domainkey.company.com.    IN  TXT  "v=DKIM1; k=rsa; p=MIGfMA0GCS..."
```

- Selector: Unique identifier for key (e.g., "default", "google")
- Contains public key for signature verification
- Generated by mail server or email service

**DMARC (Domain-based Message Authentication)**:

Policy for handling authentication failures:

```text
_dmarc.company.com.    IN  TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@company.com; pct=100"
```

- `p=`: Policy (none, quarantine, reject)
- `rua=`: Aggregate report destination
- `ruf=`: Forensic report destination
- `pct=`: Percentage of messages to which policy applies

**Other Common TXT Records**:

```text
; Domain verification
@   IN  TXT  "google-site-verification=abcd1234efgh5678"
@   IN  TXT  "MS=ms12345678"

; Description
@   IN  TXT  "Company Name - Official Domain"
```

#### PTR Records for Reverse DNS

PTR (Pointer) records map IP addresses to hostnames (reverse DNS):

**Purpose**:

- Email server verification (many mail servers require valid PTR)
- Logging and security analysis
- Troubleshooting network issues
- Compliance and audit requirements

**Format**:

For IP `203.0.113.10`:

```text
; In zone: 113.0.203.in-addr.arpa
10.113.0.203.in-addr.arpa.    IN  PTR  mail.company.com.
```

```powershell
# Windows
Add-DnsServerResourceRecordPtr -Name "10" -ZoneName "113.0.203.in-addr.arpa" `
    -PtrDomainName "mail.company.com"
```

**IPv6 Reverse DNS**:

For IPv6 `2001:db8::1`:

```text
; In zone: 0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa
1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa.
    IN  PTR  www.company.com.
```

**Reverse Zone Delegation**:

ISPs typically delegate reverse zones to customers:

- Request reverse delegation from ISP
- ISP creates NS records in their reverse zone
- Customer manages reverse zone on their DNS servers

**Best Practices**:

- Always configure PTR for mail servers
- PTR should match forward lookup (A/AAAA record)
- One PTR per IP address
- Critical for email deliverability

#### SRV Records for Service Discovery

SRV (Service) records specify location of services:

**Format**:

```text
_service._protocol.name.    TTL    IN  SRV  priority  weight  port  target.

_ldap._tcp.dc._msdcs.company.com.    IN  SRV  0  100  389  dc1.company.com.
```

```powershell
# Windows
Add-DnsServerResourceRecord -ZoneName "company.com" `
    -Name "_ldap._tcp.dc._msdcs" -Srv `
    -DomainName "dc1.company.com" -Priority 0 -Weight 100 -Port 389
```

**Components**:

- **Service**: Service name (e.g., _ldap,_kerberos, _sip)
- **Protocol**: _tcp or_udp
- **Name**: Domain name
- **Priority**: Lower = higher priority (like MX)
- **Weight**: Load distribution among same priority
- **Port**: Service port number
- **Target**: Server hostname providing service

**Common SRV Records**:

**Active Directory**:

```text
_ldap._tcp.dc._msdcs.company.com.           SRV  0 100 389  dc1.company.com.
_kerberos._tcp.dc._msdcs.company.com.       SRV  0 100 88   dc1.company.com.
_gc._tcp.company.com.                       SRV  0 100 3268 dc1.company.com.
```

**SIP (VoIP)**:

```text
_sip._tcp.company.com.    IN  SRV  10  60  5060  sipserver1.company.com.
_sip._tcp.company.com.    IN  SRV  10  40  5060  sipserver2.company.com.
```

**XMPP (Jabber)**:

```text
_xmpp-client._tcp.company.com.    IN  SRV  5  0  5222  xmpp.company.com.
_xmpp-server._tcp.company.com.    IN  SRV  5  0  5269  xmpp.company.com.
```

**Load Distribution with Weight**:

```text
_http._tcp.company.com.    IN  SRV  10  60  80  web1.company.com.
_http._tcp.company.com.    IN  SRV  10  30  80  web2.company.com.
_http._tcp.company.com.    IN  SRV  10  10  80  web3.company.com.
```

Weight 60 receives ~60% of traffic, weight 30 receives ~30%, weight 10 receives ~10%.

#### CAA Records for Certificate Authority Authorization

CAA (Certification Authority Authorization) records specify which CAs can issue certificates:

**Format**:

```text
company.com.    IN  CAA  0  issue "letsencrypt.org"
company.com.    IN  CAA  0  issue "digicert.com"
company.com.    IN  CAA  0  issuewild "letsencrypt.org"
company.com.    IN  CAA  0  iodef "mailto:security@company.com"
```

```powershell
# Windows Server 2019+
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "@" -CAA `
    -Flags 0 -Tag "issue" -Value "letsencrypt.org"
```

**CAA Tags**:

- **issue**: Authorize CA to issue certificates for domain
- **issuewild**: Authorize CA to issue wildcard certificates
- **iodef**: URL for CA to report policy violations

**Flags**:

- **0**: Non-critical (default)
- **128**: Critical (must be understood by CA)

**Benefits**:

- Prevents unauthorized certificate issuance
- Reduces risk of mis-issued certificates
- Provides notification mechanism for violations
- Required by some compliance frameworks

**Best Practices**:

- Always implement CAA records for public domains
- Specify only authorized CAs
- Include iodef for violation reporting
- Test CAA before deploying to production

#### Record TTL Considerations

TTL (Time To Live) determines how long records are cached:

**Common TTL Values**:

- **300 seconds (5 minutes)**: Frequently changing records
- **3600 seconds (1 hour)**: Standard for most records
- **86400 seconds (24 hours)**: Stable, rarely changing records
- **604800 seconds (7 days)**: Very stable infrastructure

**TTL Strategy**:

**Before Changes**:

1. Lower TTL to 300 seconds (5 minutes)
2. Wait for old TTL to expire (e.g., 24 hours)
3. Make DNS changes
4. Verify changes propagated
5. Restore higher TTL

**After Changes**:

- Monitor for issues
- Gradually increase TTL back to normal
- Document changes and TTL restoration

**Considerations**:

- **Lower TTL**: Faster propagation, more DNS queries, higher load
- **Higher TTL**: Slower propagation, fewer queries, reduced load
- **Default TTL**: Set reasonable zone-wide default (3600 common)
- **Per-Record TTL**: Override default for specific records

**Examples**:

```text
; Zone default TTL
$TTL 3600

; Specific record with different TTL
www.company.com.    300    IN  A   203.0.113.10    ; 5 minute TTL
mail.company.com.   86400  IN  A   203.0.113.20    ; 24 hour TTL
```

```powershell
# Windows - Set TTL on new record
Add-DnsServerResourceRecordA -Name "www" -ZoneName "company.com" `
    -IPv4Address "203.0.113.10" -TimeToLive (New-TimeSpan -Seconds 300)

# Modify existing record TTL
$record = Get-DnsServerResourceRecord -ZoneName "company.com" -Name "www" -RRType A
$newRecord = $record.Clone()
$newRecord.TimeToLive = New-TimeSpan -Seconds 300
Set-DnsServerResourceRecord -ZoneName "company.com" -OldInputObject $record -NewInputObject $newRecord
```

**TTL and Caching**:

- Recursive resolvers cache records for TTL duration
- Clients may also cache based on TTL
- Negative caching (NXDOMAIN) uses SOA minimum TTL
- Expired cache entries trigger new queries

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
