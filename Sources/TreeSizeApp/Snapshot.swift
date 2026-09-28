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
        store.expanded.insert(tree.path)
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
    let placesView = PlacesView(places: listPlaces()).environmentObject(store)
    let hostingView = NSHostingView(rootView: placesView)
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

    // Скрываем окно
    window.orderOut(nil)

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

/// Режим снимка ModeHelp (пояснение Размер / На диске) — размер 400x360
@MainActor
func snapshotModeHelp(args: [String]) {
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

    // Синхронный скан для заполнения store (нужен для окружения)
    let options = ScanOptions()
    let data = scanRoot(rootPath, options: options)

    let store = AppStore()
    store.result = ScanResult(data: data)

    // Создаём ModeHelpView
    let modeHelpView = ModeHelpView().environmentObject(store)
    let hostingView = NSHostingView(rootView: modeHelpView)
    hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 360)

    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 360),
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

    // Скрываем окно
    window.orderOut(nil)

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fputs("Ошибка: не удалось создать PNG\n", stderr)
        exit(1)
    }

    do {
        try data.write(to: URL(fileURLWithPath: pngPath))
        fputs("Снимок ModeHelp сохранён: \(pngPath)\n", stdout)
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

/// Снимок оверлея скана с заданными прогрессом
@MainActor
func takeSnapshotScanning(args: [String]) {
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
    store.mode = rootPath.contains("/CloudStorage/Dropbox") ? .size : .alloc

    if let tree = store.result?.tree {
        store.select(tree)
        store.expanded.insert(tree.path)
    }

    // Включаем режим сканирования с фиксированным прогрессом
    store.isScanning = true
    store.scanPath = rootPath
    store.progress = (files: 123456, alloc: 45_000_000_000, cur: "/Users/example/Documents/Project/Subdir/somefile.dat")
    store.scanStarted = Date().addingTimeInterval(-67) // 1:07 назад
    store.expectedAlloc = 300_000_000_000

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

    RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.5))

    guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        fputs("Ошибка: bitmapImageRepForCachingDisplay вернул nil\n", stderr)
        exit(1)
    }
    hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        fputs("Ошибка: не удалось создать PNG\n", stderr)
        exit(1)
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: pngPath))
        fputs("Снимок скана сохранён: \(pngPath)\n", stdout)
    } catch {
        fputs("Ошибка записи PNG: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    exit(0)
}

/// Режим `--live-demo`: показывает синтетическое частичное дерево (корень scanning,
/// одна готовая папка, одна scanning с частичным размером) + полоса прогресса.
@MainActor
func takeSnapshotLiveDemo(args: [String]) {
    guard let snapIdx = args.firstIndex(of: "--snapshot"), snapIdx + 1 < args.count else {
        fputs("--snapshot <png> обязателен\n", stderr)
        exit(1)
    }
    let pngPath = args[snapIdx + 1]
    let rootPath = "/tmp/ts-fixture"
    let isDark = args.contains("--dark")

    let store = AppStore()
    store.mode = .size
    store.isScanning = true
    store.scanPath = rootPath
    store.progress = (files: 423, alloc: 98_765_432, cur: rootPath + "/photos/last_batch")
    store.scanStarted = Date().addingTimeInterval(-13)
    store.expectedAlloc = 250_000_000

    // Строим синтетическое частичное дерево
    let rootDir = Dir(name: rootPath)
    rootDir.scanning = true
    rootDir.size = 123_456_789
    rootDir.alloc = 98_765_432
    rootDir.files = 423
    rootDir.dirs = 2

    // Готовая папка docs
    let docs = Dir(name: "docs")
    docs.size = 45_000_000; docs.alloc = 44_000_000; docs.files = 12; docs.dirs = 0
    rootDir.kids.append(docs)

    // Папка в процессе сканирования — photos
    let photos = Dir(name: "photos")
    photos.scanning = true
    photos.size = 78_456_789; photos.alloc = 54_765_432; photos.files = 411; photos.dirs = 1
    // photos содержит готовую подпапку
    let lastBatch = Dir(name: "last_batch")
    lastBatch.size = 30_000_000; lastBatch.alloc = 25_000_000; lastBatch.files = 200; lastBatch.dirs = 0
    photos.kids.append(lastBatch)
    rootDir.kids.append(photos)

    // Сериализуем и строим Node-дерево
    let thr = max(1, Int64(Double(rootDir.size) * 2e-6))
    let treeArr = serialize(rootDir, thr: thr)
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm"
    let scannedStr = df.string(from: Date())
    let snapResult = ScanResult(liveTree: treeArr, rootPath: rootPath, scanned: scannedStr)
    store.result = snapResult

    if let tree = snapResult.tree as Node? {
        store.select(tree)
        store.expanded.insert(tree.path)
        // Раскрываем photos
        if let photosNode = tree.findDescendant(by: rootPath + "/photos") {
            store.expanded.insert(photosNode.path)
        }
    }

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

    RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.5))

    guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        fputs("Ошибка: bitmapImageRepForCachingDisplay вернул nil\n", stderr)
        exit(1)
    }
    hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        fputs("Ошибка: не удалось создать PNG\n", stderr)
        exit(1)
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: pngPath))
        fputs("Снимок live-demo сохранён: \(pngPath)\n", stdout)
    } catch {
        fputs("Ошибка записи PNG: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    exit(0)
}

/// Снимок листа доступа к диску — окно 520×380 как AccessView.
@MainActor
func snapshotAccess(args: [String]) {
    guard let snapIdx = args.firstIndex(of: "--snapshot"), snapIdx + 1 < args.count else {
        fputs("--snapshot <png> обязателен\n", stderr)
        exit(1)
    }
    let pngPath = args[snapIdx + 1]
    let isDark = args.contains("--dark")

    let accessView = AccessView(showAccessSheet: .constant(true), isSnapshot: true)
    let hostingView = NSHostingView(rootView: accessView)
    hostingView.frame = NSRect(x: 0, y: 0, width: 520, height: 380)

    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 380),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered,
                          defer: false)
    window.contentView = hostingView
    window.setFrameOrigin(NSPoint(x: -10000, y: -10000))
    window.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
    window.orderFront(nil)

    RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

    guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        fputs("Ошибка: bitmapImageRepForCachingDisplay вернул nil\n", stderr)
        exit(1)
    }
    hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

    window.orderOut(nil)

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fputs("Ошибка: не удалось создать PNG\n", stderr)
        exit(1)
    }

    do {
        try data.write(to: URL(fileURLWithPath: pngPath))
        fputs("Снимок Access сохранён: \(pngPath)\n", stdout)
    } catch {
        fputs("Ошибка записи PNG: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    exit(0)
}