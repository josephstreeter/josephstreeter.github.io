---
title: "Docker Daemon Configuration"
description: "daemon.json reference, systemd integration, remote API with TLS, and managing multiple engines with contexts"
tags: ["docker", "daemon", "systemd", "configuration", "tls", "context"]
category: "infrastructure"
difficulty: "advanced"
last_updated: "2026-08-01"
---

## Docker Daemon Configuration

Most Docker behavior that cannot be changed with a `docker run` flag is set on the daemon.
Log rotation, the storage driver, which subnets Docker allocates from, whether it manages
firewall rules — all of it lives in `daemon.json` or the systemd unit. This page covers
configuring the daemon, running it safely over the network, and pointing one CLI at several
engines.

## Table of Contents

- [daemon.json](#daemonjson)
- [Applying Changes](#applying-changes)
- [Common Configuration](#common-configuration)
- [Address Pools](#address-pools)
- [Logging Configuration](#logging-configuration)
- [systemd Integration](#systemd-integration)
- [Remote Access and TLS](#remote-access-and-tls)
- [Docker Contexts](#docker-contexts)
- [Troubleshooting](#troubleshooting)

## daemon.json

| Platform | Path |
|----------|------|
| Linux | `/etc/docker/daemon.json` |
| Linux (rootless) | `~/.config/docker/daemon.json` |
| Windows | `C:\ProgramData\docker\config\daemon.json` |
| Docker Desktop | Settings → Docker Engine |

The file does not exist by default. A reasonable production baseline:

```json
{
  "data-root": "/var/lib/docker",
  "storage-driver": "overlay2",

  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },

  "default-address-pools": [
    { "base": "10.200.0.0/16", "size": 24 }
  ],

  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,

  "default-ulimits": {
    "nofile": { "Name": "nofile", "Soft": 32768, "Hard": 65536 }
  },

  "metrics-addr": "127.0.0.1:9323"
}
```

> [!IMPORTANT]
> Invalid JSON prevents the daemon from starting, and the error appears only in the journal —
> the failure looks like Docker being broken rather than a config problem. Validate before
> restarting:
>
> ```bash
> sudo dockerd --validate --config-file /etc/docker/daemon.json
> jq . /etc/docker/daemon.json
> ```

## Applying Changes

Some options reload without dropping containers; most require a restart.

```bash
# Reload — no container downtime
sudo systemctl reload docker
# equivalently: sudo kill -SIGHUP $(pidof dockerd)

# Restart — required for most options
sudo systemctl restart docker
```

The set of reloadable options is fixed and short. These — and only these — take effect on
reload:

| Option | Effect |
|--------|--------|
| `debug` | Toggle debug mode |
| `labels` | Replace the daemon's labels |
| `live-restore` | Toggle live restore |
| `max-concurrent-downloads` | Concurrent layer downloads per pull |
| `max-concurrent-uploads` | Concurrent layer uploads per push |
| `max-download-attempts` | Retry count per pull |
| `default-runtime` | Runtime used when none is specified |
| `runtimes` | The set of available OCI runtimes |
| `authorization-plugin` | Authorization plugins |
| `insecure-registries` | Registries allowed over plain HTTP |
| `registry-mirrors` | Pull-through mirrors |
| `shutdown-timeout` | Grace period when stopping all containers |
| `features` | Feature toggles |

**Everything else requires a restart** — including `storage-driver`, `data-root`, `hosts`,
`ipv6`, `mtu`, `default-address-pools`, `userland-proxy`, `iptables`, `exec-opts`,
`log-driver`, `log-opts`, `dns`, and `default-ulimits`.

> [!NOTE]
> `log-level` is not reloadable despite `debug` being so; set `debug` to raise verbosity
> without a restart. Reloading an option that is not on this list fails silently — the daemon
> accepts the signal and keeps its old value, which reads as "the setting did nothing."

### Restarting Without Killing Containers

`live-restore` keeps containers running while the daemon restarts:

```json
{
  "live-restore": true
}
```

This is worth enabling on any host where container uptime matters. Two caveats: it does not
apply to Swarm mode, and it only covers daemon restarts — changes to networking or the
storage driver still need the containers themselves to be recreated.

```bash
# Verify
docker info | grep -i 'live restore'
```

## Common Configuration

### Storage

```json
{
  "storage-driver": "overlay2",
  "data-root": "/srv/docker"
}
```

Moving `data-root` off the root filesystem is one of the more valuable changes on a real
server — it stops image and log growth from filling `/`. To migrate:

```bash
sudo systemctl stop docker docker.socket
sudo rsync -aHAX --info=progress2 /var/lib/docker/ /srv/docker/
# Edit daemon.json, then
sudo systemctl start docker
docker info | grep 'Docker Root Dir'
# Once verified: sudo rm -rf /var/lib/docker
```

See [Storage Drivers and Layers](storage.md#storage-drivers-and-layers) for driver choice.

### Registries

```json
{
  "registry-mirrors": ["https://mirror.internal:5000"],
  "insecure-registries": ["registry.internal:5000"],
  "allow-nondistributable-artifacts": ["registry.internal:5000"]
}
```

See [Registries](registries.md) for mirrors and CA trust.

### DNS and Networking

```json
{
  "dns": ["10.0.0.10", "1.1.1.1"],
  "dns-search": ["internal.example.com"],
  "dns-opts": ["ndots:2"],
  "mtu": 1450,
  "ipv6": true,
  "fixed-cidr-v6": "fd00:dead:beef::/48",
  "icc": true,
  "userland-proxy": false
}
```

`"userland-proxy": false` removes the `docker-proxy` helper process per published port and
routes purely through iptables — fewer processes and slightly less overhead. It changes how
traffic from the host to a published port on `localhost` is handled, so verify local access
after enabling it.

Setting `"dns"` matters on hosts using `systemd-resolved`, where `/etc/resolv.conf` points at
`127.0.0.53` — an address that means nothing inside a container's network namespace. Docker
usually detects this and substitutes public resolvers, which silently bypasses internal DNS.
Setting the real internal resolvers explicitly avoids that.

### Disabling iptables Management

```json
{
  "iptables": false,
  "ip-forward": false
}
```

> [!CAUTION]
> This stops Docker from creating NAT and forwarding rules, which breaks outbound container
> connectivity and all port publishing until you write equivalent rules yourself. It is
> occasionally necessary alongside a strict host firewall, but the `DOCKER-USER` chain solves
> most cases with far less risk — see
> [Firewall Interaction](networking.md#firewall-interaction).

### Runtime and Security Defaults

```json
{
  "no-new-privileges": true,
  "default-runtime": "runc",
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "seccomp-profile": "/etc/docker/seccomp-default.json",
  "selinux-enabled": true,
  "userns-remap": "default"
}
```

`userns-remap` is covered in [Rootless Docker and User Namespaces](rootless.md).

### Concurrency and Limits

```json
{
  "max-concurrent-downloads": 6,
  "max-concurrent-uploads": 6,
  "shutdown-timeout": 30,
  "default-shm-size": "128M"
}
```

`default-shm-size` defaults to 64 MB, which is too small for Chrome-based browser automation
and some database workloads — a common cause of mysterious crashes in headless-browser
containers.

## Address Pools

Docker allocates user-defined bridge networks from `172.17.0.0/16` onward by default. On a
corporate network that also uses `172.16.0.0/12`, this produces routing conflicts where a
host suddenly cannot reach internal services after `docker compose up`.

```json
{
  "default-address-pools": [
    { "base": "10.200.0.0/16", "size": 24 },
    { "base": "10.201.0.0/16", "size": 24 }
  ],
  "bip": "10.199.0.1/24"
}
```

- `default-address-pools` governs networks Docker creates. `size: 24` yields 256 `/24`
  networks per `/16` base.
- `bip` sets the default `docker0` bridge address specifically.

Changing these requires a restart, and existing networks keep their old subnets — recreate
them:

```bash
docker compose down
docker network prune
sudo systemctl restart docker
docker compose up -d
```

## Logging Configuration

Unbounded container logs are among the most common causes of a full disk, and no `prune`
command removes them.

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true"
  }
}
```

That caps each container at 30 MB. **Existing containers keep their original settings** —
the change applies to containers created afterwards, so recreate them to take effect.

### Alternative Drivers

| Driver | Use case |
|--------|----------|
| `json-file` | Default. Works with `docker logs`. Cap the size. |
| `local` | More efficient, rotates by default. `docker logs` works; external tooling may not parse it. |
| `journald` | Sends to the systemd journal; unified host logging and `journalctl` filtering. |
| `syslog` | Ships to a syslog collector. |
| `fluentd` | Structured shipping to Fluentd/Fluent Bit. |
| `awslogs`, `gcplogs` | Cloud-native log services. |
| `none` | Disable logging for a noisy container. |

```json
{
  "log-driver": "journald",
  "log-opts": { "tag": "{{.Name}}" }
}
```

> [!NOTE]
> With a remote driver such as `fluentd` or `syslog`, `docker logs` returns nothing — logs go
> straight to the collector. Use `local` or `journald` if you want both local inspection and
> shipping. Consider also that a blocking remote driver can stall containers when the
> collector is unreachable; set `"mode": "non-blocking"` in `log-opts` to avoid that.

Per-container overrides remain available:

```bash
docker run -d --log-driver json-file --log-opt max-size=50m myapp
docker run -d --log-driver none noisy-batch-job
```

More detail in [Monitoring and Logging](monitoring.md).

## systemd Integration

### Service Management

```bash
sudo systemctl status docker
sudo systemctl start docker
sudo systemctl stop docker docker.socket
sudo systemctl restart docker

# Start on boot
sudo systemctl enable --now docker

# Prevent start on boot
sudo systemctl disable docker
```

`docker.socket` provides socket activation. Stopping only `docker.service` leaves the socket
active, and the next CLI command starts the daemon again — which is why `systemctl stop
docker` sometimes appears not to work. Stop both.

### Drop-In Overrides

Never edit `/lib/systemd/system/docker.service` directly; package updates overwrite it. Use
a drop-in:

```bash
sudo systemctl edit docker
```

```ini
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:3128"
Environment="HTTPS_PROXY=http://proxy.example.com:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.internal.example.com"
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl show docker --property=Environment
```

This is the supported way to configure a proxy for image pulls. Note it affects the daemon
only — containers need their own proxy environment, typically via `~/.docker/config.json`:

```json
{
  "proxies": {
    "default": {
      "httpProxy": "http://proxy.example.com:3128",
      "httpsProxy": "http://proxy.example.com:3128",
      "noProxy": "localhost,127.0.0.1,.internal.example.com"
    }
  }
}
```

### The `hosts` Conflict

Setting `"hosts"` in `daemon.json` fails on stock systemd installs, because the unit already
passes `-H fd://`:

```text
unable to configure the Docker daemon with file /etc/docker/daemon.json:
the following directives are specified both as a flag and in the configuration file:
hosts
```

Clear the unit's `ExecStart` before redefining it:

```bash
sudo systemctl edit docker
```

```ini
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
```

Then `daemon.json` controls the sockets:

```json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://127.0.0.1:2375"]
}
```

The empty `ExecStart=` is required — it resets the list rather than appending.

### Container Autostart

Docker restart policies handle boot autostart, provided the service is enabled:

```bash
sudo systemctl enable docker
docker run -d --restart unless-stopped myapp
```

| Policy | Behavior |
|--------|----------|
| `no` | Default. Never restarted. |
| `on-failure[:n]` | Restart on non-zero exit, optionally limited to `n` attempts. |
| `always` | Always restart, **including after a manual `docker stop` once the daemon restarts**. |
| `unless-stopped` | Like `always`, but respects a manual stop across daemon restarts. |

`unless-stopped` is almost always the right choice: a container you deliberately stopped
stays stopped after a reboot.

```bash
docker update --restart unless-stopped mycontainer
```

### Managing a Container as a systemd Unit

When a container must be ordered against other host services, a unit gives you dependency
control that restart policies cannot:

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=MyApp container
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

[Service]
Restart=always
RestartSec=10
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker rm -f myapp
ExecStartPre=/usr/bin/docker pull registry.example.com/myapp:1.0
ExecStart=/usr/bin/docker run --rm --name myapp \
  -p 8080:80 \
  -v myapp-data:/data \
  registry.example.com/myapp:1.0
ExecStop=/usr/bin/docker stop myapp

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now myapp
```

Use `--rm` with `docker run` in the foreground here, not `-d`; systemd needs to supervise a
process that stays in the foreground. Do not also set a Docker restart policy — two
supervisors fighting over the same container produces confusing behavior.

For Compose stacks:

```ini
[Unit]
Description=MyApp stack
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/srv/myapp
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
ExecReload=/usr/bin/docker compose up -d --force-recreate

[Install]
WantedBy=multi-user.target
```

### Persisting Host Network Configuration

Host-side network setup that Docker depends on — such as the
[macvlan shim](networking.md#macvlan) — belongs in a unit that runs before Docker:

```ini
# /etc/systemd/system/macvlan-shim.service
[Unit]
Description=macvlan host shim
Before=docker.service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/ip link add macvlan-shim link eth0 type macvlan mode bridge
ExecStart=/sbin/ip addr add 192.168.1.253/32 dev macvlan-shim
ExecStart=/sbin/ip link set macvlan-shim up
ExecStart=/sbin/ip route add 192.168.1.192/27 dev macvlan-shim
ExecStop=/sbin/ip link del macvlan-shim

[Install]
WantedBy=multi-user.target
```

### Daemon Logs

```bash
sudo journalctl -u docker -f
sudo journalctl -u docker --since "10 min ago"
sudo journalctl -u docker -p err
```

Enable debug logging temporarily when diagnosing:

```json
{
  "debug": true
}
```

```bash
sudo systemctl reload docker    # debug is reloadable — no restart needed
```

Use `debug` rather than `log-level` here: `debug` is one of the few options that takes effect
on reload, while `log-level` needs a full restart. Turn it back off the same way once you have
what you need — debug logging is verbose enough to fill a disk on a busy host.

## Remote Access and TLS

### The Risk

The Docker API grants root-equivalent control of the host — anyone who can reach it can
start a privileged container that mounts `/`.

> [!CAUTION]
> **Never expose `tcp://0.0.0.0:2375`.** Unauthenticated Docker sockets on the public
> internet are scanned for continuously and used to deploy cryptominers and worms within
> minutes. If you need remote access, use [SSH contexts](#docker-contexts) — no TLS setup,
> no open port, and access is governed by existing SSH keys.

### Generating Certificates

If you do need the TCP API, use mutual TLS on port 2376.

```bash
mkdir -p ~/docker-tls && cd ~/docker-tls
HOST=docker.example.com

# CA
openssl genrsa -aes256 -out ca-key.pem 4096
openssl req -new -x509 -days 3650 -key ca-key.pem -sha256 -out ca.pem \
  -subj "/CN=docker-ca"

# Server key and CSR
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=${HOST}" -sha256 -new -key server-key.pem -out server.csr

echo "subjectAltName = DNS:${HOST},IP:10.0.0.5,IP:127.0.0.1" > extfile.cnf
echo "extendedKeyUsage = serverAuth" >> extfile.cnf

openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf

# Client key and CSR
openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
echo "extendedKeyUsage = clientAuth" > extfile-client.cnf
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile-client.cnf

chmod 0400 ca-key.pem key.pem server-key.pem
chmod 0444 ca.pem server-cert.pem cert.pem
rm -f client.csr server.csr extfile.cnf extfile-client.cnf
```

### Daemon Configuration

```bash
sudo mkdir -p /etc/docker/certs
sudo cp ca.pem server-cert.pem server-key.pem /etc/docker/certs/
```

```json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"],
  "tls": true,
  "tlsverify": true,
  "tlscacert": "/etc/docker/certs/ca.pem",
  "tlscert": "/etc/docker/certs/server-cert.pem",
  "tlskey": "/etc/docker/certs/server-key.pem"
}
```

Remember the [`ExecStart` reset](#the-hosts-conflict) for the `hosts` key. `tlsverify`
requires clients to present a certificate signed by your CA — without it, TLS encrypts the
channel but authenticates nobody.

Restrict the port at the firewall as well:

```bash
sudo iptables -A INPUT -p tcp --dport 2376 -s 10.0.0.0/24 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2376 -j DROP
```

### Client Usage

```bash
mkdir -p ~/.docker
cp ca.pem cert.pem key.pem ~/.docker/

export DOCKER_HOST=tcp://docker.example.com:2376
export DOCKER_TLS_VERIFY=1
export DOCKER_CERT_PATH=~/.docker

docker info
```

Better, wrap it in a context so nothing global changes — see below.

## Docker Contexts

Contexts let one CLI address several engines without juggling `DOCKER_HOST`.

```bash
docker context ls
docker context inspect default
```

### SSH Contexts

The simplest and safest remote access — no daemon changes, no exposed port:

```bash
docker context create prod \
  --docker "host=ssh://deploy@prod.example.com" \
  --description "Production host"

docker context use prod
docker ps                      # runs against prod

docker context use default
```

Requirements on the remote host: key-based SSH for the user, and that user in the `docker`
group. Use an SSH config entry for anything non-standard:

```text
# ~/.ssh/config
Host prod.example.com
  User deploy
  IdentityFile ~/.ssh/id_ed25519_deploy
  ControlMaster auto
  ControlPath ~/.ssh/cm-%r@%h:%p
  ControlPersist 10m
```

`ControlMaster` reuses one connection across commands, which noticeably speeds up repeated
CLI calls.

### TLS Contexts

```bash
docker context create prod-tls \
  --docker "host=tcp://docker.example.com:2376,ca=~/.docker/ca.pem,cert=~/.docker/cert.pem,key=~/.docker/key.pem"
```

### Working With Contexts

```bash
# One-off against another context, without switching
docker --context prod ps
docker --context prod compose -f /srv/app/docker-compose.yml up -d

# Environment variable form
DOCKER_CONTEXT=prod docker ps

docker context update prod --description "Production (Frankfurt)"
docker context rm prod
```

Precedence: `DOCKER_HOST` overrides the selected context, and `--context` overrides both.
An unexplained "wrong host" usually turns out to be a stale `DOCKER_HOST` in a shell profile.

```bash
docker context ls        # the active one is marked with *
env | grep DOCKER
```

> [!TIP]
> Add the active context to your shell prompt when you regularly operate against production.
> `docker context show` prints just the name, which is cheap enough to call from a prompt
> function.

## Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| Daemon will not start after config change | Invalid JSON or an unknown key — `journalctl -u docker -n 50`, then `dockerd --validate` |
| `directives specified both as a flag and in the configuration file` | `hosts` conflict with the systemd unit; see [above](#the-hosts-conflict) |
| Changes to `log-opts` have no effect | Only applies to newly created containers; recreate them |
| Containers cannot resolve internal DNS | `systemd-resolved` stub address; set `"dns"` explicitly |
| Host loses access to internal subnets after starting containers | Address pool collision; set `default-address-pools` |
| `docker` commands hit the wrong machine | Stale `DOCKER_HOST`, or an unexpected active context |
| Daemon restart kills all containers | Enable `live-restore` |
| `Cannot connect to the Docker daemon` | Daemon down, or the user is not in the `docker` group |

```bash
# Full effective configuration
docker info

# What the daemon was actually started with
systemctl show docker --property=ExecStart
ps aux | grep dockerd

# Socket permissions
ls -l /var/run/docker.sock
```

> [!WARNING]
> Membership in the `docker` group is equivalent to root — a member can mount the host
> filesystem into a privileged container. Treat it as an administrative privilege, and
> consider [rootless Docker](rootless.md) where that is not acceptable.

## Related Topics

- [Rootless Docker and User Namespaces](rootless.md) — running without daemon root
- [Docker Networking](networking.md) — MTU, address pools, and firewall interaction
- [Docker Storage](storage.md) — storage driver and data root selection
- [Registries](registries.md) — mirrors, insecure registries, and CA trust
- [Monitoring and Logging](monitoring.md) — log drivers and the metrics endpoint
- [Container Security](../containers/security/index.md) — daemon hardening in context
