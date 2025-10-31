#!/usr/bin/env bash
# wifiname.sh - Get current WiFi network name (SSID)

# Primary function to get current WiFi name
function wifiname() {
    local wifi_name
    # Try ipconfig method first (faster)
    wifi_name=$(ipconfig getsummary en0 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2}')
    
    # Fallback to networksetup if ipconfig fails
    if [[ -z "$wifi_name" ]]; then
        wifi_name=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk '/ SSID/ {print $2}')
    fi
    
    echo "$wifi_name"
}

# Helper: check if WiFi matches exact name
function _wifi_matches_exact() {
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

# Helper: check if WiFi matches substring
function _wifi_matches_substring() {
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
