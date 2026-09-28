#!/bin/zsh
# make_app.sh — сборка .app, Info.plist, иконка, подпись
set -e
cd "$(dirname "$0")/.."
B=build
T=/tmp/ts-build

APP_NAME=$(grep 'static let name' Sources/TreeSizeCore/AppInfo.swift | sed 's/.*"\(.*\)".*/\1/')
BUNDLE_ID=$(grep 'static let bundleID' Sources/TreeSizeCore/AppInfo.swift | sed 's/.*"\(.*\)".*/\1/')
VERSION=$(grep 'static let version' Sources/TreeSizeCore/AppInfo.swift | sed 's/.*"\(.*\)".*/\1/')

# Исполняемый файл — без пробела (TreeScanSize)
EXEC=$(echo "$APP_NAME" | tr -d ' ')

echo "=== Шаг 1: иконка ==="
swift scripts/make_icon.swift 2>&1 | tail -1

echo "=== Шаг 2: сборка бинарника ==="
swift build -c release --disable-sandbox --scratch-path "$T" --product TreeSizeApp 2>&1 | tail -3

echo "=== Шаг 3: собираем .app ==="
APP_DIR="$B/$APP_NAME.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp -f "$T/release/TreeSizeApp" "$APP_DIR/Contents/MacOS/$EXEC"
cp -f "$B/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

# Удаляем старый TreeBars.app, если есть
rm -rf "$B/TreeBars.app"

cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>$BUNDLE_ID</string>
	<key>CFBundleName</key>
	<string>$APP_NAME</string>
	<key>CFBundleDisplayName</key>
	<string>$APP_NAME</string>
	<key>CFBundleExecutable</key>
	<string>$EXEC</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleShortVersionString</key>
	<string>$VERSION</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSHumanReadableCopyright</key>
	<string>MIT License</string>
</dict>
</plist>
EOF

echo "=== Шаг 4: подпись ==="
codesign --force --deep -s - "$APP_DIR"

echo "=== Готово: "$APP_DIR" ==="
ls -la "$APP_DIR/Contents/MacOS/$EXEC"
ls -la "$APP_DIR/Contents/Resources/AppIcon.icns"
ls -la "$APP_DIR/Contents/Info.plist"