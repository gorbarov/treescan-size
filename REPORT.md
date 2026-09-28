
# Задание 13

**Что сделано:**
- ContentView.swift: `Text("TreeSize")` → `Text("TreeBars")` — видимое название в верхней панели
- TreeSizeUIApp.swift: `.windowTitle("TreeBars")` не добавлено, т.к. `.windowTitle` недоступен в macOS 14 / Swift 5.9; заголовок окна и пункт «О программе» подхватываются из Info.plist (`CFBundleName`, `CFBundleDisplayName`)
- `scripts/make_app.sh`: сборка в `build/TreeBars.app`, Info.plist с новыми значениями:
  - `CFBundleIdentifier`: `io.github.gorbarov.treebars`
  - `CFBundleName`/`CFBundleDisplayName`: `TreeBars`
  - `CFBundleExecutable`: `TreeBars`
  - `CFBundleShortVersionString`: `0.1.0`
  - `NSHumanReadableCopyright`: не добавлен, в задании он не обязателен (и не задан); если нужен — `MIT License`
- Кэш и UserDefaults: grep не нашёл упоминаний `TreeSize` в ключах или путях; ничего менять не понадобилось

**Сборка:**
- 1 раз не собралась (`.windowTitle` не доступен), убрал — собралась
- `codesign -v build/TreeBars.app` — OK

**Проверка:**
- `--selftest` совпадает с эталоном 03 — OK
- `tools/check_task.sh 07 --tab pie` — снимок сделан
- `tools/check_task.sh 03` — **ЗАДАНИЕ 03: OK**
- Коммит не удался: git заблокирован песочницей (нет доступа к `~/.gitconfig`)

**Файлы:**
- Изменён: `Sources/TreeSizeApp/ContentView.swift` (1 строка)
- Изменён: `Sources/TreeSizeApp/TreeSizeUIApp.swift` (убрал `.windowTitle`)
- Изменён: `scripts/make_app.sh` (весь блок сборки)
- Создан: `build/TreeBars.app` (рядом со старым `build/TreeSize.app`)

# Задание 18а

**Что сделано:**
- `AppStore.expanded: Set<Int>` → `Set<String>` — раскрытие хранится по `node.path`.
- Добавлен `selectedPath: String?` — при каждой новой сборке дерева (`result` меняется) выделение восстанавливается по `selectedPath` через `node(at:)`.
- `rescan()` сохраняет `selectedPath` и `expanded` перед сканом, восстанавливает после.
- `node.path` перестал вычисляться рекурсивно: в `Node` добавлено поле `path` (заполняется при `assignPaths()` после `build`).
- `Scanner`: добавлен `_allocBytes` (счётчик занятого места) и публичное `allocBytes`.
- Прогресс-бар: `progress` теперь содержит `(files, alloc, cur)`, добавлены `scanStarted` и `expectedAlloc`. Ожидаемый итог считается через `statfs` (точка монтирования) или `UserDefaults "lastAlloc.*"`.
- Оверлей: `ProgressView` с/без значения, прошедшее время `М:СС`, форматированный прогресс.
- `Scanner.shouldSkip(path:root:)` — статическая функция, пропускает `/System/Volumes/Data` при корне `/`.
- Добавлено `--scanning` в snapshot (снимок оверлея скана).
- `nf()` и `elapsedString()` добавлены в Format.swift.
- Selftest: добавлены факты `shouldskip_*`, `node_at_media_name`, `rebuild_rows_with_expanded_media`.

**Сборка:**
- 1 раз не собралась (`ContentView.swift` compiler type-check timeout) — вынес в подвыражения.
- 1 раз не собралась (UITest.swift — `expanded.contains(mid)` с Int вместо String) — поправил.

**Проверка:**
- `tools/check_task.sh 03` — **ЗАДАНИЕ 03: OK** (все факты эталона совпадают)
- `python3 tools/compare.py /tmp/ts-fixture` — OK: вывод Swift совпадает с эталоном
- `--selftest` — новые факты: shouldskip_root_slash_volumes_data=True, node_at_media_name='media', rebuild_rows_with_expanded_media=14
- `--root /tmp/ts-fixture --select /tmp/ts-fixture/media --tab pie --snapshot /tmp/ts-build/snap_18a.png` — снимок сделан
- `--root /tmp/ts-fixture --scanning --snapshot /tmp/ts-build/snap_18a_scan.png` — снимок оверлея скана сделан

**Файлы:**
- Изменён: `Sources/TreeSizeCore/Model.swift` — path кэширован через assignPaths()
- Изменён: `Sources/TreeSizeCore/Scanner.swift` — allocBytes, shouldSkip
- Изменён: `Sources/TreeSizeCore/Format.swift` — nf(), elapsedString()
- Изменён: `Sources/TreeSizeApp/AppStore.swift` — expanded→Set<String>, selectedPath, node(at:),
  computeExpectedAlloc, progress с alloc и scanStarted, rescan сохраняет пути
- Изменён: `Sources/TreeSizeApp/ContentView.swift` — новый оверлей скана с ProgressView
- Изменён: `Sources/TreeSizeApp/TreeView.swift` — expanded.contains(\.path), scrollTo по пути
- Изменён: `Sources/TreeSizeApp/Snapshot.swift` — takeSnapshotScanning()
- Изменён: `Sources/TreeSizeApp/SelfTest.swift` — новые факты
- Изменён: `Sources/TreeSizeApp/UITest.swift` — expanded с path
- Изменён: `Sources/TreeSizeApp/main.swift` — routing для --scanning
- **18а fix 1**: `findDescendant(by:)` — спуск по префиксу, а не полный обход (зависание вкладки «Дубли» на 9 мин)
- **18а fix 2**: `assignPaths` — разделитель без двойной косой (корень `/` → `//Users` исправлено)
- **18а fix 3**: `NodeMenu` — узел ищется лениво при построении `body`, а не в `init`
