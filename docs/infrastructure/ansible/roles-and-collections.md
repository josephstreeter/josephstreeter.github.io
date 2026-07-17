---
title: Roles and Collections
description: Structuring reusable automation with Ansible roles, and distributing content with collections and Ansible Galaxy.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: concept
ms.service: ansible
keywords: ansible, roles, collections, ansible-galaxy, requirements.yml, FQCN, reusable
uid: docs.infrastructure.ansible.roles-and-collections
---

## Roles and Collections

As playbooks grow, copying the same tasks, handlers, and templates between plays becomes unmanageable. Ansible solves this with two layers of reuse: **roles**, which package related automation into a self-contained, shareable unit, and **collections**, which bundle roles, modules, and plugins for distribution through Ansible Galaxy or a private Automation Hub.

This page assumes familiarity with [playbooks.md](playbooks.md) and [variables-and-facts.md](variables-and-facts.md). If you are new to Ansible, start at [index.md](index.md) and [installation.md](installation.md).

### Why Roles

A role groups everything a single unit of automation needs — tasks, handlers, templates, static files, default and overriding variables, and metadata — into a predictable directory layout. Instead of pasting the same twenty tasks into every play that configures a web server, you write them once as a `webserver` role and call it by name.

Roles give you:

- **DRY playbooks.** Plays shrink to a list of roles and the variables that customize them.
- **Encapsulation.** A role's internals (which template it renders, which handler restarts a service) stay hidden behind its name.
- **Shareability.** A well-structured role can be published to Galaxy or vendored into other projects unchanged.
- **Testability.** Roles have a conventional `tests/` directory and pair naturally with Molecule.

> [!TIP]
> Aim for one responsibility per role. A role named `nginx` should install and configure Nginx — not also provision the database. Compose behavior by listing several small roles in a play rather than building one monolithic role.

### Role Directory Structure

Every role follows the same standard tree. Ansible auto-loads the `main.yml` file in each directory, so you rarely reference these paths explicitly.

```text
roles/
  webserver/
    tasks/main.yml          # Primary list of tasks the role runs
    handlers/main.yml       # Handlers, notified by tasks (e.g. restart nginx)
    templates/              # Jinja2 templates rendered with ansible.builtin.template
    files/                  # Static files copied with ansible.builtin.copy
    vars/main.yml           # Role variables (high precedence)
    defaults/main.yml       # Default variables (low precedence, meant to be overridden)
    meta/main.yml           # Role metadata: dependencies and galaxy_info
    library/                # Custom modules local to this role
    module_utils/           # Shared Python helpers for the role's modules
    lookup_plugins/         # Custom lookup plugins (also filter_plugins/, etc.)
    tests/                  # Test inventory and a sample playbook
```

| Directory | Auto-loaded file | Purpose |
| --- | --- | --- |
| `tasks/` | `main.yml` | The role's entry point — the tasks executed when the role runs. |
| `handlers/` | `main.yml` | Handlers triggered by `notify`; run once at the end of the play. |
| `templates/` | (none) | Jinja2 templates; `ansible.builtin.template` searches here first. |
| `files/` | (none) | Static assets; `ansible.builtin.copy` searches here first. |
| `vars/` | `main.yml` | Variables tied to the role's logic; high precedence. |
| `defaults/` | `main.yml` | Sensible defaults callers are expected to override; lowest precedence. |
| `meta/` | `main.yml` | Declares `dependencies` and `galaxy_info` (author, license, platforms). |
| `library/` | (none) | Custom modules usable only by this role. |
| `module_utils/` | (none) | Reusable Python code imported by the role's modules. |
| `lookup_plugins/` | (none) | Role-scoped plugins (lookup, filter, test, callback, etc.). |
| `tests/` | `test.yml` | A minimal inventory and playbook for exercising the role. |

Any directory you do not need can be omitted. A trivial role might contain only `tasks/main.yml`.

> [!NOTE]
> Within `tasks/main.yml` you can split logic across additional files (for example `tasks/install.yml`) and pull them in with `ansible.builtin.import_tasks` or `ansible.builtin.include_tasks`. Only `main.yml` is auto-loaded; everything else is included explicitly.

### Creating a Role

Scaffold the standard tree with `ansible-galaxy`:

```bash
# Create a role skeleton in the current directory
ansible-galaxy role init webserver

# Older shorthand (still valid)
ansible-galaxy init webserver
```

Roles are discovered from a `roles_path`. By default Ansible looks in a `roles/` directory next to the playbook, then in `~/.ansible/roles`, `/usr/share/ansible/roles`, and `/etc/ansible/roles`. Set a custom path in `ansible.cfg`:

```text
[defaults]
roles_path = ./roles:./external_roles
```

For most projects, keeping roles in a `roles/` directory beside your playbooks is the simplest layout and needs no configuration.

### Using Roles in a Play

There are three ways to invoke a role. The classic `roles:` keyword adds roles to a play, and they run **before** any tasks in that play's `tasks:` section:

```yaml
- name: Configure web tier
  hosts: web
  become: true
  roles:
    - common
    - role: webserver
      vars:
        http_port: 8080
```

Inside the `tasks:` section you can instead call a role with a module, which gives you finer control:

```yaml
- name: Configure web tier
  hosts: web
  become: true
  tasks:
    - name: Apply baseline hardening (static)
      ansible.builtin.import_role:
        name: common

    - name: Deploy each site (dynamic)
      ansible.builtin.include_role:
        name: webserver
      vars:
        http_port: "{{ item.port }}"
      loop: "{{ sites }}"
```

The difference between the two matters:

- **`ansible.builtin.import_role` is static.** The role's tasks are parsed and inserted when the playbook is first read. Tags applied to the import propagate to every task in the role, but you cannot use it inside a `loop`.
- **`ansible.builtin.include_role` is dynamic.** The role is resolved at runtime, so it works with `loop`, `when`, and other runtime constructs. Because it is evaluated late, a tag on the include does not automatically reach the role's inner tasks.

> [!IMPORTANT]
> Use `import_role` when you want the role's tasks visible to `--list-tasks` and controllable by tags. Use `include_role` when you need to run a role conditionally or repeatedly in a loop. Mixing them freely is fine — choose per call site.

Variables passed with `vars:` (as shown above) are scoped to that role invocation, which is the cleanest way to parameterize a role.

### Role Variables and Precedence

Roles expose two variable files with very different precedence:

- **`defaults/main.yml`** holds the lowest-precedence variables in Ansible. They exist to be overridden by inventory, play vars, `-e` extra vars, or a `vars:` block on the role call. Put every knob a user might tune here.
- **`vars/main.yml`** holds high-precedence variables tied to the role's internal logic — values you do *not* expect callers to change, such as a package name that differs per OS family.

```yaml
# defaults/main.yml — caller-overridable
http_port: 80
worker_processes: auto

# vars/main.yml — internal, high precedence
nginx_package: nginx
nginx_service: nginx
```

Because `vars/main.yml` outranks most other sources, avoid placing tunable settings there — a caller's inventory value will be silently ignored. For the complete precedence order, see [variables-and-facts.md](variables-and-facts.md).

### Role Dependencies

A role can require other roles to run first. Declare them in `meta/main.yml`:

```yaml
galaxy_info:
  author: Joseph Streeter
  description: Installs and configures Nginx
  license: MIT
  min_ansible_version: "2.16"
  platforms:
    - name: Ubuntu
      versions:
        - jammy
        - noble

dependencies:
  - role: common
  - role: firewall
    vars:
      firewall_allowed_ports:
        - 80
        - 443
```

Listed dependencies are executed **before** the role that declares them, in order. Keep dependency chains shallow; deep chains make execution order hard to reason about. `galaxy_info` is also what Ansible Galaxy reads when the role is published.

### Collections

A **collection** is a distributable bundle that can contain roles, modules, plugins, and even entire playbooks, packaged under a namespace. Content inside a collection is addressed by its **Fully Qualified Collection Name (FQCN)** in the form `namespace.collection.content`:

```text
ansible.builtin.copy          # copy module in the builtin collection
community.general.timezone    # timezone module in community.general
ansible.posix.firewalld       # firewalld module in ansible.posix
amazon.aws.ec2_instance       # ec2_instance module in amazon.aws
```

`ansible.builtin` ships inside `ansible-core` itself — modules like `copy`, `template`, `service`, and `apt` are always available. Everything else lives in a separate collection you install on demand:

| Collection | Contents |
| --- | --- |
| `ansible.builtin` | Core modules bundled with `ansible-core`; no install needed. |
| `community.general` | Broad grab-bag of community modules and plugins. |
| `ansible.posix` | POSIX-oriented modules (`firewalld`, `mount`, `sysctl`, `authorized_key`). |
| `amazon.aws` | Official AWS modules maintained by the cloud provider. |

> [!NOTE]
> The `ansible` package (as opposed to the minimal `ansible-core`) is itself a curated bundle of many popular collections. Installing `ansible-core` alone gives you only `ansible.builtin`, so you add the collections you need explicitly. See [installation.md](installation.md).

### Installing and Managing Collections and Roles

Install a single collection or role directly:

```bash
# Install a collection from Ansible Galaxy
ansible-galaxy collection install community.general

# Install a standalone role
ansible-galaxy role install geerlingguy.docker
```

By default collections install to `~/.ansible/collections`. For reproducible, project-local installs, point Ansible at a directory inside the repo:

```bash
export ANSIBLE_COLLECTIONS_PATH=./collections
ansible-galaxy collection install community.general -p ./collections
```

The durable, team-friendly approach is a `collections/requirements.yml` that pins both collections **and** roles to specific versions. Commit this file so every checkout resolves identical content:

```yaml
# collections/requirements.yml
---
collections:
  - name: community.general
    version: "9.5.0"
  - name: ansible.posix
    version: "1.5.4"
  - name: amazon.aws
    version: ">=8.0.0,<9.0.0"

roles:
  - name: geerlingguy.docker
    version: "7.4.1"
  - src: https://github.com/example/ansible-role-myapp.git
    scm: git
    version: "v2.1.0"
    name: myapp
```

Install everything the file declares:

```bash
# Installs BOTH the collections and roles sections
ansible-galaxy install -r collections/requirements.yml

# Installs only the collections section
ansible-galaxy collection install -r collections/requirements.yml
```

> [!IMPORTANT]
> Always pin versions and commit `requirements.yml`. Unpinned dependencies mean a `community.general` release can silently change your automation's behavior between runs. Pinning makes builds reproducible across developers and CI.

### Using Collection Content

The recommended way to reference collection content is by its full FQCN at each usage site. It is unambiguous and survives refactoring:

```yaml
- name: Ensure the timezone is set
  community.general.timezone:
    name: America/Chicago

- name: Open the HTTPS service in the firewall
  ansible.posix.firewalld:
    service: https
    permanent: true
    state: enabled
    immediate: true
```

Ansible also supports a play-level `collections:` keyword that lets you write short module names by declaring a search list. Treat this as legacy shorthand — it obscures where a module comes from and can collide when two collections define the same name:

```yaml
# Legacy shorthand — prefer explicit FQCN instead
- name: Configure host
  hosts: all
  collections:
    - community.general
  tasks:
    - name: Set timezone using short name
      timezone:
        name: America/Chicago
```

> [!TIP]
> Standardize on FQCN everywhere. It is required by `ansible-lint`'s default rules, makes examples copy-pasteable without hidden context, and prevents ambiguous module resolution. See [best-practices.md](best-practices.md).

### Publishing and Sharing

You can share your own content the same way you consume others'. Build a collection tarball from a directory containing a `galaxy.yml` manifest:

```bash
# From the collection's root (contains galaxy.yml)
ansible-galaxy collection build

# Publish the built artifact
ansible-galaxy collection publish ./my_namespace-my_collection-1.0.0.tar.gz
```

Public content is distributed through [Ansible Galaxy](https://galaxy.ansible.com), while organizations typically host vetted, internal content on a private **Automation Hub** and point `ansible.cfg` at it via a `[galaxy]` server list. For most teams, consuming pinned upstream collections and keeping your own roles in `roles/` covers day-to-day needs without publishing anything.

Keep secrets out of shared roles and collections — parameterize sensitive values and supply them at runtime, as described in [vault-and-secrets.md](vault-and-secrets.md).

## Related

- [Playbooks](playbooks.md)
- [Variables and Facts](variables-and-facts.md)
- [Best Practices](best-practices.md)
- [Installation](installation.md)

## References

- [Roles — Ansible Documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html)
- [Using collections — Ansible Documentation](https://docs.ansible.com/ansible/latest/collections_guide/index.html)
- [ansible-galaxy CLI — Ansible Documentation](https://docs.ansible.com/ansible/latest/cli/ansible-galaxy.html)
- [Developing collections — Ansible Documentation](https://docs.ansible.com/ansible/latest/dev_guide/developing_collections.html)
- [Ansible Galaxy](https://galaxy.ansible.com)
