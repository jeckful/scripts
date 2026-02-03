# Discord Updater

Bash script to update Discord on Debian/Ubuntu systems using the official `.deb` package.

## Description

Checks for updates to Discord and installs the latest version when available. Works only with the `.deb` package version (not Snap/Flatpak).

## Usage

```bash
./discord_updater.sh
```

## What it does

1. Checks current Discord version
2. Downloads latest `.deb` from Discord's servers
3. Compares versions
4. If newer version exists, asks for confirmation and installs
5. Optionally launches Discord after update

## Requirements

- Debian/Ubuntu system
- `dpkg` and `apt` package managers
- `wget` for downloads
- sudo privileges

## Installation

```bash
chmod +x discord_updater.sh
sudo mv discord_updater.sh /usr/local/bin/discord-update
```