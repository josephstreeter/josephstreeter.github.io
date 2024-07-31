---

title:  Check SHA1 Hash of a File with PowerShell
date:   2015-07-06 00:00:00 -0500
categories: IT
---







A short PowerShell script for checking the hash on a file downloaded from the Internet

```powershell$FilePath = "C:\users\user\downloads\gpg4win-2.2.4.exe"

$Sha1 = New-Object -TypeName System.Security.Cryptography.SHA1CryptoServiceProvider

$hashSha1 = [System.BitConverter]::ToString($sha1.ComputeHash([System.IO.File]::ReadAllBytes($FilePath)))

If ($hashSha1.Replace("-","") -eq $SourceSha1) {"Match"}Else{"Doesn not Match"}

$hashSha1.Replace("-","")
$SourceSha1.ToUpper()```


