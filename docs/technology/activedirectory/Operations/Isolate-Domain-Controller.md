# Isolate Domain Controller

When replacing Domain Controllers, it can be disruptive to services that are hard-coded to use either the name or the IP of the old hosts. To check for services still using the old Domain Controllers because information is hard-coded, we can isolate the hosts from being discovered through the use of resource records in DNS. Once this is done, we can investigate any connections to these hosts.

## Prevent Registering All DNS Resource Records

Prevent the Domain Controller from registering any Resource Records in DNS.

```text
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters
```

```text
UseDynamicDns REG_SZ = 0x0
```

Restart the Netlogon service or reboot the host for the changes to take effect.

## Prevent Registering Non-Site Specific DNS Resource Records

Domain controllers will publish site-specific and non-site-specific DNS SRV resource records.

Location of the resource records:

- ```Site-Specific - <domain> - _sites - _tcp```
- ```Non-site-specific - <domain> - _tcp```

If a client cannot locate a domain controller in the local site, it will query the non-site-specific records to locate a domain controller anywhere in the environment. If there are domain controllers that should not be answering these requests, like a branch office, Group Policy can be used to prevent those domain controllers from registering non-site-specific resource records.

Create a new Group Policy Object and link it to the Domain Controllers OU. Be sure to scope the policy to only apply to the domain controllers that should have the policy applied to.

Locate the following policy:

```text
Computer Configuration -> Policies -> Administrative Templates -> System -> Net Logon -> DC Locator DNS Records -> Specify DC Locator DNS records not registered by the DCs
```

Set the policy to enabled and configure the following mnemonics:

```text
LdapIpAddress Ldap Gc GcIPAddress Kdc Dc DcByGuid Rfc1510Kdc Rfc1510Kpwd Rfc1510UdpKdc Rfc1510UdpKpwd GenericGc
```

Restart the Netlogon service or reboot the host for the changes to take effect.

## Resources

- [MS Learn: Description of the netmask ordering feature and the round robin feature in Windows Server 2003 DNS](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/how-to-use-netmask-ordering-round-robin-feature#more-information)
- [MS Learn: How to optimize the location of a domain controller or global catalog that resides outside of a client's site](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/optimize-dc-location-global-catalog)
- [MS Learn: Description of the netmask ordering feature and the round robin feature in Windows Server 2003 DNS](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/how-to-use-netmask-ordering-round-robin-feature)
- [How to create an Active Directory Subnet/Site with /32 or /128 and why](http://blogs.technet.com/b/askpfeplat/archive/2013/03/27/how-to-create-an-active-directory-subnet-site-with-32-or-128-and-why.aspx)
- [Preventing a Domain Controller from Dynamically Registering Certain Resource Records](http://codeidol.com/active-directory/active-directory/DNS-and-DHCP/Preventing-a-Domain-Controller-from-Dynamically-Registering-Certain-Resource-Records/)
- [https://blog.matrixpost.net/prevent-branch-office-domain-controller-from-registering-generic-dns-records-and-netmask-ordering/](https://blog.matrixpost.net/prevent-branch-office-domain-controller-from-registering-generic-dns-records-and-netmask-ordering/)
