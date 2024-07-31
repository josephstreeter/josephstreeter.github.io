---

title:  Configure RSAT from the Command Line
date:   2012-10-19 00:00:00 -0500
categories: IT
---






Use the command line to configure the role and feature tools on Windows 7.

```powershell
dism /online /enable-feature /featurename:*feature name*
```

For information about the current roles and features?

```powershell
dism /online /get-features | more
```

How to install the Active Directory and Group Policy tools.

<b>***Must be in proper order***</b>

```powershell
dism /online /enable-feature /featurename:RemoteServerAdministrationTools
dism /online /enable-feature /featurename:RemoteServerAdministrationTools-Roles
dism /online /enable-feature /featurename:RemoteServerAdministrationTools-Roles-AD
dism /online /enable-feature /featurename:RemoteServerAdministrationTools-Roles-AD-DS
dism /online /enable-feature /featurename:RemoteServerAdministrationTools-Roles-AD-DS-SnapIns
dism /online /enable-feature /featurename:RemoteServerAdministrationTools-Roles-AD-Powershell
dism /online /enable-feature /featurename:RemoteServerAdministrationTools-Features
dism /online /enable-feature /featurename:RemoteServerAdministrationTools-Features-GP
```

<a href="http://4sysops.com/archives/how-to-install-rsat-on-windows-7-sp1/">How to install RSAT on Windows SP1 from CLI</a>

On Server 2008 you configure features and roles using PowerShell

Load the Server Manager module

```powershell
Import-Module Servermanager
```

See a list of features and roles

```powershell
Get-WindowsFeature
```

Add the feature

```powershell
Add-WindowsFeature *name* -restart
```

The "-restart" argument will cause the host to reboot.

How to install the Active Directory and Group Policy tools.

```powershell
Add-WindowsFeature RSAT-AD-Tools,RSAT-ADDS,RSAT-ADDS-Tools,RSAT-AD-PowerShell
```


