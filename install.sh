#!/usr/bin/env bash

###############################################################################
# Terminal Setup Script
# Installs and configures: tmux, zsh, btop, gh, and modern CLI tools
# Usage: curl -fsSL https://raw.githubusercontent.com/DeRossoMarco/terminal-setup/main/install.sh | bash
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CONFIG_DIR="$SCRIPT_DIR/configs"
CONFIG_DIR="$HOME/.config"

# Selection state
INTERACTIVE_MODE=false
TOOLS_ARG=""
EXCLUDE_TOOLS_ARG=""

ALL_TOOLS=(
    "shell"
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
    "git-config"
    "zsh"
    "zsh-plugins"
    "nerd-font"
)

DEFAULT_TOOLS=(
    "shell"
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
    "git-config"
    "zsh-plugins"
    "nerd-font"
)

SELECTED_TOOLS=()

###############################################################################
# Helper Functions
###############################################################################

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

contains_tool() {
    local needle="$1"
    local tool
    for tool in "${SELECTED_TOOLS[@]}"; do
        if [[ "$tool" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

is_valid_tool() {
    local needle="$1"
    local tool
    for tool in "${ALL_TOOLS[@]}"; do
        if [[ "$tool" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

add_tool() {
    local tool="$1"
    if ! contains_tool "$tool"; then
        SELECTED_TOOLS+=("$tool")
    fi
}

remove_tool() {
    local tool="$1"
    local updated=()
    local t
    for t in "${SELECTED_TOOLS[@]}"; do
        if [[ "$t" != "$tool" ]]; then
            updated+=("$t")
        fi
    done
    SELECTED_TOOLS=("${updated[@]}")
}

apply_csv_tools() {
    local csv="$1"
    local mode="$2" # set or exclude
    local raw
    local token

    raw="${csv// /}"
    IFS=',' read -r -a parsed <<< "$raw"

    if [[ "$mode" == "set" ]]; then
        SELECTED_TOOLS=()
    fi

    for token in "${parsed[@]}"; do
        [ -n "$token" ] || continue
        if ! is_valid_tool "$token"; then
            print_error "Unknown tool: $token"
            print_error "Use --help to see available tool names."
            exit 1
        fi

        if [[ "$mode" == "set" ]]; then
            add_tool "$token"
        else
            remove_tool "$token"
        fi
    done
}

resolve_tool_dependencies() {
    if contains_tool "git-config" && ! contains_tool "git"; then
        add_tool "git"
        print_info "Auto-enabled dependency: git (required by git-config)"
    fi

    if contains_tool "zsh-plugins" && ! contains_tool "git"; then
        add_tool "git"
        print_info "Auto-enabled dependency: git (required by zsh-plugins)"
    fi

    if [[ "$OS" == "linux" ]] && contains_tool "zsh-plugins" && ! contains_tool "zsh"; then
        add_tool "zsh"
        print_info "Auto-enabled dependency: zsh (required by zsh-plugins on Linux)"
    fi

    if [[ "$OS" != "macos" ]] && contains_tool "nerd-font"; then
        remove_tool "nerd-font"
        print_warning "Removed unsupported selection: nerd-font (macOS only in this script)"
    fi
}

print_selected_tools() {
    local out=""
    local tool
    for tool in "${SELECTED_TOOLS[@]}"; do
        if [ -z "$out" ]; then
            out="$tool"
        else
            out="$out, $tool"
        fi
    done
    print_info "Selected tools: ${out:-none}"
}

prompt_tool_selection() {
    local tool
    local answer
    local prompt

    print_info "Interactive selection mode"
    print_info "Choose tools to install/configure:"

    for tool in "${ALL_TOOLS[@]}"; do
        if [[ "$tool" == "nerd-font" && "$OS" != "macos" ]]; then
            continue
        fi

        if contains_tool "$tool"; then
            prompt="Install ${tool}? [Y/n]: "
            read -r -p "$prompt" answer
            if [[ "$answer" =~ ^[Nn]$ ]]; then
                remove_tool "$tool"
            fi
        else
            prompt="Install ${tool}? [y/N]: "
            read -r -p "$prompt" answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                add_tool "$tool"
            fi
        fi
    done
}

show_help() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --interactive                Prompt for each tool selection
  --tools <csv>                Install only the listed tools
  --exclude-tools <csv>        Remove listed tools from current selection
  -h, --help                   Show this help

Tool names:
  shell, tmux, btop, starship, gh, fzf, ripgrep, bat, eza, zoxide,
  neovim, git, git-config, zsh, zsh-plugins, nerd-font

Examples:
  ./install.sh --interactive
  ./install.sh --tools tmux,starship,git,shell
  ./install.sh --exclude-tools btop,gh
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            --tools)
                if [[ -z "${2:-}" ]]; then
                    print_error "--tools requires a comma-separated value"
                    exit 1
                fi
                TOOLS_ARG="$2"
                shift 2
                ;;
            --exclude-tools)
                if [[ -z "${2:-}" ]]; then
                    print_error "--exclude-tools requires a comma-separated value"
                    exit 1
                fi
                EXCLUDE_TOOLS_ARG="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown argument: $1"
                print_error "Use --help to see supported options."
                exit 1
                ;;
        esac
    done
}

prepare_tool_selection() {
    SELECTED_TOOLS=("${DEFAULT_TOOLS[@]}")

    if [[ -n "$TOOLS_ARG" ]]; then
        apply_csv_tools "$TOOLS_ARG" "set"
    fi

    if [[ -n "$EXCLUDE_TOOLS_ARG" ]]; then
        apply_csv_tools "$EXCLUDE_TOOLS_ARG" "exclude"
    fi

    if [[ "$INTERACTIVE_MODE" == true ]]; then
        prompt_tool_selection
    fi

    resolve_tool_dependencies
    print_selected_tools
}

###############################################################################
# OS Detection
###############################################################################

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_info "Detected macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        print_info "Detected Linux"
        
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
            print_info "Distribution: $DISTRO"
        fi
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

###############################################################################
# Package Manager Installation
###############################################################################

install_package_manager() {
    if [[ "$OS" == "macos" ]]; then
        if ! command_exists brew; then
            print_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH for Apple Silicon Macs
            if [[ $(uname -m) == "arm64" ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            
            print_success "Homebrew installed"
        else
            print_info "Homebrew already installed"
        fi
    elif [[ "$OS" == "linux" ]]; then
        print_info "Using system package manager"
    fi
}

###############################################################################
# Package Installation
###############################################################################

install_packages() {
    print_info "Installing packages..."
    
    if [[ "$OS" == "macos" ]]; then
        local packages=()

        contains_tool "tmux" && packages+=("tmux")
        contains_tool "btop" && packages+=("btop")
        contains_tool "starship" && packages+=("starship")
        contains_tool "gh" && packages+=("gh")
        contains_tool "fzf" && packages+=("fzf")
        contains_tool "ripgrep" && packages+=("ripgrep")
        contains_tool "bat" && packages+=("bat")
        contains_tool "eza" && packages+=("eza")
        contains_tool "zoxide" && packages+=("zoxide")
        contains_tool "neovim" && packages+=("neovim")
        contains_tool "git" && packages+=("git")
        contains_tool "zsh" && packages+=("zsh")

        if contains_tool "zsh-plugins"; then
            packages+=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-history-substring-search")
        fi

        if [[ ${#packages[@]} -gt 0 ]]; then
            brew update
        fi

        for package in "${packages[@]}"; do
            if ! brew list "$package" &>/dev/null; then
                print_info "Installing $package..."
                brew install "$package"
            else
                print_info "$package already installed"
            fi
        done

        if contains_tool "nerd-font"; then
            install_nerd_font_macos
        fi
        
    elif [[ "$OS" == "linux" ]]; then
        local packages=()

        contains_tool "tmux" && packages+=("tmux")
        contains_tool "zsh" && packages+=("zsh")
        contains_tool "fzf" && packages+=("fzf")
        contains_tool "ripgrep" && packages+=("ripgrep")
        contains_tool "bat" && packages+=("bat")
        contains_tool "zoxide" && packages+=("zoxide")
        contains_tool "neovim" && packages+=("neovim")
        contains_tool "git" && packages+=("git")

        if contains_tool "starship" || contains_tool "gh"; then
            packages+=("curl")
        fi

        if contains_tool "eza"; then
            packages+=("wget")
        fi

        # Linux packages
        if command_exists apt-get; then
            # Debian/Ubuntu
            sudo apt-get update
            if [[ ${#packages[@]} -gt 0 ]]; then
                sudo apt-get install -y "${packages[@]}"
            fi
                
        elif command_exists yum; then
            # RHEL/CentOS/Fedora
            if [[ ${#packages[@]} -gt 0 ]]; then
                sudo yum install -y "${packages[@]}"
            fi
                
        elif command_exists dnf; then
            # Fedora
            if [[ ${#packages[@]} -gt 0 ]]; then
                sudo dnf install -y "${packages[@]}"
            fi
        fi
        
        if contains_tool "zsh-plugins"; then
            install_zsh_plugins_linux
        fi
        
        # Install btop (may need manual install)
        if contains_tool "btop" && ! command_exists btop; then
            print_info "Installing btop..."
            if command_exists snap; then
                sudo snap install btop
            else
                print_warning "btop installation may require manual setup"
            fi
        fi
        
        # Install GitHub CLI
        if contains_tool "gh" && ! command_exists gh; then
            print_info "Installing GitHub CLI..."
            if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt update
                sudo apt install gh -y
            fi
        fi
        
        # Install eza (modern ls replacement)
        if contains_tool "eza" && ! command_exists eza; then
            print_info "Installing eza..."
            if command_exists cargo; then
                cargo install eza
            else
                print_warning "eza requires Rust. Install with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
            fi
        fi

        # Install Starship prompt
        if contains_tool "starship" && ! command_exists starship; then
            print_info "Installing Starship..."
            if command_exists curl; then
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            else
                print_warning "curl not found; skipping Starship install"
            fi
        fi
    fi
    
    print_success "Package installation complete"
}

install_nerd_font_macos() {
    print_info "Checking Nerd Font for eza icons..."

    if ! brew list --cask font-hack-nerd-font &>/dev/null; then
        print_info "Installing Hack Nerd Font..."
        if brew install --cask font-hack-nerd-font; then
            print_success "Hack Nerd Font installed"
        else
            print_warning "Could not install Hack Nerd Font automatically"
            print_warning "Install manually with: brew install --cask font-hack-nerd-font"
        fi
    else
        print_info "Hack Nerd Font already installed"
    fi
}

###############################################################################
# Zsh Plugins - Linux
###############################################################################

install_zsh_plugins_linux() {
    if ! command_exists zsh; then
        print_warning "zsh not installed, skipping plugins"
        return 0
    fi
    
    print_info "Installing zsh plugins..."
    
    # Install zsh-autosuggestions
    if [ ! -d "$HOME/.zsh/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/zsh-autosuggestions" 2>/dev/null || print_warning "Could not clone zsh-autosuggestions"
    fi
    
    # Install zsh-syntax-highlighting
    if [ ! -d "$HOME/.zsh/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.zsh/zsh-syntax-highlighting" 2>/dev/null || print_warning "Could not clone zsh-syntax-highlighting"
    fi
    
    # Install zsh-history-substring-search
    if [ ! -d "$HOME/.zsh/zsh-history-substring-search" ]; then
        git clone https://github.com/zsh-users/zsh-history-substring-search "$HOME/.zsh/zsh-history-substring-search" 2>/dev/null || print_warning "Could not clone zsh-history-substring-search"
    fi
}

###############################################################################
# Shell Configuration
###############################################################################

setup_shell() {
    print_info "Configuring shell..."
    
    # Always prefer zsh if available
    if command_exists zsh; then
        setup_zshrc
    elif [[ "$OS" == "linux" ]]; then
        setup_bashrc
    fi
    
    print_success "Shell configuration complete"
}

ensure_starship_init_in_file() {
    local shell_file="$1"
    local shell_name="$2"

    [ -f "$shell_file" ] || return 0

    if grep -q 'starship init' "$shell_file"; then
        return 0
    fi

    cat >> "$shell_file" << EOF

# Starship prompt
if command -v starship &> /dev/null; then
    eval "\$(starship init $shell_name)"
fi
EOF

    print_info "Added Starship init block to $shell_file"
}

setup_zshrc() {
    local zshrc="$HOME/.zshrc"
    
    print_info "Configuring .zshrc..."
    # Check if already configured
    if [ -f "$zshrc" ] && grep -q "Terminal Setup Configuration" "$zshrc"; then
        ensure_starship_init_in_file "$zshrc" "zsh"
        print_info ".zshrc already configured - skipping"
        return 0
    fi
    
    # Backup existing .zshrc
    if [ -f "$zshrc" ]; then
        cp "$zshrc" "$zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing .zshrc"
    fi
    
    cat > "$zshrc" << 'EOF'
# ~/.zshrc - Terminal Setup Configuration

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS

# Basic options
setopt AUTO_CD
setopt CORRECT
setopt INTERACTIVE_COMMENTS

# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Aliases
if command -v eza &> /dev/null; then
    alias ll='eza -lh --icons --git'
    alias ls='eza --icons'
    alias la='eza -lha --icons'
else
    alias ll='ls -lh'
    alias la='ls -lha'
fi
alias cl="printf '\33c\e[3J'"
alias h='history'
alias please='sudo'

if command -v bat &> /dev/null; then
    alias cat='bat --style=plain'
fi

if command -v btop &> /dev/null; then
    alias top='btop'
fi

if command -v nvim &> /dev/null; then
    alias vim='nvim'
    alias vi='nvim'
fi

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# Modern CLI tools
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd='z'
fi

# Zsh-autosuggestions
if [[ "$OSTYPE" == "darwin"* ]]; then
    [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
else
    [ -f $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Zsh-syntax-highlighting (must be sourced after zsh-autosuggestions)
if [[ "$OSTYPE" == "darwin"* ]]; then
    [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
    [ -f $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Zsh-history-substring-search (must be sourced after zsh-syntax-highlighting)
if [[ "$OSTYPE" == "darwin"* ]]; then
    [ -f /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh ] && source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
else
    [ -f $HOME/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh ] && source $HOME/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
fi

# Bind keys for history search (safe fallback when widget is unavailable)
if [[ ${+widgets[history-substring-search-up]} -eq 1 ]] && [[ ${+widgets[history-substring-search-down]} -eq 1 ]]; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
else
    bindkey '^[[A' up-line-or-history
    bindkey '^[[B' down-line-or-history
fi

# Fzf history search (Ctrl+R for fuzzy history)
if command -v fzf &> /dev/null; then
    __fzf_history() {
        local output
        output=$(fc -lnr -2147483648 | awk '!seen[$0]++' | fzf --no-sort --reverse --query="$LBUFFER")
        LBUFFER="$output"
    }
    zle -N __fzf_history
    bindkey '^R' __fzf_history
fi

# Custom functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# Load local customizations
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
EOF

    print_success "Created .zshrc"
}

setup_bashrc() {
    local bashrc="$HOME/.bashrc"
    
    print_info "Configuring .bashrc..."

    # If managed block already exists, only ensure Starship init is present.
    if [ -f "$bashrc" ] && grep -q "Terminal Setup Configuration" "$bashrc"; then
        ensure_starship_init_in_file "$bashrc" "bash"
        print_info ".bashrc already configured - skipping"
        return 0
    fi
    
    # Backup existing .bashrc
    if [ -f "$bashrc" ]; then
        cp "$bashrc" "$bashrc.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing .bashrc"
    fi
    
    cat >> "$bashrc" << 'EOF'

# Terminal Setup Configuration
# History settings
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend

# Better navigation
shopt -s cdspell
shopt -s dirspell
shopt -s autocd 2>/dev/null

# Aliases
if command -v eza &> /dev/null; then
    alias ll='eza -lh --icons --git'
    alias ls='eza --icons'
    alias la='eza -lha --icons'
else
    alias ll='ls -lh'
    alias la='ls -lha'
fi
alias cl="printf '\33c\e[3J'"
alias h='history'
alias please='sudo'

if command -v bat &> /dev/null; then
    alias cat='bat --style=plain'
fi

if command -v btop &> /dev/null; then
    alias top='btop'
fi

if command -v nvim &> /dev/null; then
    alias vim='nvim'
    alias vi='nvim'
fi

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# Modern CLI tools
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
    alias cd='z'
fi

# Fzf history search (Ctrl+R for fuzzy history)
if command -v fzf &> /dev/null; then
    eval "$(fzf --bash)"
fi

# Custom functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# Load local customizations
[ -f ~/.bashrc.local ] && source ~/.bashrc.local
EOF

    print_success "Updated .bashrc"
}

###############################################################################
# Tool Configurations
###############################################################################

setup_tmux() {
    print_info "Setting up tmux configuration..."
    
    # Create directories
    mkdir -p "$HOME/.config/tmux"
    
    # Try to use repo config files first
    if [ -f "$REPO_CONFIG_DIR/tmux.conf" ]; then
        cp "$REPO_CONFIG_DIR/tmux.conf" "$HOME/.config/tmux/tmux.conf"
        print_success "Installed tmux.conf from repo"
    else
        print_warning "tmux.conf not found in repo"
        return 1
    fi
    
    # Ensure tmux loads this config by default
    if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing ~/.tmux.conf"
    fi
    ln -sfn "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"
    
    print_info "Tmux configuration installed"
    print_info "Edit ~/.config/tmux/tmux.conf for further customizations"
}

setup_btop() {
    print_info "Setting up btop..."
    mkdir -p "$CONFIG_DIR/btop"
    print_info "btop will use default configuration on first run"
    print_info "Customize it later in ~/.config/btop/btop.conf"
}

setup_starship() {
    local starship_config="$CONFIG_DIR/starship.toml"

    print_info "Setting up Starship configuration..."
    mkdir -p "$CONFIG_DIR"

    if [ -f "$starship_config" ]; then
        cp "$starship_config" "$starship_config.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing ~/.config/starship.toml"
    fi

    if [ -f "$REPO_CONFIG_DIR/starship.toml" ]; then
        cp "$REPO_CONFIG_DIR/starship.toml" "$starship_config"
        print_success "Installed Starship config from repo"
    else
        print_warning "starship.toml not found in repo config directory"
    fi
}

setup_git() {
    print_info "Setting up Git configuration..."
    echo ""
    
    # Check existing git configuration
    current_name=$(git config --global user.name 2>/dev/null)
    current_email=$(git config --global user.email 2>/dev/null)
    
    if [ -n "$current_name" ] && [ -n "$current_email" ]; then
        print_info "Current Git configuration:"
        echo "  Name:  $current_name"
        echo "  Email: $current_email"
        echo ""
        read -p "Do you want to change this? (y/N): " change_git
        
        if [[ "$change_git" =~ ^[Yy]$ ]]; then
            read -p "Enter your Git username: " git_name
            read -p "Enter your Git email: " git_email
            
            if [ -n "$git_name" ]; then
                git config --global user.name "$git_name"
                print_success "Git username set to: $git_name"
            fi
            
            if [ -n "$git_email" ]; then
                git config --global user.email "$git_email"
                print_success "Git email set to: $git_email"
            fi
        else
            print_info "Keeping existing Git configuration"
        fi
    else
        # No git config exists, must ask
        print_warning "Git user information not configured"
        echo ""
        read -p "Enter your Git username: " git_name
        read -p "Enter your Git email: " git_email
        
        if [ -n "$git_name" ]; then
            git config --global user.name "$git_name"
            print_success "Git username set to: $git_name"
        else
            print_warning "Git username not set"
        fi
        
        if [ -n "$git_email" ]; then
            git config --global user.email "$git_email"
            print_success "Git email set to: $git_email"
        else
            print_warning "Git email not set"
        fi
    fi
    
    echo ""
    print_info "Configuring useful Git defaults..."
    
    # Set useful Git defaults
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.editor "nvim"
    git config --global color.ui auto
    git config --global core.autocrlf input
    
    # Better diff and merge tools
    git config --global diff.colorMoved zebra
    git config --global merge.conflictstyle diff3
    
    # Helpful aliases
    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.unstage "reset HEAD --"
    git config --global alias.last "log -1 HEAD"
    git config --global alias.visual "log --oneline --graph --decorate --all"
    
    print_success "Git configured with helpful defaults and aliases"
}

###############################################################################
# Main Installation Flow
###############################################################################

main() {
    parse_args "$@"

    print_info "Starting terminal setup..."
    echo ""
    
    # Detect OS
    detect_os
    echo ""

    # Tool selection
    prepare_tool_selection
    echo ""
    
    # Install package manager
    install_package_manager
    echo ""
    
    # Install packages
    install_packages
    echo ""
    
    # Setup shell
    if contains_tool "shell"; then
        setup_shell
        echo ""
    fi

    # Setup tools
    if contains_tool "tmux"; then
        setup_tmux
    fi
    if contains_tool "btop"; then
        setup_btop
    fi
    if contains_tool "starship"; then
        setup_starship
    fi
    if contains_tool "git-config"; then
        setup_git
    fi
    echo ""
    
    print_success "Installation complete! 🎉"
    echo ""
    print_info "Next steps:"

    if contains_tool "shell"; then
        if command_exists zsh; then
            echo "  - Reload shell: source ~/.zshrc"
        else
            echo "  - Reload shell: source ~/.bashrc"
        fi
    fi
    if contains_tool "gh"; then
        echo "  - Login to GitHub: gh auth login"
    fi
    if contains_tool "tmux"; then
        echo "  - Start tmux: tmux"
    fi
    if contains_tool "btop"; then
        echo "  - Open system monitor: btop"
    fi
    if [[ "$OS" == "macos" ]] && contains_tool "nerd-font"; then
        echo "  - Set terminal font to: Hack Nerd Font"
    fi

    echo ""
    print_info "Key bindings:"
    if contains_tool "shell"; then
        echo "  - Ctrl+R: Fuzzy search history"
        echo "  - Up/Down arrows: Search history (substring match)"
    fi
    if contains_tool "tmux"; then
        echo "  - Ctrl+B: tmux prefix"
    fi
    echo ""
    print_info "Configuration files:"
    if contains_tool "shell"; then
        if command_exists zsh; then
            echo "  - ~/.zshrc (shell config)"
        else
            echo "  - ~/.bashrc (shell config)"
        fi
    fi
    if contains_tool "starship"; then
        echo "  - ~/.config/starship.toml (starship prompt)"
    fi
    if contains_tool "tmux"; then
        echo "  - ~/.config/tmux/tmux.conf (tmux config)"
    fi
    echo ""
    print_info "Happy coding! ✨"
}

# Run main function
main "$@"
