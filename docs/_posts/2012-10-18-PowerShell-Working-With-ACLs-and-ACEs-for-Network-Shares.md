---

title:  PowerShell Working With ACLs and ACEs for Network Shares
date:   2012-10-18 00:00:00 -0500
categories: IT
---






Need to do some scripting to make some reports on ACLs on network shares. Should be an interesting project.

Since I've been job hunting, everyone seems to want someone that knows PowerShell. So, I have decided that I should attempt this endevor in PowerShell as a learning experience for myself. I've used it in automating Exchange 2007 tasks to make up for the rather thin GUI, but otherwise I've stuck to VBScript because it's what I know.

<a href="http://www.computerperformance.co.uk/powershell/powershell_share.htm">PowerShell Share Set-Acl</a>

<a href="http://www.computerperformance.co.uk/powershell/powershell_wmi_shares.htm">Scripting File Shares with PowerShell</a>

Below is what I've come up with to start with. It enumerates all of the computer objects in the Directory and then enumerates all of the shares on each box. It then runs Get-Acl against each share.

```
$ErrorView = "CategoryView"

$objName = "<b>partial name to query here</b>"
$searcher = new-object DirectoryServices.DirectorySearcher([ADSI]"")
$searcher.filter = "(&(objectClass=user)(objectCategory=computer)(cn= $objName*))"
$objAd = $searcher.findall()

foreach ($objComp in $objAd)
{
    $strServer = $objComp.properties.cn
    $shares = Get-WmiObject -class Win32_Share -computerName $strServer | where {$_.type -match "0"}

    foreach ($strInfo in $arrShares)
    {
        $strSharename = $strInfo.name
        Get-Acl \\$strServer\$sharename | format-list
    }
}
```



