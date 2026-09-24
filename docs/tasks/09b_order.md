# Задание 09b. Порядок топа файлов в сканере и папка файла во вкладке «Топ»

Нашлась ошибка, которую пропускала проверка этапа 1 (теперь она строже):

1. В `Sources/TreeSizeCore/Scanner.swift` функция `topResult()` отдаёт файлы не по порядку. Эталон (`scan_root` в treesize.py): `sorted(sc.top, reverse=True)` — по убыванию размера, при равном размере — по убыванию пути (так сортирует Python кортежи `(size, path, ...)`). Сделай так же. Проверь, что `ext` и `dups` тоже по убыванию (эталон: `ext` по убыванию размера, `dups` по убыванию `size*(n-1)`).
2. Вкладка «Топ файлов» (`TopView.swift`): под именем файла показывается «.», а должна быть папка файла относительно выбранной папки (как `renderTop` в эталоне: `p.slice(cut, slash) || '.'`). Для /tmp/ts-fixture/many/f277.txt при выбранном корне это «many», для /tmp/ts-fixture/sparse/disk.img — «sparse». «.» — только для файлов прямо в выбранной папке.

Проверка:
- `python3 tools/compare.py /tmp/ts-fixture` → `OK` (теперь проверяет и порядок);
- `tools/check_task.sh 09t --tab top` (первым должен быть disk.img, 200 МБ);
- `tools/check_task.sh 01`;
- `tools/check_task.sh 03`.
