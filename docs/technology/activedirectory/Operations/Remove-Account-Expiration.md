# Remove Account Expiration

Created: 2023-09-11 10:05:37 -0500

Modified: 2023-09-11 10:06:35 -0500

---

<table>
<colgroup>
<col style="width: 6%" />
<col style="width: 93%" />
</colgroup>
<thead>
<tr>
<th><p>1</p>
<p>2</p></th>
<th><p>$expired=Search-ADAccount -AccountExpired -UsersOnly -ResultPageSize 2000 -resultSetSize $null | ? {$_.DistinguishedName -like "*student*"}</p>
<p>$expired | % {Clear-ADAccountExpiration -Identity $_.distinguishedname}</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>
