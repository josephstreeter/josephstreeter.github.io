---

title:  Delegate DNS Zone in BIND
date:   2013-12-10 00:00:00 -0500
categories: IT
---






The following will delegate a zone file for a sub-domain, "sub", under the "example.com" parent domain.

Edit the "/etc/named.conf" file on "ns1.example.com" by adding a block for the parent domain:
```powershellzone "example.com" IN {
type master;
file "db.example.com";
allow-update { none; };
notify no;
forwarders { };```
Create the "db.example.com" zone file for the "example.com" domain if it doesn't already exist:
```powershell$TTL 1200
$ORIGIN example.com.

@       IN      SOA     ns1.example.com.  hostmaster.example.com. (
2009032201      ; serial
1800            ; refresh
900             ; retry
1209600         ; expire
1200            ; minimum TTL
)

IN      NS      ns1.example.com.
IN      NS      ns2.example.com.

ns1     A       192.168.0.53
ns2     A       192.168.1.53
mail    A       192.168.0.25
www     A       192.168.0.80```
Once the "example.com" zone is verified as working you can add the info for the "sub.example.com" zone file:
```powershellsub.example.com.       IN   NS  ns1.sub.example.com.
sub.example.com.       IN   NS  ns2.sub.example.com.
ns1.sub.example.com.   IN   A   192.168.10.53
ns2.sub.example.com.   IN   A   192.168.20.53```
Edit the "/etc/named.conf" file on "ns1.sub.example.com" by adding a block for the sub domain:
```powershellzone "sub.example.com" IN {
type master;
file "db.sub.example.com";
allow-update { none; };
notify no;
forwarders { };```
Create the "db.sub.example.com" zone file for the "sub.example.com" domain:
```powershell$TTL 1200
$ORIGIN sub.example.com.

@       IN      SOA     ns1.sub.example.com.  hostmaster.sub.example.com. (
2009032201      ; serial
1800            ; refresh
900             ; retry
1209600         ; expire
1200            ; minimum TTL
)

IN      NS      ns1.sub.example.com.
IN      NS      ns2.sub.example.com.

ns1     A       192.168.10.53
ns2     A       192.168.20.53
mail    A       192.168.10.25
www     A       192.168.10.80```


