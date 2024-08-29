# Apply Baseline Group Policy and Security Settings to Windows Hosts

Created: 2015-03-20 09:23:29 -0500

Modified: 2015-03-20 09:24:49 -0500

---

**Keywords:** Local Group Policy Object Baseline Security Policies

**Summary:** This process will allow administrators to create a baseline for the local Group Policy Object and Security Policies.

This process may be used for standalone hosts or hosts joined to Active Directory. Many administrators will copy the registry.pol file from machine to machine. This method is not supported by Microsoft and will overwrite any policies already set.

By using the Local Group Policy Utilities from Microsoft we can export the registry-based policies to a text file. The secedit and auditpol commands can be used to export the local Security Policy and Advanced Auditing Policy.

## Create and export baseline

Download and extract the Local Group Policy Object Utilities

[LGPO_2D00_Utilities.zip](http://blogs.technet.com/cfs-file.ashx/__key/communityserver-components-postattachments/00-03-05-16-48/LGPO_2D00_Utilities.zip)

- Configure a host with the baseline settings in the local Group Policy Object that you wish to capture

- Export the local Security Policy and Advanced Auditing Policy configuration

    ```cmd
    secedit /export /cfg SECPOLWS2012.inf
    auditpol /backup /file:AUDITWS2012DC.txt
    ```

- Dump all registry-based Group Policy settings to a text file

```cmd
copy C:WindowsSystem32GroupPolicyMachineRegistry.pol
ImportRegPol.exe -m Registry.pol /log .LGPOWS2012DC.txt
```

## Configure Target Host with Baseline

- Copy the Local Group Policy Object Utilities and export files to the target host

- Import the local Security Policy and Advanced Auditing Policy configuration

```cmd
secedit /configure /db secpol.db /cfg SECPOLWS2012.inf
auditpol /restore /file:AUDITWS2012DC.txt
```

Import all registry-based Group Policy settings

```cmd
Apply_LGPO_Delta.exe LGPOWS2012DC.txt /log .lgpo.log /error lgpo_error.log
```

### Scripts

Export Baseline script:

```cmd
@ECHO OFF
ECHO ############################################
ECHO Export Server 2012 Domain Controller Basline
ECHO ############################################
ECHO Export Registry Based Local Group Policy

copy C:WindowsSystem32GroupPolicyMachineRegistry.pol .

ImportRegPol.exe -m Registry.pol /log .LGPOWS2012DC.txt

ECHO Export Local Security Policy Template

secedit /export /cfg SECPOLWS2012.inf

ECHO Export Complete
ECHO Export Detailed Audit Policy

auditpol /backup /file:AUDITWS2012DC.txt

ECHO ############################################
ECHO Export Complete
ECHO ############################################
```

Import Baseline script:

```cmd
@ECHO OFF
ECHO ############################################
ECHO Configure Server 2012 Domain Controller Basline
ECHO ############################################
ECHO Apply Registry Based Local Group Policy

Apply_LGPO_Delta LGPOWS2012DC.txt /log .lgpo.log /error .lgpo_error.log

ECHO Apply Local Security Policy Template

secedit /configure /db secpol.db /cfg SECPOLWS2012.inf

ECHO Configuration Complete

ECHO Apply Detailed Audit Policy

auditpol /restore /file:AUDITWS2012DC.txt

ECHO ############################################
ECHO Configuration Complete
ECHO ############################################
```
