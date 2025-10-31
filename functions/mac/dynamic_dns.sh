#!/usr/bin/env bash
# dynamic_dns.sh - Manage DNS settings based on WiFi network

# Helper: log messages
function __dns_log() {
    local LOG_DIR="${LOG_DIR:-/Users/$(whoami)/.ezsh/logs}"
    local LOG_FILE="${LOG_FILE:-$LOG_DIR/dynamic_dns.log}"
    local VERBOSE_LOGGING="${VERBOSE_LOGGING:-true}"
    
    if [ "$VERBOSE_LOGGING" = true ]; then
        mkdir -p "$LOG_DIR"
        echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
    fi
}

# Helper: get current DNS servers
function __dns_get() {
    local interface="${1:-Wi-Fi}"
    networksetup -getdnsservers "$interface"
}

# Helper: set DNS servers
function __dns_set() {
    local interface="${1:-Wi-Fi}"
    shift
    local dns_servers=("$@")
    
    if [[ ${#dns_servers[@]} -eq 0 ]]; then
        # Set to empty (use DHCP)
        networksetup -setdnsservers "$interface" empty
        __dns_log "DNS servers cleared for $interface (using DHCP)"
    else
        networksetup -setdnsservers "$interface" "${dns_servers[@]}"
        __dns_log "DNS servers set to ${dns_servers[*]} for $interface"
    fi
}

# Helper: check if DNS is already set to specific server
function __dns_already_set() {
    local interface="${1:-Wi-Fi}"
    local target_dns="$2"
    local current_dns
    
    current_dns=$(__dns_get "$interface")
    
    if [[ "$current_dns" == *"$target_dns"* ]]; then
        return 0
    fi
    return 1
}

# Helper: check if DNS is empty (using DHCP)
function __dns_is_empty() {
    local interface="${1:-Wi-Fi}"
    local current_dns
    
    current_dns=$(__dns_get "$interface")
    
    if [[ "$current_dns" == *"empty"* ]] || [[ "$current_dns" == *"aren't any"* ]]; then
        return 0
    fi
    return 1
}

# Primary function to manage DNS based on WiFi match
function dnsmanage() {
    local interface="${1:-Wi-Fi}"
    local wifi_matched="${2:-false}"
    local dns_server="${3:-${DNS_SERVER_ADDRESS:-8.8.8.8}}"
    
    __dns_log "Managing DNS for $interface (matched: $wifi_matched)"
    
    if [[ "$wifi_matched" == "true" ]]; then
        # WiFi is in the list, set to specific DNS
        if __dns_already_set "$interface" "$dns_server"; then
            __dns_log "DNS server already set to $dns_server"
            return 0
        fi
        __dns_set "$interface" "$dns_server"
        __dns_log "DNS server changed to $dns_server"
    else
        # WiFi not in the list, clear DNS (use DHCP)
        if __dns_is_empty "$interface"; then
            __dns_log "DNS already set to empty (DHCP)"
            return 0
        fi
        __dns_set "$interface"
        __dns_log "DNS cleared, using DHCP"
    fi
}
