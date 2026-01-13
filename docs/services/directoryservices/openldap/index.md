---
title: "OpenLDAP"
description: "Documentation for OpenLDAP directory services implementation, configuration, and management"
tags: ["openldap", "ldap", "directory-services", "authentication", "linux"]
category: "services"
difficulty: "intermediate"
last_updated: "2026-01-13"
author: "Joseph Streeter"
---

This section covers OpenLDAP directory services implementation, configuration, and management.

## Overview

OpenLDAP is an open-source implementation of the Lightweight Directory Access Protocol (LDAP), providing a robust, enterprise-ready directory service for authentication, authorization, and information management. As a standards-compliant LDAP server, it implements RFC 4510 and related specifications, making it suitable for Linux, Unix, and cross-platform directory service deployments.

### What is LDAP?

LDAP (Lightweight Directory Access Protocol) is an industry-standard application protocol for accessing and maintaining distributed directory information services over IP networks. LDAP is defined in RFC 4510 and provides a hierarchical database optimized for read-heavy operations, making it ideal for storing organizational information, user credentials, access control policies, and configuration data.

### LDAP vs Relational Databases

LDAP directories differ fundamentally from relational databases:

| Characteristic | LDAP Directory | Relational Database |
| --- | --- | --- |
| **Data Structure** | Hierarchical tree | Tables with rows |
| **Read/Write Ratio** | Optimized for reads (90%+ reads) | Balanced read/write |
| **Query Language** | LDAP filters | SQL |
| **Schema** | Flexible, extensible | Rigid, normalized |
| **Replication** | Multi-master, consumer | Master-slave, clustering |
| **Use Cases** | Identity, authentication, org data | Transactions, business data |
| **Data Model** | Object-oriented (entries, attributes) | Relational (tables, columns) |

### LDAP Protocol Fundamentals

#### Directory Information Tree (DIT)

LDAP organizes data in a hierarchical tree structure called the Directory Information Tree:

```text
dc=example,dc=com (root)
├── ou=people
│   ├── cn=John Smith
│   ├── cn=Jane Doe
│   └── cn=Bob Johnson
├── ou=groups
│   ├── cn=administrators
│   ├── cn=developers
│   └── cn=users
└── ou=services
    ├── cn=mail
    └── cn=web
```

Each node in the tree is called an **entry**, and entries are identified by their **Distinguished Name (DN)**, which represents the full path from the entry to the root.

#### Distinguished Names (DN)

A DN uniquely identifies an entry in the directory:

```text
cn=John Smith,ou=people,dc=example,dc=com
```

Components of a DN:

- **cn** (Common Name) - Person or object name
- **ou** (Organizational Unit) - Department or division
- **dc** (Domain Component) - DNS domain parts
- **uid** (User ID) - Unique user identifier
- **o** (Organization) - Organization name

#### Relative Distinguished Name (RDN)

The RDN is the leftmost component of the DN that makes the entry unique within its parent:

```text
DN:  cn=John Smith,ou=people,dc=example,dc=com
RDN: cn=John Smith
```

### LDAP Entry Structure

Each entry consists of:

1. **Distinguished Name (DN)** - Unique identifier
2. **Object Classes** - Define what attributes the entry can have
3. **Attributes** - Key-value pairs storing actual data

Example entry:

```ldif
dn: cn=John Smith,ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: top
cn: John Smith
sn: Smith
givenName: John
mail: john.smith@example.com
uid: jsmith
userPassword: {SSHA}encrytedPasswordHash
```

### LDAP Operations

LDAP defines nine core operations:

| Operation | Purpose | RFC Section |
| --- | --- | --- |
| **Bind** | Authenticate to the directory | RFC 4511 §4.2 |
| **Unbind** | Terminate the session | RFC 4511 §4.3 |
| **Search** | Query directory entries | RFC 4511 §4.5 |
| **Compare** | Check if attribute matches value | RFC 4511 §4.10 |
| **Add** | Create new entry | RFC 4511 §4.7 |
| **Delete** | Remove entry | RFC 4511 §4.8 |
| **Modify** | Change entry attributes | RFC 4511 §4.6 |
| **Modify DN** | Rename or move entry | RFC 4511 §4.9 |
| **Extended** | Custom operations | RFC 4511 §4.12 |

### LDAP Search Filters

LDAP uses filters to query the directory. Filter syntax follows RFC 4515:

**Basic Filters:**

```text
(attribute=value)           Equality
(attribute>=value)          Greater than or equal
(attribute<=value)          Less than or equal
(attribute=value*)          Substring (starts with)
(attribute=*value)          Substring (ends with)
(attribute=*value*)         Substring (contains)
(attribute=*)               Attribute exists
```

**Logical Operators:**

```text
(&(filter1)(filter2))       AND - all must be true
(|(filter1)(filter2))       OR - at least one true
(!(filter))                 NOT - negation
```

**Complex Filter Examples:**

```text
# Find user by username
(uid=jsmith)

# Find all users in department
(&(objectClass=person)(ou=engineering))

# Find users with email but no phone
(&(mail=*)(!(telephoneNumber=*)))

# Find all groups or organizational units
(|(objectClass=groupOfNames)(objectClass=organizationalUnit))

# Find users whose name starts with 'John'
(cn=John*)
```

### LDAP Schema

The schema defines the structure and content rules for directory entries:

#### Object Classes

Object classes define what attributes an entry must have (MUST) and may have (MAY):

**Structural Object Classes** - Define the basic entry type:

- `person` - Basic person entry
- `organizationalUnit` - Department or division
- `organization` - Top-level organization
- `domain` - DNS domain

**Auxiliary Object Classes** - Add additional attributes:

- `posixAccount` - Unix account information
- `shadowAccount` - Unix shadow password data
- `mailAccount` - Email account attributes

#### Attribute Types

Attributes define the data stored in entries:

**Common Attributes:**

| Attribute | Description | Example |
| --- | --- | --- |
| `cn` | Common Name | John Smith |
| `sn` | Surname | Smith |
| `givenName` | First Name | John |
| `mail` | Email Address | `john@example.com` |
| `uid` | User ID | jsmith |
| `uidNumber` | Unix UID | 1001 |
| `gidNumber` | Unix GID | 1001 |
| `homeDirectory` | Home Directory Path | /home/jsmith |
| `userPassword` | Encrypted Password | {SSHA}hash |

#### Attribute Syntax

Each attribute has a syntax defining the data type:

- **Directory String** - UTF-8 text
- **IA5 String** - ASCII text
- **Integer** - Numeric values
- **Boolean** - TRUE or FALSE
- **Binary** - Binary data
- **Distinguished Name** - DN references

### LDAP URLs

LDAP URLs provide a standard way to reference directory entries and searches:

**Syntax:**

```text
ldap://host:port/basedn?attributes?scope?filter
```

**Examples:**

```text
# Connect to server
ldap://ldap.example.com:389

# Query specific entry
ldap://ldap.example.com/cn=John Smith,ou=people,dc=example,dc=com

# Search with filter
ldap://ldap.example.com/ou=people,dc=example,dc=com??sub?(uid=jsmith)

# Secure connection
ldaps://ldap.example.com:636/dc=example,dc=com
```

### Why Use LDAP?

#### Centralized Authentication

- Single source of truth for user credentials
- Consistent authentication across multiple systems
- Reduced password management overhead

#### Hierarchical Organization

- Natural representation of organizational structure
- Efficient delegation of administration
- Logical grouping of resources

#### Scalability

- Optimized for read-heavy workloads
- Efficient replication strategies
- Handles millions of entries

#### Standards-Based

- Interoperable with many applications
- Well-defined protocol specifications
- Vendor-neutral implementation

#### Flexibility

- Extensible schema
- Custom attributes and object classes
- Adaptable to various use cases

### Common Use Cases

#### User Authentication

- Operating system login (PAM/NSS)
- Application authentication
- Single Sign-On (SSO) backend
- VPN and network access

#### Address Book Services

- Corporate contact directories
- Email client address books
- Phone directories
- Organizational charts

#### Configuration Management

- Application settings
- Network device configuration
- Service discovery
- DNS integration (SRV records)

#### Access Control

- Group-based authorization
- Role-based access control (RBAC)
- Attribute-based access control (ABAC)
- Resource permissions

#### Certificate Management

- Public key infrastructure (PKI)
- Certificate storage and retrieval
- Certificate revocation lists (CRL)
- Digital certificate attributes

## LDAP Architecture

### Client-Server Model

LDAP operates on a client-server architecture:

```text
┌─────────────┐         LDAP Protocol         ┌─────────────┐
│             │         (Port 389/636)        │             │
│   Client    │◄────────────────────────────►│    Server   │
│             │                               │             │
└─────────────┘                               └─────────────┘
                                                     │
                                                     ▼
                                              ┌─────────────┐
                                              │   Backend   │
                                              │  Database   │
                                              └─────────────┘
```

**Client Operations:**

- Establish connection (bind)
- Send requests (search, modify, add, delete)
- Receive responses
- Close connection (unbind)

**Server Operations:**

- Accept connections
- Authenticate clients
- Process requests
- Apply access controls
- Return results
- Replicate data

### LDAP Port Numbers

| Port | Protocol | Purpose |
| --- | --- | --- |
| **389** | TCP | Standard LDAP (cleartext or StartTLS) |
| **636** | TCP | LDAPS (LDAP over SSL/TLS) |
| **3268** | TCP | Global Catalog (Microsoft AD) |
| **3269** | TCP | Global Catalog over SSL |

### Backend Database Options

OpenLDAP supports multiple backend database types:

#### MDB (Lightning Memory-Mapped Database)

- Default and recommended backend
- Memory-mapped architecture
- Excellent performance
- ACID compliant
- Crash-proof

#### HDB (Hierarchical Database) - Deprecated

- Legacy Berkeley DB backend
- Hierarchical indexing
- No longer recommended

#### LDIF Backend

- Read-only flat file backend
- Useful for static data
- Simple configuration

#### SQL Backend

- Stores data in relational database
- PostgreSQL, MySQL support
- Useful for integration scenarios

## LDAP Security

### Authentication Methods

#### Simple Bind

- Username and password in cleartext
- Only use with TLS/SSL
- Defined in RFC 4513

```text
Bind DN: cn=admin,dc=example,dc=com
Password: secretpassword
```

#### SASL (Simple Authentication and Security Layer)

- Pluggable authentication framework
- Multiple mechanisms supported
- Defined in RFC 4422

**Common SASL Mechanisms:**

| Mechanism | Description | Use Case |
| --- | --- | --- |
| **PLAIN** | Username/password | With TLS only |
| **EXTERNAL** | TLS client certificate | Certificate-based auth |
| **GSSAPI** | Kerberos integration | Single sign-on |
| **DIGEST-MD5** | Challenge-response | Legacy systems |
| **CRAM-MD5** | Challenge-response | Legacy systems |

### Transport Security

#### StartTLS

- Upgrade plain connection to TLS
- Uses port 389
- Recommended for most deployments

#### LDAPS (LDAP over SSL)

- SSL/TLS from connection start
- Uses port 636
- Legacy but still common

**TLS Best Practices:**

- Use TLS 1.2 or higher
- Strong cipher suites
- Valid certificates from trusted CA
- Certificate validation enabled

### Access Control Lists

LDAP implements sophisticated access control lists (ACLs) to protect directory data:

**Access Control Elements:**

- **What** - Which entries/attributes
- **Who** - Which users/groups
- **Access Level** - Read, write, search, compare
- **Control** - Grant or deny

**Access Levels:**

| Level | Permissions |
| --- | --- |
| **none** | No access |
| **disclose** | Discover entry exists |
| **auth** | Bind authentication only |
| **compare** | Compare attribute values |
| **search** | Search but not read |
| **read** | Read attribute values |
| **write** | Modify attributes |
| **manage** | Administrative access |

## Topics

### Installation and Configuration

- System requirements and prerequisites
- Installation on various Linux distributions
- Initial setup and bootstrap
- Backend database configuration
- Network and firewall configuration
- Service management and startup

### Schema Management

- Understanding LDAP schema
- Core schema components
- Custom schema design
- Schema extension procedures
- Schema validation and testing
- Common schema patterns

### Directory Information Tree Design

- DIT structure planning
- Naming conventions
- Organizational hierarchy
- Suffix and base DN selection
- Multi-tenant considerations
- Best practices for scalability

### Replication and High Availability

- Replication concepts and terminology
- Provider-consumer replication
- Multi-provider (multi-master) replication
- Replication configuration
- Conflict resolution
- High availability architectures
- Load balancing strategies

### Security and Access Control

- TLS/SSL configuration
- Certificate management
- SASL authentication setup
- Access control list (ACL) syntax
- ACL design patterns
- Password policies
- Auditing and logging

### Performance Tuning

- Index configuration
- Cache tuning
- Connection pooling
- Query optimization
- Monitoring performance
- Capacity planning
- Troubleshooting slow queries

### Backup and Recovery

- Backup strategies
- Online vs offline backups
- LDIF export/import
- Point-in-time recovery
- Disaster recovery planning
- Testing recovery procedures

### Integration and Applications

- PAM/NSS integration for Linux authentication
- Sudo LDAP integration
- Mail server integration
- Web application authentication
- Single Sign-On (SSO) integration
- Monitoring tools integration
- Custom application development

## Getting Started

Before implementing OpenLDAP, ensure you have:

1. **System Requirements** - Linux/Unix server with appropriate resources
2. **Network Planning** - DNS configuration and network connectivity
3. **Security Planning** - SSL/TLS certificates and access control policies
4. **Directory Design** - LDAP schema and directory information tree (DIT) structure

## Quick Links

- Official Documentation: [OpenLDAP Documentation](https://www.openldap.org/doc/)
- Community Support: [OpenLDAP Mailing Lists](https://www.openldap.org/lists/)

## Related Topics

- [Active Directory](../activedirectory/index.md)
- [Identity Management](../../iam/index.md)
