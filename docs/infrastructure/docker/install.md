---
title: "Installing Docker"
description: "Installing Docker Engine on Linux and Docker Desktop on Windows and macOS, with post-install steps and troubleshooting"
author: "Joseph Streeter"
tags: ["docker", "containers", "installation", "ubuntu", "debian", "rhel", "windows", "macos"]
category: "infrastructure"
difficulty: "beginner"
last_updated: "2026-08-01"
---

## Installing Docker

There are two distinct products. **Docker Engine** is the daemon and CLI, runs natively on
Linux, and is what servers use. **Docker Desktop** bundles the engine with a VM, a GUI, and
Kubernetes, and is how you run Docker on Windows and macOS.

> [!IMPORTANT]
> Docker Desktop requires a paid subscription for commercial use in larger organizations —
> Docker's terms set thresholds on employee count and annual revenue. Docker Engine on Linux
> is free under the Apache 2.0 license and carries no such requirement. Check the current
> terms before deploying Desktop across a company.

## [Linux](#tab/linux)

### Ubuntu and Debian

1. Install the packages needed to fetch a repository over HTTPS:

    ```bash
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    ```

2. Determine the correct upstream distribution and codename. Docker publishes repositories
   for **ubuntu** and **debian** only — derivatives such as Linux Mint, Pop!\_OS, Zorin, and
   elementary must use their upstream's repository:

    ```bash
    . /etc/os-release

    case "$ID" in
      ubuntu|debian)
        DISTRO="$ID"; CODENAME="$VERSION_CODENAME" ;;
      *)
        # Ubuntu derivatives carry UBUNTU_CODENAME; Debian derivatives do not
        if [ -n "${UBUNTU_CODENAME:-}" ]; then
          DISTRO="ubuntu"; CODENAME="$UBUNTU_CODENAME"
        else
          DISTRO="debian"; CODENAME="$VERSION_CODENAME"
        fi ;;
    esac

    echo "Using https://download.docker.com/linux/$DISTRO ($CODENAME)"
    ```

3. Add Docker's GPG key:

    ```bash
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/$DISTRO/gpg" \
      | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    ```

4. Add the repository:

    ```bash
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/$DISTRO $CODENAME stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ```

5. Install the engine, CLI, and plugins:

    ```bash
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
    ```

    `docker-compose-plugin` provides `docker compose`; `docker-buildx-plugin` provides
    `docker buildx`. Both are needed — see [Docker Compose](dockercompose/index.md) and
    [Building Images](images.md).

> [!TIP]
> Before running step 4, sanity-check that the repository exists for your resolved values.
> A `404` here is the cause of the "Release file" error in
> [Troubleshooting](#repository-does-not-have-a-release-file):
>
> ```bash
> curl -sS -o /dev/null -w "%{http_code}\n" \
>   "https://download.docker.com/linux/$DISTRO/dists/$CODENAME/Release"
> ```

Debian derivatives that are not Ubuntu-based — Kali, Raspberry Pi OS, Devuan — report their
own codename and have no `UBUNTU_CODENAME`. Set `CODENAME` manually to the Debian release the
distribution is built on (for example `bookworm` or `trixie`).

### RHEL, CentOS, and Fedora

1. Install the repository management plugin:

    ```bash
    sudo dnf -y install dnf-plugins-core
    ```

2. Add the Docker repository, matching your distribution:

    ```bash
    # RHEL
    sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

    # CentOS / CentOS Stream
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    # Fedora
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    ```

3. Install:

    ```bash
    sudo dnf install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
    ```

4. Start it — unlike the Debian packages, the RPM packages do not start the service:

    ```bash
    sudo systemctl enable --now docker
    ```

> [!NOTE]
> On Fedora 41+ and other dnf5 systems, `dnf config-manager --add-repo` has been replaced by
> `dnf config-manager addrepo --from-repofile=<url>`. If the older form errors, use the new
> syntax.
>
> Older guides also install `device-mapper-persistent-data` and `lvm2` here. Those were
> dependencies of the `devicemapper` storage driver, which has been removed — `overlay2` is
> the driver in use today and needs neither. See
> [Storage Drivers](storage.md#storage-drivers-and-layers).

### Convenience Script

For a throwaway VM or a lab machine, Docker's script handles detection for you:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

It installs the engine plus the Compose and buildx plugins. Docker does not recommend it for
production hosts, since it always installs the newest release and gives you no control over
versions.

## [Windows](#tab/windows)

### Windows 10/11 Pro, Enterprise, or Education

1. **Requirements**
   - Windows 10/11 64-bit, build 19044 or later
   - Hardware virtualization enabled in firmware
   - WSL 2 (recommended) or Hyper-V

2. **Install WSL 2** — the default and better-performing backend:

    ```powershell
    wsl --install
    ```

    Restart when prompted.

3. **Install Docker Desktop**
   - Download [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
   - Run the installer, keeping "Use WSL 2 instead of Hyper-V" selected
   - Launch it from the Start menu

4. **Verify**

    ```powershell
    docker --version
    docker compose version
    docker run hello-world
    ```

### Windows Home

Windows 10/11 Home supports Docker Desktop with the WSL 2 backend, following the same steps
as above. It cannot use the Hyper-V backend, and therefore cannot run
[Windows containers](windows-containers.md) — Linux containers only.

> [!TIP]
> Keep project files inside the WSL 2 filesystem (`\\wsl$\...`) rather than under `/mnt/c`.
> Bind mounts that cross the Windows/Linux boundary are dramatically slower — see
> [I/O Performance](storage.md#io-performance).

## [Mac OS](#tab/macos)

1. **Requirements**
   - macOS 13 (Ventura) or newer, on the current and two previous major releases
   - Apple Silicon or Intel

2. **Install**
   - Download [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/),
     choosing the Apple Silicon or Intel build to match your hardware
   - Open the `.dmg`, drag Docker to Applications, and launch it

3. **Verify**

    ```bash
    docker --version
    docker compose version
    docker run hello-world
    ```

> [!TIP]
> Enable **VirtioFS** in Docker Desktop's settings (General → file sharing implementation).
> It is substantially faster than the alternatives for bind mounts.

---

## Post-Installation

### Run Docker Without sudo

```bash
sudo usermod -aG docker "$USER"
newgrp docker      # or log out and back in
docker run hello-world
```

> [!WARNING]
> Membership in the `docker` group is equivalent to root on the host — a member can mount the
> host filesystem into a privileged container. Treat it as an administrative grant. Where that
> is unacceptable, use [rootless Docker](rootless.md) instead, which needs no group membership
> at all.

### Start on Boot

```bash
sudo systemctl enable --now docker
sudo systemctl status docker
```

### Verify the Full Installation

```bash
docker --version
docker compose version
docker buildx version
docker info
docker run --rm hello-world
```

### Recommended First Configuration

New installs log without limit and can fill the disk. Set a cap before running anything
long-lived — see [Daemon Configuration](daemon.md) for the full reference:

```json
{
  "log-driver": "local",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
```

```bash
sudo systemctl restart docker
```

## Troubleshooting

### Repository does not have a Release file

```text
E: The repository 'https://download.docker.com/linux/linuxmint xia Release' does not have a Release file.
```

The repository URL or codename does not exist. This almost always means an Ubuntu or Debian
**derivative** was detected as its own distribution — Docker publishes repositories for
`ubuntu` and `debian` only. Use the detection in
[step 2](#ubuntu-and-debian), which maps derivatives to their upstream, and verify with the
`curl` check above.

For a worked example on Proxmox, see
[Proxmox Docker Repository Troubleshooting](../proxmox/troubleshooting.md).

### Cannot connect to the Docker daemon

```bash
sudo systemctl status docker
sudo systemctl start docker
sudo journalctl -u docker -n 50
```

If the daemon refuses to start after a configuration change, validate the config:

```bash
sudo dockerd --validate --config-file /etc/docker/daemon.json
```

### Permission denied on /var/run/docker.sock

```bash
groups                              # is "docker" listed?
sudo usermod -aG docker "$USER"
newgrp docker
```

The group change does not apply to shells that were already open.

### Conflicting packages on Ubuntu and Debian

Distribution-packaged Docker (`docker.io`, `docker-doc`, `podman-docker`) conflicts with
Docker's own packages. Remove them first:

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg"
done
```

### `docker compose` not found

Compose v2 is a CLI plugin, not a `docker-compose` binary. Install `docker-compose-plugin`
and invoke it as `docker compose` — see
[Docker Compose — Installation](dockercompose/index.md#installation).

## Next Steps

- [Docker Quickstart](quickstart.md) — your first containers
- [Docker overview](index.md) — the rest of this section
- [Daemon Configuration](daemon.md) — log limits, storage, and address pools
- [Rootless Docker](rootless.md) — installing without daemon root
