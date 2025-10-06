# Active Directory Naming Convention

## Overview

This document establishes standardized naming conventions for all Active Directory objects to ensure consistency, manageability, and security across the organization. Proper naming conventions facilitate automated management, improve troubleshooting efficiency, and support compliance requirements.

## General Naming Principles

### Core Standards

- **Case Sensitivity**: Use PascalCase for all object names (first letter of each word capitalized)
- **Character Limitations**: Use only alphanumeric characters and hyphens (no spaces, special characters, or underscores)
- **Length Limits**: Respect AD object length limitations while maintaining readability
- **Descriptive Names**: Names should clearly indicate the object's purpose and function
- **Consistency**: Apply conventions uniformly across the entire organization
- **Future-Proofing**: Design names to accommodate organizational growth and changes

### Prohibited Characters and Practices

**Never Use:**

- Spaces in any object names
- Special characters: `/ \ [ ] : ; | = , + * ? < > @ "`
- Leading or trailing hyphens
- Consecutive hyphens
- Personal names or temporary designations
- Ambiguous abbreviations

**Reserved Names to Avoid:**

- Built-in AD objects (Administrator, Guest, etc.)
- System service names
- Common application names without prefixes

## Domain and Forest Naming

### Domain Names

**Format**: `[purpose].[organization].[tld]`

**Examples:**

- Primary domain: `corp.contoso.com`
- Child domains: `europe.corp.contoso.com`, `asia.corp.contoso.com`
- Resource domains: `resources.corp.contoso.com`
- DMZ domain: `dmz.contoso.com`

**Guidelines:**

- Use `.corp` or `.internal` for internal domains
- Geographic child domains: `[region].corp.[organization].com`
- Functional child domains: `[function].corp.[organization].com`
- Keep domain names short and meaningful
- Avoid using numbers in domain names

### Forest Structure

**Root Forest**: `corp.contoso.com`
**Resource Forests**: `resources.contoso.com`
**DMZ Forests**: `dmz.contoso.com`

## Organizational Unit (OU) Naming

### OU Structure Format

**Geographic OUs**: `[Country]-[State/Province]-[City]`

- Examples: `US-CA-LosAngeles`, `UK-England-London`, `DE-Bavaria-Munich`

**Departmental OUs**: `Dept-[DepartmentName]`

- Examples: `Dept-InformationTechnology`, `Dept-HumanResources`, `Dept-Sales`

**Functional OUs**: `[Function]-[Purpose]`

- Examples: `Computers-Workstations`, `Computers-Servers`, `ServiceAccounts-Database`

**Administrative OUs**: `Admin-[Purpose]`

- Examples: `Admin-DelegatedRights`, `Admin-PolicyExclusions`

### Complete OU Hierarchy Example

```text
corp.contoso.com
├── Geographic
│   ├── US-CA-LosAngeles
│   ├── US-NY-NewYork
│   ├── UK-England-London
│   └── DE-Bavaria-Munich
├── Departments
│   ├── Dept-InformationTechnology
│   ├── Dept-HumanResources
│   ├── Dept-Finance
│   ├── Dept-Sales
│   └── Dept-Operations
├── Objects
│   ├── Computers-Workstations
│   ├── Computers-Servers
│   ├── Computers-Mobile
│   ├── ServiceAccounts-Applications
│   ├── ServiceAccounts-Database
│   └── ServiceAccounts-Infrastructure
└── Administration
    ├── Admin-TestAccounts
    ├── Admin-DisabledObjects
    └── Admin-Quarantine
```

## User Account Naming

### Standard User Accounts

**Format**: `[FirstInitial][LastName][Number]`

**Examples:**

- John Smith: `JSmith` (first occurrence)
- John Smith (second employee): `JSmith01` (when duplicates exist)
- John Smith (third employee): `JSmith02` (sequential numbering)
- Mary Johnson-Williams: `MJohnsonWilliams` (20 characters exactly)
- José García: `JGarcia` (normalize special characters)

**Handling Long Names (Over 20 Characters):**

When `[FirstInitial][LastName]` exceeds 20 characters, use these truncation strategies:

1. **Use First Two Initials**: `[FirstInitial][MiddleInitial][LastName]`
   - Christopher Alexander Montgomery-Smith → `CAMontgomerySmith` (too long)
   - Use: `CAMontgomery` (11 characters)

2. **Truncate Last Name**: Keep first initial + truncated last name to 20 characters
   - Elizabeth Vandenberghe-Williams → `EVandenberghe` (13 characters)
   - Alexander Constantine-Rodriguez → `AConstantineRodr` (16 characters)

3. **Use Hyphenated Surnames**: For hyphenated names, use first surname if single surname fits
   - Maria Rodriguez-Gonzalez → `MRodriguez` (10 characters)
   - If both parts needed: `MRodriguezGonzal` (15 characters)

4. **Sequential Numbering for Truncated Names**: Apply numbering after truncation
   - First Alexander Constantine-Rodriguez: `AConstantineRodr`
   - Second Alexander Constantine-Rodriguez: `AConstantineRod1` (add number, remove character)

**Rules:**

- Maximum 20 characters for SAM Account Name (AD limitation)
- Use full last name when possible
- Add sequential numbers for duplicates (01, 02, etc.) or single digits for truncated names
- Normalize special characters (é→e, ñ→n, ü→u, etc.)
- For hyphenated surnames, try single surname first, then concatenate if space allows
- Document truncation decisions in user account notes
- Maintain a registry of truncated names to ensure consistency

### Administrative Accounts

**Format**: `ADM-[StandardUserName]`

**Examples:**

- Admin account for JSmith: `ADM-JSmith`
- Service admin: `ADM-MJohnson`
- Emergency admin: `ADM-Emergency01`

**Guidelines:**

- All administrative accounts must have `ADM-` prefix
- Link to standard user account when possible
- Use descriptive names for shared admin accounts
- Never use personal names for shared accounts

### Service Accounts

**Format**: `SVC-[Application]-[Purpose]-[Environment]`

**Examples:**

- SQL Server service: `SVC-SQL-Database-PROD`
- Backup service: `SVC-Backup-Agent-PROD`
- Exchange service: `SVC-Exchange-Transport-PROD`
- Test environment: `SVC-IIS-WebServer-TEST`

**Guidelines:**

- All service accounts must have `SVC-` prefix
- Include application name and purpose
- Specify environment (PROD, TEST, DEV)
- Maximum 20 characters for SAM Account Name
- Use consistent application abbreviations

### System and Application Accounts

**Format**: `SYS-[System]-[Function]`

**Examples:**

- Domain join account: `SYS-Domain-JoinComputers`
- DHCP service: `SYS-DHCP-ServiceAccount`
- Monitoring system: `SYS-Monitor-DataCollection`

## Computer Naming

### Workstations

**Format**: `[Location][Department][Type][Number]`

**Examples:**

- Los Angeles IT workstation: `LACIT-WS-001`
- New York Sales laptop: `NYCSL-LT-045`
- London Finance desktop: `LONFN-DT-012`

**Components:**

- **Location**: 3-letter airport code or abbreviation
- **Department**: 2-letter department code
- **Type**: WS (Workstation), LT (Laptop), DT (Desktop)
- **Number**: Sequential 3-digit number

### Servers

**Format**: `[Location]-[Role]-[Number]`

**Examples:**

- Domain controller: `LAC-DC-01`
- File server: `NYC-FS-03`
- Application server: `LON-APP-05`
- Database server: `MUN-SQL-02`

**Server Role Abbreviations:**

- **DC**: Domain Controller
- **FS**: File Server
- **SQL**: Database Server
- **WEB**: Web Server
- **APP**: Application Server
- **EX**: Exchange Server
- **HV**: Hyper-V Host
- **BK**: Backup Server
- **MON**: Monitoring Server

## Group Naming

### Security Groups

**Format**: `[Scope]-[Purpose]-[AccessLevel]`

**Scope Prefixes:**

- **GS**: Global Groups
- **DS**: Domain Local Groups
- **US**: Universal Groups

**Examples:**

- File share access: `DS-FileShare-Finance-ReadWrite`
- Application access: `GS-Application-Payroll-Users`
- Administrative rights: `DS-Servers-DatabaseAdmins`

### Distribution Groups

**Format**: `DS-[Purpose]-[Department]`

**Examples:**

- Department distribution: `DS-AllUsers-HumanResources`
- Project communication: `DS-Project-WebsiteRedesign`
- Location-based: `DS-Location-LosAngelesOffice`

### Role-Based Groups

**Format**: `ROLE-[JobFunction]-[AccessLevel]`

**Examples:**

- IT administrators: `ROLE-ITAdmin-FullAccess`
- Help desk staff: `ROLE-HelpDesk-Limited`
- Database administrators: `ROLE-DBA-ReadWrite`

## Group Policy Object (GPO) Naming

### GPO Naming Format

**Format**: `[Scope]-[Category]-[Purpose]-[Version]`

**Examples:**

- Security baseline: `Domain-Security-PasswordPolicy-v2.1`
- Software deployment: `OU-Software-AdobeReader-v1.0`
- User configuration: `Department-User-DesktopSettings-v1.5`

**Scope Indicators:**

- **Domain**: Applies to entire domain
- **Site**: Applies to AD site
- **OU**: Applies to specific OU
- **Department**: Applies to department OUs

**Categories:**

- **Security**: Security-related settings
- **Software**: Software installation/configuration
- **User**: User environment settings
- **Computer**: Computer configuration
- **Administrative**: Administrative templates

## Site and Subnet Naming

### AD Sites

**Format**: `[Location]-[Purpose]`

**Examples:**

- Main office: `LosAngeles-Headquarters`
- Branch office: `NewYork-Branch`
- Data center: `Phoenix-DataCenter`
- Remote site: `Denver-Remote`

### Subnets

**Format**: Include location and network purpose in description

**Examples:**

- `10.1.1.0/24` - "Los Angeles - User Network"
- `10.1.2.0/24` - "Los Angeles - Server Network"
- `10.2.1.0/24` - "New York - User Network"

## DNS Naming Conventions

### DNS Zones

**Internal Zones:**

- Primary: `corp.contoso.com`
- Application-specific: `apps.corp.contoso.com`
- Infrastructure: `infra.corp.contoso.com`

### DNS Records

**A Records:**

- Servers: Use computer name
- Services: `[service].[location].corp.contoso.com`
- Applications: `[app].[environment].corp.contoso.com`

**CNAME Records:**

- Service aliases: `[service].corp.contoso.com`
- Application aliases: `[app].corp.contoso.com`

## Certificate Template Naming

### Template Format

**Format**: `[Purpose]-[KeyUsage]-[ValidityPeriod]`

**Examples:**

- User certificates: `User-Authentication-1Year`
- Computer certificates: `Computer-Authentication-2Year`
- Web server certificates: `WebServer-ServerAuth-2Year`
- Code signing: `CodeSigning-Authentication-3Year`

## Implementation Guidelines

### Naming Convention Documentation

1. **Centralized Registry**: Maintain a master list of all naming conventions
2. **Approval Process**: Require approval for new naming patterns
3. **Regular Reviews**: Review and update conventions annually
4. **Training Materials**: Provide training on naming conventions
5. **Enforcement Tools**: Use scripts to validate naming compliance

### Migration Planning

**For Existing Environments:**

1. **Assessment Phase**
   - Inventory current naming patterns
   - Identify non-compliant objects
   - Assess impact of changes

2. **Gradual Implementation**
   - Start with new objects
   - Rename critical objects during maintenance windows
   - Update documentation and procedures

3. **Validation and Monitoring**
   - Implement automated compliance checking
   - Regular audits of naming convention adherence
   - Corrective action procedures

### Automation and Scripting

**PowerShell Examples for Validation:**

```powershell
# Validate user account naming convention
function Test-UserNamingConvention
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SamAccountName
    )
    
    # Check length limit (AD SAM Account Name limit is 20 characters)
    if ($SamAccountName.Length -gt 20)
    {
        Write-Warning "User account '$SamAccountName' exceeds 20 character limit"
        return $false
    }
    
    # Check for proper format: FirstInitial + LastName + optional number
    # Supports single digit or two-digit numbers (01-99)
    $StandardPattern = '^[A-Z][A-Za-z]+(0[1-9]|[1-9][0-9])?$'
    
    # Also allow single digit for truncated names
    $TruncatedPattern = '^[A-Z][A-Za-z]+[1-9]$'
    
    if ($SamAccountName -match $StandardPattern -or $SamAccountName -match $TruncatedPattern)
    {
        return $true
    }
    else
    {
        Write-Warning "User account '$SamAccountName' does not follow naming convention"
        Write-Warning "Expected format: [FirstInitial][LastName][OptionalNumber]"
        return $false
    }
}

# Generate compliant user account name with truncation handling
function New-UserAccountName
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FirstName,
        
        [Parameter(Mandatory = $true)]
        [string]$LastName,
        
        [Parameter()]
        [string]$MiddleName,
        
        [Parameter()]
        [int]$SequenceNumber = 0
    )
    
    # Normalize names (remove special characters)
    $FirstName = $FirstName -replace '[àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ]', {
        switch ($_.Value) {
            {$_ -in 'àáâãäå'} { 'a' }
            'æ' { 'ae' }
            'ç' { 'c' }
            {$_ -in 'èéêë'} { 'e' }
            {$_ -in 'ìíîï'} { 'i' }
            'ð' { 'd' }
            'ñ' { 'n' }
            {$_ -in 'òóôõöø'} { 'o' }
            {$_ -in 'ùúûü'} { 'u' }
            {$_ -in 'ýþÿ'} { 'y' }
            default { $_ }
        }
    }
    
    $LastName = $LastName -replace '[àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ]', {
        switch ($_.Value) {
            {$_ -in 'àáâãäå'} { 'a' }
            'æ' { 'ae' }
            'ç' { 'c' }
            {$_ -in 'èéêë'} { 'e' }
            {$_ -in 'ìíîï'} { 'i' }
            'ð' { 'd' }
            'ñ' { 'n' }
            {$_ -in 'òóôõöø'} { 'o' }
            {$_ -in 'ùúûü'} { 'u' }
            {$_ -in 'ýþÿ'} { 'y' }
            default { $_ }
        }
    }
    
    # Remove spaces and special characters, handle hyphenated names
    $LastName = $LastName -replace '[-\s]', '' -replace '[^A-Za-z]', ''
    $FirstInitial = $FirstName.Substring(0, 1).ToUpper()
    $MiddleInitial = if ($MiddleName) { $MiddleName.Substring(0, 1).ToUpper() } else { '' }
    
    # Try different strategies to fit within 20 characters
    $BaseNames = @()
    
    # Strategy 1: FirstInitial + LastName
    $BaseNames += "$FirstInitial$LastName"
    
    # Strategy 2: FirstInitial + MiddleInitial + LastName (if middle name provided)
    if ($MiddleInitial) {
        $BaseNames += "$FirstInitial$MiddleInitial$LastName"
    }
    
    foreach ($BaseName in $BaseNames) {
        $FinalName = $BaseName
        
        # Add sequence number if provided
        if ($SequenceNumber -gt 0) {
            if ($SequenceNumber -lt 10) {
                $FinalName = "$BaseName$SequenceNumber"
            } else {
                $FinalName = "$BaseName$('{0:D2}' -f $SequenceNumber)"
            }
        }
        
        # If name fits within 20 characters, use it
        if ($FinalName.Length -le 20) {
            Write-Output $FinalName
            return
        }
        
        # If too long, try truncation
        $MaxBaseLength = if ($SequenceNumber -gt 0) { 
            if ($SequenceNumber -lt 10) { 19 } else { 18 }
        } else { 20 }
        
        if ($BaseName.Length -gt $MaxBaseLength) {
            $TruncatedBase = $BaseName.Substring(0, $MaxBaseLength)
            $FinalName = if ($SequenceNumber -gt 0) {
                if ($SequenceNumber -lt 10) {
                    "$TruncatedBase$SequenceNumber"
                } else {
                    "$TruncatedBase$('{0:D2}' -f $SequenceNumber)"
                }
            } else {
                $TruncatedBase
            }
            
            Write-Warning "Name truncated to fit 20 character limit: $FinalName"
            Write-Output $FinalName
            return
        }
    }
    
    # Fallback: Use first initial + truncated last name
    $MaxLastNameLength = if ($SequenceNumber -gt 0) { 
        if ($SequenceNumber -lt 10) { 18 } else { 17 }
    } else { 19 }
    
    $TruncatedLastName = $LastName.Substring(0, [Math]::Min($LastName.Length, $MaxLastNameLength))
    $FinalName = if ($SequenceNumber -gt 0) {
        if ($SequenceNumber -lt 10) {
            "$FirstInitial$TruncatedLastName$SequenceNumber"
        } else {
            "$FirstInitial$TruncatedLastName$('{0:D2}' -f $SequenceNumber)"
        }
    } else {
        "$FirstInitial$TruncatedLastName"
    }
    
    Write-Warning "Name heavily truncated to fit 20 character limit: $FinalName"
    Write-Output $FinalName
}

# Validate computer naming convention
function Test-ComputerNamingConvention
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )
    
    # Check for proper format: Location + Department + Type + Number
    $WorkstationPattern = '^[A-Z]{3}[A-Z]{2}-(WS|LT|DT)-[0-9]{3}$'
    $ServerPattern = '^[A-Z]{3}-(DC|FS|SQL|WEB|APP|EX|HV|BK|MON)-[0-9]{2}$'
    $VirtualPattern = '^V[A-Z]{3}-(DC|FS|SQL|WEB|APP|EX|HV|BK|MON)-[0-9]{2}$'
    
    if ($ComputerName -match $WorkstationPattern -or 
        $ComputerName -match $ServerPattern -or 
        $ComputerName -match $VirtualPattern)
    {
        return $true
    }
    else
    {
        Write-Warning "Computer '$ComputerName' does not follow naming convention"
        return $false
    }
}

# Generate compliant service account name
function New-ServiceAccountName
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Application,
        
        [Parameter(Mandatory = $true)]
        [string]$Purpose,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("PROD", "TEST", "DEV")]
        [string]$Environment
    )
    
    $ServiceAccountName = "SVC-$Application-$Purpose-$Environment"
    
    # Ensure it doesn't exceed 20 characters for SAM Account Name
    if ($ServiceAccountName.Length -gt 20)
    {
        Write-Warning "Generated name '$ServiceAccountName' exceeds 20 character limit"
        # Suggest truncation strategy
        $TruncatedName = $ServiceAccountName.Substring(0, 20)
        Write-Output "Suggested truncated name: $TruncatedName"
    }
    else
    {
        Write-Output $ServiceAccountName
    }
}
```

## Compliance and Monitoring

### Regular Auditing

**Monthly Reviews:**

- New object naming compliance
- Identify non-compliant objects
- Update naming convention registry

**Quarterly Assessments:**

- Full environment naming audit
- Convention effectiveness review
- Update procedures as needed

**Annual Reviews:**

- Complete convention documentation review
- Organizational change impact assessment
- Convention update and approval process

### Enforcement Mechanisms

1. **Automated Validation**: Scripts to check naming compliance during object creation
2. **Group Policy Restrictions**: Limit object creation to authorized personnel
3. **Regular Reporting**: Dashboard showing naming compliance metrics
4. **Training Requirements**: Mandatory training for AD administrators
5. **Change Control**: Naming convention changes require formal approval

## Exception Handling

### Exception Process

1. **Request Submission**: Document business justification for exception
2. **Impact Assessment**: Evaluate impact on existing systems and processes
3. **Approval Authority**: Designated authority for exception approval
4. **Documentation**: Maintain registry of approved exceptions
5. **Review Schedule**: Regular review of exceptions for continued validity

### Common Exception Scenarios

- **Legacy System Integration**: Systems requiring specific naming formats
- **Vendor Requirements**: Applications with specific naming requirements
- **Regulatory Compliance**: Industry-specific naming requirements
- **Temporary Objects**: Short-term testing or project objects

## Reference Tables

### Location Codes

| Location | Code | Location | Code |
|----------|------|----------|------|
| Los Angeles, CA | LAC | New York, NY | NYC |
| London, UK | LON | Tokyo, JP | TKY |
| Munich, DE | MUN | Sydney, AU | SYD |
| Toronto, CA | TOR | Singapore, SG | SIN |

### Department Codes

| Department | Code | Department | Code |
|------------|------|------------|------|
| Information Technology | IT | Human Resources | HR |
| Finance | FN | Sales | SL |
| Marketing | MK | Operations | OP |
| Legal | LG | Executive | EX |

### Server Role Abbreviations

| Role | Code | Role | Code |
|------|------|------|------|
| Domain Controller | DC | File Server | FS |
| Database Server | SQL | Web Server | WEB |
| Application Server | APP | Exchange Server | EX |
| Hyper-V Host | HV | Backup Server | BK |
| Monitoring Server | MON | Print Server | PS |

---

*This naming convention document should be reviewed annually and updated as organizational needs change. For questions or exception requests, contact the IT Infrastructure team.*
