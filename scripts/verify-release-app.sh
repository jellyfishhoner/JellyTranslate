#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: scripts/verify-release-app.sh /path/to/JellyTranslate.app"
  exit 64
fi

APP_PATH="$1"

if [ ! -d "$APP_PATH" ]; then
  echo "App not found: $APP_PATH"
  exit 66
fi

echo "Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Assessing with Gatekeeper..."
spctl --assess --type execute --verbose "$APP_PATH"

echo "Reading signing authority..."
codesign -dv "$APP_PATH" 2>&1 | sed -n '/Authority=/p;/TeamIdentifier=/p;/Runtime Version=/p'

echo "OK: app passed local signature and Gatekeeper checks."
