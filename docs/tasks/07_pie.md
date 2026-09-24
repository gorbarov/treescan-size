# Задание 07. Вкладка «Диаграмма»

Прочитай docs/UI-SPEC.md, раздел 6. Эталон — `renderPie`, `pieHover`, `pieClick`, `renderCrumbs`.

`Sources/TreeSizeApp/PieView.swift` (`import Charts`), секторы — из `store.pieSlices`. Хлебные крошки — отдельной вью `CrumbsView`, она понадобится и в других вкладках.

Проверка:
- `tools/check_task.sh 07 --tab pie`;
- `tools/check_task.sh 07b --tab pie --select /tmp/ts-fixture/media --dark`;
- `tools/check_task.sh 03` — OK.
