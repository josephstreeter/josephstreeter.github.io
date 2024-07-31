---

title:  WSUS Uninstall Troubles
date:   2012-10-18 00:00:00 -0500
categories: IT
---






Recently I could not get Microsoft WSUS 3.0 to uninstall. The fix appears to be:

"[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Update Services\Server\Setup], change the value for "wYukonInstalled" from 1 to 0"

Ran the uninstall again and everything seems to have worked fine. Now I just hope that it reinstalls ok.

Too Easy


