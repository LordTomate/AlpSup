#!/usr/bin/env bash
# Alpine Linux Setup Script
# Stack: sway, foot, dmenu, ranger, LibreWolf+Tridactyl, neovim, zathura, cmus, nftables, dnscrypt-proxy

set -e

# --- Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Starting Alpine Linux Setup...${NC}\n"

# --- Helper Function for Error Handling & Fixes ---
run_step() {
    local step_name="$1"
    local command="$2"
    local fix_msg="$3"
    
    echo -e "${BLUE}[*] Executing:${NC} $step_name"
    # Run the command and capture its output to a log file
    if eval "$command" > /tmp/alpine-setup-step.log 2>&1; then
        echo -e "${GREEN}[+] Success:${NC} $step_name\n"
    else
        echo -e "${RED}[!] ERROR:${NC} Failed to execute: $step_name"
        echo -e "${YELLOW}[?] FIX:${NC} $fix_msg"
        echo -e "         Detailed log placed at: /tmp/alpine-setup-step.log"
        echo -e "         Last 5 lines of log:"
        tail -n 5 /tmp/alpine-setup-step.log
        exit 1
    fi
}

# --- 1. Pre-flight Checks ---
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        return 1
    fi
}
run_step "Check Root Privileges" "check_root" "This script must be run as root. Run 'sudo ./alpine-setup.sh' or log in as root."

# --- 2. Repositories setup ---
enable_repos() {
    # Enable community repo by un-commenting it
    sed -i 's/^#\(.*community\)/\1/' /etc/apk/repositories
    
    # Enable edge/testing for newer packages (like LibreWolf or Tridactyl dependencies if needed)
    if ! grep -q "testing" /etc/apk/repositories; then
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
    fi
}
run_step "Enable Community and Testing repositories" "enable_repos" "Ensure your /etc/apk/repositories file is writable and you have internet access."

# --- 3. System Update ---
run_step "Update package index" "apk update" "Check your network connection and DNS settings."
run_step "Upgrade existing packages" "apk upgrade" "Check your network connection and ensure no other apk process is running."

# --- 4. Install Wayland, Window Manager, and Base ---
run_step "Install core services (udev, dbus, seatd)" "apk add eudev dbus seatd font-dejavu" "Ensure the main repositories are accessible."
run_step "Install Window Manager (sway, swaybg, xwayland)" "apk add sway swaybg xwayland wl-clipboard" "Ensure community repositories are enabled."

# --- 5. Install Terminal ---
run_step "Install Terminal (foot)" "apk add foot" "Foot requires the community repository."

# --- 6. Install App Launcher ---
run_step "Install App Launcher (dmenu)" "apk add dmenu" "dmenu requires the community repository."

# --- 7. Install File Manager ---
run_step "Install File Manager (ranger)" "apk add ranger" "ranger requires community repository."

# --- 8. Install Browser (LibreWolf + Tridactyl) ---
run_step "Install Browser (LibreWolf)" "apk add librewolf" "LibreWolf requires testing or community repositories depending on your Alpine version."

setup_tridactyl_policy() {
    mkdir -p /usr/lib/librewolf/distribution
    cat > /usr/lib/librewolf/distribution/policies.json << 'EOF'
{
  "policies": {
    "ExtensionSettings": {
      "tridactyl.vim@cmcaine.co.uk": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi"
      }
    }
  }
}
EOF
}
run_step "Configure LibreWolf to auto-install Tridactyl" "setup_tridactyl_policy" "Ensure /usr/lib/librewolf/distribution directory can be created and is writable."

# --- 9. Install Editor ---
run_step "Install Editor (neovim)" "apk add neovim" "neovim requires community repository."

# --- 10. Install PDF Viewer ---
run_step "Install PDF Viewer (zathura + mupdf plugin)" "apk add zathura zathura-pdf-mupdf" "zathura requires community repository."

# --- 11. Install Music Player ---
run_step "Install Music Player (cmus)" "apk add cmus" "cmus requires community repository."

# --- 12. Configure Firewall (nftables) ---
run_step "Install Firewall (nftables)" "apk add nftables" "nftables requires main repository."

setup_firewall() {
    rc-update add nftables default
    cat << 'EOF' > /etc/nftables.nft
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
        chain input {
                type filter hook input priority 0; policy drop;

                # Allow loopback traffic
                iif "lo" accept

                # Allow established and related connections
                ct state established,related accept

                # Allow ICMP
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
}
run_step "Configure and enable nftables firewall" "setup_firewall" "Ensure openrc is installed and you have permissions to configure services."

# --- 13. Configure DNS (dnscrypt-proxy) ---
run_step "Install DNS (dnscrypt-proxy)" "apk add dnscrypt-proxy" "dnscrypt-proxy requires community repository."

setup_dns() {
    rc-update add dnscrypt-proxy default
    
    # Ensure system uses local DNS proxy
    cp /etc/resolv.conf /etc/resolv.conf.backup
    echo "nameserver 127.0.0.1" > /etc/resolv.conf.new
    # Fallback DNS
    echo "nameserver 9.9.9.9" >> /etc/resolv.conf.new
    mv /etc/resolv.conf.new /etc/resolv.conf
}
run_step "Configure and enable dnscrypt-proxy" "setup_dns" "Ensure file /etc/resolv.conf is modifiable and won't be immediately overwritten by networkmanager/dhcpcd."

# --- 14. Configure Login (.profile) ---
setup_login() {
    # Auto-start sway on login on tty1
    local user_dirs=("/root")
    for d in /home/*; do
        if [ -d "$d" ]; then
            user_dirs+=("$d")
        fi
    done
    
    for dir in "${user_dirs[@]}"; do
        if [ -w "$dir" ]; then
            cat << 'EOF' > "$dir/.profile"
if [ -z "${DISPLAY}" ] && [ -n "${XDG_VTNR}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec sway
fi
EOF
            if [[ "$dir" == /home/* ]]; then
                # Get the username from the directory path
                local uname=$(basename "$dir")
                chown "$uname:$uname" "$dir/.profile"
                # Add user to seat group (required for wayland/sway)
                adduser "$uname" seat || true
                adduser "$uname" video || true
            fi
        fi
    done
    adduser root seat || true
}
run_step "Setup auto-start on tty1 for all users and seat access" "setup_login" "Ensure user home directories are accessible and writable."

# Ensure eudev, dbus, and seatd services are added to startup (required for Wayland on init systems)
run_step "Add hardware management services to startup" "rc-update add udev sysinit && rc-update add udev-trigger sysinit && rc-update add udev-settle sysinit && rc-update add udev-postmount default && rc-update add dbus default && rc-update add seatd default" "Ensure openrc, eudev, dbus, and seatd are installed correctly."

# --- Finish ---
echo -e "------------------------------------------------"
echo -e "${GREEN}[SUCCESS] Alpine Setup Completed!${NC}"
echo -e "\n${YELLOW}IMPORTANT USAGE NOTES:${NC}"
echo -e "1. ${BLUE}Start the GUI:${NC} Log in to tty1 as your regular user. Sway will automatically start."
echo -e "   (Sway is exactly like i3wm but designed for Wayland, supporting your 'foot' terminal natively)."
echo -e "2. ${BLUE}File Locations:${NC} Your setup script is saved at: /Users/matteo.frenzel/code/alpine_setup/alpine-setup.sh"
