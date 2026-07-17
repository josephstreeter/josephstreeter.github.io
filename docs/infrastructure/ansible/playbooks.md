---
title: Playbooks and Tasks
description: Writing Ansible playbooks - plays, tasks, modules, handlers, conditionals, loops, blocks, error handling, and controlling execution.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: how-to
ms.service: ansible
keywords: ansible, playbook, tasks, handlers, conditionals, loops, blocks, ansible-playbook, idempotency
uid: docs.infrastructure.ansible.playbooks
---

## Playbooks and Tasks

Playbooks are the heart of Ansible automation. A playbook is a YAML file describing an ordered list of *plays*, and each play maps a set of hosts to a set of tasks. Unlike ad-hoc commands, playbooks are declarative, version-controlled, and repeatable, making them the standard way to define configuration and orchestration.

This page covers playbook and play structure, tasks and modules, registering results, handlers, conditionals, loops, blocks, error handling, tags, running playbooks from the command line, and controlling execution across hosts.

> [!NOTE]
> All examples use fully-qualified collection names (FQCN) such as `ansible.builtin.apt` and target current `ansible-core` (2.16/2.17). See [installation.md](installation.md) for setting up your control node.

### Playbook Structure

A playbook is an ordered list of plays. A *play* binds a group of hosts (from your [inventory](inventory.md)) to the tasks that run against them. Plays execute top to bottom, and tasks within a play execute in order.

The anatomy of a play:

```yaml
---
- name: Configure web servers          # human-readable play name
  hosts: webservers                     # inventory group or pattern
  become: true                          # privilege escalation (sudo)
  gather_facts: true                    # collect host facts (default)
  vars:                                 # play-scoped variables
    http_port: 80
    app_user: www-data
  tasks:                                # ordered list of tasks
    - name: Ensure nginx is installed
      ansible.builtin.apt:
        name: nginx
        state: present
        update_cache: true
  handlers:                             # triggered by notify
    - name: Restart nginx
      ansible.builtin.systemd:
        name: nginx
        state: restarted
```

A single file can contain multiple plays. This is useful for orchestrating different host groups in one run, for example configuring database servers before web servers:

```yaml
---
- name: Configure database tier
  hosts: databases
  become: true
  tasks:
    - name: Install PostgreSQL
      ansible.builtin.apt:
        name: postgresql
        state: present

- name: Configure web tier
  hosts: webservers
  become: true
  tasks:
    - name: Install nginx
      ansible.builtin.apt:
        name: nginx
        state: present
```

> [!TIP]
> Always name your plays and tasks. Names appear in output, make `--start-at-task` and `--list-tasks` usable, and document intent for the next reader.

### Tasks and Modules

Each task calls exactly one *module* — a unit of work such as installing a package, copying a file, or managing a service. Use the FQCN (`namespace.collection.module`) to remove ambiguity and to make dependencies on [collections](roles-and-collections.md) explicit.

```yaml
tasks:
  - name: Copy application config
    ansible.builtin.copy:
      src: files/app.conf
      dest: /etc/app/app.conf
      owner: root
      group: root
      mode: "0644"
```

Well-behaved modules are *idempotent*: running the same task repeatedly converges the system to the desired state without making changes if the state already matches. This is why Ansible reports a status for every task:

| Status | Meaning |
| --- | --- |
| `ok` | Task ran; system already in desired state (no change) |
| `changed` | Task made a change to reach the desired state |
| `failed` | Task encountered an error |
| `skipped` | Task was skipped (a `when` condition was false) |
| `unreachable` | Ansible could not connect to the host |

For quick, one-off actions you can use an *ad-hoc command* instead of a playbook:

```bash
ansible webservers -i inventory.ini -m ansible.builtin.ping
ansible webservers -i inventory.ini -b -m ansible.builtin.apt -a "name=curl state=present"
```

Ad-hoc commands are ideal for exploration and troubleshooting; playbooks are for anything you want to reproduce.

### Registering Results and Using Them

The `register` keyword captures a module's return value into a variable. You can then inspect fields such as `.stdout`, `.rc` (return code), `.stderr`, or module-specific keys, and drive follow-up tasks conditionally.

```yaml
tasks:
  - name: Check whether the app binary exists
    ansible.builtin.command: which myapp
    register: app_check
    changed_when: false          # a check should never report "changed"
    failed_when: false           # don't fail if the binary is missing

  - name: Report the resolved path
    ansible.builtin.debug:
      msg: "myapp is at {{ app_check.stdout }}"
    when: app_check.rc == 0

  - name: Install the app if it is missing
    ansible.builtin.apt:
      name: myapp
      state: present
    when: app_check.rc != 0
```

> [!TIP]
> Use `ansible.builtin.debug` with `var: app_check` to inspect the full structure of a registered result while developing. See [variables-and-facts.md](variables-and-facts.md) for more on working with variables.

### Handlers

Handlers are tasks that run only when *notified*, and only if the notifying task reported `changed`. They run once, at the end of the play, after all regular tasks — so many tasks can notify the same handler and it still fires a single time. This is the canonical way to restart a service only when its configuration actually changes.

```yaml
tasks:
  - name: Deploy nginx configuration
    ansible.builtin.template:
      src: templates/nginx.conf.j2
      dest: /etc/nginx/nginx.conf
      mode: "0644"
    notify: Restart nginx

handlers:
  - name: Restart nginx
    ansible.builtin.systemd:
      name: nginx
      state: restarted
```

To run pending handlers immediately rather than waiting for the end of the play, flush them explicitly:

```yaml
  - name: Flush handlers now
    ansible.builtin.meta: flush_handlers
```

Handlers can also be triggered by topic using `listen`, decoupling the notifier's text from a specific handler name. Multiple handlers may listen on the same topic:

```yaml
tasks:
  - name: Update TLS certificate
    ansible.builtin.copy:
      src: files/site.crt
      dest: /etc/ssl/certs/site.crt
      mode: "0644"
    notify: "reload web stack"

handlers:
  - name: Reload nginx
    ansible.builtin.systemd:
      name: nginx
      state: reloaded
    listen: "reload web stack"

  - name: Reload haproxy
    ansible.builtin.systemd:
      name: haproxy
      state: reloaded
    listen: "reload web stack"
```

> [!IMPORTANT]
> By default handlers do not run if any task fails earlier in the play. Use `--force-handlers` on the command line, or `force_handlers: true` on the play, if handlers must run despite failures.

### Conditionals

The `when` keyword runs a task only if an expression is true. Expressions are Jinja2 (without the surrounding `{{ }}` for the whole condition) and can reference facts, variables, and registered results.

```yaml
tasks:
  - name: Install Apache on Debian family
    ansible.builtin.apt:
      name: apache2
      state: present
    when: ansible_facts['os_family'] == "Debian"

  - name: Install Apache on RedHat family
    ansible.builtin.dnf:
      name: httpd
      state: present
    when: ansible_facts['os_family'] == "RedHat"
```

Combine conditions with `and`/`or`, or supply a list (which is an implicit `and`):

```yaml
  - name: Start service only on production Debian hosts
    ansible.builtin.systemd:
      name: myapp
      state: started
    when:
      - ansible_facts['os_family'] == "Debian"
      - environment_name == "production"

  - name: Act on staging or QA
    ansible.builtin.debug:
      msg: "Non-production host"
    when: environment_name == "staging" or environment_name == "qa"
```

### Loops

The `loop` keyword repeats a task once per item in a list. This is far more efficient and readable than writing near-identical tasks. Install several packages in one task:

```yaml
tasks:
  - name: Install base packages
    ansible.builtin.apt:
      name: "{{ item }}"
      state: present
      update_cache: true
    loop:
      - git
      - curl
      - vim
      - htop
```

> [!TIP]
> Package modules like `ansible.builtin.apt` and `ansible.builtin.dnf` also accept a list directly for `name:`, which installs everything in a single transaction and is faster than looping. Prefer `name: "{{ packages }}"` where the module supports it.

Loop over a list of dictionaries to pass multiple values per iteration:

```yaml
  - name: Create application users
    ansible.builtin.user:
      name: "{{ item.name }}"
      groups: "{{ item.groups }}"
      shell: "{{ item.shell }}"
    loop:
      - { name: alice, groups: sudo, shell: /bin/bash }
      - { name: bob, groups: developers, shell: /bin/zsh }
```

Use `loop_control` to rename the loop variable (avoiding collisions in nested loops) and to produce cleaner output with `label`:

```yaml
  - name: Deploy virtual hosts
    ansible.builtin.template:
      src: "templates/vhost.conf.j2"
      dest: "/etc/nginx/sites-available/{{ site.name }}.conf"
      mode: "0644"
    loop: "{{ vhosts }}"
    loop_control:
      loop_var: site
      label: "{{ site.name }}"
```

> [!NOTE]
> The older `with_items`, `with_dict`, and other `with_*` keywords are legacy. New playbooks should use `loop` (optionally with filters like `dict2items` or `subelements`).

### Blocks and Error Handling

A `block` groups tasks so they share directives (such as `when` or `become`) and enables try/rescue/finally-style error handling with `rescue` and `always`.

```yaml
tasks:
  - name: Attempt application deployment
    block:
      - name: Pull latest release
        ansible.builtin.get_url:
          url: https://example.com/releases/app-latest.tar.gz
          dest: /tmp/app.tar.gz
          mode: "0644"

      - name: Unpack release
        ansible.builtin.unarchive:
          src: /tmp/app.tar.gz
          dest: /opt/app
          remote_src: true

    rescue:
      - name: Roll back on failure
        ansible.builtin.command: /opt/app/bin/rollback.sh
        changed_when: true

    always:
      - name: Clean up download
        ansible.builtin.file:
          path: /tmp/app.tar.gz
          state: absent
```

Tasks in `rescue` run only if a task in the `block` fails; tasks in `always` run regardless of outcome. Three related keywords let you fine-tune how success and change are judged per task:

| Keyword | Purpose |
| --- | --- |
| `ignore_errors: true` | Continue the play even if this task fails |
| `failed_when: <expr>` | Define a custom failure condition |
| `changed_when: <expr>` | Define a custom "changed" condition |

```yaml
  - name: Run a health check that may exit non-zero
    ansible.builtin.command: /usr/local/bin/healthcheck
    register: health
    changed_when: false
    failed_when: health.rc not in [0, 2]   # treat rc 2 as acceptable
```

> [!WARNING]
> Prefer `failed_when` and `rescue` over blanket `ignore_errors: true`. Ignoring errors hides real problems and can leave hosts in an inconsistent state.

### Tags

Tags let you run — or skip — a subset of tasks or plays without editing the playbook. Attach one or more tags to any task, block, or play.

```yaml
tasks:
  - name: Install packages
    ansible.builtin.apt:
      name: nginx
      state: present
    tags:
      - packages
      - nginx

  - name: Deploy configuration
    ansible.builtin.template:
      src: templates/nginx.conf.j2
      dest: /etc/nginx/nginx.conf
      mode: "0644"
    tags:
      - config
```

Run only tagged tasks, or exclude them:

```bash
ansible-playbook -i inventory site.yml --tags config
ansible-playbook -i inventory site.yml --skip-tags packages
```

The special tags `always` (runs unless explicitly skipped) and `never` (runs only when its tag is requested) are useful for debug or destructive tasks.

### Running Playbooks

Run a playbook with `ansible-playbook`, passing an inventory and the playbook file:

```bash
ansible-playbook -i inventory site.yml
```

Key flags:

| Flag | Purpose |
| --- | --- |
| `--check` | Dry run — report what *would* change without applying |
| `--diff` | Show file/content differences for changed tasks |
| `--limit HOST` | Restrict the run to a host or group subset |
| `--tags TAGS` | Run only tasks with the listed tags |
| `--skip-tags TAGS` | Run everything except the listed tags |
| `-e "k=v"` | Pass extra variables (highest precedence) |
| `--start-at-task NAME` | Begin execution at a named task |
| `--step` | Prompt before each task (interactive) |
| `-v` / `-vvv` | Increase verbosity (`-vvvv` adds connection debug) |
| `--syntax-check` | Parse the playbook without running it |
| `--list-tasks` | List tasks that would run |
| `--list-hosts` | List hosts that would be targeted |

> [!TIP]
> Combine `--check --diff` to preview exactly what a run would change. Note that tasks depending on a prior task's real effect (via `register`) may behave differently in check mode.

### Controlling Execution Across Hosts

By default Ansible runs each task on all hosts before moving to the next task (the `linear` strategy). Several keywords change this behavior for orchestration and rolling deployments.

| Keyword | Effect |
| --- | --- |
| `serial:` | Run the play in batches (rolling updates) |
| `strategy:` | `linear` (default) or `free` (hosts advance independently) |
| `run_once: true` | Run the task on a single host on behalf of the batch |
| `delegate_to:` | Run the task on a different host than the current one |
| `throttle:` | Cap concurrent hosts for a specific task |

A minimal rolling deployment that updates two hosts at a time and pauses if too many fail:

```yaml
---
- name: Rolling web deploy
  hosts: webservers
  become: true
  serial: 2
  max_fail_percentage: 25
  tasks:
    - name: Remove host from the load balancer
      ansible.builtin.command: /usr/local/bin/lb-drain {{ inventory_hostname }}
      delegate_to: loadbalancer01
      changed_when: true

    - name: Update the application package
      ansible.builtin.apt:
        name: myapp
        state: latest
        update_cache: true

    - name: Add host back to the load balancer
      ansible.builtin.command: /usr/local/bin/lb-enable {{ inventory_hostname }}
      delegate_to: loadbalancer01
      changed_when: true

    - name: Send a single deploy notification
      ansible.builtin.uri:
        url: https://hooks.example.com/deploy-complete
        method: POST
      run_once: true
```

### Complete Worked Example

The following play updates the package cache, installs and configures nginx from a Jinja2 template, restarts it only when the configuration changes, and opens the firewall — all with FQCN modules and idempotent state.

```yaml
---
- name: Provision an nginx web server
  hosts: webservers
  become: true
  gather_facts: true
  vars:
    http_port: 80
    server_name: www.example.com

  tasks:
    - name: Update apt cache and install nginx
      ansible.builtin.apt:
        name: nginx
        state: present
        update_cache: true
        cache_valid_time: 3600

    - name: Ensure the site document root exists
      ansible.builtin.file:
        path: /var/www/example
        state: directory
        owner: www-data
        group: www-data
        mode: "0755"

    - name: Deploy the nginx site configuration
      ansible.builtin.template:
        src: templates/example.conf.j2
        dest: /etc/nginx/sites-available/example.conf
        owner: root
        group: root
        mode: "0644"
      notify: Restart nginx

    - name: Enable the site
      ansible.builtin.file:
        src: /etc/nginx/sites-available/example.conf
        dest: /etc/nginx/sites-enabled/example.conf
        state: link
      notify: Restart nginx

    - name: Ensure nginx is started and enabled at boot
      ansible.builtin.systemd:
        name: nginx
        state: started
        enabled: true

    - name: Open the HTTP port in firewalld
      ansible.posix.firewalld:
        port: "{{ http_port }}/tcp"
        permanent: true
        immediate: true
        state: enabled

  handlers:
    - name: Restart nginx
      ansible.builtin.systemd:
        name: nginx
        state: restarted
```

Run it, previewing changes first:

```bash
ansible-playbook -i inventory site.yml --check --diff
ansible-playbook -i inventory site.yml
```

Running it a second time should report `ok` for every task (no `changed`), demonstrating idempotency. For structuring reusable versions of plays like this, see [roles-and-collections.md](roles-and-collections.md), and for hiding secrets used in variables, see [vault-and-secrets.md](vault-and-secrets.md).

## Related

- [Ansible Overview](index.md)
- [Inventory](inventory.md)
- [Variables and Facts](variables-and-facts.md)
- [Roles and Collections](roles-and-collections.md)
- [Best Practices](best-practices.md)

## References

- [Ansible Playbooks](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html)
- [Handlers: running operations on change](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html)
- [Conditionals](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_conditionals.html)
- [Loops](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_loops.html)
- [Blocks and error handling](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_blocks.html)
- [Controlling playbook execution: strategies and more](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_strategies.html)
- [ansible-playbook command reference](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html)
