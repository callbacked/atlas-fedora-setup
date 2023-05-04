#!/bin/bash

# Check if the user is root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

# Stop and disable the VNC server
systemctl disable --now vncserver@:1.service

# Remove the VNC server configuration
rm -f /etc/systemd/system/vncserver@.service

# Reload systemd configuration
systemctl daemon-reload

# Remove VNC server packages
dnf remove -y tigervnc-server tigervnc

# Remove firewall rule for VNC server
firewall-cmd --remove-service=vnc-server --permanent
firewall-cmd --reload

echo "VNC server removed."
