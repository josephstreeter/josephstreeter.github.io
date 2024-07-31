---

title:  Reset Secure Channel
date:   2013-11-05 00:00:00 -0500
categories: IT
---






Problems with a host's secure channel can be responsible for a number of authentication issues.

Each host that is joined to Active Directory maintains a local secret, or password, that is created by the client and stored in Active Directory. The client will initiate a password change every 30 days by default. Active Directory will store the current password as well as the previous password in the computer object for the joined host. Each time the client creates a new password, it creates the new password locally and stores it in the registry and then attempts to update the password in Active Directory. If the Active Directory password update is unsuccessful, the client keeps the newly created password and continues to attempt updating the Active Directory password.

If the client attempts to authenticate and Active Directory does not have the most recent password it will utilize the previous password. If the password used by the client to authenticate to Active Directory is newer than both passwords stored in the computer object, or the computer object is deleted, the authentication request will fail and the client will show the following error: "The trust relationship between this workstation and the primary domain failed."

It is possible to reset the computer password using the nltest.exe, dsmod.exe, netdom.exe, or the PowerShell cmdlets Test-ComputerSecureChannel and Reset-MachineAccountPassword.
## Netdom Command
In order to use the netdom tool you must have Remote Server Administration Tools (RSAT) installed.

- Download and install RSAT
- Go to Control Panel -> Programs and Features -> Turn Windows features on or off
- Select Remote Server Administration Tools -> Role Administration Tools -> AD DS and AD LDS Tools and select AD DS Tools
- Click Ok

To reset the computer's password:

- Log into the affected client with a local account with administrative privileges
- Open an elevated PowerShell or Command prompt
- Run the Netdom command
```powershellnetdom.exe resetpwd /s:CADSDC-CSSC-01.ad.wisc.edu /ud:ad\jsmith-ou /pd:*```

- The user specified with the "/ud:" must have rights to change the computer object password
- The "/pd:*" switch will hide the entered password


- Reboot

## PowerShell v2 - Test-ComputerSecureChannel

- Log into the affected client with a local account with administrative privileges
- Open an elevated PowerShell prompt
- Load the Active Directory PowerShell module
```powershellImport-Module activedirectory```

- Test the secure channel
```powershellTest-ComputerSecureChannel```

- If the command returns false, run the command with the "-Repair" switch
```powershellTest-ComputerSecureChannel -Repair -Credential $(Get-Credential)```

- verify the secure channel using the Test-ComputerSecureChannel
```powershellTest-ComputerSecureChannel```

- Reboot

## PowerShell v3 or higher - Reset-MachineAccountPassword

- Log into the affected client with a local account with administrative privileges
- Open an elevated PowerShell prompt
- Load the Active Directory PowerShell module
```powershellImport-Module activedirectory```

- Test the secure channel
```powershellTest-ComputerSecureChannel```

- If the command returns false, run the Reset-MachineAccountPassword command
```powershellReset-MachineAccountPassword -Credential $(Get-Credential)```

- verify the secure channel using the Test-ComputerSecureChannel
```powershellTest-ComputerSecureChannel```

- Reboot

## Nltest Command
The nltest command exists by default in Windows 7 and later. The following command will show the status of the secure channel and repair it if it is broken.
```powershellnltest /sc_verify:<domain-controller>```
## Nltest Command
The nltest command exists by default in Windows 7 and later. The following command will show the status of the secure channel and repair it if it is broken.
```powershellnltest /sc_verify:<domain-controller>```
## DSMod Command
The dsmod command can be used to reset the computer password on multiple computers at once
```powershelldsmod computer CN=<member-server>,CN=computers,DC=domain,DC=com -reset```
## References

- <a href="http://blogs.technet.com/b/heyscriptingguy/archive/2012/03/02/use-powershell-to-reset-the-secure-channel-on-a-desktop.aspx">Use PowerShell to Reset the Secure Channel on a Desktop (Hey, Scripting Guy! Blog)</a>
- <a href="http://blogs.technet.com/b/askds/archive/2009/02/15/test2.aspx">Machine Account Password Process (Ask DS Blog)</a>
- <a href="http://support.microsoft.com/kb/260575/en-us">How To Use Netdom.exe to Reset Machine Account Passwords of a Windows 2000 Domain Controller (MS Support)</a>
- <a href="http://technet.microsoft.com/en-us/library/hh849757.aspx"> Test-ComputerSecureChannel (MS TechNet)</a>
- <a href="http://technet.microsoft.com/en-us/library/hh849751.aspx"> Reset-ComputerMachinePassword (MS TechNet)</a>



