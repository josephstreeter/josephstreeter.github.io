---
title: "Threat Hunting Tools and References"
description: "Platforms, open-source tooling, frameworks, and further reading for threat hunting"
tags: ["threat-hunting", "tools", "references", "sigma", "security"]
category: "security"
difficulty: "advanced"
last_updated: "2026-07-11"
author: "Joseph Streeter"
---

## Tools and references

Hunting does not require a single product; it requires access to telemetry and a way to query it. The categories below cover the tooling that most programs rely on.

## Platforms

| Category | Examples | Role in hunting |
| -------- | -------- | --------------- |
| SIEM / log analytics | Microsoft Sentinel, Splunk, Elastic Security | Central store and query engine for correlated telemetry |
| EDR / XDR | Microsoft Defender for Endpoint, CrowdStrike Falcon, SentinelOne | Rich endpoint telemetry and response actions |
| Data lake / big-data | Azure Data Explorer, Databricks | Long-retention, high-volume analytics |
| DFIR collection | Velociraptor, GRR, Kansa | On-demand, at-scale endpoint collection for a hunt |

## Query and analytics tooling

- **[KQL](../../infrastructure/kql/index.md)** - the query language used throughout this section, for Microsoft Sentinel and Defender Advanced Hunting.
- **Jupyter notebooks** - combine queries, statistics, and visualization for model-assisted and repeatable hunts; often paired with Python libraries such as MSTICPy.
- **Sigma** - a generic, vendor-neutral signature format for describing detections. Sigma rules can be converted to KQL, SPL, and other query languages, making hunts portable across platforms.

## Frameworks and knowledge bases

- **[MITRE ATT&CK](https://attack.mitre.org/)** - the knowledge base of adversary tactics and techniques ([hunting with ATT&CK](mitre-attack.md)).
- **[ATT&CK Navigator](https://mitre-attack.github.io/attack-navigator/)** - annotate the matrix to build coverage layers.
- **PEAK** - the *Prepare, Execute, and Act with Knowledge* hunting framework ([methodology](methodology.md#peak)).
- **TaHiTI** - *Targeted Hunting integrating Threat Intelligence* ([methodology](methodology.md#tahiti)).
- **The Pyramid of Pain** - David Bianco's model for indicator durability ([why it matters](mitre-attack.md#complementary-models)).

## Open-source telemetry sources

- **Sysmon** - detailed Windows process, network, and file telemetry that greatly enriches endpoint hunting.
- **Zeek** - network-security monitoring that produces rich, structured connection and protocol logs.
- **osquery** - query your endpoints' state as if it were a database.

## Detection rule repositories

- **Sigma HQ rules** - a large community collection of detections in Sigma format.
- **Microsoft Sentinel GitHub** - hunting queries and analytics rules maintained by Microsoft and the community.
- **MITRE Cyber Analytics Repository (CAR)** - analytics mapped to ATT&CK techniques.

## Further reading

- [MITRE ATT&CK](https://attack.mitre.org/) - adversary tactics and techniques
- [The ThreatHunting Project](https://www.threathunting.net/) - community hunts and resources
- [Sigma rule format](https://github.com/SigmaHQ/sigma) - portable detection signatures
- [MSTICPy](https://msticpy.readthedocs.io/) - Python toolkit for security investigation and hunting
- [Kusto Query Language (KQL)](../../infrastructure/kql/index.md) - the query language used in this section's examples

## Section contents

- [Overview](index.md)
- [Methodology and frameworks](methodology.md)
- [Data sources and telemetry](data-sources.md)
- [Hunting with MITRE ATT&CK](mitre-attack.md)
- [Analytic techniques](techniques.md)
- [Example hunts](example-hunts.md)
