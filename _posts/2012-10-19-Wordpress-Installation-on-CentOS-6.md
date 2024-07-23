---
layout: post
title:  Wordpress Installation on CentOS 6
date:   2012-10-19 00:00:00 -0500
categories: IT
---






It's time to move on from the old Debian host that this blog is running on. Since I've decided that it is also time to move from Debian to CentOS for my Linux OS of choice. Now that I work in a place that has a Linux team that uses RHEL I figure it would be a good idea to make the change.

Since it doesn't look like it's going to be an easy migration for my blog, I decided that it's time to look at something other than Drupal. The whole reason I'm doing all of this anyways is to learn, so, it is time to experience another CMS product. That new product will be Wordpress.

To install Wordpress on CentOS 6:

Install the Wordpress and MySQL RPMs
yum install wordpress mysql-server
(Assuming that you already have the epel repository enabled.)

***Configure MySQL***
service mysqld start
chkconfig mysqld --level 3 on
/usr/bin/mysql_secure_installation (answer questions)

***Configure the Wordpress database in MySQL***
mysql -u root -p
mysql> create database wordpress;
mysql> grant all privileges on wordpress.* to wordpress@'localhost' identified by 'yourpassword';
mysql> flush privileges;

***Edit Wordpress configuration file***
cp /etc/wordpress/wp-config.php /etc/wordpress/wp-config.php.bk
vi /etc/wordpress/wp-config.php

Change the following lines (19, 22, and 25) to reflect the proper database, username, and password that you've configured:

define('DB_NAME', 'wordpress');
define('DB_USER', 'username');
define('DB_PASSWORD', 'yourpassword');

***Complete Wordpress configuration***
Start (or restart) the Apache service
service httpd restart

Navigate to http:///wordpress/ with a browser and complete the form.

***Done!***
Click login
Enter credentials
Begin blogging


