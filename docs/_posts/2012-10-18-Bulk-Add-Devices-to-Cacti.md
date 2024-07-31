---

title:  Bulk Add Devices to Cacti
date:   2012-10-18 00:00:00 -0500
categories: IT
---

Working on a script to bulk add devices to Cacti. I've done on in a bash script, but that will only work on a windows box. I wrote this perl script so that I should be able to run it on any Linux or Windows box as long as perl is installed.

```batch
#!/usr/bin/perl -w

$LOGFILE = "/home/hades/perl/devices";
open(LOGFILE) or die("Could not open log file.");
foreach $line (<LOGFILE>) {

($description, $ip, $template, $notes, $avail, $version, $community) = split(',',$line);

system("php /usr/share/cacti/cli/add_device.php --description=$description --ip=$ip --template=$template --notes=\"$notes\" --avail=$avail --version=$version --community=$community");
}
```

The source for the script is this text file named devices.

```bash
Firewall1,172.16.10.1,9,Firewall,snmp,2,public
Router1,10.10.0.1,5,Edge router,snmp,2,public
Switch2,10.10.0.5,5,Core switch,snmp,,2,public
Switch3,10.10.0.6,5,Access switch,snmp,,2,public
Switch4,10.10.0.7,5,Access switch,snmp,2,public
Switch5,10.10.0.8,5,Access switch,snmp,2,public
```

I have some more tweaking to do, but it's basically functional.
