#!/bin/sh
# Headless Alpine Setup Script (based on tw-studio dotfiles)
# Target: zsh, tmux, neovim, fzf, system hardening, and strict SSH constraints.

set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Starting Headless Alpine Setup (Keyboard-only Workflow)...${NC}\n"

# --- Helper Function ---
run_step() {
    local step_name="$1"
    local command="$2"
    
    echo -ne "${BLUE}[*] Executing:${NC} $step_name ... "
    eval "$command" > /tmp/claude-setup-step.log 2>&1 &
    local pid=$!
    
    local spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "[%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
        printf "\b\b\b"
    done
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "\r\033[K${GREEN}[+] Success:${NC} $step_name\n"
    else
        echo -e "\r\033[K${RED}[!] ERROR:${NC} Failed to execute: $step_name"
        echo -e "         Detailed log placed at: /tmp/claude-setup-step.log"
        tail -n 5 /tmp/claude-setup-step.log
        exit 1
    fi
}

# --- Pre-flight Checks ---
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[!] ERROR:${NC} This script must be run as root."
    exit 1
fi

# Ask for the username to configure
read -p "$(echo -e ${BLUE}"Enter the username you want to setup (e.g., your login name): "${NC})" USERNAME
if [ -z "$USERNAME" ] || [ "$USERNAME" = "root" ]; then
    echo -e "${RED}[!] ERROR:${NC} Invalid username. Must not be empty or root."
    exit 1
fi

# Ensure user exists (create if missing)
if ! id -u "$USERNAME" >/dev/null 2>&1; then
    run_step "Creating user '$USERNAME'" "adduser -D '$USERNAME' && addgroup '$USERNAME' wheel"
    echo -e "${YELLOW}Please set a password for $USERNAME:${NC}"
    passwd "$USERNAME"
fi

# --- 1. Repositories and Base Updates ---
enable_repos() {
    sed -i 's/^#\(.*community\)/\1/' /etc/apk/repositories
    if ! grep -q "testing" /etc/apk/repositories; then
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
    fi
}
run_step "Enable Community and Testing repos" "enable_repos"
run_step "Update & Upgrade Packages" "apk update && apk upgrade"

# --- 2. Install Sudo & Config ---
install_sudo() {
    apk add sudo
    echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
}
run_step "Install & Configure sudo" "install_sudo"

# --- 3. SSH Hardening ---
harden_ssh() {
    apk add openssh
    
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    
    # Configure SSH securely
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
    
    if ! grep -q "^MaxAuthTries" /etc/ssh/sshd_config; then
        echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
    else
        sed -i 's/^.*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
    fi

    # Ensure user has .ssh directory
    mkdir -p "/home/$USERNAME/.ssh"
    chmod 700 "/home/$USERNAME/.ssh"
    touch "/home/$USERNAME/.ssh/authorized_keys"
    chmod 600 "/home/$USERNAME/.ssh/authorized_keys"
    chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"

    rc-update add sshd default
    rc-service sshd restart || true
}
run_step "Harden SSH Daemon" "harden_ssh"
echo -e "${YELLOW}[!] WARNING:${NC} PasswordAuthentication is now disabled. Ensure your public key is in /home/$USERNAME/.ssh/authorized_keys before logging out."

# --- 4. System Hardening (Sysctl & Pwquality & Sshguard) ---
harden_system() {
    # sshguard
    apk add sshguard
    rc-update add sshguard default
    rc-service sshguard start || true

    # Sysctl Parameters
    cat << 'EOF' > /etc/sysctl.d/99-hardening.conf
# No ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
# No IP forwarding
net.ipv4.ip_forward = 0
# SYN-Flood protection
net.ipv4.tcp_syncookies = 1
# No Source Routing
net.ipv4.conf.all.accept_source_route = 0
# Disable Core Dumps
kernel.core_pattern = |/bin/false
fs.suid_dumpable = 0
# Maximize ASLR
kernel.randomize_va_space = 2
EOF
    sysctl -p /etc/sysctl.d/99-hardening.conf || true

    # Password Policy
    apk add libpwquality
    cat << 'EOF' > /etc/security/pwquality.conf
minlen = 12
minclass = 3
maxrepeat = 3
EOF
}
run_step "Apply System Hardening (Sysctl, sshguard, pwquality)" "harden_system"

# --- 5. Firewall (nftables) ---
setup_firewall() {
    apk add nftables
    cat << 'EOF' > /etc/nftables.conf
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        iifname lo accept
        ct state established,related accept
        tcp dport 22 accept
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF
    nft -f /etc/nftables.conf || true
    rc-update add nftables default
    rc-service nftables start || true
}
run_step "Configure nftables Firewall" "setup_firewall"

# --- 6. Utility Binaries Install ---
run_step "Install Productivity CLI Tools" "apk add curl wget git ripgrep bat fd htop jq ncdu lazygit gnupg zsh tmux"

# --- 7. tw-studio Dotfiles Execution ---
echo -e "${BLUE}[*] Executing tw-studio dotfiles setup for $USERNAME...${NC}"
# The setup script from tw-studio uses standard paths and creates files in ~.
# We execute it as the user.
su - "$USERNAME" -c 'sh -c "$(wget https://raw.githubusercontent.com/tw-studio/dotfiles/main/codespace-setup/scripts/codespace-alpine.sh -O -)"' || {
    echo -e "${YELLOW}[!] Warning:${NC} The tw-studio dotfiles script encountered an issue. Please review logs or output."
}

# Ensure zsh is the default shell
chsh -s /bin/zsh "$USERNAME"

echo -e "------------------------------------------------"
echo -e "${GREEN}[SUCCESS] Headless Alpine Setup Completed!${NC}"
echo -e "Your system is now hardened, running nftables, sshguard, and configured for a tmux/zsh/neovim workflow."
echo -e "Please read GuiLess.md for instructions and keybindings."
