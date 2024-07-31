---

title:  Runaway Process Taking All of Your CPU? Kill It! Kill It Now!
date:   2012-10-18 00:00:00 -0500
categories: IT
---






Here is a PowerShell script that will find the process using the most CPU and then kills that process.

```powershell
$strProc = gps | sort cpu -desc | select -first 1
$strProc.kill()
```

Schedule it to run every once in a while and let it go. I think I would like to narrow the list if processes that it could shut off though.


