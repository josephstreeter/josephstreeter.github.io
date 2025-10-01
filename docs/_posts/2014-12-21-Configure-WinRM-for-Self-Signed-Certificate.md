---
title:  Configure WinRM for Self-Signed Certificate
date:   2014-12-21 00:00:00 -0500
categories: IT
---

First, create the self-sighed certificate using the New-SelfSignedCertificate cmdlet.

```powershell
New-SelfSignedCertificate -DnsName comp-name.domain.tdl -CertStoreLocation Cert:\LocalMachine\My
```

Example Results:

```console
PS C:\> New-SelfSignedCertificate -DnsName comp-name.domain.tdl -CertStoreLocation Cert:\LocalMachine\My

Directory: Microsoft.PowerShell.Security\Certificate::LocalMachine\My

Thumbprint                                Subject
----------                                -------
65C6C9F1B062FE48E53687AA226F6FF1655AFBCC  CN=comp-name.domain.tdl```
Next, configure the WinRM listener to use the certificate that you created by specifying its thumbprint (place all on one line).
```powershellwinrm create winrm/config/listener?Address=*+Transport=HTTPS '@{Hostname="comp-name.domain.tdl";CertificateThumbprint="65C6C9F1B062FE48E53687AA226F6FF1655AFBCC";port="5986"}'```
Notice the single quotes in the command. This allows the command to be run from PowerShell.

Example Results:
```powershellPS C:\> winrm create winrm/config/listener?Address=*+Transport=HTTPS '@{Hostname="comp-name.domain.tdl";CertificateThumbprint="65C6C9F1B062FE48E53687AA226F6FF1655AFBCC";port="5986"}'
ResourceCreated
Address = http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous
ReferenceParameters
ResourceURI = http://schemas.microsoft.com/wbem/wsman/1/config/listener
SelectorSet
Selector: Address = *, Transport = HTTPS
```

Lastly, make sure that the WinRM traffic is allowed through the firewall. Create a rule with the name "Windows Remote Management (HTTPS-In)" that allows TCP/5986 through.

```powershell
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP
```

To connect to the host from another client use the following code:

```powershell
$Options = New-PsSessionOption -SkipCACheck
etsn -cn comp-name.domain.tdl -Credential $(get-credential) -UseSSL -SessionOption $Options
```

The following PowerShell script will configure the WinRM service create the HTTPS WinRM listener with a self-signed certificate and create a firewall rule:

```powershell
If ((Get-Service WinRM).status -eq "Stopped") {Start-Service WinRM}

$DNSName = $(Get-WmiObject -class win32_computersystem).name + "." + $(Get-WmiObject -class win32_computersystem).domain
$Name = $(Get-WmiObject -class win32_computersystem).name

$cert = New-SelfSignedCertificate -DnsName $ENV:COMPUTERNAME, "$env:COMPUTERNAME.$env:USERDNSDOMAIN".ToLower() -CertStoreLocation Cert:\LocalMachine\My
$Config = '@{Hostname="' + $ENV:COMPUTERNAME + '";CertificateThumbprint="' + $cert.Thumbprint + '"}'
winrm create winrm/config/listener?Address=*+TransPort=HTTPS $Config

If (-Not(get-netfirewallrule "Windows Remote Management (HTTPS-In)"))
{
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP
}
```
