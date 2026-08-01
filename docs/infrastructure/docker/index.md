---
title: "Docker"
description: "Docker documentation: installation, images, networking, storage, registries, daemon configuration, Swarm, and monitoring"
author: "Joseph Streeter"
tags: ["docker", "containers", "overview", "reference"]
category: "infrastructure"
difficulty: "beginner"
last_updated: "2026-08-01"
---

## Docker

Docker packages an application together with its dependencies into an image, then runs that
image as an isolated process on a shared kernel. Unlike a virtual machine, there is no guest
operating system — which is why a container starts in milliseconds and costs megabytes rather
than gigabytes.

```text
┌──────────────────────────────┐   ┌──────────────────────────────┐
│  Virtual Machines            │   │  Containers                  │
├──────────────────────────────┤   ├──────────────────────────────┤
│  App A    │  App B           │   │  App A    │  App B           │
│  Bins/Lib │  Bins/Lib        │   │  Bins/Lib │  Bins/Lib        │
│  Guest OS │  Guest OS        │   ├───────────┴──────────────────┤
├───────────┴──────────────────┤   │  Container runtime           │
│  Hypervisor                  │   ├──────────────────────────────┤
├──────────────────────────────┤   │  Host OS  (shared kernel)    │
│  Host OS                     │   ├──────────────────────────────┤
├──────────────────────────────┤   │  Hardware                    │
│  Hardware                    │   └──────────────────────────────┘
└──────────────────────────────┘
```

The shared kernel is also the main caveat: containers isolate processes, not kernels. A
Linux container needs a Linux kernel, which is why Docker Desktop runs a VM on Windows and
macOS, and why [Windows containers](windows-containers.md) are a separate thing entirely.

### Core Concepts

| Term | What it is |
| ---- | ---------- |
| **Image** | A read-only, layered filesystem plus metadata. Built from a Dockerfile. |
| **Container** | A running instance of an image, with a thin writable layer on top. |
| **Volume** | Storage managed by Docker that outlives the container. |
| **Network** | A virtual network containers attach to in order to reach each other. |
| **Registry** | Where images are stored and distributed — Docker Hub, GHCR, Harbor. |
| **Dockerfile** | The recipe an image is built from. |
| **Compose** | A file format and CLI for running a multi-container application. |

## Getting Started

New to Docker, in order:

1. **[Install Docker](install.md)** — Linux, Windows, or macOS
2. **[Quickstart](quickstart.md)** — run your first containers and build an image
3. **[Working with Containers](containers.md)** — lifecycle, inspection, and operations
4. **[Docker Compose](dockercompose/index.md)** — define a multi-service application

## In This Section

### Fundamentals

| Page | Covers |
| ---- | ------ |
| [Installing Docker](install.md) | Engine on Linux, Desktop on Windows and macOS, post-install setup |
| [Quickstart](quickstart.md) | First containers, images, ports, volumes |
| [Working with Containers](containers.md) | Lifecycle, inspection, security options, resource limits |
| [Building Images](images.md) | Dockerfiles, layer caching, BuildKit, multi-arch, build secrets |
| [Docker Compose](dockercompose/index.md) | Multi-container applications, environments, production patterns |

### Infrastructure

| Page | Covers |
| ---- | ------ |
| [Networking](networking.md) | Drivers, DNS, `EXPOSE` vs `-p`, firewall interaction, IPv6 |
| [Storage](storage.md) | Volumes, bind-mount permissions, storage drivers, disk usage |
| [Registries](registries.md) | Authentication, tagging, private registries, mirrors, signing |
| [GPU and Device Access](gpu.md) | NVIDIA GPUs, integrated graphics, USB and serial devices |
| [Daemon Configuration](daemon.md) | `daemon.json`, systemd, remote engines, contexts |
| [Monitoring and Logging](monitoring.md) | Log drivers, `docker stats`, events, health checks, metrics |

### Advanced

| Page | Covers |
| ---- | ------ |
| [Rootless and User Namespaces](rootless.md) | Running Docker without daemon root |
| [Docker Swarm](swarm.md) | Clustering, services, stacks, rolling updates |
| [Windows Containers](windows-containers.md) | Windows workloads, process vs Hyper-V isolation |
| [Command Formatting](formatting.md) | Customizing CLI output with Go templates |

## Common Tasks

| I want to… | Start here |
| ---------- | ---------- |
| Make my container's data survive a restart | [Storage — Named Volumes](storage.md#named-volumes) |
| Fix "permission denied" on a mounted directory | [Storage — Permissions](storage.md#permissions-and-ownership) |
| Let two containers talk to each other by name | [Networking — Bridge Networks](networking.md#bridge-networks) |
| Understand why a published port bypasses my firewall | [Networking — Firewall Interaction](networking.md#firewall-interaction) |
| Make builds faster | [Images — Layer Caching](images.md#layer-caching) |
| Use a private registry | [Registries — Authentication](registries.md#authentication) |
| Stop Docker filling my disk | [Storage — Disk Usage and Pruning](storage.md#disk-usage-and-pruning) |
| Find out why a container exited | [Monitoring — Debugging a Container](monitoring.md#debugging-a-container) |
| Give a container access to a GPU or USB device | [GPU and Device Access](gpu.md) |
| Reload code without rebuilding on every save | [Compose — Development Workflow](dockercompose/index.md#development-workflow) |
| Run Docker without giving out root | [Rootless Docker](rootless.md) |

## Quick Reference

### Essential Docker Commands

```bash
# Container management
docker run <image>                   # Run a container
docker ps                            # List running containers
docker ps -a                         # List all containers
docker stop <container>              # Stop a container
docker start <container>             # Start a stopped container
docker restart <container>           # Restart a container
docker rm <container>                # Remove a container
docker exec -it <container> bash     # Execute a command in a container

# Image management
docker images                        # List images
docker pull <image>                  # Pull an image from a registry
docker build -t <name> .             # Build an image from a Dockerfile
docker rmi <image>                   # Remove an image
docker tag <image> <new-name>        # Tag an image

# System management
docker info                          # Display system information
docker version                       # Show Docker version
docker system df                     # Show disk usage
docker system prune                  # Remove unused data
docker logs <container>              # View container logs
```

### Common Docker Run Options

```bash
# Background execution
docker run -d <image>

# Port mapping — bind to localhost unless it must be public
docker run -p 127.0.0.1:8080:80 <image>

# Named volume (preferred for application data)
docker run -v myvolume:/data <image>

# Bind mount
docker run -v /host/path:/container/path <image>

# Environment variables
docker run -e VAR_NAME=value <image>

# Interactive terminal
docker run -it <image> /bin/bash

# Remove container on exit
docker run --rm <image>

# Set container name
docker run --name my-container <image>

# Limit resources
docker run --memory=512m --cpus=1 <image>
```

### Docker Compose Quick Commands

```bash
# Start services
docker compose up

# Start in background
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Rebuild images
docker compose up --build

# Scale a service
docker compose up -d --scale web=3
```

> [!NOTE]
> Compose v2 is invoked as `docker compose`, not `docker-compose`. The hyphenated v1 binary
> is end-of-life and is not installed by current packages.

## Related Topics

- [Container Infrastructure](../containers/index.md) — the wider container ecosystem
- [Kubernetes](../kubernetes/index.md) — orchestration beyond a single host
- [Container Security](../containers/security/index.md) — image scanning, runtime hardening
- [Infrastructure Monitoring](../monitoring/index.md) — Prometheus and Grafana
- [CI/CD Pipelines](../../development/automation/ci-cd/index.md) — automating builds and deploys
