# Задание 18а. Прогресс-бар скана и раскрытие папок по пути

Подготовка к живому скану (задание 18б): дерево будет перестраиваться во время скана раз в секунду, а номера узлов (`Node.id`) при каждой сборке новые. Поэтому раскрытие и выделение нужно хранить по **пути**, а не по номеру. Заодно — нормальный прогресс-бар.

## 1. Раскрытие и выделение по пути (`Sources/TreeSizeApp/AppStore.swift` и все вью)

- `@Published public var expanded: Set<Int>` → `Set<String>`: храним `node.path` (свойство уже есть в `Model.swift`, строка ~111).
- Добавь `@Published public var selectedPath: String?`. `selected: Node?` оставь, но при каждой новой сборке дерева (`result` меняется) находи узел по `selectedPath` заново: функция `func node(at path: String) -> Node?` — спуск от корня по компонентам пути относительно `result.root`.
- Везде, где сейчас `expanded.contains(x.id)`, `expanded.insert(x.id)`, `expanded.remove(x.id)` — заменить на `x.path`. Найти все места: `grep -rn "expanded" Sources/TreeSizeApp`.
- **Пересканирование** (кнопка «⟳») больше не должно сворачивать дерево: раскрытые пути и выделенный путь сохраняются, после скана выделение восстанавливается по пути (если такого пути больше нет — выделить корень).
- `node.path` при каждой перерисовке не пересчитывай для тысяч строк: если `path` вычисляется подъёмом по `parent`, закэшируй его в `Node` (`public private(set) lazy var` или заполнение при `build`).

## 2. Прогресс-бар (`ContentView.swift`, оверлей скана)

Сейчас в оверлее вместо прошедшего времени выводится `Date().timeIntervalSince1970` — это секунды с 1970 года. Исправь и сделай прогресс-бар.

- В `Scanner` добавь счётчик занятого места `_allocBytes` (под тем же `lock`, рядом с `_bytes`, прибавлять `alloc` каждого файла) и публичное `allocBytes`.
- В `AppStore.progress` добавь `alloc` и время старта `scanStarted: Date`.
- **Ожидаемый итог** (`expectedAlloc: Int64?`), в порядке приоритета:
  1. если корень — точка монтирования (`statfs(path)` и `f_mntonname == path`), то занято на томе: `(f_blocks - f_bfree) * f_bsize`;
  2. иначе если есть прошлый скан этого же корня — `UserDefaults` ключ `"lastAlloc." + path` (записывать после каждого успешного скана `tree.alloc`);
  3. иначе `nil`.
- Оверлей:

```swift
VStack(spacing: 8) {
    Text(tr("Сканирую ") + store.scanPath + tr("…")).fontWeight(.bold)
    if let exp = store.expectedAlloc, exp > 0 {
        ProgressView(value: min(Double(store.progress.alloc) / Double(exp), 1.0)).frame(width: 360)
    } else {
        ProgressView().progressViewStyle(.linear).frame(width: 360)      // без процента — бегущая полоса
    }
    Text(nf(store.progress.files) + tr(" файлов · ") + fmtBytes(store.progress.alloc) + (store.expectedAlloc.map { tr(" из ") + fmtBytes($0) } ?? "") + " · " + elapsed)
        .foregroundColor(.secondary).monospacedDigit()
    Text(store.progress.cur).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1).truncationMode(.head)
}
```

  где `elapsed` — прошедшее время `М:СС` от `scanStarted`, обновляется вместе с прогрессом.
- Новые строки через `tr(...)`; ключ `" из "` уже есть во всех словарях. Если добавишь новые ключи — добавь во все 8 словарей со значением-английским и напиши в отчёте.

## 3. Двойной счёт при скане `/`

CEO выбрал корнем `/` и получил 1,66 ТБ при диске 460 ГБ. Причина: на macOS содержимое тома с данными видно дважды — через фирменные ссылки (`/Users`, `/Applications`, `/Library`, `/private`, `/opt`, `/usr/local`) и через `/System/Volumes/Data`. Скан `/` прошёл оба пути (замер 28.09: `System` — 918 ГБ, из них почти всё — `System/Volumes/Data`; `Users` — 661 ГБ).

- В `Scanner.scan`: если корень скана — `/`, то подпапку `/System/Volumes/Data` **не заходить** (пропустить молча, без пометки `skipped`). Остальное в `/System/Volumes` (VM, Preboot, Update) сканировать как есть — это реально занятое место.
- В `ScanOptions` это правило не выносить: оно всегда включено для корня `/`. Эталон на Python этого не умеет, на фикстуре правило не срабатывает — `compare.py` не меняется.
- Проверка без полного скана диска: в `--selftest` добавь факт, что `Scanner.shouldSkip(path: "/System/Volumes/Data", root: "/") == true` и `== false` для корня `/System/Volumes/Data` и для пути `/System/Volumes/VM`. Сделай такую статическую функцию и используй её в `scan`.

## Проверка

- `tools/check_task.sh 03` и `python3 tools/compare.py /tmp/ts-fixture` — OK.
- `--selftest`: добавь факты: (а) `node(at: "/tmp/ts-fixture/media")` находит узел `media`; (б) после повторной сборки `ScanResult` из тех же данных раскрытый путь `/tmp/ts-fixture/media` по-прежнему раскрыт в `visibleRows`.
- Снимок дерева как раньше: `--root /tmp/ts-fixture --select /tmp/ts-fixture/media --tab pie --snapshot /tmp/ts-build/snap_18a.png`.
- Оверлей скана: добавь в режим снимка флаг `--scanning`, который рисует окно в состоянии «идёт скан» с `progress = (files: 123456, alloc: 45 ГБ)`, `expectedAlloc = 300 ГБ`, прошло 1:07 — снимок `/tmp/ts-build/snap_18a_scan.png`.

Коммит «Задание 18а: прогресс-бар, раскрытие по пути», раздел в конце REPORT.md (только дописать).
