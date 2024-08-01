---
title:  Asterisk - IAX2 Trunks and Using Google Talk and Google Voice
date:   2012-10-19 00:00:00 -0500
categories: IT
---

Another adventure with installing and configuring Asterisk to work with Cisco Callmanager Express, other Asterisk boxes, and Google Talk/Voice.

Here is a good start to installing on a Debian box:

```bash
apt-get install vim make gcc libc-dev build-essential linux-headers-$(uname -r) cvs libssl-dev zlib1g-dev libnewt-dev bison ncurses-dev libssl-dev libnewt-dev zlib1g-dev procps libiksemel3 libxml2-dev
```

Now, create a folder to store all the source files

```bash
mkdir /usr/src/asterisk
```

Then download the source files for libpri, dahdi (formally zaptel), and Asterisk.

```bash
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-1.4-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux/dahdi-linux-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-1.8-current.tar.gz
```

Uncompress the source files

```bash
tar zxvf libpri-1.4-current.tar.gz
tar zxvf dahdi-linux-current.tar.gz
tar zxvf asterisk-1.8-current.tar.gz
```

Then the usual commands

```bash
./configure
make clean
make menuselect
make install
```

Links:

- <a href="https://wiki.asterisk.org/wiki/display/AST/Calling+using+Google">Calling using Google - Asterisk Wiki</a>
- <a href="http://www.personal.psu.edu/wcs131/blogs/psuvoip/2010/11/asterisk_18_freepbx_28_and_goo.html">Asterisk 1.8, FreePBX 2.8, and Google Voice on a Cloudy Day</a>
- <a href="http://letitknow.wordpress.com/2011/05/16/how-to-install-asterisk-1-8-4-on-debian-6-0-1/">How to install Asterisk 1.8.4 on Debian 6.0.1 - Let IT Know</a>
- <a href="http://michigantelephone.wordpress.com/2010/12/21/how-to-use-google-voice-for-free-calls-on-an-asterisk-1-8freepbx-2-8-system-the-easy-way/">How to use Google Voice for free calls on an Asterisk 1.8+/FreePBX 2.8 system (the easy way) - The Michigan Telephone blog</a>
