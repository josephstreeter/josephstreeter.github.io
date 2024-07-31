---

title:  Search for Bad MIM Portal Records with PowerShell
date:   2019-11-21 00:00:00 -0500
categories: IT
---

I needed a script to find all of the MIM Portal records that did not have a Display Name or a Domain populated. This is usually an indication of an ID having multiple records in the Metaverse. This way I can target the MV objects to disconnect all of the MAs so that the deletion rule deletes the MV object.

This requires the Lithnet RMA module and must be run with an account that has Portal access. Oh, and don't forget to NOT delete the built-in Synchronization account....

```powershell
import-module lithnetrma

$query1=New-XPathQuery -AttributeName "DisplayName" -Operator IsNotPresent
$query2=New-XPathQuery -AttributeName "Domain" -Operator IsNotPresent
$queryGroup1=New-XPathQueryGroup -Operator Or -Queries @($query1, $query2)

$query3=New-XPathQuery -AttributeName "DisplayName" -Operator Equals -Value "Built-in Synchronization Account" -Negate
$queryGroup2=New-XPathQueryGroup -Operator and -Queries @($queryGroup1, $query3)

$expression=New-XPathExpression -ObjectType "Person" -QueryObject $queryGroup2

$Users=Search-Resources $expression -AttributesToGet @("AccountName","Domain","DisplayName","ObjectID")
$users 
    | select accountname, domain, displayname, ObjectID 
    | sort displayname 
    | convertto-csv 
    | Out-File .\Desktop\portalusers.txt

foreach ($user in $users)
{
    $user.ObjectID
    Remove-Resource $user.ObjectID
}
```
