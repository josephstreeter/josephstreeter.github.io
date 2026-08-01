---
title: "Docker Swarm"
description: "Clustering Docker hosts with Swarm mode: services, stacks, secrets, rolling updates, and overlay networking"
tags: ["docker", "swarm", "orchestration", "clustering", "services", "stacks"]
category: "infrastructure"
difficulty: "advanced"
last_updated: "2026-08-01"
---

## Docker Swarm

Swarm mode turns a group of Docker hosts into a single cluster with scheduling, service
discovery, rolling updates, and secret distribution — using the Docker CLI and Compose files
you already know. It is built into the engine, so there is nothing to install.

Swarm is far simpler than Kubernetes and correspondingly less capable. That trade is a
genuine advantage for small clusters, homelabs, and teams without a platform engineer, and a
real limitation once you need autoscaling, a rich operator ecosystem, or fine-grained RBAC.

## Table of Contents

- [Swarm or Kubernetes](#swarm-or-kubernetes)
- [Architecture](#architecture)
- [Creating a Cluster](#creating-a-cluster)
- [Managing Nodes](#managing-nodes)
- [Services](#services)
- [Rolling Updates and Rollback](#rolling-updates-and-rollback)
- [Stacks](#stacks)
- [Overlay Networking](#overlay-networking)
- [Secrets and Configs](#secrets-and-configs)
- [Placement Control](#placement-control)
- [Storage](#storage)
- [Operations](#operations)
- [Troubleshooting](#troubleshooting)

## Swarm or Kubernetes

| | Swarm | Kubernetes |
|---|-------|------------|
| Setup | `docker swarm init` | Managed service, or kubeadm and a CNI |
| Learning curve | Hours | Weeks |
| Config format | Compose files | Manifests, Helm, Kustomize |
| Autoscaling | Manual scaling only | HPA, VPA, cluster autoscaler |
| Ecosystem | Small | Very large |
| RBAC | Minimal | Comprehensive |
| Ingress | Routing mesh, or a proxy service | Ingress controllers, Gateway API |
| Development pace | Maintenance-level | Rapid |

Swarm remains supported and is a reasonable choice for a handful of nodes running services
you deploy by hand, a homelab, or an edge site where a Kubernetes control plane is
disproportionate. Choose Kubernetes when you need autoscaling, multi-tenancy, or the wider
ecosystem — and see [Container Orchestration](../containers/orchestration/index.md) and
[Kubernetes](../kubernetes/index.md) for that path.

> [!NOTE]
> Swarm development is in maintenance mode: it receives fixes and security updates rather
> than significant new capability. Factor that into decisions with a long horizon.

## Architecture

**Manager nodes** maintain cluster state and schedule work. They use the Raft consensus
algorithm, so a majority must be reachable for the cluster to accept changes.

**Worker nodes** run tasks. Managers are also workers by default.

| Managers | Failures tolerated |
|----------|-------------------|
| 1 | 0 — any failure loses the cluster |
| 3 | 1 |
| 5 | 2 |
| 7 | 3 |

Use an **odd number** of managers — an even count adds no fault tolerance over the odd number
below it. Three is right for most clusters; five for larger ones. More than seven degrades
write performance without meaningful benefit.

> [!IMPORTANT]
> Losing manager quorum does not stop running containers, but the cluster becomes read-only:
> no deployments, no rescheduling, no scaling. Recovering requires either restoring a manager
> or forcing a new cluster with `--force-new-cluster`, which is disruptive. Spread managers
> across failure domains.

### Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 2377 | TCP | Cluster management — managers only |
| 7946 | TCP + UDP | Node-to-node communication and gossip |
| 4789 | UDP | Overlay network traffic (VXLAN) |

```bash
sudo ufw allow 2377/tcp
sudo ufw allow 7946
sudo ufw allow 4789/udp
```

Blocked port 7946 or 4789 produces the characteristic failure where nodes join successfully
but services cannot reach each other across hosts.

## Creating a Cluster

```bash
# On the first manager — advertise-addr matters on multi-homed hosts
docker swarm init --advertise-addr 192.168.1.10
```

The output includes the worker join command. Retrieve join tokens later with:

```bash
docker swarm join-token worker
docker swarm join-token manager

# Just the token
docker swarm join-token -q worker
```

```bash
# On each worker
docker swarm join --token SWMTKN-1-xxxx 192.168.1.10:2377

# On additional managers
docker swarm join --token SWMTKN-1-yyyy 192.168.1.10:2377
```

```bash
docker node ls
docker info | grep -A10 Swarm
```

### Leaving and Dissolving

```bash
# On a worker
docker swarm leave

# On a manager (last one, or forcing)
docker swarm leave --force

# Remove a departed node from the roster, from a manager
docker node rm <node-id>
```

### Locking the Swarm

Raft logs and TLS keys sit encrypted on disk, but the unlock key is stored in the clear by
default so the daemon can restart unattended. Autolock requires the key on every restart:

```bash
docker swarm init --autolock
docker swarm update --autolock=true

# After a daemon restart
docker swarm unlock

# Retrieve or rotate the key
docker swarm unlock-key
docker swarm unlock-key --rotate
```

Store the key in a password manager. Losing it with autolock enabled means rebuilding the
cluster.

## Managing Nodes

```bash
docker node ls
docker node inspect <node> --pretty
docker node ps <node>              # tasks on that node
```

### Availability

```bash
docker node update --availability drain worker-2    # evacuate for maintenance
docker node update --availability pause worker-2    # no new tasks, keep existing
docker node update --availability active worker-2   # back into rotation
```

Draining a manager is good practice on small clusters — it keeps the control plane
responsive under load.

### Promotion and Labels

```bash
docker node promote worker-1
docker node demote manager-3

# Labels drive placement constraints
docker node update --label-add zone=rack1 --label-add disk=ssd worker-1
docker node inspect worker-1 --format '{{json .Spec.Labels}}'
```

## Services

A service is the declared desired state; Swarm creates **tasks** (containers) to satisfy it.

```bash
docker service create \
  --name web \
  --replicas 3 \
  --publish published=80,target=80 \
  nginx:1.25-alpine

docker service ls
docker service ps web
docker service inspect web --pretty
docker service logs -f web
```

### Replicated vs Global

```bash
# Replicated — a fixed number of tasks, placed anywhere eligible
docker service create --name api --replicas 5 myapp:1.0

# Global — exactly one task on every eligible node
docker service create --name node-exporter --mode global \
  --mount type=bind,source=/proc,target=/host/proc,readonly \
  prom/node-exporter
```

Global mode suits agents: log shippers, metrics exporters, monitoring.

### Scaling

```bash
docker service scale web=5
docker service scale web=5 api=3

docker service update --replicas 10 web
```

Swarm has no autoscaling. Scaling is a deliberate operation, which is one of the sharper
differences from Kubernetes.

### Resource Limits and Health

```bash
docker service create \
  --name api \
  --replicas 3 \
  --limit-cpu 1.0 --limit-memory 512M \
  --reserve-cpu 0.25 --reserve-memory 128M \
  --health-cmd "curl -fsS http://localhost:8080/health || exit 1" \
  --health-interval 30s \
  --health-retries 3 \
  --health-start-period 40s \
  --restart-condition on-failure \
  --restart-max-attempts 3 \
  myapp:1.0
```

**Reservations** are what the scheduler uses to decide placement; **limits** are enforced at
runtime. Setting reservations too high leaves tasks pending with no eligible node — a common
cause of a service that never starts.

Health checks matter more here than in standalone Docker: rolling updates use them to decide
whether a new task is good before continuing.

## Rolling Updates and Rollback

```bash
docker service update \
  --image myapp:2.0 \
  --update-parallelism 1 \
  --update-delay 30s \
  --update-order start-first \
  --update-failure-action rollback \
  --update-monitor 60s \
  --update-max-failure-ratio 0.25 \
  api
```

| Option | Effect |
|--------|--------|
| `--update-parallelism` | Tasks updated simultaneously. `1` is safest. |
| `--update-delay` | Pause between batches |
| `--update-order` | `start-first` (new task healthy before old stops) or `stop-first` (default) |
| `--update-failure-action` | `pause` (default), `continue`, or `rollback` |
| `--update-monitor` | Window in which a task failure counts against the update |
| `--update-max-failure-ratio` | Failure fraction tolerated before the action triggers |

`--update-order start-first` with a health check is what gives zero-downtime deployment.
`stop-first` briefly reduces capacity and can drop requests.

```bash
# Watch progress
docker service ps api

# Manual rollback to the previous spec
docker service rollback api
```

Configure rollback behavior in advance:

```bash
docker service update \
  --rollback-parallelism 2 \
  --rollback-delay 10s \
  --rollback-failure-action pause \
  api
```

> [!TIP]
> Deploy by digest rather than tag. `docker service update --image myapp:2.0` resolves the
> tag once at update time and pins the digest, but referencing an immutable digest directly
> makes what is running unambiguous. See [Digest Pinning](registries.md#digest-pinning).

### Forcing a Restart

```bash
docker service update --force api
```

Useful after a config change that does not alter the service spec.

## Stacks

A stack deploys a whole Compose file to the cluster.

```yaml
# docker-stack.yml
services:
  web:
    image: nginx:1.25-alpine
    ports:
      - "80:80"
    networks:
      - frontend
    configs:
      - source: nginx_conf
        target: /etc/nginx/conf.d/default.conf
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 20s
        order: start-first
        failure_action: rollback
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: "0.5"
          memory: 256M
        reservations:
          cpus: "0.1"
          memory: 64M
      placement:
        constraints:
          - node.role == worker

  api:
    image: registry.example.com/myapp:1.0
    networks:
      - frontend
      - backend
    secrets:
      - db_password
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 40s
    deploy:
      replicas: 4
      placement:
        max_replicas_per_node: 2

  db:
    image: postgres:16-alpine
    networks:
      - backend
    volumes:
      - db-data:/var/lib/postgresql/data
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.labels.disk == ssd

networks:
  frontend:
    driver: overlay
  backend:
    driver: overlay
    internal: true

volumes:
  db-data:

secrets:
  db_password:
    external: true

configs:
  nginx_conf:
    file: ./nginx.conf
```

```bash
docker stack deploy -c docker-stack.yml myapp

docker stack ls
docker stack services myapp
docker stack ps myapp
docker stack rm myapp
```

Redeploying the same file applies changes as rolling updates — `docker stack deploy` is both
create and update.

```bash
# Pull newer images on every node during deploy
docker stack deploy -c docker-stack.yml --with-registry-auth --resolve-image always myapp
```

`--with-registry-auth` forwards your registry credentials to the workers, and is required for
private images — without it workers fail to pull with an authentication error even though the
manager pulled fine.

### Compose Differences

`docker stack deploy` and `docker compose up` read the same file but honor different keys:

| Key | `docker compose up` | `docker stack deploy` |
|-----|--------------------|-----------------------|
| `build:` | **Used** | Ignored — push to a registry first |
| `depends_on:` | Controls start order | Ignored |
| `container_name:` | Used | Ignored |
| `profiles:` | Used | Ignored |
| `restart:` | Used | Ignored — use `deploy.restart_policy` |

`deploy:` is not simply "Swarm-only" — Compose v2 honors part of it and silently ignores the
rest:

| `deploy` key | `docker compose up` | `docker stack deploy` |
|--------------|--------------------|-----------------------|
| `replicas` | **Used** — creates N containers | Used |
| `resources.limits` / `reservations` | **Used** — limits applied; reservations inform scheduling only | Used |
| `restart_policy` | **Used** | Used |
| `mode: global` | Ignored | Used |
| `endpoint_mode` | Ignored | Used |
| `update_config` / `rollback_config` | Ignored | Used |
| `placement` | Ignored | Used |

The ignored keys produce **no warning** — a Compose file with `mode: global` and
`update_config` comes up cleanly, having applied neither. Do not read a successful
`docker compose up` as confirmation that a stack file's orchestration settings are in effect.

The `build:` and `depends_on:` differences catch people out most often. Swarm has no startup
ordering at all — services must tolerate their dependencies being temporarily absent, which
is sound design regardless but is mandatory here.

See [Docker Compose](dockercompose/index.md) for the file format itself.

## Overlay Networking

Overlay networks span nodes using VXLAN, so containers on different hosts share a subnet.

```bash
docker network create -d overlay backend

# Allow standalone containers to attach, not just services
docker network create -d overlay --attachable dev-net

# Encrypt the data plane with IPsec
docker network create -d overlay --opt encrypted secure-net

docker network create -d overlay --subnet 10.20.0.0/16 --gateway 10.20.0.1 custom
```

Encryption costs throughput; it is worthwhile when nodes communicate over untrusted networks
and unnecessary within a trusted private VLAN.

### The Routing Mesh

Publishing a service port makes it reachable on **every node**, regardless of where tasks
actually run. A request to a node without a local task is forwarded to one that has it.

```bash
docker service create --name web --replicas 2 --publish published=80,target=80 nginx
# Reachable on port 80 of every node in the cluster
```

This makes external load balancing simple — point at any node, or all of them. It also means
the source IP seen by the container is a mesh address rather than the real client. To
preserve client IPs, bypass the mesh:

```bash
docker service create \
  --name web \
  --mode global \
  --publish mode=host,published=80,target=80 \
  nginx
```

`mode=host` publishes only on nodes running a task, so pair it with `--mode global` or an
external load balancer that knows where tasks are.

### Service Discovery

Every service gets a DNS name resolving to a **virtual IP** that load-balances across healthy
tasks:

```bash
docker service create --name api --network backend --replicas 3 myapp:1.0
# Other services on 'backend' simply use http://api:8080
```

For the individual task addresses instead of a VIP:

```bash
docker service create --endpoint-mode dnsrr --name api myapp:1.0
```

VIP mode is the default and generally what you want; `dnsrr` is for cases where a client does
its own load balancing, and it does not work with the routing mesh.

## Secrets and Configs

Swarm secrets are encrypted in the Raft log, transmitted over mutual TLS, and mounted into
tasks on an in-memory filesystem.

```bash
# From a file
docker secret create db_password ./db_password.txt

# From stdin — avoids leaving the value on disk
printf 'S3cr3t!' | docker secret create db_password -

docker secret ls
docker secret inspect db_password        # metadata only; the value is never readable
```

```bash
docker service create \
  --name api \
  --secret db_password \
  --secret source=tls_cert,target=/etc/ssl/cert.pem,mode=0400 \
  myapp:1.0
```

Secrets appear at `/run/secrets/<name>`. Most well-behaved images accept a `_FILE` variant of
their environment variables so the value never lands in the environment:

```yaml
environment:
  POSTGRES_PASSWORD_FILE: /run/secrets/db_password
```

Configs work identically for non-sensitive files, and are not encrypted at rest:

```bash
docker config create nginx_conf ./nginx.conf
docker service create --name web --config source=nginx_conf,target=/etc/nginx/nginx.conf nginx
```

### Rotation

Secrets and configs are **immutable**. Rotating means creating a new one and updating the
service:

```bash
printf 'newS3cr3t!' | docker secret create db_password_v2 -

docker service update \
  --secret-rm db_password \
  --secret-add source=db_password_v2,target=/run/secrets/db_password \
  api

docker secret rm db_password
```

Keeping `target=` stable means the application path does not change.

## Placement Control

```bash
# Constraints — hard requirements
docker service create --name db \
  --constraint 'node.role == worker' \
  --constraint 'node.labels.disk == ssd' \
  --constraint 'node.hostname != worker-3' \
  postgres:16

# Preferences — soft spreading
docker service create --name api \
  --replicas 9 \
  --placement-pref 'spread=node.labels.zone' \
  myapp:1.0

# Spread across nodes
docker service create --name api --replicas 6 \
  --placement-pref 'spread=node.id' \
  myapp:1.0
```

Available attributes: `node.id`, `node.hostname`, `node.role`, `node.platform.os`,
`node.platform.arch`, `node.labels.*`, `engine.labels.*`.

In a stack file:

```yaml
deploy:
  placement:
    constraints:
      - node.role == worker
      - node.labels.zone == east
    preferences:
      - spread: node.labels.rack
    max_replicas_per_node: 2
```

Mixed-OS clusters use the platform attributes:

```yaml
deploy:
  placement:
    constraints:
      - node.platform.os == windows
```

See [Windows Containers](windows-containers.md).

## Storage

Swarm does **not** move volume data between nodes. A task rescheduled onto another host finds
an empty local volume — which silently loses data for a stateful service unless you plan for
it.

Options, in order of robustness:

1. **Pin the service to one node** with a constraint, and accept that the node is a single
   point of failure.
2. **Use shared storage** — NFS, CIFS, or a clustered filesystem — so any node sees the same
   data.
3. **Run stateful services outside the cluster**, and treat Swarm as stateless compute.

```yaml
volumes:
  db-data:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=192.168.1.100,rw,nfsvers=4,hard"
      device: ":/exports/db-data"
```

See [Volume Drivers](storage.md#volume-drivers). For databases specifically, option 3 is
usually the sound choice — replication and failover are the database's job, not the
orchestrator's.

## Operations

### Backing Up Cluster State

Swarm state lives in `/var/lib/docker/swarm` on managers.

```bash
# On a manager — stop the daemon for a consistent copy
sudo systemctl stop docker
sudo tar czf swarm-backup-$(date +%F).tar.gz -C /var/lib/docker swarm
sudo systemctl start docker
```

Restoring:

```bash
sudo systemctl stop docker
sudo rm -rf /var/lib/docker/swarm
sudo tar xzf swarm-backup-2026-08-01.tar.gz -C /var/lib/docker
sudo systemctl start docker
docker swarm init --force-new-cluster --advertise-addr 192.168.1.10
```

`--force-new-cluster` rebuilds a single-manager cluster from the restored Raft log, preserving
services and secrets. Rejoin the other managers afterwards.

> [!IMPORTANT]
> The backup contains the Raft log, and therefore every secret. Encrypt it and restrict
> access accordingly.

### Certificate Rotation

Swarm issues mutual TLS certificates to nodes automatically, rotating every 90 days by
default.

```bash
docker swarm update --cert-expiry 720h
docker swarm ca --rotate            # rotate the CA itself
```

### Monitoring

```bash
docker node ls
docker service ls
docker stack ps myapp --no-trunc
docker service ps api --filter 'desired-state=running'
```

The Prometheus metrics endpoint from [Daemon Configuration](daemon.md) exposes Swarm metrics
on managers. See [Monitoring and Logging](monitoring.md).

## Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| Tasks stuck in `Pending` | No node satisfies constraints or reservations — `docker service ps --no-trunc` |
| `no suitable node` | Constraints too narrow, or all candidates drained |
| Nodes join but services cannot communicate | Ports 7946 or 4789 blocked |
| `Down` nodes that are actually up | Clock skew, or 7946 gossip blocked |
| Workers cannot pull private images | Deploy with `--with-registry-auth` |
| Service keeps restarting | Failing health check — `docker service logs` and `docker service ps --no-trunc` |
| Data lost after rescheduling | Local volume on a different node; see [Storage](#storage) |
| Cluster read-only, deploys hang | Lost manager quorum |
| Client IPs show as mesh addresses | Routing mesh; use `mode=host` publishing |

```bash
# The most useful single command — shows the error for failed tasks
docker service ps api --no-trunc

# Task-level detail
docker inspect <task-id>

# Per-node view
docker node ps <node> --no-trunc

# Daemon logs on the affected node
sudo journalctl -u docker -n 100
```

### Recovering Lost Quorum

With a majority of managers permanently gone, force a new cluster from a survivor:

```bash
# On a surviving manager
docker swarm init --force-new-cluster --advertise-addr 192.168.1.10

# Then rejoin the rest
docker node rm <dead-node>
docker swarm join-token manager
```

Running services continue throughout — this restores the control plane, not the workloads.

## Related Topics

- [Docker Compose](dockercompose/index.md) — the file format stacks build on
- [Docker Networking](networking.md) — the networking concepts overlays extend
- [Docker Storage](storage.md) — volume drivers for shared storage
- [Registries](registries.md) — private image access from workers
- [Daemon Configuration](daemon.md) — cluster host configuration
- [Container Orchestration](../containers/orchestration/index.md) — comparison with other orchestrators
- [Kubernetes](../kubernetes/index.md) — the alternative when Swarm is not enough
