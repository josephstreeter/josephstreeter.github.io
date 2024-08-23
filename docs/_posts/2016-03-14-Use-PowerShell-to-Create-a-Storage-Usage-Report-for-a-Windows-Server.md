---

title:  Use PowerShell to Create a Storage Usage Report for a Windows Server
date:   2016-03-14 00:00:00 -0500
categories: IT
---

This PowerShell script will give you a report for a server's storage usage. It will give you a status of "Green", "Amber", or "Red" for each drive.

```powershell
$StorageReport = @()
$date = get-date -uformat "%Y-%m-%d"
$Drives = Get-WmiObject -Class Win32_LogicalDisk | ? {$_.drivetype -eq 3} | select-object DeviceID,Size,Freespace,drivetype,VolumeName

foreach ($Drive in $Drives)
{
    if ($Drive.freespace)
    {
        $PercentFree = "{0:N2}" -f (($drive.freespace / $drive.size) * 100)
        $Size = "{0:N2}" -f (($drive.size / 1024 / 1024 / 1024))
        $Freespace = "{0:N2}" -f (($drive.freespace / 1024 / 1024 / 1024))
        switch ($PercentFree)
        {
            {$_ -gt 20} {$Status="Green"}
            {($_ -lt 20)-and($_ -gt 10)} {$Status="Amber"}
            {$_ -lt 10} {$Status="Red"}
            Default {$Status="Unknown"}
        }

        $StorageReport += New-object PSObject -Property @{
            "Drive" = $drive.DeviceID
            "DriveName" = $drive.volumeName
            "Freespace" = $Freespace
            "Size" = $Size
            "PercentFree" = $PercentFree + "%"
            "Status" = $Status
        }
    }
}

$StorageReport | ft Drive,DriveName,Size,FreeSpace,PercentFree,status -AutoSize
```
The results look like this:
```powershell
Drive DriveName           Size   Freespace PercentFree Status
----- ---------           ----   --------- ----------- ------
C:    System              99.66  17.28     17.34%      Amber
H:    SQL Backup          160.00 83.35     52.10%      Green
I:    MIM Svc SQL Logs    20.00  0.01      0.05%       Red
J:    MIM Svc SQL Data    140.00 129.86    92.76%      Green
K:    MIM Svc SQL TempDB  10.00  7.28      72.78%      Green
L:    MIM Sync SQL Logs   20.00  19.86     99.30%      Green
M:    MIM Sync SQL Data   80.00  79.12     98.91%      Green
N:    MIM Sync SQL TempDB 10.00  9.80      98.07%      Green
O:    MIM SPS SQL Logs    5.00   2.61      52.19%      Green
P:    MIM SPS SQL Data    10.00  9.95      99.58%      Green
Q:    MIM SPS SQL TempDB  10.00  9.93      99.37%      Green
R:    MIM Stage SQL Logs  5.00   4.61      92.25%      Green
S:    MIM Stage SQL Data  10.00  9.81      98.15%      Green
T:    MIM Stage TempDB    10.00  9.95      99.49%      Green
```




