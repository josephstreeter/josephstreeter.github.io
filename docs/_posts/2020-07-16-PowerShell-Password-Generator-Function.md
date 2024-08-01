---

title:  PowerShell Password Generator Function
date:   2020-07-16 00:00:00 -0500
categories: IT
---

Doesn't really need an explanation. Returns a PSCustomObject with the clear-text and secure string.   

```powershell
Function Generate-Password() 
{
     param($LowerCase,$UpperCase,$Numbers,$SpecialChar)
     $pw = [char[]]'abcdefghiklmnoprstuvwxyz' | Get-Random -Count $LowerCase
     $pw += [char[]]'ABCDEFGHKLMNOPRSTUVWXYZ' | Get-Random -Count $UpperCase
     $pw += [char[]]'1234567890' | Get-Random -Count $Numbers
     $pw += [char[]]'!$?_-' | Get-Random -Count $SpecialChar
     $pw=($pw | Get-Random -Count $pw.length) -join ""
     $SecString=ConvertTo-SecureString -String $pw -AsPlainText -Force
     $results = [PSCustomObject] @{Password=$pw;SecureString=$SecString}
     return $Results 
}

Generate-Password -LowerCase 15 -UpperCase 15 -Numbers 14 -SpecialChar 14  
Password                                                      SecureString 
--------                                                      ------------ 
9ixLlfXw6S_-?Po!KpHGyU3ZE5gBs7Avk8uFW1Me0$42d                 System.Security.SecureString 
```
