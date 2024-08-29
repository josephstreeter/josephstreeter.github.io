# Monitoring and Logging

Created: 2019-05-13 11:30:29 -0500

Modified: 2019-05-13 11:32:12 -0500

---

Monitoring and Auditing

Auditing

All Active Directory related logs should be sent to Splunk as the organization's centralized logging facility.

Monitoring

## Performance Counter Graphing

SCOM Management Packs

Security System-Wide Statistics

- KDC AS Requests
- KDC TGS Requests
- Kerberos Authentication

Database

- Database Cache % Hit
- Database Page Fault Stalls/sec
- Database Page Evictions/sec
- Database Cache Size (MB)

NTDS

- LDAP Successful Binds/sec

Available Disk Space

- System volume
- SYSVOL/Database volume
- Logs volume

Diagnostic Logging

[Garbage collection diagnostic logging is configured for "minimal" on three of the domain controllers.]{.mark}

[Diagnostic logging should be configured the same across all domain controllers by turning on Garbage Collection logging on the remaining DCs.]{.mark}

## Services to Monitor

The following services are critical to the operation of Active Directory and should be closely monitored.

| **Service** | **Description** |
|------------------------|------------------------------------------------|
| COM+ Event System | Used for components that are based on the Component Object Model (COM) |
| Remote Procedure Call (RPC) | Used to perform Remote Procedure Calls (RPCs) for COM and DCOM services |
| Active Directory Domain Services (AD DS) | The service under which Active Directory runs |
| DNS Client | The client component of DNS |
| DNS Server | The server component of DNS |
| DFS Replication | Performs SYSVOL replication between Domain Controllers (Replaces FRS) |
| Intersite Messaging | Allows DCs to send and receive messages with DCs in other sites |
| Kerberos Key Distribution Center | The AS and TGT that assigns Kerberos tickets |
| Security Accounts Manager | Used for local accounts on the Domain Controller and without it some services may not start |
| Server | Provides host services for the DC (File sharing, print sharing, and named-pipe sharing) |
| Workstation | Used to establish client-side SMB connections |
| Windows Time | Used to synchronize time throughout the domain |
| Netlogon | Maintains secure connections for authentication and DNS registration |
