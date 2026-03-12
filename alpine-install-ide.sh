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

echo -e "\n${GREEN}[SUCCESS] IDE Installation Phase Completed!${NC}"
echo -e "You can now log into tty1 to start your Sway environment."
