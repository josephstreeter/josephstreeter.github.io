---

title:  Create ACL Report for Your Home Directories
date:   2012-10-19 00:00:00 -0500
categories: IT
---






Not sure if the ACLs on your home directories are set up correctly? If you're not they're likely not.

I wrote this little PowerShell script to create a report from the home directories on all of our file servers.
<hr>
```
$strFileServers = @("Server-01", "Server-02", "Server-03", "Server-05", "Server-07", "Server-08", "Server-09", "Server-12", "Server-17", "Server-18", "Server-19")

foreach ($strServer in $strFileServers)
{
    $arrHome = Get-ChildItem \\$strServer\home
    foreach ($strUser in $arrHome) 
    {
        Get-Acl \\$strServer\home\$strUser | format-list
    }
}
```
<hr>


