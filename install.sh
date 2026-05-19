#!/bin/bash

set -e

GIF_URL="https://upload.wikimedia.org/wikipedia/commons/b/b1/Loading_icon.gif"
THEME_NAME="custom-gif-theme"
THEME_DIR="/usr/share/plymouth/themes/$THEME_NAME"

if [ "$EUID" -ne 0 ]; then
  echo "Error: Run as root."
  exit 1
fi

echo "GIF URL: $GIF_URL"
read -p "Proceed? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  exit 0
fi

apt-get update -qq
apt-get install -y -qq wget imagemagick plymouth plymouth-themes initramfs-tools grub2-common systemd > /dev/null

rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR"

wget -q -O /tmp/bootlogo.gif "$GIF_URL"
convert -coalesce /tmp/bootlogo.gif "$THEME_DIR/frame_%d.png"

FRAME_COUNT=$(ls -1q "$THEME_DIR"/frame_*.png | wc -l)

cat << EOF > "$THEME_DIR/${THEME_NAME}.plymouth"
[Plymouth Theme]
Name=Custom Animated GIF
Description=Custom Theme
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

update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$THEME_DIR/${THEME_NAME}.plymouth" 100 > /dev/null
update-alternatives --set default.plymouth "$THEME_DIR/${THEME_NAME}.plymouth" > /dev/null

mkdir -p /etc/plymouth
echo -e "[Daemon]\nTheme=$THEME_NAME\nShowDelay=0" > /etc/plymouth/plymouthd.conf

echo "FRAMEBUFFER=y" > /etc/initramfs-tools/conf.d/splash

GRUB_FILE="/etc/default/grub"
sed -i 's/nosplash//g' "$GRUB_FILE"
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE"; then
    if ! grep -q 'splash' "$GRUB_FILE"; then
        sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 splash"/' "$GRUB_FILE"
    fi
    if ! grep -q 'quiet' "$GRUB_FILE"; then
        sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 quiet"/' "$GRUB_FILE"
    fi
fi
update-grub > /dev/null

cat << EOF > /etc/systemd/system/plymouth-delay.service
[Unit]
Description=Delay Plymouth Quit for 5 seconds
After=plymouth-start.service
Before=plymouth-quit.service display-manager.service

[Service]
Type=oneshot
ExecStart=/bin/sleep 5

[Install]
WantedBy=plymouth-quit.service
EOF

systemctl daemon-reload
systemctl enable plymouth-delay.service > /dev/null 2>&1

plymouth-set-default-theme -R $THEME_NAME > /dev/null 2>&1 || update-initramfs -u > /dev/null

rm -f /tmp/bootlogo.gif
echo "Done. Reboot."
