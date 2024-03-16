---
layout: post
title:  OpenLDAP and Kerberos on Debian
date:   2012-10-19 00:00:00 -0500
categories: IT
---






I've been working on creating a LDAP/Kerberos lab for a while now. The idea being that once I get it all working I can start trying out how to make it play nicely with Active Directory.

These articles have gotten me started:

- <a href="http://www.linux-mag.com/id/4738/">Integrating LDAP and Kerberos: Part One (Kerberos) - LINUX Magazine</a>
- <a href="http://www.linux-mag.com/id/4765/">Integrating LDAP and Kerberos: Part Two (LDAP) - LINUX Magazine</a>
- <a href="http://web.mit.edu/kerberos/krb5-1.6/krb5-1.6.3/doc/krb5-admin.html">Kerberos V5 System Administrator's Guide</a>
- <a href="http://techpubs.spinlocksolutions.com/dklar/ldap.html">Debian GNU: Setting up OpenLDAP</a>
- <a href="http://techpubs.spinlocksolutions.com/dklar/kerberos.html">Debian GNU: Setting up MIT Kerberos 5</a>
- <a href="http://www.rjsystems.nl/en/2100-openldap-client.php">OpenLDAP client on Debian lenny</a>
- <a href="https://help.ubuntu.com/11.04/serverguide/C/kerberos-ldap.html">Kerberos and LDAP - Ubuntu Documentation</a>

The following command can be used to bind to Active Directory and search:
ldapsearch -b 'dc=domain,dc=com' -D 'domain\user' -W -x

These tools are helpful in troubleshooting kerberos:
kinit - Request a ticket from the KDC
klist - List the tickets that you have been issued
klist -k - List the SPNs that are configured in your keytab file

Command for creating Keytab:
ktpass /princ host/servername@domain.com /mapuser servername@domain.com /pass Pa$$Word123456 /out c:\krb5.keytab /crypto all /ptype KRB5_NT_PRINCIPAL

Command for creating mod_auth_kerb Keytab:
ktpass /princ HTTP/servername@domain.com /mapuser servername@domain.com /pass Pa$$Word123456 /out c:\mod_auth_kerb.keytab /crypto all /ptype KRB5_NT_PRINCIPAL


