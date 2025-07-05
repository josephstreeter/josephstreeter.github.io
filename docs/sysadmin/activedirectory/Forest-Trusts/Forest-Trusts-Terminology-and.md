# Forest Trusts Terminology and Definitions

## Summary

AD trust relationships are an inherent part of domain and forest architecture. Trusts are the mechanism for allowing a user to authenticate to one domain and access resources in another domain without authenticating again. Establishing a trust relationship outside a forest makes one or both participants dependent on the security practices of the other. For a forest trust, the trusting forest is relying on the identification and authentication practices in the trusted forest. The amount of risk to security that either forest or domain is exposed to is determined by a combination of the trust type, direction, and transivity. By configuring trusts according to the need of both organizations risk can br significantly lowered to a reasonable level. That risk can be further mitigated by implementing additional technical controls and periodic auditing.

## Trust Types

Default Trusts - These trusts are created automatically when new domains are created in the same forest. These types of trusts are out of scope for this document and are only included for completeness.

- Parent and child - By default, when a new child domain is added to an existing domain tree, a new parent and child trust is established. Authentication requests made from subordinate domains flow upward through their parent to the trusting domain.
- Tree-root - By default, when a new domain tree is created in an existing forest, a new tree-root trust is established.

| **Trust type** | **Transitivity** | **Direction** | **Authentication** | **SID Filtering** |
|----------------|-------------|-----------|-----------------|----------------|
| Parent and child | Transitive | Two-way | Not Recomended | Not Recomended |
| Tree-root | Transitive | Two-way | Not Recomended | Not Recomended |

Other Trusts - These trusts are created manually using the New Trusts wizard or the Netdom command.

- External - An external trust can be created between two domains in different forests or between an AD domain and a Windows NT domain.
- Forest - A forest trust can be created between the forest root domains of two forests and allows authentication between all domains in either forest.
- Shortcut - A shortcut trust can be defined between two domains in the same forest. A shortcut trust is used where the trust path is long or network connections between domain controllers in the trust path cannot efficiently support the authorization traffic.
- Realm - A realm trust can be created between a domain and a non-Windows system such as a system hosting a UNIX or Linux OS with Kerberos version 5.

<table>
<colgroup>
<col style="width: 13%" />
<col style="width: 31%" />
<col style="width: 22%" />
<col style="width: 18%" />
<col style="width: 13%" />
</colgroup>
<thead>
<tr>
<th><strong>Trust Type</strong></th>
<th><strong>Transitivity</strong></th>
<th><strong>Direction</strong></th>
<th><strong>Authentication</strong></th>
<th><strong>SID Filtering</strong></th>
</tr>
</thead>
<tbody>
<tr>
<td>External</td>
<td>Non-Transitive</td>
<td>One-way</td>
<td><p>Domain-wide</p>
<p>or selective</p></td>
<td><p>Enabled</p>
<p>or Disabled</p></td>
</tr>
<tr>
<td>Forest</td>
<td>Transitive (within forests)</td>
<td>One-way or two-way</td>
<td><p>Forest-wide</p>
<p>or selective</p></td>
<td><p>Enabled</p>
<p>or Disabled</p></td>
</tr>
<tr>
<td>Shortcut</td>
<td>Partial</td>
<td>One-way or two-way</td>
<td>N/A</td>
<td>N/A</td>
</tr>
<tr>
<td>Realm</td>
<td>Either (With supporting partner)</td>
<td>One-way</td>
<td>N/A</td>
<td>N/A</td>
</tr>
</tbody>
</table>

## Trust Direction

A trust provides an authentication path between the "trusted" forest/domain and the trusting forest/domain. Security pricipals in the trusted side of the trust can access resources on the trusting side of the trust. This means that the trusting organization is relying on the identity proofing standards used in the trusted organization.

- One-Way - Provides a unidirectional authentication path between two organizations. A one-way trust between organizations "A" and "B" where "A" is the trusting domain and "B" is a trusted domain would allow users in domain "B" to access resources in domain "A". This would trust would not allow any users in domain "A" access to resources in domain "B"
- Two-Way - Provide a bidirectional authentication path between two organizations. A two-way trust is simply two one-way trusts between the same two organizations in oposite directions.

## Trusts Transivity

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
- [Client, service, and program issues can occur if you change security settings and user rights assignments (MS TechNet)](http://support.microsoft.com/kb/823659)
- [Domain and Forest Trusts Technical Reference (MS TechNet)](http://technet.microsoft.com/en-us/library/cc738955(v=ws.10).aspx)
- [Understanding Trusts (MS TechNet)](http://technet.microsoft.com/en-us/library/cc736874(v=ws.10).aspx)
- [Active Directory Domains and Trusts (MS TechNet)](http://technet.microsoft.com/en-us/library/cc770299.aspx)
- [Enable Selective Authentication over a Forest Trust (MS TechNet)](http://technet.microsoft.com/en-us/library/cc794747%28v=ws.10%29.aspx)
- [Grant the Allowed to Authenticate Permission on Computers in the Trusting Domain or Forest (MS TechNet)](http://technet.microsoft.com/en-us/library/cc816733%28v=ws.10%29.aspx)
