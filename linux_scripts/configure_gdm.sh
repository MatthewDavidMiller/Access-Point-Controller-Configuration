#!/bin/bash

# Script to configure gdm

# Get username
user_name=$(logname)

# Specify session for gdm to use
read -r -p "Specify session to use. Example: i3 " session

# Enable gdm
systemctl enable gdm.service

# Enable tap to click
gdm gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

# Enable autologin
cat <<EOF > '/etc/gdm/custom.conf'
# Enable automatic login for user
[daemon]
AutomaticLogin=${user_name}
AutomaticLoginEnable=True

EOF

# Setup default session
cat <<EOF > "/var/lib/AccountsService/users/$user_name"
[User]
Language=
Session=${session}
XSession=${session}

EOF
