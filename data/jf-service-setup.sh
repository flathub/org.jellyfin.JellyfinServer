#!/bin/bash

cat << 'EOF'
# The command below cannot be executed by the app itself from within the sandbox.
# Please copy the script below and execute it to configure automatic updates of ALL Flatpaks on your system.
# ---

# https://wiki.archlinux.org/title/Systemd/User#Automatic_start-up_of_systemd_user_instances
loginctl list-users
loginctl enable-linger $USER
loginctl list-users

unit="jellyfin.service"
cp -v "$(flatpak info --show-location org.jellyfin.JellyfinServer)/files/share/templates/${unit}" \
  "${HOME}/.local/share/systemd/user/${unit}"
# # Override defaults, like starting the app in --user scope.
# mkdir -pv "${HOME}/.local/share/systemd/user/${unit}.d/"
# echo -e "[Service]\nEnvironment=FLATPAK_SCOPE=--user" > "${HOME}/.local/share/systemd/user/${unit}.d/override.conf"
systemctl --user daemon-reload
systemctl --user --no-pager enable "${unit}" --now
sleep 1
systemctl --user --no-pager --full status "${unit}"
EOF
