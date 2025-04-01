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

# Helper function to update config in-place
update_config() {
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

# Function to update qBittorrent default setting for new downloads
update_add_trackers_setting() {
  local host="$1"
  local port="$2"
  local username="$3"
  local password="$4"
  local auth_bypass="$5"

  local full_url="${host}:${port}"
  local cookie_file="/tmp/cookies.txt"

  echo "[INFO] Fetching live tracker list..."
  tracker_list=$(
    curl -s https://newtrackon.com/api/stable && echo &&
    curl -s https://trackerslist.com/best.txt && echo &&
    curl -s https://trackerslist.com/http.txt && echo &&
    curl -s https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt
  )

  tracker_list=$(echo -e "$tracker_list" | sort -u)

  if [ "$auth_bypass" = "true" ]; then
    echo "[INFO] Skipping login due to auth bypass"
  else
    echo "[INFO] Logging in to $full_url to set default trackers..."
    curl --fail --silent --show-error \
      --cookie-jar "$cookie_file" \
      --cookie "$cookie_file" \
      --header "Referer: $full_url" \
      --data "username=$username&password=$password" \
      "$full_url/api/v2/auth/login" > /dev/null
  fi

  echo "[INFO] Setting 'add_trackers' qBittorrent preference"
  json_string=$(jq -n --arg trackers "$tracker_list" '{add_trackers: $trackers}')

  curl --fail --silent --show-error \
    --cookie-jar "$cookie_file" \
    --cookie "$cookie_file" \
    --data-urlencode "json=$json_string" \
    "$full_url/api/v2/app/setPreferences" || echo "[WARN] Failed to set default trackers on $full_url"
}

# Parse host list into an array
IFS="," read -r -a HOSTS <<< "$QBT_HOSTS"
IFS="," read -r -a PORTS <<< "$QBT_PORTS"

# Run on a loop
while true; do
  echo "[INFO] Updating qBittorrent trackers at $(date)"

  for i in "${!HOSTS[@]}"; do
    echo "[INFO] Updating host ${HOSTS[$i]}:${PORTS[$i]}"
    update_config "${HOSTS[$i]}" "${PORTS[$i]}" "$QBT_USERNAME" "$QBT_PASSWORD" "$QBT_AUTH_BYPASS"
    bash /AddqBittorrentTrackers.sh -a || echo "[WARN] Failed updating ${HOSTS[$i]}"

    update_add_trackers_setting "${HOSTS[$i]}" "${PORTS[$i]}" "$QBT_USERNAME" "$QBT_PASSWORD" "$QBT_AUTH_BYPASS"
  done

  echo "[INFO] Sleeping for ${INTERVAL_SECONDS}s..."
  sleep "${INTERVAL_SECONDS:-7200}"
  echo ""
done
