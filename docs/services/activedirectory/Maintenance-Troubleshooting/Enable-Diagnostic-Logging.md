# Enable Diagnostic Logging

## Summary

Turn on diagnostic logging for AD DS

Diagnostic logging for domain controllers is managed in the following registry location:

```console
HKLMSYSTEMCurrentControlSetServicesNTDSDiagnostics
```

Logging can be configured by modifying these REG_DWORD entries:

- 1 Knowledge Consistency Checker (KCC)
- 2 Security Events
- 3 ExDS Interface Events
- 4 MAPI Interface Events
- 5 Replication Events
- 6 Garbage Collection
- 7 Internal Configuration
- 8 Directory Access
- 9 Internal Processing
- 10 Performance Counters
- 11 Initialization/Termination
- 12 Service Control
- 13 Name Resolution
- 14 Backup
- 15 Field Engineering
- 16 LDAP Interface Events
- 17 Setup
- 18 Global Catalog
- 19 Inter-site Messaging
- 20 Group Caching
- 21 Linked-Value Replication
- 22 DS RPC Client
- 23 DS RPC Server
- 24 DS Schema

## Diagnostic Logging Levels

The values below are used to configure the level of diagnostic logging provided by the host:

| 0 | None | Only critical events and error events are logged at this level. This is the default setting for all entries, and it should be modified only if a problem occurs that you want to investigate |
|---------|---------|------------------------------------------------------|
| 1 | Minmal | Very high-level events are recorded in the event log at this setting. Events may include one message for each major task that is performed by the service. Use this setting to start an investigation when you do not know the location of the problem |
| 2 | Basic |  |
| 3 | Extensive | This level records more detailed information than the lower levels, such as steps that are performed to complete a task. Use this setting when you have narrowed the problem to a service or a group of categories |
| 4 | Verbose |  |
| 5 | Internal | This level logs all events, including debug strings and configuration changes. A complete log of the service is recorded. Use this setting when you have traced the problem to a particular category of a small set of categories |

## View Current Logging Levels

$Reg = "HKLM:SYSTEMCurrentControlSetServicesNTDSDiagnostics"
Get-ItemProperty -Path $Reg

## Configure with PowerShell

Use the following PowerShell example to configure logging levels:

```powershell
$Reg = "HKLM:SYSTEMCurrentControlSetServicesNTDSDiagnostics"
Set-ItemProperty -Path $Reg -Name <service> -Type DWORD -Value <value>
```

## Netlogon Logging

After enabling Netlogon logging the activity will be logged to %windir%debugnetlogon.log. Depending on the amount of activity you may want to increase the size of this log from the default 20 MB. When the file reaches 20 MB, it is renamed to Netlogon.bak, and a new Netlogon.log file is created.

The size of the Netlogon.log file can be increased by changing the MaximumLogFileSize registry entry. This registry entry does not exist by default.

### Configure log size with PowerShell

```powershell
$Reg = "HKLM: SYSTEMCurrentControlSetServicesNetlogonParameters"
New-ItemProperty -Path -Name MaximumLogFileSize -Type DWORD -Value <log-size>
```

### Configure log size with Group Policy

```text
Computer Configuration -> Administrative Templates -> SystemNet Logon -> Maximum Log File Size
```

### Turn on NetLogon Logging - Command Line

```cmd
nltest /dbflag:0x2080ffff
```

### Turn on NetLogon Logging - PowerShell

```Powershell
$Reg = "HKLM:SYSTEMCurrentControlSetServicesNetlogonParametersÂÂÃ‚Â"
New-ItemProperty -Path -Name DBFlag -Type DWORD -Value 545325055

$Reg = "HKLM:SYSTEMCurrentControlSetServicesNetlogonParameters"
Set-ItemProperty -Path $Reg -Name DBFlag -Type DWORD -Value 545325055

Restart-Service netlogon
```

### Turn off NetLogon Logging - Command Line

```cmd
nltest /dbflag:0x0
```

### Turn off NetLogon Logging - PowerShell

```powershell
$Reg = "HKLM:SYSTEMCurrentControlSetServicesNetlogonParameters"
Set-ItemProperty -Path $Reg -Name DBFlag -Type DWORD -Value 0

Restart-Service netlogon
```
