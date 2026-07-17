---
title: "Postfix TLS/SSL Configuration"
description: "Guide for configuring TLS/SSL encryption in Postfix"
author: "Joseph Streeter"
ms.date: 01/13/2026
ms.topic: guide
keywords: postfix, tls, ssl, encryption, certificates
---

Configure TLS/SSL encryption for secure email transmission.

## Overview

This guide covers implementing TLS/SSL encryption in Postfix.

## Obtaining a Certificate

For how to obtain and manage the certificate itself, use the central certificate documentation rather than duplicating it here:

- [ACME / Certbot](../../../security/certificates/acme/certbot.md) — free, auto-renewing certificates for a public-facing MTA (recommended)
- [Self-Signed Certificates](../../../security/certificates/self-signed.md) — for testing or internal relays only
- [OpenSSL Guide](../../../security/certificates/openssl/index.md) — key generation, CSRs, and format conversions

## Postfix-Specific Configuration

Once you have a certificate and key, configure Postfix's `smtpd_tls_*` (inbound) and `smtp_tls_*` (outbound) parameters. See [Security Hardening](security-hardening.md) for a hardened TLS parameter set, including protocol/cipher restrictions and 2048-bit DH parameters.

Key parameters:

```ini
# Inbound (smtpd) TLS — server certificate presented to connecting clients
smtpd_tls_cert_file = /etc/ssl/certs/mail.crt
smtpd_tls_key_file  = /etc/ssl/private/mail.key
smtpd_tls_security_level = may          # opportunistic; use "encrypt" to require TLS

# Restrict to modern protocols (disable SSLv2/SSLv3/TLS1.0/1.1)
smtpd_tls_mandatory_protocols = >=TLSv1.2
smtpd_tls_protocols = >=TLSv1.2

# Outbound (smtp) TLS
smtp_tls_security_level = may
smtp_tls_protocols = >=TLSv1.2
```

> [!NOTE]
> Postfix expects the certificate and key in PEM format. If your CA issued a PKCS#12/PFX bundle, convert it first — see the [OpenSSL Guide](../../../security/certificates/openssl/conversions.md).
