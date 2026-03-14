# Alpine Linux Setup Environment

This repository contains an automated setup script (`setup.sh`) to quickly bootstrap a fresh Alpine Linux installation with a pre-configured graphical environment and essential tools.

## Included Stack

- **Window Manager:** sway (Wayland proxy for i3wm)
- **Terminal:** foot (Wayland-native), dmenu (App Launcher)
- **File Manager:** ranger
- **Browser:** LibreWolf (with Tridactyl extension force-installed)
- **Editor:** neovim
- **PDF Viewer:** zathura
- **Media:** cmus
- **System Services:** nftables (Firewall), dnscrypt-proxy (DNS proxy), acpid (ACPI events)
- **Login:** tty1 auto-start (No Display Manager)

---

## Resource Usage (Approximate)

> Values are estimates based on Alpine package sizes and typical idle RSS. Actual numbers vary with hardware and usage.

### Base Stack (`setup.sh`)

| Component | Disk | Idle RAM |
|---|---|---|
| Alpine base | ~150 MB | ~15 MB |
| Sway + Wayland stack | ~60 MB | ~30 MB |
| foot (terminal) | ~5 MB | ~15 MB |
| LibreWolf (browser) | ~180 MB | ~250–500 MB |
| neovim + zathura + cmus | ~35 MB | ~15 MB |
| nftables + dnscrypt-proxy + acpid | ~10 MB | ~20 MB |
| **Total (base, Sway idle)** | **~450 MB** | **~80 MB** |
| **Total (LibreWolf open)** | —  | **~380 MB** |

### Optional Tools (`ide.sh` menu)

| Option | Tool | Extra Disk | Extra RAM |
|---|---|---|---|
| [1] | Zed Editor | ~100 MB | ~150 MB |
| [2] | Code OSS | ~300 MB | ~350 MB |
| [3] | cliphist | ~2 MB | ~5 MB |
| [4] | grim + slurp | ~2 MB | negligible |
| [5] | brightnessctl + alsa-utils | ~5 MB | ~2 MB |
| [6] | mako | ~2 MB | ~5 MB |
| [7] | waybar | ~10 MB | ~15 MB |
| [8] | swaylock + swayidle | ~3 MB | ~5 MB |
| [9] | Podman + Distrobox | ~80 MB | ~30 MB |
| [9]+VS Code | Ubuntu container + VS Code | +1.5 GB | ~400 MB |
| [9]+Antigravity | Ubuntu container + Antigravity | +1.5 GB | ~300 MB |

---

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
wget -O setup.sh https://raw.githubusercontent.com/LordTomate/AlpSup/main/setup.sh
```

**Option 2. Download the IDE Master Installer** (which runs the basic setup automatically):
```sh
wget -O ide.sh https://raw.githubusercontent.com/LordTomate/AlpSup/main/ide.sh
```
In the following steps, we will use the Master Installer script.
*(Alternatively, if you are transferring the files manually over SSH, you can copy them from your host machine):*
```sh
# Run this from your local machine while SSH is enabled on Alpine
scp ide.sh root@<alpine-ip-address>:/root/
```

### 2. Make the Scripts Executable

Navigate to the directory where the scripts are located and grant execution permissions:

```sh
chmod +x ide.sh
./ide.sh
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
./ide.sh
```
*(If you are logged as a normal user and have sudo configured, run `sudo ./ide.sh`)*

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

Once the script completes successfully, start your graphical environment:

---

## Starting the GUI (TTY1)

> **Alpine has no display manager.** Sway is launched manually from the text login screen.

1. **Switch to TTY1**: Press **`Ctrl + Alt + F1`** (you may already be on it after a fresh boot).
2. **Log in** with your regular (non-root) user account. Type your username, press Enter, then your password.
3. **Sway starts automatically** — your `.profile` runs `exec sway` the moment you log in on TTY1. You will see a black screen for 1–2 seconds, then your desktop appears.

> **First boot test**: On the very first login, **LibreWolf will launch automatically** to confirm your Wayland stack is working.

---

## Using LibreWolf

| Action | Key |
|---|---|
| **Open a terminal** (foot) | `Mod + Enter` |
| **Launch LibreWolf manually** | Inside foot, type `librewolf` and press Enter |
| **Close any window** | `Mod + Shift + q` |
| **Open app launcher** | `Mod + d` |

> `Mod` = your **Super / Windows / Command (⌘)** key.  
> LibreWolf does **not** need Flatpak — it is installed natively via `apk`.

---

## Battery Display (Akku)

If you installed **Waybar** (option [7]), add a battery module to its config:

```sh
mkdir -p ~/.config/waybar
cat >> ~/.config/waybar/config << 'EOF'
{
    "modules-right": ["battery", "clock"],
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""],
        "states": { "warning": 30, "critical": 10 }
    }
}
EOF
```
Then reload Sway config: `Mod + Shift + c`

---

## Troubleshooting: "zed not found in PATH"

Zed installs its binary at `/usr/lib/zed/zed` on Alpine, with a wrapper at `/usr/bin/zed`. If verification fails:

```sh
# Check where zed actually is
apk info -L zed | grep bin

# If /usr/bin/zed exists but is not executable:
chmod +x /usr/bin/zed

# If missing glibc compatibility:
apk add gcompat libc6-compat
```

---

## Using Zed Editor (option [1])

| Action | Command |
|---|---|
| **Launch** | `Mod + Enter` → type `zed` → Enter |
| **Open a file** | `zed /path/to/file` |
| **Open a folder** | `zed /path/to/project` |
| **Close window** | `Mod + Shift + q` |

> Zed requires `gcompat` (glibc compatibility layer). If it crashes on launch, run: `apk add gcompat libc6-compat`

---

## Using Code OSS (option [2])

| Action | Command |
|---|---|
| **Launch** | `Mod + Enter` → type `code-oss` → Enter |
| **Open a folder** | `code-oss /path/to/project` |
| **Close window** | `Mod + Shift + q` |

> Code OSS is the telemetry-free VS Code build. It does **not** have access to Microsoft's extension marketplace — use [Open VSX](https://open-vsx.org) instead for extensions.

---

## Using Distrobox Containers (option [9])

Distrobox runs a full Ubuntu container that shares your Wayland display and home folder. Apps installed inside appear as if they are native.

### Managing your container

```sh
distrobox enter ubuntu-dev       # Enter the Ubuntu shell
distrobox list                   # Show all containers
distrobox stop ubuntu-dev        # Stop the container
distrobox rm ubuntu-dev          # Delete the container entirely
distrobox upgrade ubuntu-dev     # Upgrade packages inside
```

### Using VS Code from a container

| Action | Command |
|---|---|
| **Launch (from host terminal)** | `code` |
| **Launch (from inside container)** | `distrobox enter ubuntu-dev -- code` |
| **Close** | `Mod + Shift + q` or `Ctrl + q` |

> VS Code in Distrobox has full access to the official **Microsoft extension marketplace** and Copilot.  
> ⚠️ It sends telemetry to Microsoft by default. Disable via: `File → Preferences → Telemetry → off`

### Using Antigravity from a container

| Action | Command |
|---|---|
| **Launch (from host terminal)** | `antigravity` |
| **Launch (from inside container)** | `distrobox enter ubuntu-dev -- antigravity` |
| **Close** | `Mod + Shift + q` |

### Container storage & data

- Your **home directory is shared** between Alpine host and the container — files you create inside are accessible outside and vice versa.
- Container system files (Ubuntu root) live at `~/.local/share/containers/`. Delete the container with `distrobox rm` to reclaim this space (~1.5 GB).
- **Network** passes straight through the host — dnscrypt-proxy and nftables apply to container traffic too.
