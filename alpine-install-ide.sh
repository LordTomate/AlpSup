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

echo -e "${YELLOW}-- Select Additional Tools & IDEs --${NC}"
echo -e "  [1] Zed Editor (Requires 'edge' repo, gcompat)"
echo -e "  [2] Code OSS (Official open-source VS Code)"
echo -e "  [3] Clipboard Manager (cliphist)"
echo -e "  [4] Screenshot Tools (grim & slurp)"
echo -e "  [5] Hardware Controls (brightnessctl & alsa-utils)"
echo -e "  [6] Notification Daemon (mako)"
echo -e "  [7] Modern Status Bar (waybar)"
echo -e "  [8] Screen Locker (swayidle & swaylock)"
echo -e "  [9] Glibc Compatibility Layer (Distrobox + Podman)"

echo -e "\n${RED}Note on Antigravity & Official VS Code:${NC} Choice [9] allows running these via an Ubuntu/Debian container."

echo -e ""
read -p "$(echo -e ${BLUE}"Enter numbers separated by space or comma (e.g., 1,3,4,9) - or press Enter to skip: "${NC})" USER_CHOICES

case "$USER_CHOICES" in *1*) INSTALL_ZED=y ;; *) INSTALL_ZED=N ;; esac
case "$USER_CHOICES" in *2*) INSTALL_CODEOSS=y ;; *) INSTALL_CODEOSS=N ;; esac
case "$USER_CHOICES" in *3*) INSTALL_CLIPHIST=y ;; *) INSTALL_CLIPHIST=N ;; esac
case "$USER_CHOICES" in *4*) INSTALL_SCREENSHOTS=y ;; *) INSTALL_SCREENSHOTS=N ;; esac
case "$USER_CHOICES" in *5*) INSTALL_HWKEYS=y ;; *) INSTALL_HWKEYS=N ;; esac
case "$USER_CHOICES" in *6*) INSTALL_MAKO=y ;; *) INSTALL_MAKO=N ;; esac
case "$USER_CHOICES" in *7*) INSTALL_WAYBAR=y ;; *) INSTALL_WAYBAR=N ;; esac
case "$USER_CHOICES" in *8*) INSTALL_LOCKER=y ;; *) INSTALL_LOCKER=N ;; esac
case "$USER_CHOICES" in *9*) INSTALL_DISTROBOX=y ;; *) INSTALL_DISTROBOX=N ;; esac
echo -e ""

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

if [ "$INSTALL_DISTROBOX" = "y" ] || [ "$INSTALL_DISTROBOX" = "Y" ]; then
    echo -e "${BLUE}[*] Setting up Glibc Compatibility Layer (Podman + Distrobox)...${NC}"
    # podman requires cgroups v2
    install_ide "Glibc Compatibility Layer" "apk add podman distrobox && rc-update add cgroups boot && rc-service cgroups start"
    
    # Enable rootless podman for the users
    for d in /root /home/*; do
        if [ -d "$d" ]; then
            uname=$(basename "$d")
            # Setup subuid/subgid
            if ! grep -q "$uname" /etc/subuid 2>/dev/null; then
                echo "$uname:100000:65536" >> /etc/subuid
                echo "$uname:100000:65536" >> /etc/subgid
            fi
        fi
    done
    echo -e "${GREEN}[+] Distrobox & Podman installed successfully.${NC}"
fi

echo -e "\n${GREEN}[SUCCESS] IDE Installation Phase Completed!${NC}"
echo -e "You can now log into tty1 to start your Sway environment."

if [ "$INSTALL_DISTROBOX" = "y" ] || [ "$INSTALL_DISTROBOX" = "Y" ]; then
    echo -e "\n${YELLOW}--- Distrobox Usage for Antigravity/VS Code ---${NC}"
    echo -e "1. Open a terminal and run: ${BLUE}distrobox create --name ubuntu --image ubuntu:latest${NC}"
    echo -e "2. Enter the container: ${BLUE}distrobox enter ubuntu${NC}"
    echo -e "3. Inside the container, you can install any glibc app (Antigravity, official VS Code, etc.)."
    echo -e "4. They will automatically appear in your Sway environment!"
fi
