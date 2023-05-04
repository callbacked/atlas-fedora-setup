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

cat << EOF > /etc/systemd/system/vncserver@:1.service
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=forking
User=${vnc_user}
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill %i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver %i
ExecStop=/usr/bin/vncserver -kill %i

[Install]
WantedBy=multi-user.target
EOF

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
