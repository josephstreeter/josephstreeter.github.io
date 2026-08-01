---
title: "Docker Storage"
description: "Volumes, bind mounts, storage drivers, permissions, disk usage, and I/O performance"
tags: ["docker", "containers", "storage", "volumes", "overlay2", "permissions"]
category: "infrastructure"
difficulty: "intermediate"
last_updated: "2026-08-01"
---

## Docker Storage

Containers are ephemeral; their filesystems are not meant to survive. Anything that must
outlive a container — database files, uploads, logs worth keeping — has to live on a mount.
This page covers how Docker stores data, how to choose between the mount types, and the two
areas that cause the most trouble in practice: **permissions on bind mounts** and
**disk usage that grows without obvious cause**.

## Table of Contents

- [Mount Types](#mount-types)
- [Named Volumes](#named-volumes)
- [Bind Mounts](#bind-mounts)
- [Permissions and Ownership](#permissions-and-ownership)
- [tmpfs Mounts](#tmpfs-mounts)
- [Volume Drivers](#volume-drivers)
- [Storage Drivers and Layers](#storage-drivers-and-layers)
- [Disk Usage and Pruning](#disk-usage-and-pruning)
- [I/O Performance](#io-performance)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)

## Mount Types

| Type | Managed by | Survives container removal | Portable | Typical use |
| ---- | ---------- | -------------------------- | -------- | ----------- |
| Named volume | Docker | Yes | Yes | Database data, application state |
| Bind mount | You | Yes (it is a host path) | No | Source code in development, host config |
| `tmpfs` | Kernel (RAM) | No | N/A | Secrets, scratch space |

The general rule: **named volumes for data the application owns, bind mounts for files you
own.** A database's data directory belongs in a named volume. A configuration file you edit
by hand belongs in a bind mount.

### `-v` vs `--mount`

Both flags work, but they behave differently in one important way:

```bash
# Short form — if /host/path does not exist, Docker CREATES it as a root-owned directory
docker run -v /host/path:/data alpine

# Long form — if the source does not exist, Docker ERRORS
docker run --mount type=bind,source=/host/path,target=/data alpine
```

The silent-directory-creation behavior of `-v` turns a typo in a host path into an empty
mount, and the application starts with no data and no error. Prefer `--mount` in anything
scripted or committed; it is explicit and it fails loudly.

```bash
# --mount syntax
docker run --mount type=volume,source=appdata,target=/var/lib/app myapp
docker run --mount type=bind,source="$(pwd)"/conf,target=/etc/app,readonly myapp
docker run --mount type=tmpfs,target=/tmp,tmpfs-size=100m myapp
```

## Named Volumes

```bash
docker volume create appdata
docker volume ls
docker volume inspect appdata
docker volume rm appdata

# Use it
docker run -d --name db -v appdata:/var/lib/postgresql/data postgres:16
```

Volumes live under `/var/lib/docker/volumes/<name>/_data` on Linux. You can read that path
directly for debugging, but do not write to it while a container is running.

### Anonymous Volumes

If an image declares `VOLUME /data` and you do not supply a mount, Docker creates an
**anonymous volume** with a random name. These accumulate — every `docker run` of such an
image leaves another one behind:

```bash
# Find them
docker volume ls -f dangling=true

# Remove the container and its anonymous volumes together
docker rm -v mycontainer

# Always clean up throwaway containers
docker run --rm -v /data alpine
```

### The First-Mount Copy

This behavior explains why named volumes "just work" where bind mounts do not:

> [!IMPORTANT]
> When an **empty named volume** is mounted, Docker copies the image's existing content at
> that path into the volume, **including ownership and permissions**. This happens only
> once, only for named volumes, and only when the volume is empty. Bind mounts never do
> this — they shadow the image content entirely.

So `postgres:16` with a named volume gets a data directory owned by the `postgres` user
automatically, while the same image with an empty bind-mounted host directory gets a
root-owned empty directory and fails to initialize.

### Read-Only Mounts

```bash
docker run -d --mount source=config,target=/etc/app,readonly myapp
docker run -d -v config:/etc/app:ro myapp

# Make the whole container filesystem read-only, with writable exceptions
docker run -d --read-only \
  --tmpfs /tmp \
  --mount source=appdata,target=/var/lib/app \
  myapp
```

`--read-only` is a strong hardening measure — see
[Container Security](../containers/security/index.md).

## Bind Mounts

```bash
# Development: live source code
docker run -d \
  --mount type=bind,source="$(pwd)"/src,target=/app/src \
  -p 3000:3000 \
  node:20 npm run dev

# Read-only host configuration
docker run -d \
  --mount type=bind,source=/etc/myapp/config.yml,target=/etc/app/config.yml,readonly \
  myapp
```

### Mount Propagation

When the host path is itself a mount point that changes, propagation controls whether the
container sees it:

```bash
docker run -d \
  --mount type=bind,source=/mnt/storage,target=/data,bind-propagation=rslave \
  myapp
```

| Mode | Behavior |
| ---- | -------- |
| `rprivate` | Default. Neither side sees the other's new sub-mounts. |
| `rslave` | Container sees host sub-mounts; host does not see container's. |
| `rshared` | Both directions propagate. |

`rslave` is what you want when the host mounts removable media or network shares under the
bind-mounted path after the container starts.

### SELinux Labels

On RHEL, Fedora, CentOS, and other SELinux-enforcing systems, a bind mount is inaccessible
until it carries a container-compatible label:

```bash
# :z — shared label, multiple containers may access
docker run -v /host/data:/data:z myapp

# :Z — private label, this container only
docker run -v /host/data:/data:Z myapp
```

> [!WARNING]
> `:Z` **relabels the host directory recursively**. Pointing it at `/home`, `/usr`, or
> another system directory will relabel everything underneath and can break the host. Only
> apply it to directories created for the container.

## Permissions and Ownership

This is the most common source of "permission denied" in Docker, and the mechanics are
straightforward once stated plainly.

**The kernel checks numeric UIDs and GIDs, not names.** A container has its own
`/etc/passwd`, so UID 1000 might be `node` inside and `joseph` on the host — but they are
the same UID, and that is all the kernel compares. There is no translation layer on a bind
mount.

```bash
# What UID does the container run as?
docker run --rm myapp id

# What owns the host directory?
ls -ln /host/data
```

If those numbers do not match and the directory is not world-writable, writes fail.

### Three Ways to Fix It

**1. Run the container as the host user.** Best for development bind mounts:

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --mount type=bind,source="$(pwd)",target=/work \
  -w /work \
  alpine touch newfile
```

The caveat is that the UID may not exist in the container's `/etc/passwd`, so the shell
shows `I have no name!` and `$HOME` may be unset. That is cosmetic for most tooling, but
software that looks itself up by UID will complain. Supplying `--user` with a group the
image already defines, or passing `-e HOME=/tmp`, usually settles it.

**2. Chown the host directory to the container's UID:**

```bash
# Find the UID the image uses
docker run --rm postgres:16 id -u postgres    # 999

sudo chown -R 999:999 /srv/postgres-data
```

**3. Use a named volume instead**, and let the first-mount copy set ownership correctly.
For service data this is nearly always the right answer.

### Entrypoint Chown Pattern

Many official images start as root, fix ownership, then drop privileges with `gosu` or
`su-exec`. If you write your own image and need this:

```dockerfile
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["entrypoint.sh"]
```

```bash
#!/bin/sh
set -e
# Fix ownership of the mounted data directory, then drop privileges
chown -R app:app /var/lib/app
exec su-exec app "$@"
```

This requires the container to start as root, which conflicts with a `--user` override.
Document which model your image expects.

### User Namespace Remapping

With `userns-remap` enabled, container UID 0 maps to an unprivileged host UID, and file
ownership on volumes shifts by that offset. This changes every calculation above. See
[Rootless Docker and User Namespaces](rootless.md).

## tmpfs Mounts

`tmpfs` mounts live in RAM and never touch disk — appropriate for secrets and scratch data:

```bash
docker run -d \
  --tmpfs /app/secrets:noexec,nosuid,size=10m \
  --tmpfs /tmp:noexec,nosuid,size=1g \
  myapp

# --mount equivalent
docker run -d \
  --mount type=tmpfs,target=/app/cache,tmpfs-size=536870912,tmpfs-mode=1770 \
  myapp
```

Always set `size` — an unbounded `tmpfs` can consume all host memory. `noexec` and `nosuid`
should be the default for anything holding data rather than programs.

> [!NOTE]
> `tmpfs` is Linux-only. On Swarm, the equivalent is `--mount type=tmpfs` in the service
> definition; for secrets specifically, prefer [Swarm secrets](swarm.md), which are already
> delivered via an in-memory filesystem.

## Volume Drivers

The built-in `local` driver accepts the same options as `mount(8)`, which is enough to
attach network storage without any plugin.

### NFS

```bash
docker volume create \
  --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.1.100,rw,nfsvers=4,hard,timeo=600 \
  --opt device=:/exports/appdata \
  nfs-appdata

docker run -d -v nfs-appdata:/data myapp
```

In Compose:

```yaml
volumes:
  nfs-appdata:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=192.168.1.100,rw,nfsvers=4,hard,timeo=600"
      device: ":/exports/appdata"
```

> [!TIP]
> Use `hard` rather than `soft` for data you cannot afford to corrupt: a `soft` mount returns
> I/O errors when the server is unreachable, and many applications handle that badly. `hard`
> blocks until the server returns.

### CIFS/SMB

```bash
docker volume create \
  --driver local \
  --opt type=cifs \
  --opt device=//192.168.1.50/share \
  --opt o=username=svc_docker,password=secret,uid=1000,gid=1000,vers=3.0 \
  smb-share
```

CIFS has no concept of Unix ownership by default, so `uid`/`gid` in the options set what
every file appears to be owned by inside the container — which conveniently sidesteps the
permission problem above.

> [!WARNING]
> This puts a password in the volume definition, visible via `docker volume inspect` and in
> any committed Compose file. Use a credentials file (`credentials=/root/.smbcreds`) with
> restrictive permissions instead.

### Third-Party Plugins

```bash
docker plugin install vieux/sshfs
docker plugin ls
docker volume create -d vieux/sshfs -o sshcmd=user@host:/path -o password=secret sshvol
```

Plugins exist for most cloud block storage and clustered filesystems. Evaluate them
carefully — a volume plugin failure takes the data path down with it.

## Storage Drivers and Layers

### How Layers Work

An image is a stack of read-only layers. A running container adds a thin writable layer on
top. Reads fall through the stack until the file is found; writes go to the writable layer.

The mechanism is **copy-on-write**: modifying a file that lives in a lower layer first
copies the *entire file* upward, then modifies the copy. Two consequences follow:

- Changing one byte of a 2 GB file costs a 2 GB copy and 2 GB of disk.
- Write-heavy workloads on the container filesystem are markedly slower than on a volume.

This is the technical reason databases must use volumes, not merely a stylistic preference.

### overlay2

`overlay2` is the default and the right choice on every modern Linux distribution:

```bash
docker info | grep -A5 'Storage Driver'
```

It composes a view from several directories under `/var/lib/docker/overlay2/`:

| Directory | Role |
| --------- | ---- |
| `lowerdir` | The read-only image layers |
| `upperdir` | The container's writable layer |
| `merged` | The unified view the container actually sees |
| `workdir` | Internal scratch space overlayfs requires |

```bash
# See the layer directories for a container
docker inspect -f '{{json .GraphDriver.Data}}' mycontainer | jq
```

### Selecting a Driver

Set it in `/etc/docker/daemon.json` — see [Daemon Configuration](daemon.md):

```json
{
  "storage-driver": "overlay2"
}
```

| Driver | Status |
| ------ | ------ |
| `overlay2` | Default. Use this. |
| `fuse-overlayfs` | For rootless Docker on kernels without unprivileged overlayfs |
| `btrfs` / `zfs` | Only when `/var/lib/docker` is already on that filesystem; enables snapshots |
| `vfs` | No copy-on-write — full copy per layer. Very slow and space-hungry; a testing fallback only |
| `devicemapper` | Removed from current releases; migrate off it |

> [!WARNING]
> Changing the storage driver makes existing images and containers invisible — the daemon
> looks for them in a different backend. Export anything you need first, and plan for
> `/var/lib/docker` to be rebuilt.

### Backing Filesystem

`overlay2` requires `d_type` support in the backing filesystem. `ext4` and `xfs` (formatted
with `ftype=1`) both provide it; XFS formatted without it silently misbehaves:

```bash
docker info | grep -i 'backing filesystem'
xfs_info /var/lib/docker | grep ftype
```

If `ftype=0`, the filesystem must be recreated — it cannot be changed in place.

## Disk Usage and Pruning

Docker disk consumption grows quietly. Images, stopped containers, unused volumes, and the
build cache all accumulate, and the build cache in particular can reach tens of gigabytes
without anyone noticing.

### Finding Where Space Went

```bash
# Summary by category
docker system df

# Per-object detail — this is the one that finds the culprit
docker system df -v
```

```text
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          42        12        18.3GB    12.1GB (66%)
Containers      15        8         1.2GB     840MB (70%)
Local Volumes   23        9         31.4GB    22.8GB (72%)
Build Cache     318       0         14.7GB    14.7GB
```

### Pruning Safely

```bash
# Stopped containers
docker container prune

# Dangling images (untagged, unreferenced)
docker image prune

# ALL images not used by a running container — aggressive
docker image prune -a

# Build cache
docker builder prune
docker builder prune --filter 'until=168h'    # older than a week

# Everything except volumes
docker system prune

# Everything, volumes included
docker system prune -a --volumes
```

> [!CAUTION]
> `docker system prune` does **not** touch volumes unless you pass `--volumes` — a deliberate
> safety default, since volumes hold the data that matters. Conversely, once you do pass
> `--volumes`, any volume not attached to a container is deleted permanently. Confirm with
> `docker volume ls -f dangling=true` before running it, and never run it unattended on a
> host where containers are recreated on a schedule: a volume is "unused" during the gap
> between `docker compose down` and `docker compose up`.

### Volume Pruning Specifics

```bash
# Removes ANONYMOUS unused volumes only
docker volume prune

# Also removes unused NAMED volumes
docker volume prune -a
```

The default deliberately spares named volumes, on the reasoning that anything you bothered
to name is probably data you want.

### Scheduled Cleanup

```bash
#!/bin/bash
# /usr/local/bin/docker-cleanup.sh
set -euo pipefail

# Conservative: containers, dangling images, and old build cache only.
# Volumes and tagged images are deliberately left alone.
docker container prune -f --filter 'until=24h'
docker image prune -f
docker builder prune -f --filter 'until=168h'

docker system df
```

```bash
# Weekly, via systemd timer or cron
0 4 * * 0 /usr/local/bin/docker-cleanup.sh >> /var/log/docker-cleanup.log 2>&1
```

### Log Files

Container logs are not covered by any prune command and are a frequent cause of a full disk.
Cap them in `daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
```

See [Daemon Configuration](daemon.md) and [Monitoring and Logging](monitoring.md).

### Limiting Container Write Layers

On `xfs` or `btrfs` backing storage with the appropriate driver, a per-container quota is
available:

```bash
docker run -d --storage-opt size=10G myapp
```

This is unsupported on `overlay2` over `ext4`, where it returns an error. Where it is not
available, bound growth by capping logs and directing writes to volumes.

## I/O Performance

### Choose the Right Location for Writes

In descending order of throughput:

1. **`tmpfs`** — RAM, fastest, non-persistent
2. **Named volume** — direct filesystem access, no copy-on-write overhead
3. **Bind mount** — equivalent to a named volume on Linux
4. **Container writable layer** — copy-on-write penalty on every first write

Anything doing sustained writes — databases, message queues, build caches — belongs on a
volume.

### Docker Desktop

On macOS and Windows, containers run inside a Linux VM and bind mounts cross a filesystem
bridge, which is dramatically slower than native. A dependency install into a bind-mounted
`node_modules` can be an order of magnitude slower than the same operation in a volume.

```yaml
services:
  app:
    volumes:
      - .:/app                 # source: bind mount, needs to be live-editable
      - node_modules:/app/node_modules   # dependencies: volume, stays fast
volumes:
  node_modules:
```

Enabling VirtioFS in Docker Desktop's settings substantially narrows the gap on macOS.
On Windows, keeping project files inside the WSL2 filesystem rather than under `/mnt/c`
matters far more than any Docker setting.

### Measuring

```bash
# Write throughput to a volume
docker run --rm -v testvol:/data alpine \
  dd if=/dev/zero of=/data/testfile bs=1M count=1024 oflag=direct

# Compare against the container's writable layer
docker run --rm alpine \
  dd if=/dev/zero of=/testfile bs=1M count=1024 oflag=direct

# Live block I/O per container
docker stats --format "table {{.Name}}\t{{.BlockIO}}"
```

### Throttling

```bash
docker run -d \
  --device-read-bps /dev/sda:50mb \
  --device-write-bps /dev/sda:50mb \
  --device-write-iops /dev/sda:1000 \
  --blkio-weight 500 \
  myapp
```

Useful for keeping a batch job from starving interactive services on shared hardware.

## Backup and Restore

### Backing Up a Volume

```bash
docker run --rm \
  -v appdata:/data:ro \
  -v "$(pwd)":/backup \
  alpine tar czf /backup/appdata-$(date +%F).tar.gz -C /data .
```

### Restoring

```bash
docker run --rm \
  -v appdata:/data \
  -v "$(pwd)":/backup \
  alpine sh -c 'rm -rf /data/* && tar xzf /backup/appdata-2026-08-01.tar.gz -C /data'
```

> [!IMPORTANT]
> Stop the containers using a volume before backing it up. A `tar` of a live database
> directory produces a file that restores into a corrupt database. For databases, use the
> engine's own dump tool (`pg_dump`, `mysqldump`) instead of copying files.

For Compose-managed stacks, see the backup and restore scripts in
[Docker Compose](dockercompose/index.md#backup-and-restore).

### Migrating a Volume Between Hosts

```bash
# On the source host
docker run --rm -v appdata:/data:ro alpine tar czf - -C /data . \
  | ssh user@newhost 'docker run --rm -i -v appdata:/data alpine tar xzf - -C /data'
```

The destination volume must already exist — create it with `docker volume create appdata`.

## Troubleshooting

| Symptom | Cause and fix |
| ------- | ------------- |
| `permission denied` writing to a bind mount | UID mismatch — see [Permissions](#permissions-and-ownership) |
| Bind mount is empty | Host path did not exist and `-v` created it; use `--mount` to catch this |
| Data vanished after `docker compose down` | Anonymous volume, or `down -v` was used; declare named volumes |
| Volume in use, cannot remove | `docker ps -a --filter volume=<name>` to find the holder |
| Disk full despite pruning | Build cache or container logs — `docker system df -v`, then cap log size |
| Changes to image files are slow | Copy-on-write on a large file; move it to a volume |
| `no space left on device` with free disk | Inode exhaustion — `df -i` |

### Finding What Holds a Volume

```bash
docker ps -a --filter volume=appdata
docker volume inspect appdata
```

### Inspecting Volume Contents

```bash
# Read-only look at a volume without disturbing the app
docker run --rm -it -v appdata:/data:ro alpine sh
```

### Disk Full on `/var/lib/docker`

If `/var/lib/docker` shares a partition with the OS, a runaway image or log can take the host
down. Moving it to its own filesystem is worthwhile on any server that matters:

```json
{
  "data-root": "/srv/docker"
}
```

Stop the daemon, copy the existing tree with `rsync -aHAX /var/lib/docker/ /srv/docker/`,
then restart. See [Daemon Configuration](daemon.md).

## Related Topics

- [Daemon Configuration](daemon.md) — storage driver, data root, and log limits
- [Docker Networking](networking.md) — the other half of container infrastructure
- [Building Images](images.md) — layer caching and how images consume disk
- [Docker Compose](dockercompose/index.md) — declaring volumes in a stack
- [Rootless Docker](rootless.md) — how user namespaces change volume ownership
- [Container Security](../containers/security/index.md) — read-only filesystems and mount hardening
