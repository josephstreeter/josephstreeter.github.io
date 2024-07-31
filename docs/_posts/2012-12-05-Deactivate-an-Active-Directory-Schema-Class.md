---

title:  Deactivate an Active Directory Schema Class
date:   2012-12-05 00:00:00 -0500
categories: IT
---






Perhaps you created a custom schema class and made a mistake. You're stuck, right? Not so fast!

Create an LDIF file like the one below. Make sure to replace the schema class name.



dn: CN=badClass,CN=Schema,CN=Configuration,DC=X
changetype: modify
replace: isDefunct
isDefunct: TRUE
-

dn: CN=badClass,CN=Schema,CN=Configuration,DC=X
changetype: modrdn
newrdn: cn=badClassOld
deleteoldrdn: 1

dn:
changetype: modify
add: schemaUpdateNow
schemaUpdateNow: 1
-

Then- run the following command. Remember to use an account that has Schema Admin rights and run the command on the DC with the Schema Master role.
```powershellldifde /i /f class.ldf /c "DC=X" "dc=domain,dc=com"```
Now, go ahead and create the class the correct way.


