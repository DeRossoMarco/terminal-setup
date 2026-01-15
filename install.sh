#!/usr/bin/env bash

###############################################################################
# Terminal Setup Script
# Installs and configures: starship, tmux, zsh/bash, btop, gh, and more
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
            "starship"      # Prompt
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
        )
        
        for package in "${packages[@]}"; do
            if ! brew list "$package" &>/dev/null; then
                print_info "Installing $package..."
                brew install "$package"
            else
                print_info "$package already installed"
            fi
        done
        
    elif [[ "$OS" == "linux" ]]; then
        # Linux packages
        if command_exists apt-get; then
            # Debian/Ubuntu
            sudo apt-get update
            sudo apt-get install -y \
                tmux \
                bash \
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
                bash \
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
                bash \
                fzf \
                ripgrep \
                bat \
                neovim \
                git \
                curl \
                wget
        fi
        
        # Install starship (not in most repos)
        if ! command_exists starship; then
            print_info "Installing Starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
        
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

###############################################################################
# Shell Configuration
###############################################################################

setup_shell() {
    print_info "Configuring shell..."
    
    if [[ "$OS" == "macos" ]]; then
        # macOS uses zsh by default since Catalina (10.15)
        print_info "Using macOS default zsh shell"
        
        # Setup .zshrc
        setup_zshrc
    elif [[ "$OS" == "linux" ]]; then
        # Setup .bashrc
        setup_bashrc
    fi
    
    print_success "Shell configuration complete"
}

setup_zshrc() {
    local zshrc="$HOME/.zshrc"
    
    print_info "Configuring .zshrc..."
    Check if already configured
    if [ -f "$zshrc" ] && grep -q "Terminal Setup Configuration" "$zshrc"; then
        print_info ".zshrc already configured - skipping"
        return 0
    fi
    
    # 
    # Backup existing .zshrc
    if [ -f "$zshrc" ]; then
        cp "$zshrc" "$zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing .zshrc"
    fi
    
    cat > "$zshrc" << 'EOF'
# ~/.zshrc - Terminal Setup Configuration

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Basic options
setopt AUTO_CD
setopt CORRECT
setopt INTERACTIVE_COMMENTS

# Colors
autoload -U colors && colors

# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Aliases
alias ll='eza -lah --icons --git'
alias ls='eza --icons'
alias la='eza -a --icons'
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

if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi

# Starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# Zsh plugins (macOS Homebrew)
if [[ "$OSTYPE" == "darwin"* ]]; then
    [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Custom functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# FFmpeg functions
ffmpeg-compress() {
    ffmpeg -i "$1" -vn -ar 44100 -ac 1 -b:a 96k "$2"
}

ffmpeg-concat() {
    for f in *."$1"; do
        echo "file '$f'" >> files.txt
    done
    ffmpeg -f concat -safe 0 -i files.txt -c copy "$2"
    rm -f files.txt
}

# Markdown to PDF
md2pdf() {
    pandoc "$1" -s -V geometry:margin=1in -o "${1%.*}.pdf"
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
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend

# Better navigation
shopt -s cdspell
shopt -s dirspell
shopt -s autocd 2>/dev/null

# Aliases
if command -v eza &> /dev/null; then
    alias ll='eza -lah --icons --git'
    alias ls='eza --icons'
    alias la='eza -a --icons'
else
    alias ll='ls -lah'
    alias la='ls -A'
fi

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

if command -v fzf &> /dev/null; then
    eval "$(fzf --bash)"
fi

# Starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
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

setup_starship() {
    if [ -f "$CONFIG_DIR/starship.toml" ]; then
        print_info "Starship config already exists - backing up and updating"
        cp "$CONFIG_DIR/starship.toml" "$CONFIG_DIR/starship.toml.backup.$(date +%Y%m%d_%H%M%S)"
    else
        print_info "Creating Starship configuration..."
    fi
    
    mkdir -p "$CONFIG_DIR"
    
    # Try to use repo config file first, fall back to inline if not available
    if [ -f "$REPO_CONFIG_DIR/starship.toml" ]; then
        cp "$REPO_CONFIG_DIR/starship.toml" "$CONFIG_DIR/starship.toml"
        print_success "Installed Starship configuration from repo"
    else
        cat > "$CONFIG_DIR/starship.toml" << 'EOF'
# Starship Configuration

format = """
[┌───────────────────>](bold green)
[│](bold green)$directory$git_branch$git_status
[└─>](bold green) """

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
style = "bold cyan"
truncation_length = 3
truncate_to_repo = true
format = "[$path]($style)[$read_only]($read_only_style) "

[git_branch]
symbol = " "
style = "bold purple"
format = "on [$symbol$branch]($style) "

[git_status]
style = "bold yellow"
format = "([$all_status$ahead_behind]($style) )"
conflicted = "🏳"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
up_to_date = "✓"
untracked = "?"
stashed = "$"
modified = "!"
staged = "+"
renamed = "»"
deleted = "✘"

[nodejs]
symbol = " "
format = "via [$symbol($version )]($style)"

[python]
symbol = " "
format = 'via [${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'

[rust]
symbol = " "
format = "via [$symbol($version )]($style)"

[golang]
symbol = " "
format = "via [$symbol($version )]($style)"

[docker_context]
symbol = " "
format = "via [$symbol$context]($style) "

[time]
disabled = false
format = "🕙[$time]($style) "
time_format = "%T"
style = "bold white"

[cmd_duration]
min_time = 500
format = "took [$duration](bold yellow) "
EOF

    print_success "Created Starship configuration"
    fi
}

setup_tmux() {
    # Check if Oh My Tmux is already installed
    if [ -d "$HOME/.local/share/tmux/oh-my-tmux" ] || [ -L "$HOME/.config/tmux/tmux.conf" ]; then
        print_success "Oh My Tmux! already installed"
        print_info "Main config: ~/.local/share/tmux/oh-my-tmux/.tmux.conf"
        print_info "Symlink: ~/.config/tmux/tmux.conf"
        print_info "User customizations: ~/.config/tmux/tmux.conf.local"
        return 0
    fi
    
    # Check for existing simple tmux.conf
    if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
        print_info "Existing .tmux.conf found - skipping tmux setup"
        print_info "To upgrade to Oh My Tmux, backup and remove ~/.tmux.conf first"
        return 0
    fi
    
    print_info "Installing Oh My Tmux!..."
    
    # Create directories
    mkdir -p "$HOME/.local/share/tmux"
    mkdir -p "$HOME/.config/tmux"
    
    # Clone Oh My Tmux
    if [ ! -d "$HOME/.local/share/tmux/oh-my-tmux" ]; then
        print_info "Downloading Oh My Tmux from GitHub..."
        if ! git clone https://github.com/gpakosz/.tmux.git "$HOME/.local/share/tmux/oh-my-tmux" 2>/dev/null; then
            print_warning "Failed to clone Oh My Tmux, using simple config instead"
            install_simple_tmux
            return 0
        fi
        print_success "Oh My Tmux! downloaded to ~/.local/share/tmux/oh-my-tmux/"
    fi
    
    # Create symlink to main config
    if [ ! -e "$HOME/.config/tmux/tmux.conf" ]; then
        ln -sf "$HOME/.local/share/tmux/oh-my-tmux/.tmux.conf" "$HOME/.config/tmux/tmux.conf"
        print_success "Created symlink: ~/.config/tmux/tmux.conf"
    fi
    
    # Copy local config from repo or Oh My Tmux template
    if [ ! -f "$HOME/.config/tmux/tmux.conf.local" ]; then
        if [ -f "$REPO_CONFIG_DIR/tmux.conf.local" ]; then
            cp "$REPO_CONFIG_DIR/tmux.conf.local" "$HOME/.config/tmux/tmux.conf.local"
            print_success "Installed custom tmux.conf.local from repo"
        elif [ -f "$HOME/.local/share/tmux/oh-my-tmux/.tmux.conf.local" ]; then
            cp "$HOME/.local/share/tmux/oh-my-tmux/.tmux.conf.local" "$HOME/.config/tmux/tmux.conf.local"
            print_success "Created ~/.config/tmux/tmux.conf.local from template"
        fi
    fi
    
    print_success "Oh My Tmux! installation complete"
    print_info "Edit ~/.config/tmux/tmux.conf.local to customize your tmux setup"
}

install_simple_tmux() {
    print_info "Installing simple tmux config..."
    
    # Use inline minimal config as fallback (Oh My Tmux requires full repo structure)
    cat > "$HOME/.tmux.conf" << 'EOF'
# Tmux Configuration (Minimal)

# Prefix
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Mouse
set -g mouse on

# Indexing
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Colors
set -g default-terminal "screen-256color"

# History
set -g history-limit 50000

# Status bar
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left '#[bg=#89b4fa,fg=#1e1e2e,bold] #S '
set -g status-right '#[bg=#89b4fa,fg=#1e1e2e,bold] %Y-%m-%d %H:%M '

# Split panes
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Reload config
bind r source-file ~/.tmux.conf \; display "Reloaded!"

# Vi mode
set-window-option -g mode-keys vi
EOF
    print_success "Created minimal tmux configuration"
}

btop() {
    print_info "Configuring btop..."
    
    mkdir -p "$CONFIG_DIR/btop"
    
    cat > "$CONFIG_DIR/btop/btop.conf" << 'EOF'
# Btop Configuration

# Color theme
color_theme = "Default"

# Update time in milliseconds
update_ms = 2000

# Show disks
show_disks = True

# Show network
net_download = 100
net_upload = 100

# CPU graph
cpu_graph_upper = "total"
cpu_graph_lower = "total"

# Show temperature
show_cpu_freq = True
EOF

    print_success "Created btop configuration"
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
    setup_starship
    setup_tmux
    setup_btop
    setup_git
    echo ""
    
    print_success "Installation complete! 🎉"
    echo ""
    print_info "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc (macOS) or source ~/.bashrc (Linux)"
    echo "  2. For GitHub CLI, run: gh auth login"
    echo "  3. Start tmux with: tmux"
    echo "  4. Open btop with: btop"
    echo ""
    print_info "Configuration files:"
    echo "  - ~/.zshrc or ~/.bashrc"
    echo "  - ~/.config/starship.toml"
    if [ -d "$HOME/.config/tmux" ]; then
        echo "  - ~/.config/tmux/ (Oh My Tmux!)"
    elif [ -f "$HOME/.tmux.conf" ]; then
        echo "  - ~/.tmux.conf"
    fi
    echo "  - ~/.config/btop/btop.conf"
    echo ""
    print_info "Happy coding! ✨"
}

# Run main function
main
