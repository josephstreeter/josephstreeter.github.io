---
title: "Hunting with MITRE ATT&CK"
description: "Using the MITRE ATT&CK knowledge base to structure, prioritize, and scope threat hunts"
tags: ["threat-hunting", "mitre-attack", "ttp", "detection", "security"]
category: "security"
difficulty: "advanced"
last_updated: "2026-07-11"
author: "Joseph Streeter"
---

## Hunting with MITRE ATT&CK

[MITRE ATT&CK](https://attack.mitre.org/) is a globally accessible knowledge base of adversary tactics and techniques based on real-world observations. It gives hunters a shared vocabulary for describing *how* adversaries operate, and a structured map for deciding *what* to hunt.

## Tactics, techniques, and procedures

ATT&CK is organized as a hierarchy that mirrors the common "TTP" shorthand:

- **Tactics** - the adversary's *goal*, the "why" (for example, *Persistence* or *Exfiltration*). These form the columns of the ATT&CK matrix.
- **Techniques** (and sub-techniques) - *how* the goal is achieved (for example, *T1053 Scheduled Task/Job*). These are the individual cells.
- **Procedures** - the specific, observed implementation an actor uses to carry out a technique.

The enterprise matrix is arranged as tactics running roughly in attack order:

| Tactic | Adversary goal |
| ------ | -------------- |
| Reconnaissance | Gather information to plan the operation |
| Resource Development | Establish infrastructure and capabilities |
| Initial Access | Get a foothold in the environment |
| Execution | Run malicious code |
| Persistence | Maintain access across restarts and credential changes |
| Privilege Escalation | Gain higher-level permissions |
| Defense Evasion | Avoid detection |
| Credential Access | Steal account names and passwords |
| Discovery | Learn about the environment |
| Lateral Movement | Move through the environment |
| Collection | Gather data of interest |
| Command and Control | Communicate with compromised systems |
| Exfiltration | Steal data |
| Impact | Manipulate, interrupt, or destroy systems and data |

## Why ATT&CK is useful for hunting

- **A hypothesis backlog.** Each technique is a ready-made, testable hypothesis: "is technique X happening in my environment?"
- **A common language.** Findings map to a shared taxonomy that everyone - hunters, detection engineers, and IR - understands.
- **Coverage measurement.** You can track which techniques you have hunted and detected, and where the gaps are.
- **Prioritization.** You can focus on the techniques most relevant to the actors that target your industry.

## Turning a technique into a hunt

A repeatable pattern for ATT&CK-driven hunting:

1. **Select a technique** relevant to your threat model (for example *T1059.001 - PowerShell*).
2. **Identify the data source** that would reveal it (process-creation logs with command lines).
3. **Confirm you collect it** and that the key fields are populated (see [Data sources](data-sources.md)).
4. **Form the hypothesis** - "an adversary is using encoded PowerShell to execute code."
5. **Write the query** to surface candidate activity (see [Example hunts](example-hunts.md)).
6. **Analyze and refine** - separate benign administration from suspicious use.
7. **Operationalize** - convert a reliable pattern into an automated detection.

## Prioritizing techniques

You cannot hunt the entire matrix at once. Prioritize using:

- **Threat intelligence** - which techniques do the actors targeting your sector actually use? Resources such as the ATT&CK groups pages and industry ISACs help.
- **Data availability** - favor techniques your telemetry can actually see; a hunt you cannot support with data is wasted effort.
- **Impact** - weight techniques that would be most damaging in your environment.
- **Detection gaps** - target techniques you have no existing automated coverage for.

## ATT&CK Navigator and coverage mapping

The [ATT&CK Navigator](https://mitre-attack.github.io/attack-navigator/) is a free tool for annotating the matrix. Hunters commonly use it to build **coverage layers**:

- A layer showing which techniques have automated detections.
- A layer showing which techniques have been actively hunted.
- A layer showing the techniques used by a specific adversary group.

Overlaying these layers reveals exactly where to focus: high-impact, actively-used techniques with neither detection nor recent hunting coverage.

> [!TIP]
> Do not mistake matrix coverage for security. A colored cell means you have *some* visibility or detection for a technique - not that you would catch every variant. Treat the map as a planning aid, not a scorecard.

## Complementary models

ATT&CK describes behavior once an adversary is active. Two other models are useful alongside it:

- **The Cyber Kill Chain** (Lockheed Martin) - a higher-level, seven-stage view of an intrusion, useful for communicating the overall narrative.
- **The Pyramid of Pain** (David Bianco) - ranks indicator types by how much they cost the adversary to change. Hunting for **TTPs** (the apex) is far more durable than hunting for hashes or IPs, which attackers rotate cheaply.

## Next steps

- Map the prioritized techniques to your [data sources](data-sources.md).
- Apply [analytic techniques](techniques.md) to hunt the selected techniques.
- Work through the [example hunts](example-hunts.md), which are annotated with their ATT&CK techniques.
