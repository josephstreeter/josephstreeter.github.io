---
title: "Asterisk Installation and Deployment"
description: "Deploying the Asterisk PBX with Docker — images, config volumes, and the SIP/RTP networking model"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Installation and Deployment

### Images

There is **no official Asterisk Docker image**. Options, in order of preference:

1. **Build from source** in your own image — full control over version and modules.
2. **A maintained community image** (for example [`mlan/asterisk`](https://hub.docker.com/r/mlan/asterisk) or [`andrius/asterisk`](https://hub.docker.com/r/andrius/asterisk)) — quick to start; audit what it bundles.
3. **A distro (FreePBX) image** if you want the web GUI.

A minimal build-from-source image on Debian:

```dockerfile
# Dockerfile
FROM debian:bookworm-slim

ARG ASTERISK_VERSION=20
RUN apt-get update && apt-get install -y --no-install-recommends \
        asterisk && \
    rm -rf /var/lib/apt/lists/*

# Config and data are provided via volumes at runtime
EXPOSE 5060/udp 5060/tcp 5061/tcp
EXPOSE 10000-10100/udp

# Run in the foreground as the asterisk user
CMD ["asterisk", "-f", "-U", "asterisk", "-G", "asterisk", "-vvvg"]
```

> [!NOTE]
> Distribution packages (as above) are convenient but may lag the latest Asterisk. For a specific version or extra modules (e.g. Opus, ODBC), build Asterisk from the [source tarball](https://downloads.asterisk.org/pub/telephony/asterisk/) in a multi-stage image.

### The Networking Problem (Read First)

Asterisk uses **two** separate flows, and both must reach the phones:

- **SIP signaling** — UDP/TCP **5060** (TLS **5061**). Sets up and tears down calls.
- **RTP media** — a **UDP port range** (default **10000–20000**) carrying the actual audio.

Publishing a 10,000-port UDP range through Docker's userland proxy is impractical and slow, and Docker NAT rewrites addresses in ways that break SIP/RTP. Two workable approaches:

| Approach | When to use | Trade-off |
| -------- | ----------- | --------- |
| **Host networking** (`network_mode: host`) | Most self-hosted PBX deployments | Simplest and most reliable for media; the container shares the host's network stack (Linux only) |
| **Bridge + narrow RTP range + NAT config** | When host networking isn't allowed | Must map the RTP range explicitly and set `external_media_address`/`external_signaling_address` so Asterisk advertises the correct public IP |

This guide uses **host networking**, which avoids double-NAT and is the pragmatic default for a containerized PBX.

### Docker Compose (Host Networking)

```yaml
# docker-compose.yml
services:
  asterisk:
    build: .
    # Alternatively: image: mlan/asterisk:latest
    container_name: asterisk
    network_mode: host          # SIP 5060/5061 + RTP range share the host stack
    volumes:
      - ./config:/etc/asterisk               # your configuration
      - asterisk-lib:/var/lib/asterisk       # voicemail, recordings, sounds
      - asterisk-spool:/var/spool/asterisk   # CDR, queues, voicemail spool
      - asterisk-log:/var/log/asterisk       # logs
    restart: unless-stopped

volumes:
  asterisk-lib:
  asterisk-spool:
  asterisk-log:
```

### Docker Compose (Bridge with Explicit Ports)

If host networking is unavailable, narrow the RTP range and publish it. Keep the range small (enough for your concurrent calls — each call uses ~2 ports):

```yaml
services:
  asterisk:
    build: .
    container_name: asterisk
    ports:
      - "5060:5060/udp"
      - "5060:5060/tcp"
      - "5061:5061/tcp"
      - "10000-10100:10000-10100/udp"   # ~50 concurrent calls
    volumes:
      - ./config:/etc/asterisk
      - asterisk-lib:/var/lib/asterisk
      - asterisk-spool:/var/spool/asterisk
    restart: unless-stopped

volumes:
  asterisk-lib:
  asterisk-spool:
```

Match `rtp.conf` to the published range:

```ini
; config/rtp.conf
[general]
rtpstart=10000
rtpend=10100
```

And tell PJSIP the public address to advertise (see [Configuration](configuration.md) and [Best Practices](best-practices.md) for NAT details):

```ini
; in the transport section of pjsip.conf
external_media_address=203.0.113.10
external_signaling_address=203.0.113.10
local_net=10.0.0.0/8
```

### First Start and Verification

```bash
# Build and start
docker compose up -d

# Watch it come up
docker logs -f asterisk

# Attach to the Asterisk CLI
docker exec -it asterisk asterisk -rvvv
```

At the CLI, confirm core status and that PJSIP loaded:

```text
asterisk*CLI> core show version
asterisk*CLI> pjsip show transports
asterisk*CLI> pjsip show endpoints
asterisk*CLI> module show like pjsip
```

### Directory Layout

| Path | Contents |
| ---- | -------- |
| `/etc/asterisk` | Configuration files (`asterisk.conf`, `pjsip.conf`, `extensions.conf`, …) |
| `/var/lib/asterisk` | Sounds, music-on-hold, firmware, AGI scripts |
| `/var/spool/asterisk` | Voicemail, call recordings, CDR CSV, outgoing call files |
| `/var/log/asterisk` | `full`, `messages`, and CDR/CEL logs |

Mount `/etc/asterisk` from a version-controlled directory so your configuration is reproducible; keep `/var/lib` and `/var/spool` on named volumes so voicemail and recordings survive container recreation.

## Navigation

[◄ Overview](index.md) · [Asterisk Overview](index.md) · [Configuration ►](configuration.md)
