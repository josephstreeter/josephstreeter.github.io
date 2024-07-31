---

title:  PDC Emulator Time in VMWare
date:   2012-10-19 00:00:00 -0500
categories: IT
---






This information was taken from the VMWare white paper <a href="http://www.vmware.com/files/pdf/Virtualizing_Windows_Active_Directory.pdf">*Virtualizing a Windows Active Directoy Domain Infrastructure*</a>

<b>Using Windows Time Service for Synchronization</b>

The first option is to use the Windows Time Service and not
VMware Tools synchronization for the forest root PDC Emulator.
This requires configuring the forest PDC emulator to use an
external time source. The procedure for defining an alternative
external time source for this â€œmaster time server is as follows:

1. Modify Registry settings on the PDC Emulator for the forest
root domain:
In this key:

*HKLM\System\CurrentControlSet\Services\W32Time\Parameters\Type*

â€¢ Change the Type REG_SZ value from NT5DS to NTP.
This determines from which peers W32Time will accept
synchronization. When the REG_SZ value is changed from
NT5DS to NTP, the PDC Emulator synchronizes from the list of
reliable time servers specified in the NtpServer registry key.

*HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\NtpServer*

â€¢ Change the NtpServer value from time.windows.com,0x1 to
an external stratum 1 time sourceâ€”for example, *tock.usno.
navy.mil,0x1*.

This entry specifies a space-delimited list of stratum 1 time
servers from which the local computer can obtain reliable
time stamps. The list can use either fully-qualified domain
names or IP addresses. (If DNS names are used, you must
append ,0x1 to the end of each DNS name.)

In this key:

*HKLM\System\CurrentControlSet\Services\W32Time\Config*

â€¢ Change AnnounceFlags REG_DWORD from 10 to 5.

This entry controls whether the local computer is marked as
a reliable time server (which is only possible if the previous
registry entry is set to NTP as described above). Change the
REG_DWORD value from 10 to 5 here.

2. Stop and restart the time service:

*net stop w32time*
*net start w32time*

3. Manually force an update:
*w32tm /resync /rediscover*

Microsoft KB article # 816042 provides detailed instructions
for this process.


