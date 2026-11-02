#!/bin/zsh
set -e
cd "$(dirname "$0")"
APP="Arrange by Penis.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -parse-as-library main.swift -o "$APP/Contents/MacOS/ArrangeByPenis"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Arrange by Penis</string>
  <key>CFBundleDisplayName</key><string>Arrange by Penis</string>
  <key>CFBundleIdentifier</key><string>local.oki.arrangebypenis</string>
  <key>CFBundleExecutable</key><string>ArrangeByPenis</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSAppleEventsUsageDescription</key><string>Die App verschiebt die Icons auf deinem Schreibtisch über den Finder.</string>
</dict></plist>
PLIST
codesign --force --deep -s - "$APP"
echo "Gebaut: $PWD/$APP"
