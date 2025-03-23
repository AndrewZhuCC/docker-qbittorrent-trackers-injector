#!/bin/bash

set -e

# Inject configuration into script
sed -i "s|^qbt_host=.*|qbt_host=\"${QBT_HOST}\"|" /AddqBittorrentTrackers.sh
sed -i "s|^qbt_port=.*|qbt_port=\"${QBT_PORT}\"|" /AddqBittorrentTrackers.sh

if [ "$QBT_AUTH_BYPASS" = "true" ]; then
  sed -i 's/^qbt_username=.*/qbt_username=""/' /AddqBittorrentTrackers.sh
  sed -i 's/^qbt_password=.*/qbt_password=""/' /AddqBittorrentTrackers.sh
else
  sed -i "s|^qbt_username=.*|qbt_username=\"${QBT_USERNAME}\"|" /AddqBittorrentTrackers.sh
  sed -i "s|^qbt_password=.*|qbt_password=\"${QBT_PASSWORD}\"|" /AddqBittorrentTrackers.sh
fi

# Run on a loop
while true; do
  echo "[INFO] Updating qBittorrent trackers at $(date)"
  bash /AddqBittorrentTrackers.sh -a
  echo "[INFO] Sleeping for ${INTERVAL_SECONDS}s..."
  sleep "${INTERVAL_SECONDS:-7200}"
done