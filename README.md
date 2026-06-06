<div align="center">

<img src="https://i.imgur.com/kyZTtCl.png" width="80" alt="LimeTorrent logo">

# LimeTorrent

**A lightweight, self-hosted torrent manager with a REST API and Web UI.**  
Built on [libtorrent 1.2.19](https://libtorrent.org) and [Flask](https://flask.palletsprojects.com).

[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows-a3e635)](#installation)
[![Arch](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-a3e635)](#installation)
[![License](https://img.shields.io/github/license/Limenime/LimeTorrent?color=a3e635)](LICENSE)

</div>

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
  - [Linux (amd64)](#linux-amd64)
  - [Linux (arm64)](#linux-arm64)
  - [Windows (amd64)](#windows-amd64)
- [Usage](#usage)
  - [CLI Options](#cli-options)
  - [Environment Variables](#environment-variables)
  - [Examples](#examples)
- [Authentication](#authentication)
  - [API Key](#1-api-key-recommended-for-automation)
  - [Session Cookie](#2-session-cookie-webui-login)
  - [User Management](#user-management)
  - [Admin Credentials (RAM-only)](#admin-credentials-ram-only)
- [REST API Overview](#rest-api-overview)
- [State Model](#state-model)
- [Resume Persistence](#resume-persistence)
- [Post-Download Commands](#post-download-commands)
- [HTTP File Download](#http-file-download)
- [Logging](#logging)
- [Data Directories](#data-directories)
- [Running as a Service (systemd)](#running-as-a-service-systemd)
- [FAQ](#faq)

---

## Features

- **Multiple add methods** — magnet links, `.torrent` file upload, or direct `.torrent` URL
- **Full torrent control** — pause, resume, stop, remove (with optional data deletion), recheck, re-announce
- **Per-file priority** — select which files to download and at what priority (skip / normal / high / max)
- **Speed limits** — global and per-torrent upload/download caps
- **Super-seeding mode** — enabled by default; per-torrent and global toggle
- **Resume persistence** — torrent state survives restarts; on-disk resume data written atomically
- **All-time statistics** — cumulative upload/download totals persisted across restarts
- **REST API** — full JSON API with per-user API-key authentication and permission levels
- **Web UI** — dark/light theme, live progress, drag-and-drop upload, multi-select bulk actions, resizable drawer
- **Torrent creation** — create `.torrent` files from local data; `name` parameter sets the output `.torrent` filename, while internal torrent structure always uses the actual disk directory/file name to ensure seeding works correctly; supports web seeds (BEP-19 url_seed / BEP-17 http_seed), custom trackers, comment, and private flag
- **Auto-seed after create** — admin users can have a freshly created torrent immediately added to the session and verified via recheck (`auto_seed: true`); excluded from post-download command by design
- **Multi-user access control** — admin creates regular users with individually selectable permissions
- **Auto-provisioned API keys** — a personal API key is automatically generated when a non-admin account is created and returned in the creation response; users can view and revoke their keys via `/api/keys/me` but cannot generate new ones (admin issues additional keys via `POST /users/<username>/api_key`); admin key is fixed via `API_KEY` env var
- **RAM-only admin credentials** — admin password and API key are never written to disk; set via CLI/env
- **Single active session per account** — prevents concurrent logins for the same user
- **Granular delete permissions** — separate permissions for metadata-only removal vs. file deletion
- **Per-user activity logs** — each user sees only their own log; admin sees all; written to separate files
- **Post-download commands** — run a shell command automatically when a torrent finishes; supports per-torrent override and privilege dropping (`run_as`); `LIME_API_KEY` and `LIME_API_ENDPOINT` are automatically injected; **RAM-only** — config cleared on restart; torrents added via `/create` (auto-seed) and `/seed` are excluded
- **HTTP file download** — serve completed files from the server over HTTP via API key in URL path
- **View-only mode** — unauthenticated users can monitor torrents but cannot modify anything
- **Login rate limiting** — IP lockout after 3 failed attempts (5-minute cooldown)
- **Graceful shutdown** — SIGTERM/SIGINT handler saves all resume data before exit
- **Credential recovery endpoint** — `GET /info` (no auth) returns runtime credentials if terminal is cleared
- **Download folder management** — admin can change the download directory at runtime via API or WebUI
- **Admin data manager** — delete all logs or reset all app data from the WebUI (admin only)
- **Autosave interval** — configurable resume/stats autosave interval (default 30 s, range 5–3600 s)

---

## Screenshots

<p align="center">
  <span style="display: inline-flex; gap: 20px;">
    <img src="https://i.imgur.com/SyVe5R0.png" width="300" alt="Light-Theme">
    <img src="https://i.imgur.com/R3CbykP.png" width="300" alt="Dark-Theme">
  </span>
</p>

---

## Installation

LimeTorrent is distributed as a **single self-contained binary** — no Python, no pip, no dependencies required.  
Download the binary for your platform from the [Releases](https://github.com/Limenime/LimeTorrent/releases) page.

### Linux (amd64)

For standard 64-bit desktops, servers, VMs, and most cloud instances (x86-64).

```bash
# Download the binary
wget https://github.com/Limenime/LimeTorrent/releases/latest/download/LimeTorrent-linux-amd64.tgz -O LimeTorrent.tgz
tar -xvzf LimeTorrent.tgz

# Make it executable
chmod u+rwx LimeTorrent

# (Optional) Install system-wide
sudo mv LimeTorrent /usr/local/bin/LimeTorrent

# Run
LimeTorrent
```

### Linux (arm64).

For 64-bit ARM boards.

```bash
# Download the ARM64 binary
wget https://github.com/Limenime/LimeTorrent/releases/latest/download/LimeTorrent-linux-arm64.tgz -O LimeTorrent.tgz
tar -xvzf LimeTorrent.tgz

# Make it executable
chmod u+rwx LimeTorrent

# (Optional) Install system-wide
sudo mv LimeTorrent /usr/local/bin/LimeTorrent

# Run
LimeTorrent
```

### Windows (amd64)

For 64-bit Windows 10 / 11 (x64).

1. Download `LimeTorrent-windows-amd64.7z` from the [Releases](https://github.com/Limenime/LimeTorrent/releases) page.
2. Extrack and run it from Command Prompt or PowerShell:

```cmd
LimeTorrent.exe
```

Or with options:

```cmd
LimeTorrent.exe --host 0.0.0.0 --port 5000 --webui-pass mysecret
```

> **Windows Defender / SmartScreen:** Because the binary is not code-signed, Windows may show a SmartScreen warning on first launch. Click **"More info" → "Run anyway"** to proceed.

---

On first launch you will see:

```
============================================================
  LimeTorrent
============================================================
  WebUI      : http://127.0.0.1:5000/webui
  API Docs   : http://127.0.0.1:5000/doc
  Info dump  : http://127.0.0.1:5000/info  (no auth required)
------------------------------------------------------------
  Username   : admin
  Password   : lAQ90OeO  [auto-generated -- save this!]
  API Key    : cc69b715bbc953e69127697ab63c2a1f84d9e2f0b5c7d8e3a4b9f21c6d7e8f0a1
------------------------------------------------------------
  libtorrent : 1.2.19.0
  Listen     : 0.0.0.0:6881   max-connections: 500
  Super-seed : ON (default)
  Debug log  : off (errors only)
------------------------------------------------------------
  Config     : /home/you/.local/share/.limetorrent
  Downloads  : /home/you/Downloads
  Resume     : /home/you/.local/share/.limetorrent/resume
  Torrents   : /home/you/.local/share/.limetorrent/created
  Logs       : /home/you/.local/share/.limetorrent/logs
============================================================
```

The admin password is shown **in full** at startup. Save it, or set a fixed password via `--webui-pass`.  
If the terminal is cleared before you note the credentials, visit **`http://127.0.0.1:5000/info`** (no authentication required) to retrieve them again.

> **Security note:** Admin credentials are **never stored on disk** — they exist in RAM only and are reconstructed from CLI args / environment variables on every startup. Rotating the password is as simple as restarting with a new `--webui-pass` value.

---

## Usage

### CLI Options

```
usage: LimeTorrent [OPTIONS]

LimeTorrent — libtorrent 1.2.x REST API server.
Manages torrents via HTTP: add (magnet/file/URL), pause, stop,
delete (by hash or .torrent file), seed, create, monitor, and more.

options:
  -h, --help                show this help message and exit
  --host HOST               Bind address (default: 0.0.0.0, env: HOST)
  --port PORT               Bind port (default: 5000, env: PORT)
  --download-dir DIR        Directory for downloaded files (env: DOWNLOAD_DIR)
  --torrent-dir DIR         Directory for created .torrent files (env: TORRENT_DIR)
  --resume-dir DIR          Directory for resume data (env: RESUME_DIR)
  --upload-limit BPS        Global upload limit in bytes/s, 0=unlimited (env: GLOBAL_UPLOAD_LIMIT)
  --download-limit BPS      Global download limit in bytes/s, 0=unlimited (env: GLOBAL_DOWNLOAD_LIMIT)
  --upload-slots N          Max upload slots per torrent (default: 8, env: UPLOAD_SLOTS)
  --connections N           Max connections limit (default: 500, env: CONNECTIONS_LIMIT)
  --listen IFACE:PORT       libtorrent listen interface (default: 0.0.0.0:6881, env: LISTEN_INTERFACES)
  --webui-user USER         WebUI username (default: admin, env: WEBUI_USER)
  --webui-pass PASS         WebUI password (default: auto-generated, env: WEBUI_PASS)
  --super-seeding           Enable global super-seeding mode on startup (default: ON)
  --no-super-seeding        Disable global super-seeding mode on startup
  --http-download           Enable HTTP file download endpoint (default: ON)
  --no-http-download        Disable HTTP file download endpoint
  --post-cmd CMD            Shell command to run after each torrent finishes (env: POST_CMD)
  --post-cmd-run-as USER    Drop privileges to this OS user before running --post-cmd (Linux/macOS only)
  --debug                   Enable full debug logging incl. HTTP requests (env: DEBUG)

API Endpoints (quick reference):
  POST   /add/magnet            Add torrent via magnet link
  POST   /add/file              Add torrent via .torrent file upload
  POST   /add/url               Add torrent via direct .torrent URL
  GET    /list                  List all torrents
  GET    /status/<hash>         Status of a single torrent
  GET    /files/<hash>          List files in torrent with priorities
  POST   /files/<hash>          Set per-file priorities
  GET    /monitor               Live streaming monitor
  POST   /pause/<hash>          Pause torrent
  POST   /stop/<hash>           Stop torrent (pause + save resume)
  POST   /stop/file             Stop torrent identified by .torrent file
  POST   /resume/<hash>         Resume torrent
  DELETE /remove/<hash>         Remove torrent (add ?delete_files=1 to wipe data)
  DELETE /remove/file           Remove torrent identified by .torrent file
  POST   /limit/<hash>          Set per-torrent speed limits (JSON body)
  POST   /limit/global          Set global speed limits
  POST   /recheck/<hash>        Force recheck
  POST   /announce/<hash>       Force re-announce
  GET    /trackers/<hash>       List trackers
  GET    /peers/<hash>          List connected peers
  POST   /create                Create .torrent from local path
  POST   /seed                  Seed local data with .torrent file
  GET    /magnet/<hash>         Get magnet URI
  POST   /save                  Persist resume data for all torrents
  GET    /health                Health check
  GET    /info                  Credential recovery (no auth required)
  POST   /super_seed/<hash>     Toggle super-seeding mode for a torrent
  POST   /super_seed/global     Set global super-seeding mode on/off
  GET    /download/torrent/<hash>               Download .torrent file
  GET    /download/file/<api_key>/<hash>/<path> Download completed file
  POST   /postcmd/global        Set global post-download command
  POST   /postcmd/<hash>        Set per-torrent post-download command
  GET    /stats/global          Session + all-time upload/download stats
  GET    /api/key               Get API key info — admin: global key, non-admin: own key list (session required)
  POST   /api/key/toggle        Enable/disable API key authentication (admin only)
  GET    /api/keys/me           List own API keys with full values (session required)
  POST   /api/keys/me           Disabled — always returns 403 (keys issued at account creation)
  DELETE /api/keys/me/<idx>     Revoke own API key by index (non-admin only)
  GET    /users                 List users (admin only)
  POST   /users                 Create user (admin only)
  GET    /logs/webui            Activity log (filtered per role)
  GET    /webui                 Web UI (browser)
  GET    /doc                   API documentation

Examples:
  LimeTorrent --host 0.0.0.0 --port 8080
  LimeTorrent --upload-limit 1048576 --download-limit 5242880
  LimeTorrent --webui-user admin --webui-pass mysecret
  LimeTorrent --post-cmd '/scripts/notify.sh' --post-cmd-run-as ubuntu
  curl -X POST http://127.0.0.1:5000/add/magnet -d '{"magnet":"magnet:?xt=..."}'
  curl -X DELETE http://127.0.0.1:5000/remove/<hash>?delete_files=1
  curl -X POST http://127.0.0.1:5000/stop/<hash>
  curl -X POST -F torrent=@file.torrent http://127.0.0.1:5000/stop/file
  curl -X DELETE -F torrent=@file.torrent http://127.0.0.1:5000/remove/file
```

### Environment Variables

All CLI options can also be set via environment variables. CLI arguments take priority over environment variables.

| Variable | CLI equivalent | Default |
|---|---|---|
| `HOST` | `--host` | `0.0.0.0` |
| `PORT` | `--port` | `5000` |
| `DOWNLOAD_DIR` | `--download-dir` | `~/Downloads` |
| `TORRENT_DIR` | `--torrent-dir` | `~/.local/share/.limetorrent/created` (Linux) / `%APPDATA%\.limetorrent\created` (Windows) |
| `RESUME_DIR` | `--resume-dir` | `~/.local/share/.limetorrent/resume` (Linux) / `%APPDATA%\.limetorrent\resume` (Windows) |
| `GLOBAL_UPLOAD_LIMIT` | `--upload-limit` | `0` (unlimited) |
| `GLOBAL_DOWNLOAD_LIMIT` | `--download-limit` | `0` (unlimited) |
| `UPLOAD_SLOTS` | `--upload-slots` | `8` |
| `CONNECTIONS_LIMIT` | `--connections` | `500` |
| `LISTEN_INTERFACES` | `--listen` | `0.0.0.0:6881` |
| `WEBUI_USER` | `--webui-user` | `admin` |
| `WEBUI_PASS` | `--webui-pass` | _(random 12-char)_ |
| `API_KEY` | _(no CLI equivalent)_ | _(auto-generated at startup)_ — fix the admin API key to a known value; useful for post-cmd scripts and integrations that need a stable key across restarts |
| `SUPER_SEEDING` | `--super-seeding` | `true` (set to `0` to disable) |
| `HTTP_DOWNLOAD` | `--http-download` | `1` (enabled) |
| `POST_CMD` | `--post-cmd` | _(not set)_ |
| `POST_CMD_RUN_AS` | `--post-cmd-run-as` | _(not set)_ |
| `DEBUG` | `--debug` | `false` |

### Examples

```bash
# Listen on all interfaces, custom port
LimeTorrent --host 0.0.0.0 --port 8080

# Set credentials and download directory
LimeTorrent --webui-user admin --webui-pass mysecret --download-dir /data/torrents

# Limit upload to 2 MB/s, download to 10 MB/s
LimeTorrent --upload-limit 2097152 --download-limit 10485760

# Run a notification script after every completed torrent
LimeTorrent --post-cmd '/scripts/notify.sh "$TORRENT_NAME"' --post-cmd-run-as ubuntu

# Disable HTTP file download
LimeTorrent --no-http-download

# Using environment variables (Linux)
HOST=0.0.0.0 PORT=8080 WEBUI_PASS=secret LimeTorrent

# Using environment variables (Windows PowerShell)
$env:WEBUI_PASS="secret"; .\LimeTorrent.exe
```

---

## Authentication

LimeTorrent supports two authentication methods:

### 1. API Key (recommended for automation)

Pass the `Lime-API-Key` header with every request:

```bash
curl -H "Lime-API-Key: YOUR_API_KEY" http://127.0.0.1:5000/list
```

The API key is printed in full at startup and visible in **Settings → API Key** (requires login).  
API keys have a **level** — `admin` (full access) or `user` (respects the account's permissions).

**Admin API key** is runtime-only and never stored on disk. To fix it to a known value across restarts, set the `API_KEY` environment variable:

```bash
API_KEY=mysecretkey LimeTorrent --webui-pass mysecret
```

**Non-admin users** receive an API key automatically when their account is created — it is returned once in the `POST /users` response as `api_key`. Users can view and revoke their keys, but cannot generate new ones. If an additional key is needed, an admin can issue one:

```bash
# List own keys (full values) — session required
curl -b cookies.txt http://127.0.0.1:5000/api/keys/me

# Revoke key at index 0 (only if more than one key exists)
curl -b cookies.txt -X DELETE http://127.0.0.1:5000/api/keys/me/0
```

Admins can also issue additional API keys for any user via `POST /users/<username>/api_key`.

### 2. Session Cookie (WebUI login)

Log in via the Web UI at `/webui` or via the API:

```bash
curl -s -c cookies.txt -X POST http://127.0.0.1:5000/webui/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"YOUR_PASS"}'

# Use the cookie for subsequent requests
curl -b cookies.txt http://127.0.0.1:5000/list
```

> **Rate limiting:** After 3 failed login attempts, the IP is locked out for 5 minutes.  
> **Single session:** Only one active session per account is allowed at a time.

### View-only Access

Unauthenticated users who open the Web UI can **view** torrent status but cannot add, pause, stop, or remove torrents.

### User Management

Admins can create regular user accounts with individually selectable permissions:

```bash
# Create a user with default permissions
curl -H "Lime-API-Key: ADMIN_KEY" -X POST http://127.0.0.1:5000/users \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"secret"}'

# Create a user with specific permissions only
curl -H "Lime-API-Key: ADMIN_KEY" -X POST http://127.0.0.1:5000/users \
  -H "Content-Type: application/json" \
  -d '{"username":"bob","password":"secret","permissions":["add_torrent","pause_torrent"]}'

# Update permissions
curl -H "Lime-API-Key: ADMIN_KEY" -X PUT http://127.0.0.1:5000/users/bob/permissions \
  -H "Content-Type: application/json" \
  -d '{"permissions":["add_torrent","pause_torrent","stop_torrent"]}'
```

**Available permissions:**

| Permission | Description | Default for new users |
|---|---|---|
| `add_torrent` | Add new torrents (magnet / file / URL) | ✓ |
| `pause_torrent` | Pause and resume torrents | ✓ |
| `stop_torrent` | Stop torrents | ✓ |
| `create_torrent` | Create `.torrent` files from local data | ✓ |
| `set_limits` | Adjust speed limits | ✓ |
| `recheck` | Force piece recheck | ✓ |
| `announce` | Force re-announce to trackers | ✓ |
| `super_seed` | Toggle super-seeding per torrent | ✓ |
| `view_peers` | View connected peers | ✓ |
| `view_files` | View file list and priorities | ✓ |
| `download_file` | HTTP download completed files from server | ✗ |
| `set_post_cmd` | Set post-download run commands | ✗ |
| `delete_torrent` | Remove torrent metadata (no file deletion) | ✗ |
| `delete_torrent_data` | Remove torrent **and** delete files from disk | ✗ |

Delete permissions and `download_file` are **off by default** for new users. Only admins can grant them.

### Admin Credentials (RAM-only)

The admin account is special: its password, username, and API key are **never written to any file**.  
They exist in RAM only and are reconstructed from CLI args / environment variables on every startup.  
Changing the admin password requires restarting with a new `--webui-pass` (or `WEBUI_PASS` env var).

If you lose the credentials, visit `GET /info` (no authentication required) to retrieve the current runtime values.

---

## REST API Overview

Full interactive documentation is available at **`http://127.0.0.1:5000/doc`** when the server is running.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/add/magnet` | Add torrent via magnet link |
| `POST` | `/add/file` | Add torrent via `.torrent` file upload |
| `POST` | `/add/url` | Add torrent via direct `.torrent` URL |
| `GET` | `/list` | List all torrents |
| `GET` | `/status/{hash}` | Status of a single torrent |
| `GET` | `/files/{hash}` | List files and priorities |
| `POST` | `/files/{hash}` | Set per-file download priorities |
| `GET` | `/peers/{hash}` | List connected peers |
| `GET` | `/trackers/{hash}` | List tracker URLs and status |
| `GET` | `/magnet/{hash}` | Get magnet URI |
| `POST` | `/pause/{hash}` | Pause torrent |
| `POST` | `/resume/{hash}` | Resume torrent |
| `POST` | `/stop/{hash}` | Stop torrent |
| `POST` | `/stop/file` | Stop torrent by `.torrent` file upload |
| `DELETE` | `/remove/{hash}` | Remove torrent (`?delete_files=1` to wipe data) |
| `DELETE` | `/remove/file` | Remove torrent by `.torrent` file upload |
| `POST` | `/recheck/{hash}` | Force piece recheck |
| `POST` | `/announce/{hash}` | Force re-announce to trackers |
| `POST` | `/limit/{hash}` | Per-torrent speed limits |
| `POST` | `/limit/global` | Global speed limits |
| `POST` | `/super_seed/{hash}` | Toggle super-seeding per torrent |
| `POST` | `/super_seed/global` | Toggle global super-seeding |
| `POST` | `/create` | Create `.torrent` from local path; `name` sets the output `.torrent` filename only; `trackers`, `web_seeds` (BEP-19/17), `comment`, `private`, `auto_seed` (admin only) |
| `POST` | `/seed` | Seed existing local data |
| `GET` | `/stats/global` | Session + all-time stats |
| `POST` | `/save` | Persist resume data to disk now |
| `GET/POST` | `/autosave/interval` | Get or set autosave interval |
| `GET` | `/health` | Health check |
| `GET` | `/info` | Runtime credentials dump _(no auth required)_ |
| `GET` | `/download/torrent/{hash}` | Download `.torrent` metadata file |
| `GET` | `/download/file/{api_key}/{hash}/{path}` | Download completed file |
| `GET/POST` | `/postcmd/global` | Get or set global post-download command |
| `GET/POST` | `/postcmd/{hash}` | Get or set per-torrent post-download command |
| `GET` | `/settings/http-download` | Get HTTP download enabled state |
| `POST` | `/settings/http-download` | Enable/disable HTTP download _(admin only)_ |
| `GET/POST` | `/settings/download_dir` | Get or change download directory |
| `GET` | `/api/key` | Get API key info — admin gets global key, non-admin gets own key list _(session required)_ |
| `POST` | `/api/key/toggle` | Enable/disable API key auth _(admin only)_ |
| `GET` | `/api/keys/me` | List own API keys with full values _(session required)_ |
| `POST` | `/api/keys/me` | **Disabled** — always returns 403; keys are auto-issued at account creation |
| `DELETE` | `/api/keys/me/{index}` | Revoke own API key by index _(non-admin only)_ |
| `GET` | `/users` | List all users _(admin only)_ |
| `POST` | `/users` | Create a new regular user _(admin only)_ |
| `GET` | `/users/{username}` | Get user details _(admin only)_ |
| `PUT` | `/users/{username}/permissions` | Update user permissions _(admin only)_ |
| `PUT` | `/users/{username}/password` | Change another user's password _(admin only)_ |
| `DELETE` | `/users/{username}` | Delete a user _(admin only)_ |
| `POST` | `/users/{username}/kick` | Force-logout a user _(admin only)_ |
| `POST` | `/users/kick_all` | Force-logout all non-admin users _(admin only)_ |
| `POST` | `/users/{username}/api_key` | Generate API key for a user _(admin only)_ |
| `GET` | `/users/me/permissions` | Get calling user's permissions |
| `PUT` | `/users/me/password` | Change your own password |
| `GET` | `/logs/webui` | Fetch activity log (filtered per role) |
| `POST` | `/admin/delete_logs` | Delete all log files _(admin only)_ |
| `POST` | `/admin/reset_app_data` | Reset all app data _(admin only — irreversible)_ |
| `GET` | `/webui` | Web UI (browser) |
| `GET` | `/doc` | API documentation |

---

## State Model

| State | Description |
|-------|-------------|
| `downloading` | Actively downloading; progress < 100% |
| `seeding` | Download complete; actively uploading to peers |
| `paused` | Temporarily paused; can auto-resume |
| `stopped` | Explicitly stopped (`auto_managed=off`); progress < 100% |
| `completed` | Explicitly stopped after finishing download |
| `checking` | Running piece verification |
| `metadata` | Fetching torrent metadata (magnet link, no info-hash yet) |

---

## Resume Persistence

LimeTorrent saves **resume data** to disk so torrents survive server restarts.

- Resume files are stored in `RESUME_DIR`
  - Linux default: `~/.local/share/.limetorrent/resume/`
  - Windows default: `%APPDATA%\.limetorrent\resume\`
- Each torrent gets a `<infohash>.resume` file and, if completed, a `<infohash>.completed` marker
- On startup, torrents in `stopped`, `paused`, or `downloading` state are automatically **rechecked** to verify on-disk data integrity
- Torrents already `seeding` or `completed` skip recheck (already verified)

**Transferring torrents to another machine:**

1. Copy the downloaded data folder to the same path on the new machine
2. Copy the corresponding `.resume` file from `RESUME_DIR` to the new instance's `RESUME_DIR`
3. Start LimeTorrent — it will recheck and resume from where it left off

---

## Web Seeds (`/create`)

LimeTorrent supports embedding web seed sources directly into created `.torrent` files.
Two BitTorrent web seed protocols are supported:

| Protocol | BEP | `type` value | Notes |
|---|---|---|---|
| HTTP url_seed | [BEP-19](https://www.bittorrent.org/beps/bep_0019.html) | `url_seed` | Default — modern clients, recommended |
| HTTP http_seed | [BEP-17](https://www.bittorrent.org/beps/bep_0017.html) | `http_seed` | Legacy protocol, still widely supported |

### `web_seeds` field formats

```json
// Plain string — automatically treated as url_seed (BEP-19)
"web_seeds": [
  "https://mirror1.example.com/MyContent/",
  "https://mirror2.example.com/MyContent/"
]

// Object with explicit type
"web_seeds": [
  {"url": "https://mirror1.example.com/MyContent/", "type": "url_seed"},
  {"url": "https://legacy.example.com/MyContent/",  "type": "http_seed"}
]

// Mixed — plain strings and objects in the same array
"web_seeds": [
  "https://mirror1.example.com/MyContent/",
  {"url": "https://cdn.example.com/MyContent/",    "type": "url_seed"},
  {"url": "https://legacy.example.com/MyContent/", "type": "http_seed"}
]

// Single URL shorthand — always url_seed (BEP-19)
"web_seed": "https://mirror.example.com/MyContent/"
```

### Validation rules

- URL **must** start with `http://` or `https://` — others are silently skipped
- Invalid URLs do **not** fail the request — they are reported in the response header
- Unknown `type` values fall back to `url_seed`

### Response headers

| Header | Present when |
|---|---|
| `X-LimeTorrent-WebSeeds` | At least one valid web seed was added — comma-separated URLs |
| `X-LimeTorrent-WebSeedErrors` | At least one URL was invalid — semicolon-separated error messages |

### Full example

```json
POST /create
{
  "path": "/data/MyContent",
  "name": "My Release",
  "trackers": [
    "udp://tracker.opentrackr.org:1337/announce"
  ],
  "web_seeds": [
    "https://mirror1.example.com/MyContent/",
    {"url": "https://mirror2.example.com/MyContent/", "type": "url_seed"},
    {"url": "https://legacy.example.com/MyContent/",  "type": "http_seed"}
  ],
  "comment": "My release",
  "private": false,
  "auto_seed": true
}
```

---

## Post-Download Commands

LimeTorrent can execute a shell command automatically when a torrent finishes downloading.

**Global command** (runs for all torrents unless overridden):

```bash
LimeTorrent --post-cmd '/scripts/notify.sh "$TORRENT_NAME"' --post-cmd-run-as ubuntu
```

Or via the API / WebUI Settings:

```bash
curl -X POST http://127.0.0.1:5000/postcmd/global \
  -H "Lime-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"command":"/scripts/notify.sh","run_as":"ubuntu"}'
```

**Per-torrent command** (overrides the global command for that torrent):

```bash
curl -X POST http://127.0.0.1:5000/postcmd/INFOHASH \
  -H "Lime-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"command":"./per-torrent.sh","run_as":""}'
```

**Environment variables available inside the command:**

**Torrent-level** (always available):

| Variable | Description |
|---|---|
| `TORRENT_HASH` | Info hash of the finished torrent (40-char hex) |
| `TORRENT_NAME` | Torrent display name |
| `TORRENT_SAVE_PATH` | Absolute path to the download destination directory |
| `TORRENT_SIZE` | Total torrent size in bytes |
| `TORRENT_FILE_COUNT` | Number of files inside the torrent |
| `LIME_API_KEY` | Current admin API key — use this to call the REST API from within the script without hard-coding credentials (matches `API_KEY` env var or auto-generated value) |
| `LIME_API_ENDPOINT` | Base URL of this LimeTorrent instance (e.g. `http://127.0.0.1:5000`) — combine with `LIME_API_KEY` to make API calls from the script |

**Per-file** — indexed with `_i` suffix (zero-based, from `0` to `TORRENT_FILE_COUNT - 1`):

| Variable | Description |
|---|---|
| `TORRENT_LISTFILE_NAME_i` | Relative path of file *i* inside the torrent (from the torrent root) |
| `TORRENT_LISTFILE_PATH_i` | Absolute path of file *i* on disk (`TORRENT_SAVE_PATH + "/" + TORRENT_LISTFILE_NAME_i`) |
| `TORRENT_LISTFILE_SIZE_i` | Size of file *i* in bytes |

> **Bash:** Variable names use underscore indexing — accessible directly or via indirect expansion in loops:
> ```bash
> # Direct access (single file):
> echo "$TORRENT_LISTFILE_PATH_0"
>
> # In a loop:
> for (( i=0; i<TORRENT_FILE_COUNT; i++ )); do
>     path_var="TORRENT_LISTFILE_PATH_${i}"
>     echo "${!path_var}"
> done
> ```
> **Windows (CMD):** Use delayed expansion in loops:
> ```bat
> for /l %%i in (0,1,!LAST!) do (
>     echo !TORRENT_LISTFILE_PATH_%%i!
> )
> ```

- Commands run in a shell (`sh -c` / `cmd /c`) with a **5-minute timeout**
- `run_as` uses `setuid` to drop privileges — only works when LimeTorrent runs as root/sudo (Linux/macOS only; ignored on Windows)
- Each torrent fires its command **at most once per process lifetime** — fired state is RAM-only and resets on restart
- Clear a command by sending `{"command": ""}` to its endpoint
- `LIME_API_KEY` and `LIME_API_ENDPOINT` are always injected — use them to call the REST API from your script:

```bash
# Example: stop the torrent and send a notification after processing
curl -s -X POST "$LIME_API_ENDPOINT/stop/$TORRENT_HASH" \
  -H "Lime-API-Key: $LIME_API_KEY"
```

To keep the API key stable across restarts (recommended for post-cmd scripts), set `API_KEY` before starting LimeTorrent:

```bash
API_KEY=mysecretkey LimeTorrent --webui-pass mysecret
```

---

## HTTP File Download

When enabled (default), LimeTorrent can serve completed files directly over HTTP.

**Download a completed file:**

```bash
# URL format: /download/file/<API_KEY>/<hash>/<path/to/file>
curl -O "http://127.0.0.1:5000/download/file/YOUR_API_KEY/INFOHASH/MyMovie.mkv"
```

**Download the `.torrent` metadata file:**

```bash
curl -O "http://127.0.0.1:5000/download/torrent/INFOHASH" \
  -H "Lime-API-Key: YOUR_API_KEY"
```

Requirements for file download:
- HTTP download must be enabled server-wide (default: on; toggle with `--no-http-download` or via API)
- The requesting user/API key must have the `download_file` permission
- The file must be 100% downloaded (progress = 100%)

Admins can disable HTTP download at runtime via **Settings → Enable HTTP file download** or:

```bash
curl -X POST http://127.0.0.1:5000/settings/http-download \
  -H "Lime-API-Key: ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}'
```

---

## Logging

LimeTorrent writes three separate log files under the config directory (`logs/`):

| File | Contains |
|---|---|
| `logs/limelog_<timestamp>.log` | All events — startup, internal, and all user actions |
| `logs/admin.log` | User-initiated actions only (what the admin sees in WebUI) |
| `logs/users/<username>.log` | Actions by that specific user only |

In the WebUI (Logs page), regular users see only their own activity; admins see the combined log.  
Both the live in-memory buffer and the on-disk log files are accessible via `GET /logs/webui?source=buffer|file`.

Admins can delete all logs via **Settings → Data Manager → Delete Logs** or `POST /admin/delete_logs`.

---

## Data Directories

All persistent data is stored in a platform-specific config directory:

| Platform | Config Directory |
|---|---|
| **Linux / macOS** | `~/.local/share/.limetorrent/` (respects `XDG_DATA_HOME`) |
| **Windows** | `%APPDATA%\.limetorrent\` |

| Subdirectory / File | Contents |
|---|---|
| `resume/` | Per-torrent resume data (`<hash>.resume`, `<hash>.completed`) |
| `created/` | `.torrent` files created by the server |
| `logs/` | Application, admin, and per-user log files |
| `users.json` | Non-admin user accounts and permissions (admin is never written here) |
| `_stats.json` | All-time cumulative upload/download statistics |
| _(post-cmd config)_ | Post-download commands are **RAM-only** — not stored on disk; cleared on restart |

---

## Running as a Service (systemd)

To run LimeTorrent automatically on boot on Linux:

**1. Create a systemd unit file**

```bash
sudo nano /etc/systemd/system/limetorrent.service
```

```ini
[Unit]
Description=LimeTorrent - Torrent Server
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
ExecStart=/usr/local/bin/LimeTorrent \
  --host 0.0.0.0 \
  --port 5000 \
  --download-dir /data/torrents \
  --webui-pass YOUR_SECURE_PASSWORD
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**2. Enable and start**

```bash
sudo systemctl daemon-reload
sudo systemctl enable limetorrent
sudo systemctl start limetorrent

# Check status
sudo systemctl status limetorrent

# View logs
sudo journalctl -u limetorrent -f
```

**3. (Optional) Open the firewall port**

```bash
sudo ufw allow 5000/tcp
```

---

## FAQ

**Which binary should I download?**

| OS | Architecture | Binary |
|---|---|---|
| Linux (most desktops/servers) | x86-64 | `LimeTorrent-linux-amd64` |
| Linux (Raspberry Pi 3/4/5, ARM servers) | AArch64 | `LimeTorrent-linux-arm64` |
| Windows 10/11 | x86-64 | `LimeTorrent-windows-amd64.exe` |

**How do I check my architecture?**

```bash
# Linux
uname -m
# x86_64  → use linux-amd64
# aarch64 → use linux-arm64
```

**Windows Defender blocks the exe. What do I do?**  
Click **"More info" → "Run anyway"** in the SmartScreen dialog. The binary is not code-signed, but the source code is fully available in this repository for review.

**I cleared the terminal and lost my credentials. What do I do?**  
Visit `http://127.0.0.1:5000/info` (no authentication required) — it prints the current runtime credentials (username, full password, full API key) and all directory paths **to the server console only**. The HTTP response only confirms they were printed. Firewall this endpoint in production if LimeTorrent is exposed to an untrusted network.

**How do I change the admin password?**  
The admin password is runtime-only — it is never stored on disk. To change it, restart LimeTorrent with `--webui-pass NEW_PASSWORD` or set the `WEBUI_PASS` environment variable. Non-admin user passwords can be changed via `PUT /users/me/password` or by the admin via `PUT /users/<username>/password`.

**Where are config files stored?**
- Linux/macOS: `~/.local/share/.limetorrent/` (respects `$XDG_DATA_HOME`)
- Windows: `%APPDATA%\.limetorrent\`

Only non-admin user accounts (`users.json`), torrent stats (`_stats.json`), log files, and resume data are stored there. Admin credentials are never written to any file.

**Can a regular user delete torrents?**  
Only if the admin has granted them the `delete_torrent` (remove metadata) or `delete_torrent_data` (remove metadata + delete files) permission. Both are disabled by default for new users.

**Can I run multiple instances?**  
Yes — use different `--port` and `--download-dir` values for each instance. Each instance will automatically create its own config directory based on the process's environment.

**How do I run LimeTorrent as a different user for post-download commands?**  
Use `--post-cmd-run-as USERNAME` (Linux/macOS only). LimeTorrent must be running as root or sudo for privilege dropping to work. Windows does not support `run_as`.

---

<div align="center">

Built with ❤️ using [libtorrent](https://libtorrent.org) + [Flask](https://flask.palletsprojects.com)

[GitHub](https://github.com/Limenime/LimeTorrent) · [Issues](https://github.com/Limenime/LimeTorrent/issues) · [Releases](https://github.com/Limenime/LimeTorrent/releases)

</div>