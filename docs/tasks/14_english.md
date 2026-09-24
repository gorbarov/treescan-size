# Задание 14. Английский интерфейс (язык по системе)

Приложение выходит в мир, интерфейс сейчас только на русском. Нужен английский: если первый предпочитаемый язык системы не русский — всё по-английски, иначе по-русски. Без `.strings` и String Catalog (Xcode нет): простой словарь в коде.

## Скелет — `Sources/TreeSizeCore/L10n.swift`

```swift
import Foundation

public enum L10n {
    /// Язык: переменная окружения TREEBARS_LANG (ru/en) важнее системы — для тестов и снимков.
    public static var isRussian: Bool = {
        if let forced = ProcessInfo.processInfo.environment["TREEBARS_LANG"] { return forced == "ru" }
        return (Locale.preferredLanguages.first ?? "en").hasPrefix("ru")
    }()
    static let en: [String: String] = [
        "Размер": "Size", "На диске": "On disk", "Только в облаке": "Cloud only",
        // ... ВСЕ русские строки интерфейса
    ]
}

/// Перевод строки интерфейса: по-русски возвращает как есть.
public func tr(_ ru: String) -> String { L10n.isRussian ? ru : (L10n.en[ru] ?? ru) }
```

## Что сделать

1. Оберни в `tr(...)` все русские строки интерфейса во всех вью (TreeSizeApp): кнопки, вкладки, заголовки колонок, подписи, подсказки, меню, алерты, плашки, поповер. Строки со вставками (`"Сканирую \(path)…"`) раздели на части или сделай отдельные ключи-шаблоны. Найти всё: `grep -rn '"[^"]*[А-Яа-яЁё]' Sources/TreeSizeApp`.
2. Форматы в английском режиме (Format.swift): единицы `B, KB, MB, GB, TB, PB`, точка вместо запятой, процент без пробела (`6.7%`), дата `yyyy-MM-dd`. `plural` — английский: `1 file`, `2 files` (форма `one` для 1, иначе `many`; передавай английские формы через перегрузку или словарь). Названия групп файлов (Видео → Video, Фото и графика → Photos & graphics, Аудио → Audio, Документы → Documents, Архивы и образы → Archives & disk images, Код и данные → Code & data, Программы → Apps, Прочее → Other) и корзины возраста (до 1 месяца → < 1 month, 1–3 месяца → 1–3 months, 3–12 месяцев → 3–12 months, 1–2 года → 1–2 years, 2–5 лет → 2–5 years, старше 5 лет → > 5 years).
3. **Тесты не ломать:** `tools/check_task.sh 01`, `02`, `03` сравнивают русские строки. В режимах `--selftest`, `--model-check`, `--actions-check` язык всегда русский (`L10n.isRussian = true` в начале), а в `--snapshot` — по `TREEBARS_LANG` или системе.
4. Снимки для README: `TREEBARS_LANG=en tools/check_task.sh 14en --tab pie --select /tmp/ts-fixture/media` и `TREEBARS_LANG=ru tools/check_task.sh 14ru --tab pie --select /tmp/ts-fixture/media` — на английском не должно остаться ни одной русской буквы.

Проверка:
- `tools/check_task.sh 01`, `02`, `03` — OK;
- оба снимка 14en/14ru сделаны;
- `scripts/make_app.sh` проходит.

Коммит «Задание 14: английский интерфейс», раздел в конце REPORT.md (только дописать).
