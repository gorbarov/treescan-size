import AppKit
import SwiftUI
import TreeSizeCore

@MainActor
func runUITest(root: String, snapshotPath: String? = nil) -> [String: Any] {
    L10n.forceLang("ru")
    let options = ScanOptions()
    let data = scanRoot(root, options: options)

    let store = AppStore()
    store.result = ScanResult(data: data)
    store.mode = root.contains("/CloudStorage/Dropbox") ? .size : .alloc

    if let tree = store.result?.tree {
        store.select(tree)
        store.expanded.insert(tree.path)
        for child in store.children(tree) {
            store.expanded.remove(child.path)
        }
    }

    // Создаём окно как в snapshot (accessory policy)
    let contentView = ContentView().environmentObject(store)
    let host = NSHostingView(rootView: contentView)
    host.frame = NSRect(x: 0, y: 0, width: 1280, height: 820)

    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1280, height: 820),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
    window.contentView = host
    window.setFrameOrigin(NSPoint(x: -10000, y: -10000))
    window.appearance = NSAppearance(named: .aqua)
    window.orderFront(nil)

    // Даём время на отрисовку (как в snapshot: 1,5 с)
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.5))
    func wait(_ s: Double) { RunLoop.main.run(until: Date().addingTimeInterval(s)) }

    print("DEBUG host.frame=\(host.frame) host.bounds=\(host.bounds) window.contentLayoutRect=\(window.contentLayoutRect)")

    for (k, v) in store.uiFrames.sorted(by: { $0.key < $1.key }) {
        print("DEBUG frame[\(k)] = \(v)")
    }

    func click(_ tag: String, count: Int = 1) -> Bool {
        guard let r = store.uiFrames[tag], r.width > 0, r.height > 0 else { return false }
        // uitest coordinate: top-left origin, Y-down
        // convert to window (bottom-left origin, Y-up)
        let yWindow = host.frame.height - r.midY
        let p = NSPoint(x: r.midX, y: yWindow)
        print("DEBUG click[\(tag)] uitest=\(r.midX),\(r.midY) winPt=\(p.x),\(p.y) hostH=\(host.frame.height)")
        for c in 1...count {
            for t in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                guard let ev = NSEvent.mouseEvent(with: t, location: p, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                    windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: c, pressure: 1) else { return false }
                window.sendEvent(ev)
            }
            wait(0.1)
        }
        wait(0.3); return true
    }

    func key(_ code: UInt16, _ ch: Int) {
        let s = String(UnicodeScalar(ch)!)
        for t in [NSEvent.EventType.keyDown, .keyUp] {
            guard let ev = NSEvent.keyEvent(with: t, location: .zero, modifierFlags: [.numericPad, .function], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, characters: s, charactersIgnoringModifiers: s, isARepeat: false, keyCode: code) else { return }
            window.sendEvent(ev)
            wait(0.1)
        }
        wait(0.3)
    }

    var f: [String: Any] = [:]
    let rootPath = store.result?.root ?? ""

    func reset() {
        guard let tree = store.result?.tree else { return }
        store.select(tree)
        store.expanded.removeAll()
        store.expanded.insert(tree.path)
    }

    reset()
    if !click("row:media") { f["click_select"] = "не найден: row:media" }
    else { f["click_select"] = store.selected?.name ?? "" }

    reset()
    if !click("row:media", count: 2) { f["dbl_expand_rows"] = "не найден: row:media" }
    else { f["dbl_expand_rows"] = store.visibleRows.count }

    if !click("row:media", count: 2) { f["dbl_collapse_rows"] = "не найден: row:media" }
    else { f["dbl_collapse_rows"] = store.visibleRows.count }

    reset()
    if !click("row:" + rootPath) { f["key_down_selected"] = "не найден: row:" + rootPath }
    else {
        key(125, NSDownArrowFunctionKey)
        f["key_down_selected"] = store.selected?.name ?? ""
    }

    reset()
    if !click("row:media") { f["key_right_expanded"] = "не найден: row:media" }
    else {
        key(124, NSRightArrowFunctionKey)
        let mid = store.result?.tree.findDescendant(by: rootPath + "/media")
        f["key_right_expanded"] = mid == nil ? false : store.expanded.contains(mid!.path)
    }
    key(123, NSLeftArrowFunctionKey)
    let mn = store.result?.tree.findDescendant(by: rootPath + "/media")
    f["key_left_collapsed"] = mn == nil ? false : !store.expanded.contains(mn!.path)

    reset()
    if !click("tab:Детали") { f["tab_details"] = "не найден: tab:Детали" }
    else { f["tab_details"] = store.tab.rawValue }

    reset()
    if !click("mode:size") { f["mode_size"] = "не найден: mode:size" }
    else { f["mode_size"] = store.mode.rawValue }

    reset()
    if !click("mode:alloc") { f["legend_click_selected"] = "не найден: mode:alloc" }
    else if !click("tab:Диаграмма") { f["legend_click_selected"] = "не найден: tab:Диаграмма" }
    else if !click("legend:docs") { f["legend_click_selected"] = "не найден: legend:docs" }
    else { f["legend_click_selected"] = store.selected?.name ?? "" }

    reset()
    if !click("tab:Детали") { f["details_dbl_selected"] = "не найден: tab:Детали" }
    else if !click("cell:docs", count: 2) { f["details_dbl_selected"] = "не найден: cell:docs" }
    else { f["details_dbl_selected"] = store.selected?.name ?? "" }

    // Стрелки + снимок: открыть корень, ↓ дважды, снимок
    if let snapPath = snapshotPath {
        reset()
        // Раскрываем корень
        guard let tree = store.result?.tree else { return f }
        store.expanded.insert(tree.path)
        wait(0.5)
        // ↓ дважды
        key(125, NSDownArrowFunctionKey)
        key(125, NSDownArrowFunctionKey)
        let selName = store.selected?.name ?? ""
        f["key_down_twice_selected"] = selName
        wait(0.3)

        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
            f["keys_snapshot"] = "bitmapImageRepForCachingDisplay вернул nil"
            return f
        }
        host.cacheDisplay(in: host.bounds, to: rep)

        guard let pngData = rep.representation(using: .png, properties: [:]) else {
            f["keys_snapshot"] = "не удалось создать PNG"
            return f
        }

        do {
            try pngData.write(to: URL(fileURLWithPath: snapPath))
            f["keys_snapshot"] = snapPath
        } catch {
            f["keys_snapshot"] = "ошибка записи: \(error.localizedDescription)"
        }
    }

    return f
}