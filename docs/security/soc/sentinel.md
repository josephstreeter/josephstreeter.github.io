---
title: "Microsoft Sentinel in the SOC"
description: >-
   How Microsoft Sentinel supports SIEM operations, automation, and
   cross-source investigations in the SOC
author: "Joseph Streeter"
ms.date: "2026-05-19"
ms.topic: "conceptual"
---

## Microsoft Sentinel in the SOC

Microsoft Sentinel extends the SOC beyond product-specific detections by
providing SIEM-scale collection, analytics, automation, and case management.
In this environment, Sentinel complements Microsoft Defender by correlating
security data across additional sources and supporting standardized response
workflows.

## Purpose and Scope

The purpose of this page is to define how Sentinel is used operationally by the
SOC and how it complements Defender-centric investigation workflows.

### In Scope

- Cross-source analytics and incident correlation
- Log retention and query-driven investigation workflows
- Automation, enrichment, and notification playbooks
- Centralized incident handling for multi-source cases
- Reporting views for operational and leadership audiences

### Out of Scope

- Non-security analytics use cases
- General Azure platform administration outside SOC workflows
- Application monitoring unrelated to threat detection or incident handling

## Sentinel Role in the SOC Stack

Sentinel provides capabilities that are broader than a single control plane or
security product.

Key roles include:

- Aggregating security data across Microsoft and non-Microsoft sources
- Running analytics that span identity, endpoint, mail, cloud, and network
  evidence
- Enabling hunting and correlation across longer time windows
- Orchestrating response actions through playbooks and integrations

## Data Sources and Connectors

Sentinel is most effective when the SOC clearly documents which connectors are
enabled and what operational value each one provides.

Typical connector categories include:

- Microsoft Defender and Microsoft 365 sources
- Entra ID sign-in and audit data
- Azure activity and platform diagnostics
- Firewall, proxy, or network security logs
- Third-party SaaS and endpoint tools where applicable

Each connector should have an owner, onboarding status, validation date, and
expected use case for investigations.

## Analytics and Incident Correlation

Analytics rules in Sentinel should be used to identify patterns that are hard
to see from a single product view.

Good Sentinel analytics candidates include:

- Multi-stage activity spanning identity, endpoint, and email artifacts
- Cross-user or cross-device correlation over longer time windows
- Log patterns from sources that do not produce native Defender incidents
- Custom detections based on organizational risk patterns

Incident correlation should help analysts decide whether multiple alerts belong
to the same case or represent separate issues.

## Hunting and Investigation

Sentinel should support hypothesis-driven hunting and deeper pivot analysis.

Analysts should use Sentinel when they need:

- Broad workspace searches across multiple log sources
- Longer retention than the product portal provides
- Ad hoc KQL correlation that joins data from separate systems
- Timeline reconstruction across unrelated connectors

Hunts should be documented, repeatable, and promoted into analytics when they
become operationally valuable.

## Automation and Playbooks

Automation in Sentinel should standardize enrichment and response workflows.

Common playbook uses include:

- Creating tickets or cases in downstream systems
- Notifying responders and stakeholders for high-severity incidents
- Pulling enrichment from threat intelligence or directory sources
- Executing approval-aware containment steps

The SOC should define which workflows are safe to run automatically and which
must remain human-approved.

## Analyst Workflow Expectations

Analysts should generally use Defender XDR for product-specific incident triage
and Sentinel for broader correlation, hunting, and automation-backed cases.

Practical workflow guidance:

1. Start in Defender when the signal originates from Defender-native incidents.
2. Pivot to Sentinel when investigation requires broader log coverage or
   multi-source joins.
3. Use Sentinel playbooks and enrichment when the case benefits from workflow
   automation.
4. Record whether the authoritative case record is managed in Defender,
   Sentinel, or another incident system.

## Metrics and Reporting

Sentinel reporting should help the SOC understand ingestion quality,
investigation value, and automation effectiveness.

Useful operational measures include:

- Analytics rule volume and fidelity
- Connector health and data freshness
- Hunt success rate and promotion into analytics
- Playbook execution success and failure rate
- Case enrichment quality and correlation depth

## Relationship to Defender

Defender and Sentinel should be documented as complementary, not competing,
platforms.

- Defender is the primary XDR and product-response workspace
- Sentinel is the broader SIEM and orchestration layer
- Both should share common severity, evidence, and escalation expectations

## Related Pages

- [SOC Home](index.md)
- [SOC Analyst Playbook](soc_analyst.md)
- [Kusto Cheatsheet](kusto_cheatsheet.md)
- [Microsoft Defender](ms_defender.md)
