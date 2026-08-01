---
title: "Terraform Solutions"
description: "End-to-end Terraform reference deployments for Azure and Proxmox, covering Active Directory, DNS, and Kubernetes infrastructure"
author: "Joseph Streeter"
tags: ["terraform", "solutions", "azure", "proxmox", "reference-architecture"]
category: "infrastructure"
difficulty: "advanced"
last_updated: "2026-08-01"
---

## Terraform Solutions

Complete, opinionated reference deployments rather than isolated snippets. Each page builds a
working environment end to end — provider configuration, networking, the resources
themselves, and the operational concerns that follow.

Use these as starting points to adapt, not as copy-paste templates: every one carries
assumptions about naming, addressing, and sizing that will need to match your environment.

## Azure

| Solution | Builds | Size |
|----------|--------|------|
| [Active Directory Forest](active-directory-forest-azure.md) | A production-ready AD forest on Azure — domain controllers, networking, and replication | 1,408 lines |
| [Private DNS](dns-azure-private.md) | Azure Private DNS zones, virtual network links, and record management | 1,309 lines |
| [Public DNS](dns-azure-public.md) | Azure Public DNS zones, delegation, and record management | 1,365 lines |

## Proxmox

| Solution | Builds | Size |
|----------|--------|------|
| [Kubernetes Cluster on Proxmox](kubernetes-cluster-proxmox.md) | VM infrastructure for a Kubernetes cluster — templates, cloud-init, control plane and worker provisioning | 5,013 lines |

> [!NOTE]
> The Proxmox guide is substantially longer than the others because it covers the full
> lifecycle from image template through cluster bootstrap. Work through it in stages rather
> than as a single sitting.

## Before You Start

Each solution assumes you are comfortable with the material in the main
[Terraform](../index.md) section — provider configuration, state management, and the module
patterns in [Patterns](../patterns.md). The Azure solutions additionally assume an existing
subscription and appropriate role assignments; the Proxmox solution assumes a working
[Proxmox](../../proxmox/index.md) host or cluster.

## Related Topics

- [Terraform](../index.md) — provider setup, state, and workflow
- [Terraform Patterns](../patterns.md) — module structure and reusable patterns
- [Proxmox](../../proxmox/index.md) — the virtualization platform behind the Kubernetes solution
- [Kubernetes](../../kubernetes/index.md) — what to do with the cluster once it exists
- [Ansible](../../ansible/index.md) — configuration management after provisioning
