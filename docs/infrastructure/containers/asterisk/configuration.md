---
title: "Asterisk Configuration"
description: "Asterisk core configuration files and PJSIP setup — transports, endpoints, auth, and AORs"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Configuration

Asterisk is configured through flat files in `/etc/asterisk`. Each file uses an INI-like syntax of `[sections]` and `key = value` (or `key => value` in the dialplan). Reload changes without a restart from the CLI.

### Core Configuration Files

| File | Purpose |
| ---- | ------- |
| `asterisk.conf` | Global paths and runtime options |
| `modules.conf` | Which modules load at startup |
| `pjsip.conf` | SIP transports, endpoints, trunks (the modern SIP driver) |
| `extensions.conf` | The **dialplan** — call-routing logic (see [Dialplan](dialplan.md)) |
| `rtp.conf` | RTP media port range |
| `logger.conf` | Log destinations and verbosity |
| `cdr.conf` / `cel.conf` | Call Detail Records / Channel Event Logging |
| `manager.conf` | AMI (Asterisk Manager Interface) — see [Security](security.md) |
| `http.conf` / `ari.conf` | Built-in HTTP server and ARI REST API |

### Config File Syntax

```ini
[section-name]
type = endpoint
; a comment starts with a semicolon
key = value

[template](!)          ; (!) marks a template
context = internal
disallow = all
allow = ulaw

[6001](template)       ; inherit from "template"
auth = 6001
aors = 6001
```

Templates (`(!)`) and inheritance (`(template)`) keep large PJSIP configs DRY — define common options once and inherit them.

### asterisk.conf and modules.conf

`asterisk.conf` rarely needs changes in a container; the defaults match the image's paths. In `modules.conf`, prefer autoloading and only explicitly `noload` drivers you don't want:

```ini
; modules.conf
[modules]
autoload = yes

; Do not load the deprecated/removed SIP driver
noload = chan_sip.so
; Example: skip a driver you don't use
noload = chan_dahdi.so
```

### PJSIP Configuration (`pjsip.conf`)

PJSIP splits a SIP entity into several cooperating section *types*. The four you use constantly:

| Section type | Role |
| ------------ | ---- |
| `transport` | A listening socket — protocol (UDP/TCP/TLS/WS) and bind address |
| `endpoint` | The SIP entity's behavior — codecs, context, media settings |
| `auth` | Credentials (username/password) for authenticating the endpoint |
| `aor` | "Address of Record" — where the endpoint is reachable; holds registered contacts |

#### Transports

Define one transport per protocol you accept. Set NAT/public-address options here for internet-facing deployments:

```ini
; pjsip.conf

[transport-udp]
type = transport
protocol = udp
bind = 0.0.0.0:5060
; For NAT — advertise the public IP so media/signaling return correctly
external_media_address = 203.0.113.10
external_signaling_address = 203.0.113.10
local_net = 10.0.0.0/8
local_net = 192.168.0.0/16

[transport-tls]
type = transport
protocol = tls
bind = 0.0.0.0:5061
cert_file = /etc/asterisk/keys/asterisk.crt
priv_key_file = /etc/asterisk/keys/asterisk.key
method = tlsv1_2
```

#### An Internal Extension (Phone)

A user phone is an `endpoint` + `auth` + `aor`, conventionally all sharing the extension number. Using a template avoids repeating options for every phone:

```ini
; A reusable template for internal phones
[endpoint-internal](!)
type = endpoint
context = internal            ; dialplan context inbound calls from this phone enter
disallow = all
allow = ulaw
allow = alaw
allow = opus
direct_media = no             ; keep media flowing through Asterisk (needed behind NAT)
rtp_symmetric = yes
force_rport = yes
rewrite_contact = yes

[aor-internal](!)
type = aor
max_contacts = 1              ; one registration per phone
remove_existing = yes

; --- Extension 6001 ---
[6001](endpoint-internal)
auth = 6001
aors = 6001

[6001]
type = auth
auth_type = userpass
username = 6001
password = ChangeMe_Str0ng!    ; use a long random secret (see Security)

[6001](aor-internal)
```

| Endpoint option | Why it matters |
| --------------- | -------------- |
| `context` | The dialplan context calls from this phone enter — the basis of call-routing isolation |
| `disallow=all` + `allow=` | Codec negotiation; list only codecs you want, in preference order |
| `direct_media=no` | Relays media through Asterisk instead of phone-to-phone — required behind NAT and for recording |
| `rtp_symmetric`, `force_rport`, `rewrite_contact` | NAT-traversal helpers that make Asterisk reply to the address/port packets actually came from |
| `max_contacts` (AOR) | How many simultaneous registrations (devices) an extension allows |

### Applying Configuration Changes

Reload from the CLI instead of restarting — this keeps active calls up:

```text
asterisk*CLI> pjsip reload            ; reload pjsip.conf
asterisk*CLI> dialplan reload         ; reload extensions.conf
asterisk*CLI> module reload res_pjsip.so
asterisk*CLI> core reload             ; reload most configuration
```

From outside the container:

```bash
docker exec asterisk asterisk -rx "pjsip reload"
docker exec asterisk asterisk -rx "dialplan reload"
```

> [!TIP]
> Validate a phone came online with `pjsip show endpoint 6001` and `pjsip show aor 6001` (shows current contacts). `pjsip show endpoints` lists all endpoints with their state (`Avail`/`Unavailable`).

## Navigation

[◄ Installation and Deployment](installation.md) · [Asterisk Overview](index.md) · [Dialplan ►](dialplan.md)
