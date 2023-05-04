#!/bin/bash

# Request confirmation before proceeding
read -p "Are you sure you want to revert the VNC server setup? (y/N) " CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
    echo "Revert cancelled."
    exit 0
fi

# Stop and disable the VNC server service
read -p "Enter the display number you used during the initial setup (e.g., 1): " DISPLAY_NUM
sudo systemctl stop vncserver@:${DISPLAY_NUM}.service
sudo systemctl disable vncserver@:${DISPLAY_NUM}.service

# Remove the VNC server service file
sudo rm /etc/systemd/system/vncserver@:${DISPLAY_NUM}.service

# Reload the systemd daemon
sudo systemctl daemon-reload

# Remove the firewall rule for the VNC server
echo "Removing the firewall rule for the VNC server..."
VNC_PORT=$((5900 + DISPLAY_NUM))
sudo firewall-cmd --remove-port=${VNC_PORT}/tcp --permanent
sudo firewall-cmd --reload

echo "VNC server setup has been reverted successfully."
