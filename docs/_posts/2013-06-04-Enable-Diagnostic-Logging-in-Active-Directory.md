---

title:  Enable Diagnostic Logging in Active Directory
date:   2013-06-04 00:00:00 -0500
categories: IT
---






Sometimes the event logs just don't give you enough information for what you're troubleshooting. You can get a little more information by turning on diagnostic logging for a particular service.

Diagnostic logging for domain controllers is managed in the following registry location:

Logging can be configured by modifying these REG_DWORD entries:

1 Knowledge Consistency Checker (KCC)
2 Security Events
3 ExDS Interface Events
4 MAPI Interface Events
5 Replication Events
6 Garbage Collection
7 Internal Configuration
8 Directory Access
9 Internal Processing
10 Performance Counters
11 Initialization/Termination
12 Service Control
13 Name Resolution
14 Backup
15 Field Engineering
16 LDAP Interface Events
17 Setup
18 Global Catalog
19 Inter-site Messaging
20 Group Caching
21 Linked-Value Replication
22 DS RPC Client
23 DS RPC Server
24 DS Schema

Edit them by hand, script them, or use Group Policy Preferences to push them out. I would recommend using GPO Preferences to keep them to the values that you want so that it's not so easy for someone to change them without your knowledge.

Diagnostic Logging Levels

The values below are used to configure the level of diagnostic logging provided by the host:
<table border="1" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td valign="top" width="49">0</td>
<td valign="top" width="72">None<b></b></td>
<td valign="top" width="517">Only -  critical events and error events are logged at this level. This is the -  default setting for all entries, and it should be modified only if a problem -  occurs that you want to investigate<b></b></td>
</tr>
<tr>
<td valign="top" width="49">1</td>
<td valign="top" width="72">Minimal</td>
<td valign="top" width="517">Very -  high-level events are recorded in the event log at this setting. Events may -  include one message for each major task that is performed by the service. Use -  this setting to start an investigation when you do not know the location of -  the problem</td>
</tr>
<tr>
<td valign="top" width="49">2</td>
<td valign="top" width="72">Basic</td>
<td valign="top" width="517"></td>
</tr>
<tr>
<td valign="top" width="49">3</td>
<td valign="top" width="72">Extensive</td>
<td valign="top" width="517">This -  level records more detailed information than the lower levels, such as steps -  that are performed to complete a task. Use this setting when you have -  narrowed the problem to a service or a group of categories</td>
</tr>
<tr>
<td valign="top" width="49">4</td>
<td valign="top" width="72">Verbose</td>
<td valign="top" width="517"></td>
</tr>
<tr>
<td valign="top" width="49">5</td>
<td valign="top" width="72">Internal</td>
<td valign="top" width="517">This -  level logs all events, including debug strings and configuration changes. A -  complete log of the service is recorded. Use this setting when you have -  traced the problem to a particular category of a small set of categories</td>
</tr>
</tbody>
</table>


Configure with PowerShell

Use the following PowerShell example to configure logging levels:

```powershell
$Reg = â€œHKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics
Set-ItemProperty -Path $Reg -Name <service> -Type DWORD -Value <value>
```

***Enable NetLogon Logging***

After enabling Netlogon logging the activity will be logged to %windir%\debug\netlogon.log. Depending on the amount of activity you may want to increase the size of this log from the default 20 MB. - When the file reaches 20 MB, it is renamed to Netlogon.bak, and a new Netlogon.log file is created.

The size of the Netlogon.log file can be increased by changing the MaximumLogFileSize registry entry. This registry entry does not exist by default.

***Configure log size with PowerShell:***

```powershell
$Reg = â€œHKLM:\ SYSTEM\CurrentControlSet\Services\Netlogon\Parameters
New-ItemProperty -Path -Name MaximumLogFileSize-  -Type DWORD -Value <Log-Size>
```

***Configure log size with Group Policy:***

```powershell
Computer Configuration\Administrative Templates\System\Net Logon\Maximum Log File Size
```

***Turn on NetLogon Logging***

Command Line:

```powershell
nltest /dbflag:0x2080ffff
```

Powershell:

```powershell
Reg = â€œHKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\
New-ItemProperty -Path -Name DBFlag -Type DWORD -Value 545325055

$Reg = â€œHKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\
Set-ItemProperty -Path $Reg -Name DBFlag -Type DWORD -Value 545325055

Restart-Service netlogon
```
***Turn off NetLogon Logging***

Command Line:

```powershell
nltest /dbflag:0x0
```

PowerShell:

```powershell
$Reg = â€œHKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\
Set-ItemProperty -Path $Reg -Name DBFlag -Type DWORD -Value 0

Restart-Service netlogon
```


