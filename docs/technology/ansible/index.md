# Ansible

## Ansible Setup

Install Ansible

```bash
apt update && apt upgrade -y
apt install ansible -y
```

Create directory to store ansible related files

[Ansible Sample Setup](https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html)

```bash
sudo mkdir /etc/ansible

```

## Populate Inventory

Enter hosts by role in an inventory file. The file can be an INI or YAML.

YAML:

```yaml
mail.example.com

[webservers]
foo.example.com
bar.example.com

[dbservers]
one.example.com
two.example.com
three.example.com
```

INI:

```text
mail.example.com

[webservers]
foo.example.com
bar.example.com

[dbservers]
one.example.com
two.example.com
three.example.com
```

## Create Playbook

Create a playbook.

```bash

```

## Configure Remote Hosts

Linux Hosts

Create user account

```bash
sudo useradd -m ansi
sudo password ansi
```

<https://serversforhackers.com/c/create-user-in-ansible>

Copy SSH Key

```bash
ssh-copy-id ~/.ssh/<key> ansi@<host>
```
