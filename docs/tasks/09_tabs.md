# Задание 09. Вкладки «Расширения», «Возраст файлов», «Топ файлов», «Дубли»

Прочитай docs/UI-SPEC.md, раздел 8. Эталон — `renderExt`, `renderAge`, `renderTop`, `renderDup`.

Четыре файла: `ExtView.swift`, `AgeView.swift`, `TopView.swift`, `DupsView.swift`.

Проверка — четыре снимка:
- `tools/check_task.sh 09e --tab ext`;
- `tools/check_task.sh 09a --tab age`;
- `tools/check_task.sh 09t --tab top`;
- `tools/check_task.sh 09d --tab dups`;

и `tools/check_task.sh 03` — OK.

Замечание приёмки задания 08 (входит сюда): в таблице «Детали» колонка «Изменено» уходит за правый край панели. Уменьши `Имя` до `.width(min: 110, ideal: 140)`, чтобы все 8 колонок помещались. Проверь снимком `tools/check_task.sh 08 --tab details`.
