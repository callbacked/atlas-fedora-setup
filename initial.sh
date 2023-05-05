#!/bin/bash

# Define serial numbers
SERIAL_1TBNVME="2018B4806653"
SERIAL_2TBNVME1="214202800464"
SERIAL_2TBNVME2="214202800499"
SERIAL_2TBHDDSPLIT="WD-WX32D81065UT"

# Get device names based on serial numbers
DEVICE_1=$(sudo smartctl --scan | awk -v serial=$SERIAL_1TBNVME '$3 == serial {print $1}')
DEVICE_2=$(sudo smartctl --scan | awk -v serial=$SERIAL_2TBNVME1 '$3 == serial {print $1}')
DEVICE_3=$(sudo smartctl --scan | awk -v serial=$SERIAL_2TBNVME2 '$3 == serial {print $1}')
DEVICE_4=$(sudo smartctl --scan | awk -v serial=$SERIAL_2TBHDDSPLIT '$3 == serial {print $1}')

# Get UUIDs based on device names and filesystem type
UUID_1=$(sudo blkid -s UUID -o value $(lsblk -o NAME,FSTYPE $DEVICE_1 | awk '$2 == "ext4" {print "/dev/"$1}'))
UUID_2=$(sudo blkid -s UUID -o value $(lsblk -o NAME,FSTYPE $DEVICE_2 | awk '$2 == "ext4" {print "/dev/"$1}'))
UUID_3=$(sudo blkid -s UUID -o value $(lsblk -o NAME,FSTYPE $DEVICE_3 | awk '$2 == "ext4" {print "/dev/"$1}'))
UUID_4=$(sudo blkid -s UUID -o value $(lsblk -o NAME,FSTYPE $DEVICE_4 | awk '$2 == "ext4" {print "/dev/"$1}'))

# Print the obtained UUIDs
echo "Obtained UUIDs:"
echo "1TBNVME: $UUID_1"
echo "2TBNVME1: $UUID_2"
echo "2TBNVME2: $UUID_3"
echo "2TBHDDSPLIT: $UUID_4"

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

#Installing virtualization stuff
echo "Installing @virtualization"
sudo dnf install @virtualization -y

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

echo "Script completed sucessfully -- reboot recommended for the GPU Driver"
