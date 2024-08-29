# Acceptable Use Policy

## Summary

This document outlines the appropriate use of user accounts in Campus Active Directory directly or using the ActiveRoles Server (ARS) product. Body:

## User Objects

There are two categories of user accounts: Person and Non-Person.

## Person Accounts

A person account is auser object created to represent an individual person's identity. Person accounts are primarily provisioned and managed through the campus Identity and Access Management systems and at no time will they be created in Active Directory by delegated administrators.

There are two types of Person Accounts:

- Unprivileged - Accounts created by the NetID system (students, faculty, and staff) or Manifest (university affiliates)
- Privileged - Accounts created by the Campus Active Directory service team to allow delegated administration of services such as Active Directory

## Unprivileged Accounts

The NetID user objects have been secured in such a way that one NetID user cannot view information contained in another NetID. This allows for compliance with the Federal Education Rights and Privacy Act (FERPA) and Campus policy. Requests for additional access to NetID information is subject to the approval of a UDS Access Request submitted to DoIT Middleware.

The use of NetID accounts will be limited to non-privileged user activities such as using email clients, accessing file shares, office suites, and web browsers. NetID accounts will not be granted administrative privileges on hosts or used to authenticate services or applications to Active Directory.

Users are required to comply with all Campus and NetID policies regarding the use and security of NetID passwords.

## Privileged

All Campus Active Directory administrators must have a separate account for performing Active Directory administration. This administrative account is to be used [strictly]{.underline} for [administrative]{.underline} purposes. This account is NOT to be used for day-to-day (normal) business, e.g. e-mail accounts are not to be tied to this account. All administrators will use their NetID account to logon to their workstations and use the RunAs command to connect to administrative applications, such as Active Directory Users and Computers.

### OU Owner / Admin Accounts

Campus Active Directory Service departmental administrators will have an OU Owner/OU Admin account created for them by the Service Team to be used as the secondary account. These accounts are used by the designated administrators to Create, delete, and manage Active Directory Objects within their Organizational Unit.

The OU Owner/Admin accounts have been authorized access to specific NetID information for the purpose of managing Active Directory. Sharing the OU Owner/Admin account with another user, utilizing the account to bind applications to AD, or running services/daemons is a violation of the Campus Responsible Use and UDS Data Access Policies. Failure to comply with these policies may result in the loss of delegated privileges within the Campus Active Directory Service.

### System Administrator Accounts

Department system administrators may have a System Administrator account created for use as a secondary account for those administrators that do not require delegated administrative rights in Active Directory.

Once the account is created it is the departmentâ€™s responsibility to provide the new user account administrator rights on hosts within the departmentâ€™s OU manually, by script, or with Group Policy.

## Non-Person Accounts

A non-person account is auser object created to represent a service, a group of people, or anonymous access.

These accounts are created in Active Directory by delegated CADS administrators for use within their department. These non-person accounts will not be used as person accounts for individual users.

### Service Accounts

A service account is a user object that corresponds to an application or a service instead of a person. Local accounts or system accounts (Local System, Local Service, and Network Service) shall be used whenever possible. If an application or service requires a domain service account a user account may be created for that purpose.

Password complexity and age will be controlled by a Fine Grained Password Policy that will be applied to the user object though membership in the appropriate security group. Passwords shall be maintained in a secure location and only accessible to authorized personnel.

Service accounts will only be used for the documented purpose of that account and shall not be used for Interactive logon at any time. Service accounts shall not be used for multiple services or in any way that provides NetID data access to an undocumented service or application. Separate service accounts shall be created for each function of a service or application.

Service account user objects will comply with established naming conventions and will be assigned only the rights and permissions necessary. If a department has an application or service that requires access to NetID data a UDS request must be submitted to Middleware for approval. Once the request has been approved, a service account will be created and the delegation will be performed.

### Organizational Accounts

An organizational account is an account that is shared by a group to access department resources.

These accounts will be limited to non-privileged user activities such as using email clients, accessing file shares, office suites, and web browsers. Organizational accounts will not be granted administrative privileges on hosts or used to authenticate services or applications to Active Directory.

Password complexity and age will be controlled by a Fine Grained Password Policy that will be applied to the user object though membership in the appropriate security group.

## References

- [Responsible Use of University of Wisconsin â€" Madison Information Technology Resources](http://www.cio.wisc.edu/policies-responsibleuse.aspx)
- [Terms of Use for Campus Active Directory Service](https://cads.ad.wisc.edu/public/ptos.aspx)
