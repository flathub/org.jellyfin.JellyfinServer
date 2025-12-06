#!/usr/bin/env bash
set -euo pipefail

# Defaults
XML_FILE="org.jellyfin.JellyfinServer.metainfo.xml"

echo "Please provide information about the new release for the metainfo file ($XML_FILE)."

# Prompt for inputs
read -r -e -i "xx.yy.z" -p "(1/2) Version: " VERSION
if [[ "$VERSION" == "xx.yy.z" ]]; then
  echo "Version is required." >&2
  exit 1
fi

read -r -e -i "Updated Jellyfin and Jellyfin Web to $VERSION" \
  -p "(2/2) Description (will be placed inside a <p> element): " DESC
if [[ -z "$DESC" ]]; then
  echo "Description is required." >&2
  exit 1
fi

# Date in YYYY-MM-DD (matches example)
DATE=$(date +"%Y-%m-%d")

# Create a temporary file for the modified XML
TEMP_FILE=$(mktemp)

# Use xmlstarlet to insert the new release and pretty-print
xmlstarlet ed -P \
  -i "/component/releases/release[1]" -t elem -n "release" \
  -s "/component/releases/release[1]" -t attr -n "version" -v "$VERSION" \
  -s "/component/releases/release[1]" -t attr -n "date" -v "$DATE" \
  -s "/component/releases/release[1]" -t elem -n "description" -v "" \
  -s "/component/releases/release[1]/description" -t elem -n "p" -v "$DESC" \
  "$XML_FILE" | xmlstarlet fo -s 2 > "$TEMP_FILE"

# Replace the original file with the formatted version
mv "$TEMP_FILE" "$XML_FILE"

echo "Added release version=$VERSION date=$DATE to $XML_FILE)"
