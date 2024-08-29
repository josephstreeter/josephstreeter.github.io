# Security Group Management Recommendation

Created: 2015-03-20 10:01:05 -0500

Modified: 2015-03-20 10:02:44 -0500

---

**Keywords:** Active Directory security groups global domain local universal

**Summary:** This document will cover the recommended creation and usage of Security Groups within Campus Active Directory. The creation of distribution groups and mail-enabling distribution or security groups is considered out of scope. Security groups are objects that are used to organize users and other directory objects for the purpose of authorization. Groups allow for easier organization and management of authorized access to resources. Body:

**Purpose of this Document:**

Campus Active Directory delegated administrators should be able to understand and use these guidelines for group management. Groups should be created and named in such a way that the purpose and scope of each group is easily recognized by other administrators. By using these AD group management rules and guidelines, a department can maintain a strong group management strategy. This will prevent the unnecessary proliferation of security groups, which leads to stale objects as well as authentication issues resulting from token bloat and circular nesting.

**Sources of Security Groups:**

While delegated administrators have the ability to create their own security groups through tools provided as part of the AD service, some groups originate from external sources such as Manifest.

Groups created in the Manifest service can be provisioned into Campus Active Directory for the purpose of authorizing access to Active Directory related resources. In addition, the security groups provisioned through Manifest may also be used to authorize access to services that are not bound to Active Directory (e.g. Shibboleth).

For more information about using Manifest click here. <link to Manifest info>

**Information About Groups:**

**Group Types:**

Groups in Active Directory come in two distinct types: Security and Distribution.

- **Security groups** --- Used to assign access rights and authorize appropriate access to resources such as file shares and printers. The use of groups greatly simplifies administration because adding a user to a single group can automatically give that user access to multiple resources.
- **Distribution groups** --- Used in conjunction with email services, such as Microsoft Exchange, to distribute email to a population of users and contacts. While distribution groups appear similar to security groups they cannot be used to authorize access to resources.

**Group Scope:**

For security groups there are three group scopes that are available. Knowing these three group scopes and how to properly use them is an important part of an organized group management strategy.

- **Domain local groups** --- May have users, computers, other domain local groups, global groups and universal groups as members from any domain in the forest or from trusted domains in other forests
- **Global groups** --- May have users, computers, and other global groups from within the same domain as members
- **Universal groups** --- May have users, computers, global groups, and universal groups from anywhere in the forest or from trusted forests

**Group Management:**

When assigning rights and permissions resources never assign permissions to individual users. Always assign permissions to security groups.

- **User rights** - User rights include both privileges (such as Back Up Files and Directories) and logon rights (such as allow logon locally).
- **Access control permissions** -- Any object (files, folders, mailboxes, directory object, etc) that has an Access Control List (ACL) can be given permissions such as Read, Write, Full Control, or Modify.

It is recommended that when creating and managing security groups you follow the Role Based Access Control (RBAC) model. The RBAC model lays out a multi-level strategy involving individual users, groups, and resources that lends itself to attestation and self-documentation. The pneumonic AGDLP explains the implementation of RBAC in Active Directory.

AGDLP stands for "**[A]{.underline}**ccounts go in **[G]{.underline}**lobal groups, global groups go in **[D]{.underline}**omain **[L]{.underline}**ocal groups, and local groups are assigned **[P]{.underline}**ermissions"

The AGDLP strategy is based the idea of using the different group scopes at each level:

- Global groups contain only users.
- Domain Local groups contain only other global or universal groups. End-point permissions are assigned only to local groups. Directory permissions are assigned to domain local groups.
- Universal groups contain only global groups.

AGDLP provides maximum flexibility, scalability, and ease of administration when creating and managing security groups. The following description outlines the recommended method of using global and domain local groups.

- Users are placed into security groups with global scope that represents a role that all members of the group will fulfill (Help Desk, Web Admin, Manager, Financial group, local admin).
- Create security groups with domain local scope and assign them permissions to access a resource (File, folder, mailbox, directory object, etc).
- Put the global group that was created for the role into any domain local group in the forest that is assigned permissions or rights required by those users assigned to the role.

**Domain Local**

For example, to give five users access to a particular printer, you could add all five user accounts, one at a time, to the printer permissions list. Later, if you wanted to give the same five users access to a new printer, you would again have to specify all five accounts in the permissions list for the new printer. Or, you could take advantage of groups with domain local scope.

**Global**

Use global groups to collect users or computers that are in the same domain and share the same job, organizational role, or function. For example, "Full-time employees," "Managers," "RAS Servers" are all possible global groups. Because group members typically need to access the same resources, make these global groups members of domain local or machine local groups, which, in turn, are listed on the DACL of needed resources.

**Universal**

If you choose to use groups with universal scope in a multi-domain environment, these groups can help you represent and consolidate groups that span domains. For example, you might use universal groups to build groups that perform a common function across an enterprise.

Although few organizations will choose to implement this level of complexity, you can add user accounts to groups with global scope, nest these groups within groups having universal scope, and then make the universal group a member of a domain local (or machine local) group that has access permissions to resources. Using this strategy, any membership changes in the groups having global scope do not affect the groups with universal scope.

**Example**

A department administrator needs to secure a number of resources. The resources are for the finance, marketing, and sales staff. The finance and sales staff each have access to a shared folder, shared Exchange mailbox, and a printer. The marketing staff only requires read only access to the other staff's shared folders and their own printer.

First, the administrator creates a global security group for each role (i.e. Finance, Marketing, and Sales) in either Manifest or Active Directory. The staff's user objects are then added to the appropriate "role" group.

**Note:**

*Groups created in Manifest are available for use in services outside of Campus Active Directory while groups created in Active Directory are only available to services that directly leverage Campus Active Directory or forests that have created a trust with Campus Active Directory. Groups created in Manifest must be replicated to Campus Active Directory. See Manifest documentation <link to Manifest Doc>*

Then the administrator creates domain local security groups for each level of access to be allowed to each resource (i.e. Shared folder -- Full Control, Shared Folder -- Read Only, Mailbox -- Send-as, etc). These "resource" groups are then given the appropriate permissions to each of the resources. It is important that a detailed description of the resource and level of access being provided to the group.

The "role" groups are then made members of the "resource" groups in order to provide the users access to those resources.

**Note:**

*If a user is currently logged into a host when the group changes are made, the user will have to log out and log back in for the newly granted access to take effect.*
