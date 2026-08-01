---
title: "Windows Containers"
description: "Running Windows container workloads, process versus Hyper-V isolation, base images, and version compatibility"
tags: ["docker", "windows", "containers", "hyper-v", "nanoserver", "servercore"]
category: "infrastructure"
difficulty: "advanced"
last_updated: "2026-08-01"
---

## Windows Containers

Windows containers run Windows binaries against a Windows kernel — they are a genuinely
different thing from running Docker *on* Windows, which is what Docker Desktop does by
default (Linux containers inside a WSL2 VM). If you need to containerize a .NET Framework
application, an IIS site, or anything depending on Windows APIs, you need Windows containers
and a Windows host.

The two constraints that shape everything else: **a Windows container cannot run on a Linux
host, and the host build version constrains which container images will run.**

## Table of Contents

- [When You Need Them](#when-you-need-them)
- [Isolation Modes](#isolation-modes)
- [Version Compatibility](#version-compatibility)
- [Base Images](#base-images)
- [Host Setup](#host-setup)
- [Switching Container Types](#switching-container-types)
- [Writing Windows Dockerfiles](#writing-windows-dockerfiles)
- [Networking](#networking)
- [Storage](#storage)
- [Resource Limits](#resource-limits)
- [Troubleshooting](#troubleshooting)

## When You Need Them

| Workload | Container type |
|----------|----------------|
| .NET Framework (4.x) application | Windows |
| Classic ASP.NET on IIS | Windows |
| Windows Services, COM components, WCF | Windows |
| Software requiring the Windows registry or Win32 APIs | Windows |
| .NET (Core) 6/8/9+ cross-platform application | Linux — smaller, cheaper, better tooled |
| Anything new | Linux, unless a hard Windows dependency exists |

Windows containers carry real costs: images are one to two orders of magnitude larger,
the host needs Windows licensing, orchestration support is thinner, and the version-matching
rules below add operational friction. Porting to .NET 8 and Linux containers is usually the
better investment when it is feasible. Where it is not — a decade-old .NET Framework
application that must keep running — Windows containers are a sound way to get it off a
hand-built server.

## Isolation Modes

This is the central concept, and the source of most confusion.

### Process Isolation

Containers share the host kernel, exactly as Linux containers do. Namespaces and job objects
provide separation.

- Fast startup, low overhead, higher density
- **Requires the container's base image build to match the host's**
- The default on Windows Server

### Hyper-V Isolation

Each container runs in a minimal, purpose-built virtual machine with its own kernel.

- Startup measured in seconds rather than sub-second; noticeably more memory per container
- **Any supported base image version runs on any supported host**
- Stronger security boundary — a kernel exploit is contained by the hypervisor
- The default on Windows 10/11 client editions

```powershell
# Explicit selection at run time
docker run --isolation=process mcr.microsoft.com/windows/servercore:ltsc2022 cmd /c echo hi
docker run --isolation=hyperv  mcr.microsoft.com/windows/servercore:ltsc2019 cmd /c echo hi

# Check what a running container used
docker inspect -f '{{.HostConfig.Isolation}}' mycontainer
```

Set a host default in `daemon.json`:

```json
{
  "exec-opts": ["isolation=hyperv"]
}
```

> [!NOTE]
> Hyper-V isolation requires hardware virtualization and the Hyper-V feature. In a virtual
> machine this means **nested virtualization** must be enabled by the hypervisor — a common
> blocker on cloud VMs and on vSphere without explicit configuration.

### Choosing

| Priority | Mode |
|----------|------|
| Density and speed, images match host | Process |
| Running mixed or older base image versions | Hyper-V |
| Untrusted or multi-tenant workloads | Hyper-V |
| Development on Windows 10/11 | Hyper-V (usually the only option) |

## Version Compatibility

Under process isolation, the container's kernel *is* the host's kernel, so the base image
must match the host build. Mismatches fail to start, or — worse across revisions — behave
unpredictably.

| Host | Process isolation supports | Hyper-V isolation supports |
|------|---------------------------|----------------------------|
| Windows Server 2019 (LTSC) | `ltsc2019` images | `ltsc2019` and earlier |
| Windows Server 2022 (LTSC) | `ltsc2022` images | `ltsc2022` and earlier |
| Windows Server 2025 (LTSC) | `ltsc2025` images | `ltsc2025` and earlier |
| Windows 10/11 client | Matching build only | All supported versions |

```powershell
# Host build
[System.Environment]::OSVersion.Version
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber

# Base image build
docker inspect mcr.microsoft.com/windows/servercore:ltsc2022 `
  --format '{{.OsVersion}}'
```

Rules of thumb:

- **The host must be the same or newer** than the container base image. An `ltsc2022` image
  will not run on a 2019 host in any mode.
- **Older images on a newer host require Hyper-V isolation.** An `ltsc2019` image runs on a
  2022 host only with `--isolation=hyperv`.
- **Pin base image tags to an LTSC version**, never `:latest`. A `latest` that rolls to a new
  LTSC release silently breaks every process-isolated host that has not been upgraded.

## Base Images

All published under `mcr.microsoft.com`:

| Image | Approx. size | Contains |
|-------|-------------|----------|
| `windows/nanoserver` | 250–300 MB | Minimal. No PowerShell, no full .NET Framework. `cmd` only. |
| `windows/servercore` | 2–5 GB | Most of the Windows Server API surface, PowerShell, IIS-capable |
| `windows` | 8+ GB | Full API set, including graphics and media. Rarely needed. |

```powershell
docker pull mcr.microsoft.com/windows/nanoserver:ltsc2022
docker pull mcr.microsoft.com/windows/servercore:ltsc2022
```

Application images build on these:

```powershell
# .NET Framework runtime and SDK
docker pull mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2022
docker pull mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2022

# ASP.NET (Framework) with IIS preconfigured
docker pull mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2022

# .NET (Core) on Nano Server — much smaller
docker pull mcr.microsoft.com/dotnet/aspnet:8.0-nanoserver-ltsc2022
```

> [!IMPORTANT]
> Nano Server dropped PowerShell some releases ago. If a Dockerfile uses
> `RUN powershell ...` against `nanoserver`, it fails — use `servercore` for the build stage
> and copy artifacts into `nanoserver` for runtime, the same multi-stage pattern used on
> Linux.

## Host Setup

### Windows Server

```powershell
# Install the Containers feature
Install-WindowsFeature -Name Containers
Restart-Computer -Force

# Hyper-V, only if you need Hyper-V isolation
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
Restart-Computer -Force
```

Install a container runtime. Microsoft partners with Mirantis for the supported Docker
engine on Windows Server:

```powershell
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force
Restart-Computer -Force

docker version
docker info
```

> [!NOTE]
> `DockerMsftProvider` is the long-standing path but has been superseded — current guidance
> is the Mirantis Container Runtime installer, and Microsoft's own tooling increasingly
> targets `containerd` directly. Check the current Microsoft documentation for your Server
> release rather than assuming the PowerShell provider is still the supported route.

### Windows 10/11

Docker Desktop with Hyper-V or WSL2 backend. Windows containers require the Hyper-V backend
and Pro, Enterprise, or Education — Home editions cannot run them.

```powershell
# Enable required features
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

See [Installing Docker](install.md) for the general Docker Desktop install.

## Switching Container Types

A single daemon serves either Linux or Windows containers, not both simultaneously.

```powershell
# Docker Desktop — right-click the tray icon → "Switch to Windows containers…"
# Or from the CLI:
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchDaemon

# Confirm which mode is active
docker info --format '{{.OSType}}'
# windows   or   linux
```

Switching restarts the daemon. Containers of the other type keep existing but are not
listed or runnable until you switch back — `docker ps -a` showing an empty list after a
switch is expected, not data loss.

> [!TIP]
> On a build agent that needs both, run two hosts rather than switching. Switching is slow,
> disruptive, and awkward to automate reliably.

## Writing Windows Dockerfiles

```dockerfile
# escape=`
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2022

SHELL ["powershell", "-Command", "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';"]

WORKDIR /inetpub/wwwroot

RUN Install-WindowsFeature Web-Asp-Net45

COPY ./publish/ .

EXPOSE 80
```

### The `escape` Directive

Windows paths use backslashes, which Dockerfile treats as line continuations. The
`# escape=` directive on the first line switches the continuation character to a backtick:

```dockerfile
# escape=`
FROM mcr.microsoft.com/windows/servercore:ltsc2022

RUN powershell -Command `
    New-Item -ItemType Directory -Path C:\app; `
    Write-Host 'created'
```

Without it, use forward slashes in paths — Windows accepts them in most contexts — and keep
the default `\` continuation.

### SHELL and Error Handling

The default shell is `cmd /S /C`, which does not stop on error the way you would expect.
Set PowerShell with `$ErrorActionPreference='Stop'` so a failing command actually fails the
build:

```dockerfile
SHELL ["powershell", "-Command", "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';"]
```

`$ProgressPreference='SilentlyContinue'` is not cosmetic — PowerShell's progress bar makes
`Invoke-WebRequest` dramatically slower in a non-interactive session.

### Multi-Stage Builds

```dockerfile
# escape=`
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2022 AS build
WORKDIR /src
COPY *.sln .
COPY MyApp/*.csproj MyApp/
RUN nuget restore
COPY . .
RUN msbuild /p:Configuration=Release /p:DeployOnBuild=true /p:PublishUrl=C:\publish

FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2022 AS runtime
WORKDIR /inetpub/wwwroot
COPY --from=build /publish .
```

The same caching and ordering principles from [Building Images](images.md#layer-caching)
apply — copy project files and restore packages before copying source.

### Users

Windows containers have no direct `USER 1000` equivalent. Built-in accounts are available:

```dockerfile
USER ContainerUser          # unprivileged
USER ContainerAdministrator # administrative
```

`ContainerUser` should be the default for anything not needing to modify the system. IIS
images typically run the worker process under its own application pool identity regardless.

## Networking

Windows uses the Host Network Service, with different drivers from Linux:

| Driver | Purpose |
|--------|---------|
| `nat` | Default. Private subnet behind NAT — the equivalent of `bridge`. |
| `transparent` | Container attaches directly to the physical network, like macvlan. |
| `l2bridge` | Layer 2 bridging with the host MAC; for SDN environments. |
| `overlay` | Multi-host, Swarm or Kubernetes. |
| `ics` | Internet Connection Sharing, client SKUs only. |

```powershell
docker network ls
docker network create -d nat --subnet=172.30.0.0/16 --gateway=172.30.0.1 appnet
docker network create -d transparent transparent-net
```

Behavioral differences worth knowing:

- **There is no `--network host`.** Windows has no equivalent; publish ports instead.
- **Published ports may not be reachable via `localhost` from the host.** Historically you
  had to use the container's IP directly. This has improved in recent Windows builds, but if
  `localhost:8080` fails, try the container address:

  ```powershell
  docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mycontainer
  ```

- **DNS behaves like Linux user-defined networks** — containers on a custom `nat` network
  resolve each other by name.

See [Docker Networking](networking.md) for the concepts these mirror.

## Storage

Volumes and bind mounts work, with Windows path syntax:

```powershell
docker volume create appdata
docker run -d -v appdata:C:\data myapp

# Bind mount — note the quoting
docker run -d -v C:\host\config:C:\app\config myapp
docker run -d --mount type=bind,source=C:\host\config,target=C:\app\config myapp
```

Constraints that differ from Linux:

- **You cannot bind-mount a single file**, only directories. Mount the parent directory.
- **`tmpfs` mounts are not supported.**
- SMB shares can be mounted, but require credentials configured for the container's identity
  — often the awkward part of migrating a file-dependent application.
- The storage layer uses the Windows filter driver, not overlay2. `docker info` reports
  `windowsfilter`.

## Resource Limits

```powershell
docker run -d --memory 2g --cpus 2 myapp

# Windows-specific CPU controls
docker run -d --cpu-count 2 --cpu-percent 50 myapp
```

Under Hyper-V isolation, `--memory` sets the VM's memory and is a hard allocation reserved up
front — sizing it generously across many containers exhausts host memory faster than the
equivalent Linux configuration. Under process isolation it behaves as a job object limit,
much like Linux cgroups.

## Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| `image operating system "windows" cannot be used on this platform` | Daemon is in Linux mode; switch it |
| `The container operating system does not match the host` | Base image build newer than host, or process isolation with a mismatch — use `--isolation=hyperv` or a matching tag |
| `hcsshim::CreateComputeSystem` failures | Hyper-V not enabled, or nested virtualization unavailable in the VM |
| `RUN powershell` fails on `nanoserver` | No PowerShell in that image; build on `servercore` |
| Published port unreachable on `localhost` | Use the container IP; see [Networking](#networking) |
| Extremely slow `Invoke-WebRequest` in build | Set `$ProgressPreference='SilentlyContinue'` |
| Backslash paths breaking the Dockerfile | Add `# escape=\`` or use forward slashes |
| Enormous image sizes | Expected — use `nanoserver` runtime stages and multi-stage builds |

```powershell
# Which mode is the daemon in
docker info --format '{{.OSType}} / {{.Isolation}}'

# Host and image build numbers side by side
Get-ComputerInfo | Select-Object OsBuildNumber
docker image inspect <image> --format '{{.OsVersion}}'

# Container logs and interactive access
docker logs mycontainer
docker exec -it mycontainer powershell
```

### Licensing

Windows containers require Windows Server licensing on the host. Under process isolation,
containers are covered by the host license; Hyper-V-isolated containers may count against
virtualization rights depending on the edition. Confirm the terms for your specific
agreement before planning density — this is a real cost input, not a formality.

## Related Topics

- [Installing Docker](install.md) — Docker Desktop on Windows
- [Building Images](images.md) — multi-stage builds and layer caching
- [Docker Networking](networking.md) — the Linux concepts these mirror
- [Docker Storage](storage.md) — volume and bind mount fundamentals
- [Docker Swarm](swarm.md) — mixed Linux/Windows clusters
- [Windows Infrastructure](../windows/index.md) — Windows Server administration
