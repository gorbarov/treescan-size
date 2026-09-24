---
title: TreeSize для мака — план сборки для исполнителя
type: project
updated: 2026-09-24
sources: [SPEC.md, ../reference/treesize.py]
agent: claude-code
---

# План сборки TreeSize.app

Сначала прочитай [SPEC.md](SPEC.md) и [AGENTS.md](../AGENTS.md). Этапы идут строго по порядку: следующий начинается, только когда проверка предыдущего прошла. После каждой задачи — коммит `git commit -m "Этап N.M: …"`.

Корень проекта ниже — `PROJECT` = `projects/treesize-mac` внутри воркспейса. Эталон — `reference/treesize.py` (от `PROJECT`).

## Этап 1. Сканер на Swift → JSON как у эталона

### 1.1 Package.swift

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TreeSize",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "tscan", targets: ["tscan"]),
        .executable(name: "TreeSizeApp", targets: ["TreeSizeApp"]),
    ],
    targets: [
        .target(name: "TreeSizeCore"),
        .executableTarget(name: "tscan", dependencies: ["TreeSizeCore"]),
        .executableTarget(name: "TreeSizeApp", dependencies: ["TreeSizeCore"]),
    ]
)
```

Версия инструментов 5.9 выбрана специально: без строгих проверок параллельности Swift 6. Не повышать.

Для этапа 1 в `Sources/TreeSizeApp/main.swift` достаточно заглушки `print("TreeSizeApp: этап 2")`.

### 1.2 `Sources/TreeSizeCore/Scanner.swift`: перенос `Scanner` и `list_dir` из эталона

Переносить построчно, логику не «улучшать». Соответствие:

| Python (эталон) | Swift |
|---|---|
| `os.scandir` + `entry.stat(follow_symlinks=False)` | `opendir`/`readdir` (пропускать `.` и `..`), затем `lstat` на полный путь. **Порядок обхода — как у `readdir`**: от него зависит сворачивание мелочи на лету, и с эталоном вывод совпадёт только при том же порядке. `FileManager.contentsOfDirectory` не использовать |
| `list_dir(path, timeout)` в потоке | `Thread` или `DispatchQueue.global()` делает чтение, основной поток ждёт. Счётчик прочитанных элементов под `NSLock`. Если `timeout` секунд подряд нет новых элементов — папку бросить (`stuck`), зависший поток не ждать |
| `stat.S_ISLNK`, `S_ISDIR` | `(st.st_mode & S_IFMT) == S_IFLNK / S_IFDIR` |
| `s.st_blocks * 512` | `Int64(st.st_blocks) * 512` |
| `st_flags & SF_DATALESS` | `st.st_flags & 0x40000000 != 0` |
| `s.st_mtime` (float) и `int()` при выводе | `st.st_mtimespec.tv_sec` (целые секунды). Будущая дата (`> now + 86400`) → 0 |
| `st_nlink > 1` → set `(st_dev, st_ino)` | то же, `Set<String>` ключей `"\(dev):\(ino)"` |
| `is_ignored(path)` | `getxattr(path, "com.apple.fileprovider.ignore#P", nil, 0, 0, XATTR_NOFOLLOW) >= 0` или то же для `com.dropbox.ignored` |
| `args.one_fs` | не заходить в папку, если `st_dev` ≠ `st_dev` корня |
| `heapq` для топ-1000 | массив и сортировка раз в N вставок — важен результат, не алгоритм |
| `self.dups[(size, ext)]` | словарь по ключу `"\(size)|\(ext)"`, только если `size >= dupMin` |

Константы и правила — те же: `KEEP_FILES_PER_DIR = 400`, `TOP_FILES = 1000`, корзины возраста `AGE_BUCKETS`, извлечение расширения (`0 < dot < len-1` и `len - dot <= 12`, нижний регистр), сворачивание мелочи на лету (`floor = bytes * minShare`, первые 3 всегда остаются), `rest` из 7 полей, `ign` и `selfign`.

Параметры по умолчанию: `minShare = 2e-6`, `dupMin = 5 * 1024 * 1024`, `timeout = 10`, `oneFS = true`.

Прогресс для приложения: публичные `nfiles`, `bytes`, `cur` — читать и писать под `NSLock`.

Рекурсия допустима, глубина папок обычно меньше 100.

### 1.3 `Sources/TreeSizeCore/Report.swift`: сборка `data`

- `func serialize(_ d: Dir, thr: Int64) -> [Any]` — перенос `serialize` эталона один в один.
- `func scanRoot(_ root: String, options: ScanOptions, scanner: Scanner? = nil) -> [String: Any]` — перенос `scan_root`: словарь с ключами из SPEC. Строки возраста — русские, как в эталоне.
- `func renderHTML(data: [String: Any], template: String) -> String`:
  - `JSONSerialization` (без `.prettyPrinted`);
  - в строке заменить `"</"` на `"<\\/"`;
  - вставить вместо `/*__DATA__*/{}`.
- Числа в JSON — целые `Int64`, кроме `took` (Double, один знак после запятой).

### 1.4 `Sources/tscan/main.swift`: консольная утилита

```
tscan <папка> --json out.json [--html out.html --template путь] [--min-share 2e-6] [--dup-min N] [--timeout 10] [--all-fs]
```

Пишет JSON и, если попросили, HTML. Прогресс — в stderr, как у эталона.

### Проверка этапа 1

```bash
swift build -c release
tools/make_fixture.sh /tmp/ts-fixture
python3 tools/compare.py /tmp/ts-fixture
python3 tools/compare.py ~/Downloads
```

- **На фикстуре** нужно `OK`. Расхождения чинить в Swift, не в `compare.py` и не в эталоне.
- **На `~/Downloads`** тоже должно быть `OK`. Если папка поменялась между двумя запусками, повторить.
- **Скорость:** `time .build/release/tscan ~/Library/CloudStorage/Dropbox --json /tmp/d.json` должен уложиться в полтора времени эталона (эталон — около 14 с).

## Этап 2. Окно приложения с WKWebView и мостом

Файлы в `Sources/TreeSizeApp/`:

- `main.swift`:
  ```swift
  import AppKit
  let app = NSApplication.shared
  let delegate = AppDelegate()
  app.delegate = delegate
  app.setActivationPolicy(.regular)
  app.run()
  ```

- `AppDelegate.swift` — окно, меню, загрузка отчёта:
  - Окно 1280×820, минимум 800×500, `setFrameAutosaveName("TreeSizeMain")`, заголовок `TreeSize — <имя корня>` (для `/System/Volumes/Data` — «Macintosh HD»).
  - Меню собрать кодом (`NSMenu`):
    - меню приложения: «О программе», «Выйти» ⌘Q;
    - «Файл»: «Открыть…» ⌘O → JS `document.getElementById('openBtn').click()`; «Пересканировать» ⌘R → JS `runScan(null)`; «Закрыть» ⌘W;
    - «Правка»: стандартные `cut:`/`copy:`/`paste:`/`selectAll:` с `target = nil`, иначе ⌘C/⌘V в поле пути не заработают.
  - Шаблон: `Bundle.main.url(forResource: "template", withExtension: "html")`. Если не нашёлся (запуск через `swift run`) — переменная окружения `TREESIZE_TEMPLATE`, затем `reference/template.html` от текущей папки.
  - Отчёт писать в `~/Library/Caches/TreeSize/report.html` с `data["api"] = "app"` и открывать через `webView.loadFileURL(url, allowingReadAccessTo: папка)`. **Не** `loadHTMLString`: после скана страница делает `location.reload()` и должна перечитать файл.
  - Что сканировать при запуске:
    1. `UserDefaults` ключ `lastRoot`;
    2. иначе `~/Library/CloudStorage/Dropbox`, если есть;
    3. иначе домашняя папка.
  - Пока идёт первый скан, показать страницу-заглушку (`loadHTMLString`): «Сканирую <путь>…» и счётчик. Счётчик обновлять таймером раз в 0,5 с через `evaluateJavaScript` из `scanner.nfiles`/`bytes`/`cur`.
  - Скан — в `DispatchQueue.global(qos: .userInitiated)`, загрузка страницы — на главном потоке.

- `Bridge.swift` — `final class Bridge: NSObject, WKScriptMessageHandlerWithReply`:
  - Регистрация: `config.userContentController.addScriptMessageHandler(bridge, contentWorld: .page, name: "treesize")`.
  - `userContentController(_:didReceive:replyHandler:)`: `message.body` → `[String: Any]`, взять `action` и `path`. Ответ: `replyHandler(["ok": true, "error": NSNull(), ...], nil)` или `["ok": false, "error": "текст"]`.
  - Долгие действия (`scan`, `rescan`) выполнять в фоне и звать `replyHandler` на главном потоке, когда файл отчёта перезаписан. Параллельный второй скан отклонять: «скан уже идёт».
  - Действия:
    - `reveal` → `NSWorkspace.shared.activateFileViewerSelecting([url])`;
    - `trash` → `FileManager.default.trashItem(at:resultingItemURL:)`;
    - `ignore` → `setxattr(path, "com.apple.fileprovider.ignore#P", "1", 1, 0, XATTR_NOFOLLOW)`;
    - `unignore` → `removexattr` для обоих имён атрибута;
    - `copy` → `NSPasteboard.general` (сначала `clearContents()`, потом `setString`);
    - `choose` → `NSOpenPanel`: `canChooseDirectories = true`, `canChooseFiles = false`, `beginSheetModal(for: window)`;
    - `places` → как `places()` в эталоне: том данных `/System/Volumes/Data` под именем «Macintosh HD», смонтированные тома из `/Volumes` кроме ссылки на `/`, типовые папки, всё из `~/Library/CloudStorage`. Объём и свободное место — `URLResourceValues.volumeTotalCapacity` / `volumeAvailableCapacity`.
  - Проверки пути и `protected()` — перенести из `serve()` эталона в `Sources/TreeSizeCore/FileActions.swift`.

- `UIDelegate` (можно в `AppDelegate`): `WKUIDelegate` с `runJavaScriptAlertPanelWithMessage` и `runJavaScriptConfirmPanelWithMessage` через `NSAlert`. **Без него `alert()` и `confirm()` в WKWebView молча не работают**, и корзина никогда не спросит подтверждение.

- Самопроверка — запуск с аргументом `--selftest <папка>`:
  1. просканировать папку;
  2. загрузить отчёт;
  3. дождаться `didFinish`;
  4. выполнить JS `JSON.stringify({nodes: NODES.length, bridge: !!BRIDGE, api: API, places: null})`, затем `apiJ({action:'places'}).then(j => j.places.length)`;
  5. вывести результат в stdout и выйти с кодом 0. Если за 60 с не уложился — выйти с кодом 1.

### Проверка этапа 2

```bash
swift build -c release
.build/release/TreeSizeApp --selftest /tmp/ts-fixture
```

Ожидается JSON с `nodes > 20`, `bridge: true`, `api: "app"` и число мест ≥ 2.

## Этап 3. Сборка .app и иконка

- `scripts/make_icon.swift` — рисует PNG 1024×1024 средствами AppKit (`NSImage` + `NSBezierPath`):
  - фон — скруглённый квадрат, почти белый;
  - три квадрата как в логотипе отчёта: высокий синий `#2a78d6` слева, справа сверху жёлтый `#eda100`, под ним оранжевый `#eb6834`.

  Затем `sips` режет картинку в набор размеров `AppIcon.iconset` (16, 32, 64, 128, 256, 512, 1024 и @2x), `iconutil -c icns` собирает `AppIcon.icns`.
- `scripts/make_app.sh`:
  ```bash
  set -e
  cd "$(dirname "$0")/.."
  swift build -c release --product TreeSizeApp
  APP=build/TreeSize.app
  rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
  cp .build/release/TreeSizeApp "$APP/Contents/MacOS/TreeSize"
  cp reference/template.html "$APP/Contents/Resources/template.html"
  cp build/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
  # Info.plist: CFBundleIdentifier ru.gorbarov.treesize, CFBundleName/DisplayName TreeSize,
  # CFBundleExecutable TreeSize, CFBundlePackageType APPL, CFBundleIconFile AppIcon,
  # CFBundleShortVersionString 0.1, CFBundleVersion 1, LSMinimumSystemVersion 13.0,
  # NSHighResolutionCapable true, NSHumanReadableCopyright "TreeBars authors"
  codesign --force --deep -s - "$APP"
  echo "Готово: $APP"
  ```
  Info.plist писать через `cat <<EOF`, а не через `defaults write`.

### Проверка этапа 3

- `scripts/make_app.sh` отрабатывает без ошибок.
- `build/TreeSize.app/Contents/MacOS/TreeSize --selftest /tmp/ts-fixture` даёт тот же результат, что на этапе 2.
- `codesign -v build/TreeSize.app` молчит (подпись в порядке).
- **В `/Applications` не копировать** — это делает CEO.

## Этап 4. Отчёт исполнителя

Файл `docs/REPORT.md` (с frontmatter):
- что сделано по этапам;
- на какой модели;
- где спотыкался;
- что проверено и чем;
- что осталось.

Ничего не приукрашивать.
