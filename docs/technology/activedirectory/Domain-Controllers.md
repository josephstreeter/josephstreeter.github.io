# Domain Controllers

Created: 2019-05-12 21:57:29 -0500

Modified: 2019-05-13 11:22:46 -0500

---

## Domain Controller Configuration

A Domain Controller (DC) is a server that responds to authentication and authorization requests within the domain. Domain Controllers will not perform any functions other than Domain Controller and DNS Server.

Domain Controllers within Active Directory will be configured per the following guidelines.

## SYSVOL, Database, and Log File Locations

Domain controllers should have three volumes: System (>60GB), Database (>25GB), Logs (>4GB). By locating the database files on the system drive causes the operating system to disable write caching on the System drive and increases the possibility of system file corruption in the event of a hard shutdown. For performance reasons log files should be placed on their own drive. VMware recommends that the database and log drives be placed on a separate vSCSI controller from the system drive as well.

## VMware Storage Configuration

| Controller | Hard Drive |
|--------------------|----------------------|
| vSCSI Controller 0 | Disk1 (C:) OS > 80GB |
| vSCSI Controller 1 | Disk2 (N:) Database 25GB or greater for larger directories |
|                    | Disk3 (L:) Log files 4GB |

| Files    | Location |
|----------|----------|
| Database | N:NTDS   |
| SYSVOL   | N:SYSVOL |
| Logs     | L:Logs   |

## Replication

Replication over IPSec Configuration

The RPC replication requires many ports to be opened in the firewall resulting in an insecure environment. To simplify this the replication traffic can be confined to static port numbers and then encrypted with IPSec.

Setting Static Ports for Replication

- Set static RPC port HKEY_LOCAL_MACHINESYSTEMCurrentControlSetServicesNTDSParameters DWORD TCP/IP Port = 50000
- Set static DFSR port dfsrdiag StaticRPC /port: 50001 /Member: dc.domain.com (If no member is specified, Dfsrdiag.exe uses the local computer.)

## IPSec

The Domain Controller IPSec policies should be applied to the locally to avoid potentially isolating an individual DC from replicating with the other DCs.

### IPSec Policies

| Name | Description | Default Response Rule | Check for Policy Changes (minutes) | Master Key PFS | Auth and generate key every (Minutes/Sessions) | IKE Security Methods (integrity/Encryption/DH group) | Applied to: (Local or GPO name/Link Location)|
| Domain Controllers | Domain Controller IPSec Policy| Off | 180 | N | 480 / 0 |3DES/SHA1/Med(2)/3DES/MD5/Med(2)/DES/SHA1/Low(1)/DES/MD5/Low(1) | Local Policy |

**IPSec Rules:**Domain Controllers

| Name | Description | Mode/ (Transport or Tunnel IP) | IP Filter List | Filter Action List | Network Type | Authentication Method |
|-----|----|----|----|----|----|----|
| DC <-> DC | All Inter-Domain DC traffic | Transport | Domain Controllers | ESP-3DES-MD5-0-3600 | LAN | Kerberos |

> [!Note]
>Using MD5 in the filter action will result in a warning message. However, HMAC-MD5 is not as vulnerable as raw MD5 and is more efficient then SHA1

**IP Filter List Name:**Domain Controllers

| **Name** | **Src Address** | **Dst Address** | **Protocol** | **Src Port** | **Dst Port** | **Mirrored** |
|------------|-------------|------------|----------|---------|---------|---------|
| DC1<-> ANY | My IP Address | ANY | TCP | ANY | 50000 | Y |
| DC1<-> ANY | My IP Address | ANY | TCP | ANY | 50001 | Y |

**IP Filter Actions**

| **Name** | **Description** | **Filter Action Behavior** | **Security Method** | **AH** | **ESP** | **Session Key Lifetimes (sessions/Seconds)** | **Accept Clear** | **Allow Fallback** | **Use PFS** |
|------|----------|--------|-------|-----|---------|-------------|-------|-------|-----|
| ESP-3DES-SHA1-0-3600 | Require ESP 3DES/SHA1, no inbound clear, no fallback to clear, No PFS | Negotiate Security | Custom | N/A | 3DES/SHA1 | 0 / 3600 | N | N | N |
| ESP-3DES-MD5-0-3600 | Require ESP 3DES/MD5, no inbound clear, no fallback to clear, No PFS | Negotiate Security | Custom | N/A | 3DES/MD5 | 0 / 3600 | N | N | N |

Firewall

**Firewall Configuration**

| **Service** | **Port/protocol** | **Notes** |
|----------------------------|---------------|------------------------------|
| RPC endpoint mapper | 135/TCP, 135/UDP |  |
| NetBIOS name service | 137/TCP, 137/UDP | Not used |
| NetBIOS datagram service | 138/UDP | Not used |
| NetBIOS session service | 139/TCP | Not used |
| RPC dynamic assignment | 1024-65535/TCP |  |
| IKE, Internet Key Exchange | 500/UDP |  |
| IPSec over TCP | 4500/TCP |  |
| IPSec ESP, Encapsulated Security Payload | IP protocol 50 |  |
| IPSec AH, Authenticated Header | IP protocol 51 | Not used |
| SMB over IP (Microsoft-DS) | 445/TCP, 445/UDP |  |
| LDAP | 389/TCP |  |
| LDAP ping | 389/UDP | Not used |
| LDAP over SSL | 636/TCP |  |
| Global catalog LDAP | 3268/TCP |  |
| Global catalog LDAP over SSL | 3269/TCP |  |
| Kerberos | 88/TCP, 88/UDP | Configure Kerberos to use TCP only and block UDP |
| Kpassd | 464/TCP, 464/UDP |  |
| Domain Name Service (DNS) | 53/TCP, 53/UDP |  |
| Remote Desktop | 3389/TCP |  |
| AD Web Service | 9389/TCP |  |
| Windows Remote Management Service(SSL) | 5986/TCP |  |

You can configure the servers to carry Kerberos traffic inside IPSec. Regardless of authentication mode, Kerberos between domain controllers is still required.

IPSec will not work through network address translation (NAT) devices. IPSec uses IP addresses when computing packet checksums, IPSec packets whose source addresses were altered by NAT are discarded when they arrive at the destination

Domain Controller Configuration Standards

- Servers will be installed with a currently supported Operating System with all the latest Service Packs and patches applied
- Servers will have antivirus installed with the most current definitions
- Domain Controller computer objects are automatically created in the root of the "Domain Controllers" OU and will not be moved
- Domain Controllers should not be multi-homed
- Client DNS settings: Primary DNS entry will be itself and secondary DNS entry will be another DNS server
- Domain suffixes will be added to network interfaces for each domain in the forest.
- A scheduled task will perform a daily System State Backup
- Appropriate security templates and Group Policy will be applied locally

Local Security Policies

The following security settings will be implemented to improve the security of Active Directory

## LDAP Server/Client Signing Requirements**

[All domain controllers will be configured to require signed and sealed LDAPS.]{.mark}

[Currently all domain controllers are configured to negotiate LDAP signing for client and domain controller settings. This can expose protected data and possibly credentials to an attacker. The transition to requiring signed and sealed LDAP will require reconfiguration of all Windows and non-Windows clients that bind to Active Directory for AuthN/Z or directory information. Some older equipment, namely devices like multi-function printers, may not be capable of this configuration.]{.mark}

## LAN Manager Authentication Level**

[All domain controllers are configured to eliminate LM and NTLM and instead rely on NTMLv2 and Kerberos as the only authentication mechanisms.]{.mark}

[Currently all domain controllers are configured for "Send NTLM response only." The NTLM protocol is not considered adequately secure. Eliminating NTLM may affect some older appliances and devices that may not be capable of utilizing the newer protocols.]{.mark}

## Do not store LAN Manager Hash value on next password change**

[All domain controllers are configured with the "Do not store LAN Manager Hash value on next password change" setting enabled.]{.mark}

[Currently all domain controllers have this setting configured, no further changes are required.]{.mark}

## Domain Controller Network Interfaces

[IPv6 is not currently in use. The protocol should be removed from the interfaces.]{.mark}

[DNS Server entries for each domain controller should point to itself as the primary (Not 127.0.0.1) and to another domain controller located in the same site for the secondary.]{.mark}

[The DNS search suffix entries should]{.mark} include all domains and sub domains that a client host may need to resolve an unqualified domain name for. Domains that only include internet accessible hosts should not be included in the DNS Search Suffix list.

## Windows Update Schedule

Configured to download and install with reboots scheduled so that domain controllers do not all reboot on the same day.

## User Rights Assignments

[Configured in accordance with the Center for Internet Security Baseline where possible. In the interim these policies should be checked to ensure they do not contain inappropriate users/groups or entries that display only as a SID]{.mark}

## Domain Controller Interactive Login

*[This right should be granted only to highly privileged accounts that are associated with a specific individual. Currently domain controllers allow Generic users accounts and ISUR login]{.mark}*

## Roles other than AD DS and DNS

```<Check>```

## Static Ports

[Static ports are configured for DFSR, RPC, and Netlogon services wherever that traffic must traverse a firewall.]{.mark}

[Currently no static ports are configured for DFSR, RPC, or Netlogon services. No further action is required unless it is determined that creating IPSec rules for the purposes of simplifying firewall rules is necessary.]{.mark}

## Remote Management

### Remote Desktop Configuration

### WinRM configuration

- Require SSL
- Create/install certificate
