---
title:  Remove Those Annoying Action Panes in All MMCs
date:   2012-10-19 00:00:00 -0500
categories: IT
---

If you find yourself removing the checkbox for the action pane to recover the wasted space in your snapins this powershell script is for you.

```powershell
$snapins = Get-ChildItem HKLM:\SOFTWARE\Microsoft\MMC\SnapIns
foreach ($snap in $snapins)
{
$snapname=($snap.name.split("\"))[($snap.name.split("\").count-1)]
New-ItemProperty HKLM:\SOFTWARE\Microsoft\MMC\SnapIns\$snapname SuppressActionsPane -value 1 -propertyType dword
}
```
