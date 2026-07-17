---
title: Variables, Facts, and Templating
description: Ansible variables and their precedence, gathered and custom facts, magic variables, and Jinja2 templating with filters and tests.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: concept
ms.service: ansible
keywords: ansible, variables, precedence, facts, jinja2, templating, filters, set_fact, hostvars
uid: docs.infrastructure.ansible.variables-and-facts
---

## Variables, Facts, and Templating

Variables let a single playbook or role adapt to many hosts, environments, and edge cases without duplicating logic. Ansible combines statically defined variables, dynamically discovered *facts*, and *magic variables* (data about the inventory and run itself), then renders everything through the Jinja2 templating engine. This page covers where variables come from, how conflicting definitions resolve through precedence, how facts are gathered and extended, and how to template configuration files reliably.

For where these fit in the broader workflow, see [playbooks.md](playbooks.md) and [roles-and-collections.md](roles-and-collections.md). For inventory-scoped variables, see [inventory.md](inventory.md).

### Defining variables

Variables can be set in many places. The most common sources, roughly from broadest scope to most targeted:

```yaml
---
# Play-level vars (in a playbook)
- name: Configure web tier
  hosts: web
  vars:
    http_port: 80
    max_clients: 200
  vars_files:
    - vars/common.yml           # external file of variables
  vars_prompt:
    - name: db_password
      prompt: "Database password"
      private: true             # do not echo input
  tasks:
    - name: Show a variable
      ansible.builtin.debug:
        msg: "Listening on {{ http_port }}"
```

Other sources you will use constantly:

- **Inventory `group_vars/` and `host_vars/`** — files named after a group or host, loaded automatically. See [inventory.md](inventory.md).
- **Role `defaults/main.yml`** — the lowest-precedence, intended-to-be-overridden values for a role.
- **Role `vars/main.yml`** — higher-precedence role constants.
- **`set_fact`** — variables created at runtime from expressions or other facts.
- **Registered variables** — output captured from a task with `register`.
- **Extra vars** — passed on the command line with `-e` / `--extra-vars`; these win over everything.

```yaml
---
- name: Runtime variables
  hosts: app
  gather_facts: true
  tasks:
    - name: Register command output
      ansible.builtin.command: hostname -f
      register: fqdn_result
      changed_when: false

    - name: Derive a fact from registered output
      ansible.builtin.set_fact:
        node_fqdn: "{{ fqdn_result.stdout | trim }}"

    - name: Use the registered and derived values
      ansible.builtin.debug:
        msg: "rc={{ fqdn_result.rc }} fqdn={{ node_fqdn }}"
```

Pass extra vars at invocation time:

```bash
ansible-playbook site.yml -e "http_port=8080 env=staging"
ansible-playbook site.yml -e "@vars/overrides.yml"   # from a file
```

> [!NOTE]
> Variable names must be valid Python identifiers: letters, digits, and underscores, and they cannot start with a digit. Avoid reserved names and Ansible's own keywords (for example `environment`, `name`, `tags`). Prefix role variables with the role name (`nginx_worker_processes`) to prevent collisions across roles.

### Variable precedence

When the same variable is defined in more than one place, Ansible resolves it using a fixed order of roughly 22 levels. Later (higher) sources override earlier (lower) ones. You rarely need the full list, but you must know the practical ordering to avoid surprises.

| Precedence (low to high) | Source | Typical use |
| --- | --- | --- |
| 1 (lowest) | Role `defaults/main.yml` | Sane, overridable defaults |
| 2 | Inventory `group_vars/` | Per-group configuration |
| 3 | Inventory `host_vars/` | Per-host configuration |
| 4 | Play `vars` and `vars_files` | Play-scoped settings |
| 5 | Role `vars/main.yml` | Role constants |
| 6 | Block and task `vars` | Narrow, local overrides |
| 7 | `set_fact` and registered vars | Runtime-derived values |
| 8 (highest) | Extra vars (`-e`) | Command-line overrides, always win |

> [!TIP]
> Put values you expect operators to override in a role's `defaults/` directory, and put values that must not change in `vars/`. Because `vars/` outranks inventory `group_vars`/`host_vars`, constants placed there cannot be accidentally overridden by inventory.

The table above is a shortlist. The complete ordering distinguishes several finer levels (for example inventory file vars versus `group_vars`, and playbook `group_vars` versus inventory `group_vars`). See the official precedence reference linked under [References](#references) for the authoritative full list.

> [!WARNING]
> Extra vars (`-e`) override everything, including `set_fact`. This makes them powerful for one-off runs but dangerous in automation: a stray `-e` can silently mask carefully computed values. Reserve extra vars for deliberate overrides.

### Accessing variables and subelements

Reference a variable by wrapping its name in double curly braces. Quote any value that begins with `{{` so YAML does not misparse it as a dictionary.

```yaml
---
- name: Access variables
  hosts: localhost
  vars:
    app:
      name: billing
      ports: [8080, 8443]
  tasks:
    - name: Dotted access
      ansible.builtin.debug:
        msg: "{{ app.name }} on {{ app.ports[0] }}"

    - name: Bracket access (needed for keys with dashes or dynamic keys)
      ansible.builtin.debug:
        msg: "{{ app['name'] }}"
```

Use bracket notation when a key contains characters that are not valid in an identifier (hyphens, dots) or when the key itself is stored in a variable. Guard optionally defined variables with the `default` filter so a missing value does not fail the run:

```yaml
---
- name: Provide fallbacks
  ansible.builtin.debug:
    msg: "{{ log_level | default('info') }}"
```

The `default` filter also accepts a second argument, `default(omit)`, which removes the parameter entirely when the source variable is undefined — useful for optional module arguments.

### Facts

Facts are pieces of system information Ansible discovers about each managed host: OS family, network interfaces, memory, mounted filesystems, and much more. By default a play begins with an implicit fact-gathering step that runs the `ansible.builtin.setup` module against every host.

```yaml
---
- name: Use gathered facts
  hosts: all
  gather_facts: true          # default; set false to skip
  tasks:
    - name: Show OS details
      ansible.builtin.debug:
        msg: >-
          {{ ansible_facts['distribution'] }}
          {{ ansible_facts['distribution_version'] }}
          ({{ ansible_facts['os_family'] }})

    - name: Show primary IPv4 address
      ansible.builtin.debug:
        msg: "{{ ansible_facts['default_ipv4']['address'] }}"
```

Facts are exposed two ways. The modern namespace is `ansible_facts` (for example `ansible_facts['os_family']`). The legacy form promotes each fact to a top-level `ansible_`-prefixed variable (for example `ansible_os_family`, `ansible_default_ipv4.address`). Both refer to the same data; the `ansible_facts` dictionary is preferred in new code.

Gathering facts on every host adds latency. Disable it when a play does not need facts, or gather them explicitly later:

```yaml
---
- name: Skip automatic gathering for speed
  hosts: all
  gather_facts: false
  tasks:
    - name: Gather only when needed
      ansible.builtin.gather_facts:
      tags: [facts]
```

> [!NOTE]
> You can also collect a subset of facts by setting `gather_subset` (for example `gather_subset: ['network', '!hardware']`) on the play or on the `ansible.builtin.setup` module, which reduces gathering time on large fleets.

### Custom facts

Beyond built-in facts, you can supply your own. **Local facts** are files placed in `/etc/ansible/facts.d/` on the managed host, ending in `.fact`. Static files use INI or JSON format; executable files must emit JSON on stdout. Their contents appear under `ansible_facts['ansible_local']`.

```text
# /etc/ansible/facts.d/app.fact
[deployment]
tier=web
release=2024.11
```

```yaml
---
- name: Read a local fact
  ansible.builtin.debug:
    msg: "{{ ansible_facts['ansible_local']['app']['deployment']['tier'] }}"
```

**Runtime facts** are created during a play with `ansible.builtin.set_fact`. By default they live only for the current run; add `cacheable: true` to persist them to the configured fact cache so later plays can read them.

```yaml
---
- name: Set a cacheable runtime fact
  ansible.builtin.set_fact:
    deploy_stamp: "{{ '%Y%m%dT%H%M%S' | strftime }}"
    cacheable: true
```

### Magic variables

Magic variables are provided automatically by Ansible and describe the inventory, the current host, and the run. They are read-only and cannot be set with `set_fact`.

| Variable | Meaning |
| --- | --- |
| `hostvars` | Dictionary of every host's variables and facts, keyed by hostname |
| `groups` | Dictionary mapping each group name to its list of hosts |
| `group_names` | List of groups the current host belongs to |
| `inventory_hostname` | Name of the current host as defined in inventory |
| `inventory_hostname_short` | The hostname up to the first dot |
| `ansible_play_hosts` | Hosts still active in the current play (post-failure) |
| `play_hosts` | Legacy alias for the active-hosts list |
| `ansible_playbook_python` | Path to the Python interpreter running ansible-playbook |

`hostvars` is the key to cross-host data. Because facts are gathered per host, one host can read another's facts — provided that host has been gathered earlier in the run:

```yaml
---
- name: Build a backend pool from peer facts
  hosts: load_balancers
  tasks:
    - name: List app-server IPs
      ansible.builtin.debug:
        msg: >-
          {{ groups['app']
             | map('extract', hostvars, ['ansible_facts', 'default_ipv4', 'address'])
             | list }}
```

### Jinja2 templating

Ansible uses Jinja2 for all variable interpolation. There are three delimiters:

- `{{ ... }}` — expressions that render a value.
- `{% ... %}` — statements such as loops and conditionals.
- `{# ... #}` — comments that are removed from output.

**Filters** transform values with a pipe. Common filters include `default`, `to_json`, `to_nice_yaml`, `join`, `map`, `select`/`reject`, `unique`, `combine`, `regex_replace`, and `b64encode`. **Tests** return booleans and are used with `is`, such as `is defined`, `is match`, and `is version`.

```yaml
---
- name: Filter examples
  hosts: localhost
  vars:
    packages: [nginx, curl, nginx, git]
    base_config: { timeout: 30, retries: 3 }
    override: { retries: 5 }
  tasks:
    - name: Deduplicate and join
      ansible.builtin.debug:
        msg: "{{ packages | unique | join(', ') }}"

    - name: Merge two dictionaries (override wins)
      ansible.builtin.debug:
        msg: "{{ base_config | combine(override) }}"

    - name: Select matching hosts and encode a secret
      ansible.builtin.debug:
        msg: >-
          {{ groups['all'] | select('match', '^web') | list }}
          token={{ 'p@ss' | b64encode }}

    - name: Guard on definition and pattern
      ansible.builtin.debug:
        msg: "release looks valid"
      when:
        - app_release is defined
        - app_release is match('^[0-9]{4}\\.[0-9]{2}$')
```

> [!IMPORTANT]
> Filters and tests run on the control node, not the managed host. They operate on already-gathered data, so a filter cannot query a remote system by itself — use a module or lookup for that.

### The template module

`ansible.builtin.template` renders a Jinja2 `.j2` file locally and copies the result to the target. Templates have full access to variables, facts, and magic variables.

```yaml
---
- name: Render nginx config
  ansible.builtin.template:
    src: templates/nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: "0644"
    validate: "nginx -t -c %s"
  notify: Reload nginx
```

A short template that uses a loop and a conditional:

```jinja2
# {{ ansible_managed }}
worker_processes {{ nginx_worker_processes | default('auto') }};

upstream backend {
{% for host in groups['app'] %}
    server {{ hostvars[host]['ansible_facts']['default_ipv4']['address'] }}:8080;
{% endfor %}
}

server {
    listen {{ http_port | default(80) }};
{% if enable_tls | default(false) %}
    listen 443 ssl;
    ssl_certificate     /etc/ssl/certs/site.pem;
    ssl_certificate_key /etc/ssl/private/site.key;
{% endif %}
}
```

**Lookups** run on the control node and pull external data into a play. Useful ones include `file` (read a local file), `env` (read an environment variable), and `template` (render a template into a variable):

```yaml
---
- name: Lookups
  ansible.builtin.debug:
    msg: >-
      pubkey={{ lookup('ansible.builtin.file', '~/.ssh/id_ed25519.pub') }}
      home={{ lookup('ansible.builtin.env', 'HOME') }}
```

> [!TIP]
> Keep secrets out of templates and plain variable files. Store sensitive values with Ansible Vault and reference them like any other variable — see [vault-and-secrets.md](vault-and-secrets.md).

## Related

- [Playbooks](playbooks.md)
- [Roles and Collections](roles-and-collections.md)
- [Inventory](inventory.md)
- [Vault and Secrets](vault-and-secrets.md)

## References

- [Using Variables](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html)
- [Variable Precedence: Where Should I Put a Variable?](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable)
- [Discovering Variables: Facts and Magic Variables](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html)
- [Special Variables](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html)
- [Templating (Jinja2)](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_templating.html)
- [Playbook Filters](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_filters.html)
- [ansible.builtin.set_fact module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/set_fact_module.html)
- [ansible.builtin.template module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html)
