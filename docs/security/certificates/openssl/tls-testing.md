---
title: OpenSSL SSL/TLS Testing
description: Testing SSL/TLS connections, ciphers, and TLS 1.3 with OpenSSL s_client and s_server
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: security
---

## SSL/TLS Testing

OpenSSL provides powerful tools for testing and troubleshooting SSL/TLS connections. These commands help you verify server configurations, identify misconfigurations, and diagnose connectivity issues.

### Testing SSL/TLS Connections

The `s_client` command creates an SSL/TLS client connection to a server, showing details about the handshake, certificates, and protocols:

```bash
# Basic connection test (HTTPS)
openssl s_client -connect example.com:443

# Test with Server Name Indication (SNI) - important for virtual hosts
openssl s_client -connect example.com:443 -servername example.com

# Display the full certificate chain
openssl s_client -connect example.com:443 -showcerts

# Save server certificate to a file
openssl s_client -connect example.com:443 -showcerts </dev/null | \
  sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > certificate.pem

# Test a specific TLS version
openssl s_client -connect example.com:443 -tls1_2
openssl s_client -connect example.com:443 -tls1_3

# Force TLSv1.3 only
openssl s_client -connect example.com:443 -tls1_3 -no_tls1_2 -no_tls1_1 -no_tls1

# Test STARTTLS for protocols like SMTP, POP3, IMAP, FTP
openssl s_client -connect mail.example.com:25 -starttls smtp
openssl s_client -connect mail.example.com:110 -starttls pop3
openssl s_client -connect mail.example.com:143 -starttls imap

# Check for certificate expiration
openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates

# Bypass DNS resolution with IP connection
openssl s_client -connect 192.168.1.1:443 -servername example.com

# View all handshake details including session tickets and session resumption
openssl s_client -connect example.com:443 -state -debug
```

### Analyzing Connection Security

Evaluate various security aspects of an SSL/TLS connection:

```bash
# Check for SSL renegotiation support (security vulnerability)
openssl s_client -connect example.com:443 -reconnect

# Check for session resumption capability
openssl s_client -connect example.com:443 -reconnect -no_ticket

# Verify OCSP stapling
openssl s_client -connect example.com:443 -status

# Check which cipher suites a server supports
for cipher in $(openssl ciphers 'ALL:eNULL' | tr ':' ' '); do
  echo -n "Testing $cipher... "
  result=$(openssl s_client -connect example.com:443 -cipher "$cipher" -servername example.com </dev/null 2>&1)
  if [[ "$result" =~ "Cipher is $cipher" || "$result" =~ "Cipher    :" ]]; then
    echo "Supported"
  else
    echo "Not supported"
  fi
done

# Test for specific vulnerabilities
# Heartbleed
openssl s_client -connect example.com:443 -tlsextdebug 2>&1 | grep 'server extension "heartbeat"'

# BEAST vulnerability (CBC ciphers in TLSv1.0)
openssl s_client -connect example.com:443 -tls1 -cipher 'ECDHE-RSA-AES128-SHA:AES128-SHA'

# POODLE vulnerability (SSLv3)
openssl s_client -connect example.com:443 -ssl3

# FREAK vulnerability (export ciphers)
openssl s_client -connect example.com:443 -cipher 'EXPORT'

# CRIME vulnerability (TLS compression)
openssl s_client -connect example.com:443 -compress

# Check for secure renegotiation support
openssl s_client -connect example.com:443 | grep "Secure Renegotiation"

# Check for perfect forward secrecy (a "Server Temp Key" line indicates PFS)
openssl s_client -connect example.com:443 | grep "Server Temp Key"
```

### Server Setup and Testing

OpenSSL also provides an `s_server` command to set up a test SSL/TLS server:

```bash
# First, create a self-signed certificate for the test server (if needed)
openssl req -x509 -newkey rsa:2048 -keyout server.key -out server.crt -days 365 -nodes \
  -subj "/CN=localhost"

# Set up a simple HTTPS server for testing (on port 4433)
openssl s_server -cert server.crt -key server.key -accept 4433 -www

# Set up a server with specific TLS version and ciphers
openssl s_server -cert server.crt -key server.key -accept 4433 -tls1_2 -cipher 'HIGH:!aNULL:!MD5'

# Test client certificate authentication
openssl s_server -cert server.crt -key server.key -accept 4433 -verify 1 -CAfile ca.crt

# Connect to a test server with a client certificate
openssl s_client -connect localhost:4433 -cert client.crt -key client.key -CAfile ca.crt
```

### Practical Security Assessments

Here are some practical security checks for production servers:

```bash
# 1. Check supported protocols (prefer TLS 1.2+ only)
echo "Testing TLS 1.3:"
openssl s_client -connect example.com:443 -tls1_3 </dev/null 2>/dev/null | grep Protocol
echo "Testing TLS 1.2:"
openssl s_client -connect example.com:443 -tls1_2 </dev/null 2>/dev/null | grep Protocol
echo "Testing TLS 1.1 (deprecated):"
openssl s_client -connect example.com:443 -tls1_1 </dev/null 2>/dev/null | grep Protocol
echo "Testing TLS 1.0 (deprecated):"
openssl s_client -connect example.com:443 -tls1 </dev/null 2>/dev/null | grep Protocol
echo "Testing SSL 3.0 (insecure):"
openssl s_client -connect example.com:443 -ssl3 </dev/null 2>/dev/null | grep Protocol

# 2. Check certificate information
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null | \
  openssl x509 -noout -text | grep -A 2 Validity

# 3. Check cipher order (preference)
openssl s_client -connect example.com:443 -cipher "ALL:eNULL" -servername example.com </dev/null 2>/dev/null | \
  grep "Cipher    :"
```

> [!TIP]
> For comprehensive security testing, consider specialized tools like SSLyze, testssl.sh, or Qualys SSL Labs (online).

### Testing SSL/TLS Ciphers

Evaluate cipher support and security configuration:

```bash
# List all supported ciphers by your OpenSSL installation
openssl ciphers -v 'ALL:eNULL'

# List only strong ciphers
openssl ciphers -v 'HIGH:!aNULL:!eNULL:!3DES:!DES:!RC4:!MD5:!PSK:!SRP:!DSS'

# List elliptic curve ciphers only
openssl ciphers -v 'ECDHE:ECDH:ECDSA'

# List TLS 1.3 cipher suites (OpenSSL 1.1.1+)
openssl ciphers -v -tls1_3

# List all ciphers in order of strength (from strongest to weakest)
openssl ciphers -v 'ALL:@STRENGTH'

# Check if a server supports a specific cipher
# (if the connection succeeds, the server supports it)
openssl s_client -connect example.com:443 -cipher 'ECDHE-RSA-AES256-GCM-SHA384'
```

### Modern TLS 1.3 Configurations

TLS 1.3 (introduced in OpenSSL 1.1.1+) brings significant security and performance improvements:

```bash
# Check if OpenSSL supports TLS 1.3
openssl version
openssl ciphers -v | grep TLSv1.3

# Test TLS 1.3 connection
openssl s_client -connect example.com:443 -tls1_3

# Test TLS 1.3 with specific cipher suite
openssl s_client -connect example.com:443 -tls1_3 -ciphersuites TLS_AES_256_GCM_SHA384

# View TLS 1.3 handshake details
openssl s_client -connect example.com:443 -tls1_3 -msg -state

# List supported TLS 1.3 cipher suites
openssl ciphers -v -tls1_3

# Test TLS 1.3 0-RTT (Early Data) feature
echo "GET / HTTP/1.1" > request.txt
openssl s_client -connect example.com:443 -tls1_3 -sess_out session.pem
openssl s_client -connect example.com:443 -tls1_3 -sess_in session.pem -early_data request.txt
```

Key differences in TLS 1.3:

1. **Simplified Handshake**: Faster connections with fewer round-trips
2. **Improved Privacy**: Encrypts more of the handshake
3. **Removed Legacy Algorithms**: Eliminates all known vulnerable cryptographic algorithms
4. **Forward Secrecy by Default**: All TLS 1.3 cipher suites provide perfect forward secrecy
5. **Standard Cipher Suites**: Only 5 cipher suites, all considered secure

> [!TIP]
> For production servers, consider supporting only TLS 1.2 and TLS 1.3 with strong cipher suites. TLS 1.0 and 1.1 are deprecated and considered insecure.

### Advanced Testing and Diagnostics

```bash
# Check SSL/TLS session parameters and ticket information
openssl s_client -connect example.com:443 -status -tlsextdebug

# Check OCSP stapling support
openssl s_client -connect example.com:443 -status | grep -A 10 "OCSP response"

# Test mutual TLS authentication (client certificate)
openssl s_client -connect example.com:443 -cert client.crt -key client.key

# Capture detailed handshake timing
openssl s_client -connect example.com:443 -debug -msg -state -time

# Validate certificate against Mozilla's included CA list
openssl s_client -connect example.com:443 -CApath /etc/ssl/certs

# Test TLS protocol version negotiation (downgrade attack protection)
openssl s_client -connect example.com:443 -no_tls1_3
```

### Interpreting Connection Results

When using `s_client`, look for these key indicators:

1. **Verify return code**: Should be `0 (ok)` if the certificate validates properly
2. **Protocol version**: Should be TLSv1.2 or TLSv1.3 for modern security
3. **Cipher**: Should use modern algorithms (ECDHE, AES-GCM, ChaCha20)
4. **Handshake**: Check for successful completion
5. **Certificate chain**: Verify all certificates in the chain are present

Example of a secure connection:

```text
Protocol: TLSv1.3
Cipher: TLS_AES_256_GCM_SHA384
Verification: OK
Secure Renegotiation: supported
Server Temp Key: X25519, 253 bits
```

## Navigation

[◄ Validation and Troubleshooting](validation-troubleshooting.md) · [OpenSSL Guide](index.md) · [Advanced Operations ►](advanced.md)
