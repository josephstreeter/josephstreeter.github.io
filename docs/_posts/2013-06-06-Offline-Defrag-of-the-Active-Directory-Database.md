---
title:  Offline Defrag of the Active Directory Database
date:   2013-06-06 00:00:00 -0500
categories: IT
---

In small instances of Active Directory the regular online defrag that runs every 12 hours is likely enough. Many administrators can get away with installing one or more Domain Controllers and never really touching them again, except for patching.

For larger organizations that might have large numbers of people who come and go the occasional offline defrag may be required. In order to do this you will have to take each Domain Controller offline while you perform the defrag, either by booting into DSRM mode (Server 2003 and earlier) or stopping the AD DS service (Server 2008 and later).

How can I tell how much whitespace the database has? You can turn on Garbage Collection logging and you will see the amount of whitespace in your database every 12 hours in Event ID 1646. To turn on Garbage Collection logging set the Garbage Collection entry in "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" to "1."

The event id 1646 "Free hard disk space (megabytes)" will tell you how much space within the database is whitespace. The entry will look similar to this:

```text
Event ID:- -  1646
Event Type: Information
Event Message:
Internal event: The Active Directory Domain Services database has the following amount of free hard disk space remaining.
Free hard disk space (megabytes):
393
Total allocated hard disk space (megabytes):
5182
```

In the following example we will perform an offline defrag on a Domain Controller that has the database stored on the D: drive (D:\NTDS\ntds.dit) and the logs on the L: drive (L:\Logs). The configuration of other Domain Controllers may vary.

1. Create a temporary directory for the storage of the compacted database. For example, D:\NTDS-Backup. Make sure that the drive you are using for the copy of the database will have enough space for the operation.

2. Open a command prompt and enter the NTDSUtil command followed by these commands:
```powershellfiles
info
compact D:\NTDS-Backup```
When the operation finishes you should see the following text:
```powershell
If compaction was successful, you need to:
copy "D:\NTDS-Backup\ntds.dit"
"D:\NTDS\ntds.dit"
and delete the old log files:
del L:\Logs*.log```
3. Save a copy of the ntds.dit file if possible so that it can be reused in the event that the compacted database has been corrupted.

4. In order to complete the offline defrag you must copy the compacted ntds.dit in D:\NTDS-Backup to D:\NTDS, overwriting the existing ntds.dit file, and then delete the log files located in L:\Logs. The only files that will remain are the edb.chk, temp.edb and ntds.dit.

5. Perform a file integrity check on the new ntds.dit file using the NTDSUtil command.
```powershellntdsutil
files
integrity```
6. Finally, restart the Domain Controller or start the AD DS service.

***References:***

- <a title="TechNet - Change the garbage collection logging level to 1" href="http://technet.microsoft.com/en-us/library/cc787136(WS.10).aspx" target="_blank">TechNet - Change the garbage collection logging level to 1</a>



