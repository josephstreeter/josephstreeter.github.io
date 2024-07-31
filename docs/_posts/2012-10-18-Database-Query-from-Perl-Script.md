---

title:  Database Query from Perl Script
date:   2012-10-18 00:00:00 -0500
categories: IT
---

You can always find a use for a script that will query against a database.
I worte this one to query on of our network management databases running on MySQL 5 to feed another Perl script that I've written for configuring Cisco equipment.

```perl
#! /usr/bin/perl

use warnings;
use DBI;

$host = "*Name/ip*";
$dbname = "*DB Name*";
$user = "*DB UserName*";
$pass = "*DB Password*";
$table = "*Table Name*";

my $db = DBI->connect("DBI:mysql:$dbname;host=$host", $user, $pass);

$DBI::result = $db->prepare("select * from $table ORDER by hostname");
$DBI::result->execute();
```
