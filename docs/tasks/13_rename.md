# Задание 13. Новое имя: TreeBars

Проект выходит в открытый доступ. «TreeSize» — торговая марка JAM Software, поэтому у приложения другое имя: **TreeBars** (дерево с полосками). Меняем только то, что видит пользователь, и имя `.app`. Внутренние имена модулей и целей (`TreeSizeCore`, `TreeSizeApp`, `tscan`) **не трогать**, иначе сломается всё.

1. Интерфейс: в верхней панели `Text("TreeSize")` → `Text("TreeBars")`. Заголовок окна и пункт «О программе» — тоже TreeBars. Найди все видимые строки: `grep -rn '"TreeSize' Sources/TreeSizeApp`.
2. `scripts/make_app.sh`: собирать `build/TreeBars.app`, исполняемый файл `Contents/MacOS/TreeBars`, в Info.plist: `CFBundleIdentifier` `io.github.gorbarov.treebars`, `CFBundleName`/`CFBundleDisplayName` `TreeBars`, `CFBundleExecutable` `TreeBars`, `CFBundleShortVersionString` `0.1.0`, `NSHumanReadableCopyright` `MIT License`. Старый `build/TreeSize.app` не удалять (rm запрещён), просто собрать новый рядом.
3. Кэш и настройки: если где-то путь или ключ с `TreeSize` (например, `~/Library/Caches/TreeSize`, ключи UserDefaults), поменяй на `TreeBars`.

Проверка:
- `scripts/make_app.sh`, `codesign -v build/TreeBars.app`;
- `build/TreeBars.app/Contents/MacOS/TreeBars --root /tmp/ts-fixture --selftest` даёт те же факты, что `tools/check_task.sh 03`;
- `tools/check_task.sh 07 --tab pie` (на снимке в шапке «TreeBars»);
- `tools/check_task.sh 03`.

Коммит «Задание 13: имя TreeBars», раздел в конце REPORT.md (только дописать).
