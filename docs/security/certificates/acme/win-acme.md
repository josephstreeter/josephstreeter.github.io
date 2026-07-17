---
title: win-acme Guide
description: Installing and using win-acme to automate Let's Encrypt certificates on Windows and IIS
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: security
---

## win-acme Guide

### Overview

[**win-acme**](https://www.win-acme.com/) (Windows ACME Simple, abbreviated **WACS**) is a free, open-source ACME client written in .NET for Windows. It is the de facto standard for obtaining and renewing [Let's Encrypt](https://letsencrypt.org/) and other ACME certificates on Windows servers, with first-class integration for IIS, Exchange, Remote Desktop Services, and the Windows Certificate Store.

win-acme is distributed as a self-contained command-line executable (`wacs.exe`). It offers a guided interactive menu for common scenarios and a full command-line interface for unattended automation. When it creates a certificate, it also **registers a Windows Scheduled Task** that renews the certificate automatically, so most deployments are truly "set and forget."

> [!NOTE]
> win-acme runs on Windows and targets the .NET runtime. Recent releases ship as self-contained builds that do not require a separate .NET installation. Verify the current requirements on the [win-acme download page](https://www.win-acme.com/).

### Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Interactive Quick Start (IIS)](#interactive-quick-start-iis)
- [Understanding the Renewal Task](#understanding-the-renewal-task)
- [Validation Methods](#validation-methods)
- [Unattended and Scripted Usage](#unattended-and-scripted-usage)
- [DNS Validation and Wildcards](#dns-validation-and-wildcards)
- [Installation Steps and Non-IIS Targets](#installation-steps-and-non-iis-targets)
- [Managing Renewals](#managing-renewals)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Prerequisites

- A Windows Server or Windows client machine with administrative privileges.
- A publicly resolvable DNS name pointing at the server (for HTTP validation), **or** API access to your DNS provider (for DNS validation).
- For **HTTP-01 validation**: inbound TCP port 80 reachable from the internet.
- For IIS integration: the IIS role installed with at least one site and binding configured.
- Outbound HTTPS access to the ACME CA (Let's Encrypt endpoints).

> [!IMPORTANT]
> Run win-acme from an **elevated** command prompt or PowerShell session (Run as Administrator). It needs administrative rights to bind certificates in IIS, write to the machine certificate store, and create the renewal scheduled task.

## Installation

win-acme requires no installer — download and extract the release archive.

```powershell
# 1. Create a permanent home for win-acme (do NOT run it from a temp folder;
#    the scheduled task references this path)
New-Item -Path 'C:\Program Files\win-acme' -ItemType Directory -Force

# 2. Download the latest release from https://github.com/win-acme/win-acme/releases
#    (example filename — check the releases page for the current version)
$release = 'win-acme.v2.2.9.1701.x64.pluggable.zip'
Invoke-WebRequest -Uri "https://github.com/win-acme/win-acme/releases/download/v2.2.9.1701/$release" `
    -OutFile "$env:TEMP\$release"

# 3. Extract into the permanent folder
Expand-Archive -Path "$env:TEMP\$release" -DestinationPath 'C:\Program Files\win-acme' -Force
```

You can also install it with a package manager:

```powershell
# Using Chocolatey
choco install win-acme

# Using winget
winget install winacme.winacme
```

> [!WARNING]
> Install win-acme in a **stable, permanent location** (such as `C:\Program Files\win-acme`). The scheduled renewal task invokes `wacs.exe` by its full path. If you run it from a Downloads or temp folder and later delete that folder, automatic renewals will silently fail.

## Interactive Quick Start (IIS)

The fastest path for an IIS site is the interactive menu.

1. Open an elevated PowerShell or Command Prompt and change to the win-acme folder:

   ```powershell
   Set-Location 'C:\Program Files\win-acme'
   .\wacs.exe
   ```

2. Choose **N** — *Create certificate (default settings)*.
3. win-acme scans IIS and lists your sites and bindings. Select the site (and host names) to secure.
4. Confirm the domain names and accept the Let's Encrypt terms of service (first run only, plus an email for expiry notices).
5. win-acme performs HTTP-01 validation, requests the certificate, installs it into the Windows Certificate Store, updates the IIS HTTPS binding, and creates the renewal scheduled task.

That's it — the site now serves a trusted certificate that renews automatically.

> [!TIP]
> The menu option **M** — *Create certificate (full options)* — exposes every setting: specific host selection, alternative validation methods, key type (RSA vs EC), CSR options, and custom installation/store steps. Use it when the defaults don't fit.

## Understanding the Renewal Task

When win-acme creates its first renewal, it registers a Windows Scheduled Task named **win-acme renew (acme-v02.api.letsencrypt.org)** (the name reflects the CA endpoint). By default this task runs daily and renews any certificate within its renewal window (typically 55 days after issuance for a 90-day certificate).

```powershell
# View the win-acme scheduled task
Get-ScheduledTask -TaskName 'win-acme*' | Format-List TaskName, State

# Run the renewal check manually (dry run of all due renewals)
Set-Location 'C:\Program Files\win-acme'
.\wacs.exe --renew
```

> [!IMPORTANT]
> Renewal only replaces certificates that are actually **due**. Running `--renew` does not force reissuance of everything. To force a specific renewal (for testing), add `--force`.

## Validation Methods

win-acme supports the standard ACME challenge types. The right choice depends on your network exposure and whether you need wildcards.

| Method | win-acme name | When to use |
| ------ | ------------- | ----------- |
| HTTP-01 (IIS) | `--validation selfhosting` / IIS | Publicly reachable IIS site on port 80 (default) |
| HTTP-01 (filesystem) | `--validation filesystem` | Serve the token from a known web root (non-IIS web server) |
| DNS-01 | `--validation dns-01` + a DNS plugin | Wildcards, or hosts not reachable on port 80 |
| TLS-ALPN-01 | `--validation tls-alpn-01` | Port 443 reachable but port 80 blocked |

> [!NOTE]
> For default IIS scenarios, win-acme uses its own temporary HTTP listener ("self-hosting") or writes the challenge file into the site's web root automatically. No manual web server configuration is needed.

## Unattended and Scripted Usage

For automation, configuration management, or golden images, drive win-acme entirely from the command line. A typical IIS certificate with HTTP validation:

```powershell
.\wacs.exe `
    --target iis `
    --host www.example.com,example.com `
    --installation iis `
    --emailaddress admin@example.com `
    --accepttos
```

Key common arguments:

| Argument | Purpose |
| -------- | ------- |
| `--target iis` | Source host names from IIS bindings |
| `--host` | Comma-separated list of domains (SANs) |
| `--validation` | Validation method (e.g. `selfhosting`, `filesystem`, `dns-01`) |
| `--installation` | How to install the result (e.g. `iis`, `certificatestore`, `none`) |
| `--store` | Where to store the certificate (e.g. `certificatestore`, `pemfiles`, `pfxfile`) |
| `--emailaddress` | Contact for the ACME account and expiry notices |
| `--accepttos` | Accept the CA's terms of service (required for unattended runs) |
| `--force` | Force renewal even if not yet due |

> [!TIP]
> Always test new automation against the Let's Encrypt **staging** environment first. Add `--baseuri "https://acme-staging-v02.api.letsencrypt.org/"` to your command. Staging issues untrusted certificates but has far higher rate limits, so you can iterate safely. Remove the flag (and delete the test renewal) for production.

## DNS Validation and Wildcards

Wildcard certificates (`*.example.com`) **require DNS-01 validation** — there is no HTTP alternative. win-acme provides DNS plugins for many providers (Cloudflare, Azure DNS, Route 53, and others), plus a script hook and a manual mode.

```powershell
# Example: wildcard certificate via a DNS plugin (full options menu, "M",
# then choose the DNS validation plugin and enter provider credentials)
.\wacs.exe `
    --target manual `
    --host "*.example.com,example.com" `
    --validation dns-01 `
    --emailaddress admin@example.com `
    --accepttos
```

### Amazon Route 53

win-acme ships a built-in **Route 53** validation plugin, so no extra download is needed. It creates and removes the `_acme-challenge` TXT record in your AWS Route 53 hosted zone.

Configure it interactively through the full-options menu (**M**), choosing the Route 53 DNS validation plugin, or supply the settings on the command line for unattended use:

```powershell
# Wildcard certificate validated via Route 53, exported as PEM files
.\wacs.exe `
    --target manual --host "*.example.com,example.com" `
    --validation route53 `
    --route53iamrole "arn:aws:iam::123456789012:role/win-acme-dns" `
    --store pemfiles --pemfilespath 'C:\certs' `
    --emailaddress admin@example.com --accepttos
```

win-acme can authenticate to AWS in two ways:

- **IAM role** (preferred on EC2): pass `--route53iamrole <role-arn>` and let the instance profile supply short-lived credentials. No stored secret.
- **Access keys**: pass `--route53accesskeyid <id>` and `--route53secretaccesskey <secret>` for machines outside AWS.

The IAM principal needs permission to read the hosted zone and change the challenge record. Scope it tightly:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListHostedZones",
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:GetChange"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ChangeChallengeRecords",
      "Effect": "Allow",
      "Action": "route53:ChangeResourceRecordSets",
      "Resource": "arn:aws:route53:::hostedzone/YOUR_HOSTED_ZONE_ID"
    }
  ]
}
```

> [!TIP]
> On an EC2 instance, prefer `--route53iamrole` with an instance profile over stored access keys. The instance profile provides short-lived, automatically rotated credentials, so no long-lived AWS secret is written to the win-acme configuration.

The same credential-handling discipline applies to every DNS provider plugin, not just Route 53.

> [!WARNING]
> DNS plugins need API credentials for your DNS provider so win-acme can create and remove the `_acme-challenge` TXT record automatically. Store these credentials securely, scope them to the minimum required permissions (for Route 53, restrict the IAM policy to the specific hosted zone as shown above), and never commit them to source control. See the [DNS validation plugin documentation](https://www.win-acme.com/reference/plugins/validation/dns/) for provider-specific setup.

If you cannot use a provider API, win-acme can run in **manual DNS** mode and pause while you create the TXT record by hand — useful for one-off wildcard certificates but unsuitable for automatic renewal.

## Installation Steps and Non-IIS Targets

win-acme separates the certificate lifecycle into **target** (what to certify), **validation** (prove control), **store** (where to keep the certificate), and **installation** (what to configure). This makes it useful beyond IIS.

- **Windows Certificate Store only**: Use `--store certificatestore --installation none` to place the certificate in the machine store for another service (SQL Server, RDS, a custom app) to consume by thumbprint.
- **PEM files**: Use `--store pemfiles --pemfilespath C:\certs` to export the certificate and key as PEM for tools that expect them (many non-Windows-native services).
- **PFX export**: Use `--store pfxfile` to produce a `.pfx` for import elsewhere.
- **Post-install scripts**: Use `--installation script` with `--script` and `--scriptparameters` to run a PowerShell script after each issuance/renewal — for example, to restart a service or copy the certificate to another host.

```powershell
# Export PEM files and run a post-renewal script (e.g. to reload a service)
.\wacs.exe `
    --target manual --host app.example.com `
    --validation selfhosting `
    --store pemfiles --pemfilespath 'C:\certs' `
    --installation script `
    --script 'C:\scripts\reload-app.ps1' `
    --scriptparameters '{CertCommonName} {CachePassword}' `
    --emailaddress admin@example.com --accepttos
```

## Managing Renewals

win-acme stores each renewal's configuration so it can repeat the process unattended.

```powershell
Set-Location 'C:\Program Files\win-acme'

# List all configured renewals
.\wacs.exe --list

# Renew everything that is due
.\wacs.exe --renew

# Force renew everything now (testing only — watch rate limits)
.\wacs.exe --renew --force

# Cancel / remove a renewal interactively (Manage renewals menu)
.\wacs.exe
# then choose: A - Manage renewals
```

Renewal configuration and account data live under `%ProgramData%\win-acme` by default. Back up this folder to preserve your ACME account key and renewal definitions.

> [!IMPORTANT]
> The renewal store under `%ProgramData%\win-acme` contains your ACME account key and (for DNS validation) may reference provider credentials. Include it in secure backups and protect it with appropriate NTFS permissions.

## Troubleshooting

| Symptom | Likely cause | Resolution |
| ------- | ------------ | ---------- |
| HTTP validation fails / timeout | Port 80 not reachable from the internet | Open port 80 in the firewall and any upstream NAT; confirm public DNS resolves to this host |
| "Rate limit exceeded" | Too many production requests | Switch to staging (`--baseuri` staging URL) while testing; wait for the limit window to reset |
| Renewal task never runs | win-acme run from a temp folder that was deleted | Reinstall to a permanent path and recreate renewals |
| Certificate issued but IIS still serves the old one | Binding not updated | Re-run with `--installation iis`, or check the binding's certificate hash in IIS Manager |
| "Access denied" writing to the store | Not running elevated | Re-run from an elevated (Administrator) session |
| DNS validation fails | TXT record not visible in time, or wrong credentials | Verify the `_acme-challenge` record with `Resolve-DnsName`; check DNS plugin credentials and propagation delay |

```powershell
# Inspect win-acme logs (default location)
Get-ChildItem "$env:ProgramData\win-acme\logs" | Sort-Object LastWriteTime -Descending | Select-Object -First 3

# Verify a challenge TXT record is published (DNS-01)
Resolve-DnsName -Name '_acme-challenge.example.com' -Type TXT

# Confirm the certificate landed in the machine store
Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -like '*example.com*'
```

## Best Practices

- **Install to a permanent path** (`C:\Program Files\win-acme`) so scheduled renewals never break.
- **Always run elevated** — certificate store and IIS binding operations require admin rights.
- **Test against staging first** with `--baseuri` before every production change.
- **Provide a real contact email** so the CA can warn you if automatic renewal stops working.
- **Back up `%ProgramData%\win-acme`** to preserve the ACME account key and renewal definitions.
- **Prefer EC keys** where compatible (`--certificatestore` scenarios) for smaller, faster certificates; keep RSA for broad compatibility.
- **Monitor expiry independently** — do not rely solely on the scheduled task; add an external check that alerts if a certificate gets within, say, 14 days of expiry.
- **Scope DNS credentials tightly** when using DNS-01 validation.

## Related Topics

- [ACME Protocol Overview](index.md)
- [Certbot Guide](certbot.md)
- [Certificate Management and PKI](../index.md)
- [OpenSSL Guide](../openssl/index.md)

## Additional Resources

- [win-acme Official Documentation](https://www.win-acme.com/)
- [win-acme GitHub Releases](https://github.com/win-acme/win-acme/releases)
- [win-acme Command Line Reference](https://www.win-acme.com/reference/cli)
- [win-acme DNS Validation Plugins](https://www.win-acme.com/reference/plugins/validation/dns/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
