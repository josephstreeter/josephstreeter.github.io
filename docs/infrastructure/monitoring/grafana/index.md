---
title: Grafana
description: Grafana visualization, dashboards, provisioning, security, and clustering for the Prometheus monitoring stack.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 12/30/2025
ms.topic: overview
ms.service: monitoring
keywords: Grafana, dashboards, visualization, provisioning, security, high availability
uid: docs.infrastructure.grafana.index
---

## Grafana

[Grafana](https://grafana.com/) is the visualization and dashboarding layer of this monitoring stack. It queries [Prometheus](../prometheus/index.md) (and other data sources), renders dashboards, and can optionally handle alerting. This section covers installing, configuring, securing, and scaling Grafana.

> [!NOTE]
> For the high-level stack overview (architecture, components, and how the pieces fit), see the [Monitoring overview](../index.md). For metrics collection and alert rules, see [Prometheus](../prometheus/index.md); for alert routing, see [Alertmanager](../alertmanager/index.md).

### What Grafana Provides

- **Dashboards** — flexible panels and visualizations over Prometheus and many other data sources
- **Data sources** — Prometheus, Loki, SQL databases, cloud providers, and more
- **Provisioning** — data sources, dashboards, and alerting as code
- **Alerting** — Grafana unified alerting as an alternative to Prometheus + Alertmanager (see [Prometheus — Alerting](../prometheus/alerting.md) for the "choose one" guidance)
- **Access control** — authentication (LDAP, OAuth/OIDC), org roles, and TLS

### In This Section

- **[Installation](installation.md)** — Docker Compose and native install, secrets management
- **[Configuration](configuration.md)** — `grafana.ini`, provisioning, data sources
- **[Dashboards](dashboards.md)** — building, importing, and provisioning dashboards
- **[Security](security.md)** — TLS/mTLS, authentication, hardening
- **[High Availability](high-availability.md)** — Grafana clustering with a shared database and load balancing
- **[Backup and Recovery](backup-recovery.md)** — backing up the Grafana database, dashboards, and provisioning

### Quick Start

Run Grafana as a container (the [Installation](installation.md) guide covers the full stack and secrets):

```bash
docker run -d --name grafana -p 3000:3000 grafana/grafana:11.2.0
```

Then:

1. Log in at `http://localhost:3000` (default `admin`/`admin`; change the password on first login).
2. Add a **Prometheus data source** pointing at your Prometheus server (e.g. `http://prometheus:9090`).
3. Import a community dashboard by ID (see below), or build your own — [Dashboards](dashboards.md).

Confirm Grafana is up (the health endpoint needs no authentication):

```bash
curl http://localhost:3000/api/health
```

### Recommended Dashboards

Popular dashboards to import by ID:

1. **Node Exporter Full** (ID: 1860) — system metrics
2. **Docker Container & Host Metrics** (ID: 10619) — container monitoring
3. **UniFi Poller** (ID: 11315) — UniFi network devices
4. **Blackbox Exporter** (ID: 13659) — endpoint/network probing

### Related

- [Monitoring overview](../index.md) — the stack hub
- [Prometheus](../prometheus/index.md) — metrics, exporters, and alerting
- [Alertmanager](../alertmanager/index.md) — alert routing and notification

### References

- [Grafana Documentation](https://grafana.com/docs/)
- [Grafana Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [Grafana Dashboards Library](https://grafana.com/grafana/dashboards/)
