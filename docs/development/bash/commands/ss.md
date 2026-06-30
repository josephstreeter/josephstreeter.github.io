---
title: ss Command
description: Comprehensive reference for the ss command in Bash, including socket inspection, filtering, and troubleshooting patterns.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 06/30/2026
ms.topic: reference
ms.service: development
---

The `ss` command displays socket statistics and network connection details.
It is a modern replacement for many `netstat` use cases and is useful for diagnosing listening ports, active sessions, and transport-level state.

## Overview

Use `ss` when you need to:

- See which ports are listening
- Inspect active TCP/UDP connections
- Troubleshoot connection states (ESTABLISHED, TIME-WAIT, etc.)
- Correlate sockets with owning processes
- Filter socket views by protocol, state, and address

## Syntax

```bash
ss [options] [filter]
```

Common forms:

```bash
# Show all sockets
ss -a

# Show listening TCP sockets with process info
ss -ltnp

# Show active TCP connections
ss -tn
```

## Common Options

| Option | Purpose | Example |
| --- | --- | --- |
| `-a` | Show all sockets (listening and non-listening) | `ss -a` |
| `-l` | Show listening sockets only | `ss -l` |
| `-t` | TCP sockets only | `ss -t` |
| `-u` | UDP sockets only | `ss -u` |
| `-n` | Do not resolve service/host names | `ss -tn` |
| `-p` | Show process using socket | `ss -ltnp` |
| `-e` | Extended socket information | `ss -te` |
| `-m` | Show socket memory usage | `ss -tm` |
| `-s` | Summary statistics | `ss -s` |
| `-4` | IPv4 sockets only | `ss -4ltn` |
| `-6` | IPv6 sockets only | `ss -6ltn` |
| `-H` | Omit header line | `ss -Htn` |

## Useful Filters

`ss` supports filter expressions after options.

Examples:

```bash
# Sockets using destination port 443
ss -tn 'dport = :443'
```

```bash
# Listening sockets on local port 8080
ss -ltn 'sport = :8080'
```

```bash
# Established TCP sessions only
ss -tn state established
```

Common state filters:

- `state listening`
- `state established`
- `state time-wait`
- `state close-wait`

## Examples

```bash
# List listening TCP ports numerically
ss -ltn
```

```bash
# Show listening sockets with processes (requires privileges for full detail)
sudo ss -ltnp
```

```bash
# Show all UDP listeners
ss -lun
```

```bash
# Show connections to remote HTTPS endpoints
ss -tn 'dport = :443'
```

```bash
# Show summary counts by protocol/state
ss -s
```

```bash
# Inspect sockets for a specific local service port
ss -ltnp 'sport = :5432'
```

## Troubleshooting Workflow

Check whether service is listening:

```bash
ss -ltnp 'sport = :8080'
```

Check if clients are connecting:

```bash
ss -tn 'dport = :8080'
```

Inspect problematic states:

```bash
ss -tn state time-wait
ss -tn state close-wait
```

## Safe Usage Guidelines

1. Use `-n` to avoid DNS/service-name resolution delays.
2. Use `sudo` only when process mapping (`-p`) detail is needed.
3. Combine protocol and state filters to reduce noise.
4. Capture baseline snapshots before and after configuration changes.

## Troubleshooting

### Process names are missing in output

Cause: Insufficient privileges for process association.

Fix:

```bash
sudo ss -ltnp
```

### Output is hard to read due to name resolution

Cause: Host/service names are being resolved.

Fix:

```bash
ss -tn
```

### Port appears open but service is unreachable

Possible causes:

- Service bound to localhost only
- Firewall/network policy blocking traffic
- Application-level failures after accept

Next checks:

- Inspect local bind address in `ss -ltnp`
- Verify firewall rules and service logs

## Notes

`ss` is part of the `iproute2` tooling family on Linux.
For scripting, use stable flags (`-n`, protocol selectors, and state filters) to keep output predictable.

For command details and implementation-specific behavior, run:

```bash
man ss
ss --help
```

## Related Commands

- [ps](ps.md)
- [pgrep](pgrep.md)
- [pkill](pkill.md)
- [systemctl](systemctl.md)
- [journalctl](journalctl.md)
