---
title: "Asterisk Security"
description: "Securing Asterisk against toll fraud — strong auth, ACLs, TLS/SRTP encryption, fail2ban, and locking down AMI/ARI"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Security

A PBX is a high-value target: a compromised system can be used for **toll fraud** (racking up expensive international/premium calls), eavesdropping, and denial of service. Security is not optional — apply these controls before exposing Asterisk to any untrusted network.

> [!IMPORTANT]
> The single most important rule: **do not put SIP on the public internet unless you have to.** Prefer a VPN, an SBC (Session Border Controller), or IP allow-lists. If you must expose it, layer every control below.

### Toll-Fraud Prevention Checklist

- **Strong, unique secrets** on every endpoint and trunk `auth` (long random strings, never the extension number or a dictionary word).
- **Context isolation** — inbound/trunk contexts must not reach outbound-dialing extensions (see [Endpoints and Trunks](endpoints-trunks.md)).
- **Reject unknown callers** — `allow_guest = no` in `pjsip.conf` globals and never route the default/guest context to a trunk.
- **Restrict outbound patterns** — allow only the specific number formats you use; avoid catch-all `.` patterns that can match premium/international prefixes.
- **Block or explicitly gate international dialing** unless the business needs it; consider per-extension outbound permissions.
- **Set a spending/rate alarm** with your provider (many ITSPs offer daily caps and anomaly alerts).

### Global PJSIP Hardening

```ini
; pjsip.conf
[global]
type = global
; Do not accept unauthenticated ("guest") calls
allow_guest = no
; Send a 401 for unknown endpoints so attackers can't tell valid users apart
; (default behavior in modern PJSIP; keep endpoints uniform)
```

### Access Control Lists (ACLs)

Restrict which source IPs may reach an endpoint. Define an ACL and reference it, or set `match`/`deny`/`permit` per endpoint:

```ini
; acl.conf — named ACL
[office-only]
deny = 0.0.0.0/0.0.0.0
permit = 203.0.113.0/24
permit = 10.0.0.0/8
```

```ini
; pjsip.conf — apply the ACL to an endpoint's matching
[6001]
type = endpoint
acl = office-only          ; signaling ACL
; media-level restriction
rtp_engine = asterisk
```

For provider trunks, use an `identify` with a specific `match` (the provider's IPs) so only they are recognized as the trunk.

### Encryption: TLS Signaling + SRTP Media

Encrypt both the SIP signaling (TLS) and the audio (SRTP). Signaling on TLS alone still leaves audio in the clear, so enable both.

```ini
; pjsip.conf
[transport-tls]
type = transport
protocol = tls
bind = 0.0.0.0:5061
cert_file = /etc/asterisk/keys/asterisk.crt
priv_key_file = /etc/asterisk/keys/asterisk.key
method = tlsv1_2

[6001]
type = endpoint
transport = transport-tls
media_encryption = sdes        ; SRTP (or "dtls" for DTLS-SRTP, e.g. WebRTC)
media_encryption_optimistic = no   ; require encryption; don't fall back to plain RTP
```

> [!TIP]
> Use a publicly trusted certificate for the TLS transport so phones validate it without warnings — obtain one with Let's Encrypt (see the [ACME / Certbot guide](../../../security/certificates/acme/certbot.md)) and point `cert_file`/`priv_key_file` at the issued `fullchain.pem`/`privkey.pem`. Reload PJSIP after each renewal.

### Fail2ban (Brute-Force Protection)

Attackers probe SIP with registration/INVITE floods to guess credentials. `fail2ban` watches the Asterisk security log and bans offending IPs at the firewall.

Enable Asterisk's dedicated security log so fail2ban has clean events to parse:

```ini
; logger.conf
[logfiles]
security => security
```

A fail2ban jail (host-side; the log must be accessible to fail2ban — bind-mount `/var/log/asterisk`):

```ini
# /etc/fail2ban/jail.d/asterisk.conf
[asterisk]
enabled  = true
filter   = asterisk
logpath  = /var/log/asterisk/security
maxretry = 5
findtime = 600
bantime  = 86400
action   = iptables-allports[name=asterisk, protocol=all]
```

> [!NOTE]
> With Docker **host networking**, fail2ban on the host can ban attackers directly. With bridge networking, bans must be applied where traffic ingresses (the host/NAT), and container-internal IPs may obscure the real source — another reason host networking is common for PBX deployments.

### Securing AMI and ARI

The **Asterisk Manager Interface** (AMI, TCP 5038) and **ARI** (REST over the built-in HTTP server) grant deep control — full compromise if exposed.

```ini
; manager.conf — AMI
[general]
enabled = yes
bindaddr = 127.0.0.1          ; localhost only; never 0.0.0.0 on an untrusted host
port = 5038

[admin]
secret = a-long-random-secret
deny = 0.0.0.0/0.0.0.0
permit = 127.0.0.1/255.255.255.255
read = system,call,log,verbose
write = system,call,command   ; grant only what the integration needs
```

```ini
; http.conf — the HTTP server ARI rides on
[general]
enabled = yes
bindaddr = 127.0.0.1
; For remote ARI, terminate TLS (tlsenable=yes) and put it behind a reverse proxy
```

```ini
; ari.conf
[general]
enabled = yes
[my-app]
type = user
password = a-long-random-secret
```

- Bind AMI/ARI/HTTP to **localhost** and reach them via a reverse proxy or SSH tunnel, not directly.
- Give each AMI/ARI account the **minimum** read/write classes it needs.
- Put ARI behind TLS and authentication if it must be remote.

### Security Checklist

- [ ] SIP not directly public (VPN / SBC / IP allow-list), or fully hardened if it is
- [ ] Strong random secrets on every `auth`; no default or numeric passwords
- [ ] `allow_guest = no`; inbound contexts cannot dial out
- [ ] Outbound dialplan restricted to needed number formats; international gated
- [ ] TLS transport + SRTP (`media_encryption`) enabled
- [ ] fail2ban watching the Asterisk security log
- [ ] AMI/ARI/HTTP bound to localhost with least-privilege accounts
- [ ] Provider spending caps/alerts configured
- [ ] Asterisk kept patched (track your version's security releases)

## Navigation

[◄ Queues and IVR](queues-ivr.md) · [Asterisk Overview](index.md) · [Monitoring and Troubleshooting ►](monitoring.md)
