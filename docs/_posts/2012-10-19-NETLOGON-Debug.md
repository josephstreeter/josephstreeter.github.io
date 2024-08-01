---
title:  NETLOGON Debug
date:   2012-10-19 00:00:00 -0500
categories: IT
---

In order to turn on debugging to troubleshoot authentication run this command:

```cmd
nltest /dbflag:2080FFFF
```

The Net Logon events can be viewed in %windir%\debug\netlogon.log

<a href="http://thebackroomtech.com/2007/09/19/howto-enable-windows-debug-logging-to-solve-authentication-problems/">Howto: Enable Windows Debug Logging to Solve Authentication Problems - thebackroomtech</a>

<a href="http://blogs.technet.com/b/askpfeplat/archive/2011/12/26/in-search-of-roaming-active-directory-clients-how-to-scriptomatically-identify-missing-active-directory-subnet-definitions.aspx">In Search Ofâ€¦. Roaming Active Directory Clients. (How to scriptomatically identify missing Active Directory Subnet Definitions) - Sign In   Ask Premier Field Engineering (PFE) Platforms Blog</a>
