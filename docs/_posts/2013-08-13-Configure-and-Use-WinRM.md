---
title:  Configure and Use WinRM
date:   2013-08-13 00:00:00 -0500
categories: IT
---

A simple way to execute commands and scripts on remove Windows Servers is to configure WinRM. In order to perform these tasks securely we will be configuring WinRM to use SSL to encrypt all of its traffic. This will require that each host has a valid Server Authentication certificate with a CN matching the hostname.

The following command will configure WinRM:

```powershell
winrm quickconfig -transport:https
```

Verify that TCP/5986 is open in the firewall and you should be all set. Be sure to use the computer name as it appears in the CN of the server certificate and the "-UseSSL" argument.
Now you should be able to use the following commands:
Run a command on a remote server

```powershell
Invoke-Command -computer computer.domain.tld -scriptblock {Get-Service Server} -UseSSL
```

Run a local script on a remote server

```powershell
Invoke-Command -computer computer.domain.tld -FilePath C:\scripts\test.ps1 -UseSSL
```

Execute a command multiple remote servers:

```powershell
$Servers = @("RemoteHost1.domain.tld ", "RemoteHost2.domain.tld ", "RemoteHost3.domain.tld ")
Invoke-Command -ComputerName $Servers -ScriptBlock {Get-Service Server}
```

Force Group Policy Update on all Domain Controllers

```powershell
Invoke-Command -comp $((Get-ADComputer -f * -searchbase "ou=domain controllers,dc=domain,dc=tld").dnshostname) -ScriptBlock {gpupdate /target:computer /force} -UseSSL
```

Connect to a local/remote computer by name:

```powershell
Enter-PSSession -ComputerName RemoteHost.domain.tld -UseSSL
```
