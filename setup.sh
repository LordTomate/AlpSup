#!/bin/sh
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

# --- 0. Pre-Setup Options ---
echo -e "${YELLOW}--- Clean Setup Option ---${NC}"
echo -e "Do you want to WIPE existing configurations for the tools in this stack?"
echo -e "(This deletes existing sway, foot, ranger, nvim, zathura, cmus, and profile configs for a fresh start.)"
read -p "$(echo -e ${BLUE}"Wipe configurations? [y/N]: "${NC})" WIPE_CONFIGS
WIPE_CONFIGS=${WIPE_CONFIGS:-N}


if [ "$WIPE_CONFIGS" = "y" ] || [ "$WIPE_CONFIGS" = "Y" ]; then
    echo -ne "${BLUE}[*] Executing:${NC} Deep Wiping old applications and configurations... "
    
    (
        # 1. Uninstall the software stack if it exists
        apk del --quiet --purge \
            sway swaybg xwayland wl-clipboard foot dmenu ranger \
            librewolf neovim zathura zathura-pdf-mupdf cmus nftables \
            dnscrypt-proxy eudev dbus seatd font-dejavu >/dev/null 2>&1 || true
            
        # 2. Delete configuration folders
        for d in /root /home/*; do
            if [ -d "$d" ]; then
                rm -rf "$d/.config/sway" "$d/.config/foot" "$d/.config/ranger" "$d/.config/nvim" "$d/.config/zathura" "$d/.config/cmus" "$d/.profile"
            fi
        done
        rm -f /etc/nftables.nft /etc/sway/config
        rm -rf /usr/lib/librewolf/distribution
    ) &
    
    pid=$!
    spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        temp=${spinstr#?}
        printf "[%c]" "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
        printf "\b\b\b"
    done
    wait $pid
    
    echo -e "\r\033[K${GREEN}[+] Success:${NC} System deeply wiped.\n"
fi

# --- 0. Keyboard Configuration (Auto-Detect) ---
echo -e "${YELLOW}--- Auto-Detecting Keyboard Layout ---${NC}"
# Extract layout and variant from Alpine's loadkmap config (set during setup-alpine)
if [ -f /etc/conf.d/loadkmap ]; then
    # Parse KEYMAP string like "de-mac", "us", "de"
    BKEYMAP=$(grep "^KEYMAP=" /etc/conf.d/loadkmap | cut -d'=' -f2 | tr -d '"'\')
    KB_LAYOUT=$(echo $BKEYMAP | cut -d'-' -f1)
    # Check if there's a variant (like -mac)
    case "$BKEYMAP" in
        *-*) KB_VARIANT=$(echo $BKEYMAP | cut -d'-' -f2) ;;
        *)   KB_VARIANT="" ;;
    esac
    echo -e "${GREEN}[+] Detected Keyboard Layout:${NC} $KB_LAYOUT"
    [ -n "$KB_VARIANT" ] && echo -e "${GREEN}[+] Detected Variant:${NC} $KB_VARIANT"
else
    echo -e "${YELLOW}[!] Warning:${NC} Could not find /etc/conf.d/loadkmap. Falling back to 'us'."
    KB_LAYOUT="us"
    KB_VARIANT=""
fi
echo -e ""

# --- Helper Function for Error Handling & Fixes ---
run_step() {
    local step_name="$1"
    local command="$2"
    local fix_msg="$3"
    
    echo -ne "${BLUE}[*] Executing:${NC} $step_name ... "
    # Run the command in the background, redirecting output
    eval "$command" > /tmp/alpine-setup-step.log 2>&1 &
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
run_step "Install ACPI daemon (battery, power events)" "apk add acpid" "acpid provides battery info for Waybar and handles power button events."
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
    user_dirs="/root"
    for d in /home/*; do
        if [ -d "$d" ]; then
            user_dirs="$user_dirs $d"
        fi
    done
    
    for dir in $user_dirs; do
        if [ -w "$dir" ]; then
            # 1. Setup Sway keyboard layout
            mkdir -p "$dir/.config/sway"
            if [ -f /etc/sway/config ]; then
                cp /etc/sway/config "$dir/.config/sway/config"
            else
                echo "include /etc/sway/config" > "$dir/.config/sway/config"
            fi
            
            cat << EOF >> "$dir/.config/sway/config"

# --- Added by Alpine Setup Script ---
input * {
    xkb_layout "$KB_LAYOUT"
    xkb_variant "$KB_VARIANT"
}

# Explicitly set the Mod key (Mod4 = Super/Windows/Command key)
set \$mod Mod4

# Explicitly set the terminal to exactly what we installed
set \$term foot

# Explicitly set the application launcher to dmenu
set \$menu dmenu_path | dmenu | xargs swaymsg exec --

# --- Auto-Test LibreWolf on First Run ---
exec [ ! -f ~/.local/state/alpine_setup_tested ] && mkdir -p ~/.local/state && touch ~/.local/state/alpine_setup_tested && swaymsg exec librewolf
EOF

            # 2. Auto-start sway on login on tty1
            cat << 'EOF' > "$dir/.profile"
if [ -z "${DISPLAY}" ] && [ -n "${XDG_VTNR}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec sway
fi
EOF
            case "$dir" in
                /home/*)
                    # Get the username from the directory path
                    uname=$(basename "$dir")
                    chown -R "$uname:$uname" "$dir/.config"
                    chown "$uname:$uname" "$dir/.profile"
                    # Add user to seat group (required for wayland/sway)
                    adduser "$uname" seat || true
                    adduser "$uname" video || true
                    ;;
            esac
        fi
    done
    adduser root seat || true
}
run_step "Setup auto-start on tty1 for all users and seat access" "setup_login" "Ensure user home directories are accessible and writable."

# Ensure eudev, dbus, seatd, and acpid services are added to startup
run_step "Add hardware management services to startup" "rc-update add udev sysinit && rc-update add udev-trigger sysinit && rc-update add udev-settle sysinit && rc-update add udev-postmount default && rc-update add dbus default && rc-update add seatd default && rc-update add acpid default" "Ensure openrc, eudev, dbus, seatd, and acpid are installed correctly."

# --- Finish ---
echo -e "------------------------------------------------"
echo -e "${GREEN}[SUCCESS] Alpine Setup Completed!${NC}"
echo -e "\n${YELLOW}IMPORTANT USAGE NOTES:${NC}"
echo -e "1. ${BLUE}Start the GUI:${NC} Log in to tty1 as your regular user. Sway will automatically start."
echo -e "2. ${BLUE}Initial Test:${NC} On your very first login, ${GREEN}LibreWolf will launch automatically${NC} to verify that the Wayland graphical stack is working properly."
echo -e "   -> ${YELLOW}To close LibreWolf (or any window):${NC} Press ${GREEN}Mod + Shift + q${NC}."
echo -e "   -> ${YELLOW}To open a terminal (foot):${NC} Press ${GREEN}Mod + Enter${NC}."
echo -e "   -> ${YELLOW}To launch LibreWolf manually again:${NC} Press Mod+Enter, type 'librewolf', and press Enter."
echo -e "   *(Note: The 'Mod' key is your Super/Windows/Command key).* "
