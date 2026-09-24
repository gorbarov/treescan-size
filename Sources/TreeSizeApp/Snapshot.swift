// Режим снимка — UI-SPEC раздел 13: --snapshot <png> [--root <папка>] [--select <путь>] [--tab <имя>] [--dark]
import AppKit
import SwiftUI
import TreeSizeCore

/// Синхронный скан, окно 1280×820 с NSHostingView(ContentView), снимок через 1,5 с, exit(0)
@MainActor
func takeSnapshot(args: [String]) {
    guard let snapIdx = args.firstIndex(of: "--snapshot"), snapIdx + 1 < args.count else {
        fputs("--snapshot <png> обязателен\n", stderr)
        exit(1)
    }
    guard let rootIdx = args.firstIndex(of: "--root"), rootIdx + 1 < args.count else {
        fputs("--root <папка> обязателен\n", stderr)
        exit(1)
    }

    let pngPath = args[snapIdx + 1]
    let rootPath = args[rootIdx + 1]

    let isDark = args.contains("--dark")

    // Синхронный скан
    let options = ScanOptions()
    let data = scanRoot(rootPath, options: options)

    let store = AppStore()
    store.result = ScanResult(data: data)

    // Режим: по умолчанию (UserDefaults не читаем в режиме снимка)
    store.mode = rootPath.contains("/CloudStorage/Dropbox") ? .size : .alloc

    // Выделить корень, раскрыть его
    if let tree = store.result?.tree {
        store.select(tree)
        store.expanded.insert(tree.id)
    }

    // --select
    if let selectIdx = args.firstIndex(of: "--select"), selectIdx + 1 < args.count {
        let selectPath = args[selectIdx + 1]
        if let tree = store.result?.tree {
            // Ищем узел по пути
            if let node = findNode(by: selectPath, in: tree) {
                store.select(node, expand: true)
            }
        }
    }

    // --tab
    if let tabIdx = args.firstIndex(of: "--tab"), tabIdx + 1 < args.count {
        let tabName = args[tabIdx + 1]
        switch tabName {
        case "pie": store.tab = .pie
        case "details": store.tab = .details
        case "ext": store.tab = .ext
        case "age": store.tab = .age
        case "top": store.tab = .top
        case "dups": store.tab = .dups
        default: break
        }
    }

    // Создаём окно
    let contentView = ContentView().environmentObject(store)
    let hostingView = NSHostingView(rootView: contentView)
    hostingView.frame = NSRect(x: 0, y: 0, width: 1280, height: 820)

    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1280, height: 820),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered,
                          defer: false)
    window.contentView = hostingView
    window.setFrameOrigin(NSPoint(x: -10000, y: -10000))

    window.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)

    window.orderFront(nil)

    // Даём время на отрисовку (1,5 с)
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.5))

    // Снимаем bitmap
    guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        fputs("Ошибка: bitmapImageRepForCachingDisplay вернул nil\n", stderr)
        exit(1)
    }
    hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fputs("Ошибка: не удалось создать PNG\n", stderr)
        exit(1)
    }

    do {
        try data.write(to: URL(fileURLWithPath: pngPath))
        fputs("Снимок сохранён: \(pngPath)\n", stdout)
    } catch {
        fputs("Ошибка записи PNG: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    exit(0)
}

/// Режим снимка Places (поповер мест) — размер 460×520
@MainActor
func snapshotPlaces(args: [String]) {
    guard let snapIdx = args.firstIndex(of: "--snapshot"), snapIdx + 1 < args.count else {
        fputs("--snapshot <png> обязателен\n", stderr)
        exit(1)
    }
    guard let rootIdx = args.firstIndex(of: "--root"), rootIdx + 1 < args.count else {
        fputs("--root <папка> обязателен\n", stderr)
        exit(1)
    }

    let pngPath = args[snapIdx + 1]
    let rootPath = args[rootIdx + 1]
    let isDark = args.contains("--dark")

    // Синхронный скан для заполнения store
    let options = ScanOptions()
    let data = scanRoot(rootPath, options: options)

    let store = AppStore()
    store.result = ScanResult(data: data)

    // Создаём PlacesView
    let placesView = PlacesView().environmentObject(store)
    let hostingView = NSHostingView(rootView: AnyView(placesView))
    hostingView.frame = NSRect(x: 0, y: 0, width: 460, height: 520)

    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 520),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered,
                          defer: false)
    window.contentView = hostingView
    window.setFrameOrigin(NSPoint(x: -10000, y: -10000))
    window.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
    window.orderFront(nil)

    // Даём время на отрисовку
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

    guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        fputs("Ошибка: bitmapImageRepForCachingDisplay вернул nil\n", stderr)
        exit(1)
    }
    hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fputs("Ошибка: не удалось создать PNG\n", stderr)
        exit(1)
    }

    do {
        try data.write(to: URL(fileURLWithPath: pngPath))
        fputs("Снимок Places сохранён: \(pngPath)\n", stdout)
    } catch {
        fputs("Ошибка записи PNG: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    exit(0)
}

/// Найти узел в дереве по полному пути (рекурсивный обход)
func findNode(by path: String, in node: Node) -> Node? {
    if node.path == path { return node }
    guard let children = node.children else { return nil }
    for child in children {
        if let found = findNode(by: path, in: child) {
            return found
        }
    }
    return nil
}