# Задание 10u. Живая проверка кликов и клавиш (самотест интерфейса)

Снимки доказывают, что окно рисуется, но не доказывают, что работают клики. Нужен режим `--uitest`: приложение открывает **настоящее окно** с `ContentView`, посылает в него настоящие события мыши и клавиатуры (`NSEvent` → `window.sendEvent`) и печатает, как изменилось состояние `AppStore`. Никаких системных разрешений не нужно: события посылаются внутри своего процесса.

## Что сделать

Файл `Sources/TreeSizeApp/UITest.swift` и ключ `--uitest` в `main.swift` (рядом с `--selftest`/`--snapshot`, корень — `--root`).

1. **Подготовка.** Синхронный скан `--root`, `AppStore` без чтения UserDefaults (как в снимке), режим по умолчанию. Окно 1280×820 с `NSHostingView(rootView: ContentView().environmentObject(store))`, `window.makeKeyAndOrderFront(nil)`, `NSApp.activate(ignoringOtherApps: true)`. Дай 1 с на отрисовку: `RunLoop.main.run(until: Date().addingTimeInterval(1))`.

2. **Поиск элемента по тексту** через доступность SwiftUI внутри своего процесса (разрешения не нужны):

```swift
func findElement(_ root: Any, label: String) -> NSAccessibilityElementProtocol? {
    // обход в ширину по accessibilityChildren(); сравнивать accessibilityLabel() и accessibilityValue() как String
    var queue: [Any] = [root]
    while !queue.isEmpty {
        let el = queue.removeFirst()
        if let e = el as? NSAccessibilityElementProtocol & NSObjectProtocol,
           let a = e as? NSAccessibilityProtocol {
            let lbl = (a.accessibilityLabel() ?? "") + "|" + String(describing: a.accessibilityValue() ?? "")
            if lbl.contains(label) { return e }
        }
        if let a = el as? NSAccessibilityProtocol, let kids = a.accessibilityChildren() { queue.append(contentsOf: kids) }
    }
    return nil
}
// центр элемента в координатах окна:
let screenFrame = (el as! NSAccessibilityProtocol).accessibilityFrame()
let winPoint = window.convertPoint(fromScreen: NSPoint(x: screenFrame.midX, y: screenFrame.midY))
```

   Если у строки дерева нет подходящей метки, добавь в TreeView `.accessibilityElement(children: .combine)` и `.accessibilityLabel(node.displayName)` на строку. У кнопок вкладок и режима метка — их текст.

3. **Клик и двойной клик:**

```swift
func click(_ p: NSPoint, count: Int = 1, in w: NSWindow) {
    for c in 1...count {
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let e = NSEvent.mouseEvent(with: type, location: p, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                                       windowNumber: w.windowNumber, context: nil, eventNumber: 0, clickCount: c, pressure: 1)!
            w.sendEvent(e)
        }
    }
    RunLoop.main.run(until: Date().addingTimeInterval(0.4))
}
```

   Клавиша: `NSEvent.keyEvent(with: .keyDown, … characters: String(UnicodeScalar(NSDownArrowFunctionKey)!), charactersIgnoringModifiers: …, isARepeat: false, keyCode: 125)` → `w.sendEvent`, затем пауза 0,4 с. Коды: вниз 125, вправо 124, влево 123.

4. **Шаги и факты.** Каждый шаг — со свежим состоянием: заново выдели корень и сверни всё, кроме корня.

   | ключ | действие | что записать |
   |---|---|---|
   | `click_select` | один клик по строке «media» в дереве | имя `store.selected` |
   | `dbl_expand_rows` | двойной клик по строке «media» | `store.visibleRows.count` |
   | `dbl_collapse_rows` | ещё раз двойной клик по «media» | `visibleRows.count` |
   | `key_down_selected` | клик по строке корня, потом клавиша ↓ | имя выделенного |
   | `key_right_expanded` | выделена media (кликом), клавиша → | раскрыта ли media (Bool) |
   | `key_left_collapsed` | затем клавиша ← | свёрнута ли media (Bool) |
   | `tab_details` | клик по кнопке вкладки «Детали» | `store.tab` как строка: pie/details/ext/age/top/dups |
   | `mode_size` | клик по кнопке «Размер» | `store.mode`: size/alloc |
   | `legend_click_selected` | вернуть режим «На диске» кликом по «На диске», открыть вкладку «Диаграмма» кликом, клик по строке легенды «docs» | имя выделенного |
   | `details_dbl_selected` | выделить корень, открыть «Детали» кликом, двойной клик по строке «docs» в таблице | имя выделенного |

   Если элемент не нашёлся — записать в факт строку `"не найден: <текст>"`. Ответ в коде не подставлять: если клик не сработал, так и должно быть видно.

5. Напечатать JSON (`.sortedKeys`) в stdout и выйти `exit(0)`. Весь тест не дольше 30 с.

**Нельзя подгонять:** факты считаются только из `store` после настоящих событий. Прямые вызовы `store.select`, `store.toggle` и т. п. в шагах запрещены, кроме «подготовки свежего состояния» перед шагом.

## Проверка

- `tools/check_task.sh 10u` → `ЗАДАНИЕ 10u: OK`. Если какой-то клик в приложении правда не работает, чини **приложение** (TreeView, вкладки, легенду, таблицу), а не тест.
- `tools/check_task.sh 03` — OK.
- Коммит «Задание 10u: …» и раздел в конце REPORT.md (только дописать).
