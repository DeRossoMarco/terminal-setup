#!/usr/bin/env bash

###############################################################################
# Terminal Setup Reset Script
# Removes managed configuration and restores previous backups when available.
# Usage: ./reset.sh [--yes] [--keep-packages]
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

AUTO_YES=false
KEEP_PACKAGES=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)
                AUTO_YES=true
                shift
                ;;
            --keep-packages)
                KEEP_PACKAGES=true
                shift
                ;;
            -h|--help)
                cat <<'EOF'
Usage: ./reset.sh [options]

Options:
  --yes, -y          Run non-interactively (skip confirmation)
  --keep-packages    Keep installed packages and only reset configuration files
  -h, --help         Show this help
EOF
                exit 0
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Unknown argument: $1"
                echo -e "${RED}[ERROR]${NC} Use --help to see supported options."
                exit 1
                ;;
        esac
    done
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

restore_latest_backup() {
    local target="$1"
    local latest_backup

    latest_backup=$(ls -1t "${target}".backup.* 2>/dev/null | head -n 1 || true)
    if [[ -n "$latest_backup" ]]; then
        cp "$latest_backup" "$target"
        print_success "Restored backup for $target"
        return 0
    fi

    return 1
}

remove_file_if_exists() {
    local file="$1"
    if [[ -e "$file" || -L "$file" ]]; then
        rm -f "$file"
        print_success "Removed $file"
    fi
}

clean_bashrc_managed_block_if_needed() {
    local bashrc="$HOME/.bashrc"

    if [[ ! -f "$bashrc" ]]; then
        return 0
    fi

    if ! grep -q "# Terminal Setup Configuration" "$bashrc"; then
        return 0
    fi

    cp "$bashrc" "$bashrc.reset.backup.$(date +%Y%m%d_%H%M%S)"
    awk 'BEGIN {stop=0} /^# Terminal Setup Configuration$/ {stop=1} stop==0 {print}' "$bashrc" > "$bashrc.tmp"
    mv "$bashrc.tmp" "$bashrc"
    print_success "Removed managed block from $bashrc"
}

remove_starship_init_lines() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 0
    fi

    cp "$file" "$file.reset.backup.$(date +%Y%m%d_%H%M%S)"

    # Remove both managed block and one-line legacy init entries if present.
    sed -i.bak \
        -e '/if command -v starship .*; then/,/^[[:space:]]*fi$/d' \
        -e '/^eval "$(starship init zsh)"$/d' \
        -e '/^eval "$(starship init bash)"$/d' \
        "$file"

    rm -f "$file.bak"
}

sanitize_zshrc_optional_tools() {
    local zshrc="$HOME/.zshrc"

    if [[ ! -f "$zshrc" ]]; then
        return 0
    fi

    cp "$zshrc" "$zshrc.reset.backup.$(date +%Y%m%d_%H%M%S)"

    # Make optional integrations safe when tools/plugins are not installed.
    sed -i.bak \
        -e 's|^eval "$(starship init zsh)"$|if command -v starship >/dev/null 2>\&1; then\n  eval "$(starship init zsh)"\nfi|' \
        -e 's|^eval "$(zoxide init zsh)"$|if command -v zoxide >/dev/null 2>\&1; then\n  eval "$(zoxide init zsh)"\nfi|' \
        -e 's|^source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh$|[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] \&\& source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh|' \
        -e 's|^source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh$|[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] \&\& source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh|' \
        "$zshrc"

    rm -f "$zshrc.bak"
}

remove_starship_config() {
    local starship_config="$HOME/.config/starship.toml"

    if ! restore_latest_backup "$starship_config"; then
        remove_file_if_exists "$starship_config"
    fi
}

remove_setup_configs() {
    print_info "Removing managed tmux/btop configuration..."

    remove_file_if_exists "$HOME/.config/tmux/tmux.conf"
    remove_file_if_exists "$HOME/.config/tmux/tmux.conf.local"

    # Remove symlinks created by install.sh and restore backups when possible.
    if [[ -L "$HOME/.tmux.conf" ]]; then
        rm -f "$HOME/.tmux.conf"
        print_success "Removed symlink $HOME/.tmux.conf"
    fi
    restore_latest_backup "$HOME/.tmux.conf" || true

    if [[ -L "$HOME/.tmux.conf.local" ]]; then
        rm -f "$HOME/.tmux.conf.local"
        print_success "Removed symlink $HOME/.tmux.conf.local"
    fi
    restore_latest_backup "$HOME/.tmux.conf.local" || true

    if [[ -d "$HOME/.config/tmux" ]] && [[ -z "$(ls -A "$HOME/.config/tmux")" ]]; then
        rmdir "$HOME/.config/tmux"
        print_success "Removed empty directory $HOME/.config/tmux"
    fi

    if [[ -d "$HOME/.config/btop" ]]; then
        rm -rf "$HOME/.config/btop"
        print_success "Removed $HOME/.config/btop"
    fi

    # Linux plugin folders cloned by install.sh
    if [[ -d "$HOME/.zsh/zsh-autosuggestions" ]]; then
        rm -rf "$HOME/.zsh/zsh-autosuggestions"
        print_success "Removed $HOME/.zsh/zsh-autosuggestions"
    fi
    if [[ -d "$HOME/.zsh/zsh-syntax-highlighting" ]]; then
        rm -rf "$HOME/.zsh/zsh-syntax-highlighting"
        print_success "Removed $HOME/.zsh/zsh-syntax-highlighting"
    fi
    if [[ -d "$HOME/.zsh/zsh-history-substring-search" ]]; then
        rm -rf "$HOME/.zsh/zsh-history-substring-search"
        print_success "Removed $HOME/.zsh/zsh-history-substring-search"
    fi

    # Linux Nerd Font installed by install.sh
    if [[ -d "$HOME/.local/share/fonts/NerdFonts/Hack" ]]; then
        rm -rf "$HOME/.local/share/fonts/NerdFonts/Hack"
        print_success "Removed $HOME/.local/share/fonts/NerdFonts/Hack"
        if command_exists fc-cache; then
            fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
        fi
    fi
}

uninstall_brew_packages() {
    if ! command_exists brew; then
        print_info "Homebrew not found, skipping package removal"
        return 0
    fi

    print_info "Removing Homebrew packages installed by terminal-setup..."

    local formulas=(
        "tmux"
        "btop"
        "starship"
        "gh"
        "fzf"
        "ripgrep"
        "bat"
        "eza"
        "zoxide"
        "neovim"
        "git"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "zsh-history-substring-search"
    )

    local casks=(
        "font-hack-nerd-font"
    )

    local pkg
    for pkg in "${formulas[@]}"; do
        if brew list --formula "$pkg" >/dev/null 2>&1; then
            if brew uninstall --formula "$pkg"; then
                print_success "Uninstalled brew formula: $pkg"
            else
                print_warning "Could not uninstall brew formula: $pkg"
            fi
        fi
    done

    for pkg in "${casks[@]}"; do
        if brew list --cask "$pkg" >/dev/null 2>&1; then
            if brew uninstall --cask "$pkg"; then
                print_success "Uninstalled brew cask: $pkg"
            else
                print_warning "Could not uninstall brew cask: $pkg"
            fi
        fi
    done

    print_info "Homebrew itself was not removed"
}

uninstall_linux_packages() {
    if [[ "${OSTYPE}" != linux* ]]; then
        return 0
    fi

    print_info "Removing Linux packages installed by terminal-setup..."

    local packages=(
        "tmux"
        "btop"
        "starship"
        "gh"
        "fzf"
        "ripgrep"
        "bat"
        "eza"
        "zoxide"
        "neovim"
        "git"
        "zsh"
    )

    local pkg
    local installed=()

    if command_exists apt-get; then
        for pkg in "${packages[@]}"; do
            if dpkg -s "$pkg" >/dev/null 2>&1; then
                installed+=("$pkg")
            fi
        done

        if [[ ${#installed[@]} -gt 0 ]]; then
            sudo apt-get remove -y "${installed[@]}" || print_warning "Some apt packages could not be removed"
            sudo apt-get autoremove -y || true
        fi

        if [[ -f /etc/apt/sources.list.d/github-cli.list ]]; then
            sudo rm -f /etc/apt/sources.list.d/github-cli.list
            print_success "Removed /etc/apt/sources.list.d/github-cli.list"
        fi
        if [[ -f /usr/share/keyrings/githubcli-archive-keyring.gpg ]]; then
            sudo rm -f /usr/share/keyrings/githubcli-archive-keyring.gpg
            print_success "Removed /usr/share/keyrings/githubcli-archive-keyring.gpg"
        fi
        sudo apt-get update || true
    elif command_exists dnf; then
        for pkg in "${packages[@]}"; do
            if rpm -q "$pkg" >/dev/null 2>&1; then
                installed+=("$pkg")
            fi
        done

        if [[ ${#installed[@]} -gt 0 ]]; then
            sudo dnf remove -y "${installed[@]}" || print_warning "Some dnf packages could not be removed"
        fi

        if [[ -f /etc/yum.repos.d/github-cli.repo ]]; then
            sudo rm -f /etc/yum.repos.d/github-cli.repo
            print_success "Removed /etc/yum.repos.d/github-cli.repo"
        fi
    elif command_exists yum; then
        for pkg in "${packages[@]}"; do
            if rpm -q "$pkg" >/dev/null 2>&1; then
                installed+=("$pkg")
            fi
        done

        if [[ ${#installed[@]} -gt 0 ]]; then
            sudo yum remove -y "${installed[@]}" || print_warning "Some yum packages could not be removed"
        fi

        if [[ -f /etc/yum.repos.d/github-cli.repo ]]; then
            sudo rm -f /etc/yum.repos.d/github-cli.repo
            print_success "Removed /etc/yum.repos.d/github-cli.repo"
        fi
    else
        print_warning "No supported Linux package manager found (apt/dnf/yum)"
    fi

    if [[ -x /usr/local/bin/starship ]]; then
        sudo rm -f /usr/local/bin/starship || print_warning "Could not remove /usr/local/bin/starship"
        print_success "Removed /usr/local/bin/starship"
    fi
}

restore_shell_configs() {
    print_info "Restoring shell configuration..."

    if ! restore_latest_backup "$HOME/.zshrc"; then
        if [[ -f "$HOME/.zshrc" ]] && grep -q "Terminal Setup Configuration" "$HOME/.zshrc"; then
            rm -f "$HOME/.zshrc"
            print_success "Removed managed $HOME/.zshrc"
        fi
    fi

    if ! restore_latest_backup "$HOME/.bashrc"; then
        clean_bashrc_managed_block_if_needed
    fi

    remove_starship_init_lines "$HOME/.zshrc"
    remove_starship_init_lines "$HOME/.bashrc"
}

confirm_reset() {
    if [[ "$AUTO_YES" == true ]]; then
        return 0
    fi

    echo ""
    print_warning "This will remove terminal-setup managed config and try to restore previous backups."
    if [[ "$KEEP_PACKAGES" == true ]]; then
        print_warning "Installed packages will be kept; only configuration files are reset."
    else
        print_warning "It also uninstalls related packages (Homebrew on macOS, apt/dnf/yum on Linux)."
    fi
    print_warning "It does not reset global Git settings."
    echo ""
    read -r -p "Continue? (y/N): " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

main() {
    parse_args "$@"

    print_info "Starting terminal setup reset..."

    if ! confirm_reset; then
        print_info "Reset cancelled."
        exit 0
    fi

    if [[ "$KEEP_PACKAGES" != true ]]; then
        uninstall_brew_packages
        uninstall_linux_packages
    else
        print_info "Skipping package uninstallation (--keep-packages enabled)"
    fi
    restore_shell_configs
    sanitize_zshrc_optional_tools
    remove_starship_config
    remove_setup_configs

    echo ""
    print_success "Reset complete."
    print_info "Open a new terminal session to apply changes."
}

main "$@"
