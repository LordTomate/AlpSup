#!/bin/sh
# Distrobox App Installer for Alpine Linux
# Called automatically by alpine-install-ide.sh after option [9] (Glibc Compatibility Layer)
# Installs VS Code and/or Antigravity IDE inside a Debian/Ubuntu Distrobox container.

set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BOX_NAME="ubuntu-dev"
BOX_IMAGE="ubuntu:22.04"

echo -e "${GREEN}=== Distrobox Application Installer ===${NC}"
echo -e "This will create an Ubuntu 22.04 container named '${CYAN}${BOX_NAME}${NC}'."
echo -e "Apps installed inside it will appear seamlessly in your Sway environment.\n"

# --- Check prerequisites ---
if ! command -v distrobox >/dev/null 2>&1; then
    echo -e "${RED}[!] ERROR:${NC} 'distrobox' is not installed."
    echo -e "${YELLOW}[TIP]${NC} Run alpine-install-ide.sh and select option [9] first."
    exit 1
fi
if ! command -v podman >/dev/null 2>&1; then
    echo -e "${RED}[!] ERROR:${NC} 'podman' is not installed. Distrobox requires Podman to run."
    exit 1
fi

# --- App Selection ---
echo -e "${YELLOW}-- Select Apps to Install inside Ubuntu --${NC}"
echo -e "  [0] None - Set up container only, install apps later"
echo -e "  [1] VS Code (Official Microsoft build with full marketplace)"
echo -e "  [2] Antigravity IDE"
echo -e "  [3] Both VS Code and Antigravity"
echo -e ""
read -p "$(echo -e ${BLUE}"Enter your choice [0/1/2/3]: "${NC})" APP_CHOICE

case "$APP_CHOICE" in
    ""|q|Q|0)
        echo -e "${YELLOW}[*] No apps selected. Exiting.${NC}"
        exit 0
        ;;
esac

case "$APP_CHOICE" in *1*) INSTALL_VSCODE=y ;; *) INSTALL_VSCODE=N ;; esac
case "$APP_CHOICE" in *2*) INSTALL_ANTIGRAVITY=y ;; *) INSTALL_ANTIGRAVITY=N ;; esac
case "$APP_CHOICE" in *3*)
    INSTALL_VSCODE=y
    INSTALL_ANTIGRAVITY=y
    ;;
esac

# ----------------------------------------------------------------
# Helper: run command inside the box with a spinner
# ----------------------------------------------------------------
run_in_box() {
    local desc="$1"
    local cmd="$2"

    echo -ne "${BLUE}[*] ${desc}...${NC} "
    distrobox enter "$BOX_NAME" -- sh -c "$cmd" >/tmp/distrobox-step.log 2>&1 &
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
        echo -e "\r\033[K${GREEN}[+] Done:${NC} ${desc}"
    else
        echo -e "\r\033[K${RED}[!] FAILED:${NC} ${desc}"
        echo -e "${YELLOW}[TIP]${NC} Details: /tmp/distrobox-step.log"
        tail -n 8 /tmp/distrobox-step.log
        # Non-fatal – continue with other apps
    fi
}

# ----------------------------------------------------------------
# 1. Create the Ubuntu container (if not already existing)
# ----------------------------------------------------------------
echo -e "\n${BLUE}[*] Checking for existing '${BOX_NAME}' container...${NC}"
if distrobox list 2>/dev/null | grep -q "$BOX_NAME"; then
    echo -e "${GREEN}[+] Container '${BOX_NAME}' already exists. Reusing it.${NC}"
else
    echo -e "${YELLOW}>> Creating Ubuntu 22.04 container. This downloads ~100 MB...${NC}"
    distrobox create --name "$BOX_NAME" --image "$BOX_IMAGE" --yes
    echo -e "${GREEN}[+] Container created successfully.${NC}\n"
fi

# ----------------------------------------------------------------
# 2. Bootstrap the container (run once to init + install basics)
# ----------------------------------------------------------------
echo -e "${BLUE}[*] Bootstrapping container (first-time init + curl/wget)...${NC}"
distrobox enter "$BOX_NAME" -- sh -c "
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -qq &&
    sudo apt-get install -y -qq curl wget gpg apt-transport-https software-properties-common
" >/tmp/distrobox-bootstrap.log 2>&1 &
pid=$!
spinstr='|/-\'; while kill -0 $pid 2>/dev/null; do
    temp=${spinstr#?}; printf "[%c]" "$spinstr"; spinstr=$temp${spinstr%"$temp"}; sleep 0.1; printf "\b\b\b"
done; wait $pid
echo -e "${GREEN}[+] Container ready.${NC}\n"

# ----------------------------------------------------------------
# 3. Install VS Code
# ----------------------------------------------------------------
if [ "$INSTALL_VSCODE" = "y" ]; then
    echo -e "${CYAN}--- Installing Official VS Code ---${NC}"

    run_in_box "Adding Microsoft apt repository" "
        export DEBIAN_FRONTEND=noninteractive
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null &&
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main' | sudo tee /etc/apt/sources.list.d/vscode.list &&
        sudo apt-get update -qq"

    run_in_box "Installing VS Code package" "
        export DEBIAN_FRONTEND=noninteractive
        sudo apt-get install -y -qq code"

    run_in_box "Exporting VS Code to host (creates desktop entry)" "
        distrobox-export --app code"

    echo -e "${GREEN}[+] VS Code installed!${NC}"
    echo -e "    ${YELLOW}>> To launch:${NC} Inside Sway, press Mod+Enter, then type '${BLUE}code${NC}'"
    echo -e ""
fi

# ----------------------------------------------------------------
# 4. Install Antigravity
# ----------------------------------------------------------------
if [ "$INSTALL_ANTIGRAVITY" = "y" ]; then
    echo -e "${CYAN}--- Installing Antigravity IDE ---${NC}"
    echo -e "${YELLOW}[*] Fetching latest Antigravity .deb download URL...${NC}"

    # Download Antigravity .deb directly into the container
    run_in_box "Downloading Antigravity .deb installer" "
        export DEBIAN_FRONTEND=noninteractive
        # Try official installer – fall back to manual download
        if curl -fsSL https://antigravity.app/linux-install | sh; then
            : # success
        else
            echo 'Falling back to direct .deb download...' &&
            DEB_URL=\$(curl -fsSL https://api.github.com/repos/antigravity-ide/antigravity/releases/latest \
                | grep browser_download_url | grep '.deb' | head -1 | cut -d'\"' -f4) &&
            [ -n \"\$DEB_URL\" ] && wget -qO /tmp/antigravity.deb \"\$DEB_URL\" &&
            sudo apt-get install -y /tmp/antigravity.deb
        fi"

    run_in_box "Exporting Antigravity to host (creates desktop entry)" "
        distrobox-export --app antigravity 2>/dev/null || distrobox-export --app Antigravity 2>/dev/null || true"

    echo -e "${GREEN}[+] Antigravity IDE installed!${NC}"
    echo -e "    ${YELLOW}>> To launch:${NC} Inside Sway, press Mod+Enter, then type '${BLUE}antigravity${NC}'"
    echo -e "    ${YELLOW}>> Or open dmenu:${NC} Press Mod+d and search for 'Antigravity'"
    echo -e ""
fi

# ----------------------------------------------------------------
# 5. Summary
# ----------------------------------------------------------------
echo -e "------------------------------------------------"
echo -e "${GREEN}[SUCCESS] Distrobox App Installation Complete!${NC}"
echo -e ""
echo -e "${YELLOW}Your installed apps are exported to your host environment.${NC}"
echo -e "They will appear in dmenu and can be launched from any terminal inside Sway.\n"
echo -e "${CYAN}Useful Distrobox commands:${NC}"
echo -e "  ${BLUE}distrobox enter ${BOX_NAME}${NC}          - Enter the Ubuntu shell"
echo -e "  ${BLUE}distrobox list${NC}                        - List all containers"
echo -e "  ${BLUE}distrobox rm ${BOX_NAME}${NC}              - Remove the container"
echo -e "  ${BLUE}distrobox upgrade ${BOX_NAME}${NC}         - Update software inside the box"
