# Exchange Server Naming Convention

## Overview

This document establishes standardized naming conventions for all Exchange Server objects and components to ensure consistency, manageability, and integration with Active Directory infrastructure. These conventions build upon and reference the [Active Directory Naming Convention](../../../directoryservices/activedirectory/documentation/namingconvention.md) to maintain enterprise-wide consistency.

## General Naming Principles

### Core Standards

- **Consistency with AD**: Follow Active Directory naming conventions for all shared components (servers, domains, accounts)
- **Exchange-Specific Objects**: Use Exchange-specific prefixes and patterns for mail-specific objects
- **Case Sensitivity**: Use PascalCase for all object names (first letter of each word capitalized)
- **Character Limitations**: Use only alphanumeric characters and hyphens (no spaces, special characters, or underscores)
- **Descriptive Names**: Names should clearly indicate the object's purpose and function
- **Environment Identification**: Include environment indicators (PROD, TEST, DEV) where appropriate
- **Location Awareness**: Include location identifiers for multi-site deployments

### Prohibited Characters and Practices

**Never Use:**

- Spaces in any object names
- Special characters: `/ \ [ ] : ; | = , + * ? < > @ " '`
- Leading or trailing hyphens
- Consecutive hyphens
- Personal names for shared resources
- Ambiguous abbreviations
- Reserved Exchange or SMTP keywords

## Exchange Server Infrastructure

### Exchange Server Naming

**Follow Active Directory Server Naming Convention**: `[Location]-[Role]-[Number]`

**Exchange Server Role Abbreviations:**

- **EX**: Exchange Server (combined Mailbox/ClientAccess role)
- **MBX**: Mailbox Server (dedicated mailbox role)
- **CAS**: Client Access Server (dedicated client access role)
- **HUB**: Hub Transport Server (legacy)
- **EDGE**: Edge Transport Server
- **UM**: Unified Messaging Server (legacy)

**Examples:**

- Primary Exchange servers: `LAC-EX-01.corp.contoso.com`, `LAC-EX-02.corp.contoso.com`
- Branch Exchange servers: `NYC-EX-01.corp.contoso.com`, `CHI-EX-01.corp.contoso.com`
- Edge servers: `DMZ-EDGE-01.contoso.com`, `DMZ-EDGE-02.contoso.com`
- Dedicated roles: `LAC-MBX-01.corp.contoso.com`, `LAC-CAS-01.corp.contoso.com`

**Guidelines:**

- Use three-letter airport codes for locations (LAC, NYC, CHI, LON)
- Edge servers use external domain (contoso.com) not internal (corp.contoso.com)
- Sequential numbering starting with 01
- Include full FQDN in documentation

## Database Availability Groups (DAG)

### DAG Naming Format

**Format**: `DAG-[Location/Purpose]`

**Examples:**

- Primary site: `DAG-LosAngeles`, `DAG-Headquarters`
- Branch sites: `DAG-Branches`, `DAG-Regional`
- Specialized: `DAG-Archive`, `DAG-Compliance`

**Guidelines:**

- Use descriptive location or purpose names
- Avoid generic names like "DAG1" or "Production"
- Consider spanning multiple locations: `DAG-WestCoast`, `DAG-EastCoast`
- Maximum 15 characters for DAG names

### DAG Network Naming

**Format**: `[DAGName]-[NetworkType]`

**Examples:**

- MAPI networks: `DAG-LosAngeles-MAPI`
- Replication networks: `DAG-LosAngeles-Replication`

## Mailbox Database Naming

### Database Naming Format

**Format**: `DB-[Purpose]-[Location/Number]`

**Purpose Categories:**

- **Users**: Standard user mailboxes
- **Executives**: Executive/VIP mailboxes  
- **Shared**: Shared and resource mailboxes
- **Archive**: Archive mailboxes
- **Public**: Public folder databases
- **Branch**: Branch office databases
- **Compliance**: Compliance/legal hold databases

**Examples:**

- User databases: `DB-Users-01`, `DB-Users-02`, `DB-Users-03`
- Executive databases: `DB-Executives`, `DB-VIP`
- Shared mailboxes: `DB-Shared`, `DB-Resources`
- Branch databases: `DB-Branch-NYC`, `DB-Branch-CHI`
- Archive databases: `DB-Archive-01`, `DB-Archive-Legal`
- Public folders: `DB-PublicFolders`

**Guidelines:**

- Use sequential numbering for similar databases (01, 02, 03)
- Include location for branch-specific databases
- Keep database names under 64 characters
- Avoid environment suffixes in database names (use server placement instead)

### Database File Naming

**Format**: Follow database naming with .edb extension

**Examples:**

- Database files: `DB-Users-01.edb`, `DB-Executives.edb`
- Log files: Use database name as prefix (`DB-Users-01[LogGeneration].log`)

## Transport Infrastructure

### Send Connector Naming

**Format**: `[Purpose]-[Destination/Type]`

**Examples:**

- Internet mail: `Internet-Mail`, `SMTP-Internet`
- Partner connections: `Partner-ContosoPartners`, `SMTP-TrustedPartners`
- Hybrid connectors: `Hybrid-Office365`, `O365-Outbound`
- Internal routing: `Internal-Branches`, `Site-NYC`
- Application connectors: `App-PrinterNotifications`, `System-Monitoring`

**Guidelines:**

- Use descriptive purpose names
- Include security level: `Secure-Partners`, `Encrypted-Legal`
- Avoid generic names like "Connector1"

### Receive Connector Naming

**Format**: `[Server]-[Purpose/Type]`

**Examples:**

- Default connectors: `LAC-EX-01-Default`, `LAC-EX-01-Internal`
- Client submission: `LAC-EX-01-ClientAuth`, `LAC-EX-01-Submission`
- Application connectors: `LAC-EX-01-Applications`, `LAC-EX-01-Monitoring`
- Partner connectors: `LAC-EX-01-Partners`, `LAC-EX-01-TrustedRelay`
- Anonymous: `DMZ-EDGE-01-Internet`, `DMZ-EDGE-01-Anonymous`

### Transport Rules

**Format**: `[Priority]-[Purpose]-[Action]`

**Examples:**

- Security rules: `01-BlockExecutables-Quarantine`, `02-ScanAttachments-Strip`
- Compliance rules: `10-JournalExecutives-Archive`, `11-EncryptLegal-Apply`
- Routing rules: `20-RoutePartners-Redirect`, `21-RouteExternal-Relay`
- Content rules: `30-LargeAttachments-Warn`, `31-SpamFilter-Delete`

**Guidelines:**

- Use two-digit priority prefixes (01-99)
- Lower numbers = higher priority
- Include action in name for clarity
- Group by tens (01-09 security, 10-19 compliance, etc.)

## Client Access Services

### Virtual Directory Naming

**Format**: Follow Exchange defaults but document consistently

**Standard Virtual Directories:**

- Outlook Web App: `/owa`
- Exchange ActiveSync: `/Microsoft-Server-ActiveSync`
- Exchange Web Services: `/EWS/Exchange.asmx`
- Offline Address Book: `/OAB`
- MAPI/HTTP: `/mapi`
- Exchange Control Panel: `/ecp`

**Custom Virtual Directories:**

- Application-specific: `/owa-executives`, `/eas-mobile`
- Environment-specific: `/owa-test`, `/eas-dev`

### Client Access Server Arrays

**Format**: `[Location]-CAS-Array`

**Examples:**

- `LAC-CAS-Array`, `NYC-CAS-Array`
- `Headquarters-CAS-Array`, `Branches-CAS-Array`

## Exchange Service Accounts

### Service Account Naming

**Follow Active Directory Service Account Convention**: `SVC-[Application]-[Purpose]-[Environment]`

**Exchange-Specific Examples:**

- Exchange services: `SVC-Exchange-Transport-PROD`
- Database services: `SVC-Exchange-Database-PROD`
- Monitoring: `SVC-Exchange-Monitor-PROD`
- Backup: `SVC-Exchange-Backup-PROD`
- Anti-malware: `SVC-Exchange-Antivirus-PROD`
- Compliance: `SVC-Exchange-Journal-PROD`

**Hybrid and Integration:**

- Office 365: `SVC-Exchange-O365Hybrid-PROD`
- Third-party: `SVC-Exchange-Archiving-PROD`

## Distribution Groups and Mail-Enabled Security Groups

### Follow Active Directory Group Naming Convention

**Reference**: Use AD group prefixes (GS-, DG-, DS-, US-) as defined in AD naming convention

**Exchange-Specific Examples:**

- **Mail Distribution Groups**: `DG-[Purpose]-[Department/Location]`
  - `DG-AllUsers-Organization`
  - `DG-Department-Sales`
  - `DG-Location-NewYorkBranch`
  - `DG-Project-WebsiteRedesign`

- **Mail-Enabled Security Groups**: `GS-[Purpose]-[AccessLevel]`
  - `GS-Exchange-FullAccess`
  - `GS-Exchange-ViewOnly`
  - `GS-Mailbox-PowerUsers`

**Exchange Administration Groups:**

- `GS-Exchange-OrganizationManagement`
- `GS-Exchange-RecipientManagement`
- `GS-Exchange-ServerManagement`
- `GS-Exchange-ViewOnlyManagement`
- `GS-Exchange-HygieneManagement`

### Dynamic Distribution Groups

**Format**: `DYN-[Criteria]-[Purpose]`

**Examples:**

- `DYN-AllEmployees-CompanyNews`
- `DYN-Managers-Leadership`
- `DYN-Department-IT`
- `DYN-Location-Headquarters`

## Mailbox Types

### User Mailbox Naming

**Follow Active Directory User Account Convention**: `[FirstInitial][LastName][Number]`

**Examples:**

- Standard users: `JSmith`, `MJohnson`, `ASmith01` (when duplicates exist)
- Reference AD naming convention for detailed rules

### Shared Mailbox Naming

**Format**: `SHR-[Purpose]-[Department/Location]`

**Examples:**

- Department shared: `SHR-Sales-TeamMailbox`, `SHR-HR-Applications`
- Functional shared: `SHR-Reception-Lobby`, `SHR-Orders-Processing`
- Location shared: `SHR-NYC-Reception`, `SHR-LAC-Facilities`

**Guidelines:**

- Use SHR- prefix to identify shared mailboxes
- Include department or location for context
- Avoid personal names in shared mailbox names

### Resource Mailbox Naming

**Format**: `[Type]-[Location]-[Description]`

**Resource Types:**

- **ROOM**: Conference rooms and meeting spaces
- **EQUIP**: Equipment and resources

**Examples:**

- Conference rooms: `ROOM-LAC-BoardRoom`, `ROOM-NYC-TrainingRoom01`
- Equipment: `EQUIP-LAC-Projector01`, `EQUIP-NYC-VideoConference`

**Guidelines:**

- Include building/floor if multiple locations: `ROOM-LAC-Floor2-Conference`
- Use descriptive names: `ROOM-LAC-ExecutiveBoardroom`
- Sequential numbering for similar resources

### Public Folder Naming

**Format**: Use descriptive hierarchy without prefixes

**Examples:**

```text
All Public Folders
├── Company Information
│   ├── HR Policies
│   ├── Employee Handbook
│   └── Organization Charts
├── Departments
│   ├── IT Documentation
│   ├── Sales Materials
│   └── Finance Reports
└── Projects
    ├── Website Redesign
    └── Office Relocation
```

**Guidelines:**

- Use clear, descriptive folder names
- Organize in logical hierarchy
- Avoid abbreviations in folder names
- Use proper capitalization

## Administrative Accounts

### Exchange Administrative Accounts

**Follow Active Directory Administrative Account Convention**: `ADM-[Purpose/Role]`

**Exchange-Specific Examples:**

- `ADM-ExchangeAdmin` (full Exchange administrator)
- `ADM-MailboxAdmin` (mailbox management only)
- `ADM-TransportAdmin` (transport rule management)
- `ADM-HygieneAdmin` (anti-spam/malware management)
- `ADM-ComplianceOfficer` (compliance and legal hold)

**Break-Glass Accounts:**

- `ADM-Exchange-Emergency01`
- `ADM-Exchange-Emergency02`

## Certificate Naming

### Certificate Template Naming

**Format**: `Exchange-[Purpose]-[Duration]`

**Examples:**

- Server certificates: `Exchange-ServerAuth-2Year`
- Client certificates: `Exchange-ClientAuth-1Year`
- S/MIME certificates: `Exchange-SMIME-1Year`

### Certificate Subject Naming

**Format**: Use FQDN of Exchange server

**Examples:**

- `CN=LAC-EX-01.corp.contoso.com`
- `CN=mail.contoso.com` (for external access)
- `CN=*.corp.contoso.com` (wildcard for internal)

## Address Lists and Policies

### Email Address Policy Naming

**Format**: `[Priority]-[Scope]-[Purpose]`

**Examples:**

- `01-Default-AllRecipients`
- `02-Executive-VIPUsers`
- `03-European-EUDomain`
- `04-Branch-RemoteOffices`

**Guidelines:**

- Use two-digit priority (lower number = higher priority)
- Include scope for clarity
- Describe the purpose or filter criteria

### Address List Naming

**Format**: `[Type]-[Criteria]`

**Examples:**

- `GAL-AllUsers` (Global Address List)
- `AL-Executives` (Address List for executives)
- `AL-Department-Sales`
- `AL-Location-NYC`
- `AL-External-Contacts`

## Retention Policies

### Retention Policy Naming

**Format**: `[Scope]-[Duration/Purpose]`

**Examples:**

- `Default-2Year-Standard`
- `Executive-7Year-Compliance`
- `Legal-Litigation-Hold`
- `Archive-10Year-Regulatory`

### Retention Policy Tag Naming

**Format**: `[Type]-[Duration]-[Action]`

**Examples:**

- `Personal-1Year-Delete`
- `Business-3Year-Archive`
- `Legal-Never-Retain`
- `Junk-30Days-Delete`

## Mobile Device Policies

### ActiveSync Policy Naming

**Format**: `[UserType]-[SecurityLevel]`

**Examples:**

- `Default-Standard` (default policy for all users)
- `Executive-High` (high security for executives)
- `BYOD-Restricted` (bring your own device)
- `Kiosk-Limited` (kiosk/shared devices)
- `Guest-Basic` (temporary access)

## Exchange Hybrid Configuration

### Hybrid Configuration Objects

**Format**: `[Type]-[Purpose]`

**Examples:**

- Send connectors: `Hybrid-O365-Outbound`
- Receive connectors: `Hybrid-O365-Inbound`
- Accepted domains: Use standard domain naming
- Organization relationships: `O365-[TenantName]`

## Monitoring and Reporting

### Management Pack/Solution Naming

**Format**: `Exchange-[Component]-[Purpose]`

**Examples:**

- `Exchange-Mailflow-Monitoring`
- `Exchange-Database-Performance`
- `Exchange-ClientAccess-Availability`

### Alert Rule Naming

**Format**: `[Severity]-[Component]-[Condition]`

**Examples:**

- `Critical-Database-Dismounted`
- `Warning-Queue-HighVolume`
- `Info-Backup-Completed`

## Implementation Guidelines

### Documentation Requirements

1. **Naming Registry**: Maintain centralized registry of all Exchange object names
2. **Change Control**: Require approval for naming convention changes
3. **Migration Planning**: Plan naming updates during maintenance windows
4. **Training**: Provide training on naming conventions to all Exchange administrators

### Validation and Compliance

**PowerShell Validation Examples:**

```powershell
# Validate Exchange server naming convention
function Test-ExchangeServerNaming {
    param([string]$ServerName)
    
    $Pattern = "^[A-Z]{3}-[A-Z]{2,4}-\d{2}\.corp\.contoso\.com$"
    if ($ServerName -match $Pattern) {
        Write-Output "Valid Exchange server name: $ServerName"
        return $true
    } else {
        Write-Warning "Invalid Exchange server name: $ServerName"
        return $false
    }
}

# Validate database naming convention
function Test-DatabaseNaming {
    param([string]$DatabaseName)
    
    $Pattern = "^DB-[A-Za-z]+-[A-Za-z0-9]+$"
    if ($DatabaseName -match $Pattern) {
        Write-Output "Valid database name: $DatabaseName"
        return $true
    } else {
        Write-Warning "Invalid database name: $DatabaseName"
        return $false
    }
}

# Validate service account naming
function Test-ServiceAccountNaming {
    param([string]$AccountName)
    
    $Pattern = "^SVC-Exchange-[A-Za-z]+-[A-Z]{3,4}$"
    if ($AccountName -match $Pattern) {
        Write-Output "Valid service account name: $AccountName"
        return $true
    } else {
        Write-Warning "Invalid service account name: $AccountName"
        return $false
    }
}
```

### Migration Strategy

**For Existing Environments:**

1. **Assessment Phase**
   - Inventory current Exchange objects and naming patterns
   - Identify non-compliant objects
   - Assess dependencies and impact of changes

2. **Phased Implementation**
   - Start with new objects using proper naming
   - Rename non-critical objects during maintenance windows
   - Update documentation and procedures
   - Plan major renames during planned outages

3. **Testing and Validation**
   - Test naming changes in lab environment
   - Validate application dependencies
   - Update monitoring and management tools
   - Document rollback procedures

### Integration with Active Directory

**Shared Components:**

- **Server Names**: Use AD server naming convention exactly
- **Domain Names**: Follow AD domain structure
- **Administrative Accounts**: Use AD admin account prefixes
- **Security Groups**: Use AD group naming prefixes
- **Service Accounts**: Follow AD service account format

**Exchange-Specific Components:**

- **Databases**: Use Exchange-specific DB- prefix
- **Transport Objects**: Use Exchange-specific formats
- **Mailboxes**: Follow user account naming from AD
- **Public Folders**: Use descriptive names without prefixes

## Summary

This Exchange Server naming convention provides:

1. **Consistency**: Aligns with Active Directory naming standards
2. **Clarity**: Object names clearly indicate purpose and scope
3. **Scalability**: Supports organizational growth and expansion
4. **Maintainability**: Simplifies administration and troubleshooting
5. **Integration**: Seamless integration with AD infrastructure
6. **Compliance**: Supports audit and compliance requirements
7. **Automation**: Enables PowerShell scripting and automation

**Key Principles:**

- Reference AD naming convention for shared infrastructure
- Use Exchange-specific prefixes for mail objects
- Include location and purpose in names
- Maintain consistency across all environments
- Document all naming decisions and exceptions
- Implement validation and compliance checking
- Plan migration strategy for existing environments

For questions or exceptions to these naming conventions, contact the Exchange Administration team at <exchange-admins@contoso.com>.

---

*This document should be reviewed annually and updated as needed to reflect organizational changes and Exchange Server evolution.*
