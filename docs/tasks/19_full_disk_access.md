# Задание 19. Полный доступ к диску: один экран при запуске вместо десятка вопросов

По живой проверке CEO: при скане приложение просит доступ ко всему подряд (Рабочий стол, Документы, Загрузки, iCloud, «данные других приложений», съёмные диски). Нужно, как в других анализаторах диска: при запуске одно окно «дайте полный доступ к диску», а без доступа — не трогать защищённые места и честно сказать, что они пропущены.

## 1. Проверка доступа (`Sources/TreeSizeCore/Access.swift`, новый файл)

```swift
import Foundation

public enum Access {
    /// Есть ли у приложения «Полный доступ к диску». Открыть этот файл можно только с полным доступом;
    /// попытка не вызывает системного вопроса.
    public static func hasFullDiskAccess() -> Bool {
        let fd = open("/Library/Application Support/com.apple.TCC/TCC.db", O_RDONLY)
        if fd >= 0 { close(fd); return true }
        return false
    }

    /// Места, чтение которых без полного доступа вызывает системный вопрос. Пути абсолютные.
    public static func promptingPaths(home: String = NSHomeDirectory()) -> [String] {
        ["Desktop", "Documents", "Downloads", "Library/Mobile Documents",
         "Library/Containers", "Library/Group Containers", "Pictures/Photos Library.photoslibrary",
         "Library/Mail", "Library/Messages", "Library/Safari"].map { home + "/" + $0 }
        + ["/Volumes"]
    }
}
```

## 2. Пропуск защищённых мест в сканере

- В `ScanOptions` добавь `public var skipPaths: Set<String> = []`.
- В `Scanner.scan` перед рекурсией в подпапку: если `options.skipPaths.contains(ePath)`, **не читать её вообще** (ни `opendir`, ни `lstat` содержимого). Вместо этого добавить пустую папку с пометкой: заведи в `Dir` поле `skipped = true`, наверх ничего не суммировать.
- Сериализация и `Node`: поле `skipped` должно дойти до `Node` (новый `public var skipped: Bool`). В эталоне на Python такого поля нет — **в `tools/compare.py` ничего не менять**: `tscan` по умолчанию `skipPaths` пустой, вывод должен совпадать с эталоном как раньше. Если поле меняет формат JSON для `tscan`, пиши его только когда `skipped == true`, а в фикстуре таких нет.
- В дереве у пропущенной папки вместо размера — «🔒», серым текст «нет доступа», подсказка при наведении: «Нужен полный доступ к диску».

## 3. Окно при запуске (`Sources/TreeSizeApp/AccessView.swift`, новый файл)

- При запуске, **до первого скана**, если `!Access.hasFullDiskAccess()` и в `UserDefaults` нет `"access.skip" == true`, показать лист (`.sheet`) поверх главного окна. Размер 520 × примерно 360, отступы 24:
  - заголовок жирным 17 pt: «Дайте TreeBars полный доступ к диску»;
  - текст: «Без него macOS будет спрашивать разрешение на каждую защищённую папку: Рабочий стол, Документы, Загрузки, iCloud, данные других приложений. С полным доступом — ни одного вопроса и честный размер всего диска.»;
  - шаги нумерованным списком: «1. Нажмите «Открыть настройки». 2. Включите TreeBars в списке «Полный доступ к диску» (если его нет — нажмите «+» и выберите TreeBars в Программах). 3. Перезапустите TreeBars.»;
  - текст мелким серым: «TreeBars ничего не отправляет в сеть и удаляет только в Корзину, после подтверждения.»;
  - кнопки: основная «Открыть настройки», вторичная «Продолжить без доступа».
- «Открыть настройки»: `NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)`. Лист не закрывать; под кнопками появляется кнопка «Перезапустить TreeBars», которая перезапускает приложение:

```swift
let url = Bundle.main.bundleURL
let cfg = NSWorkspace.OpenConfiguration(); cfg.createsNewApplicationInstance = true
NSWorkspace.shared.openApplication(at: url, configuration: cfg) { _, _ in
    DispatchQueue.main.async { NSApp.terminate(nil) }
}
```

- «Продолжить без доступа»: записать `"access.skip" = true`, закрыть лист, начать скан.
- **Скан без полного доступа** всегда передаёт `skipPaths = Set(Access.promptingPaths())`, кроме случая, когда пользователь сам выбрал корнем одну из этих папок или папку внутри неё (тогда её не пропускать — пользователь сам туда пошёл, вопрос ожидаем).
- С полным доступом `skipPaths` пустой.

## 4. Плашка о пропущенном

Если в результате есть узлы `skipped`, над деревом плашка в стиле Dropbox-плашки: «🔒 Часть папок пропущена — у TreeBars нет полного доступа к диску.» и кнопка «Дать доступ», которая снова открывает лист из п. 3.

## 5. Переводы

Все новые строки — через `tr(...)`, ключи добавь в словари всех 8 языков `L10n_<код>.swift`. Переводы ниже; если чего-то не хватает — оставь английский и напиши в отчёте, сам не переводи.

| ru | en |
|---|---|
| Дайте TreeBars полный доступ к диску | Give TreeBars Full Disk Access |
| Без него macOS будет спрашивать разрешение на каждую защищённую папку: Рабочий стол, Документы, Загрузки, iCloud, данные других приложений. С полным доступом — ни одного вопроса и честный размер всего диска. | Without it, macOS asks for permission for every protected folder: Desktop, Documents, Downloads, iCloud, other apps' data. With Full Disk Access there are no prompts and you see the real size of the whole disk. |
| 1. Нажмите «Открыть настройки». | 1. Click “Open Settings”. |
| 2. Включите TreeBars в списке «Полный доступ к диску» (если его нет — нажмите «+» и выберите TreeBars в Программах). | 2. Turn on TreeBars in the Full Disk Access list (if it isn't there, click “+” and choose TreeBars in Applications). |
| 3. Перезапустите TreeBars. | 3. Restart TreeBars. |
| TreeBars ничего не отправляет в сеть и удаляет только в Корзину, после подтверждения. | TreeBars never sends anything over the network and only moves files to the Trash, after a confirmation. |
| Открыть настройки | Open Settings |
| Продолжить без доступа | Continue without access |
| Перезапустить TreeBars | Restart TreeBars |
| нет доступа | no access |
| Нужен полный доступ к диску | Needs Full Disk Access |
| 🔒 Часть папок пропущена — у TreeBars нет полного доступа к диску. | 🔒 Some folders were skipped — TreeBars doesn't have Full Disk Access. |
| Дать доступ | Grant access |

Для zh, ja, ko, de, es, fr, pt переводы положит Claude отдельным коммитом — ты добавь ключи со значением-английским.

## Проверка

- `tools/check_task.sh 03` и `python3 tools/compare.py /tmp/ts-fixture` — OK (формат `tscan` не изменился).
- В `--selftest` добавь факт: скан `/tmp/ts-fixture` с `skipPaths = ["/tmp/ts-fixture/media"]` — узел `media` есть, `skipped == true`, размер 0, у корня размер меньше ровно на размер `media` из обычного скана.
- Снимок листа: режим `--snapshot ... --access` (как `--mode-help`, окно 520×380), `TREEBARS_LANG=ru` и `en`.
- **Сам приложение с листом не запускай** и настройки системы не открывай.

Коммит «Задание 19: полный доступ к диску», раздел в конце REPORT.md (только дописать).
