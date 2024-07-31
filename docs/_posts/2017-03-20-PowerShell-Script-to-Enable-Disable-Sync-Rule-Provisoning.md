---

title:  PowerShell Script to Enable/Disable Sync Rule Provisoning
date:   2017-03-20 00:00:00 -0500
categories: IT
---






I had a need to run synchronization without having provisioning on periodically and accomplishing it as a manual process wasn't going to work. I found a script script online that looked like it might be useful.
(https://social.technet.microsoft.com/Forums/en-US/8d9ae376-8d90-4b6e-8111-5ce9fa18e34e/using-powershell-to-enable-provisioning?forum=ilm2)

I simplified it and made it a function to add to our scheduled run profile script.

```powershell
function Set-SRProvisoning()
{
    Param
    (
    [Parameter(Mandatory=$false,Position=0)]$Server="localhost",
    [Parameter(Mandatory=$true,Position=1)]$Enable
    )

    Set-Variable -name URI -value "http://$($Server):5725/resourcemanagementservice' " -option constant

    if(@(get-pssnapin | where-object {$_.Name -eq "FIMAutomation"} ).count -eq 0) {add-pssnapin FIMAutomation}
    clear-host

    switch ($Enable)
    {
        $True {$ProvisioningStatus = "sync-rule"}
        $False {$ProvisioningStatus = "none"}
        Default {Write "Bad option"}
    }

    $exportObject = export-fimconfig -uri $URI `
        -onlyBaseResources `
        -customconfig ("/mv-data") `
        -ErrorVariable Err `
        -ErrorAction SilentlyContinue

    $provisioningState = ($exportObject.ResourceManagementObject.ResourceManagementAttributes | `
        Where-Object {$_.AttributeName -eq "SyncConfig-provisioning-type"}).Value

    $importChange = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
    $importChange.Operation = 1
    $importChange.AttributeName = "SyncConfig-provisioning-type"
    $importChange.AttributeValue = $ProvisioningStatus
    $importChange.FullyResolved = 1
    $importChange.Locale = "Invariant"

    $importObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
    $importObject.ObjectType = $exportObject.ResourceManagementObject.ObjectType
    $importObject.TargetObjectIdentifier = $exportObject.ResourceManagementObject.ObjectIdentifier
    $importObject.SourceObjectIdentifier = $exportObject.ResourceManagementObject.ObjectIdentifier
    $importObject.State = 1
    $importObject.Changes = (,$importChange)

    $importObject | Import-FIMConfig -uri $URI -ErrorVariable Err -ErrorAction SilentlyContinue

    switch ($Enable)
    {
        $True {write-host "`nProvisioning enabled successfully`n"}
        $False {write-host "`nProvisioning disabled successfully`n"}
    }
}
```