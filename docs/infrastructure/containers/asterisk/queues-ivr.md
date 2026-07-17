---
title: "Asterisk Queues and IVR"
description: "Building auto-attendant IVR menus and ACD call queues in Asterisk — Background/WaitExten/Read, time-based routing, queues.conf strategies, and agent management"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Queues and IVR

Two of the most common PBX features build directly on the [dialplan](dialplan.md): an **IVR** (Interactive Voice Response, or "auto-attendant") that greets callers and routes them by keypad input, and **queues** (ACD — Automatic Call Distribution) that hold callers until an agent is free. This page covers both.

## Interactive Voice Response (IVR)

An IVR plays a menu prompt, collects a DTMF digit, and jumps to the matching extension in a context. The building blocks are dialplan applications:

| Application | Role |
| ----------- | ---- |
| `Background(file)` | Plays a prompt **while listening** for a digit; a pressed digit interrupts playback and matches an extension |
| `WaitExten(sec)` | After the prompt finishes, wait this long for a digit |
| `Read(var,file,digits)` | Collect a fixed number of digits into a variable (e.g. an account number) |
| `Playback(file)` | Play a prompt **without** collecting input |
| `Goto()` / `GotoIf()` | Move between menus and options |

### A Basic Auto-Attendant

```ini
; extensions.conf
[ivr-main]
exten => s,1,Answer()
 same => n,Set(TIMEOUT(digit)=3)          ; inter-digit timeout
 same => n,Set(TIMEOUT(response)=10)      ; overall response timeout
 same => n(menu),Background(custom/main-menu)   ; "Press 1 for sales, 2 for support..."
 same => n,WaitExten(10)

; Menu options — each dialed digit matches its own extension
exten => 1,1,Goto(internal,6001,1)        ; 1 -> Sales
exten => 2,1,Goto(queue-support,s,1)      ; 2 -> Support queue
exten => 3,1,VoiceMailMain(@default)      ; 3 -> check voicemail
exten => 0,1,Dial(PJSIP/6000,20)          ; 0 -> operator
 same => n,Voicemail(6000@default,u)
 same => n,Hangup()

; Caller pressed an invalid key
exten => i,1,Playback(pbx-invalid)
 same => n,Goto(s,menu)

; Caller didn't press anything in time
exten => t,1,Playback(vm-goodbye)
 same => n,Hangup()
```

Callers reach this by routing an inbound DID (or an internal feature code) to `Goto(ivr-main,s,1)` — see [Endpoints and Trunks](endpoints-trunks.md).

### Nested / Sub-Menus

Give each submenu its own context and route back to the parent with `Goto`:

```ini
[ivr-support]
exten => s,1,Background(custom/support-menu)   ; "1 for billing, 2 for technical..."
 same => n,WaitExten(10)
exten => 1,1,Goto(queue-billing,s,1)
exten => 2,1,Goto(queue-tech,s,1)
exten => 9,1,Goto(ivr-main,s,1)                ; 9 -> back to main menu
exten => i,1,Playback(pbx-invalid)
 same => n,Goto(s,1)
exten => t,1,Goto(ivr-main,s,1)
```

### Collecting Input with Read

Use `Read` when you need several digits (an account or PIN), then act on the value:

```ini
[ivr-account]
exten => s,1,Answer()
 same => n,Read(ACCOUNT,custom/enter-account,6)   ; collect up to 6 digits
 same => n,GotoIf($["${ACCOUNT}" = ""]?s,1)        ; nothing entered -> retry
 same => n,NoOp(Caller entered account ${ACCOUNT})
 same => n,AGI(lookup-account.agi,${ACCOUNT})      ; hand off to a script, DB lookup, etc.
 same => n,Hangup()
```

### Time-Based Routing (Business Hours)

Route differently by time of day with `GotoIfTime` (`times,weekdays,monthdays,months`). Wildcards are `*`:

```ini
[inbound]
exten => s,1,NoOp(Inbound call at ${STRFTIME(${EPOCH},,%H:%M %A)})
 ; Mon–Fri 09:00–17:00 -> open menu
 same => n,GotoIfTime(09:00-17:00,mon-fri,*,*?ivr-main,s,1)
 ; Otherwise -> after-hours greeting
 same => n,Playback(custom/after-hours)
 same => n,Voicemail(6000@default,u)
 same => n,Hangup()

; Holidays override normal hours (place before the hours check)
exten => s,1,GotoIfTime(*,*,25,dec?closed,1)      ; Christmas Day
```

> [!TIP]
> Record custom prompts as 8 kHz, mono, signed-linear WAV (or GSM/ulaw) and place them under `/var/lib/asterisk/sounds/custom/`, referencing them without the extension (`custom/main-menu`). Keep menus short (3–5 options), state the option before the digit ("for sales, press 1"), and always handle `i` (invalid) and `t` (timeout).

## Call Queues (ACD)

A queue holds callers and distributes them to **members** (agents) according to a strategy. Queues are defined in `queues.conf` and entered from the dialplan with the `Queue()` application.

### queues.conf

```ini
; queues.conf
[general]
persistentmembers = yes        ; remember dynamic members across restarts
monitor-type = MixMonitor       ; enable call recording hooks

[support]
strategy = rrmemory            ; round-robin with memory (see table below)
timeout = 20                   ; seconds to ring a member before trying the next
retry = 5                      ; seconds between ring attempts
wrapuptime = 15                ; cooldown after a call before an agent gets another
musicclass = default           ; music-on-hold class while waiting
maxlen = 0                     ; 0 = unlimited callers waiting
ringinuse = no                 ; don't ring agents already on a call
joinempty = no                 ; don't let callers join if no members are available
leavewhenempty = yes           ; eject waiting callers if all members leave

; Announcements to waiting callers
announce-frequency = 30        ; re-announce every 30s
announce-holdtime = yes        ; "estimated hold time is..."
announce-position = yes        ; "you are caller number..."
periodic-announce = custom/thanks-for-holding

; Static members (always in the queue)
member => PJSIP/6001
member => PJSIP/6002
```

### Distribution Strategies

Set with `strategy =` in the queue:

| Strategy | Behavior |
| -------- | -------- |
| `ringall` | Ring **all** available members at once; first to answer wins |
| `leastrecent` | Ring the member who least recently took a call |
| `fewestcalls` | Ring the member who has completed the fewest calls |
| `random` | Ring a random available member |
| `rrmemory` | Round-robin, remembering where it left off (even distribution) |
| `rrordered` | Round-robin in the exact `member` order listed |
| `linear` | Always try members in listed order, from the top (priority hunt) |
| `wrandom` | Random, weighted by each member's `penalty` |

### Entering a Queue from the Dialplan

```ini
[queue-support]
exten => s,1,Answer()
 same => n,Playback(custom/all-agents-busy)
 same => n,Queue(support,tT,,,300)     ; join "support"; 300s max wait
 same => n,Playback(custom/still-busy-voicemail)
 same => n,Voicemail(6000@default,u)   ; timed out in queue -> voicemail
 same => n,Hangup()
```

`Queue(queuename,options,URL,announceoverride,timeout)` — common options:

| Option | Effect |
| ------ | ------ |
| `t` / `T` | Allow the **called** / **calling** party to transfer |
| `h` / `H` | Allow either party to hang up with a key |
| `c` | Continue in the dialplan even if the queue was empty |
| `n` | No retries — try members once then leave the queue |

When `Queue()` returns (caller was answered elsewhere, timed out, or hung up), execution continues at the next priority — use that to send timed-out callers to voicemail.

### Static vs Dynamic Members

- **Static** members (`member =>` in `queues.conf`) are always part of the queue.
- **Dynamic** members log in and out at runtime — the basis of "agent login". Manage them from the dialplan:

```ini
[agent-features]
; *51 — log this phone into the support queue
exten => *51,1,AddQueueMember(support,PJSIP/${CALLERID(num)})
 same => n,Playback(agent-loginok)
 same => n,Hangup()

; *52 — log out
exten => *52,1,RemoveQueueMember(support,PJSIP/${CALLERID(num)})
 same => n,Playback(agent-loggedoff)
 same => n,Hangup()

; *53 / *54 — pause / unpause (e.g. on a break; stays a member but isn't rung)
exten => *53,1,PauseQueueMember(support,PJSIP/${CALLERID(num)})
 same => n,Playback(vm-goodbye)
 same => n,Hangup()
exten => *54,1,UnpauseQueueMember(support,PJSIP/${CALLERID(num)})
 same => n,Hangup()
```

> [!NOTE]
> The old `AgentLogin`/`chan_agent` mechanism is deprecated. Use **dynamic queue members** (`AddQueueMember`/`RemoveQueueMember`) with `persistentmembers = yes` so logins survive restarts. Penalties (`member => PJSIP/6001,1`) create tiers — lower-penalty members are tried first.

### Monitoring Queues

```text
asterisk*CLI> queue show                 ; all queues, callers, and members
asterisk*CLI> queue show support         ; one queue in detail
asterisk*CLI> queue add member PJSIP/6003 to support
asterisk*CLI> queue remove member PJSIP/6003 from support
asterisk*CLI> queue pause member PJSIP/6001 queue support reason lunch
```

Queue activity is written to the **`queue_log`** (`/var/log/asterisk/queue_log`) — join, connect, complete, abandon, and agent events — which drives reporting/wallboard tools. See [Monitoring](monitoring.md) for logging setup.

### Queue Best Practices

- Set `wrapuptime` so agents get a breather between calls; set `ringinuse = no` so busy agents aren't rung.
- Announce position and hold time (`announce-position`, `announce-holdtime`) and offer an exit (voicemail or callback) so callers aren't trapped.
- Give the `Queue()` call a sensible `timeout` and route timed-out callers onward — never leave a bare `Queue()` with no fallback.
- Prefer `rrmemory` for even distribution, or `linear`/penalties for tiered/priority routing.
- Enable `persistentmembers` so dynamic agent logins survive an Asterisk restart.

## Navigation

[◄ Endpoints and Trunks](endpoints-trunks.md) · [Asterisk Overview](index.md) · [Security ►](security.md)
