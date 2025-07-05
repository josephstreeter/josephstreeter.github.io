# Group Policy

Created: 2019-05-13 11:29:16 -0500

Modified: 2019-05-13 11:29:38 -0500

---

Group Policy is a feature that provides centralized management and configuration of computers and users in Active Directory. Group Policy can control a target object's registry, NTFS security, audit and security policy, install software, run logon/logoff and startup/shutdown scripts, folder redirection and offline file synchronization, Internet Explorer settings, and more.

Regular audits should be performed in order to identify:

- Group Policy objects that are not linked to a site, domain or OU
- Have no policies defined
- Do not meet naming standards

> [!NOTE]
> The following are findings in the current environment:
>
> A large number of Group Policy Objects are not linked to any containers. These objects should be removed from Active Directory if they are not being used. Additionally, there are a few GPOs that do not have any policy settings configured. These should also be removed.
>
> Only one GPO appears to have database and sysvol version numbers out of sync.
>
> Block inheritance is utilized in several areas -- redesign OU structure.
> Group Policy ADMX/ADML templates (Microsoft Server 2008 and later) should be located in a Central Store so that all Group Policy administrators receive the latest ADMX templates when using GPMC

Windows will process all GPOs that are linked to determine the effective policy setting to apply to either user or computer objects. In order to reduce logon and startup times the following steps should be taken when applying Group Policy

- Where possible combine Group Policy Settings into a fewer GPOs
- Filter GPOs by WMI or group membership
- Disable unused portions (e.g. user or computer) of a GPO
- GPOs should be periodically audited and all GPOs that are not linked or do not have policies configured should be removed
- Group Policy is applied in such a way that blocking inheritance is often required the organizational structure should likely be modified
