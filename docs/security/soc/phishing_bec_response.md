---
title: "Phishing and Business Email Compromise Response"
description: >-
  Runbook for phishing and business email compromise investigations in the SOC
author: "Joseph Streeter"
ms.date: "2026-05-19"
ms.topic: "how-to"
---

## Phishing and Business Email Compromise Response

This runbook covers phishing and BEC investigations using Microsoft Defender
for Office 365 and related SOC workflows.

## Initial Triage

- Identify sender, subject pattern, and recipient scope
- Determine whether mail was delivered, blocked, or remediated
- Confirm whether a user account appears compromised or spoofed

## Investigation Steps

- Review message headers, URLs, attachments, and network message IDs
- Check recipient spread and repeat targeting patterns
- Review mailbox rules, forwarding, and delegate changes
- Determine whether the message is part of a broader campaign

## Containment Actions

- Remediate malicious messages from affected mailboxes
- Block or restrict malicious senders, URLs, or attachments as appropriate
- Escalate broad campaigns or executive-targeted BEC attempts immediately

## Recovery Validation

- Confirm message remediation completed successfully
- Confirm persistence mechanisms such as inbox rules are removed
- Confirm targeted users received follow-up guidance when required

## Evidence to Capture

- Network message IDs
- Sender and recipient list
- URLs, attachments, and remediation actions
- Case notes on campaign scope and impact
