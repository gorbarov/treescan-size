// Форматирование чисел, дат, размера - как в эталоне template.html
import Foundation

/// Форматирование байтов - как fmt() в эталоне.
public func fmtBytes(_ b: Int64) -> String {
    if b < 1024 { return "\(b) Б" }
    let units = ["КБ", "МБ", "ГБ", "ТБ", "ПБ"]
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
    return s.replacingOccurrences(of: ".", with: ",") + " " + units[i]
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
    return s.replacingOccurrences(of: ".", with: ",") + " %"
}

/// Форматирование даты из unix-секунд - как dateTxt() в эталоне.
public func fmtDate(_ unix: Int64) -> String {
    if unix == 0 { return "\u{2014}" }
    let date = Date(timeIntervalSince1970: Double(unix))
    let df = DateFormatter()
    df.dateFormat = "dd.MM.yyyy"
    return df.string(from: date)
}

/// Русское склонение с разделителем тысяч (U+00A0) - как plural() в эталоне.
public func plural(_ n: Int64, _ one: String, _ few: String, _ many: String) -> String {
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
    let ns = NumberFormatter()
    ns.numberStyle = .decimal
    ns.locale = Locale(identifier: "ru-RU")
    let numStr = ns.string(from: NSNumber(value: n)) ?? "\(n)"
    return numStr + " " + word
}