---
title: SQL Query Reference
description: A comprehensive collection of commonly used SQL queries for quick reference and daily development tasks, including SELECT, UPDATE, INSERT, DELETE, and advanced SQL operations.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: article
ms.service: sql-server
keywords: SQL, queries, database, T-SQL, SQL Server, SELECT, UPDATE, INSERT, DELETE, JOIN, CTE
uid: docs.infrastructure.sql.sqlqueries
---

A comprehensive collection of commonly used SQL queries for quick reference and daily development tasks.

> [!NOTE]
> This reference guide covers SQL Server T-SQL syntax. Some queries may need modification for other database systems like MySQL, PostgreSQL, or Oracle.

## SELECT Statements

### Basic SELECT Operations

**Simple select with WHERE clause:**

```sql
SELECT *
FROM [dbo].[table]
WHERE (column = 'value1') AND (column = 'value2')
```

**Select distinct values in a column:**

```sql
SELECT DISTINCT [column]
FROM [dbo].[table]
```

### Aggregate Queries

**Select values that appear more than N times:**

```sql
SELECT column1, COUNT(column2)
FROM [dbo].[table]
GROUP BY column1
HAVING COUNT(column2) > 1
```

### Working with Temporary Tables

> [!TIP]
> Temporary tables are useful for storing intermediate results and breaking down complex queries into manageable steps.

**Find duplicate records using temporary table:**

```sql
DECLARE @Temp TABLE (NAME varchar(20))
INSERT INTO @Temp (NAME)
SELECT accountName
FROM [StagingDirectory].[dbo].[Identities]
GROUP BY accountName
HAVING COUNT(accountName) > 1
```

**Join with temporary table to get full records:**

```sql
SELECT [accountName],
    [lastName],
    [firstName],
    [initials],
    [employeeID],
    [employeeStatus],
    [employeeType],
    [employeeNumber]
FROM @Temp Temp
JOIN Identities ON Temp.name = Identities.accountname
ORDER BY accountName
```

## UPDATE Statements

### Basic UPDATE Operations

**Simple update statement:**

```sql
UPDATE [dbo].[table]
SET column = 'value'
WHERE column = 'value';
```

**Find and replace text in a column:**

```sql
UPDATE [dbo].[table]
SET Column = REPLACE(Column, 'xx', 'XX')
```

## INSERT Statements

### Basic INSERT Operations

**Insert single record:**

```sql
INSERT INTO [dbo].[table] (column1, column2, column3)
VALUES ('value1', 'value2', 'value3');
```

**Copy data from another table:**

```sql
INSERT INTO dbo.Table2
SELECT *
FROM dbo.Table1;
```

## DELETE Statements

### Basic DELETE Operations

**Delete with WHERE clause:**

```sql
DELETE FROM [dbo].[table]
WHERE column = 'value'
```

## MERGE Statements

### UPSERT Operations

> [!IMPORTANT]
> MERGE statements should always be used within transactions to ensure data consistency. Test thoroughly before using in production environments.

**Update if exists, insert if not:**

```sql
BEGIN TRAN;
MERGE Target AS T
USING Source AS S
ON (T.EmployeeID = S.EmployeeID)
WHEN NOT MATCHED BY TARGET AND S.EmployeeName LIKE 'S%'
    THEN INSERT(EmployeeID, EmployeeName) 
    VALUES(S.EmployeeID, S.EmployeeName)
WHEN MATCHED
    THEN UPDATE SET T.EmployeeName = S.EmployeeName
WHEN NOT MATCHED BY SOURCE AND T.EmployeeName LIKE 'S%'
    THEN DELETE
OUTPUT $action, inserted.*, deleted.*;
ROLLBACK TRAN;
GO
```

## Database Schema and Metadata

### Table Information

**List columns in a table:**

```sql
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TableName'
```

**Format column information as CREATE TABLE statement:**

```sql
SELECT COLUMN_NAME + ' ' + DATA_TYPE + '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS varchar) + ')' AS Columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TableName'
```

## Advanced Queries

### Conditional Aggregation

**Count records with different conditions:**

```sql
SELECT  
    SUM(CASE WHEN accountName IS NOT NULL AND employeeStatus IN ('A','P') THEN 1 ELSE 0 END) AS ActiveIds,
    SUM(CASE WHEN accountName IS NOT NULL AND employeeStatus IN ('D') THEN 1 ELSE 0 END) AS DisabledIds,
    SUM(CASE WHEN accountName IS NOT NULL AND employeeStatus IN ('A','P') AND employeeType != 'S' THEN 1 ELSE 0 END) AS ActiveIdsEmployees,
    SUM(CASE WHEN accountName IS NOT NULL AND employeeStatus = 'D' AND employeeType != 'S' THEN 1 ELSE 0 END) AS DisabledIdsEmployees,
    SUM(CASE WHEN accountName IS NOT NULL AND employeeStatus IN ('A','P') AND employeeType = 'S' THEN 1 ELSE 0 END) AS ActiveIdsStudents,
    SUM(CASE WHEN accountName IS NOT NULL AND employeeStatus = 'D' AND employeeType = 'S' THEN 1 ELSE 0 END) AS DisabledIdsStudents,
    SUM(CASE WHEN accountName IS NOT NULL AND ((employeeStatus = 'A' AND employeeType = 'S' AND termNumber < 1250) OR (employeeStatus = 'A' AND employeeType != 'S')) THEN 1 ELSE 0 END) AS O365Users
FROM [StagingDirectory].[dbo].[Identities]
```

**Sample output:**

| ActiveIds | DisabledIds | ActiveIdsEmployees | DisabledIdsEmployees | ActiveIdsStudents | DisabledIdsStudents | O365Users |
|-----------|-------------|--------------------|--------------------|-------------------|---------------------|-----------|
| 323944    | 14296       | 3406               | 8831               | 320538            | 5465                | 241263    |

### Date-Based Queries

**Return records after a specific date:**

```sql
SELECT [accountName], 
    [email],
    [firstName],
    [lastName],
    [initials],
    [personalEmail],
    [employeeID],
    [employeeStatus],
    [employeeType],
    [jobTitle]
FROM [StagingDirectory].[dbo].[Identities]
WHERE employeeType = 'S' 
    AND whenUpdated > DATEADD(day, -6, GETDATE())
ORDER BY whenUpdated
```

## Common Date Functions

**Various date operations:**

# [SQL Server](#tab/sql-server)

```sql
-- Current date and time
SELECT GETDATE()

-- Add/subtract time intervals
SELECT DATEADD(day, 30, GETDATE())     -- Add 30 days
SELECT DATEADD(month, -6, GETDATE())   -- Subtract 6 months
SELECT DATEADD(year, 1, GETDATE())     -- Add 1 year

-- Date difference
SELECT DATEDIFF(day, '2023-01-01', GETDATE())

-- Format dates
SELECT FORMAT(GETDATE(), 'yyyy-MM-dd')
SELECT FORMAT(GETDATE(), 'MM/dd/yyyy')
```

# [MySQL](#tab/mysql)

```sql
-- Current date and time
SELECT NOW()

-- Add/subtract time intervals
SELECT DATE_ADD(NOW(), INTERVAL 30 DAY)     -- Add 30 days
SELECT DATE_SUB(NOW(), INTERVAL 6 MONTH)    -- Subtract 6 months
SELECT DATE_ADD(NOW(), INTERVAL 1 YEAR)     -- Add 1 year

-- Date difference
SELECT DATEDIFF(NOW(), '2023-01-01')

-- Format dates
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d')
SELECT DATE_FORMAT(NOW(), '%m/%d/%Y')
```

# [PostgreSQL](#tab/postgresql)

```sql
-- Current date and time
SELECT NOW()

-- Add/subtract time intervals
SELECT NOW() + INTERVAL '30 days'     -- Add 30 days
SELECT NOW() - INTERVAL '6 months'    -- Subtract 6 months
SELECT NOW() + INTERVAL '1 year'      -- Add 1 year

-- Date difference
SELECT NOW() - '2023-01-01'::date

-- Format dates
SELECT TO_CHAR(NOW(), 'YYYY-MM-DD')
SELECT TO_CHAR(NOW(), 'MM/DD/YYYY')
```

---

## String Functions

**Common string manipulation:**

```sql
-- Concatenation
SELECT CONCAT(firstName, ' ', lastName) AS FullName
SELECT firstName + ' ' + lastName AS FullName

-- Substring
SELECT SUBSTRING(email, 1, CHARINDEX('@', email) - 1) AS Username

-- String length
SELECT LEN(columnName)

-- Trim whitespace
SELECT LTRIM(RTRIM(columnName))

-- Case conversion
SELECT UPPER(columnName), LOWER(columnName)

-- Pattern matching
SELECT * FROM table WHERE columnName LIKE 'A%'    -- Starts with 'A'
SELECT * FROM table WHERE columnName LIKE '%@%.%' -- Contains email pattern
```

## Window Functions

**Ranking and analytical functions:**

```sql
-- Row numbers
SELECT 
    columnName,
    ROW_NUMBER() OVER (ORDER BY columnName) AS RowNum
FROM table

-- Ranking
SELECT 
    columnName,
    RANK() OVER (ORDER BY columnName) AS Rank,
    DENSE_RANK() OVER (ORDER BY columnName) AS DenseRank
FROM table

-- Partitioned ranking
SELECT 
    category,
    columnName,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY columnName) AS RowNum
FROM table
```

## JOIN Operations

### Different types of JOINs

**INNER JOIN (only matching records):**

```sql
SELECT t1.column1, t2.column2
FROM table1 t1
INNER JOIN table2 t2 ON t1.id = t2.id
```

**LEFT JOIN (all records from left table):**

```sql
SELECT t1.column1, t2.column2
FROM table1 t1
LEFT JOIN table2 t2 ON t1.id = t2.id
```

**RIGHT JOIN (all records from right table):**

```sql
SELECT t1.column1, t2.column2
FROM table1 t1
RIGHT JOIN table2 t2 ON t1.id = t2.id
```

**FULL OUTER JOIN (all records from both tables):**

```sql
SELECT t1.column1, t2.column2
FROM table1 t1
FULL OUTER JOIN table2 t2 ON t1.id = t2.id
```

## Common Table Expressions (CTEs)

**Basic CTE:**

```sql
WITH EmployeeCTE AS (
    SELECT employeeID, firstName, lastName, departmentID
    FROM Employees
    WHERE employeeStatus = 'A'
)
SELECT * FROM EmployeeCTE
WHERE departmentID = 10
```

**Recursive CTE (for hierarchical data):**

```sql
WITH OrgChart AS (
    -- Anchor member
    SELECT employeeID, managerID, firstName, lastName, 1 AS Level
    FROM Employees
    WHERE managerID IS NULL
    
    UNION ALL
    
    -- Recursive member
    SELECT e.employeeID, e.managerID, e.firstName, e.lastName, o.Level + 1
    FROM Employees e
    INNER JOIN OrgChart o ON e.managerID = o.employeeID
)
SELECT * FROM OrgChart
```

## Performance Tips

> [!WARNING]
> Always test performance changes in a development environment before applying to production. Monitor query execution plans and system performance.

**Use indexes effectively:**

```sql
-- Create index
CREATE INDEX IX_Employee_Email ON Employees(email)

-- Create composite index
CREATE INDEX IX_Employee_Status_Type ON Employees(employeeStatus, employeeType)
```

**Avoid SELECT * in production:**

```sql
-- Bad
SELECT * FROM LargeTable

-- Good
SELECT column1, column2, column3 FROM LargeTable
```

**Use EXISTS instead of IN for subqueries:**

```sql
-- Less efficient
SELECT * FROM table1 WHERE id IN (SELECT id FROM table2)

-- More efficient
SELECT * FROM table1 WHERE EXISTS (SELECT 1 FROM table2 WHERE table2.id = table1.id)
```

## Error Handling

> [!CAUTION]
> Always implement proper error handling in production code. Unhandled exceptions can cause data corruption or application crashes.

**TRY-CATCH blocks:**

```sql
BEGIN TRY
    BEGIN TRANSACTION
    
    INSERT INTO table1 (column1, column2) VALUES ('value1', 'value2')
    UPDATE table2 SET column1 = 'newvalue' WHERE id = 1
    
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
    
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState
END CATCH
```

## Useful System Functions

**Database information:**

```sql
-- Current database
SELECT DB_NAME()

-- Current user
SELECT CURRENT_USER, USER_NAME()

-- Database size
SELECT 
    name,
    size/128.0 AS SizeMB
FROM sys.database_files

-- Table row counts
SELECT 
    t.name AS TableName,
    p.rows AS RowCount
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id < 2
ORDER BY p.rows DESC
```

## Advanced Topics

### Stored Procedures

**Create a basic stored procedure:**

```sql
CREATE PROCEDURE GetEmployeesByDepartment
    @DepartmentID INT
AS
BEGIN
    SELECT employeeID, firstName, lastName, email
    FROM Employees
    WHERE departmentID = @DepartmentID
        AND employeeStatus = 'A'
    ORDER BY lastName, firstName
END
```

**Execute stored procedure:**

```sql
EXEC GetEmployeesByDepartment @DepartmentID = 10
```

### Views

**Create a view:**

```sql
CREATE VIEW ActiveEmployees AS
SELECT employeeID, firstName, lastName, email, departmentID
FROM Employees
WHERE employeeStatus = 'A'
```

**Query a view:**

```sql
SELECT * FROM ActiveEmployees
WHERE departmentID = 10
```

### Triggers

**Create an audit trigger:**

```sql
CREATE TRIGGER tr_Employee_Audit
ON Employees
AFTER UPDATE
AS
BEGIN
    INSERT INTO EmployeeAudit (employeeID, changeDate, changeType)
    SELECT employeeID, GETDATE(), 'UPDATE'
    FROM inserted
END
```

## Security Best Practices

> [!IMPORTANT]
> Always follow security best practices when writing SQL queries to prevent SQL injection and unauthorized access.

**Use parameterized queries:**

```sql
-- Bad (vulnerable to SQL injection)
SELECT * FROM Users WHERE username = '" + userInput + "'

-- Good (parameterized)
SELECT * FROM Users WHERE username = @username
```

**Grant minimal permissions:**

```sql
-- Create user with limited permissions
CREATE USER AppUser WITHOUT LOGIN
GRANT SELECT, INSERT, UPDATE ON dbo.Employees TO AppUser
```

## Next Steps

- Learn about [SQL Server Query Optimization](https://docs.microsoft.com/en-us/sql/relational-databases/query-processing-architecture-guide)
- Explore [Advanced T-SQL Features](https://docs.microsoft.com/en-us/sql/t-sql/language-reference)
- Practice with [SQL Server Sample Databases](https://docs.microsoft.com/en-us/sql/samples/sql-samples-where-are)
- Study [Database Design Best Practices](https://docs.microsoft.com/en-us/sql/relational-databases/tables/design-tables)

## Related Resources

- [T-SQL Language Reference](https://docs.microsoft.com/en-us/sql/t-sql/language-reference)
- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/sql-server/)
- [Query Performance Tuning](https://docs.microsoft.com/en-us/sql/relational-databases/performance/query-performance-tuning)
- [Database Engine Programming](https://docs.microsoft.com/en-us/sql/relational-databases/database-engine-developer-documentation)
