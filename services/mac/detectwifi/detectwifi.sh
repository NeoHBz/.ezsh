# Constants
DNS_SERVER_ADDRESS="141.148.194.201"
LOG_DIR="/Users/$(whoami)/.zsh/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"
VERBOSE_LOGGING=true

# Arrays of Wi-Fi names to check (exact match and substring match)
WIFI_NAMES_EXACT=("NULL")
WIFI_NAMES_SUBSTRING=("RED_APPEL_LIVING")

# Function to log messages
log() {
    if [ "$VERBOSE_LOGGING" = true ]; then
        echo "$(date) $1" >> "$LOG_FILE"
    fi
}

# Get current Wi-Fi name
current_wifi=$(ipconfig getsummary en0 | awk -F ' SSID : ' '/ SSID : / {print $2}')

# Log the current Wi-Fi and DNS
log "Current WiFi: $current_wifi"

# Variables for matching
exact_match=false
substring_match=false
match_type=""
matched_entry=""

# Check for exact match in the Wi-Fi names
for wifi in "${WIFI_NAMES_EXACT[@]}"; do
    if [[ "$current_wifi" == "$wifi" ]]; then
        exact_match=true
        match_type="exact"
        matched_entry="$wifi"
        break
    fi
done

# Check for substring match in the Wi-Fi names
for wifi in "${WIFI_NAMES_SUBSTRING[@]}"; do
    if echo "$current_wifi" | grep -qF "$wifi"; then
        substring_match=true
        match_type="substring"
        matched_entry="$wifi"
        break
    fi
done

# Log the match type and entry
if $exact_match; then
    log "Exact match found in the WIFI_NAMES_EXACT array!"
    log "Match type: $match_type"
    log "Match array entry: $matched_entry"
elif $substring_match; then
    log "Substring match found in the WIFI_NAMES_SUBSTRING array!"
    log "Match type: $match_type"
    log "Match array entry: $matched_entry"
else
    log "No match found"
fi

# Get current DNS configuration
current_dns=$(networksetup -getdnsservers Wi-Fi)
log "Current DNS: $current_dns"

# Main logic to handle DNS settings based on Wi-Fi match
if $exact_match || $substring_match; then
    # If the Wi-Fi is in the list, check DNS and set accordingly
    if [[ "$current_dns" == *"$DNS_SERVER_ADDRESS"* ]]; then
        log "DNS server already set to $DNS_SERVER_ADDRESS\n"
        exit 0
    fi
    networksetup -setdnsservers Wi-Fi "$DNS_SERVER_ADDRESS"
    log "DNS server set to $DNS_SERVER_ADDRESS\n"
else
    # If Wi-Fi is not in the list, set DNS to empty
    if [[ "$current_dns" == *"empty"* ]]; then
        log "DNS server already set to empty\n"
        exit 0
    fi
    networksetup -setdnsservers Wi-Fi empty
    log "DNS server set to empty\n"
fi
