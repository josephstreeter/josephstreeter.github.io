---
title: "iTop Monitoring and Troubleshooting"
description: "Monitoring iTop — application and cron logs, query logging, background-task health, and solutions to common issues"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Monitoring and Troubleshooting

### Logs

iTop writes to files under `log/` (the `itop-log` volume); Apache/PHP write to the container's stdout/stderr. Watch both:

| Source | Where | Contents |
| ------ | ----- | -------- |
| iTop application log | `log/error.log` | Application errors and warnings |
| Cron log | `log/cron.log` | Background-task scheduler output (this guide's cron service) |
| Setup log | `log/setup.log` | Installer/upgrade diagnostics |
| Web server / PHP | `docker logs itop-app` | HTTP errors, PHP fatals, stack traces |
| Database | `docker logs itop-db` | Connection and query errors |

```bash
docker logs -f itop-app                       # web server + PHP
docker exec itop-app tail -f /var/www/html/log/error.log
docker logs itop-cron --tail 30               # scheduler
```

### Query and Debug Logging

For diagnosing slow pages or data issues, enable query logging in `config-itop.php` — temporarily, as it is verbose:

```php
'log_level' => 'Debug',           // Error | Warning | Info | Debug
'query_log_enabled' => true,      // log SQL queries
'log_kpi_duration' => true,       // log timing of expensive operations
```

Turn these off again once you've captured what you need.

### Background-Task Health

The cron scheduler is the most common source of "it's not working" reports (notifications not sent, SLAs not escalating, syncs not running). Check it in **Admin tools → Background tasks** and confirm each task shows a recent *Last run*:

```bash
# Is the scheduler actually executing?
docker logs itop-cron --tail 20

# Run cron once manually and watch the output
docker exec itop-app php /var/www/html/webservices/cron.php \
  --auth_user=admin --auth_pwd=SECRET --verbose=1
```

### Health Checks and Metrics

- **HTTP health check** — probe the login page; a 200 means Apache/PHP and the DB connection are alive:

  ```yaml
  healthcheck:
    test: ["CMD-SHELL", "curl -fsS http://localhost/pages/UI.php >/dev/null || exit 1"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 60s
  ```

- **Database** — monitor MariaDB/MySQL separately (connections, slow queries); see [MySQL](../mysql/index.md).
- **Reverse proxy** — front-end metrics (status codes, latency) via the proxy's own monitoring ([Nginx](../nginx/monitoring.md) / [Apache](../apache/monitoring.md)).

### Troubleshooting Guide

| Symptom | Likely cause | What to check |
| ------- | ------------ | ------------- |
| **White page / HTTP 500** | PHP error or missing extension | `docker logs itop-app`; `log/error.log`; confirm `mysqli`/`gd`/`ldap` extensions are in the image |
| **"Error: MySQL server has gone away" / can't connect** | DB down, wrong `db_host`/creds, or startup ordering | Verify the `db` service is healthy; check `config-itop.php`; ensure `depends_on: condition: service_healthy` |
| **Notifications never send; SLAs don't escalate** | Cron not running | Check `itop-cron` logs and **Background tasks** *Last run* times |
| **Links/redirects use `http://` or loop** | `app_root_url` / `X-Forwarded-Proto` wrong | Set `app_root_url` to the HTTPS URL; forward `X-Forwarded-Proto https` ([Security](security.md)) |
| **Impact diagrams don't render** | graphviz missing or `graphviz_path` wrong | Install `graphviz` in the image; set `graphviz_path=/usr/bin/dot` |
| **Attachment upload fails** | PHP or proxy size limits | Raise `upload_max_filesize`/`post_max_size` and the proxy `client_max_body_size` |
| **Setup wizard won't run for upgrade** | Setup locked (by design) | Re-enable setup from a trusted network, upgrade, then re-lock ([Backup and Recovery](backup-recovery.md)) |
| **Changes to a module have no effect** | Data model not recompiled | Re-run setup or use the Toolkit so `env-production/` rebuilds ([Configuration](configuration.md#modules-and-extensions)) |

```bash
# Confirm required PHP extensions are present
docker exec itop-app php -m | grep -iE 'mysqli|gd|ldap|soap|zip'

# Test DB connectivity from the app container
docker exec itop-app php -r '$c=mysqli_connect("db","itop",getenv("DB_PWD"),"itop"); echo $c?"OK\n":"FAIL\n";'
```

> [!TIP]
> When something misbehaves after a config or module change, check `log/setup.log` and `log/error.log` first, then the cron log — most iTop operational problems are either a recompile that didn't happen, a stalled cron, or a reverse-proxy/URL mismatch, all of which these logs reveal quickly.

## Navigation

[◄ Backup and Recovery](backup-recovery.md) · [iTop Overview](index.md)
