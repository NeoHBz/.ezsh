#!/usr/bin/env bash
# lpu_captive_login.sh — login to LPU captive portal
# Primary function: lpu (login by default, accepts logout/status as args)
# Credentials file: ~/.neoscripts/lpu_internet_creds.env
# File should export USERNAME and PASSWORD, e.g.:
#   export USERNAME="123456@lpu.com"
#   export PASSWORD="PASSWORD"

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
  local CREDS_FILE="${HOME}/.neoscripts/lpu_internet_creds.env"
  local COOKIEJAR="${HOME}/.neoscripts/.lpu_cookies_lpu.txt"
  local URL="${LPU_PORTAL_URL:-https://internet.lpu.in/24online/servlet/E24onlineHTTPClient}"
  local REFERER="${LPU_PORTAL_REFERER:-https://internet.lpu.in/24online/webpages/client.jsp}"
  local ORIGIN="${LPU_PORTAL_ORIGIN:-https://internet.lpu.in}"
  local LPU_SERVER="${LPU_SERVER:-172.20.0.66}"
  
  # Quick captive check: if generate_204 returns 204, we have internet
  if curl -s --max-time 5 -I http://clients3.google.com/generate_204 | grep -q "HTTP/.* 204"; then
    echo "Already online (no captive portal)."
    return 0
  fi

  # Detect wifi device, mac and ip (macOS)
  local WIFI_DEV="$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort/{getline; print $2; exit}')"
  if [[ -z "$WIFI_DEV" ]]; then
    WIFI_DEV="en0"
  fi

  local MAC="$(ifconfig "$WIFI_DEV" 2>/dev/null | awk '/ether/ {print $2}' || true)"
  local IP="$(ipconfig getifaddr "$WIFI_DEV" 2>/dev/null || true)"

  # Load creds
  if [[ -f "$CREDS_FILE" ]]; then
    source "$CREDS_FILE"
  else
    echo "Credentials file missing: $CREDS_FILE" >&2
    return 2
  fi

  if [[ -z "$USERNAME" ]] || [[ -z "$PASSWORD" ]]; then
    echo "USERNAME or PASSWORD not set in creds file" >&2
    return 2
  fi

  local mac_e ip_e user_e pass_e data
  mac_e="$(__lpu_urlenc "${MAC:-}")"
  ip_e="$(__lpu_urlenc "${IP:-}")"
  user_e="$(__lpu_urlenc "$USERNAME")"
  pass_e="$(__lpu_urlenc "$PASSWORD")"

  data="mode=191&isAccessDenied=null&url=null&message=&regusingpinid=&checkClose=1&sessionTimeout=0&guestmsgreq=false&logintype=2&orgSessionTimeout=0&chrome=-1&alerttime=null&timeout=0&popupalert=0&dtold=0&mac=${mac_e}&servername=${LPU_SERVER}&macaddress=${mac_e}&ipaddress=${ip_e}&username=${user_e}&password=${pass_e}&loginotp=false&logincaptcha=false&registeruserotp=false&registercaptcha=false"

  if curl -sSf -b "$COOKIEJAR" -c "$COOKIEJAR" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Origin: $ORIGIN" \
    -H "Referer: $REFERER" \
    -A "curl/8" \
    --data-raw "$data" "$URL" >/dev/null; then
    echo "Login request sent."
  else
    echo "Login failed." >&2
    return 1
  fi
}

# Helper: logout function
function _lpu_logout() {
  local CREDS_FILE="${HOME}/.neoscripts/lpu_internet_creds.env"
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

  # Load creds
  if [[ -f "$CREDS_FILE" ]]; then
    source "$CREDS_FILE"
  else
    echo "Credentials file missing: $CREDS_FILE" >&2
    return 2
  fi

  if [[ -z "$USERNAME" ]]; then
    echo "USERNAME not set in creds file" >&2
    return 2
  fi

  local mac_e ip_e user_e data
  mac_e="$(__lpu_urlenc "${MAC:-}")"
  ip_e="$(__lpu_urlenc "${IP:-}")"
  user_e="$(__lpu_urlenc "$USERNAME")"

  data="mode=193&isAccessDenied=null&url=null&message=&regusingpinid=&checkClose=1&sessionTimeout=-1&guestmsgreq=false&logintype=2&orgSessionTimeout=-1&chrome=1&alerttime=-11&timeout=-1&popupalert=1&dtold=0&mac=${mac_e}&servername=${LPU_SERVER}&temptype=&selfregpageid=&leave=no&macaddress=${mac_e}&ipaddress=${ip_e}&loggedinuser=${user_e}&username=${user_e}&logout=Logout&saveinfo="

  if curl -sSf -b "$COOKIEJAR" -c "$COOKIEJAR" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Origin: $ORIGIN" \
    -H "Referer: $REFERER" \
    -A "curl/8" \
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
