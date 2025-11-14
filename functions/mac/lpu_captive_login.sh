#!/usr/bin/env bash
# lpu_captive_login.sh — login to LPU captive portal
# Primary function: lpu (login by default, accepts logout/status as args)
# Credentials: Set LPU_USERNAME and LPU_PASSWORD in ~/.ezsh/.env
# Example:
#   LPU_USERNAME="123456@lpu.com"
#   LPU_PASSWORD="your_password"

# Global configuration variables
# Set LPU_VERBOSE=true/1 to enable verbose debug output
LPU_VERBOSE="${LPU_VERBOSE:-false}"
# Set LPU_OUTPUT_PASSWORD=true/1 to show password in verbose logs (INSECURE!)
LPU_OUTPUT_PASSWORD="${LPU_OUTPUT_PASSWORD:-false}"

# Helper: normalize boolean values
function __lpu_is_true() {
  local val="$1"
  [[ "$val" == "true" || "$val" == "1" || "$val" == "yes" || "$val" == "TRUE" || "$val" == "YES" ]]
}

# Helper: debug logging function
function __lpu_debug() {
  if __lpu_is_true "$LPU_VERBOSE"; then
    echo "[DEBUG] $*" >&2
  fi
}

# Helper: url-encode using python3 (fallback to raw if python3 missing)
function __lpu_urlenc() {
  local s="${1:-}"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$s"
  else
    printf '%s' "$s" | sed \
      -e 's/ /%20/g' \
      -e 's/@/%40/g' \
      -e 's/:/%3A/g' \
      -e 's/\//%2F/g'
  fi
}

# Helper: login function
function _lpu_login() {
  local COOKIEJAR="${HOME}/.neoscripts/.lpu_cookies_lpu.txt"
  local URL="${LPU_PORTAL_URL:-https://internet.lpu.in/24online/servlet/E24onlineHTTPClient}"
  local REFERER="${LPU_PORTAL_REFERER:-https://internet.lpu.in/24online/webpages/client.jsp}"
  local ORIGIN="${LPU_PORTAL_ORIGIN:-https://internet.lpu.in}"
  local LPU_SERVER="${LPU_SERVER:-172.20.0.66}"
  
  __lpu_debug "Starting LPU login process..."
  __lpu_debug "URL: $URL"
  __lpu_debug "Referer: $REFERER"
  __lpu_debug "Origin: $ORIGIN"
  __lpu_debug "Server: $LPU_SERVER"
  
  # Quick captive check: if generate_204 returns 204, we have internet
  __lpu_debug "Checking captive portal status..."
  if curl -s --max-time 5 -I http://clients3.google.com/generate_204 | grep -q "HTTP/.* 204"; then
    echo "Already online (no captive portal)."
    return 0
  fi
  __lpu_debug "Captive portal detected, proceeding with login..."

  # Detect wifi device, mac and ip (macOS)
  __lpu_debug "Detecting network interface..."
  local WIFI_DEV="$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort/{getline; print $2; exit}')"
  if [[ -z "$WIFI_DEV" ]]; then
    WIFI_DEV="en0"
  fi
  __lpu_debug "WiFi device: $WIFI_DEV"

  local MAC="$(ifconfig "$WIFI_DEV" 2>/dev/null | awk '/ether/ {print $2}' || true)"
  local IP="$(ipconfig getifaddr "$WIFI_DEV" 2>/dev/null || true)"
  __lpu_debug "MAC address: $MAC"
  __lpu_debug "IP address: $IP"

  # Load credentials from environment variables
  __lpu_debug "Loading credentials from environment (LPU_USERNAME, LPU_PASSWORD)"
  
  if [[ -z "$LPU_USERNAME" ]] || [[ -z "$LPU_PASSWORD" ]]; then
    echo "LPU_USERNAME or LPU_PASSWORD not set in environment" >&2
    echo "Please set them in ~/.ezsh/.env" >&2
    return 2
  fi

  # Always log username (non-verbose)
  echo "Logging in with username: $LPU_USERNAME"
  
  # Optionally log password (verbose only, INSECURE!)
  if __lpu_is_true "$LPU_OUTPUT_PASSWORD"; then
    __lpu_debug "Password: $LPU_PASSWORD"
  else
    __lpu_debug "Password: [hidden - set LPU_OUTPUT_PASSWORD=true to show]"
  fi

  local mac_e ip_e user_e pass_e data
  mac_e="$(__lpu_urlenc "${MAC:-}")"
  ip_e="$(__lpu_urlenc "${IP:-}")"
  user_e="$(__lpu_urlenc "$LPU_USERNAME")"
  pass_e="$(__lpu_urlenc "$LPU_PASSWORD")"

  __lpu_debug "URL-encoded MAC: $mac_e"
  __lpu_debug "URL-encoded IP: $ip_e"
  __lpu_debug "URL-encoded username: $user_e"
  if __lpu_is_true "$LPU_OUTPUT_PASSWORD"; then
    __lpu_debug "URL-encoded password: $pass_e"
  fi

  data="mode=191&isAccessDenied=null&url=null&message=&regusingpinid=&checkClose=1&sessionTimeout=0&guestmsgreq=false&logintype=2&orgSessionTimeout=0&chrome=-1&alerttime=null&timeout=0&popupalert=0&dtold=0&mac=${mac_e}&servername=${LPU_SERVER}&macaddress=${mac_e}&ipaddress=${ip_e}&username=${user_e}&password=${pass_e}&loginotp=false&logincaptcha=false&registeruserotp=false&registercaptcha=false"

  __lpu_debug "POST data prepared (length: ${#data} bytes)"
  if __lpu_is_true "$LPU_OUTPUT_PASSWORD"; then
    __lpu_debug "Full POST data: $data"
  fi

  # Capture response for analysis
  local TMPFILE="/tmp/lpu_login_response_$$.html"
  __lpu_debug "Cookie jar: $COOKIEJAR"
  
  __lpu_debug "Sending login request..."
  local http_response
  http_response=$(curl -sS -w "\nHTTP_CODE:%{http_code}\n" -b "$COOKIEJAR" -c "$COOKIEJAR" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7" \
    -H "Accept-Encoding: gzip, deflate, br, zstd" \
    -H "Accept-Language: en-US,en;q=0.9" \
    -H "Cache-Control: max-age=0" \
    -H "Connection: keep-alive" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "DNT: 1" \
    -H "Origin: $ORIGIN" \
    -H "Referer: $REFERER" \
    -H "Sec-Fetch-Dest: document" \
    -H "Sec-Fetch-Mode: navigate" \
    -H "Sec-Fetch-Site: same-origin" \
    -H "Sec-Fetch-User: ?1" \
    -H "Upgrade-Insecure-Requests: 1" \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36" \
    -H "sec-ch-ua: \"Chromium\";v=\"142\", \"Google Chrome\";v=\"142\", \"Not_A Brand\";v=\"99\"" \
    -H "sec-ch-ua-mobile: ?0" \
    -H "sec-ch-ua-platform: \"macOS\"" \
    --compressed \
    --data-raw "$data" "$URL" 2>&1)
  
  local curl_exit=$?
  
  __lpu_debug "Curl exit code: $curl_exit"
  
  # Extract HTTP code from response
  local http_code
  http_code=$(echo "$http_response" | grep "HTTP_CODE:" | sed 's/HTTP_CODE://')
  __lpu_debug "HTTP response code: $http_code"
  
  if [[ $curl_exit -eq 0 ]]; then
    __lpu_debug "Request completed successfully"
    
    # Check for success indicators in response
    if echo "$http_response" | grep -qi "To start surfing\|Minimize this login window" 2>/dev/null; then
      __lpu_debug "SUCCESS: Login page detected - authenticated"
      echo "Login successful!"
      return 0
    elif echo "$http_response" | grep -qi "Invalid\|incorrect\|Authentication.*failed" 2>/dev/null; then
      __lpu_debug "ERROR: Invalid credentials detected in response"
      echo "$http_response" > "$TMPFILE"
      echo "Login failed - check credentials" >&2
      echo "Response saved to: $TMPFILE" >&2
      return 1
    elif echo "$http_response" | grep -qi "name=\"username\".*type=\"text\"\|name=\"password\".*type=\"password\"" 2>/dev/null; then
      __lpu_debug "WARNING: Login form still present - authentication may have failed"
      echo "$http_response" > "$TMPFILE"
      echo "Login failed - still on login page" >&2
      echo "Response saved to: $TMPFILE" >&2
      return 1
    else
      __lpu_debug "UNKNOWN: Cannot determine login status from response"
      echo "$http_response" > "$TMPFILE"
      echo "Login request sent (status unknown - please verify connection)"
      echo "Debug: Response saved to $TMPFILE" >&2
      return 0
    fi
  else
    __lpu_debug "ERROR: Curl request failed with exit code $curl_exit"
    echo "$http_response" > "$TMPFILE"
    echo "Login failed - network error" >&2
    echo "Response saved to: $TMPFILE" >&2
    return 1
  fi
}

# Helper: logout function
function _lpu_logout() {
  local COOKIEJAR="${HOME}/.neoscripts/.lpu_cookies_lpu.txt"
  local URL="${LPU_PORTAL_URL:-https://internet.lpu.in/24online/servlet/E24onlineHTTPClient}"
  local REFERER="${LPU_PORTAL_REFERER:-https://internet.lpu.in/24online/webpages/client.jsp}"
  local ORIGIN="${LPU_PORTAL_ORIGIN:-https://internet.lpu.in}"
  local LPU_SERVER="${LPU_SERVER:-172.20.0.66}"

  # Detect wifi device, mac and ip (macOS)
  local WIFI_DEV="$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort/{getline; print $2; exit}')"
  if [[ -z "$WIFI_DEV" ]]; then
    WIFI_DEV="en0"
  fi

  local MAC="$(ifconfig "$WIFI_DEV" 2>/dev/null | awk '/ether/ {print $2}' || true)"
  local IP="$(ipconfig getifaddr "$WIFI_DEV" 2>/dev/null || true)"

  # Load credentials from environment variables
  if [[ -z "$LPU_USERNAME" ]]; then
    echo "LPU_USERNAME not set in environment" >&2
    echo "Please set it in ~/.ezsh/.env" >&2
    return 2
  fi

  local mac_e ip_e user_e data
  mac_e="$(__lpu_urlenc "${MAC:-}")"
  ip_e="$(__lpu_urlenc "${IP:-}")"
  user_e="$(__lpu_urlenc "$LPU_USERNAME")"

  data="mode=193&isAccessDenied=null&url=null&message=&regusingpinid=&checkClose=1&sessionTimeout=-1&guestmsgreq=false&logintype=2&orgSessionTimeout=-1&chrome=1&alerttime=-11&timeout=-1&popupalert=1&dtold=0&mac=${mac_e}&servername=${LPU_SERVER}&temptype=&selfregpageid=&leave=no&macaddress=${mac_e}&ipaddress=${ip_e}&loggedinuser=${user_e}&username=${user_e}&logout=Logout&saveinfo="

  if curl -sSf -b "$COOKIEJAR" -c "$COOKIEJAR" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7" \
    -H "Accept-Encoding: gzip, deflate, br, zstd" \
    -H "Accept-Language: en-US,en;q=0.9" \
    -H "Cache-Control: max-age=0" \
    -H "Connection: keep-alive" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "DNT: 1" \
    -H "Origin: $ORIGIN" \
    -H "Referer: $REFERER" \
    -H "Sec-Fetch-Dest: document" \
    -H "Sec-Fetch-Mode: navigate" \
    -H "Sec-Fetch-Site: same-origin" \
    -H "Sec-Fetch-User: ?1" \
    -H "Upgrade-Insecure-Requests: 1" \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36" \
    -H "sec-ch-ua: \"Chromium\";v=\"142\", \"Google Chrome\";v=\"142\", \"Not_A Brand\";v=\"99\"" \
    -H "sec-ch-ua-mobile: ?0" \
    -H "sec-ch-ua-platform: \"macOS\"" \
    --compressed \
    --data-raw "$data" "$URL" >/dev/null; then
    echo "Logged out."
  else
    echo "Logout failed." >&2
    return 1
  fi
}

# Helper: status function
function _lpu_status() {
  if curl -s --max-time 5 -I http://clients3.google.com/generate_204 | grep -q "HTTP/.* 204"; then
    echo "online"
    return 0
  fi
  echo "captive"
  return 1
}

# Primary function: lpu - login/logout/status for LPU captive portal
# Usage: lpu [login|logout|status]
function lpu() {
  case "${1:-login}" in
    login) _lpu_login ;;
    logout) _lpu_logout ;;
    status) _lpu_status ;;
    *)
      echo "Usage: lpu [login|logout|status]" >&2
      return 1
      ;;
  esac
}
