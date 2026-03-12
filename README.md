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

### 1. Download the Setup Scripts

Log into your fresh Alpine installation. Since you only have a base command line, you can download the scripts directly using `wget` (which is included in Alpine by default).

Run one of the following commands to download the script from GitHub:

**Option 1. Download the basic setup script:**
```sh
wget -O alpine-setup.sh https://raw.githubusercontent.com/LordTomate/alpine_setup/main/alpine-setup.sh
```

**Option 2. Download the IDE Master Installer** (which runs the basic setup automatically):
```sh
wget -O alpine-install-ide.sh https://raw.githubusercontent.com/LordTomate/alpine_setup/main/alpine-install-ide.sh
```
In the following steps, we will use the Master Installer script.
*(Alternatively, if you are transferring the files manually over SSH, you can copy them from your host machine):*
```sh
# Run this from your local machine while SSH is enabled on Alpine
scp alpine-install-ide.sh root@<alpine-ip-address>:/root/
```

### 2. High-Performance IDEs & Power Tools
Run the master installer to selectively install IDEs and Wayland power tools:
```sh
chmod +x alpine-install-ide.sh
./alpine-install-ide.sh
```
The installer features a **multi-select menu** (Titus-style) where you can enter numbers (e.g., `1,3,4,9`) to batch-install:
- **IDEs**: Zed, Code OSS.
- **Power Tools**: `cliphist` (Clipboard), `grim/slurp` (Screenshots), Hardware Key support, `mako` (Notifications), `waybar`, and `swaylock`.
- **Glibc Compatibility**: Option [9] installs **Distrobox + Podman**, allowing you to run a Debian/Ubuntu container to use glibc-only apps like **Antigravity IDE** or official VS Code natively within your Sway environment.

---

## Post-Installation: Running Antigravity/glibc Apps
If you installed the **Glibc Compatibility Layer** ([9]):
1. Open a terminal and create your container: `distrobox create --name ubuntu --image ubuntu:latest`
2. Enter the box: `distrobox enter ubuntu`
3. Download/install your `.deb` or binary (like Antigravity) inside. It will automatically share your Sway Wayland socket and look like a native app.

Run it using:
```sh
./alpine-install-ide.sh
```
*(If you are logged as a normal user and have sudo configured, run `sudo ./alpine-install-ide.sh`)*

The script will present a series of prompts:
1. Optionally wipe existing configurations.
2. Provide your keyboard layout.
3. Choose whether to install **Zed Editor** and **Code OSS** (VS Code Open Source).
4. Optionally self-destruct the setup scripts.

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
