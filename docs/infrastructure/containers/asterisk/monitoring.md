---
title: "Asterisk Monitoring and Troubleshooting"
description: "Operating Asterisk — the CLI, logging, CDR/CEL call records, and diagnosing SIP registration, one-way-audio, and NAT issues"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Monitoring and Troubleshooting

### The Asterisk CLI

The CLI is the primary operational tool. Attach to a running container:

```bash
docker exec -it asterisk asterisk -rvvv        # connect with verbose output
# or run a single command and exit:
docker exec asterisk asterisk -rx "core show channels"
```

Essential commands:

```text
; --- State ---
core show version
core show channels                 ; active calls
core show uptime

; --- PJSIP ---
pjsip show endpoints               ; all endpoints and Avail/Unavailable state
pjsip show endpoint 6001           ; one endpoint in detail
pjsip show aors                    ; registered contacts
pjsip show registrations           ; outbound trunk registrations
pjsip show contacts

; --- Dialplan ---
dialplan show internal             ; a context
dialplan show 6001@internal        ; one extension

; --- Live protocol tracing ---
pjsip set logger on                ; log all SIP messages to the console
pjsip set logger host 203.0.113.5  ; ...only for one host
rtp set debug on                   ; log RTP activity

; --- Reloads ---
pjsip reload
dialplan reload
```

> [!TIP]
> `pjsip set logger on` prints full SIP messages (REGISTER, INVITE, responses) to the console — the fastest way to see *why* a registration or call is rejected. Turn it off (`pjsip set logger off`) when done; it is verbose.

### Logging

`logger.conf` controls destinations and levels. In containers, also send key logs to stdout so `docker logs` captures them:

```ini
; logger.conf
[general]
dateformat = %F %T

[logfiles]
console  => notice,warning,error
messages => notice,warning,error
full     => notice,warning,error,verbose,dtmf
security => security               ; feed fail2ban (see Security)
```

Reload logging without dropping calls:

```text
asterisk*CLI> logger reload
asterisk*CLI> logger show channels
```

| Log | Contents |
| --- | -------- |
| `full` | Everything — the go-to log for debugging |
| `messages` | Notices, warnings, errors |
| `security` | Authentication/security events (for fail2ban) |
| `queue_log` | ACD queue events |

### Call Detail Records (CDR) and CEL

**CDR** records one summary row per call (who called whom, when, duration, disposition). **CEL** (Channel Event Logging) records granular per-channel events for detailed reconstruction.

```ini
; cdr.conf
[general]
enable = yes

; cdr_custom.conf — write a CSV
[mappings]
Master.csv => ${CSV_QUOTE(${CDR(clid)})},${CSV_QUOTE(${CDR(src)})},${CSV_QUOTE(${CDR(dst)})},${CSV_QUOTE(${CDR(duration)})},${CSV_QUOTE(${CDR(disposition)})}
```

```text
asterisk*CLI> cdr show status
```

CDR CSVs land under `/var/spool/asterisk/cdr-csv/`. For production reporting, use a database backend (`cdr_odbc`/`cdr_adaptive_odbc`) instead of CSV.

### Metrics

- The [prometheus module (`res_prometheus`)](https://docs.asterisk.org/) exposes channel, endpoint, and bridge metrics at an HTTP endpoint for Prometheus/Grafana.
- AMI events (see [Security](security.md)) can be consumed by monitoring integrations for real-time call/registration state.

### Troubleshooting Guide

| Symptom | Likely cause | What to check |
| ------- | ------------ | ------------- |
| **Phone won't register** | Wrong credentials, transport mismatch, ACL/firewall | `pjsip set logger on` and watch the REGISTER; confirm `auth` secret, transport (UDP/TLS), and that 5060/5061 is reachable |
| **One-way or no audio** | RTP blocked or NAT mis-advertised | Open the RTP range; set `external_media_address`/`local_net`; `direct_media=no`; `rtp_symmetric=yes` (see [Best Practices](best-practices.md)) |
| **Calls drop after ~30s** | SIP timer/NAT — ACK or re-INVITE not traversing NAT | Check NAT settings; `force_rport=yes`, `rewrite_contact=yes`; verify session timers |
| **Outbound calls rejected** | Trunk auth, caller ID, or number format | `pjsip show registrations`; confirm the provider's expected `from_user`/DID and dial string |
| **Inbound calls not routed** | DID doesn't match the dialplan; wrong context | `pjsip show identify`; confirm the trunk `context` and the exact DID the provider sends |
| **Fast busy / congestion** | No matching dialplan extension | `dialplan show <ctx>`; add/adjust the pattern; watch for `i` (invalid) hits |
| **Choppy audio** | Packet loss/jitter, codec/CPU | Check network; try `ulaw` (low CPU); inspect `rtp set debug on` and jitter |

```bash
# See what SIP is arriving on the wire (host networking)
sudo tcpdump -n -i any udp port 5060 -A

# Confirm the RTP range is listening
docker exec asterisk asterisk -rx "rtp show settings"

# Watch live channels during a test call
watch -n1 'docker exec asterisk asterisk -rx "core show channels concise"'
```

> [!IMPORTANT]
> Audio problems are almost always **RTP/NAT**, not SIP. If signaling works (calls connect and ring) but audio is missing or one-way, focus on the RTP port range and the public address Asterisk advertises — not on the SIP configuration.

## Navigation

[◄ Security](security.md) · [Asterisk Overview](index.md) · [Best Practices ►](best-practices.md)
