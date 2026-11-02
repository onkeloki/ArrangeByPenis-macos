#!/bin/zsh
# Baut, signiert (Developer ID), notarisiert und veröffentlicht ein GitHub-Release.
# Nutzung: ./release.sh 1.0
set -e
cd "$(dirname "$0")"
VERSION="${1:?Version angeben, z. B. ./release.sh 1.0}"
export VERSION
export SIGN_ID="${SIGN_ID:-Developer ID Application: Marko Luft (GNJRMFRZ53)}"
PROFILE="${NOTARY_PROFILE:-notary}"
APP="Arrange by Penis.app"
ZIP="ArrangeByPenis-$VERSION.zip"

./build.sh
codesign --verify --strict --verbose=2 "$APP"

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"
spctl --assess --type execute --verbose "$APP"

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

gh release create "v$VERSION" "$ZIP" --title "Arrange by Penis $VERSION" --notes-file - <<NOTES
Finder finally gets the sort option it was missing. 🍆

**Download** \`$ZIP\`, unzip, move the app to *Applications* and start it.
The app is signed and notarized by Apple, so it opens without Gatekeeper warnings.

On the first click macOS asks for permission to control Finder. Allow it.
NOTES
echo "Release v$VERSION veröffentlicht."
