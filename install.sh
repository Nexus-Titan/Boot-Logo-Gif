#!/bin/bash

GIF_URL="https://upload.wikimedia.org/wikipedia/commons/b/b1/Loading_icon.gif"
THEME_NAME="custom-gif-theme"
THEME_DIR="/usr/share/plymouth/themes/$THEME_NAME"

set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root (use sudo)."
  exit 1
fi

echo "==================================================================="
echo " This script will setup an animated GIF as your Debian Boot Logo."
echo " GIF URL: $GIF_URL"
echo "==================================================================="
read -p "Do you want to proceed with the installation? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Installation aborted."
  exit 0
fi

echo -e "\n⏳ Starting installation..."

echo "📦 Installing required dependencies (wget, imagemagick, plymouth)..."
apt-get update -qq
apt-get install -y -qq wget imagemagick plymouth plymouth-themes initramfs-tools grub2-common > /dev/null

echo "📁 Preparing theme directories..."
rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR"

echo "🌐 Downloading GIF..."
if ! wget -q --show-progress -O /tmp/bootlogo.gif "$GIF_URL"; then
    echo "❌ Error: Failed to download the GIF. Please check the URL and your internet connection."
    exit 1
fi

echo "🖼️ Extracting frames from GIF..."
if ! convert -coalesce /tmp/bootlogo.gif "$THEME_DIR/frame_%d.png"; then
    echo "❌ Error: Failed to convert GIF to PNG frames. The GIF file might be corrupted."
    exit 1
fi

FRAME_COUNT=$(ls -1q "$THEME_DIR"/frame_*.png | wc -l)
echo "✅ Extracted $FRAME_COUNT frames."

echo "⚙️ Generating Plymouth configuration files..."
cat << EOF > "$THEME_DIR/${THEME_NAME}.plymouth"
[Plymouth Theme]
Name=Custom Animated GIF
Description=Automatically generated theme from a GIF
ModuleName=script

[script]
ImageDir=$THEME_DIR
ScriptFile=$THEME_DIR/${THEME_NAME}.script
EOF

cat << EOF > "$THEME_DIR/${THEME_NAME}.script"
Window.GetMaxWidth = fun (){ return Window.GetWidth(); };
Window.GetMaxHeight = fun (){ return Window.GetHeight(); };

frame_count = $FRAME_COUNT;
for (i = 0; i < frame_count; i++) {
    frames[i] = Image("frame_" + i + ".png");
}

sprite = Sprite();

progress = 0;
fun refresh_callback () {
    current_frame = Math.Int(progress / 3) % frame_count;
    sprite.SetImage(frames[current_frame]);
    
    sprite.SetX(Window.GetWidth() / 2 - sprite.GetImage().GetWidth() / 2);
    sprite.SetY(Window.GetHeight() / 2 - sprite.GetImage().GetHeight() / 2);
    
    progress++;
}

Plymouth.SetRefreshFunction (refresh_callback);
EOF

echo "🛠️ Configuring GRUB bootloader to enable splash screen..."
GRUB_FILE="/etc/default/grub"
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE"; then
    if ! grep -q 'splash' "$GRUB_FILE"; then
        sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 splash"/' "$GRUB_FILE"
    fi
    if ! grep -q 'quiet' "$GRUB_FILE"; then
        sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 quiet"/' "$GRUB_FILE"
    fi
fi
update-grub > /dev/null

echo "🎨 Applying the new boot theme..."
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$THEME_DIR/${THEME_NAME}.plymouth" 100 > /dev/null
update-alternatives --set default.plymouth "$THEME_DIR/${THEME_NAME}.plymouth" > /dev/null

echo "🔄 Updating initramfs (This might take a minute)..."
update-initramfs -u > /dev/null

rm -f /tmp/bootlogo.gif

echo -e "\n🎉 Success! The animated GIF has been set as your boot logo."
echo "Reboot your computer to see it in action!"
