# Active Directory

## Table of Contents

- [Remove ACE for a Security Principal from an Object's ACL](#remove-ace-for-a-security-principal-from-an-objects-acl)

## Remove ACE for a Security Principal from an Object's ACL

```powershell
function Remove-ADObjectACE()
{
    [CmdletBinding()]
    Param
    (
        $ADObject,
        $SecPrincipal
    )

    Write-Output ("Removing {0} from {1}" -f $SecPrincipal, $ADObject.name)
    Try
    {
        $Acl=(get-acl -path $ADObject.distinguishedname)
        $Ace = $Acl.access | ?{ $_.IsInherited -eq $false -and $_.IdentityReference -eq $SecPrincipal }
        if ($Ace)
        {
            $Acl.RemoveAccessRule($ace)
            Set-Acl -Path $ADObject.DistinguishedName -AclObject $Acl -ErrorAction Stop
            Return
        }
        else
        {
            Write-Output ("No ACL to remove from {0}" -f $ADObject.name)
        }
    }
    catch
    {
        Write-Error $_.exception.message
    }
}


$SecPrincipal = "AD\Domain Admins"
$ADObjects = Get-ADGroup -Filter * -SearchBase "OU=groups,OU=managed,DC=ad,DC=domain,DC=com"

foreach ($ADObject in $ADObjects)
{
    Remove-ADObjectACE -ADObject $ADObject -SecPrincipal $SecPrincipal -ErrorAction Stop
}
```

[Top](#table-of-contents)
