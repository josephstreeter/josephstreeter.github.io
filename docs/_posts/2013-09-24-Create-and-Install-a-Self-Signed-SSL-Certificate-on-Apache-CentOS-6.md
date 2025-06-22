---
title:  Create and Install a Self-Signed SSL Certificate on Apache/CentOS 6
date:   2013-09-24 00:00:00 -0500
categories: IT
---

SSL is a great way to protect traffic to your website. These are the steps to create a self-signed certificate and install it on an apache web server. It is self-signed, so the user's browser will throw an error because it doesn't trust the certificate. It's a start though....

Install Mod SSL

```bash
yum install mod_ssl
```

Create a directory for the new certificate and key

```bash
mkdir /etc/httpd/ssl
```

Create the certificate

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/httpd/ssl/apache.key -out /etc/httpd/ssl/apache.crt
```

Enter the appropriate information when promptted

```text
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:WI
Locality Name (eg, city) []:Madison
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Test Co
Organizational Unit Name (eg, section) []:Test
Common Name (e.g. server FQDN or YOUR name) []:server.domain.tld
Email Address []:first.last@domain.tld
```

Configure Apache to use the new certificate

```powershell
vi /etc/httpd/conf.d/ssl.conf

DocumentRoot /var/www/html  # Uncomment
ServerName example.com:443  # Uncomment and replace "example.com" with your domain name

SSLEngine on  # Set to "on"
SSLCertificateFile /etc/httpd/ssl/apache.crt   # Edit path
SSLCertificateKeyFile /etc/httpd/ssl/apache.key  # Edit path
```

Restart Apache

```powershell
service httpd restart
```


