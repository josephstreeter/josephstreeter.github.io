---
title: "GPU and Device Access"
description: "Passing NVIDIA GPUs, integrated graphics, and other host devices into containers"
tags: ["docker", "gpu", "nvidia", "devices", "cuda", "transcoding"]
category: "infrastructure"
difficulty: "advanced"
last_updated: "2026-08-01"
---

## GPU and Device Access

Containers see no host hardware by default beyond a minimal set of pseudo-devices. Anything
physical — a GPU for model inference, an Intel iGPU for video transcoding, a USB radio for
home automation — has to be passed in explicitly.

For NVIDIA GPUs that means installing the NVIDIA Container Toolkit and using `--gpus`.
Everything else is generally a `--device` mapping plus getting the group permissions right.

## Table of Contents

- [NVIDIA GPUs](#nvidia-gpus)
- [Installing the Container Toolkit](#installing-the-container-toolkit)
- [Running GPU Containers](#running-gpu-containers)
- [GPUs in Compose](#gpus-in-compose)
- [Integrated and AMD Graphics](#integrated-and-amd-graphics)
- [Other Host Devices](#other-host-devices)
- [Rootless and Swarm](#rootless-and-swarm)
- [Troubleshooting](#troubleshooting)

## NVIDIA GPUs

### How It Works

The **host** provides the NVIDIA kernel driver. The **container** provides the CUDA
userspace libraries. The NVIDIA Container Toolkit bridges the two: it hooks container
creation, injects the correct driver libraries and device nodes from the host into the
container, and leaves the CUDA toolkit in the image untouched.

The practical consequence is that **the container's CUDA version must be supported by the
host driver**, but you do not install the driver inside the container. Never try to.

### Prerequisites

The host driver must already be working:

```bash
nvidia-smi
```

If that fails, fix it before touching Docker — no container configuration compensates for a
missing or broken host driver.

## Installing the Container Toolkit

### Debian and Ubuntu

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -sL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

### RHEL, CentOS, and Fedora

```bash
curl -sL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
  | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

sudo dnf install -y nvidia-container-toolkit
```

> [!WARNING]
> Many guides still use `nvidia.github.io/nvidia-docker/` with `apt-key add`. Both are
> obsolete: the repository moved to `libnvidia-container`, and `apt-key` has been removed
> from current Debian and Ubuntu releases. The `nvidia-docker2` package and the
> `nvidia-docker` wrapper command are likewise superseded — `--gpus` replaced them.

### Configure the Docker Runtime

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

That writes the `nvidia` runtime into `/etc/docker/daemon.json`:

```json
{
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "args": []
    }
  }
}
```

Confirm the daemon picked it up:

```bash
docker info | grep -i runtime
```

To make every container GPU-capable without passing `--gpus`, set the default runtime — see
[Daemon Configuration](daemon.md#runtime-and-security-defaults):

```json
{
  "default-runtime": "nvidia"
}
```

`default-runtime` is one of the few options that applies on `systemctl reload docker`.

### Verify

```bash
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

Seeing the same GPU table as on the host means the whole chain works.

## Running GPU Containers

```bash
# All GPUs
docker run --rm --gpus all myimage

# A specific GPU by index
docker run --rm --gpus '"device=0"' myimage

# Several by index — note the nested quoting
docker run --rm --gpus '"device=0,1"' myimage

# By UUID, which survives reordering across reboots
docker run --rm --gpus '"device=GPU-4a2b1c3d-..."' myimage

# A count rather than specific devices
docker run --rm --gpus 2 myimage

# Restrict capabilities
docker run --rm --gpus 'all,capabilities=compute,utility' myimage
```

The nested quoting on `device=` is a genuine requirement, not a typo — the shell must pass
the double quotes through to Docker.

```bash
# List UUIDs
nvidia-smi --query-gpu=index,name,uuid --format=csv
```

### Environment Variables

The toolkit also reads these, which is how most CUDA images are configured:

| Variable | Purpose |
|----------|---------|
| `NVIDIA_VISIBLE_DEVICES` | `all`, `none`, indices, or UUIDs |
| `NVIDIA_DRIVER_CAPABILITIES` | `compute,utility`, `video`, `graphics`, or `all` |
| `NVIDIA_REQUIRE_CUDA` | Driver version constraint, e.g. `cuda>=12.0` |

```bash
docker run --rm \
  -e NVIDIA_VISIBLE_DEVICES=0 \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  myimage
```

`video` is required for NVENC/NVDEC hardware transcoding; `compute` alone will not expose the
encoder.

## GPUs in Compose

Two forms work. The newer `gpus` key is simpler:

```yaml
services:
  inference:
    image: myapp:latest
    gpus: all
```

```yaml
services:
  inference:
    image: myapp:latest
    gpus:
      - driver: nvidia
        device_ids: ["0"]
        capabilities: [gpu]
```

The older form nests under `deploy`, and is still what most examples show:

```yaml
services:
  inference:
    image: myapp:latest
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

> [!NOTE]
> `deploy.resources` is one of the `deploy` keys that `docker compose up` **does** honor, so
> this works outside Swarm despite living under `deploy`. See
> [Compose Differences](swarm.md#compose-differences) for which `deploy` keys are and are not
> applied.

Use `count: all` or `device_ids` — not both. `count` and specific IDs are mutually exclusive.

## Integrated and AMD Graphics

Intel QuickSync and AMD graphics need no vendor toolkit; the kernel driver exposes
`/dev/dri` and you pass it through directly. This is the common path for hardware video
transcoding in Jellyfin, Plex, and Frigate.

```bash
docker run -d \
  --device /dev/dri:/dev/dri \
  --group-add "$(getent group render | cut -d: -f3)" \
  jellyfin/jellyfin
```

```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin
    devices:
      - /dev/dri:/dev/dri
    group_add:
      - "989"   # the host's "render" GID — check with: getent group render
```

> [!IMPORTANT]
> The permission problem here is the usual one. `/dev/dri/renderD128` is owned by the
> `render` group (or `video` on older distributions), and the container's user must be in a
> group with that **numeric GID**. Group *names* do not carry across the boundary — see
> [Permissions and Ownership](storage.md#permissions-and-ownership).
>
> ```bash
> ls -l /dev/dri/
> getent group render video
> ```

AMD ROCm compute workloads additionally need `/dev/kfd`:

```bash
docker run --rm \
  --device /dev/kfd --device /dev/dri \
  --group-add video \
  --security-opt seccomp=unconfined \
  rocm/pytorch
```

## Other Host Devices

```bash
# Serial adapters — Zigbee, Z-Wave, UPS
docker run -d --device /dev/ttyUSB0:/dev/ttyUSB0 zigbee2mqtt

# By stable path, since ttyUSB numbering changes across reboots
docker run -d --device /dev/serial/by-id/usb-Silicon_Labs_xxx:/dev/ttyUSB0 zigbee2mqtt

# TUN/TAP for VPN containers
docker run -d --device /dev/net/tun --cap-add NET_ADMIN vpnclient

# Restrict permissions: read, write, mknod
docker run -d --device /dev/sdb:/dev/sdb:r myapp
```

```yaml
services:
  zigbee2mqtt:
    image: koenkk/zigbee2mqtt
    devices:
      - /dev/serial/by-id/usb-Silicon_Labs_xxx:/dev/ttyUSB0
```

> [!TIP]
> Always reference USB devices by `/dev/serial/by-id/` rather than `/dev/ttyUSB0`. The
> numbered names are assigned in enumeration order, so adding a second adapter — or simply
> rebooting — can silently point your container at the wrong hardware.

`--privileged` also grants device access, but it grants everything else as well. Use
`--device` for the specific nodes you need; see
[Container Security](../containers/security/index.md).

## Rootless and Swarm

**Rootless Docker** can use GPUs, but needs extra configuration: set
`no-cgroups = true` in `/etc/nvidia-container-runtime/config.toml`, because an unprivileged
daemon cannot manage the device cgroup. Expect rougher edges than rootful. See
[Rootless Docker](rootless.md).

**Swarm** has no native GPU scheduling. The usual approach is a node label plus a placement
constraint, with `--generic-resource` for accounting:

```yaml
deploy:
  placement:
    constraints:
      - node.labels.gpu == true
```

See [Placement Control](swarm.md#placement-control). Workloads that genuinely need GPU
scheduling are better served by Kubernetes with the NVIDIA device plugin.

## Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| `could not select device driver "" with capabilities: [[gpu]]` | Toolkit not installed, or runtime not configured — run `nvidia-ctk runtime configure` |
| `nvidia-smi` works on host, fails in container | Runtime not registered; check `docker info \| grep -i runtime` |
| `CUDA driver version is insufficient for CUDA runtime version` | Image's CUDA is newer than the host driver — upgrade the driver or use an older image tag |
| `Failed to initialize NVML: Unknown Error` after some uptime | Usually cgroups v2 plus systemd daemon-reload; set `no-cgroups` or pin the toolkit config |
| No NVENC despite `--gpus all` | Add `video` to `NVIDIA_DRIVER_CAPABILITIES` |
| `permission denied` on `/dev/dri/renderD128` | Container user not in the host's `render`/`video` GID — use `--group-add` |
| Device disappears after reboot | `/dev/ttyUSB*` renumbered — use `/dev/serial/by-id/` |

```bash
# What the toolkit thinks it can see
nvidia-ctk cdi list

# Full driver and device view from inside a container
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 \
  bash -c 'nvidia-smi; ls -l /dev/nvidia*'

# Toolkit configuration
cat /etc/nvidia-container-runtime/config.toml
```

## Related Topics

- [Daemon Configuration](daemon.md) — registering runtimes and setting `default-runtime`
- [Working with Containers](containers.md) — resource limits and security options
- [Docker Compose](dockercompose/index.md) — declaring devices in a stack
- [Rootless Docker](rootless.md) — constraints on device access without root
- [Container Security](../containers/security/index.md) — why `--privileged` is not the answer
- [Local LLMs — Installation and Setup](../../ai/local-llms/installation-setup.md) — GPU-accelerated model serving
