#!/bin/bash
# Dotfiles Synchronization Script
# A tool to manage and synchronize dotfiles across multiple machines using Git

set -e
shopt -s nullglob

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANCH="main"

backup_file() {
    local file="$1"
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup="${file}.backup_${timestamp}"
        echo "Backup: $file -> $backup"
        mv "$file" "$backup"
    fi
}

collect_files() {
    echo "Collecting current files..."
    
    # Customize this list with your configuration files
    config_files=(
        ".bashrc"
        ".bash_aliases"
        ".vimrc"
        ".gitconfig"
        ".nanorc"
        ".inputrc"
        ".hushlogin"
    )
    
    echo "Collecting configuration files..."
    for config in "${config_files[@]}"; do
        src_file="$HOME/$config"
        dest_file="$DOTFILES_DIR/configs/$config"
        
        if [ -f "$src_file" ] || [ -L "$src_file" ]; then
            if [ -L "$src_file" ] && [ "$(readlink -f "$src_file")" = "$(readlink -f "$dest_file")" ]; then
                echo "  Skipping $config (already linked to dotfiles)"
            else
                if [ -L "$src_file" ]; then
                    cp -L "$src_file" "$dest_file"
                else
                    cp "$src_file" "$dest_file"
                fi
                echo "  Copied: $config"
            fi
        else
            echo "  Not found: $config"
        fi
    done
    
    echo "Collecting personal scripts from ~/bin..."
    mkdir -p "$DOTFILES_DIR/scripts"
    
    # Customize with your preferred script extensions
    script_extensions=("sh" "py" "bash" "zsh" "pl" "rb" "js" "php" "r" "jl")
    
    if [ -d "$HOME/bin" ]; then
        for script in "$HOME/bin"/*; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                extension="${script_name##*.}"
                
                if [[ " ${script_extensions[@]} " =~ " ${extension} " ]]; then
                    if [ -L "$script" ]; then
                        if [[ "$(readlink -f "$script")" == "$DOTFILES_DIR/scripts/"* ]]; then
                            echo "  Skipping $script_name (already linked to dotfiles)"
                        else
                            cp -L "$script" "$DOTFILES_DIR/scripts/$script_name"
                            chmod +x "$DOTFILES_DIR/scripts/$script_name"
                            echo "  Copied: $script_name"
                        fi
                    else
                        cp "$script" "$DOTFILES_DIR/scripts/"
                        chmod +x "$DOTFILES_DIR/scripts/$script_name"
                        echo "  Copied: $script_name"
                    fi
                fi
            fi
        done
    fi
    
    # Collect package list (Debian/Ubuntu systems only)
    if [ -z "$WSL_DISTRO_NAME" ] && command -v dpkg >/dev/null 2>&1; then
        echo "Collecting package list..."
        dpkg --get-selections > "$DOTFILES_DIR/packages.list" 2>/dev/null || true
    fi
    
    # Optional: Collect SSH configurations
    if [ -d "$HOME/.ssh" ]; then
        echo "Collecting SSH configs..."
        mkdir -p "$DOTFILES_DIR/configs/ssh"
        [ -f "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ] && cp "$HOME/.ssh/config" "$DOTFILES_DIR/configs/ssh/config"
        [ -f "$HOME/.ssh/authorized_keys" ] && [ ! -L "$HOME/.ssh/authorized_keys" ] && cp "$HOME/.ssh/authorized_keys" "$DOTFILES_DIR/configs/ssh/authorized_keys"
    fi
    
    echo "Collection complete."
}

link_configs() {
    echo "Linking configuration files..."
    
    # Must match the list in collect_files
    config_files=(
        ".bashrc"
        ".bash_aliases"
        ".vimrc"
        ".gitconfig"
        ".nanorc"
        ".inputrc"
        ".hushlogin"
    )
    
    for config in "${config_files[@]}"; do
        if [ -f "$DOTFILES_DIR/configs/$config" ]; then
            backup_file "$HOME/$config"
            ln -sf "$DOTFILES_DIR/configs/$config" "$HOME/$config"
            echo "  $config"
        fi
    done
    
    # Optional: Link SSH config
    if [ -f "$DOTFILES_DIR/configs/ssh/config" ]; then
        mkdir -p "$HOME/.ssh"
        backup_file "$HOME/.ssh/config"
        ln -sf "$DOTFILES_DIR/configs/ssh/config" "$HOME/.ssh/config"
        echo "  .ssh/config"
    fi
    
    echo "Configuration files linked."
}

link_scripts() {
    echo "Linking scripts to ~/bin..."
    
    mkdir -p ~/bin
    
    if [ -d "$DOTFILES_DIR/scripts" ]; then
        for script in "$DOTFILES_DIR/scripts/"*; do
            [ -e "$script" ] || continue
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                # Remove .sh extension for cleaner executable names
                if [[ "$script_name" == *.sh ]]; then
                    link_name="${script_name%.*}"
                else
                    link_name="$script_name"
                fi
                backup_file "$HOME/bin/$link_name"
                ln -sf "$script" "$HOME/bin/$link_name"
                echo "  Linked: $script_name -> ~/bin/$link_name"
            fi
        done
    else
        echo "  No scripts directory found"
    fi
    
    echo "Scripts linked."
}

pull_changes() {
    echo "Pulling latest changes from remote..."
    cd "$DOTFILES_DIR"
    
    if git pull origin "$BRANCH"; then
        echo "Pull successful"
        link_configs
        link_scripts
    else
        echo "Warning: Git pull failed, using local files"
        link_configs
        link_scripts
    fi
}

push_changes() {
    echo "Pushing local changes to remote..."
    cd "$DOTFILES_DIR"
    
    if [ -z "$(git status --porcelain)" ]; then
        echo "No changes to push"
        return
    fi
    
    git add .
    git commit -m "Update dotfiles: $(date +'%Y-%m-%d %H:%M')"
    
    if git push origin "$BRANCH"; then
        echo "Push successful"
    else
        echo "Push failed"
        return 1
    fi
}

setup_new_machine() {
    echo "Setting up new machine..."
    
    # Add ~/bin to PATH if not already present
    if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
        echo "Added ~/bin to PATH in .bashrc"
    fi
    
    link_configs
    link_scripts
    
    echo ""
    echo "Setup complete."
    echo "Next steps:"
    echo "  1. Run: source ~/.bashrc"
    echo "  2. Review packages.list for package installation"
    echo "  3. Customize configuration files as needed"
    echo ""
}

case "$1" in
    collect)
        collect_files
        ;;
    pull)
        pull_changes
        ;;
    push)
        push_changes
        ;;
    setup)
        setup_new_machine
        ;;
    sync)
        echo "Starting full synchronization..."
        pull_changes
        echo ""
        push_changes
        echo "Synchronization complete."
        ;;
    help|--help|-h)
        echo "Dotfiles Sync Script - Help"
        echo "==========================="
        echo "Usage: $0 {collect|pull|push|setup|sync|help}"
        echo ""
        echo "Commands:"
        echo "  collect  - Backup current configs and scripts to repository"
        echo "  pull     - Get latest changes from Git and apply them"
        echo "  push     - Send local changes to Git repository"
        echo "  setup    - Configure new machine (create symlinks)"
        echo "  sync     - Full sync: pull then push"
        echo "  help     - Show this help message"
        echo ""
        echo "Typical workflow:"
        echo "  1. On existing machine: ./sync.sh collect"
        echo "  2. Edit files in repository as needed"
        echo "  3. ./sync.sh push (to save to remote repository)"
        echo "  4. On new machine: git clone <repo> && cd dotfiles && ./sync.sh setup"
        echo ""
        echo "Customization:"
        echo "  - Edit config_files array for your configuration files"
        echo "  - Edit script_extensions array for script types to collect"
        echo "  - Review optional sections (SSH, package list) for your needs"
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo "Run: $0 help"
        exit 1
        ;;
esac