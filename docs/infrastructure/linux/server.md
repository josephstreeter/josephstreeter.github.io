---
title: Linux Server Administration
description: Comprehensive guide to Linux server administration, focusing on Debian and Ubuntu server environments for enterprise and cloud deployments.
author: Joseph Streeter
ms.author: jstreeter
ms.date: 07/08/2025
ms.topic: article
ms.service: linux
keywords: Linux server, Ubuntu server, Debian server, system administration, enterprise, cloud, infrastructure
uid: docs.infrastructure.linux.server
---

Linux servers form the backbone of modern IT infrastructure, powering everything from web applications to enterprise databases. This guide focuses on server administration using Debian and Ubuntu distributions.

## Server Editions Overview

### Ubuntu Server

Ubuntu Server is designed for enterprise environments with:

- **Minimal Installation**: No GUI by default, optimized for server workloads
- **Long-Term Support (LTS)**: 5-year support lifecycle
- **Enterprise Features**: Professional support and security updates
- **Cloud Integration**: First-class support for major cloud providers
- **Container Ready**: Built-in Docker and Kubernetes support

### Debian Server

Debian Server offers exceptional stability with:

- **Rock-Solid Stability**: Extensively tested packages
- **Long Release Cycles**: Focus on stability over cutting-edge features
- **Minimal Resource Usage**: Efficient resource utilization
- **Universal Architecture**: Supports multiple hardware platforms
- **Pure Open Source**: Strict adherence to free software principles

## Installation and Initial Setup

### Ubuntu Server Installation

```bash
# Download Ubuntu Server LTS
# https://ubuntu.com/download/server

# During installation, select:
# - Minimal installation
# - OpenSSH server
# - Docker (optional)

# First boot configuration
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git vim htop
```

### Debian Server Installation

```bash
# Download Debian stable
# https://www.debian.org/CD/

# Post-installation setup
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git vim htop sudo

# Add user to sudo group
sudo usermod -aG sudo username
```

### Initial Security Hardening

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install security updates automatically
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades

# Configure SSH security
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
# Set: PasswordAuthentication no (after setting up SSH keys)
# Set: Port 2222 (optional)

sudo systemctl restart ssh

# Configure firewall
sudo ufw enable
sudo ufw allow 2222/tcp  # SSH (if changed port)
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
```

## System Administration

### User Management

```bash
# Create system user for applications
sudo adduser --system --no-create-home --group appuser

# Create regular user
sudo adduser username
sudo usermod -aG sudo username

# SSH key setup
sudo -u username ssh-keygen -t rsa -b 4096 -C "user@example.com"
sudo -u username mkdir -p /home/username/.ssh
sudo -u username chmod 700 /home/username/.ssh

# Add public key to authorized_keys
sudo -u username nano /home/username/.ssh/authorized_keys
sudo -u username chmod 600 /home/username/.ssh/authorized_keys
```

### Service Management

```bash
# List all services
systemctl list-units --type=service

# Service operations
sudo systemctl start service-name
sudo systemctl stop service-name
sudo systemctl restart service-name
sudo systemctl reload service-name

# Enable/disable services
sudo systemctl enable service-name
sudo systemctl disable service-name

# View service logs
sudo journalctl -u service-name
sudo journalctl -u service-name -f  # Follow logs
```

### Process Management

```bash
# View running processes
ps aux
top
htop

# Kill processes
kill PID
killall process-name
pkill -f pattern

# Background processes
nohup command &
screen -S session-name
tmux new-session -d -s session-name
```

## Network Configuration

### Static IP Configuration

#### Ubuntu Server (Netplan)

```yaml
# /etc/netplan/00-installer-config.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

```bash
# Apply configuration
sudo netplan apply
```

#### Debian Server (interfaces)

```bash
# /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
```

```bash
# Apply configuration
sudo systemctl restart networking
```

### DNS Configuration

```bash
# Configure DNS servers
sudo nano /etc/resolv.conf
# Add:
# nameserver 8.8.8.8
# nameserver 8.8.4.4

# Make changes persistent (Ubuntu)
sudo nano /etc/systemd/resolved.conf
# Set: DNS=8.8.8.8 8.8.4.4
sudo systemctl restart systemd-resolved
```

## Web Server Setup

### Apache HTTP Server

```bash
# Install Apache
sudo apt install -y apache2

# Enable and start Apache
sudo systemctl enable apache2
sudo systemctl start apache2

# Configure firewall
sudo ufw allow 'Apache Full'

# Basic configuration
sudo nano /etc/apache2/sites-available/000-default.conf

# Enable modules
sudo a2enmod rewrite
sudo a2enmod ssl
sudo systemctl restart apache2

# Virtual host example
sudo nano /etc/apache2/sites-available/example.com.conf
```

Example virtual host:

```apache
<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com
    DocumentRoot /var/www/example.com
    ErrorLog ${APACHE_LOG_DIR}/example.com_error.log
    CustomLog ${APACHE_LOG_DIR}/example.com_access.log combined
</VirtualHost>
```

### Nginx Web Server

```bash
# Install Nginx
sudo apt install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Configure firewall
sudo ufw allow 'Nginx Full'

# Basic configuration
sudo nano /etc/nginx/sites-available/default

# Create new site
sudo nano /etc/nginx/sites-available/example.com
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Example Nginx configuration:

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/example.com;
    index index.html index.php;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
}
```

## Database Servers

### MySQL/MariaDB

```bash
# Install MariaDB
sudo apt install -y mariadb-server

# Secure installation
sudo mysql_secure_installation

# Connect to database
sudo mysql -u root -p

# Create database and user
CREATE DATABASE app_db;
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON app_db.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;
```

### PostgreSQL

```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Switch to postgres user
sudo -u postgres psql

# Create database and user
CREATE DATABASE app_db;
CREATE USER appuser WITH PASSWORD 'strong_password';
GRANT ALL PRIVILEGES ON DATABASE app_db TO appuser;
```

## Container Services

### Docker Installation

```bash
# Install Docker
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker
sudo apt update
sudo apt install -y docker-ce

# Add user to docker group
sudo usermod -aG docker $USER

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker
```

### Docker Compose

```bash
# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Example docker-compose.yml
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: appdb
    volumes:
      - db_data:/var/lib/mysql
volumes:
  db_data:
```

## Monitoring and Maintenance

### System Monitoring

```bash
# System resources
htop
iotop
free -h
df -h

# Service status
sudo systemctl status service-name
sudo journalctl -u service-name -f

# Log analysis
sudo tail -f /var/log/syslog
sudo tail -f /var/log/auth.log
sudo tail -f /var/log/apache2/access.log
```

### Automated Monitoring with Netdata

```bash
# Install Netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Configure firewall
sudo ufw allow 19999/tcp

# Access: http://server-ip:19999
```

### Backup Strategies

```bash
# Database backup
mysqldump -u root -p database_name > backup.sql
pg_dump -U postgres database_name > backup.sql

# File system backup with rsync
rsync -av --exclude='/proc/*' --exclude='/sys/*' / /backup/destination/

# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup"
DB_NAME="app_db"

# Create backup directory
mkdir -p $BACKUP_DIR/$DATE

# Database backup
mysqldump -u root -p$DB_PASS $DB_NAME > $BACKUP_DIR/$DATE/db_backup.sql

# File backup
tar -czf $BACKUP_DIR/$DATE/files_backup.tar.gz /var/www/

# Keep only last 7 days of backups
find $BACKUP_DIR -type d -mtime +7 -exec rm -rf {} \;
```

## Security Best Practices

### Firewall Configuration

```bash
# UFW (Uncomplicated Firewall)
sudo ufw status
sudo ufw enable

# Allow specific services
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow from 192.168.1.0/24 to any port 3306

# Deny specific traffic
sudo ufw deny 23
sudo ufw deny from 192.168.1.100
```

### Fail2ban

```bash
# Install Fail2ban
sudo apt install -y fail2ban

# Configure
sudo nano /etc/fail2ban/jail.local
```

Example jail.local:

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
```

### SSL/TLS with Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-apache

# Get SSL certificate
sudo certbot --apache -d example.com -d www.example.com

# Automatic renewal
sudo crontab -e
# Add: 0 2 * * * /usr/bin/certbot renew --quiet
```

## Performance Optimization

### System Optimization

```bash
# Adjust swappiness
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf

# File descriptor limits
echo 'fs.file-max = 65536' | sudo tee -a /etc/sysctl.conf

# Network optimization
echo 'net.core.rmem_max = 16777216' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' | sudo tee -a /etc/sysctl.conf

# Apply changes
sudo sysctl -p
```

### Database Optimization

```bash
# MySQL optimization
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

# Add optimizations:
# innodb_buffer_pool_size = 256M
# innodb_log_file_size = 64M
# query_cache_size = 64M
# max_connections = 100

sudo systemctl restart mysql
```

## Troubleshooting

### Common Issues

> [!WARNING]
> Always backup your system before making significant changes.

**Service won't start:**

```bash
sudo systemctl status service-name
sudo journalctl -u service-name
```

**High CPU usage:**

```bash
top
htop
ps aux --sort=-%cpu
```

**Disk space issues:**

```bash
df -h
du -h /var/log/
sudo apt autoremove
sudo apt autoclean
```

**Network connectivity:**

```bash
ping 8.8.8.8
nslookup example.com
netstat -tuln
ss -tuln
```

### Log Analysis

```bash
# System logs
sudo tail -f /var/log/syslog
sudo tail -f /var/log/auth.log

# Application logs
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/log/nginx/error.log

# Search logs
sudo grep -i "error" /var/log/syslog
sudo grep -i "failed" /var/log/auth.log
```

## Automation and Scripting

### Bash Scripting

```bash
#!/bin/bash
# System maintenance script

# Update packages
sudo apt update && sudo apt upgrade -y

# Clean package cache
sudo apt autoremove -y
sudo apt autoclean

# Clear old logs
sudo journalctl --vacuum-time=7d

# Backup important files
rsync -av /etc/ /backup/etc/
rsync -av /var/www/ /backup/www/

echo "Maintenance completed: $(date)"
```

### Cron Jobs

```bash
# Edit crontab
crontab -e

# Examples:
# Daily backup at 2 AM
0 2 * * * /home/user/backup.sh

# Weekly system update
0 3 * * 0 sudo apt update && sudo apt upgrade -y

# Monthly log cleanup
0 1 1 * * sudo journalctl --vacuum-time=30d
```

## Cloud Integration

### AWS Integration

```bash
# Install AWS CLI
sudo apt install -y awscli

# Configure AWS
aws configure

# EC2 instance metadata
curl http://169.254.169.254/latest/meta-data/instance-id
curl http://169.254.169.254/latest/meta-data/public-ipv4
```

### Azure Integration

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Get instance metadata
curl -H "Metadata:true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
```

## High Availability

### Load Balancing with HAProxy

```bash
# Install HAProxy
sudo apt install -y haproxy

# Configure HAProxy
sudo nano /etc/haproxy/haproxy.cfg
```

Example HAProxy configuration:

```txt
global
    daemon

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend web_frontend
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    server web1 192.168.1.10:80 check
    server web2 192.168.1.11:80 check
```

### Database Replication

```bash
# MySQL Master-Slave replication
# Master configuration
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
# Add:
# server-id = 1
# log-bin = mysql-bin
# binlog-do-db = app_db

# Slave configuration
# server-id = 2
# relay-log = mysql-relay-bin
# replicate-do-db = app_db
```

## Resources

### Documentation

- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [Debian Administrator's Handbook](https://debian-handbook.info/index.md)
- [Linux System Administrator's Guide](https://tldp.org/LDP/sag/html/index.md)

### Tools

- **Monitoring**: Netdata, Nagios, Zabbix
- **Configuration Management**: Ansible, Puppet, Chef
- **Container Orchestration**: Kubernetes, Docker Swarm
- **Backup**: Bacula, Amanda, Duplicity

### Best Practices

1. **Regular Updates**: Keep system and packages updated
2. **Security Hardening**: Follow security best practices
3. **Monitoring**: Implement comprehensive monitoring
4. **Backups**: Regular, tested backup procedures
5. **Documentation**: Document configurations and procedures
6. **Automation**: Automate routine tasks
7. **Testing**: Test changes in staging environment first

Linux servers provide a robust, secure, and scalable foundation for modern applications and services. With proper configuration, monitoring, and maintenance, they can deliver exceptional performance and reliability for enterprise workloads.
