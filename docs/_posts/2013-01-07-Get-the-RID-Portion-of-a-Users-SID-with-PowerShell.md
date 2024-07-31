---
title:  Get the RID Portion of a Users SID with PowerShell
date:   2013-01-07 00:00:00 -0500
categories: IT
---

Since we're looking at putting UID/GID information into Active Directory we've been looking at what number to us so that we don't conflict with numbers already in use. The idea was floated on a mailing list that you could use the RID portion of a user's SID. That just might work if we append that number to the end of some arbitrary number that will make it long enough to put it in the range we're thinking about.

This should get the RID

```powershell
Get-ADUser -f * | % {$_.sid.tostring().split(“-“)[7]}
```
In order to make it a larger number you can prepend a number to it like "1024." That should keep it from overlapping any UID/GID in use on the local box.

```powershell
Get-ADUser -f * | % {$_.sid.tostring().split(“-“)[7]}
```

To make them all line up I will have to find a way to pad the RID with a number of zeros so that all of the UID/GIDs are the same length.

More to come....
