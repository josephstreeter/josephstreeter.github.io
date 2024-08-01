---
title:  Regular Active Directory Tasks
date:   2012-10-19 00:00:00 -0500
categories: IT
---

There are great benefits to closely monitoring your Active Directory domain controllers. Here are some lists of daily, weekly, and monthly tasks.

Microsoft TechNet:
- <a href="http://technet.microsoft.com/en-us/library/bb727046.aspx">Monitoring Active Directory</a>

Scribd:
- <a href="http://www.scribd.com/doc/4623275/System-Administrator-Checklist">System Administrator Checklist</a>
- <a href="http://www.scribd.com/doc/54687404/Complete-System-Administrator-Checklist">Complete System Administrator Checklist</a>

Network Steve Forum:
- <a href="http://www.networksteve.com/forum/topic.php/Active_Directory_Daily_Check_list/?TopicId=19558&Posts=6">Active Directory Daily Check list</a>

Looking at the suggestion in the Network Steve post one suggestion is using several CLI tools to create a report.

```powershell
dcdiag /v /c /d /e /s:dcname >c:\dcdiag.txt
netdiag /v >c:\netdiag.txt
repadmin /showrepl * /verbose /all /intersite >c:\repl.tx
dnslint /ad /s "DCipaddress"
Download DNSLINT: http://support.microsoft.com/kb/321045
```

Expect to see some errors using DCDIAG in certain situations:
<a href="http://support.microsoft.com/kb/2512643">DCDIAG.EXE /E or /A or /C expected errors (MS Support)</a>

<a href="http://blogs.technet.com/b/askds/archive/2011/03/22/what-does-dcdiag-actually-do.aspx">What does DCDIAG actuallyâ€¦ do? (Ask the AD Guys Blog)</a>

You will notice that REPLMON is no longer available in Windows Server 2008 R2.

blog.powershell.no:
- <a href="http://blogs.technet.com/b/askds/archive/2009/07/01/getting-over-replmon.aspx">Replmon.exe not included in Windows Server 2008/2008 R2</a>

Ask the Directory Services Team Blog:
- <a href="http://blogs.technet.com/b/askds/archive/2009/07/01/getting-over-replmon.aspx">Getting Over Replmon</a>

NETDIAG is also no longer supported, but DCDIAG should give you all the information and ability that you need.
