#!/usr/bin/env bash
# lpu_auto_login.sh - Auto-login service for LPU captive portal
# Monitors WiFi connection and automatically logs in when on LPU network

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="/Users/$(whoami)/.ezsh/functions/mac"
LOG_DIR="/Users/$(whoami)/.ezsh/logs"
LOG_FILE="$LOG_DIR/lpu_auto_login.log"
VERBOSE_LOGGING=true

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
source "$FUNCTIONS_DIR/lpu_captive_login.sh"

# LPU WiFi network names to monitor (can be overridden by environment)
IFS=',' read -ra LPU_WIFI_NAMES_EXACT <<< "${LPU_WIFI_NAMES_EXACT:-LPU}"
IFS=',' read -ra LPU_WIFI_NAMES_SUBSTRING <<< "${LPU_WIFI_NAMES_SUBSTRING:-LPU,lpu}"

# Function to log messages
log() {
    if [ "$VERBOSE_LOGGING" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
    fi
}

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Main logic
main() {
    log "=== LPU Auto-Login Service Started ==="
    
    # Get current WiFi name
    current_wifi=$(wifiname)
    log "Current WiFi: $current_wifi"
    
    # Check if we're on LPU network
    is_lpu_network=false
    
    if _wifi_matches_exact "$current_wifi" "${LPU_WIFI_NAMES_EXACT[@]}"; then
        is_lpu_network=true
        log "Exact match: Connected to LPU network"
    elif _wifi_matches_substring "$current_wifi" "${LPU_WIFI_NAMES_SUBSTRING[@]}"; then
        is_lpu_network=true
        log "Substring match: Connected to LPU network"
    fi
    
    if [[ "$is_lpu_network" == "false" ]]; then
        log "Not on LPU network, skipping login"
        return 0
    fi
    
    # Check current connection status
    log "Checking connection status..."
    if lpu status >/dev/null 2>&1; then
        log "Already online, no action needed"
        return 0
    fi
    
    # We're on LPU network but behind captive portal, try to login
    log "Captive portal detected, attempting login..."
    if lpu login; then
        log "Login successful"
        
        # Verify login worked
        sleep 2
        if lpu status >/dev/null 2>&1; then
            log "Connection verified: Online"
        else
            log "WARNING: Login sent but connection still captive"
        fi
    else
        log "ERROR: Login failed"
        return 1
    fi
    
    log "=== LPU Auto-Login Service Completed ==="
}

# Run main function
main
