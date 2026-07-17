---
title:  Disable SSLv2 on Windows Server 2008 Domain Controllers
date:   2013-08-13 00:00:00 -0500
categories: IT
---

> **⚠️ Historical post — do not follow as written.** This 2013 article predates the POODLE attack (2014) and targets Windows Server 2008 (end-of-life). **SSLv3 is now insecure and must also be disabled**, along with TLS 1.0 and TLS 1.1. Configure clients and servers for **TLS 1.2 (minimum) and TLS 1.3**. See the current guidance in [SSL vs TLS](../security/certificates/sslvstls.md) and [Certificate Management](../security/certificates/index.md).

Using LDAP over SSL is a good step towards security. The original advice below disabled SSLv2 and fell back to SSLv3 — that is no longer safe. Disable **SSLv2, SSLv3, TLS 1.0, and TLS 1.1**, and require **TLS 1.2 or higher** on all domain controllers.

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
