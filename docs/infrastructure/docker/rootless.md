---
title: "Rootless Docker and User Namespaces"
description: "Running Docker without root privileges using rootless mode or userns-remap, and the trade-offs of each"
tags: ["docker", "security", "rootless", "userns", "namespaces", "hardening"]
category: "infrastructure"
difficulty: "advanced"
last_updated: "2026-08-01"
---

## Rootless Docker and User Namespaces

By default the Docker daemon runs as root, and any user in the `docker` group can escalate to
root on the host trivially:

```bash
# Any docker group member can do this
docker run -v /:/host -it alpine chroot /host sh
```

That is not a bug — it follows from the daemon's privileges. But it means "give the developer
Docker access" is the same decision as "give the developer root", which is frequently not
what anyone intended.

Two mechanisms narrow this. **User namespace remapping** keeps the root daemon but maps
container UIDs to unprivileged host UIDs. **Rootless mode** runs the daemon itself as a
normal user. This page covers both, their limitations, and how to choose.

## Table of Contents

- [Choosing an Approach](#choosing-an-approach)
- [User Namespace Remapping](#user-namespace-remapping)
- [Rootless Docker](#rootless-docker)
- [Rootless Networking](#rootless-networking)
- [Resource Limits](#resource-limits)
- [Limitations](#limitations)
- [Troubleshooting](#troubleshooting)

## Choosing an Approach

| | Standard | `userns-remap` | Rootless |
| --- | ---- | -------------- | -------- |
| Daemon runs as | root | root | Unprivileged user |
| Container root maps to | Host root | Unprivileged host UID | Unprivileged host UID |
| `docker` group is root-equivalent | Yes | Yes | N/A — no group needed |
| Container escape reaches root | Yes | No | No |
| Host daemon compromise reaches root | Yes | **Yes** | No |
| Multi-user isolation on one host | No | No | Yes — one daemon per user |
| Performance | Baseline | Baseline | Slight network overhead |
| Feature completeness | Full | Near-full | Reduced |

The distinction that matters: **`userns-remap` protects the host from container breakout;
rootless additionally protects it from the daemon.** With `userns-remap` the daemon is still
root, so a daemon vulnerability or an unrestricted API socket is still a full compromise.

Practical guidance:

- **Shared build servers and CI runners** — rootless. Each user gets an isolated daemon and
  no root-equivalent group membership.
- **Developer workstations** — rootless, unless a needed feature is missing.
- **Production servers running trusted images** — `userns-remap` is easier to adopt and keeps
  every feature; use it if rootless limitations block you.
- **Anything needing macvlan, privileged containers, or host networking** — standard mode
  with careful access control, since neither alternative supports these.

## User Namespace Remapping

### How It Works

A container's UID 0 is mapped to some high, unprivileged host UID. A process that is root
inside the container is a nobody-equivalent user outside it, so a breakout lands with no
meaningful privileges.

### Setup

Docker can create and manage the mapping user itself:

```json
{
  "userns-remap": "default"
}
```

```bash
sudo systemctl restart docker
```

This creates a `dockremap` user and allocates subordinate UID/GID ranges:

```bash
id dockremap
cat /etc/subuid
cat /etc/subgid
# dockremap:231072:65536
```

The container's UID 0 becomes host UID 231072, UID 1 becomes 231073, and so on for 65536
IDs.

To use a specific user instead:

```bash
sudo useradd -r -s /usr/sbin/nologin dockerns
echo "dockerns:500000:65536" | sudo tee -a /etc/subuid
echo "dockerns:500000:65536" | sudo tee -a /etc/subgid
```

```json
{
  "userns-remap": "dockerns"
}
```

### Verifying

```bash
docker run --rm alpine id
# uid=0(root) gid=0(root)   <- inside the container

# On the host, while a container sleeps
docker run -d --name t alpine sleep 300
ps -o user,pid,cmd -p "$(docker inspect -f '{{.State.Pid}}' t)"
# USER 231072 ... sleep 300  <- unprivileged on the host
docker rm -f t
```

### What Changes on Disk

Docker relocates its data root per mapping:

```bash
ls /var/lib/docker/
# 231072.231072/   <- images, containers, volumes for this mapping
```

Existing images and containers under the old path become invisible. Plan the switch as a
rebuild, or export first:

```bash
docker save -o images.tar $(docker images -q)
# ... enable userns-remap, restart ...
docker load -i images.tar
```

Volume ownership shifts by the same offset, which is the most common surprise:

```bash
# A file owned by container UID 1000 appears on the host as
ls -ln /var/lib/docker/231072.231072/volumes/appdata/_data
# owner 232072  (231072 + 1000)
```

Bind mounts need host ownership set to the *remapped* UID:

```bash
# Container wants UID 1000 to own /data; the offset is 231072
sudo chown -R 232072:232072 /srv/appdata
docker run -v /srv/appdata:/data --user 1000:1000 myapp
```

See [Permissions and Ownership](storage.md#permissions-and-ownership) for the underlying
model.

### Per-Container Opt-Out

Individual containers can bypass remapping when they genuinely need host privileges:

```bash
docker run --rm --userns=host --privileged some-tool
```

This restores full root equivalence for that container, so it defeats the protection —
restrict who can run it.

### Limitations

`userns-remap` is incompatible with:

- `--network=host` and `--pid=host`
- `--privileged`, unless combined with `--userns=host`
- Volume and storage drivers unaware of the ID mapping

## Rootless Docker

The daemon runs entirely as an unprivileged user inside its own user namespace, created by
RootlessKit. No root, no `docker` group.

### Prerequisites

```bash
# Debian/Ubuntu
sudo apt-get install -y uidmap dbus-user-session fuse-overlayfs slirp4netns

# RHEL/Fedora
sudo dnf install -y shadow-utils fuse-overlayfs slirp4netns
```

Confirm subordinate ID ranges exist for your user — most distributions create them at user
creation:

```bash
grep "^$(whoami):" /etc/subuid /etc/subgid
# joseph:100000:65536
```

If missing:

```bash
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$(whoami)"
```

### Unprivileged User Namespaces

Rootless mode depends on the kernel allowing unprivileged processes to create user
namespaces. Two distinct restrictions exist, and applying the wrong fix is a common time
sink — check which sysctl your system actually has:

```bash
sysctl kernel.unprivileged_userns_clone 2>/dev/null
sysctl kernel.apparmor_restrict_unprivileged_userns 2>/dev/null
```

**Ubuntu 23.10 and later** ship an AppArmor restriction that blocks unconfined binaries from
creating user namespaces. This is the blocker you are most likely to hit today, and it
surfaces as `rootlesskit: failed to setup UID/GID map` or a permission error during install:

```bash
# Confirm it is enabled (1 = restricted)
sysctl kernel.apparmor_restrict_unprivileged_userns
```

The targeted fix is an AppArmor profile permitting `rootlesskit`:

```bash
cat <<'EOF' | sudo tee /etc/apparmor.d/rootlesskit
abi <abi/4.0>,
include <tunables/global>

/usr/bin/rootlesskit flags=(unconfined) {
  userns,
  include if exists <local/rootlesskit>
}
EOF
sudo systemctl restart apparmor.service
```

Disabling the restriction host-wide also works, but removes the protection for every binary:

```bash
echo 'kernel.apparmor_restrict_unprivileged_userns=0' \
  | sudo tee /etc/sysctl.d/50-apparmor-userns.conf
sudo sysctl --system
```

**Older Debian kernels** used a different sysctl, `kernel.unprivileged_userns_clone`. It
defaults to `1` on current Debian releases, so it rarely needs changing — but if the sysctl
exists and reads `0`:

```bash
echo 'kernel.unprivileged_userns_clone=1' | sudo tee /etc/sysctl.d/50-userns.conf
sudo sysctl --system
```

> [!NOTE]
> These are mutually exclusive in practice: Ubuntu 23.10+ has the AppArmor knob and not the
> `unprivileged_userns_clone` one; Debian has the reverse. RHEL and Fedora have neither and
> permit user namespaces by default.

### Installation

If a rootful daemon is installed, disable it first so the two do not contend:

```bash
sudo systemctl disable --now docker.service docker.socket
```

Then, as your normal user — **not** with `sudo`:

```bash
dockerd-rootless-setuptool.sh install
```

The script installs a user-level systemd unit and prints the environment to set:

```bash
export PATH=/usr/bin:$PATH
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
```

Persist those in your shell profile, then:

```bash
systemctl --user enable --now docker
systemctl --user status docker

# Keep the daemon running when you are not logged in
sudo loginctl enable-linger "$(whoami)"
```

`enable-linger` is easy to forget and its absence is confusing: containers work while you
are logged in and vanish when you disconnect.

### Verifying

```bash
docker info | grep -i -E 'rootless|storage driver|cgroup'
# Context:  rootless
# Storage Driver: overlay2
# Cgroup Driver: systemd
# Cgroup Version: 2

docker run --rm alpine id       # uid=0 inside
ps -u "$(whoami)" | grep dockerd # daemon owned by you on the host
```

### Using a Context

Rather than exporting `DOCKER_HOST` globally, define a context — this keeps a rootful daemon
usable alongside:

```bash
docker context create rootless \
  --docker "host=unix:///run/user/$(id -u)/docker.sock"
docker context use rootless
```

See [Docker Contexts](daemon.md#docker-contexts).

### Configuration

Rootless reads its own paths:

| Purpose | Path |
| ------- | ---- |
| Daemon config | `~/.config/docker/daemon.json` |
| Data root | `~/.local/share/docker` |
| CLI config | `~/.docker/config.json` |
| systemd unit | `~/.config/systemd/user/docker.service` |

```bash
systemctl --user edit docker      # drop-in overrides
systemctl --user restart docker
journalctl --user -u docker -f
```

## Rootless Networking

An unprivileged process cannot create host network interfaces, so rootless Docker routes
container traffic through a userspace network stack — `slirp4netns` by default, with
`pasta` available and generally faster.

```bash
# Select the port forwarding and network drivers
systemctl --user edit docker
```

```ini
[Service]
Environment="DOCKERD_ROOTLESS_ROOTLESSKIT_NET=pasta"
Environment="DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER=implicit"
```

### Privileged Ports

Binding below port 1024 is not permitted by default:

```bash
docker run -d -p 80:80 nginx
# Error: cannot expose privileged port 80
```

Three options:

```bash
# 1. Publish a high port and redirect at the host, or front it with a proxy
docker run -d -p 8080:80 nginx

# 2. Lower the threshold system-wide (affects all unprivileged processes)
echo 'net.ipv4.ip_unprivileged_port_start=80' | sudo tee /etc/sysctl.d/50-unprivileged-ports.conf
sudo sysctl --system

# 3. Grant the capability to rootlesskit specifically
sudo setcap cap_net_bind_service=ep "$(which rootlesskit)"
systemctl --user restart docker
```

Option 3 is the most targeted. Note it must be reapplied after a Docker package upgrade
replaces the binary.

### Source IP Preservation

With the default `slirp4netns` port driver, incoming connections appear to originate from
`127.0.0.1` rather than the real client — which breaks access logs, rate limiting, and
IP-based access control.

```ini
[Service]
Environment="DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER=slirp4netns"
```

The `slirp4netns` port driver preserves the source address at some throughput cost; the
default `builtin` driver is faster but does not. Choose based on whether the application
needs client IPs.

### Performance

Userspace networking is slower than the kernel bridge path. For throughput-sensitive
workloads, `pasta` substantially narrows the gap over `slirp4netns`, and
`--network=host` inside the RootlessKit namespace avoids the userspace hop entirely — though
"host" there means the RootlessKit network namespace, not the real host.

## Resource Limits

CPU and memory limits in rootless mode require **cgroup v2** with systemd delegation.

```bash
# Confirm cgroup v2
stat -fc %T /sys/fs/cgroup/
# cgroup2fs

docker info | grep -i cgroup
```

Delegate the needed controllers to user sessions:

```bash
sudo mkdir -p /etc/systemd/system/user@.service.d
cat <<'EOF' | sudo tee /etc/systemd/system/user@.service.d/delegate.conf
[Service]
Delegate=cpu cpuset io memory pids
EOF
sudo systemctl daemon-reload
```

Log out and back in, then:

```bash
docker run --rm --memory 512m --cpus 1.5 alpine echo ok
```

Without delegation, `--memory` and `--cpus` are silently ignored — the container runs
unconstrained rather than failing, which is worth knowing before relying on limits.

## Limitations

### Rootless

Not supported:

- **macvlan and ipvlan** networks — creating them requires `NET_ADMIN` on a host device
- **Overlay networks** and Swarm mode
- **`--privileged`** containers with real host capabilities
- **AppArmor** profiles
- **Checkpoint and restore**
- Binding **privileged ports** without extra configuration
- Mounting arbitrary host filesystems (NFS, CIFS) that require privileged mount operations

Constrained:

- Storage drivers limited to `overlay2` (with `fuse-overlayfs` on older kernels), `btrfs`,
  and `vfs`
- Resource limits need cgroup v2 plus delegation
- Network throughput lower than rootful
- `--network=host` is scoped to the RootlessKit namespace

Volume mounts, bind mounts, Compose, BuildKit, buildx, and health checks all work normally.

### userns-remap

Covered [above](#limitations): no `--network=host`, no `--pid=host`, no `--privileged`
without `--userns=host`, and volume/storage plugins must understand the mapping.

## Troubleshooting

| Symptom | Cause and fix |
| ------- | ------------- |
| `Cannot connect to the Docker daemon` (rootless) | `DOCKER_HOST` unset, or the user service is not running |
| Containers stop when you log out | `loginctl enable-linger` not set |
| `newuidmap: write to uid_map failed` | Missing or wrong `/etc/subuid`/`/etc/subgid` entries |
| `rootlesskit: failed to setup UID/GID map` | On Ubuntu 23.10+, the AppArmor userns restriction — see [Unprivileged User Namespaces](#unprivileged-user-namespaces) |
| `cannot expose privileged port` | See [Privileged Ports](#privileged-ports) |
| `--memory` and `--cpus` have no effect | cgroup v2 delegation missing |
| Images "disappeared" after enabling `userns-remap` | New data root under `/var/lib/docker/<uid>.<gid>/` |
| Permission denied on a bind mount after `userns-remap` | Chown the host path to the remapped UID |
| Client IPs show as `127.0.0.1` | Rootless port driver; see [Source IP](#source-ip-preservation) |
| `failed to mount overlay` | Install `fuse-overlayfs` |

```bash
# Rootless daemon logs
journalctl --user -u docker -n 50

# Confirm which daemon you are talking to
docker context ls
docker info -f '{{.SecurityOptions}}'
# [name=seccomp,profile=builtin/default name=rootless name=cgroupns]

# Inspect the actual ID mapping of a running container
cat /proc/$(docker inspect -f '{{.State.Pid}}' mycontainer)/uid_map
```

### Uninstalling Rootless

```bash
dockerd-rootless-setuptool.sh uninstall
rootlesskit rm -rf ~/.local/share/docker
```

## Related Topics

- [Daemon Configuration](daemon.md) — `daemon.json`, systemd units, and socket permissions
- [Docker Storage](storage.md) — how ID mapping affects volume ownership
- [Docker Networking](networking.md) — what rootless networking gives up
- [Container Security](../containers/security/index.md) — capabilities, seccomp, and non-root users
