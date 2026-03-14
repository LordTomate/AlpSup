# Alpine Linux Headless Setup (Keyboard-Only)

This repository provides an alternative, **pure-terminal** setup for Alpine Linux via the `claude.sh` script, optimized for remote VPS environments, Docker containers, or headless servers.

It heavily embraces a strict Terminal-User-Interface (TUI) workflow centered around `zsh`, `tmux`, and `neovim`.

## Features
- **Security First**: Disables root SSH login and password authentication, implements strict password policies, hardens sysctl kernel parameters (against IP spoofing, redirects, SYN floods), and auto-blocks brute-force attempts with `sshguard` and `nftables`.
- **Productivity TUI**: Installs a curated stack including `fzf`, `ripgrep`, `bat`, `htop`, `lazygit`, and more.
- **Automated Configuration**: Fetches and applies the powerful `tw-studio` dotfiles to unify `zsh`, `tmux`, and `neovim` gracefully.

## Installation

1. Boot into a fresh Alpine installation.
2. Ensure you have network connectivity.
3. Download and execute the installer:

```sh
wget -O claude.sh https://raw.githubusercontent.com/LordTomate/AlpSup/main/claude.sh
chmod +x claude.sh
./claude.sh
```

**⚠️ Important Setup Notes:**
- You MUST run this as `root`.
- The script will prompt you to create an unprivileged user (e.g., `devadmin`) and ask for a password.
- **Password Authentication for SSH will be disabled.** You must ensure your public `id_rsa.pub` or `id_ed25519.pub` is copied to `/home/$USERNAME/.ssh/authorized_keys` before you close your session, otherwise you will be locked out remotely!

## Keyboard Workflow Reference

### ZSH & Fuzzy Finding
- **`Ctrl+R`**: Fuzzy search command history
- **`Ctrl+T`**: Fuzzy search files in the current directory
- **`Alt+C`**: Fuzzy directory jump
- **`!!`**: Repeat last command

### TMUX (Terminal Multiplexer)
The default prefix key is **`Ctrl+B`**.
- **`Prefix + c`**: Create new window
- **`Prefix + n` / `p`**: Next / Previous window
- **`Prefix + 0-9`**: Switch window by number
- **`Prefix + %`**: Split pane vertically (left/right)
- **`Prefix + "`**: Split pane horizontally (top/bottom)
- **`Prefix + Arrows`**: Navigate between panes
- **`Prefix + z`**: Maximize current pane (zoom)
- **`Prefix + d`**: Detach session (leaves it running in the background)
- **`tmux attach`**: Re-attach to the background session.

### Neovim (Editor)
- **`i`**: Insert Mode
- **`Esc`**: Normal Mode
- **`:w`**: Save
- **`:q` / `:q!`**: Quit / Force Quit
- **`/search`**: Find text (use `n` for next, `N` for previous)
- **`gg` / `G`**: Go to top / bottom of file
- **`Ctrl+W + Arrow`**: Navigate split editor panes
