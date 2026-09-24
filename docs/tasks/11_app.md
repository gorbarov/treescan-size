# Задание 11. Сборка TreeSize.app и иконка

Сделай:
- `scripts/make_icon.swift` — рисует PNG 1024×1024: скруглённый почти белый квадрат, на нём логотип из трёх квадратов, как в UI-SPEC 4.1. Из него `sips` и `iconutil` собирают `build/AppIcon.icns` (набор размеров 16–1024 и @2x).
- `scripts/make_app.sh`:
  - `swift build -c release --scratch-path /tmp/ts-build --product TreeSizeApp`;
  - собирает `build/TreeSize.app` (`Contents/MacOS/TreeSize`, `Contents/Resources/AppIcon.icns`, `Contents/Info.plist`);
  - Info.plist через `cat <<EOF`: `CFBundleIdentifier` `ru.gorbarov.treesize`, `CFBundleName` и `CFBundleDisplayName` TreeSize, `CFBundleExecutable` TreeSize, `CFBundlePackageType` APPL, `CFBundleIconFile` AppIcon, `CFBundleShortVersionString` 0.1, `CFBundleVersion` 1, `LSMinimumSystemVersion` 14.0, `NSHighResolutionCapable` true;
  - подпись `codesign --force --deep -s -`.

  Старый `build/TreeSize.app` не удаляй командой `rm` (запрещена) — пересобирай поверх: `mkdir -p` и `cp -f`.

Проверка:
- `scripts/make_app.sh`;
- `codesign -v build/TreeSize.app`;
- `build/TreeSize.app/Contents/MacOS/TreeSize --root /tmp/ts-fixture --selftest` даёт тот же JSON, что `tools/check_task.sh 03`.

В `/Applications` не копировать.
