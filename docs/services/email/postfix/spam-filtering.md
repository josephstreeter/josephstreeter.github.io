---
title: "Postfix Anti-Spam and Anti-Virus - Complete Guide"
description: "Comprehensive guide for implementing spam filtering and virus scanning with Postfix using SpamAssassin, Amavis, ClamAV, Postgrey, and Rspamd"
author: "Joseph Streeter"
ms.date: 01/13/2026
ms.topic: guide
keywords: postfix, spam filtering, antivirus, spamassassin, amavis, clamav, postgrey, rspamd, mail security
---

Comprehensive guide for protecting your Postfix mail server against spam
and viruses using industry-standard tools and best practices.

## Overview

### The Spam Problem

Email spam accounts for 45-85% of all email traffic globally. Without
proper filtering:

- Users waste time dealing with unwanted mail
- Malware and phishing attacks increase security risks
- Server resources are consumed by junk mail
- Legitimate email may be lost in the noise
- Legal and compliance issues may arise

### Defense Strategy

A robust anti-spam solution uses multiple layers:

```text
┌─────────────────────────────────────────────────────────────────┐
│                  Multi-Layer Defense Strategy                   │
└─────────────────────────────────────────────────────────────────┘

Incoming Email
      ↓
1. Connection Level (Postfix restrictions)
   • DNS blacklists (RBL/DNSBL)
   • Client restrictions
   • Helo/sender checks
      ↓
2. Grey listing (Postgrey)
   • Temporary rejection
   • Retry verification
      ↓
3. Content Filtering (Amavis + SpamAssassin/Rspamd)
   • Spam scoring
   • Bayesian filtering
   • Rule-based detection
      ↓
4. Virus Scanning (ClamAV)
   • Malware detection
   • Attachment scanning
      ↓
5. Delivery or Rejection
   • Quarantine
   • Tag and deliver
   • Reject
```

### Solution Comparison

| Solution | Type | Pros | Cons | Best For |
| --- | --- | --- | --- | --- |
| SpamAssassin | Content | Mature, accurate | Resource heavy | Medium volume |
| Rspamd | Content | Fast, modern | Learning curve | High volume |
| Amavis | Integration | Standard, flexible | Complex setup | Enterprise |
| ClamAV | Antivirus | Free, effective | Signature-based | All servers |
| Postgrey | Greylisting | Simple, effective | Delays mail | Low/medium |

## Prerequisites

Before implementing spam filtering:

- ✅ Working Postfix installation
- ✅ Root or sudo access
- ✅ At least 2GB RAM (4GB+ recommended for high volume)
- ✅ DNS properly configured
- ✅ Understanding of mail flow

## SpamAssassin Integration

### What is SpamAssassin?

SpamAssassin is a mature, widely-used spam filtering system that uses a
variety of tests to identify spam including:

- Header analysis
- Body analysis
- Bayesian filtering
- DNS blacklists
- Custom rules

### SpamAssassin Installation

#### SpamAssassin on Ubuntu/Debian

```bash
# Install SpamAssassin
sudo apt update
sudo apt install spamassassin spamc -y

# Create spamd user if not exists
sudo adduser --system --group --no-create-home --disabled-login spamd

# Enable and start service
sudo systemctl enable spamassassin
sudo systemctl start spamassassin
```

#### SpamAssassin on RHEL/CentOS/Rocky

```bash
# Install SpamAssassin
sudo dnf install spamassassin -y

# Enable and start service
sudo systemctl enable spamassassin
sudo systemctl start spamassassin
```

### SpamAssassin Configuration

```bash
# Edit SpamAssassin configuration
sudo nano /etc/spamassassin/local.cf
```

**Basic Configuration:**

```bash
# /etc/spamassassin/local.cf

# Rewrite subject of spam messages
rewrite_header Subject [***SPAM***]

# Spam threshold (default 5.0)
required_score 5.0

# Use Bayesian filtering
use_bayes 1
bayes_auto_learn 1

# Store Bayes data in SQL (recommended for multi-server)
# bayes_store_module Mail::SpamAssassin::BayesStore::MySQL

# Enable network tests
skip_rbl_checks 0

# DNS blacklists to use
urirhssub   URIBL_BLACK  multi.uribl.com.  A   2
body        URIBL_BLACK  eval:check_uridnsbl('URIBL_BLACK')

# Report spam level in headers
add_header all Level _STARS(*)_
add_header all Status _YESNO_, score=_SCORE_ required=_REQD_ tests=_TESTS_
autolearn=_AUTOLEARN_ version=_VERSION_

# Trusted networks (where to not check received headers)
trusted_networks 127.0.0.0/8 192.168.1.0/24
```

### Configure Postfix to Use SpamAssassin

**Method 1: Using spamc (Simple, Lower Performance):**

```bash
# /etc/postfix/master.cf
# Add after smtp inet line

smtp      inet  n       -       y       -       -       smtpd
  -o content_filter=spamassassin

# Add at end of file
spamassassin unix -     n       n       -       -       pipe
  user=spamd argv=/usr/bin/spamc -f -e
  /usr/sbin/sendmail -oi -f ${sender} ${recipient}
```

**Method 2: Using Milter (Better Performance):**

```bash
# Install spamass-milter
sudo apt install spamass-milter -y

# Configure spamass-milter
sudo nano /etc/default/spamass-milter
```

```bash
# /etc/default/spamass-milter
OPTIONS="-u spamass-milter -i 127.0.0.1 -m -r -1"
```

```bash
# Configure Postfix
sudo postconf -e 'smtpd_milters = unix:/spamass/spamass.sock'
sudo postconf -e 'milter_default_action = accept'

# Restart services
sudo systemctl restart spamass-milter postfix
```

### Training SpamAssassin

Train SpamAssassin with spam and ham (legitimate mail) samples:

```bash
# Train with spam samples
sa-learn --spam /path/to/spam/folder

# Train with ham samples
sa-learn --ham /path/to/ham/folder

# Check database stats
sa-learn --dump magic

# Backup Bayesian database
sa-learn --backup > bayes_backup.txt

# Restore from backup
sa-learn --restore bayes_backup.txt
```

### Testing SpamAssassin

```bash
# Test SpamAssassin is working
echo "Test" | spamassassin -D

# Test with GTUBE (Generic Test for Unsolicited Bulk Email)
echo "XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X" |
spamassassin

# Should show: ***** SPAM ***** with high score
```

## Amavis + ClamAV Integration

### What is Amavis?

Amavis (A Mail Virus Scanner) is a high-performance interface between
MTA and content filters. It provides:

- Virus scanning integration
- Spam checking integration
- Content filtering
- Attachment filtering

### Amavis Installation

#### Amavis on Ubuntu/Debian

```bash
# Install Amavis and ClamAV
sudo apt install amavisd-new clamav clamav-daemon -y

# Add clamav user to amavis group
sudo adduser clamav amavis

# Update ClamAV virus definitions
sudo freshclam

# Start services
sudo systemctl start clamav-daemon
sudo systemctl start amavis
```

#### Amavis on RHEL/CentOS/Rocky

```bash
# Install Amavis and ClamAV
sudo dnf install amavisd-new clamd clamav-update -y

# Update virus definitions
sudo freshclam

# Start services
sudo systemctl enable --now clamd@scan
sudo systemctl enable --now amavisd
```

### Amavis Configuration

```bash
# Edit Amavis configuration
sudo nano /etc/amavis/conf.d/50-user
```

**Basic Configuration:**

```bash
# /etc/amavis/conf.d/50-user

use strict;

# Daemon user and group
$daemon_user  = 'amavis';
$daemon_group = 'amavis';

# Listening address
$inet_socket_bind = '127.0.0.1';
$inet_socket_port = 10024;

# Enable virus scanning
@bypass_virus_checks_maps = (
   \%bypass_virus_checks, \@bypass_virus_checks_acl,
$bypass_virus_checks_re);

# Enable spam scanning
@bypass_spam_checks_maps = (
   \%bypass_spam_checks, \@bypass_spam_checks_acl,
$bypass_spam_checks_re);

# Spam tag levels
$sa_tag_level_deflt  = 2.0;  # Add spam headers at this level
$sa_tag2_level_deflt = 6.2;  # Add 'spam detected' header
$sa_kill_level_deflt = 6.9;  # Reject spam at this level
$sa_dsn_cutoff_level = 10;   # Spam level to not send DSN

# Quarantine infected emails
$virus_quarantine_to = 'virus-quarantine';

# Quarantine spam
$spam_quarantine_to = 'spam-quarantine';

# Notify administrator of viruses
$virus_admin = 'virusalert@example.com';

# Domain-specific settings
$mydomain = 'example.com';
$myhostname = 'mail.example.com';

# Enable SpamAssassin
$sa_spam_subject_tag = '[***SPAM***] ';
@local_domains_maps = ( [".$mydomain"] );

1;  # Ensure file ends with this
```

### ClamAV Configuration

```bash
# Edit ClamAV configuration
sudo nano /etc/clamav/clamd.conf
```

**Key Settings:**

```bash
# /etc/clamav/clamd.conf

# Local socket
LocalSocket /var/run/clamav/clamd.ctl
LocalSocketGroup amavis
LocalSocketMode 660

# Maximum file size to scan (25MB)
MaxFileSize 25M

# Maximum scan size
MaxScanSize 100M

# Maximum recursion level
MaxRecursion 16

# Detect potentially unwanted applications
DetectPUA yes

# Enable algorithmic detection
AlgorithmicDetection yes
```

### Configure Postfix for Amavis

```bash
# Edit Postfix configuration
sudo nano /etc/postfix/main.cf
```

```bash
# /etc/postfix/main.cf
# Add content filter for Amavis

content_filter = smtp-amavis:[127.0.0.1]:10024
```

```bash
# Edit master.cf
sudo nano /etc/postfix/master.cf
```

```bash
# /etc/postfix/master.cf
# Add these lines

# Before-queue content filter on SMTP port 10024
smtp-amavis unix -      -       n       -       2       smtp
    -o smtp_data_done_timeout=1200
    -o smtp_send_xforward_command=yes
    -o disable_dns_lookups=yes
    -o max_use=20

# Reinjection on port 10025
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
    -o smtpd_error_sleep_time=0
    -o smtpd_soft_error_limit=1001
    -o smtpd_hard_error_limit=1000
    -o smtpd_client_connection_count_limit=0
    -o smtpd_client_connection_rate_limit=0
    -o receive_override_options=no_header_body_checks,no_unknown_recipient_checks
```

### Restart Services

```bash
# Restart all services
sudo systemctl restart clamav-daemon
sudo systemctl restart amavis
sudo systemctl restart postfix

# Check status
sudo systemctl status clamav-daemon amavis postfix
```

### Testing Amavis + ClamAV

```bash
# Test with EICAR virus test file
curl https://secure.eicar.org/eicar.com.txt | \
mail -s "Virus Test" user@example.com

# Check logs
sudo tail -f /var/log/mail.log

# Should see: "Blocked INFECTED" in logs
```

## Postgrey (Greylisting)

### What is Greylisting?

Greylisting temporarily rejects email from unknown senders. Legitimate
mail servers retry delivery, but most spambots don't. This catches 50-90%
of spam with minimal false positives.

### Postgrey Installation

```bash
# Ubuntu/Debian
sudo apt install postgrey -y

# RHEL/CentOS
sudo dnf install postgrey -y

# Start service
sudo systemctl enable postgrey
sudo systemctl start postgrey
```

### Postgrey Configuration

```bash
# Edit Postgrey configuration
sudo nano /etc/default/postgrey  # Ubuntu/Debian
sudo nano /etc/sysconfig/postgrey  # RHEL/CentOS
```

```bash
# /etc/default/postgrey

# Port to listen on
POSTGREY_OPTS="--inet=127.0.0.1:10023
  --delay=300
  --max-age=35
  --auto-whitelist-clients=10"

# --delay=300: Wait 5 minutes before accepting
# --max-age=35: Remember hosts for 35 days
# --auto-whitelist-clients=10: Auto-whitelist after 10 successful retries
```

### Whitelist Legitimate Servers

```bash
# Edit whitelist
sudo nano /etc/postgrey/whitelist_clients.local
```

```bash
# /etc/postgrey/whitelist_clients.local
# Add domains/IPs that should bypass greylisting

# Microsoft/Office365
.outlook.com
.protection.outlook.com

# Google/Gmail
.google.com
.googlemail.com

# Other common services
.amazon.com
.salesforce.com
.zendesk.com

# Your business partners
example-partner.com
```

### Configure Postfix for Postgrey

```bash
# Add to smtpd_recipient_restrictions
sudo postconf -e 'smtpd_recipient_restrictions =
  permit_mynetworks,
  permit_sasl_authenticated,
  reject_unauth_destination,
  check_policy_service inet:127.0.0.1:10023'

# Restart services
sudo systemctl restart postgrey postfix
```

### Monitor Greylisting

```bash
# View greylist database
sudo sqlite3 /var/lib/postgrey/postgrey.db "SELECT * FROM greylist
LIMIT 10;"

# Check logs
sudo grep postgrey /var/log/mail.log

# Stats
sudo grep "action=greylist" /var/log/mail.log | wc -l
sudo grep "action=pass" /var/log/mail.log | wc -l
```

## Rspamd (Modern Alternative)

### What is Rspamd?

Rspamd is a modern, fast spam filtering system with:

- Multi-threaded architecture
- Built-in Redis support
- Machine learning
- Web UI for management
- Better performance than SpamAssassin

### Rspamd Installation

```bash
# Ubuntu/Debian
sudo apt install rspamd redis-server -y

# RHEL/CentOS - Add repository first
curl https://rspamd.com/rpm-stable/centos-9/rspamd.repo | \
sudo tee /etc/yum.repos.d/rspamd.repo
sudo dnf install rspamd redis -y

# Start services
sudo systemctl enable --now redis-server
sudo systemctl enable --now rspamd
```

### Rspamd Configuration

```bash
# Generate password for web UI
rspamadm pw

# Configure local override
sudo nano /etc/rspamd/local.d/worker-controller.inc
```

```bash
# /etc/rspamd/local.d/worker-controller.inc
password = "$2$your_generated_hash_here";
bind_socket = "localhost:11334";
```

```bash
# Configure Redis
sudo nano /etc/rspamd/local.d/redis.conf
```

```bash
# /etc/rspamd/local.d/redis.conf
servers = "127.0.0.1:6379";
```

### Integrate with Postfix

```bash
# Configure Rspamd proxy
sudo nano /etc/rspamd/local.d/worker-proxy.inc
```

```bash
# /etc/rspamd/local.d/worker-proxy.inc
bind_socket = "localhost:11332";
milter = yes;
timeout = 120s;
upstream "local" {
  default = yes;
  self_scan = yes;
}
```

```bash
# Configure Postfix milter
sudo postconf -e 'smtpd_milters = inet:localhost:11332'
sudo postconf -e 'milter_protocol = 6'
sudo postconf -e 'milter_mail_macros = i {mail_addr} {client_addr}
{client_name} {auth_authen}'
sudo postconf -e 'milter_default_action = accept'

# Restart services
sudo systemctl restart rspamd postfix
```

### Access Rspamd Web UI

```bash
# Access web interface at:
# http://localhost:11334

# Or configure nginx proxy for remote access
sudo apt install nginx -y
```

```nginx
# /etc/nginx/sites-available/rspamd
server {
    listen 80;
    server_name rspamd.example.com;

    location / {
        proxy_pass http://localhost:11334;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## DNS Blacklists (DNSBL/RBL)

### Configure DNS Blacklists

```bash
# Edit Postfix main.cf
sudo nano /etc/postfix/main.cf
```

```bash
# /etc/postfix/main.cf

# DNS blacklist restrictions
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_rbl_client zen.spamhaus.org,
    reject_rbl_client bl.spamcop.net,
    reject_rbl_client dnsbl.sorbs.net,
    reject_unauth_destination

# Client restrictions
smtpd_client_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_rbl_client zen.spamhaus.org
```

**Popular DNSBLs:**

- **Spamhaus ZEN** - zen.spamhaus.org (most comprehensive)
- **SpamCop** - bl.spamcop.net
- **Barracuda** - b.barracudacentral.org
- **SORBS** - dnsbl.sorbs.net
- **URIBL** - multi.uribl.com (URL blacklist)

### Test DNSBL

```bash
# Test if IP is blacklisted
dig +short 4.3.2.1.zen.spamhaus.org

# If returns 127.0.0.x, IP is blacklisted
```

## Header Checks and Body Checks

### Configure Header Checks

```bash
# Create header checks file
sudo nano /etc/postfix/header_checks
```

```bash
# /etc/postfix/header_checks

# Reject emails with suspicious subjects
/^Subject:.*\b(v[il1]agra|cialis|pharmacy)\b/i  REJECT Spam detected

# Reject Nigerian scam patterns
/^Subject:.*\b(million dollars?|beneficiary|next of kin)\b/i  REJECT

# Reject common spam patterns
/^Subject:.*\b(weight loss|get rich|work from home)\b/i  REJECT

# Reject suspicious from headers
/^From:.*<?(admin|postmaster|webmaster)@.*/  WARN Suspicious sender
```

```bash
# Compile and enable
sudo postmap /etc/postfix/header_checks
sudo postconf -e 'header_checks = regexp:/etc/postfix/header_checks'
```

### Configure Body Checks

```bash
# Create body checks file
sudo nano /etc/postfix/body_checks
```

```bash
# /etc/postfix/body_checks

# Block executables in body
/\.(exe|bat|cmd|scr|vbs|pif|com)$/  REJECT Executable attachment blocked

# Block suspicious URLs
/http:\/\/.*\.(ru|cn)\/.*\.(exe|zip)/  REJECT Suspicious URL blocked
```

```bash
# Enable body checks
sudo postmap /etc/postfix/body_checks
sudo postconf -e 'body_checks = regexp:/etc/postfix/body_checks'
sudo postfix reload
```

## Monitoring and Maintenance

### Log Analysis

```bash
# Spam statistics script
#!/bin/bash
# /usr/local/bin/spam-stats.sh

echo "=== Spam Statistics ==="
echo "Date: $(date)"
echo ""

# SpamAssassin stats
echo "SpamAssassin:"
grep "spamd: identified spam" /var/log/mail.log | wc -l |
awk '{print "  Spam detected: " $1}'
grep "spamd: clean message" /var/log/mail.log | wc -l |
awk '{print "  Clean messages: " $1}'

# Amavis stats
echo ""
echo "Amavis:"
grep "Blocked INFECTED" /var/log/mail.log | wc -l |
awk '{print "  Viruses blocked: " $1}'
grep "Blocked SPAM" /var/log/mail.log | wc -l |
awk '{print "  Spam blocked: " $1}'

# Postgrey stats
echo ""
echo "Postgrey:"
grep "action=greylist" /var/log/mail.log | wc -l |
awk '{print "  Greylisted: " $1}'
grep "action=pass" /var/log/mail.log | wc -l |
awk '{print "  Passed: " $1}'

# RBL rejections
echo ""
echo "RBL Rejections:"
grep "reject: RCPT.*blocked using" /var/log/mail.log | wc -l |
awk '{print "  RBL rejections: " $1}'
```

### Update Virus Definitions

```bash
# Manual update
sudo freshclam

# Automatic updates (cron)
sudo crontab -e

# Add:
0 */6 * * * /usr/bin/freshclam --quiet
```

### Performance Monitoring

```bash
# Check Amavis performance
sudo amavisd-nanny

# Check ClamAV memory usage
ps aux | grep clamd

# Check SpamAssassin performance
ps aux | grep spamd

# Monitor mail queue
watch mailq
```

## Troubleshooting

### Issue 1: High False Positives

**Solutions:**

```bash
# Lower spam threshold in SpamAssassin
sudo nano /etc/spamassassin/local.cf
required_score 6.0  # Increase from 5.0

# Whitelist legitimate senders
# /etc/postfix/sender_access
example-partner.com    OK
friend@example.com     OK

sudo postmap /etc/postfix/sender_access
sudo postconf -e 'smtpd_sender_restrictions =
check_sender_access hash:/etc/postfix/sender_access'
```

### Issue 2: ClamAV High Memory Usage

**Solutions:**

```bash
# Limit ClamAV memory
sudo nano /etc/clamav/clamd.conf

# Add/modify:
MaxFileSize 10M      # Reduce from 25M
MaxScanSize 50M      # Reduce from 100M
MaxThreads 10        # Limit concurrent scans
```

### Issue 3: Legitimate Mail Delayed by Greylisting

**Solutions:**

```bash
# Reduce greylist delay
sudo nano /etc/default/postgrey
POSTGREY_OPTS="--delay=180"  # 3 minutes instead of 5

# Whitelist sender
echo "sender-domain.com" | sudo tee -a
/etc/postgrey/whitelist_clients.local
sudo systemctl restart postgrey
```

## Best Practices

1. **Multi-Layer Defense**: Use multiple filtering methods
2. **Monitor and Tune**: Regularly review false positives/negatives
3. **Update Regularly**: Keep virus definitions and rules current
4. **Train Filters**: Feed spam and ham samples to Bayesian filters
5. **Whitelist Important Senders**: Prevent false positives
6. **Log Everything**: Maintain detailed logs for troubleshooting
7. **Test Changes**: Use test accounts before production deployment

## Quick Reference

### Essential Commands

```bash
# SpamAssassin
sa-learn --spam /path/to/spam       # Train with spam
sa-learn --ham /path/to/ham         # Train with ham
spamassassin -D < test.eml          # Test message

# ClamAV
sudo freshclam                      # Update definitions
clamscan -r /path                   # Scan directory
clamdscan file.txt                  # Scan with daemon

# Amavis
sudo amavisd-new debug              # Debug mode
sudo amavisd-new showkeys           # Show DKIM keys
sudo amavisd-nanny                  # Monitor performance

# Postgrey
sudo systemctl status postgrey      # Check status
sudo grep postgrey /var/log/mail.log  # View logs

# Rspamd
rspamadm configtest                 # Test configuration
rspamadm pw                         # Generate password
rspamc stat                         # Show statistics
```

## Related Documentation

- [Postfix Complete Guide](index.md) - Full Postfix documentation
- [SASL Authentication](sasl.md) - User authentication
- [DKIM Email Signing](dkim.md) - Email authentication
- [Security Hardening](security-hardening.md) - Security best practices

## External Resources

- [SpamAssassin Wiki](https://wiki.apache.org/spamassassin/)
- [ClamAV Documentation](https://docs.clamav.net/)
- [Rspamd Documentation](https://rspamd.com/doc/)
- [Amavis Documentation](https://www.amavis.org/documentation.html)

---

**Last Updated:** January 13, 2026

> Comprehensive spam and virus protection requires multiple layers of
> defense. Regular monitoring and tuning ensure optimal protection with
> minimal false positives.
