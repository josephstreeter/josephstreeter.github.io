---
title: "Identity Compromise Response"
description: >-
  Runbook for investigating and responding to suspected or confirmed identity
  compromise in the SOC
author: "Joseph Streeter"
ms.date: "2026-05-19"
ms.topic: "how-to"
---

## Identity Compromise Response

This runbook covers response steps for suspected or confirmed compromised user
identities in Microsoft Defender.

## Initial Triage

- Confirm risk level, privilege level, and affected user role
- Review recent sign-ins, geographic anomalies, and MFA outcomes
- Check for associated mailbox, endpoint, or privilege alerts

## Investigation Steps

- Review sign-in history and failed-to-success chains
- Validate current and recent group membership or role assignments
- Check for mailbox rule changes, unusual email activity, and session reuse
- Identify any related endpoints or cloud resources used by the account

## Containment Actions

- Revoke active sessions
- Require password reset and validate MFA posture
- Escalate privileged account cases for lead approval when needed

## Recovery Validation

- Confirm the account no longer shows risky or abusive activity
- Confirm required groups and roles are in approved state
- Monitor for recurrence during the defined watch window

## Evidence to Capture

- User principal name and object ID
- Source IPs and locations
- Group or role changes
- Session revocation and reset timestamps
