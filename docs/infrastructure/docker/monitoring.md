---
title: "Docker Monitoring and Logging"
description: "Container logs, log drivers, resource statistics, events, health checks, and exposing Docker metrics to Prometheus"
tags: ["docker", "monitoring", "logging", "observability", "healthcheck", "prometheus"]
category: "infrastructure"
difficulty: "intermediate"
last_updated: "2026-08-01"
---

## Docker Monitoring and Logging

This page covers what the Docker engine itself gives you: container logs and the drivers that
carry them, live resource statistics, the event stream, health check state, and the metrics
endpoint that lets Prometheus scrape the daemon.

It deliberately stops short of building a monitoring stack. Prometheus, Grafana,
Alertmanager, and the exporters have their own guides — see
[Infrastructure Monitoring](../monitoring/index.md) for the stack and
[Grafana — Installation](../monitoring/grafana/installation.md) for a complete Compose
deployment including cAdvisor and Node Exporter.

## Table of Contents

- [Container Logs](#container-logs)
- [Logging Drivers](#logging-drivers)
- [Log Rotation](#log-rotation)
- [Resource Statistics](#resource-statistics)
- [The Event Stream](#the-event-stream)
- [Health Checks](#health-checks)
- [Debugging a Container](#debugging-a-container)
- [Metrics for Prometheus](#metrics-for-prometheus)
- [Best Practices](#best-practices)

## Container Logs

Docker captures whatever a container writes to stdout and stderr. Anything an application
writes to a file inside the container is invisible to `docker logs` — which is why
containerized software should log to stdout rather than to `/var/log`.

```bash
docker logs mycontainer

# Follow
docker logs -f mycontainer

# Last 100 lines, then follow
docker logs -f --tail 100 mycontainer

# With timestamps
docker logs -t mycontainer

# Time-bounded
docker logs --since 10m mycontainer
docker logs --since 2026-08-01T09:00:00 --until 2026-08-01T10:00:00 mycontainer

# Separate the streams — stderr only
docker logs mycontainer 2>&1 1>/dev/null
```

For a Compose project:

```bash
docker compose logs -f
docker compose logs -f --tail 100 web
docker compose logs --since 15m web db
```

### Where Logs Live

With the default `json-file` driver, each container's log is a file on the host:

```bash
docker inspect -f '{{.LogPath}}' mycontainer
# /var/lib/docker/containers/<id>/<id>-json.log

# Size of every container log, largest first
sudo du -sh /var/lib/docker/containers/*/*-json.log | sort -rh | head
```

> [!WARNING]
> **`json-file` has no size limit by default.** A container logging steadily will fill the
> disk, and no `docker system prune` command removes container logs. This is one of the most
> common causes of a full Docker host — see [Log Rotation](#log-rotation).

## Logging Drivers

Confirm what your daemon supports:

```bash
docker info --format '{{.Plugins.Log}}'
# [awslogs fluentd gcplogs gelf journald json-file local splunk syslog]

docker info --format '{{.LoggingDriver}}'
```

| Driver | `docker logs` works | Notes |
|--------|---------------------|-------|
| `json-file` | Yes | Default. Cap the size. |
| `local` | Yes | More efficient, compresses, and **rotates by default**. Not human-readable on disk. |
| `journald` | Yes | Into the systemd journal — unified with host logging, queryable via `journalctl`. |
| `syslog` | No | Ships to a syslog collector. |
| `gelf` | No | Graylog Extended Log Format — Graylog, Logstash. |
| `fluentd` | No | Fluentd / Fluent Bit. |
| `awslogs`, `gcplogs`, `splunk` | No | Hosted log services. |
| `none` | No | Disables logging for a container. |

> [!IMPORTANT]
> With any driver that ships logs elsewhere, `docker logs` returns an error rather than
> output — the daemon never stored them locally. If you want both local inspection and
> centralized shipping, use `journald` or `local` and collect from the host, rather than
> pointing containers directly at a remote collector.

### Setting a Driver

Per container:

```bash
docker run -d --log-driver local --log-opt max-size=10m myapp
docker run -d --log-driver none noisy-batch-job
docker run -d --log-driver journald --log-opt tag="{{.Name}}" myapp
```

In Compose:

```yaml
services:
  web:
    image: nginx:alpine
    logging:
      driver: local
      options:
        max-size: "10m"
        max-file: "3"

  app:
    build: .
    logging:
      driver: journald
      options:
        tag: "{{.Name}}"
```

Host-wide defaults belong in `daemon.json` — see
[Logging Configuration](daemon.md#logging-configuration).

### Blocking vs Non-Blocking Delivery

A remote driver that cannot reach its collector will, by default, **block the container's
writes** — the application stalls on `stdout`. This turns a logging outage into an
application outage.

```yaml
logging:
  driver: fluentd
  options:
    fluentd-address: "logs.internal:24224"
    mode: non-blocking
    max-buffer-size: 4m
```

`mode: non-blocking` buffers in memory and drops messages once the buffer fills, which is
almost always the right trade for a production service. Set it on every remote driver.

## Log Rotation

### json-file

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true"
  }
}
```

That caps each container at roughly 30 MB.

> [!NOTE]
> Log settings are fixed when a container is **created**. Changing `daemon.json` affects only
> containers created afterwards — existing ones keep their original limits until recreated
> (`docker compose up -d --force-recreate`). This is the usual reason a rotation change
> "didn't work."

### The `local` Driver

`local` rotates by default and is more efficient than `json-file`. It is the better choice
for anything that does not need external tooling to read the raw files:

```json
{
  "log-driver": "local",
  "log-opts": { "max-size": "10m", "max-file": "5" }
}
```

### Emergency Truncation

When a log has already filled the disk, truncate in place rather than deleting the file —
the daemon holds an open descriptor, so `rm` frees nothing until the container stops:

```bash
sudo truncate -s 0 "$(docker inspect -f '{{.LogPath}}' mycontainer)"
```

Then fix the rotation settings so it does not recur.

## Resource Statistics

```bash
# Live, all running containers
docker stats

# One-shot, script-friendly
docker stats --no-stream

# Specific containers
docker stats web db

# Custom columns
docker stats --no-stream \
  --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"

# JSON for further processing
docker stats --no-stream --format json | jq -r '"\(.Name) \(.CPUPerc)"'
```

Available fields: `.Container`, `.Name`, `.ID`, `.CPUPerc`, `.MemUsage`, `.MemPerc`,
`.NetIO`, `.BlockIO`, `.PIDs`.

> [!NOTE]
> `MemUsage` is the cgroup's accounting, which includes page cache attributable to the
> container. It will not match what the application reports as its own heap, and a container
> sitting near its memory limit is not necessarily in trouble — cache is reclaimable. Judge
> pressure by whether the kernel is actually killing the process, not by `MemPerc` alone.

`docker stats` is a live view with no history. For trends, scrape cAdvisor into Prometheus —
see [Metrics for Prometheus](#metrics-for-prometheus).

### Processes Inside a Container

```bash
docker top mycontainer
docker top mycontainer -eo pid,ppid,user,%cpu,%mem,cmd
```

### Disk Consumption

```bash
docker system df
docker system df -v
```

Covered in full under [Disk Usage and Pruning](storage.md#disk-usage-and-pruning).

## The Event Stream

The daemon emits an event for everything it does. This is the most direct way to answer
"what happened to that container at 3 a.m."

```bash
# Live
docker events

# Historical window
docker events --since 1h --until 0s

# Container lifecycle only, formatted
docker events --since 24h --until 0s \
  --filter type=container \
  --format '{{.Time}} {{.Action}} {{.Actor.Attributes.name}}'
```

```text
1785595807 exec_start: /bin/sh -c exit 0 t-health
1785595807 exec_die t-health
1785595809 kill t-health
1785595809 die t-health
1785595809 destroy t-health
```

Useful filters:

```bash
# Why did it restart? Look for oom, die, and the exit code
docker events --since 24h --until 0s --filter event=oom
docker events --since 24h --until 0s --filter event=die \
  --format '{{.Actor.Attributes.name}} exit={{.Actor.Attributes.exitCode}}'

# Health transitions
docker events --filter event=health_status

# A single container
docker events --filter container=myapp

# Image pulls and pushes
docker events --filter type=image
```

> [!TIP]
> `docker events` without `--since` shows only events from the moment you run it. Historical
> events are held in memory and lost on daemon restart — if you need durable audit history,
> pipe the stream to a file from a long-running service.

## Health Checks

A health check is defined in the image (see
[Metadata and Health Checks](images.md#metadata-and-health-checks)) or at run time. This
section covers observing the result.

```bash
docker run -d --name web \
  --health-cmd 'curl -fsS http://localhost/ || exit 1' \
  --health-interval 30s \
  --health-timeout 3s \
  --health-retries 3 \
  --health-start-period 40s \
  nginx
```

### Reading Health State

```bash
# Current status: starting | healthy | unhealthy
docker inspect -f '{{.State.Health.Status}}' web

# The last few probe results, with output and exit codes
docker inspect -f '{{json .State.Health.Log}}' web | jq

# Filter containers by health
docker ps --filter health=unhealthy
docker ps --filter health=healthy --format '{{.Names}}'
```

`docker ps` also shows health in the STATUS column — `Up 2 minutes (healthy)`.

> [!IMPORTANT]
> Docker does **not** restart an unhealthy container. `unhealthy` is a reported state, not an
> action — a restart policy reacts to the process *exiting*, not to a failing probe. If you
> want automatic recovery you need an orchestrator: [Swarm](swarm.md) reschedules unhealthy
> tasks, and Kubernetes restarts on a failed liveness probe.

### Compose Dependency Conditions

Health checks are what make `depends_on` meaningful — without a condition, Compose only waits
for the container to *start*, not to become usable:

```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  app:
    build: .
    depends_on:
      db:
        condition: service_healthy
```

### Watching for Failures

```bash
# Alert-worthy: anything currently unhealthy
docker ps --filter health=unhealthy --format '{{.Names}}'

# Live transitions
docker events --filter event=health_status \
  --format '{{.Actor.Attributes.name}} {{.Status}}'
```

## Debugging a Container

### Why It Stopped

```bash
docker inspect -f '{{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}}' mycontainer
docker inspect -f '{{.State.Error}}' mycontainer
```

| Exit code | Meaning |
|-----------|---------|
| `0` | Clean exit |
| `1` / `2` | Application error |
| `125` | The daemon itself failed — bad `docker run` flags |
| `126` | Command found but not executable |
| `127` | Command not found — usually a wrong path in `ENTRYPOINT`/`CMD` |
| `137` | `SIGKILL` (128+9) — OOM kill, or a `docker stop` that timed out |
| `143` | `SIGTERM` (128+15) — a normal `docker stop` |

A `137` with `OOMKilled=true` is the kernel killing the process for exceeding its memory
limit. A `137` with `OOMKilled=false` usually means the container ignored `SIGTERM` and was
killed after the stop grace period — see
[ENTRYPOINT vs CMD](images.md#entrypoint-vs-cmd) for why shell-form entrypoints cause this.

### Inspecting a Running Container

```bash
docker exec -it mycontainer sh
docker exec mycontainer ps aux
docker exec mycontainer cat /proc/1/status

# Full configuration and state
docker inspect mycontainer | jq

# Filesystem changes since the image
docker diff mycontainer
```

For minimal images without a shell, attach a toolbox to the container's namespaces rather
than rebuilding it:

```bash
docker run --rm -it --pid container:mycontainer --network container:mycontainer \
  nicolaka/netshoot bash
```

The same technique for networking specifically is covered in
[Testing From Inside a Container](networking.md#testing-from-inside-a-container).

## Metrics for Prometheus

### Daemon Metrics

The daemon can expose its own Prometheus metrics — engine-level counters covering builds,
container actions, and daemon health:

```json
{
  "metrics-addr": "127.0.0.1:9323"
}
```

```bash
sudo systemctl restart docker
curl -s http://127.0.0.1:9323/metrics | head
```

> [!CAUTION]
> Bind to `127.0.0.1`, not `0.0.0.0`. The endpoint is unauthenticated and reveals detail
> about what the host is running. Scrape it from a collector on the same host, or over an
> internal interface protected by firewall rules.

```yaml
# prometheus.yml
scrape_configs:
  - job_name: docker-engine
    static_configs:
      - targets: ['127.0.0.1:9323']
```

### Container Metrics

The daemon endpoint does **not** provide per-container CPU, memory, and I/O. Those come from
**cAdvisor**, with host-level metrics from **Node Exporter**. Both are documented, with
working configuration, in [Prometheus — Exporters](../monitoring/prometheus/exporters.md);
a complete Compose stack wiring them to Prometheus and Grafana is in
[Grafana — Installation](../monitoring/grafana/installation.md).

Alert rules for container conditions belong with the rest of the rule set — see
[Prometheus — Alerting](../monitoring/prometheus/alerting.md), and
[Alertmanager](../monitoring/alertmanager/index.md) for routing. Two container-specific
notes when writing them:

- `up == 0` means **the scrape target is down**, which is not the same as a container being
  down. For container liveness from cAdvisor, key off `container_last_seen` going stale.
- Aggregate CPU rates before comparing. `rate(container_cpu_usage_seconds_total[5m])` yields
  one series per CPU per container; without `sum by (name)` a threshold fires on individual
  series rather than on the container's total.

### Centralized Logging

Shipping container logs to Loki, the ELK stack, or a hosted service is a
[logging driver](#logging-drivers) choice on the Docker side. The collectors themselves are
covered under [Log Management](../monitoring/index.md#log-management).

## Best Practices

- **Log to stdout/stderr.** Files inside a container are invisible to every Docker logging
  mechanism.
- **Cap log size on day one** — `json-file` is unbounded by default, or use `local`, which
  rotates.
- **Set `mode: non-blocking`** on any remote driver so a collector outage cannot stall the
  application.
- **Emit structured JSON** from applications where the log volume justifies parsing.
- **Add a `HEALTHCHECK`** to anything long-running, and remember Docker alone will not act on
  it.
- **Never log secrets** — container logs are readable by anyone with daemon access and are
  usually shipped somewhere less protected.
- **Recreate containers after changing log settings**; the configuration is fixed at creation.
- **Keep the metrics endpoint on localhost.**

## Related Topics

- [Daemon Configuration](daemon.md) — host-wide log driver defaults and the metrics endpoint
- [Docker Storage](storage.md) — disk usage, and why logs are not covered by pruning
- [Building Images](images.md) — authoring `HEALTHCHECK` and correct signal handling
- [Docker Compose](dockercompose/index.md) — per-service logging and health configuration
- [Docker Swarm](swarm.md) — health-driven rescheduling and rolling updates
- [Infrastructure Monitoring](../monitoring/index.md) — the Prometheus and Grafana stack
- [Prometheus — Exporters](../monitoring/prometheus/exporters.md) — cAdvisor and Node Exporter
