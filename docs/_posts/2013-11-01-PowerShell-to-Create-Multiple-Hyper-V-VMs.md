---
title:  PowerShell to Create Multiple Hyper-V VMs
date:   2013-11-01 00:00:00 -0500
categories: IT
---

I've created the exact same lab a dozen times with the same three Linux hosts. It's time to automate the process with a script. The scripts assume that the virtual switches are already created, although their creation or a check to verify their existence could easily be added.

The first host, RT-ISP-01, is a router that has one interface on the connected to the "External" switch for access to the Internet and an interface on the "Network A" and "Network B" private switches. The other two hosts, SVR-A-01 and SVR-B-01, are attached to the "Network A" and "Network B" respectively.

Each host gets 512MB of RAM and a single 40GB hard drive.

The initial setup of these Linux hosts require that legacy interfaces are used at first. The script removes the default interface and adds the appropriate legacy interfaces.

Each host has its DVD drive configured to contain the Linux install ISO so that it is ready to go when the host is started.

```powershell
$VMNames = @("SRV-A-01", "SRV-B-02", "RT-ISP-01")
$VHDSize = 40GB
$VMMemory = 512MB
$VMIso = "C:\Scripts\ISO\CentOS-6.4-x86_64-minimal.iso"

foreach ($VMName in $VMNames) {
New-VM `
-Name $VMName `
-MemoryStartupBytes $VMMemory `
-ComputerName $(gwmi win32_computersystem).name `http://www.joseph-streeter.com/wp-admin/index.php
-Path "C:\Users\Public\Documents\Hyper-V" `
-NewVHDPath "C:\Users\Public\Documents\Hyper-V\$VMName\$VMName.vhdx" `
-NewVHDSizeBytes $VHDSize

Set-VMDvdDrive -VMName $VMName -Path $VMIso

Get-VMNetworkAdapter $VMName | ? {$_.islegacy -eq $false} | Remove-VMNetworkAdapter

if ($VMName -like "RT-*") {
Add-VMNetworkAdapter -VMName $VMName -SwitchName "External" -IsLegacy $true
Add-VMNetworkAdapter -VMName $VMName -SwitchName "Network A" -IsLegacy $true
Add-VMNetworkAdapter -VMName $VMName -SwitchName "Network B" -IsLegacy $true
} Elseif ($VMName -like "*-A-*"){
Add-VMNetworkAdapter -VMName $VMName -SwitchName "Network A" -IsLegacy $true
} Elseif ($VMName -like "*-B-*"){
Add-VMNetworkAdapter -VMName $VMName -SwitchName "Network B" -IsLegacy $true
}
Start-VM $VMName
}
```
