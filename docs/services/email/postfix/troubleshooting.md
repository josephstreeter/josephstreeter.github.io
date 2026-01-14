---
title: "Postfix Troubleshooting Guide"
description: "Comprehensive troubleshooting guide for Postfix mail server issues including connection problems, delivery failures, and configuration errors"
author: "Joseph Streeter"
ms.date: 01/13/2026
ms.topic: guide
keywords: postfix, troubleshooting, debugging, mail delivery, smtp errors, queue management
---

Comprehensive troubleshooting guide for diagnosing and resolving common
Postfix mail server issues.

## Quick Diagnostic Commands

Essential commands for troubleshooting Postfix issues:

```bash
# Check Postfix service status
systemctl status postfix

# View recent mail log entries
tail -50 /var/log/mail.log

# Check mail queue
mailq

# Test Postfix configuration
postfix check

# View configuration parameters
postconf -n

# Check specific parameter
postconf parameter_name

# Reload configuration
postfix reload

# Restart Postfix
systemctl restart postfix
```

## Common Issues and Solutions

### Mail Delivery Failures

#### Symptom: Mail Not Being Delivered

**Check Queue:**

```bash
# View mail queue
mailq

# Detailed queue information
postqueue -p

# View specific message
postcat -q QUEUE_ID

# Force queue processing
postqueue -f
```

**Common Causes:**

1. DNS resolution issues
2. Network connectivity problems
3. Recipient server rejecting mail
4. Incorrect relay configuration

**Solutions:**

```bash
# Test DNS resolution
dig MX example.com

# Test connection to destination
telnet mail.example.com 25

# Check relay configuration
postconf relayhost

# View detailed delivery attempts
grep QUEUE_ID /var/log/mail.log
```

#### Symptom: Mail Stuck in Queue

**Diagnosis:**

```bash
# View deferred queue
postqueue -p | grep "^[A-F0-9]"

# Count messages in queue
mailq | tail -1

# View why messages are deferred
postcat -vq QUEUE_ID
```

**Solutions:**

```bash
# Flush queue for specific domain
postqueue -s example.com

# Retry all deferred mail
postqueue -f

# Delete all messages in queue
postsuper -d ALL

# Delete messages from specific sender
mailq | grep sender@example.com | awk '{print $1}' |
postsuper -d -
```

### Connection Issues

#### Symptom: Cannot Connect to Port 25/587

**Diagnosis:**

```bash
# Check if Postfix is listening
ss -tlnp | grep master

# Test connection locally
telnet localhost 25

# Test from remote host
telnet mail.example.com 25

# Check firewall
sudo ufw status
sudo iptables -L -n | grep -E "25|587|465"
```

**Solutions:**

```bash
# Ensure Postfix is running
systemctl start postfix

# Check inet_interfaces
postconf inet_interfaces
# Should be 'all' for external access

# Open firewall ports
sudo ufw allow 25/tcp
sudo ufw allow 587/tcp
sudo ufw allow 465/tcp

# Check if port is blocked by ISP
# Try alternate port for submission (587)
```

#### Symptom: TLS/SSL Connection Errors

**Diagnosis:**

```bash
# Test TLS connection
openssl s_client -connect mail.example.com:587 -starttls smtp

# Check certificate
openssl s_client -connect mail.example.com:465

# Verify certificate files
postconf -n | grep tls_cert
ls -l /etc/ssl/certs/mail.crt
```

**Solutions:**

```bash
# Verify certificate is valid
openssl x509 -in /etc/ssl/certs/mail.crt -text -noout

# Check certificate expiration
openssl x509 -in /etc/ssl/certs/mail.crt -noout -dates

# Fix certificate permissions
sudo chmod 644 /etc/ssl/certs/mail.crt
sudo chmod 600 /etc/ssl/private/mail.key

# Reload Postfix
postfix reload
```

### Authentication Issues

#### Symptom: SASL Authentication Failing

**Diagnosis:**

```bash
# Check SASL configuration
postconf -n | grep sasl

# Test authentication
testsaslauthd -u username -p password -s smtp

# Check saslauthd status
systemctl status saslauthd

# View authentication logs
grep -i sasl /var/log/mail.log | tail -20
```

**Solutions:**

See [Postfix SASL Authentication Guide](sasl.md#troubleshooting) for
detailed SASL troubleshooting.

### Configuration Errors

#### Symptom: Postfix Won't Start

**Diagnosis:**

```bash
# Check for syntax errors
postfix check

# View service errors
systemctl status postfix -l

# Check system logs
journalctl -u postfix -n 50

# Verify configuration files exist
ls -l /etc/postfix/main.cf
ls -l /etc/postfix/master.cf
```

**Solutions:**

```bash
# Fix syntax errors shown by postfix check

# Check file permissions
sudo chmod 644 /etc/postfix/main.cf
sudo chmod 644 /etc/postfix/master.cf
sudo chown root:root /etc/postfix/*.cf

# Restore default configuration if needed
sudo cp /etc/postfix/main.cf.default /etc/postfix/main.cf

# Start Postfix
systemctl start postfix
```

#### Symptom: Parameter Errors

**Diagnosis:**

```bash
# Check configuration syntax
postfix check

# View current parameters
postconf -n

# Check for duplicate parameters
grep -n "^parameter_name" /etc/postfix/main.cf
```

**Solutions:**

```bash
# Remove duplicate parameters
sudo nano /etc/postfix/main.cf

# Use postconf to set parameters
sudo postconf -e 'parameter=value'

# Reload configuration
postfix reload
```

### Email Rejection Issues

#### Symptom: Mail Being Rejected as Spam

**Diagnosis:**

```bash
# Check reverse DNS
dig -x YOUR_SERVER_IP

# Check SPF record
dig TXT example.com

# Check DKIM
dig TXT default._domainkey.example.com

# Check DMARC
dig TXT _dmarc.example.com

# Test with mail-tester.com
# Send test email to address shown
```

**Solutions:**

1. Configure reverse DNS (PTR record)
2. Implement SPF, DKIM, DMARC
3. Ensure not on blacklists
4. Fix server reputation

See [Email Authentication Guide](../smtp/authentication.md) for details.

#### Symptom: Relay Access Denied

**Diagnosis:**

```bash
# Check relay restrictions
postconf smtpd_relay_restrictions
postconf mynetworks

# View rejection in logs
grep "Relay access denied" /var/log/mail.log
```

**Solutions:**

```bash
# Allow specific networks
postconf -e 'mynetworks = 127.0.0.0/8 192.168.1.0/24'

# Configure SASL authentication
# See SASL guide for setup

# Configure submission port properly
# Edit /etc/postfix/master.cf

# Reload Postfix
postfix reload
```

### Performance Issues

#### Symptom: Slow Mail Delivery

**Diagnosis:**

```bash
# Check queue length
mailq | tail -1

# Check system resources
top
free -h
df -h

# Check connection limits
postconf | grep limit

# Monitor active connections
ss -tn | grep :25 | wc -l
```

**Solutions:**

```bash
# Increase concurrency limits
postconf -e 'default_destination_concurrency_limit = 20'
postconf -e 'smtp_destination_concurrency_limit = 10'

# Adjust queue processing
postconf -e 'minimal_backoff_time = 300s'
postconf -e 'maximal_backoff_time = 4000s'

# Increase process limits
# Edit /etc/postfix/master.cf

# Reload Postfix
postfix reload
```

#### Symptom: High CPU/Memory Usage

**Diagnosis:**

```bash
# Check Postfix processes
ps aux | grep postfix

# Monitor resource usage
top -u postfix

# Check queue size
mailq | tail -1

# Check for mail loops
grep "loops back to myself" /var/log/mail.log
```

**Solutions:**

```bash
# Clean up queue
postsuper -d ALL deferred

# Fix mail loops
# Check mydestination and relay settings

# Adjust process limits
# Edit /etc/postfix/master.cf

# Restart Postfix
systemctl restart postfix
```

## Log Analysis

### Key Log Locations

```bash
# Main mail log
/var/log/mail.log       # Debian/Ubuntu
/var/log/maillog        # RHEL/CentOS

# Postfix-specific logs
/var/log/mail.info
/var/log/mail.warn
/var/log/mail.err
```

### Log Analysis Commands

```bash
# View real-time logs
tail -f /var/log/mail.log

# Search for specific message
grep QUEUE_ID /var/log/mail.log

# Count messages by status
grep "status=" /var/log/mail.log | cut -d'=' -f2 | sort | uniq -c

# Find rejected messages
grep "reject" /var/log/mail.log

# View authentication attempts
grep "sasl_method" /var/log/mail.log

# Analyze delivery times
grep "delay=" /var/log/mail.log

# Find bounced messages
grep "bounce" /var/log/mail.log
```

### Log Parsing Tools

```bash
# pflogsumm - Postfix log summary
sudo apt install pflogsumm -y
pflogsumm /var/log/mail.log

# mailgraph - graphical log analysis
sudo apt install mailgraph -y
systemctl start mailgraph

# Custom analysis script
awk '/status=sent/ {sent++}
     /status=deferred/ {deferred++}
     /status=bounced/ {bounced++}
     END {print "Sent:", sent, "Deferred:", deferred,
     "Bounced:", bounced}' /var/log/mail.log
```

## Debugging Techniques

### Enable Verbose Logging

```bash
# /etc/postfix/main.cf
debug_peer_list = example.com
debug_peer_level = 2

# Or for all connections
smtpd_tls_loglevel = 2
smtp_tls_loglevel = 2

# Reload Postfix
postfix reload
```

### Test SMTP Manually

```bash
# Connect to Postfix
telnet localhost 25

# SMTP session:
EHLO test.example.com
MAIL FROM:<sender@example.com>
RCPT TO:<recipient@example.com>
DATA
Subject: Test

Test message.
.
QUIT
```

### Trace Message Delivery

```bash
# Add header tracing
postconf -e 'always_add_missing_headers = yes'

# View message headers
postcat -vq QUEUE_ID

# Follow message through logs
grep QUEUE_ID /var/log/mail.log
```

## Emergency Procedures

### Stop All Mail Processing

```bash
# Stop Postfix
systemctl stop postfix

# Hold all messages in queue
postsuper -h ALL

# Resume later
postsuper -H ALL
systemctl start postfix
```

### Clear Problematic Queue

```bash
# View queue
mailq

# Delete specific message
postsuper -d QUEUE_ID

# Delete all from sender
mailq | grep sender@domain.com | awk '{print $1}' | postsuper -d -

# Delete all mail
postsuper -d ALL
postsuper -d ALL deferred
```

### Restore from Backup

```bash
# Stop Postfix
systemctl stop postfix

# Restore configuration
sudo cp /backup/main.cf /etc/postfix/main.cf
sudo cp /backup/master.cf /etc/postfix/master.cf

# Restore queue (if needed)
sudo rsync -av /backup/postfix/spool/ /var/spool/postfix/

# Fix permissions
sudo postfix set-permissions

# Start Postfix
systemctl start postfix
```

## Monitoring and Prevention

### Regular Health Checks

```bash
#!/bin/bash
# /usr/local/bin/postfix-health-check.sh

echo "=== Postfix Health Check ==="
echo "Date: $(date)"
echo ""

# Service status
if systemctl is-active --quiet postfix; then
    echo "✓ Postfix service: Running"
else
    echo "✗ Postfix service: Stopped"
fi

# Queue status
QUEUE_SIZE=$(mailq | tail -1 | awk '{print $5}')
echo "ℹ Mail queue: $QUEUE_SIZE messages"

# Disk space
DISK_USAGE=$(df -h /var/spool/postfix | tail -1 | awk '{print $5}')
echo "ℹ Queue partition usage: $DISK_USAGE"

# Recent errors
ERROR_COUNT=$(grep -c "error" /var/log/mail.log)
if [ $ERROR_COUNT -gt 0 ]; then
    echo "⚠ Recent errors: $ERROR_COUNT"
fi

echo ""
echo "Health check completed"
```

### Automated Monitoring

```bash
# Add to crontab for regular checks
crontab -e

# Run health check hourly
0 * * * * /usr/local/bin/postfix-health-check.sh

# Alert on large queue
*/15 * * * * [ $(mailq | tail -1 | awk '{print $5}') -gt 100 ] &&
echo "Queue size exceeded" | mail -s "Alert" admin@example.com
```

## Getting Help

### Information to Gather

When seeking help, provide:

1. Postfix version: `postconf mail_version`
2. Operating system: `cat /etc/os-release`
3. Configuration: `postconf -n`
4. Error logs: `grep ERROR /var/log/mail.log`
5. Queue status: `mailq`
6. Specific error message or QUEUE_ID

### Resources

- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [Postfix Users Mailing List](http://www.postfix.org/lists.html)

## Related Documentation

- [Postfix Overview](index.md) - Complete Postfix guide
- [Postfix Configuration Reference](postfix-configuration.md)
- [Postfix SASL Authentication](sasl.md)
- [Postfix with OpenDKIM](dkim.md)

---

**Last Updated:** January 13, 2026

> This troubleshooting guide provides solutions for common Postfix
> issues. For complex problems, consult the official Postfix
> documentation or seek help from the community.
