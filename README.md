# Alpine Linux Setup Environment

This repository contains an automated setup script (`alpine-setup.sh`) to quickly bootstrap a fresh Alpine Linux installation with a pre-configured graphical environment and essential tools.

## Included Stack

- **Window Manager:** i3wm (X11)
- **Terminal:** foot (Wayland-native)*, dmenu (App Launcher)
- **File Manager:** ranger
- **Browser:** LibreWolf (with Tridactyl extension force-installed)
- **Editor:** neovim
- **PDF Viewer:** zathura
- **Media:** cmus
- **System Services:** nftables (Firewall), dnscrypt-proxy (DNS proxy)
- **Login:** startx (No Display Manager)

> **Important Note regarding `foot` & `i3wm`:**
> You requested both `foot` (a highly specialized Wayland terminal emulator) and `i3wm` (an X11 window manager). `foot` does not natively run under X11. If you attempt to open a terminal and nothing happens, log out/switch to a virtual terminal (TTY) and install an X11-compatible terminal like `alacritty` or `kitty`. Alternatively, transition your desktop environment to `sway`, which is the Wayland equivalent of `i3wm`.

## Prerequisites

1. A fresh base installation of Alpine Linux.
2. An active internet connection.
3. Root privileges (either by logging in as `root` or using `sudo` if configured).

## How to Initialize

Follow these steps to download and run the setup script on a completely fresh Alpine target:

### 1. Download the Setup Script

Log into your fresh Alpine installation. Since you only have a base command line, you can download the script directly using `wget` (which is included in Alpine by default).

First, ensure this script is hosted somewhere accessible (like a GitHub Gist, a raw file link, or a local HTTP server). Then run:

```sh
wget -O alpine-setup.sh https://link-to-your-hosted-script.sh
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
1. Log in with your standard (non-root) user account.
2. Start the graphical environment by typing:
   ```sh
   startx
   ```
3. Your i3 window manager should launch immediately.
