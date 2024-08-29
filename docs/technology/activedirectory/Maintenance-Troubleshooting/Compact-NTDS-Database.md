# Compact NTDS Database

## Summary

Every 12 hours Active Directory performs garbage collections where it defragments whitespace within the database. This whitespace is optimized for performance but it is not returned to the file system. Body: **Garbage Collection** Increase the garbage collection logging level from 0 to 1 in order to determine how much whitespace exists in a database. This change in logging level will result in a Event ID 1646 being logged to the Directory Service log. The event will show how much total space is used by the database file and how much recoverable whitespace exists.

## Configure Garbage Collection Logging

View current setting:

```powershell
$Reg = "HKLM:SYSTEMCurrentControlSetServicesNTDSDiagnostics"
Get-ItemProperty -Path $Reg
```

Set logging level:

```powershell
$Reg = "HKLM:SYSTEMCurrentControlSetServicesNTDSDiagnostics"
Set-ItemProperty -Path $Reg -Name "6 Garbage Collection" -Type DWORD -Value 1
```

### Compact (Offline Defragmentation)

1. Prepare for Compacting: Create a folder named "compact" in D:NTDS.
2. Open an elevated PowerShell prompt Stop the AD DS Service by typing *"stop-service ntds -force"*
3. Begin Compacting: Enter the command *"ntdsutil"*
4. At the ntdsutil prompt, type *"activate instance ntds"* and press *"ENTER"*
5. Type *"files"* and press *"ENTER"*
6. To begin compacting the database type *compact to "d:NTDScompact*"
7. If compacting completed with errors perform an integrity check (See Perform Integrity Check bellow)
8. Finish Compacting: Rename *"D:NTDSndts.dit" "D:NTDSndts.dit.bk"* so that it isn't overwritten
9. Copy the compacted database file from *"D:NTDScompact"* to *"D:NTDS"* by typing *"copy D:NTDScompactndts.dit D:NTDSndts.dit"*
10. Delete all existing log files in *"L:Logs"* by typing *"del L:Logs*.logs"*
11. Perform Integrity Check: Enter the command *"ntdsutil"*
12. At the ntdsutil prompt, type *"activate instance ntds"* and press *"ENTER"*
13. Type *"files"* and press *"ENTER"*
14. To begin the integrity check, type *integrity*

### Database Integrity Check

1. If there are any errors from the integrity check, delete the compacted database file, *"D:NTDSntds.dit"*, and perform the copy again
2. Restart AD DS: Start the AD DS Service by typing *"start-service ntds"*)
3. If successful Event IDs 1000 and 1394 should appear in the "Directory Service" log
4. If Event IDs 1046 and 1168 appear in the "Directory Service" log check the database integrity again If the database integrity fails again:
    a.  Stop the AD DS service (*"stop-service ntds -force"*)
    b.  Delete the compacted database file (*"del D:NTDSntds.dit"*)
    c.  Rename the original database file (*"D:NTDSntds.dit.bk"* to *"D:NTDSntds.dit"*)
    d.  Compact the database
    e.  Rename the original database and copy the compacted database
    f.  Perform integrity check If the integrity check succeeds but errors persist when starting the AD DS service, perform a "semantic database analysis with fixup
