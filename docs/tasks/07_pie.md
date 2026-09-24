# Задание 07. Вкладка «Диаграмма»

Прочитай docs/UI-SPEC.md, раздел 6. Эталон — `renderPie`, `pieHover`, `pieClick`, `renderCrumbs`.

`Sources/TreeSizeApp/PieView.swift` (`import Charts`), секторы — из `store.pieSlices`. Хлебные крошки — отдельной вью `CrumbsView`, она понадобится и в других вкладках.

Проверка:
- `tools/check_task.sh 07 --tab pie`;
- `tools/check_task.sh 07b --tab pie --select /tmp/ts-fixture/media --dark`;
- `tools/check_task.sh 03` — OK.

Замечания приёмки задания 06, которые входят в это задание:
- Вкладка по умолчанию — «Диаграмма», а не «Детали» (при запуске, в режиме снимка без `--tab` и в `--selftest`).
- Полоса вкладок прижата влево с отступом 8 pt (как `.tabs` в эталоне: `padding:6px 8px 0`), а не по центру. Фон полосы — `#f7f9fb` / тёмная `#1f232a`, снизу разделитель.
