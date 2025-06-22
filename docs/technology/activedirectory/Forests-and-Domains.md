# Forests and Domains

Active Directory is primarily organized by forests and domains. In most cases a single forest and a single domain are necessary.

## Forest Structure

An ADforest is a collection of one or moreActive Directory domains organized into one or more trees. Forests serve two main purposes: to simplify user interaction with the directory, and to simplify the management of multiple domains.InActive Directory theforest is the boundary of the security context boundary similar to domains in an NT4 environment.

Forests have the following key characteristics:

- Single Schema
- Single Configuration Container
- Complete Trust
- Single Global Catalog
- Users Search the Global Catalog
- Users can log on using User Principal Names

A single forest environment is simple to create, manage and maintain. The cost of managing a single forest is significantly lower than multiple forests. All users see a single directory through the global catalog and do not need to be aware of any directory structure.Forest level configuration changes only need to be applied once to affect all domains.

### Setting up Empty Root Domain -- Microsoft research Academic Computing Report

- Each domain incurs a number of additional costs, both in terms of duplicated hardware and software, but also additional administrative work. Many of the costs are hidden:*
- System administrators must manage extra complexity. For instance, the effort required to move a student between two departmental domains is significantly greater than between two organizational units (OUs), especially if the departments have different IT infrastructures or procedures.
- Duplicated hardware and personnel resources are required, as every departmental domain must provide redundancy, 24/7 support, fault tolerance, backup solutions, etc.
- Multiple domain controllers for every subdomain are required at sites.
- Specialized skills are not shared efficiently. For instance, separate domains must each have administrators who understand directory services, security, and a number of other issues. A central authority in a single domain model could handle many of these issues using fewer resources.

- You should carefully weigh the costs of adding extra domains. Do not create multiple domains out of habit -- many of the reasons for creating domains under Windows NT do not exist under Windows 2000. For instance, the restriction on the number of objects within a Windows NT domain does not apply to Windows 2000 domains.

### Additional Forests

Additional forests will only be created in situations where:

- Resources that require Active Directory need to be secured in a DMZ
- Separation of data for security, compliance, or privacyreasons is required (HIPAA, PCI, classified research)

## Domain Structure

An Active Directory Domain is a collection of users, groups, and computers that share a common security context.

A Single Domain Design should be used for the following reasons:

- Less complex to design, implement, manage, and troubleshoot
- No trust links to create, manage, or have fail
- No Global Catalog placement issues (Each DC already has all of the AD database)
- Lower TCOdue toless hardware, fewer licenses, fewer backups to perform, and less patching for Domain Controllers
- It is easier to change Organizational Unit structure than it is to change domains in the event of a reorganization
- Objects can be move between OUs more easily than between domains

Additional domains will be created only in the following cases:

- Extremely low bandwidth between two large sites (The Global Catalog accounts for nearly 55% of replication traffic)
- Department or organization that cannot work within the policies that are domain wide
- Separate DNS name is required and multiple name records (split DNS) is not acceptable

```text
"Politics is the number one reason organizations tend to end up with multiple domains, not because of valid technical or security considerations" 
--Jason Fossen SANS.org
```

### The following is from a Microsoft Whitepaper called "Setting up an Empty Root Domain"

```text
(Pg 10)
The empty root domain is not suitable for all situations. In particular, if departments are amenable to working together, and dividing responsibility and control using organizational units, a single domain model may be preferred.
```

```text
(Pg 11)

Almost all of the administrative delegation, separation and protection that can be done using an empty root domain can also be done under the single domain model using organizational units.

- Reduced hardware and software costs to setup and operate a single domain compared to multiple domains. Multiple domains require needless duplication of resources in each domain.
- Increased flexibility for future changes. OUs can be created, changed and moved more easily than domains.
- Increased flexibility to support roaming user populations
- Reduced effort to administer policies. Group policy, security settings and access control do not flow automatically between domains in a tree. In particular, group policy objects (GPOs) cannot be applied across domain boundaries. In a single domain, managing policies is much easier.
- Security principals can be moved between departments more easily. Moving between OUs is trivial, while moving between domains is not. To move a user between two domains requires cooperation between domain administrators and may require administrators to move settings and data manually.

The simplicity of the single domain model is compelling and should always be given serious consideration. In general, political and not technical decisions cause organizations not to use the single domain model.
```

```text
(Pg 19)

Subdomains should not be created without good reason. Each domain added to the forest or tree results in additional administrative workload and required computer resources. Some of the extra costs associated with domains include:

- Additional domain controllers are required - Each domain requires at least two domain controllers, and the administrative staff to support them.
- 24/7 availability - Departments setting up subdomains must provide hardware and administrators to provide 24/7availability. Problems in the subdomain can have forest wide consequences so must be fixed prompttly.
- Secure domain controllers -Domain controllers must be physically secured and administrator accounts properly restricted and managed. A security breach on a domain controller can jeopardize the security of the forest.

...almost all decentralization that can be done with domains could also be done with OUs in a single domain, at far lower cost.
```

## Domain Names

Two names are associated with each domain, DNS and NetBIOS. The DNS name for each domain make a unique reference to each domain. The DNS name should be a sub domain of a domain name registered to the organization. NetBIOS names will have to be unique within a forest and are most often seen and used by users when authenticating to a particular domain.

Current AD forest names for production and pre-production are MATC.Madison.Login and MATC.ts.test respectively. While these types of "local" DNS names were acceptable, even encouraged by Microsoft, at one time they are no longer acceptable. This is primarily due to a change made by all publicly trusted certificate authorities which prevent the issuance of x509 certificates that contain these type of local names.

For that reason, DNS names used for AD forests in the future should be sub-domains of the publicly resolvable domain name owned and used by the College for other services. Listed below are the NetBIOS and DNS names for production and pre-production AD forests located internally or in the DMZ.
