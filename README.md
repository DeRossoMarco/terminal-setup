# 🚀 Terminal Setup Script

One-command installation and configuration for a modern, beautiful terminal setup.

## ✨ What's Included

### Tools Installed

- **[Starship](https://starship.rs/)** - Fast, customizable prompt
- **[tmux](https://github.com/tmux/tmux)** - Terminal multiplexer
- **[btop](https://github.com/aristocratos/btop)** - Beautiful system monitor
- **[GitHub CLI](https://cli.github.com/)** - GitHub command-line tool
- **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finder
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Fast grep alternative
- **[bat](https://github.com/sharkdp/bat)** - Better cat with syntax highlighting
- **[eza](https://github.com/eza-community/eza)** - Modern ls replacement
- **[zoxide](https://github.com/ajmeek/zoxide)** - Smarter cd command
- **[Neovim](https://neovim.io/)** - Hyperextensible text editor

### Shell Configuration

- **macOS**: Configures `zsh` with modern aliases and functions
- **Linux**: Configures `bash` with modern aliases and functions

### Features

✅ OS-aware installation (macOS & Linux)  
✅ Automatic package manager setup (Homebrew/apt/yum)  
✅ Beautiful, informative prompt with Starship  
✅ Pre-configured tmux with sane defaults  
✅ Modern command aliases (`ll`, `cat`, `top`, etc.)  
✅ Git integration and shortcuts  
✅ Fuzzy finding and smart navigation  
✅ All config files backed up before modification  

## 🎯 Quick Install

### One-Line Install (when hosted on GitHub)

```bash
curl -fsSL https://raw.githubusercontent.com/DeRossoMarco/terminal-setup/main/install.sh | bash
```

### Manual Install

```bash
# Clone the repository
git clone https://github.com/DeRossoMarco/terminal-setup.git
cd terminal-setup

# Make executable and run
chmod +x install.sh
./install.sh
```

## 📦 What Gets Configured

### Shell Configuration Files

The script creates/updates:

- `~/.zshrc` (macOS) or `~/.bashrc` (Linux)
- `~/.config/starship.toml`
- `~/.config/tmux/` (Oh My Tmux! installation)
- `~/.config/btop/btop.conf`

**Note**: Existing configuration files are automatically backed up with a timestamp.

### New Aliases

After installation, you'll have access to:

```bash
# Modern file operations
ll         # Better ls with icons and git info
ls         # eza with icons
la         # List all files with icons
cat        # bat with syntax highlighting
top        # btop system monitor

# Editor
vim, vi    # Aliased to neovim

# Git shortcuts
gs         # git status
ga         # git add
gc         # git commit
gp         # git push
gl         # git log (pretty graph)
gd         # git diff

# Smart navigation
cd         # zoxide (learns your habits)
z          # Jump to frequent directories
```

### New Functions

```bash
mkcd <dir>  # Create directory and cd into it
```

## 🎨 Customization

### Local Customizations

Add your personal customizations to:

- `~/.zshrc.local` (macOS)
- `~/.bashrc.local` (Linux)

These files are sourced automatically and won't be overwritten by the script.

### Starship Prompt

Edit `~/.config/starship.toml` to customize your prompt.

See [Starship documentation](https://starship.rs/config/) for all options.

### Tmux

The script installs **[Oh My Tmux!](https://github.com/gpakosz/.tmux)** - a beautiful, feature-rich tmux configuration.

**Installation structure:**
- Main config: `~/.local/share/tmux/oh-my-tmux/.tmux.conf` (managed by Oh My Tmux)
- Symlink: `~/.config/tmux/tmux.conf` → main config
- **Your customizations**: `~/.config/tmux/tmux.conf.local` ← Edit this file!

**If you already have Oh My Tmux:**
- The script will detect and skip installation
- Your customizations in `~/.config/tmux/tmux.conf.local` are preserved

**Key bindings (Oh My Tmux defaults):**
- Prefix: `Ctrl-a` (instead of default `Ctrl-b`)
- Split horizontal: `Ctrl-a -`
- Split vertical: `Ctrl-a |`
- Reload config: `Ctrl-a r`
- Create session: `Ctrl-a C-c`
- Find session: `Ctrl-a C-f`

**For more info:**
- See [Oh My Tmux documentation](https://github.com/gpakosz/.tmux)
- Edit `~/.config/tmux/tmux.conf.local` for your customizations
- Don't edit the main `.tmux.conf` (it gets overwritten on updates)

## 🖥️ OS Support

### macOS

- Uses **Homebrew** as package manager
- Configures **zsh** as default shell
- Installs all packages via `brew`

### Linux

Supported distributions:

- **Debian/Ubuntu** (apt)
- **RHEL/CentOS** (yum)
- **Fedora** (dnf)

Configures **bash** as default shell.

## 📝 Manual Steps

After installation:

1. **Restart your terminal** or reload your shell config:
   ```bash
   # macOS
   source ~/.zshrc
   
   # Linux
   source ~/.bashrc
   ```

2. **Authenticate GitHub CLI** (optional):
   ```bash
   gh auth login
   ```

3. **Start using tmux**:
   ```bash
   tmux
   ```

4. **Try btop**:
   ```bash
   btop
   ```

## 🔧 Troubleshooting

### Permission Denied

If you get permission errors, ensure the script is executable:

```bash
chmod +x install.sh
./install.sh
```

### Homebrew Not Found (macOS)

If Homebrew installation fails, install it manually:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Package Not Available (Linux)

Some packages may not be available in all distributions. The script will skip unavailable packages and continue.

### Prompt Not Showing

If the Starship prompt doesn't appear after installation:

```bash
# Check if starship is installed
which starship

# Manually initialize
echo 'eval "$(starship init zsh)"' >> ~/.zshrc  # macOS
echo 'eval "$(starship init bash)"' >> ~/.bashrc  # Linux

# Reload shell
exec $SHELL
```

## 🤝 Contributing

Contributions welcome! Feel free to:

- Add support for more Linux distributions
- Include additional useful tools
- Improve configuration defaults
- Fix bugs or add features

## ⭐ Credits

This setup script configures amazing open-source tools. Give them a star!

- [Starship](https://github.com/starship/starship)
- [tmux](https://github.com/tmux/tmux)
- [btop](https://github.com/aristocratos/btop)
- [fzf](https://github.com/junegunn/fzf)
- And many more...

---
