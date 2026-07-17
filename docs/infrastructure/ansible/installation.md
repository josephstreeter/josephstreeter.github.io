---
title: Installation and Setup
description: Installing Ansible on the control node, configuring ansible.cfg, project layout, and preparing managed nodes.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: install
ms.service: ansible
keywords: ansible, installation, pipx, pip, ansible-core, ansible.cfg, control node, managed nodes, ssh
uid: docs.infrastructure.ansible.installation
---

## Installation and Setup

This page covers standing up an Ansible control node, choosing between `ansible-core` and the community package, configuring `ansible.cfg`, laying out a project repository, and preparing managed nodes for SSH-based automation.

### Control Node and Managed Nodes

Ansible uses an agentless, push-based architecture with two roles:

- **Control node** — the machine where Ansible is installed and from which playbooks and ad-hoc commands run. It requires Python 3.9 or newer and runs on Linux, macOS, or Windows Subsystem for Linux (WSL).
- **Managed nodes** — the hosts Ansible configures. They require only an SSH server and a Python interpreter (Python 3.x on modern systems). Nothing Ansible-specific is installed on them; Ansible copies modules over SSH, executes them, and removes them.

> [!IMPORTANT]
> Windows cannot serve as a control node. Ansible depends on a POSIX environment for its execution model. On Windows, install a Linux distribution under WSL 2 and run the control node from there. Windows hosts can still be *managed* nodes (over WinRM or SSH), just not the control node.

Because the control node needs outbound SSH to every managed node, place it where it has network reach to your fleet and where its private keys can be protected.

### ansible-core vs. the ansible Community Package

There are two distinct things you can install:

- **`ansible-core`** — the engine: the CLI tools (`ansible`, `ansible-playbook`, `ansible-vault`, `ansible-galaxy`, `ansible-config`), the language runtime, and the `ansible.builtin` collection. This is the minimal, fast-moving package.
- **`ansible`** — the community package: `ansible-core` plus a large curated batch of community collections (networking, cloud, `community.general`, and many more) pinned to tested versions.

Install the full `ansible` package when you want batteries included and do not want to manage collection dependencies by hand. Install `ansible-core` alone when you want a lean control node and will declare the exact collections you need in `collections/requirements.yml`.

> [!TIP]
> Use `pipx` to install either package into an isolated virtual environment. This keeps Ansible and its dependencies off your system Python and lets you upgrade or remove it cleanly.

### Installing on the Control Node

#### pipx (recommended)

`pipx` installs each Python application into its own isolated environment and exposes its CLIs on your `PATH`.

```bash
# Install pipx (Debian/Ubuntu shown; use your package manager or pip)
sudo apt update && sudo apt install -y pipx
pipx ensurepath

# Install the full community package
pipx install ansible

# ...or install ansible-core only (lean control node)
pipx install ansible-core
```

By default `pipx install ansible` exposes the console scripts declared by the package. If you later `pipx inject ansible <extra>` a dependency and want its scripts on your `PATH` as well, install with `--include-deps`:

```bash
pipx install --include-deps ansible
```

Upgrade in place with `pipx upgrade ansible`.

#### pip in a virtualenv

When you need tight control over the Python version or want to vendor Ansible alongside a project, use a virtual environment.

```bash
python3 -m venv ~/.venvs/ansible
source ~/.venvs/ansible/bin/activate
pip install --upgrade pip
pip install ansible          # or: pip install ansible-core
ansible --version
```

Activate the environment (or reference its `bin/ansible-playbook` directly) whenever you run Ansible.

> [!WARNING]
> Do not `sudo pip install ansible` into the system Python. It can overwrite distribution-managed packages and break OS tooling. Always use `pipx` or a virtual environment.

#### Distribution packages

Distro packages are convenient but often lag the upstream release. Use them when you prefer OS-managed updates over the newest features.

```bash
# Ubuntu / Debian — official Ansible PPA for current releases
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
```

On RHEL, CentOS Stream, Rocky, or Alma, enable EPEL first; Fedora ships Ansible directly.

```bash
# RHEL / CentOS Stream — enable EPEL, then install
sudo dnf install -y epel-release
sudo dnf install -y ansible

# Fedora
sudo dnf install -y ansible
```

On macOS, Homebrew provides an up-to-date formula.

```bash
# macOS
brew install ansible
```

#### Comparison of installation methods

| Method | When to use | Update path |
| --- | --- | --- |
| `pipx` | Default for most users; isolated, current, easy to remove | `pipx upgrade ansible` |
| `pip` + venv | Need a specific Python version or per-project pinning | `pip install -U ansible` inside the venv |
| Distro package (apt/dnf) | Prefer OS-managed updates; air-gapped or policy-controlled hosts | `apt`/`dnf` upgrade with the system |
| Homebrew (macOS) | macOS control node, current release desired | `brew upgrade ansible` |

### Verify the Installation and Run a First Command

Confirm the CLI is on your `PATH` and note which Python it uses:

```bash
ansible --version
```

The output reports the `ansible-core` version, the config file in effect, the collection search paths, and the Python executable. Then run an ad-hoc command against the control node itself using the `ansible.builtin.ping` module (a connectivity and Python check, not an ICMP ping):

```bash
ansible localhost -m ansible.builtin.ping
```

A successful run returns `"ping": "pong"`. This confirms the engine, its module runtime, and the local connection plugin all work before you touch any remote host.

### Configuring the Control Node: ansible.cfg

Ansible reads a single configuration file. It searches these locations in order and uses the **first** one it finds — settings from the files do **not** merge:

1. The file named by the `ANSIBLE_CONFIG` environment variable.
2. `./ansible.cfg` in the current working directory.
3. `~/.ansible.cfg` in the user's home directory.
4. `/etc/ansible/ansible.cfg` (system-wide).

Because the current-directory file wins over per-user and system files, commit a project-local `ansible.cfg` to the repository. Everyone who runs playbooks from the project root then shares identical behavior.

Generate a fully documented template to start from, and inspect what is actually in effect:

```bash
# Write a commented template of every setting (all disabled)
ansible-config init --disabled -t all > ansible.cfg.example

# Show only settings that differ from the defaults
ansible-config dump --only-changed
```

A sensible project-local `ansible.cfg`:

```ini
[defaults]
inventory = inventories/production/hosts.yml
remote_user = ansible
host_key_checking = true
forks = 20
gathering = smart
fact_caching = jsonfile
fact_caching_connection = .ansible_cache
fact_caching_timeout = 7200
interpreter_python = auto_silent
stdout_callback = yaml

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false

[ssh_connection]
pipelining = true
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
control_path = %(directory)s/%%h-%%r
```

Key choices above: `gathering = smart` with `fact_caching` avoids re-collecting facts on every run; `pipelining = true` reduces SSH round-trips (requires `requiretty` to be disabled in sudoers, which the drop-in below satisfies); and `ControlPersist` reuses SSH connections across tasks for a large speed-up.

> [!WARNING]
> Setting `host_key_checking = false` disables SSH host-key verification and exposes you to man-in-the-middle attacks. Avoid it in production. Instead, keep `host_key_checking = true` and pre-populate a managed `known_hosts` file (for example with `ssh-keyscan` during provisioning) so first connections succeed without weakening verification.

### Recommended Project Directory Layout

Prefer a self-contained, version-controlled project directory over the global `/etc/ansible` location. A repo-local layout is portable, reviewable, and reproducible.

```text
my-ansible-project/
├── ansible.cfg
├── site.yml                     # top-level playbook (imports others)
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   ├── group_vars/
│   │   │   └── all.yml
│   │   └── host_vars/
│   │       └── web01.yml
│   └── staging/
│       ├── hosts.yml
│       ├── group_vars/
│       └── host_vars/
├── group_vars/                  # inventory-independent group defaults
├── host_vars/
├── roles/                       # locally developed roles
│   └── common/
├── collections/
│   └── requirements.yml         # external collections to install
└── playbooks/
    └── webservers.yml
```

Install declared collections into the project with:

```bash
ansible-galaxy collection install -r collections/requirements.yml -p ./collections
```

> [!NOTE]
> Keeping `group_vars/` and `host_vars/` beside each inventory scopes variables to that environment, so production and staging can diverge cleanly. See [inventory.md](inventory.md) for how these directories are resolved.

### Preparing Managed Nodes and SSH

Managed nodes need a login account Ansible can use, key-based authentication, and a way to escalate privileges. Create a dedicated `ansible` service account rather than automating as `root` directly.

```bash
# On each managed node (or bake into your image/provisioning)
sudo useradd --create-home --shell /bin/bash ansible
```

From the control node, generate a key pair (if you do not already have one) and distribute the public key:

```bash
ssh-keygen -t ed25519 -C "ansible control node" -f ~/.ssh/ansible_ed25519
ssh-copy-id -i ~/.ssh/ansible_ed25519.pub ansible@managed-node.example.com
```

Grant passwordless `sudo` with a sudoers drop-in (validated by `visudo -cf` before installing) so `become` works non-interactively:

```bash
echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ansible
sudo chmod 0440 /etc/sudoers.d/ansible
sudo visudo -cf /etc/sudoers.d/ansible
```

Point Ansible at this account and escalation. Set `ansible_user` in inventory (or `remote_user` in `ansible.cfg`) and enable `become`:

```yaml
all:
  vars:
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/ansible_ed25519
    ansible_become: true
    ansible_become_method: sudo
```

Verify connectivity and privilege escalation end-to-end against the fleet:

```bash
ansible all -m ansible.builtin.ping
ansible all -m ansible.builtin.command -a "id" --become
```

> [!TIP]
> Keep managed-node preparation minimal here. Detailed inventory grouping, connection variables, and dynamic inventory are covered in [inventory.md](inventory.md); how `become` interacts with tasks is expanded in [playbooks.md](playbooks.md).

## Related

- [Ansible Overview](index.md)
- [Inventory](inventory.md)
- [Playbooks](playbooks.md)
- [Best Practices](best-practices.md)

## References

- [Installing Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [Ansible configuration settings](https://docs.ansible.com/ansible/latest/reference_appendices/config.html)
- [Sample Ansible setup and directory layout](https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html)
- [Connection methods and details](https://docs.ansible.com/ansible/latest/inventory_guide/connection_details.html)
