# Time Service

Created: 2019-05-13 11:23:13 -0500

Modified: 2022-08-23 14:34:40 -0500

---

Time Service

The Domain Controller that hosts the PDC Emulator role in the forest root domain is an important part of time synchronization for the entire forest. The Domain Controller with the PDCE emulator role should be configured to use a reliable external time source. All other DCs should be configured to use the standard DC method of time synchronization.

A Group Policy Object linked to the Domain Controllers OU will configure Time Synchronization for the PDCE. A WMI filter on the policy will ensure that the policy applies to the PDCE in the event that the PDCE roll is transferred to or seized by another DC. In a Single Forest - Multiple Domain configuration this policy would only have to apply to the PDCE in the Forest Root Domain.

A separate Group Policy Object will configure the time service for all other domain controllers. It is important that the Group Policy Objects are applied in the appropriate order to ensure the PDCE GPO is applied last.

## WMI Filter for PDCE FSMO Roll

| Select * from Win32_ComputerSystem where DomainRole = 5 |
|------------------------------------------------------------------------|
| Roles 0 = standalone, 1 = Member workstation, 2 = Standalone Server, 3 = Member Server, 4 = Backup domain controller, 5 = Primary domain controller |

## PDCE Time Service Configuration

Administrative Templates/System/Windows Time Service/Global Configuration Settings -- Enabled

- AnnounceFlags 5

Administrative Templates/System/Windows Time Service/Time Providers/Configure Windows NTP Client -- Enabled

- NtpServer ntp1.madisoncollege.edu,0x1, ntp2.madisoncollege.edu,0x1
- TypeNTP

Administrative Templates/System/Windows Time Service/Time Providers/Enable Windows NTP Client -- Enabled

## All Domain Controllers that are not Root Domain PDC Emulator

A Group Policy Object linked to the Domain Controllers OU, other than the Default Domain Controllers policy, will ensure that the default Time Syncronization settings are not changed on the remaining Domain Controllers.

Administrative Templates/System/Windows Time Service/Global Configuration Settings -- Enabled

- AnnounceFlags 10

Administrative Templates/System/Windows Time Service/Time Providers/Configure Windows NTP Client -- Enabled

- NtpServer ntp1.madisoncollege,0x1, ntp2.madisoncollege,0x1
- TypeNT5DS

Administrative Templates/System/Windows Time Service/Time Providers/Enable Windows NTP Client -- Enabled
