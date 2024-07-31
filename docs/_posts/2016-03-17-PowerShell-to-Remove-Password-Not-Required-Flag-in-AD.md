---

title:  PowerShell to Remove Password Not Required Flag in AD
date:   2016-03-17 00:00:00 -0500
categories: IT
---






We had a couple thousand users in our test AD that had the Password Not Required flag set without a password. This was causing an error when Microsoft Identity Management tried to set the password for these user objects.
We used the following script to remove the flag and set a password.
```powershell
$Users = Get-ADUser -searchscope subtree -ldapfilter "(&(objectCategory=User)(userAccountControl:1.2.840.113556.1.4.803:=32))"
$newPassword = (Read-Host -Prompt "Provide New Password" -AsSecureString)

foreach ($user in $Users)
{
Set-ADAccountPassword -Identity $User.samaccountname -NewPassword $newPassword -Reset
Set-ADAccountControl $User.samaccountname -PasswordNotRequired $false
}
```


