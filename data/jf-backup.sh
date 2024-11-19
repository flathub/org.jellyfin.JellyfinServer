#!/bin/bash

echo "# This is just a simple script for now."
echo "# The command below cannot be executed by the app itself from within the sandbox."
echo "# Please run the command to backup your data before a release upgrade."
echo "# Remove the data when you are confident that the migration was successful to free up storage space."
echo -e "# ---\n"

# shellcheck disable=SC2016
echo -e \
  'cp -a \\\n' \
  '  "${HOME}/.var/app/org.jellyfin.JellyfinServer/" \\\n' \
  '  "${HOME}/.var/app/org.jellyfin.JellyfinServer_bak_$(date -I)"'
# shellcheck disable=SC2016
echo 'du -hs "${HOME}/.var/app/org.jellyfin.JellyfinServer"*'
