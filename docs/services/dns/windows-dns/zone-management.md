---
title: Windows DNS Zone Management
description: Comprehensive guide to managing DNS zones in Windows Server environments
author: Joseph Streeter
date: 2025-09-12
tags: [windows-dns-zones, dns-zone-management, windows-server, dns-administration]
---

Comprehensive guide to creating, configuring, and managing DNS zones in Windows Server environments.

## 🎯 Zone Types

### Primary Zones

Primary zones contain the master copy of zone data and allow read/write operations.

```powershell
# Create primary zone
Add-DnsServerPrimaryZone -Name "contoso.com" -ZoneFile "contoso.com.dns"

# Create Active Directory integrated primary zone
Add-DnsServerPrimaryZone -Name "contoso.com" -ReplicationScope "Forest"
```

### Secondary Zones

Secondary zones contain read-only copies of zone data from primary zones.

```powershell
# Create secondary zone
Add-DnsServerSecondaryZone -Name "contoso.com" -ZoneFile "contoso.com.dns" -MasterServers "192.168.1.10"
```

### Stub Zones

Stub zones contain only NS, SOA, and A records for zone delegation.

```powershell
# Create stub zone
Add-DnsServerStubZone -Name "contoso.com" -MasterServers "192.168.1.10"
```

## 📋 Zone Configuration

### Zone Properties

```powershell
# Configure zone aging and scavenging
Set-DnsServerZoneAging -Name "contoso.com" -Aging $true -ScavengeServers "192.168.1.10"

# Set zone transfer restrictions
Set-DnsServerPrimaryZone -Name "contoso.com" -SecureSecondaries "TransferToZoneNameServer"
```

### Record Management

```powershell
# Add A record
Add-DnsServerResourceRecordA -ZoneName "contoso.com" -Name "www" -IPv4Address "192.168.1.100"

# Add CNAME record
Add-DnsServerResourceRecordCName -ZoneName "contoso.com" -Name "mail" -HostNameAlias "exchange.contoso.com"

# Add MX record
Add-DnsServerResourceRecordMX -ZoneName "contoso.com" -Name "." -MailExchange "mail.contoso.com" -Preference 10
```

---

> **💡 Pro Tip**: Use Active Directory integrated zones for enhanced security and automatic replication in domain environments.

*Effective zone management ensures reliable DNS resolution and proper domain delegation.*
