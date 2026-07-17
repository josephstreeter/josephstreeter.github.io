---
title: TLS Testing and Troubleshooting
description: SSL/TLS testing commands, advanced diagnostic workflows, and common troubleshooting patterns
author: josephstreeter
ms.author: josephstreeter
ms.date: 2025-09-22
ms.topic: conceptual
ms.service: security
---

## TLS Testing and Troubleshooting

### Test SSL/TLS connections

```bash
openssl s_client -connect example.com:443 -servername example.com
openssl s_client -connect example.com:443 -showcerts
openssl s_client -connect example.com:443 -tls1_2
openssl s_client -connect example.com:443 -tls1_3
```

### Evaluate security posture

```bash
openssl s_client -connect example.com:443 -status
openssl s_client -connect example.com:443 -tlsextdebug
openssl s_client -connect example.com:443 -cipher 'HIGH:!aNULL:!eNULL:!3DES:!DES:!RC4:!MD5:!PSK:!SRP:!DSS'
```

### Launch an in-memory test server

```bash
openssl s_server -cert server.crt -key server.key -accept 4433 -www
openssl s_client -connect localhost:4433
```

### Common troubleshooting checks

```bash
# Verify the chain
openssl verify -verbose -CAfile ca_bundle.crt certificate.crt

# Match the private key and certificate
openssl x509 -noout -modulus -in certificate.crt | openssl md5
openssl rsa -noout -modulus -in private.key | openssl md5

# Check expiration dates
openssl x509 -enddate -noout -in certificate.crt
```

### Common issues and fixes

| Problem | Likely cause | Suggested action |
| ------- | ------------ | ---------------- |
| Certificate not trusted | Missing CA in trust store | Add the intermediate or root certificate to the trust store |
| Name mismatch | Hostname does not match SANs | Correct the certificate request or use proper SAN entries |
| Expired certificate | Renewal missed | Issue and install a replacement certificate |
| Revocation errors | Certificate was revoked | Replace the certificate and update dependent services |

### Advanced operations

```bash
openssl enc -aes-256-cbc -salt -in plaintext.txt -out encrypted.bin -pbkdf2
openssl dgst -sha256 -sign private.key -out signature.bin document.txt
openssl ocsp -issuer ca.crt -cert certificate.crt -url http://ocsp.example.com -resp_text
```

### Recommendations

- Prefer TLS 1.2 and TLS 1.3 only.
- Use strong cipher suites and disable legacy versions.
- Automate certificate monitoring and renewal.
- Consider dedicated certificate-management tooling such as Certbot, ACME.sh, or cert-manager.
