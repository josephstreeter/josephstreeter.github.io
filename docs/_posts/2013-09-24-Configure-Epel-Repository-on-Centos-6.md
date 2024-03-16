---
layout: post
title:  Install Wordpress on CentOS 6
date:   2013-09-24 00:00:00 -0500
categories: IT
---






Steps to install Wordpress on a CentOS host using RPMs the easy way instead of installing- from source.

Configure Epel repository
Click <a title="Configure Epel Repository on Centos 6" href="http://www.joseph-streeter.com/?p=763" target="_blank">Here</a>



Configure LAMP by installing Apache, MySQL, and PHP
{% highlight powershell %}yum install httpd mysql-server php wordpress{% endhighlight %}
Log in to MySQL
{% highlight powershell %}mysql -u root -p{% endhighlight %}
Create the database
{% highlight powershell %}CREATE DATABASE wordpress;
Query OK, 1 row affected (0.00 sec)
Query OK, 0 rows affected (0.00 sec){% endhighlight %}
Create the wordpress user and set a password
{% highlight powershell %}CREATE USER wordpress@localhost;
Query OK, 0 rows affected (0.00 sec)

SET PASSWORD FOR wordpressuser@localhost= PASSWORD("password");
Query OK, 0 rows affected (0.00 sec){% endhighlight %}
Grant the wordpress user rights to the database
{% highlight powershell %}GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost IDENTIFIED BY 'password';
Query OK, 0 rows affected (0.00 sec)

FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec){% endhighlight %}
Configure Wordpress
{% highlight powershell %}vi /usr/share/wordpress/wp-config.php

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'wordpress');

/** MySQL database password */
define('DB_PASSWORD', 'password');{% endhighlight %}
Restart Apache
{% highlight powershell %}service httpd restart{% endhighlight %}


