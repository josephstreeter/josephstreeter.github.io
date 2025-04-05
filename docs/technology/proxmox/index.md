# Proxmox

The Proxmox Virtual Environment is a complete, open-source server management platform for enterprise virtualization. It tightly integrates the KVM hypervisor and Linux Containers (LXC), software-defined storage and networking functionality, on a single platform. With the integrated web-based user interface you can manage VMs and containers, high availability for clusters, or the integrated disaster recovery tools with ease.

## Installation

## Post-Installation

After the installation is complete, there are some configuration changes that should be performed to ensure the Proxmox server is secure.

### Non-Production APT Repository

To access non-production Proxmox packages, you need to modify your repository sources. Edit the sources.list file:

```bash
vi /etc/apt/sources.list
```

Add the following lines to the bottom of the file:

```bash
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
```

Next, disable the production repository by commenting out these lines in pve-enterprise.list:

```bash
vi /etc/apt/sources.list.d/pve-enterprise.list
```

Comment out this line:

```bash
#deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
```

Similarly, disable the enterprise repository for Ceph by commenting out these lines in ceph.list:

```bash
vi /etc/apt/sources.list.d/ceph.list
```

### VLAN Configuration

After your server reboots, you can configure VLAN support in the Proxmox web UI:

- Select server.
- Go to “Network” in the menu.
- Select the Linux bridge (vmbro#).
- Click “Edit” at the top of the window.
- Check the box that says “VLAN aware.”
- Press “OK.”

### Disable Subscription Popup

To remove the subscription popup, run the following command:

```bash
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
```

Afterward, reboot your server, log out of the Proxmox web GUI, clear your browser cache, and then log back in.

## Qemu Guest Agent Setup

1. Enable Qemu Guest Agent
    - In the Proxmox web interface, select your VM.
    - Go to "Hardware" > "Add" > "QEMU Guest Agent".
    - Start the VM if it's not already running.

2. Qemu Guest Agent Install

    Debian/Ubuntu

    ```bash
    apt update
    apt install qemu-guest-agent
    ```

3. Enable and Start the Qemu Agent

    ```bash
    systemctl enable qemu-guest-agent
    systemctl start qemu-guest-agent
    ```

4. Verify Installation

    To verify that the QEMU Guest Agent is running:

    ```bash
    systemctl status qemu-guest-agent
    ```

Complete script to install, enable, and start the Qemu guest agent.

```bash
apt update
apt install qemu-guest-agent

systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent
```
