---
title: "Getting Started with Postfix - Quick Guide"
description: "15-minute quick start guide to get Postfix mail server up and running with basic configuration and test email sending"
author: "Joseph Streeter"
ms.date: 01/13/2026
ms.topic: quickstart
keywords: postfix, quick start, getting started, installation, basic setup, first email
---

Get Postfix mail server up and running in 15 minutes. This quick start
guide covers installation, basic configuration, and sending your first
test email.

## Prerequisites

Before starting, ensure you have:

- ✅ Ubuntu 20.04/22.04 or RHEL/CentOS 8/9 server
- ✅ Root or sudo access
- ✅ Fully qualified domain name (FQDN) configured
- ✅ Basic command-line knowledge

## Step 1: Install Postfix (5 minutes)

### Ubuntu/Debian

```bash
# Update package lists
sudo apt update

# Install Postfix
sudo apt install postfix -y

# During installation, select "Internet Site"
# Enter your domain name when prompted
```

### RHEL/CentOS/Rocky Linux

```bash
# Install Postfix
sudo dnf install postfix -y

# Enable and start Postfix
sudo systemctl enable postfix
sudo systemctl start postfix
```

### Verify Installation

```bash
# Check Postfix is running
systemctl status postfix

# Check version
postconf mail_version
```

## Step 2: Basic Configuration (5 minutes)

### Configure Hostname and Domain

```bash
# Edit main configuration file
sudo nano /etc/postfix/main.cf
```

**Essential settings:**

```bash
# /etc/postfix/main.cf

# Your mail server's hostname
myhostname = mail.example.com

# Your domain
mydomain = example.com

# Origin for locally-posted mail
myorigin = $mydomain

# Which domains to receive mail for
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain

# Network interfaces to listen on
inet_interfaces = all

# IP protocols (all = IPv4 and IPv6)
inet_protocols = all

# Trusted networks (allow relay from localhost only)
mynetworks = 127.0.0.0/8 [::1]/128

# Mailbox location
home_mailbox = Maildir/
```

**Replace `example.com` with your actual domain.**

### Restart Postfix

```bash
# Check configuration for errors
sudo postfix check

# Restart Postfix
sudo systemctl restart postfix

# Verify it's running
systemctl status postfix
```

## Step 3: Send Test Email (5 minutes)

### Install Mail Utilities

```bash
# Ubuntu/Debian
sudo apt install mailutils -y

# RHEL/CentOS
sudo dnf install mailx -y
```

### Send Test Email

```bash
# Send a test email
echo "This is a test email from Postfix" | mail -s "Test Email"
your-email@gmail.com

# Check mail queue
mailq

# View mail log
sudo tail -f /var/log/mail.log    # Ubuntu/Debian
sudo tail -f /var/log/maillog     # RHEL/CentOS
```

### Verify Email Was Sent

```bash
# Check logs for successful delivery
sudo grep "status=sent" /var/log/mail.log

# Example successful log entry:
# postfix/smtp[1234]: ABC123: to=<user@example.com>,
# relay=mx.example.com[1.2.3.4]:25,
# status=sent (250 Message accepted)
```

## Common Quick Start Issues

### Issue 1: Mail Not Sending

**Check if Postfix is running:**

```bash
systemctl status postfix
```

**Check configuration:**

```bash
postfix check
```

**View logs:**

```bash
sudo tail -50 /var/log/mail.log
```

### Issue 2: Firewall Blocking Port 25

```bash
# Ubuntu (UFW)
sudo ufw allow 25/tcp

# RHEL/CentOS (firewalld)
sudo firewall-cmd --permanent --add-service=smtp
sudo firewall-cmd --reload
```

### Issue 3: SELinux Blocking (RHEL/CentOS)

```bash
# Check SELinux status
getenforce

# If SELinux is blocking, check audit log
sudo ausearch -c postfix -m avc

# Allow postfix in SELinux
sudo setsebool -P httpd_can_network_connect 1
```

## Next Steps

Now that Postfix is running, enhance your mail server:

### 1. Configure TLS/SSL Encryption

Secure your mail server with Let's Encrypt:

```bash
# Install certbot
sudo apt install certbot -y

# Obtain certificate
sudo certbot certonly --standalone -d mail.example.com

# Configure Postfix for TLS
sudo postconf -e 'smtpd_tls_cert_file =
/etc/letsencrypt/live/mail.example.com/fullchain.pem'
sudo postconf -e 'smtpd_tls_key_file =
/etc/letsencrypt/live/mail.example.com/privkey.pem'
sudo postconf -e 'smtpd_tls_security_level = may'

# Restart Postfix
sudo systemctl restart postfix
```

See: [TLS Configuration Guide](index.md#tlsssl-encryption)

### 2. Enable SMTP Authentication

Allow authenticated users to send mail:

```bash
# Install SASL
sudo apt install sasl2-bin libsasl2-modules -y

# Configure basic SASL
sudo postconf -e 'smtpd_sasl_auth_enable = yes'
sudo postconf -e 'smtpd_relay_restrictions = permit_mynetworks,
permit_sasl_authenticated, reject_unauth_destination'

# Restart Postfix
sudo systemctl restart postfix
```

See: [SASL Authentication Guide](sasl.md)

### 3. Implement DKIM Email Signing

Improve email deliverability with DKIM:

```bash
# Install OpenDKIM
sudo apt install opendkim opendkim-tools -y

# Generate DKIM keys
sudo mkdir -p /etc/opendkim/keys/example.com
sudo opendkim-genkey -b 2048 -d example.com
-D /etc/opendkim/keys/example.com -s default -v

# Publish DNS record
sudo cat /etc/opendkim/keys/example.com/default.txt
```

See: [DKIM Configuration Guide](dkim.md)

### 4. Configure Virtual Domains

Host multiple domains:

```bash
# Configure virtual domains
sudo postconf -e 'virtual_mailbox_domains =
hash:/etc/postfix/virtual_domains'
sudo postconf -e 'virtual_mailbox_maps =
hash:/etc/postfix/vmailbox'

# Create domain configuration
echo "example.com OK" | sudo tee -a /etc/postfix/virtual_domains
sudo postmap /etc/postfix/virtual_domains
```

See: [Virtual Domains Guide](virtual-domains.md)

### 5. Set Up Anti-Spam Filtering

Protect against spam:

```bash
# Install SpamAssassin
sudo apt install spamassassin spamc -y

# Enable SpamAssassin
sudo systemctl enable spamassassin
sudo systemctl start spamassassin
```

See: [Spam Filtering Guide](spam-filtering.md)

## Quick Reference Commands

```bash
# Service Management
sudo systemctl status postfix        # Check status
sudo systemctl restart postfix       # Restart service
sudo systemctl reload postfix        # Reload configuration

# Configuration
sudo postconf -n                     # Show non-default settings
sudo postconf parameter_name         # Show specific parameter
sudo postconf -e 'param=value'       # Set parameter
sudo postfix check                   # Validate configuration

# Queue Management
mailq                                # View mail queue
postqueue -f                         # Flush queue (retry delivery)
postsuper -d ALL                     # Delete all queued mail

# Logs
sudo tail -f /var/log/mail.log      # Watch logs (Ubuntu/Debian)
sudo tail -f /var/log/maillog       # Watch logs (RHEL/CentOS)
sudo journalctl -u postfix -f       # Watch systemd logs

# Testing
echo "Test" | mail -s "Subject" user@example.com  # Send test email
telnet localhost 25                  # Test SMTP connection
```

## Deployment Scenarios

### Scenario 1: Basic Internal Mail Server

Perfect for: Internal company email, testing, development

**Configuration:**

```bash
sudo postconf -e 'myhostname = mail.internal.local'
sudo postconf -e 'mydomain = internal.local'
sudo postconf -e 'mynetworks = 127.0.0.0/8 192.168.1.0/24'
sudo postconf -e 'inet_interfaces = all'
sudo systemctl restart postfix
```

### Scenario 2: Relay Through Smart Host

Perfect for: Relay through Office 365, Gmail, SendGrid

**Configuration:**

```bash
# Configure relay host
sudo postconf -e 'relayhost = [smtp.office365.com]:587'
sudo postconf -e 'smtp_sasl_auth_enable = yes'
sudo postconf -e 'smtp_sasl_password_maps =
hash:/etc/postfix/sasl_passwd'
sudo postconf -e 'smtp_tls_security_level = encrypt'

# Create credentials file
echo "[smtp.office365.com]:587 username:password" |
sudo tee /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd*

# Restart Postfix
sudo systemctl restart postfix
```

See: [Relay Configuration Guide](relay-guide.md)

### Scenario 3: Application Mail Server

Perfect for: Web applications, automated notifications, no incoming mail

**Configuration:**

```bash
# Listen only on localhost
sudo postconf -e 'inet_interfaces = loopback-only'
sudo postconf -e 'mydestination ='

# Restrict to local applications only
sudo postconf -e 'mynetworks = 127.0.0.0/8 [::1]/128'

# Restart Postfix
sudo systemctl restart postfix
```

## Troubleshooting Tips

### Check Configuration Syntax

```bash
# Validate configuration
sudo postfix check

# Show effective configuration
sudo postconf -n
```

### View Detailed Logs

```bash
# Last 50 log entries
sudo tail -50 /var/log/mail.log

# Follow log in real-time
sudo tail -f /var/log/mail.log

# Search for errors
sudo grep -i error /var/log/mail.log

# Search for specific message ID
sudo grep "QUEUE_ID" /var/log/mail.log
```

### Test SMTP Connection

```bash
# Connect to Postfix
telnet localhost 25

# Type these commands:
EHLO test.example.com
MAIL FROM:<test@example.com>
RCPT TO:<user@example.com>
DATA
Subject: Test

Test message
.
QUIT
```

### Check Queue

```bash
# View queue
mailq

# Detailed queue info
postqueue -p

# Flush queue (retry delivery)
postqueue -f

# Delete specific message
postsuper -d QUEUE_ID

# Delete all deferred mail
postsuper -d ALL deferred
```

## Security Best Practices

Even for quick setup, implement basic security:

1. **Restrict Relay Access:**

   ```bash
   # Only allow localhost to relay
   sudo postconf -e 'mynetworks = 127.0.0.0/8 [::1]/128'
   ```

2. **Enable TLS:**

   ```bash
   # Require TLS for submission
   sudo postconf -e 'smtpd_tls_security_level = may'
   ```

3. **Configure Firewall:**

   ```bash
   # Only open necessary ports
   sudo ufw allow 25/tcp    # SMTP
   sudo ufw allow 587/tcp   # Submission (if needed)
   ```

4. **Monitor Logs:**

   ```bash
   # Check for suspicious activity daily
   sudo grep "reject" /var/log/mail.log
   ```

See: [Security Hardening Guide](security-hardening.md)

## What You've Accomplished

After completing this guide, you have:

- ✅ Installed Postfix mail server
- ✅ Configured basic settings
- ✅ Sent test emails
- ✅ Learned essential commands
- ✅ Know where to look when troubleshooting

## Complete Guides

For production deployments, explore these comprehensive guides:

- [**Postfix Complete Guide**](index.md) - Full Postfix documentation
- [**SASL Authentication**](sasl.md) - User authentication setup
- [**DKIM Email Signing**](dkim.md) - Improve deliverability
- [**Virtual Domains**](virtual-domains.md) - Multi-domain hosting
- [**Spam Filtering**](spam-filtering.md) - Anti-spam configuration
- [**Security Hardening**](security-hardening.md) - Production security
- [**Troubleshooting**](troubleshooting.md) - Problem resolution

## Additional Resources

- [Official Postfix Documentation](http://www.postfix.org/documentation.html)
- [Postfix Basic Configuration](http://www.postfix.org/BASIC_CONFIGURATION_README.html)
- [Postfix Standard Configuration](http://www.postfix.org/STANDARD_CONFIGURATION_README.html)

---

**Last Updated:** January 13, 2026

> This quick start gets you operational fast. For production deployments,
> review the complete guides to implement security, authentication, and
> monitoring.
