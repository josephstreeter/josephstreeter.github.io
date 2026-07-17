---
title: "iTop Configuration"
description: "Configuring iTop — config-itop.php parameters, the cron scheduler, modules and extensions, and the Toolkit/Designer for data-model customization"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Configuration

### config-itop.php

The setup wizard writes the main configuration to `conf/production/config-itop.php` (persisted on the `itop-conf` volume). It is a PHP array of parameters you can edit directly — restart is not required, but the file must be writable by the web-server user during setup and read-only-safe afterwards.

```php
// conf/production/config-itop.php (excerpt)
$MySettings = array(
    // Database connection
    'db_host' => 'db',
    'db_user' => 'itop',
    'db_pwd'  => 'from-a-secret',
    'db_name' => 'itop',
    'db_subname' => '',            // optional table prefix

    // The public URL iTop generates links with — set this behind a reverse proxy
    'app_root_url' => 'https://itop.example.com/',

    // Path to graphviz 'dot' for impact diagrams
    'graphviz_path' => '/usr/bin/dot',

    // Security / sessions
    'secure_connection_required' => true,   // force HTTPS
    'session_name' => 'iTop',
);
```

| Parameter | Purpose |
| --------- | ------- |
| `db_host` / `db_user` / `db_pwd` / `db_name` | Database connection (host is the Compose service name, `db`) |
| `app_root_url` | The externally visible base URL — **must** match your reverse-proxy hostname or links/emails break |
| `graphviz_path` | Location of graphviz `dot`, used to render impact/dependency graphs |
| `secure_connection_required` | Rejects non-HTTPS access (set once TLS is in front) |
| `log_level` / `query_log_enabled` | Logging verbosity and SQL query logging (see [Monitoring](monitoring.md)) |

> [!IMPORTANT]
> When iTop runs behind a reverse proxy, set `app_root_url` to the **public** HTTPS URL, and make sure the proxy forwards `X-Forwarded-Proto`. Otherwise iTop generates `http://` links, mixed-content warnings, and broken redirects. See [Security](security.md).

### The Cron Scheduler

iTop performs background work — sending queued notifications, escalating tickets against SLAs, running scheduled data synchronizations — through `webservices/cron.php`, which **must run regularly** (typically every minute). Without it, notifications never send and SLA timers don't fire.

The [Deployment](deployment.md) Compose file runs it as a dedicated `cron` service. Equivalently, on a host cron:

```bash
* * * * * php /var/www/html/webservices/cron.php --auth_user=admin --auth_pwd=SECRET >/dev/null 2>&1
```

Inspect scheduled background tasks in the UI under **Admin tools → Background tasks**, or check the log:

```bash
docker logs itop-cron --tail 30
docker exec itop-app tail -f /var/www/html/log/cron.log
```

> [!TIP]
> Run `cron.php` with a **dedicated service account** that has only the profiles it needs, not the primary admin. Store its password in a secret, and verify in **Background tasks** that jobs show recent "Last run" times — a stalled cron is a common cause of "notifications aren't sending".

### Modules and Extensions

iTop's functionality is delivered as **datamodel modules**. The core ITIL modules are chosen during setup; additional extensions (asset management add-ons, connectors, the Mail-to-Ticket automation, etc.) come from the [iTop Hub store](https://store.itophub.io/).

To add an extension:

1. Place the extension folder under `extensions/` in the web root (bake it into your image or mount it).
2. **Re-run setup** (upgrade mode) so iTop compiles the new module into `env-production/`, or apply it via the Toolkit.
3. Verify it appears under **Admin tools → iTop configuration**.

```dockerfile
# In your image: add an extension so it's part of the build
COPY extensions/my-extension /var/www/html/extensions/my-extension
```

> [!NOTE]
> iTop compiles the active modules into the `env-production/` directory. Adding, removing, or updating a module requires a **recompile** (re-run setup or use the Toolkit) — simply dropping files in does nothing until the model is rebuilt. Keep `env-production/` on a volume so the compiled model persists.

### The Toolkit (Designer)

The **Toolkit** (`toolkit/` in the web root, or the online iTop Designer) customizes the data model without editing XML by hand — add classes, fields, relationships, and lifecycle states. It regenerates the datamodel XML, which you then apply by recompiling.

Workflow:

1. Open the Toolkit and make changes (new attribute, new class, workflow state).
2. Export the resulting `datamodel` delta as a module.
3. Apply it by re-running setup so `env-production/` is rebuilt.

> [!WARNING]
> Always **back up before a data-model change** (see [Backup and Recovery](backup-recovery.md)). Structural changes alter the database schema; test them in a staging copy first, because a bad model change can be disruptive to reverse on a production ticketing system.

### Localization and Portal

- **Language** is chosen at setup and per-user in profile preferences; additional language packs are extensions.
- The **Service Portal** (`/pages/exec.php?exec_module=itop-portal...`) is the simplified end-user interface, distinct from the full back-office console — configure which users land on the portal via their profiles.

## Navigation

[◄ Deployment](deployment.md) · [iTop Overview](index.md) · [CMDB and ITSM ►](cmdb-itsm.md)
