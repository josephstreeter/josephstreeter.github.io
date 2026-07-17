---
title: "Apache Load Balancing"
description: "Load balancing with Apache mod_proxy_balancer — balancing methods, sticky sessions, health checks, and the balancer manager"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Load Balancing

Apache balances traffic across multiple backend servers with `mod_proxy_balancer`, built on top of `mod_proxy`. A *balancer* is a named group of *members* (backends); Apache distributes requests among the members according to a load-balancing method.

### Enabling the Balancer Modules

```apache
LoadModule proxy_module            modules/mod_proxy.so
LoadModule proxy_http_module       modules/mod_proxy_http.so
LoadModule proxy_balancer_module   modules/mod_proxy_balancer.so
LoadModule slotmem_shm_module      modules/mod_slotmem_shm.so   # shared memory for balancer state

# Choose at least one load-balancing method module
LoadModule lbmethod_byrequests_module  modules/mod_lbmethod_byrequests.so
LoadModule lbmethod_bytraffic_module   modules/mod_lbmethod_bytraffic.so
LoadModule lbmethod_bybusyness_module  modules/mod_lbmethod_bybusyness.so
LoadModule lbmethod_heartbeat_module   modules/mod_lbmethod_heartbeat.so
```

> [!NOTE]
> `mod_slotmem_shm` is required — it stores shared balancer state (member status, request counts) so all Apache worker processes agree on the balancer's condition.

### Basic Load Balancer

Define a balancer with two members and proxy traffic to it:

```apache
# apache/httpd.conf
ProxyRequests Off
ProxyPreserveHost On

<Proxy "balancer://mycluster">
    BalancerMember "http://app1:80"
    BalancerMember "http://app2:80"
    Require all granted

    # Load-balancing method (see below)
    ProxySet lbmethod=byrequests
</Proxy>

ProxyPass        "/" "balancer://mycluster/"
ProxyPassReverse "/" "balancer://mycluster/"
```

### Load-Balancing Methods

Set the method with `ProxySet lbmethod=...` inside the `<Proxy balancer://...>` block:

| Method | Module | Behavior |
| ------ | ------ | -------- |
| `byrequests` | `mod_lbmethod_byrequests` | Distributes requests evenly by count (weighted round-robin). The default and simplest. |
| `bytraffic` | `mod_lbmethod_bytraffic` | Balances by bytes transferred — favors backends that have served less traffic. Good when response sizes vary widely. |
| `bybusyness` | `mod_lbmethod_bybusyness` | Sends each request to the member with the fewest active requests. Best when request durations vary. |
| `heartbeat` | `mod_lbmethod_heartbeat` | Distributes based on load reported by backends running `mod_heartmonitor`/`mod_heartbeat`. |

### Weighted Members

Give more capable backends a larger share with the `loadfactor` parameter (default `1`):

```apache
<Proxy "balancer://mycluster">
    BalancerMember "http://app1:80" loadfactor=3
    BalancerMember "http://app2:80" loadfactor=1
    ProxySet lbmethod=byrequests
</Proxy>
```

Here `app1` receives roughly three times the traffic of `app2`.

### Sticky Sessions (Session Affinity)

When a backend keeps per-user session state in memory, route each user consistently to the same member. Apache uses a cookie or URL parameter to "stick" a client to a route:

```apache
Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED

<Proxy "balancer://mycluster">
    BalancerMember "http://app1:80" route=1
    BalancerMember "http://app2:80" route=2
    ProxySet stickysession=ROUTEID
</Proxy>

ProxyPass        "/" "balancer://mycluster/"
ProxyPassReverse "/" "balancer://mycluster/"
```

Each member is tagged with a `route`; the `ROUTEID` cookie records which route served the client, and subsequent requests return to the same member. Prefer stateless backends (shared session store) where possible so any member can serve any request.

### Health Checks and Member States

Apache marks a member as failed after connection errors and retries it after a cooldown. Tune this per member:

```apache
<Proxy "balancer://mycluster">
    # retry: seconds to wait before retrying a failed member (default 60)
    # connectiontimeout / timeout: connection and response timeouts
    BalancerMember "http://app1:80" retry=30 connectiontimeout=5 timeout=30
    BalancerMember "http://app2:80" retry=30 connectiontimeout=5 timeout=30

    # A hot standby: only used when all non-standby members are down
    BalancerMember "http://app3:80" status=+H
</Proxy>
```

Apache 2.4 also supports **active** health checks with `mod_proxy_hcheck`, which probes members on a schedule instead of waiting for a live request to fail:

```apache
LoadModule proxy_hcheck_module modules/mod_proxy_hcheck.so

<Proxy "balancer://mycluster">
    BalancerMember "http://app1:80" hcmethod=GET hcuri=/health hcinterval=10 hcpasses=2 hcfails=3
    BalancerMember "http://app2:80" hcmethod=GET hcuri=/health hcinterval=10 hcpasses=2 hcfails=3
</Proxy>
```

| Parameter | Meaning |
| --------- | ------- |
| `hcmethod` | Health-check request method (`GET`, `HEAD`, `OPTIONS`, `TCP`) |
| `hcuri` | Path to request for the check (e.g. `/health`) |
| `hcinterval` | Seconds between checks |
| `hcpasses` / `hcfails` | Consecutive successes/failures before marking a member up/down |

Common member `status` flags: `+H` (hot standby), `+D` (disabled/drain), `+S` (stopped), `+E` (in error).

### Balancer Manager

`mod_status`'s companion, the **balancer-manager**, is a web UI to view member status and change load factors, drain, or disable members at runtime — without restarting Apache:

```apache
LoadModule status_module modules/mod_status.so

<Location "/balancer-manager">
    SetHandler balancer-manager
    Require ip 127.0.0.1 10.0.0.0/8
</Location>
```

> [!WARNING]
> The balancer-manager lets anyone who can reach it change how traffic is routed. Restrict it tightly with `Require ip`/authentication and never expose it to the public internet.

### Docker Compose Example

```yaml
# docker-compose.yml
services:
  app1:
    image: httpd:2.4
    volumes: [ "./app1:/usr/local/apache2/htdocs:ro" ]
    networks: [ web ]
  app2:
    image: httpd:2.4
    volumes: [ "./app2:/usr/local/apache2/htdocs:ro" ]
    networks: [ web ]
  lb:
    image: httpd:2.4
    container_name: apache-lb
    ports: [ "80:80" ]
    volumes: [ "./apache/httpd.conf:/usr/local/apache2/conf/httpd.conf:ro" ]
    depends_on: [ app1, app2 ]
    networks: [ web ]

networks:
  web:
    driver: bridge
```

```bash
docker compose up -d

# Repeated requests are distributed across app1 and app2
for i in $(seq 1 6); do curl -s http://localhost/; done
```

## Navigation

[◄ Reverse Proxy](reverse-proxy.md) · [Apache Overview](index.md) · [TLS / Let's Encrypt ►](tls.md)
