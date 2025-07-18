---
title: SQL Server Security
description: Comprehensive guide to SQL Server security features, best practices, and implementation strategies for protecting enterprise data.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: article
ms.service: sql-server
keywords: SQL Server security, database security, authentication, authorization, encryption, audit, compliance
uid: docs.infrastructure.sql.security
---

SQL Server security is a multi-layered approach to protecting data, ensuring proper access controls, and maintaining compliance with regulatory requirements. This guide covers comprehensive security features and implementation strategies for enterprise environments.

## Security Architecture Overview

SQL Server implements a defense-in-depth security model with multiple layers:

- **Network Security**: Firewalls, protocols, and connection encryption
- **Authentication**: Identity verification and access control
- **Authorization**: Permission management and role-based access
- **Data Protection**: Encryption, masking, and classification
- **Auditing**: Monitoring and compliance tracking
- **Application Security**: SQL injection prevention and secure coding

> [!IMPORTANT]
> Security should be implemented from the ground up, not as an afterthought. Plan security measures during the design phase of your database application.

## Authentication Methods

### Windows Authentication (Recommended)

Windows Authentication leverages Active Directory for centralized identity management:

```sql
-- Create Windows login
CREATE LOGIN [DOMAIN\SQLAdmin] FROM WINDOWS;

-- Grant server-level permissions
ALTER SERVER ROLE sysadmin ADD MEMBER [DOMAIN\SQLAdmin];

-- Create Windows group login
CREATE LOGIN [DOMAIN\DatabaseUsers] FROM WINDOWS;
```

**Benefits:**

- Centralized identity management
- Strong password policies
- Kerberos authentication support
- No password storage in SQL Server

### SQL Server Authentication

SQL Server Authentication uses database-specific logins:

```sql
-- Create SQL Server login with strong password policy
CREATE LOGIN SQLUser WITH PASSWORD = 'StrongP@ssw0rd123!',
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = ON;

-- Set password expiration
ALTER LOGIN SQLUser WITH PASSWORD = 'NewP@ssw0rd456!';
```

> [!WARNING]
> SQL Server Authentication should only be used when Windows Authentication is not feasible. Always enforce strong password policies.

### Azure Active Directory Authentication

For Azure SQL Database and hybrid scenarios:

```sql
-- Create Azure AD login
CREATE LOGIN [user@company.com] FROM EXTERNAL PROVIDER;

-- Create Azure AD group login
CREATE LOGIN [DatabaseAdmins] FROM EXTERNAL PROVIDER;
```

## Authorization and Permissions

### Database Roles

SQL Server provides predefined database roles for common permission sets:

```sql
-- Add user to database roles
USE CompanyDB;
CREATE USER SQLUser FOR LOGIN SQLUser;

-- Grant read access
ALTER ROLE db_datareader ADD MEMBER SQLUser;

-- Grant read/write access
ALTER ROLE db_datawriter ADD MEMBER SQLUser;

-- Grant schema modification rights
ALTER ROLE db_ddladmin ADD MEMBER SQLUser;

-- Grant backup permissions
ALTER ROLE db_backupoperator ADD MEMBER SQLUser;
```

### Custom Database Roles

Create custom roles for specific business requirements:

```sql
-- Create custom role for application users
CREATE ROLE ApplicationUsers;

-- Grant specific permissions to custom role
GRANT SELECT, INSERT, UPDATE ON Orders TO ApplicationUsers;
GRANT SELECT ON Customers TO ApplicationUsers;
GRANT EXECUTE ON GetCustomerOrders TO ApplicationUsers;

-- Add users to custom role
ALTER ROLE ApplicationUsers ADD MEMBER AppUser1;
ALTER ROLE ApplicationUsers ADD MEMBER AppUser2;
```

### Granular Permissions

Implement fine-grained access control:

```sql
-- Grant column-level permissions
GRANT SELECT (CustomerID, CustomerName) ON Customers TO ReportUsers;

-- Grant permissions with GRANT OPTION
GRANT SELECT ON Orders TO TeamLead WITH GRANT OPTION;

-- Row-level security setup
CREATE SCHEMA Security;

CREATE FUNCTION Security.AccessPredicate(@UserID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS AccessResult
WHERE @UserID = USER_ID() OR IS_MEMBER('db_datareader') = 1;

CREATE SECURITY POLICY CustomerAccessPolicy
ADD FILTER PREDICATE Security.AccessPredicate(CustomerID) ON dbo.Customers;
```

## Data Encryption

### Transparent Data Encryption (TDE)

TDE encrypts the entire database at rest:

```sql
-- Enable TDE (run on master database)
USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MasterKeyP@ssw0rd123!';

-- Create certificate for TDE
CREATE CERTIFICATE TDECert WITH SUBJECT = 'TDE Certificate for CompanyDB';

-- Create database encryption key
USE CompanyDB;
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDECert;

-- Enable TDE
ALTER DATABASE CompanyDB SET ENCRYPTION ON;

-- Verify encryption status
SELECT 
    db_name(database_id) AS DatabaseName,
    encryption_state,
    encryption_state_desc,
    percent_complete
FROM sys.dm_database_encryption_keys;
```

### Always Encrypted

Protects sensitive data with client-side encryption:

```sql
-- Create column master key
CREATE COLUMN MASTER KEY CMK_Auto1
WITH (
    KEY_STORE_PROVIDER_NAME = 'MSSQL_CERTIFICATE_STORE',
    KEY_PATH = 'CurrentUser/My/A66BB0F6CC34D0C374B8CE46CFBC417F2B7162B2'
);

-- Create column encryption key
CREATE COLUMN ENCRYPTION KEY CEK_Auto1
WITH VALUES (
    COLUMN_MASTER_KEY = CMK_Auto1,
    ALGORITHM = 'RSA_OAEP',
    ENCRYPTED_VALUE = 0x016E000001630075007200720065006E0074007500730065007200...
);

-- Create table with encrypted columns
CREATE TABLE EmployeeData (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    SSN NVARCHAR(11) ENCRYPTED WITH (
        COLUMN_ENCRYPTION_KEY = CEK_Auto1,
        ENCRYPTION_TYPE = DETERMINISTIC,
        ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'
    ),
    Salary DECIMAL(10,2) ENCRYPTED WITH (
        COLUMN_ENCRYPTION_KEY = CEK_Auto1,
        ENCRYPTION_TYPE = RANDOMIZED,
        ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'
    )
);
```

### Connection Encryption

Encrypt data in transit:

```sql
-- Force encrypted connections (SQL Server Configuration Manager)
-- Or use connection string parameters:
-- "Server=myServer;Database=myDB;Encrypt=true;TrustServerCertificate=false;"
```

## Data Masking and Classification

### Dynamic Data Masking

Obscure sensitive data for non-privileged users:

```sql
-- Create table with data masking
CREATE TABLE CustomerData (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) MASKED WITH (FUNCTION = 'partial(1,"XXX",1)'),
    LastName NVARCHAR(50) MASKED WITH (FUNCTION = 'partial(1,"XXX",1)'),
    Email NVARCHAR(100) MASKED WITH (FUNCTION = 'email()'),
    Phone NVARCHAR(20) MASKED WITH (FUNCTION = 'default()'),
    CreditCardNumber NVARCHAR(19) MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XXXX-",4)'),
    Salary DECIMAL(10,2) MASKED WITH (FUNCTION = 'random(1000, 5000)')
);

-- Grant unmask permission to specific users
GRANT UNMASK TO DataAnalyst;

-- Test masking behavior
SELECT * FROM CustomerData; -- Regular user sees masked data
```

### Data Classification

Classify and label sensitive data:

```sql
-- Add sensitivity labels to columns
ADD SENSITIVITY CLASSIFICATION TO
    CustomerData.FirstName
WITH (LABEL = 'Personal', INFORMATION_TYPE = 'Name');

ADD SENSITIVITY CLASSIFICATION TO
    CustomerData.CreditCardNumber
WITH (LABEL = 'Highly Confidential', INFORMATION_TYPE = 'Financial');

-- Query classification metadata
SELECT 
    SCHEMA_NAME(o.schema_id) AS SchemaName,
    o.name AS TableName,
    c.name AS ColumnName,
    ic.label,
    ic.information_type
FROM sys.sensitivity_classifications ic
INNER JOIN sys.objects o ON ic.major_id = o.object_id
INNER JOIN sys.columns c ON ic.major_id = c.object_id AND ic.minor_id = c.column_id;
```

## Auditing and Compliance

### SQL Server Audit

Implement comprehensive auditing:

```sql
-- Create server audit
CREATE SERVER AUDIT CompanyAudit
TO FILE (
    FILEPATH = 'C:\SQLAudit\',
    MAXSIZE = 100MB,
    MAX_ROLLOVER_FILES = 10
)
WITH (
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);

-- Enable server audit
ALTER SERVER AUDIT CompanyAudit WITH (STATE = ON);

-- Create database audit specification
USE CompanyDB;
CREATE DATABASE AUDIT SPECIFICATION CompanyDB_Audit
FOR SERVER AUDIT CompanyAudit
ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Orders BY public),
ADD (SELECT ON dbo.Customers BY public),
ADD (EXECUTE ON dbo.GetCustomerOrders BY public);

-- Enable database audit specification
ALTER DATABASE AUDIT SPECIFICATION CompanyDB_Audit WITH (STATE = ON);
```

### Common Compliance Frameworks

#### GDPR Compliance

```sql
-- Implement data retention policies
CREATE PROCEDURE CleanupPersonalData
AS
BEGIN
    -- Delete old customer data (example: 7 years)
    DELETE FROM CustomerData
    WHERE CreatedDate < DATEADD(YEAR, -7, GETDATE());
    
    -- Log deletion activity
    INSERT INTO AuditLog (Action, TableName, RecordCount, ActionDate)
    VALUES ('GDPR_CLEANUP', 'CustomerData', @@ROWCOUNT, GETDATE());
END;
```

#### HIPAA Compliance

```sql
-- Implement access logging for healthcare data
CREATE TRIGGER tr_PatientAccess
ON PatientData
FOR SELECT, INSERT, UPDATE, DELETE
AS
BEGIN
    INSERT INTO AccessLog (
        UserName,
        Action,
        TableName,
        RecordID,
        AccessTime
    )
    SELECT 
        SUSER_SNAME(),
        'ACCESS',
        'PatientData',
        i.PatientID,
        GETDATE()
    FROM inserted i;
END;
```

## SQL Injection Prevention

### Parameterized Queries

Always use parameterized queries:

```sql
-- Vulnerable code (DON'T DO THIS)
-- EXEC('SELECT * FROM Users WHERE Username = ''' + @Username + '''')

-- Secure parameterized query
CREATE PROCEDURE GetUserInfo
    @Username NVARCHAR(50)
AS
BEGIN
    SELECT UserID, Username, Email, CreatedDate
    FROM Users
    WHERE Username = @Username;
END;
```

### Input Validation

Implement server-side validation:

```sql
CREATE PROCEDURE CreateUser
    @Username NVARCHAR(50),
    @Email NVARCHAR(100),
    @Password NVARCHAR(128)
AS
BEGIN
    -- Validate input parameters
    IF @Username IS NULL OR LEN(@Username) < 3 OR LEN(@Username) > 50
    BEGIN
        RAISERROR('Invalid username length', 16, 1);
        RETURN;
    END;
    
    IF @Email IS NULL OR @Email NOT LIKE '%@%.%'
    BEGIN
        RAISERROR('Invalid email format', 16, 1);
        RETURN;
    END;
    
    -- Use parameterized insert
    INSERT INTO Users (Username, Email, PasswordHash, CreatedDate)
    VALUES (@Username, @Email, HASHBYTES('SHA2_256', @Password), GETDATE());
END;
```

## Network Security

### SQL Server Configuration

Secure network configuration:

```sql
-- Disable unnecessary protocols
-- Use SQL Server Configuration Manager to disable:
-- - Named Pipes (if not needed)
-- - VIA protocol
-- - TCP/IP on unnecessary ports

-- Configure firewall rules
-- Allow only necessary ports:
-- - TCP 1433 (default SQL Server)
-- - TCP 1434 (SQL Browser Service)
-- - Custom ports for named instances
```

### Connection Security

```sql
-- Force SSL/TLS connections
-- In SQL Server Configuration Manager:
-- 1. Install SSL certificate
-- 2. Enable "Force Encryption"
-- 3. Set "Hide Instance" to Yes

-- Connection string with encryption
-- "Server=myServer;Database=myDB;Encrypt=true;TrustServerCertificate=false;"
```

## Security Best Practices

### Server-Level Security

> [!TIP]
> Follow the principle of least privilege - grant only the minimum permissions necessary for users to perform their tasks.

```sql
-- Disable unnecessary features
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

-- Disable xp_cmdshell
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;

-- Disable OLE Automation
EXEC sp_configure 'Ole Automation Procedures', 0;
RECONFIGURE;

-- Disable CLR integration (if not needed)
EXEC sp_configure 'clr enabled', 0;
RECONFIGURE;
```

### Database-Level Security

```sql
-- Remove guest user access
USE CompanyDB;
REVOKE CONNECT FROM guest;

-- Disable cross-database ownership chaining
ALTER DATABASE CompanyDB SET DB_CHAINING OFF;

-- Enable trustworthy only when necessary
ALTER DATABASE CompanyDB SET TRUSTWORTHY OFF;
```

### Application Security

```sql
-- Use application roles for connection pooling
CREATE APPLICATION ROLE AppRole WITH PASSWORD = 'AppRoleP@ssw0rd123!';

-- Grant permissions to application role
GRANT SELECT, INSERT, UPDATE ON Orders TO AppRole;
GRANT EXECUTE ON GetCustomerOrders TO AppRole;

-- Activate application role in application
-- sp_setapprole 'AppRole', 'AppRoleP@ssw0rd123!'
```

## Security Monitoring

### Real-Time Monitoring

```sql
-- Monitor failed login attempts
SELECT 
    event_time,
    database_name,
    server_principal_name,
    client_ip,
    application_name,
    statement
FROM sys.fn_get_audit_file('C:\SQLAudit\*.sqlaudit', DEFAULT, DEFAULT)
WHERE action_id = 'LGIF' -- Login Failed
ORDER BY event_time DESC;

-- Monitor permission changes
SELECT 
    event_time,
    database_name,
    server_principal_name,
    action_id,
    statement
FROM sys.fn_get_audit_file('C:\SQLAudit\*.sqlaudit', DEFAULT, DEFAULT)
WHERE action_id IN ('GRANT', 'REVOKE', 'DENY')
ORDER BY event_time DESC;
```

### Security Assessment

```sql
-- Check for common security vulnerabilities
SELECT 
    name,
    is_policy_checked,
    is_expiration_checked,
    password_last_set_time
FROM sys.sql_logins
WHERE is_policy_checked = 0 OR is_expiration_checked = 0;

-- Check for unused logins
SELECT 
    sp.name,
    sp.create_date,
    sp.modify_date,
    sl.last_login_time
FROM sys.server_principals sp
LEFT JOIN sys.dm_exec_sessions s ON sp.principal_id = s.user_id
LEFT JOIN sys.server_logins sl ON sp.name = sl.name
WHERE sp.type IN ('S', 'U') 
    AND s.user_id IS NULL
    AND (sl.last_login_time < DATEADD(DAY, -90, GETDATE()) OR sl.last_login_time IS NULL);
```

## Disaster Recovery Security

### Backup Security

```sql
-- Encrypt backups
BACKUP DATABASE CompanyDB 
TO DISK = 'C:\Backups\CompanyDB_Encrypted.bak'
WITH ENCRYPTION (
    ALGORITHM = AES_256,
    SERVER CERTIFICATE = BackupCertificate
);

-- Create backup certificate
CREATE CERTIFICATE BackupCertificate
WITH SUBJECT = 'Database Backup Certificate';
```

### Recovery Security

```sql
-- Restore with security validation
RESTORE DATABASE CompanyDB_Test
FROM DISK = 'C:\Backups\CompanyDB_Encrypted.bak'
WITH REPLACE, CHECKSUM, VERIFY_ONLY;

-- Reset orphaned users after restore
USE CompanyDB_Test;
EXEC sp_change_users_login 'Report';
EXEC sp_change_users_login 'Auto_Fix', 'username';
```

## Security Troubleshooting

### Common Security Issues

> [!WARNING]
> Security issues can lead to data breaches. Address them immediately and follow your organization's incident response procedures.

**Authentication Failures:**

- Check login credentials and expiration
- Verify server accessibility and firewall rules
- Review Active Directory connectivity

**Permission Denied Errors:**

- Verify user permissions and role membership
- Check object ownership and permission inheritance
- Review application role activation

**Encryption Issues:**

- Validate certificate installation and expiration
- Check TDE status and key accessibility
- Verify Always Encrypted configuration

### Useful Security Queries

```sql
-- Check current security context
SELECT 
    SUSER_NAME() AS LoginName,
    USER_NAME() AS UserName,
    IS_SRVROLEMEMBER('sysadmin') AS IsSysAdmin,
    IS_MEMBER('db_owner') AS IsDBOwner;

-- Review user permissions
SELECT 
    dp.state_desc,
    dp.permission_name,
    dp.class_desc,
    COALESCE(o.name, s.name) AS object_name,
    pr.name AS principal_name
FROM sys.database_permissions dp
LEFT JOIN sys.objects o ON dp.major_id = o.object_id
LEFT JOIN sys.schemas s ON dp.major_id = s.schema_id
JOIN sys.database_principals pr ON dp.grantee_principal_id = pr.principal_id
WHERE pr.name = 'username';

-- Check for security vulnerabilities
SELECT 
    name,
    type_desc,
    is_disabled
FROM sys.server_principals
WHERE type IN ('S', 'U') AND is_disabled = 0;
```

## Resources and Further Reading

### Official Documentation

- [SQL Server Security Center](https://docs.microsoft.com/en-us/sql/relational-databases/security/security-center-for-sql-server-database-engine-and-azure-sql-database)
- [SQL Server Audit Reference](https://docs.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-database-engine)
- [Always Encrypted Documentation](https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/always-encrypted-database-engine)

### Security Tools

- **SQL Server Configuration Manager**: Network and service configuration
- **SQL Server Management Studio**: Security management interface
- **PowerShell**: Automated security configuration
- **Azure Security Center**: Cloud-based security monitoring

### Compliance Resources

- [Microsoft Compliance Center](https://compliance.microsoft.com/index.md)
- [SQL Server Compliance Documentation](https://docs.microsoft.com/en-us/sql/relational-databases/security/compliance/index.md)
- [Azure Trust Center](https://azure.microsoft.com/en-us/trust-center/index.md)

## Conclusion

SQL Server security requires a comprehensive approach combining authentication, authorization, encryption, auditing, and monitoring. Regular security assessments, proper configuration management, and staying updated with security patches are essential for maintaining a secure database environment.

Remember that security is an ongoing process, not a one-time setup. Regularly review and update your security measures to address new threats and changing business requirements.
