---

title:  MS Access DB with PowerShell
date:   2014-04-18 00:00:00 -0500
categories: IT
---






Use ADO to connect to a Microsoft Access database from PowerShell. In order to do this you may have to download "Microsoft Access Database Engine 2010." If you have 32-bit MS Office installed you will have to install the 32-bit engine. Likewise, you will have to run PowerShell in 32-bit mode.
```powershell$adOpenStatic = 3
$adLockOptimistic = 3

$conn=New-Object -com "ADODB.Connection"
$rs = New-Object -com "ADODB.Recordset"
$conn.Open('Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\inventory.accdb;Persist Security Info=True;')

$rs.Open("SELECT * FROM COMPUTERS",$conn,$adOpenStatic,$adLockOptimistic)

$rs.Fields.Item("Name").value
$rs.Fields.Item("OperatingSystem").value
$rs.Fields.Item("Model").value
$rs.Fields.Item("SerialNumber").value

$conn.Close
$rs.Close```
First we set these two variables to set the cursor type and record locking method used
```powershell$adOpenStatic = 3
$adLockOptimistic = 3```
*adLockOptimistic* - Indicates optimistic locking, record by record. The provider uses optimistic locking, which locks records only when you call the Update method.
*adOpenStatic* - Uses a static cursor, which is a static copy of a set of records that you can use to find data or generate reports. Additions, changes, or deletions by other users are not visible.

Next we create objects for ADODB.Connection and ADODB.Recordset. These objects will be used for the connection to the database itself and the set of records we want to work with.
```powershell$conn=New-Object -com "ADODB.Connection"
$rs = New-Object -com "ADODB.Recordset"```
Now we will use the $conn object to connect to the database.
```powershell(Access 2010 - 2013)
$conn.Open('Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\inventory.accdb;Persist Security Info=True;')```
```powershell(Access 2007 and earlier)
$conn.Open('Provider=Microsoft.Jet.OLEDB.4.0; Data Source=C:\inventory.mdb;')```
Now that we have a connection set we can select the records we want to work with.
```powershell$rs.Open("SELECT * FROM COMPUTERS",$conn,$adOpenStatic,$adLockOptimistic)```
Once the recordset is created we can read whats in it.
```powershell$rs.Fields.Item("Name").value
$rs.Fields.Item("OperatingSystem").value
$rs.Fields.Item("Model").value
$rs.Fields.Item("SerialNumber").value```
Or we could add a new record
```powershell$rs.AddNew()
$rs.Fields.Item("Name").value = "Computer01"
$rs.Fields.Item("OperatingSystem").value = "Microsoft Windows 8 Pro"
$rs.Fields.Item("Model").value = "Dell D820 Latitude"
$rs.Fields.Item("SerialNumber").value "D123456"
$rs.Update()```
Close the connection and recordset when you're done.
```powershell$conn.Close
$rs.Close```


