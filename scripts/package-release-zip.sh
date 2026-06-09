#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: scripts/package-release-zip.sh /path/to/JellyTranslate.app JellyTranslate-VERSION-mac.zip"
  exit 64
fi

APP_PATH="$1"
ZIP_PATH="$2"
APP_DIR="$(dirname "$APP_PATH")"
APP_NAME="$(basename "$APP_PATH")"

if [ ! -d "$APP_PATH" ]; then
  echo "App not found: $APP_PATH"
  exit 66
fi

case "$ZIP_PATH" in
  *.zip) ;;
  *)
    echo "Output file must end with .zip"
    exit 64
    ;;
esac

echo "Creating zip with macOS metadata preserved..."
ditto -c -k --keepParent "$APP_DIR/$APP_NAME" "$ZIP_PATH"

echo "Created: $ZIP_PATH"
shasum -a 256 "$ZIP_PATH"
