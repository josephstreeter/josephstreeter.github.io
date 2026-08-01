---
title: "DNS Delegation"
description: "Delegating DNS zones: fundamentals, Active Directory delegation, best practices, and practical scenarios"
author: "Joseph Streeter"
tags: ["dns", "enterprise", "delegation", "zones", "active directory"]
category: "services"
last_updated: "2026-08-01"
---
## DNS Delegation

DNS delegation is a fundamental mechanism that distributes the responsibility for portions of the DNS namespace to different DNS servers. In enterprise environments, delegation enables organizational hierarchy, improves performance, and supports distributed administration. Understanding delegation is critical for Active Directory implementations and complex enterprise DNS architectures.

### Delegation Fundamentals

#### What is DNS Delegation

DNS delegation is the process by which authority for a subdomain is assigned from a parent zone to child name servers. This creates a hierarchical structure where:

- **Parent Zone**: Maintains NS records pointing to authoritative servers for the child zone
- **Child Zone**: Becomes independently authoritative for its portion of the namespace
- **Distributed Authority**: Multiple organizations or teams can manage different parts of the namespace

For example, if `company.com` delegates `division.company.com` to separate name servers, those name servers become authoritative for all names within `division.company.com`, while the parent zone retains authority for `company.com` itself.

**Key Characteristics**:

- **Autonomy**: Delegated zones operate independently from the parent
- **Scalability**: Distributes DNS load across multiple server sets
- **Administrative Separation**: Different teams can manage their own zones
- **Hierarchical Structure**: Mirrors organizational or geographic structure

#### How Delegation Works

The delegation process involves several DNS components working together:

##### Step 1: Parent Zone Configuration

The parent zone creates NS (name server) records pointing to the child zone's authoritative servers:

```text
; Parent zone: company.com
division.company.com.  IN  NS  ns1.division.company.com.
division.company.com.  IN  NS  ns2.division.company.com.
```

##### Step 2: Glue Records (When Necessary)

If the child name servers are within the delegated zone, glue records provide IP addresses:

```text
; Glue records in parent zone
ns1.division.company.com.  IN  A  10.20.30.10
ns2.division.company.com.  IN  A  10.20.30.11
```

##### Step 3: Child Zone Configuration

The child zone's name servers host the authoritative zone data:

```text
; Child zone: division.company.com
$ORIGIN division.company.com.
@  IN  SOA  ns1.division.company.com. admin.division.company.com. (
       2024011301 ; Serial
       3600       ; Refresh
       1800       ; Retry
       604800     ; Expire
       86400 )    ; Minimum

@  IN  NS  ns1.division.company.com.
@  IN  NS  ns2.division.company.com.

ns1  IN  A  10.20.30.10
ns2  IN  A  10.20.30.11
www  IN  A  10.20.30.20
```

##### Step 4: Query Resolution

When a client queries `www.division.company.com`:

1. Resolver queries root servers for `.com`
2. Root servers refer to `.com` TLD servers
3. TLD servers refer to `company.com` authoritative servers
4. `company.com` servers respond with NS records for `division.company.com`
5. Resolver queries `ns1.division.company.com` directly
6. Child server returns authoritative answer for `www.division.company.com`

#### NS (Name Server) Records

NS records are the foundation of DNS delegation:

**Format**: `subdomain IN NS nameserver-fqdn`

**Requirements**:

- **Minimum Two NS Records**: Redundancy requires at least two name servers per delegation
- **Fully Qualified Domain Names**: NS records must specify complete FQDNs (ending with dot)
- **Reachable Name Servers**: All listed name servers must be accessible and operational
- **Consistent Configuration**: All name servers should return identical zone data
- **Parent and Child Agreement**: NS records in parent should match NS records in child zone's SOA

**Best Practices**:

- Deploy 3-4 name servers for critical zones
- Distribute name servers across different networks/locations
- Monitor all delegated name servers for availability
- Maintain current contact information for delegated zone administrators

#### Glue Records and Their Importance

Glue records solve the circular dependency problem in DNS delegation.

**The Problem**:

If `division.company.com` is delegated to `ns1.division.company.com`, a resolver faces a circular dependency:

- To resolve `www.division.company.com`, it needs to contact `ns1.division.company.com`
- To resolve `ns1.division.company.com`, it needs to contact `ns1.division.company.com`

**The Solution - Glue Records**:

The parent zone includes A (or AAAA) records for name servers within the delegated zone:

```text
; In parent zone: company.com
division.company.com.      IN  NS  ns1.division.company.com.
division.company.com.      IN  NS  ns2.division.company.com.
ns1.division.company.com.  IN  A   10.20.30.10  ; Glue record
ns2.division.company.com.  IN  A   10.20.30.11  ; Glue record
```

**When Glue Records Are Required**:

- Name servers are within the delegated zone (in-bailiwick)
- IPv6 AAAA glue records for IPv6-enabled name servers

**When Glue Records Are NOT Required**:

- Name servers are outside the delegated zone (out-of-bailiwick)
- Example: `division.company.com` delegated to `ns1.hosting-provider.net`

**Common Glue Record Issues**:

- **Missing Glue**: Delegation fails completely; subdomain unresolvable
- **Incorrect IP Addresses**: Queries sent to wrong servers or fail to reach name servers
- **Stale Glue**: IP addresses changed but parent zone glue not updated
- **Inconsistent Glue**: Glue in parent doesn't match A records in child zone

#### Delegation vs. Forwarding

Delegation and forwarding are often confused but serve different purposes:

**Delegation**:

- **Authority Transfer**: Child zone becomes independently authoritative
- **Persistent**: NS records permanently establish the delegation
- **Hierarchical**: Follows standard DNS hierarchy
- **Recursive Behavior**: Resolvers follow referrals to delegated servers
- **Use Case**: Permanent organizational boundaries, Active Directory child domains

**Forwarding**:

- **Proxy Queries**: Forwarding server sends queries on behalf of clients
- **No Authority Transfer**: Forwarded-to servers don't become authoritative
- **Configuration-Based**: Set up on resolvers, not in zone files
- **Performance Optimization**: Reduces external query load
- **Use Case**: Routing queries to specific resolvers for performance or policy reasons

**Conditional Forwarding**:

A special case where specific domain queries are forwarded to designated servers:

```powershell
# Windows DNS conditional forwarder
Add-DnsServerConditionalForwarderZone -Name "partner.com" -MasterServers "192.0.2.10","192.0.2.11"
```

This forwards all queries for `partner.com` to the specified servers without delegation.

### Active Directory DNS Delegation

Active Directory deployments require specific DNS delegation patterns to function correctly. AD relies on DNS for domain controller location and authentication services.

#### Why Delegate AD DNS Zones

Active Directory child domains require DNS delegation for several critical reasons:

**Domain Controller Location**:

- Clients must locate domain controllers in child domains
- SRV records for child domains must be resolvable
- Cross-domain authentication depends on DNS resolution

**Kerberos Authentication**:

- Kerberos requires accurate SRV records for KDC location
- `_kerberos._tcp.childdom.company.com` must resolve correctly
- Without delegation, authentication to child domain fails

**Global Catalog Queries**:

- Forest-wide searches require GC location
- GC SRV records span forest but use domain-specific names
- Delegation ensures GC servers discoverable in all domains

**Site-Aware Service Location**:

- AD clients locate nearest domain controllers using site information
- Site-specific SRV records like `_ldap._tcp.sitename._sites.childdom.company.com`
- Proper delegation enables site-aware DC location

**Trust Relationships**:

- Trust establishment and validation require DNS resolution
- Trust referral tickets require locating KDCs in trusted domains

#### Parent Zone Requirements

The parent domain must properly configure delegation for child domains:

**NS Record Creation**:

In the parent zone (`company.com`), create NS records for child domain:

```powershell
# Windows DNS Server
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "child" `
    -NS -NameServer "dc1.child.company.com"
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "child" `
    -NS -NameServer "dc2.child.company.com"
```

**Glue Record Creation**:

Add A records for child domain controllers in parent zone:

```powershell
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "dc1.child" `
    -A -IPv4Address "10.20.30.10"
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "dc2.child" `
    -A -IPv4Address "10.20.30.11"
```

**Delegation Verification**:

```powershell
# Verify delegation from parent
Resolve-DnsName -Name "child.company.com" -Type NS -Server "dc1.company.com"

# Verify child domain reachable
Resolve-DnsName -Name "dc1.child.company.com" -Type A -Server "dc1.company.com"
```

**Parent Zone Considerations**:

- All parent domain controllers should host the parent zone
- Delegation records must replicate to all parent DCs
- DNS zone replication should be verified after delegation creation
- Test delegation from multiple parent DCs

#### Child Zone Configuration

Child domain controllers must properly configure their DNS zones:

**Zone Creation**:

Child domain DCs automatically create AD-integrated DNS zones during dcpromo:

- **Primary Zone Type**: Active Directory-Integrated
- **Replication Scope**: All domain controllers in the domain
- **Dynamic Updates**: Secure only (domain-joined computers only)

**SOA and NS Records**:

Child zone must contain proper SOA and NS records:

```text
; Child zone: child.company.com
@  IN  SOA  dc1.child.company.com. hostmaster.child.company.com. (...)
@  IN  NS   dc1.child.company.com.
@  IN  NS   dc2.child.company.com.
```

**SRV Record Registration**:

Domain controllers automatically register SRV records:

- `_ldap._tcp.child.company.com`
- `_ldap._tcp.dc._msdcs.child.company.com`
- `_kerberos._tcp.child.company.com`
- `_gc._tcp.forest.com` (if hosting Global Catalog)
- Site-specific SRV records

**Verification Commands**:

```cmd
# Verify SRV record registration
nslookup -type=SRV _ldap._tcp.child.company.com

# Verify DC can resolve parent domain
nslookup dc1.company.com

# Check DNS configuration
dcdiag /test:dns /v
```

#### Conditional Forwarders vs. Delegation

Active Directory environments often use both delegation and conditional forwarding:

**When to Use Delegation**:

- **Child Domains**: Always use delegation for AD child domains
- **Permanent Structure**: Organizational boundaries unlikely to change
- **Full Authority**: Child domain needs complete control over its namespace
- **Standard AD Hierarchy**: Following Microsoft best practices

**When to Use Conditional Forwarding**:

- **Forest Trusts**: Forward queries for trusted forest domains
- **Partner Networks**: Route queries to partner organization DNS servers
- **Split-Brain Scenarios**: Direct internal queries to internal DNS servers
- **Performance Optimization**: Reduce query latency for specific domains

**Combined Approach Example**:

```powershell
# Delegation for child domain (in parent zone)
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "sales" `
    -NS -NameServer "dc1.sales.company.com"

# Conditional forwarder for trusted forest (on all DCs)
Add-DnsServerConditionalForwarderZone -Name "partner.com" `
    -ReplicationScope "Forest" -MasterServers "192.0.2.10"
```

**Key Differences**:

| Aspect | Delegation | Conditional Forwarding |
| ------ | ---------- | -------------------- |
| Authority | Transfers authority to child | No authority transfer |
| Configuration | Zone NS records | Server forwarding config |
| Persistence | Permanent via DNS | Config-based, can change |
| Replication | Via zone data | AD replication (if AD-stored) |
| Use Case | AD hierarchy | Cross-forest, partners |

#### Multi-Domain Forest Delegation Patterns

Complex AD forests require careful delegation planning:

**Single-Level Child Domains**:

```text
Forest: company.com
├── company.com (forest root)
├── sales.company.com (delegated child)
├── engineering.company.com (delegated child)
└── operations.company.com (delegated child)
```

Each child domain delegated from parent with NS and glue records.

**Multi-Level Hierarchy**:

```text
Forest: company.com
├── company.com (forest root)
├── us.company.com (delegated child)
│   ├── east.us.company.com (delegated grandchild)
│   └── west.us.company.com (delegated grandchild)
└── europe.company.com (delegated child)
    ├── uk.europe.company.com
    └── germany.europe.company.com
```

**Delegation Chain**:

- `company.com` delegates `us.company.com`
- `us.company.com` delegates `east.us.company.com`
- Each level maintains NS records for its children

**Tree Root Domains**:

```text
Forest: company.com
├── company.com (forest root)
├── sales.company.com (child in same tree)
└── subsidiary.net (separate tree in same forest)
```

`subsidiary.net` is NOT delegated from `company.com` (different namespace), but both share the same forest and require DNS name resolution between trees.

**_msdcs Zone Considerations**:

- Forest root maintains `_msdcs.forestroot.com`
- Contains forest-wide service locations
- Not delegated to child domains
- All domains reference forest root `_msdcs` zone

### Delegation Best Practices

#### Planning Delegation Hierarchy

Effective delegation requires thoughtful planning:

**Align with Organizational Structure**:

- Mirror business units, divisions, or subsidiaries
- Reflect reporting structures and administrative boundaries
- Consider future reorganizations and mergers

**Consider Administrative Boundaries**:

- Delegate where different teams manage resources
- Match delegation to IT organizational structure
- Ensure clear ownership and responsibility

**Limit Delegation Depth**:

- Avoid excessive delegation levels (more than 3-4 levels)
- Each level adds query latency and complexity
- Deeper hierarchies harder to troubleshoot

**Plan for Growth**:

- Reserve namespace for future divisions or services
- Use consistent naming conventions across delegations
- Document delegation strategy and rationale

#### Delegation for Organizational Units

Aligning DNS delegation with organizational structure:

**Geographic Delegation**:

```text
company.com
├── americas.company.com
│   ├── us.americas.company.com
│   └── canada.americas.company.com
├── emea.company.com
│   ├── uk.emea.company.com
│   └── germany.emea.company.com
└── apac.company.com
    ├── australia.apac.company.com
    └── singapore.apac.company.com
```

**Functional Delegation**:

```text
company.com
├── sales.company.com
├── engineering.company.com
├── marketing.company.com
└── operations.company.com
```

**Hybrid Approach**:

```text
company.com
├── us.company.com
│   ├── sales.us.company.com
│   └── engineering.us.company.com
└── europe.company.com
    ├── sales.europe.company.com
    └── engineering.europe.company.com
```

#### Geographic Delegation Strategies

Geographic distribution offers specific benefits:

**Performance Benefits**:

- Local name resolution reduces latency
- Queries resolved by geographically-close servers
- Reduces WAN traffic for DNS queries

**Administrative Autonomy**:

- Regional IT teams manage local DNS
- Changes implemented during local business hours
- Reduced dependency on central IT

**Disaster Recovery**:

- Regional outages don't affect other regions
- Each region maintains independent DNS infrastructure

**Compliance**:

- Data residency requirements met by local DNS
- Regulatory boundaries respected

**Implementation Example**:

```powershell
# North America delegation
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "na" `
    -NS -NameServer "ns1.na.company.com"
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "ns1.na" `
    -A -IPv4Address "10.10.10.10"

# Europe delegation
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "eu" `
    -NS -NameServer "ns1.eu.company.com"
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "ns1.eu" `
    -A -IPv4Address "10.20.10.10"
```

#### Delegation Security Considerations

Securing delegated zones requires attention to multiple factors:

**DNSSEC for Delegations**:

- Parent zone must include DS (Delegation Signer) records for signed child zones
- Child zone must provide DNSKEY records to parent
- Maintain chain of trust from parent to child

**Access Control**:

- Restrict zone transfer permissions on delegated zones
- Implement TSIG for authenticated zone transfers
- Use DNSSEC TSIG for secure dynamic updates

**Monitoring Delegated Zones**:

- Monitor availability of delegated name servers
- Alert on delegation breakage or misconfigurations
- Track query rates and identify anomalies

**Change Control**:

- Document delegation ownership and contacts
- Require approval for delegation changes
- Test delegation changes in non-production first

**Prevent Subdomain Takeover**:

- Monitor for dangling DNS delegations (NS points to unregistered domain)
- Remove delegations when child zones decommissioned
- Regularly audit delegation records

#### Testing Delegation Configuration

Thorough testing prevents delegation issues:

**Basic Delegation Test**:

```bash
# Query child zone from parent name server
dig @parent-dns-server.com child.company.com NS

# Should return NS records for child zone
# Should NOT return authoritative answer (AA flag should not be set)

# Query child zone from child name server
dig @ns1.child.company.com child.company.com NS

# Should return NS records with AA flag set
```

**Glue Record Verification**:

```bash
# Query with +trace to see delegation path
dig child.company.com +trace

# Look for glue records in additional section
dig @parent-dns-server.com child.company.com NS +additional
```

**End-to-End Resolution Test**:

```bash
# Test resolution of record in delegated zone
dig www.child.company.com A

# Verify response comes from delegated name servers
# Check authority section for child zone NS records
```

**Windows-Specific Tests**:

```powershell
# Test from parent domain controller
Resolve-DnsName -Name "child.company.com" -Type NS -Server "parent-dc.company.com"

# Test from child domain controller
Resolve-DnsName -Name "www.child.company.com" -Server "child-dc.child.company.com"

# Comprehensive DNS test
dcdiag /test:dns /v
```

#### Common Delegation Mistakes

##### Mistake 1: Missing or Incorrect NS Records

Problem: Parent zone lacks NS records or has typos in name server names

Impact: Subdomain completely unresolvable

Solution:

```bash
# Verify NS records in parent
dig @parent-dns.com child.company.com NS
```

##### Mistake 2: Missing Glue Records

Problem: Parent zone missing A records for in-bailiwick name servers

Impact: Circular dependency prevents resolution

Solution:

```bash
# Check for glue in additional section
dig @parent-dns.com child.company.com NS +additional
```

##### Mistake 3: Inconsistent NS Records

Problem: NS records in parent don't match NS records in child zone

Impact: Some name servers unreachable, intermittent failures

Solution: Ensure NS records match in both zones

##### Mistake 4: Unreachable Name Servers

Problem: Delegated name servers not accessible (firewall, server down, wrong IP)

Impact: Queries fail or time out

Solution: Monitor name server availability, test from multiple locations

##### Mistake 5: Delegating Non-Existent Zones

Problem: NS records point to servers that don't host the zone

Impact: SERVFAIL responses, failed resolution

Solution: Verify zone exists on all delegated name servers

##### Mistake 6: Forgetting to Update Glue After IP Changes

Problem: Name server IP address changed but glue not updated in parent

Impact: Queries sent to old IP addresses, resolution fails

Solution: Maintain inventory of glue records, update parent when child IPs change

### Practical Delegation Scenarios

#### Delegating Subdomains to Different Teams

**Scenario**: Large organization wants development, QA, and production teams to manage their own DNS zones independently.

**Solution**:

```text
company.com (Corporate IT manages)
├── dev.company.com (Development team manages)
├── qa.company.com (QA team manages)
└── prod.company.com (Operations team manages)
```

**Implementation**:

```powershell
# Corporate IT creates delegations
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "dev" `
    -NS -NameServer "ns1.dev.company.com"
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "ns1.dev" `
    -A -IPv4Address "10.10.10.10"

Add-DnsServerResourceRecord -ZoneName "company.com" -Name "qa" `
    -NS -NameServer "ns1.qa.company.com"
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "ns1.qa" `
    -A -IPv4Address "10.20.10.10"

Add-DnsServerResourceRecord -ZoneName "company.com" -Name "prod" `
    -NS -NameServer "ns1.prod.company.com"
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "ns1.prod" `
    -A -IPv4Address "10.30.10.10"
```

**Benefits**:

- Each team has full control over their namespace
- Changes don't require corporate IT approval
- Environments clearly separated in DNS
- Reduced ticket volume for corporate IT

**Considerations**:

- Establish naming conventions across all delegated zones
- Implement monitoring for all delegated name servers
- Maintain documentation of team contacts
- Set up alerts for delegation issues

#### Branch Office Delegation

**Scenario**: Multi-site organization with branch offices requiring local DNS management and WAN failure resilience.

**Solution**: Delegate branch-specific zones to branch DNS servers with local authority.

```text
company.com (Headquarters)
├── branch-nyc.company.com (New York branch)
├── branch-lon.company.com (London branch)
└── branch-tok.company.com (Tokyo branch)
```

**Implementation**:

```powershell
# Delegate NYC branch
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "branch-nyc" `
    -NS -NameServer "ns1.branch-nyc.company.com"
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "ns1.branch-nyc" `
    -A -IPv4Address "10.100.1.10"

# Configure conditional forwarder on branch for corporate zones
# On NYC branch DNS server:
Add-DnsServerConditionalForwarderZone -Name "company.com" `
    -MasterServers "10.1.1.10","10.1.1.11" # HQ DNS servers
```

**Benefits**:

- Branch DNS operational during WAN outages
- Local resolution for branch resources
- Reduced WAN bandwidth for DNS queries
- Branch IT autonomy

**Considerations**:

- Implement site-to-site VPN for secure DNS communication
- Configure forwarders to headquarters for non-branch queries
- Monitor WAN links and DNS reachability
- Document failover procedures

#### DMZ and Security Zone Delegation

**Scenario**: Security policy requires separate DNS infrastructure for DMZ resources, managed by security team.

**Solution**: Delegate DMZ subdomain to dedicated DNS servers in DMZ network segment.

```text
company.com (Internal network)
└── dmz.company.com (DMZ zone on separate servers)
```

**Implementation**:

```powershell
# Create delegation from internal DNS
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "dmz" `
    -NS -NameServer "ns1.dmz.company.com"
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "ns1.dmz" `
    -A -IPv4Address "172.16.1.10"
```

**Security Considerations**:

- DMZ DNS servers accessible from both internal and internet
- Implement strict ACLs on DMZ DNS servers
- Separate admin credentials for DMZ DNS
- Enhanced logging and monitoring for DMZ zone changes
- Regular security audits of DMZ DNS configuration

**Network Design**:

```text
Internet
   ↓
Firewall (allows UDP/53, TCP/53 to DMZ DNS)
   ↓
DMZ (172.16.1.0/24)
   ├── ns1.dmz.company.com (172.16.1.10)
   └── ns2.dmz.company.com (172.16.1.11)
   ↓
Firewall (allows DNS queries from internal to DMZ)
   ↓
Internal Network (10.0.0.0/8)
   ├── ns1.company.com (10.1.1.10)
   └── ns2.company.com (10.1.1.11)
```

#### Third-Party Managed Zones

**Scenario**: Organization uses third-party SaaS provider requiring custom subdomain delegation for branded service.

**Solution**: Delegate subdomain to provider's DNS servers.

**Example - Delegating** `portal.company.com` **to SaaS Provider**:

```powershell
# Delegate to provider's name servers (out-of-bailiwick, no glue needed)
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "portal" `
    -NS -NameServer "ns1.saas-provider.com"
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "portal" `
    -NS -NameServer "ns2.saas-provider.com"
```

**Verification**:

```bash
# Verify delegation working
dig portal.company.com NS

# Should show provider's name servers
```

**Use Cases**:

- Custom domain for Microsoft 365 / Office 365
- Delegated subdomain for Shopify store
- Custom vanity domain for marketing platform
- Branded subdomain for support ticketing system

**Best Practices**:

- Document the delegation and provider contact info
- Monitor delegated subdomain availability
- Review provider SLA for DNS uptime
- Test delegation before going live
- Maintain ability to revoke delegation if needed

**Security Considerations**:

- Verify provider's DNS security practices
- Confirm DNSSEC support if required
- Understand implications of provider DNS compromise
- Consider using CNAME instead of delegation where possible

#### Cloud Environment Integration

**Scenario**: Hybrid cloud deployment with resources in Azure, AWS, and on-premises requiring unified DNS namespace.

**Solution**: Strategic delegation and conditional forwarding to integrate cloud DNS.

**Architecture**:

```text
company.com (On-premises)
├── azure.company.com (Delegated to Azure DNS)
├── aws.company.com (Delegated to AWS Route 53)
└── onprem.company.com (On-premises resources)
```

**Azure DNS Delegation**:

```powershell
# Create Azure DNS zone
New-AzDnsZone -ResourceGroupName "MyRG" -Name "azure.company.com"

# Note the assigned Azure DNS name servers
Get-AzDnsZone -ResourceGroupName "MyRG" -Name "azure.company.com"
# Returns: ns1-01.azure-dns.com, ns2-01.azure-dns.net, etc.

# Delegate from on-premises DNS
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "azure" `
    -NS -NameServer "ns1-01.azure-dns.com."
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "azure" `
    -NS -NameServer "ns2-01.azure-dns.net."
```

**AWS Route 53 Delegation**:

```bash
# Create Route 53 hosted zone
aws route53 create-hosted-zone --name aws.company.com --caller-reference "2024-01-13"

# Note the assigned name servers (in the NS record set)
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890ABC --query "ResourceRecordSets[?Type=='NS']"
```

```powershell
# Delegate from on-premises DNS
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "aws" `
    -NS -NameServer "ns-1234.awsdns-10.org."
Add-DnsServerResourceRecord -ZoneName "company.com" -Name "aws" `
    -NS -NameServer "ns-5678.awsdns-20.com."
```

**Hybrid Resolution Configuration**:

**On-Premises to Cloud**:

- Delegation handles queries from on-premises to cloud resources
- Public DNS resolution for cloud name servers

**Cloud to On-Premises**:

- Azure: Configure custom DNS servers in VNets pointing to on-premises
- AWS: VPC DNS resolver with outbound endpoints forwarding to on-premises
- Both: Conditional forwarding rules for on-premises domains

**Best Practices**:

- Use automation (Terraform, ARM templates) for cloud DNS configuration
- Implement DNS failover between cloud providers
- Monitor delegated cloud DNS zones
- Document cloud DNS architecture and delegation flow
- Test cross-environment name resolution regularly

This comprehensive DNS delegation coverage provides the practical knowledge needed to implement delegations in complex enterprise environments.

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
