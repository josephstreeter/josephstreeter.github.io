---
title: Relay and Smart Host Configuration
description: Guide to configuring Postfix as a relay or smart host with Office 365, Gmail, SendGrid, and AWS SES integration
author: Joseph Streeter
ms.date: 01/13/2026
ms.topic: article
---

Learn how to configure Postfix to relay email through external providers like
Office 365, Gmail, SendGrid, and AWS SES for improved deliverability and
centralized email management.

## Overview

### What is a Smart Host?

A **smart host** is an external mail server that handles outbound email
delivery on behalf of your local mail server. Benefits include:

- **Improved deliverability** - Leverage provider reputation
- **No direct internet delivery** - Avoid firewall complexity
- **Professional features** - SPF, DKIM, DMARC handled by provider
- **Centralized logging** - Track all outbound mail
- **Compliance** - Meet organizational email policies

### Common Use Cases

| Scenario | Best Provider | Reason |
| --- | --- | --- |
| Office 365 org | Office 365 | Native integration |
| G Suite org | Gmail | Native integration |
| Application email | SendGrid/SES | Transactional focus |
| High volume | SendGrid/SES | Cost-effective |
| Internal relay | Custom relay | Control & privacy |

### Architecture

```mermaid
graph LR
    A[Application] --> B[Postfix Relay]
    C[User] --> B
    B --> D{Smart Host}
    D --> E[Office 365]
    D --> F[Gmail]
    D --> G[SendGrid]
    D --> H[AWS SES]
    E --> I[Internet]
    F --> I
    G --> I
    H --> I
```

## Prerequisites

### General Requirements

- Postfix 3.x or later installed
- Valid credentials for smart host provider
- TLS/SSL certificates configured
- SASL authentication libraries
- Network access to provider SMTP ports

### Install Required Packages

**Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install postfix libsasl2-modules postfix-pcre
```

**RHEL/CentOS/Rocky:**

```bash
sudo dnf install postfix cyrus-sasl-plain cyrus-sasl-md5
sudo systemctl enable postfix
```

### Provider-Specific Requirements

- **Office 365**: Microsoft 365 license with SMTP relay enabled
- **Gmail**: App password or OAuth2 credentials
- **SendGrid**: API key with Mail Send permissions
- **AWS SES**: IAM user with SES sending permissions

## Office 365 Relay Configuration

### Office 365 Prerequisites

- Office 365 tenant with Exchange Online
- Connector created in Exchange Admin Center
- Public IP address or SPF record

### Create Office 365 Connector

1. **Exchange Admin Center** → **Mail flow** → **Connectors**
2. Click **+ Add a connector**
3. **Connection from**: Your organization's email server
4. **Connection to**: Office 365
5. Configure:
   - **Name**: "Postfix Relay"
   - **Retain internal headers**: Yes (if needed)
   - **Email from**: Your domain(s)
   - **Authentication**: Certificate or IP address
6. Add your Postfix server's public IP address

### Office 365 Postfix Configuration

Add to `/etc/postfix/main.cf`:

```ini
# Office 365 relay settings
relayhost = [smtp.office365.com]:587
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous

# Office 365 specific settings
smtp_generic_maps = hash:/etc/postfix/generic
smtp_header_checks = regexp:/etc/postfix/header_checks

# Sender restrictions
sender_canonical_maps = hash:/etc/postfix/sender_canonical
```

### Office 365 Create Password File

#### /etc/postfix/sasl_passwd (Office 365)

```text
[smtp.office365.com]:587 your-email@yourdomain.com:YourPassword
```

Generate password database:

```bash
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
```

### Address Rewriting (Optional)

If rewriting local addresses to Office 365 addresses:

#### /etc/postfix/generic (Office 365)

```text
root@localhost.localdomain admin@yourdomain.com
@localhost.localdomain @yourdomain.com
```

Generate database:

```bash
sudo postmap /etc/postfix/generic
sudo chmod 600 /etc/postfix/generic /etc/postfix/generic.db
```

### Office 365 Throttling Limits

Office 365 enforces rate limits:

- **10,000 messages per day** per mailbox
- **30 messages per minute** per connection
- **500 recipients per day** per mailbox

Add to `/etc/postfix/main.cf`:

```ini
# Rate limiting for Office 365
default_destination_rate_delay = 2s
default_destination_recipient_limit = 5
```

### Office 365 Testing

```bash
# Test relay
echo "Test from Postfix relay" | mail -s "Test Office 365" user@example.com

# Check logs
sudo tail -f /var/log/mail.log

# Verify authentication
sudo postqueue -p
```

## Gmail/Google Workspace Relay

### Gmail Prerequisites

- Gmail account or Google Workspace domain
- App password (personal Gmail) or OAuth2 (Workspace)
- Less secure app access enabled OR App-specific password created

### Create Gmail App Password

1. **Google Account** → **Security** → **2-Step Verification**
2. **App passwords** → Select **Mail** and **Other (Custom name)**
3. Generate password and save securely

### Gmail Postfix Configuration

Add to `/etc/postfix/main.cf`:

```ini
# Gmail relay settings
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous

# Gmail specific settings
smtp_generic_maps = hash:/etc/postfix/generic
```

### Gmail Create Password File

#### /etc/postfix/sasl_passwd (Gmail)

```text
[smtp.gmail.com]:587 your-email@gmail.com:YourAppPassword
```

For Google Workspace with multiple domains:

```text
[smtp.gmail.com]:587 postmaster@yourdomain.com:YourAppPassword
```

Generate database:

```bash
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
```

### Gmail Rate Limits

Gmail enforces limits:

- **500 emails per day** (personal Gmail)
- **2,000 emails per day** (Google Workspace)
- **10,000 per day** (Workspace with higher limits)

Add to `/etc/postfix/main.cf`:

```ini
# Rate limiting for Gmail
default_destination_rate_delay = 2s
default_destination_recipient_limit = 10
```

### Gmail Address Canonicalization

#### /etc/postfix/generic (Gmail)

```text
root@localhost admin@yourdomain.com
www-data@localhost noreply@yourdomain.com
@localhost.localdomain @yourdomain.com
```

```bash
sudo postmap /etc/postfix/generic
```

### Gmail Testing

```bash
# Send test email
echo "Gmail relay test" | mail -s "Test Gmail Relay" user@example.com

# Check authentication
sudo grep "sasl_username" /var/log/mail.log

# Verify delivery
sudo mailq
```

## SendGrid Integration

### SendGrid Prerequisites

- SendGrid account (free or paid tier)
- API key with Mail Send permissions
- Sender authentication configured

### Create SendGrid API Key

1. **SendGrid Dashboard** → **Settings** → **API Keys**
2. Click **Create API Key**
3. Name: "Postfix Relay"
4. Permissions: **Mail Send** → Full Access
5. Save API key securely

### SendGrid Postfix Configuration

Add to `/etc/postfix/main.cf`:

```ini
# SendGrid relay settings
relayhost = [smtp.sendgrid.net]:587
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous

# SendGrid header handling
smtp_header_checks = regexp:/etc/postfix/sendgrid_header_checks
```

### SendGrid Create Password File

#### /etc/postfix/sasl_passwd (SendGrid)

```text
[smtp.sendgrid.net]:587 apikey:SG.YourAPIKeyHere
```

**Important**: Username is literally `apikey`, password is your API key.

Generate database:

```bash
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
```

### Sender Authentication

SendGrid requires sender verification:

#### Single Sender Verification

1. **Settings** → **Sender Authentication** → **Single Sender Verification**
2. Add and verify sender email addresses

#### Domain Authentication (Recommended)

1. **Settings** → **Sender Authentication** → **Authenticate Your Domain**
2. Add DNS records provided by SendGrid
3. Verify domain ownership

### Header Management

SendGrid processes custom headers for tracking:

#### /etc/postfix/sendgrid_header_checks

```text
# Add SendGrid category for tracking
/^Subject:/ PREPEND X-SMTPAPI: {"category": "postfix-relay"}

# Add custom tracking
/^Subject:/ PREPEND X-SendGrid-Category: production
```

```bash
sudo postmap /etc/postfix/sendgrid_header_checks
sudo chmod 644 /etc/postfix/sendgrid_header_checks
```

### SendGrid Rate Limits

Free tier: **100 emails per day**
Paid tiers: Based on plan (40k+ per day)

### SendGrid Testing

```bash
# Send test email
echo "SendGrid test" | mail -s "Test SendGrid" verified-sender@example.com

# Check logs for API authentication
sudo grep "sendgrid" /var/log/mail.log

# Verify delivery in SendGrid dashboard
# Dashboard → Activity
```

## AWS SES Integration

### AWS SES Prerequisites

- AWS account with SES enabled
- SES moved out of sandbox (for production)
- SMTP credentials generated
- Domain verified in SES

### Create SES SMTP Credentials

1. **AWS Console** → **SES** → **SMTP Settings**
2. Click **Create My SMTP Credentials**
3. IAM User Name: "ses-smtp-user"
4. Download credentials CSV (username and password)

### Verify Domain in SES

1. **SES Console** → **Verified identities** → **Create identity**
2. Identity type: **Domain**
3. Domain: your-domain.com
4. Add DNS records (DKIM, verification)

### Move Out of Sandbox

1. **SES Console** → **Account dashboard**
2. **Request production access**
3. Complete questionnaire about use case
4. Wait for AWS approval (usually 24-48 hours)

### Postfix Configuration

Add to `/etc/postfix/main.cf`:

```ini
# AWS SES relay settings
# Use region-specific endpoint
relayhost = [email-smtp.us-east-1.amazonaws.com]:587
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous

# SES specific settings
smtp_generic_maps = hash:/etc/postfix/generic
```

**Important**: Replace `us-east-1` with your SES region.

### SES Endpoints by Region

| Region | Endpoint |
| --- | --- |
| US East (N. Virginia) | email-smtp.us-east-1.amazonaws.com |
| US East (Ohio) | email-smtp.us-east-2.amazonaws.com |
| US West (Oregon) | email-smtp.us-west-2.amazonaws.com |
| EU (Ireland) | email-smtp.eu-west-1.amazonaws.com |
| EU (Frankfurt) | email-smtp.eu-central-1.amazonaws.com |
| Asia Pacific (Tokyo) | email-smtp.ap-northeast-1.amazonaws.com |
| Asia Pacific (Sydney) | email-smtp.ap-southeast-2.amazonaws.com |

### Create Password File

#### /etc/postfix/sasl_passwd

```text
[email-smtp.us-east-1.amazonaws.com]:587 AKIAIOSFODNN7EXAMPLE:wJalr...
```

Use SMTP username and password from SES credentials CSV.

```bash
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
```

### SES Rate Limits

- **Sandbox**: 200 emails per 24 hours, 1 per second
- **Production**: Based on sending quota (request increases)
- **Default production**: 50,000 per day, 14 per second

Add rate limiting:

```ini
# AWS SES rate limiting
default_destination_rate_delay = 100ms
default_destination_recipient_limit = 50
```

### Configuration for Verified Email Only

While in sandbox mode:

```ini
# Restrict to verified addresses (sandbox only)
smtpd_recipient_restrictions =
    check_recipient_access hash:/etc/postfix/ses_verified_recipients,
    reject
```

#### /etc/postfix/ses_verified_recipients

```text
verified-user@example.com OK
another-verified@example.com OK
```

```bash
sudo postmap /etc/postfix/ses_verified_recipients
```

### AWS SES Testing

```bash
# Send test email
echo "AWS SES test" | mail -s "Test SES" verified@example.com

# Check logs
sudo tail -f /var/log/mail.log | grep "smtp.amazonaws.com"

# Verify in SES console
# SES → Sending Statistics
```

### Monitoring SES Metrics

Use AWS CloudWatch or SES API:

```bash
# Check sending statistics (requires AWS CLI)
aws ses get-send-statistics --region us-east-1

# Check reputation metrics
aws ses get-account-sending-enabled --region us-east-1
```

## Advanced Configuration

### Conditional Relay (Per-Domain)

Route different domains to different smart hosts:

```ini
sender_dependent_relayhost_maps = hash:/etc/postfix/sender_relay
```

#### /etc/postfix/sender_relay

```text
@example.com [smtp.office365.com]:587
@example.org [smtp.gmail.com]:587
@example.net [smtp.sendgrid.net]:587
```

```bash
sudo postmap /etc/postfix/sender_relay
```

Create per-relay password files:

```text
[smtp.office365.com]:587 user1@example.com:Pass1
[smtp.gmail.com]:587 user2@example.org:Pass2
[smtp.sendgrid.net]:587 apikey:SG.KeyHere
```

### Fallback Smart Host

Configure primary and fallback relays:

```ini
# Primary relay
relayhost = [smtp.sendgrid.net]:587

# Fallback relay
smtp_fallback_relay = [smtp-relay.gmail.com]:587
```

### TLS Fingerprint Verification

Enhanced security with certificate fingerprinting:

```bash
# Get fingerprint
openssl s_client -connect smtp.gmail.com:587 -starttls smtp < /dev/null \
    2>/dev/null | openssl x509 -fingerprint -noout -sha256
```

```ini
smtp_tls_fingerprint_digest = sha256
smtp_tls_fingerprint_cert_match = 
    smtp.gmail.com=AA:BB:CC:DD:...
```

### Header Rewriting

Rewrite sender addresses dynamically:

```ini
sender_canonical_maps = regexp:/etc/postfix/sender_canonical
```

#### /etc/postfix/sender_canonical

```text
# Rewrite root@ to admin@
/^root@(.*)$/ admin@yourdomain.com

# Rewrite all local addresses
/^(.*)@localhost\.localdomain$/ ${1}@yourdomain.com

# Specific rewrites
/^www-data@/ noreply@yourdomain.com
```

No postmap needed for regexp maps.

### Queue Management

Optimize queue handling for relay:

```ini
# Queue lifetime
maximal_queue_lifetime = 1d
bounce_queue_lifetime = 1d

# Delivery concurrency
smtp_destination_concurrency_limit = 5
smtp_destination_rate_delay = 1s

# Connection reuse
smtp_connection_cache_on_demand = yes
smtp_connection_reuse_time_limit = 300s
smtp_connection_cache_destinations = 
    smtp.gmail.com,
    smtp.office365.com,
    smtp.sendgrid.net
```

### Retry Schedule

Customize retry behavior:

```ini
# Retry schedule (delay progressively)
minimal_backoff_time = 300s
maximal_backoff_time = 4000s
```

## Monitoring and Troubleshooting

### Enable Detailed Logging

```ini
# SASL debugging
smtp_sasl_auth_enable = yes
smtp_sasl_loglevel = 1

# TLS debugging
smtp_tls_loglevel = 1

# General debugging (temporary)
debug_peer_list = smtp.gmail.com,smtp.office365.com
debug_peer_level = 2
```

### Common Issues

#### Authentication Failures

```bash
# Check credentials
sudo postmap -q "[smtp.gmail.com]:587" hash:/etc/postfix/sasl_passwd

# Test SASL manually
perl -MMIME::Base64 -e 'print encode_base64("\000username\000password");'
openssl s_client -connect smtp.gmail.com:587 -starttls smtp
AUTH PLAIN <base64-string>
```

#### TLS Handshake Failures

```bash
# Test TLS connection
openssl s_client -connect smtp.gmail.com:587 -starttls smtp -showcerts

# Check CA bundle
ls -la /etc/ssl/certs/ca-certificates.crt

# Update CA certificates
sudo update-ca-certificates
```

#### Rate Limiting Issues

```bash
# Check queue
sudo postqueue -p

# Check deferred messages
sudo qshape deferred

# Flush queue (slowly)
sudo postqueue -f
```

#### Relay Access Denied

```bash
# Check relay settings
sudo postconf relayhost smtp_sasl_auth_enable

# Verify DNS resolution
nslookup smtp.gmail.com
dig smtp.gmail.com

# Test SMTP connectivity
telnet smtp.gmail.com 587
```

### Monitoring Scripts

#### /usr/local/bin/check-relay-health.sh

```bash
#!/bin/bash

echo "Postfix Relay Health Check - $(date)"
echo "========================================"

# Check service status
systemctl is-active --quiet postfix && echo "✓ Postfix running" || \
    echo "✗ Postfix stopped"

# Check queue size
QUEUE_SIZE=$(postqueue -p | tail -1 | awk '{print $5}')
echo "Queue size: $QUEUE_SIZE"

# Check recent relay status
echo ""
echo "Recent relay attempts:"
sudo grep "relay=" /var/log/mail.log | tail -5

# Check authentication failures
AUTH_FAIL=$(sudo grep "authentication failed" /var/log/mail.log | \
    tail -1 | wc -l)
if [ "$AUTH_FAIL" -gt 0 ]; then
    echo "⚠ Recent authentication failures detected"
fi

# Check TLS issues
TLS_FAIL=$(sudo grep "TLS.*failed" /var/log/mail.log | tail -1 | wc -l)
if [ "$TLS_FAIL" -gt 0 ]; then
    echo "⚠ Recent TLS failures detected"
fi

echo ""
echo "Recent successful deliveries:"
sudo grep "status=sent" /var/log/mail.log | tail -3
```

```bash
sudo chmod +x /usr/local/bin/check-relay-health.sh
```

### Log Analysis

```bash
# Count deliveries by relay host
sudo grep "relay=" /var/log/mail.log | \
    awk -F'relay=' '{print $2}' | \
    awk '{print $1}' | sort | uniq -c | sort -rn

# Check authentication success rate
sudo grep "sasl_username" /var/log/mail.log | wc -l

# Find failed deliveries
sudo grep "status=deferred\|status=bounced" /var/log/mail.log | tail -10

# Track specific email
sudo grep "message-id-here" /var/log/mail.log
```

## Security Best Practices

### Secure Credential Storage

```bash
# Restrict sasl_passwd access
sudo chmod 600 /etc/postfix/sasl_passwd*
sudo chown root:root /etc/postfix/sasl_passwd*

# Use separate credentials file
sudo chmod 600 /etc/postfix/relay_passwords
sudo chown root:postfix /etc/postfix/relay_passwords
```

### Enforce TLS

```ini
# /etc/postfix/main.cf
smtp_tls_security_level = encrypt
smtp_tls_mandatory_protocols = >=TLSv1.2
smtp_tls_mandatory_ciphers = high
```

### Restrict Relay Access

```ini
# Only allow local submission
smtpd_relay_restrictions = 
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination
```

### Credential Rotation

```bash
# Rotate relay passwords quarterly
# Update password in provider console
# Update /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo systemctl reload postfix
```

## Performance Optimization

### Connection Caching

```ini
smtp_connection_cache_on_demand = yes
smtp_connection_cache_destinations = 
    smtp.gmail.com, smtp.office365.com
smtp_connection_cache_time_limit = 300s
```

### Parallel Delivery

```ini
# Increase concurrent deliveries
smtp_destination_concurrency_limit = 10
default_destination_concurrency_limit = 5
```

### Queue Processing

```ini
# Faster queue scans
queue_run_delay = 60s
minimal_backoff_time = 300s
```

## Migration Strategies

### Testing New Relay

```bash
# Test without changing main config
sudo postfix -c /etc/postfix-test start
echo "Test" | mail -s "Test" user@example.com
```

### Gradual Migration

Use transport maps for gradual rollout:

#### /etc/postfix/transport

```text
example.com smtp:[new-relay.example.com]:587
.example.com smtp:[old-relay.example.com]:587
```

```bash
sudo postmap /etc/postfix/transport
```

### Rollback Plan

```bash
# Backup current config
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.backup

# Document rollback steps
# 1. Restore main.cf
# 2. Restore sasl_passwd
# 3. Reload Postfix
```

## Next Steps

- [SASL Authentication](sasl.md) - Configure local SMTP authentication
- [DKIM Signing](dkim.md) - Add email authentication
- [Spam Filtering](spam-filtering.md) - Implement filtering
- [Security Hardening](security-hardening.md) - Secure your server

## Additional Resources

- [Postfix SASL Howto](http://www.postfix.org/SASL_README.html)
- [Office 365 Connector Setup](https://learn.microsoft.com/exchange/mail-flow)
- [Gmail SMTP Settings](https://support.google.com/a/answer/176600)
- [SendGrid SMTP API](https://docs.sendgrid.com/for-developers/sending-email/integrating-with-the-smtp-api)
- [AWS SES SMTP Interface](https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp.html)
