# Задание 01. Модель дерева и форматы (TreeSizeCore)

Прочитай docs/UI-SPEC.md, разделы 1 и 2. Эталон форматов — функции `fmt`, `pctTxt`, `dateTxt`, `plural`, `aggName`, `GROUPS`, `groupOf` в reference/template.html (ищи их Grep-ом).

Сделай:
1. В Package.swift поменяй платформу на `.macOS(.v14)`. Больше в нём ничего не меняй.
2. `Sources/TreeSizeCore/Model.swift`:
   - `public enum NodeKind { case dir, file, rest }`;
   - `public final class Node: Identifiable` (поля из UI-SPEC 1);
   - `public static func build(from: [Any]) -> Node` — рекурсивно из вывода `serialize`, `id` по порядку обхода с 0;
   - `public var path: String` — как в UI-SPEC 1;
   - `public var displayName` — у сводки «[… помельче]», у остальных `name`;
   - `public struct ScanResult` с `init(data: [String: Any])`. Поля: `root: String`, `scanned: String`, `took: Double`, `errors: Int64`, `stuck: [String]`, `tree: Node`, `top: [TopFile]`, `ext: [ExtStat]`, `age: [AgeBucket]`, `dups: [DupGroup]`, `dupMin: Int64`, где
     - `TopFile{size, path, alloc, cloud, mtime}`,
     - `ExtStat{ext, size, count, cloud}`,
     - `AgeBucket{label, size, count}`,
     - `DupGroup{size, paths}`.

     Числа в словаре приходят как `Int`/`Int64`/`NSNumber` — приводи через `(x as? NSNumber)?.int64Value ?? 0`.
3. `Sources/TreeSizeCore/Format.swift`:
   - `public func fmtBytes(_ b: Int64) -> String`;
   - `public func fmtPct(_ x: Double) -> String`;
   - `public func fmtDate(_ unix: Int64) -> String`;
   - `public func plural(_ n: Int64, _ one: String, _ few: String, _ many: String) -> String` — разделитель тысяч U+00A0, как в примерах.

   Строки чисел собирай через `String(format: "%.2f")` и т. п., потом меняй точку на запятую.
4. `Sources/TreeSizeCore/FileGroups.swift`:
   - `public struct FileGroup { id, title, colorHex }`;
   - `public let fileGroups: [FileGroup]` — 8 групп из эталона в том же порядке и с теми же цветами;
   - `public func groupIndex(forExt:) -> Int` — прочее = последняя группа;
   - `extOf` из Scanner.swift сделай `public`, не меняя логику.
5. В `Sources/tscan/main.swift` добавь ключ `--model-check <папка>`: просканировать с параметрами по умолчанию, собрать `ScanResult` и напечатать строго в формате файла `tools/expected/01_model_check.txt` (открой его и повтори формат):
   - `root:` — имя корня (последний сегмент пути);
   - `nodes:` — число всех узлов дерева, включая корень и сводки;
   - `children:` — дети корня по убыванию `size`, кроме пустых сводок: `  <fmtBytes> | <displayName> | <fmtPct(size/size корня)>`;
   - строки `fmt:`, `pct:`, `plural:`, `date:` — с теми же входными значениями, что в файле.

Проверка: `tools/check_task.sh 01` должна напечатать `ЗАДАНИЕ 01: OK` (diff без различий).
