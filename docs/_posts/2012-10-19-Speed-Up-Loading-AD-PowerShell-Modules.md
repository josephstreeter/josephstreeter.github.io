---
title:  Speed Up Loading AD PowerShell Modules
date:   2012-10-19 00:00:00 -0500
categories: IT
---

Here is the short version of the story. When you import the Active Directory PowerShell Modules (Import-module ActiveDirectory) it takes some time to load.

To speed things up run this command first:

<b>$Env:ADPS_LoadDefaultDrive = 0</b>

If you want to know more about it you can read the Blog post below.

<a href="http://blogs.msdn.com/b/adpowershell/archive/2010/04/12/disable-loading-the-default-drive-ad-during-import-module.aspx">Active Directory Powershell Blog - Disable loading the default drive 'AD:' during import-module</a>
