---
title: "Docker Installation Guide"
description: "Complete guide to installing Docker on Linux, Windows, and macOS with verification steps and troubleshooting."
author: "Joseph Streeter"
ms.date: "2025-07-17"
ms.topic: "how-to"
ms.service: "containers"
keywords: ["Docker", "Containers", "Installation", "Ubuntu", "Debian", "Windows", "macOS"]
---

Docker is a platform for developing, shipping, and running applications in containers. This guide covers installing Docker on different operating systems.

## Install

## [Linux](#tab/linux)

### Ubuntu and Debian

Follow these steps to install Docker on Ubuntu or Debian-based distributions:

1. Update the apt package index and install packages to allow apt to use a repository over HTTPS:

    ```bash
    sudo apt-get update
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    ```

2. Add Docker's official GPG key:

    ```bash
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    ```

3. Set up the repository:

    ```bash
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ```

4. Update the apt package index and install Docker:

    ```bash
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ```

5. Add your user to the docker group to run Docker commands without sudo:

    ```bash
    sudo usermod -aG docker $USER
    ```

    > [!NOTE]
    > Log out and back in for this change to take effect.

6. Verify the installation:

    ```bash
    docker --version
    docker run hello-world
    ```

### CentOS/RHEL

1. Install required packages:

    ```bash
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    ```

2. Add the Docker repository:

    ```bash
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    ```

3. Install Docker:

    ```bash
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ```

4. Start and enable Docker:

    ```bash
    sudo systemctl start docker
    sudo systemctl enable docker
    ```

5. Add your user to the docker group:

    ```bash
    sudo usermod -aG docker $USER
    ```

6. Verify the installation:

    ```bash
    docker --version
    docker run hello-world
    ```

## [Windows](#tab/windows)

### Windows 10/11 Professional, Enterprise, or Education

1. **System Requirements**:
   - Windows 10/11 64-bit: Pro, Enterprise, or Education (Build 16299 or later)
   - Hyper-V and Containers Windows features must be enabled

2. **Download and Install**:
   - Download [Docker Desktop for Windows](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe)
   - Double-click the installer to run it
   - Follow the installation wizard

3. **Post-Installation**:
   - Start Docker Desktop from the Windows Start menu
   - Verify the installation by running in PowerShell or Command Prompt:

     ```powershell
     docker --version
     docker run hello-world
     ```

### Windows 10 Home

1. **System Requirements**:
   - Windows 10 64-bit Home (Build 19041 or later)
   - WSL 2 must be installed

2. **Install WSL 2**:
   - Open PowerShell as Administrator and run:

     ```powershell
     wsl --install
     ```

   - Restart your computer

3. **Download and Install Docker Desktop**:
   - Download [Docker Desktop for Windows](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe)
   - Double-click the installer to run it
   - Follow the installation wizard
   - Ensure "Use WSL 2 instead of Hyper-V" is checked

4. **Verify Installation**:

   ```powershell
   docker --version
   docker run hello-world
   ```

## [Mac OS](#tab/macos)

### macOS

1. **System Requirements**:
   - macOS 11 (Big Sur) or newer for Intel Macs
   - macOS 12 (Monterey) or newer for Apple Silicon (M1/M2) Macs

2. **Download and Install**:
   - Download [Docker Desktop for Mac](https://desktop.docker.com/mac/main/amd64/Docker.dmg) (Intel) or [Docker Desktop for Apple Silicon](https://desktop.docker.com/mac/main/arm64/Docker.dmg) (M1/M2)
   - Open the downloaded `.dmg` file
   - Drag the Docker icon to the Applications folder
   - Open Docker from the Applications folder

3. **Verify Installation**:
   - Open Terminal and run:

     ```bash
     docker --version
     docker run hello-world
     ```

---

## Troubleshooting

### Common Issues

#### Repository does not have a Release file

If you encounter an error about missing Release files on Debian-based systems:

- Check that the correct distribution name is used in the repository URL
- See [Proxmox Docker Repository Troubleshooting](../../proxmox/troubleshooting.md) for a specific example

#### Docker daemon not running

If you get "Cannot connect to the Docker daemon" errors:

- Check if the Docker service is running: `sudo systemctl status docker`
- Start the service if needed: `sudo systemctl start docker`

#### Permission denied

If you get "permission denied" errors:

- Make sure your user is in the docker group: `groups`
- If not, add it and log out/in: `sudo usermod -aG docker $USER`

## Next Steps

- [Docker Quickstart Tutorial](quickstart.md)
- [Working with Docker Containers](containers.md)
- [Docker Compose for Multi-Container Applications](dockercompose.md)
