#!/usr/bin/env bash
# wifiname.sh - Get current WiFi network name (SSID)

# Function to get current WiFi name
get_wifi_name() {
    local wifi_name
    # Try ipconfig method first (faster)
    wifi_name=$(ipconfig getsummary en0 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2}')
    
    # Fallback to networksetup if ipconfig fails
    if [[ -z "$wifi_name" ]]; then
        wifi_name=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk '/ SSID/ {print $2}')
    fi
    
    echo "$wifi_name"
}

# Function to check if WiFi matches exact name
wifi_matches_exact() {
    local current_wifi="$1"
    shift
    local wifi_names=("$@")
    
    for wifi in "${wifi_names[@]}"; do
        if [[ "$current_wifi" == "$wifi" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if WiFi matches substring
wifi_matches_substring() {
    local current_wifi="$1"
    shift
    local wifi_names=("$@")
    
    for wifi in "${wifi_names[@]}"; do
        if echo "$current_wifi" | grep -qF "$wifi"; then
            return 0
        fi
    done
    return 1
}

# If script is executed directly (not sourced), print the WiFi name
# Check if we're being sourced or executed
(return 0 2>/dev/null) && _SOURCED=1 || _SOURCED=0

if [[ $_SOURCED -eq 0 ]]; then
    get_wifi_name
fi

unset _SOURCED
