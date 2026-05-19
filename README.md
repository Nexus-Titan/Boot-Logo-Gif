# Debian Custom GIF Boot Logo Installer 🐧✨

A fully automated Bash script that downloads any `.gif` image from a URL and sets it as your animated boot screen (Plymouth theme) on Debian-based Linux distributions. 

This script bypasses the default Debian "3 dots" boot screen, converts your GIF into a compatible Plymouth animation frame-by-frame, and uses a custom Systemd service to ensure your boot logo displays for **at least 5 seconds** during startup.

## ✨ Features
- **100% Automated:** Installs dependencies, sets up directories, and configures GRUB/initramfs automatically.
- **GIF Support:** Uses ImageMagick to natively extract frames from `.gif` URLs.
- **Auto-Centering:** Calculates your screen resolution dynamically to keep the logo perfectly centered.
- **Forced Display:** Includes a custom `systemd` service that prevents the boot logo from vanishing too quickly on fast SSDs.

## 📋 Prerequisites
- A Debian-based Linux distribution (Debian, Ubuntu, Linux Mint, etc.)
- `sudo` (root) privileges
- An active internet connection (to download dependencies and your GIF)

## 🚀 Installation & Usage

1. **Clone or download the repository:**
   ```bash
   git clone https://github.com/Nexus-Titan/Boot-Logo-Gif.git
   cd Nexus-Titan/Boot-Logo-Gif
   ```

2. **Set your custom GIF:**
   Open the script in a text editor (like `nano`) and replace the `GIF_URL` variable with a direct link to your desired `.gif` file.
   ```bash
   nano install.sh
   ```
   *Change this line:*
   ```bash
   GIF_URL="https://your-link-here.com/your-image.gif"
   ```

3. **Make the script executable:**
   ```bash
   chmod +x install.sh
   ```

4. **Run the installer:**
   ```bash
   sudo ./install.sh
   ```

5. **Reboot your system:**
   ```bash
   sudo reboot
   ```
   *Enjoy your new animated boot logo!*

## ⚙️ How it works (Under the hood)
* **Dependencies:** Installs `plymouth`, `imagemagick`, and `initramfs-tools`.
* **Conversion:** Uses `convert -coalesce` to break down the GIF into optimized `.png` frames.
* **Plymouth:** Generates a custom `.script` and `.plymouth` file.
* **GRUB:** Injects `splash` and `quiet` into `/etc/default/grub` to hide text logs and force the graphical boot.
* **Systemd Timer:** Creates a `plymouth-delay.service` that intentionally pauses the boot sequence for 5 seconds before the display manager takes over, guaranteeing you actually get to see your animation.

## 📝 License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

See the [LICENSE](LICENSE) file for more details.
