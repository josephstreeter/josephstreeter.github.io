# Windows Time Service

---

date:   2012-10-19 00:00:00 -0500
categories: IT

---

## Time Service

The Domain Controller that hosts the PDC Emulator role in the forest root domain is an important part of time synchronization for the entire forest. The Domain Controller with the PDCE emulator role should be configured to use a reliable external time source. All other DCs should be configured to use the standard DC method of time synchronization.

## PDC Emulator Time in VMWare

This information was taken from the VMWare white paper:
[Virtualizing a Windows Active Directoy Domain Infrastructure]("http://www.vmware.com/files/pdf/Virtualizing_Windows_Active_Directory.pdf")

## Configure Windows Time Service for Synchronization in Registry

The first option is to use the Windows Time Service and not VMware Tools synchronization for the forest root PDC Emulator. This requires configuring the forest PDC emulator to use an external time source. The procedure for defining an alternative external time source for this â€œmaster time server is as follows:

1. Modify Registry settings on the PDC Emulator for the forest
root domain:
In this key:

    ```text
    HKLM\System\CurrentControlSet\Services\W32Time\Parameters\Type
    ```

    - Change the Type REG_SZ value from NT5DS to NTP. This determines from which peers W32Time will accept synchronization. When the REG_SZ value is changed from NT5DS to NTP, the PDC Emulator synchronizes from the list of reliable time servers specified in the NtpServer registry key.

    ```text
    HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\NtpServer
    ```

    - Change the NtpServer value from ```time.windows.com,0x1``` to
    an external stratum 1 time source. For example, ```tock.usno.
    navy.mil,0x1```.

    This entry specifies a space-delimited list of stratum 1 time
    servers from which the local computer can obtain reliable
    time stamps. The list can use either fully-qualified domain
    names or IP addresses.

    > [!NOTE]
    > If DNS names are used, you must append ,0x1 to the end of each DNS name.

    In this key:

    ```text
    HKLM\System\CurrentControlSet\Services\W32Time\Config
    ```

    - Change AnnounceFlags REG_DWORD from ```10``` to ```5```.

    This entry controls whether the local computer is marked as a reliable time server (which is only possible if the previous registry entry is set to NTP as described above). Change the REG_DWORD value from 10 to 5 here.

2. Stop and restart the time service:

    ```cmd
    net stop w32time
    net start w32time
    ```

3. Manually force an update:

    ```cmd
    w32tm /resync /rediscover
    ```

Microsoft KB article # 816042 provides detailed instructions
for this process.

## Configure Windows Time Service for Synchronization with Group Policy

A Group Policy Object linked to the Domain Controllers OU will configure Time Synchronization for the PDCE. A WMI filter on the policy will ensure that the policy applies to the PDCE in the event that the PDCE roll is transferred to or seized by another DC. In a Single Forest - Multiple Domain configuration this policy would only have to apply to the PDCE in the Forest Root Domain.

A separate Group Policy Object will configure the time service for all other domain controllers. It is important that the Group Policy Objects are applied in the appropriate order to ensure the PDCE GPO is applied last.

### WMI Filter for PDCE FSMO Roll

| Select * from Win32_ComputerSystem where DomainRole = 5 |
|------------------------------------------------------------------------|
| Roles 0 = standalone, 1 = Member workstation, 2 = Standalone Server, 3 = Member Server, 4 = Backup domain controller, 5 = Primary domain controller |

### PDCE Time Service Configuration

Administrative Templates/System/Windows Time Service/Global Configuration Settings -- Enabled

- AnnounceFlags 5

Administrative Templates/System/Windows Time Service/Time Providers/Configure Windows NTP Client -- Enabled

- NtpServer ntp1.madisoncollege.edu,0x1, ntp2.madisoncollege.edu,0x1
- TypeNTP

Administrative Templates/System/Windows Time Service/Time Providers/Enable Windows NTP Client -- Enabled

### All Domain Controllers that are not Root Domain PDC Emulator

A Group Policy Object linked to the Domain Controllers OU, other than the Default Domain Controllers policy, will ensure that the default Time Syncronization settings are not changed on the remaining Domain Controllers.

Administrative Templates/System/Windows Time Service/Global Configuration Settings -- Enabled

- AnnounceFlags 10

Administrative Templates/System/Windows Time Service/Time Providers/Configure Windows NTP Client -- Enabled

- NtpServer ntp1.madisoncollege,0x1, ntp2.madisoncollege,0x1
- TypeNT5DS

Administrative Templates/System/Windows Time Service/Time Providers/Enable Windows NTP Client -- Enabled
