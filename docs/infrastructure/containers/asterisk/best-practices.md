---
title: "Asterisk Best Practices"
description: "Production Asterisk — NAT and RTP handling, codec selection, high availability, backups, and container operations"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: conceptual
ms.service: infrastructure
---

## Best Practices

### NAT and RTP (The Number-One Issue)

Most Asterisk problems in containers are NAT/RTP, not SIP. Get these right up front:

- **Prefer host networking** for the container so RTP isn't double-NATed (see [Installation](installation.md)).
- **Advertise the correct public address** on each transport:

  ```ini
  ; pjsip.conf transport
  external_media_address = 203.0.113.10
  external_signaling_address = 203.0.113.10
  local_net = 10.0.0.0/8
  local_net = 192.168.0.0/16
  ```

- **Keep media through Asterisk** with `direct_media = no` — required behind NAT and for call recording/monitoring.
- **Use the NAT helpers** on endpoints: `rtp_symmetric = yes`, `force_rport = yes`, `rewrite_contact = yes`.
- **Open the RTP range** on every firewall in the path, and keep it only as large as you need (~2 UDP ports per concurrent call):

  ```ini
  ; rtp.conf
  [general]
  rtpstart = 10000
  rtpend   = 10100      ; ~50 concurrent calls
  ```

### Codec Selection

List only the codecs you want, in preference order, on each endpoint (`disallow = all` then `allow = ...`):

| Codec | Bandwidth | Notes |
| ----- | --------- | ----- |
| `ulaw` / `alaw` (G.711) | ~64 kbps | Uncompressed, low CPU, excellent quality on a LAN/good WAN. `ulaw` in North America, `alaw` in Europe. Safe default. |
| `opus` | ~6–64 kbps (variable) | Best quality-per-bit, resilient to loss; higher CPU; ideal for internet/WebRTC. Needs the Opus module built in. |
| `g722` | ~64 kbps | HD wideband audio at G.711-like bandwidth. |
| `gsm` | ~13 kbps | Very low bandwidth, lower quality; legacy. |

- **Match codecs end to end** — if the phone, Asterisk, and trunk share a codec, no transcoding occurs (lower CPU, no quality loss).
- **Avoid unnecessary transcoding** — it burns CPU and adds latency. Prefer passing through a common codec.
- For internet trunks with limited bandwidth, prefer `opus`; on a clean LAN, `ulaw` keeps CPU low.

### Reliability and High Availability

- **Persist state on volumes** — voicemail (`/var/spool/asterisk`), sounds/recordings (`/var/lib/asterisk`), and config (`/etc/asterisk`) must survive container recreation.
- **Version-control `/etc/asterisk`** so the entire PBX config is reproducible and reviewable.
- **Active/standby** rather than naive scaling — Asterisk holds live call state in memory, so you cannot simply run two identical instances behind a round-robin. Use a floating IP / keepalived with a shared or replicated config, and let the provider fail calls over to the standby.
- **Provider failover** — configure multiple trunk registrations or a secondary provider and dialplan fallbacks (`Dial(...)` then try an alternate on failure).
- **Health checks** — probe SIP OPTIONS (many providers/monitors do) to detect a dead PBX; alert on `pjsip show registrations` going offline.

### Backups

Back up regularly and test restores:

```bash
# Configuration (small, version this too)
docker exec asterisk tar czf - /etc/asterisk > asterisk-config-$(date +%F).tgz

# Voicemail and recordings (can be large)
docker run --rm -v asterisk-spool:/data -v "$PWD":/backup alpine \
  tar czf /backup/asterisk-spool-$(date +%F).tgz -C /data .
```

Include in backups: `/etc/asterisk`, voicemail/recordings under `/var/spool/asterisk`, custom sounds under `/var/lib/asterisk`, and any external CDR database.

### Upgrades

- **Track your version's security releases** and apply them — telephony is actively attacked.
- Prefer an **LTS** release (e.g. Asterisk 20) for production stability; upgrade within the LTS line for fixes.
- **Test config against the new version** in a staging container first — module options and defaults change across major versions (notably the removal of `chan_sip` in Asterisk 21).
- Rebuild the image to pick up a new Asterisk version deliberately; pin the version rather than tracking `latest`.

### Performance and Sizing

- **Disable unused modules** in `modules.conf` (`noload`) to reduce attack surface and memory.
- **Right-size for concurrent calls**, not registrations — CPU load tracks active/transcoded calls. A modern core handles many G.711 calls but far fewer heavily-transcoded Opus calls.
- **Watch CPU during transcoding** — if load is high, align codecs to eliminate transcoding.
- **Keep the RTP range and worker resources** sized together; set container `--cpus`/`--memory` limits and monitor with [mod_status-style metrics](monitoring.md).

### Operational Checklist

- [ ] Config in version control; `/etc/asterisk` bind-mounted
- [ ] Voicemail/recordings/CDR on persistent volumes, backed up and restore-tested
- [ ] NAT/RTP correct: public address advertised, RTP range open, `direct_media=no`
- [ ] Codecs aligned end-to-end to avoid transcoding
- [ ] Security controls in place (see [Security](security.md))
- [ ] Monitoring/alerts on registrations and channel counts
- [ ] Standby/failover plan for the PBX and the trunk
- [ ] Running a supported (ideally LTS) Asterisk version, patched

## Navigation

[◄ Monitoring and Troubleshooting](monitoring.md) · [Asterisk Overview](index.md)
