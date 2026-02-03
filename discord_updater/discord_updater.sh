#!/bin/bash
# Discord updater for Debian/Ubuntu (deb package version)

set -e

DISCORD_URL="https://discord.com/api/download?platform=linux&format=deb"
TEMP_FILE="/tmp/discord-latest.deb"

# Check if running on Debian/Ubuntu
if ! command -v dpkg &> /dev/null; then
    echo "Error: This script is for Debian/Ubuntu systems only"
    exit 1
fi

echo "=== Discord Updater ==="
echo

# Check current version
echo "Checking installed Discord version..."
INSTALLED_VERSION=$(dpkg -l discord 2>/dev/null | grep ^ii | awk '{print $3}' || echo "none")

if [ "$INSTALLED_VERSION" = "none" ]; then
    echo "Discord is not currently installed."
    INSTALLED_VERSION="not installed"
fi
echo "Installed version: $INSTALLED_VERSION"

# Download latest version
echo "Downloading latest Discord version..."
if ! wget -q --show-progress -O "$TEMP_FILE" "$DISCORD_URL"; then
    echo "Failed to download Discord"
    exit 1
fi

# Check downloaded version
NEW_VERSION=$(dpkg-deb -I "$TEMP_FILE" 2>/dev/null | grep Version | awk '{print $2}')
echo "Available version: $NEW_VERSION"

# Compare versions
if [ "$INSTALLED_VERSION" = "$NEW_VERSION" ]; then
    echo "Discord is already up to date"
    rm -f "$TEMP_FILE"
    exit 0
fi

# Ask for confirmation
read -p "Update Discord from $INSTALLED_VERSION to $NEW_VERSION? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "Update cancelled."
    rm -f "$TEMP_FILE"
    exit 0
fi

# Install new version
echo "Installing Discord $NEW_VERSION..."
if sudo dpkg -i "$TEMP_FILE"; then
    echo "Update successful"
    
    # Fix dependencies if needed
    if sudo apt-get -f install -y 2>/dev/null; then
        echo "Dependencies resolved."
    fi
    
    # Ask to launch Discord
    read -p "Launch Discord now? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        echo "Starting Discord..."
        discord &
    fi
else
    echo "Installation failed"
    exit 1
fi

# Cleanup
rm -f "$TEMP_FILE"
echo "Update complete."
