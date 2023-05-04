#!/bin/bash

# Ask for UUIDs
read -p "Enter UUID for 1TBNVME: " UUID_1
read -p "Enter UUID for 2TBNVME1: " UUID_2
read -p "Enter UUID for 2TBNVME2: " UUID_3
read -p "Enter UUID for 2TBHDDSPLIT: " UUID_4

# Update the system
echo "Updating the system..."
sudo dnf update -y

# Add RPM Fusion repository
echo "Adding RPM Fusion repository..."
sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Update repositories
echo "Updating repositories..."
sudo dnf update -y

# Install NVIDIA drivers
echo "Installing NVIDIA drivers..."
sudo dnf install -y akmod-nvidia
sudo dnf install -y xorg-x11-drv-nvidia-cuda


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

echo "Script completed sucessfully -- reboot recommended for the GPU Driver"
