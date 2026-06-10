#!/bin/sh
set -eu

usage() {
  echo "Usage: scripts/bump-version.sh VERSION [alpha|beta|stable]"
  echo "Example: scripts/bump-version.sh 0.1.1 alpha"
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 64
fi

VERSION="$1"
CHANNEL="${2:-alpha}"

case "$VERSION" in
  *[!0-9.]* | .* | *..* | *.)
    echo "Version must look like 0.1.1"
    exit 64
    ;;
esac

case "$CHANNEL" in
  alpha | beta)
    RELEASE_LABEL="$VERSION $CHANNEL"
    TAG="v$VERSION-$CHANNEL"
    ZIP_FILE="JellyTranslate-$VERSION-$CHANNEL-mac.zip"
    ;;
  stable)
    RELEASE_LABEL="$VERSION"
    TAG="v$VERSION"
    ZIP_FILE="JellyTranslate-$VERSION-mac.zip"
    ;;
  *)
    echo "Channel must be alpha, beta, or stable"
    exit 64
    ;;
esac

ROOT_DIR="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/JellyTranslate/Resources/Info.plist"
SITE_HTML="$ROOT_DIR/site/index.html"
SITE_README="$ROOT_DIR/site/README.md"
DOWNLOAD_URL="https://github.com/jellyfishhoner/JellyTranslate/releases/download/$TAG/$ZIP_FILE"

perl -0pi -e "s#(<key>CFBundleShortVersionString</key>\\s*<string>)[^<]+(</string>)#\${1}$VERSION\${2}#" "$INFO_PLIST"
perl -0pi -e "s#https://github\\.com/jellyfishhoner/JellyTranslate/releases/download/[^/]+/JellyTranslate-[^\"]+-mac\\.zip#$DOWNLOAD_URL#g" "$SITE_HTML"
perl -0pi -e "s#https://github\\.com/jellyfishhoner/JellyTranslate/releases/download/[^/]+/JellyTranslate-[^\\s]+-mac\\.zip#$DOWNLOAD_URL#g" "$SITE_README"
perl -0pi -e "s/const releaseVersion = \"[^\"]+\";/const releaseVersion = \"$RELEASE_LABEL\";/" "$SITE_HTML"
perl -0pi -e "s/>Version [^<]+</>Version $RELEASE_LABEL</" "$SITE_HTML"

echo "Updated JellyTranslate release version:"
echo "App version:   $VERSION"
echo "Site label:    $RELEASE_LABEL"
echo "Git tag:       $TAG"
echo "Download URL:  $DOWNLOAD_URL"
echo

"$ROOT_DIR/scripts/check-release-state.sh"
