---
title: "Split-Brain DNS"
description: "Split-horizon DNS concepts, implementation strategies, configuration examples, and best practices"
author: "Joseph Streeter"
tags: ["dns", "enterprise", "split-brain", "split-horizon", "views"]
category: "services"
last_updated: "2026-08-01"
---
## Split-Brain DNS (Split-Horizon DNS)

Split-brain DNS, also known as split-horizon or split-view DNS, is an architectural pattern where different DNS responses are provided for the same domain name depending on the source of the query. This approach enables organizations to present different views of their namespace to internal users versus external internet users.

### Concept and Architecture

#### Definition and Purpose

Split-brain DNS maintains two separate DNS zones for the same domain name:

- **External Zone**: Contains publicly accessible resources with public IP addresses, visible to internet users
- **Internal Zone**: Contains internal resources with private IP addresses, visible only to corporate network users

For example, `mail.company.com` might resolve to:

- `203.0.113.50` (public IP) when queried from the internet
- `10.20.30.40` (private IP) when queried from the internal network

This architecture provides several key benefits:

- **Security**: Internal infrastructure remains hidden from external reconnaissance
- **Performance**: Internal clients connect directly to private IP addresses, avoiding NAT hairpinning
- **Flexibility**: Maintain different services for internal and external users under the same hostname
- **Cost Optimization**: Avoid bandwidth charges for internal-to-internal communication through public gateways

#### When to Use Split-Brain DNS

Split-brain DNS is appropriate for organizations with:

- **Dual-Homed Services**: Applications accessible both internally and externally (web portals, email, collaboration tools)
- **Security Requirements**: Need to hide internal infrastructure topology from external view
- **Performance Optimization**: Want internal clients to access services via private network paths
- **Hybrid Cloud Deployments**: Maintain consistent namespace across on-premises and cloud environments
- **Regulatory Compliance**: Must segment internal and external network access for audit purposes

Common use cases include:

- Corporate websites with internal-only administration interfaces
- Email systems with external MX records and internal submission servers
- VPN portals accessible from both internal and external networks
- Application APIs with different endpoints for internal and external consumers
- SharePoint or collaboration platforms with enhanced internal functionality

#### Internal vs. External Name Resolution

The split-brain architecture creates two distinct resolution paths:

**External Resolution Path**:

1. Internet client queries public DNS resolvers
2. Query forwarded to organization's authoritative DNS servers
3. External DNS zone returns public IP addresses
4. Client connects to public-facing infrastructure (load balancers, reverse proxies, firewalls)
5. Traffic potentially inspected and forwarded to internal resources

**Internal Resolution Path**:

1. Internal client queries corporate DNS resolvers
2. Resolver checks internal DNS zone (higher priority)
3. Internal DNS zone returns private IP addresses
4. Client connects directly to internal servers
5. Traffic remains on private network, bypassing perimeter security devices

#### Security and Access Control Benefits

Split-brain DNS enhances security posture:

- **Topology Hiding**: External DNS reveals only public-facing assets, concealing internal infrastructure
- **Reduced Attack Surface**: Internal resources not discoverable through external DNS reconnaissance
- **Access Segregation**: Internal-only resources absent from external zones entirely
- **Defense in Depth**: Additional layer complementing firewalls and network segmentation
- **Audit and Compliance**: Clear separation of internal and external resources for regulatory requirements

### Implementation Strategies

Organizations can implement split-brain DNS using several technical approaches, each with specific advantages and trade-offs.

#### Same Domain Name, Different Zones

The most common approach maintains two completely separate zone files for the same domain:

```text
External Zone (company.com):
  www.company.com     A    203.0.113.10
  mail.company.com    A    203.0.113.20
  vpn.company.com     A    203.0.113.30

Internal Zone (company.com):
  www.company.com     A    10.10.10.10
  mail.company.com    A    10.10.10.20
  vpn.company.com     A    10.10.10.30
  fileserver.company.com  A    10.10.10.50
  database.company.com    A    10.10.10.60
```

**Advantages**:

- Complete control over internal and external records
- Maximum flexibility for different record sets
- Clear separation for security and compliance

**Disadvantages**:

- Requires manual synchronization of common records
- Risk of inconsistency between zones
- Double maintenance burden

#### Separate DNS Servers for Internal/External

Deploy physically or logically separate DNS infrastructure:

- **External DNS Servers**: Hosted in DMZ or cloud, serve external queries only
- **Internal DNS Servers**: Hosted on internal network or domain controllers, serve internal queries only

Configuration requirements:

- **External servers**: Publicly accessible IP addresses, restricted zone transfers, hardened security
- **Internal servers**: Private IP addresses, integrated with Active Directory, support dynamic updates
- **Network separation**: Firewall rules preventing internal DNS servers from being queried externally
- **Client configuration**: Internal clients configured to use internal DNS servers

#### View-Based DNS Configuration

Modern DNS servers (BIND, PowerDNS, Microsoft DNS with policies) support view-based configurations:

**BIND Views Example**:

```text
view "internal" {
    match-clients { 10.0.0.0/8; 172.16.0.0/12; 192.168.0.0/16; };
    zone "company.com" {
        type master;
        file "internal/company.com.zone";
    };
};

view "external" {
    match-clients { any; };
    zone "company.com" {
        type master;
        file "external/company.com.zone";
    };
};
```

**Windows DNS Policies** (Server 2016+):

```powershell
# Create internal subnet scope
Add-DnsServerClientSubnet -Name "InternalNetwork" -IPv4Subnet "10.0.0.0/8"

# Create zone scope for internal view
Add-DnsServerZoneScope -ZoneName "company.com" -Name "InternalScope"

# Add internal records to internal scope
Add-DnsServerResourceRecord -ZoneName "company.com" -A -Name "www" -IPv4Address "10.10.10.10" -ZoneScope "InternalScope"

# Create query resolution policy
Add-DnsServerQueryResolutionPolicy -Name "InternalPolicy" -Action ALLOW -ClientSubnet "eq,InternalNetwork" -ZoneScope "InternalScope,1" -ZoneName "company.com"
```

**Advantages**:

- Single DNS server infrastructure
- Reduced hardware/licensing costs
- Centralized management

**Disadvantages**:

- More complex configuration
- Single point of failure (mitigated with clustering)
- Potential performance impact with large view sets

#### Zone File Management

Effective split-brain implementation requires careful zone file management:

- **Version Control**: Store zone files in Git or other VCS for change tracking
- **Automation**: Use infrastructure-as-code tools (Ansible, Terraform) for zone deployment
- **Validation**: Implement pre-deployment validation to catch syntax errors
- **Testing**: Maintain test environments to verify changes before production
- **Documentation**: Clearly document which records exist in which views/zones

#### Record Synchronization Considerations

Maintaining consistency for records that should match across internal/external zones:

- **Common Records**: Identify records that must remain synchronized (MX, TXT for SPF/DKIM, some CNAMEs)
- **Automation Tools**: Develop scripts to synchronize specific records between zones
- **Single Source of Truth**: Maintain one authoritative source (database, YAML file) for shared records
- **Change Management**: Require explicit approval for records that differ between internal/external
- **Monitoring**: Alert on unexpected differences in records that should match

### Configuration Examples

#### Windows DNS Server Implementation

Windows DNS Server supports split-brain through DNS Policies (Server 2016 and later):

```powershell
# Step 1: Define internal network subnet
Add-DnsServerClientSubnet -Name "CorpNetwork" -IPv4Subnet @("10.0.0.0/8", "172.16.0.0/12")

# Step 2: Create internal zone scope
Add-DnsServerZoneScope -ZoneName "contoso.com" -Name "Internal"

# Step 3: Add internal records
Add-DnsServerResourceRecord -ZoneName "contoso.com" -A -Name "intranet" `
    -IPv4Address "10.20.30.40" -ZoneScope "Internal"

Add-DnsServerResourceRecord -ZoneName "contoso.com" -A -Name "www" `
    -IPv4Address "10.20.30.50" -ZoneScope "Internal"

# Step 4: Add external records (default scope)
Add-DnsServerResourceRecord -ZoneName "contoso.com" -A -Name "www" `
    -IPv4Address "203.0.113.10"

# Step 5: Create query resolution policy
Add-DnsServerQueryResolutionPolicy -Name "InternalPolicy" `
    -Action ALLOW -ClientSubnet "eq,CorpNetwork" `
    -ZoneScope "Internal,1" -ZoneName "contoso.com"

# Verify configuration
Get-DnsServerQueryResolutionPolicy -ZoneName "contoso.com"
Get-DnsServerZoneScope -ZoneName "contoso.com"
```

For older Windows DNS versions without policy support, use separate DNS servers or conditional forwarding.

#### BIND Split-Horizon Configuration

BIND views provide powerful split-brain capabilities:

```text
# /etc/named.conf

acl "internal-networks" {
    10.0.0.0/8;
    172.16.0.0/12;
    192.168.0.0/16;
    localhost;
    localnets;
};

view "internal-view" {
    match-clients { internal-networks; };
    recursion yes;
    
    zone "company.com" {
        type master;
        file "/var/named/internal/company.com.zone";
        allow-update { none; };
    };
    
    zone "10.in-addr.arpa" {
        type master;
        file "/var/named/internal/10.in-addr.arpa.zone";
    };
};

view "external-view" {
    match-clients { any; };
    recursion no;
    
    zone "company.com" {
        type master;
        file "/var/named/external/company.com.zone";
        allow-transfer { slave-servers; };
    };
};
```

**Internal Zone File** (`/var/named/internal/company.com.zone`):

```text
$TTL 3600
@   IN  SOA ns1.company.com. admin.company.com. (
        2024011301 ; Serial
        3600       ; Refresh
        1800       ; Retry
        604800     ; Expire
        86400 )    ; Minimum

    IN  NS  ns1.company.com.
    IN  NS  ns2.company.com.

ns1         IN  A   10.10.10.1
ns2         IN  A   10.10.10.2
www         IN  A   10.20.30.10
mail        IN  A   10.20.30.20
intranet    IN  A   10.20.30.30
fileserver  IN  A   10.20.30.40
```

**External Zone File** (`/var/named/external/company.com.zone`):

```text
$TTL 3600
@   IN  SOA ns1.company.com. admin.company.com. (
        2024011301 ; Serial
        3600       ; Refresh
        1800       ; Retry
        604800     ; Expire
        86400 )    ; Minimum

    IN  NS  ns1.company.com.
    IN  NS  ns2.company.com.
    IN  MX  10 mail.company.com.

ns1  IN  A   203.0.113.1
ns2  IN  A   203.0.113.2
www  IN  A   203.0.113.10
mail IN  A   203.0.113.20
```

#### Cloud Provider Solutions

**Azure DNS Private Zones**:

Azure DNS Private Zones provide split-brain functionality for Azure virtual networks:

```powershell
# Create private DNS zone
New-AzPrivateDnsZone -ResourceGroupName "MyResourceGroup" -Name "company.com"

# Link to virtual network
New-AzPrivateDnsVirtualNetworkLink -ResourceGroupName "MyResourceGroup" `
    -ZoneName "company.com" -Name "MyVNetLink" `
    -VirtualNetworkId "/subscriptions/.../virtualNetworks/MyVNet" `
    -EnableAutoRegistration

# Add private record
New-AzPrivateDnsRecordSet -ResourceGroupName "MyResourceGroup" `
    -ZoneName "company.com" -Name "webapp" -RecordType A `
    -Ttl 3600 -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address "10.1.0.4")
```

Public zone maintained separately in Azure DNS or external provider.

**AWS Route 53 Private Hosted Zones**:

```bash
# Create private hosted zone
aws route53 create-hosted-zone --name company.com \
    --vpc VPCRegion=us-east-1,VPCId=vpc-123456 \
    --caller-reference "internal-$(date +%s)" \
    --hosted-zone-config PrivateZone=true

# Add internal record
aws route53 change-resource-record-sets --hosted-zone-id Z1234567890ABC \
    --change-batch '{
      "Changes": [{
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "webapp.company.com",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [{"Value": "10.0.1.10"}]
        }
      }]
    }'
```

Public hosted zone created separately for external resolution.

#### Hybrid Cloud Scenarios

Hybrid environments require DNS integration across on-premises and cloud:

**Azure-Connected Networks**:

1. Azure Private DNS zones for internal Azure resources
2. On-premises DNS servers with conditional forwarders to Azure DNS (168.63.129.16)
3. Azure VMs configured with custom DNS pointing to on-premises resolvers
4. DNS forwarding zones on-premises for `*.azure.com` domains

**AWS Hybrid DNS**:

1. Route 53 Resolver inbound endpoints for cloud-to-on-premises queries
2. Route 53 Resolver outbound endpoints for on-premises-to-cloud queries
3. Forwarding rules directing specific domains to appropriate resolvers
4. Private hosted zones for internal AWS resources

**Cross-Cloud Split-Brain**:

Organizations with multi-cloud deployments may maintain:

- On-premises internal DNS as authoritative for internal views
- Azure Private DNS zones for Azure-specific resources
- AWS Private Hosted Zones for AWS-specific resources
- Conditional forwarding between environments for cross-cloud communication

### Best Practices

#### Namespace Planning

Careful planning prevents future complications:

- **Consistent Naming**: Use identical FQDNs across internal/external where services are dual-homed
- **Internal-Only Subdomains**: Consider `internal.company.com` for resources never exposed externally
- **Service-Based Naming**: Use descriptive names that indicate service function, not infrastructure details
- **Avoid Conflicts**: Never use `.local` if you might need external resolution for same names
- **Documentation**: Maintain comprehensive DNS architecture documentation with clear internal/external designation

#### Record Consistency Management

Maintain accuracy across zones:

- **Automated Synchronization**: Script synchronization of records that must match (MX, SPF, DKIM, etc.)
- **Regular Audits**: Periodically compare internal/external zones for unintended differences
- **Change Control**: Require documented justification for intentional internal/external discrepancies
- **Testing**: Test both internal and external resolution after changes
- **Monitoring**: Alert on unexpected changes to critical records in either zone

#### Certificate Implications

SSL/TLS certificates must account for split-brain DNS:

- **Subject Alternative Names (SANs)**: Ensure certificates include all necessary FQDNs
- **Internal CAs**: May use internal CA for internal-only resources with internal IPs
- **Public CAs**: Required for publicly accessible resources
- **Certificate Validation**: Clients must be able to resolve hostnames in certificates to perform validation
- **Split Certificates**: Some organizations use different certificates for internal vs. external access

#### Troubleshooting Split-Brain Issues

Common issues and diagnostic approaches:

##### Issue: Clients get wrong IP address

- Verify client DNS configuration points to correct server (internal vs. external)
- Check DNS server logs to identify which zone/view served the query
- Use `nslookup` or `dig` specifying DNS server: `nslookup www.company.com 10.10.10.1`

##### Issue: Certificate validation failures

- Verify DNS resolution matches certificate CN/SAN fields
- Check that clients can resolve all names in certificate
- Validate certificate chain is trusted by client

##### Issue: Inconsistent resolution between clients

- Check DNS server configuration for view/policy matching
- Verify client subnet definitions include all internal ranges
- Review DNS caching on clients and intermediate resolvers

##### Issue: External users accessing internal IPs

- Security risk! Verify internal DNS servers not accessible from internet
- Check firewall rules blocking external access to internal DNS
- Review DNS server ACLs and access controls

**Diagnostic Commands**:

```bash
# Test internal resolution
nslookup www.company.com 10.10.10.1

# Test external resolution
nslookup www.company.com 8.8.8.8

# Detailed query with dig
dig @10.10.10.1 www.company.com +short

# Trace resolution path
dig @10.10.10.1 www.company.com +trace
```

#### Documentation Requirements

Comprehensive documentation is essential:

- **Architecture Diagrams**: Visual representation of split-brain topology
- **Zone Inventory**: Complete list of zones with internal/external/both designation
- **Record Inventory**: Spreadsheet documenting key records in each zone
- **IP Address Plans**: Clear documentation of public vs. private IP allocations
- **Change Procedures**: Step-by-step process for making DNS changes
- **Troubleshooting Runbooks**: Common issues and resolution procedures
- **Contact Information**: DNS administrators and escalation contacts
- **Review Schedule**: Regular review and update of documentation (quarterly recommended)

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
