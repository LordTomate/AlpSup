# Alpine Linux Setup Environment

This repository contains an automated setup script (`alpine-setup.sh`) to quickly bootstrap a fresh Alpine Linux installation with a pre-configured graphical environment and essential tools.

## Included Stack

- **Window Manager:** sway (Wayland proxy for i3wm)
- **Terminal:** foot (Wayland-native), dmenu (App Launcher)
- **File Manager:** ranger
- **Browser:** LibreWolf (with Tridactyl extension force-installed)
- **Editor:** neovim
- **PDF Viewer:** zathura
- **Media:** cmus
- **System Services:** nftables (Firewall), dnscrypt-proxy (DNS proxy)
- **Login:** tty1 auto-start (No Display Manager)

## Prerequisites

1. A fresh base installation of Alpine Linux.
2. An active internet connection.
3. Root privileges (either by logging in as `root` or using `sudo` if configured).

## How to Initialize

Follow these steps to download and run the setup script on a completely fresh Alpine target:

### 1. Download the Setup Script

Log into your fresh Alpine installation. Since you only have a base command line, you can download the script directly using `wget` (which is included in Alpine by default).

Run the following command to download the script from GitHub:

```sh
wget -O alpine-setup.sh https://raw.githubusercontent.com/LordTomate/alpine_setup/main/alpine-setup.sh
```

*(Alternatively, if you are transferring the file manually over SSH, you can copy it from your host machine):*
```sh
# Run this from your local machine while SSH is enabled on Alpine
scp alpine-setup.sh root@<alpine-ip-address>:/root/
```

### 2. Make the Script Executable

Navigate to the directory where the script is located and grant execution permissions:

```sh
# Assuming the file is in your current directory
chmod +x alpine-setup.sh
```

### 3. Run the Script

The script must be executed with root privileges to install packages and configure system services.

Run it using:
```sh
./alpine-setup.sh
```
*(If you are logged as a normal user and have sudo configured, run `sudo ./alpine-setup.sh`)*

### 4. Observe the Output

The script executes step-by-step. If any step fails:
- It will **STOP** immediately.
- It will print a clear `[ERROR]` message explaining what broke.
- It will print a `[FIX]` with instructions on how to resolve it.
- It will output the location of a detailed log file (`/tmp/alpine-setup-step.log`) to help you debug perfectly.

### 5. Finalize the Setup

Once the script completes successfully:
1. Log in to `tty1` with your standard (non-root) user account.
2. Your sway window manager (and foot terminal) will automatically start immediately on successful login.
