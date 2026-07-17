---
title: "iTop Integration"
description: "Integrating iTop — the REST/JSON API, data synchronization and collectors, LDAP authentication, and email-to-ticket"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Integration

iTop is designed to sit at the center of an IT toolchain. It exposes a REST/JSON API, a data-synchronization framework for feeding the CMDB, and pluggable authentication.

## REST / JSON API

iTop's REST API (`/webservices/rest.php`) lets external systems create and query any object — tickets, CIs, contacts. It is the standard way to integrate monitoring, automation, and custom apps.

### Enabling API Access

Grant a user the **REST Services User** profile (or a custom profile with the right rights). Never use the main admin account for integrations.

### Request Format

Send an HTTP POST with a `json_data` payload describing the operation. Common operations: `core/get`, `core/create`, `core/update`, `core/delete`, `core/apply_stimulus`.

```bash
# Create an incident via the REST API
curl -s "https://itop.example.com/webservices/rest.php?version=1.3" \
  -u "api_user:api_password" \
  --data-urlencode 'json_data={
    "operation": "core/create",
    "class": "Incident",
    "fields": {
      "title": "Web server unreachable",
      "description": "HTTP 503 from the CRM front end",
      "org_id": "SELECT Organization WHERE name = \"Demo\"",
      "caller_id": "SELECT Person WHERE email = \"jdoe@example.com\"",
      "impact": "2",
      "urgency": "2"
    },
    "comment": "Created by monitoring",
    "output_fields": "id,ref,status"
  }'
```

```bash
# Query open incidents (OQL — Object Query Language)
curl -s "https://itop.example.com/webservices/rest.php?version=1.3" \
  -u "api_user:api_password" \
  --data-urlencode 'json_data={
    "operation": "core/get",
    "class": "Incident",
    "key": "SELECT Incident WHERE status != \"closed\"",
    "output_fields": "ref,title,status,start_date"
  }'
```

| Operation | Purpose |
| --------- | ------- |
| `core/get` | Query objects with an OQL `key` |
| `core/create` | Create a new object |
| `core/update` | Modify fields of an existing object |
| `core/apply_stimulus` | Drive a ticket through its lifecycle (e.g. `ev_assign`, `ev_resolve`) |
| `core/delete` | Remove an object (use cautiously) |
| `list_operations` | Discover available operations |

> [!NOTE]
> Object references use **OQL** — iTop's SQL-like query language — inside the JSON (for example `"SELECT Person WHERE email = ..."`). This lets you reference related objects by attribute instead of internal ID, which is invaluable when integrating external systems that don't know iTop's primary keys.

---

> [!TIP]
> Prefer a **service account with the minimum profile** and always call the API over **HTTPS with least-privilege credentials**. Test queries in the UI (the OQL query editor under Data administration) before embedding them in an integration.

## Data Synchronization (Collectors)

To keep the CMDB accurate, feed it automatically rather than by hand. iTop's **Synchro Data Sources** define how external data maps onto iTop classes, with rules for creating, updating, and reconciling objects (and what to do when a source stops reporting an object).

- **Synchro Data Source** — a mapping (source columns → iTop attributes), a reconciliation key, and policies (create missing, update changed, mark obsolete).
- **Data Collectors** — Combodo's [collector framework](https://www.itophub.io/wiki/page?id=extensions:data_collector_base_class) (PHP/Python) that pulls from a source (LDAP, a monitoring tool, vCenter, a CSV export) and pushes to a Synchro Data Source on a schedule (run from the cron/scheduler).

Typical flow:

```text
[External source] -> [Collector (scheduled)] -> [Synchro Data Source] -> [CMDB objects]
```

Collectors run as scheduled jobs — in a container deployment, run them from the same scheduler pattern as `cron.php`, or as their own sidecar. Reconciliation keys (e.g. serial number, FQDN) prevent duplicates when the same CI comes from multiple sources.

> [!IMPORTANT]
> Choose reconciliation keys carefully and set the **obsolescence** policy deliberately. A Synchro Data Source that "deletes objects missing from the source" will remove CIs if the source feed breaks — usually you want it to **mark them as obsolete** for review instead of hard-deleting.

## Authentication (LDAP / SSO)

iTop supports pluggable **login modules**: the built-in form (database) login, **LDAP/Active Directory**, and external SSO (CAS, SAML/OpenID via extensions).

Configure LDAP in `config-itop.php`:

```php
// conf/production/config-itop.php (excerpt)
'authent-ldap' => array(
    'host' => 'ldap.example.com',
    'port' => 389,
    'default_user' => 'cn=itop-bind,ou=svc,dc=example,dc=com',
    'default_pwd'  => 'from-a-secret',
    'base_dn'      => 'ou=people,dc=example,dc=com',
    'user_query'   => '(&(objectClass=person)(sAMAccountName=%1$s))',
    'options' => array(
        LDAP_OPT_PROTOCOL_VERSION => 3,
        LDAP_OPT_REFERRALS => 0,
    ),
),
'allowed_login_types' => 'form|external|ldap',
```

- Enable the `authent-ldap` module (installed via setup) and list `ldap` in `allowed_login_types`.
- Use **LDAPS** or StartTLS in production so credentials aren't sent in the clear (see [Security](security.md)).
- LDAP authenticates users, but each must still exist as an iTop `User` linked to a `Person` — provision these manually, via CSV, or via a synchro source.

## Email to Ticket

The **Mail to Ticket Automation** extension (from the iTop Hub) polls a mailbox (IMAP) and creates or updates tickets from inbound email — the basis of an email-driven service desk. It runs via the cron scheduler and maps senders to callers/organizations. Install it like any [extension](configuration.md#modules-and-extensions) and configure the mailbox and rules in the UI.

## Navigation

[◄ CMDB and ITSM](cmdb-itsm.md) · [iTop Overview](index.md) · [Security ►](security.md)
