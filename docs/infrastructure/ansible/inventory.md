---
title: Inventory
description: Defining managed hosts with static INI and YAML inventories, groups, group_vars/host_vars, dynamic inventory, and targeting patterns.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: concept
ms.service: ansible
keywords: ansible, inventory, groups, group_vars, host_vars, dynamic inventory, patterns, ansible-inventory
uid: docs.infrastructure.ansible.inventory
---

## Inventory

The inventory is Ansible's source of truth: the definitive list of which hosts exist, how they are grouped, and how Ansible connects to each one. Every playbook run and ad-hoc command resolves its target hosts against an inventory, so getting the inventory right is the foundation of everything else.

An inventory can be a single static file, a directory of static files, or a dynamic source that queries an external system (a cloud provider, a CMDB, or a container runtime) at run time. You select the inventory with the `-i` / `--inventory` option or by setting `inventory` under `[defaults]` in `ansible.cfg`.

> [!NOTE]
> Ansible ships a default inventory at `/etc/ansible/hosts`, but you should almost always keep the inventory inside your project directory and reference it explicitly with `-i`. This keeps the inventory versioned alongside the code that uses it.

### What an inventory is

At its core, the inventory answers two questions for every host: *does this host exist* and *how do I reach it*. Static inventories encode that answer in files you edit and commit to version control. Dynamic inventories generate the answer on demand from an authoritative external system so that ephemeral infrastructure (autoscaling groups, spot instances, short-lived containers) is always current.

Hosts belong to groups, and groups can contain other groups. Two groups always exist implicitly:

- `all` — every host in the inventory.
- `ungrouped` — every host that is not a member of any other group (besides `all`).

Groups are how you scope plays and variables to a meaningful subset of your fleet, such as `webservers`, `dbservers`, or `production`.

### Static inventory — INI format

The INI format is compact and convenient for small to medium inventories. Ungrouped hosts appear at the top of the file, groups are declared in `[brackets]`, and per-host connection parameters can follow the hostname on the same line.

```ini
# inventory/hosts.ini

# Ungrouped hosts
bastion.example.com

[webservers]
# Host ranges expand to web01..web05
web[01:05].example.com

[dbservers]
db01.example.com ansible_host=10.0.20.11
db02.example.com ansible_host=10.0.20.12

[loadbalancers]
lb01.example.com
lb02.example.com

# Variables applied to every host in a group
[webservers:vars]
ansible_user=deploy
http_port=8080

# A group made of other groups
[production:children]
webservers
dbservers
loadbalancers
```

Host ranges such as `web[01:05].example.com` expand to `web01` through `web05` (the zero padding is preserved). Alphabetic ranges like `db-[a:c]` are also supported.

> [!WARNING]
> INI group variables set under `[group:vars]` are convenient but do not scale. For anything beyond a handful of values, prefer `group_vars/` and `host_vars/` directories described below, which keep variables in structured YAML.

### Static inventory — YAML format

The YAML format expresses the same structure explicitly through the `hosts`, `children`, and `vars` keys nested under the special top-level `all` group. It is the preferred format for complex inventories because it represents nesting and data types (lists, dictionaries, booleans) natively.

```yaml
# inventory/hosts.yml
---
all:
  hosts:
    bastion.example.com:
  children:
    webservers:
      hosts:
        web01.example.com:
        web02.example.com:
        web03.example.com:
        web04.example.com:
        web05.example.com:
      vars:
        ansible_user: deploy
        http_port: 8080
    dbservers:
      hosts:
        db01.example.com:
          ansible_host: 10.0.20.11
        db02.example.com:
          ansible_host: 10.0.20.12
    loadbalancers:
      hosts:
        lb01.example.com:
        lb02.example.com:
    production:
      children:
        webservers:
        dbservers:
        loadbalancers:
```

> [!TIP]
> YAML inventories do not support the `web[01:05]` range shorthand directly, but you can achieve the same result with a dynamic `constructed` inventory or by generating the file. For static lists, spell out the hosts as shown above.

### Connection and behavioral parameters

Ansible controls how it connects to and executes on each host through a set of special variables, usually prefixed `ansible_`. Set them per host, per group, or in `group_vars`/`host_vars`.

| Parameter | Purpose |
| --- | --- |
| `ansible_host` | The actual address (IP or DNS name) to connect to when it differs from the inventory hostname. |
| `ansible_user` | The remote user Ansible logs in as. |
| `ansible_port` | The connection port (defaults to 22 for SSH). |
| `ansible_connection` | The connection plugin: `ssh` (default), `local`, `winrm`, `community.docker.docker`, or `community.general.psrp`. |
| `ansible_python_interpreter` | Path to the Python interpreter on the managed host, e.g. `/usr/bin/python3`. |
| `ansible_become` | Whether to escalate privileges (`true`/`false`); pair with `ansible_become_user` and `ansible_become_method`. |

> [!NOTE]
> `ansible_host` decouples the inventory *name* from the *address*. This lets you use friendly, stable inventory names (like `db01.example.com`) while connecting over a private IP or a bastion-forwarded address.

### Assigning variables — group_vars/ and host_vars/

The preferred place to define variables is in `group_vars/` and `host_vars/` directories rather than inline in the inventory file. Ansible automatically loads these based on file and directory names that match group or host names. They are searched relative to both the inventory file's location and the playbook's location.

```text
project/
├── ansible.cfg
├── site.yml
├── inventory/
│   └── hosts.yml
├── group_vars/
│   ├── all.yml              # variables for every host
│   ├── webservers.yml       # variables for the webservers group
│   └── dbservers/           # directory form: all *.yml files are merged
│       ├── tuning.yml
│       └── credentials.yml
└── host_vars/
    ├── db01.example.com.yml
    └── web01.example.com.yml
```

A single file such as `group_vars/webservers.yml` holds all variables for that group. The directory form (`group_vars/dbservers/`) lets you split variables across multiple files that are merged together — useful for separating, for example, tuning parameters from secrets you keep in an encrypted file.

```yaml
# group_vars/webservers.yml
---
http_port: 8080
worker_processes: 4
app_release: "2.4.1"
```

Because inventory variables sit low in Ansible's precedence order, values in `host_vars/` override those in `group_vars/`, which in turn override inline inventory vars. For the complete ordering, see [variables-and-facts.md](variables-and-facts.md).

> [!IMPORTANT]
> Keep `group_vars/all.yml` for genuinely global defaults only. Overusing it makes it hard to reason about where a value comes from when a host belongs to several groups.

### Multiple inventories and environments

Rather than one large inventory with environment-suffixed group names, give each environment its own inventory directory with its own hosts and its own `group_vars`. Select the environment at run time with `-i`.

```text
inventories/
├── production/
│   ├── hosts.yml
│   └── group_vars/
│       ├── all.yml
│       └── webservers.yml
└── staging/
    ├── hosts.yml
    └── group_vars/
        ├── all.yml
        └── webservers.yml
```

```bash
# Run against staging
ansible-playbook -i inventories/staging/ site.yml

# Run the same playbook against production
ansible-playbook -i inventories/production/ site.yml
```

Per-environment inventories keep variables that share a group name (like `webservers`) cleanly separated, prevent a staging value from ever leaking into production, and make it obvious from the `-i` argument exactly which fleet a command targets. A single monolithic inventory forces awkward naming (`prod_webservers`, `stage_webservers`) and invites mistakes.

### Dynamic inventory

Dynamic inventory generates host data at run time from an external system. Modern Ansible uses **inventory plugins** (configured via a small YAML file) rather than the legacy executable scripts. Plugins are cached, testable, and integrate with the rest of the plugin system, so prefer them for all new work.

Enable the plugins you need in `ansible.cfg`:

```ini
# ansible.cfg
[inventory]
enable_plugins = amazon.aws.aws_ec2, azure.azcollection.azure_rm, google.cloud.gcp_compute, constructed, ini, yaml
```

A plugin configuration file must end in a recognized suffix such as `_aws_ec2.yml` (or `.aws_ec2.yml`) and set `plugin:` to the plugin's FQCN:

```yaml
# inventory/prod_aws_ec2.yml
---
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
  - us-west-2
filters:
  tag:Environment: production
  instance-state-name: running
keyed_groups:
  # Build groups from tags, e.g. tag_Role_web
  - prefix: tag_Role
    key: tags.Role
hostnames:
  - private-ip-address
compose:
  ansible_host: private_ip_address
```

Point Ansible at the config file just like any other inventory: `ansible-playbook -i inventory/prod_aws_ec2.yml site.yml`. You can pass a whole directory to `-i` to combine static and dynamic sources.

The `constructed` plugin builds additional groups and variables from Jinja2 expressions over existing host data, letting you compose groups without touching the cloud queries. Other cloud providers are covered by `azure.azcollection.azure_rm` and `google.cloud.gcp_compute`, and the `community.docker.docker_containers` plugin discovers running containers.

```bash
# Visualize what a dynamic source resolves to
ansible-inventory -i inventory/prod_aws_ec2.yml --graph
```

### Targeting patterns

Playbooks (`hosts:`) and ad-hoc commands take a host pattern that selects a subset of the inventory. Patterns combine group names, host names, wildcards, and set operators.

| Pattern | Selects |
| --- | --- |
| `all` (or `*`) | Every host in the inventory. |
| `webservers` | All hosts in the `webservers` group. |
| `web01.example.com` | A single named host. |
| `web*` | All hosts whose name matches the wildcard. |
| `webservers:dbservers` | Union — hosts in either group. |
| `webservers:&production` | Intersection — hosts in `webservers` **and** `production`. |
| `webservers:!lb01.example.com` | Exclusion — `webservers` except `lb01`. |
| `webservers[0]` / `webservers[0:2]` | The first, or a slice, of a group's hosts. |

```bash
# Ad-hoc: ping every production webserver except one host
ansible 'webservers:&production:!web05.example.com' -m ansible.builtin.ping
```

The `--limit` (`-l`) flag further restricts an already-chosen play to a subset without editing the playbook — invaluable for a controlled, host-by-host rollout.

```bash
# Run site.yml but only against a single host this time
ansible-playbook -i inventories/production/ site.yml --limit web03.example.com
```

> [!TIP]
> Quote patterns that contain `&`, `!`, or `*` so the shell does not interpret them. Single quotes are the safest choice.

### Verifying inventory

Before running a playbook, confirm that Ansible parses your inventory the way you expect. The `ansible-inventory` command renders the fully resolved inventory, and `--list-hosts` shows exactly which hosts a pattern would match.

```bash
# Full JSON dump of hosts, groups, and resolved variables
ansible-inventory -i inventories/production/ --list

# Tree view of groups and their members
ansible-inventory -i inventories/production/ --graph

# Every variable resolved for one host
ansible-inventory -i inventories/production/ --host web01.example.com

# Which hosts does this pattern actually match?
ansible 'webservers:&production' -i inventories/production/ --list-hosts
```

> [!NOTE]
> `ansible-inventory --graph --vars` adds resolved variables to the tree view, which is the quickest way to spot a value coming from the wrong `group_vars` file.

## Related

- [Variables and Facts](variables-and-facts.md) — variable precedence, including where inventory, `group_vars`, and `host_vars` sit.
- [Playbooks](playbooks.md) — how the `hosts:` key consumes inventory patterns.
- [Installation](installation.md) — installing ansible-core and the collections that provide inventory plugins.
- [Best Practices](best-practices.md) — recommended directory layout for inventories and variables.

## References

- [How to build your inventory](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html)
- [Working with dynamic inventory](https://docs.ansible.com/ansible/latest/inventory_guide/intro_dynamic_inventory.html)
- [Patterns: targeting hosts and groups](https://docs.ansible.com/ansible/latest/inventory_guide/intro_patterns.html)
- [ansible-inventory command reference](https://docs.ansible.com/ansible/latest/cli/ansible-inventory.html)
