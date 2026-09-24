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

## Этап 2 (с 24.09.2026): нативный интерфейс — задания для дешёвых моделей

Прежний план этапов 2–3 (WKWebView + мост) отменён: CEO выбрал полностью нативный интерфейс. Что строим — [UI-SPEC.md](UI-SPEC.md). Задания — `docs/tasks/NN_*.md`, общий пролог — `docs/tasks/_preamble.md`.

**Как запускается исполнитель:** `tools/run_executor.sh <модель> docs/tasks/NN_*.md`:
- Claude Code в режиме `-p --bare` с отдельным конфигом `.agent-home`, модель из coding-lite через `your-gateway.example`, ключ `CODING_LITE_KEY`;
- песочница `tools/executor-settings.json`: запись только в проект и `/tmp/ts-*`; `rm`/`mv`/`xattr`/`osascript`/`open`/`curl` запрещены; правка `tools/`, заданий и спецификаций запрещена;
- лог — `docs/runs/*.jsonl`, стоимость — `tools/run_cost.py`.

**Приёмка (Claude):** `tools/check_task.sh NN` сам, снимки окна смотрю глазами, выборочно код. Если не прошло — повторный запуск с уточнением или другая модель, код за исполнителя не пишу.

| № | Задание | Проверка |
|---|---|---|
| 01 | Модель дерева и форматы | вывод = `tools/expected/01_model_check.txt` |
| 02 | Действия над файлами, места | вывод = `tools/expected/02_actions_check.txt` |
| 03 | AppStore и самопроверка без окна | факты = `tools/expected/03_selftest.json` |
| 04 | Окно, каркас, скан с прогрессом, режим снимка | снимок |
| 05 | Дерево с полосками, двойной клик, клавиши | снимки, светлый и тёмный |
| 06 | Строка сведений, плашки, строка состояния | снимок |
| 07 | Круговая диаграмма и хлебные крошки | снимки |
| 08 | Таблица «Детали» | снимок |
| 09 | Расширения, возраст, топ, дубли | 4 снимка |
| 10 | Контекстное меню, корзина, «не синхр.», «Открыть…» | снимок; корзину проверяет CEO |
| 11 | TreeSize.app, иконка, подпись | `make_app.sh`, `codesign -v`, самопроверка из .app |

Статус и расход по заданиям — в [REPORT.md](REPORT.md).
