#!/usr/bin/env bash
# dynamic_dns_service.sh - WiFi detection and DNS management service
# This script now uses modular components for better maintainability

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="/Users/$(whoami)/.ezsh/functions/mac"

# Load configuration from .config file
CONFIG_FILE="/Users/$(whoami)/.ezsh/.config"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Load environment variables from .env
ENV_FILE="/Users/$(whoami)/.ezsh/.env"
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# Check if this service is enabled
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
if [[ ! "${ENABLED_SERVICES}" =~ (^|,)${SCRIPT_NAME}(,|$) ]]; then
    # Service is not in the enabled list, exit silently
    exit 0
fi

# Source required modules
source "$FUNCTIONS_DIR/wifiname.sh"
source "$FUNCTIONS_DIR/dynamic_dns.sh"

# Configuration (use environment variables or defaults)
export DNS_SERVER_ADDRESS="${DNS_SERVER_ADDRESS:-8.8.8.8}"
export LOG_DIR="/Users/$(whoami)/.ezsh/logs"
export LOG_FILE="$LOG_DIR/dynamic_dns.log"
export VERBOSE_LOGGING=true

# Arrays of Wi-Fi names to check (exact match and substring match)
# Can be overridden by environment variables
IFS=',' read -ra WIFI_NAMES_EXACT <<< "${WIFI_NAMES_EXACT:-}"
IFS=',' read -ra WIFI_NAMES_SUBSTRING <<< "${WIFI_NAMES_SUBSTRING:-}"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Get current Wi-Fi name
current_wifi=$(wifiname)

# Log the current Wi-Fi
__dns_log "Current WiFi: $current_wifi"

# Variables for matching
wifi_matched=false
match_type=""
matched_entry=""

# Check for exact match
if _wifi_matches_exact "$current_wifi" "${WIFI_NAMES_EXACT[@]}"; then
    wifi_matched=true
    match_type="exact"
    __dns_log "Exact match found in the WIFI_NAMES_EXACT array!"
fi

# Check for substring match (if no exact match)
if [[ "$wifi_matched" == "false" ]] && _wifi_matches_substring "$current_wifi" "${WIFI_NAMES_SUBSTRING[@]}"; then
    wifi_matched=true
    match_type="substring"
    __dns_log "Substring match found in the WIFI_NAMES_SUBSTRING array!"
fi

if [[ "$wifi_matched" == "false" ]]; then
    __dns_log "No match found"
fi

# Manage DNS based on WiFi match
dnsmanage "Wi-Fi" "$wifi_matched" "$DNS_SERVER_ADDRESS"
