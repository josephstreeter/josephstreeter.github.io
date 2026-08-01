---
title: "Working with Docker Containers"
description: "Container lifecycle, inspection, security options, resource limits, and production deployment strategies"
author: "Joseph Streeter"
tags: ["docker", "containers", "deployment", "lifecycle", "production"]
category: "infrastructure"
difficulty: "intermediate"
last_updated: "2026-08-01"
---

This comprehensive guide covers advanced Docker container operations, from lifecycle management to production deployment strategies. It builds upon the [Docker Quickstart](quickstart.md) guide.

## Container Lifecycle Management

### Container States

Containers transition through several states during their lifecycle:

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Container Lifecycle                          │
├─────────────────────────────────────────────────────────────────┤
│  Created → Running → Paused → Stopped → Removed                │
│      ↑         ↓         ↑         ↑         ↑                 │
│      └─────────┴─────────┴─────────┴─────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

### Advanced Container Operations

#### Creating Containers

```bash
# Create container without starting
docker create --name webserver nginx:latest

# Create with resource limits
docker create --name limited-app \
  --memory="512m" \
  --cpus="1.0" \
  --storage-opt size=10G \
  nginx:latest

# Create with environment variables
docker create --name app \
  -e NODE_ENV=production \
  -e DATABASE_URL=postgres://localhost/mydb \
  node:16-alpine
```

#### Container Inspection

```bash
# Detailed container information
docker inspect webserver

# Get specific information using format
docker inspect --format='{{.State.Status}}' webserver
docker inspect --format='{{.NetworkSettings.IPAddress}}' webserver
docker inspect --format='{{range .Mounts}}{{.Source}}:{{.Destination}}{{end}}' webserver

# Container resource usage
docker stats webserver

# Real-time container events
docker events --filter container=webserver
```

#### Container Process Management

```bash
# List processes in container
docker top webserver

# Execute commands in running container
docker exec webserver ls -la /etc

# Interactive shell in container
docker exec -it webserver /bin/bash

# Execute as specific user
docker exec -u root -it webserver /bin/bash

# Execute with environment variables
docker exec -e VAR=value webserver env
```

## Networking

Containers on the same user-defined network reach each other by name; publishing is only
needed to reach a container from outside Docker.

```bash
# Create a user-defined network and attach containers to it
docker network create mynet
docker run -d --name api --network mynet myapp:latest
docker run -d --name web --network mynet -p 8080:80 nginx

# Attach a running container to an additional network
docker network connect backend web

# Inspect
docker network ls
docker network inspect mynet
docker port web
```

For network drivers (bridge, host, macvlan, ipvlan, overlay), embedded DNS behavior,
`EXPOSE` versus `-p`, firewall interaction, and IPv6, see
[Docker Networking](networking.md).

## Volumes and Persistence

| Type | Use case | Managed by |
|------|----------|------------|
| Named volume | Application data, databases | Docker |
| Bind mount | Source code, host config files | You |
| `tmpfs` | Secrets, scratch space | Kernel (RAM) |

```bash
# Named volume — preferred for service data
docker volume create appdata
docker run -d --name db --mount source=appdata,target=/var/lib/postgresql/data postgres:16

# Bind mount, read-only
docker run -d --mount type=bind,source=/etc/myapp,target=/etc/app,readonly myapp

# In-memory scratch space
docker run -d --tmpfs /app/cache:noexec,nosuid,size=100m myapp
```

For storage drivers and layer mechanics, bind-mount permissions and UID/GID handling,
NFS and CIFS volume drivers, disk usage and pruning, and I/O performance, see
[Docker Storage](storage.md).

## Container Security

### Running as Non-Root User

```dockerfile
# Dockerfile example
FROM alpine:latest

# Create user and group
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser

# Switch to non-root user
USER appuser

# Application files owned by appuser
COPY --chown=appuser:appgroup . /app
WORKDIR /app
```

```bash
# Override user at runtime
docker run -u 1001:1001 myapp:latest

# Run as specific user with home directory
docker run -u $(id -u):$(id -g) -v $HOME:/home/user myapp:latest
```

### Security Options

```bash
# Run with security profiles
docker run --security-opt apparmor=docker-default myapp
docker run --security-opt seccomp=chrome.json myapp

# Disable privileged escalation
docker run --security-opt no-new-privileges myapp

# Drop capabilities
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx

# Run with read-only root filesystem
docker run --read-only --tmpfs /tmp myapp
```

### Resource Limits and Constraints

```bash
# Memory limits
docker run -m 512m myapp                    # 512 MB limit
docker run --memory=1g myapp                # 1 GB limit
docker run --memory=1g --memory-swap=2g myapp  # 1GB memory + 1GB swap

# CPU limits
docker run --cpus="1.5" myapp               # 1.5 CPU cores
docker run --cpu-shares=512 myapp           # Relative CPU weight
docker run --cpuset-cpus="0,1" myapp        # Specific CPU cores

# I/O limits
docker run --device-read-bps /dev/sda:1mb myapp
docker run --device-write-bps /dev/sda:1mb myapp

# Process limits
docker run --pids-limit=100 myapp           # Max 100 processes

# Ulimits
docker run --ulimit nofile=1024:1024 myapp  # File descriptor limit
```

## Production Deployment Strategies

### Health Checks

```dockerfile
# Dockerfile health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

```bash
# Runtime health check
docker run -d --name web \
  --health-cmd="curl -f http://localhost || exit 1" \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  nginx

# Check health status
docker inspect --format='{{.State.Health.Status}}' web
```

### Restart Policies

```bash
# Always restart unless manually stopped
docker run -d --restart=unless-stopped nginx

# Restart on failure only
docker run -d --restart=on-failure:3 nginx

# Always restart
docker run -d --restart=always nginx

# Update restart policy of running container
docker update --restart=unless-stopped mycontainer
```

### Logging Configuration

Cap log size per container, because `json-file` is unbounded by default:

```bash
docker run -d --name app \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  myapp
```

Driver selection, rotation, and reading logs are covered in
[Monitoring and Logging](monitoring.md#logging-drivers); host-wide defaults belong in
`daemon.json` — see [Logging Configuration](daemon.md#logging-configuration).

## Multi-Container Applications

Running several containers together — a web tier, an application, a database, a cache — is
Compose's job rather than something to wire up with `docker run`. It handles the network,
dependency ordering, and lifecycle as a unit:

```bash
docker compose up -d
docker compose ps
docker compose logs -f app
docker compose down
```

Production stack examples, including resource limits, secrets, internal networks, and
Traefik-based routing, are in [Docker Compose](dockercompose/index.md#templates). For
multi-host clustering, see [Docker Swarm](swarm.md).

> [!NOTE]
> Compose honors only part of the `deploy:` key — `replicas`, `resources`, and
> `restart_policy` — and silently ignores the Swarm-only remainder. See
> [Compose Differences](swarm.md#compose-differences).


## Debugging a Running Container

### Copying Files In and Out

```bash
docker cp myapp:/etc/nginx/nginx.conf ./
docker cp ./new-config.conf myapp:/etc/nginx/

# Works on stopped containers too — useful for recovering state after a crash
docker cp stopped-container:/var/log/app.log ./
```

### Attaching a Toolbox

Minimal images have no shell or diagnostic tools. Rather than rebuilding the image, start a
throwaway container inside the target's namespaces:

```bash
# Network namespace only
docker run --rm -it --network container:myapp nicolaka/netshoot

# Network, PID, and the target's volumes — a near-complete view
docker run --rm -it \
  --network container:myapp \
  --pid container:myapp \
  --volumes-from myapp \
  busybox sh
```

### Entering Namespaces Directly

```bash
PID=$(docker inspect -f '{{.State.Pid}}' myapp)
sudo nsenter -t "$PID" -n -p ss -tlnp
```

`nsenter` runs host binaries against the container's namespaces, so it works even when the
image contains nothing at all.

Resource statistics, the event stream, exit codes, and log inspection are covered in
[Monitoring and Logging](monitoring.md#debugging-a-container).

## Performance Optimization

Image size and build speed are a build-time concern — multi-stage builds, layer caching, and
base image selection are covered in [Building Images](images.md#image-size-optimization).
What follows is runtime tuning.

### Container Performance Tuning

```bash
# Optimize container startup
docker run -d --name app \
  --memory="1g" \
  --cpus="2.0" \
  --oom-kill-disable=false \
  --memory-swappiness=0 \
  myapp:latest

# Use init process for proper signal handling
docker run -d --init myapp:latest

# Throttle block I/O so a batch job cannot starve interactive services
docker run -d --name app \
  --device-read-iops /dev/sda:1000 \
  --device-write-iops /dev/sda:1000 \
  --blkio-weight 500 \
  myapp:latest
```

> [!NOTE]
> `--storage-opt size=` appears in many older guides here, but it is only supported on
> specific driver and filesystem combinations and errors out on `overlay2` over `ext4` — the
> most common setup. Bound growth by capping logs and writing to volumes instead. See
> [Limiting Container Write Layers](storage.md#limiting-container-write-layers).

Sustained writes belong on a volume rather than the container's writable layer, which pays a
copy-on-write penalty — see [I/O Performance](storage.md#io-performance).

## Backup and Migration

> [!IMPORTANT]
> **`docker commit`, `docker save`, and `docker export` do not capture volume data.** They
> capture the image or the container's own filesystem layer; every mounted volume and bind
> mount is excluded. A "backup" made only with `commit` and `save` restores an application
> with none of its data. Always back up volumes separately, as shown below.
>
> `docker export` additionally discards image metadata — `ENTRYPOINT`, `CMD`, `ENV`, and
> layer history — so an imported filesystem will not start on its own without those being
> supplied again.

### Container State Backup

```bash
# Snapshot the container's filesystem layer as an image (no volumes)
docker commit myapp myapp:backup-$(date +%Y%m%d)

# Save an image, with its metadata and layers, to a tar
docker save myapp:latest > myapp-image.tar
docker load < myapp-image.tar

# Back up the data — this is the part that actually matters
for volume in $(docker volume ls -q); do
  docker run --rm \
    -v "$volume":/data:ro \
    -v "$(pwd)":/backup \
    alpine tar czf "/backup/$volume.tar.gz" -C /data .
done
```

Stop the containers using a volume before archiving it; a `tar` of a live database directory
restores into a corrupt database. For databases, prefer the engine's own dump tool. See
[Backup and Restore](storage.md#backup-and-restore).

### Container Migration

```bash
#!/bin/bash
set -euo pipefail

CONTAINER_NAME="myapp"
BACKUP_DIR="/backup"

# --- On the source host ---

# Prefer re-pulling the tagged image on the target over committing a mutated container.
# Use commit only when the running container has drifted from its image.
docker save "$CONTAINER_NAME:latest" > "$BACKUP_DIR/$CONTAINER_NAME.tar"

# Archive the volume contents (note -C so paths are relative)
docker run --rm \
  -v myapp_data:/source:ro \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/myapp_data.tar.gz -C /source .

# --- On the target host ---

docker load < "$BACKUP_DIR/$CONTAINER_NAME.tar"
docker volume create myapp_data
docker run --rm \
  -v myapp_data:/target \
  -v "$BACKUP_DIR":/backup \
  alpine tar xzf /backup/myapp_data.tar.gz -C /target
```

Streaming both hosts together avoids the intermediate files entirely — see
[Migrating a Volume Between Hosts](storage.md#migrating-a-volume-between-hosts).

## Related Topics

- [Docker Networking](networking.md) — network drivers, DNS, and port publishing in depth
- [Docker Storage](storage.md) — volumes, permissions, storage drivers, and pruning
- [Building Images](images.md) — Dockerfiles, BuildKit, and image optimization
- [Docker Compose](dockercompose/index.md) — running multi-container applications
- [Monitoring and Logging](monitoring.md) — stats, events, health checks, and log drivers
- [Daemon Configuration](daemon.md) — host-level defaults and restart policies
- [Docker Swarm](swarm.md) — running containers across multiple hosts
- [Container Security](../containers/security/index.md)
- [Container Orchestration](../containers/orchestration/index.md)
- [Infrastructure Monitoring](../monitoring/index.md)
