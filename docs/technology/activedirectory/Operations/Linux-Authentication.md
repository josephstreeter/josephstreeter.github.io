# Linux Authentication

Created: 2015-03-20 09:46:00 -0500

Modified: 2015-03-20 09:48:44 -0500

---

**Keywords:** active directory red hat centos rhel linux

**Summary:** Linux hosts can be configured to allow local console logon or remote logon though a service such as SSH. The configuration steps will vary depending on the Linux distribution and version used. Linux hosts will utilize the Kerberos authentication service that is integrated with Active Directory

**[Support]{.underline}**

Support from the Campus Active Directory Service Team for Active Directory authentication on Linux hosts will be limited to distributions and versions that are supported by the DoIT Systems Engineering Linux Team. All other distributions and versions will be supported as â€œBest Effort.â€ While basic support of supported distributions and versions will be provided at no cost, advanced support may incur charges.

**[Methods]{.underline}**

Four methods exist for configuring Active Directory authentication on Linux hosts. Currently two methods will be supported by the Campus Active Directory Service Team:

1.)**Kerberos with stub user accounts** â€" Configuring the Linux hostâ€™s Kerberos client and PAM to use Active Directory and provision a local user object with a username matching the NetID of each user authorized access to the host.

2.)**Bind to Active Directory** â€" Configuring Kerberos, Samba/Winbind, PAM and NSS to bind the host to Active Directory. Winbind uses Kerberos for authentication and LDAP to retrieve user and group information. Winbind will also perform other tasks such as changing the computer object password and perform the DCLOCATOR process in order to find Domain Controllers.

The following methods are not supported by the Campus Active Directory Service Team:

3.)**Bind to Active Directory using third-party clients** â€" Several vendors provide clients that can be installed on the Linux hosts to bind to Active Directory and provide authentication/authorization. No third-party clients have been tested and none are supported by the Service Team.

4.)**LDAP Authentication** Configuring PAM to use LDAP for authentication. While this is a simple method of configuring Active Directory authentication, this method has very limited functionality and is the least secure. LDAP authentication is not supported by the Service Team.

**[Components]{.underline}**

**Active Directory** A distributed Jet/ESE database that is exposed through LDAP and includes services such as Kerberos and DNS.

**Samba** An open source suite of programs that provide file and print services for Linux clients and servers in a Windows environment.

**Winbind** A part of the samba suite that uses Remote Procedure Calls (RPC), Pluggable Authentication Modules (PAM), Name Service Switch (NSS) to interact with Active Directory.

**Kerberos** A network authentication protocol that uses symmetric key cryptography to provide highly secure authentication between client and server applications.

**LDAP** Lightweight Data Access Protocol is a protocol based on the x.500 standard to access information from a central directory.

**DNS** A hierarchical, distributed naming system for managing the mapping of human-friendly domain, host, and service names to IP addresses.

**NTP** A protocol used to synchronize system clocks on network connected hosts.

**NSS** Allows a host to obtain passwd, shadow, and group information from a centralized services such as LDAP, NIS, etc.

**PAM** A mechanism that allows individual applications to utilize their own authentication methods independent of the authentication schemes configured for other applications.

**[Configuration]{.underline}**

**Kerberos with Stub User Accounts**

Red Hat Enterprise Linux

Install the following packages

yum install krb5-workstation pam_krb5 authconfig ntp

Verify DNS client settings in "/etc/resolve.conf"

domain ad.wisc.edu

search ad.wisc.edu

nameserver 128.104.254.254

nameserver 144.92.254.254

Configure NTP (/etc/ntp.conf)

server 128.104.30.17

server 144.92.20.100

Synchronize the host's time

ntpdate 144.92.20.100

Configure the kerberos client (/etc/krb5.conf)

[libdefaults]

default_realm = AD.WISC.EDU

dns_lookup_realm = true

dns_lookup_kdc = true

ticket_lifetime = 24h

renew_lifetime = 7d

forwardable = true

[realms]

AD.WISC.EDU = {

}

[domain_realm]

.ad.wisc.edu = AD.WISC.EDU

ad.wisc.edu = AD.WISC.EDU

Create stub user on the host.

adduser <netid> -m -s /bin/bash

**[Bind to Active Directory]{.underline}**

Redhat Enterprise Linux

Configure hostname (/etc/sysconfig/network)

NETWORKING=yes

HOSTNAME=<clientid>.ad.wisc.edu

Configure the hosts file (/etc/hosts)

127.0.0.1 <clientid>.ad.wisc.edu <clientid>

Install the following packages

yum install samba samba-common samba-client samba-winbind samba-winbind-clients krb5-workstation pam_krb5 authconfig ntp

# Configure winbind to start

chkconfig winbind on

service winbind start

# Configure Samba to start

chkconfig smb on

service smb start

# Configure NSS to start

chkconfig nmb on

service nmb start

# Configure Home directory

mkdir /home/AD

chmod 0666 /home/AD

hostname -f

# Configure DNS client

# /etc/resolv.conf

search ad.wisc.edu

nameserver 128.104.254.254

nameserver 144.92.254.254

# Test DNS

ping ad.wisc.edu

host -t srv _kerberos._tcp.ad.wisc.edu

host -t srv _kpasswd._tcp.ad.wisc.edu

host -t srv _ldap._tcp.ad.wisc.edu

host -t srv _gc._tcp.ad.wisc.edu

# Configure ntp

# /etc/ntp.conf

server 128.104.30.17

server 144.92.20.100

# Synchronize time

ntpdate 144.92.20.100

# Configure authentication/authorization

# /etc/krb5.conf, /etc/samba/smb.conf, /etc/pam.d/system-auth, /etc/nsswitch.conf

authconfig

 --disablecache

 --enablewinbind

 --enablewinbindauth

 --smbsecurity=ads

 --smbworkgroup=$domain

 --smbrealm=$domainname

 --enablewinbindusedefaultdomain

 --winbindtemplatehomedir=/home/$domain/%U

 --winbindtemplateshell=/bin/bash

 --enablekrb5

 --krb5realm=$domainname

 --enablekrb5kdcdns

 --enablekrb5realmdns

 --enablelocauthorize

 --enablemkhomedir

 --enablepamaccess

 --updateall

service winbind restart

# RID Mapping <http://technet.microsoft.com/en-us/magazine/2008.12.linux.aspx>

# /etc/samba/smb.conf

workgroup = $domain

realm = $domainname

security = ads

idmap domains = AD# Add this line

idmap config AD:backend = rid# Add this line

idmap config AD:base_rid = 500# Add this line

idmap config AD:range = 500-1000000# Add this line

# idmap uid = 16777216-33554431# Comment out this line

# idmap gid = 16777216-33554431# Comment out this line

template homedir = /home/$domain/%U

template shell = /bin/bash

winbind use default domain = true

winbind offline logon = false

# Verify Kerberos client config

# /etc/krb5.conf

[logging]

default = [FILE:/var/log/krb5libs.log](FILE://var/log/krb5libs.log)

kdc = [FILE:/var/log/krb5kdc.log](FILE://var/log/krb5kdc.log)

admin_server = [FILE:/var/log/kadmind.log](FILE://var/log/kadmind.log)

[libdefaults]

default_realm = AD.WISC.EDU

dns_lookup_realm = true

dns_lookup_kdc = true

ticket_lifetime = 24h

renew_lifetime = 7d

forwardable = true

[realms]

AD.WISC.EDU = {

}

[domain_realm]

.ad.wisc.edu = AD.WISC.EDU

ad.wisc.edu = AD.WISC.EDU

# Verify Kerberos functionality

# Flush current tickets and requrest new tickets

kdestroy

klist

klist: No credentials cache found (ticket cache [FILE:/tmp/krb5cc_0](FILE://tmp/krb5cc_0))

kinit <netid>

Password for <netid>: ***********

klist

Ticket cache: [FILE:/tmp/krb5cc_0](FILE://tmp/krb5cc_0)

Default principal: <administrator@AD.WISC.EDU>

Valid starting Expires Service principal

03/22/12 19:31:49 03/23/12 05:31:52 krbtgt/REFARCHAD.

<CLOUD.LAB.ENG.BOS.REDHAT.COM@REFARCHAD>.

CLOUD.LAB.ENG.BOS.REDHAT.COM

renew until 03/29/12 19:31:49

# Join to domain

net ads join -U $username

# tail "/var/log/secure" for errors
