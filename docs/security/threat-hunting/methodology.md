---
title: "Threat Hunting Methodology and Frameworks"
description: "Hypothesis-driven hunting, hunt types, and structured frameworks including the Sqrrl hunt loop, PEAK, and TaHiTI"
tags: ["threat-hunting", "methodology", "peak", "tahiti", "hypothesis", "security"]
category: "security"
difficulty: "advanced"
last_updated: "2026-07-11"
author: "Joseph Streeter"
---

## Methodology and frameworks

Effective hunting is disciplined, not random. A repeatable methodology ensures hunts are scoped, documented, and produce lasting value rather than one-off findings.

## Hypothesis-driven hunting

A hunt begins with a **hypothesis**: a specific, testable statement about adversary activity that could plausibly exist in your environment. A good hypothesis is:

- **Specific** - it names a behavior, technique, or data source, not just "look for bad stuff."
- **Testable** - the available data can prove or disprove it.
- **Grounded** - it is motivated by threat intelligence, a known technique, a recent change, or an anomaly.

| Weak hypothesis | Strong hypothesis |
| --------------- | ----------------- |
| "There may be malware on our endpoints." | "An adversary is using `rundll32.exe` to execute code from an unusual path, visible in process-creation logs over the last 30 days." |
| "Someone might be exfiltrating data." | "A compromised account is staging data in a cloud storage app and downloading it from a new country, visible in sign-in and cloud app logs." |

Where hypotheses come from:

- **Threat intelligence** - a report describes a technique used by an actor relevant to your industry.
- **The ATT&CK framework** - pick a technique your telemetry can see and hunt for it (see [Hunting with MITRE ATT&CK](mitre-attack.md)).
- **Situational awareness** - a new application, a merger, a newly exposed service, or a recent vulnerability.
- **Anomalies** - something in the environment looks statistically unusual and warrants explanation.

## Types of hunts

| Hunt type | Starting point | Example |
| --------- | -------------- | ------- |
| Intelligence-driven | A threat report or IOC set | Hunt for the infrastructure and TTPs described in a new APT report |
| Hypothesis-driven | An analyst's testable idea | "Attackers are clearing event logs to cover tracks" |
| Entity / situational | A high-value asset or identity | Deep-dive on all activity around a domain controller or an executive's account |
| Baseline / anomaly | Statistical deviation from normal | Investigate hosts making DNS requests far above the fleet norm |

## Structured hunting frameworks

Several published frameworks formalize the hunting process. You do not need to adopt one wholesale, but they provide useful vocabulary and structure.

### The Sqrrl hunt loop

The four-stage loop introduced on the [overview page](index.md#the-hunt-loop): create a hypothesis, investigate via tools and techniques, uncover new patterns and TTPs, then inform and enrich automated detections. It is the simplest model and a good default.

### PEAK

The **PEAK** framework (*Prepare, Execute, and Act with Knowledge*) is a modern, three-stage model that emphasizes documentation and knowledge capture, and it recognizes three hunt types:

- **Prepare** - define the topic, form the hypothesis, gather the data and context.
- **Execute** - run the hunt: gather and analyze the data, and follow the evidence.
- **Act with Knowledge** - document findings, create detections, and communicate results.

PEAK explicitly names three hunt styles: **hypothesis-driven**, **baseline** (understanding normal to reveal abnormal), and **model-assisted** (using machine learning or statistics to surface candidates).

### TaHiTI

**TaHiTI** (*Targeted Hunting integrating Threat Intelligence*) structures hunting into three phases - initiate, hunt, and finalize - and tightly couples each hunt to threat intelligence. It maintains a backlog of investigation abstracts, so hypotheses are triaged and prioritized rather than run ad hoc.

## Documenting a hunt

Documentation is what turns a hunt from a fishing trip into a repeatable asset. At a minimum, record:

- **Hypothesis** - what you set out to test.
- **Scope** - data sources, time range, and systems in scope.
- **Queries and steps** - the exact queries run, so the hunt is reproducible.
- **Findings** - what you found (including "nothing," which is still a valuable result).
- **Outcome** - detections created, tickets opened, telemetry gaps identified.

> [!TIP]
> Treat "we found nothing" as a first-class outcome. A well-scoped hunt that disproves its hypothesis still increases assurance and often reveals visibility gaps worth fixing.

## Measuring success

Hunt programs are not measured only by the number of adversaries caught - a mature program may catch very few, because its detections keep improving. More durable measures include:

- Number of new detections and analytics created.
- Telemetry and visibility gaps identified and closed.
- Reduction in mean time to detect over successive hunts.
- Coverage of the ATT&CK matrix that has been actively hunted.

## Next steps

- Understand the [data sources](data-sources.md) that hunts depend on.
- Learn to [structure hunts with MITRE ATT&CK](mitre-attack.md).
- Apply the [analytic techniques](techniques.md) used during the investigate phase.
