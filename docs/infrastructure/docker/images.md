---
title: "Building Docker Images"
description: "Dockerfiles, BuildKit, buildx, multi-arch builds, layer caching, build secrets, and image optimization"
tags: ["docker", "dockerfile", "buildkit", "buildx", "images", "multi-arch"]
category: "infrastructure"
difficulty: "intermediate"
last_updated: "2026-08-01"
---

## Building Docker Images

Writing a Dockerfile that works is easy. Writing one that builds quickly, produces a small
image, rebuilds efficiently when source changes, and does not leak credentials takes a few
specific techniques. This page covers those techniques and the modern build tooling —
BuildKit and buildx — that most older Docker material predates.

## Table of Contents

- [Dockerfile Fundamentals](#dockerfile-fundamentals)
- [Layer Caching](#layer-caching)
- [COPY vs ADD](#copy-vs-add)
- [ARG vs ENV](#arg-vs-env)
- [ENTRYPOINT vs CMD](#entrypoint-vs-cmd)
- [.dockerignore](#dockerignore)
- [Multi-Stage Builds](#multi-stage-builds)
- [BuildKit](#buildkit)
- [Cache Mounts](#cache-mounts)
- [Build Secrets](#build-secrets)
- [buildx and Multi-Arch Builds](#buildx-and-multi-arch-builds)
- [Image Size Optimization](#image-size-optimization)
- [Metadata and Health Checks](#metadata-and-health-checks)
- [Inspecting Images](#inspecting-images)
- [Best Practices](#best-practices)

## Dockerfile Fundamentals

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-alpine

WORKDIR /app

# Dependency manifests first — see Layer Caching
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Source last, because it changes most often
COPY . .

EXPOSE 3000
USER node
CMD ["node", "server.js"]
```

```bash
docker build -t myapp:1.0 .
docker build -t myapp:1.0 -f docker/Dockerfile.prod .
docker build -t myapp:1.0 --build-arg NODE_VERSION=20 .
```

The `# syntax=docker/dockerfile:1` line on the first line opts into the current Dockerfile
frontend, which is what makes `--mount`, `--link`, and heredocs available. It is worth
including in every Dockerfile.

### Instruction Reference

| Instruction | Purpose | Creates a layer |
| ----------- | ------- | --------------- |
| `FROM` | Base image, or start of a stage | Yes |
| `RUN` | Execute a command at build time | Yes |
| `COPY` | Copy files from context or another stage | Yes |
| `ADD` | Copy, plus tar extraction and URL fetching | Yes |
| `WORKDIR` | Set the working directory | Metadata |
| `ENV` | Environment variable, persists at runtime | Metadata |
| `ARG` | Build-time variable | Metadata |
| `EXPOSE` | Document a port (see [networking](networking.md#expose-vs--p)) | Metadata |
| `USER` | Set the user for subsequent instructions and runtime | Metadata |
| `VOLUME` | Declare an anonymous volume mount point | Metadata |
| `ENTRYPOINT` | The executable | Metadata |
| `CMD` | Default arguments, or the command | Metadata |
| `HEALTHCHECK` | Liveness probe | Metadata |
| `LABEL` | Arbitrary metadata | Metadata |

## Layer Caching

Each instruction produces a layer. On rebuild, Docker reuses a cached layer when the
instruction and its inputs are unchanged — and **once one layer misses, every subsequent
layer is rebuilt**. Ordering instructions by how often they change is therefore the single
highest-leverage optimization available.

### Order From Least to Most Volatile

```dockerfile
# Wrong — any source change reinstalls all dependencies
COPY . .
RUN npm ci
```

```dockerfile
# Right — dependencies reinstall only when the manifests change
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
```

The same pattern applies to every ecosystem:

```dockerfile
# Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Go
COPY go.mod go.sum ./
RUN go mod download
COPY . .

# Rust
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo 'fn main(){}' > src/main.rs && cargo build --release
COPY src ./src
RUN touch src/main.rs && cargo build --release
```

### Combine Related RUN Commands

Each `RUN` is a layer, and a file deleted in a later layer still occupies space in the
earlier one:

```dockerfile
# Wrong — the apt lists remain in layer 1 regardless of the rm in layer 2
RUN apt-get update && apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*
```

```dockerfile
# Right — single layer, cleanup included
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
```

> [!WARNING]
> `RUN apt-get update` in its own layer is a classic cache trap. If the update layer is
> cached from weeks ago and a later `apt-get install` runs fresh, you install against a stale
> package index and may pull a version that no longer exists. Always chain `update` and
> `install` in one `RUN`.

### Inspecting Cache Behavior

```bash
# Show layer sizes and the instruction that created each
docker history myapp:1.0

# Build with no cache to confirm reproducibility
docker build --no-cache -t myapp:1.0 .

# Invalidate from a specific stage onward
docker build --no-cache-filter builder -t myapp:1.0 .
```

## COPY vs ADD

Both copy files into the image. The difference is that `ADD` does extra things — some
useful, some surprising:

| Behavior | `COPY` | `ADD` |
| -------- | ------ | ----- |
| Copy local files | Yes | Yes |
| Auto-extract local tar archives | No | **Yes** |
| Fetch remote URLs | No | Yes |
| Fetch a Git repository | No | Yes (current syntax) |

**Use `COPY` by default.** The automatic tar extraction is the problem: `ADD archive.tar.gz /`
silently unpacks, so a file that happens to be an archive behaves differently from every
other file, and the result is not obvious from reading the Dockerfile.

```dockerfile
# Predictable
COPY app.jar /opt/app/

# Legitimate use of ADD — extracting a tarball you control
ADD rootfs.tar.gz /

# Downloading with ADD: verify the checksum
ADD --checksum=sha256:24454f830c... https://example.com/tool.tar.gz /tmp/

# Prefer this when you need control over the fetch
RUN curl -fsSL https://example.com/tool.tar.gz -o /tmp/tool.tar.gz \
    && echo "24454f830c...  /tmp/tool.tar.gz" | sha256sum -c - \
    && tar xzf /tmp/tool.tar.gz -C /opt \
    && rm /tmp/tool.tar.gz
```

The `RUN curl` form has one further advantage: download, verify, extract, and delete happen
in a single layer, so the archive never persists in the image.

### COPY --link

BuildKit's `--link` creates the layer independently of the previous filesystem state, so it
stays cached even when earlier layers change:

```dockerfile
COPY --link package.json package-lock.json ./
COPY --link --from=builder /app/dist /app/dist
```

It also enables `--chown` and `--chmod` without an extra `RUN`:

```dockerfile
COPY --chown=node:node --chmod=755 entrypoint.sh /usr/local/bin/
```

## ARG vs ENV

```dockerfile
# ARG — available during build only
ARG NODE_VERSION=20
ARG BUILD_DATE

# ENV — baked into the image, present at runtime
ENV NODE_ENV=production
ENV PATH="/opt/app/bin:${PATH}"
```

| | `ARG` | `ENV` |
| - | ----- | ----- |
| Available during build | Yes | Yes |
| Present in the running container | No | Yes |
| Settable at build time | `--build-arg` | No |
| Overridable at run time | No | `-e` / `--env` |
| Visible in image history | **Yes** | Yes |

### ARG Before FROM

An `ARG` declared before the first `FROM` is global and usable in `FROM` lines, but is **not**
available inside build stages unless re-declared:

```dockerfile
ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-alpine AS builder

# Must re-declare to use it inside the stage
ARG NODE_VERSION
RUN echo "Building with Node ${NODE_VERSION}"
```

### Never Put Secrets in ARG

```dockerfile
# WRONG — recoverable from the image
ARG API_TOKEN
RUN curl -H "Authorization: Bearer ${API_TOKEN}" https://internal/artifact
```

```bash
# Anyone with the image can read it
docker history --no-trunc myapp:1.0 | grep -i token
```

Build arguments are recorded in image metadata. Use [build secrets](#build-secrets) instead.

## ENTRYPOINT vs CMD

```dockerfile
# Exec form — no shell, signals reach the process directly. Use this.
ENTRYPOINT ["node", "server.js"]

# Shell form — wraps in /bin/sh -c, the process becomes a child of sh
ENTRYPOINT node server.js
```

The distinction matters for shutdown. In shell form, the shell is PID 1 and does not forward
`SIGTERM` to your application, so `docker stop` waits the full timeout and then kills the
container — losing in-flight work and skipping cleanup.

The two instructions compose: `ENTRYPOINT` is the executable, `CMD` supplies default
arguments that a `docker run` argument replaces.

```dockerfile
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
```

```bash
docker run myimage                 # nginx -g "daemon off;"
docker run myimage -t              # nginx -t
```

### PID 1 and Zombie Reaping

Applications that spawn child processes need a real init to reap them:

```bash
docker run --init myapp
```

```dockerfile
# Or build one in
ENTRYPOINT ["/usr/bin/tini", "--", "node", "server.js"]
```

## .dockerignore

The build context is everything Docker sends to the daemon before the build starts. Without
a `.dockerignore`, that includes `.git`, `node_modules`, build output, and any local secrets
— slowing every build and risking their inclusion in the image via `COPY . .`.

```gitignore
# Version control
.git
.gitignore

# Dependencies — reinstalled inside the image
node_modules
vendor
__pycache__
*.pyc

# Build output
dist
build
target
*.egg-info

# Local environment and secrets
.env
.env.*
*.pem
*.key
secrets/
.aws
.npmrc

# Editor and OS noise
.vscode
.idea
.DS_Store

# Docker files themselves
Dockerfile*
docker-compose*.yml
.dockerignore

# Documentation and CI
README.md
docs/
.github/
```

```bash
# See how large the context is
docker build --progress=plain . 2>&1 | head -3
```

> [!IMPORTANT]
> Excluding `.env` and key material here is a genuine security control, not just an
> optimization. `COPY . .` with a careless context has put credentials into published images
> many times over.

Negation works for allow-listing:

```gitignore
*
!src/
!package.json
!package-lock.json
```

## Multi-Stage Builds

Build in one stage with the full toolchain, then copy only the artifacts into a minimal
runtime image. This is the most effective size reduction available.

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.22 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /out/app ./cmd/app

FROM gcr.io/distroless/static-debian12
COPY --from=builder /out/app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

A Go binary in `distroless/static` lands around 10–20 MB against roughly 900 MB for the
`golang` build image.

### Node Example

```dockerfile
# syntax=docker/dockerfile:1

FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

### Targeting a Stage

```bash
# Build only up to a named stage — useful for a test image in CI
docker build --target build -t myapp:build .
```

```dockerfile
FROM build AS test
RUN npm run test:ci
```

```bash
docker build --target test .    # fails the build if tests fail
```

### Copying From an External Image

```dockerfile
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
```

## BuildKit

BuildKit is the current builder and is the default for `docker build` in modern releases. It
parallelizes independent stages, skips stages whose output is unused, and adds the `--mount`
family of features.

```bash
# Confirm it is active — output shows the structured step display
docker build .

# Force it on older versions
DOCKER_BUILDKIT=1 docker build .
```

To make it the default on an older daemon, set it in `daemon.json`:

```json
{
  "features": { "buildkit": true }
}
```

### Build Output and Progress

```bash
# Full, non-collapsed log — essential for debugging a failing build
docker build --progress=plain .

# Export the built filesystem instead of an image
docker build --output type=local,dest=./out --target artifacts .
```

## Cache Mounts

Package managers re-download everything on each build because their caches live in layers
that get invalidated. A cache mount gives them a persistent directory that is **not** part of
the image:

```dockerfile
# syntax=docker/dockerfile:1

# apt
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends build-essential

# npm
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# pip
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# Go
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    go build -o /out/app ./cmd/app

# Cargo
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release
```

Note that with an apt cache mount you must **not** delete `/var/lib/apt/lists` afterwards,
and Debian images ship a config that auto-cleans the cache — override it:

```dockerfile
RUN rm -f /etc/apt/apt.conf.d/docker-clean
```

`sharing=locked` serializes concurrent builds against the same cache; `sharing=private`
gives each build its own.

### Bind Mounts at Build Time

Use files from the context without copying them into a layer:

```dockerfile
RUN --mount=type=bind,source=package-lock.json,target=/app/package-lock.json \
    --mount=type=bind,source=package.json,target=/app/package.json \
    npm ci
```

## Build Secrets

Secrets mounted this way are available to a single `RUN` and never enter the image or its
history.

```dockerfile
# syntax=docker/dockerfile:1

RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci

RUN --mount=type=secret,id=api_key \
    curl -H "Authorization: Bearer $(cat /run/secrets/api_key)" \
         -fsSL https://internal.example.com/artifact.tar.gz -o /tmp/artifact.tar.gz
```

```bash
docker build \
  --secret id=npmrc,src=$HOME/.npmrc \
  --secret id=api_key,env=API_KEY \
  -t myapp .
```

Secrets default to `/run/secrets/<id>`; `target=` overrides that.

### SSH Forwarding for Private Repositories

```dockerfile
RUN --mount=type=ssh \
    mkdir -p -m 0700 ~/.ssh \
    && ssh-keyscan github.com >> ~/.ssh/known_hosts \
    && git clone git@github.com:example/private-lib.git
```

```bash
docker build --ssh default -t myapp .
```

### Verifying Nothing Leaked

```bash
docker history --no-trunc myapp:latest
docker save myapp:latest | tar -xO | grep -ri 'BEGIN PRIVATE KEY' || echo "clean"
```

For continuous checking, image scanners detect embedded credentials — see
[Image Security](../containers/security/index.md#image-security).

## buildx and Multi-Arch Builds

`docker buildx` extends builds with multiple platforms, remote builders, and richer cache
export. It ships with current Docker installs.

```bash
docker buildx version
docker buildx ls
```

### Creating a Builder

The default `docker` driver cannot do multi-platform builds. Create one that can:

```bash
docker buildx create --name multiarch --driver docker-container --bootstrap --use
docker buildx inspect
```

### Emulation

Building for foreign architectures requires QEMU binfmt handlers:

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
ls /proc/sys/fs/binfmt_misc/ | grep qemu
```

### Building for Multiple Platforms

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t registry.example.com/myapp:1.0 \
  --push .
```

> [!IMPORTANT]
> Multi-platform builds must be pushed to a registry, not loaded locally. The local image
> store holds one architecture per tag, so `--load` fails with more than one platform. Build
> a single platform with `--load` for local testing, and use `--push` for the real artifact.

```bash
# Local testing, single platform
docker buildx build --platform linux/arm64 -t myapp:test --load .

# Verify the published manifest
docker buildx imagetools inspect registry.example.com/myapp:1.0
```

### Native Builders Instead of Emulation

QEMU emulation is correct but slow — often 5–10× — and some toolchains fail under it. Where
build time matters, attach a native node per architecture:

```bash
docker buildx create --name multiarch --driver docker-container \
  --node amd64 --platform linux/amd64
docker buildx create --append --name multiarch \
  --node arm64 --platform linux/arm64 ssh://user@arm-builder
```

Cross-compilation is the other answer, and the better one for Go and Rust:

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.22 AS builder
ARG TARGETOS TARGETARCH
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/app .
```

`BUILDPLATFORM` is the builder's architecture; `TARGETPLATFORM`, `TARGETOS`, and
`TARGETARCH` describe the requested output. Pinning the build stage to `$BUILDPLATFORM`
keeps the compiler running natively while producing a foreign binary.

### Registry Cache

Sharing cache across CI runners, where the local cache is always cold:

```bash
docker buildx build \
  --cache-from type=registry,ref=registry.example.com/myapp:buildcache \
  --cache-to type=registry,ref=registry.example.com/myapp:buildcache,mode=max \
  -t registry.example.com/myapp:1.0 --push .
```

`mode=max` exports intermediate layers as well as the final ones — larger, but far more
likely to hit. GitHub Actions has a dedicated backend:

```bash
--cache-from type=gha --cache-to type=gha,mode=max
```

## Image Size Optimization

### Choosing a Base

| Base | Approx. size | Notes |
| ---- | ------------ | ----- |
| `scratch` | 0 | Static binaries only; no shell, no libc |
| `distroless` | 2–20 MB | Runtime libraries, no shell or package manager |
| `alpine` | ~7 MB | musl libc; small but watch for glibc incompatibilities |
| `*-slim` | 30–80 MB | Debian, trimmed |
| Full distro | 100–1000 MB | Build stages only |

> [!NOTE]
> Alpine uses musl rather than glibc. Most software is fine, but Python wheels frequently
> lack musl builds and fall back to compiling from source, which can make an Alpine image
> both slower to build and larger than the Debian `-slim` equivalent. Measure rather than
> assuming Alpine is smaller for your stack.

### Techniques That Actually Matter

```dockerfile
# 1. Multi-stage — the single biggest win
# 2. Install only what is needed, and clean up in the same layer
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# 3. Skip pip's wheel cache
RUN pip install --no-cache-dir -r requirements.txt

# 4. Production dependencies only
RUN npm ci --omit=dev && npm cache clean --force

# 5. Strip debug symbols from compiled binaries
RUN go build -ldflags="-s -w" -o /out/app
```

### Finding the Bloat

```bash
docker images myapp
docker history myapp:1.0 --human --format "table {{.Size}}\t{{.CreatedBy}}"

# Layer-by-layer exploration
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest myapp:1.0
```

## Metadata and Health Checks

### OCI Labels

```dockerfile
LABEL org.opencontainers.image.title="myapp" \
      org.opencontainers.image.description="Example service" \
      org.opencontainers.image.source="https://github.com/example/myapp" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="Example Ltd"

ARG VERSION
ARG REVISION
ARG BUILD_DATE
LABEL org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${BUILD_DATE}"
```

```bash
docker build \
  --build-arg VERSION="$(git describe --tags --always)" \
  --build-arg REVISION="$(git rev-parse HEAD)" \
  --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -t myapp:latest .

docker inspect -f '{{json .Config.Labels}}' myapp:latest | jq
```

Populating `image.source` is what lets registries such as GHCR link a package back to its
repository.

### HEALTHCHECK

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -fsS http://localhost:3000/health || exit 1
```

`--start-period` covers slow startup: failures during it do not count toward `--retries`.
For images without `curl`, ship a tiny purpose-built probe rather than adding a package:

```dockerfile
HEALTHCHECK CMD ["/app", "healthcheck"]
```

## Inspecting Images

```bash
# Configuration and metadata
docker inspect myapp:1.0

# Layer history with sizes
docker history myapp:1.0

# What is in the filesystem, without running it
docker create --name tmp myapp:1.0
docker export tmp | tar -tv | head -50
docker rm tmp

# Manifest and platforms of a remote image, no pull
docker buildx imagetools inspect registry.example.com/myapp:1.0 --raw
```

## Best Practices

### Correctness

- Pin base image tags — `node:20.11.1-alpine3.19`, not `node:latest`. For full
  reproducibility pin by digest: `node:20-alpine@sha256:...`
- Chain `apt-get update` with `apt-get install` in one `RUN`
- Use exec form for `ENTRYPOINT` and `CMD` so signals are delivered
- Commit a lockfile and install from it (`npm ci`, `pip install -r`, `go mod download`)

### Security

- Run as a non-root `USER`
- Never pass secrets through `ARG` or `ENV`; use `--mount=type=secret`
- Keep `.env`, keys, and `.git` out of the build context
- Scan images in CI — see [Image Security](../containers/security/index.md#image-security)
- Prefer minimal bases; a missing shell removes a whole class of exploitation

### Speed and size

- Order instructions least- to most-volatile
- Use multi-stage builds
- Use cache mounts for package managers
- Maintain a real `.dockerignore`
- Share cache across CI with `--cache-from`/`--cache-to`

### Maintainability

- Add OCI labels, especially `image.source` and `image.revision`
- Name build stages (`AS builder`) rather than relying on indices
- Add a `HEALTHCHECK` for anything long-running

## Related Topics

- [Registries](registries.md) — tagging, pushing, and signing what you build
- [Docker Storage](storage.md) — how layers consume disk, and pruning the build cache
- [Docker Networking](networking.md) — `EXPOSE` versus published ports
- [Docker Compose](dockercompose/index.md) — `build:` configuration in a stack
- [Container Security](../containers/security/index.md) — image scanning, SBOMs, and signing
- [CI/CD Pipelines](../../development/automation/ci-cd/index.md) — automating builds
