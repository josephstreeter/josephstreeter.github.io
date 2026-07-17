---
title: Best Practices
description: Project structure, idempotency, linting and testing, performance tuning, CI/CD, and scaling Ansible with Automation Platform.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: best-practice
ms.service: ansible
keywords: ansible, best practices, ansible-lint, molecule, ci-cd, performance, pipelining, awx, automation platform
uid: docs.infrastructure.ansible.best-practices
---

## Best Practices

This page distills field-tested conventions for building maintainable, testable, and performant Ansible automation. It assumes a working install (see [installation.md](installation.md)) and familiarity with the concepts in [index.md](index.md). The recommendations target current `ansible-core` (2.16/2.17) and use fully qualified collection names (FQCN) throughout.

> [!TIP]
> Adopt these practices incrementally. Start with project structure and linting, add idempotency verification and Molecule tests as roles mature, then wire everything into CI/CD.

### Project structure

A predictable layout makes automation discoverable and keeps environment-specific data separate from reusable logic. The following layout scales from a handful of hosts to large fleets.

```text
.
├── ansible.cfg                     # Project-local config (forks, pipelining, fact cache)
├── collections/
│   └── requirements.yml            # Pinned collection dependencies (installed to ./collections)
├── requirements.yml                # Pinned role dependencies (ansible-galaxy roles)
├── inventories/
│   ├── production/
│   │   ├── hosts.yml               # Inventory for prod
│   │   ├── group_vars/
│   │   │   ├── all.yml
│   │   │   └── webservers.yml
│   │   └── host_vars/
│   │       └── web01.example.com.yml
│   └── staging/
│       ├── hosts.yml
│       └── group_vars/
│           └── all.yml
├── group_vars/                     # Optional shared defaults across inventories
├── host_vars/
├── roles/
│   └── nginx/
│       ├── defaults/main.yml
│       ├── handlers/main.yml
│       ├── tasks/main.yml
│       ├── templates/
│       ├── meta/main.yml
│       └── molecule/default/       # Tests live next to the role
├── playbooks/
│   ├── webservers.yml
│   └── database.yml
└── site.yml                        # Top-level playbook that imports the others
```

Rationale:

- **`ansible.cfg` at the project root** is auto-detected when you run from the repo, so behavior is reproducible for everyone without relying on a user's home directory config.
- **`inventories/<env>/`** keeps production and staging fully isolated. Each environment owns its `group_vars/` and `host_vars/`, which prevents accidental cross-environment variable bleed. See [inventory.md](inventory.md) for inventory design details.
- **`roles/`** holds reusable, parameterized units of automation. Keep site-specific data out of roles and pass it in via variables. See [roles-and-collections.md](roles-and-collections.md).
- **`collections/requirements.yml`** pins external collections; committing the manifest (not the installed content) keeps builds reproducible.
- **`site.yml`** composes smaller playbooks with `import_playbook`, giving you both a single entry point and the ability to run a subset.

> [!NOTE]
> Prefer `group_vars`/`host_vars` files over inline `vars:` in plays. Variable precedence is easier to reason about when data lives in predictable locations.

### Writing maintainable playbooks

Readable playbooks are cheaper to review, debug, and hand off. The following conventions pay for themselves quickly.

- **Always name every task and play.** Names become your run log and are required by `ansible-lint` production profile.
- **Prefer specific modules over `command`/`shell`.** Modules like `ansible.builtin.copy`, `ansible.builtin.apt`, and `ansible.builtin.systemd_service` are idempotent and report accurate change state. Reach for `command`/`shell` only when no module exists.
- **When you must use `command`/`shell`, constrain change detection.** Set `creates`/`removes`, or `changed_when`/`failed_when`, so the task reports honest state.
- **Keep plays small and role-composed.** A play should orchestrate roles, not contain hundreds of inline tasks.
- **Use handlers for service restarts.** Notify a handler so a restart happens once, at the end, only when something actually changed.
- **Avoid hardcoding.** Push values into `defaults/main.yml` and `group_vars`. See [variables-and-facts.md](variables-and-facts.md).

```yaml
---
- name: Configure web tier
  hosts: webservers
  become: true
  roles:
    - role: nginx

# roles/nginx/tasks/main.yml
- name: Deploy nginx site configuration
  ansible.builtin.template:
    src: site.conf.j2
    dest: /etc/nginx/conf.d/site.conf
    owner: root
    group: root
    mode: "0644"
  notify: Restart nginx

- name: Rotate application logs (no module available)
  ansible.builtin.command:
    cmd: /usr/local/bin/rotate-logs.sh
  args:
    creates: /var/log/app/rotated.marker
  changed_when: false
```

```yaml
---
# roles/nginx/handlers/main.yml
- name: Restart nginx
  ansible.builtin.systemd_service:
    name: nginx
    state: restarted
```

### Idempotency

An idempotent playbook produces the same result no matter how many times it runs: the first run makes changes, and every subsequent run reports `changed=0`. This is the single most important quality signal for automation.

Verify idempotency by running twice and confirming the second run is clean:

```bash
ansible-playbook -i inventories/staging/hosts.yml site.yml
ansible-playbook -i inventories/staging/hosts.yml site.yml   # expect changed=0
```

`command` and `shell` are the usual culprits for non-idempotency because Ansible cannot know whether they changed anything. Guard them with `creates`, `changed_when`, or a preceding check task. Use check mode with diff to preview changes without applying them:

```bash
ansible-playbook -i inventories/staging/hosts.yml site.yml --check --diff
```

> [!IMPORTANT]
> Check mode is only reliable if your tasks support it. Tasks that use `command`/`shell` are skipped in check mode unless you set `check_mode: false` and provide your own change logic — plan for this when auditing changes.

### Linting and style

Two complementary linters catch most issues before a playbook ever runs. Use `yamllint` for YAML formatting (indentation, line length, truthy values) and `ansible-lint` for Ansible-specific rules (FQCN usage, unnamed tasks, deprecated syntax, risky `command` usage).

```bash
pip install ansible-lint yamllint
yamllint .
ansible-lint
ansible-playbook site.yml --syntax-check
```

Configure `ansible-lint` with a `.ansible-lint` file at the repo root. The `production` profile is the strictest and is the target for anything you deploy widely.

```yaml
---
# .ansible-lint
profile: production
exclude_paths:
  - collections/
  - .github/
skip_list:
  - yaml[line-length]   # Delegated to yamllint's own config
```

> [!TIP]
> `--syntax-check` only validates parse-ability; it does not evaluate logic. Treat it as a fast first gate, then run `ansible-lint` for substantive checks.

### Testing with Molecule

Molecule automates role testing by managing a full lifecycle: it creates an ephemeral instance, converges the role against it, runs verification assertions, re-runs to confirm idempotence, and then destroys the instance. This catches regressions that linting cannot.

```bash
pip install molecule molecule-plugins[docker]
cd roles/nginx
molecule init scenario default
molecule test
```

`molecule test` runs the full sequence (dependency, create, converge, idempotence, verify, destroy). During development, iterate faster with `molecule converge` and `molecule verify`, then run the full `molecule test` before committing.

The default driver runs against containers (Docker or Podman), which is fast and disposable. Configure the driver and platforms in `molecule/default/molecule.yml`:

```yaml
---
# roles/nginx/molecule/default/molecule.yml
driver:
  name: docker
platforms:
  - name: instance
    image: quay.io/centos/centos:stream9
    pre_build_image: true
provisioner:
  name: ansible
verifier:
  name: ansible
```

> [!NOTE]
> Podman is a drop-in rootless alternative to Docker. Set `driver.name: podman` and install `molecule-plugins[podman]` if your build hosts disallow the Docker daemon.

### CI/CD

Run the same gates locally and in the pipeline: syntax-check, `ansible-lint`, and (for roles) `molecule test`. Gate deployments behind these checks so nothing merges or ships without passing lint and tests.

```yaml
---
# .github/workflows/lint.yml
name: Ansible Lint
on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install Ansible and linters
        run: pip install ansible-core ansible-lint yamllint

      - name: Install collections
        run: ansible-galaxy collection install -r collections/requirements.yml

      - name: Run yamllint
        run: yamllint .

      - name: Run ansible-lint
        run: ansible-lint
```

For roles, add a second job that runs `molecule test` on a matrix of target images. Keep destructive production deploys in a separate, protected workflow that only triggers after the lint and test jobs succeed.

### Performance tuning

Most slowness comes from serial task execution and repeated SSH setup. The following knobs address both. Set the durable ones in `ansible.cfg` and reach for per-run flags when tuning.

| Setting | Where | Effect |
| --- | --- | --- |
| `forks` / `-f` | `ansible.cfg` `[defaults]` or CLI | Number of hosts configured in parallel; raise from the default 5 for large fleets. |
| `pipelining = true` | `ansible.cfg` `[ssh_connection]` | Reduces SSH operations per task; requires `requiretty` disabled in sudoers. |
| `ControlPersist` | `ssh_args` in `[ssh_connection]` | Reuses SSH connections across tasks, avoiding repeated handshakes. |
| `gathering = smart` + fact cache | `ansible.cfg` `[defaults]` | Caches facts (jsonfile/redis) so re-runs skip re-gathering. |
| `gather_facts: false` | Play level | Skips fact gathering entirely when a play does not need facts. |
| `gather_subset` | Play/`setup` module | Limits gathering to needed subsets (for example `!hardware`). |
| `strategy: free` | Play level | Lets each host proceed independently instead of lock-step. |
| `async` / `poll` | Task level | Runs long tasks in the background so they do not block the fork. |

```ini
; ansible.cfg
[defaults]
forks = 25
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_fact_cache
fact_caching_timeout = 7200

[ssh_connection]
pipelining = true
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

For a long-running task, decouple it from the fork with `async` and `poll`:

```yaml
---
- name: Run a long database migration
  ansible.builtin.command:
    cmd: /usr/local/bin/migrate.sh
  async: 3600
  poll: 15
  changed_when: false
```

> [!TIP]
> The third-party [Mitogen](https://mitogen.networkgenie.com/) strategy plugin can dramatically reduce connection overhead for large runs. It is community-maintained and version-sensitive, so validate it against your `ansible-core` version before relying on it in production.

### Secrets and safety

Never commit plaintext secrets. Store them in Ansible Vault and reference them by variable — see [vault-and-secrets.md](vault-and-secrets.md) for encryption workflows. Add defense in depth around how secrets are handled at runtime.

- **Use `no_log: true`** on tasks that handle passwords, tokens, or keys so values never appear in output or logs.
- **Apply least-privilege `become`.** Escalate only on the tasks that need it, and use `become_user` to target the minimum-privilege account.
- **Dry-run destructive changes.** Run `--check --diff` before any run that deletes, recreates, or reconfigures production resources.

```yaml
---
- name: Configure API credentials
  ansible.builtin.template:
    src: app.env.j2
    dest: /etc/app/app.env
    owner: app
    group: app
    mode: "0600"
  no_log: true
```

### Version and dependency management

Reproducible runs require pinned dependencies. Pin `ansible-core` in your Python requirements, and pin collection and role versions in their manifests so a fresh checkout resolves to identical content.

```yaml
---
# collections/requirements.yml
collections:
  - name: community.general
    version: "9.5.0"
  - name: ansible.posix
    version: "1.6.2"
```

```bash
pip install "ansible-core==2.17.*"
ansible-galaxy collection install -r collections/requirements.yml -p ./collections
ansible-galaxy role install -r requirements.yml
```

For maximum reproducibility, package the control-node runtime as an Execution Environment: a container image built with `ansible-builder` that bundles a specific `ansible-core`, collections, and system dependencies. The same image then runs locally, in CI, and in Automation Platform, eliminating "works on my machine" drift.

> [!IMPORTANT]
> Pin to specific versions rather than ranges for anything you ship. Version ranges make builds non-deterministic and turn an upstream release into an unplanned change in your environment.

### Scaling with Ansible Automation Platform / AWX

The CLI is ideal for individuals and small teams, but shared, multi-team automation benefits from a control layer. AWX (the upstream project) and Red Hat Ansible Automation Platform (the supported product) add a web UI and REST API on top of `ansible-core`, turning ad-hoc runs into governed, auditable operations. Consider it once many people or teams need to run the same automation safely.

- **RBAC** so teams see only the projects, inventories, and credentials they own.
- **Encrypted credential storage** that injects secrets at run time without exposing them.
- **Job templates, schedules, and surveys** that make runs repeatable and self-service.
- **Workflows** that chain job templates with success/failure branching.
- **Inventory sync** from cloud and CMDB sources, plus a REST API for integration.

## Related

- [Roles and Collections](roles-and-collections.md)
- [Inventory](inventory.md)
- [Variables and Facts](variables-and-facts.md)
- [Vault and Secrets](vault-and-secrets.md)

## References

- [Ansible documentation](https://docs.ansible.com/)
- [Ansible best practices (tips and tricks)](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- [ansible-lint documentation](https://ansible.readthedocs.io/projects/lint/)
- [Molecule documentation](https://ansible.readthedocs.io/projects/molecule/)
