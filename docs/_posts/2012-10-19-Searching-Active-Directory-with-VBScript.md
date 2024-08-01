---
title:  Searching Active Directory with VBScript
date:   2012-10-19 00:00:00 -0500
categories: IT
---

I am constantly writing scripts to search AD. Basically I'm using them to create little reports for one reason or another. Sometimes I will use them to do bulk updates. I've attached examples for searching users, computers, and shared printers that are published in AD.

The following script is one that I am writing to get a list of user objects that have a Kerberos username in the â€œaltSecurityIdentities attribute. We are using pass-through authentication to a MIT Kerberos implementation outside of our Active Directory environment. Most of you won't find anything in that attribute and may want to test this with the â€œdescription attribute instead.

First you will need to connect to the Directory. Connecting to the RootDSE is usually the easiest place to connect. Using RootDSE will make your script more portable by not requiring you to change LDAP strings to use it in another domain. In this case I've broken up the connection string into variables to make it easier to change

```powershell
Set objRootDSE = GetObject("LDAP://RootDSE")
strDNSDomain = objRootDSE.Get("defaultNamingContext")

Set objCmd = CreateObject("ADODB.Command")
Set objConn = CreateObject("ADODB.Connection")
objConn.Provider = "ADsDSOObject"
objConn.Open "Active Directory Provider"
objCmd.ActiveConnection = objConn
```

You will have to construct an ADSI filter to return the results that you want.

**Examples:**

"(objectClass=*)" = All objects.
"(&(objectCategory=person)(objectClass=user)(!cn=andy))" = All user objects but "andy".
"(sn=sm*)" = All objects with a surname that starts with "sm".
"(&(objectCategory=person)(objectClass=contact)(|(sn=Smith)(sn=Johnson)))" = All contacts with a surname equal to "Smith" or "Johnson".

<a href="http://msdn.microsoft.com/en-us/library/windows/desktop/aa746475(v=vs.85).aspx">Search Filter Syntax</a>


```powershell
strBase = "<LDAP://" & strDNSDomain & ">"
strFilter = "(&(objectCategory=user)(altSecurityIdentities=Kerberos*))"
strAttributes = "distinguishedName,member,userPrincipalName,altSecurityIdentities"
strQuery = strBase & ";" & strFilter & ";" & strAttributes & ";subtree"
```

This is where the script sets the properties and actually makes the connection.

```powershell
objCmd.CommandText = strQuery
objCmd.Properties("Page Size") = 100
objCmd.Properties("Timeout") = 30
objCmd.Properties("Cache Results") = False
Set objRs = objCmd.Execute
```

Now that we have made the connection we can loop through the recordset that is returned.

```powershell
Do Until objRs.EOF
strUPN = objRs.Fields("userPrincipalName").Value
arrKrb = objRs.Fields("altSecurityIdentities").value
If IsNull(arrKrb) Then
strKrb = ""
Else
For Each strAltID In arrKrb
strKrb = strAltID
Next
End if
WScript.echo  strDn & "	, " & strKrb
objRs.MoveNext
Loop
```

Notice the difference between how the two attributes are assigned to variables. The strUPN variable is simply set this way:

```powershell
strUPN = objRs.Fields("userPrincipalName").Value
```

With some attributes this method will fail with a â€œMismatch error. The reason for this is that the information is stored as a multi-value attribute. You'll see this with â€œdescription, â€œaltSecurityIdentities, and several others. In this case you have to assign it to an array and then parse the array with a â€œfor each loop.

```powershell
If IsNull(arrKrb) Then
strKrb = ""
Else
For Each strAltID In arrKrb
strKrb = strAltID
Next
End if
```

Once you've assigned the attributes to variables you must do something with them. Usually I will just echo the results.

```powershell
WScript.echo  strDn & "	, " & strKrb
```

If there is a lot of info to look at or I want to send the info to someone else I will pipe the output of the script to a text file or CSV.

```powershell
cscript enum_objects.vbs > objects.txt
```

Another option is to create the output file within the script. You just have to add a few lines of code at the top.

```powershell
set fso = CreateObject("Scripting.FileSystemObject")
set ts = fso.CreateTextFile("c:\scripts\users-.csv", true)
```

We're creating a CSV so we will want to add a header to the file.

```powershell
ts.writeline("UPN,Kerberos ID ")
```

Now we change the line with the â€œwscript.echo code to add a new line to the file that we created.

```powershell
ts.writeline( strDn & "," & strKrb)
```

Now all we have to do is close the recordset.

```powershell
objRs.Close
```
