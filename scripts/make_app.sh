#!/bin/zsh
# make_app.sh — сборка TreeBars.app, Info.plist, иконка, подпись
set -e
cd "$(dirname "$0")/.."
B=build
T=/tmp/ts-build

echo "=== Шаг 1: иконка ==="
swift scripts/make_icon.swift 2>&1 | tail -1

echo "=== Шаг 2: сборка бинарника ==="
swift build -c release --disable-sandbox --scratch-path "$T" --product TreeSizeApp 2>&1 | tail -3

echo "=== Шаг 3: собираем .app ==="
mkdir -p "$B/TreeBars.app/Contents/MacOS"
mkdir -p "$B/TreeBars.app/Contents/Resources"

cp -f "$T/release/TreeSizeApp" "$B/TreeBars.app/Contents/MacOS/TreeBars"
cp -f "$B/AppIcon.icns" "$B/TreeBars.app/Contents/Resources/AppIcon.icns"

cat <<EOF > "$B/TreeBars.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>io.github.gorbarov.treebars</string>
	<key>CFBundleName</key>
	<string>TreeBars</string>
	<key>CFBundleDisplayName</key>
	<string>TreeBars</string>
	<key>CFBundleExecutable</key>
	<string>TreeBars</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleShortVersionString</key>
	<string>0.1.0</string>
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
codesign --force --deep -s - "$B/TreeBars.app"

echo "=== Готово: $B/TreeBars.app ==="
ls -la "$B/TreeBars.app/Contents/MacOS/TreeBars"
ls -la "$B/TreeBars.app/Contents/Resources/AppIcon.icns"
ls -la "$B/TreeBars.app/Contents/Info.plist"