# Задание 10u (вторая попытка). Живая проверка кликов и клавиш

Первая попытка не удалась: SwiftUI не отдаёт элементы через доступность внутри своего процесса, поэтому поиск по accessibility не работает — **не используй accessibility вообще**. Вместо этого вью сами сообщают свои рамки через `PreferenceKey`, а тест кликает в центр рамки настоящими `NSEvent`. Делай строго по скелету. Если за 25 минут не выйдет — остановись и опиши в REPORT.md, на чём застрял.

## 1. `Sources/TreeSizeApp/UIFrames.swift` (новый файл, целиком)

```swift
import SwiftUI

/// Рамки размеченных вью в координатах окна (начало — левый верхний угол контента). Нужны только самотесту.
struct UIFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func uiTag(_ tag: String) -> some View {
        background(GeometryReader { g in
            Color.clear.preference(key: UIFramesKey.self, value: [tag: g.frame(in: .global)])
        })
    }
}
```

## 2. Разметка (маленькие правки в существующих вью)

- **Дерево** (TreeView): на строку — `.uiTag("row:" + node.displayName)`. У корня `displayName` — полный путь, это нормально.
- **Вкладки**: на кнопку каждой вкладки — `.uiTag("tab:" + заголовок)`, например `"tab:Детали"`, `"tab:Диаграмма"`.
- **Режим**: на кнопки сегмента — `.uiTag("mode:size")` и `.uiTag("mode:alloc")`. Если сегмент — это `Picker`, замени его на две `Button` в `HStack` с тем же видом, иначе в половинки не попасть.
- **Легенда диаграммы**: на строку — `.uiTag("legend:" + slice.title)`.
- **Таблица «Детали»**: на вью имени в ячейке — `.uiTag("cell:" + node.displayName)`.
- **В ContentView** на самый внешний контейнер — `.onPreferenceChange(UIFramesKey.self) { store.uiFrames = $0 }`. В `AppStore` — `var uiFrames: [String: CGRect] = [:]`, **без** `@Published`, чтобы не было цикла перерисовки.

## 3. `Sources/TreeSizeApp/UITest.swift` и ключ `--uitest`

```swift
import AppKit
import SwiftUI
import TreeSizeCore

@MainActor
func runUITest(root: String) -> [String: Any] {
    // подготовка: как в режиме снимка — синхронный скан, store без UserDefaults, окно 1280×820
    let store = ...               // как в Snapshot.swift
    let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 1280, height: 820),
                          styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
    let host = NSHostingView(rootView: ContentView().environmentObject(store))
    window.contentView = host
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    func wait(_ s: Double) { RunLoop.main.run(until: Date().addingTimeInterval(s)) }
    wait(1.0)

    func point(_ tag: String) -> NSPoint? {
        guard let r = store.uiFrames[tag] else { return nil }
        return NSPoint(x: r.midX, y: host.bounds.height - r.midY)   // SwiftUI сверху вниз → AppKit снизу вверх
    }
    func click(_ tag: String, count: Int = 1) -> Bool {
        guard let p = point(tag) else { return false }
        for c in 1...count {
            for t in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                window.sendEvent(NSEvent.mouseEvent(with: t, location: p, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                    windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: c, pressure: 1)!)
            }
        }
        wait(0.5); return true
    }
    func key(_ code: UInt16, _ ch: Int) {
        let s = String(UnicodeScalar(ch)!)
        for t in [NSEvent.EventType.keyDown, .keyUp] {
            window.sendEvent(NSEvent.keyEvent(with: t, location: .zero, modifierFlags: [.numericPad, .function], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, characters: s, charactersIgnoringModifiers: s, isARepeat: false, keyCode: code)!)
        }
        wait(0.5)
    }
    var f: [String: Any] = [:]
    // ... шаги из таблицы ниже; если click(...) вернул false — f[ключ] = "не найден: <tag>"
    return f
}
```

Коды клавиш: ↓ — `key(125, NSDownArrowFunctionKey)`, → — `key(124, NSRightArrowFunctionKey)`, ← — `key(123, NSLeftArrowFunctionKey)`.

В `main.swift`: `--uitest` → `let f = runUITest(root:)`, напечатать JSON (`.sortedKeys`), `exit(0)`.

## 4. Шаги (перед каждым — «свежее состояние»: `store.select(корень)`, свернуть всё, кроме корня, `wait(0.5)`)

| ключ | действие | что записать |
|---|---|---|
| `click_select` | `click("row:media")` | имя `store.selected` |
| `dbl_expand_rows` | `click("row:media", count: 2)` | `store.visibleRows.count` |
| `dbl_collapse_rows` | ещё раз `click("row:media", count: 2)` | `visibleRows.count` |
| `key_down_selected` | `click("row:" + путь корня)`, затем ↓ | имя выделенного |
| `key_right_expanded` | `click("row:media")`, затем → | раскрыта ли media (Bool) |
| `key_left_collapsed` | затем ← | свёрнута ли media (Bool) |
| `tab_details` | `click("tab:Детали")` | `store.tab`: pie/details/ext/age/top/dups |
| `mode_size` | `click("mode:size")` | `store.mode`: size/alloc |
| `legend_click_selected` | `click("mode:alloc")`, `click("tab:Диаграмма")`, `click("legend:docs")` | имя выделенного |
| `details_dbl_selected` | `click("tab:Детали")`, `click("cell:docs", count: 2)` | имя выделенного |

**Запрещено** подставлять ответы или вызывать `store.select`/`toggle` внутри шагов (только в «свежем состоянии»). Если клик реально не работает — чини приложение, а не тест. Если рамка ячейки таблицы выглядит неверно (вне таблицы), напиши в REPORT.md, что вышло, и оставь `"не найден: cell:docs"`.

## Проверка

- `tools/check_task.sh 10u` → `ЗАДАНИЕ 10u: OK`;
- `tools/check_task.sh 03` — OK;
- снимки не сломаны: `tools/check_task.sh 07 --tab pie`.

Коммит «Задание 10u: живая проверка кликов» и раздел в конце REPORT.md (только дописать).
