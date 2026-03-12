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

verify_app() {
    local binary="$1"
    local app_name="$2"
    local run_advice="$3"

    echo -ne "${BLUE}[*] Verifying ${app_name}...${NC} "
    
    # 1. Check if binary exists in PATH
    if ! command -v "$binary" >/dev/null 2>&1; then
        echo -e "${RED}[FAILED]${NC} Binary '$binary' not found in PATH."
        return 1
    fi

    # 2. Check for missing shared libraries (crucial on Alpine)
    # Filter for 'not found' in ldd output
    local missing_libs=$(ldd "$(command -v "$binary")" 2>&1 | grep "not found" || true)
    
    if [ -n "$missing_libs" ]; then
        echo -e "${RED}[FAILED]${NC} Missing dependencies for $app_name:"
        echo "$missing_libs"
        echo -e "${YELLOW}[TIP]${NC} Try installing 'gcompat' or checking edge repositories."
        return 1
    fi

    echo -e "${GREEN}[VIABLE]${NC}"
    echo -e "    ${YELLOW}>> To test manually:${NC} $run_advice"
    return 0
}

echo -e "------------------------------------------------"
if [ "$INSTALL_ZED" = "y" ] || [ "$INSTALL_ZED" = "Y" ]; then
    # Enable edge testing repo specifically for zed if not already there
    if ! grep -q "edge/testing" /etc/apk/repositories; then
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
    fi
    # Install zed and the required compatibility layer
    install_ide "Zed Editor" "apk update && apk add zed gcompat"
    verify_app "zed" "Zed Editor" "Inside Sway, press Mod+Enter and type 'zed'"
fi

if [ "$INSTALL_CODEOSS" = "y" ] || [ "$INSTALL_CODEOSS" = "Y" ]; then
    # Install code-oss from testing
    install_ide "Code OSS" "apk update && apk add code-oss"
    verify_app "code-oss" "Code OSS" "Inside Sway, press Mod+Enter and type 'code-oss'"
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
    verify_app "cliphist" "Cliphist" "Inside Sway, press Mod+c to see clipboard history"
    inject_sway_config "
# --- Added by Config Installer: Cliphist ---
exec wl-paste --watch cliphist store
bindsym \$mod+c exec cliphist list | dmenu | cliphist decode | wl-copy"
fi

if [ "$INSTALL_SCREENSHOTS" = "y" ] || [ "$INSTALL_SCREENSHOTS" = "Y" ]; then
    install_ide "Grim & Slurp" "apk add grim slurp wl-clipboard"
    verify_app "grim" "Grim" "Inside Sway, press Mod+Shift+s to take a screenshot"
    verify_app "slurp" "Slurp" "(Used automatically by your screenshot shortcut)"
    inject_sway_config "
# --- Added by Config Installer: Screenshots ---
bindsym \$mod+Shift+s exec grim -g \"\$(slurp)\" - | wl-copy"
fi

if [ "$INSTALL_HWKEYS" = "y" ] || [ "$INSTALL_HWKEYS" = "Y" ]; then
    install_ide "Hardware Controls" "apk add brightnessctl alsa-utils"
    verify_app "brightnessctl" "Brightness Control" "Press your physical Brightness keys"
    verify_app "amixer" "Audio Control (ALSA)" "Press your physical Volume keys"
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
    verify_app "mako" "Mako Notifications" "Launch with 'mako' and dismiss with Mod+Space"
    inject_sway_config "
# --- Added by Config Installer: Mako ---
exec mako
bindsym \$mod+space exec makoctl dismiss"
fi

if [ "$INSTALL_WAYBAR" = "y" ] || [ "$INSTALL_WAYBAR" = "Y" ]; then
    install_ide "Waybar" "apk add waybar"
    verify_app "waybar" "Waybar" "Log in to Sway to see your new status bar"
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
    verify_app "swaylock" "Swaylock" "Lock manually with 'swaylock -c 000000'"
    verify_app "swayidle" "Swayidle" "(Runs in background to auto-lock after 5 mins)"
    inject_sway_config "
# --- Added by Config Installer: Screen Locker ---
exec swayidle -w \\
    timeout 300 'swaylock -f -c 000000' \\
    timeout 600 'swaymsg \"output * dpms off\"' resume 'swaymsg \"output * dpms on\"' \\
    before-sleep 'swaylock -f -c 000000'"
fi

if [ "$INSTALL_DISTROBOX" = "y" ] || [ "$INSTALL_DISTROBOX" = "Y" ]; then
    echo -e "${BLUE}[*] Setting up Glibc Compatibility Layer (Podman + Distrobox)...${NC}"
    install_ide "Glibc Compatibility Layer" "apk add podman distrobox && rc-update add cgroups boot && rc-service cgroups start"
    verify_app "podman" "Podman" "Required for Distrobox containers"
    verify_app "distrobox" "Distrobox" "Used to run Ubuntu/Debian apps (see instructions below)"

    # Enable rootless podman for the users
    for d in /root /home/*; do
        if [ -d "$d" ]; then
            uname=$(basename "$d")
            if ! grep -q "$uname" /etc/subuid 2>/dev/null; then
                echo "$uname:100000:65536" >> /etc/subuid
                echo "$uname:100000:65536" >> /etc/subgid
            fi
        fi
    done

    # --- Download and execute the dedicated Distrobox app installer ---
    echo -e "\n${CYAN}--- Glibc App Installer (VS Code / Antigravity) ---${NC}"
    if [ ! -f "./alpine-distrobox-apps.sh" ]; then
        echo -e "${YELLOW}>> Downloading alpine-distrobox-apps.sh from GitHub...${NC}"
        if wget -O alpine-distrobox-apps.sh https://raw.githubusercontent.com/LordTomate/alpine_setup/dev/alpine-distrobox-apps.sh; then
            chmod +x alpine-distrobox-apps.sh
            echo -e "${GREEN}[+] Downloaded successfully.${NC}\n"
        else
            echo -e "${RED}[!] ERROR:${NC} Could not download the app installer. Check your internet connection."
            echo -e "${YELLOW}[TIP]${NC} You can re-run it manually later: wget -O alpine-distrobox-apps.sh <URL> && sh alpine-distrobox-apps.sh"
        fi
    fi
    if [ -f "./alpine-distrobox-apps.sh" ]; then
        ./alpine-distrobox-apps.sh
    fi
fi

echo -e "\n${GREEN}[SUCCESS] IDE Installation Phase Completed!${NC}"
echo -e "You can now log into tty1 to start your Sway environment."
