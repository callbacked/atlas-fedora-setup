#!/bin/bash

# Check if the user is root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

# Install necessary packages
dnf install -y tigervnc-server tigervnc

# Configure the VNC server
cp /usr/lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@.service

# Set the user who will run the VNC server
read -p "Enter the username for the VNC server: " vnc_user
sed -i "s|<USER>|${vnc_user}|g" /etc/systemd/system/vncserver@.service

# Reload systemd configuration
systemctl daemon-reload

# Set a VNC password for the user
su - ${vnc_user} -c "vncpasswd"

# Enable and start the VNC server
systemctl enable --now vncserver@:1.service

# Add firewall rule to allow VNC traffic
firewall-cmd --add-service=vnc-server --permanent
firewall-cmd --reload

echo "VNC server setup completed."
