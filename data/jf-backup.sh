#!/bin/bash

cat << 'EOF'
# This is just a simple script for now.
# The command below cannot be executed by the app itself from within the sandbox.
# Please run the command to backup your data before a release upgrade.
# Remove the data when you are confident that the migration was successful to free up storage space.
# ---\n"

cp -a \
  "${HOME}/.var/app/org.jellyfin.JellyfinServer/" \
  "${HOME}/.var/app/org.jellyfin.JellyfinServer_bak_$(date -I)"
du -hs "${HOME}/.var/app/org.jellyfin.JellyfinServer"*
EOF
