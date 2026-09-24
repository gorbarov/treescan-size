# Задание 04. Окно приложения: каркас, запуск скана, снимок

Прочитай docs/UI-SPEC.md, разделы 4, 10, 12, 13.

Сделай в `Sources/TreeSizeApp/`:
1. `TreeSizeUIApp.swift` — `struct TreeSizeUIApp: App` **без** атрибута `@main`. В модуле уже есть `main.swift`, поэтому запуск такой: в `main.swift`, если нет `--selftest` и `--snapshot`, — `NSApplication.shared.setActivationPolicy(.regular)` и `TreeSizeUIApp.main()`.
   - `WindowGroup` с `ContentView`, `.environmentObject(store)`, `.defaultSize(width: 1280, height: 820)`;
   - `.commands`: «Открыть…» ⌘O (пока просто `store.showPlaces = true`) и «Пересканировать» ⌘R (`store.rescan()`);
   - при появлении окна — `store.startInitialScan(args)` по правилам UI-SPEC 12.
2. `ContentView.swift` — каркас сверху вниз, по UI-SPEC 4. Пока вместо сложных частей — заглушки:
   - панель инструментов (логотип, название, путь, кнопки, сегмент режима — настоящие);
   - строка сведений (пока одна строка: имя и размер выделенного);
   - `HSplitView`: слева `Text("дерево — задание 05")`, справа `TabView` с шестью вкладками-заглушками («Диаграмма», «Детали», «Расширения», «Возраст файлов», «Топ файлов», «Дубли»);
   - строка состояния (путь выделенного и справа «Скан … · … с»);
   - оверлей скана с прогрессом (настоящий).
3. `Snapshot.swift` — режим `--snapshot <png>` из UI-SPEC 13:
   - синхронно просканировать `--root`;
   - `AppStore` с результатом; `--select <путь>` и `--tab <имя>` применить, если есть;
   - `NSWindow` 1280×820 с `NSHostingView(rootView: ContentView().environmentObject(store))`, при `--dark` — `window.appearance = NSAppearance(named: .darkAqua)`;
   - вынести за экран, `orderFront`, через 1,5 с (`RunLoop.main.run(until:)`) снять `cacheDisplay` в PNG и `exit(0)`.

   Запуск снимка — через `NSApplication.shared` без `.run()` (`setActivationPolicy(.accessory)`).

Проверка: `tools/check_task.sh 04` — сборка проходит и появляется `/tmp/ts-build/snap_04.png` (не пустой). Картинку оценит приёмщик. Также `tools/check_task.sh 03` должна по-прежнему давать OK.
