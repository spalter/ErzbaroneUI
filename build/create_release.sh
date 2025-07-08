#!/bin/bash

# This script creates a release zip file for the ErzbaroneUI addon.
# It should be run from the 'build' directory.

# --- Configuration ---
ADDON_NAME="ErzbaroneUI"
# Get the version from the .toc file
VERSION=$(grep -i '## Version:' ../ErzbaroneUI.toc | awk -F': ' '{print $2}' | tr -d '\r')
ZIP_FILE_NAME="${ADDON_NAME}-v${VERSION}.zip"
SOURCE_DIR=".." # The root directory of the addon, relative to this script
RELEASE_DIR="releases" # Where to put the generated zip file
TEMP_DIR="pkg" # A temporary directory for packaging

# --- Script ---

# Clean up and create directories
rm -rf "$TEMP_DIR"
mkdir -p "$RELEASE_DIR"
mkdir -p "$TEMP_DIR/$ADDON_NAME"

echo "Creating release archive: $RELEASE_DIR/$ZIP_FILE_NAME"

# Copy addon files to the temporary packaging directory
# This ensures the correct structure within the zip
cp -r "$SOURCE_DIR/modules" "$TEMP_DIR/$ADDON_NAME/"
cp -r "$SOURCE_DIR/textures" "$TEMP_DIR/$ADDON_NAME/"
cp "$SOURCE_DIR/ErzbaroneUI.toc" "$TEMP_DIR/$ADDON_NAME/"
cp "$SOURCE_DIR/main.lua" "$TEMP_DIR/$ADDON_NAME/"

# Navigate to the temp directory to create the zip with the correct root folder
cd "$TEMP_DIR" || exit

# Create the zip file
zip -r "../$RELEASE_DIR/$ZIP_FILE_NAME" "$ADDON_NAME" \
    -x "*/.*" -x "*/*.bak" # Exclude hidden files and backup files

# Navigate back to the original directory
cd - > /dev/null || exit

# Clean up the temporary directory
rm -rf "$TEMP_DIR"

echo "Done."