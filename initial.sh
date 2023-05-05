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

#install virtualization stuff

echo "Installing virtualization tools..."
sudo dnf install -y @virtualization

#enable IOMMU

echo "Enabling Intel IOMMU and iommu=pt in /etc/sysconfig/grub..."
sudo sed -i 's/^GRUB_CMDLINE_LINUX="\(.*\)"$/GRUB_CMDLINE_LINUX="\1 intel_iommu=on iommu=pt"/' /etc/sysconfig/grub

# Update the GRUB configuration
echo "Updating GRUB configuration..."
sudo grub2-mkconfig -o /etc/grub2.cfg


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

# Reboot after
echo "Script completed successfully. The system will reboot in 10 seconds to apply changes."

for i in {10..1}; do
  echo -ne "\rRebooting in $i seconds..."
  sleep 1
done

echo -e "\rRebooting now.                      "
sudo reboot


