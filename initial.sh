#!/bin/bash

# Ask for UUIDs
read -p "Enter UUID for 1TBNVME: " UUID_1
read -p "Enter UUID for 2TBNVME1: " UUID_2
read -p "Enter UUID for 2TBNVME2: " UUID_3
read -p "Enter UUID for 3TBHDD (the split up part of your HDD btw): " UUID_4

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
flatpak install -y com.visualstudio.code
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

# Install non-flatpak apps
sudo dnf install -y discord

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
mkdir -p /home/alex/3TBHDD

# Change ownership of the directories to user 'alex'
echo "Changing ownership of directories..."
sudo chown alex:alex /home/alex/1TBNVME
sudo chown alex:alex /home/alex/2TBNVME1
sudo chown alex:alex /home/alex/2TBNVME2
sudo chown alex:alex /home/alex/3TBHDD

# Add entries to /etc/fstab
echo "Adding entries to /etc/fstab..."
echo "UUID=\"$UUID_1\" /home/alex/1TBNVME ext4 defaults,x-gvfs-show 0 0" | sudo tee -a /etc/fstab
echo "UUID=\"$UUID_2\" /home/alex/2TBNVME1 ext4 defaults,x-gvfs-show 0 0" | sudo tee -a /etc/fstab
echo "UUID=\"$UUID_3\" /home/alex/2TBNVME2 ext4 defaults,x-gvfs-show 0 0" | sudo tee -a /etc/fstab
echo "UUID=\"$UUID_4\" /home/alex/3TBHDD ext4 defaults,x-gvfs-show 0 0" | sudo tee -a /etc/fstab

# Mount the drives
echo "Mounting the drives..."
sudo mount -a

# Create XDG directories in 3TBHDD
echo "Creating XDG directories in /home/alex/3TBHDD..."
mkdir -p /home/alex/3TBHDD/Desktop
mkdir -p /home/alex/3TBHDD/Documents
mkdir -p /home/alex/3TBHDD/Downloads
mkdir -p /home/alex/3TBHDD/Music
mkdir -p /home/alex/3TBHDD/Pictures
mkdir -p /home/alex/3TBHDD/Public
mkdir -p /home/alex/3TBHDD/Templates
mkdir -p /home/alex/3TBHDD/Videos

# Change the default XDG directories
echo "Changing default XDG directories..."
cat <<EOT > /home/alex/.config/user-dirs.dirs
XDG_DESKTOP_DIR="/home/alex/3TBHDD/Desktop"
XDG_DOCUMENTS_DIR="/home/alex/3TBHDD/Documents"
XDG_DOWNLOAD_DIR="/home/alex/3TBHDD/Downloads"
XDG_MUSIC_DIR="/home/alex/3TBHDD/Music"
XDG_PICTURES_DIR="/home/alex/3TBHDD/Pictures"
XDG_PUBLICSHARE_DIR="/home/alex/3TBHDD/Public"
XDG_TEMPLATES_DIR="/home/alex/3TBHDD/Templates"
XDG_VIDEOS_DIR="/home/alex/3TBHDD/Videos"
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

# Import GPG key and enable the Jellyfin-RPC repository
echo "Importing GPG key and enabling Jellyfin-RPC repository..."
sudo rpm --import https://repo.radical.fun/rpm/gpgkey.pub
echo -e "[jellyfin-rpc]\nname=Jellyfin-RPC\nmetadata_expire=2d\nbaseurl=https://repo.radical.fun/rpm/x86_64/\ngpgkey=https://repo.radical.fun/rpm/gpgkey.pub\nrepo_gpgcheck=1\npkg_gpgcheck=1\nenabled=1" | sudo tee /etc/yum.repos.d/jellyfin-rpc.repo

# Update DNF cache
echo "Updating DNF cache..."
sudo dnf -q makecache -y --disablerepo="*" --enablerepo="jellyfin-rpc"

# Install the Jellyfin-RPC package
echo "Installing Jellyfin-RPC..."
sudo dnf install -y jellyfin-rpc --nogpgcheck

# Create config.json template in ~/jellyfin-rpc/
echo "Creating config.json template..."
mkdir -p ~/jellyfin-rpc/
cat <<EOT > ~/jellyfin-rpc/config.json
{
    "jellyfin": {
        "url": "",
        "api_key": "",
        "username": "",
        "music": {
            "display": ["genres"],
            "separator": "-"
        },
        "movies": {
            "display": ["genres"],
            "separator": "-"
        },
        "self_signed_cert": false,
        "show_simple": false,
        "append_prefix": false,
        "add_divider": false,
        "blacklist": {
            "media_types": [],
            "libraries": []
        }
    },
    "discord": {
        "application_id": "1053747938519679018",
        "buttons": [
            {
                "name": "dynamic",
                "url": "dynamic"
            },
            {
                "name": "dynamic",
                "url": "dynamic"
            }
        ],
        "show_paused": true
    },
    "imgur": {
        "client_id": "asdjdjdg394209fdjs093"
    },
    "images": {
        "enable_images": true,
        "imgur_images": true
    }
}
EOT

# Prompt user for Jellyfin settings
read -p "Enter Jellyfin URL: " JELLYFIN_URL
read -p "Enter Jellyfin API Key: " JELLYFIN_API_KEY
read -p "Enter Jellyfin Username: " JELLYFIN_USERNAME

# Update the config.json with the user input
echo "Updating config.json with user input..."
sed -i "s|\"url\": \"\"|\"url\": \"$JELLYFIN_URL\"|g" ~/jellyfin-rpc/config.json
sed -i "s|\"api_key\": \"\"|\"api_key\": \"$JELLYFIN_API_KEY\"|g" ~/jellyfin-rpc/config.json
sed -i "s|\"username\": \"\"|\"username\": \"$JELLYFIN_USERNAME\"|g" ~/jellyfin-rpc/config.json

echo "Jellyfin-RPC setup complete."

# Create systemd service file
echo "Creating systemd service file..."
cat <<EOT | sudo tee /etc/systemd/system/jellyfin-rpc.service
[Unit]
Description=Jellyfin RPC Service
After=network.target graphical.target

[Service]
Type=simple
User=alex
Environment=XDG_RUNTIME_DIR=/run/user/1000
WorkingDirectory=/home/alex
ExecStart=/usr/bin/jellyfin-rpc -c /home/alex/jellyfin-rpc/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

# Reload systemd daemon and enable the service
echo "Reloading systemd daemon and enabling Jellyfin-RPC service..."
sudo systemctl daemon-reload
sudo systemctl enable jellyfin-rpc.service

echo "Jellyfin-RPC service has been created and enabled."

# Reboot after
echo "Script completed successfully. The system will reboot in 10 seconds to apply changes."

for i in {10..1}; do
  echo -ne "\rRebooting in $i seconds..."
  sleep 1
done

echo -e "\rRebooting now.                      "
sudo reboot


