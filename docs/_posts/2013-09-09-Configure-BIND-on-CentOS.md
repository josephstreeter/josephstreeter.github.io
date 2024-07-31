---

title:  Configure BIND on CentOS
date:   2013-09-09 00:00:00 -0500
categories: IT
---






The following instructions will help you install and configure BIND on CentOS 6.

Install BIND with the following command:
```powershellyum install bind -y```


Create a zone file for the new domain
```powershellvi /var/named/test.domain.com```
Add the zone information for the new domain
```powershell$TTL	1H
@       IN      SOA     test.domain.com. hostmaster.test.domain.com. (
2012080701      ; Serial
1H      ; Refresh
30M       ; Retry
20D    ; Expire
1H )  ; Minimum

@       IN      NS      ns1.test.domain.com.
@       IN      NS      ns2.test.domain.com.
ns1     IN      A       192.168.0.254
ns2     IN      A       192.168.0.253

@       IN      MX  10  smtp.test.domain.com.

www     IN      A       192.168.0.1
smtp    IN      A       192.168.0.1
ftp     IN      A       192.168.0.1```
Add the new zone file to the named.conf file.
```powershellvi /etc/named.conf```


Add the following text to add the zone file
```powershellzone "test.domain.com" {
type master;
file "/var/named/test.domain.com";
};```


Change the following lines from:
```powershelllisten-on port 53 {127.0.0.1; };
allow-query { localhost; };```
to:
```powershelllisten-on port 53 { 192.168.254.254; }; // Enter the interface you want BIND to listen on.
allow-query { any; };  // May also be an IP address or subnet```
Optionally add forwarders by adding the following line:
```powershellforwarders { 8.8.8.8; 8.8.4.4; };```
You may turn off recursion if it isn't required by changing the following line"
```powershellrecursion yes;```
To
```powershellrecursion no;```
Restart the named service
```powershellservice named restart```


