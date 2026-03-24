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
        # macOS packages
        brew update
        
        local packages=(
            "tmux"          # Terminal multiplexer
            "btop"          # System monitor
            "gh"            # GitHub CLI
            "fzf"           # Fuzzy finder
            "ripgrep"       # Better grep
            "bat"           # Better cat
            "eza"           # Better ls
            "zoxide"        # Smart cd
            "neovim"        # Text editor
            "git"           # Version control
            "zsh-autosuggestions"    # Command suggestions
            "zsh-syntax-highlighting" # Syntax highlighting
            "zsh-history-substring-search" # History substring search
        )
        
        for package in "${packages[@]}"; do
            if ! brew list "$package" &>/dev/null; then
                print_info "Installing $package..."
                brew install "$package"
            else
                print_info "$package already installed"
            fi
        done

        install_nerd_font_macos
        
    elif [[ "$OS" == "linux" ]]; then
        # Linux packages
        if command_exists apt-get; then
            # Debian/Ubuntu
            sudo apt-get update
            sudo apt-get install -y \
                tmux \
                zsh \
                fzf \
                ripgrep \
                bat \
                zoxide \
                neovim \
                git \
                curl \
                wget \
                build-essential
                
        elif command_exists yum; then
            # RHEL/CentOS/Fedora
            sudo yum install -y \
                tmux \
                zsh \
                fzf \
                ripgrep \
                bat \
                neovim \
                git \
                curl \
                wget
                
        elif command_exists dnf; then
            # Fedora
            sudo dnf install -y \
                tmux \
                zsh \
                fzf \
                ripgrep \
                bat \
                neovim \
                git \
                curl \
                wget
        fi
        
        # Install zsh plugins and autosuggestions
        install_zsh_plugins_linux
        
        # Install btop (may need manual install)
        if ! command_exists btop; then
            print_info "Installing btop..."
            if command_exists snap; then
                sudo snap install btop
            else
                print_warning "btop installation may require manual setup"
            fi
        fi
        
        # Install GitHub CLI
        if ! command_exists gh; then
            print_info "Installing GitHub CLI..."
            if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt update
                sudo apt install gh -y
            fi
        fi
        
        # Install eza (modern ls replacement)
        if ! command_exists eza; then
            print_info "Installing eza..."
            if command_exists cargo; then
                cargo install eza
            else
                print_warning "eza requires Rust. Install with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
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

setup_zshrc() {
    local zshrc="$HOME/.zshrc"
    
    print_info "Configuring .zshrc..."
    # Check if already configured
    if [ -f "$zshrc" ] && grep -q "Terminal Setup Configuration" "$zshrc"; then
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
alias cat='bat --style=plain'
alias top='btop'
alias vim='nvim'
alias vi='nvim'

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

# Load local customizations
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
EOF

    print_success "Created .zshrc"
}

setup_bashrc() {
    local bashrc="$HOME/.bashrc"
    
    print_info "Configuring .bashrc..."
    
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
        print_success "Installed tmux.conf from repo (Oh my tmux!)"
    else
        print_warning "tmux.conf not found in repo"
        return 1
    fi
    
    # Copy .local customizations if they exist
    if [ -f "$REPO_CONFIG_DIR/tmux.conf.local" ]; then
        cp "$REPO_CONFIG_DIR/tmux.conf.local" "$HOME/.config/tmux/tmux.conf.local"
        print_success "Installed tmux.conf.local customizations"
    fi

    # Ensure tmux loads this config by default
    if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing ~/.tmux.conf"
    fi
    ln -sfn "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"

    if [ -f "$HOME/.config/tmux/tmux.conf.local" ]; then
        if [ -e "$HOME/.tmux.conf.local" ] && [ ! -L "$HOME/.tmux.conf.local" ]; then
            mv "$HOME/.tmux.conf.local" "$HOME/.tmux.conf.local.backup.$(date +%Y%m%d_%H%M%S)"
            print_info "Backed up existing ~/.tmux.conf.local"
        fi
        ln -sfn "$HOME/.config/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
    fi
    
    print_info "Tmux configuration: Oh my tmux!"
    print_info "Edit ~/.config/tmux/tmux.conf.local for further customizations"
}

setup_btop() {
    print_info "Setting up btop..."
    mkdir -p "$CONFIG_DIR/btop"
    print_info "btop will use default configuration on first run"
    print_info "Customize it later in ~/.config/btop/btop.conf"
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
    print_info "Starting terminal setup..."
    echo ""
    
    # Detect OS
    detect_os
    echo ""
    
    # Install package manager
    install_package_manager
    echo ""
    
    # Install packages
    install_packages
    echo ""
    
    # Setup shell
    setup_shell
    echo ""
    
    # Setup tools
    setup_tmux
    setup_btop
    setup_git
    echo ""
    
    print_success "Installation complete! 🎉"
    echo ""
    print_info "Next steps:"
    echo "  1. Reload shell: source ~/.zshrc"
    echo "  2. Login to GitHub: gh auth login"
    echo "  3. Start tmux: tmux"
    echo "  4. Open system monitor: btop"
    if [[ "$OS" == "macos" ]]; then
        echo "  5. Set terminal font to: Hack Nerd Font"
    fi
    echo ""
    print_info "Key bindings:"
    echo "  - Ctrl+R: Fuzzy search history"
    echo "  - Up/Down arrows: Search history (substring match)"
    echo "  - Ctrl+B: tmux prefix"
    echo ""
    print_info "Configuration files:"
    echo "  - ~/.zshrc (shell config)"
    echo "  - ~/.config/tmux/tmux.conf (tmux config)"
    echo "  - ~/.config/tmux/tmux.conf.local (tmux customizations)"
    echo ""
    print_info "Happy coding! ✨"
}

# Run main function
main
