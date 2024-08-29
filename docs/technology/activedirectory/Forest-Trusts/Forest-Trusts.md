# Forest Trusts

## Summary

The Campus Active Directory Service allows participating departments to take advantage of centralized NetID-based authentication and authorization while allowing for delegated administration of local resources. As we move towards centralizing our directory services, trusts will be important to the migration process as well as providing continuity of operations during the cleanup. The existence of external forest trusts will be vital to sharing enterprise resources with departments and organizations that fall out of scope of Campus Active Directory and require more than the federation of web applications.

## Scope

While this document discusses all available trusts for completeness, only external, forest and realm trusts are within scope. Parent/Child, Tree-root, and Shortcut trusts are created for performance reasons only and do not have any security implications.

## Guiding Principals in trust relationships

- Compliance with University of Wisconsin - Madison policies and standards - The CADS forest will comply with all UW Madison and UW Systems policies and standards.
- Follow industry standard practices where possible
  - Where possible, the CADS forest will leverage industry standard practices in baseline configurations
  - The adherence to well known or proven practices to create a secure environment while maintaining ease of use
- Requests for trusts with CADS will be reviewed and approved only when the requesting organization has an established relationship with UW-Madison or UW System and only for as long as the trust is required
- Approved trusts will be periodically audited and removed if determined to be no longer necessary
- Whenever possible, one-way trusts should be chosen over two-way trusts
- Whenever possible, non-transitive trusts should be chosen over transitive trusts

## Business Cases where Trust Relationships will be needed

Case 1: A departments in the process of migrating to CADS will require a trust to accomplish migration.

Case 2: A department that anticipates a near term migration to CADS, but that cannot move immediately may benefit from a trust to allow for making the transition to NetID authentication while working out any other barriers to immediate migration. Reasons a department might not be capable of moving to CADS immediately include time needed for some measure of internal right-sizing or alignment necessary for inclusion in CADS, coordination with other trusts, or because scheduling of CADS assisted migration requires a waiting period.

Case 3: Avoid possible collisions between departments that may run enterprise applications that require conflicting schema extensions. This would also allow departments to run applications that require Active Directory changes that CADS governance is unwilling or unable to approve.

Case 4: UW System applications, such as HRS and ISIS, may require trusts to AD forests in other campuses once those applications are migrated to CADS.

Case 5: Organizations loosely affiliated with UW - Madison (UW Foundation, WID, WHS, etc) may have a need to access core campus services or resources.

## Trust Types

### Temporary Trusts

(Business Case 1 and 2)

Short-term temporary trusts may be approved for the purpose of migration. A short-term trust that is approved will be active for 180 days from the creation date and are eligible for a one time extension of an additional 180 days. Short-term trusts may be one-way non-transitive or two-way non-transitive trust. The department requesting the temporary trust will be provisioned as a new CADS customer and expected to perform migration operations during the life of the trust.

Long-term temporary trusts may be approved for groups that anticipate a near term migration, but that cannot move immediately. A long-term trust that is approved will be active for 365 days from the creation date and are eligible for a one time extension of an additional 180 days. Long-term trusts may only be one-way non-transitive. Such a relationship will allow for making the transition to NetID authentication while working out any other barriers to immediate migration.

Reasons a department might not be capable of moving to CADS immediately include time needed for some measure of internal right-sizing or alignment necessary for inclusion in CADS, coordination with other trusts, or because scheduling of CADS assisted migration requires a waiting period. Once ready to perform the migration the department may request a two-way trust which will then be valid for 180 days and eligible for one additional 180 day extension. The department will be provisioned as a new CADS customer and expected to perform migration operations during the life of the trust.

### Persistent Trusts

(Business Case 3,4, and 5)

Persistent trusts may be approved for long-term projects, collaboration with off-Campus organizations, and Campus organizations that are unable to migrate to Campus Active Directory for technical reasons. The domain name of the Active Directory forest must be able to be resolved recursively by the Campus DNS. All permanent trusts will require governance approval and will be subject to periodic auditing by the Office of Campus Information Security. Any trusts that are found to be out of compliance with established policies will be removed.

## Requirements for Creating and Maintaining Trusts

### All Trusts

- Any business cases not previously defined must be approved by CADS Governance and DoIT Security
- Will be subject to audit for technical controls and documentation prior to approval
- All required documentation must be completed
- Customer domain controller must meet or exceed the technical requirements listed below
- Established trusts will be periodically audited by Security
- All responsible parties must agree and adhere to terms of service
- Trusts that are not compliant with service standards will be removed

### One-Way and Two-Ways Trusts

- CADS - Trusted / Customer Domain - Trusting (One-Way)
  - Non-transitive
  - Customer may choose to implement Selective Authentication or SID filtering
  - Persistant trusts may be approved by governance
- Customer Domain - Trusted / CADS - Trusting (One-Way or part of Two-Way)
  - Non-transitive
  - CADS service team will implement Selective Authentication and SID filtering
  - Temporary trusts only
  - Approved for migration purposes only

## Terminology and Definitions

### Active Directory Trusts

AD trust relationships are an inherent part of domain and forest architecture. Trusts are the mechanism for allowing a user to authenticate to one domain and access resources in another domain without authenticating again. Establishing a trust relationship outside a forest makes one or both participants dependent on the security practices of the other. For a forest trust, the trusting forest is relying on the identification and authentication practices in the trusted forest.

The amount of risk to security that either forest or domain is exposed to is determined by a combination of the trust type, direction, and transivity. By configuring trusts according to the need of both organizations risk can br significantly lowered to a reasonable level. That risk can be further mitigated by implementing additional technical controls and periodic auditing.

### Trust Types

**Default Trusts** - These trusts are created automatically when new domains are created in the same forest. These types of trusts are out of scope for this document and are only included for completeness.

- Parent and child - By default, when a new child domain is added to an existing domain tree, a new parent and child trust is established. Authentication requests made from subordinate domains flow upward through their parent to the trusting domain.
- Tree-root - By default, when a new domain tree is created in an existing forest, a new tree-root trust is established.

| **Trust type** | **Transitivity** | **Direction** | **Authentication** | **SID Filtering** |
|----------------|-------------|-----------|-----------------|----------------|
| Parent and child | Transitive | Two-way | Not Recomended | Not Recomended |
| Tree-root | Transitive | Two-way | Not Recomended | Not Recomended |

**Other Trusts** - These trusts are created manually using the New Trusts wizard or the Netdom command.

- External - An external trust can be created between two domains in different forests or between an AD domain and a Windows NT domain.
- Forest - A forest trust can be created between the forest root domains of two forests and allows authentication between all domains in either forest.
- Shortcut - A shortcut trust can be defined between two domains in the same forest. A shortcut trust is used where the trust path is long or network connections between domain controllers in the trust path cannot efficiently support the authorization traffic.
- Realm - A realm trust can be created between a domain and a non-Windows system such as a system hosting a UNIX or Linux OS with Kerberos version 5.

| Trust Type | Transitivity | Direction | Authentication | SID Filtering |
| External   | Non-Transitive | One-way | Domain-wide or selective | Enabled or Disabled |
| Forest     | Transitive (within forests) | One-way or two-way | Forest-wide or selective |Enabled or Disabled |
| Shortcut | Partial | One-way or two-way | N/A | N/A |
| Realm | Either (With supporting partner) | One-way | N/A | N/A |

### Trust Direction

A trust provides an authentication path between the "trusted" forest/domain and the trusting forest/domain. Security pricipals in the trusted side of the trust can access resources on the trusting side of the trust. This means that the trusting organization is relying on the identity proofing standards used in the trusted organization.

- One-Way - Provides a unidirectional authentication path between two organizations. A one-way trust between organizations "A" and "B" where "A" is the trusting domain and "B" is a trusted domain would allow users in domain "B" to access resources in domain "A". This would trust would not allow any users in domain "A" access to resources in domain "B"
- Two-Way - Provide a bidirectional authentication path between two organizations. A two-way trust is simply two one-way trusts between the same two organizations in oposite directions.

### Trusts Transivity

Transivity determines the scope of the authentication path beyond the domains that explicitly trust each other.

- Transitive - If domain "A" has a transitive trust with domain "B" and domain "B" has a transitive trust with domain "C", domain "A" will also trust domain "C" despite there not being an explicit trust between domain "A" and domain "C."
- Non-Transitive - If the trusts between domains "A" and "B" and between "B" and "C" are non-transitive domain "A" will not trust domain "C."

## Security

### Selective Authentication

Selective Authentication allows more granular control of access trusted forests have resources. Selective authentication is implemented per computer by setting an additional permission on the AD computer object:

- The trust Authentication property defaults to a value that allows all users in the trusted forest or domain to be authenticated via the trust. Selective authentication must be enabled on the trust.
- The Allowed to Authenticate permission for AD computer objects is not set by default.

The Allowed to Authenticate permission can be set to Allow or Deny for specific users or groups. When an external or forest trust has the Selective authentication option set and a user from a trusted forest or domain attempts to access an object, the Allowed to Authenticate permission on the computer object in the trusting domain is checked. If the permission is set to Allow, access is permitted.

### SID Filtering

SID filtering should be enabled on all trusts to prevent administrators in trusted domains from using the SID history feature to elevate their level of access in the trusted domain. The SID history feature is used by migration tools to facilitate the migration of user accounts without significant impact to resource access in either domain. Trusts that are created for the purpose of migration will not be able to use SID filtering because it will remove the ability to use SID history. Enabling SID filtering will remove any SIDs from the authentication request that are not associated with the originating domain.

## Documentation

Because trust relationships effectively eliminate a level of authentication in the trusting domain or forest, they represent less stringent access control at the domain or forest level in which the resource resides. To mitigate this risk, trust relationships should be documented so that they can be readily verified during periodic inspections designed to validate that only approved trusts are configured.

## Required Information

- Domain Name (NetBIOS/FQDN)
- Classification
- Defined Trusts
  - Type (Forest, Domain, Realm)
  - Other Domain/Forest (NetBIOSFQDN)
  - Classification (Production, Test, Research)
  - Direction (Incoming, Outgoing, Both)
  - Transitive (Y, N)
  - Selected Authentication (Y, N, N/A) *
  - SID Filtering (Y, N) **
  - Reason for Trust

***** Selective Authentication is not applicable (N/A) for realm trusts or any incoming trusts.

** SID Filtering is not applicable (N/A) for realm trusts or any incoming trusts.

## Example Trust Documentation

**Domain Name (NetBIOS/FQDN):** AD / ad.doit.wisc.edu

**Classification:** Production

**Trusts Defined:**

| **Type** | **Other Domain/Forest** (NetBIOS / FQDN) | **Duration**(Temporary Short-term Temporary Long-term Persistent) | **Direction** | **Transitive** | **Selected Auth** | **SID Filtering** |
|-------|---------------|-------------------|--------|---------|---------|--------|
| Realm | LOGIN / LOGIN.WISC.EDU | Temporary Short-Term | Both | Y | N/A | N/A |
| Forest | BFS / bfs.uwm.local | Persistent | Outgoing | N | N | N/A |
| Forest | UWP / uwp.wisc.edu | Persistent | Outgoing | N | Y | N/A |
| Forest | UWC / uwc.net | Persistent | Outgoing | N | N | N/A |

**Reason for Trust:**

| Other Domain/Forest (NetBIOS / FQDN) | Access Requirements | Point of Contact |
|--------------------------------------|---------------------|------------------|
| LOGIN / LOGIN.WISC.EDU  Provides NetID authentication to DoIT Active Directory Forest | Mark Weber DoIT Middleware (```mgweber@wisc.edu```) |
| BFS / bfs.uwm.local | UW-Milwaukee access to SFS | Eric Skibicki UW Milwaukee(```skibicke@uwm.edu```) |
| UWP / uwp.wisc.edu | UW-Parkside access to SFS | Tony Brzoskowski UW Parkside(```brzoskow@uwp.edu```) |
| UWC / uwc.net | UW Systems access to SFS | Jeff Harrison UW Systems (```jeff.harrison@uwex.uwc.edu```) |

## Requirements for Creating and Maintaining Trusts

### Temporary Trusts

Temporary trusts may be approved for the purpose of migration. The authorization for these temporary trusts will be valid for 90 days from the date of approval. At the completion of 90 days the trust will be terminated unless an extension is requested and approved. Temporary trusts may be one-way incoming or two-way if necessary to facilitate Active Directory migrations. All temporary trusts will be non-transitive.

### Persistent Trusts

Persistent trusts may be approved for long-term projects, collaboration with off-Campus organizations, and Campus organizations that are unable to migrate to Campus Active Directory for technical reasons. The domain name of the Active Directory forest must be able to be resolved recursively by the Campus DNS. All permanent trusts will be subject to periodic auditing by the Office of Campus Information Security. Any trusts that are found to be out of compliance with established policies will be removed.

### All Trusts

- Business case must be approved by CADS Governance and DoIT Security
- All documentation must be completed
- Any trust related traffic traversing non-UW networks must be encrypted by IPSec or carried over IPSec encrypted tunnels
- Established trusts will be periodically audited by DoIT Security
- Trusts that are not compliant with service standards will be removed

### One-Way and Two-Ways Trusts

- CADS - Trusted / Customer Domain - Trusting (One-Way)
  - Non-transitive
  - Customer may choose to implement Selective Authentication or SID filtering
  - Persistant trusts may be approved
- Customer Domain - Trusted / CADS - Trusting (One-Way or part of Two-Way)
  - Non-transitive
  - CADS service team will implement Selective Authentication and SID filtering
  - Temporary trusts only
  - Approved for migration purposes only

For an Active Directory forest to be eligible for a one-way non-transitive trust with Campus Active Directory it must meet a list of requirements.

Implementation of the security requirements in the trusting forest are the responsibility of the customer's Active Directory administrators. Reasonable effort must be made by the customer administrators to research the effects of these changes on their environment and to implement them in a way consistent with the customer's change management process.

## Glossary

- Parent and child trust - By default, when a new child domain is added to an existing domain tree, a new parent and child trust is established. Authentication requests made from subordinate domains flow upward through their parent to the trusting domain.
- Tree-root trust - By default, when a new domain tree is created in an existing forest, a new tree-root trust is established.
- External trust - An external trust can be created between two domains in different forests or between an AD domain and a Windows NT domain.
- Forest trust- A forest trust can be created between the forest root domains of two forests and allows authentication between all domains in either forest.
- Shortcut trust- A shortcut trust can be defined between two domains in the same forest. A shortcut trust is used where the trust path is long or network connections between domain controllers in the trust path cannot efficiently support the authorization traffic.
- Realm trust - A realm trust can be created between a domain and a non-Windows system such as a system hosting a UNIX or Linux OS with Kerberos version 5.
- Transitive trust - If domain "A" has a transitive trust with domain "B" and domain "B" has a transitive trust with domain "C", domain "A" will also trust domain "C" despite there not being an explicit trust between domain "A" and domain "C."
- Non-Transitive trust - If the trusts between domains "A" and "B" and between "B" and "C" are non-transitive domain "A" will not trust domain "C."

## References

- [Center for Internet Security](http://www.cisecurity.org/)
- [Campus Active Directory Service Request](https://cads.ad.wisc.edu/)
- Campus Active Directory Domain Controller Security Settings
- [Client, service, and program issues can occur if you change security settings and user rights assignments (MS TechNet)](http://support.microsoft.com/kb/823659)
- [Domain and Forest Trusts Technical Reference (MS TechNet)](http://technet.microsoft.com/en-us/library/cc738955(v=ws.10).aspx)
- [Understanding Trusts (MS TechNet)](http://technet.microsoft.com/en-us/library/cc736874(v=ws.10).aspx)
- [Active Directory Domains and Trusts (MS TechNet)](http://technet.microsoft.com/en-us/library/cc770299.aspx)
- [Enable Selective Authentication over a Forest Trust (MS TechNet)](http://technet.microsoft.com/en-us/library/cc794747%28v=ws.10%29.aspx)
- [Grant the Allowed to Authenticate Permission on Computers in the Trusting Domain or Forest (MS TechNet)](http://technet.microsoft.com/en-us/library/cc816733%28v=ws.10%29.aspx)
