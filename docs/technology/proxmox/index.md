# Proxmox

The Proxmox Virtual Environment is a complete, open-source server management platform for enterprise virtualization. It tightly integrates the KVM hypervisor and Linux Containers (LXC), software-defined storage and networking functionality, on a single platform. With the integrated web-based user interface you can manage VMs and containers, high availability for clusters, or the integrated disaster recovery tools with ease.

## Installation

\<install steps>

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

Comment out this line:

```bash
# deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise
```

The following script will execute the above tasks in one step.

```bash
echo "Configure the 'non-subscription' repositories for pve and ceph...."
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | tee -a /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription" | tee -a /etc/apt/sources.list

echo "Disable the Enterprise repositories for pve and ceph...."
sed -i '/^deb/s/^/# /' /etc/apt/sources.list.d/pve-enterprise.list
sed -i '/^deb/s/^/# /' /etc/apt/sources.list.d/ceph.list

echo "Disable the subscription pop-up...."
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy.service
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

## Virtual Machine Setup

There are a number of different ways to create a template in Proxmox that can then be deployed using Terraform or CLI (qm).

### Create Cloud-Init Clone

The following script will download the Cloud-Init image and create a VM template from it.

```bash
VMID=9000
TEMPLATENAME="debian12-cloudinit"
TEMPLATEURL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
FILE="debian-12-genericcloud-amd64.qcow2"

pushd /root/
if [ -f $FILE ]; then
   echo "Image ($FILE) exists."
else
   echo "image ($FILE) does not exist. Downloading...."
   wget $TEMPLATEURL
fi
popd

qm create $VMID --name $TEMPLATENAME
qm create $VMID --name $TEMPLATENAME
qm set $VMID --scsi0 local-lvm:0,import-from=/root/$file
qm template $VMID
```

### Qemu Guest Agent Setup

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
