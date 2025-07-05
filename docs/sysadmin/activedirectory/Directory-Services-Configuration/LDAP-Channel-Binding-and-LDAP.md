# LDAP Channel Binding and LDAP Signing requirement

## 2020 LDAP channel binding and LDAP signing requirement for Windows

Applies to: Windows 10, version 1903Windows 10, version 1809Windows Server 2019, all versionsWindows 10, version 1803Windows 10, version 1709Windows 10, version 1703Windows 10, version 1607Windows Server 2016Windows 10Windows 8.1Windows Server 2012 R2Windows Server 2012Windows 7 Service Pack 1Windows Server 2008 R2 Service Pack 1Windows Server 2008 Service Pack 2 [Less](https://support.microsoft.com/)

## Summary

[LDAP channel binding](https://support.microsoft.com/en-us/help/4034879) and[LDAP signing](https://support.microsoft.com/en-us/help/935834) provide ways to increase the security of network communications between an Active Directory Domain Services (AD DS) or an Active Directory Lightweight Directory Services (AD LDS)and its clients. There is a vulerability in the default configuration for Lightweight Directory Access Protocol (LDAP) channel bindingand LDAP signing and may expose Active directory domain controllers to elevation of privilege vulnerabilities. MicrosoftSecurity Advisory [ADV190023](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023)addressthe issue by recommending the administrators enable LDAP channel binding and LDAP signing on Active Directory Domain Controllers.This hardening must be done manually until the release of the security update that will enable these settings by default.

Microsoft intends to release a security update on Windows Update to enable LDAP channel binding and LDAP signing hardening changes and anticipate this update will be available inmid-January 2020.

## Why this change is needed

Microsoft recommends administrators make the hardening changes described in[ADV190023](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023)because when using default settings, an elevation of privilege vulnerability exists in Microsoft Windows that could allow a man-in-the-middle attacker to successfully forward an authentication request to a Windows LDAP server, such as a system running AD DS or AD LDS, which has not configured to require signing or sealing on incoming connections.The security of a directory server can be significantly improved by configuring the server to reject Simple Authentication and Security Layer (SASL) LDAP binds that do not request signing (integrity verification) or to reject LDAP simple binds that are performed on a clear text (non-SSL/TLS-encrypted) connection. SASLs may include protocols such as the Negotiate, Kerberos, NTLM, and Digest protocols. Unsigned network traffic is susceptible to replay attacks in which an intruder intercepts the authentication attempt and the issuance of a ticket. The intruder can reuse the ticket to impersonate the legitimate user. Additionally, unsigned network traffic is susceptible to man-in-the-middle attacks in which an intruder captures packets between the client and the server, changes the packets, and then forwards them to the server. If this occurs on an LDAP server, an attacker can cause a server to make decisions that are based on forged requests from the LDAP client.

## Recommended actions

We strongly advise administrators to enable LDAP channel binding and LDAP signing between now and mid-January 2020 to find and fix any operating systems, applications or intermediate devicecompatibility issues in their environment. If any compatibility issue is found, administrators will need to contact the manufacturer ofthat particular OS, application or devicefor support.

**Important** AnyOS version, applicationand intermediate devicethat performs a man-in-the-middle inspection of LDAP traffic are most likely to be impacted by this hardening change.

## Security update schedule

Microsoft is targeting the following schedule to enable LDAP channel binding and LDAP signing support.Please note that the timeline below is subject to change. We will update this page as the process begins and as needed.

<table style="width:100%;">
<colgroup>
<col style="width: 12%" />
<col style="width: 71%" />
<col style="width: 15%" />
</colgroup>
<thead>
<tr>
<th><strong>Target Date</strong></th>
<th><strong>Event</strong></th>
<th><strong>Applies To</strong></th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>August 13, 2019</strong></td>
<td><strong>Take Action: Microsoft Security Advisory</strong> <a href="https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023">ADV190023</a>published to introduce LDAP channel binding and LDAP signing support. Administrators will need to test these settings in their environmentafter manually adjusting them on their servers.</td>
<td><p>Windows Server 2008 SP2,</p>
<p>Windows 7 SP1,</p>
<p>Windows Server 2008 R2 SP1,</p>
<p>Windows 8.1,</p>
<p>Windows Server 2012 R2,</p>
<p>Windows 10 1507,</p>
<p>Windows Server 2016,</p>
<p>Windows 10 1607,</p>
<p>Windows 10 1703,</p>
<p>Windows 10 1709,</p>
<p>Windows 10 1803,</p>
<p>Windows 10 1809,</p>
<p>Windows Server 2019,</p>
<p>Windows 10 1903</p></td>
</tr>
<tr>
<td><strong>January 2020</strong></td>
<td><strong>Required: Security Update</strong> available on Windows Update for all supported Windows platforms that will enable LDAP channel binding and LDAP signing on Active Directory servers by default.</td>
<td><p>Windows Server 2008 SP2,</p>
<p>Windows 7 SP1,</p>
<p>Windows Server 2008 R2 SP1,</p>
<p>Windows 8.1,</p>
<p>Windows Server 2012 R2,</p>
<p>Windows 10 1507,</p>
<p>Windows Server 2016,</p>
<p>Windows 10 1607,</p>
<p>Windows 10 1703,</p>
<p>Windows 10 1709,</p>
<p>Windows 10 1803,</p>
<p>Windows 10 1809,</p>
<p>Windows Server 2019,</p>
<p>Windows 10 1903</p></td>
</tr>
</tbody>
</table>

## Frequently Ask Questions

[Why is there a delay between the release of the Security Advisory and the release of the security update for Windows which will set LDAP channel binding to a more secure default setting?](https://support.microsoft.com/)

Based on feedback Microsoft received, customers preferred we release the update after the 2019 holidays. Many administrators restrict configuration changes during the holiday season. Administrators will also need time to test these configuration changes and adjust their environment as needed to support it. This release schedule is intended to provide lead-time to prepare for this change.

*From <<https://support.microsoft.com/en-us/help/4520412/2020-ldap-channel-binding-and-ldap-signing-requirement-for-windows>>

## ADV190023 | Microsoft Guidance for Enabling LDAP Channel Binding and LDAP Signing

Security Advisory

Published: 08/13/2019 | Last Updated : 09/09/2019

On this page

- [Executive Summary](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023#ID0EN)
- [ExploitabilityAssessment](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023#ID0EA)
- [Security Updates](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023#ID0EGB)
- [Mitigations](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023#ID0EMGAC)
- [Workarounds](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023#ID0EUGAC)
- [FAQ](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023#ID0EKIAC)
- [Acknowledgements](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023#ID0EWIAC)
- [Disclaimer](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023#ID0ECJAC)
- [Revisions](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023#ID0EHJAC)

### Executive Summary

[LDAP channel binding](https://support.microsoft.com/en-us/help/4034879/how-to-add-the-ldapenforcechannelbinding-registry-entry) and [LDAP signing](https://support.microsoft.com/en-us/help/935834/how-to-enable-ldap-signing-in-windows-server-2008) provide ways to increase the security for communications between LDAP clients and Active Directory domain controllers. A set of unsafe default configurations for LDAP channel binding and LDAP signing exist on Active Directory Domain Controllers that let LDAP clients communicate with them without enforcing LDAP channel binding and LDAP signing. This can open Active directory domain controllers to elevation of privilege vulnerabilities.

This advisory addresses the issue by recommending a new set of safe default configurations for LDAP channel binding and LDAP signing on Active Directory Domain Controllers that supersedes the original unsafe configuration.

### Recommended Actions

In an upcoming release in early 2020, Microsoft will provide a Windows update that by default will change the LDAP channel binding and LDAP signing to more secure configurations. When the update is available, customers will be notified via a revision to this advisory. If you wish to be notified when the update is released, we recommend that you register for the security notifications mailer to be alerted of content changes to this advisory. See [Microsoft Technical Security Notifications](https://technet.microsoft.com/en-us/security/dd252948). In the meantime, we strongly advise customers to take the following steps at the earliest opportunity:

- Configure your systems to help make LDAP channel binding and LDAP signing on Active Directory Domain Controllers more secure.
- Find and fix any application compatibility issues in the environment.

See the following Microsoft Knowledge Base articles for guidance on how to enable LDAP channel binding and LDAP signing on Active Directory Domain Controllers:

- [2020 LDAP channel binding and LDAP signing requirement for Windows](https://support.microsoft.com/en-us/help/4520412)
- [LDAP channel binding](https://support.microsoft.com/en-us/help/4034879/how-to-add-the-ldapenforcechannelbinding-registry-entry)
- [LDAP signing](https://support.microsoft.com/en-us/help/935834/how-to-enable-ldap-signing-in-windows-server-2008)

### FAQ

**1. Why did Microsoft delay the release of the update which sets LDAP channel binding to a more secure default setting?**

Based on feedback Microsoft received, customers preferred that we release the update after the 2019 holiday season. Many administrators restrict configuration changes during the holiday season. Administrators will also need time to test these LDAP configuration changes and to adjust their environment as needed to support the changes. Releasing the update is intended to provide the lead-time needed to prepare for this change.

| **Product** | **Platform** | **Article** | **Download** | **Impact** | **Severity** | **Supersedence** |
|----------|-----------|---------|------------|---------|----------|-------------|

### Security Updates

To determine the support life cycle for your software version or edition, see the [Microsoft Support Lifecycle](https://support.microsoft.com/en-us/lifecycle).

### Mitigations

Microsoft has not identified any [mitigating factors](https://technet.microsoft.com/library/security/dn848375.aspx#Mitigation) for this vulnerability.

### Workarounds

Microsoft has not identified any [workarounds](https://technet.microsoft.com/library/security/dn848375.aspx#Workaround) for this vulnerability.

### Acknowledgements

Microsoft recognizes the efforts of those in the security community who help us protect customers through coordinated vulnerability disclosure.

See [acknowledgements](https://portal.msrc.microsoft.com/en-us/security-guidance/acknowledgments) for more information.

### Disclaimer

The information provided in the Microsoft Knowledge Base is provided "as is" without warranty of any kind. Microsoft disclaims all warranties, either express or implied, including the warranties of merchantability and fitness for a particular purpose. In no event shall Microsoft Corporation or its suppliers be liable for any damages whatsoever including direct, indirect, incidental, consequential, loss of business profits or special damages, even if Microsoft Corporation or its suppliers have been advised of the possibility of such damages. Some states do not allow the exclusion or limitation of liability for consequential or incidental damages so the foregoing limitation may not apply.

### Revisions

| **Version** | **Date** | **Description** |
|---------|-----------|-----------------------------------------------------|
| 1.0 | 08/13/2019 | Information published. |
| 1.1 | 09/09/2019 | Revised Recommended Actions section to provide customers with more detailed information about actions to take to make LDAP channel binding and LDAP signing on Active Directory Domain Controllers more secure. |

*From <<https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/ADV190023>>*

*********************************************************************************************************************************

*********************************************************************************************************************************

### How to enable LDAP signing in Windows Server 2008

Applies to: Windows Server 2008 Datacenter without Hyper-VWindows Server 2008 Enterprise without Hyper-VWindows Server 2008 for Itanium-Based Systems [More](https://support.microsoft.com/)

### RAPID PUBLISHING

RAPID PUBLISHING ARTICLES PROVIDE INFORMATION IN RESPONSE TO EMERGING OR UNIQUE TOPICS AND MAY BE UPDATED AS NEW INFORMATION BECOMES AVAILABLE.

### INTRODUCTION

The security of a directory server can be significantly improved by configuring the server to reject Simple Authentication and Security Layer (SASL) LDAP binds that do not request signing (integrity verification) or to reject LDAP simple binds that are performed on a clear text (non-SSL/TLS-encrypted) connection. SASLs may include protocols such as the Negotiate, Kerberos, NTLM, and Digest protocols.

Unsigned network traffic is susceptible to replay attacks in which an intruder intercepts the authentication attempt and the issuance of a ticket. The intruder can reuse the ticket to impersonate the legitimate user. Additionally, unsigned network traffic is susceptible to man-in-the-middle attacks in which an intruder captures packets between the client and the server, changes the packets, and then forwards them to the server. If this occurs on an LDAP server, an attacker can cause a server to make decisions that are based on forged requests from the LDAP client.

This article describes how to configure your directory server to protect it from such attacks.

### More Information

### How to discover clients that do not use the "Require signing" option

Clients that rely on unsigned SASL (Negotiate, Kerberos, NTLM, or Digest) LDAP binds or on LDAP simple binds over a non-SSL/TLS connection stop working after you make this configuration change. To help identify these clients, the directory server logs a summary event 2887 one time every 24 hours to indicate how many such binds occurred. We recommend that you configure these clients not to use such binds. After no such events are observed for an extended period, we recommend that you configure the server to reject such binds.

If you must have more information to identify such clients, you can configure the directory server to provide more detailed logs. This additional logging will log an event 2889 when a client tries to make an unsigned LDAP bind. The logging displays the IP address of the client and the identity that the client tried to use to authenticate. You can enable this additional logging by setting the **LDAP Interface Events** diagnostic setting to **2 (Basic)**. For more information about how to change the diagnostic settings, go to the following Microsoft website:

<http://go.microsoft.com/?linkid=9645087>

If the directory server is configured to reject unsigned SASL LDAP binds or LDAP simple binds over a non-SSL/TLS connection, the directory server will log a summary event 2888 one time every 24 hours when such bind attempts occur.

### How to configure the directory to require LDAP server signing

### Using Group Policy

### How to set the server LDAP signing requirement

- Click **Start**, click **Run**, type mmc.exe, and then click **OK**.
- On the **File** menu, click **Add/Remove Snap-in**.
- In the **Add or Remove Snap-ins** dialog box, click **Group Policy Management Editor**, and then click **Add**.
- In the **Select Group Policy Object** dialog box, click **Browse**.
- In the **Browse for a Group Policy Object** dialog box, click **Default Domain Policy** under the **Domains, OUs and linked Group Policy Objects** area, and then click **OK**.
- Click **Finish**.
- Click **OK**.
- Expand **Default Domain Controller Policy**, expand **Computer Configuration**, expand **Policies**, expand **Windows Settings**, expand **Security Settings**, expand **Local Policies**, and then click **Security Options**.
- Right-click **Domain controller: LDAP server signing requirements**, and then click **Properties**.
- In the **Domain controller: LDAP server signing requirements Properties** dialog box, enable **Define this policy setting**, click to select **Require signing** in the **Define this policy setting** drop-down list, and then click **OK**.
- In the **Confirm Setting Change** dialog box, click **Yes**.

### How to set the client LDAP signing requirement through local computer policy

- Click **Start**, click **Run**, type mmc.exe, and then click **OK**.
- On the **File** menu, click **Add/Remove Snap-in**.
- In the **Add or Remove Snap-ins** dialog box, click **Group Policy Object Editor**, and then click **Add**.
- Click **Finish**.
- Click **OK**.
- Expand **Local Computer Policy**, expand **Computer Configuration**, expand **Policies**, expand **Windows Settings**, expand **Security Settings**, expand **Local Policies**, and then click **Security Options**.
- Right-click **Network security: LDAP client signing requirements**, and then click **Properties**.
- In the **Network security: LDAP client signing requirements Properties** dialog box, click to select **Require signing** in the drop-down list, and then click **OK**.
- In the **Confirm Setting Change** dialog box, click **Yes**.

### How to set the client LDAP signing requirement through a domain Group Policy Object

- Click **Start**, click **Run**, type **mmc.exe**, and then click **OK**.
- On the **File** menu, click **Add/Remove Snap-in**.
- In the **Add or Remove Snap-ins** dialog box, click **Group Policy Object Editor**, and then click **Add**.
- Click **Browse**, and then select **Default Domain Policy** (or the Group Policy Object for which you want to enable client LDAP signing).
- Click **OK**.
- Click **Finish**.
- Click **Close**.
- Click **OK**.
- Expand **Default Domain Policy**, expand **Computer Configuration**, expand **Windows Settings**, expand **Security Settings**, expand **Local Policies**, and then click **Security Options**.
- In the **Network security: LDAP client signing requirements Properties** dialog box, click to select **Require signing** in the drop-down list, and then click **OK**.
- In the **Confirm Setting Change** dialog box, click **Yes**.

For more information, click the following article number to view the article in the Microsoft Knowledge Base:

[823659](https://support.microsoft.com/en-us/help/823659) Client, service, and program incompatibilities that may occur when you modify security settings and user rights assignments

### How to use registry keys

To have us change the registry keys for you, go to the "[Fix it for me](https://support.microsoft.com/en-us/help/935834/how-to-enable-ldap-signing-in-windows-server-2008#fixitformealways)" section. If you prefer to change the registry keys yourself, go to the "[Let me fix it myself](https://support.microsoft.com/en-us/help/935834/how-to-enable-ldap-signing-in-windows-server-2008#letmefixitmyselfalways)" section.

### Fix it for me

To fix this problem automatically, click the **Fix it** button or link, click **Run** in the **File Download** dialog box, and then follow the steps in the Fix it wizard.

### Notes

- This wizard may be in English only. However, the automatic fix also works for other language versions of Windows.
- If you are not using the computer that has the problem, save the Fix it solution to a flash drive or a CD, and then run it on the computer that has the problem.

Then, go to the "[Did this fix the problem?](https://support.microsoft.com/en-us/help/935834/how-to-enable-ldap-signing-in-windows-server-2008#fixedalways)" section.

### Let me fix it myself

Important This section, method, or task contains steps that tell you how to modify the registry. However, serious problems might occur if you modify the registry incorrectly. Therefore, make sure that you follow these steps carefully. For added protection, back up the registry before you modify it. Then, you can restore the registry if a problem occurs. For more information about how to back up and restore the registry, click the following article number to view the article in the Microsoft Knowledge Base:

[322756](https://support.microsoft.com/en-us/help/322756) How to back up and restore the registry in Windows

- Click **Start**, click **Run**, type regedit, and then click **OK**.
- Locate and then click the following registry subkey:
    **HKEY_LOCAL_MACHINESYSTEMCurrentControlSetServicesNTDSParameters**

- Right-click the **LDAPServerIntegrity** registry entry, and then click **Modify**.
- Change **Value data** to 2, and then click **OK**.
- Locate and then click the following registry subkey:
    **HKEY_LOCAL_MACHINESYSTEMCurrentControlSetServicesldapParameters**

- Right-click the **ldapclientintegrity** registry entry, and then click **Modify**.
- Change the **Value data** to 2, and then click **OK**.

By default, for Active Directory Lightweight Directory Services (AD LDS), the registry key is not available. Therefore, you must create a LDAPServerIntegrity registry entry of the REG_DWORD type under the following registry subkey:

```text
HKEY_LOCAL_MACHINESYSTEMCurrentControlSetServices<InstanceName>Parameters
```

Note The placeholder ```<InstanceName>``` represents the name of the AD LDS instance that you want to change.

**How to verify configuration changes

- Click **Start**, click **Run**, type ldp.exe, and then click **OK**.
- Under the **Connection** menu, click **Connect**.
- In the **Server** field and in the **Port** field, type the server name and the non-SSL/TLS port of your directory server, and then click **OK**.

    Note For an Active Directory Domain Controller, the applicable port is 389.

- After a connection is established, select **Bind** on the **Connection** menu.
- Under **Bind type**, select **Simple bind**.
- Type the user name and password, and then click **OK**.

if you receive the following error message, you successfully configured your directory server:

Ldap_simple_bind_s() failed: Strong Authentication Required
*From <<https://support.microsoft.com/en-us/help/935834/how-to-enable-ldap-signing-in-windows-server-2008>>

**Use the LdapEnforceChannelBinding registry entry to make LDAP authentication over SSL/TLS more secure

Applies to: Windows Server 2016 DatacenterWindows Server 2016 EssentialsWindows Server 2016 Standard [More](https://support.microsoft.com/)

**Summary

[CVE-2017-8563](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563) introduces a registry setting that administrators can use to help make LDAP authentication over SSL/TLS more secure.

**More Information

**Important** This section, method, or task contains steps that tell you how to modify the registry. However, serious problems might occur if you modify the registry incorrectly. Therefore, make sure that you follow these steps carefully. For added protection, back up the registry before you modify it. Then, you can restore the registry if a problem occurs. For more information about how to back up and restore the registry, click the following article number to view the article in the Microsoft Knowledge Base:

[322756](https://support.microsoft.com/en-us/help/322756) How to back up and restore the registry in Windows

To help make LDAP authentication over SSLTLS more secure, administrators can configure the following registry settings:

- **Path for Active Directory Domain Services (AD DS) domain controllers:** HKEY_LOCAL_MACHINESystemCurrentControlSetServicesNTDSParameters
- **Path for Active Directory Lightweight Directory Services (AD LDS) servers:** HKEY_LOCAL_MACHINESYSTEMCurrentControlSetServices*<LDS instance name>*Parameters
- **DWORD:** LdapEnforceChannelBinding
- **DWORD value: 0** indicates *disabled*. No channel binding validation is performed. This is the behavior of all servers that have not been updated.
- **DWORD value: 1** indicates *enabled*, when supported. All clients that are running on a version of Windows that has been updated to support channel binding tokens (CBT) must provide channel binding information to the server. Clients that are running a version of Windows that has not been updated to support CBT do not have to do so. This is an intermediate option that allows for application compatibility.
- **DWORD value: 2** indicates *enabled, always*. All clients must provide channel binding information. The server rejects authentication requests from clients that do not do so.

**Notes

- Before you enable this setting on a Domain Controller, clients must install the security update that is described in [CVE-2017-8563](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563). Otherwise, compatibility issues may arise, and LDAP authentication requests over SSL/TLS that previously worked may no longer work. By default, this setting is disabled.
- The LdapEnforceChannelBindings registry entry must be explicitly created.
- LDAP server responds dynamically to changes to this registry entry. Therefore, you do not have to restart the computer after you apply the registry change.

To maximize compatibility with older operating system versions (Windows Server 2008 and earlier versions), we recommend that you enable this setting with a value of **1**.

To explicitly disable the setting, set the LdapEnforceChannelBinding entry to **0** (zero).

Windows Server 2008 and older systems require that Microsoft Security Advisory [973811](https://technet.microsoft.com/library/security/973811), available in "KB [968389](https://support.microsoft.com/en-us/help/968389/extended-protection-for-authentication) Extended Protection for Authentication", be installed before installing CVE-2017-8563.If you installCVE-2017-8563 without KB [968389](https://support.microsoft.com/en-us/help/968389/extended-protection-for-authentication) on a Domain controller or AD LDS instance, all LDAPS connections will fail with LDAP error 81 - LDAP_SERVER_DOWN. In addition,we strongly recommended that you also review and install the fixes documented in the Known Issues section of KB [968389](https://support.microsoft.com/en-us/help/968389/extended-protection-for-authentication).

*From <<https://support.microsoft.com/en-us/help/4034879/how-to-add-the-ldapenforcechannelbinding-registry-entry>>*

### CVE-2017-8563 | Windows Elevation of Privilege Vulnerability

### Security Vulnerability

Published: 07/11/2017 | Last Updated : 07/13/2017

[MITRE CVE-2017-8563](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8563)

On this page

- [Executive Summary](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563#ID0EN)
- [ExploitabilityAssessment](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563#ID0EA)
- [Security Updates](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563#ID0EGB)
- [Mitigations](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563#ID0EMGAC)
- [Workarounds](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563#ID0EUGAC)
- [FAQ](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563#ID0EKIAC)
- [Acknowledgements](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563#ID0EWIAC)
- [Disclaimer](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563#ID0ECJAC)
- [Revisions](https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563#ID0EHJAC)

An elevation of privilege vulnerability exists in Microsoft Windows when a man-in-the-middle attacker is able to successfully forward an authentication request to a Windows LDAP server, such as a system running Active Directory Domain Services (AD DS) or Active Directory Lightweight Directory Services (AD LDS), which has been configured to require signing or sealing on incoming connections.

The update addresses this vulnerability by incorporating support for Extended Protection for Authentication security feature, which allows the LDAP server to detect and block such forwarded authentication requests once enabled.

| **Publicly Disclosed** | **Exploited** | **LatestSoftwareRelease** | **OlderSoftwareRelease** | **DenialofService** |
|----------|---------|--------------------|--------------------|--------------|
| No | No | 1 - Exploitation More Likely | 1 - Exploitation More Likely | Not Applicable |

**ExploitabilityAssessment

The following table provides an [exploitability assessment](https://technet.microsoft.com/en-us/security/cc998259.aspx) for this vulnerability at the time of original publication.

- [Security Updates](javascript:void(0))
- [CVSS Score](javascript:void(0))

| **Product** | **Platform** | **Article** | **Download** | **Impact** | **Severity** | **Supersedence** |
|--------------|---------|---------|----------|----------|----------|-------------|
| Windows 10 for 32-bit Systems |  | [4025338](https://support.microsoft.com/help/4025338) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025338) | Elevation of Privilege | Important | 4022727 |
| Windows 10 for x64-based Systems |  | [4025338](https://support.microsoft.com/help/4025338) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025338) | Elevation of Privilege | Important | 4022727 |
| Windows 10 Version 1511 for 32-bit Systems |  | [4025344](https://support.microsoft.com/help/4025344) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025344) | Elevation of Privilege | Important | 4022714 |
| Windows 10 Version 1511 for x64-based Systems |  | [4025344](https://support.microsoft.com/help/4025344) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025344) | Elevation of Privilege | Important | 4022714 |
| Windows 10 Version 1607 for 32-bit Systems |  | [4025339](https://support.microsoft.com/help/4025339) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025339) | Elevation of Privilege | Important | 4022715 |
| Windows 10 Version 1607 for x64-based Systems |  | [4025339](https://support.microsoft.com/help/4025339) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025339) | Elevation of Privilege | Important | 4022715 |
| Windows 10 Version 1703 for 32-bit Systems |  | [4025342](https://support.microsoft.com/help/4025342) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025342) | Elevation of Privilege | Important | 4022725 |
| Windows 10 Version 1703 for x64-based Systems |  | [4025342](https://support.microsoft.com/help/4025342) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025342) | Elevation of Privilege | Important | 4022725 |
| Windows 7 for 32-bit Systems Service Pack 1 |  | [4025341](https://support.microsoft.com/help/4025341) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025341) | Elevation of Privilege | Important | 4022719 |
|  |  | [4025337](https://support.microsoft.com/help/4025337) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025337) |  |  |  |
| Windows 7 for x64-based Systems Service Pack 1 |  | [4025341](https://support.microsoft.com/help/4025341) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025341) | Elevation of Privilege | Important | 4022719 |
|  |  | [4025337](https://support.microsoft.com/help/4025337) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025337) |  |  |  |
| Windows 8.1 for 32-bit systems |  | [4025336](https://support.microsoft.com/help/4025336) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025336) | Elevation of Privilege | Important | 4022726 |
|  |  | [4025333](https://support.microsoft.com/help/4025333) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025333) |  |  |  |
| Windows 8.1 for x64-based systems |  | [4025336](https://support.microsoft.com/help/4025336) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025336) | Elevation of Privilege | Important | 4022726 |
|  |  | [4025333](https://support.microsoft.com/help/4025333) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025333) |  |  |  |
| Windows RT 8.1 |  | [4025336](https://support.microsoft.com/help/4025336) | Monthly Rollup | Elevation of Privilege | Important | 4022726 |
| Windows Server 2008 for 32-bit Systems Service Pack 2 |  | [4025409](https://support.microsoft.com/help/4025409) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025409) | Elevation of Privilege | Important | 3184471 |
| Windows Server 2008 for 32-bit Systems Service Pack 2 (Server Core installation) |  | [4025409](https://support.microsoft.com/help/4025409) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025409) | Elevation of Privilege | Important | 3184471 |
| Windows Server 2008 for Itanium-Based Systems Service Pack 2 |  | [4025409](https://support.microsoft.com/help/4025409) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025409) | Elevation of Privilege | Important | 3184471 |
| Windows Server 2008 for x64-based Systems Service Pack 2 |  | [4025409](https://support.microsoft.com/help/4025409) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025409) | Elevation of Privilege | Important | 3184471 |
| Windows Server 2008 for x64-based Systems Service Pack 2 (Server Core installation) |  | [4025409](https://support.microsoft.com/help/4025409) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025409) | Elevation of Privilege | Important | 3184471 |
| Windows Server 2008 R2 for Itanium-Based Systems Service Pack 1 |  | [4025341](https://support.microsoft.com/help/4025341) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025341) | Elevation of Privilege | Important | 4022719 |
|  |  | [4025337](https://support.microsoft.com/help/4025337) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025337) |  |  |  |
| Windows Server 2008 R2 for x64-based Systems Service Pack 1 |  | [4025341](https://support.microsoft.com/help/4025341) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025341) | Elevation of Privilege | Important | 4022719 |
|  |  | [4025337](https://support.microsoft.com/help/4025337) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025337) |  |  |  |
| Windows Server 2008 R2 for x64-based Systems Service Pack 1 (Server Core installation) |  | [4025341](https://support.microsoft.com/help/4025341) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025341) | Elevation of Privilege | Important | 4022719 |
|  |  | [4025337](https://support.microsoft.com/help/4025337) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025337) |  |  |  |
| Windows Server 2012 |  | [4025331](https://support.microsoft.com/help/4025331) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025331) | Elevation of Privilege | Important | 4022724 |
|  |  | [4025343](https://support.microsoft.com/help/4025343) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025343) |  |  |  |
| Windows Server 2012 (Server Core installation) |  | [4025331](https://support.microsoft.com/help/4025331) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025331) | Elevation of Privilege | Important | 4022724 |
|  |  | [4025343](https://support.microsoft.com/help/4025343) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025343) |  |  |  |
| Windows Server 2012 R2 |  | [4025336](https://support.microsoft.com/help/4025336) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025336) | Elevation of Privilege | Important | 4022726 |
|  |  | [4025333](https://support.microsoft.com/help/4025333) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025333) |  |  |  |
| Windows Server 2012 R2 (Server Core installation) |  | [4025336](https://support.microsoft.com/help/4025336) | [Monthly Rollup](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025336) | Elevation of Privilege | Important | 4022726 |
|  |  | [4025333](https://support.microsoft.com/help/4025333) | [Security Only](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025333) |  |  |  |
| Windows Server 2016 |  | [4025339](https://support.microsoft.com/help/4025339) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025339) | Elevation of Privilege | Important | 4022715 |
| Windows Server 2016 (Server Core installation) |  | [4025339](https://support.microsoft.com/help/4025339) | [Security Update](https://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB4025339) | Elevation of Privilege | Important | 4022715 |

**Security Updates

To determine the support life cycle for your software version or edition, see the [Microsoft Support Lifecycle](https://support.microsoft.com/en-us/lifecycle).

**Mitigations

Microsoft has not identified any [mitigating factors](https://technet.microsoft.com/library/security/dn848375.aspx#Mitigation) for this vulnerability.

**Workarounds

Microsoft has not identified any [workarounds](https://technet.microsoft.com/library/security/dn848375.aspx#Workaround) for this vulnerability.

**FAQ

**In addition to installing the updates for CVE-2017-8563 are there any further steps I need to carry out to be protected from this CVE?** Yes. To make LDAP authentication over SSL/TLS more secure, administrators need to create a LdapEnforceChannelBinding registry setting on machine running AD DS or AD LDS. For more information about setting this registry key, see [Microsoft Knowledge Base article 4034879](https://support.microsoft.com/en-us/help/4034879).

**Acknowledgements

Yaron Zinar, Eyal Karni, Roman Blachman [Preempt](https://www.preempt.com)

See [acknowledgements](https://portal.msrc.microsoft.com/en-us/security-guidance/acknowledgments) for more information.

**Disclaimer

The information provided in the Microsoft Knowledge Base is provided "as is" without warranty of any kind. Microsoft disclaims all warranties, either express or implied, including the warranties of merchantability and fitness for a particular purpose. In no event shall Microsoft Corporation or its suppliers be liable for any damages whatsoever including direct, indirect, incidental, consequential, loss of business profits or special damages, even if Microsoft Corporation or its suppliers have been advised of the possibility of such damages. Some states do not allow the exclusion or limitation of liability for consequential or incidental damages so the foregoing limitation may not apply.

**Revisions

| **Version** | **Date** | **Description** |
|---------|------------|----------------------------------------------------|
| 1.0 | 07/11/2017 | Information published. |
| 1.1 | 07/13/2017 | Revised description for CVE-2017-8563 to more accurately describe this vulnerability. This is an informational change only. |

*From <<https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2017-8563>>*
