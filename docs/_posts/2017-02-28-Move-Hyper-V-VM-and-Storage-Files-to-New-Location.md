---

title:  Move Hyper-V VM and Storage Files to New Location
date:   2017-02-28 00:00:00 -0500
categories: IT
---






The following script will move all of the VMs on a Hyper-V host to a new storage location. In this case we are moving the VMs from "C:\VM\VirtualMachines\" to "D:\VM\VirtualMachines\." This script assumes that the VM disks are kept in the VM folder and not in a separate location.

```powershell
$VMs=Get-VM
$Path="D:\VM\VirtualMachines\$($VM.Name)"

foreach ($VM in $VMs)
{
    Move-VMStorage -VM $(Get-VM $VM.Name) -DestinationStoragePath $Path
}
```


