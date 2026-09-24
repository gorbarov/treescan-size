# Задание 14. Английский и китайский интерфейс (язык по системе)

Приложение выходит в мир, интерфейс сейчас только на русском. Нужны английский и китайский (упрощённый). Язык берётся из системы: первый предпочитаемый язык с префиксом `ru` → русский, `zh` → китайский, любой другой → английский. Позже добавятся японский, немецкий, испанский, французский, португальский, корейский — поэтому словари держи по одному файлу на язык. Без `.strings` и String Catalog (Xcode нет): простой словарь в коде.

## Скелет — `Sources/TreeSizeCore/L10n.swift`

```swift
import Foundation

public enum L10n {
    /// Словари: код языка → (русская строка → перевод). Каждый язык — в своём файле L10n_<код>.swift,
    /// который добавляет себя в этот словарь, например: extension L10n { static let en: [String: String] = [...] }
    public static let tables: [String: [String: String]] = ["en": en, "zh": zh]
    /// Язык: переменная окружения TREEBARS_LANG (ru/en/zh/…) важнее системы — для тестов и снимков.
    public static var lang: String = {
        if let forced = ProcessInfo.processInfo.environment["TREEBARS_LANG"] { return forced }
        let pref = (Locale.preferredLanguages.first ?? "en").lowercased()
        if pref.hasPrefix("ru") { return "ru" }
        for code in tables.keys where pref.hasPrefix(code) { return code }
        return "en"
    }()
    public static var isRussian: Bool { lang == "ru" }
}

/// Перевод строки интерфейса: по-русски возвращает как есть; нет перевода — английский; нет и его — русский.
public func tr(_ ru: String) -> String {
    if L10n.lang == "ru" { return ru }
    return L10n.tables[L10n.lang]?[ru] ?? L10n.en[ru] ?? ru
}
```

## Что сделать

1. Оберни в `tr(...)` все русские строки интерфейса во всех вью (TreeSizeApp): кнопки, вкладки, заголовки колонок, подписи, подсказки, меню, алерты, плашки, поповер. Строки со вставками (`"Сканирую \(path)…"`) раздели на части или сделай отдельные ключи-шаблоны. Найти всё: `grep -rn '"[^"]*[А-Яа-яЁё]' Sources/TreeSizeApp`.
2. Словари `Sources/TreeSizeCore/L10n_en.swift` и `L10n_zh.swift` — **одинаковый набор ключей** (все русские строки интерфейса). Китайский — упрощённый, естественный для интерфейса macOS (如 大小、磁盘占用、仅云端、文件、文件夹、最近修改).
3. Форматы в английском и китайском режиме (Format.swift): единицы `B, KB, MB, GB, TB, PB`, точка вместо запятой, процент без пробела (`6.7%`), дата `yyyy-MM-dd`. `plural` — английский: `1 file`, `2 files` (форма `one` для 1, иначе `many`; передавай английские формы через перегрузку или словарь). Названия групп файлов (Видео → Video, Фото и графика → Photos & graphics, Аудио → Audio, Документы → Documents, Архивы и образы → Archives & disk images, Код и данные → Code & data, Программы → Apps, Прочее → Other) и корзины возраста (до 1 месяца → < 1 month, 1–3 месяца → 1–3 months, 3–12 месяцев → 3–12 months, 1–2 года → 1–2 years, 2–5 лет → 2–5 years, старше 5 лет → > 5 years).
   В китайском: единицы как в английском, число через точку, дата `yyyy-MM-dd`, `plural` — без форм (`3 个文件`).
4. **Тесты не ломать:** `tools/check_task.sh 01`, `02`, `03` сравнивают русские строки. В режимах `--selftest`, `--model-check`, `--actions-check` язык всегда русский (`L10n.isRussian = true` в начале), а в `--snapshot` — по `TREEBARS_LANG` или системе.
5. Снимки для README: `TREEBARS_LANG=en tools/check_task.sh 14en --tab pie --select /tmp/ts-fixture/media` и `TREEBARS_LANG=ru tools/check_task.sh 14ru --tab pie --select /tmp/ts-fixture/media` — на английском не должно остаться ни одной русской буквы. И китайский: `TREEBARS_LANG=zh tools/check_task.sh 14zh --tab pie --select /tmp/ts-fixture/media`.

Проверка:
- `tools/check_task.sh 01`, `02`, `03` — OK;
- снимки 14en/14ru/14zh сделаны;
- `grep -c '"' Sources/TreeSizeCore/L10n_en.swift` и `L10n_zh.swift` — примерно одинаковое число строк (одинаковые ключи);
- `scripts/make_app.sh` проходит.

Коммит «Задание 14: английский и китайский интерфейс», раздел в конце REPORT.md (только дописать).
