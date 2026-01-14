---
title: "Postfix Configuration Reference"
description: "Comprehensive configuration reference for Postfix mail server including basic setup, TLS, relay, virtual domains, and performance tuning"
author: "Joseph Streeter"
ms.date: 01/13/2026
ms.topic: guide
keywords: postfix, configuration, main.cf, master.cf, tls, relay, virtual domains, performance
---

Comprehensive configuration guide for Postfix mail server covering
essential setup, security, and optimization.

## Basic Configuration

Basic Postfix configuration in `/etc/postfix/main.cf`.

### Hostname and Domain Settings

```bash
# /etc/postfix/main.cf

# System hostname
myhostname = mail.example.com

# Domain name
mydomain = example.com

# Origin domain for locally-posted mail
myorigin = $mydomain
```

### Network Configuration

```bash
# Listen on all interfaces
inet_interfaces = all

# Support both IPv4 and IPv6
inet_protocols = all

# Networks allowed to relay
mynetworks = 127.0.0.0/8 [::1]/128
```

### Mail Delivery

```bash
# Local delivery
mydestination = $myhostname, localhost.$mydomain, localhost

# Mailbox location
home_mailbox = Maildir/

# Alias maps
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
```

## TLS Configuration

Secure connections with TLS/SSL encryption.

### TLS Settings

```bash
# /etc/postfix/main.cf

# TLS parameters
smtpd_tls_cert_file = /etc/ssl/certs/mail.crt
smtpd_tls_key_file = /etc/ssl/private/mail.key
smtpd_tls_security_level = may

# TLS protocols
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1

# Session cache
smtpd_tls_session_cache_database =
btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database =
btree:${data_directory}/smtp_scache

# Logging
smtpd_tls_loglevel = 1
```

### Certificate Configuration

```bash
# Let's Encrypt certificates
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.example.com/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/mail.example.com/privkey.pem
smtpd_tls_CAfile = /etc/letsencrypt/live/mail.example.com/chain.pem
```

## Relay Configuration

Configure Postfix to relay mail through another server.

### Smart Host Relay

```bash
# /etc/postfix/main.cf

# Relay all mail through smart host
relayhost = [smtp.example.com]:587

# SASL authentication for relay
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
```

### Relay Authentication

```bash
# /etc/postfix/sasl_passwd
[smtp.example.com]:587 username:password

# Compile the database
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd*
```

## Virtual Domains

Host multiple domains on one server.

### Virtual Mailbox Domains

```bash
# /etc/postfix/main.cf

# Virtual domains
virtual_mailbox_domains = hash:/etc/postfix/virtual_domains
virtual_mailbox_base = /var/mail/vhosts
virtual_mailbox_maps = hash:/etc/postfix/vmailbox
virtual_alias_maps = hash:/etc/postfix/virtual

# Virtual user
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000
```

### Domain Configuration Files

```bash
# /etc/postfix/virtual_domains
example.com     OK
example.net     OK

# /etc/postfix/vmailbox
user1@example.com    example.com/user1/
user2@example.net    example.net/user2/

# /etc/postfix/virtual
# Aliases
admin@example.com    user1@example.com
sales@example.com    user1@example.com,user2@example.com
```

```bash
# Compile databases
sudo postmap /etc/postfix/virtual_domains
sudo postmap /etc/postfix/vmailbox
sudo postmap /etc/postfix/virtual
```

## Performance Tuning

Optimize Postfix for high-volume environments.

### Queue Management

```bash
# /etc/postfix/main.cf

# Queue lifetime
maximal_queue_lifetime = 5d
bounce_queue_lifetime = 5d

# Queue delivery limits
default_destination_concurrency_limit = 20
smtp_destination_concurrency_limit = 10

# Message size limits
message_size_limit = 52428800
mailbox_size_limit = 0
```

### Connection Limits

```bash
# Rate limiting
smtpd_client_connection_count_limit = 50
smtpd_client_connection_rate_limit = 100
smtpd_client_message_rate_limit = 500
smtpd_client_recipient_rate_limit = 1000
```

### Process Tuning

```bash
# /etc/postfix/master.cf

# Increase process limits for high volume
smtp      inet  n       -       y       -       -       smtpd
  -o smtpd_client_connection_count_limit=50

# Queue manager
qmgr      unix  n       -       n       300     1       qmgr
```

## Related Documentation

- [Postfix Overview](index.md) - Complete Postfix guide
- [Postfix SASL Authentication](sasl.md) - SMTP authentication
- [Postfix with OpenDKIM](dkim.md) - Email signing

## External Resources

- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [Postfix Configuration Parameters](http://www.postfix.org/postconf.5.html)

---

**Last Updated:** January 13, 2026

> This configuration reference provides essential Postfix setup patterns
> for common deployment scenarios. Refer to the main Postfix guide for
> detailed explanations and advanced configurations.
