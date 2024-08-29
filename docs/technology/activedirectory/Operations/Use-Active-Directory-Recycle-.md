# Use Active Directory Recycle Bin

Windows Server 2008 R2 Active Directory includes a feature called the Active Directory Recycle Bin that will allow administrators to restore deleted objects without having to perform an administrative restore. Campus Active Directory has the AD Recycle Bin enabled.

The example PowerShell commands bellow can be used to list and restore deleted objects.

List Deleted Objects

```powershell
Get-ADObject -f {isdeleted -eq $true } -includeDeletedObjects -pr * | ft Name,lastknownParent,objectClass
```

Restore a single deleted object

```powershell
Get-ADObject -f {(isdeleted -eq $true) -and (name -eq <name>)} | Restore-ADObject -identity
```

Restore multiple deleted objects (objects that have a name that ends with "smith"):

```powershell
Get-ADObject -f {(isdeleted -eq $true) -and (name -match "*smith")} -includeDeletedObjects -pr* | restore-adobject
```

## Technical Details

The amount of time that an object can be recovered is controlled by the Deleted Object Lifetime (DOL). By default the DOL is 180 days.

When an object is deleted it is moved to the Deleted Objects container (cn=deleted objects,dc=ad,dc=wisc,dc=edu) and its "isDeleted" attribute is set to "True." At this point the object is considered "logically" deleted and can be recovered by an administrator until the DOL has been exceeded.

Once the DOL has been exceeded the object's "isRecycled" attribute is set to "True." The object is now tombstoned and exists only to inform other domain controllers that the object has been deleted. The object can no longer be restored from the Recycle Bin. Once the Tombstone Lifetime (TSL), 180 days, has been exceeded the object is deleted from the directory by the "Garbage Collection" process.

## Common Errors

- **Error** - The operation could not be performed because the object's parent is either uninstantiated or deleted
- **Cause** - The deleted object's parent, usually an Organizational Unit, has been deleted and must be restored first.

- **Error** - An attempt was made to add an object to the directory with a name that is already in use
- **Cause** - An object exists that has the same distinguishedName as the deleted object. It's possible that the deleted object was recreated before the restoration.

## References

- [Get-ADObject (TechNet)](http://technet.microsoft.com/en-us/library/ee617198.aspx)
- [Restore-ADObject (TechNet)](http://technet.microsoft.com/en-us/library/ee617262.aspx)
