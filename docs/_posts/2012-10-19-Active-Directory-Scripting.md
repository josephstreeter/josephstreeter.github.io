---
title:  Active Directory Scripting
date:   2012-10-19 00:00:00 -0500
categories: IT
---

## vADSI scripting information

- <a href="http://www.rlmueller.net">Hilltop Lab</a>
- <a href="http://www.powershellpro.com/powershell-tutorial-introduction/powershell-tutorial-active-directory/">PowerShell Pro! - Part 1: Active Directory Management</a>
- <a href="http://www.activxperts.com/activmonitor/windowsmanagement/adminscripts/usersgroups/users/">ActiveXperts - Scripts - Users and Groups</a>
- <a href="http://www.activxperts.com/activmonitor/windowsmanagement/adminscripts/usersgroups/users/">Computer Performance
- LDAP Properties for CSVDE and VBScript</a>

### Connect to RootDSE

```powershell
Set objRootDSE = GetObject("LDAP://RootDSE")
strDNSDomain = objRootDSE.Get("defaultNamingContext")

# Use ADO to search Active Directory.
Set objCmd = CreateObject("ADODB.Command")
Set objConn = CreateObject("ADODB.Connection")
objConn.Provider = "ADsDSOObject"
objConn.Open "Active Directory Provider"
objCmd.ActiveConnection = objConn

# Search entire domain.
strBase = "<LDAP://" & strDNSDomain & ">"

# Filter on group objects.
strFilter = "(objectCategory=group)"

# Comma delimited list of attribute values to retrieve.
# The member attribute of group objects is a multi-valued attribute.
strAttributes = "distinguishedName,member"

# Construct the ADO query, using LDAP syntax.
strQuery = strBase & ";" & strFilter & ";" & strAttributes & ";subtree"

# Run the query.
objCmd.CommandText = strQuery
objCmd.Properties("Page Size") = 100
objCmd.Properties("Timeout") = 30
objCmd.Properties("Cache Results") = False
Set objRs = objCmd.Execute

# Enumerate the recordset Do Until objRs.EOF
strDN = objRs.Fields("distinguishedName").Value
objRs.MoveNext
Loop
objRs.Close
```
