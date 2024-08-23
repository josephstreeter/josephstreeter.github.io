---

title:  FIM/MIM MA Pending Export Report
date:   2016-08-02 00:00:00 -0500
categories: IT
---

This will show what export operations are pending on all of your management agents. It was adapted from a script I found in the FIM Script Box that would show the pending exports for a single MA. Instead, this script queries the Sync Service for all of the management agents and displays the pending exports for all of them.

```powershell
$MAs = $(Get-WmiObject -class "MIIS_ManagementAgent" -namespace "root\MicrosoftIdentityIntegrationServer"` -computername "." ).name
$Rpt=@()

foreach ($MA in $MAs)
{
    $MA = @(get-wmiobject `
        -class "MIIS_ManagementAgent"   
        -namespace "root\MicrosoftIdentityIntegrationServer" `
        -computername "." -filter "Name='$ma'")
    
    if($MA.count -eq 0) {throw "MA not found"}

    $Rpt+=New-Object PSObject -Property @{
        "Name"=$($MA.name)
        "Update"=$($MA[0].NumExportUpdate().ReturnValue)
        "Add"=$($MA[0].NumExportAdd().ReturnValue)
        "Delete"=$($MA[0].NumExportDelete().ReturnValue)
    }
}

$Rpt | Sort name | ft Name,Add,Update,Delete -AutoSize
```
