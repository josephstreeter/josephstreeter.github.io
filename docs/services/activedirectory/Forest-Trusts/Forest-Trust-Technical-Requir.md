# Forest Trust Technical Requirements

## Summary

Before a Forest Trust can be created between a department's Active Directory forest and Campus Active Directory an audit must be performed by OCIS/DoIT Security. This audit will verify that all security requirements listed below have been configured correctly.

Implementation of the security requirements in the trusting forest are the responsibility of the customer's Active Directory administrators. Reasonable effort must be made by the customer administrators to research the effects of these changes on their environment and to implement them in a way consistent with the customer's change management process.

- A CADS Trusts request must be completed and approved by the Office of Campus Information Security (OCIS)
- Domain and Forest level must be WS 2003 or higher
- The following Security policies must be configured on all domain controllers:
  - Publicly trusted server certificates installed
  - "Network security: Do not store LAN Manager hash value on next password change" - Enabled
  - "Network security: LDAP client signing requirements" - Require Signing
  - "Network security: LAN Manager authentication level" - Send NTLMv2 response only. Refuse LM & NTLM
  - "Domain Controller: LDAP Server signing requirements" - Require Signing
- IPsec must be implemented for all traffic between CADS domain controllers and the trusting forest's domain controllers when traffic traverses non-Campus networks
- Name resolution must be successfully verified between the CADS domain controllers and the trusting forest's domain controllers
- Campus Active Directory Service names are resolvable through Campus DNS

Click [here](https://kb.wisc.edu/page.php?id=34954) to view the KB article explaining how to enable LDAPS on AD Domain Controllers

### IPsec Policy

IPSec Rules: CADS Forest Trust Traffic

| Name | Description | Mode(Transport or Tunnel IP) | IP Filter List | Filter Action List | Network Type | Authentication Method |
|-------|-----------|----------------|-------|----------|---------|--------------|
| CADS | Forest trust traffic | Transport | DCs | ESP-3DES-SHA1-0-3600 | LAN | PSK |

### CADS Domain Controllers

| Name | Src Address | Dest Address | Protocol | Src Port | Dest Port | Mirrored |
|--------------|-------------|------------|---------|---------|---------|--------|
| CADSDC-CSSC-01 | 144.92.104.16 | My IP Address | ANY | ANY | ANY | Y |
| CADSDC-CSSC-02 | 144.92.104.17 | My IP Address | ANY | ANY | ANY | Y |
| CADSDC-CSSC-03 | 144.92.104.18 | My IP Address | ANY | ANY | ANY | Y |

### Filter Actions

| Name | Description | Filter Action Behavior | Security Method | AH | ESP | Session Key Lifetimes (sessions/seconds) | Accept Clear | Allow Fallback | Use PFS |
|------|---------|--------|-------|-----|---------|-------------|------|-------|-----|
| ESP-3DES-SHA1-0-3600 | Require ESP 3DES/SHA1, no inbound clear, no fallback to clear, No PFS | Negotiate Security | Custom | N/A | 3DES/SHA1 | 0 / 3600 | N | N | N |

### Recommendations

The following configurations are not required, but are recommended for all trusting forests

- Domain Controllers meet or exceed Center for Internet Security Benchmarks (Enterprise or SSLF)
- Request a delegation in Campus DNS for customer Active DirectoryDNS name
- The following settings applied to all Member servers and workstations:
  - "Network security: LDAP client signing requirements" - Require Signing
  - "Network security: LAN Manager authentication level" - Send NTLMv2 response only. Refuse LM & NTLM

## Glossary

- Parent and child trust - By default, when a new child domain is added to an existing domain tree, a new parent and child trust is established. Authentication requests made from subordinate domains flow upward through their parent to the trusting domain.
- Tree-root trust - By default, when a new domain tree is created in an existing forest, a new tree-root trust is established.
- External trust - An external trust can be created between two domains in different forests or between an AD domain and a Windows NT domain.
- Forest trust- A forest trust can be created between the forest root domains of two forests and allows authentication between all domains in either forest.
- Shortcut trust- A shortcut trust can be defined between two domains in the same forest. A shortcut trust is used where the trust path is long or network connections between domain controllers in the trust path cannot efficiently support the authorization traffic.
- Realm trust - A realm trust can be created between a domain and a non-Windows system such as a system hosting a UNIX or Linux OS with Kerberos version 5.
- Transitive trust - If domain "A" has a transitive trust with domain "B" and domain "B" has a transitive trust with domain "C", domain "A" will also trust domain "C" despite there not being an explicit trust between domain "A" and domain "C."
- Non-Transitive trust - If the trusts between domains "A" and "B" and between "B" and "C" are non-transitive domain "A" will not trust domain "C."

### References

- [Center for Internet Security](http://www.cisecurity.org/index.md)
- [Campus Active Directory Service Request](https://cads.ad.wisc.edu/index.md)
- Campus Active Directory Domain Controller Security Settings
- [Client, service, and program issues can occur if you change security settings and user rights assignments (MS TechNet)](http://support.microsoft.com/kb/823659)
- [Domain and Forest Trusts Technical Reference (MS TechNet)](http://technet.microsoft.com/en-us/library/cc738955(v=ws.10).aspx)
- [Understanding Trusts (MS TechNet)](http://technet.microsoft.com/en-us/library/cc736874(v=ws.10).aspx)
- [Active Directory Domains and Trusts (MS TechNet)](http://technet.microsoft.com/en-us/library/cc770299.aspx)
- [Enable Selective Authentication over a Forest Trust (MS TechNet)](http://technet.microsoft.com/en-us/library/cc794747%28v=ws.10%29.aspx)
- [Grant the Allowed to Authenticate Permission on Computers in the Trusting Domain or Forest (MS TechNet)](http://technet.microsoft.com/en-us/library/cc816733%28v=ws.10%29.aspx)
