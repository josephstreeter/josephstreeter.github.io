# User Objects

Created: 2019-05-13 11:13:18 -0500

Modified: 2019-05-13 11:14:06 -0500

---

## Person Accounts

Types of Person Accounts:

- Network ID (NetID)
- Privileged

## Network ID

A Person account is a user object that is created explicitly to provide a security context that is directly mapped to the identity of a real person that has some form of association with the organization. The use of Network ID accounts will be limited to non-privileged user activities such as using email clients, accessing file shares, office suites, and web browsers. Network ID accounts will not be granted administrative privileges on hosts or used to authenticate services or applications to Active Directory.

Person accounts will be created and managed by the IdM System for all Students, Faculty, Staff, and Contractor/Consultants.

## Privileged Accounts

Privileged accounts are created for the purpose of assigning rights and permissions required for administration of resources owned by the organization. Each Privileged Account must be mapped directly to a NetID. All users that are granted privileged access must have a separate account for performing administration tasks of hosts and systems. This administrative account is to be used strictly for administrative purposes. This account is NOT to be used for day-to-day (normal) business, e.g. e-mail accounts are not to be tied to this account. All administrators will use their NetID account to logon to their workstations and use the RunAs command to connect to administrative applications, such as Active Directory Users and Computers.

Privileged accounts will be created by the Identity and Access Management Team. Privileged accounts will be assigned rights by resource owners.

## Non-Person Accounts

A non-person account is auser object created to represent a service, a group of people, or anonymous access.These non-person accounts will not be used as person accounts for individual users.

## Service Accounts

A Service account is a user account that is created explicitly to provide a security context for services running on a server. Service accounts will be created in the following manner:

- Service accounts will be created and managed by the Identity and Access Management Team
- Service accounts will not be granted interactive logon rights (Exemption may be granted)
- Service account names will start with consist of "svc" followed by a three to five letter code for the service and a three to five letter code for the department separated by dashes (e.g. svc-{desc}-{dept}).
- The description filed of the service account's user object will consist of a brief description of the service that is using the account
- Service accounts will be used for only one service
- Service accounts will only be located in a "Service Accounts" OU.
- Service accounts will only be assigned the permissions required to run the service.
- Service accounts will have complex passwords that are maintained in a secure location that is accessible to the appropriate administrators.

## Resource

- A Resource account is a user account that is created explicitly to provide a security context.... Resource accounts will be created in the following manner:

## Organizational

- An organizational account is a user account that is created explicitly to provide a security context.... Organizational accounts will be created in the following manner:
