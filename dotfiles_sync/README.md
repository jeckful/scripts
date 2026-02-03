# Dotfiles Sync Template

A generic synchronization script for managing dotfiles across multiple machines using Git.

## Features

- **Symlink-based configuration** — Config files are linked to the repository, keeping everything in sync
- **Automatic backups** — Existing files are backed up with timestamps before being replaced
- **Smart detection** — Already-linked files are skipped during collection
- **Script management** — Personal scripts from `~/bin` are collected and deployed
- **SSH config support** — Safely syncs SSH configuration and authorized keys
- **Package tracking** — Maintains a list of installed packages (Debian/Ubuntu, non-WSL)

## Quick Start

```bash
# Download the template
curl -O https://raw.githubusercontent.com/jeckful/scripts/main/dotfiles_sync/sync_template.sh
chmod +x sync_template.sh

# On your primary machine: collect existing configs
./sync_template.sh collect

# Initialize git and push
git init && git add . && git commit -m "Initial dotfiles"
git remote add origin git@github.com:YOUR_USERNAME/dotfiles.git
git push -u origin main
```

## Commands

| Command | Description |
|---------|-------------|
| `collect` | Gather current configs and scripts from your system into the repo |
| `setup` | Initial setup on a new machine (creates symlinks, adds `~/bin` to PATH) |
| `pull` | Fetch latest changes from GitHub and apply symlinks |
| `push` | Commit and push local changes to GitHub |
| `sync` | Full sync: pull then push |
| `help` | Display help message |

## What Gets Synced

### Configuration Files
- `.bashrc`, `.bash_aliases`
- `.vimrc`, `.gitconfig`
- `.nanorc`, `.inputrc`, `.hushlogin`
- SSH config (`~/.ssh/config`, `~/.ssh/authorized_keys`)

### Scripts
Personal scripts from `~/bin` with extensions: `.sh`, `.py`, `.bash`, `.zsh`, `.pl`, `.rb`, `.js`, `.php`, `.r`, `.jl`

### System Information
Package list via `dpkg --get-selections` (Debian/Ubuntu only, disabled on WSL)

## Installation

### On Your Primary Machine

```bash
# Collect your current configuration
./sync_template.sh collect

# Initialize repository and push
git init
git add .
git commit -m "Initial dotfiles"
git remote add origin git@github.com:YOUR_USERNAME/dotfiles.git
git push -u origin main
```

### On a New Machine

```bash
# Clone and setup
git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./sync_template.sh setup
source ~/.bashrc
```

## Daily Workflow

```bash
# Get updates from other machines
./sync_template.sh pull

# Send your changes
./sync_template.sh push

# Or do both at once
./sync_template.sh sync
```

## Customization

Edit the script to customize:

- **`config_files` array** — Add or remove configuration files to sync
- **`script_extensions` array** — Change which script types are collected from `~/bin`
- **SSH section** — Enable/disable SSH config synchronization
- **Package list** — Add support for other package managers (pacman, dnf, etc.)

## Repository Structure

```
~/dotfiles/
├── sync_template.sh     # Main synchronization script
├── README.md
├── configs/
│   ├── .bashrc
│   ├── .bash_aliases
│   ├── .vimrc
│   ├── .gitconfig
│   ├── .nanorc
│   ├── .inputrc
│   ├── .hushlogin
│   └── ssh/
│       ├── config
│       └── authorized_keys
├── scripts/             # Personal scripts (deployed to ~/bin)
└── packages.list        # Installed packages snapshot
```

## Notes

- **Backups**: Existing files are saved as `filename.backup_YYYYMMDD_HHMMSS` before replacement
- **Symlink detection**: Files already linked to the dotfiles repo are skipped during collection
- **Script naming**: `.sh` extension is stripped when linking (e.g., `myscript.sh` → `~/bin/myscript`)
- **SSH safety**: Only `config` and `authorized_keys` are synced — private keys are never touched
- **WSL**: Package list collection is automatically disabled in WSL environments

## License

Public domain — use and modify freely.
