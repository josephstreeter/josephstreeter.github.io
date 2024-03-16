---
layout: post
title:  Run Commands on Remote Routers (Perl and EXPECT)
date:   2012-10-18 00:00:00 -0500
categories: IT
---






It seems that you can blow your budget and dedicate one person to using something like CiscoWorks (just to have the server die anyways) or you can use a little Perl-fu and learn some Expect scripting.
I wanted to be able to do bulk configurations to routers and switches the way I could with servers and workstations. Originally I wanted to use Perl only, but the SSH module seems a bit flaky. The telnet module works awesome, but who uses telnet anymore unless they have no choice! After that I tried Expect and it seemed to work well, but if it cratered on something the whole thing hung and ended. I'm sure it could be fixed with some more code, but I'm not that strong at Expect yet.
What I settled on was a combination of a perl script that calls an expect script for each device. In the future I would like to have the Perl script get it's information from a database, but lets not get ahead of ourselves.
---
Here is the Perl Script
{% highlight powershell %}
#! \usr\bin\perl
use warnings;
use strict;

$data_file="network_switches";

open(DAT, $data_file) || die("failed to open file!");
@raw_data=<DAT>;
close(DAT);

my $i;
foreach $i (@array) {
system("expect expect_cisco_router $i");
}
{% endhighlight %}

The script will enumerate the hosts listed in the text file, network_routers, and then calls the expect script below using the host ip as an argument.
Here is the Expect Script
{% highlight powershell %}
#!/usr/bin/expect

set timeout 2
set user "username"
set password "password"
set enable "enable-password"
set tftp "ip or host of tftpd"
set ip [lindex $argv 0]

spawn ssh $user@$ip
expect "*port 22: Connection refused" {
spawn telnet $ip
expect "Username:"
send "username\r"
}
expect "*(yes/no)" {
send "yes\r"
sleep 5
}

sleep 2
expect "?assword:"
send $password\r
expect "*#"
send "enable\r"
expect "Password:"
send $enable\r
expect "*#"
send "copy start tftp\r"
expect "address or name of remote host"
send $tftp "\r"
expect "?"
send "\r"
expect "*#"
sleep 2
send "exit\r"
expect eof
{% endhighlight %}

This script will try SSH first and then telnet if that fails.
{% highlight powershell %}
spawn ssh $user@$ip
expect "*port 22: Connection refused" {
spawn telnet $ip
expect "Username:"
send "username\r"
}
{% endhighlight %}

This can be removed if you do not have any equipment that is not capable of SSH. The code will look like the lines below instead.
{% highlight powershell %}
spawn ssh $user@$ip
expect "*(yes/no)" {
send "yes\r"
sleep 5
}
{% endhighlight %}


