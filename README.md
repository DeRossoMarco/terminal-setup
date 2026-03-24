# Terminal Setup Script

One-command installation and configuration for a modern terminal setup on macOS and Linux.

## What Is Included

### Tools Installed

- tmux - terminal multiplexer
- btop - system monitor
- starship - modern prompt
- GitHub CLI (gh)
- fzf - fuzzy finder
- ripgrep - fast grep
- bat - better cat
- eza - modern ls replacement
- zoxide - smarter cd
- neovim
- git
- zsh plugins:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - zsh-history-substring-search

### Shell Setup

- macOS: configures zsh
- Linux: configures bash

### Features

- OS-aware setup for macOS and Linux
- Homebrew bootstrap on macOS
- apt/yum/dnf support on Linux
- History-based suggestions and search in zsh
- Fuzzy history search on Ctrl+R
- Native tmux config files from this repository
- Safe icon fallback for terminals without Nerd Fonts
- Existing shell config backup before overwrite

## Quick Install

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/DeRossoMarco/terminal-setup/main/install.sh | bash
```

### Manual install

```bash
git clone https://github.com/DeRossoMarco/terminal-setup.git
cd terminal-setup
chmod +x install.sh
./install.sh
```

### Select tools to install

Interactive selection:

```bash
./install.sh --interactive
```

Install only specific tools:

```bash
./install.sh --tools tmux,starship,git,shell
```

Start from defaults and exclude some tools:

```bash
./install.sh --exclude-tools btop,gh
```

Mix both:

```bash
./install.sh --tools shell,tmux,zsh-plugins --exclude-tools tmux
```

Supported tool names:

- shell
- tmux
- btop
- starship
- gh
- fzf
- ripgrep
- bat
- eza
- zoxide
- neovim
- git
- git-config
- zsh
- zsh-plugins
- nerd-font

Notes:

- `zsh` is intended for Linux package installation workflows.
- On macOS interactive mode, `zsh` is hidden because zsh is already provided by the OS.
- `nerd-font` is supported on both macOS and Linux.

Dependency handling:

- `git-config` auto-enables `git`
- `zsh-plugins` auto-enables `git`
- On Linux, `zsh-plugins` auto-enables `zsh`
- `nerd-font` installs Hack Nerd Font on macOS and Linux

## Reset To Default

One-line remove:

```bash
curl -fsSL https://raw.githubusercontent.com/DeRossoMarco/terminal-setup/main/reset.sh | bash
```

One-line remove (non-interactive):

```bash
curl -fsSL https://raw.githubusercontent.com/DeRossoMarco/terminal-setup/main/reset.sh | bash -s -- --yes
```

To remove managed configuration, uninstall related packages, and restore the latest backups:

```bash
chmod +x reset.sh
./reset.sh
```

Non-interactive mode:

```bash
./reset.sh --yes
```

Keep installed packages and reset only configuration files:

```bash
./reset.sh --keep-packages
```

Non-interactive soft reset:

```bash
./reset.sh --yes --keep-packages
```

Notes:

- macOS: Homebrew packages installed by this setup are removed.
- Linux: apt/dnf/yum packages installed by this setup are removed when available.
- Homebrew itself is kept installed.
- Global Git settings are not reset.
- With `--keep-packages`, package uninstall is skipped and only managed configs are reset.

## What Gets Configured

### Files

- macOS: ~/.zshrc
- Linux: ~/.bashrc
- ~/.config/tmux/tmux.conf
- ~/.config/btop/ (directory only, btop uses defaults until first run)

Existing shell files are backed up as timestamped files before changes.

## Aliases And Behavior

### Main aliases

- ll, ls, la via eza
- cat via bat
- top via btop
- vim and vi via nvim
- gs, ga, gc, gp, gl, gd for git shortcuts
- cd mapped to zoxide when available

### Icon fallback

If your terminal cannot render icon glyphs, icons are disabled automatically when locale is not UTF-8.

You can force plain mode anytime:

```bash
export TERMINAL_SETUP_DISABLE_ICONS=1
```

To re-enable icons:

```bash
unset TERMINAL_SETUP_DISABLE_ICONS
```

## Tmux

This repository ships a native tmux configuration in:

- configs/tmux.conf

The installer copies them to:

- ~/.config/tmux/tmux.conf

## Zsh History Search

With zsh configuration enabled:

- Up/Down arrows: history substring search
- Ctrl+R: fuzzy history search with fzf
- Autosuggestions from command history
- Syntax highlighting while typing

## Linux Notes

Linux setup supports apt, yum, and dnf.

Default behavior on Linux:

- Shell configuration is always written to `~/.bashrc`.
- zsh plugins are not installed by default unless explicitly requested.
- If you install `zsh-plugins`, they are installed for zsh but not sourced by default in bash.
- To use zsh plugins, install with `--tools shell,zsh,zsh-plugins` and switch your login shell to zsh.

For zsh plugins on Linux, repositories are cloned under:

- ~/.zsh/zsh-autosuggestions
- ~/.zsh/zsh-syntax-highlighting
- ~/.zsh/zsh-history-substring-search

## Post-install Steps

1. Reload shell config:

On macOS:

```bash
source ~/.zshrc
```

On Linux:

```bash
source ~/.bashrc
```

2. Authenticate GitHub CLI:

```bash
gh auth login
```

3. Start tmux:

```bash
tmux
```

4. Open btop:

```bash
btop
```

## Troubleshooting

### Linux prompt/theme does not look as expected

If you install with the one-line command (`curl ... | bash`), local repo files are not present.
The installer now falls back to downloading `configs/starship.toml` and `configs/tmux.conf` from GitHub automatically.

Quick checks:

- Verify Starship is active: run `echo $STARSHIP_SHELL` (should not be empty after reloading shell).
- Reload shell config: `source ~/.zshrc` or `source ~/.bashrc`.
- Ensure a Nerd Font is selected in your terminal profile for icon glyphs.
- On Linux, the installer now tries native package-manager install for `eza` before Rust/Cargo fallback.

### Icons look broken in ls output

Install a Nerd Font and select it in your terminal profile, or force plain mode:

```bash
export TERMINAL_SETUP_DISABLE_ICONS=1
```

### zsh shows: command not found: starship

This setup configures Starship by default.

If Starship is still missing after install, install it manually and reload your shell.

macOS:

```bash
brew install starship
source ~/.zshrc
```

Linux:

```bash
curl -sS https://starship.rs/install.sh | sh -s -- -y
source ~/.bashrc
```

### Option+Delete does not delete word-by-word on macOS

Word deletion is handled by your shell keybindings, not by Starship itself.

This setup now adds macOS bindings for Option-based word navigation/deletion in zsh.
It also maps Command+Delete to full-line deletion when the terminal sends supported key sequences.
If your shell was configured before this change, run the installer again (or add the same bindings in `~/.zshrc.local`) and reload:

```bash
source ~/.zshrc
```

If you have custom shell files, ensure one Starship init block is present:

- ~/.zshrc
- ~/.zshrc.local
- ~/.bashrc
- ~/.bashrc.local

Look for lines similar to:

```bash
eval "$(starship init zsh)"
```

or:

```bash
eval "$(starship init bash)"
```

### Homebrew not found on macOS

Install Homebrew manually and rerun the script:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Contributing

Contributions are welcome for:

- additional distro support
- safer package detection
- shell improvements
- tmux and workflow enhancements
