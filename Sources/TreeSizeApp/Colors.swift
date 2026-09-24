// Цвета для дерева и всего приложения — UI-SPEC раздел 5, как template.html
import SwiftUI
import AppKit

// MARK: - Color(hex:)

extension Color {
    /// Инициализация из hex-строки вида "#rgb", "#rrggbb"
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b, a: Double
        switch h.count {
        case 3:
            (r, g, b, a) = (Double((int >> 8) & 0xf) / 15, Double((int >> 4) & 0xf) / 15, Double(int & 0xf) / 15, 1)
        case 6:
            (r, g, b, a) = (Double((int >> 16) & 0xff) / 255, Double((int >> 8) & 0xff) / 255, Double(int & 0xff) / 255, 1)
        case 8:
            (r, g, b, a) = (Double((int >> 24) & 0xff) / 255, Double((int >> 16) & 0xff) / 255,
                            Double((int >> 8) & 0xff) / 255, Double(int & 0xff) / 255)
        default:
            (r, g, b, a) = (0, 0, 0, 1)
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Создать динамический цвет через NSColor(name:dynamicProvider:)
    static func dynamicColor(lightHex: String, darkHex: String) -> Color {
        let lightNS = NSColor(hex: lightHex) ?? NSColor.clear
        let darkNS = NSColor(hex: darkHex) ?? NSColor.clear
        let key = "ts_\(lightHex)_\(darkHex)"
        let dynamic = NSColor(name: NSColor.Name(key)) { appearance in
            let isDark = appearance.name == .darkAqua || appearance.name == .vibrantDark
            return isDark ? darkNS : lightNS
        }
        return Color(nsColor: dynamic)
    }

    /// Создать динамический цвет с разной прозрачностью для светлой/тёмной темы.
    /// hex — цвет, lightAlpha / darkAlpha — прозрачность.
    static func dynamicColor(hex: String, lightAlpha: Double, darkAlpha: Double) -> Color {
        let base = NSColor(hex: hex) ?? NSColor.clear
        let key = "ts_\(hex)_\(lightAlpha)_\(darkAlpha)"
        let dynamic = NSColor(name: NSColor.Name(key)) { appearance in
            let isDark = appearance.name == .darkAqua || appearance.name == .vibrantDark
            guard let c = base.copy() as? NSColor else { return base }
            return c.withAlphaComponent(isDark ? CGFloat(darkAlpha) : CGFloat(lightAlpha))
        }
        return Color(nsColor: dynamic)
    }
}

// MARK: - NSColor(hex:)

extension NSColor {
    /// NSColor из hex-строки "#rrggbb" или "#rgb"
    convenience init?(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&int) else { return nil }
        let r, g, b, a: CGFloat
        switch h.count {
        case 3:
            (r, g, b, a) = (CGFloat((int >> 8) & 0xf) / 15, CGFloat((int >> 4) & 0xf) / 15, CGFloat(int & 0xf) / 15, 1)
        case 6:
            (r, g, b, a) = (CGFloat((int >> 16) & 0xff) / 255, CGFloat((int >> 8) & 0xff) / 255, CGFloat(int & 0xff) / 255, 1)
        case 8:
            (r, g, b, a) = (CGFloat((int >> 24) & 0xff) / 255, CGFloat((int >> 16) & 0xff) / 255,
                            CGFloat((int >> 8) & 0xff) / 255, CGFloat(int & 0xff) / 255)
        default:
            return nil
        }
        self.init(srgbRed: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - Цвета дерева (как CSS-переменные template.html)

extension Color {
    // --- Полоски папок: градиент #ffd36e → #fff0bf (светлая), #86691c → #4a3d17 (тёмная) ---
    static let treeDirBarStart = Color.dynamicColor(lightHex: "#ffd36e", darkHex: "#86691c")
    static let treeDirBarEnd   = Color.dynamicColor(lightHex: "#fff0bf", darkHex: "#4a3d17")
    static let treeDirBarBorder = Color.dynamicColor(hex: "#d6a014", lightAlpha: 0.35, darkAlpha: 0.25)

    // --- Полоски файлов: #c3d6f0 → #e4ecf7 (светлая), #2e4a72 → #23324a (тёмная) ---
    static let treeFileBarStart = Color.dynamicColor(lightHex: "#c3d6f0", darkHex: "#2e4a72")
    static let treeFileBarEnd   = Color.dynamicColor(lightHex: "#e4ecf7", darkHex: "#23324a")

    // --- Полоска сводки ---
    static let treeAggBar = Color.dynamicColor(lightHex: "#e6eaf0", darkHex: "#2a3039")

    // --- Выделение ---
    static let treeSelectionBg = Color.dynamicColor(lightHex: "#d6e6fb", darkHex: "#233a5c")
    static let treeSelectionAccent = Color(hex: "#2a78d6")

    // --- Облако ---
    static let treeCloudColor = Color.dynamicColor(lightHex: "#6a4fd8", darkHex: "#9f8bff")

    // --- Папка-иконка ---
    static let treeFolderColor = Color(hex: "#e9b53b")

    // --- Hover ---
    static let treeHover = Color.dynamicColor(lightHex: "#eef4fc", darkHex: "#222833")
}