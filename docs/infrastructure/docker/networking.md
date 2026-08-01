---
title: "Docker Networking"
description: "Docker network drivers, DNS resolution, port publishing, firewall interaction, and IPv6 configuration"
tags: ["docker", "containers", "networking", "bridge", "macvlan", "dns", "iptables"]
category: "infrastructure"
difficulty: "intermediate"
last_updated: "2026-08-01"
---

## Docker Networking

Docker networking determines how containers reach each other, the host, and the outside
world. Most day-to-day problems — a container that cannot resolve a service name, a
published port that is unexpectedly reachable from the internet, a firewall rule that
appears to do nothing — come from a small number of behaviors that are worth understanding
directly rather than by trial and error.

This page covers the Docker engine's networking. For Kubernetes networking (CNI plugins,
Services, Ingress, NetworkPolicy), see [Container Networking](../kubernetes/networking.md).

## Table of Contents

- [How Docker Networking Works](#how-docker-networking-works)
- [Network Drivers](#network-drivers)
- [Bridge Networks](#bridge-networks)
- [Host and None Networks](#host-and-none-networks)
- [Macvlan and Ipvlan](#macvlan-and-ipvlan)
- [Overlay Networks](#overlay-networks)
- [DNS and Service Discovery](#dns-and-service-discovery)
- [Publishing Ports](#publishing-ports)
- [Firewall Interaction](#firewall-interaction)
- [IPv6](#ipv6)
- [Troubleshooting](#troubleshooting)
- [Performance](#performance)

## How Docker Networking Works

On a default Linux install, the daemon creates a Linux bridge device named `docker0`,
usually on `172.17.0.0/16`:

```bash
ip addr show docker0
docker network inspect bridge --format '{{json .IPAM.Config}}'
```

When a container starts on a bridge network, the daemon creates a **veth pair** — a virtual
cable with two ends. One end becomes `eth0` inside the container's network namespace; the
other appears on the host as a `veth*` interface enslaved to the bridge:

```bash
# Host side: veth interfaces attached to the bridge
ip link show master docker0

# Container side
docker exec mycontainer ip addr show eth0
```

Three rules follow from this design, and they explain most behavior:

- **Outbound traffic is masqueraded.** The daemon adds a `MASQUERADE` rule so container
  traffic leaving the host appears to come from the host's IP.
- **Inbound traffic requires publishing.** Nothing outside the host can reach a container
  unless a port is published, which installs a DNAT rule.
- **Containers on the same bridge talk directly.** No publishing is involved for
  container-to-container traffic; they are on a shared layer 2 segment.

> [!NOTE]
> `docker0` only exists for the default bridge network. Every user-defined bridge network
> gets its own bridge device named `br-<network-id-prefix>`.

## Network Drivers

| Driver | Scope | Use case | Container gets |
| ------ | ----- | -------- | -------------- |
| `bridge` | Single host | Default for standalone containers | Private IP behind NAT |
| `host` | Single host | Maximum network performance, port-heavy apps | The host's network stack |
| `none` | Single host | Fully isolated workloads | Loopback only |
| `macvlan` | Single host | Container as a first-class device on the LAN | Own MAC and LAN IP |
| `ipvlan` | Single host | Same, where the switch restricts MAC count | LAN IP, shares host MAC |
| `overlay` | Multi-host | Swarm services across nodes | VXLAN-tunnelled private IP |

```bash
# List networks and their drivers
docker network ls

# Inspect a network in full
docker network inspect bridge
```

## Bridge Networks

### Default Bridge vs User-Defined Bridges

The difference matters more than it looks. **Use a user-defined bridge for anything real.**

| Behavior | Default `bridge` | User-defined bridge |
| -------- | ---------------- | ------------------- |
| DNS resolution by container name | No | Yes |
| Network aliases | No | Yes |
| Containers isolated from other networks | No | Yes |
| Connect/disconnect a running container | No | Yes |
| Shares environment variables via `--link` | Yes (deprecated) | No |

```bash
# Create a user-defined bridge
docker network create mynet

# Containers on it resolve each other by name
docker run -d --name api --network mynet myapp:latest
docker run --rm --network mynet alpine ping -c1 api
```

### Custom Subnets and Static Addresses

```bash
docker network create \
  --driver bridge \
  --subnet 172.20.0.0/16 \
  --ip-range 172.20.240.0/20 \
  --gateway 172.20.0.1 \
  custom-net

# Static IP (only valid on user-defined networks)
docker run -d --name web --network custom-net --ip 172.20.0.10 nginx
```

`--ip-range` narrows the pool Docker allocates from, leaving the rest of the subnet free for
static assignments — useful when addresses must be predictable for firewall rules.

### Connecting a Container to Several Networks

A container can be attached to multiple networks, which is the usual way to place a reverse
proxy in both a public-facing and a backend network:

```bash
docker network create frontend
docker network create --internal backend

docker run -d --name proxy --network frontend nginx
docker network connect backend proxy

# Disconnect when no longer needed
docker network disconnect backend proxy
```

`--internal` creates a network with no external connectivity — containers on it can reach
each other but not the internet, and the internet cannot reach them. It is the simplest way
to isolate a database tier.

### Bridge Driver Options

```bash
docker network create \
  --driver bridge \
  --opt com.docker.network.bridge.name=br-custom \
  --opt com.docker.network.bridge.enable_icc=true \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  --opt com.docker.network.driver.mtu=1450 \
  tuned-net
```

- `enable_icc=false` blocks container-to-container traffic within the network.
- `enable_ip_masquerade=false` disables outbound NAT — traffic leaves with the container's
  own source IP, which requires routes on the upstream network.
- `driver.mtu` matters when the host sits behind a VPN or tunnel; see
  [Performance](#performance).

## Host and None Networks

```bash
# Share the host network stack entirely — no NAT, no port mapping
docker run -d --network host nginx

# No networking at all beyond loopback
docker run --rm --network none alpine ip addr
```

With `--network host` the container binds directly to host ports, so `-p` is ignored and
port conflicts with host services are real. It removes the NAT hop, which is worth measuring
for high-packet-rate workloads, but it also removes network isolation.

> [!IMPORTANT]
> `--network host` behaves differently on Docker Desktop for Mac and Windows, where
> containers run inside a Linux VM. "Host" there means the VM, not your workstation.

## Macvlan and Ipvlan

These drivers put containers directly onto the physical LAN, each with its own IP that other
machines can reach without port publishing. They are the right answer for appliances that
need to be addressable — DHCP servers, PXE, media servers advertising via mDNS — and for
migrating legacy services that assume a real network presence.

### Macvlan

Each container gets its own MAC address on the parent interface:

```bash
docker network create -d macvlan \
  --subnet 192.168.1.0/24 \
  --gateway 192.168.1.1 \
  --ip-range 192.168.1.192/27 \
  -o parent=eth0 \
  lan-net

docker run -d --name dns-server --network lan-net --ip 192.168.1.200 pihole/pihole
```

Restrict `--ip-range` to a block excluded from your DHCP scope so Docker and the DHCP server
do not hand out the same addresses.

> [!WARNING]
> **The host cannot reach its own macvlan containers by default.** Traffic from the parent
> interface to a macvlan child is blocked in the kernel. This surprises people setting up
> health checks or reverse proxies on the host.

The workaround is a macvlan shim on the host:

```bash
# Create a host-side macvlan interface in the same subnet
sudo ip link add macvlan-shim link eth0 type macvlan mode bridge
sudo ip addr add 192.168.1.253/32 dev macvlan-shim
sudo ip link set macvlan-shim up

# Route to the container range through the shim
sudo ip route add 192.168.1.192/27 dev macvlan-shim
```

This is not persistent across reboots — add it to a systemd unit or your network
configuration. See [Daemon Configuration](daemon.md) for the systemd pattern.

Other constraints worth knowing before committing to macvlan:

- Most **wireless** interfaces reject multiple MAC addresses, so macvlan generally does not
  work over Wi-Fi.
- Cloud provider networks (AWS, Azure) usually drop frames with unknown source MACs.
- Managed switches with port security may shut the port when extra MACs appear.
- The parent interface must be in **promiscuous mode**, which some virtualized environments
  disallow.

### Ipvlan

Ipvlan avoids the multiple-MAC problem: every container shares the parent interface's MAC
and is distinguished by IP alone.

```bash
# L2 mode — containers on the same subnet as the host
docker network create -d ipvlan \
  --subnet 192.168.1.0/24 \
  --gateway 192.168.1.1 \
  -o parent=eth0 \
  -o ipvlan_mode=l2 \
  ipvlan-net

# L3 mode — Docker routes between subnets; no broadcast, no gateway
docker network create -d ipvlan \
  --subnet 10.10.10.0/24 \
  -o parent=eth0 \
  -o ipvlan_mode=l3 \
  ipvlan-l3
```

Choose **ipvlan L2** when the switch or cloud fabric restricts MAC addresses. Choose
**ipvlan L3** when you want Docker to act as a router for container subnets — it scales well
but requires static routes on upstream equipment, since there is no ARP to discover the
container networks.

## Overlay Networks

Overlay networks span multiple hosts using VXLAN encapsulation, and require Swarm mode:

```bash
docker swarm init

# Attachable lets standalone containers join, not just services
docker network create -d overlay --attachable multi-host

# Encrypt the data plane (IPsec between nodes)
docker network create -d overlay --opt encrypted secure-overlay
```

See [Docker Swarm](swarm.md) for the full picture, including how service discovery and
routing mesh build on overlay networks.

## DNS and Service Discovery

### The Embedded Resolver

Containers on a user-defined network get an embedded DNS server at **127.0.0.11**:

```bash
docker run --rm --network mynet alpine cat /etc/resolv.conf
# nameserver 127.0.0.11
```

It resolves:

- Container names (`api`)
- Network aliases (`--network-alias`)
- Swarm service names
- Everything else — forwarded to the host's upstream resolvers

Containers on the **default** bridge get no such resolver; they receive the host's
`/etc/resolv.conf` directly and cannot resolve each other by name. This is the single most
common reason "my containers can't talk to each other by name" — the fix is to create a
user-defined network.

### Network Aliases

```bash
docker run -d --name db \
  --network mynet \
  --network-alias database \
  --network-alias postgres-primary \
  postgres:16
```

The container is reachable as `db`, `database`, or `postgres-primary`. When several
containers share one alias, the resolver returns all their addresses in rotating order — a
crude but effective round-robin load balance:

```bash
docker run -d --network mynet --network-alias web nginx
docker run -d --network mynet --network-alias web nginx
docker run --rm --network mynet alpine nslookup web
```

> [!NOTE]
> Round-robin DNS is not a health-aware load balancer. Clients cache DNS answers, and a
> stopped container's address may still be handed out briefly. Use a real proxy for
> production traffic distribution.

### Custom DNS Settings

```bash
docker run -d \
  --dns 1.1.1.1 --dns 9.9.9.9 \
  --dns-search internal.example.com \
  --dns-opt ndots:2 \
  --add-host legacy-app:192.168.1.50 \
  myapp:latest
```

`--add-host` writes an `/etc/hosts` entry, which takes effect before DNS is consulted. The
special value `host-gateway` resolves to the host itself, which is the supported way for a
container to reach a service running on the host:

```bash
docker run --rm --add-host host.docker.internal:host-gateway alpine \
  ping -c1 host.docker.internal
```

To change DNS for every container, set it on the daemon — see
[Daemon Configuration](daemon.md).

## Publishing Ports

### EXPOSE vs `-p`

These are frequently confused, and the distinction is simple:

- **`EXPOSE` in a Dockerfile is documentation.** It records which ports the image intends to
  serve on. It opens nothing, publishes nothing, and has no effect on connectivity.
- **`-p` / `--publish` actually publishes**, installing a DNAT rule that forwards a host
  port to the container.

```dockerfile
EXPOSE 8080          # metadata only
```

```bash
docker run -p 8080:8080 myapp    # this is what makes it reachable
```

`EXPOSE` has exactly one functional use: `-P` (capital P) publishes every exposed port to a
randomly chosen high host port.

```bash
docker run -d -P nginx
docker port <container>          # discover the assigned ports
```

Critically, **containers on the same user-defined network reach each other on any port
regardless of `EXPOSE` or `-p`**. Publishing is only about reaching a container from outside
the Docker network. A database that only serves other containers should never be published.

### Publishing Syntax

```bash
# hostPort:containerPort
docker run -p 8080:80 nginx

# Bind to a specific host interface — omit this and you bind 0.0.0.0
docker run -p 127.0.0.1:8080:80 nginx

# Random host port
docker run -p 80 nginx

# UDP, and both protocols
docker run -p 53:53/udp coredns
docker run -p 53:53/tcp -p 53:53/udp coredns

# A range
docker run -p 8000-8010:8000-8010 myapp

# Explicit long form
docker run --publish published=8080,target=80 nginx
```

> [!WARNING]
> `-p 8080:80` binds to **all** host interfaces, including public ones. Combined with the
> firewall behavior below, this is how databases end up exposed to the internet. Bind to
> `127.0.0.1` unless you genuinely intend the service to be publicly reachable.

## Firewall Interaction

### Why UFW and firewalld Appear to Be Ignored

Docker manipulates `iptables` directly. When you publish a port, Docker inserts a DNAT rule
in the `nat` table's `PREROUTING` chain and an ACCEPT rule in the `DOCKER` chain of the
`FORWARD` path.

Traffic destined for a container is **forwarded**, not delivered locally — so it traverses
`FORWARD`, never `INPUT`. UFW rules overwhelmingly target `INPUT`. The result is that a
published port stays reachable no matter what UFW says.

This is a genuine, long-standing source of accidental exposure. There are three sound
responses:

**1. Bind published ports to localhost** and put a host-level reverse proxy in front. The
simplest and most robust option:

```bash
docker run -d -p 127.0.0.1:5432:5432 postgres:16
```

**2. Use the `DOCKER-USER` chain.** Docker guarantees this chain is evaluated before its own
rules and never flushes it:

```bash
# Allow an internal management network, drop other external access to containers
sudo iptables -I DOCKER-USER -i eth0 -s 192.168.1.0/24 -j RETURN
sudo iptables -I DOCKER-USER -i eth0 -j DROP
```

Rules are order-sensitive and `-I` inserts at the top, so add the broad `DROP` first and the
narrower `RETURN` exceptions after, or use explicit rule numbers. Persist them with
`iptables-persistent` or an equivalent, since they are lost on reboot.

**3. Disable Docker's iptables management** and write every rule yourself, via
`"iptables": false` in `daemon.json`. This breaks container networking until you supply your
own NAT and forwarding rules, so only take this path deliberately — see
[Daemon Configuration](daemon.md).

### Docker's Chains

```bash
sudo iptables -t nat -L -n --line-numbers
sudo iptables -L DOCKER-USER -n
sudo iptables -L DOCKER-ISOLATION-STAGE-1 -n
```

| Chain | Purpose |
|-------|---------|
| `DOCKER` | Per-published-port ACCEPT and DNAT rules. Docker owns this — do not edit. |
| `DOCKER-USER` | Empty by default and reserved for your rules. Evaluated first. |
| `DOCKER-ISOLATION-STAGE-1/2` | Keeps user-defined bridge networks from reaching each other. |
| `POSTROUTING` (nat) | `MASQUERADE` for outbound container traffic. |

### nftables

Most modern distributions ship `nftables` with an `iptables-nft` compatibility shim, and
Docker's rules land in the `ip filter`/`ip nat` tables where they can be viewed natively:

```bash
sudo nft list ruleset | less
sudo nft list chain ip filter DOCKER-USER
```

The compatibility layer works well, but avoid mixing native `nft` rules and legacy
`iptables` commands for the same traffic — inspect with one toolchain consistently.

## IPv6

IPv6 is off by default. Enable it on the daemon:

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "fd00:dead:beef::/48",
  "experimental": false
}
```

```bash
sudo systemctl restart docker
docker run --rm alpine ip -6 addr show eth0
```

Use a **unique local address** (`fd00::/8`) range with NAT, or delegate a routed prefix from
your ISP or cloud provider if you want globally routable containers.

Per-network IPv6:

```bash
docker network create \
  --ipv6 \
  --subnet 2001:db8:1::/64 \
  --subnet 172.30.0.0/16 \
  dual-stack
```

> [!NOTE]
> IPv6 handling — in particular whether the daemon manages `ip6tables` rules and performs
> IPv6 NAT — has changed across Docker Engine releases, and older guides describing an
> `"ip6tables": true` experimental flag may not match your version. Check what your daemon
> actually does with `docker info` and verify published-port behavior on IPv6 before relying
> on it, because a port that is firewalled on IPv4 is not necessarily firewalled on IPv6.

## Troubleshooting

### Inspection

```bash
# Which networks exist, and what is on them
docker network ls
docker network inspect mynet

# A container's network settings
docker inspect -f '{{json .NetworkSettings.Networks}}' mycontainer | jq

# Published port mappings
docker port mycontainer
```

### Testing From Inside a Container

Minimal images lack network tools. Rather than installing them into the container, join its
network namespace from a throwaway container that has them:

```bash
docker run --rm -it --network container:mycontainer nicolaka/netshoot bash
# Now ip/ss/dig/tcpdump/curl all operate in the target's namespace
```

The same trick works for a whole network:

```bash
docker run --rm -it --network mynet nicolaka/netshoot dig api
```

### Common Failures

| Symptom | Likely cause |
|---------|--------------|
| Cannot resolve another container by name | Both are on the default bridge; create a user-defined network |
| Published port unreachable | Container not listening on `0.0.0.0` inside — check with `ss -tlnp` |
| Published port reachable despite firewall | Docker bypasses `INPUT`; see [Firewall Interaction](#firewall-interaction) |
| `port is already allocated` | Another container or host process holds it: `ss -tlnp \| grep :8080` |
| Connections hang, small requests fine | MTU mismatch; see [Performance](#performance) |
| Container cannot reach host service | Use `--add-host host.docker.internal:host-gateway` |
| Two networks cannot reach each other | Working as designed — `DOCKER-ISOLATION` rules; attach the container to both |

A service bound to `127.0.0.1` **inside** the container is unreachable from outside no matter
how it is published, because the published port forwards to the container's external
address. Bind to `0.0.0.0` in the application's configuration.

## Performance

### MTU

If the host is behind a VPN, an overlay, or a cloud fabric with a reduced MTU, containers
that inherit the default 1500 will send frames that cannot be fragmented, producing
connections that establish and then stall on the first large payload.

```bash
# Check the host's real MTU
ip link show eth0

# Match it on the container network
docker network create --opt com.docker.network.driver.mtu=1450 vpn-safe
```

Set `"mtu"` in `daemon.json` to change the default for all networks.

### Driver Choice

- `host` removes the NAT and bridge hop; measurably better for high connection churn or
  high packet rates, at the cost of isolation.
- `macvlan` and `ipvlan` also bypass NAT while keeping separate addresses.
- Bridge networking is adequate for the overwhelming majority of workloads. Measure before
  optimizing.

### Reducing Port Publishing

Every published port adds NAT rules and a userland proxy process (`docker-proxy`) unless the
daemon has `"userland-proxy": false`. Services that only serve other containers should
communicate over a shared user-defined network rather than through the host.

## Related Topics

- [Docker Storage](storage.md) — volumes, drivers, and persistence
- [Daemon Configuration](daemon.md) — `daemon.json`, DNS defaults, MTU, and iptables control
- [Docker Swarm](swarm.md) — overlay networks and the routing mesh
- [Working with Containers](containers.md) — container lifecycle and operations
- [Container Networking](../kubernetes/networking.md) — Kubernetes CNI, Services, and NetworkPolicy
- [Container Security](../containers/security/index.md) — network isolation as a security control
