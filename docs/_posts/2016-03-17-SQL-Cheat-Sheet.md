---
layout: post
title:  SQL Cheat Sheet
date:   2016-03-17 00:00:00 -0500
categories: IT
---






A place to save the SQL queries that I constantly have to Google.
### SELECT Statements
{% highlight powershell %}
SELECT *
FROM [dbo].[table]
WHERE (column = 'value1') AND (Column = 'value2')

SELECT DISTINCT [column]
FROM [dbo].[table]

SELECT column1, COUNT(column2)
FROM [dbo].[table]
GROUP BY email
HAVING ( COUNT(email) > 1 )

DECLARE @Temp TABLE (NAME varchar(20))
INSERT INTO @Temp (NAME)
SELECT accountName --, COUNT(AccountName) AS Count
FROM [StagingDirectory].[dbo].[Identities]
GROUP BY accountName
HAVING ( COUNT(accountName) > 1 )

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
{% endhighlight %}
### UPDATE Statements
{% highlight powershell %}
UPDATE [dbo].[table]
SET column='value'
WHERE column='value';

UPDATE [dbo].[table]
SET Column = REPLACE(Column,'xx','XX')
{% endhighlight %}
## INSERT Statements
{% highlight powershell %}
INSERT INTO [dbo].[table] (column1,column2,column3)
VALUES ('value1','value2','value3');
{% endhighlight %}
### DELETE Statements
{% highlight powershell %}
DELETE FROM [dbo].[table]
WHERE column = 'value'
{% endhighlight %}
### MERGE Statements
{% highlight powershell %}
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
{% endhighlight %}

### Copy Table Data
{% highlight powershell %}
INSERT INTO dbo.Table2
SELECT *
FROM dob.Table1;
{% endhighlight %}

### List Columns in a Table
{% highlight powershell %}
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TableName'

SELECT COLUMN_NAME + ' ' + DATA_TYPE + '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS varchar) + ')' AS Columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TableName'
{% endhighlight %}


