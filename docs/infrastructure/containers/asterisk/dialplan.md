---
title: "Asterisk Dialplan"
description: "Asterisk call routing with extensions.conf — contexts, extensions, priorities, applications, variables, and pattern matching"
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Dialplan

The **dialplan** in `extensions.conf` is the heart of Asterisk — it decides what happens to every call. When a call enters, Asterisk looks up the dialed number in a *context* and executes a numbered sequence of *applications*.

### Anatomy of a Dialplan Line

```ini
exten => 6001,1,Dial(PJSIP/6001,20)
;        │    │ └─ application (+ arguments) to run
;        │    └─── priority (execution order; 1 is first, "n" = next)
;        └──────── extension (the dialed number or pattern)
```

- **Context** — `[name]`, a namespace grouping extensions. Calls from an endpoint enter the context set on that endpoint (see [Configuration](configuration.md)).
- **Extension** — the matched number (`6001`), a named target (`s`, `i`, `t`), or a pattern (`_9NXXXXXX`).
- **Priority** — steps run in order; use `n` ("next") after the first so you can reorder without renumbering. Label a step with `n(label)` and jump to it with `Goto`.
- **Application** — the action: `Dial`, `Answer`, `Playback`, `Hangup`, `Voicemail`, etc.

### A Minimal Internal Dialplan

```ini
; extensions.conf

[globals]
RINGTIME = 20

[internal]
; Call another internal extension (6001–6099)
exten => _60XX,1,NoOp(Call from ${CALLERID(num)} to ${EXTEN})
 same => n,Dial(PJSIP/${EXTEN},${RINGTIME})
 same => n,Voicemail(${EXTEN}@default,u)   ; unavailable -> voicemail
 same => n,Hangup()

; Reach voicemail by dialing *98
exten => *98,1,Answer()
 same => n,VoiceMailMain(@default)
 same => n,Hangup()
```

`same => n,...` is shorthand that repeats the current extension, so you don't restate `exten => _60XX` on every line. `${EXTEN}` is the dialed number; `${CALLERID(num)}` is the caller's number.

### Special Extensions

Asterisk invokes these automatically in a context when conditions occur:

| Extension | Fires when |
| --------- | ---------- |
| `s` | A call enters a context with no specific number ("start") — common for inbound trunk calls |
| `i` | The caller dialed an **invalid** extension |
| `t` | The caller **timed out** without dialing |
| `h` | **Hangup** — runs cleanup after either party hangs up |
| `_X.` etc. | Pattern matches (see below) |

```ini
[inbound]
exten => s,1,Answer()
 same => n,Background(welcome-menu)   ; play a prompt, collect a digit
 same => n,WaitExten(10)
exten => 1,1,Dial(PJSIP/6001,20)      ; caller pressed 1 -> reception
exten => i,1,Playback(invalid)        ; invalid choice
 same => n,Goto(s,1)
exten => t,1,Playback(vm-goodbye)     ; timed out
 same => n,Hangup()
```

### Pattern Matching

Patterns start with `_` and match classes of numbers:

| Token | Matches |
| ----- | ------- |
| `X` | any digit 0–9 |
| `Z` | any digit 1–9 |
| `N` | any digit 2–9 |
| `[1-5]` | any digit in the set |
| `.` | one or more of any character (greedy — use carefully) |
| `!` | zero or more characters |

```ini
[outbound]
; North American 10-digit dialing: 9 to grab a line, then NXXNXXXXXX
exten => _9NXXNXXXXXX,1,NoOp(Outbound to ${EXTEN:1})
 same => n,Set(CALLERID(num)=+15555551234)      ; present a valid caller ID
 same => n,Dial(PJSIP/${EXTEN:1}@provider,60)   ; strip the leading 9 with ${EXTEN:1}
 same => n,Hangup()
```

> [!WARNING]
> Patterns using `.` such as `_.` or `_X.` can match far more than intended (including provider/service codes) and are a classic **toll-fraud** enabler. Match the specific number formats you allow, and never route untrusted (inbound trunk) contexts to outbound dialing. See [Security](security.md).

### Variables and Expressions

```ini
exten => 1234,1,Set(GREETING=Hello)                 ; channel variable
 same => n,Set(GLOBAL(COMPANY)=Acme)                ; global variable
 same => n,NoOp(${GREETING} from ${COMPANY})
 same => n,GotoIf($[${CALLERID(num)} = 6001]?vip:normal)   ; expression + branch
 same => n(vip),Playback(vip-welcome)
 same => n,Hangup()
 same => n(normal),Playback(welcome)
 same => n,Hangup()
```

- `${var}` reads a variable; `${EXTEN:1}` returns a substring (drop the first character).
- `$[ ... ]` evaluates an arithmetic/logical expression.
- `GotoIf($[cond]?a:b)` jumps to label `a` if true, else `b`.

### Common Applications

| Application | Purpose |
| ----------- | ------- |
| `Dial(tech/peer,timeout,options)` | Ring an endpoint/trunk and bridge the call |
| `Answer()` / `Hangup()` | Answer / end the call |
| `Playback(file)` / `Background(file)` | Play a prompt (Background also listens for digits) |
| `Voicemail(box@ctx,options)` / `VoiceMailMain()` | Leave / retrieve voicemail |
| `Queue(name)` | Place the caller in a call queue |
| `ConfBridge(room)` | Join a conference bridge |
| `Set()` / `NoOp()` | Set a variable / log a no-op line (debugging) |
| `Goto()` / `GotoIf()` | Jump within the dialplan |

### Testing the Dialplan

```text
asterisk*CLI> dialplan reload
asterisk*CLI> dialplan show internal
asterisk*CLI> dialplan show 6001@internal
```

> [!TIP]
> Sprinkle `NoOp()` lines with `${}` variables while building a dialplan and watch them with `asterisk -rvvv` — it's the simplest way to see exactly what values Asterisk has at each step.

## Navigation

[◄ Configuration](configuration.md) · [Asterisk Overview](index.md) · [Endpoints and Trunks ►](endpoints-trunks.md)
