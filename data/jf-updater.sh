#!/bin/bash

cat << 'EOF'
# NOTE: Please check the capabilities of your desktop environment before proceeding with this solution.
#
# The command below cannot be executed by the app itself from within the sandbox.
# Please copy the script below and execute it to configure automatic updates of ALL Flatpaks on your system.
# ---

unit_selection=(
  flatpak-update.service
  flatpak-update.timer
  flatpak-update-onactive.service
  flatpak-update-onactive.timer
)

for unit in "${unit_selection[@]}"; do
  cp -v "$(flatpak info --show-location org.jellyfin.JellyfinServer)/files/share/templates/${unit}" \
    "${HOME}/.local/share/systemd/user/${unit}"
  systemctl --user daemon-reload
  systemctl --user --no-pager enable "${unit}" --now
  sleep 1
  systemctl --user --no-pager --full status "${unit}"
done
EOF
