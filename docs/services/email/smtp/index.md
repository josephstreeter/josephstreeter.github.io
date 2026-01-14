---
title: "SMTP Protocol"
description: "Documentation for Simple Mail Transfer Protocol (SMTP) implementation, configuration, and troubleshooting"
tags: ["smtp", "email", "mail-transfer", "protocol", "messaging"]
category: "services"
difficulty: "intermediate"
last_updated: "2026-01-13"
author: "Joseph Streeter"
---

This section covers the Simple Mail Transfer Protocol (SMTP) implementation, configuration, and management.

## Overview

SMTP (Simple Mail Transfer Protocol) is the standard protocol for sending email messages between mail servers. Defined in RFC 5321, SMTP is responsible for the reliable transmission of electronic mail across IP networks. It operates primarily on TCP port 25 for server-to-server communication and port 587 for mail submission from clients.

### How SMTP Works

SMTP uses a simple command-response protocol model where:

1. **Connection Establishment** - Client connects to server on TCP port 25 or 587
2. **Greeting Exchange** - Server sends welcome banner, client identifies itself
3. **Mail Transaction** - Client specifies sender, recipients, and message content
4. **Connection Termination** - Client closes connection gracefully

### SMTP Architecture

```text
┌──────────┐     SMTP      ┌──────────┐     SMTP      ┌──────────┐
│  Sender  │─────(587)────→│   MTA    │─────(25)─────→│   MTA    │
│  (MUA)   │               │ (Sending)│               │(Receiving)│
└──────────┘               └──────────┘               └──────────┘
                                 │                           │
                                 │                           ↓
                           DNS MX Lookup              ┌──────────┐
                                                      │   MDA    │
                                                      │(Delivery)│
                                                      └──────────┘
                                                            │
                                                            ↓
                                                      ┌──────────┐
                                                      │ Mailbox  │
                                                      └──────────┘

MUA = Mail User Agent (Email Client)
MTA = Mail Transfer Agent (Mail Server)
MDA = Mail Delivery Agent
```

## SMTP Command Flow

A typical SMTP transaction follows this command sequence:

```text
Client: [Connects to server:25]
Server: 220 mail.example.com ESMTP Postfix
Client: EHLO client.example.com
Server: 250-mail.example.com
        250-PIPELINING
        250-SIZE 52428800
        250-VRFY
        250-ETRN
        250-STARTTLS
        250-AUTH PLAIN LOGIN
        250-ENHANCEDSTATUSCODES
        250-8BITMIME
        250 DSN
Client: STARTTLS
Server: 220 2.0.0 Ready to start TLS
Client: [Establishes TLS connection]
Client: EHLO client.example.com
Server: 250-mail.example.com
        250-PIPELINING
        250-SIZE 52428800
        250-VRFY
        250-ETRN
        250-AUTH PLAIN LOGIN
        250-ENHANCEDSTATUSCODES
        250-8BITMIME
        250 DSN
Client: AUTH PLAIN [base64_credentials]
Server: 235 2.7.0 Authentication successful
Client: MAIL FROM:<sender@example.com>
Server: 250 2.1.0 Ok
Client: RCPT TO:<recipient@destination.com>
Server: 250 2.1.5 Ok
Client: DATA
Server: 354 End data with <CR><LF>.<CR><LF>
Client: From: sender@example.com
        To: recipient@destination.com
        Subject: Test Message
        
        This is the message body.
        .
Server: 250 2.0.0 Ok: queued as ABC123
Client: QUIT
Server: 221 2.0.0 Bye
```

## 🔐 Email Authentication

> **Important**: Implementing proper email authentication is critical for deliverability and security.

Modern email systems require authentication to prevent spoofing and ensure delivery. See our comprehensive guide:

### [📘 Complete Email Authentication Guide](authentication.md)

This guide covers:

- **SPF (Sender Policy Framework)** - DNS-based sender verification
- **DKIM (DomainKeys Identified Mail)** - Cryptographic message signing
- **DMARC (Domain-based Message Authentication)** - Policy and reporting framework

Without proper authentication, your emails may be rejected or marked as spam by receiving servers.

## SMTP Commands Reference

### Essential Commands

| Command | Description | Example |
| ------- | ----------- | ------- |
| `HELO <domain>` | Identify client (basic) | `HELO mail.example.com` |
| `EHLO <domain>` | Identify client (extended) | `EHLO mail.example.com` |
| `MAIL FROM:<address>` | Specify sender | `MAIL FROM:<user@example.com>` |
| `RCPT TO:<address>` | Specify recipient | `RCPT TO:<recipient@dest.com>` |
| `DATA` | Begin message content | `DATA` |
| `RSET` | Reset transaction | `RSET` |
| `VRFY <address>` | Verify address | `VRFY user@example.com` |
| `NOOP` | No operation (keepalive) | `NOOP` |
| `QUIT` | Close connection | `QUIT` |

### Extended Commands (ESMTP)

| Command | Description | Example |
| ------- | ----------- | ------- |
| `STARTTLS` | Initiate TLS encryption | `STARTTLS` |
| `AUTH <mechanism>` | Authentication | `AUTH PLAIN` / `AUTH LOGIN` |
| `SIZE <bytes>` | Declare message size | `MAIL FROM:<...> SIZE=1024` |
| `HELP [command]` | Get help | `HELP VRFY` |
| `ETRN <domain>` | Remote queue processing | `ETRN example.com` |

## SMTP Response Codes

### Success Responses (2xx)

| Code | Description | Meaning |
| ---- | ----------- | ------- |
| `220` | Service ready | Server is ready to accept connections |
| `221` | Closing connection | Server is closing the connection |
| `235` | Authentication successful | AUTH command completed successfully |
| `250` | Requested action completed | Command completed successfully |
| `251` | User not local, will forward | Recipient not on this server, forwarding |
| `252` | Cannot verify user | Cannot VRFY user, will attempt delivery |

### Intermediate Responses (3xx)

| Code | Description | Meaning |
| ---- | ----------- | ------- |
| `334` | Authentication response | Server awaits authentication data |
| `354` | Start mail input | Ready to receive message content |

### Temporary Failures (4xx)

| Code | Description | Common Causes | Troubleshooting |
| ---- | ----------- | ------------- | --------------- |
| `421` | Service not available | Server overload, maintenance | Retry later, check server status |
| `450` | Mailbox unavailable | Mailbox locked, greylisting | Retry after delay (typically 15+ minutes) |
| `451` | Local error | Server processing error | Check server logs, retry later |
| `452` | Insufficient storage | Disk full, quota exceeded | Check disk space, clear queue |
| `454` | TLS not available | TLS configuration error | Verify TLS certificates, check config |
| `455` | Server unable to accommodate | Parameters not supported | Adjust client configuration |

### Permanent Failures (5xx)

| Code | Description | Common Causes | Troubleshooting |
| ---- | ----------- | ------------- | --------------- |
| `500` | Syntax error, command unrecognized | Invalid command | Check SMTP command syntax |
| `501` | Syntax error in parameters | Malformed arguments | Verify command parameters |
| `502` | Command not implemented | Unsupported feature | Check server capabilities (EHLO) |
| `503` | Bad sequence of commands | Out-of-order commands | Follow proper SMTP sequence |
| `504` | Command parameter not implemented | Unsupported parameter | Remove unsupported options |
| `521` | Domain does not accept mail | Server doesn't accept any mail | Check recipient domain MX records |
| `530` | Authentication required | Missing or failed AUTH | Provide valid credentials |
| `535` | Authentication failed | Invalid credentials | Verify username/password |
| `550` | Mailbox unavailable | User doesn't exist, policy rejection | Verify recipient address, check SPF/DKIM |
| `551` | User not local | Relaying denied | Configure authorized relay domains |
| `552` | Exceeded storage allocation | Mailbox full | Recipient must clear mailbox |
| `553` | Mailbox name not allowed | Invalid address format | Check address syntax |
| `554` | Transaction failed | Multiple possible causes | Review full error message and logs |

## Troubleshooting SMTP Issues

### Diagnostic Approach

```text
┌─────────────────────────┐
│ Email Delivery Failed?  │
└───────────┬─────────────┘
            │
            ↓
   ┌────────────────┐
   │ Check Response │
   │      Code      │
   └────────┬───────┘
            │
     ┌──────┴──────┐
     │             │
     ↓             ↓
  4xx (Temp)    5xx (Perm)
     │             │
     ↓             ↓
 Retry Later   Investigate
               Immediately
     │             │
     ↓             ↓
 Greylist?     Auth Failed?
 Queue Full?   Bad Address?
 TLS Issue?    Policy Block?
```

### Common Issues and Solutions

#### Issue: Connection Refused (Cannot connect to port 25)

**Symptoms:**

```bash
$ telnet mail.example.com 25
Trying 192.0.2.1...
telnet: Unable to connect to remote host: Connection refused
```

**Common Causes:**

- Firewall blocking port 25
- SMTP service not running
- Wrong hostname or IP address
- ISP blocking outbound port 25

**Troubleshooting Steps:**

```bash
# 1. Verify DNS MX records
dig MX example.com +short

# 2. Test connectivity to mail server
telnet mail.example.com 25

# 3. Check if port 25 is open (alternative to telnet)
nc -zv mail.example.com 25

# 4. Trace network path
traceroute mail.example.com

# 5. Check local firewall rules
sudo iptables -L -n | grep 25

# 6. Verify SMTP service is running
sudo systemctl status postfix
# or
sudo systemctl status exim4
```

**Resolution:**

- Open firewall port 25 for outbound connections
- Start SMTP service: `sudo systemctl start postfix`
- Use port 587 (submission) if ISP blocks port 25
- Verify correct MX record hostname

#### Issue: 550 5.7.1 Relay Access Denied

**Symptoms:**

```text
>>> RCPT TO:<external@example.com>
<<< 550 5.7.1 <external@example.com>... Relaying denied
```

**Common Causes:**

- Server configured to prevent open relay
- Client not authenticated
- IP address not in allowed relay list
- Missing mynetworks configuration

**Troubleshooting Steps:**

```bash
# Check relay configuration (Postfix)
postconf | grep relay

# Check mynetworks setting
postconf mynetworks

# Test authentication
telnet mail.example.com 587
EHLO client.example.com
# Look for "AUTH" in response

# Check relay domains
postconf relay_domains
```

**Resolution (Postfix):**

```bash
# For authenticated users - /etc/postfix/main.cf
smtpd_relay_restrictions = permit_mynetworks,
                           permit_sasl_authenticated,
                           reject_unauth_destination

# Add authorized networks
mynetworks = 127.0.0.0/8, 192.168.1.0/24

# Reload configuration
sudo postfix reload
```

#### Issue: 535 Authentication Failed

**Symptoms:**

```text
>>> AUTH PLAIN <credentials>
<<< 535 5.7.8 Error: authentication failed
```

**Common Causes:**

- Incorrect username or password
- Authentication mechanism not supported
- SASL authentication not configured
- Encrypted connection required

**Troubleshooting Steps:**

```bash
# Check supported AUTH mechanisms
telnet mail.example.com 587
EHLO client.example.com
# Look for AUTH line showing available mechanisms

# Test authentication manually (base64 encode \0username\0password)
echo -ne '\000username\000password' | base64

# Check authentication logs
sudo tail -f /var/log/mail.log | grep auth
sudo journalctl -u postfix -f | grep authentication
```

**Resolution:**

- Verify credentials are correct
- Use STARTTLS before AUTH if required
- Configure SASL authentication properly
- Check password encoding (base64 for AUTH PLAIN)

#### Issue: 554 5.7.1 Message rejected due to spam content

**Symptoms:**

```text
>>> DATA
<<< 354 End data with <CR><LF>.<CR><LF>
>>> [message content]
<<< 554 5.7.1 Message rejected due to spam content
```

**Common Causes:**

- Missing or invalid SPF record
- DKIM signature missing or failing
- No DMARC policy configured
- Content triggers spam filters
- Sender reputation issues

**Troubleshooting Steps:**

```bash
# Check SPF record
dig TXT example.com +short | grep "v=spf1"

# Verify DKIM record (replace 'default' with your selector)
dig TXT default._domainkey.example.com +short

# Check DMARC record
dig TXT _dmarc.example.com +short

# Test email authentication
# Send test email to check-auth@verifier.port25.com
# Review the authentication results report

# Check sender reputation
# https://www.senderscore.org/
# https://www.senderbase.org/
```

**Resolution:**

1. **Implement email authentication** - See [Authentication Guide](authentication.md)
2. Configure SPF record: `v=spf1 ip4:192.0.2.0/24 -all`
3. Set up DKIM signing on your mail server
4. Create DMARC policy: `v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com`
5. Use spam testing tools: [Mail-Tester.com](https://www.mail-tester.com/)
6. Avoid spam trigger words in subject/body
7. Include proper unsubscribe links
8. Maintain good sender reputation

#### Issue: 450 4.7.1 Greylisting in action

**Symptoms:**

```text
>>> RCPT TO:<user@example.com>
<<< 450 4.7.1 <user@example.com>: Recipient address rejected: Greylisting in action, please try again later
```

**Common Causes:**

- Recipient server uses greylisting
- First-time sender to this recipient
- Temporary anti-spam measure

**Troubleshooting Steps:**

```bash
# Check mail queue
mailq

# View specific message details
postcat -q [QUEUE_ID]

# Monitor retry attempts
tail -f /var/log/mail.log | grep [QUEUE_ID]
```

**Resolution:**

- **This is normal behavior** - not a problem to fix
- Mail server will automatically retry (typically after 15 minutes)
- Most greylisting systems whitelist after successful retry
- Ensure your mail server has proper retry schedule configured
- Do not attempt immediate retry (will reset greylist timer)

### Testing SMTP Connectivity

#### Using Telnet

```bash
# Connect to SMTP server
telnet mail.example.com 25

# Expected response
# 220 mail.example.com ESMTP Postfix

# Identify yourself
EHLO client.example.com

# Test mail transaction
MAIL FROM:<test@yourdomain.com>
RCPT TO:<recipient@example.com>
DATA
Subject: Test Message

This is a test email.
.
QUIT
```

#### Using OpenSSL (for TLS)

```bash
# Test STARTTLS on port 587
openssl s_client -connect mail.example.com:587 -starttls smtp

# Test implicit TLS on port 465
openssl s_client -connect mail.example.com:465
```

#### Using PowerShell

```powershell
# Test SMTP connection
Test-NetConnection -ComputerName mail.example.com -Port 25

# Send test email
Send-MailMessage -From "test@yourdomain.com" `
                 -To "recipient@example.com" `
                 -Subject "Test Message" `
                 -Body "This is a test" `
                 -SmtpServer "mail.example.com" `
                 -Port 587 `
                 -UseSsl `
                 -Credential (Get-Credential)
```

#### Using curl

```bash
# Send email via SMTP with authentication
curl --url 'smtp://mail.example.com:587' \
     --ssl-reqd \
     --mail-from 'sender@yourdomain.com' \
     --mail-rcpt 'recipient@example.com' \
     --user 'username:password' \
     --upload-file email.txt

# email.txt content:
# From: sender@yourdomain.com
# To: recipient@example.com
# Subject: Test Email
#
# This is the message body.
```

### Monitoring and Logging

#### Key Log Locations

```bash
# Postfix
/var/log/mail.log           # Debian/Ubuntu
/var/log/maillog            # RHEL/CentOS

# Exim
/var/log/exim4/mainlog      # Debian/Ubuntu
/var/log/exim/main.log      # RHEL/CentOS

# Check mail queue
mailq                       # Show queued messages
postqueue -p                # Postfix queue
exim -bp                    # Exim queue

# View message details
postcat -q [QUEUE_ID]       # Postfix
exim -Mvh [MESSAGE_ID]      # Exim headers
exim -Mvb [MESSAGE_ID]      # Exim body
```

#### Real-time Monitoring

```bash
# Watch mail log in real-time
tail -f /var/log/mail.log

# Filter for specific domain
tail -f /var/log/mail.log | grep example.com

# Watch for errors only
tail -f /var/log/mail.log | grep -i "error\|fail\|reject"

# Monitor authentication attempts
tail -f /var/log/mail.log | grep -i "auth\|sasl"
```

## Email Security Gateway Integration

Email security gateways (ESGs) are specialized security appliances or cloud services that sit between the internet and your mail infrastructure to provide advanced threat protection, spam filtering, data loss prevention (DLP), and compliance features. Understanding how to integrate these gateways with your SMTP infrastructure is critical for enterprise email security.

### What Are Email Security Gateways?

Email security gateways provide multiple layers of protection:

- **Threat Detection** - Malware, ransomware, and phishing protection
- **Spam Filtering** - Advanced content and reputation-based filtering
- **Data Loss Prevention (DLP)** - Outbound content inspection and policy enforcement
- **Email Encryption** - TLS enforcement and message-level encryption
- **Archiving and Compliance** - Regulatory compliance and eDiscovery support
- **Continuity** - Email spooling during mail server outages

### Common Email Security Gateway Solutions

| Solution | Type | Common Use Cases |
| -------- | ---- | ---------------- |
| **Proofpoint** | Cloud/On-Prem | Enterprise threat protection, DLP, archiving |
| **Mimecast** | Cloud | Email security, archiving, continuity |
| **Microsoft Defender for Office 365** | Cloud | Microsoft 365 integrated protection |
| **Cisco Email Security (IronPort)** | Cloud/Appliance | Enterprise email security, compliance |
| **Barracuda Email Security Gateway** | Cloud/Appliance | SMB to enterprise security |
| **Trend Micro Email Security** | Cloud/Appliance | Advanced threat protection |
| **Symantec Email Security.cloud** | Cloud | Cloud email security |
| **Forcepoint Email Security** | Cloud/On-Prem | DLP and threat protection |

### Integration Architecture

#### Inbound Mail Flow with Gateway

```text
Internet                                   Your Infrastructure
   │                                              │
   ↓                                              ↓
┌────────────────────┐                   ┌──────────────┐
│  Sending MTA       │                   │  Internal    │
│  (External)        │                   │  Recipients  │
└────────┬───────────┘                   └──────▲───────┘
         │                                      │
         │ SMTP (Port 25)                      │ SMTP
         ↓                                      │
┌────────────────────┐                   ┌─────┴────────┐
│ Email Security     │────Inspects──────→│ Internal MTA │
│ Gateway (ESG)      │   & Filters       │ (Exchange/   │
│ - Anti-spam        │                   │  Postfix/    │
│ - Anti-malware     │                   │  Office 365) │
│ - DLP              │                   └──────────────┘
└────────────────────┘
         │
         ↓
   Quarantine/Block
```

#### Outbound Mail Flow with Gateway

```text
Your Infrastructure                        Internet
         │                                     │
         ↓                                     ↓
┌──────────────┐                      ┌───────────────┐
│  Internal    │                      │  Receiving    │
│  Senders     │                      │  MTA          │
└──────┬───────┘                      └───────▲───────┘
       │                                      │
       │ SMTP                                 │ SMTP (Port 25)
       ↓                                      │
┌──────────────┐                      ┌──────┴────────┐
│ Internal MTA │────Forwards─────────→│ Email         │
│ (Smarthost)  │     Outbound         │ Security      │
└──────────────┘      Mail            │ Gateway (ESG) │
                                      │ - DLP Scan    │
                                      │ - Encrypt     │
                                      │ - Archive     │
                                      └───────────────┘
```

### Configuration Steps

#### 1. MX Record Configuration

**For Cloud-Based Gateways (Inbound):**

```bash
# Update DNS MX records to point to gateway
# Example for Proofpoint:
example.com.    IN MX 10 mx1-us1.ppe-hosted.com.
example.com.    IN MX 10 mx2-us1.ppe-hosted.com.

# Verify MX records
dig MX example.com +short
```

**For Hybrid/On-Premises Gateways:**

```bash
# MX records point to your gateway appliance
example.com.    IN MX 10 mailgateway.example.com.
example.com.    IN A     203.0.113.50

# Gateway then forwards to internal mail server
```

#### 2. SPF Record Updates

Update SPF records to authorize the gateway to send on your behalf:

```bash
# Before (direct sending):
example.com. IN TXT "v=spf1 ip4:203.0.113.10 -all"

# After (with gateway):
example.com. IN TXT "v=spf1 include:_spf.proofpoint.com ip4:203.0.113.10 -all"

# Common gateway SPF includes:
# Proofpoint: include:_spf.proofpoint.com
# Mimecast: include:_netblocks.mimecast.com
# Barracuda: include:_spf.ess.barracudanetworks.com
```

#### 3. DKIM Configuration

Configure DKIM signing either on your mail server or the gateway:

**Option A: Gateway Signs (Recommended for Outbound):**

```bash
# Generate DKIM key in gateway console
# Publish DNS record provided by gateway
selector._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCS..."

# Gateway signs all outbound mail
# Internal server sends unsigned mail to gateway
```

**Option B: Internal Server Signs:**

```bash
# Internal server signs before sending to gateway
# Gateway preserves DKIM signature
# Ensure gateway doesn't modify message content (breaks signature)
```

#### 4. Configure Internal Mail Server

**Postfix Configuration (Outbound via Gateway):**

```bash
# /etc/postfix/main.cf
relayhost = [mailgateway.example.com]:25

# Authenticate to gateway if required
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous

# TLS configuration
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt

# /etc/postfix/sasl_passwd
[mailgateway.example.com]:25 username:password

# Apply configuration
postmap /etc/postfix/sasl_passwd
postfix reload
```

**Exchange Configuration (Outbound via Gateway):**

```powershell
# Create Send Connector to gateway
New-SendConnector -Name "Outbound via Gateway" `
    -AddressSpaces "*" `
    -SourceTransportServers "EXCH01" `
    -SmartHosts "mailgateway.example.com" `
    -Port 25 `
    -RequireTLS $true `
    -DNSRoutingEnabled $false

# Configure authentication if required
Set-SendConnector "Outbound via Gateway" `
    -SmartHostAuthMechanism BasicAuth `
    -AuthenticationCredential (Get-Credential)
```

#### 5. Configure Inbound Acceptance

**Accept Mail Only from Gateway (Postfix):**

```bash
# /etc/postfix/main.cf
# Only accept mail from gateway IPs
smtpd_client_restrictions = 
    permit_mynetworks,
    check_client_access cidr:/etc/postfix/gateway_clients,
    reject

# /etc/postfix/gateway_clients
# Gateway IP addresses
203.0.113.50/32   OK
203.0.113.51/32   OK
198.51.100.0/24   OK

# Reload configuration
postfix reload
```

**Accept Mail Only from Gateway (Exchange):**

```powershell
# Create Receive Connector for gateway
New-ReceiveConnector -Name "From Email Gateway" `
    -Server "EXCH01" `
    -RemoteIPRanges "203.0.113.50-203.0.113.60" `
    -Bindings "0.0.0.0:25" `
    -PermissionGroups AnonymousUsers

# Set connector to accept all domains
Set-ReceiveConnector "From Email Gateway" `
    -AuthMechanism None `
    -PermissionGroups AnonymousUsers
```

### Authentication and Authorization

#### Gateway-to-Server Authentication Options

**Option 1: IP-Based Trust (Common):**

```bash
# Whitelist gateway IP addresses
# No authentication required
# Fast and simple
# Risk: IP spoofing if network compromised
```

**Option 2: SMTP Authentication:**

```bash
# Gateway authenticates with username/password
# More secure than IP-only
# Slightly more overhead
# Recommended for Internet-facing gateways

# Postfix example
smtpd_sasl_auth_enable = yes
smtpd_recipient_restrictions = 
    permit_sasl_authenticated,
    reject_unauth_destination
```

**Option 3: TLS Certificate Authentication:**

```bash
# Gateway presents client certificate
# Highest security
# More complex setup
# Best for high-security environments

# Postfix example
smtpd_tls_ask_ccert = yes
smtpd_tls_req_ccert = yes
smtpd_tls_CAfile = /etc/postfix/ssl/gateway-ca.crt
```

### Common Integration Challenges

#### Challenge 1: SPF Alignment Failures

**Problem:** Internal servers send mail directly, bypassing gateway

```text
Result: SPF fails because sending IP not in SPF record
```

**Solution:**

```bash
# Force all outbound mail through gateway
# Postfix: Use relayhost (shown above)
# Firewall: Block outbound port 25 except from gateway

# Verify no direct sending
iptables -A OUTPUT -p tcp --dport 25 -j REJECT
iptables -I OUTPUT -s 203.0.113.50 -p tcp --dport 25 -j ACCEPT
```

#### Challenge 2: DKIM Signature Breaks

**Problem:** Gateway modifies message content (disclaimers, footers)

```text
Result: DKIM signature validation fails
```

**Solutions:**

- Configure gateway to sign DKIM after modifications
- Use gateway for signing, internal server sends unsigned
- Disable content modifications that break signatures
- Use multiple DKIM selectors (internal + gateway)

```bash
# Verify DKIM after gateway processing
# Send test email and check headers
Authentication-Results: receiver.com;
    dkim=pass header.d=example.com header.s=gateway
```

#### Challenge 3: Loop Detection

**Problem:** Mail bounces between gateway and internal server

```text
Gateway → Internal Server → Gateway → Internal Server (loop)
```

**Solution:**

```bash
# Add Received headers tracking
# Configure proper routing rules
# Use different ports for inbound vs outbound

# Postfix: Set proper relay domains
relay_domains = example.com, $mydestination

# Exchange: Configure accepted domains
Set-AcceptedDomain -Identity example.com -DomainType Authoritative
```

#### Challenge 4: TLS Version Mismatches

**Problem:** Gateway requires TLS 1.2+, internal server uses TLS 1.0

```text
Result: Connection fails, mail queues
```

**Solution:**

```bash
# Update TLS configuration (Postfix)
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_ciphers = high
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1

# Test TLS connection
openssl s_client -connect mailgateway.example.com:25 -starttls smtp -tls1_2
```

### Testing Gateway Integration

#### Test Inbound Mail Flow

```bash
# 1. Send test email from external address
# 2. Check gateway logs for receipt
# 3. Check internal server logs for delivery
# 4. Verify email headers show gateway processing

# Expected headers:
Received: from mailgateway.example.com (gateway.example.com [203.0.113.50])
    by mail.example.com with ESMTPS id abc123
    for <user@example.com>; Mon, 13 Jan 2026 10:00:00 -0000
X-Proofpoint-Virus-Version: vendor=fsecure engine=2.50.10434:6.0.138
X-Proofpoint-Spam-Details: rule=notspam policy=default score=0
```

#### Test Outbound Mail Flow

```bash
# 1. Send email from internal user to external address
# 2. Check internal server logs for relay to gateway
# 3. Check gateway logs for outbound processing
# 4. Verify recipient receives email
# 5. Check authentication results in headers

# Test SPF/DKIM/DMARC alignment
# Send to: check-auth@verifier.port25.com
# Review authentication report
```

#### Verify Authentication Headers

```bash
# Check email headers at recipient
Authentication-Results: receiver.com;
    spf=pass (sender IP is 203.0.113.50) smtp.mailfrom=example.com;
    dkim=pass (signature was verified) header.d=example.com;
    dmarc=pass (policy=reject) header.from=example.com
Received-SPF: pass (receiver.com: domain of example.com designates 203.0.113.50 as permitted sender)
```

### Monitoring and Maintenance

#### Gateway Health Checks

```bash
# Monitor gateway connectivity
while true; do
    nc -zv mailgateway.example.com 25 || \
        echo "Gateway unreachable: $(date)" | \
        mail -s "Gateway Alert" admin@example.com
    sleep 300
done

# Check mail queue for gateway-related deferrals
mailq | grep "mailgateway.example.com" | grep "Connection refused"

# Monitor authentication failures
tail -f /var/log/mail.log | grep "authentication failed\|SASL"
```

#### Key Metrics to Monitor

- **Queue Size** - Mail waiting to be relayed to/from gateway
- **Delivery Time** - Latency through gateway processing
- **Authentication Failures** - Failed AUTH attempts
- **TLS Errors** - Certificate or protocol issues
- **Spam/Malware Blocks** - Gateway protection effectiveness
- **DLP Violations** - Outbound policy violations

#### Alerting Configuration

```bash
# Alert on queue buildup (Postfix)
QUEUE_SIZE=$(mailq | tail -1 | awk '{print $5}')
if [ "$QUEUE_SIZE" -gt 100 ]; then
    echo "Mail queue size: $QUEUE_SIZE messages" | \
        mail -s "ALERT: Mail Queue Buildup" admin@example.com
fi

# Alert on gateway connectivity issues
if ! nc -zv mailgateway.example.com 25 >/dev/null 2>&1; then
    echo "Cannot connect to email gateway" | \
        mail -s "CRITICAL: Gateway Offline" admin@example.com
fi
```

### Best Practices

#### Security

- ✅ **Restrict inbound connections** to gateway IPs only
- ✅ **Enforce TLS** for all gateway communication
- ✅ **Use authentication** for gateway-to-server connections
- ✅ **Block direct inbound SMTP** (bypass gateway protection)
- ✅ **Regular certificate renewal** before expiration
- ✅ **Monitor for unauthorized relaying** through gateway

#### Reliability

- ✅ **Configure backup MX records** for gateway redundancy
- ✅ **Monitor mail queues** on both gateway and internal servers
- ✅ **Test failover scenarios** regularly
- ✅ **Document gateway IP ranges** and update firewall rules
- ✅ **Implement queue alerts** for early problem detection
- ✅ **Maintain current gateway software** and security patches

#### Authentication

- ✅ **Update SPF records** to include gateway IPs/ranges
- ✅ **Configure DKIM signing** on gateway or internal server (not both)
- ✅ **Verify DMARC alignment** after gateway changes
- ✅ **Test authentication** with external validators
- ✅ **Document authentication** configuration in runbooks

#### Troubleshooting Checklist

- [ ] Verify DNS MX records point to gateway
- [ ] Confirm SPF includes gateway IP ranges
- [ ] Check DKIM signature source (gateway vs internal)
- [ ] Test SMTP connectivity to/from gateway
- [ ] Verify firewall rules allow gateway communication
- [ ] Check TLS certificate validity and compatibility
- [ ] Review gateway and mail server logs simultaneously
- [ ] Confirm authentication credentials are correct
- [ ] Test both inbound and outbound mail flow
- [ ] Verify no mail bypasses gateway security

### Gateway-Specific Documentation

For detailed configuration instructions specific to your gateway solution:

- **Proofpoint**: [Proofpoint Email Protection Documentation](https://proofpoint.com/us/support)
- **Mimecast**: [Mimecast Administrator Guide](https://community.mimecast.com/)
- **Microsoft Defender**: [Microsoft 365 Email Security](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/)
- **Cisco ESA**: [Cisco Email Security Appliance Documentation](https://www.cisco.com/c/en/us/support/security/email-security-appliance/)
- **Barracuda**: [Barracuda Email Security Gateway Documentation](https://campus.barracuda.com/)

## Getting Started

Before implementing SMTP services, ensure you have:

1. **Network Configuration** - Proper DNS setup with MX records
2. **Security Planning** - TLS certificates and authentication mechanisms
3. **Relay Policies** - Anti-spam and relay restrictions
4. **Monitoring Tools** - Log analysis and mail queue management

### Quick Setup Checklist

- [ ] Configure DNS MX records pointing to mail server
- [ ] Install and configure mail server (Postfix, Exim, Sendmail, etc.)
- [ ] Obtain TLS certificate for encrypted connections
- [ ] Configure SMTP authentication (SASL)
- [ ] Set up SPF, DKIM, and DMARC records ([See Authentication Guide](authentication.md))
- [ ] Configure relay restrictions and access controls
- [ ] Set up logging and monitoring
- [ ] Test mail flow (internal and external)
- [ ] Configure mail queue management and alerts
- [ ] Document configuration and procedures

## Standard SMTP Ports

| Port | Purpose | Encryption | Usage |
| ---- | ------- | ---------- | ----- |
| 25 | SMTP | STARTTLS (optional) | Server-to-server mail transfer |
| 465 | SMTPS | Implicit TLS | Legacy secure SMTP (deprecated but still used) |
| 587 | Submission | STARTTLS (required) | Mail submission from clients (recommended) |
| 2525 | Alternative | STARTTLS | Alternative port when 25 is blocked |

## Quick Links

- RFC 5321: [SMTP Protocol](https://www.rfc-editor.org/rfc/rfc5321)
- RFC 3207: [SMTP over TLS](https://www.rfc-editor.org/rfc/rfc3207)
- RFC 4954: [SMTP Authentication](https://www.rfc-editor.org/rfc/rfc4954)
- RFC 6531: [Internationalized Email](https://www.rfc-editor.org/rfc/rfc6531)
- RFC 7208: [Sender Policy Framework (SPF)](https://www.rfc-editor.org/rfc/rfc7208)

## Related Topics

- [Email Authentication (SPF, DKIM, DMARC)](authentication.md) - **Essential for deliverability**
- [Exchange](../exchange/index.md)
