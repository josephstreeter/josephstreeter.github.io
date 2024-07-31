---

title:  Export Active Directory Objects for Use in a Lab
date:   2012-10-19 00:00:00 -0500
categories: IT
---






Want to create a development environment with all the same objects as your production environment? You can use LDIFDE or CSVDE to do it.

Export Users from Production:
```powershell
ldifde -f Exportuser.ldf -s Server1 -d "ou=users,dc=Export,dc=com" -p subtree -r "(&(objectCategory=person)(objectClass=User)(givenname=*))" -l "cn,givenName,objectclass,samAccountName"
```

-f Exportuser.ldf = Export to this file
-s Server1 = Remote server (not needed if run locally)
-d "ou=users,dc=Export,dc=com" = LDAP Base DN to begin the export
-r "(&(objectCategory=person)(objectClass=User)(givenname=*))" = Filter for the type of objects
-l "cn,givenName,objectclass,samAccountName" = Attributes to collect

You will have to do a find/replace within the exported file to adjust for a different domain name if it is different from the Production.

Import Users into Development:
```powershell
ldifde -i -f Exportuser.ldf -s Server2
```

The "-f" and "-s" switches are the same as the export. The addition of "-i" tells LDIFDE to import.

CSVDE works much the same as LDIFDE

CSVDE:
```powershell
csvde -d "ou=orgUsers,DC=name,DC=com" -f c:\ouput.csv -l "cn,objectclass,ou"

csvde -i -f c:\output.csv
```

LDIFDE:
```powershell
ldifde -d "ou=orgUsers,DC=name,DC=com" -f c:\ouput.ldif -l "cn,objectclass,ou"

ldifde -i -f c:\output.ldif
```


