---
title: "Remove Account Expiration"
description: "$expired=Search-ADAccount -AccountExpired -UsersOnly -ResultPageSize 2000 -resultSetSize $null | ? {$_.DistinguishedName -like '*student*'}</p>"
tags: ["directoryservices", "activedirectory", "operations"]
category: "services"
last_updated: "2026-01-13"
---

# Remove Account Expiration

```powershell
$expired=Search-ADAccount -AccountExpired -UsersOnly -ResultPageSize 2000 -resultSetSize $null | ? {$_.DistinguishedName -like "*student*"}</p>
$expired | % {Clear-ADAccountExpiration -Identity $_.distinguishedname}
```
