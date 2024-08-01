---
title:  Identify Active Directory Schema Number
date:   2012-10-19 00:00:00 -0500
categories: IT
---

How to find it:

**The repadmin tool:**

```cmd
repadmin /showattr * "cn=schema,cn=configuration,dc=Domain,dc=Com" /atts:objectVersion
```

**The following registry key:**

```text
HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters\<Schema Version #>
```

**dsquery:**

```cmd
dsquery * CN=Schema,CN=Configuration,DC=Domain,DC=Com -Scope Base -attr objectVersion
```

Windows 2000 RTM (Schema version 13)
Windows Server 2003 RTM (Schema version 30)
Windows Server 2003 R2 (Schema version 31)
Windows Server 2008 (Schema version 44)
Windows Server 2008 R2 (Schema version 47)

<a href="http://support.microsoft.com/kb/556086">How to Find the Current Schema Version - TechNet</a>
