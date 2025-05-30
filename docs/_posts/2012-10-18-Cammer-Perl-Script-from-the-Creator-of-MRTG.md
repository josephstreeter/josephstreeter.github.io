﻿---
title:  Cammer Perl Script from the Creator of MRTG
date:   2012-10-18 00:00:00 -0500
categories: IT
---

I haven't had a chance to try this script out yet. From what I've read it's pretty handy.

This is a  [site](http://www.remothelast.altervista.org/switchSNMP.html) that looks like it was taken from a SNMP book that I've read.
[cammer.pl](http://oss.oetiker.ch/mrtg/pub/contrib/cammer)

```text
cammer - list switch ports with associated IP-addresses

SYNOPSIS

cammer [--arp=comunity@router] [--verbose] community@switch

DESCRIPTION

Cammer is a script which polls a switch is able to query a switch for its
ethernet to port asignements. If a source of ip2mac mappings is provided as
well, it will resolve the ethernet addresses too.

Cammer will use the machines local arp cache as well as the the /var/lib/dhcp3/dhcpd.leases
file to resolve etherent addresses
If you have a router, the router might know a lot about mac2ip mapping. Use

--arp=comunity@router

to query the router for its arp table.

We found that running something like

nmap --host-timeout 2s -sP 192.168.0.0/24

(as user!) helps to populate the local arp cache.

COPYRIGHT

Copyright (c) 2000 ETH Zurich, All rights reserved.
Copyright (c) 2008 OETIKER+PARTNER AG

LICENSE

This script is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

AUTHOR

Tobi Oetiker E <tobi@oetiker.ch>
```

A Tek-Tips user, PalmTest, had this to say in a [post](http://www.tek-tips.com/viewthread.cfm?qid=1128455&page=1):

Here is the script. Like I said, I haven't tried this yet. So, it is what it is. Don't cry to me if it doesn't work.

```perl
#! /usr/bin/perl
# -*- mode: Perl -*-
##################################################################
# Cammer 2.0
##################################################################
# Created by Tobi Oetiker <tobi@oetiker.ch>
##################################################################
# $Id: cammer 253 2008-07-08 19:22:10Z oetiker $

require 5.005;
use strict;
my $DEBUG = 0;

use FindBin;
use lib "${FindBin::Bin}";
use lib "${FindBin::Bin}/../lib/mrtg2";

use SNMP_Session "0.78";
use BER "0.77";
use SNMP_util "0.77";
use Getopt::Long;
use Pod::Usage;
use Socket;


my %OID = ('vlanIndex' =>             [1,3,6,1,4,1,9,5,1,9,2,1,1],
'vmVlan' =>                [1,3,6,1,4,1,9,9,68,1,2,2,1,2],
'dot1dTpFdbPort' =>        [1,3,6,1,2,1,17,4,3,1,2],
'dot1dBasePortIfIndex' =>  [1,3,6,1,2,1,17,1,4,1,2],
'sysObjectID' =>           [1,3,6,1,2,1,1,2,0],
'CiscolocIfDescr' =>       [1,3,6,1,4,1,9,2,2,1,1,28],
'ifAlias' =>               [1,3,6,1,2,1,31,1,1,1,18],
'ifName' =>                [1,3,6,1,2,1,31,1,1,1,1],
'ipNetToMediaPhysAddress' => [1,3,6,1,2,1,4,22,1,2],
);


# Add the Cisco model number as displayed by the sysDescr.0 OID:
#   $ snmpget -v 1 -c public <IP|hostname> sysDescr.0
#
#  or by using your favorite SNMP MIB browser
my $CiscoCatIOS = "2900|3500|2950|2960|3550|4000 L3";

sub main {
my %opt;
options(\%opt);
$DEBUG=1 if $opt{verbose};
# which vlans do exist on the device
my @vlans;
my $vlani;
my %vlan;
my $sws = SNMPv2c_Session->open ($opt{sw},$opt{swco},161)
|| die "Opening SNMP_Session\n";


warn "* Query sysDescr to identify Switch\n";
my $sysdesc = (snmpget($opt{swco}.'@'.$opt{sw},'sysDescr'))[0];
my $mode = 'vlan';

if ($sysdesc =~ /$CiscoCatIOS/){
warn "* Query VLAN list with vmVlan (Cisco Style)\n";
$sws->map_table_4 ( [$OID{'vmVlan'}],
sub {    my($x,$value) = pretty(@_);
$vlan{$x} = $value; # catalyst 2900
print "if: $x, vlan: $value\n" if $DEBUG;
if (not scalar grep {$_ eq $value} @vlans) {
push @vlans, $value;
print "vlan: $value\n" if $DEBUG;
}
}
,100);
} else {
warn "* Query VLAN list with vlanIndex\n";
$sws->map_table_4 ([$OID{'vlanIndex'}],
sub {
my($x,$value) = pretty(@_);
push @vlans, $value;
print "vlan: $value\n" if $DEBUG;
}
,100 );
}

if (scalar @vlans == 0){
warn "* No VLANs were found, switching to normal mode\n";
$mode = 'normal';
push @vlans, '';
}

# which ifNames
my %name;
warn "* Gather Interface Name Table with ifName\n";
$sws->map_table_4 ([$OID{'ifName'}],
sub { my($if,$name) = pretty(@_);
print "if: $if, name: $name\n" if $DEBUG;
$name{$if}=$name;
}
,100);
$sws->close();

my %ip;
my %dhcp_host;

if (open my $arp, "arp -a|"){
warn "* Calling arp command to gather local arp table\n";
while (<$arp>){
chomp;
#gumpu.oetiker.ch (192.168.0.157) at 00:0C:29:11:3F:92 [ether] on lan
/\((\S+?)\)\sat\s(00:\S+)/ or next;
my $ip = $1;
my $mac = lc($2);
push @{$ip{$mac}}, $ip;
print "ip: $ip, mac: $mac\n" if $DEBUG;
}
close $arp;
}
if (open my $dhcp, "/var/lib/dhcp3/dhcpd.leases"){
my $ip;
my $mac;
my $name;
while (<$dhcp>){
/lease\s(\S+)\s\{/ and do {
$ip = $1;
$mac = undef;
$name = undef;
next;
};
/client-hostname\s"(\S+?)";/ and $name = $1;
/hardware\sethernet\s(\S+?);/ and $mac = lc($1);
/^\}/ and do {
push @{$ip{$mac}}, $ip if $ip;
$dhcp_host{$mac} = $name if $name;
}
}
}

warn "* Calling arp command to gather local arp table\n";
open my $arp, "arp -a|" or die $!;
while (<$arp>){
chomp;
#gumpu.oetiker.ch (192.168.0.157) at 00:0C:29:11:3F:92 [ether] on lan
/\((\S+?)\)\sat\s(00:\S+)/ or next;
my $ip = $1;
my $mac = lc($2);
push @{$ip{$mac}}, $ip;
print "ip: $ip, mac: $mac\n" if $DEBUG;
}


if ($opt{ro}){
# get mac to ip from router
warn "* Gather Arp Table from $opt{roco}\@$opt{ro} with ipNetToMediaPhysAddress\n";
my $ros = SNMPv2c_Session->open ($opt{ro},$opt{roco},161)
|| die "Opening SNMP_Session\n";

$ros->map_table_4 ([$OID{'ipNetToMediaPhysAddress'}],
sub {
my($ip,$mac) = pretty(@_);
$mac = unpack 'H*', pack 'a*',$mac;
$mac =~ s/../$&:/g;
$mac =~ s/.$//;
$ip =~ s/^.+?\.//;
push @{$ip{$mac}}, $ip;
print "ip: $ip, mac: $mac\n" if $DEBUG;
}
,100);
$ros->close();
}
# walk CAM table for each VLAN
my %if;
my %port;
foreach my $vlan (@vlans){
# catalist 2900 does not use com@vlan hack
$vlan = '@'.$vlan if $vlan;
warn "* Connecting  to $opt{swco}$vlan\@$opt{sw}\n";
my $sws = SNMPv2c_Session->open ($opt{sw},$opt{swco}.$vlan,161)
|| die "Opening SNMP_Session\n";
warn "* Reading mac2port assignement from dot1dTpFdbPort table\n";
$sws->map_table_4 ([$OID{'dot1dTpFdbPort'}],
sub {
my($mac,$port) = pretty(@_);
next if $port == 0;
$mac = sprintf "%02x:%02x:%02x:%02x:%02x:%02x", (split /\./, $mac);
print "mac: $mac,port: $port\n" if $DEBUG;
$port{$vlan}{$mac}=$port;
}
,100);
warn "* Reading port2if assignement from dot1dBasePortIfIndex table\n";
$sws->map_table_4 ( [$OID{'dot1dBasePortIfIndex'}],
sub {  my($port,$if) = pretty(@_);
next if $port == 0;
print "port: $port, if: $if\n" if $DEBUG;
$if{$vlan}{$port} = $if;
}
,100);
$sws->close();
}
my %output;
foreach my $vlan (@vlans){
foreach my $mac (keys %{$port{$vlan}}){
my @ip = $ip{$mac} ? @{$ip{$mac}} : ();
my @host;
foreach my $ip (@ip) {
my $host = gethostbyaddr(pack('C4',split(/\./,$ip)),AF_INET);
push @host, ($host or $ip);
}
my $name = $name{$if{$vlan}{$port{$vlan}{$mac}}};
my $truevlan = $vlan eq 'none' ? $vlan{$if{$vlan}{$port{$vlan}{$mac}}} : $vlan;
my $quest = scalar @ip > 1 ? "(Multi If Host)":"";
push @{$output{$name}}, sprintf "%4s  %-17s  %-15s  %s %s",$truevlan,$mac,$ip[0],$host[0],$dhcp_host{$mac}?"($dhcp_host{$mac})":'';
}
}
foreach my $name (sort { ($a =~ /(\d+)/)[0] <=> ($b =~ /(\d+)/)[0]}  keys %output){
my $tag = '>';
foreach my $line (@{$output{$name}}) {
printf "$tag %-4s  %s\n", $name , $line;
$tag = ' ';
}
}
}

main;
exit 0;


sub options {
my $opt = shift;
GetOptions( $opt,
'arp=s',
'verbose',
'help|?',
'man') or pod2usage(2);
pod2usage(-exitstatus => 0, -verbose => 2) if $opt->{man};
pod2usage(-verbose => 1) if $opt->{help} or scalar @ARGV != 1;

$opt->{sw} = shift @ARGV;

$opt->{sw} =~ /^(.+)@(.+?)$/;
$opt->{sw} = $2;
$opt->{swco} = $1;

if ($opt->{arp} and $opt->{arp} =~ /^(.+)@(.+?)$/){
$opt->{ro} = $2;
$opt->{roco} = $1;
}
}

sub pretty(@){
my $index = shift;
my @ret = ($index);
foreach my $x (@_){
push @ret, pretty_print($x);
};
return @ret;
}
```
