# Задание 02. Действия над файлами и места (TreeSizeCore)

Эталон — функции `protected`, `places`, `act` и проверки пути в `serve()` файла reference/treesize.py.

Сделай `Sources/TreeSizeCore/FileActions.swift`:
- `public func isProtected(_ path: String) -> Bool` — перенос `protected()` один в один;
- `public func isActionAllowed(path: String, root: String) -> Bool` — как в `serve()`: `abspath` пути, `realpath` его папки; папка — корень или внутри корня (сравнение с `realpath(root)`); путь существует (`lstat`); сам корень запрещён;
- `public func revealInFinder(_ path: String)` — `NSWorkspace.shared.activateFileViewerSelecting` (`import AppKit`);
- `public func moveToTrash(_ path: String) -> String?` — `FileManager.default.trashItem`, затем ждать до 3 с (шагами по 0,1 с), пока путь исчезнет. Возвращает текст ошибки или `nil`;
- `public func setDropboxIgnored(_ path: String, _ on: Bool) -> String?` — `setxattr` / `removexattr` с `XATTR_NOFOLLOW`, имена из эталона (`IGNORE_ATTRS`);
- `public func isDropboxIgnored(_ path: String) -> Bool`;
- `public func copyToPasteboard(_ text: String)`.

И `Sources/TreeSizeCore/Places.swift`:
- `public struct Place { kind ("disk"/"folder"), name, path, total: Int64?, free: Int64? }`;
- `public func listPlaces() -> [Place]` — как `places()` эталона. Объём тома — `URL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])`.

В `Sources/tscan/main.swift` добавь ключ `--actions-check <папка>`. Он печатает строго в формате `tools/expected/02_actions_check.txt`:
- по строке `protected <путь> = true|false` для тех же путей и в том же порядке. В выводе `~` вместо домашней папки; на вход функции подавай полный путь;
- по строке `allowed <путь> = true|false` для тех же путей, `root` = аргумент `--actions-check`;
- последняя строка — `places_at_least_2 = true`, если `listPlaces().count >= 2`.

**Не вызывай** `moveToTrash` и `setDropboxIgnored` в проверке и нигде на реальных файлах.

Проверка: `tools/check_task.sh 02` → `ЗАДАНИЕ 02: OK`.
