---
title: "Postfix SASL Authentication - Complete Guide"
description: "Comprehensive guide for implementing SASL authentication in Postfix for secure SMTP authentication with Cyrus SASL, Dovecot, LDAP, and database backends"
author: "Joseph Streeter"
ms.date: 01/13/2026
ms.topic: guide
keywords: postfix, sasl, smtp authentication, cyrus sasl, dovecot sasl, ldap, active directory, mysql, postgresql
---

This comprehensive guide covers implementing SASL (Simple Authentication
and Security Layer) in Postfix to secure SMTP authentication, allowing
legitimate users to send email while preventing unauthorized relay.

## Overview

### What is SASL?

SASL (Simple Authentication and Security Layer) is a framework for
adding authentication support to connection-based protocols. In email
systems, SASL enables clients to authenticate to the mail server before
sending messages, ensuring only authorized users can relay mail through
your server.

### Why Use SASL Authentication?

**Security Benefits:**

- Prevents open relay exploitation
- Authenticates users before allowing mail submission
- Protects against unauthorized use of your mail server
- Enables secure remote mail submission
- Supports encrypted authentication mechanisms

**Functional Benefits:**

- Allows legitimate users to send mail from anywhere
- Supports mobile and remote users
- Works with email clients (Outlook, Thunderbird, etc.)
- Enables authenticated submission on port 587
- Integrates with existing user databases (LDAP, SQL, etc.)

### SASL Authentication Flow

```text
┌─────────────────────────────────────────────────────────────────┐
│                  SASL Authentication Process                    │
└─────────────────────────────────────────────────────────────────┘

Client Connection Flow:
──────────────────────

1. Client connects to Postfix (port 587/465)
        ↓
2. Client sends EHLO command
        ↓
3. Server responds with capabilities including AUTH
   250-AUTH PLAIN LOGIN CRAM-MD5 DIGEST-MD5
        ↓
4. Client sends AUTH command with credentials
   AUTH PLAIN AHVzZXJuYW1lAHBhc3N3b3Jk
        ↓
5. Postfix passes credentials to SASL library
        ↓
6. SASL verifies credentials against backend
   • Local user database (sasldb)
   • Dovecot authentication
   • LDAP/Active Directory
   • MySQL/PostgreSQL database
        ↓
7. SASL returns authentication result
        ↓
8. If authenticated: Client can send mail
   If failed: 535 Authentication failed
```

### SASL Backend Options

**Cyrus SASL:**

- Standalone SASL implementation
- Supports multiple authentication mechanisms
- Can authenticate against local databases, LDAP, PAM, etc.
- Most common for Postfix SASL

**Dovecot SASL:**

- Uses Dovecot's authentication system
- Ideal when Dovecot is already installed for IMAP/POP3
- Shares authentication database with mail retrieval
- Simpler configuration when using Dovecot

**Authentication Backends:**

- **sasldb** - Local Berkeley DB database
- **PAM** - Pluggable Authentication Modules
- **LDAP** - Directory services (Active Directory, OpenLDAP)
- **SQL** - MySQL, PostgreSQL, SQLite
- **Dovecot** - Dovecot authentication socket

## Prerequisites

Before beginning, ensure you have:

- ✅ Working Postfix installation (see [Postfix Guide](index.md))
- ✅ Root or sudo access to the mail server
- ✅ TLS/SSL configured for secure authentication
- ✅ Decision on authentication backend (Cyrus SASL or Dovecot)
- ✅ Existing user database or directory service (if applicable)

**Security Warning:**

Never enable SASL authentication without TLS/SSL encryption.
Unencrypted authentication exposes passwords to network sniffing.

## Cyrus SASL Installation and Configuration

### Cyrus Installation

#### Ubuntu/Debian

```bash
# Update package lists
sudo apt update

# Install Cyrus SASL packages
sudo apt install sasl2-bin libsasl2-2 libsasl2-modules \
libsasl2-modules-sql -y

# Install additional modules based on your needs
# For LDAP authentication
sudo apt install libsasl2-modules-ldap -y

# For GSSAPI (Kerberos) authentication
sudo apt install libsasl2-modules-gssapi-mit -y

# Verify installation
saslfinger -s
```

#### RHEL/CentOS/Rocky Linux

```bash
# Install Cyrus SASL
sudo dnf install cyrus-sasl cyrus-sasl-plain cyrus-sasl-md5 \
cyrus-sasl-lib -y

# For LDAP authentication
sudo dnf install cyrus-sasl-ldap -y

# For GSSAPI authentication
sudo dnf install cyrus-sasl-gssapi -y

# For SQL authentication
sudo dnf install cyrus-sasl-sql -y

# Enable and start saslauthd
sudo systemctl enable saslauthd
sudo systemctl start saslauthd
```

### Basic Cyrus SASL Configuration

#### Step 1: Configure Postfix for SASL

```bash
# Edit Postfix main configuration
sudo nano /etc/postfix/main.cf
```

**Add SASL Configuration:**

```bash
# /etc/postfix/main.cf - SASL Authentication

# Enable SASL authentication
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = cyrus
smtpd_sasl_path = smtpd

# Security options
smtpd_sasl_security_options = noanonymous, noplaintext
smtpd_sasl_tls_security_options = noanonymous

# Allow authenticated clients to relay
smtpd_relay_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination

# Broken client compatibility
broken_sasl_auth_clients = yes

# SASL authentication mechanisms
smtpd_sasl_local_domain = $myhostname
```

**Configuration Parameters Explained:**

- `smtpd_sasl_auth_enable = yes` - Enable SASL authentication
- `smtpd_sasl_type = cyrus` - Use Cyrus SASL library
- `smtpd_sasl_path = smtpd` - Configuration name in SASL
- `smtpd_sasl_security_options = noanonymous, noplaintext` -
Disallow anonymous and plaintext (over non-TLS)
- `smtpd_sasl_tls_security_options = noanonymous` - Allow plaintext
over TLS
- `permit_sasl_authenticated` - Allow authenticated users to relay
- `broken_sasl_auth_clients = yes` - Support older Microsoft clients

#### Step 2: Create SASL Configuration File

```bash
# Create SASL configuration for Postfix
sudo nano /etc/postfix/sasl/smtpd.conf
```

**Basic sasldb Configuration:**

```bash
# /etc/postfix/sasl/smtpd.conf
pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5
```

**Configuration Options:**

- `pwcheck_method: auxprop` - Use auxiliary property plugin
- `auxprop_plugin: sasldb` - Use sasldb database
- `mech_list` - Supported authentication mechanisms

#### Step 3: Create User Database

```bash
# Add users to sasldb
# Format: saslpasswd2 -c -u domain username
sudo saslpasswd2 -c -u $(postconf -h myhostname) user1

# You will be prompted to enter password twice
# Password:
# Again (for verification):

# Add more users
sudo saslpasswd2 -c -u $(postconf -h myhostname) user2

# List users in sasldb
sudo sasldblistusers2

# Expected output:
# user1@mail.example.com: userPassword
# user2@mail.example.com: userPassword

# Set proper permissions
sudo chown postfix:postfix /etc/sasldb2
sudo chmod 640 /etc/sasldb2
```

#### Step 4: Configure Submission Port

```bash
# Edit master.cf to configure port 587 for authenticated submission
sudo nano /etc/postfix/master.cf
```

**Enable and Configure Submission Service:**

```bash
# /etc/postfix/master.cf

# Submission port (587) - for authenticated users
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

# SMTPS port (465) - for authenticated users (deprecated but common)
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_helo_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
```

**Key Settings:**

- `smtpd_tls_security_level=encrypt` - Require TLS encryption
- `smtpd_sasl_auth_enable=yes` - Enable SASL on this port
- `smtpd_tls_auth_only=yes` - Only allow authentication over TLS
- `permit_sasl_authenticated` - Allow authenticated clients

#### Step 5: Restart Services

```bash
# Check Postfix configuration
sudo postfix check

# Restart Postfix
sudo systemctl restart postfix

# Check service status
sudo systemctl status postfix

# Verify submission port is listening
ss -tlnp | grep :587
ss -tlnp | grep :465
```

### SASL with PAM Authentication

#### Configuration

```bash
# /etc/postfix/sasl/smtpd.conf
pwcheck_method: saslauthd
mech_list: PLAIN LOGIN
```

```bash
# Configure saslauthd to use PAM
sudo nano /etc/default/saslauthd
```

**Ubuntu/Debian:**

```bash
# /etc/default/saslauthd
START=yes
DESC="SASL Authentication Daemon"
NAME="saslauthd"
MECHANISMS="pam"
MECH_OPTIONS=""
THREADS=5
OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"
```

**RHEL/CentOS:**

```bash
# /etc/sysconfig/saslauthd
SOCKETDIR=/var/spool/postfix/var/run/saslauthd
MECH=pam
FLAGS=
```

```bash
# Create socket directory
sudo mkdir -p /var/spool/postfix/var/run/saslauthd

# Set permissions
sudo chown -R root:sasl /var/spool/postfix/var/run/saslauthd
sudo chmod 750 /var/spool/postfix/var/run/saslauthd

# Add postfix to sasl group
sudo usermod -aG sasl postfix

# Restart saslauthd
sudo systemctl restart saslauthd

# Verify saslauthd is running
sudo systemctl status saslauthd

# Restart Postfix
sudo systemctl restart postfix
```

### SASL with LDAP Authentication

#### Configuration for Active Directory

```bash
# /etc/postfix/sasl/smtpd.conf
pwcheck_method: saslauthd
mech_list: PLAIN LOGIN
```

```bash
# Configure saslauthd for LDAP
sudo nano /etc/saslauthd.conf
```

**LDAP Configuration:**

```bash
# /etc/saslauthd.conf

# LDAP server configuration
ldap_servers: ldap://dc1.example.com ldap://dc2.example.com
ldap_version: 3
ldap_timeout: 10
ldap_time_limit: 10

# Bind credentials for LDAP queries
ldap_bind_dn: cn=postfix,ou=Service Accounts,dc=example,dc=com
ldap_bind_pw: SecurePassword123

# Search parameters
ldap_search_base: ou=Users,dc=example,dc=com
ldap_filter: (sAMAccountName=%u)
ldap_scope: sub

# Use StartTLS for secure connection
ldap_start_tls: yes
ldap_tls_check_peer: yes
ldap_tls_cacert_file: /etc/ssl/certs/ca-certificates.crt

# Active Directory specific
ldap_referrals: no
ldap_restart: yes

# Authentication method
ldap_auth_method: bind
```

**For OpenLDAP:**

```bash
# /etc/saslauthd.conf

ldap_servers: ldap://ldap.example.com
ldap_version: 3
ldap_bind_dn: cn=admin,dc=example,dc=com
ldap_bind_pw: AdminPassword
ldap_search_base: ou=People,dc=example,dc=com
ldap_filter: (uid=%u)
ldap_auth_method: bind
ldap_start_tls: yes
```

```bash
# Update saslauthd configuration
sudo nano /etc/default/saslauthd
```

```bash
# /etc/default/saslauthd
START=yes
MECHANISMS="ldap"
OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd -r"
```

```bash
# Restart services
sudo systemctl restart saslauthd
sudo systemctl restart postfix

# Test LDAP authentication
testsaslauthd -u username -p password -s smtp
# Expected output for success: 0: OK "Success."
# Expected output for failure: 0: NO "authentication failed"
```

### SASL with MySQL Authentication

#### Database Setup

```bash
# Connect to MySQL
sudo mysql -u root -p
```

```sql
-- Create database and user
CREATE DATABASE mailauth;
CREATE USER 'mailadmin'@'localhost' IDENTIFIED BY 'SecurePassword';
GRANT ALL PRIVILEGES ON mailauth.* TO 'mailadmin'@'localhost';
FLUSH PRIVILEGES;

-- Use the database
USE mailauth;

-- Create users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    domain VARCHAR(255) NOT NULL,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    enabled TINYINT(1) DEFAULT 1
);

-- Add test user (password: testpass123)
-- Using MySQL's PASSWORD function or crypt()
INSERT INTO users (username, password, domain, enabled)
VALUES ('testuser',
ENCRYPT('testpass123', CONCAT('$6$', SHA(RAND()))),
'example.com', 1);

-- Query to verify
SELECT username, domain FROM users WHERE enabled = 1;
```

#### SASL Configuration

```bash
# Install SQL module
sudo apt install libsasl2-modules-sql -y  # Ubuntu/Debian
sudo dnf install cyrus-sasl-sql -y        # RHEL/CentOS
```

```bash
# /etc/postfix/sasl/smtpd.conf
pwcheck_method: auxprop
auxprop_plugin: sql
mech_list: PLAIN LOGIN CRAM-MD5
sql_engine: mysql
sql_hostnames: localhost
sql_database: mailauth
sql_user: mailadmin
sql_passwd: SecurePassword
sql_select: SELECT password FROM users WHERE username='%u' AND
domain='%r' AND enabled=1
```

#### Postfix Configuration

```bash
# /etc/postfix/main.cf
# Add to existing SASL configuration

smtpd_sasl_auth_enable = yes
smtpd_sasl_type = cyrus
smtpd_sasl_path = smtpd
smtpd_sasl_security_options = noanonymous, noplaintext
smtpd_sasl_tls_security_options = noanonymous
broken_sasl_auth_clients = yes
```

```bash
# Restart Postfix
sudo systemctl restart postfix
```

## Dovecot SASL Configuration

### When to Use Dovecot SASL

Use Dovecot SASL when:

- Dovecot is already installed for IMAP/POP3
- You want unified authentication for sending and receiving
- You prefer simpler configuration than Cyrus SASL
- You need passdb/userdb flexibility

### Dovecot Installation

```bash
# Install Dovecot (if not already installed)
sudo apt install dovecot-core dovecot-imapd -y  # Ubuntu/Debian
sudo dnf install dovecot -y                      # RHEL/CentOS
```

### Dovecot Configuration

```bash
# Edit Dovecot configuration
sudo nano /etc/dovecot/conf.d/10-master.conf
```

**Enable SASL Authentication Socket:**

```bash
# /etc/dovecot/conf.d/10-master.conf

service auth {
  # Postfix SMTP auth socket
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
```

```bash
# Configure authentication mechanisms
sudo nano /etc/dovecot/conf.d/10-auth.conf
```

```bash
# /etc/dovecot/conf.d/10-auth.conf

# Enable PLAIN and LOGIN mechanisms
auth_mechanisms = plain login

# Allow plaintext authentication only with TLS
disable_plaintext_auth = yes
```

### Postfix Configuration for Dovecot SASL

```bash
# Edit Postfix main configuration
sudo nano /etc/postfix/main.cf
```

```bash
# /etc/postfix/main.cf - Dovecot SASL Configuration

# Enable SASL authentication via Dovecot
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth

# Security options
smtpd_sasl_security_options = noanonymous
smtpd_sasl_tls_security_options = noanonymous

# Allow authenticated clients to relay
smtpd_relay_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination

# Broken client compatibility
broken_sasl_auth_clients = yes
```

```bash
# Restart services
sudo systemctl restart dovecot
sudo systemctl restart postfix

# Verify socket exists
ls -l /var/spool/postfix/private/auth
# Should show: srw-rw---- postfix postfix
```

### Dovecot with Virtual Users

```bash
# Configure virtual users
sudo nano /etc/dovecot/conf.d/auth-passwdfile.conf.ext
```

```bash
# /etc/dovecot/conf.d/auth-passwdfile.conf.ext

passdb {
  driver = passwd-file
  args = scheme=CRYPT username_format=%u /etc/dovecot/users
}

userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
}
```

```bash
# Create users file
sudo nano /etc/dovecot/users
```

```bash
# /etc/dovecot/users
# Format: user@domain:password_hash:::::

# Generate password hash
doveadm pw -s SHA512-CRYPT
# Enter password and copy the hash

# Add users
user1@example.com:{SHA512-CRYPT}$6$...hash...:::::
user2@example.com:{SHA512-CRYPT}$6$...hash...:::::
```

```bash
# Set permissions
sudo chmod 640 /etc/dovecot/users
sudo chown root:dovecot /etc/dovecot/users
```

## Testing SASL Authentication

### Test 1: Check SASL Mechanisms

```bash
# Connect to submission port and check AUTH methods
telnet localhost 587

# Commands to type:
EHLO test.example.com

# Expected response includes:
# 250-AUTH PLAIN LOGIN CRAM-MD5 DIGEST-MD5
# 250-AUTH=PLAIN LOGIN CRAM-MD5 DIGEST-MD5

# Type QUIT to exit
QUIT
```

### Test 2: Test with Base64 Encoding

```bash
# Generate Base64 encoded credentials
# Format: \0username\0password
printf '\0username\0password' | base64
# Output: AHVzZXJuYW1lAHBhc3N3b3Jk

# Test authentication
telnet localhost 587

# Commands:
EHLO test.example.com
AUTH PLAIN AHVzZXJuYW1lAHBhc3N3b3Jk

# Expected success: 235 2.7.0 Authentication successful
# Expected failure: 535 5.7.8 Authentication failed

QUIT
```

### Test 3: Test with swaks

```bash
# Install swaks (Swiss Army Knife for SMTP)
sudo apt install swaks -y

# Test with PLAIN authentication
swaks --to user@example.com \
      --from sender@example.com \
      --server localhost:587 \
      --auth PLAIN \
      --auth-user testuser \
      --auth-password testpass123 \
      --tls

# Test with LOGIN authentication
swaks --to user@example.com \
      --from sender@example.com \
      --server localhost:587 \
      --auth LOGIN \
      --auth-user testuser \
      --auth-password testpass123 \
      --tls

# Successful output shows: "250 2.0.0 Ok: queued as ..."
```

### Test 4: Test saslauthd Directly

```bash
# Test saslauthd authentication (Cyrus SASL only)
testsaslauthd -u username -p password -s smtp

# Expected success: 0: OK "Success."
# Expected failure: 0: NO "authentication failed"

# With debug output
testsaslauthd -u username -p password -s smtp -d
```

### Test 5: Check Logs

```bash
# Monitor Postfix logs
sudo tail -f /var/log/mail.log | grep -i sasl

# Successful authentication shows:
# postfix/smtpd[12345]: client=unknown[192.168.1.100],
# sasl_method=PLAIN, sasl_username=user@example.com

# Failed authentication shows:
# postfix/smtpd[12345]: warning: unknown[192.168.1.100]:
# SASL PLAIN authentication failed: authentication failure

# Check saslauthd logs
sudo journalctl -u saslauthd -f
```

### Test 6: Email Client Configuration

**Thunderbird:**

- Outgoing Server (SMTP): mail.example.com
- Port: 587
- Connection security: STARTTLS
- Authentication method: Normal password
- User Name: username or <user@example.com>

**Outlook:**

- Outgoing mail server: mail.example.com
- Port: 587
- Encryption method: TLS
- Requires authentication: Yes
- Use same settings as incoming mail server: Optional

**Apple Mail:**

- SMTP Server: mail.example.com
- Port: 587
- Use TLS/SSL: Yes
- Authentication: Password
- Username: <user@example.com>

## Advanced Configuration

### Multiple Authentication Backends

```bash
# /etc/postfix/sasl/smtpd.conf
# Try multiple authentication methods in order

pwcheck_method: auxprop saslauthd
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN CRAM-MD5
saslauthd_path: /var/spool/postfix/var/run/saslauthd/mux

# This will try sasldb first, then saslauthd
```

### Realm-Based Authentication

```bash
# /etc/postfix/main.cf
# Support multiple domains with different authentication

smtpd_sasl_auth_enable = yes
smtpd_sasl_type = cyrus
smtpd_sasl_local_domain = $mydomain

# Client must include realm in username
# Format: username@realm
```

### Authentication Rate Limiting

```bash
# /etc/postfix/main.cf
# Limit authentication attempts to prevent brute force

# Use anvil to track connection rates
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 30
smtpd_client_message_rate_limit = 100
smtpd_client_recipient_rate_limit = 200
smtpd_client_event_limit_exceptions = $mynetworks

# Failed authentication delay
smtpd_error_sleep_time = 5s
smtpd_soft_error_limit = 2
smtpd_hard_error_limit = 5
smtpd_junk_command_limit = 2
```

### SASL Authentication with fail2ban

```bash
# Install fail2ban
sudo apt install fail2ban -y

# Create Postfix SASL jail
sudo nano /etc/fail2ban/jail.d/postfix-sasl.conf
```

```bash
# /etc/fail2ban/jail.d/postfix-sasl.conf

[postfix-sasl]
enabled = true
port = smtp,submission,smtps
filter = postfix-sasl
logpath = /var/log/mail.log
maxretry = 3
bantime = 3600
findtime = 600
```

```bash
# Verify filter exists
cat /etc/fail2ban/filter.d/postfix-sasl.conf

# Restart fail2ban
sudo systemctl restart fail2ban

# Check status
sudo fail2ban-client status postfix-sasl
```

### Sender Login Maps

Restrict which authenticated users can send from which addresses:

```bash
# /etc/postfix/main.cf
smtpd_sender_login_maps = hash:/etc/postfix/sender_login_maps

# Enforce sender restrictions
smtpd_sender_restrictions =
    reject_sender_login_mismatch,
    reject_authenticated_sender_login_mismatch,
    reject_unauthenticated_sender_login_mismatch
```

```bash
# /etc/postfix/sender_login_maps
# Format: email_address   allowed_sasl_username

user1@example.com       user1
user2@example.com       user2
sales@example.com       user1,user2
support@example.com     user3,user4

# Allow user1 to send from any address in domain
@example.com            user1
```

```bash
# Compile map
sudo postmap /etc/postfix/sender_login_maps

# Reload Postfix
sudo postfix reload
```

### SASL Authentication Logging

```bash
# /etc/postfix/main.cf
# Enhanced logging for authentication

# Log SASL authentication details
smtpd_sasl_authenticated_header = yes

# Add authentication information to Received header
smtpd_sasl_auth_enable = yes

# Custom logging
# View who authenticated and from where
```

**Parse authentication logs:**

```bash
# Script to monitor SASL authentication
#!/bin/bash
# /usr/local/bin/sasl-auth-monitor.sh

echo "=== SASL Authentication Report ==="
echo "Date: $(date)"
echo ""

# Successful authentications
echo "Successful Authentications:"
grep "sasl_method" /var/log/mail.log | \
    grep -v "authentication failed" | \
    awk '{print $9, $10, $11}' | \
    sort | uniq -c | sort -rn | head -20

echo ""

# Failed authentications
echo "Failed Authentications:"
grep "authentication failed" /var/log/mail.log | \
    grep -oP '(?<=unknown\[)[^]]+' | \
    sort | uniq -c | sort -rn | head -20

echo ""

# Authentication methods used
echo "Authentication Methods:"
grep "sasl_method" /var/log/mail.log | \
    grep -oP 'sasl_method=\K\w+' | \
    sort | uniq -c
```

## Security Best Practices

### TLS/SSL Requirements

```bash
# /etc/postfix/main.cf
# Always require TLS for SASL authentication

# Require TLS on submission port
smtpd_tls_security_level = encrypt

# Only allow authentication over TLS
smtpd_sasl_tls_security_options = noanonymous
smtpd_tls_auth_only = yes

# Disable plaintext authentication without TLS
smtpd_sasl_security_options = noanonymous, noplaintext
```

### Strong Cipher Configuration

```bash
# /etc/postfix/main.cf
# Use strong TLS ciphers

smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_mandatory_ciphers = high
smtpd_tls_ciphers = high
tls_high_cipherlist = ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-
GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
```

### File Permissions

```bash
# SASL configuration files
sudo chmod 640 /etc/postfix/sasl/smtpd.conf
sudo chown root:postfix /etc/postfix/sasl/smtpd.conf

# SASL database (if using sasldb)
sudo chmod 640 /etc/sasldb2
sudo chown postfix:postfix /etc/sasldb2

# Saslauthd socket directory
sudo chmod 750 /var/spool/postfix/var/run/saslauthd
sudo chown root:sasl /var/spool/postfix/var/run/saslauthd

# LDAP configuration with credentials
sudo chmod 600 /etc/saslauthd.conf
sudo chown root:root /etc/saslauthd.conf
```

### Password Policies

```bash
# For LDAP/AD authentication, enforce strong passwords:
# - Minimum 12 characters
# - Complexity requirements
# - Regular password changes
# - Account lockout after failed attempts

# For local authentication (sasldb):
# Use strong passwords when creating users
sudo saslpasswd2 -c -u $(postconf -h myhostname) username
# Enforce minimum password length policy
```

### Network Security

```bash
# /etc/postfix/main.cf
# Restrict submission access

# Only allow submission from specific networks
submission_inet_interfaces = all

# Use firewall rules to restrict port 587/465
sudo ufw allow from any to any port 587 proto tcp
sudo ufw allow from any to any port 465 proto tcp

# Consider restricting to known networks if possible
sudo ufw allow from 192.168.1.0/24 to any port 587 proto tcp
```

## Troubleshooting

### Common Issues

#### Issue 1: Authentication Failed

**Symptoms:**

- Client receives "535 5.7.8 Authentication failed"
- Logs show "authentication failed"

**Diagnosis:**

```bash
# Check if SASL is enabled
postconf smtpd_sasl_auth_enable

# Verify SASL configuration file exists
ls -l /etc/postfix/sasl/smtpd.conf

# Check saslauthd is running (if using)
systemctl status saslauthd

# Test credentials directly
testsaslauthd -u username -p password -s smtp

# Check logs
sudo tail -50 /var/log/mail.log | grep -i sasl
```

**Solutions:**

```bash
# 1. Verify credentials are correct
# Try testing with known good credentials

# 2. Check user exists in authentication backend
sudo sasldblistusers2  # For sasldb
# Or check LDAP/SQL database

# 3. Verify permissions
sudo chmod 640 /etc/sasldb2
sudo chown postfix:postfix /etc/sasldb2

# 4. Check saslauthd socket path
grep saslauthd_path /etc/postfix/sasl/smtpd.conf
ls -l /var/spool/postfix/var/run/saslauthd/mux

# 5. Verify postfix is in sasl group
groups postfix | grep sasl

# 6. Restart services
sudo systemctl restart saslauthd postfix
```

#### Issue 2: No AUTH Command Available

**Symptoms:**

- EHLO response doesn't show AUTH capabilities
- Client says "Server doesn't support authentication"

**Diagnosis:**

```bash
# Test EHLO response
telnet localhost 587
EHLO test.example.com

# Check if SASL is enabled
postconf smtpd_sasl_auth_enable

# Verify submission port configuration
postconf -M submission/inet

# Check TLS configuration
postconf smtpd_tls_cert_file smtpd_tls_key_file
```

**Solutions:**

```bash
# 1. Enable SASL authentication
sudo postconf -e 'smtpd_sasl_auth_enable = yes'

# 2. Ensure TLS is configured (required for AUTH)
sudo postconf -e 'smtpd_tls_cert_file = /etc/ssl/certs/mail.crt'
sudo postconf -e 'smtpd_tls_key_file = /etc/ssl/private/mail.key'

# 3. Configure submission port properly
# Edit /etc/postfix/master.cf and enable submission service

# 4. Reload Postfix
sudo postfix reload

# 5. Test again
telnet localhost 587
```

#### Issue 3: SASL Library Not Found

**Symptoms:**

- Postfix logs: "warning: SASL authentication failure: cannot connect
to saslauthd server"
- Postfix logs: "warning: unknown SASL plug-in"

**Diagnosis:**

```bash
# Check installed SASL libraries
dpkg -l | grep sasl    # Ubuntu/Debian
rpm -qa | grep sasl    # RHEL/CentOS

# Verify saslauthd is running
systemctl status saslauthd

# Check socket path
ls -l /var/run/saslauthd/
ls -l /var/spool/postfix/var/run/saslauthd/
```

**Solutions:**

```bash
# 1. Install required SASL packages
sudo apt install sasl2-bin libsasl2-2 libsasl2-modules -y

# 2. Start saslauthd
sudo systemctl enable saslauthd
sudo systemctl start saslauthd

# 3. Create proper socket directory
sudo mkdir -p /var/spool/postfix/var/run/saslauthd
sudo ln -s /var/spool/postfix/var/run/saslauthd /var/run/saslauthd

# 4. Update socket path in saslauthd config
# Edit /etc/default/saslauthd (Ubuntu) or /etc/sysconfig/saslauthd
# Set: OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"

# 5. Restart services
sudo systemctl restart saslauthd postfix
```

#### Issue 4: LDAP Authentication Fails

**Symptoms:**

- testsaslauthd fails with "authentication failed"
- Logs show "ldap_bind failed"

**Diagnosis:**

```bash
# Test LDAP connection
ldapsearch -x -H ldap://dc.example.com \
           -D "cn=postfix,ou=Service Accounts,dc=example,dc=com" \
           -w password \
           -b "ou=Users,dc=example,dc=com" \
           "(sAMAccountName=username)"

# Check saslauthd configuration
cat /etc/saslauthd.conf

# Enable debug logging
sudo saslauthd -d -a ldap -c
```

**Solutions:**

```bash
# 1. Verify LDAP credentials
# Test bind DN and password manually with ldapsearch

# 2. Check LDAP filter syntax
# Ensure filter in saslauthd.conf matches your directory structure

# 3. Verify network connectivity
telnet dc.example.com 389

# 4. Check StartTLS/SSL settings
# If using StartTLS, ensure certificates are valid

# 5. Update saslauthd.conf with correct settings
sudo nano /etc/saslauthd.conf

# 6. Restart saslauthd with debug
sudo systemctl stop saslauthd
sudo saslauthd -d -a ldap

# Test and observe output
testsaslauthd -u username -p password -s smtp
```

#### Issue 5: Permission Denied Errors

**Symptoms:**

- Postfix logs: "warning: SASL authentication failure: Permission
denied"
- saslauthd logs: "permission denied"

**Solutions:**

```bash
# 1. Fix sasldb permissions
sudo chown postfix:postfix /etc/sasldb2
sudo chmod 640 /etc/sasldb2

# 2. Fix socket permissions
sudo chown root:sasl /var/spool/postfix/var/run/saslauthd
sudo chmod 750 /var/spool/postfix/var/run/saslauthd

# 3. Add postfix to sasl group
sudo usermod -aG sasl postfix

# 4. Fix SASL config permissions
sudo chown root:postfix /etc/postfix/sasl/smtpd.conf
sudo chmod 640 /etc/postfix/sasl/smtpd.conf

# 5. Check SELinux context (RHEL/CentOS)
ls -Z /etc/sasldb2
sudo restorecon -v /etc/sasldb2

# 6. Restart Postfix
sudo systemctl restart postfix
```

### Debug Mode

```bash
# Enable verbose logging in Postfix
sudo postconf -e 'smtpd_sasl_auth_enable = yes'
sudo postconf -e 'smtp_sasl_loglevel = 2'

# Run saslauthd in debug mode
sudo systemctl stop saslauthd
sudo saslauthd -d -a pam -m /var/spool/postfix/var/run/saslauthd

# In another terminal, test authentication
testsaslauthd -u username -p password -s smtp

# Watch Postfix logs
sudo tail -f /var/log/mail.log | grep -i sasl
```

### Verification Commands

```bash
# Check SASL mechanisms available
postconf smtpd_sasl_security_options

# List users in sasldb
sudo sasldblistusers2

# Test specific user
testsaslauthd -u user@example.com -p password -s smtp

# Check authentication method
postconf smtpd_sasl_type smtpd_sasl_path

# Verify socket exists
ls -l /var/spool/postfix/var/run/saslauthd/mux

# Check submission port configuration
postconf -Mf submission/inet
```

## Monitoring and Maintenance

### Regular Health Checks

```bash
# Daily monitoring script
#!/bin/bash
# /usr/local/bin/sasl-health-check.sh

echo "=== SASL Authentication Health Check ==="
echo "Date: $(date)"
echo ""

# Check saslauthd service (if used)
if systemctl list-units --type=service | grep -q saslauthd; then
    if systemctl is-active --quiet saslauthd; then
        echo "✓ saslauthd service: Running"
    else
        echo "✗ saslauthd service: Stopped"
    fi
fi

# Check SASL configuration
if [ -f /etc/postfix/sasl/smtpd.conf ]; then
    echo "✓ SASL configuration: Present"
else
    echo "✗ SASL configuration: Missing"
fi

# Check authentication statistics
AUTH_SUCCESS=$(grep "sasl_method" /var/log/mail.log | \
    grep -v "failed" | wc -l)
AUTH_FAILED=$(grep "authentication failed" /var/log/mail.log | wc -l)

echo "ℹ Successful authentications today: $AUTH_SUCCESS"
echo "⚠ Failed authentications today: $AUTH_FAILED"

# Check for brute force attempts
BRUTE_FORCE=$(grep "authentication failed" /var/log/mail.log | \
    cut -d'[' -f2 | cut -d']' -f1 | sort | uniq -c | \
    awk '$1 > 10 {print $1, $2}')

if [ -n "$BRUTE_FORCE" ]; then
    echo "⚠ Potential brute force attempts detected:"
    echo "$BRUTE_FORCE"
fi

echo ""
echo "Health check completed"
```

### Performance Metrics

```bash
# Monitor authentication performance
# Check authentication rate
grep "sasl_method" /var/log/mail.log | \
    awk '{print $1, $2, $3}' | \
    uniq -c

# Average authentications per hour
AUTHS_PER_HOUR=$(grep "sasl_method" /var/log/mail.log | \
    wc -l)
echo "Authentications per hour: $AUTHS_PER_HOUR"
```

### User Management

```bash
# Add user to sasldb
sudo saslpasswd2 -c -u $(postconf -h myhostname) newuser

# Change user password
sudo saslpasswd2 -u $(postconf -h myhostname) username

# Delete user
sudo saslpasswd2 -d -u $(postconf -h myhostname) username

# List all users
sudo sasldblistusers2

# Backup sasldb
sudo cp /etc/sasldb2 /backup/sasldb2.$(date +%Y%m%d)

# Restore sasldb
sudo cp /backup/sasldb2.20260113 /etc/sasldb2
sudo chown postfix:postfix /etc/sasldb2
sudo chmod 640 /etc/sasldb2
```

## Quick Reference

### Essential Commands

```bash
# Service Management
systemctl status saslauthd           # Check status
systemctl start saslauthd            # Start service
systemctl stop saslauthd             # Stop service
systemctl restart saslauthd          # Restart service

# User Management (sasldb)
saslpasswd2 -c -u domain user        # Create user
saslpasswd2 -d -u domain user        # Delete user
sasldblistusers2                     # List users

# Testing
testsaslauthd -u user -p pass -s smtp    # Test auth
telnet localhost 587                      # Test connection
swaks --auth PLAIN --auth-user user ...  # Test with swaks

# Debugging
tail -f /var/log/mail.log | grep sasl    # Watch logs
saslauthd -d -a pam                       # Debug mode
postconf -n | grep sasl                   # Show SASL config
```

### Configuration File Locations

| File | Purpose |
| --- | --- |
| `/etc/postfix/main.cf` | Postfix SASL configuration |
| `/etc/postfix/master.cf` | Submission port configuration |
| `/etc/postfix/sasl/smtpd.conf` | SASL plugin configuration |
| `/etc/sasldb2` | SASL user database |
| `/etc/saslauthd.conf` | saslauthd configuration (LDAP) |
| `/etc/default/saslauthd` | saslauthd options (Ubuntu) |
| `/etc/sysconfig/saslauthd` | saslauthd options (RHEL) |

### Common Authentication Mechanisms

| Mechanism | Security | Notes |
| --- | --- | --- |
| PLAIN | Low (requires TLS) | Simple username/password |
| LOGIN | Low (requires TLS) | Similar to PLAIN |
| CRAM-MD5 | Medium | Challenge-response, no cleartext |
| DIGEST-MD5 | Medium | Challenge-response |
| GSSAPI | High | Kerberos-based |

### Troubleshooting Checklist

- [ ] Postfix SASL authentication is enabled
- [ ] SASL configuration file exists
- [ ] saslauthd service is running (if using)
- [ ] Socket path is correct and accessible
- [ ] Postfix user is in sasl group
- [ ] File permissions are correct (640 for sensitive files)
- [ ] TLS/SSL is configured and working
- [ ] Submission port (587) is configured in master.cf
- [ ] Users exist in authentication backend
- [ ] Test authentication succeeds with testsaslauthd
- [ ] No authentication errors in logs
- [ ] Email clients can authenticate successfully

## Related Documentation

- [Postfix Mail Server Guide](index.md) - Complete Postfix configuration
- [Postfix with OpenDKIM](dkim.md) - DKIM email signing
- [Email Authentication (SPF, DKIM, DMARC)](../smtp/authentication.md)

## External Resources

### Official Documentation

- [Postfix SASL Howto](http://www.postfix.org/SASL_README.html)
- [Cyrus SASL Documentation](https://www.cyrusimap.org/sasl/)
- [Dovecot SASL](<https://doc.dovecot.org/configuration_manual/howto/>
postfix_and_dovecot_sasl/)

### Community Resources

- [Postfix Users Mailing List](http://www.postfix.org/lists.html)
- [Stack Overflow - Postfix SASL](<https://stackoverflow.com/questions/>
tagged/postfix+sasl)

---

**Last Updated:** January 13, 2026

> This comprehensive guide covers SASL authentication implementation with
> Postfix for secure SMTP submission. Properly configured SASL prevents
> unauthorized relay while enabling legitimate users to send email from
> anywhere.
