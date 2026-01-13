---
title: "MIM 2016 SQL Synchronization Guide"
description: "Comprehensive guide to synchronizing SQL table identities to Active Directory using MIM 2016 Sync Service with rule extensions"
tags: ["MIM", "SQL", "synchronization", "active directory", "rule extensions"]
category: "services"
difficulty: "advanced"
last_updated: "2025-07-05"
---

## MIM 2016 SQL Synchronization Guide

This comprehensive guide demonstrates how to use Microsoft Identity Manager 2016 Synchronization Service to synchronize a SQL table of identities to Active Directory. This implementation relies solely on rule extensions to avoid using the MIM Service and Portal, providing a lightweight and efficient synchronization solution.

## Overview

This guide covers the complete process of setting up SQL-to-AD synchronization using:

- **SQL Management Agent** for database connectivity
- **Active Directory Management Agent** for AD integration
- **Custom Rule Extensions** for business logic implementation
- **Metaverse Schema Extensions** for data mapping
- **Synchronization Rules** for data flow control

## Prerequisites

### System Requirements

**MIM 2016 Synchronization Service:**

- Windows Server 2012 R2 or later
- .NET Framework 4.6 or later
- Microsoft Visual Studio (for rule extension development)
- SQL Server connectivity components

**SQL Server Database:**

- SQL Server 2012 or later
- Read access to identity data tables
- Network connectivity from MIM Sync server

**Active Directory:**

- Windows Server 2008 R2 domain functional level or higher
- Service account with appropriate AD permissions
- Target Organizational Units configured

### Service Accounts

**MIM Synchronization Service Account:**

- Local logon rights on MIM server
- SQL database read permissions
- AD user creation/modification permissions

**SQL Connection Account:**

- SQL Server authentication or Windows authentication
- SELECT permissions on identity tables
- Optional: stored procedure execution rights

## Database Schema Design

### Identity Table Structure

Create a standardized identity table with the following recommended schema:

```sql
CREATE TABLE [dbo].[Identities] (
    [EmployeeID] NVARCHAR(50) PRIMARY KEY,
    [FirstName] NVARCHAR(100) NOT NULL,
    [LastName] NVARCHAR(100) NOT NULL,
    [DisplayName] NVARCHAR(200),
    [Email] NVARCHAR(255),
    [Department] NVARCHAR(100),
    [Title] NVARCHAR(100),
    [Manager] NVARCHAR(50),
    [Location] NVARCHAR(100),
    [PhoneNumber] NVARCHAR(50),
    [StartDate] DATETIME,
    [EndDate] DATETIME,
    [Status] NVARCHAR(20),
    [LastModified] DATETIME DEFAULT GETDATE(),
    [IsActive] BIT DEFAULT 1
);
```

### Change Tracking Implementation

#### Option 1: LastModified Column (Recommended)

```sql
-- Add trigger to update LastModified on changes
CREATE TRIGGER [dbo].[TR_Identities_LastModified]
ON [dbo].[Identities]
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE [dbo].[Identities]
    SET [LastModified] = GETDATE()
    WHERE [EmployeeID] IN (SELECT [EmployeeID] FROM inserted);
END;
```

#### Option 2: Change Tracking (SQL Server 2008+)

```sql
-- Enable change tracking on database
ALTER DATABASE [YourDatabase]
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 7 DAYS, AUTO_CLEANUP = ON);

-- Enable change tracking on table
ALTER TABLE [dbo].[Identities]
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON);
```

### Sample Data Population

```sql
INSERT INTO [dbo].[Identities] VALUES
('EMP001', 'John', 'Doe', 'John Doe', 'john.doe@company.com', 'IT', 'Software Engineer', 'EMP100', 'New York', '555-0101', '2023-01-15', NULL, 'Active', GETDATE(), 1),
('EMP002', 'Jane', 'Smith', 'Jane Smith', 'jane.smith@company.com', 'HR', 'HR Manager', 'EMP100', 'Boston', '555-0102', '2022-03-20', NULL, 'Active', GETDATE(), 1),
('EMP003', 'Bob', 'Johnson', 'Bob Johnson', 'bob.johnson@company.com', 'Sales', 'Sales Rep', 'EMP101', 'Chicago', '555-0103', '2023-06-01', '2024-12-31', 'Leaving', GETDATE(), 0);
```

## Management Agent Configuration

### 1. SQL Management Agent Setup

**Create New Management Agent:**

1. Open Synchronization Service Manager
2. Select **Management Agents** → **Create**
3. Choose **SQL Server** connector type
4. Configure the following settings:

**Connectivity:**

```text
Server: [SQL_SERVER_NAME]
Database: [DATABASE_NAME]
Authentication: [Windows/SQL Server]
Username: [SQL_USER] (if SQL auth)
Password: [SQL_PASSWORD] (if SQL auth)
```

**Schema Configuration:**

```sql
-- Object Types Query
SELECT 'person' as ObjectType

-- Attributes Query  
SELECT 
    'EmployeeID' as AttributeName,
    'String' as AttributeType,
    'False' as IsMultiValued,
    'True' as IsAnchor
UNION ALL
SELECT 'FirstName', 'String', 'False', 'False'
UNION ALL
SELECT 'LastName', 'String', 'False', 'False'
UNION ALL
SELECT 'DisplayName', 'String', 'False', 'False'
UNION ALL
SELECT 'Email', 'String', 'False', 'False'
UNION ALL
SELECT 'Department', 'String', 'False', 'False'
UNION ALL
SELECT 'Title', 'String', 'False', 'False'
UNION ALL
SELECT 'Manager', 'String', 'False', 'False'
UNION ALL
SELECT 'Location', 'String', 'False', 'False'
UNION ALL
SELECT 'PhoneNumber', 'String', 'False', 'False'
UNION ALL
SELECT 'StartDate', 'String', 'False', 'False'
UNION ALL
SELECT 'EndDate', 'String', 'False', 'False'
UNION ALL
SELECT 'Status', 'String', 'False', 'False'
UNION ALL
SELECT 'LastModified', 'String', 'False', 'False'
UNION ALL
SELECT 'IsActive', 'String', 'False', 'False'
```

**Import Queries:**

```sql
-- Full Import Query
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    DisplayName,
    Email,
    Department,
    Title,
    Manager,
    Location,
    PhoneNumber,
    CONVERT(NVARCHAR(50), StartDate, 120) as StartDate,
    CONVERT(NVARCHAR(50), EndDate, 120) as EndDate,
    Status,
    CONVERT(NVARCHAR(50), LastModified, 120) as LastModified,
    CASE WHEN IsActive = 1 THEN 'True' ELSE 'False' END as IsActive
FROM [dbo].[Identities]
WHERE IsActive = 1;

-- Delta Import Query (if using LastModified)
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    DisplayName,
    Email,
    Department,
    Title,
    Manager,
    Location,
    PhoneNumber,
    CONVERT(NVARCHAR(50), StartDate, 120) as StartDate,
    CONVERT(NVARCHAR(50), EndDate, 120) as EndDate,
    Status,
    CONVERT(NVARCHAR(50), LastModified, 120) as LastModified,
    CASE WHEN IsActive = 1 THEN 'True' ELSE 'False' END as IsActive
FROM [dbo].[Identities]
WHERE LastModified > ?
```

### 2. Active Directory Management Agent Setup

**Create AD Management Agent:**

1. Select **Management Agents** → **Create**
2. Choose **Active Directory Domain Services** connector type
3. Configure the following settings:

**Connectivity:**

```text
Forest name: [DOMAIN.COM]
User name: [DOMAIN\ServiceAccount]
Password: [ServiceAccountPassword]
```

**Configure Directory Partitions:**

- Select target domain partition
- Configure container filters for target OUs

**Object Types and Attributes:**

- Select **user** object type
- Include required attributes:
  - cn, displayName, givenName, sn
  - mail, telephoneNumber, department
  - title, manager, physicalDeliveryOfficeName
  - userPrincipalName, sAMAccountName
  - userAccountControl, employeeID

### 3. Run Profiles Configuration

**SQL Management Agent Run Profiles:**

```text
Full Import:
- Step Type: Full Import
- Partition: [Database]

Delta Import:
- Step Type: Delta Import  
- Partition: [Database]

Export:
- Step Type: Export
- Partition: [Database]
```

**Active Directory Management Agent Run Profiles:**

```text
Full Import:
- Step Type: Full Import
- Partition: [Domain Partition]

Delta Import:
- Step Type: Delta Import
- Partition: [Domain Partition]

Export:
- Step Type: Export
- Partition: [Domain Partition]

Delta Import and Export:
- Step 1: Delta Import
- Step 2: Export
```

## Metaverse Schema Extension

### 1. Metaverse Designer Configuration

**Extend Person Object Type:**

1. Open **Metaverse Designer**
2. Select **person** object type
3. Add custom attributes:

```text
employeeID: String (Indexed)
startDate: String
endDate: String
isActive: String
sourceSystem: String
lastSyncDate: String
```

### 2. Metaverse Rules Extension

Create a rules extension class to handle metaverse logic:

```csharp
using Microsoft.MetadirectoryServices;
using System;

public class MAExtensible : IMVSynchronization
{
    public void Initialize()
    {
        // Initialization logic
    }

    public void Terminate()
    {
        // Cleanup logic
    }

    public void Provision(MVEntry mventry)
    {
        // Provisioning logic for new metaverse objects
        if (mventry.ObjectType == "person")
        {
            ProvisionToActiveDirectory(mventry);
        }
    }

    public bool ShouldDeleteFromMV(CSEntry csentry, MVEntry mventry)
    {
        // Determine if metaverse object should be deleted
        if (csentry.MA.Name == "SQL-MA")
        {
            // Don't delete MV object when SQL object is deleted
            return false;
        }
        return true;
    }

    private void ProvisionToActiveDirectory(MVEntry mventry)
    {
        // Provision user to Active Directory
        ConnectedMA adMA = mventry.ConnectedMAs["AD-MA"];
        
        if (adMA.Connectors.Count == 0)
        {
            CSEntry csentry = adMA.Connectors.StartNewConnector("user");
            
            // Set distinguished name
            string ou = DetermineTargetOU(mventry);
            string cn = mventry["displayName"].Value ?? $"{mventry["givenName"].Value} {mventry["sn"].Value}";
            csentry.DN = adMA.EscapeDNComponent($"CN={cn}") + ou;
            
            // Set required attributes
            csentry["sAMAccountName"].Value = GenerateSAMAccountName(mventry);
            csentry["userPrincipalName"].Value = $"{csentry["sAMAccountName"].Value}@{GetDomain()}";
            csentry["userAccountControl"].IntegerValue = 512; // Normal account
            
            csentry.CommitNewConnector();
        }
    }

    private string DetermineTargetOU(MVEntry mventry)
    {
        string department = mventry["department"].Value;
        
        // Map departments to OUs
        switch (department?.ToLower())
        {
            case "it":
                return ",OU=IT,OU=Users,DC=domain,DC=com";
            case "hr":
                return ",OU=HR,OU=Users,DC=domain,DC=com";
            case "sales":
                return ",OU=Sales,OU=Users,DC=domain,DC=com";
            default:
                return ",OU=General,OU=Users,DC=domain,DC=com";
        }
    }

    private string GenerateSAMAccountName(MVEntry mventry)
    {
        string firstName = mventry["givenName"].Value?.ToLower() ?? "";
        string lastName = mventry["sn"].Value?.ToLower() ?? "";
        
        // Generate username format: first.last
        return $"{firstName}.{lastName}";
    }

    private string GetDomain()
    {
        return "domain.com"; // Replace with actual domain
    }
}
```

## Synchronization Rules Configuration

### 1. Inbound Synchronization Rules

**SQL to Metaverse Rule:**

**Rule Configuration:**

- **Name**: "In from SQL - Person"
- **Connected System**: SQL Management Agent
- **Connected System Object Type**: person
- **Metaverse Object Type**: person
- **Link Type**: Join
- **Precedence**: 10

**Join Criteria:**

```text
csObjectType = "person" AND 
mvObjectType = "person" AND
csObject("EmployeeID") = mvObject("employeeID")
```

**Attribute Flow Mappings:**

```text
Direct Mappings:
EmployeeID → employeeID
FirstName → givenName  
LastName → sn
DisplayName → displayName
Email → mail
Department → department
Title → title
Location → physicalDeliveryOfficeName
PhoneNumber → telephoneNumber

Expression Mappings:
StartDate → startDate (Flow: csObject("StartDate"))
EndDate → endDate (Flow: csObject("EndDate"))  
Status → isActive (Flow: IIF(csObject("Status")="Active","True","False"))
"SQL" → sourceSystem (Flow: "SQL")
```

### 2. Outbound Synchronization Rules

**Metaverse to Active Directory Rule:**

**Rule Configuration:**

- **Name**: "Out to AD - User"
- **Connected System**: Active Directory Management Agent
- **Connected System Object Type**: user
- **Metaverse Object Type**: person
- **Link Type**: Join
- **Precedence**: 10

**Join Criteria:**

```text
csObjectType = "user" AND 
mvObjectType = "person" AND
csObject("employeeID") = mvObject("employeeID")
```

**Attribute Flow Mappings:**

```text
Direct Mappings:
employeeID → employeeID
givenName → givenName
sn → sn  
displayName → displayName
mail → mail
department → department
title → title
physicalDeliveryOfficeName → physicalDeliveryOfficeName
telephoneNumber → telephoneNumber

Expression Mappings:
sAMAccountName (Flow: GenerateSAMAccountName())
userPrincipalName (Flow: csObject("sAMAccountName") + "@domain.com")
cn (Flow: csObject("displayName"))
```

## Advanced Rule Extensions

### 1. Custom Attribute Flow Rules

```csharp
using Microsoft.MetadirectoryServices;
using System;
using System.Text.RegularExpressions;

public class MAExtensible : IMASynchronization
{
    public void Initialize()
    {
        // Initialization
    }

    public void Terminate()
    {
        // Cleanup
    }

    public bool ShouldProjectToMV(CSEntry csentry, out string MVObjectType)
    {
        MVObjectType = "person";
        
        // Only project active employees
        if (csentry["Status"].Value == "Active" && 
            csentry["IsActive"].Value == "True")
        {
            return true;
        }
        
        return false;
    }

    public DeprovisionAction Deprovision(CSEntry csentry)
    {
        // Handle deprovisioning
        return DeprovisionAction.Disconnect;
    }

    public bool FilterForDisconnection(CSEntry csentry)
    {
        // Disconnect inactive users
        return csentry["IsActive"].Value == "False";
    }

    public void MapAttributesForJoin(string FlowRuleName, CSEntry csentry, ref ValueCollection values)
    {
        // Custom join logic
        switch (FlowRuleName)
        {
            case "cd.person:employeeID":
                values.Add(csentry["EmployeeID"].Value);
                break;
        }
    }

    public bool ResolveJoinSearch(string joinCriteriaName, CSEntry csentry, ReferenceValue[] rgmventry, out int imventry, ref string MVObjectType)
    {
        imventry = 0;
        MVObjectType = "person";
        return false;
    }

    public void MapAttributesForImport(string FlowRuleName, CSEntry csentry, ref ValueCollection values)
    {
        switch (FlowRuleName)
        {
            case "displayName":
                MapDisplayName(csentry, ref values);
                break;
            case "sAMAccountName":
                MapSAMAccountName(csentry, ref values);
                break;
            case "userPrincipalName":
                MapUserPrincipalName(csentry, ref values);
                break;
            case "manager":
                MapManager(csentry, ref values);
                break;
        }
    }

    public void MapAttributesForExport(string FlowRuleName, MVEntry mventry, ref ValueCollection values)
    {
        switch (FlowRuleName)
        {
            case "userAccountControl":
                MapUserAccountControl(mventry, ref values);
                break;
            case "homeDirectory":
                MapHomeDirectory(mventry, ref values);
                break;
        }
    }

    private void MapDisplayName(CSEntry csentry, ref ValueCollection values)
    {
        string firstName = csentry["FirstName"].Value ?? "";
        string lastName = csentry["LastName"].Value ?? "";
        
        if (!string.IsNullOrEmpty(firstName) && !string.IsNullOrEmpty(lastName))
        {
            values.Add($"{firstName} {lastName}");
        }
    }

    private void MapSAMAccountName(CSEntry csentry, ref ValueCollection values)
    {
        string firstName = csentry["FirstName"].Value?.ToLower() ?? "";
        string lastName = csentry["LastName"].Value?.ToLower() ?? "";
        
        if (!string.IsNullOrEmpty(firstName) && !string.IsNullOrEmpty(lastName))
        {
            string samAccountName = $"{firstName}.{lastName}";
            
            // Remove special characters and limit length
            samAccountName = Regex.Replace(samAccountName, @"[^a-zA-Z0-9.]", "");
            if (samAccountName.Length > 20)
            {
                samAccountName = samAccountName.Substring(0, 20);
            }
            
            values.Add(samAccountName);
        }
    }

    private void MapUserPrincipalName(CSEntry csentry, ref ValueCollection values)
    {
        string email = csentry["Email"].Value;
        if (!string.IsNullOrEmpty(email))
        {
            values.Add(email);
        }
    }

    private void MapManager(CSEntry csentry, ref ValueCollection values)
    {
        string managerEmployeeID = csentry["Manager"].Value;
        if (!string.IsNullOrEmpty(managerEmployeeID))
        {
            // Look up manager's DN in Active Directory
            string managerDN = LookupManagerDN(managerEmployeeID);
            if (!string.IsNullOrEmpty(managerDN))
            {
                values.Add(managerDN);
            }
        }
    }

    private void MapUserAccountControl(MVEntry mventry, ref ValueCollection values)
    {
        string isActive = mventry["isActive"].Value;
        
        if (isActive == "True")
        {
            values.Add("512"); // Normal account
        }
        else
        {
            values.Add("514"); // Disabled account
        }
    }

    private void MapHomeDirectory(MVEntry mventry, ref ValueCollection values)
    {
        string samAccountName = mventry["sAMAccountName"].Value;
        if (!string.IsNullOrEmpty(samAccountName))
        {
            values.Add($"\\\\fileserver\\users\\{samAccountName}");
        }
    }

    private string LookupManagerDN(string employeeID)
    {
        // Implementation to lookup manager DN by employee ID
        // This could query AD or maintain a lookup table
        return null; // Placeholder
    }
}
```

### 2. Error Handling and Logging

```csharp
using System;
using System.IO;
using System.Diagnostics;

public static class SyncLogger
{
    private static readonly string LogPath = @"C:\MIM\Logs\CustomSync.log";
    
    public static void LogInfo(string message)
    {
        WriteLog("INFO", message);
        EventLog.WriteEntry("MIM Sync Custom", message, EventLogEntryType.Information);
    }
    
    public static void LogWarning(string message)
    {
        WriteLog("WARN", message);
        EventLog.WriteEntry("MIM Sync Custom", message, EventLogEntryType.Warning);
    }
    
    public static void LogError(string message, Exception ex = null)
    {
        string fullMessage = ex != null ? $"{message}: {ex}" : message;
        WriteLog("ERROR", fullMessage);
        EventLog.WriteEntry("MIM Sync Custom", fullMessage, EventLogEntryType.Error);
    }
    
    private static void WriteLog(string level, string message)
    {
        try
        {
            string logEntry = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} [{level}] {message}";
            File.AppendAllText(LogPath, logEntry + Environment.NewLine);
        }
        catch
        {
            // Ignore logging errors
        }
    }
}

// Usage in rule extensions
public void MapAttributesForImport(string FlowRuleName, CSEntry csentry, ref ValueCollection values)
{
    try
    {
        SyncLogger.LogInfo($"Processing attribute flow: {FlowRuleName} for {csentry.DN}");
        
        switch (FlowRuleName)
        {
            case "displayName":
                MapDisplayName(csentry, ref values);
                break;
            // Other cases...
        }
    }
    catch (Exception ex)
    {
        SyncLogger.LogError($"Error in MapAttributesForImport for {FlowRuleName}", ex);
        throw;
    }
}
```

## Data Validation and Business Rules

### 1. Input Validation

```csharp
public class DataValidator
{
    public static bool ValidateEmployee(CSEntry csentry)
    {
        var errors = new List<string>();
        
        // Required field validation
        if (string.IsNullOrEmpty(csentry["EmployeeID"].Value))
            errors.Add("EmployeeID is required");
            
        if (string.IsNullOrEmpty(csentry["FirstName"].Value))
            errors.Add("FirstName is required");
            
        if (string.IsNullOrEmpty(csentry["LastName"].Value))
            errors.Add("LastName is required");
        
        // Email validation
        string email = csentry["Email"].Value;
        if (!string.IsNullOrEmpty(email) && !IsValidEmail(email))
            errors.Add("Invalid email format");
        
        // Date validation
        string startDate = csentry["StartDate"].Value;
        if (!string.IsNullOrEmpty(startDate) && !DateTime.TryParse(startDate, out _))
            errors.Add("Invalid StartDate format");
        
        if (errors.Any())
        {
            SyncLogger.LogWarning($"Validation errors for {csentry["EmployeeID"].Value}: {string.Join(", ", errors)}");
            return false;
        }
        
        return true;
    }
    
    private static bool IsValidEmail(string email)
    {
        return Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    }
}
```

### 2. Business Rule Implementation

```csharp
public class BusinessRules
{
    public static bool ShouldProvisionUser(MVEntry mventry)
    {
        // Don't provision contractors
        string employeeType = mventry["employeeType"].Value;
        if (employeeType == "Contractor")
            return false;
        
        // Don't provision users without start date
        string startDate = mventry["startDate"].Value;
        if (string.IsNullOrEmpty(startDate))
            return false;
        
        // Don't provision users with future start dates
        if (DateTime.TryParse(startDate, out DateTime start) && start > DateTime.Now)
            return false;
        
        return true;
    }
    
    public static string DetermineAccountStatus(MVEntry mventry)
    {
        string status = mventry["isActive"].Value;
        string endDate = mventry["endDate"].Value;
        
        // Check if user has passed end date
        if (!string.IsNullOrEmpty(endDate) && 
            DateTime.TryParse(endDate, out DateTime end) && 
            end < DateTime.Now)
        {
            return "Disabled";
        }
        
        return status == "True" ? "Enabled" : "Disabled";
    }
}
```

## Deployment and Testing

### 1. Development Environment Setup

**Rule Extension Compilation:**

```batch
@echo off
echo Compiling MIM Rule Extensions...

set FRAMEWORK_PATH="C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.6"
set MIM_PATH="C:\Program Files\Microsoft Forefront Identity Manager\2010\Synchronization Service\Bin"

csc.exe /target:library ^
    /reference:%MIM_PATH%\Microsoft.MetadirectoryServices.dll ^
    /reference:%FRAMEWORK_PATH%\System.dll ^
    /reference:%FRAMEWORK_PATH%\System.Core.dll ^
    /out:CustomRules.dll ^
    MAExtensible.cs ^
    SyncLogger.cs ^
    DataValidator.cs ^
    BusinessRules.cs

if %ERRORLEVEL% == 0 (
    echo Compilation successful
    copy CustomRules.dll %MIM_PATH%\Extensions\
    echo Rule extension deployed
) else (
    echo Compilation failed
)

pause
```

### 2. Testing Strategy

**Unit Testing Approach:**

```csharp
[TestClass]
public class RuleExtensionTests
{
    [TestMethod]
    public void TestSAMAccountNameGeneration()
    {
        // Create mock CSEntry
        var csentry = CreateMockCSEntry();
        csentry["FirstName"].Value = "John";
        csentry["LastName"].Value = "Doe";
        
        var extension = new MAExtensible();
        var values = new ValueCollection();
        
        extension.MapAttributesForImport("sAMAccountName", csentry, ref values);
        
        Assert.AreEqual("john.doe", values[0]);
    }
    
    [TestMethod]
    public void TestDataValidation()
    {
        var csentry = CreateMockCSEntry();
        csentry["EmployeeID"].Value = "EMP001";
        csentry["FirstName"].Value = "John";
        csentry["LastName"].Value = "Doe";
        csentry["Email"].Value = "john.doe@company.com";
        
        bool isValid = DataValidator.ValidateEmployee(csentry);
        
        Assert.IsTrue(isValid);
    }
}
```

### 3. Performance Monitoring

**PowerShell Monitoring Script:**

```powershell
# Monitor MIM Sync Performance
param(
    [string]$MIMServer = "localhost",
    [int]$IntervalMinutes = 5
)

while ($true)
{
    $timestamp = Get-Date
    
    # Check MIM Sync Service status
    $service = Get-Service -Name "FIMSynchronizationService" -ComputerName $MIMServer
    Write-Host "$timestamp - MIM Sync Service: $($service.Status)"
    
    # Check run statistics
    $sqlMA = Get-WmiObject -Namespace "root\MicrosoftIdentityIntegrationServer" -Class "MIIS_ManagementAgent" -Filter "Name='SQL-MA'" -ComputerName $MIMServer
    $adMA = Get-WmiObject -Namespace "root\MicrosoftIdentityIntegrationServer" -Class "MIIS_ManagementAgent" -Filter "Name='AD-MA'" -ComputerName $MIMServer
    
    Write-Host "$timestamp - SQL MA Objects: $($sqlMA.NumTotalConnectorSpaceObjects)"
    Write-Host "$timestamp - AD MA Objects: $($adMA.NumTotalConnectorSpaceObjects)"
    
    # Check for sync errors
    $errors = Get-EventLog -LogName Application -Source "FIMSynchronizationService" -EntryType Error -After (Get-Date).AddMinutes(-$IntervalMinutes) -ComputerName $MIMServer
    if ($errors)
    {
        Write-Warning "$timestamp - Found $($errors.Count) sync errors in last $IntervalMinutes minutes"
    }
    
    Start-Sleep -Seconds ($IntervalMinutes * 60)
}
```

## Operational Procedures

### 1. Daily Operations

**Automated Synchronization Schedule:**

```powershell
# Daily sync automation script
$MIMServer = "MIMSyncServer"
$LogPath = "C:\MIM\Logs\DailySync.log"

function Write-SyncLog($Message)
{
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $LogPath -Append
}

try
{
    Write-SyncLog "Starting daily synchronization"
    
    # SQL MA Delta Import
    Write-SyncLog "Running SQL MA Delta Import"
    Start-ManagementAgent -Name "SQL-MA" -RunProfile "Delta Import"
    
    # Synchronization
    Write-SyncLog "Running Synchronization"
    Start-ManagementAgent -Name "SQL-MA" -RunProfile "Delta Synchronization"
    
    # AD MA Export
    Write-SyncLog "Running AD MA Export"
    Start-ManagementAgent -Name "AD-MA" -RunProfile "Export"
    
    # AD MA Delta Import (for confirmations)
    Write-SyncLog "Running AD MA Delta Import"
    Start-ManagementAgent -Name "AD-MA" -RunProfile "Delta Import"
    
    Write-SyncLog "Daily synchronization completed successfully"
}
catch
{
    Write-SyncLog "ERROR: Daily synchronization failed - $($_.Exception.Message)"
    # Send alert email
    Send-MailMessage -To "admin@company.com" -Subject "MIM Sync Error" -Body $_.Exception.Message
}
```

### 2. Troubleshooting Guide

**Common Issues and Resolutions:**

| Issue | Symptoms | Resolution |
| ----- | -------- | ---------- |
| Connection timeout | Import/Export failures | Check network connectivity, increase timeout values |
| Duplicate objects | Join failures | Review join criteria, check for data quality issues |
| Rule extension errors | Sync failures with code errors | Check rule extension compilation, review logs |
| Performance issues | Slow synchronization | Optimize queries, increase batch sizes, add indexing |

**Diagnostic Commands:**

```powershell
# Check MA configuration
Get-WmiObject -Namespace "root\MicrosoftIdentityIntegrationServer" -Class "MIIS_ManagementAgent"

# View run history
Get-WmiObject -Namespace "root\MicrosoftIdentityIntegrationServer" -Class "MIIS_RunHistory" | Select-Object RunNumber, MaName, StartTime, EndTime, RunDetails

# Check connector space objects
Get-WmiObject -Namespace "root\MicrosoftIdentityIntegrationServer" -Class "MIIS_CSObject" -Filter "MaName='SQL-MA'" | Measure-Object

# Export sync statistics
$stats = Get-WmiObject -Namespace "root\MicrosoftIdentityIntegrationServer" -Class "MIIS_RunDetails"
$stats | Export-Csv -Path "C:\MIM\Reports\SyncStats.csv" -NoTypeInformation
```

## Security Considerations

### 1. Service Account Management

**SQL Service Account:**

- Minimum required permissions on SQL database
- Regular password rotation policy
- Audit account usage and access patterns

**AD Service Account:**

- Delegated permissions for target OUs only
- No interactive logon rights
- Regular access review and certification

### 2. Data Protection

**Sensitive Attribute Handling:**

```csharp
public void MapAttributesForImport(string FlowRuleName, CSEntry csentry, ref ValueCollection values)
{
    switch (FlowRuleName)
    {
        case "sensitiveData":
            // Encrypt or hash sensitive data
            string rawValue = csentry["SensitiveField"].Value;
            string encryptedValue = EncryptData(rawValue);
            values.Add(encryptedValue);
            break;
    }
}

private string EncryptData(string data)
{
    // Implement encryption logic
    // Use organization's approved encryption methods
    return data; // Placeholder
}
```

**Audit Logging:**

```csharp
public void MapAttributesForExport(string FlowRuleName, MVEntry mventry, ref ValueCollection values)
{
    // Log all export operations for audit
    SyncLogger.LogInfo($"Exporting {FlowRuleName} for user {mventry["employeeID"].Value}");
    
    // Record attribute changes for compliance
    RecordAttributeChange(mventry, FlowRuleName, values);
}
```

## Conclusion

This comprehensive guide provides a complete implementation framework for synchronizing SQL table identities to Active Directory using MIM 2016 Synchronization Service with rule extensions. The solution avoids the complexity of the MIM Service and Portal while providing robust, scalable, and maintainable identity synchronization capabilities.

Key benefits of this approach include:

- **Lightweight implementation** without MIM Service/Portal overhead
- **Flexible business logic** through custom rule extensions
- **Robust error handling** and comprehensive logging
- **Scalable architecture** supporting large identity datasets
- **Comprehensive security** with audit trails and data protection

Regular monitoring, maintenance, and adherence to security best practices ensure reliable long-term operation of the synchronization solution.

## Related Topics

- **[MIM 2016 Overview](index.md)**: High-level service architecture
- **[Rule Extensions Development](rule-extensions.md)**: Advanced custom code development
- **[Active Directory Integration](ad-integration.md)**: AD-specific configuration details
- **[Troubleshooting Guide](troubleshooting.md)**: Common issues and solutions
- **[Performance Tuning](performance-tuning.md)**: Optimization strategies
