#!/bin/bash
current_wifi=$(ipconfig getsummary en0 | awk -F ' SSID : ' '/ SSID : / {print $2}')
current_location=$(networksetup -getcurrentlocation)
current_file_name=$(basename "$0" .sh)
log_file="/Users/$(whoami)/.zsh/logs/$current_file_name.log" 
echo "\nCurrent WiFi: $current_wifi" >> "$log_file"
if [[ "$current_wifi" == *"LPU"* ]]; then
    if [[ "$current_location" != "College" ]]; then
        networksetup -switchtolocation College
        echo "\nSwitched location to College" >> "$log_file"
    fi
else
    if [[ "$current_location" != "Automatic" ]]; then
        networksetup -switchtolocation Automatic
        echo "\nSwitched location to Automatic" >> "$log_file"
    fi
fi