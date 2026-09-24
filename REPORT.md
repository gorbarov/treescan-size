
# Задание 13

**Что сделано:**
- ContentView.swift: `Text("TreeSize")` → `Text("TreeBars")` — видимое название в верхней панели
- TreeSizeUIApp.swift: `.windowTitle("TreeBars")` не добавлено, т.к. `.windowTitle` недоступен в macOS 14 / Swift 5.9; заголовок окна и пункт «О программе» подхватываются из Info.plist (`CFBundleName`, `CFBundleDisplayName`)
- `scripts/make_app.sh`: сборка в `build/TreeBars.app`, Info.plist с новыми значениями:
  - `CFBundleIdentifier`: `io.github.gorbarov.treebars`
  - `CFBundleName`/`CFBundleDisplayName`: `TreeBars`
  - `CFBundleExecutable`: `TreeBars`
  - `CFBundleShortVersionString`: `0.1.0`
  - `NSHumanReadableCopyright`: не добавлен, в задании он не обязателен (и не задан); если нужен — `MIT License`
- Кэш и UserDefaults: grep не нашёл упоминаний `TreeSize` в ключах или путях; ничего менять не понадобилось

**Сборка:**
- 1 раз не собралась (`.windowTitle` не доступен), убрал — собралась
- `codesign -v build/TreeBars.app` — OK

**Проверка:**
- `--selftest` совпадает с эталоном 03 — OK
- `tools/check_task.sh 07 --tab pie` — снимок сделан
- `tools/check_task.sh 03` — **ЗАДАНИЕ 03: OK**
- Коммит не удался: git заблокирован песочницей (нет доступа к `~/.gitconfig`)

**Файлы:**
- Изменён: `Sources/TreeSizeApp/ContentView.swift` (1 строка)
- Изменён: `Sources/TreeSizeApp/TreeSizeUIApp.swift` (убрал `.windowTitle`)
- Изменён: `scripts/make_app.sh` (весь блок сборки)
- Создан: `build/TreeBars.app` (рядом со старым `build/TreeSize.app`)
