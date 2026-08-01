---
title: "DNS Server Configuration"
description: "Configuring forwarders, recursion, caching, and server-level DNS settings"
author: "Joseph Streeter"
tags: ["dns", "enterprise", "configuration", "forwarders", "caching"]
category: "services"
last_updated: "2026-08-01"
---
## DNS Server Configuration

Server-level settings — how queries are resolved, forwarded, and cached — as
distinct from the zone and record data the server holds.

### DNS Server Configuration

DNS server configuration significantly impacts performance, security, and functionality. Proper configuration ensures reliable name resolution while protecting against threats.

#### Forwarders and Root Hints

**DNS Forwarders**:

Forwarders are DNS servers to which your DNS server sends queries it cannot resolve locally:

**Benefits**:

- **Reduced Internet Traffic**: Leverage forwarder's cache instead of querying root servers
- **Centralized Control**: Route all external queries through specific servers
- **ISP Optimization**: ISP DNS servers typically have better internet connectivity
- **Content Filtering**: Route through DNS filtering services

**Configuring Forwarders (Windows)**:

```powershell
# Add forwarders
Add-DnsServerForwarder -IPAddress "8.8.8.8","8.8.4.4"

# View current forwarders
Get-DnsServerForwarder

# Remove forwarder
Remove-DnsServerForwarder -IPAddress "8.8.8.8"
```

**Configuring Forwarders (BIND)**:

```text
options {
    forwarders {
        8.8.8.8;
        8.8.4.4;
        1.1.1.1;
    };
    forward first;  // Try forwarders first, then root servers
    // forward only;   // Only use forwarders, never root servers
};
```

**Root Hints**:

Root hints file contains IP addresses of root DNS servers (a.root-servers.net through m.root-servers.net):

**Purpose**:

- Enable recursive resolution when forwarders unavailable
- Provide starting point for iterative queries
- Required for authoritative-only servers to validate DNSSEC

**Root Hints File Location**:

- **Windows**: `%SystemRoot%\System32\dns\cache.dns`
- **BIND**: `/var/named/root.hints` or `/etc/bind/db.root`

**Updating Root Hints**:

```bash
# Download latest root hints
wget https://www.internic.net/domain/named.root -O /var/named/root.hints

# Or use dig
dig +noall +answer @a.root-servers.net . NS > /var/named/root.hints
```

```powershell
# Windows - Update root hints from Internet
Get-DnsServerRootHint | Remove-DnsServerRootHint
Invoke-DnsServerZoneRefresh -RootHint
```

**Forward First vs. Forward Only**:

- **Forward First**: Try forwarders; if they fail, use root hints
- **Forward Only**: Only use forwarders; fail if forwarders unreachable (common for internal DNS)

#### Recursion Settings

Recursion determines whether DNS server performs iterative queries on behalf of clients:

**Recursion Enabled**:

- Server performs full recursive resolution
- Builds complete answer for client
- Caches intermediate results
- Appropriate for recursive resolvers serving clients

**Recursion Disabled**:

- Server only provides authoritative answers or cached data
- Returns referrals instead of recursing
- Appropriate for authoritative-only servers
- Reduces attack surface

**Configuring Recursion (Windows)**:

```powershell
# Disable recursion (for authoritative-only servers)
Set-DnsServerRecursion -Enable $false

# Enable recursion (for recursive resolvers)
Set-DnsServerRecursion -Enable $true

# View recursion settings
Get-DnsServerRecursion
```

**Configuring Recursion (BIND)**:

```text
options {
    recursion yes;  // Enable for recursive resolvers
    // recursion no;   // Disable for authoritative-only

    allow-recursion {
        10.0.0.0/8;      // Only allow recursion from internal networks
        172.16.0.0/12;
        192.168.0.0/16;
        localhost;
    };
};
```

**Security Best Practice**:

- **Authoritative servers**: Disable recursion
- **Recursive resolvers**: Enable recursion but restrict to trusted clients
- **Never**: Allow open recursion to internet (prevents DNS amplification attacks)

#### Cache Configuration

DNS cache stores previous query results to improve performance:

**Cache Settings**:

**Maximum Cache Size**:

Limit memory used for caching:

```powershell
# Windows - Set maximum cache size (in bytes)
Set-DnsServerCache -MaxKBSize 10240  # 10 MB

# View cache settings
Get-DnsServerCache
```

```text
# BIND
options {
    max-cache-size 100M;  // Maximum cache size
};
```

**Cache TTL Limits**:

Override record TTLs to prevent excessive caching:

```powershell
# Windows - Set maximum cache TTL (seconds)
Set-DnsServerCache -MaxTTL 86400  # 24 hours max

# Set maximum negative cache TTL
Set-DnsServerCache -MaxNegativeTTL 900  # 15 minutes
```

```text
# BIND
options {
    max-cache-ttl 86400;         // Maximum positive cache
    max-ncache-ttl 10800;        // Maximum negative cache (3 hours)
};
```

**Flush Cache**:

Clear cached entries:

```powershell
# Windows - Clear entire cache
Clear-DnsServerCache

# Clear specific record
Clear-DnsServerCache -Name "www.example.com" -Type A
```

```bash
# BIND - Flush cache
rndc flush

# Flush specific zone from cache
rndc flush example.com
```

**Cache Poisoning Protection**:

```text
# BIND security features
options {
    dnssec-validation auto;      // Enable DNSSEC validation
    query-source port *;         // Randomize source port
    query-source-v6 port *;      // Randomize IPv6 source port
};
```

#### Logging and Diagnostics

Comprehensive logging enables troubleshooting and security monitoring:

**Windows DNS Logging**:

```powershell
# Enable debug logging
Set-DnsServerDiagnostics -All $true

# Enable specific log categories
Set-DnsServerDiagnostics -Queries $true -QueryErrors $true -Answers $true

# Configure query logging
Set-DnsServerDiagnostics -EnableLoggingForPluginDllEvent $true `
    -LogLevel 3

# View current diagnostic settings
Get-DnsServerDiagnostics

# Configure event log settings
Set-DnsServerDiagnostics -EventLogLevel 4  # All events
```

**Log File Location**:

- **Windows**: Event Viewer > Applications and Services Logs > DNS Server
- **Debug Log**: `%SystemRoot%\System32\dns\dns.log` (if enabled)

**BIND Logging Configuration**:

```text
logging {
    channel default_file {
        file "/var/log/named/default.log" versions 3 size 5m;
        severity dynamic;
        print-time yes;
        print-severity yes;
        print-category yes;
    };
    
    channel query_file {
        file "/var/log/named/queries.log" versions 3 size 20m;
        severity info;
        print-time yes;
    };
    
    channel security_file {
        file "/var/log/named/security.log" versions 3 size 5m;
        severity info;
        print-time yes;
    };
    
    category default { default_file; };
    category queries { query_file; };
    category security { security_file; };
    category xfer-in { default_file; };
    category xfer-out { default_file; };
    category notify { default_file; };
};
```

**Query Logging**:

```text
# BIND - Enable query logging
options {
    querylog yes;
};

# Or use rndc
rndc querylog on
```

**Log Analysis Tools**:

- **dnstop**: Real-time DNS traffic analyzer
- **dnstap**: DNS logging framework with binary format
- **Splunk/ELK**: Enterprise log aggregation and analysis
- **Custom scripts**: PowerShell/Python for parsing and alerting

**Log Retention**:

- Balance disk space vs. forensic/compliance needs
- Typical retention: 30-90 days for query logs
- Longer retention for audit/security logs
- Implement log rotation and archival

#### Performance Tuning

Optimize DNS server performance for high query volumes:

**Windows DNS Performance Tuning**:

```powershell
# Increase RPC port allocation
Set-DnsServerRpcProtocol -EnableRpcOverTcp $true

# Configure recursive query timeout
Set-DnsServerRecursion -Timeout 15  # seconds

# Adjust cache settings
Set-DnsServerCache -MaxKBSize 10240 -MaxTTL 86400

# Enable round-robin
Set-DnsServerRoundRobin -Enable $true

# Configure scavenging for performance
Set-DnsServerScavenging -ScavengingState $true -ScavengingInterval 168  # hours
```

**BIND Performance Tuning**:

```text
options {
    // TCP settings
    tcp-clients 100;           // Max simultaneous TCP connections
    tcp-listen-queue 10;       // TCP connection backlog
    
    // Query limits
    recursive-clients 1000;    // Max simultaneous recursive queries
    clients-per-query 10;      // Max clients for same query
    max-clients-per-query 100; // Hard limit per query
    
    // Transfer settings
    transfers-in 10;           // Max simultaneous inbound transfers
    transfers-out 10;          // Max simultaneous outbound transfers
    transfers-per-ns 2;        // Max concurrent transfers per remote server
    
    // Performance optimizations
    minimal-responses yes;     // Reduce response size
    additional-from-cache yes; // Include additional records from cache
    fetch-glue yes;           // Fetch missing glue records
};
```

**Operating System Tuning**:

**Linux**:

```bash
# Increase file descriptors
ulimit -n 65536

# Add to /etc/security/limits.conf
named soft nofile 65536
named hard nofile 65536

# Kernel tuning in /etc/sysctl.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
```

**Windows**:

```powershell
# Increase socket pool size
netsh int ipv4 set dynamicport tcp start=49152 num=16384

# Configure network adapter settings
# Use jumbo frames if supported
# Disable offload features if causing issues
```

**Query Pattern Optimization**:

- Pre-populate cache with frequently accessed records
- Use views/policies for geographically distributed users
- Implement anycast for geographic load distribution
- Deploy multiple resolvers behind load balancers

**Monitoring Performance Metrics**:

- Queries per second (QPS)
- Cache hit ratio
- Response time (average/percentile)
- Concurrent recursive queries
- Memory utilization
- TCP vs UDP query ratio

#### Resource Record Limits

Configure limits to prevent resource exhaustion:

**Windows DNS Limits**:

```powershell
# Maximum records per RRset
# Configured via registry (typically default 1000)

# Maximum UDP response size
Set-DnsServerEDns -EnableProbes $true -CacheTimeout "00:15:00"
```

**BIND Resource Limits**:

```text
options {
    // Response size limits
    max-udp-size 4096;            // EDNS buffer size
    
    // Query limits
    max-recursion-depth 7;        // Max delegation depth
    max-recursion-queries 75;     // Max queries per recursion
    
    // Memory limits
    max-cache-size 1000M;         // Maximum cache size
    
    // Rate limiting
    rate-limit {
        responses-per-second 10;   // Per client rate limit
        nxdomains-per-second 5;   // NXDOMAIN rate limit
        errors-per-second 5;      // Error response limit
        window 5;                 // Time window (seconds)
    };
};
```

**Record Size Considerations**:

- UDP maximum: 512 bytes (traditional), 4096 bytes (EDNS0)
- Large responses trigger TCP fallback
- TXT records limited to 255 characters per string
- SPF records should fit in single UDP response

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
