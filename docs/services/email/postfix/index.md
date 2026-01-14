---
title: "Postfix Mail Server - Complete Guide"
description: "Comprehensive guide for deploying, configuring, and managing Postfix mail transfer agent for enterprise email services with security best practices"
author: "Joseph Streeter"
ms.date: 01/13/2026
ms.topic: overview
keywords: postfix, mail server, MTA, email, SMTP, mail transfer agent, configuration, security
---

Postfix is a powerful, flexible, and secure mail transfer agent (MTA) used for routing and delivering email. This comprehensive guide covers deploying, configuring, and managing Postfix in enterprise environments.

## Overview

Postfix is a free and open-source mail transfer agent that routes and delivers electronic mail. Originally developed by Wietse Venema as an alternative to Sendmail, Postfix aims to be fast, easy to administer, and secure while maintaining compatibility with Sendmail.

### Why Postfix?

**Security by Design:**

- Modular architecture with privilege separation
- Each daemon runs with minimum required privileges
- No direct root access for mail handling processes
- Multiple security layers and sanity checks

**Performance:**

- Handles high email volumes efficiently
- Connection caching for frequent destinations
- Queue management optimized for throughput
- Minimal resource consumption

**Ease of Administration:**

- Human-readable configuration files
- Comprehensive documentation
- Extensive logging for troubleshooting
- Gradual learning curve from simple to complex configurations

**Standards Compliance:**

- Full RFC compliance for SMTP, MIME, and related standards
- Support for modern extensions (STARTTLS, AUTH, etc.)
- Interoperability with all major mail systems
- IPv6 ready

### Postfix Architecture

```text
┌──────────────────────────────────────────────────────────────┐
│                         Postfix System                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                │
│  │  smtpd   │───→│  cleanup │───→│  qmgr    │                │
│  │(receive) │    │ (rewrite)│    │ (queue)  │                │
│  └──────────┘    └──────────┘    └────┬─────┘                │
│       ↑                                │                     │
│       │                                ↓                     │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                │
│  │   smtp   │←───│  local   │←───│  pickup  │                │
│  │ (deliver)│    │ (deliver)│    │ (submit) │                │
│  └──────────┘    └──────────┘    └──────────┘                │
│       │                                                      │
└───────┼──────────────────────────────────────────────────────┘
        │
        ↓
   External MTA
```

**Key Components:**

- **smtpd** - SMTP server daemon (receives incoming mail)
- **smtp** - SMTP client daemon (sends outgoing mail)
- **pickup** - Receives mail from local sendmail command
- **cleanup** - Rewrites addresses, adds missing headers
- **qmgr** - Queue manager (schedules mail delivery)
- **local** - Local mail delivery agent
- **virtual** - Virtual domain delivery agent
- **bounce** - Handles non-delivery notifications
- **master** - Process supervisor and control daemon

## Installation

### System Requirements

**Minimum:**

- CPU: 1 GHz processor
- RAM: 512 MB
- Disk: 2 GB free space
- Network: 100 Mbps

**Recommended (Enterprise):**

- CPU: 4+ cores
- RAM: 8 GB+
- Disk: 50 GB+ (SSD preferred for queue)
- Network: 1 Gbps+

### Installing on Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install Postfix
sudo apt install postfix -y

# During installation, select:
# - General type: Internet Site
# - System mail name: mail.yourdomain.com

# Install additional utilities
sudo apt install postfix-pcre postfix-policyd-spf-python mailutils -y

# Verify installation
postconf -d | grep mail_version
# Expected output: mail_version = 3.x.x
```

### Installing on RHEL/CentOS/Rocky Linux

```bash
# Install Postfix
sudo dnf install postfix -y

# Install additional packages
sudo dnf install postfix-pcre cyrus-sasl-plain mailx -y

# Enable and start service
sudo systemctl enable postfix
sudo systemctl start postfix

# Configure firewall
sudo firewall-cmd --permanent --add-service=smtp
sudo firewall-cmd --permanent --add-service=smtps
sudo firewall-cmd --permanent --add-service=submission
sudo firewall-cmd --reload

# Verify installation
postconf mail_version
```

### Post-Installation Checks

```bash
# Check if Postfix is running
systemctl status postfix

# Verify Postfix is listening
ss -tlnp | grep master
# Should show ports 25 (smtp)

# Check configuration syntax
postfix check

# View current settings
postconf -n

# Send test email
echo "Test email body" | mail -s "Test Subject" user@example.com
```

## Basic Configuration

### Understanding main.cf

The `/etc/postfix/main.cf` file contains the main Postfix configuration parameters. It uses a simple `parameter = value` format.

```bash
# View all parameters (very long list)
postconf

# View only non-default parameters
postconf -n

# View specific parameter
postconf myhostname

# Set parameter via command line
sudo postconf -e 'myhostname = mail.example.com'

# Changes take effect after reload
sudo postfix reload
```

### Essential Configuration Parameters

#### Hostname and Domain Settings

```bash
# /etc/postfix/main.cf

# Hostname of this mail server
myhostname = mail.example.com

# Domain name
mydomain = example.com

# Origin domain for locally-posted mail
myorigin = $mydomain

# Domains to receive mail for (local delivery)
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain

# Networks/hosts to relay mail from
mynetworks = 127.0.0.0/8, 192.168.1.0/24

# Where to deliver local mail
home_mailbox = Maildir/
```

#### Network Settings

```bash
# Interfaces to listen on
# all = all network interfaces
# localhost only = loopback-only
inet_interfaces = all

# IPv4 and IPv6 support
inet_protocols = all

# Maximum message size (50MB example)
message_size_limit = 52428800

# Mailbox size limit (0 = unlimited)
mailbox_size_limit = 0
```

### Quick Setup Examples

#### Example 1: Simple Internal Mail Server

```bash
# /etc/postfix/main.cf
# For internal email only

myhostname = mail.internal.local
mydomain = internal.local
myorigin = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
mynetworks = 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
relayhost =
home_mailbox = Maildir/

# Apply changes
sudo postfix reload
```

#### Example 2: Mail Gateway/Relay

```bash
# /etc/postfix/main.cf
# Relay mail to external smarthost

myhostname = relay.example.com
mydomain = example.com
myorigin = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost
mynetworks = 127.0.0.0/8, 192.168.1.0/24
relayhost = [smtp.office365.com]:587

# SMTP AUTH for relay
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous
smtp_tls_security_level = encrypt

# Create password file
# Format: [smtp.office365.com]:587 username:password
sudo nano /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd*
sudo postfix reload
```

#### Example 3: Mail Server with Virtual Domains

```bash
# /etc/postfix/main.cf
# Hosting multiple domains

myhostname = mail.example.com
mydomain = example.com
myorigin = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost
mynetworks = 127.0.0.0/8, 192.168.1.0/24

# Virtual domains
virtual_mailbox_domains = example.com, example.net, example.org
virtual_mailbox_base = /var/mail/vhosts
virtual_mailbox_maps = hash:/etc/postfix/vmailbox
virtual_minimum_uid = 100
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000
virtual_alias_maps = hash:/etc/postfix/virtual

# Create virtual user
sudo groupadd -g 5000 vmail
sudo useradd -g vmail -u 5000 vmail -d /var/mail/vhosts -m

# Create virtual mailbox mapping
# /etc/postfix/vmailbox
# user@example.com    example.com/user/
sudo postmap /etc/postfix/vmailbox

# Create virtual aliases
# /etc/postfix/virtual
# info@example.com    user@example.com
sudo postmap /etc/postfix/virtual

sudo postfix reload
```

## TLS/SSL Encryption

### Obtaining Certificates

**Option 1: Let's Encrypt (Free):**

```bash
# Install certbot
sudo apt install certbot -y

# Obtain certificate
sudo certbot certonly --standalone -d mail.example.com

# Certificates will be in:
# /etc/letsencrypt/live/mail.example.com/fullchain.pem
# /etc/letsencrypt/live/mail.example.com/privkey.pem

# Auto-renewal (certbot adds timer automatically)
sudo systemctl status certbot.timer
```

**Option 2: Self-Signed (Testing Only):**

```bash
# Generate self-signed certificate
sudo openssl req -new -x509 -days 365 -nodes \
  -out /etc/postfix/ssl/mail.crt \
  -keyout /etc/postfix/ssl/mail.key

sudo chmod 600 /etc/postfix/ssl/mail.key
```

### Configuring TLS in Postfix

```bash
# /etc/postfix/main.cf

# TLS for incoming connections (SMTP server)
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.example.com/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/mail.example.com/privkey.pem
smtpd_tls_security_level = may
smtpd_tls_auth_only = yes
smtpd_tls_loglevel = 1
smtpd_tls_received_header = yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache

# TLS for outgoing connections (SMTP client)
smtp_tls_cert_file = /etc/letsencrypt/live/mail.example.com/fullchain.pem
smtp_tls_key_file = /etc/letsencrypt/live/mail.example.com/privkey.pem
smtp_tls_security_level = may
smtp_tls_loglevel = 1
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

# Strong ciphers only
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1

sudo postfix reload
```

### Configure Submission Port (587)

```bash
# /etc/postfix/master.cf
# Uncomment and configure submission service

submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_tls_auth_only=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_helo_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING

sudo postfix reload
```

### Test TLS Configuration

```bash
# Test STARTTLS support
openssl s_client -connect mail.example.com:25 -starttls smtp

# Test submission port with TLS
openssl s_client -connect mail.example.com:587 -starttls smtp

# Expected output should show:
# - Certificate details
# - TLS version (TLSv1.2 or TLSv1.3)
# - Cipher suite
# - Verify return code: 0 (ok)

# - Verify return code: 0 (ok)
```

## SMTP Authentication (SASL)

### Installing and Configuring SASL

```bash
# Install SASL packages
sudo apt install libsasl2-modules sasl2-bin -y

# Create SASL configuration directory
sudo mkdir -p /etc/postfix/sasl

# Configure SASL for Postfix
# /etc/postfix/sasl/smtpd.conf
echo "pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN" | sudo tee /etc/postfix/sasl/smtpd.conf

# Add SASL users
sudo saslpasswd2 -c -u example.com username

# List SASL users
sudo sasldblistusers2

# Test authentication
testsaslauthd -u username -p password -s smtp
```

### Configure Postfix for SASL

```bash
# /etc/postfix/main.cf

# Enable SASL authentication
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = cyrus
smtpd_sasl_path = smtpd
smtpd_sasl_local_domain = $mydomain
smtpd_sasl_security_options = noanonymous
smtpd_sasl_tls_security_options = noanonymous
broken_sasl_auth_clients = yes

# Relay permissions
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination

sudo postfix reload
```

### LDAP/Active Directory Authentication

```bash
# Install LDAP support
sudo apt install postfix-ldap -y

# Create LDAP lookup configuration
# /etc/postfix/ldap-users.cf
server_host = ldap://dc.example.com
search_base = dc=example,dc=com
version = 3
bind = yes
bind_dn = cn=postfix,ou=service,dc=example,dc=com
bind_pw = password123
query_filter = (mail=%s)
result_attribute = mail

# Update main.cf
# /etc/postfix/main.cf
virtual_mailbox_maps = ldap:/etc/postfix/ldap-users.cf

# Test LDAP lookup
postmap -q user@example.com ldap:/etc/postfix/ldap-users.cf

sudo postfix reload
```

## Access Control and Security

### Restrict Relay Access

```bash
# /etc/postfix/main.cf

# Only relay for authenticated users and local networks
smtpd_relay_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    defer_unauth_destination

# Client restrictions
smtpd_client_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_rbl_client zen.spamhaus.org,
    reject_rbl_client bl.spamcop.net,
    reject_unknown_client_hostname

# Sender restrictions
smtpd_sender_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_non_fqdn_sender,
    reject_unknown_sender_domain

# Recipient restrictions
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_non_fqdn_recipient,
    reject_unknown_recipient_domain,
    reject_unauth_destination,
    reject_unverified_recipient

sudo postfix reload
```

### Rate Limiting

```bash
# /etc/postfix/main.cf

# Limit connections per client
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 30

# Limit message rate per client
smtpd_client_message_rate_limit = 100

# Limit recipients per message
smtpd_recipient_limit = 50

# Anvil rate limit service settings
anvil_rate_time_unit = 60s
anvil_status_update_time = 600s

sudo postfix reload
```

### Block Attachments by Type

```bash
# /etc/postfix/main.cf
mime_header_checks = regexp:/etc/postfix/mime_header_checks
body_checks = regexp:/etc/postfix/body_checks

# /etc/postfix/mime_header_checks
# Block dangerous file types
/^Content-(Disposition|Type).*name\s*=\s*"?(.+\.(exe|vbs|pif|scr|bat|cmd|com|cpl))(\?=)?"?\s*$/
    REJECT Attachment type not allowed: $2

# /etc/postfix/body_checks
# Block URLs with dangerous patterns
/^.*http:\/\/.*malicious-domain\.com.*$/
    REJECT URL blocked by policy

sudo postmap /etc/postfix/mime_header_checks
sudo postmap /etc/postfix/body_checks
sudo postfix reload
```

### SPF, DKIM, and DMARC

For comprehensive email authentication, see the [Email Authentication Guide](../smtp/authentication.md).

**Quick SPF Check Configuration:**

```bash
# Install SPF checker
sudo apt install postfix-policyd-spf-python -y

# /etc/postfix/master.cf
# Add policy service
policy-spf  unix  -       n       n       -       0       spawn
    user=nobody argv=/usr/bin/policyd-spf

# /etc/postfix/main.cf
policy-spf_time_limit = 3600s
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination,
    check_policy_service unix:private/policy-spf

sudo postfix reload
```

## Queue Management

### Understanding the Queue

Postfix uses multiple queues for mail processing:

```text
maildrop → incoming → active → deferred/bounce/hold
                               ↓
                            delivery
```

- **maildrop** - Messages submitted via sendmail command
- **incoming** - Messages being processed by cleanup
- **active** - Messages ready for delivery
- **deferred** - Messages that couldn't be delivered (temporary failure)
- **hold** - Messages on hold (admin action required)
- **corrupt** - Unreadable messages

### Queue Commands

```bash
# View queue
postqueue -p
mailq                    # Same as postqueue -p

# Flush queue (attempt immediate delivery)
postqueue -f

# Flush specific domain
postqueue -s example.com

# Delete all messages
postsuper -d ALL

# Delete deferred messages only
postsuper -d ALL deferred

# Delete messages from specific sender
mailq | grep '^[A-F0-9]' | grep 'spam@example.com' | cut -d' ' -f1 | postsuper -d -

# Hold all messages
postsuper -h ALL

# Release held messages
postsuper -H ALL

# View message content
postcat -q [QUEUE_ID]

# View message headers only
postcat -qh [QUEUE_ID]

# Requeue message (for reprocessing)
postsuper -r [QUEUE_ID]

# Queue statistics
qshape active
qshape deferred
```

### Queue Management Script

```bash
#!/bin/bash
# /usr/local/bin/postfix-queue-report.sh

echo "=== Postfix Queue Report ==="
echo "Date: $(date)"
echo ""

echo "Queue Summary:"
postqueue -p | tail -1

echo ""
echo "Messages by Domain (Top 10):"
qshape -s active | head -11

echo ""
echo "Deferred Messages:"
qshape -s deferred | head -11

echo ""
echo "Old Messages (>4 hours):"
find /var/spool/postfix/deferred -type f -mmin +240 -print | wc -l
```

## Logging and Monitoring

### Understanding Postfix Logs

```bash
# Main log file location
# Debian/Ubuntu:
/var/log/mail.log
/var/log/mail.err

# RHEL/CentOS:
/var/log/maillog

# Systemd journal:
journalctl -u postfix -f
```

### Log Analysis

```bash
# Real-time monitoring
tail -f /var/log/mail.log

# Filter by queue ID
grep "ABC123" /var/log/mail.log

# Show only delivery attempts
grep "status=sent" /var/log/mail.log

# Show bounces
grep "status=bounced" /var/log/mail.log

# Show rejected connections
grep "reject:" /var/log/mail.log

# Count messages by status
grep "status=" /var/log/mail.log | cut -d '=' -f2 | cut -d '(' -f1 | sort | uniq -c

# Top sending IPs
grep "client=" /var/log/mail.log | awk '{print $7}' | sort | uniq -c | sort -rn | head -10
```

### Postfix Log Analyzers

**pflogsumm (Postfix Log Summary):**

```bash
# Install
sudo apt install pflogsumm -y

# Generate daily report
pflogsumm -d today /var/log/mail.log

# Generate yesterday's report
pflogsumm -d yesterday /var/log/mail.log

# Email daily report
pflogsumm -d yesterday /var/log/mail.log | mail -s "Postfix Report" admin@example.com
```

**mailgraph (Visual Statistics):**

```bash
# Install
sudo apt install mailgraph -y

# Start service
sudo systemctl enable mailgraph
sudo systemctl start mailgraph

# Access via web (requires web server)
# http://your-server/cgi-bin/mailgraph.cgi
```

### Monitoring Checklist

```bash
#!/bin/bash
# /usr/local/bin/postfix-health-check.sh

echo "=== Postfix Health Check ==="

# Check if service is running
if systemctl is-active --quiet postfix; then
    echo "✓ Postfix service: Running"
else
    echo "✗ Postfix service: Stopped"
    exit 1
fi

# Check queue size
QUEUE_SIZE=$(postqueue -p | tail -1 | awk '{print $5}')
if [ "$QUEUE_SIZE" -lt 100 ]; then
    echo "✓ Queue size: $QUEUE_SIZE (OK)"
else
    echo "⚠ Queue size: $QUEUE_SIZE (HIGH)"
fi

# Check for errors in recent logs
ERROR_COUNT=$(journalctl -u postfix --since "10 minutes ago" | grep -i "error\|fatal\|panic" | wc -l)
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✓ Recent errors: None"
else
    echo "⚠ Recent errors: $ERROR_COUNT"
fi

# Check disk space for queue
DISK_USAGE=$(df -h /var/spool/postfix | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    echo "✓ Queue disk usage: ${DISK_USAGE}%"
else
    echo "⚠ Queue disk usage: ${DISK_USAGE}% (HIGH)"
fi

# Check certificate expiration
CERT_EXPIRY=$(openssl x509 -enddate -noout -in /etc/letsencrypt/live/mail.example.com/fullchain.pem | cut -d= -f2)
echo "ℹ Certificate expires: $CERT_EXPIRY"

echo ""
echo "Health check completed: $(date)"
```

## Spam and Virus Filtering

### Integration with SpamAssassin

```bash
# Install SpamAssassin
sudo apt install spamassassin spamc -y

# Configure SpamAssassin
sudo nano /etc/default/spamassassin
# Set: ENABLED=1

# Update rules
sudo sa-update

# Start service
sudo systemctl enable spamassassin
sudo systemctl start spamassassin

# Configure Postfix to use SpamAssassin
# /etc/postfix/master.cf
smtp      inet  n       -       y       -       -       smtpd
  -o content_filter=spamassassin

spamassassin unix -     n       n       -       -       pipe
  user=debian-spamd argv=/usr/bin/spamc -f -e /usr/sbin/sendmail -oi -f ${sender} ${recipient}

sudo postfix reload
```

### Integration with Amavis and ClamAV

```bash
# Install packages
sudo apt install amavisd-new clamav clamav-daemon -y

# Update ClamAV virus definitions
sudo freshclam

# Configure Postfix
# /etc/postfix/main.cf
content_filter = smtp-amavis:[127.0.0.1]:10024

# /etc/postfix/master.cf
smtp-amavis unix -      -       n       -       2       smtp
  -o smtp_data_done_timeout=1200
  -o smtp_send_xforward_command=yes
  -o disable_dns_lookups=yes

127.0.0.1:10025 inet n  -       n       -       -       smtpd
  -o content_filter=
  -o local_recipient_maps=
  -o relay_recipient_maps=
  -o smtpd_restriction_classes=
  -o smtpd_client_restrictions=
  -o smtpd_helo_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=permit_mynetworks,reject
  -o mynetworks=127.0.0.0/8
  -o strict_rfc821_envelopes=yes

# Start services
sudo systemctl enable clamav-daemon amavis
sudo systemctl start clamav-daemon amavis

sudo postfix reload
```

### Greylisting with Postgrey

```bash
# Install
sudo apt install postgrey -y

# Configure Postfix
# /etc/postfix/main.cf
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination,
    check_policy_service inet:127.0.0.1:10023

sudo systemctl enable postgrey
sudo systemctl start postgrey

sudo postfix reload
```

## Performance Tuning

### Optimization Parameters

```bash
# /etc/postfix/main.cf

# Increase parallel deliveries
default_process_limit = 100
smtpd_client_connection_count_limit = 50

# Connection caching
smtp_connection_cache_destinations = example.com, example.net
smtp_connection_cache_on_demand = yes
smtp_connection_cache_time_limit = 2s

# Queue management
qmgr_message_active_limit = 20000
qmgr_message_recipient_limit = 20000

# Delivery concurrency
default_destination_concurrency_limit = 20
default_destination_recipient_limit = 50

# Timeouts
smtp_connect_timeout = 30s
smtp_helo_timeout = 300s

sudo postfix reload
```

### System Tuning

```bash
# Increase open file limits
# /etc/security/limits.conf
postfix soft nofile 65536
postfix hard nofile 65536

# Kernel parameters
# /etc/sysctl.conf
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.core.netdev_max_backlog = 2500

sudo sysctl -p
```

## Troubleshooting

### Common Issues and Solutions

#### Issue: Connection Refused

```bash
# Check if Postfix is running
systemctl status postfix

# Check if port is open
ss -tlnp | grep :25

# Check firewall
sudo iptables -L -n | grep 25
sudo firewall-cmd --list-all

# Test connection
telnet localhost 25
```

#### Issue: Mail Stuck in Queue

```bash
# Check queue
postqueue -p

# Check for errors
tail -100 /var/log/mail.log

# Common causes:
# 1. DNS issues
host -t MX example.com

# 2. Network connectivity
ping example.com

# 3. TLS problems
openssl s_client -connect mail.example.com:25 -starttls smtp

# Force retry
postqueue -f
```

#### Issue: Authentication Failures

```bash
# Check SASL configuration
postconf -n | grep sasl

# Test SASL
testsaslauthd -u username -p password

# Check logs for auth errors
grep "authentication failed" /var/log/mail.log

# Verify credentials
sasldblistusers2
```

#### Issue: Emails Rejected as Spam

```bash
# Check sender reputation
# Use online tools like mxtoolbox.com

# Verify SPF/DKIM/DMARC
dig TXT example.com
dig TXT _dmarc.example.com
dig TXT default._domainkey.example.com

# Test email authentication
# Send to check-auth@verifier.port25.com

# Check if on blacklists
dig 1.2.3.4.zen.spamhaus.org
```

### Debug Mode

```bash
# Enable verbose logging
postconf -e "debug_peer_list = example.com"
postconf -e "debug_peer_level = 2"

sudo postfix reload

# Watch logs
tail -f /var/log/mail.log

# Disable debug mode
postconf -e "debug_peer_list ="
postconf -e "debug_peer_level = 2"

sudo postfix reload
```

## Backup and Recovery

### What to Backup

```bash
# Configuration files
/etc/postfix/
/etc/aliases
/etc/mailname

# Queue (optional, usually don't backup)
/var/spool/postfix/

# Mailboxes
/var/mail/
/home/*/Maildir/

# SSL certificates
/etc/letsencrypt/
```

### Backup Script

```bash
#!/bin/bash
# /usr/local/bin/backup-postfix.sh

BACKUP_DIR="/backup/postfix"
DATE=$(date +%Y%m%d)

mkdir -p $BACKUP_DIR

# Backup configuration
tar -czf $BACKUP_DIR/postfix-config-$DATE.tar.gz /etc/postfix/

# Export current settings
postconf -n > $BACKUP_DIR/postfix-settings-$DATE.txt

# Backup aliases
cp /etc/aliases $BACKUP_DIR/aliases-$DATE

# Keep last 7 days
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $(date)" | mail -s "Postfix Backup" admin@example.com
```

### Recovery

```bash
# Restore configuration
sudo tar -xzf postfix-config-YYYYMMDD.tar.gz -C /

# Rebuild lookup tables
sudo postmap /etc/postfix/virtual
sudo postmap /etc/postfix/transport
sudo newaliases

# Check configuration
sudo postfix check

# Restart Postfix
sudo systemctl restart postfix
```

## Advanced Topics

### Virtual Domains with Database Backend

```bash
# Install MySQL/PostgreSQL support
sudo apt install postfix-mysql -y

# Create database
mysql -u root -p << EOF
CREATE DATABASE postfix;
CREATE USER 'postfix'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON postfix.* TO 'postfix'@'localhost';
EOF

# Create tables
mysql -u postfix -p postfix << EOF
CREATE TABLE domains (
  id INT AUTO_INCREMENT PRIMARY KEY,
  domain VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  domain VARCHAR(255) NOT NULL
);

CREATE TABLE aliases (
  id INT AUTO_INCREMENT PRIMARY KEY,
  source VARCHAR(255) NOT NULL,
  destination VARCHAR(255) NOT NULL
);
EOF

# Configure Postfix
# /etc/postfix/mysql-virtual-mailbox-domains.cf
user = postfix
password = password
hosts = localhost
dbname = postfix
query = SELECT domain FROM domains WHERE domain='%s'

# /etc/postfix/mysql-virtual-mailbox-maps.cf
user = postfix
password = password
hosts = localhost
dbname = postfix
query = SELECT email FROM users WHERE email='%s'

# /etc/postfix/main.cf
virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf

sudo postfix reload
```

### Multi-Instance Configuration

```bash
# Create second instance
sudo postmulti -e init
sudo postmulti -I postfix-outbound -e create

# Configure outbound instance
sudo postmulti -i postfix-outbound -x postconf -e "myhostname = outbound.example.com"
sudo postmulti -i postfix-outbound -x postconf -e "smtp_bind_address = 203.0.113.2"

# Enable instance
sudo postmulti -i postfix-outbound -e enable

# Manage instances
postmulti -l                           # List instances
postmulti -i postfix-outbound -p start # Start instance
postmulti -i postfix-outbound -p stop  # Stop instance
```

### Custom Content Filters

```bash
# Simple filter script
# /usr/local/bin/filter.sh
#!/bin/bash
/usr/sbin/sendmail -G -i "$@" < <(
    # Add custom header
    echo "X-Custom-Filter: Processed"
    # Pass through original content
    cat
)

# Make executable
sudo chmod +x /usr/local/bin/filter.sh

# Configure in master.cf
# /etc/postfix/master.cf
filter    unix  -       n       n       -       -       pipe
  flags=Rq user=filter argv=/usr/local/bin/filter.sh -f ${sender} -- ${recipient}

# /etc/postfix/main.cf
content_filter = filter:dummy

sudo postfix reload
```

## Quick Reference

### Essential Commands

```bash
# Service Control
systemctl status postfix              # Check status
systemctl start postfix               # Start service
systemctl stop postfix                # Stop service
systemctl restart postfix             # Restart service
systemctl reload postfix              # Reload configuration
postfix check                         # Check configuration syntax
postfix status                        # Show daemon status

# Configuration
postconf                              # Display all parameters
postconf -n                           # Display non-default parameters
postconf -d                           # Display default parameters
postconf parameter                    # Display specific parameter
postconf -e "parameter=value"         # Set parameter
postfix set-permissions               # Fix file permissions

# Queue Management
postqueue -p                          # View queue
mailq                                 # Same as postqueue -p
postqueue -f                          # Flush queue (force delivery)
postqueue -s example.com              # Flush messages to specific domain
postsuper -d [ID]                     # Delete message by queue ID
postsuper -d ALL                      # Delete all messages
postsuper -h [ID]                     # Hold message
postsuper -H [ID]                     # Release held message
postsuper -r [ID]                     # Requeue message
postcat -q [ID]                       # View message content
qshape active                         # Queue statistics

# Testing and Debugging
echo "Test" | mail -s "Subject" user@example.com  # Send test email
telnet localhost 25                   # Test SMTP connection
openssl s_client -connect mail.example.com:25 -starttls smtp  # Test TLS
postmap -q key@domain lookup_table    # Test lookup table

# Logging
tail -f /var/log/mail.log             # Monitor logs (Debian/Ubuntu)
tail -f /var/log/maillog              # Monitor logs (RHEL/CentOS)
journalctl -u postfix -f              # Monitor logs (systemd)
pflogsumm /var/log/mail.log           # Generate log summary

# Lookup Tables
postmap /etc/postfix/virtual          # Build hash lookup table
postalias /etc/aliases                # Rebuild aliases database
newaliases                            # Same as postalias /etc/aliases
```

### Critical Configuration Parameters

| Parameter | Purpose | Example |
| --------- | ------- | ------- |
| `myhostname` | Server's hostname | `mail.example.com` |
| `mydomain` | Domain name | `example.com` |
| `myorigin` | Sender domain for local mail | `$mydomain` |
| `mydestination` | Domains to receive mail for | `$myhostname, localhost, $mydomain` |
| `mynetworks` | Trusted networks | `127.0.0.0/8, 192.168.1.0/24` |
| `relayhost` | Upstream mail relay | `[smtp.relay.com]:587` |
| `inet_interfaces` | Network interfaces to listen on | `all` or `localhost` |
| `home_mailbox` | Mailbox format | `Maildir/` or `mbox` |
| `message_size_limit` | Maximum message size | `52428800` (50MB) |

### Important Files and Directories

| Path | Description |
| ---- | ----------- |
| `/etc/postfix/main.cf` | Main configuration file |
| `/etc/postfix/master.cf` | Service definitions |
| `/etc/postfix/virtual` | Virtual domain mappings |
| `/etc/postfix/transport` | Transport routing table |
| `/etc/postfix/access` | Access control rules |
| `/etc/aliases` | Email aliases (system-wide) |
| `/etc/postfix/header_checks` | Header filtering rules |
| `/etc/postfix/body_checks` | Body content filters |
| `/var/spool/postfix/` | Mail queue directory |
| `/var/log/mail.log` | Mail log (Debian/Ubuntu) |
| `/var/log/maillog` | Mail log (RHEL/CentOS) |

### SMTP Response Codes Quick Reference

| Code | Meaning | Action |
| ---- | ------- | ------ |
| 220 | Service ready | Connection established |
| 221 | Closing connection | Normal termination |
| 250 | Requested action completed | Success |
| 354 | Start mail input | Send DATA |
| 421 | Service not available | Temporary failure, retry |
| 450 | Mailbox unavailable | Temporary failure, retry |
| 451 | Local error | Temporary failure, retry |
| 452 | Insufficient storage | Temporary failure, retry |
| 500 | Syntax error | Fix command syntax |
| 501 | Syntax error in parameters | Fix parameters |
| 502 | Command not implemented | Not supported |
| 503 | Bad sequence of commands | Follow SMTP protocol |
| 550 | Mailbox unavailable | Permanent failure |
| 551 | User not local | Relaying denied |
| 552 | Storage limit exceeded | Message too large |
| 553 | Mailbox name invalid | Invalid recipient |
| 554 | Transaction failed | Rejected by policy |

### Port Reference

| Port | Service | Purpose | Security |
| ---- | ------- | ------- | -------- |
| 25 | SMTP | Server-to-server mail transfer | STARTTLS optional |
| 465 | SMTPS | Legacy encrypted SMTP | Implicit TLS |
| 587 | Submission | Client mail submission | STARTTLS required |
| 2525 | Alternative | Alternative when 25 blocked | Varies |

## Best Practices

### Security Best Practices

✅ **Do:**

- Always use TLS encryption for client submission (port 587)
- Require authentication for mail submission
- Implement rate limiting to prevent abuse
- Keep Postfix and system packages updated
- Use strong ciphers (TLS 1.2+)

- ✅ Tune queue management parameters
- ✅ Optimize for expected email volume
- ✅ Monitor system resources (CPU, memory, disk I/O)
- ✅ Implement proper mail queue management
- ✅ Use connection caching for frequent destinations

### Reliability

- ✅ Regular backups of configuration and queues
- ✅ Implement monitoring and alerting
- ✅ Plan for disaster recovery
- ✅ Document configuration changes
- ✅ Test changes in non-production environment first

### Configuration Best Practices

✅ **Do:**

- Use lookup tables (hash/btree) for better performance
- Comment your configuration files thoroughly
- Test changes in non-production environment first
- Use `postfix check` before reloading configuration
- Version control your configuration files

❌ **Don't:**

- Edit configuration files directly in production without backup
- Ignore warning messages from `postfix check`
- Copy configurations blindly from online tutorials

## Common Use Cases and Examples

### Use Case 1: Internal Mail Server

**Scenario:** Small office internal email only.

```bash
# /etc/postfix/main.cf
myhostname = mail.internal.local
mydomain = internal.local
myorigin = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
mynetworks = 127.0.0.0/8, 192.168.1.0/24
home_mailbox = Maildir/
smtpd_recipient_restrictions = permit_mynetworks, reject
```

### Use Case 2: Smarthost Relay to Office 365

**Scenario:** All outbound mail relayed through Office 365.

```bash
# /etc/postfix/main.cf
myhostname = relay.example.com
mydomain = example.com
myorigin = $mydomain
relayhost = [smtp.office365.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt

# /etc/postfix/sasl_passwd
[smtp.office365.com]:587 username@example.com:password

sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd*
```

## Related Documentation

- [SMTP Protocol Overview](../smtp/index.md) - Complete SMTP protocol guide
- [Email Authentication (SPF, DKIM, DMARC)](../smtp/authentication.md) - Essential for deliverability
- [Exchange Server](../exchange/index.md) - Microsoft Exchange integration

## External Resources

### Official Documentation

- [Postfix Official Website](http://www.postfix.org/)
- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [Postfix Configuration Parameters](http://www.postfix.org/postconf.5.html)
- [Postfix Standard Configuration Examples](http://www.postfix.org/STANDARD_CONFIGURATION_README.html)
- [Postfix TLS README](http://www.postfix.org/TLS_README.html)
- [Postfix SASL README](http://www.postfix.org/SASL_README.html)

### Community Resources

- [Postfix Users Mailing List](http://www.postfix.org/lists.html)
- [Postfix on Stack Overflow](https://stackoverflow.com/questions/tagged/postfix)
- [r/postfix on Reddit](https://www.reddit.com/r/postfix/)

### Books and Guides

- *The Book of Postfix: State-of-the-Art Message Transport* by Ralf Hildebrandt and Patrick Koetter
- *Postfix: The Definitive Guide* by Kyle Dent

---

**Last Updated:** January 13, 2026

> This comprehensive guide covers Postfix from installation to advanced configurations. For specific integration scenarios or troubleshooting, refer to the official Postfix documentation or community resources.
