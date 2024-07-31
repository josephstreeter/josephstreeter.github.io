---

title:  Network Location Awareness Issues with WS 2008 R2 Domain Controllers
date:   2015-01-09 00:00:00 -0500
categories: IT
---






There is a known issue with Windows Server 2008 R2 that causes the Network Location Awareness (NLA) service to incorrectly identify the network that it is connected to. By failing to correctly identify the network the public local firewall profile is applied to the NIC and causes connectivity issues.

There are several workarounds for this issue; a hotfix from Microsoft and several registry changes. From reading posts on the Internet it appears that the hotfix doesn't always work and the registry changes are intended as an emergency fix.

This script is meant to run at startup to check the network profile that is applied. If it doesn't detect that it is using the domain profile it will disable and then enable the NIC. This should allow the appropriate profile to be applied.

Additionally, the script will write an event to the event log if changing the profile is required. In doing so it will register a new source with the System log named "NLA-Change."
```powershell$CurrentProfile = netsh advfirewall Monitor show currentprofile

if (-not ($CurrentProfile | Select-String $(Get-WmiObject -Class Win32_ComputerSystem).domain)) {
$NIC = Get-WmiObject -Class win32_networkadapter -ComputerName -filter "AdapterType = 'Ethernet 802.3'"
$NIC.disable()
$NIC.enable()

$path = "HKLM:\System\CurrentControlSet\services\eventlog\System"
If (-not ($(gci $path -Name) -contains "NLA-Change")) {Try {New-EventLog -LogName "System" -Source "NLA-Change"} Catch {Break}}

Try {Write-EventLog -LogName "System" -Source "NLA-Change" -EventId "1234" -EntryType "Warning" -Message "NLA Location was updated"} Catch {Break}
}
```


