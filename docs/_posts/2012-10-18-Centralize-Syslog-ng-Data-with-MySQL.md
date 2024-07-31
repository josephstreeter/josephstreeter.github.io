---
title:  Centralize Syslog-ng Data with MySQL
date:   2012-10-18 00:00:00 -0500
categories: IT
---

You can send all of your syslog data to a MySQL database using syslog-ng on a linux box. You can then use PHP to display the SQL queries in a table. It's handy to see what's going on with your equipment and doesn't cost a thing!

Configure the MySQL database:

```sql
CREATE DATABASE syslog;

USE syslog;

CREATE TABLE logs (
host varchar(32) default NULL,
facility varchar(10) default NULL,
priority varchar(10) default NULL,
level varchar(10) default NULL,
tag varchar(10) default NULL,
date date default NULL,
time time default NULL,
program varchar(15) default NULL,
msg text,
seq int(10) unsigned NOT NULL auto_increment,
PRIMARY KEY (seq),
KEY host (host),
KEY seq (seq),
KEY program (program),
KEY time (time),
KEY date (date),
KEY priority (priority),
KEY facility (facility)
) TYPE=MyISAM;
```

Configure Syslog-ng:

```text
source net { udp(); };

destination d_mysql {
pipe("/var/log/mysql.pipe"
template("INSERT INTO logs
(host, facility, priority, level, tag, date, time, program, msg)
VALUES ( '$HOST', '$FACILITY', '$PRIORITY', '$LEVEL', '$TAG', '$YEAR-$MONTH-$DAY', '$HOUR:$MIN:$SEC',
'$PROGRAM', '$MSG');\n") template-escape(yes));
};

log {
source(net);
destination(d_mysql);
};
```

Configure this script to run (There are a few different ways to do it, just make sure it's running all the time):

```bash
#!/bin/bash

if [ ! -e /var/log/mysql.pipe ]
then
mkfifo /var/log/mysql.pipe
fi
while [ -e /var/log/mysql.pipe ]
do
mysql -u root --password=iw2slep! syslog < /var/log/mysql.pipe >/dev/null
done
```

Now, configure your network equipment to send syslog to your linux machine:

```text
logging <ip-address>
```

I've also written a simple PHP script to display the syslog info in a table. No real filtering or sorting. I would just teak the SQL query if I wanted to see something differnet. It would be nice to have all the sorting and filtering built into the page, but I'm just not that good with PHP yet.

This is an example that I will work off of for the next project:

```php
<html>
<body>
<?php
$username="username";
$password="password";
$database="your_database";

mysql_connect(localhost,$username,$password);
@mysql_select_db($database) or die( "Unable to select database");
$query="SELECT * FROM tablename";
$result=mysql_query($query);

$num=mysql_numrows($result);

mysql_close();
?>
<table border="0" cellspacing="2" cellpadding="2">
<tr>
<th><font face="Arial, Helvetica, sans-serif">Value1</font></th>
<th><font face="Arial, Helvetica, sans-serif">Value2</font></th>
<th><font face="Arial, Helvetica, sans-serif">Value3</font></th>
<th><font face="Arial, Helvetica, sans-serif">Value4</font></th>
<th><font face="Arial, Helvetica, sans-serif">Value5</font></th>
</tr>

<?php
$i=0;
while ($i < $num) {

$f1=mysql_result($result,$i,"field1");
$f2=mysql_result($result,$i,"field2");
$f3=mysql_result($result,$i,"field3");
$f4=mysql_result($result,$i,"field4");
$f5=mysql_result($result,$i,"field5");
?>

<tr>
<td><font face="Arial, Helvetica, sans-serif"><?php echo $f1; ?></font></td>
<td><font face="Arial, Helvetica, sans-serif"><?php echo $f2; ?></font></td>
<td><font face="Arial, Helvetica, sans-serif"><?php echo $f3; ?></font></td>
<td><font face="Arial, Helvetica, sans-serif"><?php echo $f4; ?></font></td>
<td><font face="Arial, Helvetica, sans-serif"><?php echo $f5; ?></font></td>
</tr>

<?php
$i++;
}
?>
</body>
</html>
```
