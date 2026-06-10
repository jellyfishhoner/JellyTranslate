#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/JellyTranslate/Resources/Info.plist"
SITE_HTML="$ROOT_DIR/site/index.html"
SITE_README="$ROOT_DIR/site/README.md"

APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST")
SITE_VERSION=$(sed -n 's/.*const releaseVersion = "\([^"]*\)".*/\1/p' "$SITE_HTML" | head -n 1)
DOWNLOAD_URL=$(sed -n 's#.*href="\(https://github.com/jellyfishhoner/JellyTranslate/releases/download/[^"]*JellyTranslate-[^"]*-mac.zip\)".*#\1#p' "$SITE_HTML" | head -n 1)
README_URL=$(sed -n 's#^\(https://github.com/jellyfishhoner/JellyTranslate/releases/download/.*JellyTranslate-.*-mac.zip\)$#\1#p' "$SITE_README" | head -n 1)

SITE_VERSION_NORMALIZED=$(printf "%s" "$SITE_VERSION" | sed 's/[[:space:]]alpha$//;s/-alpha$//')
DOWNLOAD_TAG=$(printf "%s" "$DOWNLOAD_URL" | sed -n 's#.*/releases/download/\([^/]*\)/.*#\1#p')
DOWNLOAD_FILE=$(basename "$DOWNLOAD_URL")

EXPECTED_TAG="v${APP_VERSION}-alpha"
EXPECTED_FILE="JellyTranslate-${APP_VERSION}-alpha-mac.zip"
ERRORS=0

fail() {
  echo "ERROR: $1"
  ERRORS=$((ERRORS + 1))
}

echo "JellyTranslate release state"
echo "App version:      $APP_VERSION"
echo "Build number:     $BUILD_NUMBER"
echo "Site version:     $SITE_VERSION"
echo "Download tag:     $DOWNLOAD_TAG"
echo "Download file:    $DOWNLOAD_FILE"
echo

if [ -z "$SITE_VERSION" ]; then
  fail "site releaseVersion is missing in site/index.html"
elif [ "$SITE_VERSION_NORMALIZED" != "$APP_VERSION" ]; then
  fail "site releaseVersion should match app version ($APP_VERSION)"
fi

if [ -z "$DOWNLOAD_URL" ]; then
  fail "download URL is missing in site/index.html"
elif [ "$DOWNLOAD_TAG" != "$EXPECTED_TAG" ]; then
  fail "download tag should be $EXPECTED_TAG"
fi

if [ -n "$DOWNLOAD_URL" ] && [ "$DOWNLOAD_FILE" != "$EXPECTED_FILE" ]; then
  fail "download file should be $EXPECTED_FILE"
fi

if [ -z "$README_URL" ]; then
  fail "download URL note is missing in site/README.md"
elif [ "$README_URL" != "$DOWNLOAD_URL" ]; then
  fail "site/README.md download URL should match site/index.html"
fi

if [ "$ERRORS" -ne 0 ]; then
  echo
  echo "Release state has $ERRORS problem(s)."
  exit 1
fi

echo "OK: app version, site label, download URL, and README note match."
