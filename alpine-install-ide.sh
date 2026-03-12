#!/bin/sh
# Master IDE Installer Script for Alpine Linux
# Wraps alpine-setup.sh and provides optional IDE installations.

set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Starting Master IDE Installer for Alpine Linux...${NC}\n"

# --- 1. Base Setup ---
echo -e "${BLUE}[*] Checking for base setup script (alpine-setup.sh)...${NC}"
if [ ! -f "./alpine-setup.sh" ]; then
    echo -e "${YELLOW}>> alpine-setup.sh not found locally. Downloading from GitHub...${NC}"
    if wget -O alpine-setup.sh https://raw.githubusercontent.com/LordTomate/alpine_setup/main/alpine-setup.sh; then
        chmod +x alpine-setup.sh
        echo -e "\n${GREEN}[+] Successfully downloaded alpine-setup.sh${NC}"
    else
        echo -e "${RED}[!] ERROR:${NC} Failed to download alpine-setup.sh. Please check your internet connection."
        exit 1
    fi
fi

echo -e "${YELLOW}>> Triggering base setup...${NC}"
./alpine-setup.sh
echo -e "${GREEN}[+] Base setup completed successfully.${NC}\n"

# --- 2. Interactive IDE Prompts ---
echo -e "${GREEN}--- Additional IDE Installations ---${NC}"
echo -e "Your base environment is ready. You can now optionally install heavily integrated development environments."
echo -e "Note: These packages require testing/edge repositories and may introduce glibc compatibility layers.\n"

# Prompt for Zed
echo -e "${YELLOW}1. Zed Editor${NC} (High-performance, multiplayer code editor)"
echo -e "   Requires the 'edge' repository and 'gcompat' (glibc compatibility layer)."
read -p "$(echo -e ${BLUE}"Install Zed? [y/N]: "${NC})" INSTALL_ZED
INSTALL_ZED=${INSTALL_ZED:-N}

# Prompt for Code OSS
echo -e "\n${YELLOW}2. Code OSS${NC} (Visual Studio Code Open Source)"
echo -e "   The official open-source build provided in Alpine's 'testing' repository."
read -p "$(echo -e ${BLUE}"Install Code OSS? [y/N]: "${NC})" INSTALL_CODEOSS
INSTALL_CODEOSS=${INSTALL_CODEOSS:-N}

# Prompt for Cliphist
echo -e "\n${YELLOW}3. Clipboard Manager (cliphist & wl-clipboard)${NC}"
echo -e "   Stores last 50 copied items. Bind Mod+c to list and paste."
read -p "$(echo -e ${BLUE}"Install Cliphist? [y/N]: "${NC})" INSTALL_CLIPHIST
INSTALL_CLIPHIST=${INSTALL_CLIPHIST:-N}

# Prompt for Screenshots
echo -e "\n${YELLOW}4. Screenshot Tools (grim & slurp)${NC}"
echo -e "   Bind Mod+Shift+s to freeze screen, select area, and copy to clipboard."
read -p "$(echo -e ${BLUE}"Install Screenshot Tools? [y/N]: "${NC})" INSTALL_SCREENSHOTS
INSTALL_SCREENSHOTS=${INSTALL_SCREENSHOTS:-N}

# Prompt for Hardware Keys
echo -e "\n${YELLOW}5. Hardware Controls (brightnessctl & alsa-utils)${NC}"
echo -e "   Enables physical volume and brightness keys on your keyboard."
read -p "$(echo -e ${BLUE}"Install Hardware Controls? [y/N]: "${NC})" INSTALL_HWKEYS
INSTALL_HWKEYS=${INSTALL_HWKEYS:-N}

# Prompt for Mako
echo -e "\n${YELLOW}6. Notification Daemon (mako)${NC}"
echo -e "   Hover notifications for system events (bind Mod+Space to dismiss)."
read -p "$(echo -e ${BLUE}"Install Mako? [y/N]: "${NC})" INSTALL_MAKO
INSTALL_MAKO=${INSTALL_MAKO:-N}

# Prompt for Waybar
echo -e "\n${YELLOW}7. Modern Status Bar (waybar)${NC}"
echo -e "   Replaces the default swaybar with the highly customizable Waybar."
read -p "$(echo -e ${BLUE}"Install Waybar? [y/N]: "${NC})" INSTALL_WAYBAR
INSTALL_WAYBAR=${INSTALL_WAYBAR:-N}

# Prompt for Swaylock
echo -e "\n${YELLOW}8. Screen Locker (swayidle & swaylock)${NC}"
echo -e "   Auto-locks screen after 5 minutes of inactivity."
read -p "$(echo -e ${BLUE}"Install Screen Locker? [y/N]: "${NC})" INSTALL_LOCKER
INSTALL_LOCKER=${INSTALL_LOCKER:-N}


# Note regarding Antigravity
echo -e "\n${RED}--- Note on Antigravity IDE ---${NC}"
echo -e "You requested Antigravity IDE. Antigravity strictly requires a true 'glibc' environment (like Debian or Fedora)."
echo -e "Because Alpine uses 'musl libc', Antigravity cannot be installed natively here without heavy containerization (like Distrobox or Docker)."
echo -e "We recommend using Neovim, Zed, or Code OSS natively instead.\n"

# --- 3. Execute Installations ---
install_ide() {
    local name="$1"
    local command="$2"
    
    echo -ne "${BLUE}[*] Installing ${name}...${NC} "
    eval "$command" > /tmp/alpine-ide-step.log 2>&1 &
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
        echo -e "\r\033[K${GREEN}[+] Success:${NC} Installed ${name}."
    else
        echo -e "\r\033[K${RED}[!] ERROR:${NC} Failed to install ${name}."
        echo -e "         Check /tmp/alpine-ide-step.log for details."
        tail -n 5 /tmp/alpine-ide-step.log
    fi
}

echo -e "------------------------------------------------"
if [ "$INSTALL_ZED" = "y" ] || [ "$INSTALL_ZED" = "Y" ]; then
    # Enable edge testing repo specifically for zed if not already there
    if ! grep -q "edge/testing" /etc/apk/repositories; then
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
    fi
    # Install zed and the required compatibility layer
    install_ide "Zed Editor" "apk update && apk add zed gcompat"
fi

if [ "$INSTALL_CODEOSS" = "y" ] || [ "$INSTALL_CODEOSS" = "Y" ]; then
    # Install code-oss from testing
    install_ide "Code OSS" "apk update && apk add code-oss"
fi

inject_sway_config() {
    local config_text="$1"
    for d in /root /home/*; do
        if [ -w "$d/.config/sway/config" ]; then
            echo "$config_text" >> "$d/.config/sway/config"
        fi
    done
}

if [ "$INSTALL_CLIPHIST" = "y" ] || [ "$INSTALL_CLIPHIST" = "Y" ]; then
    install_ide "Cliphist" "apk add cliphist wl-clipboard"
    inject_sway_config "
# --- Added by Config Installer: Cliphist ---
exec wl-paste --watch cliphist store
bindsym \$mod+c exec cliphist list | dmenu | cliphist decode | wl-copy"
fi

if [ "$INSTALL_SCREENSHOTS" = "y" ] || [ "$INSTALL_SCREENSHOTS" = "Y" ]; then
    install_ide "Grim & Slurp" "apk add grim slurp wl-clipboard"
    inject_sway_config "
# --- Added by Config Installer: Screenshots ---
bindsym \$mod+Shift+s exec grim -g \"\$(slurp)\" - | wl-copy"
fi

if [ "$INSTALL_HWKEYS" = "y" ] || [ "$INSTALL_HWKEYS" = "Y" ]; then
    install_ide "Hardware Controls" "apk add brightnessctl alsa-utils"
    inject_sway_config "
# --- Added by Config Installer: Hardware Controls ---
bindsym XF86AudioRaiseVolume exec amixer sset Master 5%+
bindsym XF86AudioLowerVolume exec amixer sset Master 5%-
bindsym XF86AudioMute exec amixer sset Master toggle
bindsym XF86MonBrightnessUp exec brightnessctl set 5%+
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-"
fi

if [ "$INSTALL_MAKO" = "y" ] || [ "$INSTALL_MAKO" = "Y" ]; then
    install_ide "Mako Notifications" "apk add mako"
    inject_sway_config "
# --- Added by Config Installer: Mako ---
exec mako
bindsym \$mod+space exec makoctl dismiss"
fi

if [ "$INSTALL_WAYBAR" = "y" ] || [ "$INSTALL_WAYBAR" = "Y" ]; then
    install_ide "Waybar" "apk add waybar"
    # Comment out default swaybar to prevent two bars
    for d in /root /home/*; do
        if [ -w "$d/.config/sway/config" ]; then
            sed -i '/^bar {/,/^}/ s/^/# /' "$d/.config/sway/config"
        fi
    done
    inject_sway_config "
# --- Added by Config Installer: Waybar ---
bar {
    swaybar_command waybar
}"
fi

if [ "$INSTALL_LOCKER" = "y" ] || [ "$INSTALL_LOCKER" = "Y" ]; then
    install_ide "Swaylock & Swayidle" "apk add swaylock swayidle"
    inject_sway_config "
# --- Added by Config Installer: Screen Locker ---
exec swayidle -w \\
    timeout 300 'swaylock -f -c 000000' \\
    timeout 600 'swaymsg \"output * dpms off\"' resume 'swaymsg \"output * dpms on\"' \\
    before-sleep 'swaylock -f -c 000000'"
fi

echo -e "\n${GREEN}[SUCCESS] IDE Installation Phase Completed!${NC}"
echo -e "You can now log into tty1 to start your Sway environment."
