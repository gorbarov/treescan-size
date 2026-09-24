# Задание 05. Дерево с полосками (самое важное)

Прочитай docs/UI-SPEC.md, раздел 5, целиком. Эталон — `rowHtml`, `flatten`, стили `.row`, `.row::before`, `.sz`, `.pc`, `.ic` в template.html.

Сделай `Sources/TreeSizeApp/TreeView.swift` и поставь его в левую часть `HSplitView` вместо заглушки. Цвета — через `Color(hex:)` (сделай такое расширение в `Sources/TreeSizeApp/Colors.swift`, с вариантами для тёмной темы через `NSColor(name:dynamicProvider:)`).

Проверка:
- `tools/check_task.sh 05`;
- `tools/check_task.sh 05b --select /tmp/ts-fixture/media` (выделена и раскрыта media);
- `tools/check_task.sh 05d --dark`;
- `tools/check_task.sh 03` — по-прежнему OK.

Три снимка оценит приёмщик. Опиши в отчёте, как сделал двойной клик и клавиши.
