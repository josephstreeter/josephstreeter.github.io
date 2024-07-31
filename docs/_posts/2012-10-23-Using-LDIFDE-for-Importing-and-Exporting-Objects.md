---

title:  Using LDIFDE for Importing and Exporting Objects
date:   2012-10-23 00:00:00 -0500
categories: IT
---

Some useful information when creating Active Directory user objects.

***Creating User Objects with LDIFDE***

***From Microsoft Support: <a href="http://support.microsoft.com/kb/555636">*LDIFDE* - Export / Import data from Active Directory - *LDIFDE* ...</a>***



1. Command to export the user with a given name of SAM Account

ldifde -f exportuser.ldf -s computer_name -r (samaccountname=SAMLNAME)

2. Command to export Organizational Units:

Running this command exports all OUs except domain controllers into a file named ExportOU.ldf.
ldifde -f exportOu.ldf -s *Server1* -d "dc=Export,dc=com" -p subtree -r "(objectClass=organizationalUnit)" -l "cn,objectclass,ou"

3. Export the User Accounts from the Source Domain

ldifde -f Exportuser.ldf -s *Server1* -d "dc=Export,dc=com" -p subtree -r "(&amp;(objectCategory=person)(objectClass=User)(givenname=*))" -l "cn,givenName,objectclass,samAccountName"

Running this command exports all users in the Export domain into a file named Exportuser.ldf. If you do not have all the required attributes, the import operation does not work. The attributes objectclass and samAccountName are required, but more can be added as needed.

4. Command to Import users from a LDF file:

ldifde -i -f Exportuser.ldf -s *Server2*

5. Exporting User Account attributes except attributes those can€™t be imported: (Using €“o switch)

This is another example filter that will export all User Account data except for the attributes that cannot be imported:

ldifde -f Exportuser.ldf -s <Server1> -d "dc=Export,dc=com" -p subtree -r "(&amp;(objectCategory=person)(objectClass=User)(givenname=*))" -o "badPasswordTime,badPwdCount,lastLogoff,lastLogon,logonCount, memberOf,objectGUID,objectSid,primaryGroupID,pwdLastSet,sAMAccountType"

Another Example: To export for any given SamAccountName:

ldifde -f Exportuser.ldf -s <Server1> -d "dc=Export,dc=com" -p subtree -r "(&amp;(objectCategory=person)(objectClass=User)(givenname=*))" -o "badPasswordTime,badPwdCount,lastLogoff,lastLogon,logonCount, memberOf,objectGUID,objectSid,primaryGroupID,pwdLastSet,sAMAccountType"

From TechNet: <a href="http://support.microsoft.com/kb/263991">How to *set* a user's *password* with *Ldifde*</a>

The password attribute used by Active Directory is "unicodePwd." This attribute can be written under restricted conditions, but cannot be read. This attribute can only be modified, not added on object creation or read by a search. To modify this attribute, the client must have a 128-bit Secure Sockets Layer (SSL) connection to the server.

Note When you use a base-64 encoder, you must make sure that it supports Unicode, or you will create an incorrect password.

The following sample Ldif file (chPwd.ldif) changes a password to newPassword:
```powershell
dn: CN=TestUser,DC=testdomain,DC=com
changetype: modify
replace: unicodePwd
unicodePwd::IgBuAGUAdwBQAGEAcwBzAHcAbwByAGQAIgA=
-
```
To import the chPwd.ldif file, use the following command:
If the password does not fulfill the criteria of the enforced Password Policies, then it will throw an error:



