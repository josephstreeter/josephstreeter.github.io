---

title:  Secure Active Directory DNS to Prevent Amplification Attacks
date:   2013-07-02 00:00:00 -0500
categories: IT
---






***Background***

A DNS amplification attack is a type of distributed denial of service attack that takes advantage of DNS servers that are configured as open resolvers. - Open resolvers are DNS servers providing recursion to anyone on the Internet. The attacker sends a small DNS query with a spoofed IP address to a vulnerable DNS server to direct a large amount of data to the victim.

***Summary***

Open resolvers on your network that are accessible to the- Internet can be- utilized in amplification attacks. It is important to secure these open resolvers to prevent future amplification attacks.- Never make Domain Controllers Internet accessible for any reason.

***Basic Configuration***

Firewall rules should be put in place that limit access to UDP/53 and TCP/53 on your Domain Controllers to your internal network IP space.- Additionally, rate limiting may be implemented to reduce the impact of the attack if it originates from within the allowed IP space.

***Recommended Configuration***

Domain Controllers can be isolated by using a separate set of DNS servers to provide recursion to your clients. These non-Domain Controller DNS servers can run Bind or Windows DNS. The Active Directory DNS servers can be further secured by disabling recursion, removing root hints, and removing forwarders. This measure has several requirements that must be met in order to be successful:

- The- DNS servers configured for recursion- must have the appropriate records (Stub Zone)- to send DNS queries for the Active Directory namespace to the DNS servers that are authoritative for the Active Directory DNS
- All client workstations and member servers must use- the- DNS servers configured for recursion as- primary and secondary- resolvers
- Domain Controllers- may- use these separate- DNS servers as- resolvers as well.- Otherwise the Active Directory DNS- will not be able to resolve any names that it is not authoritative for itself

The following steps must be performed on each Active Directory DNS server in order to disable recursion, remove forwarders, and remove root hints:

- Open DNS Management snap-in
- Right-click the DNS server and select properties
- Select the Advanced tab
- Check the box for Disable recursion
- Select the Forwarders tab
- Click the Edit button and remove each forwarder listed and click OK
- Uncheck the box for Use root hints if no forwarders are available
- Select the Root Hints tab
- Right select each entry and click the Remove button
- Click OK

In order for clients and member servers to resolve names in the Active Directory DNS zone the resolver DNS servers will require a stub zone.

***Additional Security Measures***

While not required to prevent amplification attacks, the following configuration changes should be considered when securing Active Directory DNS servers.

Secure the DNS information by configuring DNS zones to be Active Directory integrated. By doing this the DNS information is secured in the Active Directory database and it provides additional redundancy as a bonus.

- Open DNS Management snap-in
- Expand Forward Lookup Zones, right-click the DNS zone and select properties
- Next to Type click the Change button and check the box for Store this zone in Active Directory
- Click OK
- Click OK

Configure DNS zones to only accept secure dynamic updates. This configuration checks Active Directory for a valid computer object before allowing the host to create or update its DNS record.

- Open DNS Management snap-in
- Expand Forward Lookup Zones, right-click the DNS zone and select properties
- Change Dynamic updates to Secure only
- Click OK

***References***

- Disable Recursion on the DNS Server <a href="http://technet.microsoft.com/en-us/library/cc771738.aspx">http://technet.microsoft.com/en-us/library/cc771738.aspx</a>
- Configure a DNS Server to Use Forwarders <a href="http://technet.microsoft.com/en-us/library/cc754941.aspx">http://technet.microsoft.com/en-us/library/cc754941.aspx</a>
- Understanding stub zones <a href="http://technet.microsoft.com/en-us/library/cc779197(v=WS.10).aspx">http://technet.microsoft.com/en-us/library/cc779197(v=WS.10).aspx</a>



