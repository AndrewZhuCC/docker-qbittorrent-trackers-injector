#!/bin/bash

set -e

# Fail hard if old environment variable names are being used
if [[ -n "$QBT_HOST" || -n "$QBT_PORT" ]]; then
  echo "[ERROR] Detected use of deprecated environment variables QBT_HOST and/or QBT_PORT." >&2
  echo "[ERROR] This script no longer supports these variables." >&2
  echo "[ERROR] Please use the new variables QBT_HOSTS and QBT_PORTS instead." >&2
  echo "[ERROR] These env vars will contain one or more qBittorrent hosts. Example:" >&2
  echo "[ERROR]   QBT_HOSTS=http://localhost,http://192.168.1.42" >&2
  echo "[ERROR]   QBT_PORTS=8080,8081" >&2
  echo "" >&2
  exit 1
fi

# Parse host list into an array
IFS="," read -r -a HOSTS <<< "$QBT_HOSTS"
IFS="," read -r -a PORTS <<< "$QBT_PORTS"

# Auth helper (returns cookie)
get_cookie() {
  local host="$1"
  local port="$2"
  local username="$3"
  local password="$4"

  if [ "$QBT_AUTH_BYPASS" = "true" ]; then
    echo ""  # No auth cookie
  else
    curl --silent --fail --show-error \
      --cookie-jar - \
      --data "username=$username&password=$password" \
      "$host:$port/api/v2/auth/login"
  fi
}

# Update default trackers config via API
set_default_trackers() {
  local host="$1"
  local port="$2"
  local cookie="$3"

  echo "[INFO] Fetching latest tracker list for $host:$port"
  TRACKERS=$(curl -fsSL https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt)
  TRACKERS=$(echo "$TRACKERS" | sed '/^$/d' | sort -u | tr '\n' '\\n')

  echo "[INFO] Setting 'add_trackers' qBittorrent preference"
  curl --fail --silent --show-error \
    --cookie <(echo "$cookie") \
    --header "Content-Type: application/json" \
    --data "{\"add_trackers\":\"$TRACKERS\"}" \
    "$host:$port/api/v2/app/setPreferences" || echo "[WARN] Failed to set default trackers on $host:$port"
}

# Update script config on each loop
update_script_config() {
  local host="$1"
  local port="$2"
  local username="$3"
  local password="$4"
  local auth_bypass="$5"

  sed -i "s|^qbt_host=.*|qbt_host=\"$host\"|" /AddqBittorrentTrackers.sh
  sed -i "s|^qbt_port=.*|qbt_port=\"$port\"|" /AddqBittorrentTrackers.sh

  if [ "$auth_bypass" = "true" ]; then
    sed -i 's/^qbt_username=.*/qbt_username=""/' /AddqBittorrentTrackers.sh
    sed -i 's/^qbt_password=.*/qbt_password=""/' /AddqBittorrentTrackers.sh
  else
    sed -i "s|^qbt_username=.*|qbt_username=\"$username\"|" /AddqBittorrentTrackers.sh
    sed -i "s|^qbt_password=.*|qbt_password=\"$password\"|" /AddqBittorrentTrackers.sh
  fi
}

# Main loop
while true; do
  echo "[INFO] Updating qBittorrent trackers at $(date)"

  for i in "${!HOSTS[@]}"; do
    HOST="${HOSTS[$i]}"
    PORT="${PORTS[$i]}"
    echo "[INFO] Updating host $HOST:$PORT"

    update_script_config "$HOST" "$PORT" "$QBT_USERNAME" "$QBT_PASSWORD" "$QBT_AUTH_BYPASS"

    bash /AddqBittorrentTrackers.sh -a || echo "[WARN] Failed updating $HOST"

    if [ "$UPDATE_DEFAULT_TRACKERS" = "true" ]; then
      COOKIE=$(get_cookie "$HOST" "$PORT" "$QBT_USERNAME" "$QBT_PASSWORD")
      set_default_trackers "$HOST" "$PORT" "$COOKIE"
    fi
  done

  echo "[INFO] Sleeping for ${INTERVAL_SECONDS}s..."
  sleep "${INTERVAL_SECONDS:-7200}"
  echo ""
done
