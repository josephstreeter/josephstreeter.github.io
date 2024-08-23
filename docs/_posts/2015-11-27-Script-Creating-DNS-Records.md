---

title:  Script Creating DNS Records
date:   2015-11-27 00:00:00 -0500
categories: IT
---

This script creates Host A records for a list of hosts.

```powershell
$records = "mimsvc,10.39.0.78","mimsps,10.39.0.78","mimsync,10.36.1.53","mimsvcsql,10.36.1.52","mimspssql,10.36.1.52","mimsyncsql,10.36.1.52"
$DNSServer = "DC"
$Zone = "domain.tld"

foreach ($record in $records)
{
    $Name = $record.split(",")[0]
    $Ip = $record.split(",")[1]

    Add-DnsServerResourceRecordA `
        -ComputerName $DNSServer `
        -ZoneName $Zone `
        -Name $Name `
        -IPv4Address $Ip
}
```
