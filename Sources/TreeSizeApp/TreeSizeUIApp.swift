// Каркас окна приложения — UI-SPEC разделы 4, 10, 12
import SwiftUI
import TreeSizeCore

/// Текст интерфейса с разметкой **жирный** после перевода.
func mdText(_ s: String) -> Text {
    if let a = try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) { return Text(a) }
    return Text(s)
}

/// Приложение без @main (запуск из main.swift)
public struct TreeSizeUIApp: App {
    @StateObject private var store = AppStore()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 1280, height: 820)
        .windowResizability(.contentMinSize)
        .commands {
            // «Открыть…» ⌘O
            CommandGroup(after: .newItem) {
                Button(tr("Открыть…")) {
                    store.showPlaces = true
                }
                .keyboardShortcut("o", modifiers: .command)

                Button(tr("Пересканировать")) {
                    store.rescan()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}