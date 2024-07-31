---
title:  Disable SSLv2 on Windows Server 2008 Domain Controllers
date:   2013-08-13 00:00:00 -0500
categories: IT
---

Using LDAP over SSL is a good step towards security. Improve security just a little bit more by disabling SSLv2 and forcing your clients to use SSLv3

On each of your domain controllers create the following registry key:

```powershell
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0]
```

Then create the following DWORD

```powershell
DWORD = "Enabled"
Value = 00000000
```

Finally, reboot the domain controller

To make this even easier you can deploy this registry key though a Group Policy Object linked to the Domain Controllers OU.

More information from Microsoft:

<a href="http://support.microsoft.com/default.aspx?scid=kb;EN-US;245030" target="_blank">How to Restrict the Use of Certain Cryptographic Algorithms and Protocols in Schannel.dll</a>
