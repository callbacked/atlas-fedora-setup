#!/bin/bash

# Check if the user is root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

# Install necessary packages
dnf install -y tigervnc-server tigervnc

# Configure the VNC server
read -p "Enter the username for the VNC server: " vnc_user
read -p "Enter the display number for the VNC server (e.g., 1, 2, ...): " vnc_display

# Add user mapping
echo ":${vnc_display}=${vnc_user}" >> /etc/tigervnc/vncserver.users

# Set a VNC password for the user
su - ${vnc_user} -c "vncpasswd"

# Start the VNC server
systemctl start vncserver@:${vnc_display}

# Enable the VNC server
systemctl enable vncserver@:${vnc_display}

# Add firewall rule to allow VNC traffic
firewall-cmd --add-service=vnc-server --permanent
firewall-cmd --reload

echo "VNC server setup completed."
