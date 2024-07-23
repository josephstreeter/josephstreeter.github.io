---
layout: post
title:  Cacti Backup
date:   2012-10-18 00:00:00 -0500
categories: IT
---






Here is a Cacti backup script that I found the book "Cacti 0.8 Beginner's Guide." It's really handy if you've gone through all the trouble to install and configure the PA.

It seems to work, but I haven't done a restore yet.
{% highlight powershell %}#!/bin/bash#Set Variables
DATE=`date +%Y%m%d`
FILENAME="cacti_database_$DATE.sql";
BACKUPDIR="/backup/";
TGZFILENAME="cacti_files_$DATE.tgz";
DBUSER="<dbuser>";
DBPWD="<dbpassword>";
DBNAME="cacti";
GZIP="/bin/gzip -f";

cd /

#Remove files older than 3 days
find /backup/cacti_*gz -mtime +3 -exec rm {} \;

#Backup Cacti Database
mysqldump --user=$DBUSER --password=$DBPWD --add-drop-table --databases $DBNAME > $BACKUPDIR$FILENAME
$GZIP $BACKUPDIR$FILENAME

#Backup Important Files
tar -csvpf $BACKUPDIR$TGZFILENAME ./etc/cron.d/cacti ./etc/php5/apache2/php.ini ./etc/apache2/sites-available/default ./usr/share/cacti

{% endhighlight %}
Additional files or directories can be added to the backup by entering them as arguments to the final line on the script separated by a space.

Schedule the script to run daily at 2:00am by creating "/etc/cron.d/cactibackup" with the following lines:
{% highlight powershell %}

# Cacti backup Schedule
0 2 * * * root /bin/bash /backup/backupcacti.sh > /dev/null 2>&amp;1

{% endhighlight %}


