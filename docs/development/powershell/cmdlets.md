# Cmdlets

This document will cover some common and a few not-so-common cmdlets.

## ForEach-Object

```powershell
foreach ($Result in $Results)
{
    $Result.properties.Item("ExtensionAttribute2")
}
```

```powershell
$Results | ForEach-Object -Begin {Write-Output "Begining"} -Process {$_.properties.Item("ExtensionAttribute2")} -End {"Finished"}
```

## Get-Date

```powershell
$Date = (get-date).adddays(-90).ToFileTimeUtc()
```
