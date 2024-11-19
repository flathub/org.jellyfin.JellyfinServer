#!/bin/bash

# TODO: copy command with flatpak location

cat << 'EOF'
# The command below cannot be executed by the app itself from within the sandbox.
# Please copy the script below and execute it to configure automatic updates of ALL Flatpaks on your system.
# ---

unit_selection=(
  flatpak-update.service
  flatpak-update.timer
  flatpak-update-onactive.timer
)

for unit in "${unit_selection[@]}"; do
  systemctl --user --no-pager enable "${unit}" --now
  sleep 1
  systemctl --user --no-pager --full status "${unit}"
done
EOF
