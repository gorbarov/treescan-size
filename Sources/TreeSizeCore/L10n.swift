import Foundation

public enum L10n {
    /// Словари: код языка → (русская строка → перевод). Каждый язык — в своём файле L10n_<код>.swift,
    /// который добавляет себя в этот словарь, например: extension L10n { static let en: [String: String] = [...] }
    public static let tables: [String: [String: String]] = ["en": en, "zh": zh]

    /// Язык: переменная окружения TREEBARS_LANG (ru/en/zh/…) важнее системы — для тестов и снимков.
    /// Можно переопределить принудительно (например, `L10n.lang = "ru"` в --selftest).
    private static var _langOverride: String? = nil

    public static func forceLang(_ code: String) { _langOverride = code }

    public static var lang: String {
        if let forced = _langOverride { return forced }
        if let env = ProcessInfo.processInfo.environment["TREEBARS_LANG"] { return env }
        let pref = (Locale.preferredLanguages.first ?? "en").lowercased()
        if pref.hasPrefix("ru") { return "ru" }
        for code in tables.keys where pref.hasPrefix(code) { return code }
        return "en"
    }
    public static var isRussian: Bool { lang == "ru" }
}

/// Перевод строки интерфейса: по-русски возвращает как есть; нет перевода — английский; нет и его — русский.
public func tr(_ ru: String) -> String {
    if L10n.lang == "ru" { return ru }
    return L10n.tables[L10n.lang]?[ru] ?? L10n.en[ru] ?? ru
}