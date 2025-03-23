# qBittorrent Trackers Updater – Dockerized Service
![Docker Image Size](https://img.shields.io/docker/image-size/ghcr.io/greatnewhope/qbittorrent-trackers-updater/latest)
![GitHub package](https://img.shields.io/github/v/release/greatnewhope/qbittorrent-trackers-updater?label=release)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/greatnewhope/qbittorrent-trackers-updater/publish.yml?branch=main&label=build)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

🚀 This container runs [`AddqBittorrentTrackers.sh`](https://github.com/Jorman/Scripts) on a schedule to ensure **all your public torrents** in qBittorrent are updated with the **latest public trackers** from [`ngosang/trackerslist`](https://github.com/ngosang/trackerslist).

📌 This tool is different from [claabs/qbittorrent-tracker-updater](https://github.com/claabs/qbittorrent-tracker-updater), which only updates qBittorrent's default **settings** (used for *new torrents*).  
This container **actively updates existing torrents** using the qBittorrent API — hands-free and fully automated.

✨ Based on [Jorman's script](https://github.com/Jorman/Scripts), this project wraps it into a **production-ready Docker service**.

---

## ✅ Features

- 🧠 **Automatically updates existing torrents** with new trackers
- 🐳 Fully compatible with `linuxserver/qbittorrent`
- 🔒 Supports both **authenticated** and **auth-bypassed** WebUI setups
- 🔎 Skips **private torrents**
- 🧩 Works out of the box with `gluetun` and VPN setups
- 🪶 Lightweight, scheduled, and self-healing (`restart: unless-stopped`)

---

## 📦 Docker Compose Example

```yaml
services:
  qbittorrent_trackers_updater:
    image: ghcr.io/GreatNewHope/docker-qbittorrent-trackers-injector:latest
    container_name: qbittorrent_trackers_updater
    env_file:
      - .env.qbittorrent_trackers_updater
    network_mode: "service:gluetun"
    restart: unless-stopped
```

This container will reuse the network of `gluetun`, so it must be available under that name.

If you’re not using a VPN container like gluetun, just connect it to your main Docker network:

```yaml
services:
  qbittorrent_trackers_updater:
    image: ghcr.io/GreatNewHope/docker-qbittorrent-trackers-injector:latest
    container_name: qbittorrent_trackers_updater
    env_file:
      - .env.qbittorrent_trackers_updater
    networks:
      - net
    restart: unless-stopped

networks:
  net:
    external: true  # or define as internal if needed
```


---

## ⚙️ Environment Variables

Create a `.env.qbittorrent_trackers_updater` file with:

```dotenv
QBT_HOST=http://localhost
QBT_PORT=8080
QBT_USERNAME=admin
QBT_PASSWORD=adminadmin
INTERVAL_SECONDS=3600
```

> ✅ If you use **auth bypass** in qBittorrent (`Bypass authentication for clients on localhost`), you can leave `QBT_USERNAME` and `QBT_PASSWORD` empty.

---

## 🛡️ Authentication Tips

If you're using the `linuxserver/qbittorrent` container, and you've enabled:

> ⚙️ Settings → Web UI → “Bypass authentication for clients on localhost”

Then:
- Set `QBT_USERNAME=` and `QBT_PASSWORD=`
- The script will skip login and directly talk to the API

---

## 🧊 Future Plans

- Healthcheck + more logs

---

## 🙏 Credits

- Script by [Jorman](https://github.com/Jorman/Scripts)
- Tracker lists by [ngosang](https://github.com/ngosang/trackerslist)
- Original Docker concept and auth tips inspired by [`claabs/qbittorrent-tracker-updater`](https://github.com/claabs/qbittorrent-tracker-updater)

---

Feel free to contribute or open an issue if you find a bug or want to improve something!
