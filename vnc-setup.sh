#!/bin/bash

# Install TigerVNC and related packages
echo "Installing TigerVNC and related packages..."
sudo dnf install -y tigervnc-server tigervnc tigervnc-viewer

# Configure the VNC server
echo "Configuring the VNC server..."
read -p "Enter the display number (e.g., 1): " DISPLAY_NUM
sudo cp /usr/lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:${DISPLAY_NUM}.service

# Substitute the user in the service file
read -p "Enter your username (e.g., alex): " USERNAME
sudo sed -i "s|<USER>|${USERNAME}|g" /etc/systemd/system/vncserver@:${DISPLAY_NUM}.service

# Reload the systemd daemon
sudo systemctl daemon-reload

# Create the VNC password
echo "Setting up the VNC password for user ${USERNAME}..."
sudo -u ${USERNAME} vncpasswd

# Enable and start the VNC server
echo "Enabling and starting the VNC server..."
sudo systemctl enable vncserver@:${DISPLAY_NUM}.service
sudo systemctl start vncserver@:${DISPLAY_NUM}.service

# Configure the firewall to allow VNC connections
echo "Configuring the firewall to allow VNC connections..."
VNC_PORT=$((5900 + DISPLAY_NUM))
sudo firewall-cmd --add-port=${VNC_PORT}/tcp --permanent
sudo firewall-cmd --reload

echo "VNC server setup completed successfully."
