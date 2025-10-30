#!/usr/bin/env bash
# dynamic_dns.sh - Manage DNS settings based on WiFi network

# Default DNS server address (can be overridden by environment)
DNS_SERVER_ADDRESS="${DNS_SERVER_ADDRESS:-8.8.8.8}"
LOG_DIR="${LOG_DIR:-/Users/$(whoami)/.ezsh/logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/dynamic_dns.log}"
VERBOSE_LOGGING="${VERBOSE_LOGGING:-true}"

# Function to log messages
log() {
    if [ "$VERBOSE_LOGGING" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
    fi
}

# Function to get current DNS servers
get_current_dns() {
    local interface="${1:-Wi-Fi}"
    networksetup -getdnsservers "$interface"
}

# Function to set DNS servers
set_dns_servers() {
    local interface="${1:-Wi-Fi}"
    shift
    local dns_servers=("$@")
    
    if [[ ${#dns_servers[@]} -eq 0 ]]; then
        # Set to empty (use DHCP)
        networksetup -setdnsservers "$interface" empty
        log "DNS servers cleared for $interface (using DHCP)"
    else
        networksetup -setdnsservers "$interface" "${dns_servers[@]}"
        log "DNS servers set to ${dns_servers[*]} for $interface"
    fi
}

# Function to check if DNS is already set to specific server
dns_already_set() {
    local interface="${1:-Wi-Fi}"
    local target_dns="$2"
    local current_dns
    
    current_dns=$(get_current_dns "$interface")
    
    if [[ "$current_dns" == *"$target_dns"* ]]; then
        return 0
    fi
    return 1
}

# Function to check if DNS is empty (using DHCP)
dns_is_empty() {
    local interface="${1:-Wi-Fi}"
    local current_dns
    
    current_dns=$(get_current_dns "$interface")
    
    if [[ "$current_dns" == *"empty"* ]] || [[ "$current_dns" == *"aren't any"* ]]; then
        return 0
    fi
    return 1
}

# Main function to manage DNS based on WiFi match
manage_dns() {
    local interface="${1:-Wi-Fi}"
    local wifi_matched="${2:-false}"
    local dns_server="${3:-$DNS_SERVER_ADDRESS}"
    
    log "Managing DNS for $interface (matched: $wifi_matched)"
    
    if [[ "$wifi_matched" == "true" ]]; then
        # WiFi is in the list, set to specific DNS
        if dns_already_set "$interface" "$dns_server"; then
            log "DNS server already set to $dns_server"
            return 0
        fi
        set_dns_servers "$interface" "$dns_server"
        log "DNS server changed to $dns_server"
    else
        # WiFi not in the list, clear DNS (use DHCP)
        if dns_is_empty "$interface"; then
            log "DNS already set to empty (DHCP)"
            return 0
        fi
        set_dns_servers "$interface"
        log "DNS cleared, using DHCP"
    fi
}

# If script is executed directly (not sourced)
# Check if we're being sourced or executed
(return 0 2>/dev/null) && _SOURCED=1 || _SOURCED=0

if [[ $_SOURCED -eq 0 ]]; then
    # Source wifiname.sh if available
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [[ -f "$SCRIPT_DIR/wifiname.sh" ]]; then
        source "$SCRIPT_DIR/wifiname.sh"
    fi
    
    # Arrays of Wi-Fi names to check (exact match and substring match)
    WIFI_NAMES_EXACT=("")
    WIFI_NAMES_SUBSTRING=("")
    
    # Get current WiFi
    current_wifi=$(get_wifi_name)
    log "Current WiFi: $current_wifi"
    
    # Check for matches
    wifi_matched=false
    match_type=""
    matched_entry=""
    
    if wifi_matches_exact "$current_wifi" "${WIFI_NAMES_EXACT[@]}"; then
        wifi_matched=true
        match_type="exact"
        log "Exact match found in WIFI_NAMES_EXACT array"
    elif wifi_matches_substring "$current_wifi" "${WIFI_NAMES_SUBSTRING[@]}"; then
        wifi_matched=true
        match_type="substring"
        log "Substring match found in WIFI_NAMES_SUBSTRING array"
    else
        log "No match found"
    fi
    
    # Manage DNS based on match
    manage_dns "Wi-Fi" "$wifi_matched" "$DNS_SERVER_ADDRESS"
fi

unset _SOURCED
