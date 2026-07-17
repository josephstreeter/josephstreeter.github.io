---
title: Ansible
description: A comprehensive guide to Ansible - installation, inventory, playbooks, variables and facts, roles and collections, secrets management, and best practices.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: overview
ms.service: ansible
keywords: ansible, automation, configuration management, playbooks, roles, inventory, ansible vault, infrastructure as code
uid: docs.infrastructure.ansible.index
---

## Ansible

[Ansible](https://www.ansible.com/) is an open-source automation engine for configuration management, application deployment, and orchestration. It is **agentless** — it connects to managed nodes over SSH (or WinRM) and executes tasks described declaratively in YAML — so there is no software to install or maintain on the systems it manages.

This section is a complete, practical guide to Ansible: from installing the control node through writing playbooks, structuring reusable roles, managing secrets, and running it reliably in production.

> [!NOTE]
> The guide targets **ansible-core 2.16/2.17** conventions, including fully-qualified collection names (FQCN, e.g. `ansible.builtin.copy`) throughout. Examples use a repo-local project layout rather than the global `/etc/ansible` directory.

## Why Ansible

- **Agentless** — no agents or daemons on managed nodes; only SSH and Python are required.
- **Idempotent** — modules converge a system to a desired state, so runs can be repeated safely.
- **Declarative and readable** — automation is expressed in YAML that doubles as documentation.
- **Batteries included** — thousands of modules and a large collection ecosystem for OSes, clouds, network gear, and services.
- **Push-based** — you decide when automation runs; there is no central server the nodes poll.

## How it fits together

| Concept | What it is | Page |
| ------- | ---------- | ---- |
| **Control node** | The machine that runs Ansible and connects out to managed nodes | [Installation](installation.md) |
| **Inventory** | The list of managed hosts and how to reach and group them | [Inventory](inventory.md) |
| **Playbook** | An ordered set of plays mapping hosts to tasks | [Playbooks](playbooks.md) |
| **Module / Task** | A unit of work (invoked by FQCN) and its invocation in a play | [Playbooks](playbooks.md) |
| **Variables & Facts** | Data that parameterizes automation, plus gathered system facts | [Variables, Facts, and Templating](variables-and-facts.md) |
| **Role** | A reusable, shareable bundle of tasks, templates, and defaults | [Roles and Collections](roles-and-collections.md) |
| **Collection** | A distributable package of roles, modules, and plugins | [Roles and Collections](roles-and-collections.md) |
| **Vault** | Encryption for secrets kept alongside your code | [Vault and Secrets](vault-and-secrets.md) |

## In this section

1. **[Installation and Setup](installation.md)** — install Ansible on the control node, configure `ansible.cfg`, lay out a project, and prepare managed nodes.
2. **[Inventory](inventory.md)** — define hosts with static INI/YAML inventories, groups, `group_vars`/`host_vars`, dynamic inventory, and targeting patterns.
3. **[Playbooks and Tasks](playbooks.md)** — plays, tasks, handlers, conditionals, loops, blocks, error handling, and controlling execution.
4. **[Variables, Facts, and Templating](variables-and-facts.md)** — variable precedence, gathered and custom facts, magic variables, and Jinja2 templating.
5. **[Roles and Collections](roles-and-collections.md)** — structure reusable roles and distribute content with collections and Ansible Galaxy.
6. **[Vault and Secrets Management](vault-and-secrets.md)** — encrypt sensitive data with Ansible Vault and integrate external secret managers.
7. **[Best Practices](best-practices.md)** — project structure, idempotency, linting and testing, performance, CI/CD, and scaling with Automation Platform.

## Quick start

Install Ansible, define a host, and run an ad-hoc command — no playbook required:

```bash
# 1. Install (isolated) on the control node
pipx install --include-deps ansible

# 2. A minimal inventory
cat > inventory.ini <<'EOF'
[web]
web01.example.com
EOF

# 3. Verify connectivity (uses your SSH config / keys)
ansible web -i inventory.ini -m ansible.builtin.ping
```

Then capture the same intent as a repeatable **playbook**:

```yaml
---
- name: Install and start nginx
  hosts: web
  become: true
  tasks:
    - name: Install nginx
      ansible.builtin.package:
        name: nginx
        state: present

    - name: Ensure nginx is running and enabled
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
```

```bash
ansible-playbook -i inventory.ini site.yml --check   # dry run first
ansible-playbook -i inventory.ini site.yml           # apply
```

Continue with [Installation and Setup](installation.md) for a production-ready control node and project layout.

## Related

- [Infrastructure overview](../index.md) — where Ansible fits among the other infrastructure tooling.
- [Terraform](../terraform/index.md) — provisioning infrastructure that Ansible then configures (if present in your environment).
- [Docker](../containers/docker/index.md) — a common target and driver for Ansible automation.

## References

- [Ansible documentation](https://docs.ansible.com/ansible/latest/)
- [Getting started with Ansible](https://docs.ansible.com/ansible/latest/getting_started/index.html)
- [ansible-core](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html)
- [Ansible Galaxy](https://galaxy.ansible.com/)
