# Remove Account Expiration

```powershell
$expired=Search-ADAccount -AccountExpired -UsersOnly -ResultPageSize 2000 -resultSetSize $null | ? {$_.DistinguishedName -like "*student*"}</p>
$expired | % {Clear-ADAccountExpiration -Identity $_.distinguishedname}
```
