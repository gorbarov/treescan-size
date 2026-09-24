# Задание 13. Имя приложения — одна константа

Проект выходит в открытый доступ. «TreeSize» — зарегистрированная торговая марка (EUIPO 013363619), поэтому у приложения будет другое имя. Окончательное имя ещё выбирают, поэтому сделай так, чтобы оно менялось **в одном месте**. Внутренние имена модулей и целей (`TreeSizeCore`, `TreeSizeApp`, `tscan`) **не трогать**.

1. `Sources/TreeSizeCore/AppInfo.swift`:
```swift
public enum AppInfo {
    public static let name = "TreeBars"                       // видимое имя — меняется только здесь
    public static let bundleID = "io.github.gorbarov.treebars"
    public static let version = "0.1.0"
}
```
2. Все видимые упоминания «TreeSize» в интерфейсе (шапка, заголовок окна, «О программе», алерты) — через `AppInfo.name`. Найти: `grep -rn '"TreeSize' Sources/TreeSizeApp`.
3. Пути и ключи с «TreeSize» (кэш в ~/Library/Caches, ключи UserDefaults) — через `AppInfo.name`.
4. `scripts/make_app.sh`: имя берётся из одного места наверху скрипта — `APP_NAME=$(grep 'static let name' Sources/TreeSizeCore/AppInfo.swift | sed 's/.*"\(.*\)".*/\1/')`, аналогично `BUNDLE_ID` и `VERSION`. Собирать `build/$APP_NAME.app`, исполняемый файл `Contents/MacOS/$APP_NAME`, Info.plist из этих переменных, `NSHumanReadableCopyright` — `MIT License`. Старые `.app` в build не удалять (rm запрещён).

Проверка:
- `scripts/make_app.sh`, `codesign -v build/TreeBars.app`;
- `build/TreeBars.app/Contents/MacOS/TreeBars --root /tmp/ts-fixture --selftest` даёт те же факты, что `tools/check_task.sh 03`;
- `tools/check_task.sh 07 --tab pie` (в шапке «TreeBars»);
- `tools/check_task.sh 03`.

Коммит «Задание 13: имя приложения — константа AppInfo.name», раздел в конце REPORT.md (только дописать).
