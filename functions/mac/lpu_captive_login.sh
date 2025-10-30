#!/usr/bin/env bash
# lpu_captive_login.sh — login/logout/status for LPU captive portal
# Usage: lpu_captive_login.sh login|logout|status
# Can be sourced to use lpu_login, lpu_logout, lpu_status functions
# Credentials file: ~/.neoscripts/lpu_internet_creds.env
# File should export USERNAME and PASSWORD, e.g.:
#   export USERNAME="123456@lpu.com"
#   export PASSWORD="PASSWORD"

help() {
  cat << EOF
Usage: $(basename "$0") {login|logout|status}
Manage LPU captive portal login.
Commands:
  login     Log in to the captive portal
  logout    Log out from the captive portal
  status    Check if currently online or captive

Functions (when sourced):
  lpu_login    Log in to the captive portal
  lpu_logout   Log out from the captive portal
  lpu_status   Check if currently online or captive (returns 0 if online)
EOF
}

CREDS_FILE="${HOME}/.neoscripts/lpu_internet_creds.env"
COOKIEJAR="${HOME}/.neoscripts/.lpu_cookies_lpu.txt"
URL="${LPU_PORTAL_URL:-https://internet.lpu.in/24online/servlet/E24onlineHTTPClient}"
REFERER="${LPU_PORTAL_REFERER:-https://internet.lpu.in/24online/webpages/client.jsp}"
ORIGIN="${LPU_PORTAL_ORIGIN:-https://internet.lpu.in}"
LPU_SERVER="${LPU_SERVER:-172.20.0.66}"

# helper: url-encode using python3 (fallback to raw if python3 missing)
urlenc() {
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

# detect wifi device, mac and ip (macOS)
WIFI_DEV="$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort/{getline; print $2; exit}')"
if [[ -z "$WIFI_DEV" ]]; then
  # fallback to en0
  WIFI_DEV="en0"
fi

MAC="$(ifconfig "$WIFI_DEV" 2>/dev/null | awk '/ether/ {print $2}' || true)"
IP="$(ipconfig getifaddr "$WIFI_DEV" 2>/dev/null || true)"

# load creds
if [[ -f "$CREDS_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CREDS_FILE"
else
  echo "Credentials file missing: $CREDS_FILE" >&2
  exit 2
fi

: "${USERNAME:?USERNAME not set in creds file}"
: "${PASSWORD:?PASSWORD not set in creds file}"

# common curl headers
CURL_BASE=( -sSf -b "$COOKIEJAR" -c "$COOKIEJAR" -H "Content-Type: application/x-www-form-urlencoded" -H "Origin: $ORIGIN" -H "Referer: $REFERER" -A "curl/8" )

login() {
  # quick captive check: if generate_204 returns 204, we have internet
  if curl -s --max-time 5 -I http://clients3.google.com/generate_204 | grep -q "HTTP/.* 204"; then
    echo "Already online (no captive portal)."
    return 0
  fi

  local mac_e ip_e user_e pass_e data
  mac_e="$(urlenc "${MAC:-}")"
  ip_e="$(urlenc "${IP:-}")"
  user_e="$(urlenc "$USERNAME")"
  pass_e="$(urlenc "$PASSWORD")"

  data="mode=191&isAccessDenied=null&url=null&message=&regusingpinid=&checkClose=1&sessionTimeout=0&guestmsgreq=false&logintype=2&orgSessionTimeout=0&chrome=-1&alerttime=null&timeout=0&popupalert=0&dtold=0&mac=${mac_e}&servername=${LPU_SERVER}&temptype=&selfregpageid=&leave=no&macaddress=${mac_e}&ipaddress=${ip_e}&username=${user_e}&password=${pass_e}&loginotp=false&logincaptcha=false&registeruserotp=false&registercaptcha=false"

  if curl "${CURL_BASE[@]}" --data-raw "$data" "$URL" >/dev/null; then
    echo "Login request sent."
  else
    echo "Login failed." >&2
    return 1
  fi
}

logout() {
  local mac_e ip_e user_e data
  mac_e="$(urlenc "${MAC:-}")"
  ip_e="$(urlenc "${IP:-}")"
  user_e="$(urlenc "$USERNAME")"

  data="mode=193&isAccessDenied=null&url=null&message=&regusingpinid=&checkClose=1&sessionTimeout=-1&guestmsgreq=false&logintype=2&orgSessionTimeout=-1&chrome=1&alerttime=-11&timeout=-1&popupalert=1&dtold=0&mac=${mac_e}&servername=${LPU_SERVER}&temptype=&selfregpageid=&leave=no&macaddress=${mac_e}&ipaddress=${ip_e}&loggedinuser=${user_e}&username=${user_e}&logout=Logout&saveinfo="

  if curl "${CURL_BASE[@]}" --data-raw "$data" "$URL" >/dev/null; then
    echo "Logged out."
  else
    echo "Logout failed." >&2
    return 1
  fi
}

status() {
  if curl -s --max-time 5 -I http://clients3.google.com/generate_204 | grep -q "HTTP/.* 204"; then
    echo "online"
    return 0
  fi
  echo "captive"
  return 1
}

# Expose as lpu_* functions
lpu_login() {
  login "$@"
}

lpu_logout() {
  logout "$@"
}

lpu_status() {
  status "$@"
}

# Only run command handling if script is executed (not sourced)
# Check if we're being sourced or executed
(return 0 2>/dev/null) && _SOURCED=1 || _SOURCED=0

if [[ $_SOURCED -eq 0 ]]; then
  case "${1:-}" in
    login) login ;;
    logout) logout ;;
    status) status ;;
    help|--help|-h|"") help ;;
    *) help ;;
  esac
fi

unset _SOURCED
