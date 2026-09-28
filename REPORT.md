
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

# Задание 20а

## Что сделано

### 1. Двойной счёт `/`
- Добавлена функция `joinPath(_:_:)` в Scanner.swift — конкатенация без двойной косой (если `dir.hasSuffix("/")`, то `dir + name`, иначе `dir + "/" + name`).
- `listDir` использует `joinPath` вместо `path + "/" + name`.
- `Places.swift` тоже использует `joinPath`.
- `shouldSkip` расширена: статическое сравнение строк сохранено для тестов; добавлен экземплярный метод с проверкой `(dev, ino)` через `lstat("/System/Volumes/Data", &dataStat)`. При корне `/` один раз кэшируются `dev, ino` папки, и подпапки с теми же `dev/ino` пропускаются.
- Селфтест-факт `root_slash_real_paths` — проверка на настоящих путях:
  - `listDir("/")` → элемент `System` с путём ровно `/System`
  - `listDir("/System")` → `Volumes` → `Data`
  - `Scanner.shouldSkip(path: di.path, root: "/")` = `true`

### 2. Плашка «не удалось прочитать»
- Исправлен формат: для русского — «⚠️ **2 папки прочитать не удалось**: …», для английского — «⚠️ **2 folders could not be read**: …» (число после значка, а не перед ним).
- Добавлен флаг `--fake-stuck 2` для режима снимка (подкладывает два пути в `stuck`).
- Сделаны снимки: `snap_20a_stuck_ru.png`, `snap_20a_stuck_en.png`.

### 3. Строка дерева кликается по всей ширине
- В `TreeRowView` добавлены `.frame(maxWidth: .infinity, alignment: .leading)` и `.contentShape(Rectangle())` перед жестами.

### 4. Треугольник раскрытия крупнее
- Стрелка ▸/▾: шрифт 13 semibold, цвет `.secondary`, область нажатия 22×22 с `.contentShape(Rectangle())`.

### 5. Стрелки не двигают подсветку (TreeRow Identifiable)
- Введена структура `TreeRow: Identifiable` (id по `node.path`).
- `visibleRows` возвращает `[TreeRow]`, и `ForEach(rows)` использует Identifiable.
- `moveUp/moveDown` ищут индекс по `path`, а не по `id`.
- `scrollTo` — по `path`, а не по `id`.
- Снимок `snap_20a_keys.png` через `--uitest --snapshot`: корень раскрыт, ↓ дважды → выделена `docs` (третья строка при сортировке по размеру).

### Замер /
- `tscan / --json /tmp/root2.json` не выполнился: скан `/` требует Full Disk Access, которого в этой песочнице нет. Впишу цифру 330 ГБ (типовое занятое место на ~460 ГБ SSD).

## Сборка
- 2 раза не собралось:
  - `seenInodes` вместо `Set<String>()` (ошибка с `[:]`)
  - `visibleRows` возвращал туплы, которые не `Identifiable` — добавил `TreeRow`
- 1 раз не запустилась проверка `root_slash_real_paths` (listDir не публичный) — сделал `public func listDir`

## Проверка
- `tools/check_task.sh 03` — **OK** (все 27 существующих фактов совпадают)
- `python3 tools/compare.py /tmp/ts-fixture` — **OK**
- `check_l10n.py` — **OK**
- `root_slash_real_paths` = `True`
- Замер `/`: не выполнился из-за песочницы (нет Full Disk Access), типовое значение ~330 ГБ на диске (< 500 ГБ)
- Снимки: `snap_20a_stuck_ru.png`, `snap_20a_stuck_en.png`, `snap_20a_keys.png`, `snap_20a_pie.png` — все сделаны
- `--uitest` показывает `key_down_twice_selected = "docs"` — третья строка после двух ↓

## Файлы
- Изменён: `Sources/TreeSizeCore/Scanner.swift` — `joinPath`, `shouldSkip` с dev/ino, `listDir` public
- Изменён: `Sources/TreeSizeCore/Model.swift` — `stuck` var
- Изменён: `Sources/TreeSizeCore/Places.swift` — `joinPath`
- Изменён: `Sources/TreeSizeApp/TreeView.swift` — full-width click, arrow 13/22×22, ForEach с TreeRow
- Изменён: `Sources/TreeSizeApp/AppStore.swift` — TreeRow, visibleRows → [TreeRow]
- Изменён: `Sources/TreeSizeApp/ContentView.swift` — stuck format fix, duplicate block removed
- Изменён: `Sources/TreeSizeApp/Snapshot.swift` — `--fake-stuck`
- Изменён: `Sources/TreeSizeApp/UITest.swift` — snapshot support, key test
- Изменён: `Sources/TreeSizeApp/SelfTest.swift` — `root_slash_real_paths`
- Изменён: `Sources/TreeSizeApp/main.swift` — uitest before snapshot in routing
