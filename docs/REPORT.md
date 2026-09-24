# Отчёт о выполнении

## Задание 05. Дерево с полосками (самое важное)

### Что сделано
- Создан `Sources/TreeSizeApp/Colors.swift` с расширением `Color(hex:)`, `NSColor(hex:)`, и динамическими цветами через `NSColor(name:dynamicProvider:)` для светлой/тёмной темы. Цвета полосок, выделения, иконок — строго по template.html (CSS-переменные `--bar1`, `--bar2`, `--fbar1`, `--fbar2`, `--sel`, `--selLine` и т.д.).
- Создан `Sources/TreeSizeApp/TreeView.swift` — дерево с полосками по образцу `rowHtml()`/`flatten()`/`renderTree()` из эталона:
  - `ScrollViewReader` + `ScrollView` + `LazyVStack` с `.id(node.id)`;
  - отступ `depth * 16 + 4`;
  - стрелка ▸/▾ только у папок с детьми;
  - иконки: папка — жёлтый прямоугольник 16×12 с ушком, файл — 11×14 цвета группы, сводка — пунктирная рамка;
  - **полоска** — ширина = доля от родителя × доступная ширина минус 62pt; градиент для папок, файлов, сводки — как в CSS;
  - размер жирным моноширинные цифры (мин 62pt), имя, `⊘ не синхр.` серым, `☁` фиолетовым если `cloud ≥ size/2` в режиме «Размер»;
  - справа колонка процента 58pt серым;
  - выделение: фон `#d6e6fb` (тёмная `#233a5c`) + синяя полоска 2pt слева.
- Обновлён `ContentView.swift`: заглушка заменена на `TreeView()` в левой части `HSplitView`.
- **Двойной клик**: `.onTapGesture(count: 2)` перед `.onTapGesture(count: 1)` — раскрывает/сворачивает папку.
- **Клавиши**: `.focusable()` + `.onKeyPress` — ↑↓ соседняя строка, → раскрыть/первый ребёнок, ← свернуть/родитель.
- Выделенная строка прокручивается в зону видимости через `ScrollViewReader.proxy.scrollTo`.

### Сколько раз не собиралось
- **3 раза**:
  1. `ShapeStyle` не имеет члена `treeDirBarBorder` — нужно явно `Color.treeDirBarBorder`.
  2. `Group` внутри `GeometryReader` конфликтовал с `TableColumnBuilder.Group` — переделал на отдельный `@ViewBuilder var barShape`.
  3. `ShapeStyle` не имеет члена `treeAggBar` — нужно `Color.treeAggBar`.

### Проверка
- `tools/check_task.sh 05` → «ЗАДАНИЕ 05: снимок готов, его смотрит приёмщик»
- `tools/check_task.sh 05b --select /tmp/ts-fixture/media` → «ЗАДАНИЕ 05b: снимок готов, его смотрит приёмщик» (выделена и раскрыта media)
- `tools/check_task.sh 05d --dark` → «ЗАДАНИЕ 05d: снимок готов, его смотрит приёмщик»
- `tools/check_task.sh 03` → «ЗАДАНИЕ 03: OK»

### Созданные/изменённые файлы
- **Созданы**: `Sources/TreeSizeApp/Colors.swift`, `Sources/TreeSizeApp/TreeView.swift`
- **Изменён**: `Sources/TreeSizeApp/ContentView.swift` (замена заглушки на TreeView)

### Комментарии
- Тёмная тема работает через `NSColor(name:dynamicProvider:)`, как требовано в задании. `--dark` задаёт `window.appearance = .darkAqua`, и `dynamicProvider` определяет тему по `appearance.name`.