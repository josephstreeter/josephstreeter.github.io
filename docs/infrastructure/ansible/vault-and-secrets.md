---
title: Vault and Secrets Management
description: Protecting sensitive data with Ansible Vault - encrypting files and variables, vault IDs, password sources, and integrating external secret managers.
author: Joseph Streeter
ms.author: josephstreeter
ms.date: 07/17/2026
ms.topic: how-to
ms.service: ansible
keywords: ansible vault, secrets, encrypt_string, vault-id, ansible-vault, no_log, secret management
uid: docs.infrastructure.ansible.vault-and-secrets
---

## Vault and Secrets Management

Automation inevitably touches secrets: database passwords, API tokens, TLS private keys, cloud credentials, and SSH keys. Ansible Vault encrypts this sensitive data so it can live in the same repository as your playbooks and roles without exposing it in plaintext. This page covers encrypting files and individual values, supplying vault passwords at runtime, using vault IDs for multi-environment setups, hardening practices, and integrating external secret managers for dynamic secrets.

### Why Vault

Committing secrets in plaintext to version control is one of the most common and damaging security mistakes in infrastructure automation. Once a plaintext secret lands in git history, it is effectively permanent — cloning, forks, and CI logs all propagate it, and rotation becomes the only remedy.

Ansible Vault solves this by encrypting content with a symmetric passphrase using **AES256** (via the cryptography library). The encrypted blob is safe to commit: it is opaque without the password, yet it travels alongside the code that consumes it, so a single checkout gives you both the automation and its (encrypted) secrets. Decryption happens transparently in memory at runtime once you supply the vault password.

> [!IMPORTANT]
> Vault protects data **at rest** in your repository. It is only as strong as the password protecting it. A weak, reused, or committed vault password defeats the entire mechanism.

### Encrypting Whole Files

The simplest model is to encrypt an entire YAML vars file. Everything in the file is ciphertext on disk, and Ansible decrypts it during a play.

```bash
# Create a new encrypted file (opens $EDITOR, writes ciphertext on save)
ansible-vault create group_vars/production/vault.yml

# Encrypt an existing plaintext file in place
ansible-vault encrypt group_vars/production/vault.yml

# Edit an encrypted file (decrypts to a temp file, re-encrypts on save)
ansible-vault edit group_vars/production/vault.yml

# View decrypted contents without editing (read-only)
ansible-vault view group_vars/production/vault.yml

# Permanently decrypt back to plaintext (avoid committing the result)
ansible-vault decrypt group_vars/production/vault.yml

# Change the password on an already-encrypted file
ansible-vault rekey group_vars/production/vault.yml
```

By convention these encrypted files are dedicated vars files named `vault.yml`, placed under `group_vars/<group>/` or `host_vars/<host>/`. Splitting a group's variables into a plaintext `vars.yml` and an encrypted `vault.yml` keeps the encrypted surface small and lets both files be auto-loaded by inventory group name. See [variables-and-facts.md](variables-and-facts.md) for how `group_vars` and `host_vars` are discovered.

An encrypted file begins with a recognizable header, which is how Ansible and reviewers know it is vaulted:

```text
$ANSIBLE_VAULT;1.1;AES256
66386439653236336462626566653063336164663966303231363934653561363
32303431323639343266393835343430656665356532636239326439343635313...
```

### Encrypting Single Values (Inline)

Sometimes you want a mostly readable vars file with only a few sensitive values encrypted. `encrypt_string` produces a self-contained `!vault` block you paste directly into a YAML file.

```bash
ansible-vault encrypt_string 'S3cr3t-P@ssw0rd!' --name 'vault_db_password'
```

The output is a YAML key with an encrypted value:

```yaml
vault_db_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  62313365396662343061393464336163383437336164653832383661323736303
  3623562373933353538653062386633663762363238613938616337623632643...
```

#### The plaintext-references-vaulted convention

A widely used pattern is to keep an **unencrypted variable with a readable name** that references a **vaulted variable** holding the actual secret. Put the readable names in `vars.yml` and the encrypted values in `vault.yml`:

```yaml
# group_vars/production/vars.yml  (committed in plaintext)
db_password: "{{ vault_db_password }}"
api_token: "{{ vault_api_token }}"
```

```yaml
# group_vars/production/vault.yml  (encrypted with ansible-vault)
vault_db_password: S3cr3t-P@ssw0rd!
vault_api_token: ghp_xxxxxxxxxxxxxxxxxxxx
```

Why bother with the indirection instead of referencing `vault_db_password` everywhere?

- **Readable playbooks** — tasks reference `db_password`, not an opaque `vault_`-prefixed name, keeping intent clear.
- **Grep-able secrets inventory** — you can `grep -r vault_ group_vars/` to see exactly which variables are secret and where they are consumed, without decrypting anything.
- **A single encrypted file per scope** — all real secrets live in one small `vault.yml`, so rekeying and auditing target one file rather than scattered `!vault` blocks.

> [!TIP]
> Prefix every vaulted variable name with `vault_`. The convention makes secrets self-documenting and lets linters or review scripts flag any secret referenced without going through a `vault_` variable.

### Running Playbooks with Vaulted Content

When a play loads vaulted data, Ansible needs the password. There are several ways to supply it.

```bash
# Prompt interactively for the vault password
ansible-playbook site.yml --ask-vault-pass

# Read the password from a file (must not be committed)
ansible-playbook site.yml --vault-password-file ~/.vault_pass.txt

# The password "file" can be an executable script that prints the password to stdout
ansible-playbook site.yml --vault-password-file ./scripts/get-vault-pass.sh
```

If the value passed to `--vault-password-file` is executable, Ansible runs it and reads the password from stdout. This is the hook for fetching the key from a keychain, an environment variable, or a secret manager at runtime:

```bash
#!/usr/bin/env bash
# get-vault-pass.sh — fetch the vault password from an external source
set -euo pipefail
security find-generic-password -a "$USER" -s ansible-vault -w   # macOS Keychain example
```

You can avoid passing the flag every time by configuring the password source. Precedence favors the CLI flag, then the environment variable, then `ansible.cfg`:

```ini
# ansible.cfg
[defaults]
vault_password_file = ~/.vault_pass.txt
```

```bash
# Or via environment variable
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt
```

> [!WARNING]
> A vault password file (or the script it points to) must never be committed to the repository. Add `.vault_pass*`, `*vault*pass*`, and similar patterns to `.gitignore`, and restrict permissions with `chmod 600`.

### Vault IDs

Vault IDs let you manage **multiple, independently-passworded vaults** in one project — typically one per environment. Each encrypted blob records the ID that produced it, and Ansible matches passwords to blobs by ID.

```bash
# Encrypt a string tagged with a specific vault id
ansible-vault encrypt_string --vault-id prod@prompt 'prod-secret' --name 'vault_db_password'

# Encrypt a file using an existing vault id when several are configured
ansible-vault encrypt --encrypt-vault-id prod group_vars/production/vault.yml

# Run a play, prompting for the dev vault password
ansible-playbook site.yml --vault-id dev@prompt

# Supply multiple vault ids at once (a mix of files and prompts is fine)
ansible-playbook site.yml \
  --vault-id dev@vault-pass-dev.txt \
  --vault-id prod@vault-pass-prod.txt
```

The syntax is `label@source`, where `source` is `prompt`, a password file, or an executable script. When multiple IDs are provided, Ansible tries the ID that matches each encrypted blob first, then falls back to trying the others — so passing every environment's ID during a run still works, though matching IDs keeps it fast and unambiguous.

Common `ansible-vault` subcommands:

| Subcommand | Purpose |
| --- | --- |
| `create` | Create and open a new encrypted file in `$EDITOR` |
| `encrypt` | Encrypt an existing plaintext file in place |
| `edit` | Decrypt to a temp file, edit, re-encrypt on save |
| `view` | Print decrypted contents (read-only) |
| `decrypt` | Permanently convert an encrypted file back to plaintext |
| `rekey` | Change the password on an encrypted file |
| `encrypt_string` | Produce an inline `!vault` block for a single value |

> [!NOTE]
> Configure default IDs in `ansible.cfg` with `vault_identity_list = dev@vault-pass-dev.txt, prod@vault-pass-prod.txt` so routine runs need no extra flags.

### Best Practices

- **Never commit the vault password.** Keep it out of git entirely; distribute it through a secret store, a CI secret variable, or a team password manager.
- **Encrypt values, not names.** Store variable names in plaintext (`vars.yml`) and only the values in `vault.yml`. This keeps diffs and reviews meaningful while secrets stay opaque.
- **One vault password per environment.** Separate dev, staging, and production passwords with vault IDs so a leaked dev password never exposes production.
- **Rotate with `rekey`.** When a password or team member changes, `ansible-vault rekey` re-encrypts under a new password. Rotate the underlying secrets too if exposure is suspected.
- **Add `no_log: true` to tasks handling secrets.** Ansible echoes task arguments and results; a secret passed to a module can otherwise appear in stdout, `-v` output, or CI logs.
- **Keep vault files small and dedicated.** A focused `vault.yml` per scope limits blast radius, simplifies rekeying, and makes audits tractable.

```yaml
- name: Configure application database credentials
  ansible.builtin.template:
    src: app.conf.j2
    dest: /etc/app/app.conf
    owner: app
    mode: "0600"
  no_log: true   # prevents the rendered secret from leaking into logs
```

> [!CAUTION]
> `no_log: true` suppresses output for the whole task, which also hides useful error detail during debugging. Add it deliberately to tasks that genuinely handle secrets rather than blanket-applying it. See [best-practices.md](best-practices.md) for broader hardening guidance.

### External Secret Managers

Vault stores secrets **at rest, in git**. That is ideal for values that change rarely and belong with the code. For **dynamic, centrally-managed, or short-lived** secrets — rotated credentials, cloud IAM tokens, leased database passwords — fetch them **at runtime** with a lookup plugin instead of (or alongside) Vault. Nothing sensitive is written to disk; the secret is retrieved fresh on each run.

| Backend | Collection | Plugin / lookup |
| --- | --- | --- |
| HashiCorp Vault | `community.hashi_vault` | `community.hashi_vault.vault_kv2_get` |
| AWS Secrets Manager | `amazon.aws` | `amazon.aws.aws_secret` |
| Azure Key Vault | `azure.azcollection` | `azure.azcollection.azure_keyvault_secret` |

A minimal HashiCorp Vault KV v2 lookup:

```yaml
- name: Retrieve a secret from HashiCorp Vault at runtime
  hosts: appservers
  vars:
    db_password: >-
      {{ (lookup('community.hashi_vault.vault_kv2_get',
                 'app/db',
                 engine_mount_point='secret')).secret.password }}
  tasks:
    - name: Write database configuration
      ansible.builtin.template:
        src: db.conf.j2
        dest: /etc/app/db.conf
        mode: "0600"
      no_log: true
```

Authentication to the backend (a Vault token, an AWS IAM role, an Azure service principal) is typically supplied through environment variables or the collection's parameters. Install these collections as described in [roles-and-collections.md](roles-and-collections.md).

**The tradeoff:**

- **Vault-at-rest (in git)** — self-contained, works offline, no external dependency at runtime; but secrets rotate manually and every checkout carries the encrypted blob.
- **Secret-manager-at-runtime** — centralized rotation, fine-grained access policies, audit trails, and no secret material in the repository; but adds a runtime dependency and requires the control node to authenticate to the backend on every run.

> [!TIP]
> Many teams combine both: Vault protects the bootstrap credential (for example, the token used to authenticate to HashiCorp Vault), while all downstream application secrets are fetched dynamically at runtime.

## Related

- [Variables and Facts](variables-and-facts.md) — where `group_vars` and `host_vars` vault files are loaded from.
- [Best Practices](best-practices.md) — broader security and repository hygiene guidance.
- [Roles and Collections](roles-and-collections.md) — installing the collections that provide secret-manager lookups.
- [Playbooks](playbooks.md) — running plays that consume vaulted variables.

## References

- [Encrypting content with Ansible Vault](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
- [ansible-vault command reference](https://docs.ansible.com/ansible/latest/cli/ansible-vault.html)
- [Managing vault passwords and vault IDs](https://docs.ansible.com/ansible/latest/vault_guide/vault_managing_passwords.html)
- [community.hashi_vault collection](https://docs.ansible.com/ansible/latest/collections/community/hashi_vault/index.html)
- [amazon.aws.aws_secret lookup](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_secret_lookup.html)
