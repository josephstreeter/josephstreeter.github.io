# SQL

---

A place to save the SQL queries that I constantly have to Google.

## SELECT Statements

---

Simple select

```sql
SELECT *
FROM [dbo].[table]
WHERE (column = 'value1') AND (Column = 'value2')
```

Select distinct values in a column

```sql
SELECT DISTINCT [column]
FROM [dbo].[table]
```

Select the values in a column that exist more then 'N' times

```sql
SELECT column1, COUNT(column2)
FROM [dbo].[table]
GROUP BY email
HAVING ( COUNT(column2) > 1 )
```

```sql
DECLARE @Temp TABLE (NAME varchar(20))
INSERT INTO @Temp (NAME)
SELECT accountName --, COUNT(AccountName) AS Count
FROM [StagingDirectory].[dbo].[Identities]
GROUP BY accountName
HAVING ( COUNT(accountName) > 1 )
```

```sql
SELECT [accountName]
    ,[lastName]
    ,[firstName]
    ,[initials]
    ,[employeeID]
    ,[employeeStatus]
    ,[employeeType]
    ,[employeeNumber]
FROM @Temp Temp
JOIN Identities
ON Temp.name=Identities.accountname
ORDER BY accountName
```

### UPDATE Statements

---

A simple update statement

```sql
UPDATE [dbo].[table]
SET column='value'
WHERE column='value';
```

Find/Replace

```sql
UPDATE [dbo].[table]
SET Column = REPLACE(Column,'xx','XX')
```

## INSERT Statements

---

Insert into table

```sql
INSERT INTO [dbo].[table] (column1,column2,column3)
VALUES ('value1','value2','value3');
```

### DELETE Statements

---

Delete from a table

```sql
DELETE FROM [dbo].[table]
WHERE column = 'value'
```

### MERGE Statements

---

Update if a record exists and insert if it doesn't

```sql
BEGIN TRAN;
MERGE Target AS T
USING Source AS S
ON (T.EmployeeID = S.EmployeeID)
WHEN NOT MATCHED BY TARGET AND S.EmployeeName LIKE 'S%'
THEN INSERT(EmployeeID, EmployeeName) VALUES(S.EmployeeID, S.EmployeeName)
WHEN MATCHED
THEN UPDATE SET T.EmployeeName = S.EmployeeName
WHEN NOT MATCHED BY SOURCE AND T.EmployeeName LIKE 'S%'
THEN DELETE
OUTPUT $action, inserted.*, deleted.*;
ROLLBACK TRAN;
GO
```

### Copy Table Data

---

Copy a table into another table

```sql
INSERT INTO dbo.Table2
SELECT *
FROM dob.Table1;
```

### List Columns in a Table

---

List the columns of a table

```sql
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TableName'
```

```sql
SELECT COLUMN_NAME + ' ' + DATA_TYPE + '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS varchar) + ')' AS Columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TableName'
```
