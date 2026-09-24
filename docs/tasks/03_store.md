# Задание 03. Состояние приложения (AppStore) и самопроверка без окна

Прочитай docs/UI-SPEC.md, разделы 3, 6 (только выбор секторов), 8 (только фильтры топа и дублей), 9 (только корзина, шаг 2 и откат), 13.

Сделай в `Sources/TreeSizeApp/`:
1. `AppStore.swift` — `@MainActor final class AppStore: ObservableObject` из UI-SPEC 3. Плюс:
   - `func pieSlices(for dir: Node) -> [PieSlice]` — `PieSlice{ node: Node?, title: String, value: Int64, colorIndex: Int? }`; для «Прочее» `node = nil`, `title = "Прочее"`, `colorIndex = nil`;
   - `func topFiles(in dir: Node) -> [TopFile]`, `func dupGroups(in dir: Node) -> [DupGroup]`;
   - `func removeLocal(_ node: Node) -> () -> Void` — вычитание из предков, чистка `top`/`dups`, перевыбор; возвращает замыкание отката. Сам файл **не трогает**.
2. `SelfTest.swift` — `func runSelfTest(root: String) -> [String: Any]`. Синхронный скан (`Scanner` + `scanRoot` с параметрами по умолчанию), создаёт `AppStore`, ставит `result`, **не читая `UserDefaults`**, и собирает факты:
   - `default_mode`: `"alloc"` или `"size"` — режим по умолчанию для этого корня;
   - дальше переключить режим на `.size`;
   - `rows_root`: `visibleRows.count`, когда корень раскрыт;
   - `rows_media_open`: то же после `toggle` папки `media`;
   - `pie`: заголовки `pieSlices(for: корень)`;
   - `first_by_alloc`: имя первого ребёнка корня в режиме `.alloc` (потом вернуть `.size`);
   - `root_size`;
   - `top_media`: `topFiles(in: media).count`;
   - `dups_root`: `dupGroups(in: корень).count`;
   - `view_dir_of_photo`: имя `viewDir` после `select` файла `media/photo.JPG`;
   - `removeLocal(photo.JPG)` → `after_trash_root_size`, `after_trash_media_files`, `after_trash_top_media`;
   - вызвать откат → `after_rollback_root_size`, `after_rollback_media_files`.
3. `main.swift`: если в аргументах есть `--selftest`, взять `--root <папка>`, выполнить `runSelfTest`, напечатать JSON (`JSONSerialization`, `.sortedKeys`) в stdout и выйти `exit(0)`. Без `--selftest` пока напечатать `TreeSizeApp: интерфейс — задание 04` и выйти.

Всё это делается без окна и без SwiftUI-вью. `AppStore` на `@MainActor` вызывай из главного потока (`main.swift` и так в нём).

Проверка: `tools/check_task.sh 03` → `ЗАДАНИЕ 03: OK` (сравниваются значения по ключам из `tools/expected/03_selftest.json`).
