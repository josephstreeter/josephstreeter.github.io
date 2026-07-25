---
title: ACME Protocol and Automated Certificates
description: Overview of the ACME protocol for automated certificate issuance and renewal, with guides for win-acme and Certbot
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: overview
ms.service: security
---

## ACME Protocol and Automated Certificates

### Overview

The **Automatic Certificate Management Environment (ACME)** is an open standard protocol that automates the issuance, renewal, and revocation of X.509 certificates. Originally developed by the Internet Security Research Group (ISRG) for the [Let's Encrypt](https://letsencrypt.org/) certificate authority, ACME is now formalized in [RFC 8555](https://datatracker.ietf.org/doc/html/rfc8555) and supported by a growing number of certificate authorities and client tools.

Before ACME, obtaining and installing a TLS certificate was a manual, error-prone process involving CSR generation, domain validation via email or web forms, manual download, and manual installation. ACME replaces this workflow with a fully automated exchange between a client (running on your server) and the CA, enabling free, short-lived certificates that renew themselves without human intervention.

> [!NOTE]
> This section focuses on the two most widely used ACME clients: **[win-acme](win-acme.md)** for Windows/IIS environments and **[Certbot](certbot.md)** for Linux and cross-platform deployments. Both automate the same underlying protocol but target different ecosystems.

### Table of Contents

- [Why ACME Matters](#why-acme-matters)
- [How the ACME Protocol Works](#how-the-acme-protocol-works)
- [Challenge Types](#challenge-types)
- [ACME Certificate Authorities](#acme-certificate-authorities)
- [Choosing a Client](#choosing-a-client)
- [Security Considerations](#security-considerations)
- [win-acme Guide](win-acme.md)
- [Certbot Guide](certbot.md)

## Why ACME Matters

Automated certificate management solves several persistent operational problems:

- **Eliminates expiration outages**: The single most common certificate incident is an expired certificate causing an outage. ACME clients renew automatically, typically well before expiry.
- **Enables short-lived certificates**: ACME certificates are usually valid for 90 days (Let's Encrypt) or less. Short lifetimes reduce the impact of key compromise and encourage automation.
- **Removes manual toil**: No more generating CSRs, copying files between systems, or submitting web forms.
- **Free, publicly trusted certificates**: Let's Encrypt and other ACME CAs issue certificates trusted by all major browsers and operating systems at no cost.
- **Scales to large fleets**: Automation makes it practical to secure hundreds or thousands of hosts and subdomains.

> [!IMPORTANT]
> The short validity period of ACME certificates (90 days for Let's Encrypt) is a feature, not a limitation. It **requires** you to automate renewal. Any deployment that depends on manual renewal of ACME certificates will eventually fail. Always configure and test automatic renewal.

## How the ACME Protocol Works

ACME is a client–server protocol running over HTTPS. The client proves control of one or more domains, then requests certificates for those domains. The high-level flow is:

1. **Account registration**: The client generates an account key pair and registers with the CA's ACME directory endpoint, agreeing to the terms of service.
2. **Order creation**: The client submits an order identifying the domain names (identifiers) it wants certified.
3. **Authorization and challenges**: For each domain, the CA issues one or more *challenges*. The client fulfills a challenge to prove it controls the domain.
4. **Validation**: The CA verifies the completed challenge (for example, by fetching a token from the web server or querying DNS).
5. **CSR submission (finalization)**: Once all authorizations are valid, the client submits a Certificate Signing Request. The client generates a fresh key pair for the certificate.
6. **Certificate issuance**: The CA signs the certificate and provides a download URL. The client retrieves the full certificate chain.
7. **Installation and renewal**: The client installs the certificate into the target service and schedules automatic renewal, repeating the process before expiry.

```mermaid
sequenceDiagram
    participant Client as ACME Client
    participant CA as ACME CA (e.g. Let's Encrypt)
    participant Val as Validation Target<br/>(Web server / DNS)

    Client->>CA: Register account (account key)
    Client->>CA: New order (domains)
    CA-->>Client: Authorizations + challenges
    Client->>Val: Provision challenge response
    Client->>CA: Challenge ready
    CA->>Val: Verify challenge
    CA-->>Client: Authorization valid
    Client->>CA: Finalize order (CSR)
    CA-->>Client: Certificate + chain
    Client->>Val: Install certificate
```

## Challenge Types

Challenges are how the client proves domain control. The type you choose determines your infrastructure requirements and which certificate types you can obtain.

| Challenge | How it works | Requirements | Wildcards |
| --------- | ------------ | ------------ | --------- |
| **HTTP-01** | CA requests a token file at `http://<domain>/.well-known/acme-challenge/<token>` | Port 80 reachable from the internet; a web server or the client's built-in listener | No |
| **DNS-01** | Client creates a `_acme-challenge.<domain>` TXT record; CA queries DNS | API access to your DNS provider (or manual record creation) | **Yes** |
| **DNS-PERSIST-01** | Client publishes a **standing** `_validation-persist.<domain>` TXT record naming the CA and authorized account; the record is reused across issuances | One-time DNS record; a tightly protected ACME account key | **Yes** |
| **TLS-ALPN-01** | CA connects on port 443 using a special ALPN protocol; client presents a validation certificate | Port 443 reachable; client controls the TLS handshake | No |

> [!TIP]
> Use **DNS-01** when you need wildcard certificates (`*.example.com`), when the host is not reachable from the public internet, or when you want to issue certificates on a machine other than the one serving traffic. Use **HTTP-01** for simple, single-host web servers that are publicly reachable on port 80. Consider **DNS-PERSIST-01** when repeated real-time DNS updates are impractical — see the dedicated section below.

---

> [!WARNING]
> DNS-01 requires storing DNS provider API credentials on the machine running the ACME client. Scope these credentials as narrowly as possible — ideally to a single zone with permission only to manage `_acme-challenge` TXT records — and protect them with strict file permissions.

### DNS-PERSIST-01: Persistent DNS Authorization

**DNS-PERSIST-01** is a newer challenge type that replaces per-issuance DNS updates with a single, standing authorization record. It is specified in the IETF draft [draft-ietf-acme-dns-persist](https://datatracker.ietf.org/doc/draft-ietf-acme-dns-persist/) and was adopted by the CA/Browser Forum (ballot passed October 2025).

With standard DNS-01, the client must create a fresh `_acme-challenge` TXT record for **every** issuance and renewal, which means the ACME client needs live write access to your DNS zone. DNS-PERSIST-01 instead has you publish a **persistent** record that pre-authorizes a specific ACME account to issue for the domain. After the one-time setup, subsequent issuances and renewals require **no further DNS changes**.

#### How It Works

1. The client publishes a persistent TXT record at the **Authorization Domain Name** — `_validation-persist` prepended to the domain (for example, `_validation-persist.example.com`).
2. The record names the issuing CA and the **account URI** that is authorized to issue certificates for that domain.
3. On each subsequent order, the CA queries DNS, finds the persistent record, and confirms that the requesting account matches the authorized `accounturi` — no new challenge token is provisioned.

#### Record Format

The RDATA follows the `issue-value` syntax from [RFC 8659](https://datatracker.ietf.org/doc/html/rfc8659) (the same grammar used by CAA records):

```dns
_validation-persist.example.com. IN TXT ( "letsencrypt.org;"
  " accounturi=https://acme-v02.api.letsencrypt.org/acme/acct/1234567890" )
```

- **Issuer domain name** (`letsencrypt.org`): One of the CA's configured issuer domain names, in lowercase A-label form. Publish a separate record for each CA you authorize.
- **`accounturi`** (required): A stable identifier for the authorized ACME account, constructed per [RFC 8657](https://datatracker.ietf.org/doc/html/rfc8657). Because it identifies the *account* rather than the account key, it survives key rotation without a DNS change.

Optional parameters:

- **`policy=wildcard`**: Authorizes wildcard certificates (`*.example.com`) and subdomains, not just the base domain.
- **`persistUntil=<timestamp>`**: A UNIX timestamp after which the CA will no longer accept the record for new validations, requiring a periodic refresh.

#### Finding Your Let's Encrypt Account URI

The `accounturi` in the record is your existing ACME **account URL** — a URL of the form `https://acme-v02.api.letsencrypt.org/acme/acct/<numeric-id>`. You do not create it for DNS-PERSIST-01; it already exists from when your client first registered with the CA. How you look it up depends on your client:

**Certbot** (v1.23.0 or newer):

```bash
# Prints the account URL (and other details) for the default ACME server
certbot show_account

# For a non-default CA, specify the server
certbot show_account --server https://acme-v02.api.letsencrypt.org/directory
```

On older Certbot, read the `uri` field from the account registration file:

```bash
cat /etc/letsencrypt/accounts/acme-v02.api.letsencrypt.org/directory/*/regr.json
```

**win-acme**: The account URL is stored in the `Registration_v2` file inside the win-acme data folder (by default `%ProgramData%\win-acme\acme-v02.api.letsencrypt.org\`). Open it and read the account `Location`/URL value.

**acme.sh**: The account URL is recorded as `ACCOUNT_URL` in the CA config:

```bash
grep ACCOUNT_URL ~/.acme.sh/ca/acme-v02.api.letsencrypt.org/directory/ca.conf
```

If you have **no account yet**, register one first (for example, `certbot register` or by running any issuance), then look up the resulting URL.

> [!NOTE]
> The account URL is **not secret** — it is published in your DNS. What must stay secret is the *account key* that authenticates as that account. See below.

#### Managing the Account Key

Every ACME account is authenticated by a private **account key** (a JWK). The account URL is just a public identifier; the account key is the credential that proves you are that account. Under DNS-PERSIST-01, possession of the account key is what lets the holder issue for every domain whose persistent record names the account — so protecting it is paramount.

Where clients store the account key:

| Client | Account key location |
| ------ | -------------------- |
| **Certbot** | `/etc/letsencrypt/accounts/acme-v02.api.letsencrypt.org/directory/<id>/private_key.json` |
| **win-acme** | `Signer_v2` file in the win-acme data folder (default `%ProgramData%\win-acme\acme-v02.api.letsencrypt.org\`) |
| **acme.sh** | `~/.acme.sh/ca/acme-v02.api.letsencrypt.org/directory/account.key` |

Guidance for handling it:

- **Restrict permissions**: The key file should be readable only by root/`SYSTEM` (or the dedicated service account). Certbot's `/etc/letsencrypt/accounts` tree is already root-only by default — keep it that way, and set equivalent ACLs on the win-acme data folder.
- **Back it up securely**: If you lose the account key you cannot authenticate as that account; you would have to register a new account (new URL) and update every `_validation-persist` record. Store an encrypted backup of the key alongside your other secrets.
- **Rotate the key, not the account**: If you suspect the key is exposed, rotate it (Certbot: `certbot update_account`) — the account **URL stays the same**, so your published DNS records remain valid. This is a key benefit of binding to `accounturi` rather than to the key.
- **Deactivate on compromise**: If the account itself is compromised, deactivate it with the CA (Certbot: `certbot unregister`). Deactivation immediately invalidates all persistent authorizations that reference it, closing the window regardless of DNS propagation.
- **One account, deliberately scoped**: For DNS-PERSIST-01 at scale, decide intentionally which account issues for which domains. A single widely-authorized account key is a single high-value target; separate accounts per tenant or trust boundary limit the blast radius of a key compromise.

#### When to Use It

DNS-PERSIST-01 is best suited to environments where per-issuance DNS automation is impractical:

- **Multi-tenant hosting platforms** issuing on behalf of many customer domains.
- **Enterprise DNS** where zone changes are gated behind change-control processes.
- **IoT and batch operations** where large numbers of certificates are issued without live DNS API access on each host.

#### Revoking the Authorization

To withdraw the authorization, **delete the `_validation-persist` TXT record**. If the ACME account itself is compromised, deactivate the account with the CA to immediately stop all issuance that relies on its persistent authorizations.

> [!IMPORTANT]
> DNS-PERSIST-01 shifts the primary secret to protect. With DNS-01 the risk centers on DNS API credentials; with DNS-PERSIST-01 the **ACME account key becomes the high-value secret** — anyone holding it can issue against every domain that names its `accounturi`, for as long as the record stands. Protect the account key accordingly, enable DNSSEC on the zone, and prefer CAs that perform multi-perspective validation (MPIC).

---

> [!NOTE]
> DNS-PERSIST-01 is new. As of mid-2026 Let's Encrypt supports it in [Pebble](https://github.com/letsencrypt/pebble) (its test CA), with a production rollout targeted for 2026; client support (for example, in lego) is still maturing. Check your CA's and client's documentation before relying on it in production, and keep DNS-01 available as a fallback.

## ACME Certificate Authorities

While Let's Encrypt is the best-known ACME CA, the protocol is an open standard supported by others:

| CA | Notes |
| -- | ----- |
| **[Let's Encrypt](https://letsencrypt.org/)** | Free, most widely used. 90-day certificates. Rate-limited. |
| **[ZeroSSL](https://zerossl.com/)** | Free tier plus paid plans. ACME and REST API. |
| **[Buypass Go](https://www.buypass.com/products/tls-ssl-certificates/go-ssl)** | Free ACME CA offering 180-day certificates. |
| **[Google Trust Services](https://pki.goog/)** | Free ACME endpoint for Google Cloud and general use. |
| **Commercial CAs** | DigiCert, Sectigo, and others offer ACME endpoints for OV/EV automation. |
| **Private/internal** | [Smallstep `step-ca`](https://smallstep.com/docs/step-ca/), HashiCorp Vault, and Microsoft ADCS (with an ACME connector) can run ACME internally. |

> [!IMPORTANT]
> **Respect rate limits.** Let's Encrypt enforces [rate limits](https://letsencrypt.org/docs/rate-limits/) (for example, certificates per registered domain per week). When testing automation, always use the CA's **staging environment** first to avoid exhausting production limits. Both win-acme and Certbot support switching to staging.

## Choosing a Client

Both clients implement the same ACME protocol and can talk to the same CAs. Pick based on your platform and integration needs.

| Consideration | [win-acme](win-acme.md) | [Certbot](certbot.md) |
| ------------- | ----------------------- | --------------------- |
| Primary platform | Windows | Linux, BSD, macOS |
| Native integration | IIS, Exchange, RDS, Windows Certificate Store | Apache, Nginx, standalone, webroot |
| Language/runtime | .NET | Python |
| Renewal scheduling | Windows Task Scheduler (auto-created) | systemd timer or cron (auto-created) |
| Interface | Interactive menu + command line | Command line |
| Best for | IIS and other Windows services | Linux web servers and containers |

- Running **IIS, Exchange, or other Windows services**? Use **[win-acme](win-acme.md)**.
- Running **Nginx, Apache, or Linux-based services**? Use **[Certbot](certbot.md)**.
- Managing **containers or ephemeral infrastructure**? Consider Certbot in a sidecar, or lightweight alternatives such as [acme.sh](https://github.com/acmesh-official/acme.sh) or the built-in ACME support in reverse proxies like Caddy and Traefik.

## Security Considerations

- **Protect the account key**: Compromise of the ACME account key lets an attacker manage (and potentially revoke) your certificates. Store it with restrictive permissions. This is doubly important with **DNS-PERSIST-01**, where a standing DNS record pre-authorizes the account to issue — a stolen account key can then be used against every domain that names it until the record is removed or the account is deactivated.
- **Protect DNS API credentials**: When using DNS-01, treat provider tokens as high-value secrets. Scope them to the minimum required zone and permissions.
- **Automate renewal and monitor it**: Automation can fail silently. Monitor certificate expiry independently (for example, with an external check) so a broken renewal job does not become an outage.
- **Use CAA records**: Add [DNS CAA records](https://letsencrypt.org/docs/caa/) to restrict which CAs may issue certificates for your domains, reducing the risk of misissuance.
- **Prefer staging for testing**: Validate every change against the CA's staging environment before touching production.
- **Keep clients updated**: ACME clients handle cryptographic material and network communication with the CA. Keep them patched.

## Related Topics

- [win-acme Guide](win-acme.md)
- [Certbot Guide](certbot.md)
- [Certificate Management and PKI](../index.md)
- [OpenSSL Guide](../openssl/index.md)
- [SSL vs TLS](../sslvstls.md)

## Additional Resources

- [RFC 8555 - Automatic Certificate Management Environment (ACME)](https://datatracker.ietf.org/doc/html/rfc8555)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [Let's Encrypt - Finding Account IDs](https://letsencrypt.org/docs/account-id/)
- [Certbot Official Site](https://certbot.eff.org/)
- [win-acme Documentation](https://www.win-acme.com/)
