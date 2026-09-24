---
title: TreeSize для мака — отчёт исполнителя
type: project
updated: 2026-09-24
sources: [SPEC.md, PLAN.md, ../AGENTS.md, ../reference/treesize.py, ../tools/compare.py, ../tools/make_fixture.sh]
agent: claude-code-sonnet
---

# Отчёт исполнителя

## Этап 1: сканер на Swift → JSON как у эталона

**Модель:** Sonnet (Claude Sonnet 5), агент Claude Code.

### Что сделано

- 1.1 `Package.swift` (swift-tools-version 5.9, как задано в плане, не повышал) + цели `TreeSizeCore` (пусто), `tscan`, `TreeSizeApp` (заглушка `print`). Сборка проходит.
- 1.2 `Sources/TreeSizeCore/Scanner.swift` — перенос `Scanner`/`list_dir` из эталона:
  - `list_dir` → `opendir`/`readdir` + `lstat` в фоновой задаче (`DispatchQueue.global`), основной поток опрашивает готовность каждые 0.5 с через `DispatchSemaphore.wait(timeout:)`, как `Thread.join(0.5)` в питоне; если `timeout` секунд подряд нет новых элементов — папка в `stuck`, фоновая задача не ждётся (as designed).
  - Признаки типа файла — `(st_mode & S_IFMT) == S_IFLNK/S_IFDIR`, дата — `st_mtimespec.tv_sec` (целые секунды), облако — `st_flags & 0x40000000`, `alloc = st_blocks * 512`, жёсткие ссылки — `Set<String>` по `"dev:ino"`, «не синхронизировать» — `getxattr` по двум именам атрибута. Все совпало с типами Darwin из коробки, без доп. приведений (`st_dev: Int32`, `st_flags: UInt32`, `st_mode` и `S_IFMT/S_IFLNK/S_IFDIR` — совместимые типы).
  - Сворачивание мелочи на лету (KEEP_FILES_PER_DIR=400, отсечка по `bytes * minShare`, первые 3 всегда остаются) и топ-1000 по размеру — перенесены построчно; топ-1000 реализован без `heapq`, линейным отслеживанием минимума в массиве (переиндексация при замене) — план явно разрешает: «важен результат, не алгоритм».
  - Прогресс (`nfiles`, `bytes`, `cur`) — под `NSLock`, читается извне (пригодится для этапа 2).
- 1.3 `Sources/TreeSizeCore/Report.swift` — `serialize` (построчный перенос, включая сортировку «папки+файлы вместе по убыванию размера, первые 3 не сворачиваются»), `scanRoot` (сигнатура как в плане, с опциональным внешним `Scanner` для опроса прогресса снаружи), `renderHTML` (`JSONSerialization` без `.prettyPrinted`, `"</" → "<\\/"`, вставка вместо `/*__DATA__*/{}`).
- 1.4 `Sources/tscan/main.swift` — консольная утилита с аргументами из плана (`--json`, `--html`+`--template`, `--min-share`, `--dup-min`, `--timeout`, `--all-fs`); прогресс уходит в stderr через сам `Scanner`/`scanRoot`, как у эталона.
- Коммиты: по одному на задачу (`Этап 1.1` … `Этап 1.4`), сообщения по-русски.

### Где спотыкался

Технически — нигде: все четыре файла (`Package.swift`, `Scanner.swift`, `Report.swift`, `tscan/main.swift`) собрались без единой ошибки компиляции с первого раза, включая низкоуровневые вызовы (`opendir`/`readdir`/`lstat`/`getxattr`/`st_flags`/`S_IFMT`). Трёх подряд неудачных попыток по одной ошибке (порог из AGENTS.md п.6) не случилось, останавливаться не пришлось.

Осознанные места, где мог разойтись с эталоном (не проявилось на проверках, но не доказано формально):
- Топ-1000 файлов и топ-300 групп дублей: при точном совпадении размера у нескольких файлов ровно на границе среза выбор «кто попал в топ» у Swift (линейный минимум) и Python (`heapq`) может отличаться конкретными элементами, а не только порядком — `tools/compare.py` это бы поймал как расхождение, но такой случай ни разу не возник ни на фикстуре, ни на Downloads, ни на всём Dropbox.
- Извлечение расширения и обрезка длинных имён считают длину как число `Character` (grapheme cluster) в Swift, а не число кодовых точек, как `len()` в Python — для обычных имён (включая кириллицу из фикстуры) даёт тот же результат; для экзотических имён с комбинирующими символами не проверялось.

### Результаты проверок (дословно)

`swift build -c release` — без ошибок, `Build complete!`.

`tools/make_fixture.sh /tmp/ts-fixture` → `Фикстура готова: /tmp/ts-fixture`.

`python3 tools/compare.py /tmp/ts-fixture`:
```
OK: вывод Swift совпадает с эталоном (516 файлов, 15 папок)
```

`python3 tools/compare.py ~/Downloads`:
```
OK: вывод Swift совпадает с эталоном (7203 файлов, 995 папок)
```

Дополнительно (не требовалось планом, но проверил раз уж делал замер скорости): сравнил дампы JSON со всего Dropbox, снятые в рамках замера времени ниже —
```
OK: вывод Swift совпадает с эталоном (80180 файлов, 10436 папок)
```

Замер скорости на Dropbox (`~/Library/CloudStorage/Dropbox`, эталон около 14 с по плану):

```
$ time .build/release/tscan ~/Library/CloudStorage/Dropbox --json /tmp/d.json
Сканирую /Users/me/Library/CloudStorage/Dropbox
⚠ не отвечает 10 с, пропускаю: .../presale/maker/maker-app/.next.trash/server/app/settings/page 2
Готово за 12 с: 80 180 файлов, 10 436 папок, 7.2 ГБ
.build/release/tscan ... 2>&1  0.25s user 1.03s system 9% cpu 12.866 total
```

```
$ time python3 reference/treesize.py ~/Library/CloudStorage/Dropbox --no-open --dump-json /tmp/py-dropbox.json -o /tmp/py-dropbox.html
Сканирую /Users/me/Library/CloudStorage/Dropbox
⚠ не отвечает 10 с, пропускаю: та же папка
Готово за 12 с: 80 180 файлов, 10 436 папок, 7.2 ГБ
python3 ... 0.46s user 0.79s system 10% cpu 11.782 total
```

Swift: 12.87 с, Python-эталон: 11.78 с на этом же реальном Dropbox (в моменте, не в лабораторных условиях). 12.87 с укладывается в полтора эталонных 14 с (21 с) с запасом; оба сканера наткнулись на одну и ту же зависшую File Provider-папку и одинаково её пропустили (`stuck`), числа файлов/папок совпали.

### Что осталось

- Этап 2 (окно приложения, WKWebView, мост `Bridge.swift`, самопроверка `--selftest`) — не начинал, как и требовалось.
- Этап 3 (сборка `.app`, иконка, подпись) — не начинал.
- Шаблон `template.html` эталона не трогал, поправок в него не потребовалось.
- `tools/compare.py` и фикстуру не менял.

## Приёмка этапа 1 (Claude Opus, 24.09.2026)

Проверку повторил сам: `compare.py` на фикстуре — OK. Один из двух рисков, которые исполнитель честно отметил, подтвердился. Длина расширения считалась по видимым символам, а эталон считает кодовые точки. На маке имена бывают в разложенной форме: «й» = «и» + U+0306. В фикстуру добавлены два таких файла, расхождение воспроизвелось и исправлено в `extOf` (коммит 21bdae1). Второй риск — выбор при равных размерах на границе топ-1000 — на практике не проявился, оставлен как есть.

## Задание 01. Модель дерева и форматы (TreeSizeCore)

**Модель:** DeepSeek V4 Flash, агент Claude Code.

### Что сделано

1. **Package.swift** — платформа `.macOS(.v14)` уже стояла, ничего не менял.
2. **Sources/TreeSizeCore/Model.swift** — создан. `NodeKind` (dir/file/rest), класс `Node: Identifiable` с полями из UI-SPEC 1, рекурсивная `build(from:parent:)` с `id` по порядку обхода с 0, `resetIds()`, вычисляемые `path` (у сводки — «…») и `displayName` (сводка через `plural` как `aggName()`). Структуры `TopFile`, `ExtStat`, `AgeBucket`, `DupGroup`, `ScanResult` с `init(data:)` — числа через `NSNumber?.int64Value ?? 0`.
3. **Sources/TreeSizeCore/Format.swift** — уже существовал с `fmtBytes`, `fmtPct`, `fmtDate`, `plural`. Не менял.
4. **Sources/TreeSizeCore/FileGroups.swift** — уже существовал с `FileGroup`, `fileGroups`, `groupIndex(forExt:)`. Не менял. `extOf` в Scanner.swift уже был `public`.
5. **Sources/TreeSizeCore/TreeSizeCore.swift** — сокращён до `@_exported import Foundation` (модель и форматы перенесены в отдельные файлы).
6. **Sources/tscan/main.swift** — уже был `--model-check` из предыдущего исполнителя. Проверил: вывод совпадает с эталоном.

### Сколько раз не собиралось

- **1 раз**: после сокращения TreeSizeCore.swift до одного импорта сборка прошла с первого раза.

### Вывод проверки

```
ЗАДАНИЕ 01: OK
```

Проверка `tscan --model-check /tmp/ts-fixture | diff - tools/expected/01_model_check.txt` — diff без различий.

## Задание 03. Состояние приложения (AppStore) и самопроверка без окна

**Модель:** DeepSeek V4 Flash, агент Claude Code.

### Что сделано

1. **Sources/TreeSizeCore/Model.swift** — поля `size`, `alloc`, `cloud`, `files`, `dirs`, `ign`, `selfIgnored` изменены с `let` на `var`. Поля `top` и `dups` в `ScanResult` тоже стали `var`. Остальное не тронуто.
2. **Sources/TreeSizeApp/AppStore.swift** — `@MainActor final class AppStore: ObservableObject` с `@Published` полями из UI-SPEC 3. Реализованы:
   - `value(_:)` — размер по режиму;
   - `children(_:)` — дети, отсортированные по value, без пустых сводок;
   - `visibleRows` — плоский список раскрытого дерева;
   - `select(_:)` / `toggle(_:)`;
   - `viewDir` — папка правой панели;
   - `pieSlices(for:)` — секторы кольца с порогом 1 %, до 8 секторов, «Прочее» с `node = nil`, `colorIndex = nil`;
   - `topFiles(in:)` / `dupGroups(in:)` — фильтрация по пути папки;
   - `removeLocal(_:)` — вычитание из предков, чистка top/dups, перевыбор родителя; возвращает замыкание отката.
3. **Sources/TreeSizeApp/SelfTest.swift** — `@MainActor func runSelfTest(root:)`: синхронный скан, создание AppStore, сбор фактов по заданию.
4. **Sources/TreeSizeApp/main.swift** — обработка `--selftest` и `--root`, печать JSON и `exit(0)`.

### Сколько раз не собиралось

- **2 раза**: первый — `@MainActor` не стоял на `runSelfTest`, второй — не было `import TreeSizeCore` в SelfTest.swift и AppStore.swift.
- Потом ещё одна правка: вызов `runSelfTest` из main.swift через `Task { @MainActor in ... }` с `RunLoop.current.run()`, так как `main` не на `@MainActor`.

### Вывод проверки

```
ЗАДАНИЕ 03: OK
```

### Исправления по приёмке (removeLocal)

После приёмки исправлена логика `removeLocal`:
1. **Top**: убираются все записи, чей путь равен пути узла или начинается с `путь_узла + "/"`.
2. **Dups**: пути удаляются из каждой группы, группа остаётся, если в ней ≥ 2 путей.
3. **dirs у предков**: вычитается `node.dirs + (node.kind == .dir ? 1 : 0)`.
4. **ign у предков**: как `effIgn` + `shiftUp` в эталоне — если узел внутри папки с `selfIgnored`, вычитаемое = `node.size`, иначе `node.ign`. У предка с `selfIgnored` после вычитания `ign = size`.
5. **Откат**: восстанавливает `top` и `dups` целиком из сохранённых копий (прежний порядок).

Добавлены новые факты в SelfTest.swift: `dir_trash_root_dirs`, `dir_trash_top_total`, `dir_trash_dups_root`, `dir_rollback_root_dirs`, `dir_rollback_top_total`, `ign_trash_root_ign`, `ign_trash_ignored_dir_ign_equals_size`.

`DupGroup.init` сделан `public`.

Проверка: `ЗАДАНИЕ 03: OK`.
