#!/bin/bash

set -e

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
  done

  echo "[INFO] Sleeping for ${INTERVAL_SECONDS}s..."
  sleep "${INTERVAL_SECONDS:-7200}"

  echo ""
done
