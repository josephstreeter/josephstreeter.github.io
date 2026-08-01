---
title: "Docker Registries"
description: "Authentication, tagging strategy, private registries, pull-through mirrors, and image signing"
tags: ["docker", "registry", "harbor", "ghcr", "ecr", "acr", "cosign", "signing"]
category: "infrastructure"
difficulty: "intermediate"
last_updated: "2026-08-01"
---

## Docker Registries

A registry stores and distributes images. Docker Hub is the default, but most organizations
end up running or subscribing to a private one — for rate limits, for access control, or
because images should not leave the network. This page covers authenticating to registries,
tagging images so the tags remain meaningful, running a private registry or pull-through
mirror, and signing images so consumers can verify what they run.

## Table of Contents

- [Registry Basics](#registry-basics)
- [Authentication](#authentication)
- [Credential Helpers](#credential-helpers)
- [Tagging Strategy](#tagging-strategy)
- [Pushing and Pulling](#pushing-and-pulling)
- [Private Registries](#private-registries)
- [Registry Mirrors](#registry-mirrors)
- [Image Signing](#image-signing)
- [Retention and Cleanup](#retention-and-cleanup)
- [Troubleshooting](#troubleshooting)

## Registry Basics

An image reference has four parts, most of which are usually implicit:

```text
registry.example.com:5000/team/myapp:1.2.3
└─────────┬──────────────┘└───┬───┘└─┬──┘└─┬─┘
      registry           namespace  name  tag
```

When the registry is omitted, Docker assumes Docker Hub:

```bash
docker pull nginx
# is really
docker pull docker.io/library/nginx:latest
```

Official Docker Hub images live in the `library` namespace, which is why `nginx` works while
an equivalent single-word name on any other registry does not.

> [!NOTE]
> Docker distinguishes a registry hostname from a Hub namespace by looking for a dot, a
> colon, or `localhost` in the first path segment. `myregistry/myapp` is a Hub user;
> `myregistry.local/myapp` is a private registry. A registry hostname without a dot needs an
> explicit port or `localhost` prefix.

## Authentication

```bash
# Docker Hub
docker login

# Any other registry
docker login registry.example.com

# Non-interactive — never put a password directly on the command line
echo "$REGISTRY_TOKEN" | docker login registry.example.com -u svc_ci --password-stdin

docker logout registry.example.com
```

Passing `--password` inline puts the credential in your shell history and in the process
list, where any local user can read it. Docker warns about this; the warning is worth
heeding.

### Provider-Specific Login

```bash
# GitHub Container Registry — needs a PAT with read:packages / write:packages
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin

# Amazon ECR — token is valid 12 hours
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin \
    123456789012.dkr.ecr.us-east-1.amazonaws.com

# Azure Container Registry
az acr login --name myregistry
# or with a service principal
echo "$SP_PASSWORD" | docker login myregistry.azurecr.io -u "$SP_APP_ID" --password-stdin

# Google Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Where Credentials Are Stored

By default, `docker login` writes to `~/.docker/config.json`:

```json
{
  "auths": {
    "registry.example.com": {
      "auth": "c3ZjX2NpOnRva2VuMTIz"
    }
  }
}
```

> [!WARNING]
> That `auth` value is **base64, not encryption**. `base64 -d` recovers the username and
> password in full. On any shared or long-lived machine, configure a credential helper
> instead.

## Credential Helpers

Helpers store credentials in the OS keychain rather than a plaintext file.

```json
{
  "credsStore": "pass"
}
```

| Platform | Helper | Package |
|----------|--------|---------|
| Linux | `pass` | `docker-credential-pass` (with `pass` and a GPG key) |
| Linux | `secretservice` | `docker-credential-secretservice` (GNOME Keyring) |
| macOS | `osxkeychain` | Bundled with Docker Desktop |
| Windows | `wincred` | Bundled with Docker Desktop |

Per-registry helpers, useful when cloud CLIs manage their own tokens:

```json
{
  "credsStore": "pass",
  "credHelpers": {
    "123456789012.dkr.ecr.us-east-1.amazonaws.com": "ecr-login",
    "us-central1-docker.pkg.dev": "gcloud",
    "myregistry.azurecr.io": "acr-env"
  }
}
```

With `ecr-login` installed, ECR tokens refresh automatically and the 12-hour expiry stops
being something you have to script around.

### CI Environments

In CI, prefer short-lived tokens issued by the platform's identity integration over
long-lived secrets:

```yaml
# GitHub Actions — OIDC, no stored password
permissions:
  contents: read
  packages: write

steps:
  - uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}
```

## Tagging Strategy

Tags are mutable pointers. `myapp:1.2.3` can be reassigned to different content tomorrow,
which is why tags alone are a weak basis for deployment.

### Tag by Immutable Identity

```bash
GIT_SHA=$(git rev-parse --short HEAD)
VERSION=$(git describe --tags --always)

docker build \
  -t registry.example.com/myapp:"$GIT_SHA" \
  -t registry.example.com/myapp:"$VERSION" \
  -t registry.example.com/myapp:latest \
  .
```

A recommended set for a released build:

| Tag | Example | Purpose |
|-----|---------|---------|
| Git SHA | `a1b2c3d` | Exact provenance; never reused |
| Full semver | `1.2.3` | The release humans refer to |
| Minor | `1.2` | Moves with patch releases |
| Major | `1` | Moves with minor releases |
| `latest` | `latest` | Most recent release; convenience only |
| Branch | `main`, `pr-42` | Pre-release testing |

### The `latest` Problem

`latest` is not special to Docker — it is only the tag assumed when none is given. It carries
no ordering guarantee and points wherever it was last pushed.

```dockerfile
FROM node:latest        # unpredictable; changes under you
FROM node:20            # better
FROM node:20.11.1-alpine3.19  # good
FROM node:20-alpine@sha256:9e6918e8e32a47a58ed5fb9bd235bbc1d18a8c272e37f15d502b9db9e36821ee  # reproducible
```

### Digest Pinning

A digest addresses content, not a name, so it cannot be reassigned:

```bash
# Find the digest of an image
docker inspect --format='{{index .RepoDigests 0}}' myapp:1.2.3

# Pull by digest
docker pull registry.example.com/myapp@sha256:abc123...
```

Deploy by digest where supply-chain integrity matters. Tools such as Renovate can keep
digest pins updated in Dockerfiles and manifests so this does not become a maintenance
burden.

## Pushing and Pulling

```bash
# Tag an existing local image for a registry
docker tag myapp:1.0 registry.example.com/team/myapp:1.0
docker push registry.example.com/team/myapp:1.0

# Push every tag of a repository
docker push --all-tags registry.example.com/team/myapp

docker pull registry.example.com/team/myapp:1.0
```

Multi-platform images are pushed by the builder rather than `docker push` — see
[buildx](images.md#buildx-and-multi-arch-builds):

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t registry.example.com/team/myapp:1.0 --push .
```

### Inspecting Without Pulling

```bash
# Manifest, platforms, and digests of a remote image
docker buildx imagetools inspect registry.example.com/team/myapp:1.0

# Raw manifest JSON
docker buildx imagetools inspect --raw registry.example.com/team/myapp:1.0

# Copy or re-tag remotely without a local pull
docker buildx imagetools create \
  -t registry.example.com/team/myapp:stable \
  registry.example.com/team/myapp:1.0
```

## Private Registries

### Self-Hosted Registry

The upstream `registry:2` image is minimal but sufficient for internal distribution:

```yaml
services:
  registry:
    image: registry:2
    restart: always
    ports:
      - "5000:5000"
    environment:
      REGISTRY_STORAGE_DELETE_ENABLED: "true"
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: "Registry Realm"
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
      REGISTRY_HTTP_TLS_CERTIFICATE: /certs/domain.crt
      REGISTRY_HTTP_TLS_KEY: /certs/domain.key
    volumes:
      - registry-data:/var/lib/registry
      - ./auth:/auth:ro
      - ./certs:/certs:ro

volumes:
  registry-data:
```

```bash
# Generate credentials
mkdir -p auth
docker run --rm --entrypoint htpasswd httpd:2 -Bbn admin 'strong-password' > auth/htpasswd
```

`REGISTRY_STORAGE_DELETE_ENABLED` is off by default; without it, deleting tags frees no
space. See [Retention and Cleanup](#retention-and-cleanup).

### Managed and Full-Featured Options

| Registry | Notes |
|----------|-------|
| **Harbor** | Self-hosted, CNCF. RBAC, projects, built-in Trivy scanning, cosign integration, replication, quotas. The usual choice for an on-premises registry that needs governance. |
| **GHCR** (`ghcr.io`) | Tied to GitHub repos and permissions; free for public images. Good default when the code is already on GitHub. |
| **ECR** | AWS-native, IAM-based auth, lifecycle policies, optional scanning. Token expiry needs a credential helper. |
| **ACR** | Azure-native, Entra ID auth, geo-replication, tasks for in-registry builds. |
| **Artifact Registry** | Google Cloud, IAM-based, multi-format. |
| **Docker Hub** | Universal reach; note the pull rate limits below. |

### Insecure Registries

A registry on plain HTTP, or with a self-signed certificate, is refused unless the daemon is
told to allow it:

```json
{
  "insecure-registries": ["registry.internal:5000"]
}
```

> [!CAUTION]
> This disables TLS verification for that registry, allowing an on-path attacker to serve
> substituted images. Use it only on isolated networks and only as a temporary measure. The
> correct fix is to install the registry's CA certificate on each host:
>
> ```bash
> sudo cp registry-ca.crt /usr/local/share/ca-certificates/
> sudo update-ca-certificates
> sudo systemctl restart docker
> ```
>
> Docker also reads per-registry certificates from
> `/etc/docker/certs.d/registry.internal:5000/ca.crt`.

## Registry Mirrors

### Docker Hub Rate Limits

Docker Hub limits anonymous and free-tier pulls by source IP. Behind shared NAT — a CI
farm, an office, a Kubernetes cluster — a handful of builds can exhaust the quota, producing
`toomanyrequests: You have reached your pull rate limit` on every host at once.

Three mitigations, in order of effectiveness:

1. Run a pull-through cache so repeated pulls hit the mirror, not Hub.
2. Authenticate — authenticated pulls have a higher allowance than anonymous ones.
3. Host your base images in your own registry.

### Pull-Through Cache

```yaml
services:
  mirror:
    image: registry:2
    restart: always
    ports:
      - "5000:5000"
    environment:
      REGISTRY_PROXY_REMOTEURL: https://registry-1.docker.io
      REGISTRY_PROXY_USERNAME: "${HUB_USERNAME}"
      REGISTRY_PROXY_PASSWORD: "${HUB_TOKEN}"
    volumes:
      - mirror-data:/var/lib/registry

volumes:
  mirror-data:
```

Point the daemon at it:

```json
{
  "registry-mirrors": ["https://mirror.internal:5000"]
}
```

```bash
sudo systemctl restart docker
docker info | grep -A2 'Registry Mirrors'
```

Mirrors apply only to Docker Hub pulls. Images from other registries are always fetched
directly, and pushes never go to a mirror.

## Image Signing

Signing lets a consumer verify that an image came from you and has not been altered.

### Cosign

[Cosign](https://docs.sigstore.dev/) (part of Sigstore) is the current standard and works
with any OCI registry.

```bash
# Key-based signing
cosign generate-key-pair
cosign sign --key cosign.key registry.example.com/myapp:1.0
cosign verify --key cosign.pub registry.example.com/myapp:1.0
```

Keyless signing avoids managing a private key by binding the signature to an OIDC identity
and recording it in a public transparency log:

```bash
# Signs using an OIDC identity; in CI this is the workflow's own token
cosign sign registry.example.com/myapp:1.0

cosign verify \
  --certificate-identity-regexp 'https://github.com/example/myapp/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  registry.example.com/myapp:1.0
```

```yaml
# GitHub Actions
permissions:
  packages: write
  id-token: write        # required for keyless signing

steps:
  - uses: sigstore/cosign-installer@v3
  - run: cosign sign --yes ghcr.io/example/myapp@${{ steps.build.outputs.digest }}
```

> [!IMPORTANT]
> Sign the **digest**, not the tag. Signing `myapp:1.0` records a signature against whatever
> that tag pointed to at the time; if the tag is later moved, verification of the tag can
> succeed against different content than you signed.

### Attestations and SBOMs

Cosign also attaches provenance and software bills of materials:

```bash
cosign attest --predicate sbom.spdx.json --type spdxjson \
  registry.example.com/myapp@sha256:abc123...
```

buildx can generate both at build time:

```bash
docker buildx build \
  --sbom=true --provenance=mode=max \
  -t registry.example.com/myapp:1.0 --push .
```

SBOM generation and vulnerability scanning are covered in
[Image Security](../containers/security/index.md#image-security).

### Docker Content Trust

`DOCKER_CONTENT_TRUST=1` enables the older Notary v1 signing built into the Docker CLI:

```bash
export DOCKER_CONTENT_TRUST=1
docker push registry.example.com/myapp:1.0
```

It works, but it is tied to Docker Hub's Notary service and the wider ecosystem has moved to
Sigstore. Prefer cosign for new work.

### Enforcing Signatures

Signing only helps if something checks. Enforcement happens at deployment: admission
controllers such as **Kyverno**, **Connaisseur**, or **Sigstore Policy Controller** verify
signatures before a workload is admitted. Harbor can also block unsigned images from being
pulled. Without an enforcement point, a signature is documentation.

## Retention and Cleanup

Registries grow without bound unless something deletes old images.

### Self-Hosted `registry:2`

Deletion is two-phase: remove the manifest, then garbage-collect the blobs.

```bash
# Delete a manifest by digest (requires REGISTRY_STORAGE_DELETE_ENABLED=true)
DIGEST=$(curl -sI -H "Accept: application/vnd.oci.image.manifest.v1+json" \
  https://registry.example.com/v2/myapp/manifests/1.0 \
  | awk '/[Dd]ocker-[Cc]ontent-[Dd]igest/ {print $2}' | tr -d '\r')

curl -X DELETE "https://registry.example.com/v2/myapp/manifests/${DIGEST}"

# Reclaim disk
docker exec registry bin/registry garbage-collect \
  --delete-untagged /etc/docker/registry/config.yml
```

> [!WARNING]
> Run garbage collection with the registry read-only or stopped. A push concurrent with GC
> can have its blobs collected before the manifest lands, producing a corrupt repository.

### Managed Registries

Use the provider's lifecycle rules rather than scripting deletions:

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire untagged images after 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": { "type": "expire" }
    }
  ]
}
```

Harbor offers equivalent tag retention policies per project, and ACR has
`az acr task` purge jobs.

### Local Cleanup

Registry pulls also accumulate locally — see
[Disk Usage and Pruning](storage.md#disk-usage-and-pruning).

```bash
docker image prune -a --filter 'until=168h'
```

## Troubleshooting

| Error | Cause and fix |
|-------|---------------|
| `denied: requested access to the resource is denied` | Not logged in, wrong namespace, or token lacks write scope |
| `unauthorized: authentication required` | Token expired — ECR tokens last 12 hours; re-login or use a credential helper |
| `toomanyrequests` | Docker Hub rate limit; authenticate or use a [mirror](#registry-mirrors) |
| `x509: certificate signed by unknown authority` | Install the registry CA; see [Insecure Registries](#insecure-registries) |
| `server gave HTTP response to HTTPS client` | Registry is plain HTTP; enable TLS or add to `insecure-registries` |
| `manifest unknown` | Tag does not exist, or wrong platform for the manifest |
| `no matching manifest for linux/arm64` | Image is single-arch; build multi-arch or force `--platform` |
| Push succeeds but disk does not shrink after delete | Garbage collection has not run |

```bash
# Verify what the daemon believes about registries
docker info | grep -A5 -E 'Registry|Insecure'

# Check where credentials are coming from
cat ~/.docker/config.json

# Test registry reachability and auth directly
curl -u user:pass https://registry.example.com/v2/_catalog
```

## Related Topics

- [Building Images](images.md) — producing what you push, including multi-arch manifests
- [Daemon Configuration](daemon.md) — `registry-mirrors`, `insecure-registries`, and CA trust
- [Docker Storage](storage.md) — reclaiming local disk from pulled images
- [Container Security](../containers/security/index.md) — scanning, SBOMs, and admission control
- [CI/CD Pipelines](../../development/automation/ci-cd/index.md) — automated build and push
