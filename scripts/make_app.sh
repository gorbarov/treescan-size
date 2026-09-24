#!/bin/zsh
# make_app.sh — сборка TreeSize.app, Info.plist, иконка, подпись
set -e
cd "$(dirname "$0")/.."
B=build
T=/tmp/ts-build

echo "=== Шаг 1: иконка ==="
swift scripts/make_icon.swift 2>&1 | tail -1

echo "=== Шаг 2: сборка бинарника ==="
swift build -c release --disable-sandbox --scratch-path "$T" --product TreeSizeApp 2>&1 | tail -3

echo "=== Шаг 3: собираем .app ==="
mkdir -p "$B/TreeSize.app/Contents/MacOS"
mkdir -p "$B/TreeSize.app/Contents/Resources"

cp -f "$T/release/TreeSizeApp" "$B/TreeSize.app/Contents/MacOS/TreeSize"
cp -f "$B/AppIcon.icns" "$B/TreeSize.app/Contents/Resources/AppIcon.icns"

cat <<EOF > "$B/TreeSize.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>ru.gorbarov.treesize</string>
	<key>CFBundleName</key>
	<string>TreeSize</string>
	<key>CFBundleDisplayName</key>
	<string>TreeSize</string>
	<key>CFBundleExecutable</key>
	<string>TreeSize</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleShortVersionString</key>
	<string>0.1</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
EOF

echo "=== Шаг 4: подпись ==="
codesign --force --deep -s - "$B/TreeSize.app"

echo "=== Готово: $B/TreeSize.app ==="
ls -la "$B/TreeSize.app/Contents/MacOS/TreeSize"
ls -la "$B/TreeSize.app/Contents/Resources/AppIcon.icns"
ls -la "$B/TreeSize.app/Contents/Info.plist"