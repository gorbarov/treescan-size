// Форматирование чисел, дат, размера - как в эталоне template.html
import Foundation

/// Форматирование байтов - как fmt() в эталоне.
public func fmtBytes(_ b: Int64) -> String {
    if b < 1024 { return "\(b) \(L10n.isRussian ? "Б" : "B")" }
    let ruUnits = ["КБ", "МБ", "ГБ", "ТБ", "ПБ"]
    let enUnits = ["KB", "MB", "GB", "TB", "PB"]
    let units = L10n.isRussian ? ruUnits : enUnits
    var val = Double(b)
    var i = -1
    repeat {
        val /= 1024
        i += 1
    } while val >= 1024 && i < units.count - 1
    let s: String
    if val >= 100 {
        s = String(format: "%.0f", val)
    } else if val >= 10 {
        s = String(format: "%.1f", val)
    } else {
        s = String(format: "%.2f", val)
    }
    let sep = L10n.isRussian ? "," : "."
    return s.replacingOccurrences(of: ".", with: sep) + " " + units[i]
}

/// Форматирование доли в проценты - как pctTxt() в эталоне.
public func fmtPct(_ x: Double) -> String {
    let p = x * 100
    let s: String
    if p >= 10 {
        s = String(format: "%.0f", p)
    } else {
        s = String(format: "%.1f", p)
    }
    let sep = L10n.isRussian ? "," : "."
    let formatted = s.replacingOccurrences(of: ".", with: sep)
    if L10n.isRussian {
        return formatted + " %"
    } else {
        return formatted + "%"
    }
}

/// Форматирование даты из unix-секунд - как dateTxt() в эталоне.
public func fmtDate(_ unix: Int64) -> String {
    if unix == 0 { return "\u{2014}" }
    let date = Date(timeIntervalSince1970: Double(unix))
    let df = DateFormatter()
    df.dateFormat = L10n.isRussian ? "dd.MM.yyyy" : "yyyy-MM-dd"
    return df.string(from: date)
}

/// Русское склонение с разделителем тысяч (U+00A0) - как plural() в эталоне.
/// В английском/китайском — формы через tr(), 1 → one, иначе → many.
public func plural(_ n: Int64, _ one: String, _ few: String, _ many: String) -> String {
    let ns = NumberFormatter()
    ns.numberStyle = .decimal
    if L10n.lang == "zh" {
        ns.locale = Locale(identifier: "zh-CN")
    } else if !L10n.isRussian {
        ns.locale = Locale(identifier: "en-US")
    } else {
        ns.locale = Locale(identifier: "ru-RU")
    }
    let numStr = ns.string(from: NSNumber(value: n)) ?? "\(n)"
    if L10n.lang == "zh" {
        // Китайский: единая форма
        return numStr + " " + tr(many)
    } else if !L10n.isRussian {
        // Английский: one для 1, иначе many
        let word = n == 1 ? tr(one) : tr(many)
        return numStr + " " + word
    }
    // Русский
    let m10 = n % 10
    let m100 = n % 100
    let word: String
    if m10 == 1 && m100 != 11 {
        word = one
    } else if m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14) {
        word = few
    } else {
        word = many
    }
    return numStr + " " + word
}

/// Форматирование целого числа с разделителями тысяч.
public func fmtCount(_ n: Int64) -> String {
    let ns = NumberFormatter()
    ns.numberStyle = .decimal
    if L10n.lang == "zh" {
        ns.locale = Locale(identifier: "zh-CN")
    } else if !L10n.isRussian {
        ns.locale = Locale(identifier: "en-US")
    } else {
        ns.locale = Locale(identifier: "ru-RU")
    }
    return ns.string(from: NSNumber(value: n)) ?? "\(n)"
}

/// Псевдоним fmtCount для краткости в оверлее
public func nf(_ n: Int64) -> String { fmtCount(n) }

/// Прошедшее время от scanStarted в формате М:СС
public func elapsedString(from start: Date?) -> String {
    guard let start = start else { return "0:00" }
    let elapsed = Date().timeIntervalSince(start)
    let totalSeconds = Int(elapsed)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return "\(minutes):\(String(format: "%02d", seconds))"
}