#!/bin/bash

# Check if the user is root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

# Stop and disable the VNC server
systemctl disable --now vncserver@:${vnc_display}

# Remove the user mapping
sed -i "/:${vnc_display}=${vnc_user}/d" /etc/tigervnc/vncserver.users

# Remove VNC server packages
dnf remove -y tigervnc-server tigervnc

# Remove firewall rule for VNC server
firewall-cmd --remove-service=vnc-server --permanent
firewall-cmd --reload

echo "VNC server removed."
