# Software Defined Radio

Software Defined Radio using RTL-SDR dongle on Ubuntu Linux

[More information](https://ranous.files.wordpress.com/2016/03/rtl-sdr4linux_quickstartv10-16.pdf)

## RRL-SDR

A package for Ubuntu: [[https://launchpad.net/ubuntu/bionic/+...](https://launchpad.net/ubuntu/bionic/+package/rtl-sdr)]

```bash
sudo apt install -y rtl-sdr
sudo apt install -y sox
sudo apt install -y multimon-ng
```

## RTL_FM

A cli demodulation tool:
<http://kmkeen.com/rtl-demod-guide/>
<http://main.lv/writeup/rtlsdr_usage.md>

Tune in FM Broadcast

```bash
rtl_fm -M wbfm -f 89.1M | play -r 32k -t raw -e s -b 16 -c 1 -V1 -
```

'-f ...' indicated the frequency to tune to
-M fm means narrowband FM
-s 170k means to sample the radio at 170k/sec
-A fast uses a fast polynominal approximation of arctangent
-r 32k means to lowpass/resample at 32kHz
-l 0 disables squelch
-E deemp applies a deemphesis filter

Police Scanner

```bash
rtl_fm -M fm -f 154.42M -f 154.75M -f 154.82M -f 154.89M -s 12k -g 50 -l 70 | play -r 12k ...
```

-M fm narrowband FM
-f ... frequency to tune, use multiple times for scanning
-s 12k sample rate, about as narrow as possible for FM voice
-g 50 set gain to maximum (use a value appropriate to your dongle)
-l 70 set squelch to 70. The exact values varies a lot. Changing the gain or sample rate will require a change in the squelch to compensate.

Scan Airband

```bash
rtl_fm -M am -f 118M:137M:25k -s 12k -g 50 -l 280 | play -r 12k ...
```

-M am AM demodulation
-f start:stop:interval a range of frequencies to scan
-s 12k same as above
-g 50 same as above
-l 280 squelch level, exact value varies a lot

Pager Decoder

```bash
rtl_fm -M fm -f 929.77M -s 22050 -g 10 -l 250 | multimon -t raw /dev/stdin
```

Scan for signals

```bash
rtl_power -f 76M:108M:125k -i 1 fm_stations.csv
```

## GQRX

graphical spectrum analyzer: <http://http://gqrx.dk>
To install:

```bash
sudo apt-get install gqrx-sdr
```

## ACARS DECODER

A realtime aircraft message decoding: <https://github.com/TLeconte/acarsdec>
Check ACARS frequency here: <https://www.acarsd.org/ACARS_frequencies.html>

## DUMP1090

ADS-B airplane messages DECODER: <https://github.com/antirez/dump1090> / <https://www.ads-binfo.com/>

## RTL_433

Decoding Low Power devices on unlicensed bands 433MHz/315 MHz/ 868MHz / 915MHz - like keyfobs, meteo/weather stations, sensors sniffer: <https://github.com/merbanan/rtl_433>

```bash
sudo apt-get install rtl-433
```

## MULTIMON-NG

A multi system DECODER: <https://github.com/EliasOenal/multimon-ng>
APRS (Automatic Packet Reporting System) decoding video using MULTIMON-NG  here [https://www.youtube.com/watch?v=Cfnrr...](https://www.youtube.com/watch?v=CfnrrJwwNU8&t=4s)

CAPTURING & DECODING SATELLITES with NOAA-APT with simple dipole antenna  - see my other video here : [https://www.youtube.com/watch?v=Fk0WU...](https://www.youtube.com/watch?v=Fk0WUWd73O8&t=218s)

## UBUNTU 18.04 and RTL-SDR Dongle Setup

RTLSDR installation on Ubuntu:

Check if USB RTLSDR is detected and what are Product_ID and Vendor_ID (f.ex. idVendor=0bda, idProduct=2832 )

```bash
lsusb

Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 005: ID 8087:0a2b Intel Corp. Bluetooth wireless interface
Bus 001 Device 004: ID 18f8:0f99 [Maxxter] Optical gaming mouse
Bus 001 Device 003: ID 413c:2003 Dell Computer Corp. Keyboard SK-8115
Bus 001 Device 008: ID 0bda:2838 Realtek Semiconductor Corp. RTL2838 DVB-T  <---
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub

```

Blacklist ordinary DVB-T drivers in Linux Kernel not to interfere with rtlsdr library

```bash
vi /etc/modprobe.d/blacklist.conf
```

add in this file  following lines (add line respectively to ProductID value) :

```bash
blacklist dvb_usb_rtl28xxu 
blacklist rtl2832 
blacklist rtl2830
```

Restart Computer

Install the RTL-SDR package: [https://launchpad.net/ubuntu/bionic/+...](https://launchpad.net/ubuntu/bionic/+package/rtl-sdr)

```bash
sudo apt-get install rtl-sdr
```
