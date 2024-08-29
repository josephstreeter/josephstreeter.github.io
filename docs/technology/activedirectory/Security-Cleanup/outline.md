# Outline

## Table of Contents

- [Create Delegated OU Structure](#create-delegated-ou-structure)
- [Organizational Unit Creation](#organizational-unit-creation)
- [Organizational Unit Delegation](#organizational-unit-delegation)
- [Identify Owners of Existing Leaf Objects](#identify-owners-of-existing-leaf-objects)
- [Create Data-Driven Roles (EntraID write-back)](#create-data-driven-roles-entraid-write-back)
- [Create Adhoc Roles (EntraID write-back)](#create-adhoc-roles-entraid-write-back)
- [Consolidate Existing Role Groups](#consolidate-existing-role-groups)
- [Replace existing AD roles with Entra ID write-back groups](#replace-existing-ad-roles-with-entra-id-write-back-groups)
- [Create ServiceNow requests](#create-servicenow-requests)
- [Removal of Delegated Permissions](#removal-of-delegated-permissions)

## Create Delegated OU Structure

The new Organizational Units will provide a place to store leaf objects for the teams that own the objects. Teams will be delegated least privileges required to manage objects.

### Organizational Unit Creation

```<Organizational Unit design>```

### Organizational Unit Delegation

```<ACLs>```

## Identify Owners of Existing Leaf Objects

Owners of the existing leaf objects will be identified so that the objects can be moved to the appropriate OU.

### Create Data-Driven Roles (EntraID write-back)

Roles will be created from HCM data based on higherarchy, employee type, and campus location. The created roles will encorporate primary, secondary and any tierciary positions that an employee may have.

These roles will populate Entra ID Security Groups and Microsoft 365 groups. The security groups will be configured to be written back to Active Directory.

### Create Adhoc Roles (EntraID write-back)

For levels of the higherarchy that are not defined in HCM data, role groups will be created.

#### Assign Owners

The memberships of these groups will be maintained by individuals identified to be owners of these groups. Owners will managed the membership of these groups through the Microsoft "My Groups" portal.

#### Access Reviews

Access Reviews will be configured for all adhoc groups. The owners will be set as the reviewers of these access reviews.

| **Configuration** | **Settings** |
|-------------------|--------------|
| Reviewers         | Group Owners |
| Interval          | Quarterly    |
| Other settings... |              |

## Consolidate Existing Role Groups

Many of the current roles in AD are one-to-one with the resources that they are assigned to. This has created a significant amount of redundancy in roles. These rudundant roles, where multiple roles are made of the of same users, adds great deal of administrative overhead.

Roles with identical memberships will be replaced by higherarchy-based roles or consilidated into a single role.

## Replace existing AD roles with Entra ID write-back groups

In cases where multiple roles are consolidated, the old roles can be replaced by the new one. Users who are members of the new role will have to log out and log back in for any existing sessions to maintain access to Active Directory-secured resources.

In cases where a role is not being consolidated, simply re-created in Entra ID, the role group written back to Active Directory can be "swapped" with the existing group.

> [!NOTE]
> The Entra ID Connect synchronization process should be stopped while performing these steps. This prevents conflicts from arising while the groups are being changed.

- Capture the anchor value (object ID) from the Entra ID group.
- The new Entra ID group written back to AD can be deleted.
- The anchor value from the Entra ID group is set on the existing AD role group.
- Move the AD role group from its current location to the OU configured in Entra ID Connect for group write-back.

## Create ServiceNow requests

Creation, Update, and Deletion activities for user and group objects will be performed programatically through ServiceNow requests where the rights are not otherwise delegated.

### Creation of New Service Account User Objects

Active Directory user object creation for the purposes of Service Accounts will be performed through a ServiceNow request.

These user objects will be created within the Team's delegated OU where the members of the team will be able to perform tasks such as changing or resetting passwords and managing group memberships.

### Creation of New Role and Resource groups

Group creation will be performed through a ServiceNow request.

| Purpose | Group Type | Location |
|---------|------------|----------|
| Resouce Groups  (AD Resources) | Domain Local Security Groups | Team's delegated OU |
| Resouce Groups  (Entra ID Resources) | Dynamic or Assigned Entra ID Security Groups | Entra ID |
| Role Groups | Dynamic or Assigned Entra ID Security Groups | Entra ID |
| Microsoft 365 Groups * | Microsoft 365 Group | Entra ID |

/* This is a required step in Microsoft Teams and Microsoft Planner.

## Removal of Delegated Permissions

Following the creation of the ServiceNow requests, the ACLs applied to the delegaed OUs for the creation and deletion of these objects can be removed.
