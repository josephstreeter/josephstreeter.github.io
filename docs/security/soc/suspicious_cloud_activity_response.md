---
title: "Suspicious Cloud Activity Response"
description: >-
    Runbook for responding to suspicious SaaS and Azure cloud activity in the
    SOC
author: "Joseph Streeter"
ms.date: "2026-05-19"
ms.topic: "how-to"
---

## Suspicious Cloud Activity Response

This runbook covers response to suspicious SaaS or Azure cloud activity
surfaced through Microsoft Defender.

## Initial Triage

- Identify affected application, resource, and account
- Confirm whether the activity involves configuration change, access anomaly,
  or data movement
- Determine the sensitivity and business importance of the workload

## Investigation Steps

- Review session context, source location, and access pattern
- Check recent resource changes, privilege paths, and related alerts
- Identify whether the behavior aligns with expected admin or user activity
- Correlate with identity and endpoint evidence where relevant

## Containment Actions

- Restrict access or session activity when unauthorized use is likely
- Escalate critical cloud workload changes for platform owner coordination
- Preserve key configuration and audit evidence before major changes

## Recovery Validation

- Confirm resource configuration is restored to approved state
- Confirm unauthorized access paths are removed
- Confirm monitoring is in place for recurrence or residual abuse

## Evidence to Capture

- Resource identifiers and workload names
- Session details and source context
- Configuration changes and timestamps
- Approvals for containment or rollback
