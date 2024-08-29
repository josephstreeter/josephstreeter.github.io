# Privileged Account Management

Created: 2019-05-13 11:28:45 -0500

Modified: 2019-05-13 11:28:57 -0500

---

## Secure OU for Sensitive Users and Groups

All sensitive user and group objects will be stored in a tightly controlled Organizational Unit named "Sensitive Objects" under the "Enterprise" top level OU with two sub Organizational Units named "Users" and "Computers". The Service Admins OU will not inherit permissions to avoid changes to the security settings from Domain level.

The following Access Control List will be applied to the Sensitive Objects OU:

| Type  | Name              | Access        | Applies To                        |
|-------|-------------------|---------------|-----------------------------------|
| Allow | Enterprise Admins | Full Control  | This object and all child objects |
| Allow | Domain Admins     | Full Control  | This object and all child objects |
| Allow | Administrators    | Full Control  | This object and all child objects |
| Allow | Pre–Windows2000 Compatible Access | List Contents, Read All Properties, Read Permissions | User and InetOrgPerson objects |
| Allow | Enterprise Domain Controllers | List Contents, Read All Properties, Read Permissions | This object only |
| Allow | Enterprise Domain Controllers | Read All Properties | User, group, and computer objects |

The following Sensitive administrator groups are to be relocated to the Groups OU within the controlled OU:

- Domain Admins
- Enterprise Admins
- Schema Admins (Root Domain Only)
- Any groups that are nested in the previous groups.
- Any groups that are nested in the Administrators, Server Operators, Backup Operators, or Account Operators groups.

Note: The Administrators, Server Operators, Backup Operators, or Account Operators groups cannot be moved from their default locations. However, these built-in groups have additional protections by default and do not require additional security measures.

Move all user accounts that are members of the sensitive administrators groups to the Users OU within the controlled OU.

## Configure Auditing for Secured OU

Auditing is required in order to detect and track changes to sensitive user and group objects. The following auditing configuration will be applied to the Service Admins OU:

|**Type**| **Name** | **Access**            | **Applies To**                    |
|--------|----------|-----------------------|-----------------------------------|
| All    | Everyone | Write All Properties  | This object and all child objects |
| All    | Everyone | Delete                | This object and all child objects |
| All    | Everyone | Delete Subtree        | This object and all child objects |
| All    | Everyone | Modify Permissions    | This object and all child objects |
| All    | Everyone | Modify Owner          | This object and all child objects |
| All    | Everyone | All Validated Writes  | This object and all child objects |
| All    | Everyone | All Extended Rights   | This object and all child objects |
| All    | Everyone | Create All Child Objects | This object and all child objects |
| All    | Everyone | Delete All Child Objects | This object and all child objects |

## Highly Privileged Users and Groups

The default highly privileged groups are located in their default containers and are populated with users and groups. Most of these highly privileged groups should be empty most of the time when the level of rights they provide are not required.

All security groups that are used to grant a high level of privilege and their members should be moved and secured in accordance with the Microsoft recommendations. Where possible, these groups should not have any members and membership should only be granted when necessary. Membership of these groups should be controlled by Group Policy and auditing enabled to log changes to them.

## Membership Requirements for Highly Privileged Groups

The Schema Admins, Enterprise Admins, Administrators, Account Operators, and Incoming Forest Trust builders groups all have members. These groups should not contain users unless there is an operational need and only long enough to complete the appropriate tasks.

The Domain Admins group has members as well. While many would claim that Domain Admins should not contain users either, it is an operational risk to not have key administrators as members. Instead, the number of members should be kept to a minimum.

There are service accounts and shared accounts that are members of highly privileged groups. These accounts may pose a security risk because it would be difficult to trace log activity to an actual person. Additionally, the passwords for these accounts are usually not changed regularly.

Membership in the following Windows security groups assigns a high level of privilege for AD functions: Domain Admins, Enterprise Admins, Schema Admins, and Incoming Forest Trust Builders. When a large number of users are members of highly privileged groups, the risk from unintended updates or compromised accounts is significantly increased.

| **Group Name** | **Default Location** | **Description** |
|----------------|----------------------|--------------------------------------------------|
| Enterprise Admins | Users container | This group is automatically added to the Administrators group in every domain in the forest, providing complete access to the configuration of all domain controllers. |
| Schema Admins | Users container | This group has full administrative access to the Active Directory schema. |
| Administrators | Built-in container | This group has complete control over all domain controllers and all directory content stored in the domain, and it can change the membership of all administrative groups in the domain. It is the most powerful service administrative group. |
| Domain Admins | Users container | This group is automatically added to the corresponding Administrators group in every domain in the forest. It has complete control over all domain controllers and all directory content stored in the domain and it can modify the membership of all administrative accounts in the domain. |
| Server Operators | Built-in container | By default, this built-in group has no members. It can perform maintenance tasks, such as backup and restore, on domain controllers. |
| Account Operators | Built-in container | By default, this built-in group has no members. It can create and manage users and groups in the domain, but it cannot manage service administrator accounts. As a best practice, do not add members to this group, and do not use it for any delegated administration. |
| Backup Operators | Built-in container | By default, this built-in group has no members. It can perform backup and restore operations on domain controllers. |
| Incoming Forest Trust Builders | Built-in container | By default, this built-in group has no members.It can create incoming, one-way trusts to this forest |

Administrators will maintain separate accounts for privileged and non-privileged level access. At no time should the privileged account be used for routine activities (i.e. web surfing or checking email). An administrator's privileged account will have only the rights that the administrator needs to accomplish assigned duties.

Membership in these groups should be limited to the absolute minimum that is required for personnel to complete their assigned tasks.

Enterprise Admins and Schema Admins groups will remain empty being populated only when needed. The Enterprise Admins group exists only in the forest root domain and gives its members administrator rights in all domains in the forest. While the administrator rights of the Enterprise Admins group may be removed from sub-domains by that domain's Domain Admins, membership in this group may be viewed as a political or security issue.

The Schema Admins group gives its members the ability to make changes to the schema. Unauthorized or improper changes made to the schema could cause serious forest-wide consequences. In the event that an administrator needs temporary Enterprise or Schema Admin rights a request explaining the purpose and duration of the elevation will be submitted to the Active Directory service team.

Domain Admins group will only contain those accounts that have been appointed as Domain Administrators by the approval authority. The appointment letter will be maintained by Security and will be made available for verification and audit purposes. The Approval Authority for Domain Administrators is the Chief Information Security Officer. Without documentation for Domain Admins group membership it is impossible to determine if the assigned accounts are consistent with the intended security policy.

Group membership will be enforced by a Restrictive Groups policy applied to the Domain Controller Organizational Unit for the following groups:

- Schema Admins
- Enterprise Admins
- Domain Admins
- Server Operators
- Account Operators
- Backup Operators
- Incoming Forest Trust Builders

## Restricted Groups Policies

Group Policy settings will be used to enforce the appropriate membership of the highly privileged groups.

## Computer ConfigurationWindows SettingsSecurity SettingsRestricted Groups

Highly Privileged groups will be added to the policy. The policy is then linked to the Domain Controllers OU. If a security context, such as a user or security group, is added to this group, without first being added to this policy object, it is automatically removed and an ID 637 event is logged in the Security log.
