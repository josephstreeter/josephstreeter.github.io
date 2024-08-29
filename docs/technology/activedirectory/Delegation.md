# Delegation

Created: 2019-05-12 21:50:22 -0500

Modified: 2019-05-13 11:27:48 -0500

---

## Security descriptors

Access control permissions are assigned to shared objects and Active Directory objects to control how different users can use each object. A shared object, or shared resource, is an object that is intended to be used over a network by one or more users and includes files, printers, folders, and services. Both shared objects and Active Directory objects store access control permissions in security descriptors.

A security descriptor contains two access control lists (ACLs) used to assign and track security information for each object: the discretionary access control list (DACL) and the system access control list (SACL).

- **Discretionary access control lists (DACLs).**DACLs identify the users and groups that are assigned or denied access permissions on an object. If a DACL does not explicitly identify a user, or any groups that a user is a member of, the user will be denied access to that object. By default, a DACL is controlled by the owner of an object or the person who created the object, and it contains access control entries (ACEs) that determine user access to the object.
- **System access control lists (SACLs).**SACLs identify the users and groups that you want to audit when they successfully access or fail to access an object. Auditing is used to monitor events related to system or network security, to identify security breaches, and to determine the extent and location of any damage. By default, a SACL is controlled by the owner of an object or the person who created the object. A SACL contains access control entries (ACEs) that determine whether to record a successful or failed attempt by a user to access a object using a given permission, for example, Full Control and Read.

## Delegation of Rights

Delegation allows users to perform the Active Directory related tasks that are required of them without giving them blanket administrative rights. The ability to implement and maintain delegations requires planning and perhaps some coordination with administrators that implement Group Policy.
