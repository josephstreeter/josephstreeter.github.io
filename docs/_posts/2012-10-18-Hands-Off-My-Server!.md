---

title:  Hyper-V 2016 Core Lab in Intel Nuc (Install)
date:   2012-10-18 00:00:00 -0500
categories: IT
---

Download Hyper-V 2016 Core ISO

Load onto USB

Install on Nuc

Download Inet NIC Drivers
Download the Intel NUC network driver for Windows 10 10PROWin64.exe from Intel website and extract to a folder.

[https://downloadcenter.intel.com/download/26092/Intel-Network-Adapter-Driver-for-Windows-Server-2016-?product=83418](https://downloadcenter.intel.com/download/26092/Intel-Network-Adapter-Driver-for-Windows-Server-2016-?product=83418)

Install Intel NIC drivers

1. List installed network controllers.  Open powershell window and type the following command:
    ```powershellGet-NetAdapter```
2. Verify vendor id for network controllers. Open powershell and type the following commands:

    ```powershell
    Get-WMIObject win32_PNPEntity |select name,deviceid |where {$_.Name -match "Ethernet"}
    Get-WMIObject win32_PNPEntity |select name,deviceid |where {$_.Name -match "Network"}
    ```

3. List network drivers available for vendor id's  found in step 2.  Go to folder extracted in step 1 and type the following commands:

    ```powershell
    Get-ChildItem -Recurse |Select-String -Pattern "VEN_8086&DEV_1570" |group Path |select Name
    Get-ChildItem -Recurse |Select-String -Pattern "VEN_8086&DEV_24F3" |group Path |select Name
    ```

4. For Windows Server 2016 installation and we will use e1d65x64.inf file located in "PROWinx64\PRO1000\Winx64\NDIS65\e1c65x64.inf". Open e1d65x64.inf in notepad removing the lines under [ControlFlags] and copying the E1502NC lines to [Intel.NTamd64.10.0.0]

    ```text
    [Intel.NTamd64.10.0.1] %E1570NC.DeviceDesc% = E1570.10.0.1, PCI\VEN_8086&DEV_1570
    %E1570NC.DeviceDesc% = E1570.10.0.1, PCI\VEN_8086&DEV_1570&SUBSYS_00008086
    %E1570NC.DeviceDesc% = E1570.10.0.1, PCI\VEN_8086&DEV_1570&SUBSYS_00011179
    ```

    Copy and paste text at the end of section [Intel.NTamd64.10.0]

5. Disable driver signature verification by entering the following commands and rebooting:

    ```powershell
    bcdedit /set LOADOPTIONS DISABLE_INTEGRITY_CHECKS
    bcdedit /set TESTSIGNING ON
    bcdedit /set NOINTEGRITYCHECKS ON
    ```

6. Install network drive using the following command:

    ```powershell
    pnputil.exe -i -a D:\Intel\PRO1000\Winx64\NDIS65\e1d65x64.inf
    ```

7. Accept software installation
8. List installed network controllers.  Open powershell window and type the following command:

    ```powershell
    Get-NetAdapter
    ```

9. Re-enable driver signature verification by running the following commands and rebooting:

    ```powershell
    bcdedit /set LOADOPTIONS ENABLE_INTEGRITY_CHECKS
    bcdedit /set TESTSIGNING OFF
    bcdedit /set NOINTEGRITYCHECKS OFF
    ```

## References

- [https://blog.dhampir.no/content/the-intel-82579v-on-hyper-v-server-2016](https://blog.dhampir.no/content/the-intel-82579v-on-hyper-v-server-2016)
- [https://blog.citrix24.com/install-windows-server-2016-core-intel-nuc/](https://blog.citrix24.com/install-windows-server-2016-core-intel-nuc/)
