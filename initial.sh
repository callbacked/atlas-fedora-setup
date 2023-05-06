#!/bin/bash

# Ask for UUIDs
read -p "Enter UUID for 1TBNVME: " UUID_1
read -p "Enter UUID for 2TBNVME1: " UUID_2
read -p "Enter UUID for 2TBNVME2: " UUID_3
read -p "Enter UUID for 2TBHDDSPLIT: " UUID_4

# Update the system
echo "Updating the system..."
sudo dnf update -y

# Add RPM Fusion repository and Flatpak
echo "Adding RPM Fusion repository..."
sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
echo "Installing Flatpak..."
sudo dnf install -y flatpak
echo "Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install NVIDIA drivers
echo "Installing NVIDIA drivers..."
sudo dnf install -y akmod-nvidia
sudo dnf install -y xorg-x11-drv-nvidia-cuda

# Install virtualization stuff
echo "Installing virtualization tools..."
sudo dnf install -y @virtualization

# Install Flatpak apps
echo "Installing Flatpak apps..."
flatpak install -y flathub com.discordapp.Discord
flatpak install -y flathub com.valvesoftware.Steam
flatpak install -y flathub sh.cider.Cider
flatpak install -y flathub org.qbittorrent.qBittorrent
flatpak install -y flathub com.mojang.Minecraft
flatpak install -y flathub com.moonlight_stream.Moonlight
flatpak install -y flathub io.mpv.Mpv
flatpak install flathub no.mifi.losslesscut
flatpak install flathub us.zoom.Zoom
sudo dnf install -y steam-devices
sudo dnf install -y flatseal

# Install media codecs and ffmpeg-libs
echo "Installing media codecs and ffmpeg-libs..."
sudo dnf groupupdate -y multimedia sound-and-video --allowerasing
sudo dnf install -y ffmpeg-libs --allowerasing

# Install neofetch (necessary)
echo "Installing neofetch"
sudo dnf install -y neofetch

# Create directories
echo "Creating directories in /home/alex..."
mkdir -p /home/alex/1TBNVME
mkdir -p /home/alex/2TBNVME1
mkdir -p /home/alex/2TBNVME2
mkdir -p /home/alex/2TBHDDSPLIT

# Change ownership of the directories to user 'alex'
echo "Changing ownership of directories..."
sudo chown alex:alex /home/alex/1TBNVME
sudo chown alex:alex /home/alex/2TBNVME1
sudo chown alex:alex /home/alex/2TBNVME2
sudo chown alex:alex /home/alex/2TBHDDSPLIT

# Add entries to /etc/fstab
echo "Adding entries to /etc/fstab..."
echo "UUID=\"$UUID_1\" /home/alex/1TBNVME ext4 defaults,x-gvfs-show 0 0" | sudo tee -a /etc/fstab
echo "UUID=\"$UUID_2\" /home/alex/2TBNVME1 ext4 defaults,x-gvfs-show 0 0" | sudo tee -a /etc/fstab
echo "UUID=\"$UUID_3\" /home/alex/2TBNVME2 ext4 defaults,x-gvfs-show 0 0" | sudo tee -a /etc/fstab
echo "UUID=\"$UUID_4\" /home/alex/2TBHDDSPLIT ext4 defaults,x-gvfs-show 0 0" | sudo tee -a /etc/fstab

# Mount the drives
echo "Mounting the drives..."
sudo mount -a

# Change the default XDG directories
echo "Changing default XDG directories..."
cat <<EOT > /home/alex/.config/user-dirs.dirs
XDG_DESKTOP_DIR="/home/alex/2TBHDDSPLIT/Desktop"
XDG_DOCUMENTS_DIR="/home/alex/2TBHDDSPLIT/Documents"
XDG_DOWNLOAD_DIR="/home/alex/2TBHDDSPLIT/Downloads"
XDG_MUSIC_DIR="/home/alex/2TBHDDSPLIT/Music"
XDG_PICTURES_DIR="/home/alex/2TBHDDSPLIT/Pictures"
XDG_PUBLICSHARE_DIR="/home/alex/2TBHDDSPLIT/Public"
XDG_TEMPLATES_DIR="/home/alex/2TBHDDSPLIT/Templates"
XDG_VIDEOS_DIR="/home/alex/2TBHDDSPLIT/Videos"
EOT

xdg-user-dirs-update

# Delete old XDG folders from /home/alex
echo "Deleting old XDG folders from /home/alex..."
rm -rf /home/alex/Desktop
rm -rf /home/alex/Documents
rm -rf /home/alex/Downloads
rm -rf /home/alex/Music
rm -rf /home/alex/Pictures
rm -rf /home/alex/Public
rm -rf /home/alex/Templates
rm -rf /home/alex/Videos

echo "Old XDG folders have been deleted."

# Install Xrdp and Tigervnc-server
echo "Installing Xrdp and Tigervnc-server..."
dnf -y install xrdp tigervnc-server

# Enable and start Xrdp service
echo "Enabling and starting Xrdp service..."
systemctl enable --now xrdp

# Check if Firewalld is running
if systemctl is-active --quiet firewalld; then
    # Allow RDP port
    echo "Allowing RDP port through the firewall..."
    firewall-cmd --add-port=3389/tcp
    firewall-cmd --runtime-to-permanent
else
    echo "Firewalld is not running, no need to configure the firewall."
fi

echo "Installation and configuration of Xrdp is complete"

# Disabling internal motherboard BT Adapter (already have BT dongle)
VENDOR_ID="8087"
PRODUCT_ID="0026"
UDEV_RULES_FILE="/etc/udev/rules.d/81-bluetooth-hci.rules"

# Check if the udev rule already exists
if grep -q "$VENDOR_ID" "$UDEV_RULES_FILE" && grep -q "$PRODUCT_ID" "$UDEV_RULES_FILE"; then
    echo "Udev rule for disabling Intel Corp. AX201 Bluetooth already exists."
else
    # Create the udev rule to disable the Intel Corp. AX201 Bluetooth
    echo "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"$VENDOR_ID\", ATTRS{idProduct}==\"$PRODUCT_ID\", ATTR{authorized}=\"0\"" >> $UDEV_RULES_FILE
    echo "Udev rule created. Reboot your system for the changes to take effect."
fi

echo "To re-enable the Intel Corp. AX201 Bluetooth, remove or comment out the corresponding line in $UDEV_RULES_FILE and reboot your system."

# Reboot after
echo "Script completed successfully. The system will reboot in 10 seconds to apply changes."

for i in {10..1}; do
  echo -ne "\rRebooting in $i seconds..."
  sleep 1
done

echo -e "\rRebooting now.                      "
sudo reboot


