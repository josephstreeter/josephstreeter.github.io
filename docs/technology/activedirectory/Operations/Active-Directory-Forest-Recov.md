# Active Directory Forest Recovery

In order to perform a full server recovery it is important that the drive configuration matches that of the server the backup was taken from. Each disk that is used in the restore must be the same size or larger than the disks used on the server that the image was created from.

For the purpose of this guide the host name of the domain controller being restored is CADSDC-CSSC-01.ad.wisc.edu. In the event of an actual restoration the host name may be different.

**Important:** Following the Full Restore from Image stage Windows will promptt for a restart after login. It is extremely important that the host is NOT restarted until you are told to do so by this guide. Continue to select Restart Later until instructed to reboot the server. Failure to do so will cause the restore to fail.

**Note:** All Campus Active Directory Domain Controllers are configured to use User Access Control. In order to save time and effort during the restore process it is recommended that administrator conducting the restore open an elevated cmd or PowerShell session and run all commands from there. This will limit the number of times that the administrator has to enter his/her credentials into the UAC promptt. Where possible the commands to launch the necessary tools will be provided by this guide. The administrator should be familiar with the commands listed in the **Commands** section of this document and their uses.

## Performing the Full System Backup

The procedures that are outlined in this document are written for restoration from a backup image created using the Windows Server Backup feature that is included with the Windows Server 2008 R2 operating system. While backups are currently being created using IBM Tivoli Storage Manager these steps have not been tested using backup images created by TSM.

Because if issues like USN roll-back, Domain Controllers will not be restored from backup or snapshot unless a full Forest Recovery is required. In the event of a single failed domain controller a new host will be provisioned and promoted following the complete decommissioning and metadata cleanup of the failed domain controller. The newly provisioned domain controller will be allowed to backfill through normal replication or promoted with the Install from Media method.

The Windows Server Backup process will be conducted daily on the Domain Controller that holds the Primary Domain Controller Emulator role. The system image and data required for the recovery will be stored on a remote server. The location of the system image and data is listed in the Restoration Date Information section of this document.

## Restoration Data Information

| **DC Name**    | **FSMO**       | **VM (Y/N)** | **Site** | **IP Address** |
|----------------|----------------|--------------|----------|----------------|
| CADSDC-CSSC-01 | RID/PDC        | Y            | CSSC     |                |
| CADSDC-CSSC-02 | Schema/Naming  | Y            | CSSC     |                |
| CADSDC-CSSC-03 | Infrastructure | Y            | CSSC     |                |
| CADSDC-WARF-01 |                | Y            | WARF     |                |
| CADSDC-WARF-02 |                | Y            | WARF     |                |
| CADSDC-WARF-03 |                | Y            | WARF     |                |

---

| **UNC Path to Image** | [supernova.ad.wisc.edubackupimage](file://supernova.ad.wisc.edu/backup/image) |
|--------------------------|----------------------------------------------|
| **UNC Path to Data** | [supernova.ad.wisc.edubackupdata](file://supernova.ad.wisc.edu/backup/data) |

<table style="width:100%;">
<colgroup>
<col style="width: 26%" />
<col style="width: 27%" />
<col style="width: 46%" />
</colgroup>
<thead>
<tr>
<th><strong>Full System Restore</strong></th>
<th></th>
<th></th>
</tr>
</thead>
<tbody>
<tr>
<td>1</td>
<td>Start Windows Setup, accept the defaults for Language, Time and currency format, and keyboard options and click <strong>Next</strong>.</td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>2</td>
<td><p>Click <strong>Repair your computer</strong>.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>3.</td>
<td><p>In the <strong>System Recovery Options</strong> dialog box select <strong>Restore your computer using a system image that you created earlier</strong> and click <strong>Next</strong>.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>4.</td>
<td><p>In the <strong>Re-image your computer ? Select a system image backup</strong> dialog box select the <strong>Select a system image</strong> option and click <strong>Next.</strong>?</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>5.</td>
<td><p>In the <strong>Re-image your computer ? Select the location of the backup for the computer you want to restore</strong> dialog box select the desired system image.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>6.</td>
<td><p>In the <strong>Re-image your computer ? Select the date and time of system image to restore</strong> dialog box select a version and click <strong>Next</strong>.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>7</td>
<td><p>In the <strong>Re-image your computer - Choose additional restore options</strong> dialog box click <strong>Next</strong>.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>8.</td>
<td><p>In the <strong>Re-image your computer</strong> Summary window click <strong>Next.</strong></p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>9.</td>
<td><p>When promptted to continue click <strong>Yes</strong>.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>10.</td>
<td><p>While the restore is in progress watch the progress window for <strong>Restoring disk</strong>. This is a good sign that the restore is succeeding.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>11.</td>
<td><p>When the restore is complete you will be promptted to restart or the server will automatically restart when the timeout ends.</p>
<p></p></td>
<td><p>(NEED SCREEN CAPTURE FOR THIS)</p>
<p></p></td>
</tr>
<tr>
<td><p><strong></strong></p>
<p><strong>SYSVOL Authoritative Restore</strong></p>
<p><strong></strong></p></td>
<td></td>
<td></td>
</tr>
<tr>
<td>1.</td>
<td><p>Log into the newly restored Domain Controller with the built-in Administrator account or Domain Administrator account.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td><p></p>
<p></p>
<p></p>
<p></p>
<p></p>
<p></p>
<p></p>
<p></p>
<p></p>
<p></p>
<p></p></td>
<td></td>
<td></td>
</tr>
<tr>
<td>2.</td>
<td>Configure the server?s IP address based on the documented information for the Domain Controller being restored. Be sure to set the <strong>Preferred DNS server</strong> to the same IP address configured for the server.</td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>3.</td>
<td><p>Open an elevated PowerShell session and enter <strong>net share</strong>. The output of the command should show that the <strong>Netlogon</strong> and <strong>SYSVOL</strong> shares do not exist.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>4.</td>
<td><p>Stop the FRS service by entering the <strong>stop-service ntfrs</strong> command. Enter the <strong>get-service ntfrs</strong> command to verify that the service is no longer running.</p>
<p></p></td>
<td><p></p>
<p></p>
<p></p></td>
</tr>
<tr>
<td>5.</td>
<td><p>Run Regedt32.exe from the elevated PowerShell session.</p>
<p></p></td>
<td></td>
</tr>
<tr>
<td>6.</td>
<td><p>Set the registry value for authoritative restore.</p>
<p></p></td>
<td><p>HKLMSystemCurrentControlSetServicesNtFrsParametersBackup/RestoreProcess at Startup</p>
<p>Value: BurFlag</p>
<p>Data: D4</p></td>
</tr>
<tr>
<td>7.</td>
<td>Open an Explorer windows and navigate to the following directory:</td>
<td>D:SYSVOLsysvolad.wisc.edu Ntfrs_PreExisting__See_EventLog</td>
</tr>
<tr>
<td>8.</td>
<td>Copy the contents of the directory listed in the previous step and copy to the directory one level above:</td>
<td><p>D:SYSVOLsysvolad.wisc.edu</p>
<p></p>
<p></p></td>
</tr>
<tr>
<td>9.</td>
<td><p>Start the FRS service by entering the <strong>start-service ntfrs</strong> command. Enter the <strong>get-service ntfrs</strong> command to verify that the service is running.</p>
<p></p></td>
<td></td>
</tr>
<tr>
<td>10.</td>
<td><p>In <strong>Event Viewer</strong> open the <strong>File Replication Service</strong> log and look for Event ID 13516. This event must be present before proceeding. It could take up to 5 ? 10 min for the event to appear.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>11.</td>
<td><p>Run the <strong>net share</strong> command and verify netlogon and sysvol shares now exist.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>12.</td>
<td>Open <strong>Active Directory Users and Computers</strong> (dsa.msc) and verify that Active Directory is operational</td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>13.</td>
<td>The account that is being used for the install is likely already a member of Domain Admins. Add the account to the Enterprise Admins and Schema Admins groups if it is not already a member.</td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>14.</td>
<td>Log out and log back in using the same account so that you have a new security token for any new group memberships you may have.</td>
<td></td>
</tr>
<tr>
<td><p><strong></strong></p>
<p><strong>Seizing Operations Master Roles</strong></p>
<p><strong></strong></p></td>
<td></td>
<td></td>
</tr>
<tr>
<td>1.</td>
<td>Verify the Operations role holders using the <strong>netdom query fsmo</strong> command.</td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>2.</td>
<td>At an elevated? PowerShell promptt, type the command <strong>ntdsutil</strong> and then press <strong>ENTER.</strong></td>
<td></td>
</tr>
<tr>
<td>3.</td>
<td>At the <strong>ntdsutil</strong> promptt type <strong>roles</strong> and press <strong>ENTER.</strong></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>4.</td>
<td>At the <strong>FSMO maintenance:</strong> promptt, type <strong>Connections</strong> and then press <strong>ENTER.</strong></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>5.</td>
<td>At the <strong>server connections:</strong> promptt, type <strong>Connect to server &lt;server-name&gt;</strong> and then press <strong>ENTER.</strong></td>
<td></td>
</tr>
<tr>
<td>6.</td>
<td>At the <strong>server connections:</strong> promptt, type <strong>Quit</strong> and then press <strong>ENTER</strong> to return to the <strong>FSMO maintenance</strong> promptt<strong>.</strong></td>
<td></td>
</tr>
<tr>
<td>7.</td>
<td><p>Enter the appropriate commands to seize all operations master roles currently not held by the domain controller that you are restoring.</p>
<p></p>
<p>Click <strong>Yes</strong> for each of the confirmation windows that appear.</p></td>
<td><p></p>
<table>
<colgroup>
<col style="width: 47%" />
<col style="width: 52%" />
</colgroup>
<thead>
<tr>
<th><strong>Role</strong></th>
<th><strong>Command</strong></th>
</tr>
</thead>
<tbody>
<tr>
<td>Domain naming master</td>
<td><strong>Seize naming master</strong></td>
</tr>
<tr>
<td>Schema master</td>
<td><strong>Seize schema master</strong></td>
</tr>
<tr>
<td>Infrastructure master</td>
<td><strong>Seize infrastructure master</strong></td>
</tr>
<tr>
<td>PDC emulator master</td>
<td><strong>Seize pdc</strong></td>
</tr>
<tr>
<td>RID master</td>
<td><strong>Seize rid master</strong></td>
</tr>
</tbody>
</table>
<p></p>
<p></p></td>
</tr>
<tr>
<td>8.</td>
<td>Type <strong>Quit</strong> and press <strong>Enter</strong> twice to exit <strong>ntdsutil</strong>.</td>
<td></td>
</tr>
<tr>
<td>9.</td>
<td>Enter <strong>netdom query fsmo</strong> to verify that all operations master roles are now held by the restored domain controller.</td>
<td></td>
</tr>
<tr>
<td><p><strong></strong></p>
<p><strong>Metadata cleanup</strong></p>
<p><strong></strong></p>
<p>Performing metadata cleanup is how Active Directory data related to the domain controllers that have not yet been restored is removed.</p>
<p>With Windows Server 2008 and above the metadata cleanup is performed when the computer object for the domain controller is deleted using a version of Active Directory Users and Computers that is included in the Remote Server Administration Tools (RSAT).</p></td>
<td></td>
<td></td>
</tr>
<tr>
<td><p>1.</p>
<p></p>
<p></p>
<p></p>
<p></p></td>
<td>Start <strong>Active Directory Users and Computers</strong> (dsa.msc) and expand the <strong>Domain Controllers</strong> OU.</td>
<td></td>
</tr>
<tr>
<td>2.</td>
<td><p>In the details pane, right-click the Domain Controller that you want to delete, and then click <strong>Delete.</strong></p>
<p></p>
<p>Click <strong>Yes</strong> to confirm the deletion. Select the <strong>This Domain Controller is permanently offline and can no longer be demoted using the Active Directory Domain Services Installation Wizard (DCPROMO)</strong> check box and click <strong>Delete</strong></p></td>
<td></td>
</tr>
<tr>
<td>3.</td>
<td><p>Open the <strong>DNS Server</strong> snap-in (dnsmgmt.msc).</p>
<p></p>
<p>Right-click the <strong>_msdcs.ad.wisc.edu</strong> zone and click <strong>Properties</strong></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td></td>
<td><p>In the <strong>_msdcs.ad.wisc.edu</strong> zone Properties dialog box click the <strong>Name Servers Tab</strong> and remove each domain controller that has not been restored.</p>
<p></p></td>
<td></td>
</tr>
<tr>
<td></td>
<td><p>Right-click the <strong>ad.wisc.edu</strong> zone and click <strong>Properties</strong></p>
<p></p>
<p>In the <strong>ad.wisc.edu</strong> zone Properties dialog box click the <strong>Name Servers Tab</strong> and remove each domain controller that has not been restored.</p>
<p><strong></strong></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td><p><strong></strong></p>
<p><strong>Raise the Value of Available RID Pools</strong></p>
<p></p>
<p>The <strong>rIDAvailalablePool</strong> attribute of the <strong>CN=RID Manager$,CN=SYSTEM,DC=ad,DC=wisc,DC=edu</strong> object has a large integer for a value. The upper and lower parts of this value defines the number of security principals that can be allocated for each domain and number of RIDs that have aleady been allocated.</p>
<p></p></td>
<td></td>
<td></td>
</tr>
<tr>
<td>1.</td>
<td><p>From an elevated PowerShell promptt open <strong>ADSIEdit</strong> by entering the <strong>adsiedit.msc</strong> command.</p>
<p>Right-click <strong>ADSI</strong> Edit and click <strong>Connect.</strong></p>
<p><strong></strong></p>
<p>Connect to the <strong>Default Naming Context</strong></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>2.</td>
<td><p>Browse to the <strong>CN=RID Manager$,CN=SYSTEM,DC=ad,DC=wisc,DC=edu</strong> object.</p>
<p></p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td></td>
<td><p>Right-click the <strong>CN=RID Manager$,CN=SYSTEM,DC=ad,DC=wisc,DC=edu?</strong> object and click properties.</p>
<p></p>
<p>Increase the <strong>rIDAvailalablePool</strong> attribute by <strong>100,000</strong>.</p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td><p><strong></strong></p>
<p><strong>Resetting the computer account password of the domain controller</strong></p>
<p></p></td>
<td></td>
<td></td>
</tr>
<tr>
<td>1.</td>
<td>At an elevated PowerShell promptt enter the <strong>netdom resetpwd /server:&lt;<em>domain-controller-name</em>&gt; /ud:administrator /pd:*</strong> command twice.</td>
<td><p><strong>Example:</strong></p>
<p>netdom resetpwd /server:cadsdc-cssc-01 /ud:administrator /pd:*</p>
<p></p>
<p></p></td>
</tr>
<tr>
<td><p><strong></strong></p>
<p><strong>Resetting the krbtgt password</strong></p>
<p><strong></strong></p></td>
<td></td>
<td></td>
</tr>
<tr>
<td>1.</td>
<td>Start <strong>Active Directory Users and Computers</strong> (dsa.msc) and expand the <strong>Users</strong> Container.</td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>2.</td>
<td><p>Right-click the krbtgt user and click <strong>Reset Password</strong>.</p>
<p></p>
<p>Enter and confirm the password and click <strong>OK</strong>.</p>
<p></p>
<p></p></td>
<td></td>
</tr>
<tr>
<td>3.</td>
<td>From an elevated PowerShell promptt reset your Password by running the <strong>net user administrator &lt;New-Password&gt; /domain</strong>.</td>
<td><p>net user administrator C0mpl3xP@ssW0rd_! /domain</p>
<p></p>
<p></p></td>
</tr>
<tr>
<td>4.</td>
<td>Log off and log back in with the same account and new password.</td>
<td></td>
</tr>
<tr>
<td>5.</td>
<td>Reboot when promptted to do so.</td>
<td></td>
</tr>
<tr>
<td><p><strong></strong></p>
<p><strong>Resetting a trust password on one side of the trust</strong></p>
<p></p>
<p>Reset the password on only the trusting domain side of the trust, also known as the incoming trust (the side where this domain belongs). Then, use the same password on the trusted domain side of the trust, also known as the outgoing trust. Reset the password of the outgoing trust when you restore the first DC in each of the other (trusted) domains</p></td>
<td></td>
<td></td>
</tr>
<tr>
<td>1.</td>
<td>At an elevated PowerShell promptt enter <strong>netdom query trusts</strong> to view a list of configured trusts.</td>
<td></td>
</tr>
<tr>
<td>2.</td>
<td>For each existing trust enter the <strong>netdom trust ad.wisc.edu /domain:&lt;<em>trusted-domain</em>&gt; /resetoneside /pt:&lt;<em>trust-password</em>&gt; /uo:administrator /po:*</strong></td>
<td><p><strong>Example:</strong></p>
<p>netdom trust ad.wisc.edu /domain:ad.comdis.wisc.edu /resetoneside /pt:<em>C0mpl3xP@ssW0rd</em> /uo:administrator /po:*</p>
<p><strong></strong></p>
<p></p>
<p>This command only needs to be run once because it automatically resets the password twice.</p></td>
</tr>
<tr>
<td><p>?</p>
<p></p>
<p></p>
<p></p>
<p></p>
<p></p>
<p></p>
<p></p></td>
<td></td>
<td></td>
</tr>
<tr>
<td><p><strong>Rebuild the Global Catalog</strong></p>
<p></p></td>
<td></td>
<td></td>
</tr>
<tr>
<td>1.</td>
<td>Remove the Global Catalog from the restored Domain Controller by running the <strong>Repadmin /options &lt;<em>domain-controller-name</em>&gt; -is_gc</strong> command from an elevated PowerShell promptt.</td>
<td><p><strong>Example:</strong></p>
<p>Repadmin /options cadsdc-cssc-01 -is_gc</p>
<p></p>
<p></p></td>
</tr>
<tr>
<td>2.</td>
<td>Open <strong>Event Viewer</strong> (eventvwr.msc) to verify that the Domain Controller is no longer a Global Catalog by locating <strong>Event ID 1120</strong> in the <strong>Directory Service</strong> log.</td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>3.</td>
<td>Add the Global Catalog from the restored Domain Controller by running the <strong>Repadmin /options &lt;<em>domain-controller-name</em>&gt; +is_gc</strong> command from an elevated PowerShell promptt.</td>
<td><p><strong>Example:</strong></p>
<p>Repadmin /options cadsdc-cssc-01 +is_gc</p>
<p></p></td>
</tr>
<tr>
<td>4.</td>
<td>Open <strong>Event Viewer</strong> (eventvwr.msc) to verify that the Domain Controller is now a Global Catalog by locating <strong>Event ID 1110</strong> in the <strong>Directory Service</strong> log.</td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>5.</td>
<td>Verify that the process has completed five minutes later by locating <strong>Event ID 1119</strong> in the <strong>Directory Service</strong> log.</td>
<td></td>
</tr>
<tr>
<td><p><strong>Configure Time Settings</strong></p>
<p></p></td>
<td></td>
<td></td>
</tr>
<tr>
<td>1.</td>
<td><p>Open the registry editor (regedt32.exe) and verify that the Windows Time service is correctly configured.</p>
<p></p>
<p>If the Windows Time service is correctly configured not further steps are required.</p></td>
<td><p>HKLM&gt;SYSTEM&gt;CurrentControlSet&gt;services.W32Time&gt;Parameters</p>
<p>Type = NTP</p>
<p>NtpServer = ntp1.doit.wisc.edu ntp2.doit.wisc.edu ntp3.doit.wisc.edu</p>
<p></p>
<p></p>
<p></p></td>
</tr>
<tr>
<td>2.</td>
<td>If the Windows Time service is not configured correctly, stop the W32Time service by running the <strong>stop-service w32time</strong> command from an elevated PowerShell promptt</td>
<td></td>
</tr>
<tr>
<td>3.</td>
<td>Make the appropriate changes to the W32Time registry keys.</td>
<td><p>HKLM&gt;SYSTEM&gt;CurrentControlSet&gt;services.W32Time&gt;Parameters</p>
<p>Type = NTP</p>
<p>NtpServer = ntp1.doit.wisc.edu ntp2.doit.wisc.edu ntp3.doit.wisc.edu</p>
<p></p></td>
</tr>
<tr>
<td>4.</td>
<td>Start the W32Time service by running the <strong>start-service w32time</strong> command from an elevated PowerShell promptt</td>
<td><p></p>
<p></p></td>
</tr>
</tbody>
</table>

<table>
<colgroup>
<col style="width: 22%" />
<col style="width: 63%" />
<col style="width: 13%" />
</colgroup>
<thead>
<tr>
<th>Authoratative DFS-R Restore</th>
<th></th>
<th></th>
</tr>
</thead>
<tbody>
<tr>
<td>1.</td>
<td><p>Stop the DFSR service by entering the <strong>stop-service dfsr</strong> command</p>
<p></p></td>
<td><p></p>
<p></p>
<p></p></td>
</tr>
<tr>
<td>2.</td>
<td><p>Open <strong>Active Directory Users and Computers</strong> (dsa.msc).</p>
<p></p>
<p>Click on the <strong>View</strong> menu and select <strong>Advanced</strong> and <strong>View objects as containers</strong>.</p>
<p></p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>3.</td>
<td><p>Browse to the <strong>Domain controllers</strong> OU</p>
<p></p>
<p>Expand the <strong>computer object</strong> and <strong>DFSR-LocalSettings</strong> folder for the Domain Controller that you are restoring.</p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>4.</td>
<td><p>Double click <strong>SYSVOL Subscription</strong> to open the Properties dialog box.</p>
<p></p>
<p>In the <strong>SYSVOL Subscription Properties</strong> dialog box click the <strong>Attibute Editor</strong> tab.</p></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>5.</td>
<td>Set the <strong>msDFSR-Options</strong> attribute to <strong>1</strong></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>6.</td>
<td>Verify that the <strong>msDFSR-Enable</strong> is set to <strong>TRUE</strong></td>
<td><p></p>
<p></p></td>
</tr>
<tr>
<td>7.</td>
<td>Start the DFSR service by entering the <strong>start-service dfsr</strong> command</td>
<td>start-service dfsr</td>
</tr>
<tr>
<td>8.</td>
<td>Run the <strong>Dfsrdiag polladd</strong> command</td>
<td>Dfsrdiag polladd</td>
</tr>
<tr>
<td></td>
<td>Completion of DFS-R restore look for <strong>event ID 4602</strong>.</td>
<td></td>
</tr>
<tr>
<td></td>
<td>Net share to check for SYSVOL/Netlogon</td>
<td><p></p>
<p></p></td>
</tr>
</tbody>
</table>

**Commands**

****

net share

net user <username> < new-password> /domain

repadmin /viewlist *

repadmin /showrepl

repadmin /replsum

repadmin /options <dc-name> +is_gc [-is_gc]

dcdiag /e /q

dcdiag /test:dns

netdom query fsmo

netdom resetpwd

nltest /dclist:<domain-name>

ntdsutil

Dfsrdiag polladd

start-service <service-name>

stop-service -force <service-name>

get-service <service-name>

robocopy <source> < destination> /s /e

regedt32

dsa.msc

dssites.msc

adsiedit.msc

eventvwr.msc

dnsmgmt.msc

klist

klist tickets purge

dcdiag /adv
