// Каркас окна приложения — UI-SPEC разделы 4, 10, 12
import SwiftUI
import TreeSizeCore

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
                Button("Открыть…") {
                    store.showPlaces = true
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Пересканировать") {
                    store.rescan()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}